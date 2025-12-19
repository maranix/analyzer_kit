import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show ClassDeclaration, MethodDeclaration, FieldDeclaration;
import 'package:analyzer/dart/ast/visitor.dart' show RecursiveAstVisitor;
import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/types.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart'
    show toAsciiLower, stringEqualsIgnoreCaseByAscii;

void main() {
  const source = """
    @copyWith
@serialize
@overrideEquality
@overrideToString
final class User {
  User({required this.name, required this.age});

  final String name;

  final int age;

  User copyWith({int? age}) =>
      User(name: name, age: age ?? this.age);

}

@copyWith
@serialize
@overrideEquality
@overrideToString
final class Todo {
  Todo({required this.id, required this.title, required this.completed});

  final int id;

  final String title;

  final bool completed;

  Todo copyWith({int? id, bool? completed}) => Todo(
    id: id ?? this.id,
    title: title,
    completed: completed ?? this.completed,
  );
}
    """;

  final result = parseString(content: source);
  result.unit.accept(
    Visitor(
      annotations: {"copywith", "overridetostring", "overrideequality"},
      methods: {"copyWith", "toString", "hashCode", "toMap"},
    ),
  );
}

final class Visitor extends RecursiveAstVisitor {
  const Visitor({
    required Set<String> annotations,
    required Set<String> methods,
  }) : _methods = methods,
       _annotations = annotations;

  final Set<String> _annotations;
  final Set<String> _methods;

  @override
  visitClassDeclaration(ClassDeclaration node) {
    final fields = <String>{};
    final classMethodMap = <String, MethodDeclaration>{};
    final classMethodToParameterMap = <String, Set<String>>{};

    for (final annotation in node.metadata) {
      final normalizedAnnotationName = toAsciiLower(annotation.name.name);

      // TODO(maranix): Remove after figuring out the missing fields from function body or object being
      //                returned
      //
      // Basically figure out an efficient and performant way to diff between current method body and
      // expected method body accurately and reliably.
      //
      // Until then this operation is only supported for `copyWith` annotation and leaving this generic
      // implementation as it for future implementation.
      if (!stringEqualsIgnoreCaseByAscii(
        normalizedAnnotationName,
        FeatureAnnotation.copyWith.name,
      )) {
        continue;
      }

      if (_annotations.contains(normalizedAnnotationName)) {
        print("Continuing with $normalizedAnnotationName");
        // We only need to iterate through members once because since
        // are already collecting different types of initially and if a
        // collection remains empty after the initial interation, chances
        // are that the class does not contain those types of Declaration
        //
        // We do not need to keep iterating cache them over and over again
        if (fields.isEmpty && classMethodMap.isEmpty) {
          for (final member in node.members) {
            if (member is FieldDeclaration) {
              final field = ClassField.fromFieldDeclaration(member);

              if (field.isGeneratable) {
                fields.add(field.name);
              }
            }

            if (member is MethodDeclaration) {
              final methodName = member.name.lexeme;
              if (_methods.contains(methodName)) {
                classMethodMap.putIfAbsent(methodName, () => member);

                if (member.parameters != null &&
                    member.parameters!.parameters.isNotEmpty) {
                  classMethodToParameterMap
                      .putIfAbsent(methodName, () => {})
                      .addAll(
                        (member.parameters!.parameters)
                            .map(
                              (p) => p.isOptionalNamed ? p.name!.lexeme : null,
                            )
                            .nonNulls,
                      );
                }
              }
            }
          }
        }

        print("Class Field: $fields");
        print("Class Method: $classMethodMap");
        print("Class Method Parameter: $classMethodToParameterMap");

        for (final method in _methods) {
          if (!classMethodMap.containsKey(method)) continue;

          final m = classMethodMap[method]!;

          // Skip getter function because they don't have any parameters
          //
          // We will only check `copyWith` for now due to some limitations.
          if (m.isGetter) continue;

          final parameters = classMethodToParameterMap[method] ?? {};

          print("Method: $method ----- Parameters: $parameters");
          if (parameters.isEmpty || parameters.length < fields.length) {
            print("Difference: ${fields.difference(parameters)}");
            break;
          }

          // For now we will only check for missing function parameter for copyWith
          //
          // Since we have no way to determine the missing fields reliably from body as of now.
          // Because the method body is returned as a string and not tokens like usual.

          // Right now it is guaranteed to be `copyWith` method because we are skipping other
          // annotations.

          if (fields.difference(parameters).isNotEmpty) {
            print("Difference: ${fields.difference(parameters)}");
            break;
          }
        }
      }
    }
  }
}
