import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyzerKit', () {
    tearDown(() {
      AnalyzerKit.deepCollectionEquality = false;
    });

    group('deepHash', () {
      test('uses shallow hash for iterables when disabled', () {
        AnalyzerKit.deepCollectionEquality = false;
        final list1 = <int>[1, 2, 3];
        final list2 = <int>[1, 2, 3];
        
        expect(
          AnalyzerKit.deepHash(list1),
          Object.hashAll(list1),
        );
      });

      test('uses deep hash for iterables when enabled', () {
        AnalyzerKit.deepCollectionEquality = true;
        final list1 = <int>[1, 2, 3];
        final list2 = <int>[1, 2, 3];
        
        expect(
          AnalyzerKit.deepHash(list1),
          AnalyzerKit.deepHash(list2),
        );
      });

      test('uses deep hash for nested collections when enabled', () {
        AnalyzerKit.deepCollectionEquality = true;
        final nested1 = <List<int>>[[1], [2]];
        final nested2 = <List<int>>[[1], [2]];
        
        expect(
          AnalyzerKit.deepHash(nested1),
          AnalyzerKit.deepHash(nested2),
        );
      });
    });

    group('deepEquals', () {
      test('uses identity for iterables when disabled', () {
        AnalyzerKit.deepCollectionEquality = false;
        final list1 = <int>[1, 2, 3];
        final list2 = <int>[1, 2, 3];
        
        expect(AnalyzerKit.deepEquals(list1, list2), isFalse);
        expect(AnalyzerKit.deepEquals(list1, list1), isTrue);
      });

      test('uses deep equality for iterables when enabled', () {
        AnalyzerKit.deepCollectionEquality = true;
        final list1 = <int>[1, 2, 3];
        final list2 = <int>[1, 2, 3];
        
        expect(AnalyzerKit.deepEquals(list1, list2), isTrue);
      });

      test('uses deep equality for nested collections when enabled', () {
        AnalyzerKit.deepCollectionEquality = true;
        final nested1 = <List<int>>[[1], [2]];
        final nested2 = <List<int>>[[1], [2]];
        
        expect(AnalyzerKit.deepEquals(nested1, nested2), isTrue);
      });
    });
  });
}
