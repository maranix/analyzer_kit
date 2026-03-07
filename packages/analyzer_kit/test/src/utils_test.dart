import "dart:io";

import "package:analyzer/dart/analysis/analysis_context_collection.dart";
import "package:analyzer/dart/analysis/results.dart";
import "package:analyzer/dart/ast/ast.dart" show ClassDeclaration, Declaration;
import "package:analyzer/dart/constant/value.dart" show DartObject;
import "package:analyzer_kit/src/utils/utils.dart";
// ignore: depend_on_referenced_packages
import "package:path/path.dart" as p;
import "package:test/test.dart";

const _classes = """
  class User {
    User({required this.name, required this.age});

    final String name;
    final int age;
  }

  class UserStatic {
    UserStatic({required this.name});

    static const maxAge = 150;
    final String name;
  }

  class UserLate {
    User({required this.age});

    late String name;
    final int age;
  }

  class Empty() {
    const Empty();
  }

  class Data {
    Data({required this.name, required this.tags, required this.meta, this.age});

    final List<String> tags;
    final Map<String, dynamic> meta;
    final String name;
    final int? age;
  }

  class Mixed {
    static final String label = 'mixed';

    final String name;

    late int count;

    final bool active;
  }


""";

const _classesWithAnnotations = """
  class CopyWith { 
      const CopyWith();
  }

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

  class Serialize {
    const Serialize({this.name});
    final Object? name;
  }

  class Deserialize {
    const Deserialize({this.name});
    final Object? name;
  }

  // --- Annotated user classes ---

  @CopyWith()
  class UserCopyWith {
    final String name;
    UserCopyWith({required this.name});
  }

  @DataClass(copyWith: false)
  class UserDataClassCopyWithDisabled {
    final String name;
    UserDataClassCopyWithDisabled({required this.name});
  }

  @Serialize()
  class UserSerializeDefault {
    final String name;
    UserSerializeDefault({required this.name});
  }

  class UserNoAnnotation {
    final String name;
    UserNoAnnotation({required this.name});
  }

  @DataClass(serialize: false)
  class UserDataClassSerializeDisabled {
    final String name;
    UserDataClassSerializeDisabled({required this.name});
  }

  @DataClass()
  class UserDataClassDefault {
    final String name;
    UserDataClassDefault({required this.name});
  }

  @Serialize(name: 'toDto')
  class UserSerializeCustom {
    final String name;
    UserSerializeCustom({required this.name});
  }

  @Serialize(name: "toMap")
  class UserSerializeDotShorthand {
    final String name;
    UserSerializeDotShorthand({required this.name});
  }

  @Serialize(other: 'hello')
  class UserSerializeNonNameArg {
    final String name;
    UserSerializeNonNameArg({required this.name});
  }

  @Deserialize()
  class UserDeserializeDefault {
    final String name;
    UserDeserializeDefault({required this.name});
  }

  @Deserialize(name: 'fromDto')
  class UserDeserializeCustom {
    final String name;
    UserDeserializeCustom({required this.name});
  }

  @DataClass(copyWith: false, overrideEquality: false, overrideToString: false, serialize: false, deserialize: false)
  class UserDataClassAllDisabled {
    final String name;
    UserDataClassAllDisabled({required this.name});
  }

  @DataClass()
  @Serialize()
  class UserMultiAnnotation {
    final String name;
    UserMultiAnnotation({required this.name});
  }
""";

/// Finds declarations of type [T] in the given [result].
///
/// If [name] is provided, only declarations of type [T] with the given name are returned.
///
/// Throws [Exception] if type [T] is not supported.
Iterable<T> _findDeclarations<T extends Declaration>(
  ResolvedUnitResult result, [
  String? name,
]) {
  return result.unit.declarations.whereType<T>().where((d) {
    if (name == null) return true;

    final declarationName = switch (d) {
      final ClassDeclaration c => c.namePart.typeName.lexeme,
      _ => throw Exception(
        "Unable to resolve `name` of type ${T.runtimeType}, support for it is likely not implemented yet.",
      ),
    };

    return declarationName == name;
  });
}

/// Writes [fileContents] to a temporary file at [directoryPath],
/// fully resolves it using [acc] and returns the ResolvedUnitResult.
///
/// **Note:** File is deleted after acquiring [ResolvedUnitResult].
Future<ResolvedUnitResult> _resolveStringToUnit(
  AnalysisContextCollection acc,
  String directoryPath,
  String fileContents,
) async {
  final dt = DateTime.now().millisecondsSinceEpoch;

  final filePath = p.join(directoryPath, "$dt.dart");
  final file = File(filePath);

  file.writeAsStringSync(fileContents);

  final context = acc.contextFor(file.path);

  final result = await context.currentSession.getResolvedUnit(file.path);
  file.deleteSync();

  if (result is! ResolvedUnitResult) {
    throw Exception("Failed to resolve test file.");
  }

  return result;
}

void main() async {
  group("extractGeneratableFields", () {
    late final ResolvedUnitResult unit;
    late final int dt;
    late final Directory tempDir;
    late final AnalysisContextCollection acc;

    setUpAll(() async {
      dt = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory.systemTemp.createTempSync("analyzer_kit_test_$dt");
      acc = AnalysisContextCollection(includedPaths: [tempDir.path]);

      unit = await _resolveStringToUnit(acc, tempDir.path, _classes);
    });

    tearDownAll(() async {
      tempDir.deleteSync(recursive: true);
      await acc.dispose();
    });

    test("extracts basic final fields", () async {
      final node = _findDeclarations<ClassDeclaration>(unit, "User").first;

      final fields = extractGeneratableFields(node).toList();

      expect(fields, hasLength(2));
      expect(fields[0].name, "name");
      expect(fields[0].type, "String");
      expect(fields[1].name, "age");
      expect(fields[1].type, "int");
    });

    test("excludes static fields", () async {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserStatic",
      ).first;

      final fields = extractGeneratableFields(node);

      expect(fields, hasLength(1));
      expect(fields.first.name, "name");
    });

    test("excludes late fields", () async {
      final node = _findDeclarations<ClassDeclaration>(unit, "UserLate").first;

      final fields = extractGeneratableFields(node);

      expect(fields, hasLength(1));
      expect(fields.first.name, "age");
    });

    test("returns empty for class with no fields", () async {
      final node = _findDeclarations<ClassDeclaration>(unit, "Empty").first;

      final fields = extractGeneratableFields(node).toList();

      expect(fields, isEmpty);
    });

    test("handles multiple field types", () {
      final node = _findDeclarations<ClassDeclaration>(unit, "Data").first;

      final fields = extractGeneratableFields(node).map((f) => f.type);
      final expectedFields = [
        "List<String>",
        "Map<String, dynamic>",
        "String",
        "int?",
      ];

      expect(fields, hasLength(4));
      expect(fields.length, equals(expectedFields.length));
      expect(fields, containsAll(expectedFields));
    });

    test("excludes only non-generatable fields", () {
      final node = _findDeclarations<ClassDeclaration>(unit, "Mixed").first;

      final fields = extractGeneratableFields(node).toList();

      expect(fields, hasLength(2));
      expect(fields.map((f) => f.name), containsAll(["name", "active"]));
    });
  });

  group("isFeaturedEnabledInAnnotation", () {
    late final ResolvedUnitResult unit;
    late final int dt;
    late final Directory tempDir;
    late final AnalysisContextCollection acc;

    setUpAll(() async {
      dt = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory.systemTemp.createTempSync("analyzer_kit_test_$dt");
      acc = AnalysisContextCollection(includedPaths: [tempDir.path]);

      unit = await _resolveStringToUnit(
        acc,
        tempDir.path,
        _classesWithAnnotations,
      );
    });

    tearDownAll(() async {
      tempDir.deleteSync(recursive: true);
      await acc.dispose();
    });

    test(
      "throws AnnotationFeatureNotFoundException when an empty annotation is present",
      () {
        final node = _findDeclarations<ClassDeclaration>(
          unit,
          "UserCopyWith",
        ).first;

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
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserDataClassCopyWithDisabled",
      ).first;

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

    test("returns true when @DataClass defaults are used", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserDataClassDefault",
      ).first;

      final annotation = getAnnotation(node, .dataClass);

      expect(annotation, isNotNull);
      expect(
        isFeaturedEnabledInAnnotation(annotation!, .serialize),
        isTrue,
      );
    });

    test("returns true for all default-enabled features", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserDataClassDefault",
      ).first;

      final annotation = getAnnotation(node, .dataClass);

      expect(annotation, isNotNull);
      expect(
        isFeaturedEnabledInAnnotation(annotation!, .overrideToString),
        isTrue,
      );
    });

    test("returns false when all features are disabled", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserDataClassAllDisabled",
      ).first;

      final annotation = getAnnotation(node, .dataClass);

      expect(annotation, isNotNull);
      expect(
        isFeaturedEnabledInAnnotation(annotation!, .copyWith),
        isFalse,
      );
      expect(
        isFeaturedEnabledInAnnotation(annotation, .serialize),
        isFalse,
      );
    });

    test(
      "returns true for non-disabled features alongside disabled ones",
      () {
        final node = _findDeclarations<ClassDeclaration>(
          unit,
          "UserDataClassCopyWithDisabled",
        ).first;

        final annotation = getAnnotation(node, .dataClass);

        expect(annotation, isNotNull);
        expect(
          isFeaturedEnabledInAnnotation(annotation!, .serialize),
          isTrue,
        );
      },
    );
  });

  group("nodeHasAnnotation", () {
    late final ResolvedUnitResult unit;
    late final int dt;
    late final Directory tempDir;
    late final AnalysisContextCollection acc;

    setUpAll(() async {
      dt = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory.systemTemp.createTempSync("analyzer_kit_test_$dt");
      acc = AnalysisContextCollection(includedPaths: [tempDir.path]);

      unit = await _resolveStringToUnit(
        acc,
        tempDir.path,
        _classesWithAnnotations,
      );
    });

    tearDownAll(() async {
      tempDir.deleteSync(recursive: true);
      await acc.dispose();
    });

    test("returns true when annotation is present", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserCopyWith",
      ).first;

      expect(nodeHasAnnotation(node, "CopyWith"), isTrue);
    });

    test("returns true with case-insensitive match", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserCopyWith",
      ).first;

      expect(nodeHasAnnotation(node, "copywith"), isTrue);
    });

    test("returns false when annotation is absent", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserNoAnnotation",
      ).first;

      expect(nodeHasAnnotation(node, "CopyWith"), isFalse);
    });

    test("returns true for @DataClass", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserDataClassDefault",
      ).first;

      expect(nodeHasAnnotation(node, "DataClass"), isTrue);
    });

    test("returns true with multiple annotations", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserMultiAnnotation",
      ).first;

      expect(nodeHasAnnotation(node, "Serialize"), isTrue);
      expect(nodeHasAnnotation(node, "DataClass"), isTrue);
    });
  });

  group("getAnnotation", () {
    late final ResolvedUnitResult unit;
    late final int dt;
    late final Directory tempDir;
    late final AnalysisContextCollection acc;

    setUpAll(() async {
      dt = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory.systemTemp.createTempSync("analyzer_kit_test_$dt");
      acc = AnalysisContextCollection(includedPaths: [tempDir.path]);

      unit = await _resolveStringToUnit(
        acc,
        tempDir.path,
        _classesWithAnnotations,
      );
    });

    tearDownAll(() async {
      tempDir.deleteSync(recursive: true);
      await acc.dispose();
    });

    test("returns annotation when present", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserCopyWith",
      ).first;

      final annotation = getAnnotation(node, .copyWith);

      expect(annotation, isNotNull);
      expect(annotation!.name.name, "CopyWith");
    });

    test("returns null when annotation is absent", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserNoAnnotation",
      ).first;

      final annotation = getAnnotation(node, .copyWith);

      expect(annotation, isNull);
    });

    test("returns @DataClass annotation", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserDataClassDefault",
      ).first;

      final annotation = getAnnotation(node, .dataClass);

      expect(annotation, isNotNull);
      expect(annotation!.name.name, "DataClass");
    });

    test("returns correct annotation when multiple present", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserMultiAnnotation",
      ).first;

      final serialize = getAnnotation(node, .serialize);
      final dataClass = getAnnotation(node, .dataClass);

      expect(serialize, isNotNull);
      expect(serialize!.name.name, "Serialize");
      expect(dataClass, isNotNull);
      expect(dataClass!.name.name, "DataClass");
    });
  });

  group("getComputedAnnotationFieldValue", () {
    late final ResolvedUnitResult unit;
    late final int dt;
    late final Directory tempDir;
    late final AnalysisContextCollection acc;

    setUpAll(() async {
      dt = DateTime.now().millisecondsSinceEpoch;
      tempDir = Directory.systemTemp.createTempSync("analyzer_kit_test_$dt");
      acc = AnalysisContextCollection(includedPaths: [tempDir.path]);

      unit = await _resolveStringToUnit(
        acc,
        tempDir.path,
        _classesWithAnnotations,
      );
    });

    tearDownAll(() async {
      tempDir.deleteSync(recursive: true);
      await acc.dispose();
    });

    test("returns DartObject for existing bool field with default true", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserDataClassDefault",
      ).first;

      final annotation = getAnnotation(node, .dataClass)!;
      final value = getComputedAnnotationFieldValue(annotation, "copyWith");

      expect(value, isA<DartObject>());
      expect(value!.toBoolValue(), isTrue);
    });

    test(
      "returns DartObject with false value for explicitly disabled field",
      () {
        final node = _findDeclarations<ClassDeclaration>(
          unit,
          "UserDataClassCopyWithDisabled",
        ).first;

        final annotation = getAnnotation(node, .dataClass)!;
        final value = getComputedAnnotationFieldValue(annotation, "copyWith");

        expect(value, isA<DartObject>());
        expect(value!.toBoolValue(), isFalse);
      },
    );

    test("returns null for non-existent field", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserDataClassDefault",
      ).first;

      final annotation = getAnnotation(node, .dataClass)!;
      final value = getComputedAnnotationFieldValue(
        annotation,
        "nonExistent",
      );

      expect(value, isNull);
    });

    test("returns null for annotation without fields", () {
      final node = _findDeclarations<ClassDeclaration>(
        unit,
        "UserCopyWith",
      ).first;

      final annotation = getAnnotation(node, .copyWith)!;
      final value = getComputedAnnotationFieldValue(annotation, "anyField");

      expect(value, isNull);
    });

    test(
      "extracts custom name from `name` property of Serialize annotation",
      () {
        final node = _findDeclarations<ClassDeclaration>(
          unit,
          "UserSerializeCustom",
        ).first;

        final annotation = getAnnotation(node, .serialize)!;
        final value = getComputedAnnotationFieldValue(
          annotation,
          "name",
        )?.toStringValue();

        expect(value, equals("toDto"));
      },
    );

    test(
      "extracts custom deserialization name from `name` property of Deserialize annotation",
      () {
        final node = _findDeclarations<ClassDeclaration>(
          unit,
          "UserDeserializeCustom",
        ).first;

        final annotation = getAnnotation(node, .deserialize)!;
        final value = getComputedAnnotationFieldValue(
          annotation,
          "name",
        )?.toStringValue();

        expect(
          value,
          equals("fromDto"),
        );
      },
    );
  });
}
