/// Marks a class for `copyWith` method generation.
///
/// Use as `@CopyWith()` or `@copyWith` on a class declaration.
/// Set [nullable] to `true` to wrap nullable fields in `T? Function()?`
/// parameters so callers can explicitly reset nullable fields to `null`.
final class CopyWith {
  /// Creates a [CopyWith] annotation.
  const CopyWith({this.nullable = false});

  /// Whether nullable fields use `T? Function()?` parameters so they can be
  /// explicitly set to `null` via `copyWith(field: () => null)`.
  final bool nullable;
}

/// Convenience constant for `@CopyWith()`.
const copyWith = CopyWith();
