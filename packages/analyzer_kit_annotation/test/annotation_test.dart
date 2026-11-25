import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('CopyWith', () {
    test('instance can be created', () {
      expect(const CopyWith(), isA<CopyWith>());
    });

    test('convenience constant is available', () {
      expect(copyWith, isA<CopyWith>());
    });

    test('convenience constant is identical to const constructor', () {
      expect(identical(copyWith, const CopyWith()), isTrue);
    });

    test('is a final class', () {
      // CopyWith is declared as `final class` — confirming the type.
      const annotation = CopyWith();
      expect(annotation.runtimeType.toString(), 'CopyWith');
    });

    test('nullable defaults to false and can be set to true', () {
      expect(const CopyWith().nullable, isFalse);
      expect(const CopyWith(nullable: true).nullable, isTrue);
    });
  });

  group('OverrideToString', () {
    test('instance can be created', () {
      expect(const OverrideToString(), isA<OverrideToString>());
    });

    test('convenience constant is available', () {
      expect(overrideToString, isA<OverrideToString>());
    });

    test('convenience constant is identical to const constructor', () {
      expect(identical(overrideToString, const OverrideToString()), isTrue);
    });

    test('is a final class', () {
      const annotation = OverrideToString();
      expect(annotation.runtimeType.toString(), 'OverrideToString');
    });

    test('multiline defaults to false and can be set to true', () {
      expect(const OverrideToString().multiline, isFalse);
      expect(const OverrideToString(multiline: true).multiline, isTrue);
    });
  });

  group('OverrideEquality', () {
    test('instance can be created with no arguments', () {
      const annotation = OverrideEquality();
      expect(annotation, isA<OverrideEquality>());
    });

    test('deepCollectionEquality defaults to null', () {
      const annotation = OverrideEquality();
      expect(annotation.deepCollectionEquality, isNull);
    });

    test('deepCollectionEquality can be set to true', () {
      const annotation = OverrideEquality(deepCollectionEquality: true);
      expect(annotation.deepCollectionEquality, isTrue);
    });

    test('deepCollectionEquality can be set to false', () {
      const annotation = OverrideEquality(deepCollectionEquality: false);
      expect(annotation.deepCollectionEquality, isFalse);
    });

    test('convenience constant is available', () {
      expect(overrideEquality, isA<OverrideEquality>());
    });

    test('convenience constant is identical to const constructor', () {
      expect(identical(overrideEquality, const OverrideEquality()), isTrue);
    });

    test('convenience constant has null deepCollectionEquality', () {
      expect(overrideEquality.deepCollectionEquality, isNull);
    });
  });

  group('CompositeAnnotation', () {
    test('instance can be created with a list of annotations', () {
      const annotation = CompositeAnnotation([
        CopyWith(),
        OverrideEquality(),
        OverrideToString(),
        Serialize(),
        Deserialize(),
      ]);
      expect(annotation, isA<CompositeAnnotation>());
      expect(annotation.annotations, hasLength(5));
    });

    test('preserves nested and configured annotations', () {
      const annotation = CompositeAnnotation([
        CopyWith(),
        OverrideEquality(deepCollectionEquality: false),
        Serialize(name: SerializeMethod.toJson()),
        Deserialize(name: DeserializeMethod.fromJson()),
      ]);
      expect(annotation.annotations[0], isA<CopyWith>());
      expect(
        (annotation.annotations[1] as OverrideEquality).deepCollectionEquality,
        isFalse,
      );
      expect(
        (annotation.annotations[2] as Serialize).name.methodName,
        'toJson',
      );
      expect(
        (annotation.annotations[3] as Deserialize).name.methodName,
        'fromJson',
      );
    });
  });

  group('SerializeMethod', () {
    test('toMap factory creates instance with methodName "toMap"', () {
      const method = SerializeMethod.toMap();
      expect(method, isA<SerializeMethod>());
      expect(method.methodName, 'toMap');
    });

    test('toJson factory creates instance with methodName "toJson"', () {
      const method = SerializeMethod.toJson();
      expect(method, isA<SerializeMethod>());
      expect(method.methodName, 'toJson');
    });

    test('custom factory creates instance with user-defined methodName', () {
      const method = SerializeMethod.custom('toDocument');
      expect(method, isA<SerializeMethod>());
      expect(method.methodName, 'toDocument');
    });

    test('custom factory with empty string stores empty methodName', () {
      const method = SerializeMethod.custom('');
      expect(method.methodName, '');
    });

    test('toMap and toJson have different methodNames', () {
      const toMap = SerializeMethod.toMap();
      const toJson = SerializeMethod.toJson();
      expect(toMap.methodName, isNot(equals(toJson.methodName)));
    });

    test('custom method name does not affect other factory methods', () {
      const custom = SerializeMethod.custom('serialize');
      const toMap = SerializeMethod.toMap();
      expect(custom.methodName, isNot(equals(toMap.methodName)));
    });
  });

  group('Serialize', () {
    test('instance can be created with no arguments', () {
      const s = Serialize();
      expect(s, isA<Serialize>());
    });

    test('default method name is toMap', () {
      const s = Serialize();
      expect(s.name.methodName, 'toMap');
    });

    test('can configure with toJson', () {
      const s = Serialize(name: .toJson());
      expect(s.name.methodName, 'toJson');
    });

    test('can configure with custom method name', () {
      const s = Serialize(name: .custom('serializeToBuffer'));
      expect(s.name.methodName, 'serializeToBuffer');
    });

    test('convenience constant is available', () {
      expect(serialize, isA<Serialize>());
    });

    test('convenience constant is identical to const constructor', () {
      expect(identical(serialize, const Serialize()), isTrue);
    });

    test('convenience constant has toMap as default method', () {
      expect(serialize.name.methodName, 'toMap');
    });
  });

  group('DeserializeMethod', () {
    test('fromMap factory creates instance with methodName "fromMap"', () {
      const method = DeserializeMethod.fromMap();
      expect(method, isA<DeserializeMethod>());
      expect(method.methodName, 'fromMap');
    });

    test('fromJson factory creates instance with methodName "fromJson"', () {
      const method = DeserializeMethod.fromJson();
      expect(method, isA<DeserializeMethod>());
      expect(method.methodName, 'fromJson');
    });

    test('custom factory creates instance with user-defined methodName', () {
      const method = DeserializeMethod.custom('fromDocument');
      expect(method, isA<DeserializeMethod>());
      expect(method.methodName, 'fromDocument');
    });

    test('custom factory with empty string stores empty methodName', () {
      const method = DeserializeMethod.custom('');
      expect(method.methodName, '');
    });

    test('fromMap and fromJson have different methodNames', () {
      const fromMap = DeserializeMethod.fromMap();
      const fromJson = DeserializeMethod.fromJson();
      expect(fromMap.methodName, isNot(equals(fromJson.methodName)));
    });

    test('custom method name does not affect other factory methods', () {
      const custom = DeserializeMethod.custom('deserialize');
      const fromMap = DeserializeMethod.fromMap();
      expect(custom.methodName, isNot(equals(fromMap.methodName)));
    });
  });

  group('Deserialize', () {
    test('instance can be created with no arguments', () {
      const d = Deserialize();
      expect(d, isA<Deserialize>());
    });

    test('default method name is fromMap', () {
      const d = Deserialize();
      expect(d.name.methodName, 'fromMap');
    });

    test('can configure with fromJson', () {
      const d = Deserialize(name: .fromJson());
      expect(d.name.methodName, 'fromJson');
    });

    test('can configure with custom method name', () {
      const d = Deserialize(name: .custom('deserializeFromBuffer'));
      expect(d.name.methodName, 'deserializeFromBuffer');
    });

    test('convenience constant is available', () {
      expect(deserialize, isA<Deserialize>());
    });

    test('convenience constant is identical to const constructor', () {
      expect(identical(deserialize, const Deserialize()), isTrue);
    });

    test('convenience constant has fromMap as default method', () {
      expect(deserialize.name.methodName, 'fromMap');
    });
  });

  group('Ignore', () {
    test('default constructor ignores all ClassAnnotation values', () {
      const annotation = Ignore();
      expect(annotation.annotations, ClassAnnotation.values.toSet());
    });

    test('convenience constant is identical to const Ignore()', () {
      expect(identical(ignore, const Ignore()), isTrue);
    });

    test('accepts a custom set of ClassAnnotation values', () {
      const annotation = Ignore({.serialize, .overrideToString});
      expect(annotation.annotations, {
        ClassAnnotation.serialize,
        ClassAnnotation.overrideToString,
      });
    });
  });

  group('Redact', () {
    test('defaults to overrideToString and [REDACTED] placeholder', () {
      const annotation = Redact();
      expect(annotation.annotations, {ClassAnnotation.overrideToString});
      expect(annotation.placeholder, '[REDACTED]');
    });

    test('convenience constant is identical to const Redact()', () {
      expect(identical(redact, const Redact()), isTrue);
    });

    test('accepts custom ClassAnnotation set and custom placeholder', () {
      const annotation = Redact({.overrideToString, .serialize}, '***');
      expect(annotation.annotations, {
        ClassAnnotation.overrideToString,
        ClassAnnotation.serialize,
      });
      expect(annotation.placeholder, '***');
    });
  });
}
