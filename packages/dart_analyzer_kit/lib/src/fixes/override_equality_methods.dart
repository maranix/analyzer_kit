import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_analyzer_kit/src/utils/code_gen_utils.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class OverrideEqualityMethods extends ResolvedCorrectionProducer {
  OverrideEqualityMethods({required super.context});

  static const _fix = FixKind(
    "dart.fix.overrideEquality",
    100,
    "Override `==` and `hashCode`",
  );

  @override
  FixKind get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

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

    final hasHashCodeOverride = declaration.hasGetter("hashCode");
    final hasEqualityOperatorOverride = declaration.hasMethod("==");

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      fileEditBuilder.insertMethod(declaration, (editBuilder) {
        if (!hasHashCodeOverride) {
          editBuilder.writeln(generateHashCodeOverride(fields));
        }

        if (!hasEqualityOperatorOverride) {
          editBuilder.writeln(
            generateEqualityOperatorOverride(declaration.name.lexeme, fields),
          );
        }
      });
    });
  }
}
