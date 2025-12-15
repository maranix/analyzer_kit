import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'package:test/test.dart';

void main() {
  test('copyWith constant is available', () {
    expect(copyWith, isNotNull);
    expect(copyWith, isA<CopyWith>());
  });

  test('CopyWith instance can be created', () {
    const instance = CopyWith();
    expect(instance, isNotNull);
    expect(instance, isA<CopyWith>());
  });
}
