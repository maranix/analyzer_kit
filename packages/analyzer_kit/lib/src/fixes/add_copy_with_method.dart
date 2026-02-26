import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

/// Quick fix that generates a `copyWith` method for classes annotated
/// with `@CopyWith`.
final class AddCopyWithMethod extends ResolvedCorrectionProducer {
  AddCopyWithMethod({required super.context});

  static const _fix = FixKind(
    'dart.fix.addCopyWithMethod',
    DartFixKindPriority.standard,
    'Add `copyWith` method',
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

    if (hasFeatureEnabled(declaration, FeatureAnnotation.copyWith)) {
      final fields = extractGeneratableFields(declaration);
      if (fields.isEmpty) return;

      await builder.addDartFileEdit(file, (fileEditBuilder) {
        fileEditBuilder.insertMethod(declaration, (editBuilder) {
          editBuilder.write(
            generateCopyWithMethod(declaration.name.lexeme, fields),
          );
        });
      });
    }
  }
}
