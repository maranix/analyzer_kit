part of 'unused_annotation_rule.dart';

final class UnusedCopyWithRule extends UnusedAnnotationRule {
  UnusedCopyWithRule()
    : super(featureDiagnosticCode: FeatureDiagnosticCode.copyWith);

  @override
  FeatureAnnotation get annotation => FeatureAnnotation.copyWith;

  @override
  UnusedAnnotationVisitor getVisitor() => _UnusedCopyWithVisitor(this);
}

final class _UnusedCopyWithVisitor extends UnusedAnnotationVisitor {
  _UnusedCopyWithVisitor(super.rule);

  @override
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node) {
    return [FeatureMethod.copyWith.name];
  }
}
