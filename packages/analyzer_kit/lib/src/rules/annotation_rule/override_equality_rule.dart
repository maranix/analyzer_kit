part of 'annotation_rule.dart';

final class OverrideEqualityRule extends AnnotationRule {
  OverrideEqualityRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.overrideEquality);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.overrideEquality;

  @override
  AnnotationVisitor getVisitor() => _OverrideEqualityVisitor(this);
}

final class _OverrideEqualityVisitor extends AnnotationVisitor {
  _OverrideEqualityVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    return [
      FeatureMethod.overrideEquals.name,
      FeatureMethod.overrideHashCode.name,
    ];
  }
}
