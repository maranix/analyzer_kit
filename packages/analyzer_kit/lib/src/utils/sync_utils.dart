part of 'utils.dart';

/// Result of checking whether a generated member is in sync with class fields.
final class const FieldSyncResult({
  final List<String> missingFields = const [],
  final List<String> extraFields = const [],
  final List<String> driftReasons = const [],
}) {
  bool get isInSync =>
      missingFields.isEmpty && extraFields.isEmpty && driftReasons.isEmpty;

  /// Human-readable summary of out-of-sync fields for diagnostic messages.
  String get summary {
    final parts = <String>[
      if (missingFields.isNotEmpty) 'missing: ${missingFields.join(', ')}',
      if (extraFields.isNotEmpty) 'extra: ${extraFields.join(', ')}',
      ...driftReasons,
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

/// Checks whether `copyWith` [method] has exact 1:1 parameters for [fields]
/// and matches the configured [nullable] signature mode.
FieldSyncResult checkCopyWithSync(
  MethodDeclaration method,
  Iterable<ClassField> fields, {
  bool nullable = false,
}) {
  final fieldMap = {
    for (final f in fields)
      if (f.isConstructorParam) f.name: f,
  };
  final fieldNames = fieldMap.keys.toList();
  final paramNames = <String>[];
  final driftReasons = <String>[];

  for (final param
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    final name = param.name?.lexeme;
    if (name == null) continue;
    paramNames.add(name);

    final field = fieldMap[name];
    if (field != null && field.isNullableType) {
      final TypeAnnotation? typeNode = param.type;
      final isFunctionType = typeNode is GenericFunctionType;
      if (nullable != isFunctionType) {
        driftReasons.add('nullable signature mismatch: $name');
      }
    }
  }
  final paramSet = paramNames.toSet();

  return FieldSyncResult(
    missingFields: [
      for (final name in fieldNames)
        if (!paramSet.contains(name)) name,
    ],
    extraFields: [
      for (final name in paramNames)
        if (!fieldMap.containsKey(name)) name,
    ],
    driftReasons: driftReasons,
  );
}

/// Returns whether [method] (`copyWith`) is in sync with [fields].
bool isCopyWithInSync(
  MethodDeclaration method,
  Iterable<ClassField> fields, {
  bool nullable = false,
}) => checkCopyWithSync(method, fields, nullable: nullable).isInSync;

/// Checks whether `==` and `hashCode` are in sync with [fields], including
/// removed `other.<field>` references and generic [typeArguments] in `==`.
FieldSyncResult checkEqualitySync(
  MethodDeclaration equalsMethod,
  MethodDeclaration hashCodeMethod,
  Iterable<ClassField> fields, {
  String? className,
  String typeArguments = '',
}) {
  final fieldSet = {for (final f in fields) f.name};
  final equalsCollector = _FieldReferenceCollector(collectOtherFields: true);
  equalsMethod.body.accept(equalsCollector);

  final hashCollector = _FieldReferenceCollector();
  hashCodeMethod.body.accept(hashCollector);

  final missing = <String>{
    for (final f in fields)
      if (!equalsCollector.names.contains(f.name) ||
          !hashCollector.names.contains(f.name))
        f.name,
  }.toList();

  final extra = <String>[
    for (final otherField in equalsCollector.otherFields)
      if (!fieldSet.contains(otherField)) otherField,
  ];

  final driftReasons = <String>[];
  if (className != null &&
      typeArguments.isNotEmpty &&
      equalsCollector.isTypeSource != null &&
      equalsCollector.isTypeSource != '$className$typeArguments') {
    driftReasons.add('missing type arguments: $typeArguments');
  }

  return FieldSyncResult(
    missingFields: missing,
    extraFields: extra,
    driftReasons: driftReasons,
  );
}

/// Checks whether [body] references every field name in [fields], accounting
/// for redacted fields when [feature] is [FeatureAnnotation.overrideToString].
FieldSyncResult checkBodySync(
  FunctionBody body,
  Iterable<ClassField> fields, {
  FeatureAnnotation? feature,
}) {
  final checkRedaction = feature == FeatureAnnotation.overrideToString;
  final collector = _FieldReferenceCollector(
    collectStringContent: checkRedaction,
  );
  body.accept(collector);

  final missingFields = <String>[];
  final driftReasons = <String>[];
  final stringContent = checkRedaction ? collector.stringContent : '';

  for (final f in fields) {
    if (checkRedaction &&
        f.redactedFor.contains(FeatureAnnotation.overrideToString)) {
      final redactedSegment = '${f.name}: ${f.redactPlaceholder}';
      if (_containsPrefixedSegment(stringContent, redactedSegment)) {
        if (collector.names.contains(f.name)) {
          driftReasons.add('unredacted field: ${f.name}');
        }
        continue;
      }
      if (collector.names.contains(f.name)) {
        driftReasons.add('unredacted field: ${f.name}');
      } else if (_containsPrefixedSegment(stringContent, '${f.name}: ')) {
        driftReasons.add('redacted placeholder mismatch: ${f.name}');
      } else {
        missingFields.add(f.name);
      }
    } else if (!collector.names.contains(f.name)) {
      missingFields.add(f.name);
    }
  }

  return FieldSyncResult(
    missingFields: missingFields,
    driftReasons: driftReasons,
  );
}

/// Returns whether [body] references every field name in [fields].
bool isBodyInSync(
  FunctionBody body,
  Iterable<ClassField> fields, {
  FeatureAnnotation? feature,
}) => checkBodySync(body, fields, feature: feature).isInSync;

/// Checks whether a serialization [body] (`toMap` / `toJson`) has map keys
/// matching [fields], accounting for redacted fields.
FieldSyncResult checkSerializeSync(
  FunctionBody body,
  Iterable<ClassField> fields,
) {
  final collector = _FieldReferenceCollector(collectMapKeys: true);
  body.accept(collector);

  final fieldNames = [for (final f in fields) f.name];
  final fieldSet = fieldNames.toSet();
  final missingFields = <String>[];
  final driftReasons = <String>[];

  for (final f in fields) {
    if (f.redactedFor.contains(FeatureAnnotation.serialize)) {
      final entryExpr = collector.mapEntries[f.name];
      if (entryExpr == null) {
        missingFields.add(f.name);
      } else if (entryExpr is! StringLiteral) {
        driftReasons.add('unredacted field: ${f.name}');
      } else if (entryExpr.stringValue != f.redactPlaceholder) {
        driftReasons.add('redacted placeholder mismatch: ${f.name}');
      }
    } else if (!collector.names.contains(f.name)) {
      missingFields.add(f.name);
    }
  }

  return FieldSyncResult(
    missingFields: missingFields,
    extraFields: [
      for (final key in collector.mapKeys)
        if (!fieldSet.contains(key)) key,
    ],
    driftReasons: driftReasons,
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

  final collector = _FieldReferenceCollector(
    includeStringLiterals: true,
    collectMapIndexKeys: true,
  );
  body.accept(collector);
  final ctorFields = [
    for (final f in fields)
      if (f.isConstructorParam) f,
  ];
  final fieldSet = {for (final f in ctorFields) f.name};
  return FieldSyncResult(
    missingFields: [
      for (final f in ctorFields)
        if (!collector.names.contains(f.name)) f.name,
    ],
    extraFields: [
      for (final key in collector.mapIndexKeys)
        if (!fieldSet.contains(key)) key,
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
    this.collectOtherFields = false,
    this.collectMapIndexKeys = false,
    this.collectStringContent = false,
  });

  final bool includeStringLiterals;
  final bool collectMapKeys;
  final bool collectOtherFields;
  final bool collectMapIndexKeys;
  final bool collectStringContent;
  final Set<String> names = {};
  final Set<String> mapKeys = {};
  final Map<String, ast.Expression> mapEntries = {};
  final Set<String> otherFields = {};
  final Set<String> mapIndexKeys = {};
  final StringBuffer _stringBuffer = StringBuffer();
  String? isTypeSource;

  String get stringContent => _stringBuffer.toString();

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
    if (collectStringContent) {
      _stringBuffer.write(node.value);
    }
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitInterpolationString(InterpolationString node) {
    if (collectStringContent) {
      _stringBuffer.write(node.value);
    }
    super.visitInterpolationString(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (collectStringContent) {
      _stringBuffer.write('\u0000');
    }
    super.visitInterpolationExpression(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    if (collectMapKeys) {
      if (node.key case final SimpleStringLiteral keyLiteral) {
        mapKeys.add(keyLiteral.value);
        mapEntries[keyLiteral.value] = node.value;
      }
    }
    super.visitMapLiteralEntry(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (collectOtherFields &&
        node.prefix.name == 'other' &&
        node.identifier.name != 'runtimeType') {
      otherFields.add(node.identifier.name);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (collectOtherFields) {
      isTypeSource ??= node.type.toSource();
    }
    super.visitIsExpression(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (collectMapIndexKeys) {
      if (node.target case SimpleIdentifier(name: 'map')) {
        if (node.index case final SimpleStringLiteral keyLiteral) {
          mapIndexKeys.add(keyLiteral.value);
        }
      }
    }
    super.visitIndexExpression(node);
  }
}

bool _containsPrefixedSegment(String content, String segment) {
  var start = 0;
  while (true) {
    final idx = content.indexOf(segment, start);
    if (idx == -1) return false;
    if (idx == 0 || !_isIdentifierChar(content.codeUnitAt(idx - 1))) {
      return true;
    }
    start = idx + 1;
  }
}

@pragma('vm:prefer-inline')
bool _isIdentifierChar(int code) =>
    (code >= 0x30 && code <= 0x39) ||
    (code >= 0x41 && code <= 0x5A) ||
    (code >= 0x61 && code <= 0x7A) ||
    code == 0x5F ||
    code == 0x24;
