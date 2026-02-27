import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer_kit/src/constants.dart';
import 'package:analyzer_kit/src/fixes/add_copy_with_method.dart';
import 'package:analyzer_kit/src/fixes/add_data_class_methods.dart';
import 'package:analyzer_kit/src/fixes/add_deserialize_method.dart';
import 'package:analyzer_kit/src/fixes/add_serialize_method.dart';
import 'package:analyzer_kit/src/fixes/override_equality_methods.dart';
import 'package:analyzer_kit/src/fixes/override_to_string_method.dart';
import 'package:analyzer_kit/src/rules/unused_annotation_rule/unused_annotation_rule.dart';

final plugin = AnalyzerKit();

/// Dart analyzer plugin providing lint rules and quick fixes for
/// `analyzer_kit_annotation` annotations.
class AnalyzerKit extends Plugin {
  @override
  String get name => 'Analyzer Kit';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(UnusedDataClassRule())
      ..registerFixForRule(LintCodes.dataClass, AddDataClassMethods.new);

    registry
      ..registerLintRule(UnusedCopyWithRule())
      ..registerFixForRule(LintCodes.copyWith, AddCopyWithMethod.new);

    registry
      ..registerLintRule(UnusedOverrideToStringRule())
      ..registerFixForRule(
        LintCodes.overrideToString,
        OverrideToStringMethod.new,
      );

    registry
      ..registerLintRule(UnusedOverrideEqualityRule())
      ..registerFixForRule(
        LintCodes.overrideEquality,
        OverrideEqualityMethods.new,
      );

    registry
      ..registerLintRule(UnusedSerializeRule())
      ..registerFixForRule(LintCodes.serialize, AddSerializeMethod.new);

    registry
      ..registerLintRule(UnusedDeserializeRule())
      ..registerFixForRule(LintCodes.deserialize, AddDeserializeMethod.new);
  }
}
