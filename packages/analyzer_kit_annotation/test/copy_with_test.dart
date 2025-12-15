import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('CopyWith', () {
    test('instance can be created', () {
      const annotation = CopyWith();
      expect(annotation, isA<CopyWith>());
    });

    test('constant instance is available', () {
      expect(copyWith, isA<CopyWith>());
    });

    test('constant instance equality', () {
      expect(copyWith, equals(const CopyWith()));
    });
  });
}
