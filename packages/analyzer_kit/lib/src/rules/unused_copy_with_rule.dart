import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

final class UnusedCopyWithRule extends BaseAnnotationRule {
  UnusedCopyWithRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.copyWith);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.copyWith;

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
          m.name.lexeme == FeatureMethod.copyWith.name,
    );

    if (!hasMethod) reportError(node);
  }
}
