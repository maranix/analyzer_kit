import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'package:dart_analyzer_kit/src/fixes/add_copy_with_method.dart';
import 'package:dart_analyzer_kit/src/fixes/add_serialize_method.dart';
import 'package:dart_analyzer_kit/src/fixes/override_equality_methods.dart';
import 'package:dart_analyzer_kit/src/fixes/override_to_string_method.dart';
import 'package:dart_analyzer_kit/src/rules/missing_field_rule.dart';
import 'package:dart_analyzer_kit/src/rules/unused_annotation_rule.dart';
import 'package:dart_analyzer_kit/src/constants.dart';

final plugin = Analyzerkit();

class Analyzerkit extends Plugin {
  @override
  String get name => 'Analyzer kit';

  @override
  void register(PluginRegistry registry) {
    // CopyWith
    registry.registerLintRule(
      UnusedAnnotationRule(
        diagnosticCode: .copyWith,
        visitor: (rule) => UnusedAnnotationVisitor(
          rule,
          annotation: .copyWith,
          methods: {.copyWith},
        ),
      ),
    );
    registry.registerFixForRule(
      DiagnosticLintCode.copyWith,
      AddCopyWithMethod.new,
    );

    // Serialize
    registry.registerLintRule(
      UnusedAnnotationRule(
        diagnosticCode: .serialize,
        visitor: (rule) => UnusedAnnotationVisitor(
          rule,
          annotation: .serialize,
          methods: {.toMap},
        ),
      ),
    );
    registry.registerFixForRule(
      DiagnosticLintCode.serialize,
      AddSerializeMethod.new,
    );

    // Override toString
    registry.registerLintRule(
      UnusedAnnotationRule(
        diagnosticCode: .overrideToString,
        visitor: (rule) => UnusedAnnotationVisitor(
          rule,
          annotation: .overrideToString,
          methods: {.overrideToString},
        ),
      ),
    );
    registry.registerFixForRule(
      DiagnosticLintCode.overrideToString,
      OverrideToStringMethod.new,
    );

    // Override Equality
    registry.registerLintRule(
      UnusedAnnotationRule(
        diagnosticCode: .overrideEquality,
        visitor: (rule) => UnusedAnnotationVisitor(
          rule,
          annotation: .overrideEquality,
          methods: {.overrideHashCode, .overrideEquals},
        ),
      ),
    );
    registry.registerFixForRule(
      DiagnosticLintCode.overrideEquality,
      OverrideEqualityMethods.new,
    );

    // Missing fields
    registry.registerLintRule(
      MissingFieldRule(
        diagCode: .missingField,
        annotations: {
          .copyWith,
          .serialize,
          .overrideToString,
          .overrideEquality,
        },
        methods: {
          .toMap,
          .copyWith,
          .overrideEquals,
          .overrideHashCode,
          .overrideToString,
        },
      ),
    );
  }
}
