/// Naming strategy applied to map keys in `@Serialize` and `@Deserialize`.
enum FieldRename {
  /// Uses the Dart field name unchanged (e.g. `firstName` -> `firstName`).
  none,

  /// Converts Dart field names to `snake_case`
  /// (e.g. `firstName` -> `first_name`).
  snake,

  /// Converts Dart field names to `kebab-case`
  /// (e.g. `firstName` -> `first-name`).
  kebab,

  /// Converts Dart field names to `PascalCase`
  /// (e.g. `firstName` -> `FirstName`).
  pascal,

  /// Converts Dart field names to `SCREAMING_SNAKE_CASE`
  /// (e.g. `firstName` -> `FIRST_NAME`).
  screamingSnake,
}
