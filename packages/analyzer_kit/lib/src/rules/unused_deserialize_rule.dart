import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, ConstructorDeclaration, MethodDeclaration;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

final class UnusedDeserializeRule extends BaseAnnotationRule {
  UnusedDeserializeRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.deserialize);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.deserialize;

  @override
  BaseAnnotationVisitor getVisitor() => _Visitor(this);
}

final class _Visitor extends BaseAnnotationVisitor {
  _Visitor(super.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final expectedName = extractFeatureMethodName(node, annotation, 'fromMap');
    if (expectedName == null) return;

    // A deserialize function can be a factory constructor OR a static method.
    final hasFactory = node.members.any(
      (m) =>
          m is ConstructorDeclaration &&
          m.factoryKeyword != null &&
          m.name?.lexeme == expectedName,
    );

    final hasStaticMethod = node.members.any(
      (m) =>
          m is MethodDeclaration && m.isStatic && m.name.lexeme == expectedName,
    );

    if (!hasFactory && !hasStaticMethod) reportError(node);
  }
}
