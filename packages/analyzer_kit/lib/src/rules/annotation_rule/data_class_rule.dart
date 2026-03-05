part of 'annotation_rule.dart';

final class DataClassRule extends AnnotationRule {
  DataClassRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.dataClass);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.dataClass;

  @override
  AnnotationVisitor getVisitor() => _DataClassVisitor(this);
}

final class _DataClassVisitor extends AnnotationVisitor {
  _DataClassVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    final expectedMethods = <String>[];

    if (hasFeatureEnabled(node, FeatureAnnotation.copyWith)) {
      expectedMethods.add(FeatureMethod.copyWith.name);
    }

    if (hasFeatureEnabled(node, FeatureAnnotation.overrideToString)) {
      expectedMethods.add(FeatureMethod.overrideToString.name);
    }

    if (hasFeatureEnabled(node, FeatureAnnotation.overrideEquality)) {
      expectedMethods.add(FeatureMethod.overrideEquals.name);
      expectedMethods.add(FeatureMethod.overrideHashCode.name);
    }

    if (hasFeatureEnabled(node, FeatureAnnotation.serialize)) {
      final methodName = extractFeatureMethodName(
        node,
        FeatureAnnotation.serialize,
        FeatureMethod.toMap.name,
      );
      if (methodName != null) {
        expectedMethods.add(methodName);
      }
    }

    if (hasFeatureEnabled(node, FeatureAnnotation.deserialize)) {
      final methodName = extractFeatureMethodName(
        node,
        FeatureAnnotation.deserialize,
        FeatureMethod.fromMap.name,
      );
      if (methodName != null) {
        expectedMethods.add(methodName);
      }
    }

    return expectedMethods.isEmpty ? null : expectedMethods;
  }

  @override
  bool reduceExpectedMethods(
    Iterable<SyntacticEntity> members,
    Iterable<String> expectedMethods,
  ) {
    final Set<String> methods = Set.from(expectedMethods);

    for (final member in members) {
      if (member is ConstructorDeclaration && member.factoryKeyword != null) {
        methods.remove(member.name?.lexeme);
      } else if (member is MethodDeclaration) {
        methods.remove(member.name.lexeme);
      }
    }

    return methods.isEmpty;
  }
}
