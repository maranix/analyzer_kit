import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart' show ClassDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer_kit/src/enums.dart';

/// Base class for all analyzer kit lint rules.
abstract base class BaseAnnotationRule extends AnalysisRule {
  BaseAnnotationRule({required this.featureDiagnosticCode})
    : super(
        name: featureDiagnosticCode.diag.name,
        description: featureDiagnosticCode.diag.problemMessage,
      );

  final FeatureDiagnosticCode featureDiagnosticCode;

  @override
  DiagnosticCode get diagnosticCode => featureDiagnosticCode.diag;

  /// The feature annotation that triggers this rule.
  FeatureAnnotation get annotation;

  /// Returns the node processor visitor for this specific rule.
  BaseAnnotationVisitor getVisitor();

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, getVisitor());
  }
}

/// Base visitor class for analyzer kit lint rules.
abstract base class BaseAnnotationVisitor extends RecursiveAstVisitor<void> {
  BaseAnnotationVisitor(this.rule);

  final BaseAnnotationRule rule;

  FeatureAnnotation get annotation => rule.annotation;

  /// Reports a lint error on the annotation Node if the condition fails.
  void reportError(ClassDeclaration node) {
    for (final meta in node.metadata) {
      if (meta.name.name.toLowerCase() == annotation.name.toLowerCase() ||
          meta.name.name.toLowerCase() ==
              FeatureAnnotation.dataClass.name.toLowerCase()) {
        rule.reportAtNode(meta);
        return;
      }
    }
  }
}
