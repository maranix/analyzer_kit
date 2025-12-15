import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'src/fixes/add_copy_with_method.dart';
import 'src/rules/unused_copy_with_annotation.dart';

final plugin = Analyzerkit();

class Analyzerkit extends Plugin {
  @override
  String get name => 'Analyzer kit';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(UnusedCopyWithAnnotation());
    registry.registerFixForRule(
      UnusedCopyWithAnnotation.diagCode,
      AddCopyWithMethod.new,
    );
  }
}
