/// Method configuration used for the `@Deserialize()` annotation.
sealed class DeserializeMethod {
  /// Uses the `fromMap(Map<String, dynamic> map)` convention.
  const factory DeserializeMethod.fromMap() = _FromMapMethod;

  /// Uses the `fromJson(Map<String, dynamic> json)` convention.
  const factory DeserializeMethod.fromJson() = _FromJsonMethod;

  /// Uses a custom string for the deserialization method's name.
  const factory DeserializeMethod.custom(String name) =
      _CustomDeserializeMethod;
  const DeserializeMethod({required this.methodName});

  /// The name of the deserialization method.
  final String methodName;
}

final class _FromMapMethod extends DeserializeMethod {
  const _FromMapMethod() : super(methodName: "fromMap");
}

final class _FromJsonMethod extends DeserializeMethod {
  const _FromJsonMethod() : super(methodName: "fromJson");
}

final class _CustomDeserializeMethod extends DeserializeMethod {
  const _CustomDeserializeMethod(String name) : super(methodName: name);
}

/// Marks a class for deserialization generation.
///
/// Use as `@Deserialize()` or `@deserialize` on a class declaration.
final class Deserialize {
  /// Creates a new instance of [Deserialize].
  const Deserialize({this.name = const .fromMap()});

  /// The method name configuration for deserializing the class. Defaults to `.fromMap()`.
  final DeserializeMethod name;
}

/// Convenience constant for `@Deserialize()`.
const deserialize = Deserialize();
