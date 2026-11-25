import 'package:analyzer/dart/ast/ast.dart'
    show FieldDeclaration, FormalParameter, VariableDeclaration;
import 'package:analyzer/dart/element/element.dart' show EnumElement;
import 'package:analyzer/dart/element/nullability_suffix.dart'
    show NullabilitySuffix;
import 'package:analyzer/dart/element/type.dart' show DartType, InterfaceType;

/// Semantic type classification for a [ClassField], used by serialization and
/// collection code generation.
enum FieldTypeKind { other, dateTime, enumType, list, iterable, set, map }

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
    this.typeKind,
    this.typeArguments = const [],
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

  /// Resolved semantic kind of [type], or `null` when constructed without AST
  /// type resolution (in which case getters fall back to parsing [type]).
  final FieldTypeKind? typeKind;

  /// Resolved generic type arguments for collection types (e.g. `[T]` for
  /// `List<T>`, `[K, V]` for `Map<K, V>`).
  final List<ClassField> typeArguments;

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

  /// Extracts a [ClassField] from a declaring [FormalParameter] in a
  /// `PrimaryConstructorDeclaration`.
  static ClassField fromPrimaryConstructorParameter(FormalParameter param) {
    final name = param.name!.lexeme;
    final isPrivate = name.startsWith('_');
    final dartType = param.declaredFragment?.element.type;
    final (kind, args) = _classifyDartType(dartType);

    return ClassField(
      keyword: param.constFinalOrVarKeyword?.lexeme,
      type: param.type?.toSource() ?? 'dynamic',
      name: name,
      isConst: param.isConst,
      isFinal: param.isFinal,
      isPublic: !isPrivate,
      isPrivate: isPrivate,
      isPositional: param.isPositional,
      typeKind: kind,
      typeArguments: args,
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
    final (kind, args) = _classifyDartType(resolvedDartType);

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
      typeKind: kind,
      typeArguments: args,
    );
  }

  static (FieldTypeKind?, List<ClassField>) _classifyDartType(
    DartType? dartType,
  ) {
    if (dartType == null) return (null, const []);
    final element = dartType.element;
    if (element?.name == 'DateTime' &&
        (element?.library?.isDartCore ?? false)) {
      return (FieldTypeKind.dateTime, const []);
    }
    if (element is EnumElement) {
      return (FieldTypeKind.enumType, const []);
    }
    if (dartType is InterfaceType) {
      final args = [
        for (final arg in dartType.typeArguments) _fromDartType(arg),
      ];
      if (dartType.isDartCoreList) return (FieldTypeKind.list, args);
      if (dartType.isDartCoreIterable) return (FieldTypeKind.iterable, args);
      if (dartType.isDartCoreSet) return (FieldTypeKind.set, args);
      if (dartType.isDartCoreMap) return (FieldTypeKind.map, args);
    }
    return (FieldTypeKind.other, const []);
  }

  static ClassField _fromDartType(DartType dartType) {
    final (kind, args) = _classifyDartType(dartType);
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
      typeKind: kind,
      typeArguments: args,
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
