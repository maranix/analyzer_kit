import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import '../utils/utils.dart' show hasAnnotation, hasMethod;

final class AddCopyWithMethod extends ResolvedCorrectionProducer {
  AddCopyWithMethod({required super.context});

  static const _fix = FixKind(
    'dart.fix.addCopyWithMethod',
    DartFixKindPriority.standard,
    "Add copyWith method in annotated class",
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

    if (!hasAnnotation(element, .copyWith)) return;
    if (hasMethod(element, "copyWith")) return;

    final hasGenerativeConstructor = element.constructors.any(
      (c) => c.isGenerative,
    );
    if (!hasGenerativeConstructor) return;

    final fields = element.fields.where((f) => !f.isStatic && !f.isSynthetic);
    if (fields.isEmpty) return;

    final className = element.displayName;

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      fileEditBuilder.insertMethod(declaration, (editBuilder) {
        editBuilder.write('$className copyWith({');

        for (final (i, field) in fields.indexed) {
          final type = field.type;
          final fieldName = field.displayName;
          final trailingComma = i < fields.length - 1 ? ',' : '';

          editBuilder.writeln("$type? $fieldName$trailingComma");
        }

        editBuilder.writeln('}) {');

        editBuilder.write('return $className(');

        for (final (i, field) in fields.indexed) {
          final fieldName = field.displayName;
          final trailingComma = i < fields.length - 1 ? ',' : '';

          editBuilder.writeln(
            '$fieldName: $fieldName ?? this.$fieldName$trailingComma',
          );
        }

        editBuilder.writeln(');');
        editBuilder.writeln('}');
      });
    });
  }
}
