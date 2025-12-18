import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class UnusedAnnotationRule extends AnalysisRule {
  UnusedAnnotationRule({
    required FeatureDiagnosticCode diagnosticCode,
    required UnusedAnnotationVisitor Function(AnalysisRule) visitor,
  }) : _code = diagnosticCode,
       _visitor = visitor,
       super(
         name: diagnosticCode.diag.name,
         description: diagnosticCode.diag.problemMessage,
       );

  final FeatureDiagnosticCode _code;
  final UnusedAnnotationVisitor Function(AnalysisRule) _visitor;

  @override
  DiagnosticCode get diagnosticCode => _code.diag;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _visitor(this));
  }
}

final class UnusedAnnotationVisitor extends SimpleAstVisitor {
  UnusedAnnotationVisitor(
    this._rule, {
    required this.annotation,
    required this.methods,
  });

  final AnalysisRule _rule;
  final FeatureAnnotation annotation;
  final Set<FeatureMethod> methods;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    for (final metadatum in node.metadata) {
      if (stringEqualsIgnoreCaseByAscii(metadatum.name.name, annotation.name)) {
        for (var member in node.members) {
          if (methods.isEmpty) break;
          if (member is! MethodDeclaration) continue;

          methods.removeWhere(
            (method) =>
                stringEqualsIgnoreCaseByAscii(member.name.lexeme, method.name),
          );
        }

        if (methods.isNotEmpty) {
          _rule.reportAtNode(metadatum);
        }

        return;
      }
    }
  }
}
