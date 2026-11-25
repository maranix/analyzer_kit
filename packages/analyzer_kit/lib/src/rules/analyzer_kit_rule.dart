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
    // Fast-path exit: skip abstract or unannotated classes immediately.
    if (node.abstractKeyword != null || node.metadata.isEmpty) return;

    final config = extractAnnotationConfig(node);
    if (!config.hasAnyFeature) return;

    final fields = extractGeneratableFields(node);
    if (fields.isEmpty) return;

    if (config.copyWith) {
      final featureFields = fieldsForFeature(fields, FeatureAnnotation.copyWith);
      if (featureFields.isNotEmpty) {
        final method = findMethodDeclaration(node, FeatureMethod.copyWith.name);
        final sync = method == null
            ? null
            : checkCopyWithSync(
                method,
                featureFields,
                nullable: config.copyWithNullable,
              );
        _report(
          config.annotationNodes[FeatureAnnotation.copyWith],
          FeatureDiagnosticCode.copyWith,
          sync,
        );
      }
    }

    if (config.overrideToString) {
      final featureFields = fieldsForFeature(
        fields,
        FeatureAnnotation.overrideToString,
      );
      if (featureFields.isNotEmpty) {
        final method = findMethodDeclaration(
          node,
          FeatureMethod.overrideToString.name,
        );
        final sync = method == null
            ? null
            : checkBodySync(method.body, featureFields);
        _report(
          config.annotationNodes[FeatureAnnotation.overrideToString],
          FeatureDiagnosticCode.overrideToString,
          sync,
        );
      }
    }

    if (config.overrideEquality) {
      final featureFields = fieldsForFeature(
        fields,
        FeatureAnnotation.overrideEquality,
      );
      if (featureFields.isNotEmpty) {
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
          sync = checkEqualitySync(
            equals,
            hashCode,
            featureFields,
            className: node.namePart.typeName.lexeme,
            typeArguments: extractTypeArguments(node),
          );
        }
        _report(
          config.annotationNodes[FeatureAnnotation.overrideEquality],
          FeatureDiagnosticCode.overrideEquality,
          sync,
        );
      }
    }

    final toMapName = config.serializeMethodName;
    if (config.serialize && toMapName != null) {
      final featureFields = fieldsForFeature(
        fields,
        FeatureAnnotation.serialize,
      );
      if (featureFields.isNotEmpty) {
        final method = findMethodDeclaration(node, toMapName);
        final sync = method == null
            ? null
            : checkSerializeSync(method.body, featureFields);
        _report(
          config.annotationNodes[FeatureAnnotation.serialize],
          FeatureDiagnosticCode.serialize,
          sync,
        );
      }
    }

    final fromMapName = config.deserializeMethodName;
    if (config.deserialize && fromMapName != null) {
      final featureFields = fieldsForFeature(
        fields,
        FeatureAnnotation.deserialize,
      );
      if (featureFields.isNotEmpty) {
        final member = findDeserializeMember(node, fromMapName);
        final sync = member == null
            ? null
            : checkDeserializeSync(member, featureFields);
        _report(
          config.annotationNodes[FeatureAnnotation.deserialize],
          FeatureDiagnosticCode.deserialize,
          sync,
        );
      }
    }
  }

  void _report(
    Annotation? target,
    FeatureDiagnosticCode codes,
    FieldSyncResult? sync,
  ) {
    if (target == null) return;
    if (sync == null) {
      rule.reportAtNode(target, diagnosticCode: codes.diag);
    } else if (!sync.isInSync) {
      rule.reportAtNode(
        target,
        diagnosticCode: codes.outOfSyncDiag,
        arguments: [sync.summary],
      );
    }
  }
}
