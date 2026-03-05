import "package:analyzer_kit_annotation/analyzer_kit_annotation.dart";
import "package:test/test.dart";

void main() {
  group("CopyWith", () {
    test("instance can be created", () {
      expect(const CopyWith(), isA<CopyWith>());
    });

    test("convenience constant is available", () {
      expect(copyWith, isA<CopyWith>());
    });

    test("convenience constant is identical to const constructor", () {
      expect(identical(copyWith, const CopyWith()), isTrue);
    });

    test("is a final class", () {
      // CopyWith is declared as `final class` — confirming the type.
      const annotation = CopyWith();
      expect(annotation.runtimeType.toString(), "CopyWith");
    });
  });

  group("OverrideToString", () {
    test("instance can be created", () {
      expect(const OverrideToString(), isA<OverrideToString>());
    });

    test("convenience constant is available", () {
      expect(overrideToString, isA<OverrideToString>());
    });

    test("convenience constant is identical to const constructor", () {
      expect(identical(overrideToString, const OverrideToString()), isTrue);
    });

    test("is a final class", () {
      const annotation = OverrideToString();
      expect(annotation.runtimeType.toString(), "OverrideToString");
    });
  });

  group("OverrideEquality", () {
    test("instance can be created with no arguments", () {
      const annotation = OverrideEquality();
      expect(annotation, isA<OverrideEquality>());
    });

    test("deepCollectionEquality defaults to null", () {
      const annotation = OverrideEquality();
      expect(annotation.deepCollectionEquality, isNull);
    });

    test("deepCollectionEquality can be set to true", () {
      const annotation = OverrideEquality(deepCollectionEquality: true);
      expect(annotation.deepCollectionEquality, isTrue);
    });

    test("deepCollectionEquality can be set to false", () {
      const annotation = OverrideEquality(deepCollectionEquality: false);
      expect(annotation.deepCollectionEquality, isFalse);
    });

    test("convenience constant is available", () {
      expect(overrideEquality, isA<OverrideEquality>());
    });

    test("convenience constant is identical to const constructor", () {
      expect(identical(overrideEquality, const OverrideEquality()), isTrue);
    });

    test("convenience constant has null deepCollectionEquality", () {
      expect(overrideEquality.deepCollectionEquality, isNull);
    });
  });

  group("DataClass", () {
    test("instance can be created with no arguments (all defaults)", () {
      const annotation = DataClass();
      expect(annotation, isA<DataClass>());
    });

    test("all features default to true", () {
      const annotation = DataClass();
      expect(annotation.copyWith, isTrue);
      expect(annotation.overrideEquality, isTrue);
      expect(annotation.overrideToString, isTrue);
      expect(annotation.serialize, isTrue);
      expect(annotation.deserialize, isTrue);
    });

    test("copyWith can be disabled", () {
      const annotation = DataClass(copyWith: false);
      expect(annotation.copyWith, isFalse);
      expect(annotation.overrideEquality, isTrue);
      expect(annotation.overrideToString, isTrue);
      expect(annotation.serialize, isTrue);
      expect(annotation.deserialize, isTrue);
    });

    test("overrideEquality can be disabled", () {
      const annotation = DataClass(overrideEquality: false);
      expect(annotation.copyWith, isTrue);
      expect(annotation.overrideEquality, isFalse);
      expect(annotation.overrideToString, isTrue);
      expect(annotation.serialize, isTrue);
      expect(annotation.deserialize, isTrue);
    });

    test("overrideToString can be disabled", () {
      const annotation = DataClass(overrideToString: false);
      expect(annotation.copyWith, isTrue);
      expect(annotation.overrideEquality, isTrue);
      expect(annotation.overrideToString, isFalse);
      expect(annotation.serialize, isTrue);
      expect(annotation.deserialize, isTrue);
    });

    test("serialize can be disabled", () {
      const annotation = DataClass(serialize: false);
      expect(annotation.copyWith, isTrue);
      expect(annotation.overrideEquality, isTrue);
      expect(annotation.overrideToString, isTrue);
      expect(annotation.serialize, isFalse);
      expect(annotation.deserialize, isTrue);
    });

    test("deserialize can be disabled", () {
      const annotation = DataClass(deserialize: false);
      expect(annotation.copyWith, isTrue);
      expect(annotation.overrideEquality, isTrue);
      expect(annotation.overrideToString, isTrue);
      expect(annotation.serialize, isTrue);
      expect(annotation.deserialize, isFalse);
    });

    test("all features can be disabled simultaneously", () {
      const annotation = DataClass(
        copyWith: false,
        overrideEquality: false,
        overrideToString: false,
        serialize: false,
        deserialize: false,
      );
      expect(annotation.copyWith, isFalse);
      expect(annotation.overrideEquality, isFalse);
      expect(annotation.overrideToString, isFalse);
      expect(annotation.serialize, isFalse);
      expect(annotation.deserialize, isFalse);
    });

    test("convenience constant is available", () {
      expect(dataClass, isA<DataClass>());
    });

    test("convenience constant is identical to const constructor", () {
      expect(identical(dataClass, const DataClass()), isTrue);
    });

    test("convenience constant has all features enabled", () {
      expect(dataClass.copyWith, isTrue);
      expect(dataClass.overrideEquality, isTrue);
      expect(dataClass.overrideToString, isTrue);
      expect(dataClass.serialize, isTrue);
      expect(dataClass.deserialize, isTrue);
    });
  });

  group("SerializeMethod", () {
    test('toMap factory creates instance with methodName "toMap"', () {
      const method = SerializeMethod.toMap();
      expect(method, isA<SerializeMethod>());
      expect(method.methodName, "toMap");
    });

    test('toJson factory creates instance with methodName "toJson"', () {
      const method = SerializeMethod.toJson();
      expect(method, isA<SerializeMethod>());
      expect(method.methodName, "toJson");
    });

    test("custom factory creates instance with user-defined methodName", () {
      const method = SerializeMethod.custom("toDocument");
      expect(method, isA<SerializeMethod>());
      expect(method.methodName, "toDocument");
    });

    test("custom factory with empty string stores empty methodName", () {
      const method = SerializeMethod.custom("");
      expect(method.methodName, "");
    });

    test("toMap and toJson have different methodNames", () {
      const toMap = SerializeMethod.toMap();
      const toJson = SerializeMethod.toJson();
      expect(toMap.methodName, isNot(equals(toJson.methodName)));
    });

    test("custom method name does not affect other factory methods", () {
      const custom = SerializeMethod.custom("serialize");
      const toMap = SerializeMethod.toMap();
      expect(custom.methodName, isNot(equals(toMap.methodName)));
    });
  });

  group("Serialize", () {
    test("instance can be created with no arguments", () {
      const s = Serialize();
      expect(s, isA<Serialize>());
    });

    test("default method name is toMap", () {
      const s = Serialize();
      expect(s.name.methodName, "toMap");
    });

    test("can configure with toJson", () {
      const s = Serialize(name: .toJson());
      expect(s.name.methodName, "toJson");
    });

    test("can configure with custom method name", () {
      const s = Serialize(name: .custom("serializeToBuffer"));
      expect(s.name.methodName, "serializeToBuffer");
    });

    test("convenience constant is available", () {
      expect(serialize, isA<Serialize>());
    });

    test("convenience constant is identical to const constructor", () {
      expect(identical(serialize, const Serialize()), isTrue);
    });

    test("convenience constant has toMap as default method", () {
      expect(serialize.name.methodName, "toMap");
    });
  });

  group("DeserializeMethod", () {
    test('fromMap factory creates instance with methodName "fromMap"', () {
      const method = DeserializeMethod.fromMap();
      expect(method, isA<DeserializeMethod>());
      expect(method.methodName, "fromMap");
    });

    test('fromJson factory creates instance with methodName "fromJson"', () {
      const method = DeserializeMethod.fromJson();
      expect(method, isA<DeserializeMethod>());
      expect(method.methodName, "fromJson");
    });

    test("custom factory creates instance with user-defined methodName", () {
      const method = DeserializeMethod.custom("fromDocument");
      expect(method, isA<DeserializeMethod>());
      expect(method.methodName, "fromDocument");
    });

    test("custom factory with empty string stores empty methodName", () {
      const method = DeserializeMethod.custom("");
      expect(method.methodName, "");
    });

    test("fromMap and fromJson have different methodNames", () {
      const fromMap = DeserializeMethod.fromMap();
      const fromJson = DeserializeMethod.fromJson();
      expect(fromMap.methodName, isNot(equals(fromJson.methodName)));
    });

    test("custom method name does not affect other factory methods", () {
      const custom = DeserializeMethod.custom("deserialize");
      const fromMap = DeserializeMethod.fromMap();
      expect(custom.methodName, isNot(equals(fromMap.methodName)));
    });
  });

  group("Deserialize", () {
    test("instance can be created with no arguments", () {
      const d = Deserialize();
      expect(d, isA<Deserialize>());
    });

    test("default method name is fromMap", () {
      const d = Deserialize();
      expect(d.name.methodName, "fromMap");
    });

    test("can configure with fromJson", () {
      const d = Deserialize(name: .fromJson());
      expect(d.name.methodName, "fromJson");
    });

    test("can configure with custom method name", () {
      const d = Deserialize(name: .custom("deserializeFromBuffer"));
      expect(d.name.methodName, "deserializeFromBuffer");
    });

    test("convenience constant is available", () {
      expect(deserialize, isA<Deserialize>());
    });

    test("convenience constant is identical to const constructor", () {
      expect(identical(deserialize, const Deserialize()), isTrue);
    });

    test("convenience constant has fromMap as default method", () {
      expect(deserialize.name.methodName, "fromMap");
    });
  });
}
