import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_analyzer_kit/src/utils/code_gen_utils.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

void main() async {
  final source = """
@copyWith
@debugString
final class User {
  User({required this.name});

  static final someVar = "someVlaue";
  static final _someVar = "someVlaue";

  late final String someLateVar;

  final _private = "value";

  static const p = "sadsd";

  final String name;
}
""";

  final result = parseString(content: source);

  result.unit.accept(_AnnotationVisitor());
}

final class _AnnotationVisitor extends GeneralizingAstVisitor<void> {
  @override
  void visitAnnotation(Annotation node) {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    if (!declaration.hasAnnotation(.debugString)) return;
    print("Found Anotation");
    if (declaration.hasMethod("toString")) return;
    print("Method not found");

    final fields = declaration.fields
        .map(ClassField.fromFieldDeclaration)
        .where(
          (f) =>
              f.isPublic &&
              !f.isConst &&
              !f.isStatic &&
              !f.isSynthetic &&
              !f.isLate,
        );

    print(generateToStringMethod(declaration.name.lexeme, fields));
  }
}
