import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show MethodDeclaration, ClassDeclaration, Annotation;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode, LintCode;
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class UnusedSerializeAnnotation extends AnalysisRule {
  UnusedSerializeAnnotation()
    : super(name: diagCode.name, description: diagCode.problemMessage);

  static const diagCode = LintCode(
    "unused_serialize_annotation",
    "Classes annotated with @serialize must have a `toMap` method.",
    severity: .WARNING,
    correctionMessage: "Either remove this annotation or add `toMap` method.",
  );

  @override
  DiagnosticCode get diagnosticCode => diagCode;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = SerializeAnnotationVisitor(this);
    registry.addAnnotation(this, visitor);
  }
}

final class SerializeAnnotationVisitor extends GeneralizingAstVisitor<void> {
  const SerializeAnnotationVisitor(this._rule);

  final AnalysisRule _rule;

  @override
  void visitAnnotation(Annotation node) {
    final nodeName = node.name.name;
    if (nodeName.isEmpty) return;

    if (stringsMatchByCharCode(nodeName, Annotations.serialize.name)) {
      final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
      if (declaration == null || declaration.members.isEmpty) return;

      final hasSerializeMethod = declaration.members
          .whereType<MethodDeclaration>()
          .any((m) => stringsMatchByCharCode(m.name.lexeme, "toMap"));

      if (!hasSerializeMethod) {
        _rule.reportAtNode(node);
      }
    }
  }
}
