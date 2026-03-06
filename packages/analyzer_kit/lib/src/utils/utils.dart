import "package:analyzer/dart/ast/ast.dart"
    show
        AnnotatedNode,
        BooleanLiteral,
        ClassDeclaration,
        FieldDeclaration,
        NamedExpression,
        Annotation;
import "package:analyzer/dart/constant/value.dart";
import "package:analyzer_kit/src/enums.dart";
import "package:analyzer_kit/src/types.dart";
import "package:code_builder/code_builder.dart";
import "package:dart_style/dart_style.dart";

part "code_gen_utils.dart";
part "code_utils.dart";
part "exceptions.dart";
part "string_utils.dart";

/// Extracts generatable fields from a [ClassDeclaration].
Iterable<ClassField> extractGeneratableFields(ClassDeclaration declaration) =>
    declaration.body.childEntities
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

/// Checks whether a [feature] is enabled in the given [annotation].
///
/// If [annotation] has no arguments, an [AnnotationFeatureNotFoundException] is thrown.
///
/// If [annotation] has multiple boolean expressions for the same feature, an [AnnotationException] is thrown.
bool isFeaturedEnabledInAnnotation(
  Annotation annotation,
  FeatureAnnotation feature,
) {
  final arguments = annotation.arguments;
  // TODO: This is a temporary solution, until we have a better way to handle this.
  final computedFieldName = feature.toString().split(".").last;

  if (arguments == null) {
    final featureEnabled = getComputedAnnotationFieldValue(
      annotation,
      computedFieldName,
    )?.toBoolValue();

    if (featureEnabled == null) {
      throw AnnotationFeatureNotFoundException(
        feature.name,
        annotation.name.name,
      );
    }

    return featureEnabled;
  }

  final expressions = arguments.arguments
      .whereType<NamedExpression>()
      .where(
        (e) => stringEqualsIgnoreCaseByAscii(e.name.label.name, feature.name),
      )
      .map((e) => e.expression)
      .whereType<BooleanLiteral>();

  if (expressions.isEmpty) {
    final featureEnabled = getComputedAnnotationFieldValue(
      annotation,
      computedFieldName,
    )?.toBoolValue();

    if (featureEnabled == null) {
      throw AnnotationFeatureNotFoundException(
        feature.name,
        annotation.name.name,
      );
    }

    return featureEnabled;
  }

  return switch (expressions.length) {
    // We have already covered the case where there are no arguments.
    1 => expressions.first.value,
    _ => throw AnnotationMultipleFeatureExpressionsException(
      feature.name,
      annotation.name.name,
    ),
  };
}

Annotation? getAnnotation(AnnotatedNode node, FeatureAnnotation feature) {
  for (final annotation in node.metadata) {
    if (stringEqualsIgnoreCaseByAscii(annotation.name.name, feature.name)) {
      return annotation;
    }
  }

  return null;
}

/// Retrieves the correctly configured method name for a given [feature] serialization/deserialization on [node].
/// Returns null if the feature is not configured or disabled.
String? extractFeatureMethodName(
  ClassDeclaration node,
  FeatureAnnotation feature,
  String defaultName,
) {
  // Look for direct annotation first
  for (final annotation in node.metadata) {
    if (stringEqualsIgnoreCaseByAscii(annotation.name.name, feature.name)) {
      final arguments = annotation.arguments?.arguments;
      if (arguments == null || arguments.isEmpty) return defaultName;

      // Extract custom configuration e.g., @Serialize(name: .custom('xyz'))
      for (final arg in arguments) {
        if (arg is NamedExpression && arg.name.label.name == "name") {
          final expression = arg.expression;
          // Assuming a simple method invocation or custom string. Extract the method literal.
          final source = expression.toSource();
          // .toMap() -> toMap
          // .custom('myMethod') -> myMethod
          if (source.startsWith(".custom(")) {
            return source.substring(9, source.length - 2);
          } else if (source.startsWith(".")) {
            return source.substring(1, source.length - 2); // .toMap() -> toMap
          }
        }
      }
      return defaultName;
    }
  }

  return null;
}
