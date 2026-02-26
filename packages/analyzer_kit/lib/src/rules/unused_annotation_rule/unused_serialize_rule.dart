part of 'unused_annotation_rule.dart';

final class UnusedSerializeRule extends UnusedAnnotationRule {
  UnusedSerializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.serialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.serialize;

  @override
  UnusedAnnotationVisitor getVisitor() => _UnusedSerializeVisitor(this);
}

final class _UnusedSerializeVisitor extends UnusedAnnotationVisitor {
  _UnusedSerializeVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    final expectedName = extractFeatureMethodName(node, annotation, 'toMap');
    if (expectedName == null) return null;
    return [expectedName];
  }
}
