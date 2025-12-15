import 'package:analyzer/dart/element/element.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

String generateCopyWithMethod(ClassElement element) {
  final fields = element.fields.where((f) => !f.isStatic && !f.isSynthetic);
  final className = element.displayName;

  final codeBuf = StringBuffer('$className copyWith({');

  for (final (i, field) in fields.indexed) {
    final type = field.type;
    final fieldName = field.displayName;
    final trailingComma = i < fields.length - 1 ? ',' : '';

    // Avoid double-nullable types like `String??`
    final typeStr = type.getDisplayString();
    final paramType = typeStr.endsWith('?') ? typeStr : '$typeStr?';

    codeBuf.writeln("$paramType $fieldName$trailingComma");
  }

  codeBuf.writeln('}) {');

  codeBuf.write('return $className(');

  for (final (i, field) in fields.indexed) {
    final fieldName = field.displayName;
    final trailingComma = i < fields.length - 1 ? ',' : '';

    codeBuf.writeln('$fieldName: $fieldName ?? this.$fieldName$trailingComma');
  }

  codeBuf.writeln(');');
  codeBuf.writeln('}');

  return formatCode(codeBuf.toString());
}
