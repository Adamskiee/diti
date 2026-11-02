import 'dart:io';
import 'package:path/path.dart' as p;

List<String> filterRootLcovLines(String content) {
  final lines = content.split('\n');
  final result = <String>[];
  final currentRecord = <String>[];
  var isPackageRecord = false;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty && currentRecord.isEmpty) {
      continue;
    }
    currentRecord.add(line);
    if (trimmed.startsWith('SF:')) {
      final rawPath = trimmed.substring(3).trim().replaceAll(r'\', '/');
      if (rawPath.startsWith('packages/')) {
        isPackageRecord = true;
      }
    }
    if (trimmed == 'end_of_record') {
      if (!isPackageRecord) {
        result.addAll(currentRecord);
      }
      currentRecord.clear();
      isPackageRecord = false;
    }
  }

  if (!isPackageRecord && currentRecord.isNotEmpty) {
    result.addAll(currentRecord);
  }

  return result;
}

Future<void> mergeLcovFiles({
  required String rootDir,
  required String outputFilePath,
}) async {
  final buffer = StringBuffer();
  final outputFile = File(outputFilePath);

  if (await outputFile.exists()) {
    final rootContent = await outputFile.readAsString();
    final preservedLines = filterRootLcovLines(rootContent);
    for (final line in preservedLines) {
      buffer.writeln(line);
    }
  }

  final packagesDir = Directory(p.join(rootDir, 'packages'));
  if (await packagesDir.exists()) {
    final entities = await packagesDir.list().toList();
    entities.sort((a, b) => a.path.compareTo(b.path));

    for (final entity in entities) {
      if (entity is Directory) {
        final pkgName = p.basename(entity.path);
        final pkgLcov = File(p.join(entity.path, 'coverage', 'lcov.info'));

        if (await pkgLcov.exists()) {
          final lines = await pkgLcov.readAsLines();
          for (final line in lines) {
            if (line.startsWith('SF:')) {
              var rawPath = line.substring(3).trim().replaceAll(r'\', '/');
              while (rawPath.startsWith('./')) {
                rawPath = rawPath.substring(2);
              }
              if (rawPath.startsWith('/')) {
                rawPath = rawPath.replaceFirst(RegExp(r'^/+'), '');
              }
              final normalized = rawPath.startsWith('packages/')
                  ? rawPath
                  : p.posix.join('packages', pkgName, rawPath);
              buffer.writeln('SF:$normalized');
            } else {
              buffer.writeln(line);
            }
          }
        }
      }
    }
  }

  if (buffer.isNotEmpty) {
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString('${buffer.toString().trim()}\n');
    stdout.writeln('Consolidated coverage written to: $outputFilePath');
  } else {
    stdout.writeln('No coverage reports found to consolidate.');
  }
}

Future<void> main(List<String> args) async {
  final currentDir = Directory.current.path;
  final outputPath = p.join(currentDir, 'coverage', 'lcov.info');
  await mergeLcovFiles(rootDir: currentDir, outputFilePath: outputPath);
}
