import 'package:analyzer/dart/ast/ast.dart'
    show
        ClassDeclaration,
        FieldDeclaration,
        NamedExpression,
        BooleanLiteral,
        Annotation,
        NodeList;
import 'package:code_builder/code_builder.dart';
import 'package:dart_analyzer_kit/src/constants.dart';
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_style/dart_style.dart';

part 'code_gen_utils.dart';
part 'code_utils.dart';
part 'string_utils.dart';

/// Extracts generatable fields from a [ClassDeclaration].
Iterable<ClassField> extractGeneratableFields(ClassDeclaration declaration) {
  return declaration.members
      .map(
        (m) =>
            m is FieldDeclaration ? ClassField.fromFieldDeclaration(m) : null,
      )
      .nonNulls
      .where((f) => f.isGeneratable);
}

/// Checks whether a specific code generation [feature] is enabled for a [node].
///
/// This checks if the class is annotated with the direct feature annotation
/// (e.g., `@CopyWith`) or the composite `@DataClass` annotation where the
/// feature is not explicitly disabled.
bool hasFeatureEnabled(ClassDeclaration node, FeatureAnnotation feature) {
  // If we're checking for the DataClass feature itself, it's just a presence check
  if (feature == FeatureAnnotation.dataClass) {
    return _hasAnnotation(node.metadata, feature.name);
  }

  // Check for direct annotation first (e.g., @CopyWith)
  if (_hasAnnotation(node.metadata, feature.name)) {
    return true;
  }

  // Check for @DataClass and its arguments
  for (final annotation in node.metadata) {
    if (stringEqualsIgnoreCaseByAscii(
      annotation.name.name,
      FeatureAnnotation.dataClass.name,
    )) {
      // If arguments are missing, all features are enabled by default
      final arguments = annotation.arguments?.arguments;
      if (arguments == null) return true;

      // Look for the specific argument corresponding to the feature
      // The argument name uses camelCase matching the enum name (e.g., 'copyWith')
      for (final arg in arguments) {
        if (arg is NamedExpression &&
            stringEqualsIgnoreCaseByAscii(arg.name.label.name, feature.name)) {
          final expression = arg.expression;
          if (expression is BooleanLiteral) {
            return expression.value;
          }
          break;
        }
      }

      // If the argument is missing, it defaults to true
      return true;
    }
  }

  return false;
}

bool _hasAnnotation(NodeList<Annotation> metadata, String name) {
  return metadata.any((a) => stringEqualsIgnoreCaseByAscii(a.name.name, name));
}
