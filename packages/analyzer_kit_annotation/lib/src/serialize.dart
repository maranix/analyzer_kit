/// Method configuration used for the `@Serialize()` annotation.
sealed class SerializeMethod {
  const SerializeMethod({required this.methodName});

  /// Uses the `toMap()` convention.
  const factory SerializeMethod.toMap() = _ToMapMethod;

  /// Uses the `toJson()` convention.
  const factory SerializeMethod.toJson() = _ToJsonMethod;

  /// Uses a custom string for the serialization method's name.
  const factory SerializeMethod.custom(String name) = _CustomSerializeMethod;

  /// The name of the serialization method.
  final String methodName;
}

final class _ToMapMethod extends SerializeMethod {
  const _ToMapMethod() : super(methodName: "toMap");
}

final class _ToJsonMethod extends SerializeMethod {
  const _ToJsonMethod() : super(methodName: "toJson");
}

final class _CustomSerializeMethod extends SerializeMethod {
  const _CustomSerializeMethod(String name) : super(methodName: name);
}

/// Marks a class for serialization generation.
///
/// Use as `@Serialize()` or `@serialize` on a class declaration.
final class Serialize {
  /// Creates a new instance of [Serialize].
  const Serialize({this.name = const .toMap()});

  /// The method name configuration for serializing the class.  Defaults to `.toMap()`.
  final SerializeMethod name;
}

/// Convenience constant for `@Serialize()`.
const serialize = Serialize();
