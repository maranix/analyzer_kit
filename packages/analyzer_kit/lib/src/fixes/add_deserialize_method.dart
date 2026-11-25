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

/// Quick fix that generates or updates a deserialization factory/method for
/// classes annotated with `@Deserialize`.
base class AddDeserializeMethod extends ResolvedCorrectionProducer {
  AddDeserializeMethod({required super.context});

  static const _fix = FixKind(
    'dart.fix.addDeserializeMethod',
    DartFixKindPriority.standard,
    'Add or update deserialization factory/method',
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
      FeatureAnnotation.deserialize,
      'fromMap',
    );

    if (methodName != null) {
      final fields = extractGeneratableFields(declaration);
      final existing = findDeserializeMember(declaration, methodName);
      final generated = generateDeserializeMethod(
        declaration.namePart.typeName.lexeme,
        methodName,
        fields,
        constructorName: extractPrimaryConstructorName(declaration),
        typeArguments: extractTypeArguments(declaration),
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

/// Assist that force-regenerates the deserialization factory/method on
/// `@Deserialize` classes.
final class RegenerateDeserializeMethod extends AddDeserializeMethod {
  RegenerateDeserializeMethod({required super.context});

  static const _assist = AssistKind(
    'dart.assist.regenerateDeserializeMethod',
    30,
    'Regenerate deserialization factory/method',
  );

  @override
  AssistKind? get assistKind => _assist;
}
