import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';
import 'package:test/test.dart';

void main() {
  test('copyWith', () {
    final instance = CopyWith();
    final constant = copyWith;

    expect(constant, isNotNull);
    expect(instance, isNotNull);
    expect(constant, equals(instance));
  });
}
