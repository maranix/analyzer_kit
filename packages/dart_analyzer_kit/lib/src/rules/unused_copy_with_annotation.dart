import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:analyzer/dart/ast/visitor.dart' show SimpleAstVisitor;
import 'package:analyzer/error/error.dart' show DiagnosticCode, LintCode;
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/utils/constants.dart';

import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class UnusedCopyWithAnnotation extends AnalysisRule {
  UnusedCopyWithAnnotation()
      : super(name: diagCode.name, description: diagCode.problemMessage);

  static const diagCode = LintCode(
    "unused_copy_with_annotation",
    "Classes annotated with `@copyWith` or `@CopyWith()` must have a `copyWith` method.",
    severity: .WARNING,
    correctionMessage: "Either remove the annotation or add `copyWith` method",
  );

  @override
  DiagnosticCode get diagnosticCode => diagCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, CopyWithAnnotationClassVisitor(this));
  }
}

final class CopyWithAnnotationClassVisitor extends SimpleAstVisitor {
  CopyWithAnnotationClassVisitor(this._rule);

  final AnalysisRule _rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (final annotation in node.metadata) {
      if (stringEqualsIgnoreCaseByAscii(
        annotation.name.name,
        Annotations.copyWith.name,
      )) {
        bool hasCopyWith = false;
        for (var member in node.members) {
          if (member is! MethodDeclaration) continue;

          if (stringEqualsIgnoreCaseByAscii(
              member.name.lexeme, MethodConstants.copyWith)) {
            hasCopyWith = true;
            break;
          }
        }

        if (!hasCopyWith) {
          _rule.reportAtNode(annotation);
        }

        return;
      }
    }
  }
}
