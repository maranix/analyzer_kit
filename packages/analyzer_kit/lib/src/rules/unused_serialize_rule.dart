import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

final class UnusedSerializeRule extends BaseAnnotationRule {
  UnusedSerializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.serialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.serialize;

  @override
  BaseAnnotationVisitor getVisitor() => _Visitor(this);
}

final class _Visitor extends BaseAnnotationVisitor {
  _Visitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final expectedName = extractFeatureMethodName(node, annotation, 'toMap');
    if (expectedName == null) return; // Feature disabled or unset

    final hasMethod = node.members.any(
      (m) => m is MethodDeclaration && m.name.lexeme == expectedName,
    );

    if (!hasMethod) reportError(node);
  }
}
