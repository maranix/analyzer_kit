part of 'unused_annotation_rule.dart';

final class UnusedDeserializeRule extends UnusedAnnotationRule {
  UnusedDeserializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.deserialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.deserialize;

  @override
  UnusedAnnotationVisitor getVisitor() => _UnusedDeserializeVisitor(this);
}

final class _UnusedDeserializeVisitor extends UnusedAnnotationVisitor {
  _UnusedDeserializeVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    final expectedName = extractFeatureMethodName(node, annotation, 'fromMap');
    if (expectedName == null) return null;
    return [expectedName];
  }

  @override
  bool reduceExpectedMethods(
    NodeList<ClassMember> members,
    Iterable<String> expectedMethods,
  ) {
    // A deserialize function can be a factory constructor OR a static method.
    for (final member in members) {
      if (member is ConstructorDeclaration && member.factoryKeyword != null) {
        return expectedMethods.contains(member.name?.lexeme);
      }

      if (member is MethodDeclaration && member.isStatic) {
        return expectedMethods.contains(member.name.lexeme);
      }
    }

    return false;
  }
}
