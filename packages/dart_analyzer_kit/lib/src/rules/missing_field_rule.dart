import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, FieldDeclaration, MethodDeclaration;
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class MissingFieldRule extends AnalysisRule {
  MissingFieldRule({
    required FeatureDiagnosticCode diagCode,
    required Set<FeatureAnnotation> annotations,
    required Set<FeatureMethod> methods,
  }) : _code = diagCode,
       _annotations = Set.from(annotations.map((a) => toAsciiLower(a.name))),
       _methods = Set.from(methods.map((m) => m.name)),
       super(
         name: diagCode.diag.name,
         description: diagCode.diag.problemMessage,
       );

  final FeatureDiagnosticCode _code;
  final Set<String> _annotations;
  final Set<String> _methods;

  @override
  DiagnosticCode get diagnosticCode => _code.diag;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(
      this,
      MissingFieldVisitor(this, annotations: _annotations, methods: _methods),
    );
  }
}

final class MissingFieldVisitor extends SimpleAstVisitor {
  const MissingFieldVisitor(
    this._rule, {
    required Set<String> annotations,
    required Set<String> methods,
  }) : _methods = methods,
       _annotations = annotations;

  final AnalysisRule _rule;
  final Set<String> _annotations;
  final Set<String> _methods;

  @override
  visitClassDeclaration(ClassDeclaration node) {
    final fields = <String>{};
    final classMethodMap = <String, MethodDeclaration>{};
    final classMethodParameterMap = <String, Set<String>>{};

    for (final annotation in node.metadata) {
      final normalizedAnnotationName = toAsciiLower(annotation.name.name);

      if (_annotations.contains(normalizedAnnotationName)) {
        // We only need to iterate through members once because since
        // are already collecting different types of initially and if a
        // collection remains empty after the initial interation, chances
        // are that the class does not contain those types of Declaration
        //
        // We do not need to keep iterating and cache them over and over again
        if (fields.isEmpty && classMethodMap.isEmpty) {
          for (final member in node.members) {
            if (member is FieldDeclaration) {
              final field = ClassField.fromFieldDeclaration(member);

              if (field.isGeneratable) {
                fields.add(field.name);
              }
            }

            if (member is MethodDeclaration) {
              final methodName = member.name.lexeme;
              if (_methods.contains(methodName)) {
                classMethodMap.putIfAbsent(methodName, () => member);

                if (member.parameters != null &&
                    member.parameters!.parameters.isNotEmpty) {
                  classMethodParameterMap
                      .putIfAbsent(methodName, () => {})
                      .addAll(
                        (member.parameters!.parameters)
                            .map(
                              (p) => p.isOptionalNamed ? p.name!.lexeme : null,
                            )
                            .nonNulls,
                      );
                }
              }
            }
          }
        }

        for (final method in _methods) {
          final m = classMethodMap[method];
          if (m == null || method != "copyWith") continue;

          // Skip getter function because they don't have any parameters
          //
          // We will only check `copyWith` for now due to some limitations.
          if (m.isGetter) continue;

          final parameters = classMethodParameterMap[method] ?? {};
          if (parameters.isEmpty || parameters.length < fields.length) {
            _rule.reportAtNode(m);
            break;
          }

          // For now we will only check for missing function parameter for copyWith
          //
          // Since we have no way to determine the missing fields reliably from body as of now.
          // Because the method body is returned as a string and not tokens like usual.

          // Right now it is guaranteed to be `copyWith` method because we are skipping other
          // annotations.

          if (fields.difference(parameters).isNotEmpty) {
            _rule.reportAtNode(m);
            break;
          }
        }
      }
    }
  }
}
