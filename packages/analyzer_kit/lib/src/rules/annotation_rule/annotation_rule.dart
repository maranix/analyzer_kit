import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, ConstructorDeclaration, MethodDeclaration;
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

part 'copy_with_rule.dart';
part 'data_class_rule.dart';
part 'deserialize_rule.dart';
part 'override_equality_rule.dart';
part 'override_to_string_rule.dart';
part 'serialize_rule.dart';

/// Base class for lint rules that report annotations whose required methods are missing.
abstract base class AnnotationRule extends BaseAnnotationRule {
  AnnotationRule({required super.featureDiagnosticCode});

  @override
  AnnotationVisitor getVisitor();
}

/// Base visitor class that checks if annotated classes contain the expected methods.
abstract base class AnnotationVisitor extends BaseAnnotationVisitor {
  AnnotationVisitor(super.rule);

  /// Returns the required method names for the feature, given the [node].
  /// If it returns null or an empty iterable, it means no specific methods are expected
  /// (or the feature is effectively disabled).
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node);

  /// Reduces the [expectedMethods] by checking if the [members] contain the expected methods.
  ///
  /// Returns true if all expected methods are found, false otherwise.
  bool reduceExpectedMethods(
    Iterable<SyntacticEntity> members,
    Iterable<String> expectedMethods,
  ) {
    final Set<String> methods = .from(expectedMethods);

    for (final member in members) {
      if (member is! MethodDeclaration) continue;

      methods.remove(member.name.lexeme);
    }

    return methods.isEmpty;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final methods = getExpectedMethodNames(node);
    if (methods == null || methods.isEmpty) return;

    final success = reduceExpectedMethods(node.body.childEntities, methods);

    if (!success) {
      reportError(node);
    }
  }
}
