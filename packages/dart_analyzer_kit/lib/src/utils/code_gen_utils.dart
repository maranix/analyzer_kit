part of 'utils.dart';

/// Generates a `copyWith` method for the given [className] and [fields].
String generateCopyWithMethod(String className, Iterable<ClassField> fields) {
  final namedArgs = <String, Expression>{};
  final functionParams = <Parameter>[];

  for (final field in fields) {
    functionParams.add(
      Parameter(
        (b) => b
          ..name = field.name
          ..named = true
          ..type = refer('${field.type}?'),
      ),
    );

    namedArgs[field.name] = refer(
      field.name,
    ).ifNullThen(refer('this.${field.name}'));
  }

  final method = Method(
    (b) => b
      ..name = MethodNames.copyWith
      ..optionalParameters.addAll(functionParams)
      ..lambda = true
      ..body = refer(className).call(const [], namedArgs).statement
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
      ..name = MethodNames.overrideToString
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
  final hashElements = fields
      .map(
        (f) =>
            _hashExpression(f, deepCollectionEquality: deepCollectionEquality),
      )
      .join(', ');

  final override = Method(
    (b) => b
      ..type = .getter
      ..annotations.add(refer('override'))
      ..returns = refer('int')
      ..name = MethodNames.overrideHashCode
      ..lambda = true
      ..body = Code('Object.hashAll([$hashElements]);'),
  );

  return formatCode('${override.accept(_dartEmitter)}');
}

/// Returns the hash expression for a single [field].
String _hashExpression(ClassField field, {bool? deepCollectionEquality}) {
  final name = field.name;

  if (field.isCollectionType && deepCollectionEquality != false) {
    return 'AnalyzerKit.deepHash($name)';
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
      ..name = MethodNames.operatorEquals
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
    return 'AnalyzerKit.deepEquals(other.$name, $name)';
  }

  final nullable = field.isNullableType;
  final bang = nullable ? '!' : '';

  if (field.isListOrIterableType) {
    final expr =
        'other.$name$bang.length == $name$bang.length '
        '&& $name$bang.indexed.every((e) => other.$name$bang[e.\$1] == e.\$2)';
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
