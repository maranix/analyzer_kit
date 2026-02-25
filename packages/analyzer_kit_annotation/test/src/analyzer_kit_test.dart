import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyzerKit', () {
    group('deepHash', () {
      test('hashes collections based on their elements', () {
        final list1 = <int>[1, 2, 3];
        final list2 = <int>[1, 2, 3];

        expect(deepHash(list1), deepHash(list2));
      });

      test('hashes nested collections based on their elements', () {
        final nested1 = <List<int>>[
          [1],
          [2],
        ];
        final nested2 = <List<int>>[
          [1],
          [2],
        ];

        expect(deepHash(nested1), deepHash(nested2));
      });
    });

    group('deepEquals', () {
      test('evaluates equality of collections based on their elements', () {
        final list1 = <int>[1, 2, 3];
        final list2 = <int>[1, 2, 3];

        expect(deepEquals(list1, list2), isTrue);
      });

      test(
        'evaluates equality of nested collections based on their elements',
        () {
          final nested1 = <List<int>>[
            [1],
            [2],
          ];
          final nested2 = <List<int>>[
            [1],
            [2],
          ];

          expect(deepEquals(nested1, nested2), isTrue);
        },
      );
    });
  });
}
