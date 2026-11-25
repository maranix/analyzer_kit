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

/// Quick fix that generates or updates `==` operator and `hashCode` overrides
/// for classes annotated with `@OverrideEquality`.
base class OverrideEqualityMethods extends ResolvedCorrectionProducer {
  OverrideEqualityMethods({required super.context});

  static const _fix = FixKind(
    'dart.fix.overrideEquality',
    DartFixKindPriority.standard,
    'Add or update `==` and `hashCode`',
  );

  bool get forceRegenerate => false;

  @override
  FixKind get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final config = extractAnnotationConfig(declaration);
    if (!config.overrideEquality) {
      return;
    }

    final fields = extractGeneratableFields(declaration);
    if (fields.isEmpty) return;

    final deepCollectionEquality = config.deepCollectionEquality;
    final className = declaration.namePart.typeName.lexeme;
    final typeArguments = extractTypeArguments(declaration);
    final existingHashCode = findMethodDeclaration(
      declaration,
      FeatureMethod.overrideHashCode.name,
    );
    final existingEquals = findMethodDeclaration(
      declaration,
      FeatureMethod.overrideEquals.name,
    );

    final needsHashCodeInsert = existingHashCode == null;
    final needsEqualsInsert = existingEquals == null;

    final toInsert = <String>[
      if (needsHashCodeInsert)
        generateHashCodeOverride(
          fields,
          deepCollectionEquality: deepCollectionEquality,
          format: false,
        ),
      if (needsEqualsInsert)
        generateEqualityOperatorOverride(
          className,
          fields,
          typeArguments: typeArguments,
          deepCollectionEquality: deepCollectionEquality,
        ),
    ];
    final formattedInsert = toInsert.isNotEmpty
        ? formatClassMembers(toInsert)
        : null;

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      if (existingHashCode != null &&
          (forceRegenerate || !isBodyInSync(existingHashCode.body, fields))) {
        fileEditBuilder.addSimpleReplacement(
          range.node(existingHashCode),
          generateHashCodeOverride(
            fields,
            deepCollectionEquality: deepCollectionEquality,
          ).trimRight(),
        );
      }

      if (existingEquals != null &&
          (forceRegenerate || !isBodyInSync(existingEquals.body, fields))) {
        fileEditBuilder.addSimpleReplacement(
          range.node(existingEquals),
          formatCode(
            generateEqualityOperatorOverride(
              className,
              fields,
              typeArguments: typeArguments,
              deepCollectionEquality: deepCollectionEquality,
            ),
          ).trimRight(),
        );
      }

      if (formattedInsert != null) {
        fileEditBuilder.insertMethod(declaration, (editBuilder) {
          editBuilder.write(formattedInsert);
        });
      }
    });
  }
}

/// Assist that force-regenerates `==` and `hashCode` on `@OverrideEquality`
/// classes.
final class RegenerateEqualityMethods extends OverrideEqualityMethods {
  RegenerateEqualityMethods({required super.context});

  static const _assist = AssistKind(
    'dart.assist.regenerateEqualityMethods',
    30,
    'Regenerate `==` and `hashCode`',
  );

  @override
  bool get forceRegenerate => true;

  @override
  AssistKind? get assistKind => _assist;
}
