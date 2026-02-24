import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'package:dart_analyzer_kit/src/constants.dart';
import 'package:dart_analyzer_kit/src/fixes/add_copy_with_method.dart';
import 'package:dart_analyzer_kit/src/fixes/override_equality_methods.dart';
import 'package:dart_analyzer_kit/src/fixes/override_to_string_method.dart';
import 'package:dart_analyzer_kit/src/rules/unused_annotation_rule.dart';

final plugin = AnalyzerKit();

/// Dart analyzer plugin providing lint rules and quick fixes for
/// `analyzer_kit_annotation` annotations.
class AnalyzerKit extends Plugin {
  @override
  String get name => 'Analyzer Kit';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(
        UnusedAnnotationRule(
          diagnosticCode: .copyWith,
          visitor: (rule) => UnusedAnnotationVisitor(
            rule,
            annotation: .copyWith,
            methods: {.copyWith},
          ),
        ),
      )
      ..registerFixForRule(LintCodes.copyWith, AddCopyWithMethod.new);

    registry
      ..registerLintRule(
        UnusedAnnotationRule(
          diagnosticCode: .overrideToString,
          visitor: (rule) => UnusedAnnotationVisitor(
            rule,
            annotation: .overrideToString,
            methods: {.overrideToString},
          ),
        ),
      )
      ..registerFixForRule(
        LintCodes.overrideToString,
        OverrideToStringMethod.new,
      );

    registry
      ..registerLintRule(
        UnusedAnnotationRule(
          diagnosticCode: .overrideEquality,
          visitor: (rule) => UnusedAnnotationVisitor(
            rule,
            annotation: .overrideEquality,
            methods: {.overrideHashCode, .overrideEquals},
          ),
        ),
      )
      ..registerFixForRule(
        LintCodes.overrideEquality,
        OverrideEqualityMethods.new,
      );
  }
}
