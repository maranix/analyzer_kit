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
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    final expectedName = extractFeatureMethodName(node, annotation, 'toMap');
    if (expectedName == null) return null;
    return [expectedName];
  }
}
