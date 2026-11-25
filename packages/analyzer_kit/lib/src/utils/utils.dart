import 'package:analyzer/dart/ast/ast.dart'
    show
        Annotation,
        ArgumentList,
        BooleanLiteral,
        ClassDeclaration,
        ClassMember,
        ConstructorDeclaration,
        DotShorthandConstructorInvocation,
        DotShorthandInvocation,
        FieldDeclaration,
        FormalParameter,
        FunctionBody,
        GenericFunctionType,
        IndexExpression,
        InstanceCreationExpression,
        IsExpression,
        MapLiteralEntry,
        MethodDeclaration,
        MethodInvocation,
        NamedArgument,
        PrefixedIdentifier,
        PrimaryConstructorDeclaration,
        SimpleIdentifier,
        SimpleStringLiteral,
        TypeAnnotation;
import 'package:analyzer/dart/ast/visitor.dart' show RecursiveAstVisitor;
import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/types.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

part 'code_gen_utils.dart';
part 'code_utils.dart';
part 'string_utils.dart';
part 'sync_utils.dart';

/// Extracts generatable fields from a [ClassDeclaration], including declaring
/// parameters on a primary constructor, body [FieldDeclaration]s, and
/// inherited fields from non-core supertypes.
///
/// Constructor parameter metadata (`isPositional`, `isConstructorParam`) is
/// matched against the primary constructor or the unnamed generative
/// constructor when present.
List<ClassField> extractGeneratableFields(ClassDeclaration declaration) {
  final ctorParamPositional = <String, bool>{};
  var hasExplicitCtor = false;

  if (declaration.namePart case final PrimaryConstructorDeclaration primary) {
    hasExplicitCtor = true;
    for (final param in primary.formalParameters.parameters) {
      final name = param.name?.lexeme;
      if (name != null) {
        ctorParamPositional[name] = param.isPositional;
      }
    }
  } else {
    for (final member in declaration.body.members) {
      if (member is ConstructorDeclaration &&
          member.factoryKeyword == null &&
          (member.name == null || member.name?.lexeme == 'new')) {
        hasExplicitCtor = true;
        for (final param in member.parameters.parameters) {
          final name = param.name?.lexeme;
          if (name != null) {
            ctorParamPositional[name] = param.isPositional;
          }
        }
        break;
      }
    }
  }

  final fields = <ClassField>[];
  final seenNames = <String>{};

  if (declaration.namePart case final PrimaryConstructorDeclaration primary) {
    for (final param in primary.formalParameters.parameters) {
      if (param.constFinalOrVarKeyword != null && param.name != null) {
        final field = ClassField.fromPrimaryConstructorParameter(param);
        if (field.isGeneratable && seenNames.add(field.name)) {
          fields.add(field);
        }
      }
    }
  }

  for (final member in declaration.body.members) {
    if (member is FieldDeclaration) {
      for (final rawField in ClassField.fromFieldDeclarationAll(member)) {
        if (rawField.isGeneratable && seenNames.add(rawField.name)) {
          final field = hasExplicitCtor
              ? rawField.copyWithConstructorInfo(
                  isPositional:
                      ctorParamPositional[rawField.name] ??
                      rawField.isPositional,
                  isConstructorParam: ctorParamPositional.containsKey(
                    rawField.name,
                  ),
                )
              : rawField;
          fields.add(field);
        }
      }
    }
  }

  final classEl = declaration.declaredFragment?.element;
  if (classEl != null) {
    for (final supertype in classEl.allSupertypes) {
      if (supertype.element.library.isDartCore) continue;
      for (final fieldEl in supertype.element.fields) {
        final name = fieldEl.name;
        if (name == null ||
            fieldEl.isStatic ||
            !fieldEl.isOriginDeclaration ||
            fieldEl.isLate ||
            !seenNames.add(name)) {
          continue;
        }
        fields.add(
          ClassField.fromFieldElement(
            fieldEl,
            isPositional: ctorParamPositional[name] ?? false,
            isConstructorParam:
                !hasExplicitCtor || ctorParamPositional.containsKey(name),
          ),
        );
      }
    }
  }

  return fields;
}

/// Returns the named primary constructor name for [declaration] (e.g. `'named'`
/// for `class Foo.named(...)`), or `null` for unnamed or `.new` constructors.
String? extractPrimaryConstructorName(ClassDeclaration declaration) {
  if (declaration.namePart case PrimaryConstructorDeclaration(
    :final constructorName?,
  )) {
    final name = constructorName.name.lexeme;
    return name == 'new' ? null : name;
  }
  return null;
}

/// Returns the generic type argument list for [declaration] (e.g. `'<T, U>'`
/// for `class Box<T, U extends num>`), or `''` if the class is not generic.
String extractTypeArguments(ClassDeclaration declaration) {
  final typeParams = declaration.namePart.typeParameters?.typeParameters;
  if (typeParams == null || typeParams.isEmpty) return '';
  return '<${typeParams.map((p) => p.name.lexeme).join(', ')}>';
}

/// Checks whether a specific code generation [feature] is enabled for [node],
/// either via a direct annotation or via a `CompositeAnnotation` bundle.
bool hasFeatureEnabled(ClassDeclaration node, FeatureAnnotation feature) {
  final config = extractAnnotationConfig(node);
  return switch (feature) {
    .copyWith => config.copyWith,
    .overrideToString => config.overrideToString,
    .overrideEquality => config.overrideEquality,
    .serialize => config.serialize,
    .deserialize => config.deserialize,
  };
}

/// Returns whether the single metadata [annotation] enables [feature]
/// (either directly or by expanding a `CompositeAnnotation`).
bool annotationEnablesFeature(
  Annotation annotation,
  FeatureAnnotation feature,
) {
  if (stringEqualsIgnoreCaseByAscii(
    _annotationSimpleName(annotation),
    feature.name,
  )) {
    return true;
  }

  final constant = annotation.elementAnnotation?.computeConstantValue();
  if (constant == null) return false;

  for (final item in _expandAnnotationConstant(constant)) {
    final typeName = item.type?.element?.name;
    if (typeName != null &&
        stringEqualsIgnoreCaseByAscii(typeName, feature.name)) {
      return true;
    }
  }
  return false;
}

/// Retrieves the configured method name for a given [feature] on [node].
/// Returns null if the feature is not enabled.
String? extractFeatureMethodName(
  ClassDeclaration node,
  FeatureAnnotation feature,
  String defaultName,
) {
  final config = extractAnnotationConfig(node);
  return switch (feature) {
    .serialize =>
      config.serialize ? (config.serializeMethodName ?? defaultName) : null,
    .deserialize =>
      config.deserialize ? (config.deserializeMethodName ?? defaultName) : null,
    _ => hasFeatureEnabled(node, feature) ? defaultName : null,
  };
}

/// Extracts `deepCollectionEquality` from `@OverrideEquality` or any
/// `CompositeAnnotation` containing `OverrideEquality` on [declaration].
bool? extractDeepCollectionEquality(ClassDeclaration declaration) =>
    extractAnnotationConfig(declaration).deepCollectionEquality;

/// Parsed annotation configuration for a [ClassDeclaration] in a single pass.
final class AnnotationConfig {
  const AnnotationConfig({
    this.hasCompositeAnnotation = false,
    this.copyWith = false,
    this.copyWithNullable = false,
    this.overrideToString = false,
    this.overrideEquality = false,
    this.serialize = false,
    this.deserialize = false,
    this.serializeMethodName,
    this.deserializeMethodName,
    this.deepCollectionEquality,
    this.annotationNodes = const {},
  });

  final bool hasCompositeAnnotation;
  final bool copyWith;
  final bool copyWithNullable;
  final bool overrideToString;
  final bool overrideEquality;
  final bool serialize;
  final bool deserialize;
  final String? serializeMethodName;
  final String? deserializeMethodName;
  final bool? deepCollectionEquality;

  /// First metadata [Annotation] node enabling each [FeatureAnnotation] on the
  /// class, populated during [extractAnnotationConfig] to avoid re-evaluating
  /// constant values when reporting diagnostics.
  final Map<FeatureAnnotation, Annotation> annotationNodes;

  bool get hasAnyFeature =>
      copyWith ||
      overrideToString ||
      overrideEquality ||
      serialize ||
      deserialize;
}

/// Parses all `analyzer_kit` annotations on [node] in a single metadata pass,
/// expanding any `CompositeAnnotation` bundles via their constant values.
AnnotationConfig extractAnnotationConfig(ClassDeclaration node) {
  var hasCompositeAnnotation = false;
  var copyWith = false;
  var copyWithNullable = false;
  var overrideToString = false;
  var overrideEquality = false;
  bool? deepCollectionEquality;
  var serialize = false;
  String? serializeMethodName;
  var deserialize = false;
  String? deserializeMethodName;
  final annotationNodes = <FeatureAnnotation, Annotation>{};

  for (final annotation in node.metadata) {
    final name = _annotationSimpleName(annotation);
    final arguments = annotation.arguments?.arguments;

    if (stringEqualsIgnoreCaseByAscii(name, FeatureAnnotation.copyWith.name)) {
      copyWith = true;
      annotationNodes.putIfAbsent(.copyWith, () => annotation);
      if (arguments != null) {
        for (final arg in arguments) {
          if (arg is NamedArgument && arg.name.lexeme == 'nullable') {
            final expr = arg.argumentExpression;
            if (expr is BooleanLiteral) {
              copyWithNullable = expr.value;
            }
          }
        }
      }
      continue;
    }
    if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.overrideToString.name,
    )) {
      overrideToString = true;
      annotationNodes.putIfAbsent(.overrideToString, () => annotation);
      continue;
    }
    if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.overrideEquality.name,
    )) {
      overrideEquality = true;
      annotationNodes.putIfAbsent(.overrideEquality, () => annotation);
      if (arguments != null) {
        for (final arg in arguments) {
          if (arg is NamedArgument &&
              arg.name.lexeme == 'deepCollectionEquality') {
            final expr = arg.argumentExpression;
            if (expr is BooleanLiteral) {
              deepCollectionEquality = expr.value;
            }
          }
        }
      }
      continue;
    }
    if (stringEqualsIgnoreCaseByAscii(name, FeatureAnnotation.serialize.name)) {
      serialize = true;
      annotationNodes.putIfAbsent(.serialize, () => annotation);
      if (arguments != null) {
        for (final arg in arguments) {
          if (arg is NamedArgument && arg.name.lexeme == 'name') {
            serializeMethodName = _extractMethodNameFromExpression(
              arg.argumentExpression,
            );
          }
        }
      }
      continue;
    }
    if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.deserialize.name,
    )) {
      deserialize = true;
      annotationNodes.putIfAbsent(.deserialize, () => annotation);
      if (arguments != null) {
        for (final arg in arguments) {
          if (arg is NamedArgument && arg.name.lexeme == 'name') {
            deserializeMethodName = _extractMethodNameFromExpression(
              arg.argumentExpression,
            );
          }
        }
      }
      continue;
    }

    // Check if this annotation resolves to a CompositeAnnotation (or any
    // custom constant holding one of the feature annotations).
    final constant = annotation.elementAnnotation?.computeConstantValue();
    if (constant == null) continue;

    if (_isCompositeAnnotation(constant)) {
      hasCompositeAnnotation = true;
    }

    for (final item in _expandAnnotationConstant(constant)) {
      final typeName = item.type?.element?.name;
      if (typeName == null) continue;

      if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.copyWith.name,
      )) {
        copyWith = true;
        annotationNodes.putIfAbsent(.copyWith, () => annotation);
        final nullableVal = item.getField('nullable')?.toBoolValue();
        if (nullableVal == true) {
          copyWithNullable = true;
        }
      } else if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.overrideToString.name,
      )) {
        overrideToString = true;
        annotationNodes.putIfAbsent(.overrideToString, () => annotation);
      } else if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.overrideEquality.name,
      )) {
        overrideEquality = true;
        annotationNodes.putIfAbsent(.overrideEquality, () => annotation);
        deepCollectionEquality ??= item
            .getField('deepCollectionEquality')
            ?.toBoolValue();
      } else if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.serialize.name,
      )) {
        serialize = true;
        annotationNodes.putIfAbsent(.serialize, () => annotation);
        serializeMethodName ??= _extractConstantMethodName(item);
      } else if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.deserialize.name,
      )) {
        deserialize = true;
        annotationNodes.putIfAbsent(.deserialize, () => annotation);
        deserializeMethodName ??= _extractConstantMethodName(item);
      }
    }
  }

  return AnnotationConfig(
    hasCompositeAnnotation: hasCompositeAnnotation,
    copyWith: copyWith,
    copyWithNullable: copyWithNullable,
    overrideToString: overrideToString,
    overrideEquality: overrideEquality,
    serialize: serialize,
    deserialize: deserialize,
    serializeMethodName: serialize
        ? (serializeMethodName ?? FeatureMethod.toMap.name)
        : null,
    deserializeMethodName: deserialize
        ? (deserializeMethodName ?? FeatureMethod.fromMap.name)
        : null,
    deepCollectionEquality: deepCollectionEquality,
    annotationNodes: annotationNodes,
  );
}

String _annotationSimpleName(Annotation annotation) =>
    switch (annotation.name) {
      PrefixedIdentifier(:final identifier) => identifier.name,
      final id => id.name,
    };

bool _isCompositeAnnotation(DartObject obj) =>
    obj.type?.element?.name == 'CompositeAnnotation';

Iterable<DartObject> _expandAnnotationConstant(
  DartObject root, {
  int depth = 0,
}) sync* {
  if (depth > 16) return;
  if (_isCompositeAnnotation(root)) {
    final items = root.getField('annotations')?.toListValue();
    if (items == null) return;
    for (final item in items) {
      yield* _expandAnnotationConstant(item, depth: depth + 1);
    }
  } else {
    yield root;
  }
}

String? _extractConstantMethodName(DartObject obj) {
  final nameObj = obj.getField('name');
  if (nameObj == null) return null;
  return (nameObj.getField('methodName') ??
          nameObj.getField('(super)')?.getField('methodName'))
      ?.toStringValue();
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
