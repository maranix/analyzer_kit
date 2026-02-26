import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

/// Quick fix that generates a `toString` override for classes annotated
/// with `@OverrideToString`.
final class OverrideToStringMethod extends ResolvedCorrectionProducer {
  OverrideToStringMethod({required super.context});

  static const _fix = FixKind(
    'dart.fix.overrideToString',
    DartFixKindPriority.standard,
    'Override `toString` method',
  );

  @override
  FixKind get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    if (hasFeatureEnabled(declaration, .overrideToString)) {
      final fields = extractGeneratableFields(declaration);

      await builder.addDartFileEdit(file, (fileEditBuilder) {
        fileEditBuilder.insertMethod(declaration, (editBuilder) {
          editBuilder.write(
            generateToStringMethod(declaration.name.lexeme, fields),
          );
        });
      });
    }
  }
}
