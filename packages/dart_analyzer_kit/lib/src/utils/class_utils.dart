part of 'utils.dart';

extension ClassDeclarationExtension on ClassDeclaration {
  bool hasAnnotation(Annotations annotation) =>
      metadata.any((a) => stringsMatchByCharCode(a.name.name, annotation.name));

  bool hasMethod(String methodName) =>
      methods.any((m) => stringsMatchByCharCode(m.name.lexeme, methodName));

  bool hasGetter(String getterName) =>
      getters.any((m) => stringsMatchByCharCode(m.name.lexeme, getterName));

  Iterable<MethodDeclaration> get methods =>
      members.whereType<MethodDeclaration>();

  Iterable<FieldDeclaration> get fields =>
      members.whereType<FieldDeclaration>();

  Iterable<MethodDeclaration> get getters => methods.where((m) => m.isGetter);
}

extension VariableDeclarationX on VariableDeclaration {
  bool get isPrivate => name.lexeme.startsWith('_');

  bool get isPublic => !isPrivate;
}
