import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Quick fix that generates a deserialization  method for classes annotated
/// with `@Deserialize`.
final class AddDeserializeMethod extends ResolvedCorrectionProducer {
  AddDeserializeMethod({required super.context});

  static const _fix = FixKind(
    'dart.fix.addDeserializeMethod',
    DartFixKindPriority.standard,
    'Add deserialization factory/method',
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

    final methodName = extractFeatureMethodName(
      declaration,
      FeatureAnnotation.deserialize,
      'fromMap',
    );

    if (methodName != null) {
      final fields = extractGeneratableFields(declaration);

      await builder.addDartFileEdit(file, (fileEditBuilder) {
        fileEditBuilder.insertMethod(declaration, (editBuilder) {
          editBuilder.write(
            generateDeserializeMethod(
              declaration.namePart.typeName.lexeme,
              methodName,
              fields,
            ),
          );
        });
      });
    }
  }
}
