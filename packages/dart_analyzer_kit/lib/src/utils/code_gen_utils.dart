import 'package:code_builder/code_builder.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_analyzer_kit/src/constants.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

String generateCopyWithMethod(String className, Iterable<ClassField> fields) {
  final namedArgs = <String, Expression>{};
  final functionParams = <Parameter>[];

  for (final field in fields) {
    functionParams.add(
      Parameter(
        (b) => b
          ..name = field.name
          ..named = true
          ..type = refer("${field.type}?"),
      ),
    );

    namedArgs[field.name] = refer(
      field.name,
    ).ifNullThen(refer('this.${field.name}'));
  }

  final method = Method(
    (b) => b
      ..name = MethodConstants.copyWith
      ..optionalParameters.addAll(functionParams)
      ..lambda = true
      ..body = refer(className).call(const [], namedArgs).statement
      ..returns = refer(className),
  );

  return formatCode("${method.accept(dartEmitter)}");
}

String generateSerializeMethod(Iterable<ClassField> fields) {
  final jsonMap = <String, Expression>{
    for (final field in fields) field.name: refer(field.name),
  };

  final method = Method(
    (m) => m
      ..name = MethodConstants.toMap
      ..lambda = true
      ..body = literalMap(jsonMap).statement
      ..returns = refer("Map<String, dynamic>"),
  );

  return formatCode("${method.accept(dartEmitter)}");
}

String generateToStringMethod(String className, Iterable<ClassField> fields) {
  final body = literalString(
    "$className(${fields.map((f) => '${f.name}: \$${f.name}').join(', ')})",
  );

  final method = Method(
    (b) => b
      ..name = MethodConstants.overrideToString
      ..lambda = true
      ..annotations.add(refer('override'))
      ..body = body.statement
      ..returns = refer("String"),
  );

  return formatCode("${method.accept(dartEmitter)}");
}

String generateHashCodeOverride(Iterable<ClassField> fields) {
  final override = Method(
    (b) => b
      ..type = .getter
      ..annotations.add(refer("override"))
      ..returns = refer("int")
      ..name = MethodConstants.overrideHashCode
      ..lambda = true
      ..body = refer(
        'Object.hashAll',
      ).call([literalList(fields.map((f) => refer(f.name)))]).statement,
  );

  return formatCode("${override.accept(dartEmitter)}");
}

String generateEqualityOperatorOverride(
  String className,
  Iterable<ClassField> fields,
) {
  final comparisons = fields.isEmpty
      ? ""
      : "&& ${fields.map((f) => "other.${f.name} == ${f.name}").join(" && ")}";

  final statements = <Code>[
    Code(""),
    Code("if (identical(this, other)) return true;"),
    Code("return other is $className $comparisons;"),
    Code(""),
  ];

  final override = Method(
    (b) => b
      ..annotations.add(refer("override"))
      ..returns = refer("bool")
      ..name = MethodConstants.operatorEquals
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = "other"
            ..type = refer("Object"),
        ),
      )
      ..body = Block.of(statements),
  );

  // Cannot run format here because `==` override expects to be inside a class
  // Which isn't the case here since we are generating it outside of a class manually.
  return "${override.accept(dartEmitter)}";
}
