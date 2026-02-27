part of 'annotation_rule.dart';

final class CopyWithRule extends AnnotationRule {
  CopyWithRule() : super(featureDiagnosticCode: FeatureDiagnosticCode.copyWith);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.copyWith;

  @override
  AnnotationVisitor getVisitor() => _CopyWithVisitor(this);
}

final class _CopyWithVisitor extends AnnotationVisitor {
  _CopyWithVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    return [FeatureMethod.copyWith.name];
  }
}
