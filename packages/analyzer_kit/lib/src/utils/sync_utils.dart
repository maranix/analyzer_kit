part of 'utils.dart';

/// Result of checking whether a generated member is in sync with class fields.
final class FieldSyncResult {
  const FieldSyncResult({
    this.missingFields = const [],
    this.extraFields = const [],
  });

  final List<String> missingFields;
  final List<String> extraFields;

  bool get isInSync => missingFields.isEmpty && extraFields.isEmpty;

  /// Human-readable summary of out-of-sync fields for diagnostic messages.
  String get summary {
    final parts = <String>[
      if (missingFields.isNotEmpty) 'missing: ${missingFields.join(', ')}',
      if (extraFields.isNotEmpty) 'extra: ${extraFields.join(', ')}',
    ];
    return parts.join('; ');
  }
}

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

/// Checks whether `copyWith` [method] has exact 1:1 parameters for [fields].
FieldSyncResult checkCopyWithSync(
  MethodDeclaration method,
  Iterable<ClassField> fields,
) {
  final fieldNames = [for (final f in fields) f.name];
  final fieldSet = fieldNames.toSet();
  final paramNames = <String>[
    for (final param in method.parameters?.parameters ?? const [])
      ?param.name?.lexeme,
  ];
  final paramSet = paramNames.toSet();

  return FieldSyncResult(
    missingFields: [
      for (final name in fieldNames)
        if (!paramSet.contains(name)) name,
    ],
    extraFields: [
      for (final name in paramNames)
        if (!fieldSet.contains(name)) name,
    ],
  );
}

/// Returns whether [method] (`copyWith`) is in sync with [fields].
bool isCopyWithInSync(MethodDeclaration method, Iterable<ClassField> fields) =>
    checkCopyWithSync(method, fields).isInSync;

/// Checks whether [body] references every field name in [fields].
FieldSyncResult checkBodySync(FunctionBody body, Iterable<ClassField> fields) {
  final collector = _FieldReferenceCollector();
  body.accept(collector);
  return FieldSyncResult(
    missingFields: [
      for (final f in fields)
        if (!collector.names.contains(f.name)) f.name,
    ],
  );
}

/// Returns whether [body] references every field name in [fields].
bool isBodyInSync(FunctionBody body, Iterable<ClassField> fields) =>
    checkBodySync(body, fields).isInSync;

/// Checks whether a serialization [body] (`toMap` / `toJson`) has map keys
/// matching [fields].
FieldSyncResult checkSerializeSync(
  FunctionBody body,
  Iterable<ClassField> fields,
) {
  final collector = _FieldReferenceCollector(collectMapKeys: true);
  body.accept(collector);

  final fieldNames = [for (final f in fields) f.name];
  final fieldSet = fieldNames.toSet();

  return FieldSyncResult(
    missingFields: [
      for (final name in fieldNames)
        if (!collector.names.contains(name)) name,
    ],
    extraFields: [
      for (final key in collector.mapKeys)
        if (!fieldSet.contains(key)) key,
    ],
  );
}

/// Checks whether a deserialization [member] references every field name in
/// [fields] (via identifier or string key literal).
FieldSyncResult checkDeserializeSync(
  ClassMember member,
  Iterable<ClassField> fields,
) {
  final FunctionBody? body = switch (member) {
    ConstructorDeclaration(:final body) => body,
    MethodDeclaration(:final body) => body,
    _ => null,
  };
  if (body == null) {
    return FieldSyncResult(missingFields: [for (final f in fields) f.name]);
  }

  final collector = _FieldReferenceCollector(includeStringLiterals: true);
  body.accept(collector);
  return FieldSyncResult(
    missingFields: [
      for (final f in fields)
        if (!collector.names.contains(f.name)) f.name,
    ],
  );
}

/// Returns whether a deserialization [member] is in sync with [fields].
bool isDeserializeInSync(ClassMember member, Iterable<ClassField> fields) =>
    checkDeserializeSync(member, fields).isInSync;

final class _FieldReferenceCollector extends RecursiveAstVisitor<void> {
  _FieldReferenceCollector({
    this.includeStringLiterals = false,
    this.collectMapKeys = false,
  });

  final bool includeStringLiterals;
  final bool collectMapKeys;
  final Set<String> names = {};
  final Set<String> mapKeys = {};

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

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    if (collectMapKeys) {
      if (node.key case final SimpleStringLiteral keyLiteral) {
        mapKeys.add(keyLiteral.value);
      }
    }
    super.visitMapLiteralEntry(node);
  }
}
