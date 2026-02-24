import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:dart_analyzer_kit/src/constants.dart';

/// Annotation names recognized by the plugin.
enum FeatureAnnotation {
  copyWith('CopyWith'),
  overrideToString('OverrideToString'),
  overrideEquality('OverrideEquality');

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
  overrideEquality(LintCodes.overrideEquality);

  const FeatureDiagnosticCode(this.diag);

  final DiagnosticCode diag;
}
