import 'package:dart_analyzer_kit/src/utils/code_gen_utils.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  group('Code Gen Utils', () {
    test(
      'generateCopyWithMethod generates correct code for basic class',
      () async {
        final code = '''
      class Test {
        final String name;
        final int age;

        Test(this.name, this.age);
      }
      ''';

        final element = await getClassElement(code);
        final generated = generateCopyWithMethod(element);

        expect(generated, contains('Test copyWith({'));
        expect(generated, contains('String? name,'));
        expect(generated, contains('int? age'));
        expect(generated, contains('return Test('));
        expect(generated, contains('name: name ?? this.name,'));
        expect(generated, contains('age: age ?? this.age'));
      },
    );

    test('generateCopyWithMethod handles nullable fields', () async {
      final code = '''
      class Test {
        final String? name;

        Test(this.name);
      }
      ''';

      final element = await getClassElement(code);
      final generated = generateCopyWithMethod(element);

      expect(generated, contains('String? name'));
      expect(generated, contains('name: name ?? this.name'));
    });
  });

  group('Utils', () {
    test('hasMethod finds existing method', () async {
      final code = '''
      class Test {
        void existingMethod() {}
      }
      ''';
      final element = await getClassElement(code);
      expect(hasMethod(element, 'existingMethod'), isTrue);
      expect(hasMethod(element, 'missingMethod'), isFalse);
    });
  });
}
