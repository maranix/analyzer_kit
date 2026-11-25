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

/// Quick fix that generates or updates all missing/out-of-sync methods for
/// classes annotated with a `CompositeAnnotation`.
base class AddCompositeMethods extends ResolvedCorrectionProducer {
  AddCompositeMethods({required super.context});

  static const _fix = FixKind(
    'dart.fix.addCompositeMethods',
    DartFixKindPriority.standard + 1,
    'Add or update composite annotation methods',
  );

  bool get forceRegenerate => false;

  @override
  FixKind? get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final config = extractAnnotationConfig(declaration);
    if (!config.hasCompositeAnnotation) return;

    final fields = extractGeneratableFields(declaration);
    if (fields.isEmpty) return;

    final className = declaration.namePart.typeName.lexeme;
    final typeArguments = extractTypeArguments(declaration);
    final constructorName = extractPrimaryConstructorName(declaration);

    final toReplace = <(ClassMember, String)>[];
    final toInsert = <String>[];

    void handleMethod(
      MethodDeclaration? existing,
      bool inSync,
      String Function({required bool format}) generate,
    ) {
      if (existing == null) {
        toInsert.add(generate(format: false));
      } else if (forceRegenerate || !inSync) {
        toReplace.add((existing, generate(format: true)));
      }
    }

    if (config.copyWith) {
      final featureFields = fieldsForFeature(fields, FeatureAnnotation.copyWith);
      if (featureFields.isNotEmpty) {
        final existing = findMethodDeclaration(
          declaration,
          FeatureMethod.copyWith.name,
        );
        handleMethod(
          existing,
          existing != null &&
              isCopyWithInSync(
                existing,
                featureFields,
                nullable: config.copyWithNullable,
              ),
          ({required bool format}) => generateCopyWithMethod(
            className,
            featureFields,
            constructorName: constructorName,
            typeArguments: typeArguments,
            nullable: config.copyWithNullable,
            format: format,
          ),
        );
      }
    }

    if (config.overrideToString) {
      final featureFields = fieldsForFeature(
        fields,
        FeatureAnnotation.overrideToString,
      );
      if (featureFields.isNotEmpty) {
        final existing = findMethodDeclaration(
          declaration,
          FeatureMethod.overrideToString.name,
        );
        handleMethod(
          existing,
          existing != null && isBodyInSync(existing.body, featureFields),
          ({required bool format}) => generateToStringMethod(
            className,
            featureFields,
            multiline: config.overrideToStringMultiline,
            format: format,
          ),
        );
      }
    }

    final equalityFields = fieldsForFeature(
      fields,
      FeatureAnnotation.overrideEquality,
    );
    if (config.overrideEquality && equalityFields.isNotEmpty) {
      final existingHashCode = findMethodDeclaration(
        declaration,
        FeatureMethod.overrideHashCode.name,
      );
      handleMethod(
        existingHashCode,
        existingHashCode != null &&
            isBodyInSync(existingHashCode.body, equalityFields),
        ({required bool format}) => generateHashCodeOverride(
          equalityFields,
          deepCollectionEquality: config.deepCollectionEquality,
          format: format,
        ),
      );

      final existingEquals = findMethodDeclaration(
        declaration,
        FeatureMethod.overrideEquals.name,
      );
      final equalityInSync =
          existingEquals != null &&
          existingHashCode != null &&
          checkEqualitySync(
            existingEquals,
            existingHashCode,
            equalityFields,
            className: className,
            typeArguments: typeArguments,
          ).isInSync;
      handleMethod(
        existingEquals,
        equalityInSync,
        ({required bool format}) => generateEqualityOperatorOverride(
          className,
          equalityFields,
          typeArguments: typeArguments,
          deepCollectionEquality: config.deepCollectionEquality,
        ),
      );
    }

    final toMapName = config.serializeMethodName;
    if (config.serialize && toMapName != null) {
      final featureFields = fieldsForFeature(
        fields,
        FeatureAnnotation.serialize,
      );
      if (featureFields.isNotEmpty) {
        final existing = findMethodDeclaration(declaration, toMapName);
        handleMethod(
          existing,
          existing != null && isBodyInSync(existing.body, featureFields),
          ({required bool format}) =>
              generateSerializeMethod(toMapName, featureFields, format: format),
        );
      }
    }

    final fromMapName = config.deserializeMethodName;
    if (config.deserialize && fromMapName != null) {
      final featureFields = fieldsForFeature(
        fields,
        FeatureAnnotation.deserialize,
      );
      if (featureFields.isNotEmpty) {
        final existing = findDeserializeMember(declaration, fromMapName);
        if (existing == null) {
          toInsert.add(
            generateDeserializeMethod(
              className,
              fromMapName,
              featureFields,
              constructorName: constructorName,
              typeArguments: typeArguments,
              format: false,
            ),
          );
        } else if (forceRegenerate ||
            !isDeserializeInSync(existing, featureFields)) {
          toReplace.add((
            existing,
            generateDeserializeMethod(
              className,
              fromMapName,
              featureFields,
              constructorName: constructorName,
              typeArguments: typeArguments,
            ),
          ));
        }
      }
    }

    if (toReplace.isEmpty && toInsert.isEmpty) return;

    final formattedInsert = toInsert.isNotEmpty
        ? formatClassMembers(toInsert)
        : null;

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      if (config.overrideEquality &&
          config.deepCollectionEquality != false &&
          equalityFields.any((f) => f.isCollectionType)) {
        fileEditBuilder.importLibrary(
          Uri.parse(
            'package:analyzer_kit_annotation/analyzer_kit_annotation.dart',
          ),
        );
      }

      for (final (member, code) in toReplace) {
        fileEditBuilder.addSimpleReplacement(
          range.node(member),
          code.trimRight(),
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

/// Assist that force-regenerates all methods for classes annotated with a
/// `CompositeAnnotation`.
final class RegenerateCompositeMethods extends AddCompositeMethods {
  RegenerateCompositeMethods({required super.context});

  static const _assist = AssistKind(
    'dart.assist.regenerateCompositeMethods',
    31,
    'Regenerate composite annotation methods',
  );

  @override
  bool get forceRegenerate => true;

  @override
  AssistKind? get assistKind => _assist;
}
