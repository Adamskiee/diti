import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/merge_lcov.dart' as merger;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lcov_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'normalizes package source file paths and consolidates into single lcov',
    () async {
      final rootCoverageDir = Directory('${tempDir.path}/coverage');
      await rootCoverageDir.create(recursive: true);
      final rootLcov = File('${rootCoverageDir.path}/lcov.info');
      await rootLcov.writeAsString('''
SF:lib/main.dart
DA:1,1
end_of_record
''');

      final pkgCoverageDir = Directory(
        '${tempDir.path}/packages/diti_database/coverage',
      );
      await pkgCoverageDir.create(recursive: true);
      final pkgLcov = File('${pkgCoverageDir.path}/lcov.info');
      await pkgLcov.writeAsString('''
SF:lib/src/database.dart
DA:10,1
end_of_record
''');

      await merger.mergeLcovFiles(
        rootDir: tempDir.path,
        outputFilePath: rootLcov.path,
      );

      expect(await rootLcov.exists(), isTrue);
      final content = await rootLcov.readAsString();

      expect(content, contains('SF:lib/main.dart'));
      expect(
        content,
        contains('SF:packages/diti_database/lib/src/database.dart'),
      );
      expect(content, contains('end_of_record'));
    },
  );

  test('handles missing package coverage gracefully', () async {
    final rootCoverageDir = Directory('${tempDir.path}/coverage');
    await rootCoverageDir.create(recursive: true);
    final rootLcov = File('${rootCoverageDir.path}/lcov.info');
    await rootLcov.writeAsString('''
SF:lib/main.dart
DA:1,1
end_of_record
''');

    final pkgDir = Directory('${tempDir.path}/packages/timer_engine');
    await pkgDir.create(recursive: true);

    await merger.mergeLcovFiles(
      rootDir: tempDir.path,
      outputFilePath: rootLcov.path,
    );

    final content = await rootLcov.readAsString();
    expect(content, contains('SF:lib/main.dart'));
  });

  test('calling mergeLcovFiles multiple times is idempotent', () async {
    final rootCoverageDir = Directory('${tempDir.path}/coverage');
    await rootCoverageDir.create(recursive: true);
    final rootLcov = File('${rootCoverageDir.path}/lcov.info');
    await rootLcov.writeAsString('''
SF:lib/main.dart
DA:1,1
end_of_record
''');

    final pkgCoverageDir = Directory(
      '${tempDir.path}/packages/diti_database/coverage',
    );
    await pkgCoverageDir.create(recursive: true);
    final pkgLcov = File('${pkgCoverageDir.path}/lcov.info');
    await pkgLcov.writeAsString('''
SF:lib/src/database.dart
DA:10,1
end_of_record
''');

    // First merge
    await merger.mergeLcovFiles(
      rootDir: tempDir.path,
      outputFilePath: rootLcov.path,
    );
    final firstContent = await rootLcov.readAsString();

    // Second merge
    await merger.mergeLcovFiles(
      rootDir: tempDir.path,
      outputFilePath: rootLcov.path,
    );
    final secondContent = await rootLcov.readAsString();

    // Third merge
    await merger.mergeLcovFiles(
      rootDir: tempDir.path,
      outputFilePath: rootLcov.path,
    );
    final thirdContent = await rootLcov.readAsString();

    expect(secondContent, equals(firstContent));
    expect(thirdContent, equals(firstContent));

    final mainMatches =
        RegExp(r'SF:lib/main\.dart').allMatches(thirdContent).length;
    final pkgMatches = RegExp(
      r'SF:packages/diti_database/lib/src/database\.dart',
    ).allMatches(thirdContent).length;
    expect(mainMatches, equals(1));
    expect(pkgMatches, equals(1));
  });

  test(
    'normalizes Windows backslashes in package source paths to POSIX',
    () async {
      final rootCoverageDir = Directory('${tempDir.path}/coverage');
      await rootCoverageDir.create(recursive: true);
      final rootLcov = File('${rootCoverageDir.path}/lcov.info');
      await rootLcov.writeAsString('''
SF:lib/main.dart
DA:1,1
end_of_record
''');

      final pkgCoverageDir = Directory(
        '${tempDir.path}/packages/diti_tracker/coverage',
      );
      await pkgCoverageDir.create(recursive: true);
      final pkgLcov = File('${pkgCoverageDir.path}/lcov.info');
      await pkgLcov.writeAsString(r'''
SF:lib\src\tracker.dart
DA:5,1
end_of_record
''');

      await merger.mergeLcovFiles(
        rootDir: tempDir.path,
        outputFilePath: rootLcov.path,
      );

      final content = await rootLcov.readAsString();
      expect(
        content,
        contains('SF:packages/diti_tracker/lib/src/tracker.dart'),
      );
      expect(content.contains(r'\'), isFalse);
    },
  );
}
