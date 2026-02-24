import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, FieldDeclaration;
import 'package:code_builder/code_builder.dart';
import 'package:dart_analyzer_kit/src/constants.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_style/dart_style.dart';

part 'code_gen_utils.dart';
part 'code_utils.dart';
part 'string_utils.dart';

/// Extracts generatable fields from a [ClassDeclaration].
Iterable<ClassField> extractGeneratableFields(ClassDeclaration declaration) {
  return declaration.members
      .map(
        (m) =>
            m is FieldDeclaration ? ClassField.fromFieldDeclaration(m) : null,
      )
      .nonNulls
      .where((f) => f.isGeneratable);
}
