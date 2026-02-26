part of 'unused_annotation_rule.dart';

final class UnusedCopyWithRule extends BaseAnnotationRule {
  UnusedCopyWithRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.copyWith);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.copyWith;

  @override
  BaseAnnotationVisitor getVisitor() => _UnusedCopyWithVisitor(this);
}

final class _UnusedCopyWithVisitor extends BaseAnnotationVisitor {
  _UnusedCopyWithVisitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final hasMethod = node.members.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.copyWith.name,
    );

    if (!hasMethod) reportError(node);
  }
}
