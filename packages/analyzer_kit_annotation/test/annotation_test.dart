import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('CopyWith', () {
    test('instance can be created', () {
      expect(const CopyWith(), isA<CopyWith>());
    });

    test('constant is available', () {
      expect(copyWith, isA<CopyWith>());
    });

    test('constant equals constructor', () {
      expect(copyWith, equals(const CopyWith()));
    });
  });

  group('OverrideEquality', () {
    test('instance can be created', () {
      expect(const OverrideEquality(), isA<OverrideEquality>());
    });

    test('constant is available', () {
      expect(overrideEquality, isA<OverrideEquality>());
    });

    test('constant equals constructor', () {
      expect(overrideEquality, equals(const OverrideEquality()));
    });
  });

  group('OverrideToString', () {
    test('instance can be created', () {
      expect(const OverrideToString(), isA<OverrideToString>());
    });

    test('constant is available', () {
      expect(overrideToString, isA<OverrideToString>());
    });

    test('constant equals constructor', () {
      expect(overrideToString, equals(const OverrideToString()));
    });
  });

  group('Serialize', () {
    test('instance can be created', () {
      expect(const Serialize(), isA<Serialize>());
    });

    test('instance with custom name can be created', () {
      expect(const Serialize(name: .custom('test')), isA<Serialize>());
    });

    test('constant is available', () {
      expect(serialize, isA<Serialize>());
    });

    test('constant equals constructor', () {
      expect(serialize, equals(const Serialize()));
    });
  });

  group('Deserialize', () {
    test('instance can be created', () {
      expect(const Deserialize(), isA<Deserialize>());
    });

    test('instance with custom name can be created', () {
      expect(const Deserialize(name: .custom('test')), isA<Deserialize>());
    });

    test('constant is available', () {
      expect(deserialize, isA<Deserialize>());
    });

    test('constant equals constructor', () {
      expect(deserialize, equals(const Deserialize()));
    });
  });
}
