import 'package:analyzer/dart/ast/ast.dart'
    show FieldDeclaration, VariableDeclaration;

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

  /// Whether this field should be included in generated methods.
  ///
  /// Excludes static, synthetic, and late fields.
  bool get isGeneratable => !isStatic && !isSynthetic && !isLate;

  /// Whether this field's type is nullable (ends with `?`).
  bool get isNullableType => type.endsWith('?');

  /// Whether this field's type is a `List`.
  bool get isListType => _isType('List');

  /// Whether this field's type is an `Iterable`.
  bool get isIterableType => _isType('Iterable');

  /// Whether this field's type is a `List` or `Iterable` (ordered collection).
  bool get isListOrIterableType => isListType || isIterableType;

  /// Whether this field's type is a `Set` (unordered collection).
  bool get isSetType => _isType('Set');

  /// Whether this field's type is a `Map`.
  bool get isMapType => _isType('Map');

  /// Whether this field's type is any collection type.
  bool get isCollectionType => isListOrIterableType || isSetType || isMapType;

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
    final keyword = fd.fields.keyword?.lexeme;
    final isStatic = fd.isStatic;

    return fd.fields.variables.map(
      (v) => _fromVariable(
        fd,
        v,
        type: type,
        keyword: keyword,
        isStatic: isStatic,
      ),
    );
  }

  static ClassField _fromVariable(
    FieldDeclaration fd,
    VariableDeclaration variable, {
    String? type,
    String? keyword,
    bool? isStatic,
  }) {
    final name = variable.name.lexeme;
    final isPrivate = name.startsWith('_');

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
    );
  }

  @override
  String toString() =>
      'ClassField(name: $name, type: $type, keyword: $keyword, equals: $equals, '
      'initializer: $initializer, isConst: $isConst, isLate: $isLate, '
      'isFinal: $isFinal, isStatic: $isStatic, isSynthetic: $isSynthetic, '
      'isPublic: $isPublic, isPrivate: $isPrivate)';
}
