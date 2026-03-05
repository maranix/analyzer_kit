import 'package:analyzer/error/error.dart' show LintCode;
import 'package:analyzer_kit/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('LintCodes', () {
    group('dataClass', () {
      test('has correct name', () {
        expect(LintCodes.dataClass.lowerCaseName, 'data_class_annotation');
      });

      test('has correct problem message', () {
        expect(LintCodes.dataClass.problemMessage, contains('@DataClass'));
      });

      test('has ERROR severity', () {
        expect(LintCodes.dataClass.severity.name, 'ERROR');
      });

      test('has a correction message', () {
        expect(LintCodes.dataClass.correctionMessage, isNotNull);
        expect(LintCodes.dataClass.correctionMessage, isNotEmpty);
      });

      test('is a LintCode', () {
        expect(LintCodes.dataClass, isA<LintCode>());
      });
    });

    group('copyWith', () {
      test('has correct name', () {
        expect(LintCodes.copyWith.lowerCaseName, 'copy_with_annotation');
      });

      test('has correct problem message', () {
        expect(LintCodes.copyWith.problemMessage, contains('@CopyWith'));
      });

      test('has ERROR severity', () {
        expect(LintCodes.copyWith.severity.name, 'ERROR');
      });

      test('has a correction message', () {
        expect(LintCodes.copyWith.correctionMessage, isNotNull);
        expect(LintCodes.copyWith.correctionMessage, isNotEmpty);
      });

      test('is a LintCode', () {
        expect(LintCodes.copyWith, isA<LintCode>());
      });
    });

    group('overrideEquality', () {
      test('has correct name', () {
        expect(
          LintCodes.overrideEquality.lowerCaseName,
          'override_equality_annotation',
        );
      });

      test('has correct problem message', () {
        expect(
          LintCodes.overrideEquality.problemMessage,
          contains('@OverrideEquality'),
        );
      });

      test('has ERROR severity', () {
        expect(LintCodes.overrideEquality.severity.name, 'ERROR');
      });

      test('has a correction message', () {
        expect(LintCodes.overrideEquality.correctionMessage, isNotNull);
        expect(LintCodes.overrideEquality.correctionMessage, isNotEmpty);
      });
    });

    group('overrideToString', () {
      test('has correct name', () {
        expect(
          LintCodes.overrideToString.lowerCaseName,
          'override_to_string_annotation',
        );
      });

      test('has correct problem message', () {
        expect(
          LintCodes.overrideToString.problemMessage,
          contains('@OverrideToString'),
        );
      });

      test('has ERROR severity', () {
        expect(LintCodes.overrideToString.severity.name, 'ERROR');
      });

      test('has a correction message', () {
        expect(LintCodes.overrideToString.correctionMessage, isNotNull);
        expect(LintCodes.overrideToString.correctionMessage, isNotEmpty);
      });
    });

    group('serialize', () {
      test('has correct name', () {
        expect(LintCodes.serialize.lowerCaseName, 'serialize_annotation');
      });

      test('has correct problem message', () {
        expect(LintCodes.serialize.problemMessage, contains('@Serialize'));
      });

      test('has ERROR severity', () {
        expect(LintCodes.serialize.severity.name, 'ERROR');
      });

      test('has a correction message', () {
        expect(LintCodes.serialize.correctionMessage, isNotNull);
        expect(LintCodes.serialize.correctionMessage, isNotEmpty);
      });
    });

    group('deserialize', () {
      test('has correct name', () {
        expect(LintCodes.deserialize.lowerCaseName, 'deserialize_annotation');
      });

      test('has correct problem message', () {
        expect(LintCodes.deserialize.problemMessage, contains('@Deserialize'));
      });

      test('has ERROR severity', () {
        expect(LintCodes.deserialize.severity.name, 'ERROR');
      });

      test('has a correction message', () {
        expect(LintCodes.deserialize.correctionMessage, isNotNull);
        expect(LintCodes.deserialize.correctionMessage, isNotEmpty);
      });
    });

    test('all codes have unique names', () {
      final names = [
        LintCodes.dataClass.lowerCaseName,
        LintCodes.copyWith.lowerCaseName,
        LintCodes.overrideEquality.lowerCaseName,
        LintCodes.overrideToString.lowerCaseName,
        LintCodes.serialize.lowerCaseName,
        LintCodes.deserialize.lowerCaseName,
      ];
      expect(names.toSet().length, names.length);
    });
  });
}
