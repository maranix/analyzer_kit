import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show Annotation, ClassDeclaration, MethodDeclaration;
import 'package:analyzer/dart/ast/visitor.dart' show GeneralizingAstVisitor;
import 'package:analyzer/error/error.dart' show DiagnosticCode, LintCode;

import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class UnusedCopyWithAnnotation extends AnalysisRule {
  UnusedCopyWithAnnotation()
    : super(name: diagCode.name, description: diagCode.problemMessage);

  static const diagCode = LintCode(
    "unused_copy_with_annotation",
    "CopyWith annotation used but no such method found",
    severity: .WARNING,
    correctionMessage: "Either remove the annotation or add this method",
  );

  @override
  DiagnosticCode get diagnosticCode => diagCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = CopyWithAnnotationVisitor(this);
    registry.addAnnotation(this, visitor);
  }
}

final class CopyWithAnnotationVisitor extends GeneralizingAstVisitor<void> {
  CopyWithAnnotationVisitor(this._rule);

  final AnalysisRule _rule;

  @override
  void visitAnnotation(Annotation node) {
    final nodeName = node.name.name;
    if (nodeName.isEmpty) {
      return;
    }

    if (stringsMatchByCharCode(nodeName, Annotations.copyWith.name)) {
      final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classDeclaration == null || classDeclaration.members.isEmpty) return;

      final containsCopyWith = classDeclaration.members
          .whereType<MethodDeclaration>()
          .any(
            (m) => stringsMatchByCharCode(
              m.name.lexeme,
              Annotations.copyWith.name,
            ),
          );

      if (!containsCopyWith) {
        _rule.reportAtNode(node);
      }
    }
  }
}
