part of "annotation_rule.dart";

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
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    final expectedName = extractFeatureMethodName(node, annotation, "fromMap");
    if (expectedName == null) return null;
    return [expectedName];
  }

  @override
  bool reduceExpectedMethods(
    Iterable<SyntacticEntity> members,
    Iterable<String> expectedMethods,
  ) {
    bool found = false;
    // A deserialize function can be a factory constructor OR a static method.
    for (final member in members) {
      if (found) break;

      if (member is ConstructorDeclaration && member.factoryKeyword != null) {
        found = expectedMethods.contains(member.name?.lexeme);
      }

      if (member is MethodDeclaration && member.isStatic) {
        found = expectedMethods.contains(member.name.lexeme);
      }
    }

    return found;
  }
}
