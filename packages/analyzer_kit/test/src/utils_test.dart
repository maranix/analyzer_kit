import "dart:io";

import "package:analyzer/dart/analysis/analysis_context_collection.dart";
import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/analysis/utilities.dart" show parseString;
import "package:analyzer/dart/ast/ast.dart" show ClassDeclaration;
import "package:analyzer_kit/src/enums.dart";
import "package:analyzer_kit/src/utils/utils.dart";
// ignore: depend_on_referenced_packages
import "package:path/path.dart" as p;
import "package:test/test.dart";

/// Writes the string to a temporary file, fully resolves it,
/// and returns the ResolvedUnitResult.
Future<ResolvedUnitResult> resolveText(String content) async {
  // 1. Create a temporary directory and file
  final tempDir = Directory.systemTemp.createTempSync("analyzer_test");
  final file = File(p.join(tempDir.path, "test_target.dart"));
  file.writeAsStringSync(content);

  // 2. Set up the analysis context to resolve the file
  final collection = AnalysisContextCollection(includedPaths: [tempDir.path]);
  final context = collection.contextFor(file.path);

  // 3. Get the fully RESOLVED unit
  final result = await context.currentSession.getResolvedUnit(file.path);

  // 4. Clean up the temporary file
  tempDir.deleteSync(recursive: true);

  if (result is! ResolvedUnitResult) {
    throw Exception("Failed to resolve test file.");
  }

  return result;
}

/// Parses Dart [source] and returns the first [ClassDeclaration] found.
ClassDeclaration _parseClass(String source) {
  final unit = parseString(content: source).unit;
  return unit.declarations.whereType<ClassDeclaration>().first;
}

/// Parses Dart [source] and returns the [ClassDeclaration] with the given
/// [name].
ClassDeclaration _parseClassByName(String source, String name) {
  final unit = parseString(content: source).unit;
  return unit.declarations.whereType<ClassDeclaration>().firstWhere(
    (c) => c.namePart.typeName.lexeme == name,
  );
}

void main() {
  group("extractGeneratableFields", () {
    test("extracts basic final fields", () {
      final node = _parseClass("""
class User {
  final String name;
  final int age;
  User({required this.name, required this.age});
}
""");

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(2));
      expect(fields[0].name, "name");
      expect(fields[0].type, "String");
      expect(fields[1].name, "age");
      expect(fields[1].type, "int");
    });

    test("excludes static fields", () {
      final node = _parseClass("""
class User {
  static const maxAge = 150;
  final String name;
  User({required this.name});
}
""");

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(1));
      expect(fields[0].name, "name");
    });

    test("excludes late fields", () {
      final node = _parseClass("""
class User {
  late String name;
  final int age;
  User({required this.age});
}
""");

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(1));
      expect(fields[0].name, "age");
    });

    test("returns empty for class with no fields", () {
      final node = _parseClass("""
class Empty {
  const Empty();
}
""");

      final fields = extractGeneratableFields(node).toList();
      expect(fields, isEmpty);
    });

    test("handles multiple field types", () {
      final node = _parseClass("""
class Data {
  final String name;
  final int? age;
  final List<String> tags;
  final Map<String, dynamic> meta;
  Data({required this.name, this.age, required this.tags, required this.meta});
}
""");

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(4));
      expect(fields[0].type, "String");
      expect(fields[1].type, "int?");
      expect(fields[2].type, "List<String>");
      expect(fields[3].type, "Map<String, dynamic>");
    });

    test("excludes only non-generatable fields", () {
      final node = _parseClass("""
class Mixed {
  final String name;
  static final String label = 'mixed';
  late int count;
  final bool active;
}
""");

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(2));
      expect(fields.map((f) => f.name), containsAll(["name", "active"]));
    });
  });

  group("isFeaturedEnabledInAnnotation", () {
    test(
      "throws AnnotationFeatureNotFoundException when an empty annotation is present",
      () {
        final node = _parseClassByName("""
class CopyWith { const CopyWith(); }

@CopyWith()
class User {
  final String name;
  User({required this.name});
}
""", "User");

        expect(
          () => isFeaturedEnabledInAnnotation(
            node.metadata.first,
            .copyWith,
          ),
          throwsA(
            isA<AnnotationFeatureNotFoundException>().having(
              (e) => e.message,
              "message",
              equals(
                "Feature `CopyWith` not found in Annotation `CopyWith`",
              ),
            ),
          ),
        );
      },
    );

    test("returns false when @DataClass explicitly disables feature", () async {
      final result = await resolveText("""
      class DataClass {
        const DataClass({
          this.copyWith = true,
          this.overrideEquality = true,
          this.overrideToString = true,
          this.serialize = true,
          this.deserialize = true,
        });
        final bool copyWith;
        final bool overrideEquality;
        final bool overrideToString;
        final bool serialize;
        final bool deserialize;
      }

      @DataClass(copyWith: false)
      class User {
        final String name;
        User({required this.name});
      }
      """);

      final node = result.unit.declarations.whereType<ClassDeclaration>().last;

      final annotation = getAnnotation(node, .dataClass);

      expect(annotation, isNotNull);
      expect(
        isFeaturedEnabledInAnnotation(annotation!, .copyWith),
        isFalse,
      );
      expect(
        isFeaturedEnabledInAnnotation(annotation, .overrideEquality),
        isTrue,
      );
    });
  });

  group("extractFeatureMethodName", () {
    test("returns default name for direct annotation with no arguments", () {
      final node = _parseClassByName("""
class Serialize { const Serialize(); }

@Serialize()
class User {
  final String name;
  User({required this.name});
}
""", "User");

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, "toMap"),
        "toMap",
      );
    });

    test("returns null when no relevant annotation present", () {
      final node = _parseClass("""
class User {
  final String name;
  User({required this.name});
}
""");

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, "toMap"),
        isNull,
      );
    });

    // test("returns default name for @DataClass when feature is enabled", () {
    //   final node = _parseClassByName("""
    // class DataClass {
    //   const DataClass({
    //     this.copyWith = true,
    //     this.overrideEquality = true,
    //     this.overrideToString = true,
    //     this.serialize = true,
    //     this.deserialize = true,
    //   });
    //   final bool copyWith;
    //   final bool overrideEquality;
    //   final bool overrideToString;
    //   final bool serialize;
    //   final bool deserialize;
    // }

    // @DataClass()
    // class User {
    //   final String name;
    //   User({required this.name});
    // }
    // """, "User");

    //   expect(
    //     extractFeatureMethodName(node, FeatureAnnotation.serialize, "toMap"),
    //     "toMap",
    //   );
    // });

    test("returns null for @DataClass when feature is disabled", () {
      final node = _parseClassByName("""
class DataClass {
  const DataClass({
    this.copyWith = true,
    this.overrideEquality = true,
    this.overrideToString = true,
    this.serialize = true,
    this.deserialize = true,
  });
  final bool copyWith;
  final bool overrideEquality;
  final bool overrideToString;
  final bool serialize;
  final bool deserialize;
}

@DataClass(serialize: false)
class User {
  final String name;
  User({required this.name});
}
""", "User");

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, "toMap"),
        isNull,
      );
    });

    test(
      "returns default name for FeatureAnnotation.dataClass with annotation",
      () {
        final node = _parseClassByName("""
class DataClass { const DataClass(); }

@DataClass()
class User {
  final String name;
  User({required this.name});
}
""", "User");

        expect(
          extractFeatureMethodName(
            node,
            FeatureAnnotation.dataClass,
            "defaultName",
          ),
          "defaultName",
        );
      },
    );

    test("returns null for FeatureAnnotation.dataClass without annotation", () {
      final node = _parseClass("""
class User {
  final String name;
  User({required this.name});
}
""");

      expect(
        extractFeatureMethodName(
          node,
          FeatureAnnotation.dataClass,
          "defaultName",
        ),
        isNull,
      );
    });

    test("extracts custom name from .custom() annotation argument", () {
      final node = _parseClassByName("""
class Serialize {
  const Serialize({this.name});
  final Object? name;
}

@Serialize(name: .custom('toDto'))
class User {
  final String name;
  User({required this.name});
}
""", "User");

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, "toMap"),
        "toDto",
      );
    });

    test("extracts method name from dot shorthand like .toMap()", () {
      final node = _parseClassByName("""
class Serialize {
  const Serialize({this.name});
  final Object? name;
}

@Serialize(name: .toMap())
class User {
  final String name;
  User({required this.name});
}
""", "User");

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, "toMap"),
        "toMap",
      );
    });

    test("returns default name when annotation has non-name arguments", () {
      final node = _parseClassByName("""
class Serialize {
  const Serialize({this.name, this.other});
  final Object? name;
  final Object? other;
}

@Serialize(other: 'hello')
class User {
  final String name;
  User({required this.name});
}
""", "User");

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, "toMap"),
        "toMap",
      );
    });

    test("returns default for deserialization with no arguments", () {
      final node = _parseClassByName("""
class Deserialize { const Deserialize(); }

@Deserialize()
class User {
  final String name;
  User({required this.name});
}
""", "User");

      expect(
        extractFeatureMethodName(
          node,
          FeatureAnnotation.deserialize,
          "fromMap",
        ),
        "fromMap",
      );
    });

    test("extracts custom deserialization name from .custom()", () {
      final node = _parseClassByName("""
class Deserialize {
  const Deserialize({this.name});
  final Object? name;
}

@Deserialize(name: .custom('fromDto'))
class User {
  final String name;
  User({required this.name});
}
""", "User");

      expect(
        extractFeatureMethodName(
          node,
          FeatureAnnotation.deserialize,
          "fromMap",
        ),
        "fromDto",
      );
    });
  });
}
