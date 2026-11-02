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
}
