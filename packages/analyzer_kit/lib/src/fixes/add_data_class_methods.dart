import "package:analysis_server_plugin/edit/dart/correction_producer.dart";
import "package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart"
    show DartFixKindPriority;
import "package:analyzer/dart/ast/ast.dart";
import "package:analyzer_kit/src/enums.dart";
import "package:analyzer_kit/src/utils/code_gen_utils.dart";
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

    final annotation = getAnnotation(declaration, .dataClass);
    if (annotation == null) return;

    final fields = extractGeneratableFields(declaration);
    if (fields.isEmpty) return;

    final members = declaration.body.childEntities;

    final List<String> expectedMethods = [];

    for (final f in CompositeFeatureAnnotation.dataClass.features) {
      if (isFeaturedEnabledInAnnotation(annotation, f)) {
        expectedMethods.addAll(f.expectedMethods.map((n) => n.name));
      }
    }

    for (final member in members) {
      final isMethod = member is MethodDeclaration;
      final isConstructor = member is ConstructorDeclaration;

      if (!isMethod || !isConstructor) continue;

      expectedMethods.remove(member.name.lexeme);
    }

    await builder.addDartFileEdit(file, (fileEditBuilder) {
      fileEditBuilder.insertMethod(declaration, (editBuilder) {
        final className = declaration.namePart.typeName.lexeme;

        for (final name in expectedMethods) {
          switch (FeatureMethod.fromString(name)) {
            case .copyWith:
              editBuilder.writeln(generateCopyWithMethod(className, fields));
            case .overrideToString:
              editBuilder.writeln(
                generateToStringMethod(className, fields),
              );
            case .overrideHashCode:
              editBuilder.writeln(
                generateHashCodeOverride(fields),
              );
            case .overrideEquals:
              editBuilder.writeln(
                generateEqualityOperatorOverride(
                  className,
                  fields,
                ),
              );
            case .fromMap:
              editBuilder.writeln(generateSerializeMethod(name, fields));
            case .fromJson:
              editBuilder.writeln(generateSerializeMethod(name, fields));
            case .toMap:
              editBuilder.writeln(
                generateDeserializeMethod(className, name, fields),
              );
            default:
              throw UnsupportedError(
                "Feature $name is not supported by ${annotation.toString()}",
              );
          }
        }
      });
    });
  }
}
