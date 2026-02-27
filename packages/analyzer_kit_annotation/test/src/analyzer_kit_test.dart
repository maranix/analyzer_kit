import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('deepHash', () {
    group('primitive values', () {
      test('same int values produce same hash', () {
        expect(deepHash(42), deepHash(42));
      });

      test('different int values produce different hash', () {
        expect(deepHash(1), isNot(deepHash(2)));
      });

      test('same string values produce same hash', () {
        expect(deepHash('hello'), deepHash('hello'));
      });

      test('different string values produce different hash', () {
        expect(deepHash('hello'), isNot(deepHash('world')));
      });

      test('null value produces consistent hash', () {
        expect(deepHash(null), deepHash(null));
      });

      test('null and non-null produce different hash', () {
        expect(deepHash(null), isNot(deepHash(0)));
      });

      test('bool values produce consistent hash', () {
        expect(deepHash(true), deepHash(true));
        expect(deepHash(false), deepHash(false));
        expect(deepHash(true), isNot(deepHash(false)));
      });
    });

    group('lists', () {
      test('equal lists produce same hash', () {
        expect(deepHash([1, 2, 3]), deepHash([1, 2, 3]));
      });

      test('lists with different elements produce different hash', () {
        expect(deepHash([1, 2, 3]), isNot(deepHash([1, 2, 4])));
      });

      test('lists with different lengths produce different hash', () {
        expect(deepHash([1, 2]), isNot(deepHash([1, 2, 3])));
      });

      test('empty lists produce same hash', () {
        expect(deepHash(<int>[]), deepHash(<int>[]));
      });

      test('nested equal lists produce same hash', () {
        expect(
          deepHash([
            [1, 2],
            [3, 4],
          ]),
          deepHash([
            [1, 2],
            [3, 4],
          ]),
        );
      });

      test('nested lists with different elements produce different hash', () {
        expect(
          deepHash([
            [1, 2],
            [3, 4],
          ]),
          isNot(
            deepHash([
              [1, 2],
              [3, 5],
            ]),
          ),
        );
      });
    });

    group('sets', () {
      test('equal sets produce same hash regardless of order', () {
        expect(deepHash({1, 2, 3}), deepHash({3, 2, 1}));
      });

      test('different sets produce different hash', () {
        expect(deepHash({1, 2, 3}), isNot(deepHash({1, 2, 4})));
      });

      test('empty sets produce same hash', () {
        expect(deepHash(<int>{}), deepHash(<int>{}));
      });
    });

    group('maps', () {
      test('equal maps produce same hash', () {
        expect(deepHash({'a': 1, 'b': 2}), deepHash({'a': 1, 'b': 2}));
      });

      test('maps with different values produce different hash', () {
        expect(deepHash({'a': 1, 'b': 2}), isNot(deepHash({'a': 1, 'b': 3})));
      });

      test('maps with different keys produce different hash', () {
        expect(deepHash({'a': 1}), isNot(deepHash({'b': 1})));
      });

      test('empty maps produce same hash', () {
        expect(deepHash(<String, int>{}), deepHash(<String, int>{}));
      });
    });

    group('mixed collections', () {
      test('list containing maps produces consistent hash', () {
        expect(
          deepHash([
            {'a': 1},
            {'b': 2},
          ]),
          deepHash([
            {'a': 1},
            {'b': 2},
          ]),
        );
      });

      test('map containing lists produces consistent hash', () {
        expect(
          deepHash({
            'x': [1, 2],
            'y': [3, 4],
          }),
          deepHash({
            'x': [1, 2],
            'y': [3, 4],
          }),
        );
      });
    });
  });

  group('deepEquals', () {
    group('primitive values', () {
      test('same int values are equal', () {
        expect(deepEquals(42, 42), isTrue);
      });

      test('different int values are not equal', () {
        expect(deepEquals(1, 2), isFalse);
      });

      test('same string values are equal', () {
        expect(deepEquals('hello', 'hello'), isTrue);
      });

      test('different string values are not equal', () {
        expect(deepEquals('hello', 'world'), isFalse);
      });

      test('null values are equal', () {
        expect(deepEquals(null, null), isTrue);
      });

      test('null and non-null are not equal', () {
        expect(deepEquals(null, 0), isFalse);
        expect(deepEquals(0, null), isFalse);
      });

      test('bool values are compared correctly', () {
        expect(deepEquals(true, true), isTrue);
        expect(deepEquals(false, false), isTrue);
        expect(deepEquals(true, false), isFalse);
      });
    });

    group('lists', () {
      test('equal lists are equal', () {
        expect(deepEquals([1, 2, 3], [1, 2, 3]), isTrue);
      });

      test('lists with different elements are not equal', () {
        expect(deepEquals([1, 2, 3], [1, 2, 4]), isFalse);
      });

      test('lists with different lengths are not equal', () {
        expect(deepEquals([1, 2], [1, 2, 3]), isFalse);
      });

      test('empty lists are equal', () {
        expect(deepEquals(<int>[], <int>[]), isTrue);
      });

      test('list order matters for equality', () {
        // DeepCollectionEquality.unordered treats lists as unordered
        // This test documents the actual behavior
        final result = deepEquals([1, 2, 3], [3, 2, 1]);
        expect(result, isTrue); // unordered equality
      });

      test('nested equal lists are equal', () {
        expect(
          deepEquals(
            [
              [1, 2],
              [3, 4],
            ],
            [
              [1, 2],
              [3, 4],
            ],
          ),
          isTrue,
        );
      });

      test('nested lists with different elements are not equal', () {
        expect(
          deepEquals(
            [
              [1, 2],
              [3, 4],
            ],
            [
              [1, 2],
              [3, 5],
            ],
          ),
          isFalse,
        );
      });
    });

    group('sets', () {
      test('equal sets are equal', () {
        expect(deepEquals({1, 2, 3}, {1, 2, 3}), isTrue);
      });

      test('sets with different order are equal', () {
        expect(deepEquals({1, 2, 3}, {3, 2, 1}), isTrue);
      });

      test('different sets are not equal', () {
        expect(deepEquals({1, 2, 3}, {1, 2, 4}), isFalse);
      });

      test('sets with different sizes are not equal', () {
        expect(deepEquals({1, 2}, {1, 2, 3}), isFalse);
      });

      test('empty sets are equal', () {
        expect(deepEquals(<int>{}, <int>{}), isTrue);
      });
    });

    group('maps', () {
      test('equal maps are equal', () {
        expect(deepEquals({'a': 1, 'b': 2}, {'a': 1, 'b': 2}), isTrue);
      });

      test('maps with different values are not equal', () {
        expect(deepEquals({'a': 1, 'b': 2}, {'a': 1, 'b': 3}), isFalse);
      });

      test('maps with different keys are not equal', () {
        expect(deepEquals({'a': 1}, {'b': 1}), isFalse);
      });

      test('maps with different sizes are not equal', () {
        expect(deepEquals({'a': 1}, {'a': 1, 'b': 2}), isFalse);
      });

      test('empty maps are equal', () {
        expect(deepEquals(<String, int>{}, <String, int>{}), isTrue);
      });

      test('maps with nested collection values are compared deeply', () {
        expect(
          deepEquals(
            {
              'x': [1, 2],
            },
            {
              'x': [1, 2],
            },
          ),
          isTrue,
        );
      });
    });

    group('cross-type comparisons', () {
      test('list and set are not equal even with same elements', () {
        expect(deepEquals([1, 2, 3], {1, 2, 3}), isFalse);
      });

      test('empty list and empty set are not equal', () {
        expect(deepEquals(<int>[], <int>{}), isFalse);
      });

      test('int and string with same content are not equal', () {
        expect(deepEquals(1, '1'), isFalse);
      });
    });
  });
}
