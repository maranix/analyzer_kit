part of 'unused_annotation_rule.dart';

final class UnusedOverrideToStringRule extends BaseAnnotationRule {
  UnusedOverrideToStringRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.overrideToString);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.overrideToString;

  @override
  BaseAnnotationVisitor getVisitor() => _UnusedOverrideToStringVisitor(this);
}

final class _UnusedOverrideToStringVisitor extends BaseAnnotationVisitor {
  _UnusedOverrideToStringVisitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final hasMethod = node.members.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.overrideToString.name,
    );

    if (!hasMethod) reportError(node);
  }
}
