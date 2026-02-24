import 'package:analyzer/error/error.dart' show LintCode;

/// Method name constants used across lint rules and fixes.
abstract final class MethodNames {
  static const String overrideToString = 'toString';
  static const String overrideHashCode = 'hashCode';
  static const String equals = '==';
  static const String copyWith = 'copyWith';
  static const String operatorEquals = 'operator ==';
}

/// Lint diagnostic codes for unused annotation rules.
abstract final class LintCodes {
  static const LintCode copyWith = LintCode(
    'unused_copy_with_annotation',
    'Classes annotated with @copyWith must have a `copyWith` method.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or add a `copyWith` method.',
  );

  static const LintCode overrideEquality = LintCode(
    'unused_override_equality_annotation',
    'Classes annotated with @overrideEquality must override both `==` and `hashCode`.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or override both `==` and `hashCode`.',
  );

  static const LintCode overrideToString = LintCode(
    'unused_override_to_string_annotation',
    'Classes annotated with @overrideToString must override `toString`.',
    severity: .ERROR,
    correctionMessage: 'Either remove the annotation or override `toString`.',
  );
}
