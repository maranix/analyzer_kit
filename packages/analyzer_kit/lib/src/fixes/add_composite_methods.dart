import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart'
    show DartFixKindPriority;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Quick fix that generates all missing methods for classes annotated with a
/// `CompositeAnnotation`.
final class AddCompositeMethods extends ResolvedCorrectionProducer {
  AddCompositeMethods({required super.context});

  static const _fix = FixKind(
    'dart.fix.addCompositeMethods',
    DartFixKindPriority.standard + 1,
    'Add missing composite annotation methods',
  );

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

    final existingMembers = <String>{};
    for (final member in declaration.body.members) {
      if (member is MethodDeclaration) {
        existingMembers.add(member.name.lexeme);
      } else if (member is ConstructorDeclaration) {
        final name = member.name?.lexeme;
        if (name != null) existingMembers.add(name);
      }
    }

    final className = declaration.namePart.typeName.lexeme;
    final hasCopyWith = existingMembers.contains(FeatureMethod.copyWith.name);
    final hasToString = existingMembers.contains(
      FeatureMethod.overrideToString.name,
    );
    final hasHashCode = existingMembers.contains(
      FeatureMethod.overrideHashCode.name,
    );
    final hasEquals = existingMembers.contains(
      FeatureMethod.overrideEquals.name,
    );

    final toMapName = config.serializeMethodName;
    final hasSerialize =
        toMapName != null && existingMembers.contains(toMapName);

    final fromMapName = config.deserializeMethodName;
    final hasDeserialize =
        fromMapName != null && existingMembers.contains(fromMapName);

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      fileEditBuilder.insertMethod(declaration, (editBuilder) {
        if (config.copyWith && !hasCopyWith) {
          editBuilder.writeln(generateCopyWithMethod(className, fields));
        }

        if (config.overrideToString && !hasToString) {
          editBuilder.writeln(generateToStringMethod(className, fields));
        }

        if (config.overrideEquality) {
          if (!hasHashCode) {
            editBuilder.writeln(
              generateHashCodeOverride(
                fields,
                deepCollectionEquality: config.deepCollectionEquality,
              ),
            );
          }

          if (!hasEquals) {
            editBuilder.writeln(
              generateEqualityOperatorOverride(
                className,
                fields,
                deepCollectionEquality: config.deepCollectionEquality,
              ),
            );
          }
        }

        if (config.serialize && !hasSerialize && toMapName != null) {
          editBuilder.writeln(generateSerializeMethod(toMapName, fields));
        }

        if (config.deserialize && !hasDeserialize && fromMapName != null) {
          editBuilder.writeln(
            generateDeserializeMethod(className, fromMapName, fields),
          );
        }
      });
    });
  }
}
