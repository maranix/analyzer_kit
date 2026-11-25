part of 'utils.dart';

/// Generates a `copyWith` method for the given [className] and [fields].
///
/// When [nullable] is `true`, nullable fields are wrapped in `T? Function()?`
/// parameters so callers can explicitly reset them to `null`.
String generateCopyWithMethod(
  String className,
  Iterable<ClassField> fields, {
  String? constructorName,
  String typeArguments = '',
  bool nullable = false,
  bool format = true,
}) {
  final positionalArgs = <Expression>[];
  final namedArgs = <String, Expression>{};
  final functionParams = <Parameter>[];

  for (final field in fields.where((f) => f.isConstructorParam)) {
    final useWrapper = nullable && field.isNullableType;
    final paramType = useWrapper
        ? '${field.type} Function()?'
        : (field.isNullableType ? field.type : '${field.type}?');
    functionParams.add(
      Parameter(
        (b) => b
          ..name = field.name
          ..named = true
          ..type = refer(paramType),
      ),
    );

    final Expression argExpr = useWrapper
        ? CodeExpression(
            Code(
              '${field.name} != null ? ${field.name}() : this.${field.name}',
            ),
          )
        : refer(field.name).ifNullThen(refer('this.${field.name}'));
    if (field.isPositional) {
      positionalArgs.add(argExpr);
    } else {
      namedArgs[field.name] = argExpr;
    }
  }

  final fullClassName = '$className$typeArguments';
  final target = constructorName != null
      ? '$fullClassName.$constructorName'
      : fullClassName;

  final method = Method(
    (b) => b
      ..name = FeatureMethod.copyWith.name
      ..optionalParameters.addAll(functionParams)
      ..lambda = true
      ..body = refer(target).call(positionalArgs, namedArgs).statement
      ..returns = refer(fullClassName),
  );

  final raw = '${method.accept(_dartEmitter)}';
  return format ? formatCode(raw) : raw;
}

/// Generates a `toString` override for the given [className] and [fields].
String generateToStringMethod(
  String className,
  Iterable<ClassField> fields, {
  bool multiline = false,
  bool format = true,
}) {
  final fieldList = fields is List<ClassField> ? fields : fields.toList();
  final String content;
  if (multiline && fieldList.isNotEmpty) {
    final lines = fieldList.map((f) => '  ${f.name}: \$${f.name},').join('\\n');
    content = '$className(\\n$lines\\n)';
  } else {
    content =
        '$className(${fieldList.map((f) => '${f.name}: \$${f.name}').join(', ')})';
  }
  final body = Code("'$content';");

  final method = Method(
    (b) => b
      ..name = FeatureMethod.overrideToString.name
      ..lambda = true
      ..annotations.add(refer('override'))
      ..body = body
      ..returns = refer('String'),
  );

  final raw = '${method.accept(_dartEmitter)}';
  return format ? formatCode(raw) : raw;
}

/// Generates a `hashCode` getter override for the given [fields].
///
/// If [deepCollectionEquality] is explicit `false`, generates pure dart
/// shallow hashing for collections. If `true` or `null` (defer to global config),
/// generates calls to `AnalyzerKit.deepHash`.
String generateHashCodeOverride(
  Iterable<ClassField> fields, {
  bool? deepCollectionEquality,
  bool format = true,
}) {
  final fieldList = fields is List<ClassField> ? fields : fields.toList();
  final String bodyCode;

  if (fieldList.isEmpty) {
    bodyCode = '0;';
  } else if (fieldList.length == 1) {
    final expr = _hashExpression(
      fieldList.first,
      deepCollectionEquality: deepCollectionEquality,
    );
    bodyCode = '$expr.hashCode;';
  } else {
    final hashElements = fieldList
        .map(
          (f) => _hashExpression(
            f,
            deepCollectionEquality: deepCollectionEquality,
          ),
        )
        .join(', ');
    bodyCode = fieldList.length <= 20
        ? 'Object.hash($hashElements);'
        : 'Object.hashAll([$hashElements]);';
  }

  final override = Method(
    (b) => b
      ..type = .getter
      ..annotations.add(refer('override'))
      ..returns = refer('int')
      ..name = FeatureMethod.overrideHashCode.name
      ..lambda = true
      ..body = Code(bodyCode),
  );

  final raw = '${override.accept(_dartEmitter)}';
  return format ? formatCode(raw) : raw;
}

/// Returns the hash expression for a single [field].
String _hashExpression(ClassField field, {bool? deepCollectionEquality}) {
  final name = field.name;

  if (field.isCollectionType && deepCollectionEquality != false) {
    return 'deepHash($name)';
  }

  final nullable = field.isNullableType;
  final bang = nullable ? '!' : '';

  if (field.isListOrIterableType) {
    final expr = 'Object.hashAll($name$bang)';
    return nullable ? '$name == null ? null : $expr' : expr;
  }

  if (field.isSetType) {
    final expr = 'Object.hashAllUnordered($name$bang)';
    return nullable ? '$name == null ? null : $expr' : expr;
  }

  if (field.isMapType) {
    final expr =
        'Object.hashAllUnordered($name$bang.entries.map((e) => Object.hash(e.key, e.value)))';
    return nullable ? '$name == null ? null : $expr' : expr;
  }

  return name;
}

/// Generates an `operator ==` override for the given [className] and [fields].
///
/// If [deepCollectionEquality] is explicit `false`, generates pure dart
/// shallow equality for collections. If `true` or `null` (defer to global config),
/// generates calls to `AnalyzerKit.deepEquals`.
String generateEqualityOperatorOverride(
  String className,
  Iterable<ClassField> fields, {
  String typeArguments = '',
  bool? deepCollectionEquality,
}) {
  final comparisons = fields.isEmpty
      ? ''
      : '&& ${fields.map((f) => _equalityExpression(f, deepCollectionEquality: deepCollectionEquality)).join(' && ')}';

  final statements = <Code>[
    Code(''),
    Code('if (identical(this, other)) return true;'),
    Code('return other is $className$typeArguments $comparisons;'),
    Code(''),
  ];

  final override = Method(
    (b) => b
      ..annotations.add(refer('override'))
      ..returns = refer('bool')
      ..name = FeatureMethod.operatorEquals.name
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'other'
            ..type = refer('Object'),
        ),
      )
      ..body = Block.of(statements),
  );

  return '${override.accept(_dartEmitter)}';
}

/// Returns the equality comparison expression for a single [field].
String _equalityExpression(ClassField field, {bool? deepCollectionEquality}) {
  final name = field.name;

  if (field.isCollectionType && deepCollectionEquality != false) {
    return 'deepEquals(other.$name, $name)';
  }

  final nullable = field.isNullableType;
  final bang = nullable ? '!' : '';

  if (field.isListType) {
    final expr =
        'other.$name$bang.length == $name$bang.length '
        '&& () { for (var i = 0; i < $name$bang.length; i++) { '
        'if (other.$name$bang[i] != $name$bang[i]) return false; } '
        'return true; }()';
    return nullable
        ? '(identical(other.$name, $name) || (other.$name != null && $name != null && $expr))'
        : expr;
  }

  if (field.isIterableType) {
    final expr =
        '() { final it1 = other.$name$bang.iterator; '
        'final it2 = $name$bang.iterator; '
        'while (it1.moveNext()) { '
        'if (!it2.moveNext() || it1.current != it2.current) return false; } '
        'return !it2.moveNext(); }()';
    return nullable
        ? '(identical(other.$name, $name) || (other.$name != null && $name != null && $expr))'
        : expr;
  }

  if (field.isSetType) {
    final expr =
        'other.$name$bang.length == $name$bang.length '
        '&& other.$name$bang.containsAll($name$bang)';
    return nullable
        ? '(identical(other.$name, $name) || (other.$name != null && $name != null && $expr))'
        : expr;
  }

  if (field.isMapType) {
    final expr =
        'other.$name$bang.length == $name$bang.length '
        '&& $name$bang.entries.every((e) => other.$name$bang[e.key] == e.value)';
    return nullable
        ? '(identical(other.$name, $name) || (other.$name != null && $name != null && $expr))'
        : expr;
  }

  return 'other.$name == $name';
}

/// Generates a serialization method for the given [fields] and [methodName].
String generateSerializeMethod(
  String methodName,
  Iterable<ClassField> fields, {
  bool format = true,
}) {
  final entries = fields
      .map((f) => "'${f.name}': ${_serializeExpression(f, f.name)}")
      .join(', ');

  final method = Method(
    (b) => b
      ..name = methodName
      ..lambda = true
      ..returns = refer('Map<String, dynamic>')
      ..body = Code('{$entries};'),
  );

  final raw = '${method.accept(_dartEmitter)}';
  return format ? formatCode(raw) : raw;
}

/// Generates a deserialization factory/method for the given [className], [fields], and [methodName].
String generateDeserializeMethod(
  String className,
  String methodName,
  Iterable<ClassField> fields, {
  String? constructorName,
  String typeArguments = '',
  bool format = true,
}) {
  final assignments = fields
      .where((f) => f.isConstructorParam)
      .map((f) {
        final expr = _deserializeExpression(f, "map['${f.name}']");
        return f.isPositional ? expr : '${f.name}: $expr';
      })
      .join(',\n');

  final fullClassName = '$className$typeArguments';
  final target = constructorName != null
      ? '$fullClassName.$constructorName'
      : fullClassName;

  final code =
      '''
factory $className.$methodName(Map<String, dynamic> map) {
  return $target(
    $assignments
  );
}
''';

  return format ? formatConstructor(code) : code;
}

bool _needsSerializeTransform(ClassField? field) =>
    field != null &&
    (field.isDateTimeType ||
        field.isUriType ||
        field.isDurationType ||
        field.isBigIntType ||
        field.isEnumType ||
        field.isCollectionType ||
        field.serializeMethodName != null);

bool _needsDeserializeTransform(ClassField? field) =>
    field != null &&
    (field.isDateTimeType ||
        field.isUriType ||
        field.isDurationType ||
        field.isBigIntType ||
        field.isDoubleType ||
        field.isEnumType ||
        field.isCollectionType ||
        field.deserializeMethodName != null);

String _serializeExpression(ClassField field, String expr) {
  final nullable = field.isNullableType;
  final q = nullable ? '?' : '';

  if (field.isDateTimeType) {
    return '$expr$q.toIso8601String()';
  }
  if (field.isUriType || field.isBigIntType) {
    return '$expr$q.toString()';
  }
  if (field.isDurationType) {
    return '$expr$q.inMicroseconds';
  }
  if (field.isEnumType) {
    return '$expr$q.name';
  }
  if (field.serializeMethodName case final serMethod?) {
    return '$expr$q.$serMethod()';
  }
  if (field.isListOrIterableType || field.isSetType) {
    final elem = field.resolvedTypeArguments.firstOrNull;
    if (_needsSerializeTransform(elem)) {
      return '$expr$q.map((e) => ${_serializeExpression(elem!, 'e')}).toList()';
    }
    if (field.isSetType || field.isIterableType) {
      return '$expr$q.toList()';
    }
    return expr;
  }
  if (field.isMapType) {
    final args = field.resolvedTypeArguments;
    final keyField = args.elementAtOrNull(0);
    final valField = args.elementAtOrNull(1);
    if (_needsSerializeTransform(keyField) ||
        _needsSerializeTransform(valField)) {
      final kExpr = keyField != null && _needsSerializeTransform(keyField)
          ? _serializeExpression(keyField, 'k')
          : 'k';
      final vExpr = valField != null && _needsSerializeTransform(valField)
          ? _serializeExpression(valField, 'v')
          : 'v';
      return '$expr$q.map((k, v) => MapEntry($kExpr, $vExpr))';
    }
    return expr;
  }
  return expr;
}

String _deserializeExpression(ClassField field, String expr) {
  final nullable = field.isNullableType;
  final q = nullable ? '?' : '';

  if (field.isDoubleType) {
    return nullable
        ? '($expr as num?)?.toDouble()'
        : '($expr as num).toDouble()';
  }
  if (field.isDateTimeType) {
    return nullable
        ? '$expr != null ? DateTime.parse($expr as String) : null'
        : 'DateTime.parse($expr as String)';
  }
  if (field.isUriType) {
    return nullable
        ? '$expr != null ? Uri.parse($expr as String) : null'
        : 'Uri.parse($expr as String)';
  }
  if (field.isDurationType) {
    return nullable
        ? '$expr != null ? Duration(microseconds: $expr as int) : null'
        : 'Duration(microseconds: $expr as int)';
  }
  if (field.isBigIntType) {
    return nullable
        ? '$expr != null ? BigInt.parse($expr as String) : null'
        : 'BigInt.parse($expr as String)';
  }
  if (field.isEnumType) {
    final enumType = field.nonNullableType;
    return nullable
        ? '$enumType.values.asNameMap()[$expr]'
        : '$enumType.values.byName($expr as String)';
  }
  if (field.deserializeMethodName case final deserMethod?) {
    final targetType = field.nonNullableType;
    return nullable
        ? '$expr != null ? $targetType.$deserMethod($expr as Map<String, dynamic>) : null'
        : '$targetType.$deserMethod($expr as Map<String, dynamic>)';
  }
  if (field.isListOrIterableType || field.isSetType) {
    final elem = field.resolvedTypeArguments.firstOrNull;
    final listBase = '($expr as List<dynamic>$q)$q';
    if (_needsDeserializeTransform(elem)) {
      final mapped =
          '$listBase.map((e) => ${_deserializeExpression(elem!, 'e')})';
      if (field.isSetType) return '$mapped.toSet()';
      if (field.isListType) return '$mapped.toList()';
      return mapped;
    }
    if (elem != null && elem.type != 'dynamic') {
      final castExpr = '$listBase.cast<${elem.type}>()';
      return field.isSetType ? '$castExpr.toSet()' : castExpr;
    }
    return field.isSetType ? '$listBase.toSet()' : '$expr as ${field.type}';
  }
  if (field.isMapType) {
    final args = field.resolvedTypeArguments;
    final keyField = args.elementAtOrNull(0);
    final valField = args.elementAtOrNull(1);
    final mapBase = '($expr as Map<String, dynamic>$q)$q';
    if (_needsDeserializeTransform(keyField) ||
        _needsDeserializeTransform(valField)) {
      final kExpr = keyField != null && _needsDeserializeTransform(keyField)
          ? _deserializeExpression(keyField, 'k')
          : (keyField != null && keyField.type != 'dynamic'
                ? 'k as ${keyField.type}'
                : 'k');
      final vExpr = valField != null && _needsDeserializeTransform(valField)
          ? _deserializeExpression(valField, 'v')
          : (valField != null && valField.type != 'dynamic'
                ? 'v as ${valField.type}'
                : 'v');
      return '$mapBase.map((k, v) => MapEntry($kExpr, $vExpr))';
    }
    if (keyField != null &&
        valField != null &&
        (keyField.type != 'dynamic' || valField.type != 'dynamic')) {
      return '$mapBase.cast<${keyField.type}, ${valField.type}>()';
    }
    return '$expr as ${field.type}';
  }
  return '$expr as ${field.type}';
}
