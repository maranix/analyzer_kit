import 'package:analyzer/analysis_rule/analysis_rule.dart' show AnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, ConstructorDeclaration, MethodDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

part 'unused_copy_with_rule.dart';
part 'unused_deserialize_rule.dart';
part 'unused_override_equality_rule.dart';
part 'unused_override_to_string_rule.dart';
part 'unused_serialize_rule.dart';

/// Lint rule that reports annotations whose required methods are missing.
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

/// Visitor that checks if annotated classes contain the expected methods.
final class UnusedAnnotationVisitor extends SimpleAstVisitor {
  UnusedAnnotationVisitor(
    this._rule, {
    required this.annotation,
    required Set<FeatureMethod> methods,
  }) : _methods = Set.from(methods.map((m) => m.name));

  final AnalysisRule _rule;
  final FeatureAnnotation annotation;
  final Set<String> _methods;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final remainingMethods = <String>{};
    if (_methods.isNotEmpty) {
      remainingMethods.addAll(_methods);
    } else {
      // Dynamic method name extraction for serialize/deserialize
      final defaultMethod = annotation == FeatureAnnotation.serialize
          ? 'toMap'
          : annotation == FeatureAnnotation.deserialize
          ? 'fromMap'
          : null;

      if (defaultMethod != null) {
        final methodName = extractFeatureMethodName(
          node,
          annotation,
          defaultMethod,
        );
        if (methodName != null) {
          remainingMethods.add(methodName);
        }
      }
    }

    if (remainingMethods.isEmpty) return; // No methods to check

    for (var member in node.members) {
      if (remainingMethods.isEmpty) break;
      if (member is! MethodDeclaration) continue;

      remainingMethods.remove(member.name.lexeme);
    }

    if (remainingMethods.isNotEmpty) {
      // Find the annotation to report on: either the specific feature or DataClass
      for (final meta in node.metadata) {
        if (stringEqualsIgnoreCaseByAscii(meta.name.name, annotation.name) ||
            stringEqualsIgnoreCaseByAscii(
              meta.name.name,
              FeatureAnnotation.dataClass.name,
            )) {
          _rule.reportAtNode(meta);
          return;
        }
      }
    }
  }
}
