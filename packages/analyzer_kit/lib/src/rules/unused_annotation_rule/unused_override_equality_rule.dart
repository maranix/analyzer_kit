part of 'unused_annotation_rule.dart';

final class UnusedOverrideEqualityRule extends UnusedAnnotationRule {
  UnusedOverrideEqualityRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.overrideEquality);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.overrideEquality;

  @override
  UnusedAnnotationVisitor getVisitor() => _UnusedOverrideEqualityVisitor(this);
}

final class _UnusedOverrideEqualityVisitor extends UnusedAnnotationVisitor {
  _UnusedOverrideEqualityVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    return [
      FeatureMethod.overrideEquals.name,
      FeatureMethod.overrideHashCode.name,
    ];
  }
}
