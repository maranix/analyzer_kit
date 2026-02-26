import 'package:analyzer/error/error.dart' show LintCode;

/// Lint diagnostic codes for unused annotation rules.
abstract final class LintCodes {
  static const LintCode dataClass = LintCode(
    'unused_data_class_annotation',
    'Classes annotated with @DataClass must contain the required methods for enabled features.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or add the required methods.',
  );

  static const LintCode copyWith = LintCode(
    'unused_copy_with_annotation',
    'Classes annotated with @CopyWith must have a `copyWith` method.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or add a `copyWith` method.',
  );

  static const LintCode overrideEquality = LintCode(
    'unused_override_equality_annotation',
    'Classes annotated with @OverrideEquality must override both `==` and `hashCode`.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or override both `==` and `hashCode`.',
  );

  static const LintCode overrideToString = LintCode(
    'unused_override_to_string_annotation',
    'Classes annotated with @OverrideToString must override `toString`.',
    severity: .ERROR,
    correctionMessage: 'Either remove the annotation or override `toString`.',
  );

  static const LintCode serialize = LintCode(
    'unused_serialize_annotation',
    'Classes annotated with @Serialize must have a serialization method.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or add a serialization method.',
  );

  static const LintCode deserialize = LintCode(
    'unused_deserialize_annotation',
    'Classes annotated with @Deserialize must have a deserialization factory/method.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or add a deserialization factory/method.',
  );
}
