import 'package:analyzer/dart/ast/ast.dart' show FieldDeclaration;

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

  /// Whether this field's type is a `List` or `Iterable` (ordered collection).
  bool get isListOrIterableType => _isType('List') || _isType('Iterable');

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

  static ClassField fromFieldDeclaration(FieldDeclaration fd) {
    final typeAnnotation = fd.fields.type;
    final variable = fd.fields.variables.single;
    final isPrivate = variable.name.lexeme.startsWith('_');

    return ClassField(
      keyword: fd.fields.keyword?.lexeme,
      type: typeAnnotation?.toSource() ?? 'dynamic',
      name: variable.name.lexeme,
      equals: variable.equals?.lexeme,
      initializer: variable.initializer?.toString(),
      isConst: variable.isConst,
      isLate: variable.isLate,
      isFinal: variable.isFinal,
      isStatic: fd.isStatic,
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
