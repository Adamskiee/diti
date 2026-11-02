import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> mergeLcovFiles({
  required String rootDir,
  required String outputFilePath,
}) async {
  final buffer = StringBuffer();
  final outputFile = File(outputFilePath);

  if (await outputFile.exists()) {
    final rootContent = await outputFile.readAsString();
    if (rootContent.trim().isNotEmpty) {
      buffer.writeln(rootContent.trim());
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
              final rawPath = line.substring(3).trim();
              final normalized = rawPath.startsWith('packages/')
                  ? rawPath
                  : 'packages/$pkgName/$rawPath';
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
