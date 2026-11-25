import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Quick fix that generates or updates a `toString` override for classes
/// annotated with `@OverrideToString`.
base class OverrideToStringMethod extends ResolvedCorrectionProducer {
  OverrideToStringMethod({required super.context});

  static const _fix = FixKind(
    'dart.fix.overrideToString',
    DartFixKindPriority.standard,
    'Add or update `toString` method',
  );

  @override
  FixKind get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final config = extractAnnotationConfig(declaration);
    if (config.overrideToString) {
      final fields = extractGeneratableFields(declaration);
      final existing = findMethodDeclaration(
        declaration,
        FeatureMethod.overrideToString.name,
      );
      final generated = generateToStringMethod(
        declaration.namePart.typeName.lexeme,
        fields,
        multiline: config.overrideToStringMultiline,
      );

      await builder.addDartFileEdit(file, (fileEditBuilder) {
        if (existing != null) {
          fileEditBuilder.addSimpleReplacement(
            range.node(existing),
            generated.trimRight(),
          );
        } else {
          fileEditBuilder.insertMethod(declaration, (editBuilder) {
            editBuilder.write(generated);
          });
        }
      });
    }
  }
}

/// Assist that force-regenerates `toString` on `@OverrideToString` classes.
final class RegenerateToStringMethod extends OverrideToStringMethod {
  RegenerateToStringMethod({required super.context});

  static const _assist = AssistKind(
    'dart.assist.regenerateToStringMethod',
    30,
    'Regenerate `toString` method',
  );

  @override
  AssistKind? get assistKind => _assist;
}
