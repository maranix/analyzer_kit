import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer_kit/src/constants.dart';

/// Annotation names recognized by the plugin.
enum FeatureAnnotation {
  copyWith('CopyWith'),
  overrideToString('OverrideToString'),
  overrideEquality('OverrideEquality'),
  serialize('Serialize'),
  deserialize('Deserialize');

  const FeatureAnnotation(this.name);

  final String name;
}

/// Method names that each annotation expects on the class.
enum FeatureMethod {
  copyWith('copyWith'),
  overrideToString('toString'),
  overrideHashCode('hashCode'),
  overrideEquals('=='),
  operatorEquals('operator =='),
  fromMap('fromMap'),
  toMap('toMap');

  const FeatureMethod(this.name);

  final String name;
}

/// Maps each feature to its missing-method and out-of-sync diagnostic codes.
enum FeatureDiagnosticCode {
  copyWith(LintCodes.copyWith, LintCodes.copyWithOutOfSync),
  overrideToString(
    LintCodes.overrideToString,
    LintCodes.overrideToStringOutOfSync,
  ),
  overrideEquality(
    LintCodes.overrideEquality,
    LintCodes.overrideEqualityOutOfSync,
  ),
  serialize(LintCodes.serialize, LintCodes.serializeOutOfSync),
  deserialize(LintCodes.deserialize, LintCodes.deserializeOutOfSync);

  const FeatureDiagnosticCode(this.diag, this.outOfSyncDiag);

  final DiagnosticCode diag;
  final DiagnosticCode outOfSyncDiag;
}
