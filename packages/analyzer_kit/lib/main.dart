import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer_kit/src/constants.dart';
import 'package:analyzer_kit/src/fixes/add_composite_methods.dart';
import 'package:analyzer_kit/src/fixes/add_copy_with_method.dart';
import 'package:analyzer_kit/src/fixes/add_deserialize_method.dart';
import 'package:analyzer_kit/src/fixes/add_serialize_method.dart';
import 'package:analyzer_kit/src/fixes/override_equality_methods.dart';
import 'package:analyzer_kit/src/fixes/override_to_string_method.dart';
import 'package:analyzer_kit/src/rules/annotation_rule/annotation_rule.dart';

/// The plugin singleton, instantiated by the Dart analysis server.
///
/// This is the entry point for the `analyzer_kit` plugin. The analysis server
/// discovers and loads this top-level `plugin` variable to register all lint
/// rules and quick fixes.
final plugin = AnalyzerKit();

/// Dart Analyzer plugin providing warning rules and quick fixes for
/// [analyzer_kit_annotation](https://pub.dev/packages/analyzer_kit_annotation)
/// annotations.
///
/// Registers 5 warning rules (one per feature annotation) and corresponding quick
/// fixes, plus [AddCompositeMethods] for `CompositeAnnotation` bundles.
///
/// ## Registered Rules and Fixes
///
/// | Rule | Fix |
/// |---|---|
/// | [CopyWithRule] | [AddCopyWithMethod], [AddCompositeMethods] |
/// | [OverrideToStringRule] | [OverrideToStringMethod], [AddCompositeMethods] |
/// | [OverrideEqualityRule] | [OverrideEqualityMethods], [AddCompositeMethods] |
/// | [SerializeRule] | [AddSerializeMethod], [AddCompositeMethods] |
/// | [DeserializeRule] | [AddDeserializeMethod], [AddCompositeMethods] |
class AnalyzerKit extends Plugin {
  @override
  String get name => 'Analyzer Kit';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(CopyWithRule())
      ..registerFixForRule(LintCodes.copyWith, AddCompositeMethods.new)
      ..registerFixForRule(LintCodes.copyWith, AddCopyWithMethod.new);

    registry
      ..registerWarningRule(OverrideToStringRule())
      ..registerFixForRule(LintCodes.overrideToString, AddCompositeMethods.new)
      ..registerFixForRule(
        LintCodes.overrideToString,
        OverrideToStringMethod.new,
      );

    registry
      ..registerWarningRule(OverrideEqualityRule())
      ..registerFixForRule(LintCodes.overrideEquality, AddCompositeMethods.new)
      ..registerFixForRule(
        LintCodes.overrideEquality,
        OverrideEqualityMethods.new,
      );

    registry
      ..registerWarningRule(SerializeRule())
      ..registerFixForRule(LintCodes.serialize, AddCompositeMethods.new)
      ..registerFixForRule(LintCodes.serialize, AddSerializeMethod.new);

    registry
      ..registerWarningRule(DeserializeRule())
      ..registerFixForRule(LintCodes.deserialize, AddCompositeMethods.new)
      ..registerFixForRule(LintCodes.deserialize, AddDeserializeMethod.new);
  }
}
