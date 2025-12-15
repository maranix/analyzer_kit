import 'package:dart_analyzer_kit/src/enums.dart';
import 'package:dart_analyzer_kit/src/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group('stringsMatchByCharCode', () {
    test('Case insensitive (default)', () {
      expect(stringsMatchByCharCode('abc', 'abc'), isTrue);
      expect(stringsMatchByCharCode('abc', 'ABC'), isTrue);
      expect(stringsMatchByCharCode('CopyWith', 'copyWith'), isTrue);
      expect(stringsMatchByCharCode('abc', 'abd'), isFalse);
      expect(stringsMatchByCharCode('abc', 'abcd'), isFalse);
    });

    test('Case sensitive', () {
      expect(
        stringsMatchByCharCode('abc', 'abc', caseStyle: CaseStyle.sensitive),
        isTrue,
      );
      expect(
        stringsMatchByCharCode('abc', 'ABC', caseStyle: CaseStyle.sensitive),
        isFalse,
      );
      expect(
        stringsMatchByCharCode(
          'CopyWith',
          'copyWith',
          caseStyle: CaseStyle.sensitive,
        ),
        isFalse,
      );
    });
  });
}
