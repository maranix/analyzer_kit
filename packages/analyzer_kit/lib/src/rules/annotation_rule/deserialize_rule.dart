part of 'annotation_rule.dart';

final class DeserializeRule extends AnnotationRule {
  DeserializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.deserialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.deserialize;

  @override
  AnnotationVisitor getVisitor() => _DeserializeVisitor(this);
}

final class _DeserializeVisitor extends AnnotationVisitor {
  _DeserializeVisitor(super.rule);

  @override
  FieldSyncResult? checkSync(ClassDeclaration node) {
    final expectedName = extractFeatureMethodName(node, annotation, 'fromMap');
    if (expectedName == null) return const FieldSyncResult();

    final member = findDeserializeMember(node, expectedName);
    if (member == null) return null;
    return checkDeserializeSync(member, extractGeneratableFields(node));
  }
}
