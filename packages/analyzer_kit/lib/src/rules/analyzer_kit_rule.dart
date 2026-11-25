import 'package:analyzer/analysis_rule/analysis_rule.dart'
    show MultiAnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart' show Annotation, ClassDeclaration;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer_kit/src/constants.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

/// Single-pass warning rule that checks all `analyzer_kit` annotations on each
/// [ClassDeclaration] in one AST visit, avoiding redundant metadata and field
/// traversals across features.
final class AnalyzerKitRule extends MultiAnalysisRule {
  AnalyzerKitRule()
    : super(
        name: 'analyzer_kit',
        description:
            'Checks that classes with analyzer_kit annotations implement and '
            'keep their generated methods in sync.',
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => const [
    LintCodes.copyWith,
    LintCodes.copyWithOutOfSync,
    LintCodes.overrideToString,
    LintCodes.overrideToStringOutOfSync,
    LintCodes.overrideEquality,
    LintCodes.overrideEqualityOutOfSync,
    LintCodes.serialize,
    LintCodes.serializeOutOfSync,
    LintCodes.deserialize,
    LintCodes.deserializeOutOfSync,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _AnalyzerKitVisitor(this));
  }
}

final class _AnalyzerKitVisitor extends RecursiveAstVisitor<void> {
  _AnalyzerKitVisitor(this.rule);

  final AnalyzerKitRule rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Fast-path exit: skip unannotated classes immediately.
    if (node.metadata.isEmpty) return;

    final config = extractAnnotationConfig(node);
    if (!config.hasAnyFeature) return;

    final fields = extractGeneratableFields(node);

    if (config.copyWith) {
      final method = findMethodDeclaration(node, FeatureMethod.copyWith.name);
      final sync = method == null ? null : checkCopyWithSync(method, fields);
      _report(
        node,
        FeatureAnnotation.copyWith,
        FeatureDiagnosticCode.copyWith,
        sync,
      );
    }

    if (config.overrideToString) {
      final method = findMethodDeclaration(
        node,
        FeatureMethod.overrideToString.name,
      );
      final sync = method == null ? null : checkBodySync(method.body, fields);
      _report(
        node,
        FeatureAnnotation.overrideToString,
        FeatureDiagnosticCode.overrideToString,
        sync,
      );
    }

    if (config.overrideEquality) {
      final equals = findMethodDeclaration(
        node,
        FeatureMethod.overrideEquals.name,
      );
      final hashCode = findMethodDeclaration(
        node,
        FeatureMethod.overrideHashCode.name,
      );
      final FieldSyncResult? sync;
      if (equals == null || hashCode == null) {
        sync = null;
      } else {
        final equalsSync = checkBodySync(equals.body, fields);
        final hashSync = checkBodySync(hashCode.body, fields);
        sync = FieldSyncResult(
          missingFields: {
            ...equalsSync.missingFields,
            ...hashSync.missingFields,
          }.toList(),
        );
      }
      _report(
        node,
        FeatureAnnotation.overrideEquality,
        FeatureDiagnosticCode.overrideEquality,
        sync,
      );
    }

    final toMapName = config.serializeMethodName;
    if (config.serialize && toMapName != null) {
      final method = findMethodDeclaration(node, toMapName);
      final sync = method == null
          ? null
          : checkSerializeSync(method.body, fields);
      _report(
        node,
        FeatureAnnotation.serialize,
        FeatureDiagnosticCode.serialize,
        sync,
      );
    }

    final fromMapName = config.deserializeMethodName;
    if (config.deserialize && fromMapName != null) {
      final member = findDeserializeMember(node, fromMapName);
      final sync = member == null ? null : checkDeserializeSync(member, fields);
      _report(
        node,
        FeatureAnnotation.deserialize,
        FeatureDiagnosticCode.deserialize,
        sync,
      );
    }
  }

  void _report(
    ClassDeclaration node,
    FeatureAnnotation feature,
    FeatureDiagnosticCode codes,
    FieldSyncResult? sync,
  ) {
    if (sync == null) {
      _reportAtAnnotation(node, feature, codes.diag);
    } else if (!sync.isInSync) {
      _reportAtAnnotation(
        node,
        feature,
        codes.outOfSyncDiag,
        arguments: [sync.summary],
      );
    }
  }

  void _reportAtAnnotation(
    ClassDeclaration node,
    FeatureAnnotation feature,
    DiagnosticCode diagnosticCode, {
    List<Object> arguments = const [],
  }) {
    final Annotation? target = _findAnnotation(node, feature);
    if (target != null) {
      rule.reportAtNode(
        target,
        diagnosticCode: diagnosticCode,
        arguments: arguments,
      );
    }
  }

  Annotation? _findAnnotation(
    ClassDeclaration node,
    FeatureAnnotation feature,
  ) {
    for (final meta in node.metadata) {
      if (annotationEnablesFeature(meta, feature)) {
        return meta;
      }
    }
    return null;
  }
}
