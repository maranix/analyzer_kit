import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show LintCode, DiagnosticCode;
import 'package:dart_analyzer_kit/src/enums.dart' show Annotations;
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
    registry.addClassDeclaration(
      this,
      OverrideEqualityAnnotationClassVisitor(this),
    );
  }
}

final class OverrideEqualityAnnotationClassVisitor extends SimpleAstVisitor {
  OverrideEqualityAnnotationClassVisitor(this._rule);

  final AnalysisRule _rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (final annotation in node.metadata) {
      if (stringEqualsIgnoreCaseByAscii(
        annotation.name.name,
        Annotations.overrideEquality.name,
      )) {
        bool hasEquals = false;
        bool hasHashCode = false;

        for (var member in node.members) {
          if (hasEquals && hasHashCode) break;
          if (member is! MethodDeclaration) continue;

          final isEquals = stringEqualsIgnoreCaseByAscii(
            member.name.lexeme,
            '==',
          );

          final isHashCode = stringEqualsIgnoreCaseByAscii(
            member.name.lexeme,
            'hashCode',
          );

          if (isEquals && !hasEquals) {
            hasEquals = true;
          } else if (isHashCode && !hasHashCode) {
            hasHashCode = true;
          }
        }

        if (!hasEquals || !hasHashCode) {
          _rule.reportAtNode(annotation);
        }

        return;
      }
    }
  }
}
