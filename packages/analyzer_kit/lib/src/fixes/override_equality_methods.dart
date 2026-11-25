import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Quick fix that generates `==` operator and `hashCode` overrides for
/// classes annotated with `@OverrideEquality`.
final class OverrideEqualityMethods extends ResolvedCorrectionProducer {
  OverrideEqualityMethods({required super.context});

  static const _fix = FixKind(
    'dart.fix.overrideEquality',
    DartFixKindPriority.standard,
    'Override `==` and `hashCode`',
  );

  @override
  FixKind get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    if (hasFeatureEnabled(declaration, FeatureAnnotation.overrideEquality)) {
      final deepCollectionEquality = extractDeepCollectionEquality(declaration);

      var hasHashCodeOverride = false;
      var hasEqualityOperatorOverride = false;
      for (final m in declaration.body.members) {
        if (m is MethodDeclaration) {
          final name = m.name.lexeme;
          if (name == FeatureMethod.overrideHashCode.name) {
            hasHashCodeOverride = true;
          } else if (name == FeatureMethod.operatorEquals.name) {
            hasEqualityOperatorOverride = true;
          }
        }
      }

      final fields = extractGeneratableFields(declaration);
      if (fields.isEmpty) return;

      await builder.addDartFileEdit(file, (fileEditBuilder) {
        fileEditBuilder.insertMethod(declaration, (editBuilder) {
          if (!hasHashCodeOverride) {
            editBuilder.writeln(
              generateHashCodeOverride(
                fields,
                deepCollectionEquality: deepCollectionEquality,
              ),
            );
          }

          if (!hasEqualityOperatorOverride) {
            editBuilder.writeln(
              generateEqualityOperatorOverride(
                declaration.namePart.typeName.lexeme,
                fields,
                deepCollectionEquality: deepCollectionEquality,
              ),
            );
          }
        });
      });
    }
  }
}
