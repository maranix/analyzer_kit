import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/types.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:test/test.dart';

ClassDeclaration _parseClass(String source) {
  final result = parseString(content: source);
  return result.unit.declarations.whereType<ClassDeclaration>().first;
}

void main() {
  group('Primary constructor field extraction', () {
    test('extracts declaring positional and named parameters', () {
      final cls = _parseClass('''
final class Point(final int x, {required final int y, int? nonField});
''');
      final fields = extractGeneratableFields(cls);
      expect(fields.map((f) => f.name), ['x', 'y']);
      expect(fields[0].isPositional, isTrue);
      expect(fields[1].isPositional, isFalse);
      expect(extractPrimaryConstructorName(cls), isNull);
    });

    test('extracts named primary constructor name', () {
      final cls = _parseClass('''
final class Point.create(final int x, final int y);
''');
      expect(extractPrimaryConstructorName(cls), 'create');
      expect(extractGeneratableFields(cls).map((f) => f.name), ['x', 'y']);
    });

    test('treats .new primary constructor name as unnamed', () {
      final cls = _parseClass('''
final class Point.new(final int x);
''');
      expect(extractPrimaryConstructorName(cls), isNull);
    });
  });

  group('Out-of-sync field detection', () {
    test('isCopyWithInSync detects missing field parameter', () {
      final cls = _parseClass('''
class User {
  User({required this.name, required this.age});
  final String name;
  final int age;

  User copyWith({String? name}) => User(name: name ?? this.name, age: age);
}
''');
      final method = findMethodDeclaration(cls, 'copyWith')!;
      final fields = extractGeneratableFields(cls);
      final sync = checkCopyWithSync(method, fields);
      expect(sync.isInSync, isFalse);
      expect(sync.missingFields, ['age']);
      expect(sync.summary, 'missing: age');
    });

    test('checkCopyWithSync detects removed/extra field parameter', () {
      final cls = _parseClass('''
class User {
  User({required this.name});
  final String name;

  User copyWith({String? name, int? removedAge}) =>
      User(name: name ?? this.name);
}
''');
      final method = findMethodDeclaration(cls, 'copyWith')!;
      final fields = extractGeneratableFields(cls);
      final sync = checkCopyWithSync(method, fields);
      expect(sync.isInSync, isFalse);
      expect(sync.extraFields, ['removedAge']);
      expect(sync.summary, 'extra: removedAge');
    });

    test('checkSerializeSync detects removed/extra map key', () {
      final cls = _parseClass('''
class User {
  User({required this.name});
  final String name;

  Map<String, dynamic> toMap() => {'name': name, 'oldField': 1};
}
''');
      final method = findMethodDeclaration(cls, 'toMap')!;
      final fields = extractGeneratableFields(cls);
      final sync = checkSerializeSync(method.body, fields);
      expect(sync.isInSync, isFalse);
      expect(sync.extraFields, ['oldField']);
    });

    test('isCopyWithInSync returns true when all fields are parameters', () {
      final cls = _parseClass('''
class User {
  User({required this.name, required this.age});
  final String name;
  final int age;

  User copyWith({String? name, int? age}) =>
      User(name: name ?? this.name, age: age ?? this.age);
}
''');
      final method = findMethodDeclaration(cls, 'copyWith')!;
      final fields = extractGeneratableFields(cls);
      expect(isCopyWithInSync(method, fields), isTrue);
    });

    test(
      'isBodyInSync detects missing field in toString, ==, hashCode, toMap',
      () {
        final cls = _parseClass('''
class User {
  User({required this.name, required this.age});
  final String name;
  final int age;

  @override
  String toString() => 'User(name: \$name)';

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is User && other.name == name;

  Map<String, dynamic> toMap() => {'name': name};
}
''');
        final fields = extractGeneratableFields(cls);
        expect(
          isBodyInSync(findMethodDeclaration(cls, 'toString')!.body, fields),
          isFalse,
        );
        expect(
          isBodyInSync(findMethodDeclaration(cls, 'hashCode')!.body, fields),
          isFalse,
        );
        expect(
          isBodyInSync(findMethodDeclaration(cls, '==')!.body, fields),
          isFalse,
        );
        expect(
          isBodyInSync(findMethodDeclaration(cls, 'toMap')!.body, fields),
          isFalse,
        );
      },
    );

    test('isDeserializeInSync detects missing field in factory fromMap', () {
      final cls = _parseClass('''
class User {
  User({required this.name, required this.age});
  final String name;
  final int age;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(name: map['name'] as String, age: 0);
  }
}
''');
      final member = findDeserializeMember(cls, 'fromMap')!;
      final fields = extractGeneratableFields(cls);
      expect(isDeserializeInSync(member, fields), isFalse);
    });

    test('isDeserializeInSync returns true when all fields are mapped', () {
      final cls = _parseClass('''
final class Point(final int x, final int y) {
  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(map['x'] as int, map['y'] as int);
  }
}
''');
      final member = findDeserializeMember(cls, 'fromMap')!;
      final fields = extractGeneratableFields(cls);
      expect(isDeserializeInSync(member, fields), isTrue);
    });

    test('checkBodySync and checkSerializeSync handle redacted fields', () {
      final cls = _parseClass('''
class Secret {
  Secret({required this.id, required this.userId, required this.password});
  final String id;
  @Redact({.overrideToString, .serialize})
  final String userId;
  @Redact({.overrideToString, .serialize}, '***')
  final String password;

  @override
  String toString() =>
      'Secret(id: \$id, userId: [REDACTED], password: ***)';

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': '[REDACTED]',
    'password': '***',
  };
}
''');
      final fields = extractGeneratableFields(cls);
      final toStringMethod = findMethodDeclaration(cls, 'toString')!;
      final toMapMethod = findMethodDeclaration(cls, 'toMap')!;

      expect(
        checkBodySync(
          toStringMethod.body,
          fields,
          feature: FeatureAnnotation.overrideToString,
        ).isInSync,
        isTrue,
      );
      expect(checkSerializeSync(toMapMethod.body, fields).isInSync, isTrue);

      // Unredacted methods fail sync check
      final unredactedCls = _parseClass('''
class Secret {
  Secret({required this.id, required this.password});
  final String id;
  @redact
  final String password;

  @override
  String toString() => 'Secret(id: \$id, password: \$password)';

  Map<String, dynamic> toMap() => {'id': id, 'password': password};
}
''');
      final unredactedToString = findMethodDeclaration(
        unredactedCls,
        'toString',
      )!;
      final toStringSync = checkBodySync(
        unredactedToString.body,
        extractGeneratableFields(unredactedCls),
        feature: FeatureAnnotation.overrideToString,
      );
      expect(toStringSync.isInSync, isFalse);
      expect(toStringSync.driftReasons, contains('unredacted field: password'));

      // Check serialize drift when field is redacted for serialize
      final serializeFields = [
        const ClassField(name: 'id', type: 'String'),
        const ClassField(
          name: 'password',
          type: 'String',
          redactedFor: {FeatureAnnotation.serialize},
        ),
      ];
      final unredactedToMap = findMethodDeclaration(unredactedCls, 'toMap')!;
      final serSync = checkSerializeSync(unredactedToMap.body, serializeFields);
      expect(serSync.isInSync, isFalse);
      expect(serSync.driftReasons, contains('unredacted field: password'));

      // Placeholder mismatch in toString and toMap
      const customPlaceholderFields = [
        ClassField(name: 'id', type: 'String'),
        ClassField(
          name: 'userId',
          type: 'String',
          redactedFor: {
            FeatureAnnotation.overrideToString,
            FeatureAnnotation.serialize,
          },
          redactPlaceholder: 'MASKED',
        ),
        ClassField(
          name: 'password',
          type: 'String',
          redactedFor: {
            FeatureAnnotation.overrideToString,
            FeatureAnnotation.serialize,
          },
          redactPlaceholder: '***',
        ),
      ];
      final toStringMismatch = checkBodySync(
        toStringMethod.body,
        customPlaceholderFields,
        feature: FeatureAnnotation.overrideToString,
      );
      expect(toStringMismatch.isInSync, isFalse);
      expect(
        toStringMismatch.driftReasons,
        contains('redacted placeholder mismatch: userId'),
      );

      final toMapMismatch = checkSerializeSync(
        toMapMethod.body,
        customPlaceholderFields,
      );
      expect(toMapMismatch.isInSync, isFalse);
      expect(
        toMapMismatch.driftReasons,
        contains('redacted placeholder mismatch: userId'),
      );
    });

    test(
      'checkSerializeSync and checkDeserializeSync validate fieldRename keys',
      () {
        final cls = _parseClass('''
class Profile {
  Profile({required this.firstName, required this.lastName});
  final String firstName;
  final String lastName;

  Map<String, dynamic> toMap() => {
    'first_name': firstName,
    'last_name': lastName,
  };

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
    );
  }
}
''');
        final fields = extractGeneratableFields(cls);
        final toMap = findMethodDeclaration(cls, 'toMap')!;
        final fromMap = findDeserializeMember(cls, 'fromMap')!;

        expect(
          checkSerializeSync(
            toMap.body,
            fields,
            fieldRename: FieldRename.snake,
          ).isInSync,
          isTrue,
        );
        expect(
          checkDeserializeSync(
            fromMap,
            fields,
            fieldRename: FieldRename.snake,
          ).isInSync,
          isTrue,
        );

        // Drift when fieldRename is none (or changed to kebab)
        final serDrift = checkSerializeSync(
          toMap.body,
          fields,
          fieldRename: FieldRename.kebab,
        );
        expect(serDrift.isInSync, isFalse);
        expect(serDrift.missingFields, ['first-name', 'last-name']);
        expect(serDrift.extraFields, ['first_name', 'last_name']);

        final deserDrift = checkDeserializeSync(
          fromMap,
          fields,
          fieldRename: FieldRename.kebab,
        );
        expect(deserDrift.isInSync, isFalse);
        expect(deserDrift.missingFields, ['first-name', 'last-name']);
        expect(deserDrift.extraFields, ['first_name', 'last_name']);
      },
    );
  });
}
