import "package:analysis_server_plugin/edit/dart/correction_producer.dart";
import "package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart"
    show DartFixKindPriority;
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer_kit/src/enums.dart";
import "package:analyzer_kit/src/utils/utils.dart";
import "package:analyzer_plugin/utilities/change_builder/change_builder_core.dart";
import "package:analyzer_plugin/utilities/fixes/fixes.dart";

/// Quick fix that generates missing methods for classes annotated
/// with `@DataClass`.
final class AddDataClassMethods extends ResolvedCorrectionProducer {
  AddDataClassMethods({required super.context});

  static const _fix = FixKind(
    "dart.fix.addDataClassMethods",
    DartFixKindPriority.standard,
    "Add missing DataClass methods",
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

    if (hasFeatureEnabled(declaration, FeatureAnnotation.dataClass)) {
      final fields = extractGeneratableFields(declaration);
      if (fields.isEmpty) return;

      final members = declaration.body.childEntities;

      final hasCopyWith = members.any(
        (m) =>
            m is MethodDeclaration &&
            m.name.lexeme == FeatureMethod.copyWith.name,
      );
      final hasToString = members.any(
        (m) =>
            m is MethodDeclaration &&
            m.name.lexeme == FeatureMethod.overrideToString.name,
      );
      final hasHashCode = members.any(
        (m) =>
            m is MethodDeclaration &&
            m.name.lexeme == FeatureMethod.overrideHashCode.name,
      );
      final hasEquals = members.any(
        (m) =>
            m is MethodDeclaration &&
            m.name.lexeme == FeatureMethod.overrideEquals.name,
      );

      final toMapName = extractFeatureMethodName(
        declaration,
        FeatureAnnotation.serialize,
        FeatureMethod.toMap.name,
      );
      final hasSerialize =
          toMapName != null &&
          members.any(
            (m) => m is MethodDeclaration && m.name.lexeme == toMapName,
          );

      final fromMapName = extractFeatureMethodName(
        declaration,
        FeatureAnnotation.deserialize,
        FeatureMethod.fromMap.name,
      );
      final hasDeserialize =
          fromMapName != null &&
          members.any(
            (m) =>
                m is ConstructorDeclaration && m.name?.lexeme == fromMapName ||
                m is MethodDeclaration && m.name.lexeme == fromMapName,
          );

      await builder.addDartFileEdit(file, (fileEditBuilder) {
        fileEditBuilder.insertMethod(declaration, (editBuilder) {
          if (hasFeatureEnabled(declaration, FeatureAnnotation.copyWith) &&
              !hasCopyWith) {
            editBuilder.writeln(
              generateCopyWithMethod(
                declaration.namePart.typeName.lexeme,
                fields,
              ),
            );
          }

          if (hasFeatureEnabled(
                declaration,
                FeatureAnnotation.overrideToString,
              ) &&
              !hasToString) {
            editBuilder.writeln(
              generateToStringMethod(
                declaration.namePart.typeName.lexeme,
                fields,
              ),
            );
          }

          if (hasFeatureEnabled(
            declaration,
            FeatureAnnotation.overrideEquality,
          )) {
            bool? deepCollectionEquality;

            for (final annotation in declaration.metadata) {
              final name = annotation.name.name;
              if (stringEqualsIgnoreCaseByAscii(
                name,
                FeatureAnnotation.dataClass.name,
              )) {
                final arguments = annotation.arguments?.arguments;
                if (arguments != null) {
                  for (final arg in arguments) {
                    if (arg is NamedExpression &&
                        arg.name.label.name == "deepCollectionEquality") {
                      final expression = arg.expression;
                      if (expression is BooleanLiteral) {
                        deepCollectionEquality = expression.value;
                      }
                    }
                  }
                }
              }
            }

            if (!hasHashCode) {
              editBuilder.writeln(
                generateHashCodeOverride(
                  fields,
                  deepCollectionEquality: deepCollectionEquality,
                ),
              );
            }

            if (!hasEquals) {
              editBuilder.writeln(
                generateEqualityOperatorOverride(
                  declaration.namePart.typeName.lexeme,
                  fields,
                  deepCollectionEquality: deepCollectionEquality,
                ),
              );
            }
          }

          if (hasFeatureEnabled(declaration, FeatureAnnotation.serialize) &&
              !hasSerialize) {
            if (toMapName != null) {
              editBuilder.writeln(generateSerializeMethod(toMapName, fields));
            }
          }

          if (hasFeatureEnabled(declaration, FeatureAnnotation.deserialize) &&
              !hasDeserialize) {
            if (fromMapName != null) {
              editBuilder.writeln(
                generateDeserializeMethod(
                  declaration.namePart.typeName.lexeme,
                  fromMapName,
                  fields,
                ),
              );
            }
          }
        });
      });
    }
  }
}
