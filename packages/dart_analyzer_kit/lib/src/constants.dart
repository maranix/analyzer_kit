import 'package:analyzer/error/error.dart' show LintCode;

abstract final class MethodConstants {
  // toString and hashCode names conflict with existing `toString` and `hashCode`
  // methods in a class, Which is provided by [Object] as default. Since everything
  // is an object in dart naturally this class inherits these methods as well.
  static const String overrideToString = 'toString';
  static const String overrideHashCode = 'hashCode';

  static const String toMap = 'toMap';
  static const String equals = '==';
  static const String copyWith = 'copyWith';
  static const String operatorEquals = 'operator ==';
}

abstract final class DiagnosticLintCode {
  static const LintCode copyWith = LintCode(
    "unused_copy_with_annotation",
    "Classes annotated with `@copyWith` or `@CopyWith()` must have a `copyWith` method.",
    severity: .ERROR,
    correctionMessage: "Either remove the annotation or add `copyWith` method",
  );

  static const LintCode overrideEquality = LintCode(
    'unused_override_equality_annotation',
    "Classes annotated with @overrideEquality must override both `==` and `hashCode`.",
    severity: .ERROR,
    correctionMessage:
        "Either remove this annotation or override both `==` and `hashCode`.",
  );

  static const LintCode overrideToString = LintCode(
    'unused_debug_string_annotation',
    "Classes annotated with @debugString must override `toString` method.",
    severity: .ERROR,
    correctionMessage:
        "Either remove this annotation or override `toString` method.",
  );

  static const LintCode serialize = LintCode(
    "unused_serialize_annotation",
    "Classes annotated with @serialize must have a `toMap` method.",
    severity: .ERROR,
    correctionMessage: "Either remove this annotation or add `toMap` method.",
  );
}
