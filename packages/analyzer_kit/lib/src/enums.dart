import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer_kit/src/constants.dart';

/// Annotation names recognized by the plugin.
enum FeatureAnnotation {
  dataClass('DataClass'),
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
  overrideEquals('==');

  const FeatureMethod(this.name);

  final String name;
}

/// Maps each feature to its diagnostic code.
enum FeatureDiagnosticCode {
  copyWith(LintCodes.copyWith),
  overrideToString(LintCodes.overrideToString),
  overrideEquality(LintCodes.overrideEquality),
  serialize(LintCodes.serialize),
  deserialize(LintCodes.deserialize);

  const FeatureDiagnosticCode(this.diag);

  final DiagnosticCode diag;
}
