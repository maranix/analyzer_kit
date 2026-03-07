part of "annotation_rule.dart";

final class SerializeRule extends AnnotationRule {
  SerializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.serialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.serialize;

  @override
  AnnotationVisitor getVisitor() => _SerializeVisitor(this);
}

final class _SerializeVisitor extends AnnotationVisitor {
  _SerializeVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    final nodeAnnotation = getAnnotation(node, annotation)!;

    final expectedName = getComputedAnnotationFieldValue(
      nodeAnnotation,
      "name",
    )?.toStringValue();

    final name = switch (expectedName) {
      null => "toMap",
      final String n when n.contains("(") => n.substring(
        n.lastIndexOf("("),
        n.lastIndexOf(")"),
      ),
      _ => expectedName,
    };

    return [name];
  }
}
