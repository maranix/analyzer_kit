/// Marks a class for `toString` method override generation.
///
/// Use as `@OverrideToString()` or `@overrideToString` on a class declaration.
/// Set [multiline] to `true` to format each field on its own indented line.
final class const OverrideToString({
  /// Whether to format each field on its own indented line in `toString()`.
  final bool multiline = false,
}) {
  /// Creates an [OverrideToString] annotation.
  this;
}

/// Convenience constant for `@OverrideToString()`.
const overrideToString = OverrideToString();
