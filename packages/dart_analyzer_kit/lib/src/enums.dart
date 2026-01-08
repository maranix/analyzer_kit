import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:dart_analyzer_kit/src/constants.dart';

enum CaseStyle { sensitive, insensitive }

enum FeatureAnnotation {
  copyWith("CopyWith"),
  serialize("Serialize"),
  overrideToString("OverrideToString"),
  overrideEquality("OverrideEquality");

  final String name;

  const FeatureAnnotation(this.name);
}

enum FeatureMethod {
  copyWith("copyWith"),
  toMap("toMap"),
  overrideToString("toString"),
  overrideHashCode("hashCode"),
  overrideEquals("==");

  final String name;

  const FeatureMethod(this.name);
}

enum FeatureDiagnosticCode {
  copyWith(DiagnosticLintCode.copyWith),
  serialize(DiagnosticLintCode.serialize),
  overrideToString(DiagnosticLintCode.overrideToString),
  overrideEquality(DiagnosticLintCode.overrideEquality);

  final DiagnosticCode diag;

  const FeatureDiagnosticCode(this.diag);
}
