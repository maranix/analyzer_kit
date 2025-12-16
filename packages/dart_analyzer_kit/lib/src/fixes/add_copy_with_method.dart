import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/utils/code_gen_utils.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart'
    show hasAnnotation, hasMethod;

final class AddCopyWithMethod extends ResolvedCorrectionProducer {
  AddCopyWithMethod({required super.context});

  static const _fix = FixKind(
    'dart.fix.addCopyWithMethod',
    DartFixKindPriority.standard,
    "Add `copyWith` method",
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

    final fragment = declaration.declaredFragment;
    if (fragment == null) return;

    final element = fragment.element;

    if (!hasAnnotation(element, Annotations.copyWith)) return;
    if (hasMethod(element, "copyWith")) return;

    final hasGenerativeConstructor = element.constructors.any(
      (c) => c.isGenerative,
    );
    if (!hasGenerativeConstructor) return;

    final fields = element.fields.where(
      (f) => f.isPublic && !f.isLate && !f.isStatic && !f.isSynthetic,
    );
    if (fields.isEmpty) return;

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      fileEditBuilder.insertMethod(declaration, (editBuilder) {
        editBuilder.write(generateCopyWithMethod(element));
      });
    });
  }
}
