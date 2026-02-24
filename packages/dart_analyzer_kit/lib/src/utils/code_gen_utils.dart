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
String generateHashCodeOverride(Iterable<ClassField> fields) {
  final override = Method(
    (b) => b
      ..type = .getter
      ..annotations.add(refer('override'))
      ..returns = refer('int')
      ..name = MethodNames.overrideHashCode
      ..lambda = true
      ..body = refer(
        'Object.hashAll',
      ).call([literalList(fields.map((f) => refer(f.name)))]).statement,
  );

  return formatCode('${override.accept(_dartEmitter)}');
}

/// Generates an `operator ==` override for the given [className] and [fields].
String generateEqualityOperatorOverride(
  String className,
  Iterable<ClassField> fields,
) {
  final comparisons = fields.isEmpty
      ? ''
      : '&& ${fields.map((f) => 'other.${f.name} == ${f.name}').join(' && ')}';

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
