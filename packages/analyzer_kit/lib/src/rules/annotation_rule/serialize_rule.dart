part of 'annotation_rule.dart';

final class SerializeRule extends AnnotationRule {
  SerializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.serialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.serialize;

  @override
  AnnotationVisitor getVisitor() => _SerializeVisitor(this);
}

final class _SerializeVisitor extends AnnotationVisitor {
  _SerializeVisitor(super.rule);

  @override
  FieldSyncResult? checkSync(ClassDeclaration node) {
    final expectedName = extractFeatureMethodName(node, annotation, 'toMap');
    if (expectedName == null) return const FieldSyncResult();

    final method = findMethodDeclaration(node, expectedName);
    if (method == null) return null;
    return checkSerializeSync(method.body, extractGeneratableFields(node));
  }
}
