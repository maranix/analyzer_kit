import 'package:analyzer_kit/src/constants.dart';
import 'package:analyzer_kit/src/enums.dart';
import 'package:test/test.dart';

void main() {
  group('FeatureAnnotation', () {
    test('has exactly 5 values', () {
      expect(FeatureAnnotation.values.length, 5);
    });

    test('copyWith has name "CopyWith"', () {
      expect(FeatureAnnotation.copyWith.name, 'CopyWith');
    });

    test('overrideToString has name "OverrideToString"', () {
      expect(FeatureAnnotation.overrideToString.name, 'OverrideToString');
    });

    test('overrideEquality has name "OverrideEquality"', () {
      expect(FeatureAnnotation.overrideEquality.name, 'OverrideEquality');
    });

    test('serialize has name "Serialize"', () {
      expect(FeatureAnnotation.serialize.name, 'Serialize');
    });

    test('deserialize has name "Deserialize"', () {
      expect(FeatureAnnotation.deserialize.name, 'Deserialize');
    });

    test('all names are unique', () {
      final names = FeatureAnnotation.values.map((e) => e.name).toSet();
      expect(names.length, FeatureAnnotation.values.length);
    });
  });

  group('FeatureMethod', () {
    test('has exactly 7 values', () {
      expect(FeatureMethod.values.length, 7);
    });

    test('copyWith has name "copyWith"', () {
      expect(FeatureMethod.copyWith.name, 'copyWith');
    });

    test('overrideToString has name "toString"', () {
      expect(FeatureMethod.overrideToString.name, 'toString');
    });

    test('overrideHashCode has name "hashCode"', () {
      expect(FeatureMethod.overrideHashCode.name, 'hashCode');
    });

    test('overrideEquals has name "=="', () {
      expect(FeatureMethod.overrideEquals.name, '==');
    });

    test('operatorEquals has name "operator =="', () {
      expect(FeatureMethod.operatorEquals.name, 'operator ==');
    });

    test('fromMap has name "fromMap"', () {
      expect(FeatureMethod.fromMap.name, 'fromMap');
    });

    test('toMap has name "toMap"', () {
      expect(FeatureMethod.toMap.name, 'toMap');
    });

    test('all names are unique', () {
      final names = FeatureMethod.values.map((e) => e.name).toSet();
      expect(names.length, FeatureMethod.values.length);
    });
  });

  group('FeatureDiagnosticCode', () {
    test('has exactly 5 values', () {
      expect(FeatureDiagnosticCode.values.length, 5);
    });

    test('copyWith maps to LintCodes.copyWith', () {
      expect(FeatureDiagnosticCode.copyWith.diag, same(LintCodes.copyWith));
    });

    test('overrideToString maps to LintCodes.overrideToString', () {
      expect(
        FeatureDiagnosticCode.overrideToString.diag,
        same(LintCodes.overrideToString),
      );
    });

    test('overrideEquality maps to LintCodes.overrideEquality', () {
      expect(
        FeatureDiagnosticCode.overrideEquality.diag,
        same(LintCodes.overrideEquality),
      );
    });

    test('serialize maps to LintCodes.serialize', () {
      expect(FeatureDiagnosticCode.serialize.diag, same(LintCodes.serialize));
    });

    test('deserialize maps to LintCodes.deserialize', () {
      expect(
        FeatureDiagnosticCode.deserialize.diag,
        same(LintCodes.deserialize),
      );
    });

    test('all diagnostic codes are unique', () {
      final codes = FeatureDiagnosticCode.values.map((e) => e.diag).toSet();
      expect(codes.length, FeatureDiagnosticCode.values.length);
    });
  });
}
