import 'package:analyzer/dart/ast/ast.dart' show ClassDeclaration;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

part 'copy_with_rule.dart';
part 'deserialize_rule.dart';
part 'override_equality_rule.dart';
part 'override_to_string_rule.dart';
part 'serialize_rule.dart';

/// Base class for lint rules that report annotations whose required methods
/// are missing or out of sync with the class fields.
abstract base class AnnotationRule extends BaseAnnotationRule {
  AnnotationRule({required super.featureDiagnosticCode});

  @override
  AnnotationVisitor getVisitor();
}

/// Base visitor class that checks if annotated classes contain the expected
/// methods and that those methods are in sync with the class fields.
abstract base class AnnotationVisitor extends BaseAnnotationVisitor {
  AnnotationVisitor(super.rule);

  /// Returns whether [node] has all required methods present and in sync with
  /// its generatable fields.
  bool isSatisfied(ClassDeclaration node);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    if (!isSatisfied(node)) {
      reportError(node);
    }
  }
}
