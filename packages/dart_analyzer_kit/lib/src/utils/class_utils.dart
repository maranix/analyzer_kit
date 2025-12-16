part of 'utils.dart';

extension ClassDeclarationExtension on ClassDeclaration {
  bool hasAnnotation(Annotations annotation) =>
      metadata.any((a) => stringsMatchByCharCode(a.name.name, annotation.name));

  bool hasMethod(String methodName) =>
      methods.any((m) => stringsMatchByCharCode(m.name.lexeme, methodName));

  Iterable<MethodDeclaration> get methods =>
      members.whereType<MethodDeclaration>();

  Iterable<FieldDeclaration> get fields =>
      members.whereType<FieldDeclaration>();
}

extension VariableDeclarationX on VariableDeclaration {
  bool get isPrivate => name.lexeme.startsWith('_');

  bool get isPublic => !isPrivate;
}
