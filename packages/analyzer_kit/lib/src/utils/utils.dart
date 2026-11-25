import 'package:analyzer/dart/ast/ast.dart'
    show
        Annotation,
        ArgumentList,
        BooleanLiteral,
        ClassDeclaration,
        DotShorthandConstructorInvocation,
        DotShorthandInvocation,
        FieldDeclaration,
        InstanceCreationExpression,
        MethodInvocation,
        NamedArgument,
        NodeList,
        SimpleStringLiteral;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/types.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

part 'code_gen_utils.dart';
part 'code_utils.dart';
part 'string_utils.dart';

/// Extracts generatable fields from a [ClassDeclaration].
List<ClassField> extractGeneratableFields(ClassDeclaration declaration) {
  final fields = <ClassField>[];
  for (final member in declaration.body.members) {
    if (member is FieldDeclaration) {
      for (final field in ClassField.fromFieldDeclarationAll(member)) {
        if (field.isGeneratable) {
          fields.add(field);
        }
      }
    }
  }
  return fields;
}

/// Checks whether a specific code generation [feature] is enabled for a [node].
///
/// This checks if the class is annotated with the direct feature annotation
/// (e.g., `@CopyWith`) or the composite `@DataClass` annotation where the
/// feature is not explicitly disabled.
bool hasFeatureEnabled(ClassDeclaration node, FeatureAnnotation feature) {
  // Check for direct annotation first regardless ignoring letter casing
  // (e.g., @CopyWith and @copyWith are treated as same)
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
        if (arg is NamedArgument &&
            stringEqualsIgnoreCaseByAscii(arg.name.lexeme, feature.name)) {
          final expression = arg.argumentExpression;
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

/// Retrieves the correctly configured method name for a given [feature] serialization/deserialization on [node].
/// Returns null if the feature is not configured or disabled.
String? extractFeatureMethodName(
  ClassDeclaration node,
  FeatureAnnotation feature,
  String defaultName,
) {
  if (feature == FeatureAnnotation.dataClass) {
    if (_hasAnnotation(node.metadata, feature.name)) return defaultName;
    return null;
  }

  // Look for direct annotation first
  for (final annotation in node.metadata) {
    if (stringEqualsIgnoreCaseByAscii(annotation.name.name, feature.name)) {
      final arguments = annotation.arguments?.arguments;
      if (arguments == null || arguments.isEmpty) return defaultName;

      // Extract custom configuration e.g., @Serialize(name: .custom('xyz'))
      for (final arg in arguments) {
        if (arg is NamedArgument && arg.name.lexeme == 'name') {
          final methodName = _extractMethodNameFromExpression(
            arg.argumentExpression,
          );
          if (methodName != null) return methodName;
        }
      }
      return defaultName;
    }
  }

  // Fallback to @DataClass checking
  if (_hasAnnotation(node.metadata, FeatureAnnotation.dataClass.name)) {
    // We already know it has @DataClass. Now we need to check if the specific feature is enabled.
    if (hasFeatureEnabled(node, feature)) {
      return defaultName;
    }
  }
  return null;
}

/// Extracts `deepCollectionEquality` from `@OverrideEquality` or `@DataClass`
/// annotations on [declaration] in a single pass.
bool? extractDeepCollectionEquality(ClassDeclaration declaration) {
  bool? result;
  for (final annotation in declaration.metadata) {
    final name = annotation.name.name;
    if (stringEqualsIgnoreCaseByAscii(
          name,
          FeatureAnnotation.overrideEquality.name,
        ) ||
        stringEqualsIgnoreCaseByAscii(name, FeatureAnnotation.dataClass.name)) {
      final arguments = annotation.arguments?.arguments;
      if (arguments == null) continue;
      for (final arg in arguments) {
        if (arg is NamedArgument &&
            arg.name.lexeme == 'deepCollectionEquality') {
          final expression = arg.argumentExpression;
          if (expression is BooleanLiteral) {
            result = expression.value;
          }
        }
      }
    }
  }
  return result;
}

/// Parsed annotation configuration for a [ClassDeclaration] in a single pass.
final class AnnotationConfig {
  const AnnotationConfig({
    this.hasDataClass = false,
    this.copyWith = false,
    this.overrideToString = false,
    this.overrideEquality = false,
    this.serialize = false,
    this.deserialize = false,
    this.serializeMethodName,
    this.deserializeMethodName,
    this.deepCollectionEquality,
  });

  final bool hasDataClass;
  final bool copyWith;
  final bool overrideToString;
  final bool overrideEquality;
  final bool serialize;
  final bool deserialize;
  final String? serializeMethodName;
  final String? deserializeMethodName;
  final bool? deepCollectionEquality;
}

/// Parses all analyzer_kit annotations on [node] in a single metadata pass.
AnnotationConfig extractAnnotationConfig(ClassDeclaration node) {
  var hasDataClass = false;
  var dcCopyWith = true;
  var dcToString = true;
  var dcEquality = true;
  var dcSerialize = true;
  var dcDeserialize = true;
  bool? dcDeepEquality;

  var directCopyWith = false;
  var directToString = false;
  var directEquality = false;
  bool? directDeepEquality;
  var directSerialize = false;
  String? directSerializeName;
  var directDeserialize = false;
  String? directDeserializeName;

  for (final annotation in node.metadata) {
    final name = annotation.name.name;
    final arguments = annotation.arguments?.arguments;

    if (stringEqualsIgnoreCaseByAscii(name, FeatureAnnotation.dataClass.name)) {
      hasDataClass = true;
      if (arguments != null) {
        for (final arg in arguments) {
          if (arg is! NamedArgument) continue;
          final label = arg.name.lexeme;
          final expr = arg.argumentExpression;
          if (expr is BooleanLiteral) {
            if (stringEqualsIgnoreCaseByAscii(
              label,
              FeatureAnnotation.copyWith.name,
            )) {
              dcCopyWith = expr.value;
            } else if (stringEqualsIgnoreCaseByAscii(
              label,
              FeatureAnnotation.overrideToString.name,
            )) {
              dcToString = expr.value;
            } else if (stringEqualsIgnoreCaseByAscii(
              label,
              FeatureAnnotation.overrideEquality.name,
            )) {
              dcEquality = expr.value;
            } else if (stringEqualsIgnoreCaseByAscii(
              label,
              FeatureAnnotation.serialize.name,
            )) {
              dcSerialize = expr.value;
            } else if (stringEqualsIgnoreCaseByAscii(
              label,
              FeatureAnnotation.deserialize.name,
            )) {
              dcDeserialize = expr.value;
            } else if (label == 'deepCollectionEquality') {
              dcDeepEquality = expr.value;
            }
          }
        }
      }
    } else if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.copyWith.name,
    )) {
      directCopyWith = true;
    } else if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.overrideToString.name,
    )) {
      directToString = true;
    } else if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.overrideEquality.name,
    )) {
      directEquality = true;
      if (arguments != null) {
        for (final arg in arguments) {
          if (arg is NamedArgument &&
              arg.name.lexeme == 'deepCollectionEquality') {
            final expr = arg.argumentExpression;
            if (expr is BooleanLiteral) {
              directDeepEquality = expr.value;
            }
          }
        }
      }
    } else if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.serialize.name,
    )) {
      directSerialize = true;
      if (arguments != null) {
        for (final arg in arguments) {
          if (arg is NamedArgument && arg.name.lexeme == 'name') {
            directSerializeName = _extractMethodNameFromExpression(
              arg.argumentExpression,
            );
          }
        }
      }
    } else if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.deserialize.name,
    )) {
      directDeserialize = true;
      if (arguments != null) {
        for (final arg in arguments) {
          if (arg is NamedArgument && arg.name.lexeme == 'name') {
            directDeserializeName = _extractMethodNameFromExpression(
              arg.argumentExpression,
            );
          }
        }
      }
    }
  }

  final serialize = directSerialize || (hasDataClass && dcSerialize);
  final deserialize = directDeserialize || (hasDataClass && dcDeserialize);

  return AnnotationConfig(
    hasDataClass: hasDataClass,
    copyWith: directCopyWith || (hasDataClass && dcCopyWith),
    overrideToString: directToString || (hasDataClass && dcToString),
    overrideEquality: directEquality || (hasDataClass && dcEquality),
    serialize: serialize,
    deserialize: deserialize,
    serializeMethodName: serialize
        ? (directSerializeName ?? FeatureMethod.toMap.name)
        : null,
    deserializeMethodName: deserialize
        ? (directDeserializeName ?? FeatureMethod.fromMap.name)
        : null,
    deepCollectionEquality: directDeepEquality ?? dcDeepEquality,
  );
}

String? _extractMethodNameFromExpression(Object expression) {
  final (String? ctorName, ArgumentList? args) = switch (expression) {
    DotShorthandInvocation(:final memberName, :final argumentList) => (
      memberName.name,
      argumentList,
    ),
    DotShorthandConstructorInvocation(
      :final constructorName,
      :final argumentList,
    ) =>
      (constructorName.name, argumentList),
    MethodInvocation(:final methodName, :final argumentList) => (
      methodName.name,
      argumentList,
    ),
    InstanceCreationExpression(:final constructorName, :final argumentList) => (
      constructorName.name?.name,
      argumentList,
    ),
    _ => (null, null),
  };

  if (ctorName == null) return null;
  if (ctorName == 'custom') {
    final firstArg = args?.arguments.firstOrNull;
    if (firstArg is SimpleStringLiteral) {
      return firstArg.value;
    }
    return null;
  }
  return ctorName;
}
