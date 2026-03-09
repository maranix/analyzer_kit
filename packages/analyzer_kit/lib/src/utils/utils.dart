import "package:analyzer/dart/ast/ast.dart"
    show
        AnnotatedNode,
        BooleanLiteral,
        ClassDeclaration,
        FieldDeclaration,
        Expression,
        NamedExpression,
        Annotation;
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer_kit/src/enums.dart";
import "package:analyzer_kit/src/types.dart";
import "package:analyzer_kit/src/utils/exceptions.dart";
import "package:analyzer_kit/src/utils/string_utils.dart";

export "package:analyzer_kit/src/utils/exceptions.dart";

/// Extracts generatable fields from a [ClassDeclaration].
Iterable<ClassField> extractGeneratableFields(
  ClassDeclaration declaration,
) => declaration.body.childEntities
    .whereType<FieldDeclaration>()
    .map(ClassField.fromFieldDeclaration)
    .where((f) => f.isGeneratable);

/// Checks whether a [node] has an annotation with the given [name] (case-insensitive).
bool nodeHasAnnotation(AnnotatedNode node, String name) =>
    node.metadata.any((a) => stringEqualsIgnoreCaseByAscii(a.name.name, name));

/// Retrieves the computed value of a field in an annotation.
///
/// Returns null if the annotation has no computed values or the field is not found.
DartObject? getComputedAnnotationFieldValue(
  Annotation annotation,
  String fieldName,
) {
  final computedAnnotationValues = annotation.elementAnnotation
      ?.computeConstantValue();

  return computedAnnotationValues?.getField(fieldName);
}

/// Retrieves the arguments of a [annotation].
///
/// Returns an empty list if the annotation has no arguments.
///
/// Throws [ArgumentError] if the type [T] is not a subtype of [Expression].
Iterable<T> getAnnotationProps<T extends Expression>(
  Annotation annotation,
) {
  final arguments = annotation.arguments?.arguments;
  if (arguments == null) return [];

  return arguments.whereType<T>();
}

/// Checks whether a [feature] is enabled in the given [annotation].
///
/// Resolution order:
/// 1. Explicit boolean argument in the annotation source (e.g. `@DataClass(copyWith: false)`)
/// 2. Computed constant value from the resolved annotation element
///
/// Throws [AnnotationFeatureNotFoundException] if the feature cannot be resolved.
///
/// Throws [AnnotationMultipleFeatureExpressionsException] if more than one
/// boolean expression matches the same feature.
bool isFeaturedEnabledInAnnotation(
  Annotation annotation,
  FeatureAnnotation feature,
) {
  bool resolveFromComputed() {
    final value = getComputedAnnotationFieldValue(
      annotation,
      feature.name[0].toLowerCase() + feature.name.substring(1),
    )?.toBoolValue();

    if (value == null) {
      throw AnnotationFeatureNotFoundException(
        feature.name,
        annotation.name.name,
      );
    }

    return value;
  }

  // If annotation has no argument list, fall back to computed values.
  final arguments = annotation.arguments;
  if (arguments == null) return resolveFromComputed();

  // Look for an explicit boolean argument matching the feature name.
  final expressions = arguments.arguments
      .whereType<NamedExpression>()
      .where(
        (e) => stringEqualsIgnoreCaseByAscii(e.name.label.name, feature.name),
      )
      .map((e) => e.expression)
      .whereType<BooleanLiteral>();

  return switch (expressions.length) {
    0 => resolveFromComputed(),
    1 => expressions.first.value,
    _ => throw AnnotationMultipleFeatureExpressionsException(
      feature.name,
      annotation.name.name,
    ),
  };
}

/// Retrieves the [Annotation] with the given [name] from the [node].
///
/// Returns null if the annotation is not found.
Annotation? getAnnotation(AnnotatedNode node, FeatureAnnotation feature) {
  for (final annotation in node.metadata) {
    if (stringEqualsIgnoreCaseByAscii(annotation.name.name, feature.name)) {
      return annotation;
    }
  }

  return null;
}
