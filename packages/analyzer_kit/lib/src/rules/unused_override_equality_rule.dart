import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

final class UnusedOverrideEqualityRule extends BaseAnnotationRule {
  UnusedOverrideEqualityRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.overrideEquality);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.overrideEquality;

  @override
  BaseAnnotationVisitor getVisitor() => _Visitor(this);
}

final class _Visitor extends BaseAnnotationVisitor {
  _Visitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final hasEquals = node.members.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.overrideEquals.name,
    );
    final hasHashCode = node.members.any(
      (m) =>
          m is MethodDeclaration &&
          m.name.lexeme == FeatureMethod.overrideHashCode.name,
    );

    if (!hasEquals || !hasHashCode) reportError(node);
  }
}
