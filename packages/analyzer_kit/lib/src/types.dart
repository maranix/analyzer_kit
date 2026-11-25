import 'package:analyzer/dart/ast/ast.dart'
    show
        Annotation,
        DotShorthandPropertyAccess,
        FieldDeclaration,
        FormalParameter,
        NamedArgument,
        PrefixedIdentifier,
        SetOrMapLiteral,
        SimpleIdentifier,
        SimpleStringLiteral,
        VariableDeclaration;
import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, ElementAnnotation, EnumElement, FieldElement;
import 'package:analyzer/dart/element/nullability_suffix.dart'
    show NullabilitySuffix;
import 'package:analyzer/dart/element/type.dart' show DartType, InterfaceType;
import 'package:analyzer_kit/src/enums.dart' show FeatureAnnotation;

/// Semantic type classification for a [ClassField], used by serialization and
/// collection code generation.
enum FieldTypeKind {
  other,
  dateTime,
  uri,
  duration,
  bigInt,
  doubleType,
  enumType,
  list,
  iterable,
  set,
  map,
}

/// Represents a class field extracted from AST for code generation.
final class ClassField {
  const ClassField({
    required this.name,
    this.type = 'dynamic',
    this.keyword,
    this.equals,
    this.initializer,
    this.isConst = false,
    this.isLate = false,
    this.isFinal = false,
    this.isStatic = false,
    this.isSynthetic = false,
    this.isPublic = false,
    this.isPrivate = false,
    this.isPositional = false,
    this.isConstructorParam = true,
    this.typeKind,
    this.typeArguments = const [],
    this.serializeMethodName,
    this.deserializeMethodName,
    this.ignoredFor = const {},
    this.redactedFor = const {},
    this.redactPlaceholder = '[REDACTED]',
  });

  final String name;
  final String type;
  final String? keyword;
  final String? equals;
  final String? initializer;
  final bool isConst;
  final bool isLate;
  final bool isFinal;
  final bool isStatic;
  final bool isSynthetic;
  final bool isPublic;
  final bool isPrivate;
  final bool isPositional;

  /// Whether this field is accepted by the target constructor (and should be
  /// included in `copyWith` and `fromMap` constructor calls).
  final bool isConstructorParam;

  /// Resolved semantic kind of [type], or `null` when constructed without AST
  /// type resolution (in which case getters fall back to parsing [type]).
  final FieldTypeKind? typeKind;

  /// Resolved generic type arguments for collection types (e.g. `[T]` for
  /// `List<T>`, `[K, V]` for `Map<K, V>`).
  final List<ClassField> typeArguments;

  /// Serialization method name (e.g. `'toMap'` or `'toJson'`) when this field's
  /// type is a serializable class, or `null` otherwise.
  final String? serializeMethodName;

  /// Deserialization factory/method name (e.g. `'fromMap'` or `'fromJson'`)
  /// when this field's type is a deserializable class, or `null` otherwise.
  final String? deserializeMethodName;

  /// Class-level annotations for which this field is ignored.
  final Set<FeatureAnnotation> ignoredFor;

  /// Class-level annotations for which this field's value is redacted.
  final Set<FeatureAnnotation> redactedFor;

  /// Placeholder string rendered in place of the field's value when redacted.
  final String redactPlaceholder;

  /// Whether this field should be included in generated methods.
  ///
  /// Excludes static, synthetic, and late fields.
  bool get isGeneratable => !isStatic && !isSynthetic && !isLate;

  /// Whether this field's type is nullable (ends with `?`).
  bool get isNullableType => type.endsWith('?');

  /// The non-nullable representation of [type] (strips trailing `?` if any).
  String get nonNullableType =>
      isNullableType ? type.substring(0, type.length - 1) : type;

  /// Whether this field's type is `DateTime` or `DateTime?`.
  bool get isDateTimeType => typeKind == .dateTime || _isType('DateTime');

  /// Whether this field's type is `Uri` or `Uri?`.
  bool get isUriType => typeKind == .uri || _isType('Uri');

  /// Whether this field's type is `Duration` or `Duration?`.
  bool get isDurationType => typeKind == .duration || _isType('Duration');

  /// Whether this field's type is `BigInt` or `BigInt?`.
  bool get isBigIntType => typeKind == .bigInt || _isType('BigInt');

  /// Whether this field's type is `double` or `double?`.
  bool get isDoubleType => typeKind == .doubleType || _isType('double');

  /// Whether this field's type is an `enum` (requires resolved [typeKind]).
  bool get isEnumType => typeKind == .enumType;

  /// Whether this field's type is a `List`.
  bool get isListType => typeKind == .list || _isType('List');

  /// Whether this field's type is an `Iterable`.
  bool get isIterableType => typeKind == .iterable || _isType('Iterable');

  /// Whether this field's type is a `List` or `Iterable` (ordered collection).
  bool get isListOrIterableType => isListType || isIterableType;

  /// Whether this field's type is a `Set` (unordered collection).
  bool get isSetType => typeKind == .set || _isType('Set');

  /// Whether this field's type is a `Map`.
  bool get isMapType => typeKind == .map || _isType('Map');

  /// Whether this field's type is any collection type.
  bool get isCollectionType => isListOrIterableType || isSetType || isMapType;

  /// Returns the effective [typeArguments], falling back to parsing [type]
  /// when [typeArguments] is empty (e.g. in unit tests).
  List<ClassField> get resolvedTypeArguments {
    if (typeArguments.isNotEmpty) return typeArguments;
    final lt = type.indexOf('<');
    final gt = type.lastIndexOf('>');
    if (lt == -1 || gt <= lt) return const [];
    final inner = type.substring(lt + 1, gt);
    return [
      for (final part in _splitTopLevelTypeArgs(inner))
        ClassField(name: 'e', type: part.trim()),
    ];
  }

  /// Checks if [type] matches the given [typeName], accounting for generics
  /// and nullability (e.g. `List`, `List<int>`, `List<int>?`).
  bool _isType(String typeName) =>
      type == typeName ||
      type.startsWith('$typeName<') ||
      type.startsWith('$typeName?');

  static ClassField fromFieldDeclaration(FieldDeclaration fd) =>
      _fromVariable(fd, fd.fields.variables.single);

  /// Extracts all [ClassField] entries from a [FieldDeclaration], supporting
  /// multi-variable declarations (e.g. `final int a, b;`).
  static Iterable<ClassField> fromFieldDeclarationAll(FieldDeclaration fd) {
    final type = fd.fields.type?.toSource() ?? 'dynamic';
    final dartType = fd.fields.type?.type;
    final keyword = fd.fields.keyword?.lexeme;
    final isStatic = fd.isStatic;

    return fd.fields.variables.map(
      (v) => _fromVariable(
        fd,
        v,
        type: type,
        dartType: dartType,
        keyword: keyword,
        isStatic: isStatic,
      ),
    );
  }

  /// Extracts a [ClassField] from an inherited [FieldElement].
  static ClassField fromFieldElement(
    FieldElement element, {
    bool isPositional = false,
    bool isConstructorParam = true,
  }) {
    final name = element.name ?? '';
    final isPrivate = name.startsWith('_');
    final dartType = element.type;
    final resolved = _resolveDartType(dartType);
    final ignoredFor = _extractIgnoredForFromElements(
      element.metadata.annotations,
    );
    final redacted = _extractRedactedFromElements(element.metadata.annotations);
    final suffix = dartType.nullabilitySuffix == NullabilitySuffix.question
        ? '?'
        : '';
    final display = dartType.getDisplayString();
    final typeStr = suffix.isNotEmpty && !display.endsWith('?')
        ? '$display?'
        : display;

    return ClassField(
      name: name,
      type: typeStr,
      isConst: element.isConst,
      isLate: element.isLate,
      isFinal: element.isFinal,
      isStatic: element.isStatic,
      isSynthetic: !element.isOriginDeclaration,
      isPublic: !isPrivate,
      isPrivate: isPrivate,
      isPositional: isPositional,
      isConstructorParam: isConstructorParam,
      typeKind: resolved.kind,
      typeArguments: resolved.args,
      serializeMethodName: resolved.serializeMethodName,
      deserializeMethodName: resolved.deserializeMethodName,
      ignoredFor: ignoredFor,
      redactedFor: redacted.annotations,
      redactPlaceholder: redacted.placeholder,
    );
  }

  /// Returns a copy of this [ClassField] with updated constructor metadata.
  ClassField copyWithConstructorInfo({
    bool? isPositional,
    bool? isConstructorParam,
  }) => ClassField(
    name: name,
    type: type,
    keyword: keyword,
    equals: equals,
    initializer: initializer,
    isConst: isConst,
    isLate: isLate,
    isFinal: isFinal,
    isStatic: isStatic,
    isSynthetic: isSynthetic,
    isPublic: isPublic,
    isPrivate: isPrivate,
    isPositional: isPositional ?? this.isPositional,
    isConstructorParam: isConstructorParam ?? this.isConstructorParam,
    typeKind: typeKind,
    typeArguments: typeArguments,
    serializeMethodName: serializeMethodName,
    deserializeMethodName: deserializeMethodName,
    ignoredFor: ignoredFor,
    redactedFor: redactedFor,
    redactPlaceholder: redactPlaceholder,
  );

  /// Extracts a [ClassField] from a declaring [FormalParameter] in a
  /// `PrimaryConstructorDeclaration`.
  static ClassField fromPrimaryConstructorParameter(FormalParameter param) {
    final name = param.name!.lexeme;
    final isPrivate = name.startsWith('_');
    final dartType = param.declaredFragment?.element.type;
    final resolved = _resolveDartType(dartType);
    final ignoredFor = _extractIgnoredFor(param.metadata);
    final redacted = _extractRedacted(param.metadata);

    return ClassField(
      keyword: param.constFinalOrVarKeyword?.lexeme,
      type: param.type?.toSource() ?? 'dynamic',
      name: name,
      isConst: param.isConst,
      isFinal: param.isFinal,
      isPublic: !isPrivate,
      isPrivate: isPrivate,
      isPositional: param.isPositional,
      typeKind: resolved.kind,
      typeArguments: resolved.args,
      serializeMethodName: resolved.serializeMethodName,
      deserializeMethodName: resolved.deserializeMethodName,
      ignoredFor: ignoredFor,
      redactedFor: redacted.annotations,
      redactPlaceholder: redacted.placeholder,
    );
  }

  static ClassField _fromVariable(
    FieldDeclaration fd,
    VariableDeclaration variable, {
    String? type,
    DartType? dartType,
    String? keyword,
    bool? isStatic,
  }) {
    final name = variable.name.lexeme;
    final isPrivate = name.startsWith('_');
    final resolvedDartType = dartType ?? fd.fields.type?.type;
    final resolved = _resolveDartType(resolvedDartType);
    final ignoredFor = _extractIgnoredFor(fd.metadata);
    final redacted = _extractRedacted(fd.metadata);

    return ClassField(
      keyword: keyword ?? fd.fields.keyword?.lexeme,
      type: type ?? fd.fields.type?.toSource() ?? 'dynamic',
      name: name,
      equals: variable.equals?.lexeme,
      initializer: variable.initializer?.toString(),
      isConst: variable.isConst,
      isLate: variable.isLate,
      isFinal: variable.isFinal,
      isStatic: isStatic ?? fd.isStatic,
      isSynthetic: variable.isSynthetic,
      isPublic: !isPrivate,
      isPrivate: isPrivate,
      typeKind: resolved.kind,
      typeArguments: resolved.args,
      serializeMethodName: resolved.serializeMethodName,
      deserializeMethodName: resolved.deserializeMethodName,
      ignoredFor: ignoredFor,
      redactedFor: redacted.annotations,
      redactPlaceholder: redacted.placeholder,
    );
  }

  static ({
    FieldTypeKind? kind,
    List<ClassField> args,
    String? serializeMethodName,
    String? deserializeMethodName,
  })
  _resolveDartType(DartType? dartType) {
    if (dartType == null) {
      return (
        kind: null,
        args: const [],
        serializeMethodName: null,
        deserializeMethodName: null,
      );
    }
    final element = dartType.element;
    if (element?.library?.isDartCore ?? false) {
      final kind = switch (element?.name) {
        'DateTime' => FieldTypeKind.dateTime,
        'Uri' => FieldTypeKind.uri,
        'Duration' => FieldTypeKind.duration,
        'BigInt' => FieldTypeKind.bigInt,
        'double' => FieldTypeKind.doubleType,
        _ => null,
      };
      if (kind != null) {
        return (
          kind: kind,
          args: const [],
          serializeMethodName: null,
          deserializeMethodName: null,
        );
      }
    }
    if (element is EnumElement) {
      return (
        kind: FieldTypeKind.enumType,
        args: const [],
        serializeMethodName: null,
        deserializeMethodName: null,
      );
    }
    if (dartType is InterfaceType) {
      final args = [
        for (final arg in dartType.typeArguments) _fromDartType(arg),
      ];
      if (dartType.isDartCoreList) {
        return (
          kind: FieldTypeKind.list,
          args: args,
          serializeMethodName: null,
          deserializeMethodName: null,
        );
      }
      if (dartType.isDartCoreIterable) {
        return (
          kind: FieldTypeKind.iterable,
          args: args,
          serializeMethodName: null,
          deserializeMethodName: null,
        );
      }
      if (dartType.isDartCoreSet) {
        return (
          kind: FieldTypeKind.set,
          args: args,
          serializeMethodName: null,
          deserializeMethodName: null,
        );
      }
      if (dartType.isDartCoreMap) {
        return (
          kind: FieldTypeKind.map,
          args: args,
          serializeMethodName: null,
          deserializeMethodName: null,
        );
      }

      if (element is ClassElement && !(element.library.isDartCore)) {
        final (ser, deser) = _resolveClassSerialization(element);
        return (
          kind: FieldTypeKind.other,
          args: const [],
          serializeMethodName: ser,
          deserializeMethodName: deser,
        );
      }
    }
    return (
      kind: FieldTypeKind.other,
      args: const [],
      serializeMethodName: null,
      deserializeMethodName: null,
    );
  }

  static (String?, String?) _resolveClassSerialization(ClassElement element) {
    String? serializeName;
    String? deserializeName;

    for (final meta in element.metadata.annotations) {
      final constant = meta.computeConstantValue();
      if (constant == null) continue;
      for (final item in expandAnnotationConstant(constant)) {
        final typeName = item.type?.element?.name;
        if (typeName == 'Serialize') {
          serializeName ??= extractConstantMethodName(item) ?? 'toMap';
        } else if (typeName == 'Deserialize') {
          deserializeName ??= extractConstantMethodName(item) ?? 'fromMap';
        }
      }
    }

    if (serializeName == null) {
      for (final m in element.methods) {
        if (!m.isStatic && (m.name == 'toMap' || m.name == 'toJson')) {
          serializeName = m.name;
          break;
        }
      }
    }

    if (deserializeName == null) {
      for (final c in element.constructors) {
        if (c.isFactory && (c.name == 'fromMap' || c.name == 'fromJson')) {
          deserializeName = c.name;
          break;
        }
      }
    }
    if (deserializeName == null) {
      for (final m in element.methods) {
        if (m.isStatic && (m.name == 'fromMap' || m.name == 'fromJson')) {
          deserializeName = m.name;
          break;
        }
      }
    }

    return (serializeName, deserializeName);
  }

  static ClassField _fromDartType(DartType dartType) {
    final resolved = _resolveDartType(dartType);
    final suffix = dartType.nullabilitySuffix == NullabilitySuffix.question
        ? '?'
        : '';
    final display = dartType.getDisplayString();
    final typeStr = suffix.isNotEmpty && !display.endsWith('?')
        ? '$display?'
        : display;
    return ClassField(
      name: 'e',
      type: typeStr,
      typeKind: resolved.kind,
      typeArguments: resolved.args,
      serializeMethodName: resolved.serializeMethodName,
      deserializeMethodName: resolved.deserializeMethodName,
    );
  }

  static List<String> _splitTopLevelTypeArgs(String input) {
    final result = <String>[];
    var depth = 0;
    var start = 0;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == '<' || ch == '(') {
        depth++;
      } else if (ch == '>' || ch == ')') {
        depth--;
      } else if (ch == ',' && depth == 0) {
        result.add(input.substring(start, i));
        start = i + 1;
      }
    }
    result.add(input.substring(start));
    return result;
  }

  @override
  String toString() =>
      'ClassField(name: $name, type: $type, keyword: $keyword, equals: $equals, '
      'initializer: $initializer, isConst: $isConst, isLate: $isLate, '
      'isFinal: $isFinal, isStatic: $isStatic, isSynthetic: $isSynthetic, '
      'isPublic: $isPublic, isPrivate: $isPrivate)';
}

/// Recursively expands any `CompositeAnnotation` constant into its constituent
/// annotation [DartObject]s.
Iterable<DartObject> expandAnnotationConstant(
  DartObject root, {
  int depth = 0,
}) sync* {
  if (depth > 16) return;
  if (root.type?.element?.name == 'CompositeAnnotation') {
    final items = root.getField('annotations')?.toListValue();
    if (items == null) return;
    for (final item in items) {
      yield* expandAnnotationConstant(item, depth: depth + 1);
    }
  } else {
    yield root;
  }
}

/// Extracts `methodName` from a `Serialize` or `Deserialize` [DartObject]'s
/// `name` field.
String? extractConstantMethodName(DartObject obj) {
  final nameObj = obj.getField('name');
  if (nameObj == null) return null;
  return (nameObj.getField('methodName') ??
          nameObj.getField('(super)')?.getField('methodName'))
      ?.toStringValue();
}

const _defaultRedactPlaceholder = '[REDACTED]';

FeatureAnnotation? _featureFromEnumName(String? name) => switch (name) {
  'copyWith' => FeatureAnnotation.copyWith,
  'overrideEquality' => FeatureAnnotation.overrideEquality,
  'overrideToString' => FeatureAnnotation.overrideToString,
  'serialize' => FeatureAnnotation.serialize,
  'deserialize' => FeatureAnnotation.deserialize,
  _ => null,
};

Set<FeatureAnnotation> _featureSetFromDartObject(DartObject? setField) {
  final setVal = setField?.toSetValue();
  if (setVal == null) return const {};
  return {
    for (final item in setVal) ?_featureFromEnumName(item.variable?.name),
  };
}

Set<FeatureAnnotation> _featureSetFromLiteral(SetOrMapLiteral literal) {
  final result = <FeatureAnnotation>{};
  for (final element in literal.elements) {
    final enumName = switch (element) {
      DotShorthandPropertyAccess(:final propertyName) => propertyName.name,
      PrefixedIdentifier(:final identifier) => identifier.name,
      SimpleIdentifier(:final name) => name,
      _ => null,
    };
    if (_featureFromEnumName(enumName) case final f?) {
      result.add(f);
    }
  }
  return result;
}

String _annotationRawName(Annotation annotation) => switch (annotation.name) {
  SimpleIdentifier(:final name) => name,
  PrefixedIdentifier(:final identifier) => identifier.name,
};

Set<FeatureAnnotation>? _ignoredForFromDartObject(DartObject? constant) {
  if (constant == null || constant.type?.element?.name != 'Ignore') {
    return null;
  }
  return _featureSetFromDartObject(constant.getField('annotations'));
}

Set<FeatureAnnotation> _extractIgnoredForFromElements(
  Iterable<ElementAnnotation> metadata,
) {
  final result = <FeatureAnnotation>{};
  for (final meta in metadata) {
    final parsed = _ignoredForFromDartObject(meta.computeConstantValue());
    if (parsed != null) {
      result.addAll(parsed);
    }
  }
  return result;
}

Set<FeatureAnnotation> _extractIgnoredFor(Iterable<Annotation> metadata) {
  final result = <FeatureAnnotation>{};
  for (final annotation in metadata) {
    final resolved = _ignoredForFromDartObject(
      annotation.elementAnnotation?.computeConstantValue(),
    );
    if (resolved != null) {
      result.addAll(resolved);
      continue;
    }

    // Fallback for unresolved AST nodes (e.g. unit tests without resolution).
    final rawName = _annotationRawName(annotation);
    if (rawName != 'ignore' && rawName != 'Ignore') continue;

    final args = annotation.arguments?.arguments;
    if (args == null || args.isEmpty) {
      result.addAll(FeatureAnnotation.values);
      continue;
    }

    final first = args.first;
    if (first is SetOrMapLiteral) {
      result.addAll(_featureSetFromLiteral(first));
    }
  }
  return result;
}

({Set<FeatureAnnotation> annotations, String placeholder})?
_redactFromDartObject(DartObject? constant) {
  if (constant == null || constant.type?.element?.name != 'Redact') {
    return null;
  }
  return (
    annotations: _featureSetFromDartObject(constant.getField('annotations')),
    placeholder:
        constant.getField('placeholder')?.toStringValue() ??
        _defaultRedactPlaceholder,
  );
}

({Set<FeatureAnnotation> annotations, String placeholder})
_extractRedactedFromElements(Iterable<ElementAnnotation> metadata) {
  final annotations = <FeatureAnnotation>{};
  var placeholder = _defaultRedactPlaceholder;
  for (final meta in metadata) {
    final parsed = _redactFromDartObject(meta.computeConstantValue());
    if (parsed != null) {
      annotations.addAll(parsed.annotations);
      placeholder = parsed.placeholder;
    }
  }
  return (annotations: annotations, placeholder: placeholder);
}

({Set<FeatureAnnotation> annotations, String placeholder}) _extractRedacted(
  Iterable<Annotation> metadata,
) {
  final annotations = <FeatureAnnotation>{};
  var placeholder = _defaultRedactPlaceholder;
  for (final annotation in metadata) {
    final resolved = _redactFromDartObject(
      annotation.elementAnnotation?.computeConstantValue(),
    );
    if (resolved != null) {
      annotations.addAll(resolved.annotations);
      placeholder = resolved.placeholder;
      continue;
    }

    // Fallback for unresolved AST nodes (e.g. unit tests without resolution).
    final rawName = _annotationRawName(annotation);
    if (rawName != 'redact' && rawName != 'Redact') continue;

    final args = annotation.arguments?.arguments;
    if (args == null || args.isEmpty) {
      annotations.add(FeatureAnnotation.overrideToString);
      continue;
    }

    var hasExplicitAnnotations = false;
    for (final arg in args) {
      if (arg is NamedArgument) {
        final expr = arg.argumentExpression;
        if (arg.name.lexeme == 'annotations' && expr is SetOrMapLiteral) {
          hasExplicitAnnotations = true;
          annotations.addAll(_featureSetFromLiteral(expr));
        } else if (arg.name.lexeme == 'placeholder' &&
            expr is SimpleStringLiteral) {
          placeholder = expr.value;
        }
      } else if (arg is SetOrMapLiteral) {
        hasExplicitAnnotations = true;
        annotations.addAll(_featureSetFromLiteral(arg));
      } else if (arg is SimpleStringLiteral) {
        placeholder = arg.value;
      }
    }
    if (!hasExplicitAnnotations) {
      annotations.add(FeatureAnnotation.overrideToString);
    }
  }
  return (annotations: annotations, placeholder: placeholder);
}
