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
    final config = extractAnnotationConfig(node);
    final expectedMethods = <String>[];

    if (config.copyWith) {
      expectedMethods.add(FeatureMethod.copyWith.name);
    }

    if (config.overrideToString) {
      expectedMethods.add(FeatureMethod.overrideToString.name);
    }

    if (config.overrideEquality) {
      expectedMethods.add(FeatureMethod.overrideEquals.name);
      expectedMethods.add(FeatureMethod.overrideHashCode.name);
    }

    if (config.serialize && config.serializeMethodName != null) {
      expectedMethods.add(config.serializeMethodName!);
    }

    if (config.deserialize && config.deserializeMethodName != null) {
      expectedMethods.add(config.deserializeMethodName!);
    }

    return expectedMethods.isEmpty ? null : expectedMethods;
  }

  @override
  bool reduceExpectedMethods(
    NodeList<ClassMember> members,
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
