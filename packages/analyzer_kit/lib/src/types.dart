import 'package:analyzer/dart/ast/ast.dart'
    show FieldDeclaration, FormalParameter, VariableDeclaration;
import 'package:analyzer/dart/constant/value.dart' show DartObject;
import 'package:analyzer/dart/element/element.dart'
    show ClassElement, EnumElement, FieldElement;
import 'package:analyzer/dart/element/nullability_suffix.dart'
    show NullabilitySuffix;
import 'package:analyzer/dart/element/type.dart' show DartType, InterfaceType;

/// Semantic type classification for a [ClassField], used by serialization and
/// collection code generation.
enum FieldTypeKind {
  other,
  dateTime,
  uri,
  duration,
  bigInt,
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
  bool get isDateTimeType =>
      typeKind == FieldTypeKind.dateTime || _isType('DateTime');

  /// Whether this field's type is `Uri` or `Uri?`.
  bool get isUriType => typeKind == FieldTypeKind.uri || _isType('Uri');

  /// Whether this field's type is `Duration` or `Duration?`.
  bool get isDurationType =>
      typeKind == FieldTypeKind.duration || _isType('Duration');

  /// Whether this field's type is `BigInt` or `BigInt?`.
  bool get isBigIntType =>
      typeKind == FieldTypeKind.bigInt || _isType('BigInt');

  /// Whether this field's type is an `enum` (requires resolved [typeKind]).
  bool get isEnumType => typeKind == FieldTypeKind.enumType;

  /// Whether this field's type is a `List`.
  bool get isListType => typeKind == FieldTypeKind.list || _isType('List');

  /// Whether this field's type is an `Iterable`.
  bool get isIterableType =>
      typeKind == FieldTypeKind.iterable || _isType('Iterable');

  /// Whether this field's type is a `List` or `Iterable` (ordered collection).
  bool get isListOrIterableType => isListType || isIterableType;

  /// Whether this field's type is a `Set` (unordered collection).
  bool get isSetType => typeKind == FieldTypeKind.set || _isType('Set');

  /// Whether this field's type is a `Map`.
  bool get isMapType => typeKind == FieldTypeKind.map || _isType('Map');

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
  );

  /// Extracts a [ClassField] from a declaring [FormalParameter] in a
  /// `PrimaryConstructorDeclaration`.
  static ClassField fromPrimaryConstructorParameter(FormalParameter param) {
    final name = param.name!.lexeme;
    final isPrivate = name.startsWith('_');
    final dartType = param.declaredFragment?.element.type;
    final resolved = _resolveDartType(dartType);

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
      for (final item in _expandConstant(constant)) {
        final typeName = item.type?.element?.name;
        if (typeName == 'Serialize') {
          serializeName ??= _extractNameFromMethodObj(item) ?? 'toMap';
        } else if (typeName == 'Deserialize') {
          deserializeName ??= _extractNameFromMethodObj(item) ?? 'fromMap';
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

  static Iterable<DartObject> _expandConstant(
    DartObject root, {
    int depth = 0,
  }) sync* {
    if (depth > 16) return;
    if (root.type?.element?.name == 'CompositeAnnotation') {
      final items = root.getField('annotations')?.toListValue();
      if (items == null) return;
      for (final item in items) {
        yield* _expandConstant(item, depth: depth + 1);
      }
    } else {
      yield root;
    }
  }

  static String? _extractNameFromMethodObj(DartObject obj) {
    final nameObj = obj.getField('name');
    if (nameObj == null) return null;
    return (nameObj.getField('methodName') ??
            nameObj.getField('(super)')?.getField('methodName'))
        ?.toStringValue();
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
