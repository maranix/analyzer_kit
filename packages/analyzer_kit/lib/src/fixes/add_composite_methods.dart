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
    final constructorName = extractPrimaryConstructorName(declaration);

    final toReplace = <(ClassMember, String)>[];
    final toInsert = <String>[];

    void handleMethod(
      MethodDeclaration? existing,
      bool inSync,
      String generated,
    ) {
      if (existing == null) {
        toInsert.add(generated);
      } else if (forceRegenerate || !inSync) {
        toReplace.add((existing, generated));
      }
    }

    if (config.copyWith) {
      final existing = findMethodDeclaration(
        declaration,
        FeatureMethod.copyWith.name,
      );
      handleMethod(
        existing,
        existing != null && isCopyWithInSync(existing, fields),
        generateCopyWithMethod(
          className,
          fields,
          constructorName: constructorName,
        ),
      );
    }

    if (config.overrideToString) {
      final existing = findMethodDeclaration(
        declaration,
        FeatureMethod.overrideToString.name,
      );
      handleMethod(
        existing,
        existing != null && isBodyInSync(existing.body, fields),
        generateToStringMethod(className, fields),
      );
    }

    if (config.overrideEquality) {
      final existingHashCode = findMethodDeclaration(
        declaration,
        FeatureMethod.overrideHashCode.name,
      );
      handleMethod(
        existingHashCode,
        existingHashCode != null && isBodyInSync(existingHashCode.body, fields),
        generateHashCodeOverride(
          fields,
          deepCollectionEquality: config.deepCollectionEquality,
        ),
      );

      final existingEquals = findMethodDeclaration(
        declaration,
        FeatureMethod.overrideEquals.name,
      );
      handleMethod(
        existingEquals,
        existingEquals != null && isBodyInSync(existingEquals.body, fields),
        generateEqualityOperatorOverride(
          className,
          fields,
          deepCollectionEquality: config.deepCollectionEquality,
        ),
      );
    }

    final toMapName = config.serializeMethodName;
    if (config.serialize && toMapName != null) {
      final existing = findMethodDeclaration(declaration, toMapName);
      handleMethod(
        existing,
        existing != null && isBodyInSync(existing.body, fields),
        generateSerializeMethod(toMapName, fields),
      );
    }

    final fromMapName = config.deserializeMethodName;
    if (config.deserialize && fromMapName != null) {
      final existing = findDeserializeMember(declaration, fromMapName);
      final generated = generateDeserializeMethod(
        className,
        fromMapName,
        fields,
        constructorName: constructorName,
      );
      if (existing == null) {
        toInsert.add(generated);
      } else if (forceRegenerate || !isDeserializeInSync(existing, fields)) {
        toReplace.add((existing, generated));
      }
    }

    if (toReplace.isEmpty && toInsert.isEmpty) return;

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      for (final (member, code) in toReplace) {
        fileEditBuilder.addSimpleReplacement(
          range.node(member),
          code.trimRight(),
        );
      }

      if (toInsert.isNotEmpty) {
        fileEditBuilder.insertMethod(declaration, (editBuilder) {
          for (final code in toInsert) {
            editBuilder.writeln(code);
          }
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
