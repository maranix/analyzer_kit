import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'package:dart_analyzer_kit/src/fixes/add_copy_with_method.dart';
import 'package:dart_analyzer_kit/src/fixes/add_serialize_method.dart';
import 'package:dart_analyzer_kit/src/rules/unused_serialize_annotation.dart';
import 'package:dart_analyzer_kit/src/rules/unused_copy_with_annotation.dart';

final plugin = Analyzerkit();

class Analyzerkit extends Plugin {
  @override
  String get name => 'Analyzer kit';

  @override
  void register(PluginRegistry registry) {
    // CopyWith
    registry.registerLintRule(UnusedCopyWithAnnotation());
    registry.registerFixForRule(
      UnusedCopyWithAnnotation.diagCode,
      AddCopyWithMethod.new,
    );

    // Serialize
    registry.registerLintRule(UnusedSerializeAnnotation());
    registry.registerFixForRule(
      UnusedSerializeAnnotation.diagCode,
      AddSerializeMethod.new,
    );
  }
}
