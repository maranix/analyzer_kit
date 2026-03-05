part of "annotation_rule.dart";

final class OverrideToStringRule extends AnnotationRule {
  OverrideToStringRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.overrideToString);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.overrideToString;

  @override
  AnnotationVisitor getVisitor() => _OverrideToStringVisitor(this);
}

final class _OverrideToStringVisitor extends AnnotationVisitor {
  _OverrideToStringVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    return [FeatureMethod.overrideToString.name];
  }
}
