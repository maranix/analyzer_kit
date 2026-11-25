import 'package:analyzer_kit/src/types.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:test/test.dart';

String _norm(String s) =>
    s.replaceAll(RegExp(r'\s+'), ' ').replaceAll(' .', '.');

void main() {
  group('generateCopyWithMethod', () {
    test('generates method for single field', () {
      const fields = [ClassField(name: 'name', type: 'String')];

      final result = generateCopyWithMethod('Person', fields);

      expect(result, contains('copyWith'));
      expect(result, contains('String?'));
      expect(result, contains('name'));
      expect(result, contains('Person'));
    });

    test('generates method for multiple fields', () {
      const fields = [
        ClassField(name: 'name', type: 'String'),
        ClassField(name: 'age', type: 'int'),
      ];

      final result = generateCopyWithMethod('Person', fields);

      expect(result, contains('String?'));
      expect(result, contains('int?'));
      expect(result, contains('name'));
      expect(result, contains('age'));
    });

    test('preserves single ? for already-nullable type fields (String? stays String?)', () {
      const fields = [ClassField(name: 'nickname', type: 'String?')];

      final result = generateCopyWithMethod('User', fields);

      expect(result, contains('String? nickname'));
      expect(result, isNot(contains('String??')));
    });

    test('returns the class type', () {
      const fields = [ClassField(name: 'x', type: 'int')];
      final result = generateCopyWithMethod('Point', fields);
      expect(result, contains('Point'));
    });

    test('uses named parameters', () {
      const fields = [
        ClassField(name: 'a', type: 'int'),
        ClassField(name: 'b', type: 'int'),
      ];

      final result = generateCopyWithMethod('Pair', fields);

      // Should contain ?? for null coalescing fallback to this.field
      expect(result, contains('this.a'));
      expect(result, contains('this.b'));
    });
  });

  group('generateToStringMethod', () {
    test('generates toString for single field', () {
      const fields = [ClassField(name: 'name', type: 'String')];

      final result = generateToStringMethod('Person', fields);

      expect(result, contains('@override'));
      expect(result, contains('String'));
      expect(result, contains('toString'));
      expect(result, contains('Person('));
      expect(result, contains('name: \$name'));
    });

    test('generates toString for multiple fields', () {
      const fields = [
        ClassField(name: 'name', type: 'String'),
        ClassField(name: 'age', type: 'int'),
      ];

      final result = generateToStringMethod('Person', fields);

      expect(result, contains('name: \$name'));
      expect(result, contains('age: \$age'));
    });

    test('generates toString for empty fields list', () {
      final result = generateToStringMethod('Empty', const <ClassField>[]);

      expect(result, contains('@override'));
      expect(result, contains('toString'));
      expect(result, contains('Empty('));
    });

    test('includes class name in output format', () {
      const fields = [ClassField(name: 'value', type: 'int')];
      final result = generateToStringMethod('MyClass', fields);
      expect(result, contains('MyClass('));
    });
  });

  group('generateHashCodeOverride', () {
    test('generates hashCode for basic fields', () {
      const fields = [
        ClassField(name: 'name', type: 'String'),
        ClassField(name: 'age', type: 'int'),
      ];

      final result = generateHashCodeOverride(fields);

      expect(result, contains('@override'));
      expect(result, contains('int'));
      expect(result, contains('hashCode'));
      expect(result, contains('Object.hash'));
      expect(result, contains('name'));
      expect(result, contains('age'));
    });

    test('uses deepHash for collection fields when deepCollectionEquality is null (default)', () {
      const fields = [ClassField(name: 'items', type: 'List<int>')];

      final result = generateHashCodeOverride(fields);

      expect(result, contains('deepHash(items)'));
    });

    test(
      'uses deepHash for collection fields when deepCollectionEquality is true',
      () {
        const fields = [ClassField(name: 'items', type: 'List<int>')];

        final result = generateHashCodeOverride(
          fields,
          deepCollectionEquality: true,
        );

        expect(result, contains('deepHash(items)'));
      },
    );

    test('uses Object.hashAll for List fields when deepCollectionEquality is false', () {
      const fields = [ClassField(name: 'items', type: 'List<int>')];

      final result = generateHashCodeOverride(
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('Object.hashAll(items)'));
      expect(result, isNot(contains('deepHash')));
    });

    test('uses Object.hashAllUnordered for Set fields when deepCollectionEquality is false', () {
      const fields = [ClassField(name: 'tags', type: 'Set<String>')];

      final result = generateHashCodeOverride(
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('Object.hashAllUnordered(tags)'));
    });

    test('uses Object.hashAllUnordered with entries for Map fields when deep is false', () {
      const fields = [ClassField(name: 'meta', type: 'Map<String, int>')];

      final result = generateHashCodeOverride(
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('Object.hashAllUnordered'));
      expect(result, contains('meta'));
      expect(result, contains('entries'));
    });

    test('handles nullable List with deep=false', () {
      const fields = [ClassField(name: 'items', type: 'List<int>?')];

      final result = generateHashCodeOverride(
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('items == null'));
      expect(result, contains('Object.hashAll(items!)'));
    });

    test('handles nullable Set with deep=false', () {
      const fields = [ClassField(name: 'tags', type: 'Set<int>?')];

      final result = generateHashCodeOverride(
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('tags == null'));
      expect(result, contains('Object.hashAllUnordered(tags!)'));
    });

    test('handles nullable Map with deep=false', () {
      const fields = [ClassField(name: 'meta', type: 'Map<String, int>?')];

      final result = generateHashCodeOverride(
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('meta == null'));
      expect(result, contains('Object.hashAllUnordered'));
    });

    test('non-collection fields are used directly', () {
      const fields = [ClassField(name: 'count', type: 'int')];

      final result = generateHashCodeOverride(fields);

      expect(result, contains('count'));
      expect(result, isNot(contains('deepHash')));
      expect(result, isNot(contains('Object.hashAll(count')));
    });

    test('mixed collection and non-collection fields', () {
      const fields = [
        ClassField(name: 'name', type: 'String'),
        ClassField(name: 'items', type: 'List<int>'),
        ClassField(name: 'count', type: 'int'),
      ];

      final result = generateHashCodeOverride(fields);

      expect(result, contains('name'));
      expect(result, contains('deepHash(items)'));
      expect(result, contains('count'));
    });
  });

  group('generateEqualityOperatorOverride', () {
    test('generates equality for basic fields', () {
      const fields = [
        ClassField(name: 'name', type: 'String'),
        ClassField(name: 'age', type: 'int'),
      ];

      final result = generateEqualityOperatorOverride('Person', fields);

      expect(result, contains('@override'));
      expect(result, contains('bool'));
      expect(result, contains('operator =='));
      expect(result, contains('Object'));
      expect(result, contains('identical(this, other)'));
      expect(result, contains('other is Person'));
      expect(result, contains('other.name == name'));
      expect(result, contains('other.age == age'));
    });

    test('generates equality for empty fields', () {
      final result = generateEqualityOperatorOverride(
        'Empty',
        const <ClassField>[],
      );

      expect(result, contains('identical(this, other)'));
      expect(result, contains('other is Empty'));
    });

    test('uses deepEquals for collection fields when deepCollectionEquality is null', () {
      const fields = [ClassField(name: 'items', type: 'List<int>')];

      final result = generateEqualityOperatorOverride('ListHolder', fields);

      expect(result, contains('deepEquals(other.items, items)'));
    });

    test('uses deepEquals for collection fields when deepCollectionEquality is true', () {
      const fields = [ClassField(name: 'items', type: 'List<int>')];

      final result = generateEqualityOperatorOverride(
        'ListHolder',
        fields,
        deepCollectionEquality: true,
      );

      expect(result, contains('deepEquals(other.items, items)'));
    });

    test('uses element-wise comparison for List when deep is false', () {
      const fields = [ClassField(name: 'items', type: 'List<int>')];

      final result = generateEqualityOperatorOverride(
        'ListHolder',
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('other.items.length == items.length'));
      expect(result, contains('other.items[i] != items[i]'));
      expect(result, isNot(contains('deepEquals')));
    });

    test('uses containsAll for Set when deep is false', () {
      const fields = [ClassField(name: 'tags', type: 'Set<String>')];

      final result = generateEqualityOperatorOverride(
        'SetHolder',
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('other.tags.length == tags.length'));
      expect(result, contains('other.tags.containsAll(tags)'));
    });

    test('uses entry-wise comparison for Map when deep is false', () {
      const fields = [ClassField(name: 'meta', type: 'Map<String, int>')];

      final result = generateEqualityOperatorOverride(
        'MapHolder',
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('other.meta.length == meta.length'));
      expect(result, contains('meta.entries.every'));
    });

    test('handles nullable List with deep=false', () {
      const fields = [ClassField(name: 'items', type: 'List<int>?')];

      final result = generateEqualityOperatorOverride(
        'NullableListHolder',
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('identical(other.items, items)'));
      expect(result, contains('other.items != null'));
      expect(result, contains('items != null'));
    });

    test('handles nullable Set with deep=false', () {
      const fields = [ClassField(name: 'tags', type: 'Set<int>?')];

      final result = generateEqualityOperatorOverride(
        'NullableSetHolder',
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('identical(other.tags, tags)'));
      expect(result, contains('tags!.containsAll'));
    });

    test('handles nullable Map with deep=false', () {
      const fields = [ClassField(name: 'meta', type: 'Map<String, int>?')];

      final result = generateEqualityOperatorOverride(
        'NullableMapHolder',
        fields,
        deepCollectionEquality: false,
      );

      expect(result, contains('identical(other.meta, meta)'));
      expect(result, contains('meta!.entries.every'));
    });

    test('non-collection fields use simple equality', () {
      const fields = [ClassField(name: 'value', type: 'int')];

      final result = generateEqualityOperatorOverride('Simple', fields);

      expect(result, contains('other.value == value'));
      expect(result, isNot(contains('deepEquals')));
    });
  });

  group('generateSerializeMethod', () {
    test('generates toMap with single field', () {
      const fields = [ClassField(name: 'name', type: 'String')];

      final result = generateSerializeMethod('toMap', fields);

      expect(result, contains('toMap'));
      expect(result, contains('Map<String, dynamic>'));
      expect(result, contains("'name': name"));
    });

    test('generates toMap with multiple fields', () {
      const fields = [
        ClassField(name: 'name', type: 'String'),
        ClassField(name: 'age', type: 'int'),
      ];

      final result = generateSerializeMethod('toMap', fields);

      expect(result, contains("'name': name"));
      expect(result, contains("'age': age"));
    });

    test('generates with custom method name', () {
      const fields = [ClassField(name: 'value', type: 'int')];

      final result = generateSerializeMethod('toJson', fields);

      expect(result, contains('toJson'));
    });

    test('generates for empty fields', () {
      final result = generateSerializeMethod('toMap', const <ClassField>[]);

      expect(result, contains('toMap'));
      expect(result, contains('Map<String, dynamic>'));
    });
  });

  group('generateDeserializeMethod', () {
    test('generates fromMap factory with single field', () {
      const fields = [ClassField(name: 'name', type: 'String')];

      final result = generateDeserializeMethod('Person', 'fromMap', fields);

      expect(result, contains('factory Person.fromMap'));
      expect(result, contains('Map<String, dynamic>'));
      expect(result, contains("map['name'] as String"));
    });

    test('generates fromMap factory with multiple fields', () {
      const fields = [
        ClassField(name: 'name', type: 'String'),
        ClassField(name: 'age', type: 'int'),
      ];

      final result = generateDeserializeMethod('Person', 'fromMap', fields);

      expect(result, contains("name: map['name'] as String"));
      expect(result, contains("age: map['age'] as int"));
    });

    test('generates with custom method name', () {
      const fields = [ClassField(name: 'value', type: 'int')];

      final result = generateDeserializeMethod('Config', 'fromJson', fields);

      expect(result, contains('factory Config.fromJson'));
    });

    test('generates with custom class name', () {
      const fields = [ClassField(name: 'x', type: 'double')];

      final result = generateDeserializeMethod('Point2D', 'fromMap', fields);

      expect(result, contains('factory Point2D.fromMap'));
      expect(result, contains('return Point2D('));
    });

    test('handles nullable types', () {
      const fields = [ClassField(name: 'nickname', type: 'String?')];

      final result = generateDeserializeMethod('User', 'fromMap', fields);

      expect(result, contains("map['nickname'] as String?"));
    });

    test('generates for empty fields', () {
      final result = generateDeserializeMethod(
        'Empty',
        'fromMap',
        const <ClassField>[],
      );

      expect(result, contains('factory Empty.fromMap'));
    });

    test(
      'handles positional primary constructor fields and constructorName',
      () {
        const fields = [
          ClassField(name: 'x', type: 'int', isPositional: true),
          ClassField(name: 'y', type: 'int'),
        ];

        final copyWith = generateCopyWithMethod(
          'Point',
          fields,
          constructorName: 'create',
        );
        expect(copyWith, contains('Point.create('));
        expect(copyWith, contains('x ?? this.x'));
        expect(copyWith, contains('y: y ?? this.y'));

        final deserialize = generateDeserializeMethod(
          'Point',
          'fromMap',
          fields,
          constructorName: 'create',
        );
        expect(deserialize, contains('return Point.create('));
        expect(deserialize, contains("map['x'] as int"));
        expect(deserialize, contains("y: map['y'] as int"));
      },
    );
  });

  group('nullable-aware copyWith', () {
    test('wraps nullable fields in T? Function()? when nullable is true', () {
      const fields = [
        ClassField(name: 'name', type: 'String'),
        ClassField(name: 'nickname', type: 'String?'),
      ];

      final result = generateCopyWithMethod('User', fields, nullable: true);

      expect(result, contains('String? name'));
      expect(result, contains('String? Function()? nickname'));
      expect(result, contains('name: name ?? this.name'));
      expect(
        result,
        contains('nickname: nickname != null ? nickname() : this.nickname'),
      );
    });
  });

  group('generic class support', () {
    test('includes type arguments in copyWith, ==, and fromMap', () {
      const fields = [
        ClassField(name: 'value', type: 'T'),
        ClassField(name: 'label', type: 'String?'),
      ];

      final copyWith = generateCopyWithMethod(
        'Box',
        fields,
        typeArguments: '<T>',
      );
      expect(copyWith, contains('Box<T> copyWith('));
      expect(copyWith, contains('Box<T>('));

      final equals = generateEqualityOperatorOverride(
        'Box',
        fields,
        typeArguments: '<T>',
      );
      expect(equals, contains('other is Box<T>'));

      final fromMap = generateDeserializeMethod(
        'Box',
        'fromMap',
        fields,
        typeArguments: '<T>',
      );
      expect(
        fromMap,
        contains('factory Box.fromMap(Map<String, dynamic> map)'),
      );
      expect(fromMap, contains('return Box<T>('));
    });
  });

  group('rich serialization and deserialization', () {
    test('handles DateTime and DateTime?', () {
      const fields = [
        ClassField(
          name: 'createdAt',
          type: 'DateTime',
          typeKind: FieldTypeKind.dateTime,
        ),
        ClassField(
          name: 'deletedAt',
          type: 'DateTime?',
          typeKind: FieldTypeKind.dateTime,
        ),
      ];

      final toMap = generateSerializeMethod('toMap', fields);
      expect(toMap, contains("'createdAt': createdAt.toIso8601String()"));
      expect(toMap, contains("'deletedAt': deletedAt?.toIso8601String()"));

      final fromMap = _norm(
        generateDeserializeMethod('Event', 'fromMap', fields),
      );
      expect(
        fromMap,
        contains("createdAt: DateTime.parse(map['createdAt'] as String)"),
      );
      expect(
        fromMap,
        contains(
          "deletedAt: map['deletedAt'] != null ? DateTime.parse(map['deletedAt'] as String) : null",
        ),
      );
    });

    test('handles Enum and Enum?', () {
      const fields = [
        ClassField(
          name: 'status',
          type: 'Status',
          typeKind: FieldTypeKind.enumType,
        ),
        ClassField(
          name: 'prevStatus',
          type: 'Status?',
          typeKind: FieldTypeKind.enumType,
        ),
      ];

      final toMap = _norm(generateSerializeMethod('toMap', fields));
      expect(toMap, contains("'status': status.name"));
      expect(toMap, contains("'prevStatus': prevStatus?.name"));

      final fromMap = _norm(
        generateDeserializeMethod('Task', 'fromMap', fields),
      );
      expect(
        fromMap,
        contains("status: Status.values.byName(map['status'] as String)"),
      );
      expect(
        fromMap,
        contains(
          "prevStatus: map['prevStatus'] != null ? Status.values.byName(map['prevStatus'] as String) : null",
        ),
      );
    });

    test(
      'handles List, Set, and Map collections including DateTime/Enum elements',
      () {
        const fields = [
          ClassField(name: 'ids', type: 'List<int>'),
          ClassField(name: 'tags', type: 'Set<String>?'),
          ClassField(
            name: 'dates',
            type: 'List<DateTime>',
            typeKind: FieldTypeKind.list,
            typeArguments: [
              ClassField(
                name: 'e',
                type: 'DateTime',
                typeKind: FieldTypeKind.dateTime,
              ),
            ],
          ),
          ClassField(
            name: 'statuses',
            type: 'Set<Status>',
            typeKind: FieldTypeKind.set,
            typeArguments: [
              ClassField(
                name: 'e',
                type: 'Status',
                typeKind: FieldTypeKind.enumType,
              ),
            ],
          ),
          ClassField(name: 'meta', type: 'Map<String, int>'),
          ClassField(
            name: 'timestamps',
            type: 'Map<String, DateTime>',
            typeKind: FieldTypeKind.map,
            typeArguments: [
              ClassField(name: 'k', type: 'String'),
              ClassField(
                name: 'v',
                type: 'DateTime',
                typeKind: FieldTypeKind.dateTime,
              ),
            ],
          ),
        ];

        final toMap = _norm(generateSerializeMethod('toMap', fields));
        expect(toMap, contains("'ids': ids"));
        expect(toMap, contains("'tags': tags?.toList()"));
        expect(
          toMap,
          contains("'dates': dates.map((e) => e.toIso8601String()).toList()"),
        );
        expect(
          toMap,
          contains("'statuses': statuses.map((e) => e.name).toList()"),
        );
        expect(toMap, contains("'meta': meta"));
        expect(
          toMap,
          contains(
            "'timestamps': timestamps.map((k, v) => MapEntry(k, v.toIso8601String()))",
          ),
        );

        final fromMap = _norm(
          generateDeserializeMethod('Bundle', 'fromMap', fields),
        );
        expect(fromMap, contains("(map['ids'] as List<dynamic>).cast<int>()"));
        expect(
          fromMap,
          contains("(map['tags'] as List<dynamic>?)?.cast<String>().toSet()"),
        );
        expect(
          fromMap,
          contains(
            "(map['dates'] as List<dynamic>).map((e) => DateTime.parse(e as String)).toList()",
          ),
        );
        expect(
          fromMap,
          contains(
            "(map['statuses'] as List<dynamic>).map((e) => Status.values.byName(e as String)).toSet()",
          ),
        );
        expect(
          fromMap,
          contains("(map['meta'] as Map<String, dynamic>).cast<String, int>()"),
        );
        expect(
          fromMap,
          contains('(map[\'timestamps\'] as Map<String, dynamic>).map('),
        );
        expect(
          fromMap,
          contains('MapEntry(k as String, DateTime.parse(v as String))'),
        );
      },
    );
  });

  group('formatClassMembers', () {
    test('formats multiple unformatted class members in one pass', () {
      const fields = [ClassField(name: 'name', type: 'String')];
      final formatted = formatClassMembers([
        generateCopyWithMethod('User', fields, format: false),
        generateToStringMethod('User', fields, format: false),
        generateSerializeMethod('toMap', fields, format: false),
      ]);

      expect(formatted, contains('User copyWith({String? name})'));
      expect(formatted, contains('@override'));
      expect(formatted, contains('Map<String, dynamic> toMap()'));
    });
  });
}
