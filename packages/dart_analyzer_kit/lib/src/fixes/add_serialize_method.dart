import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:dart_analyzer_kit/src/types.dart' show ClassField;
import 'package:dart_analyzer_kit/src/utils/code_gen_utils.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart'
    show ClassDeclarationExtension;

final class AddSerializeMethod extends ResolvedCorrectionProducer {
  AddSerializeMethod({required super.context});

  static const _fix = FixKind(
    "dart.fix.addSerializeMethod",
    DartFixKindPriority.standard,
    "Add `toMap` method",
  );

  @override
  FixKind? get fixKind => _fix;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    if (!declaration.hasAnnotation(.serialize)) return;
    if (declaration.hasMethod("toMap")) return;

    final fields = declaration.fields
        .map(ClassField.fromFieldDeclaration)
        .where(
          (cf) =>
              cf.isPublic &&
              !cf.isConst &&
              !cf.isLate &&
              !cf.isStatic &&
              !cf.isSynthetic,
        );

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      fileEditBuilder.insertMethod(declaration, (editBuilder) {
        editBuilder.write(generateSerializeMethod(fields));
      });
    });
  }
}
