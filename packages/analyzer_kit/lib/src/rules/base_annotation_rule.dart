import 'package:analyzer/analysis_rule/analysis_rule.dart'
    show MultiAnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart' show ClassDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart'
    show annotationEnablesFeature;

/// Base class for all analyzer kit warning rules.
abstract base class BaseAnnotationRule extends MultiAnalysisRule {
  BaseAnnotationRule({required this.featureDiagnosticCode})
    : super(
        name: featureDiagnosticCode.diag.lowerCaseName,
        description: featureDiagnosticCode.diag.problemMessage,
      );

  final FeatureDiagnosticCode featureDiagnosticCode;

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    featureDiagnosticCode.diag,
    featureDiagnosticCode.outOfSyncDiag,
  ];

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

/// Base visitor class for analyzer kit warning rules.
abstract base class BaseAnnotationVisitor extends RecursiveAstVisitor<void> {
  BaseAnnotationVisitor(this.rule);

  final BaseAnnotationRule rule;

  FeatureAnnotation get annotation => rule.annotation;

  /// Reports a diagnostic on the matching annotation node.
  void reportError(
    ClassDeclaration node, {
    required DiagnosticCode diagnosticCode,
    List<Object> arguments = const [],
  }) {
    for (final meta in node.metadata) {
      if (annotationEnablesFeature(meta, annotation)) {
        rule.reportAtNode(
          meta,
          diagnosticCode: diagnosticCode,
          arguments: arguments,
        );
        return;
      }
    }
  }
}
