import 'package:analyzer/analysis_rule/analysis_rule.dart'
    show MultiAnalysisRule;
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show
        Annotation,
        ArgumentList,
        AstNode,
        ClassDeclaration,
        Expression,
        FieldDeclaration,
        FormalParameterList,
        InstanceCreationExpression,
        ListLiteral,
        MethodInvocation,
        NodeList,
        PrefixedIdentifier,
        SimpleIdentifier;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' show DiagnosticCode;
import 'package:analyzer_kit/src/constants.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

/// Callback invoked when an annotation validation lint is detected.
typedef DiagnosticReporter = void Function(
  AstNode node,
  DiagnosticCode diagnosticCode,
  List<Object> arguments,
);

const _validCompositeEntryTypes = {
  'CopyWith',
  'OverrideEquality',
  'OverrideToString',
  'Serialize',
  'Deserialize',
  'CompositeAnnotation',
};

const _fieldAnnotationTypes = {'Ignore', 'Redact'};

/// Single-pass warning rule that checks all `analyzer_kit` annotations on each
/// [ClassDeclaration] in one AST visit, avoiding redundant metadata and field
/// traversals across features, and validates annotation targets and
/// `CompositeAnnotation` entries.
final class AnalyzerKitRule extends MultiAnalysisRule {
  AnalyzerKitRule()
    : super(
        name: 'analyzer_kit',
        description:
            'Checks that classes with analyzer_kit annotations implement and '
            'keep their generated methods in sync, and validates annotation '
            'targets and CompositeAnnotation entries.',
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
    LintCodes.invalidCompositeAnnotationEntry,
    LintCodes.misplacedFieldAnnotation,
    LintCodes.misplacedClassAnnotation,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _AnalyzerKitVisitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addFormalParameterList(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addAnnotation(this, visitor);
  }
}

final class _AnalyzerKitVisitor extends SimpleAstVisitor<void> {
  _AnalyzerKitVisitor(this.rule);

  final AnalyzerKitRule rule;

  void _reportDiagnostic(
    AstNode node,
    DiagnosticCode code,
    List<Object> arguments,
  ) {
    rule.reportAtNode(node, diagnosticCode: code, arguments: arguments);
  }

  @override
  void visitAnnotation(Annotation node) {
    if (_annotationName(node) == 'CompositeAnnotation') {
      validateCompositeAnnotationArgs(node.arguments, _reportDiagnostic);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName =
        node.constructorName.type.element?.name ??
        node.constructorName.type.name.lexeme;
    if (typeName == 'CompositeAnnotation') {
      validateCompositeAnnotationArgs(node.argumentList, _reportDiagnostic);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    validateFieldOrParamMetadata(node.metadata, _reportDiagnostic);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (final param in node.parameters) {
      validateFieldOrParamMetadata(param.metadata, _reportDiagnostic);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.metadata.isEmpty) return;

    validateClassMetadata(node.metadata, _reportDiagnostic);

    // Fast-path exit: skip abstract classes for codegen sync checks.
    if (node.abstractKeyword != null) return;

    final config = extractAnnotationConfig(node);
    if (!config.hasAnyFeature) return;

    final fields = extractGeneratableFields(node);
    if (fields.isEmpty) return;

    if (config.copyWith) {
      final featureFields = fieldsForFeature(
        fields,
        FeatureAnnotation.copyWith,
      );
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
            : checkBodySync(
                method.body,
                featureFields,
                feature: FeatureAnnotation.overrideToString,
              );
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

/// Validates [metadata] on a `ClassDeclaration`, reporting
/// [LintCodes.misplacedFieldAnnotation] for `@Ignore` / `@Redact`.
void validateClassMetadata(
  NodeList<Annotation> metadata,
  DiagnosticReporter report,
) => _validateMetadataTargets(
  metadata,
  _fieldAnnotationTypes,
  LintCodes.misplacedFieldAnnotation,
  report,
);

/// Validates [metadata] on a `FieldDeclaration` or `FormalParameter`, reporting
/// [LintCodes.misplacedClassAnnotation] for class-level annotations and
/// `CompositeAnnotation` bundles.
void validateFieldOrParamMetadata(
  NodeList<Annotation> metadata,
  DiagnosticReporter report,
) => _validateMetadataTargets(
  metadata,
  _validCompositeEntryTypes,
  LintCodes.misplacedClassAnnotation,
  report,
);

void _validateMetadataTargets(
  NodeList<Annotation> metadata,
  Set<String> disallowedTypes,
  DiagnosticCode code,
  DiagnosticReporter report,
) {
  for (final annotation in metadata) {
    final constantTypeName = annotation.elementAnnotation
        ?.computeConstantValue()
        ?.type
        ?.element
        ?.name;
    final rawName = _annotationName(annotation);
    final isMatch = constantTypeName != null
        ? disallowedTypes.contains(constantTypeName)
        : disallowedTypes.any((t) => stringEqualsIgnoreCaseByAscii(rawName, t));
    if (isMatch) {
      report(annotation, code, [rawName]);
    }
  }
}

/// Validates elements inside a `CompositeAnnotation([...])` argument list,
/// reporting [LintCodes.invalidCompositeAnnotationEntry] for non-class
/// annotations or unrecognized objects.
void validateCompositeAnnotationArgs(
  ArgumentList? arguments,
  DiagnosticReporter report,
) {
  final first = arguments?.arguments.firstOrNull;
  if (first is! ListLiteral) return;

  for (final element in first.elements) {
    if (element is! Expression) continue;

    final resolvedTypeName = element.staticType?.element?.name;
    if (resolvedTypeName != null) {
      if (!_validCompositeEntryTypes.contains(resolvedTypeName)) {
        report(element, LintCodes.invalidCompositeAnnotationEntry, [
          resolvedTypeName,
        ]);
      }
      continue;
    }

    final unresolvedName = _unresolvedExpressionName(element);
    final isValidUnresolved =
        unresolvedName != null &&
        _validCompositeEntryTypes.any(
          (t) => stringEqualsIgnoreCaseByAscii(unresolvedName, t),
        );
    if (!isValidUnresolved) {
      report(element, LintCodes.invalidCompositeAnnotationEntry, [
        unresolvedName ?? element.toSource(),
      ]);
    }
  }
}

String _annotationName(Annotation annotation) => switch (annotation.name) {
  PrefixedIdentifier(:final identifier) => identifier.name,
  final id => id.name,
};

String? _unresolvedExpressionName(Expression expr) => switch (expr) {
  InstanceCreationExpression(:final constructorName) =>
    constructorName.type.name.lexeme,
  MethodInvocation(:final methodName) => methodName.name,
  PrefixedIdentifier(:final identifier) => identifier.name,
  SimpleIdentifier(:final name) => name,
  _ => null,
};
