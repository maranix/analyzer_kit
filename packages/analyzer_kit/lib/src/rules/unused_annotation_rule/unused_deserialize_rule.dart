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
  bool hasExpectedMethod(ClassMember member, String methodName) {
    // A deserialize function can be a factory constructor OR a static method.
    if (member is ConstructorDeclaration && member.factoryKeyword != null) {
      return member.name?.lexeme == methodName;
    }
    if (member is MethodDeclaration && member.isStatic) {
      return member.name.lexeme == methodName;
    }
    return false;
  }
}
