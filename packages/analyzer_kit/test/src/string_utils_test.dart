import 'package:analyzer_kit/src/enums.dart';
import 'package:analyzer_kit/src/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group('stringEqualsIgnoreCaseByAscii', () {
    group('equal strings', () {
      test('identical strings are equal', () {
        expect(stringEqualsIgnoreCaseByAscii('hello', 'hello'), isTrue);
      });

      test('empty strings are equal', () {
        expect(stringEqualsIgnoreCaseByAscii('', ''), isTrue);
      });

      test('single character strings are equal', () {
        expect(stringEqualsIgnoreCaseByAscii('a', 'a'), isTrue);
      });
    });

    group('case-insensitive matching', () {
      test('uppercase equals lowercase', () {
        expect(stringEqualsIgnoreCaseByAscii('HELLO', 'hello'), isTrue);
      });

      test('lowercase equals uppercase', () {
        expect(stringEqualsIgnoreCaseByAscii('hello', 'HELLO'), isTrue);
      });

      test('mixed case equals lowercase', () {
        expect(stringEqualsIgnoreCaseByAscii('HeLLo', 'hello'), isTrue);
      });

      test('PascalCase equals camelCase', () {
        expect(stringEqualsIgnoreCaseByAscii('CopyWith', 'copyWith'), isTrue);
      });

      test('DataClass matches dataclass', () {
        expect(stringEqualsIgnoreCaseByAscii('DataClass', 'dataclass'), isTrue);
      });

      test('all uppercase annotation names match PascalCase', () {
        expect(
          stringEqualsIgnoreCaseByAscii('OVERRIDEEQUALITY', 'OverrideEquality'),
          isTrue,
        );
      });
    });

    group('non-equal strings', () {
      test('different strings are not equal', () {
        expect(stringEqualsIgnoreCaseByAscii('hello', 'world'), isFalse);
      });

      test('different lengths are not equal', () {
        expect(stringEqualsIgnoreCaseByAscii('hello', 'hell'), isFalse);
      });

      test('empty and non-empty are not equal', () {
        expect(stringEqualsIgnoreCaseByAscii('', 'a'), isFalse);
      });

      test('non-empty and empty are not equal', () {
        expect(stringEqualsIgnoreCaseByAscii('a', ''), isFalse);
      });

      test('prefix match but different lengths', () {
        expect(
          stringEqualsIgnoreCaseByAscii('CopyWith', 'CopyWithExtra'),
          isFalse,
        );
      });

      test('similar strings with one character difference', () {
        expect(stringEqualsIgnoreCaseByAscii('abc', 'abd'), isFalse);
      });
    });

    group('edge cases', () {
      test('digits are compared correctly', () {
        expect(stringEqualsIgnoreCaseByAscii('abc123', 'ABC123'), isTrue);
      });

      test('special characters are compared exactly', () {
        expect(stringEqualsIgnoreCaseByAscii('a_b', 'A_B'), isTrue);
      });

      test('strings with underscores', () {
        expect(
          stringEqualsIgnoreCaseByAscii(
            'unused_data_class',
            'UNUSED_DATA_CLASS',
          ),
          isTrue,
        );
      });

      test('boundary ASCII characters for uppercase range', () {
        // 0x40 is '@' (just before 'A' = 0x41)
        // 0x5B is '[' (just after 'Z' = 0x5A)
        expect(stringEqualsIgnoreCaseByAscii('@', '@'), isTrue);
        expect(stringEqualsIgnoreCaseByAscii('[', '['), isTrue);
        expect(
          stringEqualsIgnoreCaseByAscii('@', '`'),
          isFalse,
        ); // @ should not become `
      });
    });
  });

  group('escapeSingleQuotedString', () {
    test('returns identical string when no characters need escaping', () {
      const input = '[REDACTED]';
      expect(identical(escapeSingleQuotedString(input), input), isTrue);
      expect(escapeSingleQuotedString(''), '');
    });

    test('escapes backslash, quote, dollar, and control whitespace', () {
      expect(
        escapeSingleQuotedString("a\\b'c\$d\ne\rf\tg"),
        r"a\\b\'c\$d\ne\rf\tg",
      );
    });
  });

  group('renameField', () {
    test('none returns the original string identically', () {
      const input = 'firstName';
      expect(identical(renameField(input, FieldRename.none), input), isTrue);
    });

    test('converts camelCase, acronyms, digits, and snake_case', () {
      expect(renameField('firstName', FieldRename.snake), 'first_name');
      expect(renameField('firstName', FieldRename.kebab), 'first-name');
      expect(renameField('firstName', FieldRename.pascal), 'FirstName');
      expect(
        renameField('firstName', FieldRename.screamingSnake),
        'FIRST_NAME',
      );

      expect(renameField('userID', FieldRename.snake), 'user_id');
      expect(
        renameField('parseHTMLString', FieldRename.snake),
        'parse_html_string',
      );
      expect(renameField('v2Endpoint', FieldRename.kebab), 'v2-endpoint');
      expect(renameField('already_snake', FieldRename.pascal), 'AlreadySnake');
      expect(renameField('', FieldRename.snake), '');
    });
  });
}
