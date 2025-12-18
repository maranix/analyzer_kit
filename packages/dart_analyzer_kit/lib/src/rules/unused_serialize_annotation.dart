import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode, LintCode;
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/utils/constants.dart';
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
    registry.addClassDeclaration(this, SerializeAnnotationClassVisitor(this));
  }
}

final class SerializeAnnotationClassVisitor extends SimpleAstVisitor<void> {
  SerializeAnnotationClassVisitor(this._rule);

  final AnalysisRule _rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (final annotation in node.metadata) {
      if (stringEqualsIgnoreCaseByAscii(
        annotation.name.name,
        Annotations.serialize.name,
      )) {
        bool hasToMap = false;
        for (var member in node.members) {
          if (member is! MethodDeclaration) continue;

          if (stringEqualsIgnoreCaseByAscii(
              member.name.lexeme, MethodConstants.toMap)) {
            hasToMap = true;
            break;
          }
        }

        if (!hasToMap) {
          _rule.reportAtNode(annotation);
        }

        return;
      }
    }
  }
}
