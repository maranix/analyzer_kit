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
