import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart' show Annotation, ClassDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show LintCode, DiagnosticCode;
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class UnusedOverrideEqualityAnnotation extends AnalysisRule {
  UnusedOverrideEqualityAnnotation()
    : super(name: diagCode.name, description: diagCode.problemMessage);

  static const diagCode = LintCode(
    'unused_override_equality_annotation',
    "Classes annotated with @overrideEquality must override both `==` and `hashCode`.",
    severity: .WARNING,
    correctionMessage:
        "Either remove this annotation or override both `==` and `hashCode`.",
  );

  @override
  DiagnosticCode get diagnosticCode => diagCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = OverrideEqualityAnnotationVisitor(this);
    registry.addAnnotation(this, visitor);
  }
}

final class OverrideEqualityAnnotationVisitor extends SimpleAstVisitor {
  const OverrideEqualityAnnotationVisitor(this._rule);

  final AnalysisRule _rule;

  @override
  visitAnnotation(Annotation node) {
    final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (declaration == null) return;

    final isMarked = declaration.hasAnnotation(.overrideEquality);
    if (!isMarked) return;

    if (!declaration.hasMethod("==") || !declaration.hasGetter("hashCode")) {
      _rule.reportAtNode(node);
    }
  }
}
