import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart' show Annotation, ClassDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show LintCode, DiagnosticCode;
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class UnusedDebugStringAnnotation extends AnalysisRule {
  UnusedDebugStringAnnotation()
    : super(name: diagCode.name, description: diagCode.problemMessage);

  static const diagCode = LintCode(
    'unused_debug_string_annotation',
    "Classes annotated with @debugString must override `toString` method.",
    severity: .WARNING,
    correctionMessage:
        "Either remove this annotation or override `toString` method.",
  );

  @override
  DiagnosticCode get diagnosticCode => diagCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = DebugStringAnnotationVisitor(this);
    registry.addAnnotation(this, visitor);
  }
}

final class DebugStringAnnotationVisitor extends SimpleAstVisitor {
  const DebugStringAnnotationVisitor(this._rule);

  final AnalysisRule _rule;

  @override
  visitAnnotation(Annotation node) {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final isMarked = declaration.hasAnnotation(.debugString);
    if (!isMarked) return;

    if (!declaration.hasMethod("toString")) {
      _rule.reportAtNode(node);
    }
  }
}
