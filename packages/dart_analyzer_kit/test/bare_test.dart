import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_analyzer_kit/src/utils/code_gen_utils.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

void main() async {
  final source = """
@copyWith
final class User {
  User({required this.name, required this.age});

  final String name;
  final int age;
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

    final className = declaration.name.lexeme;

    // final hasEqualityOverride = declaration.hasMethod("==");
    // final hasHashCodeOverride = declaration.hasGetter("hashCode");
    //
    // print("Equality: $hasEqualityOverride");
    // print("HashCode: $hasHashCodeOverride");

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

    print(generateEqualityOperatorOverride(className, fields));

    // print(generateHashCodeOverride(fields));
    // print(generateEqualityOperatorOverride(declaration.name.lexeme, fields));
  }
}
