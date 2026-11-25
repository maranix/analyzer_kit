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
  bool isSatisfied(ClassDeclaration node) {
    final equalsMethod = findMethodDeclaration(
      node,
      FeatureMethod.overrideEquals.name,
    );
    final hashCodeGetter = findMethodDeclaration(
      node,
      FeatureMethod.overrideHashCode.name,
    );
    if (equalsMethod == null || hashCodeGetter == null) return false;

    final fields = extractGeneratableFields(node);
    return isBodyInSync(equalsMethod.body, fields) &&
        isBodyInSync(hashCodeGetter.body, fields);
  }
}
