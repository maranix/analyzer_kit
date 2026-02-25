/// Marks a class for `copyWith`, `==`, `hashCode` and `toString` generation.
///
/// Use as `@DataClass()` or `@dataClass` on a class declaration.
final class DataClass {
  /// Creates a [DataClass] annotation.
  /// 
  /// By default, all code generation features are enabled.
  /// You can selectively disable them by passing `false` to the respective arguments.
  const DataClass({
    this.copyWith = true,
    this.overrideEquality = true,
    this.overrideToString = true,
  });

  /// Whether to generate the `copyWith` method. Defaults to `true`.
  final bool copyWith;

  /// Whether to generate the `==` operator and `hashCode` overrides. Defaults to `true`.
  final bool overrideEquality;

  /// Whether to generate the `toString` override. Defaults to `true`.
  final bool overrideToString;
}

/// Convenience constant for `@DataClass()`.
const dataClass = DataClass();
