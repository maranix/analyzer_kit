import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show LintCode, DiagnosticCode;
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class UnusedOverrideToStringAnnotation extends AnalysisRule {
  UnusedOverrideToStringAnnotation()
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
    registry.addClassDeclaration(this, DebugStringAnnotationClassVisitor(this));
  }
}

final class DebugStringAnnotationClassVisitor extends SimpleAstVisitor {
  DebugStringAnnotationClassVisitor(this._rule);

  final AnalysisRule _rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (final annotation in node.metadata) {
      if (stringEqualsIgnoreCaseByAscii(
        annotation.name.name,
        Annotations.debugString.name,
      )) {
        bool hasToString = false;
        for (var member in node.members) {
          if (member is! MethodDeclaration) continue;

          if (stringEqualsIgnoreCaseByAscii(member.name.lexeme, 'toString')) {
            hasToString = true;
            break;
          }
        }

        if (!hasToString) {
          _rule.reportAtNode(annotation);
        }

        return;
      }
    }
  }
}
