part of "annotation_rule.dart";

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
    final expectedMethods = <FeatureMethod>[];

    final dataClassAnnotation = node.metadata.firstWhere(
      (a) => stringEqualsIgnoreCaseByAscii(
        a.name.name,
        FeatureAnnotation.dataClass.name,
      ),
    );

    for (final feature in CompositeFeatureAnnotation.dataClass.features) {
      if (isFeaturedEnabledInAnnotation(dataClassAnnotation, feature)) {
        expectedMethods.addAll(feature.expectedMethods);
      }
    }

    return expectedMethods.isEmpty ? null : expectedMethods.map((e) => e.name);
  }

  @override
  bool reduceExpectedMethods(
    Iterable<SyntacticEntity> members,
    Iterable<String> expectedMethods,
  ) {
    final Set<String> methods = Set.from(expectedMethods);

    for (final member in members) {
      if (member is ConstructorDeclaration) {
        if (member.factoryKeyword == null) continue;

        methods.remove(member.name?.lexeme);
      } else if (member is MethodDeclaration) {
        methods.remove(member.name.lexeme);
      }
    }

    return methods.isEmpty;
  }
}
