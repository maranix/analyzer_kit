import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
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
  });
}
