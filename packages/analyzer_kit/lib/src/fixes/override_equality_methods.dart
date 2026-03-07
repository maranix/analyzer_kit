import "package:analysis_server_plugin/edit/dart/correction_producer.dart";
import "package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart"
    show DartFixKindPriority;
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer_kit/src/enums.dart";
import "package:analyzer_kit/src/utils/utils.dart";
import "package:analyzer_plugin/utilities/change_builder/change_builder_core.dart";
import "package:analyzer_plugin/utilities/fixes/fixes.dart";

/// Quick fix that generates `==` operator and `hashCode` overrides for
/// classes annotated with `@OverrideEquality`.
final class OverrideEqualityMethods extends ResolvedCorrectionProducer {
  OverrideEqualityMethods({required super.context});

  static const _fix = FixKind(
    "dart.fix.overrideEquality",
    DartFixKindPriority.standard,
    "Override `==` and `hashCode`",
  );

  @override
  FixKind get fixKind => _fix;

  @override
  CorrectionApplicability get applicability => .automatically;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final annotation = getAnnotation(declaration, .overrideEquality);
    if (annotation == null) return;

    bool? deepCollectionEquality;

    // Extract deepCollectionEquality from either @OverrideEquality or @DataClass
    for (final annotation in declaration.metadata) {
      final name = annotation.name.name;
      if (stringEqualsIgnoreCaseByAscii(
            name,
            FeatureAnnotation.overrideEquality.name,
          ) ||
          stringEqualsIgnoreCaseByAscii(
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

    final hasHashCodeOverride = declaration.body.childEntities.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.overrideHashCode.name,
    );
    final hasEqualityOperatorOverride = declaration.body.childEntities.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.operatorEquals.name,
    );

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
