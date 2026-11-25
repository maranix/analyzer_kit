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
  FieldSyncResult? checkSync(ClassDeclaration node) {
    final equalsMethod = findMethodDeclaration(
      node,
      FeatureMethod.overrideEquals.name,
    );
    final hashCodeGetter = findMethodDeclaration(
      node,
      FeatureMethod.overrideHashCode.name,
    );
    if (equalsMethod == null || hashCodeGetter == null) return null;

    final fields = extractGeneratableFields(node);
    final eqSync = checkBodySync(equalsMethod.body, fields);
    final hashSync = checkBodySync(hashCodeGetter.body, fields);
    if (eqSync.isInSync && hashSync.isInSync) {
      return const FieldSyncResult();
    }
    final missing = {...eqSync.missingFields, ...hashSync.missingFields};
    return FieldSyncResult(missingFields: missing.toList());
  }
}
