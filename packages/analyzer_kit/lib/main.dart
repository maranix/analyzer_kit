import "package:analysis_server_plugin/plugin.dart";
import "package:analysis_server_plugin/registry.dart";
import "package:analyzer_kit/src/constants.dart";
import "package:analyzer_kit/src/fixes/add_copy_with_method.dart";
import "package:analyzer_kit/src/fixes/add_data_class_methods.dart";
import "package:analyzer_kit/src/fixes/add_deserialize_method.dart";
import "package:analyzer_kit/src/fixes/add_serialize_method.dart";
import "package:analyzer_kit/src/fixes/override_equality_methods.dart";
import "package:analyzer_kit/src/fixes/override_to_string_method.dart";
import "package:analyzer_kit/src/rules/annotation_rule/annotation_rule.dart";

/// The plugin singleton, instantiated by the Dart analysis server.
///
/// This is the entry point for the `analyzer_kit` plugin. The analysis server
/// discovers and loads this top-level `plugin` variable to register all lint
/// rules and quick fixes.
final plugin = AnalyzerKit();

/// Dart Analyzer plugin providing lint rules and quick fixes for
/// [analyzer_kit_annotation](https://pub.dev/packages/analyzer_kit_annotation)
/// annotations.
///
/// Registers 6 lint rules (one per annotation) and 6 corresponding quick fixes.
/// Each lint rule detects when a class is annotated but missing the required
/// methods, and the quick fix generates the missing code.
///
/// ## Registered Rules and Fixes
///
/// | Rule | Fix |
/// |---|---|
/// | [DataClassRule] | [AddDataClassMethods] |
/// | [CopyWithRule] | [AddCopyWithMethod] |
/// | [OverrideToStringRule] | [OverrideToStringMethod] |
/// | [OverrideEqualityRule] | [OverrideEqualityMethods] |
/// | [SerializeRule] | [AddSerializeMethod] |
/// | [DeserializeRule] | [AddDeserializeMethod] |
class AnalyzerKit extends Plugin {
  @override
  String get name => "Analyzer Kit";

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(DataClassRule())
      ..registerFixForRule(LintCodes.dataClass, AddDataClassMethods.new);

    registry
      ..registerLintRule(CopyWithRule())
      ..registerFixForRule(LintCodes.copyWith, AddCopyWithMethod.new);

    registry
      ..registerLintRule(OverrideToStringRule())
      ..registerFixForRule(
        LintCodes.overrideToString,
        OverrideToStringMethod.new,
      );

    registry
      ..registerLintRule(OverrideEqualityRule())
      ..registerFixForRule(
        LintCodes.overrideEquality,
        OverrideEqualityMethods.new,
      );

    registry
      ..registerLintRule(SerializeRule())
      ..registerFixForRule(LintCodes.serialize, AddSerializeMethod.new);

    registry
      ..registerLintRule(DeserializeRule())
      ..registerFixForRule(LintCodes.deserialize, AddDeserializeMethod.new);
  }
}
