/// Method configuration used for the `@Serialize()` annotation.
sealed class SerializeMethod {
  /// Uses the `toMap()` convention.
  const factory SerializeMethod.toMap() = _ToMapMethod;

  /// Uses the `toJson()` convention.
  const factory SerializeMethod.toJson() = _ToJsonMethod;

  /// Uses a custom string for the serialization method's name.
  const factory SerializeMethod.custom(String name) = _CustomSerializeMethod;
  const SerializeMethod({required this.methodName});

  final String methodName;
}

final class _ToMapMethod extends SerializeMethod {
  const _ToMapMethod() : super(methodName: 'toMap');
}

final class _ToJsonMethod extends SerializeMethod {
  const _ToJsonMethod() : super(methodName: 'toJson');
}

final class _CustomSerializeMethod extends SerializeMethod {
  const _CustomSerializeMethod(String name) : super(methodName: name);
}

/// Marks a class for serialization generation.
///
/// Use as `@Serialize()` or `@serialize` on a class declaration.
final class Serialize {
  const Serialize({this.name = const SerializeMethod.toMap()});

  /// The method name configuration for serializing the class.  Defaults to `.toMap()`.
  final SerializeMethod name;
}

/// Convenience constant for `@Serialize()`.
const serialize = Serialize();
