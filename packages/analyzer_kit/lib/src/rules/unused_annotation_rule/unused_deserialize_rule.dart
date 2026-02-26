part of 'unused_annotation_rule.dart';

final class UnusedDeserializeRule extends BaseAnnotationRule {
  UnusedDeserializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.deserialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.deserialize;

  @override
  BaseAnnotationVisitor getVisitor() => _UnusedDeserializeVisitor(this);
}

final class _UnusedDeserializeVisitor extends BaseAnnotationVisitor {
  _UnusedDeserializeVisitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final expectedName = extractFeatureMethodName(node, annotation, 'fromMap');
    if (expectedName == null) return;

    // A deserialize function can be a factory constructor OR a static method.
    final hasFactory = node.members.any(
      (m) =>
          m is ConstructorDeclaration &&
          m.factoryKeyword != null &&
          m.name?.lexeme == expectedName,
    );

    final hasStaticMethod = node.members.any(
      (m) =>
          m is MethodDeclaration && m.isStatic && m.name.lexeme == expectedName,
    );

    if (!hasFactory && !hasStaticMethod) reportError(node);
  }
}
