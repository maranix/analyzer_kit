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
        FunctionBody,
        InstanceCreationExpression,
        MethodDeclaration,
        MethodInvocation,
        NamedArgument,
        PrimaryConstructorDeclaration,
        SimpleIdentifier,
        SimpleStringLiteral;
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
/// parameters on a primary constructor and body [FieldDeclaration]s.
List<ClassField> extractGeneratableFields(ClassDeclaration declaration) {
  final fields = <ClassField>[];

  if (declaration.namePart case final PrimaryConstructorDeclaration primary) {
    for (final param in primary.formalParameters.parameters) {
      if (param.constFinalOrVarKeyword != null && param.name != null) {
        final field = ClassField.fromPrimaryConstructorParameter(param);
        if (field.isGeneratable) {
          fields.add(field);
        }
      }
    }
  }

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
  if (stringEqualsIgnoreCaseByAscii(annotation.name.name, feature.name)) {
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
    this.overrideToString = false,
    this.overrideEquality = false,
    this.serialize = false,
    this.deserialize = false,
    this.serializeMethodName,
    this.deserializeMethodName,
    this.deepCollectionEquality,
  });

  final bool hasCompositeAnnotation;
  final bool copyWith;
  final bool overrideToString;
  final bool overrideEquality;
  final bool serialize;
  final bool deserialize;
  final String? serializeMethodName;
  final String? deserializeMethodName;
  final bool? deepCollectionEquality;
}

/// Parses all `analyzer_kit` annotations on [node] in a single metadata pass,
/// expanding any `CompositeAnnotation` bundles via their constant values.
AnnotationConfig extractAnnotationConfig(ClassDeclaration node) {
  var hasCompositeAnnotation = false;
  var copyWith = false;
  var overrideToString = false;
  var overrideEquality = false;
  bool? deepCollectionEquality;
  var serialize = false;
  String? serializeMethodName;
  var deserialize = false;
  String? deserializeMethodName;

  for (final annotation in node.metadata) {
    final name = annotation.name.name;
    final arguments = annotation.arguments?.arguments;

    if (stringEqualsIgnoreCaseByAscii(name, FeatureAnnotation.copyWith.name)) {
      copyWith = true;
      continue;
    }
    if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.overrideToString.name,
    )) {
      overrideToString = true;
      continue;
    }
    if (stringEqualsIgnoreCaseByAscii(
      name,
      FeatureAnnotation.overrideEquality.name,
    )) {
      overrideEquality = true;
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
      } else if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.overrideToString.name,
      )) {
        overrideToString = true;
      } else if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.overrideEquality.name,
      )) {
        overrideEquality = true;
        deepCollectionEquality ??= item
            .getField('deepCollectionEquality')
            ?.toBoolValue();
      } else if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.serialize.name,
      )) {
        serialize = true;
        serializeMethodName ??= _extractConstantMethodName(item);
      } else if (stringEqualsIgnoreCaseByAscii(
        typeName,
        FeatureAnnotation.deserialize.name,
      )) {
        deserialize = true;
        deserializeMethodName ??= _extractConstantMethodName(item);
      }
    }
  }

  return AnnotationConfig(
    hasCompositeAnnotation: hasCompositeAnnotation,
    copyWith: copyWith,
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
  );
}

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
