part of 'unused_annotation_rule.dart';

final class UnusedOverrideEqualityRule extends BaseAnnotationRule {
  UnusedOverrideEqualityRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.overrideEquality);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.overrideEquality;

  @override
  BaseAnnotationVisitor getVisitor() => _UnusedOverrideEqualityVisitor(this);
}

final class _UnusedOverrideEqualityVisitor extends BaseAnnotationVisitor {
  _UnusedOverrideEqualityVisitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final hasEquals = node.members.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.overrideEquals.name,
    );
    final hasHashCode = node.members.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.overrideHashCode.name,
    );

    if (!hasEquals || !hasHashCode) reportError(node);
  }
}
