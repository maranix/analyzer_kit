part of 'unused_annotation_rule.dart';

final class UnusedOverrideToStringRule extends UnusedAnnotationRule {
  UnusedOverrideToStringRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.overrideToString);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.overrideToString;

  @override
  UnusedAnnotationVisitor getVisitor() => _UnusedOverrideToStringVisitor(this);
}

final class _UnusedOverrideToStringVisitor extends UnusedAnnotationVisitor {
  _UnusedOverrideToStringVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    return [FeatureMethod.overrideToString.name];
  }
}
