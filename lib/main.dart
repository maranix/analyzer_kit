import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:dart_analyzer_toolkit/src/fixes/add_copy_with_method.dart';
import 'package:dart_analyzer_toolkit/src/rules/unused_copy_with_annotation.dart';

final plugin = AnalyzerToolkit();

class AnalyzerToolkit extends Plugin {
  @override
  String get name => 'Analyzer Toolkit';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(UnusedCopyWithAnnotation());
    registry.registerFixForRule(
      UnusedCopyWithAnnotation.diagCode,
      AddCopyWithMethod.new,
    );
  }
}
