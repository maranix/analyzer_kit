/// Marks a class for `copyWith`, `==`, `hashCode`, `toString`, `toMap`, and `fromMap` generation.
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
    this.deepCollectionEquality,
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

  /// Whether to use deep recursive equality for collections in this class.
  ///
  /// When `null` or `true`, generated equality/hashCode methods use
  /// `deepEquals` and `deepHash`. When `false`, shallow collection equality is
  /// generated instead.
  final bool? deepCollectionEquality;
}

/// Convenience constant for `@DataClass()`.
const dataClass = DataClass();
