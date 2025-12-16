import 'package:analyzer/dart/ast/ast.dart'
    show VariableDeclarationList, FieldDeclaration;
import 'package:dart_analyzer_kit/src/utils/utils.dart';

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

    return ClassField(
      keyword: fd.fields.keyword?.lexeme,
      type: typeAnnotation?.toSource() ?? "dynamic",
      name: fd.fields.variables.single.name.lexeme,
      equals: fd.fields.variables.single.equals?.lexeme,
      initializer: fd.fields.variables.single.initializer?.toString(),
      isConst: fd.fields.variables.single.isConst,
      isLate: fd.fields.variables.single.isLate,
      isFinal: fd.fields.variables.single.isFinal,
      isStatic: fd.isStatic,
      isSynthetic: fd.fields.variables.single.isSynthetic,
      isPublic: fd.fields.variables.single.isPublic,
      isPrivate: fd.fields.variables.single.isPrivate,
    );
  }

  static ClassField fromVariableDeclarationList(VariableDeclarationList vdl) {
    return ClassField(
      keyword: vdl.keyword?.lexeme,
      type: vdl.type?.toSource() ?? "dynamic",
      name: vdl.variables.single.name.lexeme,
      equals: vdl.variables.single.equals?.lexeme,
      initializer: vdl.variables.single.initializer?.toString(),
      isConst: vdl.variables.single.isConst,
      isLate: vdl.variables.single.isLate,
      isFinal: vdl.variables.single.isFinal,
      isSynthetic: vdl.variables.single.isSynthetic,
      isPublic: vdl.variables.single.isPublic,
      isPrivate: vdl.variables.single.isPrivate,
    );
  }

  @override
  String toString() =>
      "ClassField(name: $name, type: $type, keyword: $keyword, equals: $equals, initializer: $initializer, isConst: $isConst, isLate: $isLate, isFinal: $isFinal, isStatic: $isStatic, isSynthetic: $isSynthetic, isPublic: $isPublic, isPrivate: $isPrivate)";
}
