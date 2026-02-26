import 'package:analyzer/dart/ast/ast.dart'
    show
        ClassDeclaration,
        ConstructorDeclaration,
        MethodDeclaration,
        ClassMember;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/rules/base_annotation_rule.dart';
import 'package:analyzer_kit/src/utils/utils.dart';

part 'unused_copy_with_rule.dart';
part 'unused_deserialize_rule.dart';
part 'unused_override_equality_rule.dart';
part 'unused_override_to_string_rule.dart';
part 'unused_serialize_rule.dart';

/// Base class for lint rules that report annotations whose required methods are missing.
abstract base class UnusedAnnotationRule extends BaseAnnotationRule {
  UnusedAnnotationRule({required super.featureDiagnosticCode});

  @override
  UnusedAnnotationVisitor getVisitor();
}

/// Base visitor class that checks if annotated classes contain the expected methods.
abstract base class UnusedAnnotationVisitor extends BaseAnnotationVisitor {
  UnusedAnnotationVisitor(super.rule);

  /// Returns the required method names for the feature, given the [node].
  /// If it returns null or an empty iterable, it means no specific methods are expected
  /// (or the feature is effectively disabled).
  Iterable<String>? getExpectedMethodNames(ClassDeclaration node);

  /// Checks whether a [member] satisfies the requirement for a given [methodName].
  /// By default, it checks if it's a [MethodDeclaration] with the matching name.
  bool hasExpectedMethod(ClassMember member, String methodName) {
    return member is MethodDeclaration && member.name.lexeme == methodName;
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!hasFeatureEnabled(node, annotation)) return;

    final methods = getExpectedMethodNames(node);
    if (methods == null || methods.isEmpty) return;

    final remainingMethods = methods.toSet();

    for (final member in node.members) {
      if (remainingMethods.isEmpty) break;

      final satisfiedMethods = remainingMethods
          .where((m) => hasExpectedMethod(member, m))
          .toList();
      remainingMethods.removeAll(satisfiedMethods);
    }

    if (remainingMethods.isNotEmpty) {
      reportError(node);
    }
  }
}
