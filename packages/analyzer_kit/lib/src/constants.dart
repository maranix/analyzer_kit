import 'package:analyzer/error/error.dart' show LintCode;

/// Lint diagnostic codes for annotation rules.
abstract final class LintCodes {
  static const LintCode copyWith = LintCode(
    'copy_with_annotation',
    'Classes annotated with @CopyWith must have a `copyWith` method.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or add a `copyWith` method.',
  );

  static const LintCode copyWithOutOfSync = LintCode(
    'copy_with_out_of_sync',
    '`copyWith` is out of sync with class fields ({0}).',
    severity: .WARNING,
    correctionMessage: 'Update `copyWith` to match the class fields.',
  );

  static const LintCode overrideEquality = LintCode(
    'override_equality_annotation',
    'Classes annotated with @OverrideEquality must override both `==` and `hashCode`.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or override both `==` and `hashCode`.',
  );

  static const LintCode overrideEqualityOutOfSync = LintCode(
    'override_equality_out_of_sync',
    '`==` / `hashCode` is out of sync with class fields ({0}).',
    severity: .WARNING,
    correctionMessage: 'Update `==` and `hashCode` to match the class fields.',
  );

  static const LintCode overrideToString = LintCode(
    'override_to_string_annotation',
    'Classes annotated with @OverrideToString must override `toString`.',
    severity: .ERROR,
    correctionMessage: 'Either remove the annotation or override `toString`.',
  );

  static const LintCode overrideToStringOutOfSync = LintCode(
    'override_to_string_out_of_sync',
    '`toString` is out of sync with class fields ({0}).',
    severity: .WARNING,
    correctionMessage: 'Update `toString` to match the class fields.',
  );

  static const LintCode serialize = LintCode(
    'serialize_annotation',
    'Classes annotated with @Serialize must have a serialization method.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or add a serialization method.',
  );

  static const LintCode serializeOutOfSync = LintCode(
    'serialize_out_of_sync',
    'Serialization method is out of sync with class fields ({0}).',
    severity: .WARNING,
    correctionMessage:
        'Update the serialization method to match the class fields.',
  );

  static const LintCode deserialize = LintCode(
    'deserialize_annotation',
    'Classes annotated with @Deserialize must have a deserialization factory/method.',
    severity: .ERROR,
    correctionMessage:
        'Either remove the annotation or add a deserialization factory/method.',
  );

  static const LintCode deserializeOutOfSync = LintCode(
    'deserialize_out_of_sync',
    'Deserialization factory/method is out of sync with class fields ({0}).',
    severity: .WARNING,
    correctionMessage:
        'Update the deserialization factory/method to match the class fields.',
  );
}
