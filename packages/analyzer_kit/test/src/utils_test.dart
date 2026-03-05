import 'package:analyzer/dart/analysis/utilities.dart' show parseString;
import 'package:analyzer/dart/ast/ast.dart' show ClassDeclaration;
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:test/test.dart';

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
  group('extractGeneratableFields', () {
    test('extracts basic final fields', () {
      final node = _parseClass('''
class User {
  final String name;
  final int age;
  User({required this.name, required this.age});
}
''');

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(2));
      expect(fields[0].name, 'name');
      expect(fields[0].type, 'String');
      expect(fields[1].name, 'age');
      expect(fields[1].type, 'int');
    });

    test('excludes static fields', () {
      final node = _parseClass('''
class User {
  static const maxAge = 150;
  final String name;
  User({required this.name});
}
''');

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(1));
      expect(fields[0].name, 'name');
    });

    test('excludes late fields', () {
      final node = _parseClass('''
class User {
  late String name;
  final int age;
  User({required this.age});
}
''');

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(1));
      expect(fields[0].name, 'age');
    });

    test('returns empty for class with no fields', () {
      final node = _parseClass('''
class Empty {
  const Empty();
}
''');

      final fields = extractGeneratableFields(node).toList();
      expect(fields, isEmpty);
    });

    test('handles multiple field types', () {
      final node = _parseClass('''
class Data {
  final String name;
  final int? age;
  final List<String> tags;
  final Map<String, dynamic> meta;
  Data({required this.name, this.age, required this.tags, required this.meta});
}
''');

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(4));
      expect(fields[0].type, 'String');
      expect(fields[1].type, 'int?');
      expect(fields[2].type, 'List<String>');
      expect(fields[3].type, 'Map<String, dynamic>');
    });

    test('excludes only non-generatable fields', () {
      final node = _parseClass('''
class Mixed {
  final String name;
  static final String label = 'mixed';
  late int count;
  final bool active;
}
''');

      final fields = extractGeneratableFields(node).toList();
      expect(fields, hasLength(2));
      expect(fields.map((f) => f.name), containsAll(['name', 'active']));
    });
  });

  group('hasFeatureEnabled', () {
    test('returns true when direct annotation is present', () {
      final node = _parseClassByName('''
class CopyWith { const CopyWith(); }

@CopyWith()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(hasFeatureEnabled(node, FeatureAnnotation.copyWith), isTrue);
    });

    test('returns false when no annotation present', () {
      final node = _parseClass('''
class User {
  final String name;
  User({required this.name});
}
''');

      expect(hasFeatureEnabled(node, FeatureAnnotation.copyWith), isFalse);
    });

    test(
      'returns true when @DataClass is present and feature not disabled',
      () {
        final node = _parseClassByName('''
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

@DataClass()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

        expect(hasFeatureEnabled(node, FeatureAnnotation.copyWith), isTrue);
        expect(
          hasFeatureEnabled(node, FeatureAnnotation.overrideToString),
          isTrue,
        );
        expect(
          hasFeatureEnabled(node, FeatureAnnotation.overrideEquality),
          isTrue,
        );
        expect(hasFeatureEnabled(node, FeatureAnnotation.serialize), isTrue);
        expect(hasFeatureEnabled(node, FeatureAnnotation.deserialize), isTrue);
      },
    );

    test('returns false when @DataClass explicitly disables feature', () {
      final node = _parseClassByName('''
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
''', 'User');

      expect(hasFeatureEnabled(node, FeatureAnnotation.copyWith), isFalse);
      // Others should still be enabled
      expect(
        hasFeatureEnabled(node, FeatureAnnotation.overrideToString),
        isTrue,
      );
    });

    test('returns true when @DataClass has no arguments (all defaults)', () {
      final node = _parseClassByName('''
class DataClass {
  const DataClass();
}

@DataClass()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(hasFeatureEnabled(node, FeatureAnnotation.copyWith), isTrue);
    });

    test('case-insensitive annotation matching', () {
      final node = _parseClassByName('''
class copywith { const copywith(); }

@copywith()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(hasFeatureEnabled(node, FeatureAnnotation.copyWith), isTrue);
    });

    test('returns false when different annotation is present', () {
      final node = _parseClassByName('''
class Serialize { const Serialize(); }

@Serialize()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(hasFeatureEnabled(node, FeatureAnnotation.copyWith), isFalse);
    });

    test(
      'returns true when multiple features are disabled but queried one is not',
      () {
        final node = _parseClassByName('''
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

@DataClass(overrideToString: false, serialize: false)
class User {
  final String name;
  User({required this.name});
}
''', 'User');

        expect(hasFeatureEnabled(node, FeatureAnnotation.copyWith), isTrue);
        expect(
          hasFeatureEnabled(node, FeatureAnnotation.overrideToString),
          isFalse,
        );
        expect(hasFeatureEnabled(node, FeatureAnnotation.serialize), isFalse);
      },
    );
  });

  group('extractFeatureMethodName', () {
    test('returns default name for direct annotation with no arguments', () {
      final node = _parseClassByName('''
class Serialize { const Serialize(); }

@Serialize()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, 'toMap'),
        'toMap',
      );
    });

    test('returns null when no relevant annotation present', () {
      final node = _parseClass('''
class User {
  final String name;
  User({required this.name});
}
''');

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, 'toMap'),
        isNull,
      );
    });

    test('returns default name for @DataClass when feature is enabled', () {
      final node = _parseClassByName('''
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

@DataClass()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, 'toMap'),
        'toMap',
      );
    });

    test('returns null for @DataClass when feature is disabled', () {
      final node = _parseClassByName('''
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
''', 'User');

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, 'toMap'),
        isNull,
      );
    });

    test(
      'returns default name for FeatureAnnotation.dataClass with annotation',
      () {
        final node = _parseClassByName('''
class DataClass { const DataClass(); }

@DataClass()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

        expect(
          extractFeatureMethodName(
            node,
            FeatureAnnotation.dataClass,
            'defaultName',
          ),
          'defaultName',
        );
      },
    );

    test('returns null for FeatureAnnotation.dataClass without annotation', () {
      final node = _parseClass('''
class User {
  final String name;
  User({required this.name});
}
''');

      expect(
        extractFeatureMethodName(
          node,
          FeatureAnnotation.dataClass,
          'defaultName',
        ),
        isNull,
      );
    });

    test('extracts custom name from .custom() annotation argument', () {
      final node = _parseClassByName('''
class Serialize {
  const Serialize({this.name});
  final Object? name;
}

@Serialize(name: .custom('toDto'))
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, 'toMap'),
        'toDto',
      );
    });

    test('extracts method name from dot shorthand like .toMap()', () {
      final node = _parseClassByName('''
class Serialize {
  const Serialize({this.name});
  final Object? name;
}

@Serialize(name: .toMap())
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, 'toMap'),
        'toMap',
      );
    });

    test('returns default name when annotation has non-name arguments', () {
      final node = _parseClassByName('''
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
''', 'User');

      expect(
        extractFeatureMethodName(node, FeatureAnnotation.serialize, 'toMap'),
        'toMap',
      );
    });

    test('returns default for deserialization with no arguments', () {
      final node = _parseClassByName('''
class Deserialize { const Deserialize(); }

@Deserialize()
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(
        extractFeatureMethodName(
          node,
          FeatureAnnotation.deserialize,
          'fromMap',
        ),
        'fromMap',
      );
    });

    test('extracts custom deserialization name from .custom()', () {
      final node = _parseClassByName('''
class Deserialize {
  const Deserialize({this.name});
  final Object? name;
}

@Deserialize(name: .custom('fromDto'))
class User {
  final String name;
  User({required this.name});
}
''', 'User');

      expect(
        extractFeatureMethodName(
          node,
          FeatureAnnotation.deserialize,
          'fromMap',
        ),
        'fromDto',
      );
    });
  });
}
