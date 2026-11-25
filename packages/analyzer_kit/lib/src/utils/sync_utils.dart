part of 'utils.dart';

/// Finds a [MethodDeclaration] in [node] with the given [name].
MethodDeclaration? findMethodDeclaration(ClassDeclaration node, String name) {
  for (final member in node.body.members) {
    if (member is MethodDeclaration && member.name.lexeme == name) {
      return member;
    }
  }
  return null;
}

/// Finds a deserialization member (factory constructor or static method) in
/// [node] with the given [name].
ClassMember? findDeserializeMember(ClassDeclaration node, String name) {
  for (final member in node.body.members) {
    if (member is ConstructorDeclaration &&
        member.factoryKeyword != null &&
        member.name?.lexeme == name) {
      return member;
    }
    if (member is MethodDeclaration &&
        member.isStatic &&
        member.name.lexeme == name) {
      return member;
    }
  }
  return null;
}

/// Returns whether [method] (`copyWith`) declares a parameter for every field
/// in [fields].
bool isCopyWithInSync(MethodDeclaration method, Iterable<ClassField> fields) {
  final params = method.parameters?.parameters;
  if (params == null) return fields.isEmpty;

  final paramNames = <String>{for (final param in params) ?param.name?.lexeme};
  return fields.every((f) => paramNames.contains(f.name));
}

/// Returns whether [body] references every field name in [fields].
bool isBodyInSync(FunctionBody body, Iterable<ClassField> fields) {
  final collector = _FieldReferenceCollector();
  body.accept(collector);
  return fields.every((f) => collector.names.contains(f.name));
}

/// Returns whether a deserialization [member] references every field name in
/// [fields] (via identifier or string key literal).
bool isDeserializeInSync(ClassMember member, Iterable<ClassField> fields) {
  final FunctionBody? body = switch (member) {
    ConstructorDeclaration(:final body) => body,
    MethodDeclaration(:final body) => body,
    _ => null,
  };
  if (body == null) return false;

  final collector = _FieldReferenceCollector(includeStringLiterals: true);
  body.accept(collector);
  return fields.every((f) => collector.names.contains(f.name));
}

final class _FieldReferenceCollector extends RecursiveAstVisitor<void> {
  _FieldReferenceCollector({this.includeStringLiterals = false});

  final bool includeStringLiterals;
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (includeStringLiterals) {
      names.add(node.value);
    }
    super.visitSimpleStringLiteral(node);
  }
}
