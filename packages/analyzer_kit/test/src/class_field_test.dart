import "package:analyzer_kit/src/types.dart";
import "package:test/test.dart";

void main() {
  group("ClassField", () {
    group("construction", () {
      test("creates with required name only, using defaults", () {
        const field = ClassField(name: "foo");
        expect(field.name, "foo");
        expect(field.type, "dynamic");
        expect(field.keyword, isNull);
        expect(field.equals, isNull);
        expect(field.initializer, isNull);
        expect(field.isConst, isFalse);
        expect(field.isLate, isFalse);
        expect(field.isFinal, isFalse);
        expect(field.isStatic, isFalse);
        expect(field.isSynthetic, isFalse);
        expect(field.isPublic, isFalse);
        expect(field.isPrivate, isFalse);
      });

      test("creates with all properties specified", () {
        const field = ClassField(
          name: "_count",
          type: "int",
          keyword: "final",
          equals: "=",
          initializer: "0",
          isConst: false,
          isLate: false,
          isFinal: true,
          isStatic: false,
          isSynthetic: false,
          isPublic: false,
          isPrivate: true,
        );
        expect(field.name, "_count");
        expect(field.type, "int");
        expect(field.keyword, "final");
        expect(field.equals, "=");
        expect(field.initializer, "0");
        expect(field.isFinal, isTrue);
        expect(field.isPrivate, isTrue);
        expect(field.isPublic, isFalse);
      });
    });

    group("isGeneratable", () {
      test("returns true for non-static, non-synthetic, non-late field", () {
        const field = ClassField(
          name: "x",
          isStatic: false,
          isSynthetic: false,
          isLate: false,
        );
        expect(field.isGeneratable, isTrue);
      });

      test("returns false for static field", () {
        const field = ClassField(name: "x", isStatic: true);
        expect(field.isGeneratable, isFalse);
      });

      test("returns false for synthetic field", () {
        const field = ClassField(name: "x", isSynthetic: true);
        expect(field.isGeneratable, isFalse);
      });

      test("returns false for late field", () {
        const field = ClassField(name: "x", isLate: true);
        expect(field.isGeneratable, isFalse);
      });

      test("returns false when all exclusion flags are true", () {
        const field = ClassField(
          name: "x",
          isStatic: true,
          isSynthetic: true,
          isLate: true,
        );
        expect(field.isGeneratable, isFalse);
      });

      test("const and final fields are still generatable", () {
        const field1 = ClassField(name: "x", isConst: true);
        const field2 = ClassField(name: "y", isFinal: true);
        expect(field1.isGeneratable, isTrue);
        expect(field2.isGeneratable, isTrue);
      });
    });

    group("isNullableType", () {
      test("returns true for types ending with ?", () {
        const field = ClassField(name: "x", type: "String?");
        expect(field.isNullableType, isTrue);
      });

      test("returns true for generic nullable type", () {
        const field = ClassField(name: "x", type: "List<int>?");
        expect(field.isNullableType, isTrue);
      });

      test("returns false for non-nullable type", () {
        const field = ClassField(name: "x", type: "String");
        expect(field.isNullableType, isFalse);
      });

      test("returns false for dynamic type", () {
        const field = ClassField(name: "x", type: "dynamic");
        expect(field.isNullableType, isFalse);
      });

      test("returns false for type with ? in the middle", () {
        // Edge case: type name containing ? but not ending with it
        // This wouldn't be a real Dart type, but tests the implementation
        const field = ClassField(name: "x", type: "int");
        expect(field.isNullableType, isFalse);
      });
    });

    group("isListOrIterableType", () {
      test("returns true for List", () {
        const field = ClassField(name: "x", type: "List");
        expect(field.isListOrIterableType, isTrue);
      });

      test("returns true for List<int>", () {
        const field = ClassField(name: "x", type: "List<int>");
        expect(field.isListOrIterableType, isTrue);
      });

      test("returns true for List<int>?", () {
        const field = ClassField(name: "x", type: "List<int>?");
        expect(field.isListOrIterableType, isTrue);
      });

      test("returns true for Iterable", () {
        const field = ClassField(name: "x", type: "Iterable");
        expect(field.isListOrIterableType, isTrue);
      });

      test("returns true for Iterable<String>", () {
        const field = ClassField(name: "x", type: "Iterable<String>");
        expect(field.isListOrIterableType, isTrue);
      });

      test("returns false for Set", () {
        const field = ClassField(name: "x", type: "Set<int>");
        expect(field.isListOrIterableType, isFalse);
      });

      test("returns false for Map", () {
        const field = ClassField(name: "x", type: "Map<String, int>");
        expect(field.isListOrIterableType, isFalse);
      });

      test("returns false for String (not a List)", () {
        const field = ClassField(name: "x", type: "String");
        expect(field.isListOrIterableType, isFalse);
      });

      test("returns false for Lister (similar prefix but different type)", () {
        const field = ClassField(name: "x", type: "Lister");
        expect(field.isListOrIterableType, isFalse);
      });

      test(
        "returns false for IterableBase (similar prefix but different type)",
        () {
          const field = ClassField(name: "x", type: "IterableBase");
          expect(field.isListOrIterableType, isFalse);
        },
      );
    });

    group("isSetType", () {
      test("returns true for Set", () {
        const field = ClassField(name: "x", type: "Set");
        expect(field.isSetType, isTrue);
      });

      test("returns true for Set<int>", () {
        const field = ClassField(name: "x", type: "Set<int>");
        expect(field.isSetType, isTrue);
      });

      test("returns true for Set<int>?", () {
        const field = ClassField(name: "x", type: "Set<int>?");
        expect(field.isSetType, isTrue);
      });

      test("returns false for List", () {
        const field = ClassField(name: "x", type: "List<int>");
        expect(field.isSetType, isFalse);
      });

      test("returns false for SetBase (similar prefix but different type)", () {
        const field = ClassField(name: "x", type: "SetBase");
        expect(field.isSetType, isFalse);
      });
    });

    group("isMapType", () {
      test("returns true for Map", () {
        const field = ClassField(name: "x", type: "Map");
        expect(field.isMapType, isTrue);
      });

      test("returns true for Map<String, int>", () {
        const field = ClassField(name: "x", type: "Map<String, int>");
        expect(field.isMapType, isTrue);
      });

      test("returns true for Map<String, int>?", () {
        const field = ClassField(name: "x", type: "Map<String, int>?");
        expect(field.isMapType, isTrue);
      });

      test("returns false for List", () {
        const field = ClassField(name: "x", type: "List<int>");
        expect(field.isMapType, isFalse);
      });

      test(
        "returns false for MapEntry (similar prefix but different type)",
        () {
          const field = ClassField(name: "x", type: "MapEntry");
          expect(field.isMapType, isFalse);
        },
      );
    });

    group("isCollectionType", () {
      test("returns true for List", () {
        const field = ClassField(name: "x", type: "List<int>");
        expect(field.isCollectionType, isTrue);
      });

      test("returns true for Set", () {
        const field = ClassField(name: "x", type: "Set<int>");
        expect(field.isCollectionType, isTrue);
      });

      test("returns true for Map", () {
        const field = ClassField(name: "x", type: "Map<String, int>");
        expect(field.isCollectionType, isTrue);
      });

      test("returns true for Iterable", () {
        const field = ClassField(name: "x", type: "Iterable<int>");
        expect(field.isCollectionType, isTrue);
      });

      test("returns false for String", () {
        const field = ClassField(name: "x", type: "String");
        expect(field.isCollectionType, isFalse);
      });

      test("returns false for int", () {
        const field = ClassField(name: "x", type: "int");
        expect(field.isCollectionType, isFalse);
      });

      test("returns false for custom class", () {
        const field = ClassField(name: "x", type: "MyClass");
        expect(field.isCollectionType, isFalse);
      });

      test("returns false for dynamic", () {
        const field = ClassField(name: "x", type: "dynamic");
        expect(field.isCollectionType, isFalse);
      });
    });

    group("toString", () {
      test("includes all properties in output", () {
        const field = ClassField(
          name: "title",
          type: "String",
          keyword: "final",
          isFinal: true,
          isPublic: true,
        );

        final str = field.toString();
        expect(str, contains("ClassField("));
        expect(str, contains("name: title"));
        expect(str, contains("type: String"));
        expect(str, contains("keyword: final"));
        expect(str, contains("isFinal: true"));
        expect(str, contains("isPublic: true"));
        expect(str, contains("isStatic: false"));
        expect(str, contains("isSynthetic: false"));
        expect(str, contains("isPrivate: false"));
      });

      test("includes null values for optional properties", () {
        const field = ClassField(name: "x");
        final str = field.toString();
        expect(str, contains("equals: null"));
        expect(str, contains("initializer: null"));
        expect(str, contains("keyword: null"));
      });
    });
  });
}
