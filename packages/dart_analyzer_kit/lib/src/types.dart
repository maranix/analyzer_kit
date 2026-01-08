import 'package:analyzer/dart/ast/ast.dart'
    show VariableDeclarationList, FieldDeclaration;

final class ClassField {
  const ClassField({
    required this.name,
    this.type = "dynamic",
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

  static ClassField fromFieldDeclaration(FieldDeclaration fd) {
    final typeAnnotation = fd.fields.type;
    final variable = fd.fields.variables.single;
    final isPrivate = variable.name.lexeme.startsWith('_');

    return ClassField(
      keyword: fd.fields.keyword?.lexeme,
      type: typeAnnotation?.toSource() ?? "dynamic",
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

  static ClassField fromVariableDeclarationList(VariableDeclarationList vdl) {
    final variable = vdl.variables.single;
    final isPrivate = variable.name.lexeme.startsWith('_');

    return ClassField(
      keyword: vdl.keyword?.lexeme,
      type: vdl.type?.toSource() ?? "dynamic",
      name: variable.name.lexeme,
      equals: variable.equals?.lexeme,
      initializer: variable.initializer?.toString(),
      isConst: variable.isConst,
      isLate: variable.isLate,
      isFinal: variable.isFinal,
      isSynthetic: variable.isSynthetic,
      isPublic: !isPrivate,
      isPrivate: isPrivate,
    );
  }

  @override
  String toString() =>
      "ClassField(name: $name, type: $type, keyword: $keyword, equals: $equals, initializer: $initializer, isConst: $isConst, isLate: $isLate, isFinal: $isFinal, isStatic: $isStatic, isSynthetic: $isSynthetic, isPublic: $isPublic, isPrivate: $isPrivate)";
}
