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

/// Quick fix that generates or updates a serialization method for classes
/// annotated with `@Serialize`.
base class AddSerializeMethod extends ResolvedCorrectionProducer {
  AddSerializeMethod({required super.context});

  static const _fix = FixKind(
    'dart.fix.addSerializeMethod',
    DartFixKindPriority.standard,
    'Add or update serialization method',
  );

  @override
  FixKind? get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final methodName = extractFeatureMethodName(
      declaration,
      FeatureAnnotation.serialize,
      'toMap',
    );

    if (methodName != null) {
      final fields = fieldsForFeature(
        extractGeneratableFields(declaration),
        FeatureAnnotation.serialize,
      );
      if (fields.isEmpty) return;
      final existing = findMethodDeclaration(declaration, methodName);
      final generated = generateSerializeMethod(methodName, fields);

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

/// Assist that force-regenerates the serialization method on `@Serialize`
/// classes.
final class RegenerateSerializeMethod extends AddSerializeMethod {
  RegenerateSerializeMethod({required super.context});

  static const _assist = AssistKind(
    'dart.assist.regenerateSerializeMethod',
    30,
    'Regenerate serialization method',
  );

  @override
  AssistKind? get assistKind => _assist;
}
