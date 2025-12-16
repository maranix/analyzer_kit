import 'package:code_builder/code_builder.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

String generateCopyWithMethod(String className, Iterable<ClassField> fields) {
  final codeBuf = StringBuffer('$className copyWith({');

  for (final (i, field) in fields.indexed) {
    final type = field.type;
    final fieldName = field.name;
    final trailingComma = i < fields.length - 1 ? ',' : '';

    // Avoid double-nullable types like `String??`
    final paramType = type.endsWith('?') ? type : '$type?';

    codeBuf.writeln("$paramType $fieldName$trailingComma");
  }

  codeBuf.writeln('}) {');

  codeBuf.write('return $className(');

  for (final (i, field) in fields.indexed) {
    final fieldName = field.name;
    final trailingComma = i < fields.length - 1 ? ',' : '';

    codeBuf.writeln('$fieldName: $fieldName ?? this.$fieldName$trailingComma');
  }

  codeBuf.writeln(');');
  codeBuf.writeln('}');

  return formatCode(codeBuf.toString());
}

String generateSerializeMethod(Iterable<ClassField> fields) {
  final codeBuf = StringBuffer('Map<String, dynamic> toMap() => {');

  for (final (i, field) in fields.indexed) {
    final name = field.name;
    final trailingComma = i < fields.length - 1 ? "," : "";

    codeBuf.writeln("'$name': $name$trailingComma");
  }
  codeBuf.writeln("};");

  return formatCode(codeBuf.toString());
}

String generateToStringMethod(String className, Iterable<ClassField> fields) {
  final bodyBuf = StringBuffer("\"$className(");

  for (final (i, field) in fields.indexed) {
    final name = field.name;
    final trailingComma = i < fields.length - 1 ? "," : "";
    final space = i > 0 ? " " : "";

    bodyBuf.write("$space$name: \$$name$trailingComma");
  }

  bodyBuf.write(")\";");

  final method = Method(
    (b) => b
      ..name = "toString"
      ..lambda = true
      ..annotations.add(refer('override'))
      ..body = Code(bodyBuf.toString())
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
      ..name = "hashCode"
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
  final codeBuf = StringBuffer("\nif (identical(this, other)) return true;");

  codeBuf.writeln();
  codeBuf.writeln("return other is $className");
  codeBuf.writeln();

  for (final field in fields) {
    codeBuf.writeln("&& other.${field.name} == ${field.name}");
    codeBuf.writeln();
  }

  codeBuf.write(';');

  final override = Method(
    (b) => b
      ..annotations.add(refer("override"))
      ..returns = refer("bool")
      ..name = "operator =="
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = "other"
            ..type = refer("Object"),
        ),
      )
      ..body = Code(codeBuf.toString()),
  );

  // Cannot run format here because `==` override expects to be inside a class
  // Which isn't the case here since we are generating it outside of a class manually.
  return "${override.accept(dartEmitter)}";
}
