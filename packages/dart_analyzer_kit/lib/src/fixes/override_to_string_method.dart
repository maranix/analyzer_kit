import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_analyzer_kit/src/utils/code_gen_utils.dart';

final class OverrideToStringMethod extends ResolvedCorrectionProducer {
  OverrideToStringMethod({required super.context});

  static const _fix = FixKind(
    "dart.fix.overrideToString",
    100,
    "Override `toString` method",
  );

  @override
  FixKind get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final fields = declaration.members
        .map(
          (m) =>
              m is FieldDeclaration ? ClassField.fromFieldDeclaration(m) : null,
        )
        .nonNulls
        .where((fd) => fd.isGeneratable);

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      fileEditBuilder.insertMethod(declaration, (editBuilder) {
        editBuilder.write(
          generateToStringMethod(declaration.name.lexeme, fields),
        );
      });
    });
  }
}
