part of 'utils.dart';

/// Generates a `copyWith` method for the given [className] and [fields].
String generateCopyWithMethod(
  String className,
  Iterable<ClassField> fields, {
  String? constructorName,
}) {
  final positionalArgs = <Expression>[];
  final namedArgs = <String, Expression>{};
  final functionParams = <Parameter>[];

  for (final field in fields) {
    final paramType = field.isNullableType ? field.type : '${field.type}?';
    functionParams.add(
      Parameter(
        (b) => b
          ..name = field.name
          ..named = true
          ..type = refer(paramType),
      ),
    );

    final argExpr = refer(field.name).ifNullThen(refer('this.${field.name}'));
    if (field.isPositional) {
      positionalArgs.add(argExpr);
    } else {
      namedArgs[field.name] = argExpr;
    }
  }

  final target = constructorName != null
      ? '$className.$constructorName'
      : className;

  final method = Method(
    (b) => b
      ..name = FeatureMethod.copyWith.name
      ..optionalParameters.addAll(functionParams)
      ..lambda = true
      ..body = refer(target).call(positionalArgs, namedArgs).statement
      ..returns = refer(className),
  );

  return formatCode('${method.accept(_dartEmitter)}');
}

/// Generates a `toString` override for the given [className] and [fields].
String generateToStringMethod(String className, Iterable<ClassField> fields) {
  final body = literalString(
    '$className(${fields.map((f) => '${f.name}: \$${f.name}').join(', ')})',
  );

  final method = Method(
    (b) => b
      ..name = FeatureMethod.overrideToString.name
      ..lambda = true
      ..annotations.add(refer('override'))
      ..body = body.statement
      ..returns = refer('String'),
  );

  return formatCode('${method.accept(_dartEmitter)}');
}

/// Generates a `hashCode` getter override for the given [fields].
///
/// If [deepCollectionEquality] is explicit `false`, generates pure dart
/// shallow hashing for collections. If `true` or `null` (defer to global config),
/// generates calls to `AnalyzerKit.deepHash`.
String generateHashCodeOverride(
  Iterable<ClassField> fields, {
  bool? deepCollectionEquality,
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

  return formatCode('${override.accept(_dartEmitter)}');
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
  bool? deepCollectionEquality,
}) {
  final comparisons = fields.isEmpty
      ? ''
      : '&& ${fields.map((f) => _equalityExpression(f, deepCollectionEquality: deepCollectionEquality)).join(' && ')}';

  final statements = <Code>[
    Code(''),
    Code('if (identical(this, other)) return true;'),
    Code('return other is $className $comparisons;'),
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
String generateSerializeMethod(String methodName, Iterable<ClassField> fields) {
  final entries = fields.map((f) => "'${f.name}': ${f.name}").join(', ');

  final method = Method(
    (b) => b
      ..name = methodName
      ..lambda = true
      ..returns = refer('Map<String, dynamic>')
      ..body = Code('{$entries};'),
  );

  return formatCode('${method.accept(_dartEmitter)}');
}

/// Generates a deserialization factory/method for the given [className], [fields], and [methodName].
String generateDeserializeMethod(
  String className,
  String methodName,
  Iterable<ClassField> fields, {
  String? constructorName,
}) {
  final assignments = fields
      .map(
        (f) => f.isPositional
            ? "map['${f.name}'] as ${f.type}"
            : "${f.name}: map['${f.name}'] as ${f.type}",
      )
      .join(',\n');

  final target = constructorName != null
      ? '$className.$constructorName'
      : className;

  final code =
      '''
factory $className.$methodName(Map<String, dynamic> map) {
  return $target(
    $assignments
  );
}
''';

  return formatConstructor(code);
}
