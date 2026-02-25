import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';

final class UnusedOverrideToStringRule extends BaseAnnotationRule {
  UnusedOverrideToStringRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.overrideToString);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.overrideToString;

  @override
  BaseAnnotationVisitor getVisitor() => _Visitor(this);
}

final class _Visitor extends BaseAnnotationVisitor {
  _Visitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final hasMethod = node.members.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.overrideToString.name,
    );

    if (!hasMethod) reportError(node);
  }
}
