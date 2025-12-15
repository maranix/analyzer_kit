import 'package:dart_analyzer_kit/src/utils/code_gen_utils.dart';
import 'package:test/test.dart';
import '../utils/test_utils.dart';

void main() {
  group('AddCopyWithMethod', () {
    test('generates copyWith for class with fields', () async {
      final code = '''
      class User {
        final String name;
        final int age;
        User(this.name, this.age);
      }
      ''';

      final element = await getClassElement(code, className: 'User');
      final generated = generateCopyWithMethod(element);

      expect(generated, contains('User copyWith({'));
      expect(generated, contains('String? name,'));
      expect(generated, contains('int? age'));
      expect(generated, contains('return User('));
    });

    test('generates copyWith for class with nullable fields', () async {
      final code = '''
      class User {
        final String? name;
        User(this.name);
      }
      ''';

      final element = await getClassElement(code, className: 'User');
      final generated = generateCopyWithMethod(element);

      expect(generated, contains('String? name'));
      expect(generated, contains('name: name ?? this.name'));
    });
  });
}
