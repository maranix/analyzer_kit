import 'package:analyzer/dart/ast/ast.dart' show ClassDeclaration;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

part 'copy_with_rule.dart';
part 'deserialize_rule.dart';
part 'override_equality_rule.dart';
part 'override_to_string_rule.dart';
part 'serialize_rule.dart';

/// Base class for warning rules that report annotations whose required methods
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

  /// Checks whether [node] has its required method(s) present and in sync.
  ///
  /// Returns `null` when the method/member itself is missing, or a
  /// [FieldSyncResult] describing any missing/extra fields when it exists.
  FieldSyncResult? checkSync(ClassDeclaration node);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final result = checkSync(node);
    if (result == null) {
      reportError(node, diagnosticCode: rule.featureDiagnosticCode.diag);
    } else if (!result.isInSync) {
      reportError(
        node,
        diagnosticCode: rule.featureDiagnosticCode.outOfSyncDiag,
        arguments: [result.summary],
      );
    }
  }
}
