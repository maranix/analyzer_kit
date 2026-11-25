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
final plugin = AnalyzerKit();

/// Dart Analyzer plugin providing warning rules, quick fixes, and assists for
/// [analyzer_kit_annotation](https://pub.dev/packages/analyzer_kit_annotation)
/// annotations.
class AnalyzerKit extends Plugin {
  @override
  String get name => 'Analyzer Kit';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerWarningRule(CopyWithRule())
      ..registerFixForRule(LintCodes.copyWith, AddCompositeMethods.new)
      ..registerFixForRule(LintCodes.copyWithOutOfSync, AddCompositeMethods.new)
      ..registerFixForRule(LintCodes.copyWith, AddCopyWithMethod.new)
      ..registerFixForRule(LintCodes.copyWithOutOfSync, AddCopyWithMethod.new);

    registry
      ..registerWarningRule(OverrideToStringRule())
      ..registerFixForRule(LintCodes.overrideToString, AddCompositeMethods.new)
      ..registerFixForRule(
        LintCodes.overrideToStringOutOfSync,
        AddCompositeMethods.new,
      )
      ..registerFixForRule(
        LintCodes.overrideToString,
        OverrideToStringMethod.new,
      )
      ..registerFixForRule(
        LintCodes.overrideToStringOutOfSync,
        OverrideToStringMethod.new,
      );

    registry
      ..registerWarningRule(OverrideEqualityRule())
      ..registerFixForRule(LintCodes.overrideEquality, AddCompositeMethods.new)
      ..registerFixForRule(
        LintCodes.overrideEqualityOutOfSync,
        AddCompositeMethods.new,
      )
      ..registerFixForRule(
        LintCodes.overrideEquality,
        OverrideEqualityMethods.new,
      )
      ..registerFixForRule(
        LintCodes.overrideEqualityOutOfSync,
        OverrideEqualityMethods.new,
      );

    registry
      ..registerWarningRule(SerializeRule())
      ..registerFixForRule(LintCodes.serialize, AddCompositeMethods.new)
      ..registerFixForRule(
        LintCodes.serializeOutOfSync,
        AddCompositeMethods.new,
      )
      ..registerFixForRule(LintCodes.serialize, AddSerializeMethod.new)
      ..registerFixForRule(
        LintCodes.serializeOutOfSync,
        AddSerializeMethod.new,
      );

    registry
      ..registerWarningRule(DeserializeRule())
      ..registerFixForRule(LintCodes.deserialize, AddCompositeMethods.new)
      ..registerFixForRule(
        LintCodes.deserializeOutOfSync,
        AddCompositeMethods.new,
      )
      ..registerFixForRule(LintCodes.deserialize, AddDeserializeMethod.new)
      ..registerFixForRule(
        LintCodes.deserializeOutOfSync,
        AddDeserializeMethod.new,
      );

    registry
      ..registerAssist(RegenerateCompositeMethods.new)
      ..registerAssist(RegenerateCopyWithMethod.new)
      ..registerAssist(RegenerateToStringMethod.new)
      ..registerAssist(RegenerateEqualityMethods.new)
      ..registerAssist(RegenerateSerializeMethod.new)
      ..registerAssist(RegenerateDeserializeMethod.new);
  }
}
