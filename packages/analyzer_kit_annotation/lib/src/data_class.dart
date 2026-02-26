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
    this.serialize = true,
    this.deserialize = true,
  });

  /// Whether to generate the `copyWith` method. Defaults to `true`.
  final bool copyWith;

  /// Whether to generate the `==` operator and `hashCode` overrides. Defaults to `true`.
  final bool overrideEquality;

  /// Whether to generate the `toString` override. Defaults to `true`.
  final bool overrideToString;

  /// Whether to generate the serialization method. Defaults to `true`.
  final bool serialize;

  /// Whether to generate the deserialization factory/method. Defaults to `true`.
  final bool deserialize;
}

/// Convenience constant for `@DataClass()`.
const dataClass = DataClass();
