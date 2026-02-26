part of 'unused_annotation_rule.dart';

final class UnusedSerializeRule extends BaseAnnotationRule {
  UnusedSerializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.serialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.serialize;

  @override
  BaseAnnotationVisitor getVisitor() => _UnusedSerializeVisitor(this);
}

final class _UnusedSerializeVisitor extends BaseAnnotationVisitor {
  _UnusedSerializeVisitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final expectedName = extractFeatureMethodName(node, annotation, 'toMap');
    if (expectedName == null) return; // Feature disabled or unset

    final hasMethod = node.members.any(
      (m) => m is MethodDeclaration && m.name.lexeme == expectedName,
    );

    if (!hasMethod) reportError(node);
  }
}
