/// Base class for all database migration exceptions.
abstract class MigrationException implements Exception {
  final String message;
  const MigrationException(this.message);

  @override
  String toString() => 'MigrationException: $message';
}

/// Thrown when an intermediate migration step is required but not found in the registry.
class MigrationMissingException extends MigrationException {
  final int fromVersion;
  final int targetVersion;

  MigrationMissingException(this.fromVersion, this.targetVersion)
      : super('Missing migration step from version $fromVersion to $targetVersion.');
}

/// Thrown when SQLite foreign key check fails after executing migration steps.
class MigrationIntegrityException extends MigrationException {
  final List<String> violations;

  MigrationIntegrityException(this.violations)
      : super(
          'Foreign key integrity check failed after migration:\n${violations.join('\n')}',
        );
}
