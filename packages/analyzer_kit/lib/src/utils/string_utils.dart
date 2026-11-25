part of 'utils.dart';

/// Case-insensitive ASCII string equality comparison.
@pragma('vm:prefer-inline')
bool stringEqualsIgnoreCaseByAscii(String a, String b) {
  final length = a.length;
  if (length != b.length) return false;

  for (var i = 0; i < length; i++) {
    var ca = a.codeUnitAt(i);
    var cb = b.codeUnitAt(i);

    if (ca >= 0x41 && ca <= 0x5A) ca += 0x20;
    if (cb >= 0x41 && cb <= 0x5A) cb += 0x20;

    if (ca != cb) return false;
  }
  return true;
}

/// Escapes special characters in [value] for inclusion inside a single-quoted
/// Dart string literal in a single pass without allocations when nothing needs
/// escaping.
String escapeSingleQuotedString(String value) {
  StringBuffer? buffer;
  final length = value.length;

  for (var i = 0; i < length; i++) {
    final code = value.codeUnitAt(i);
    final replacement = switch (code) {
      0x5C => r'\\', // \
      0x27 => r"\'", // '
      0x24 => r'\$', // $
      0x0A => r'\n', // \n
      0x0D => r'\r', // \r
      0x09 => r'\t', // \t
      _ => null,
    };
    if (replacement != null) {
      buffer ??= StringBuffer(value.substring(0, i));
      buffer.write(replacement);
    } else {
      buffer?.writeCharCode(code);
    }
  }

  return buffer?.toString() ?? value;
}

/// Converts a Dart field identifier [name] according to [strategy].
///
/// Returns [name] unchanged when [strategy] is [FieldRename.none].
String renameField(String name, FieldRename strategy) {
  if (strategy == .none || name.isEmpty) return name;

  final words = _splitIdentifierWords(name);
  if (words.isEmpty) return name;

  return switch (strategy) {
    .none => name,
    .snake => words.map((w) => w.toLowerCase()).join('_'),
    .kebab => words.map((w) => w.toLowerCase()).join('-'),
    .pascal => words.map(_capitalizeWord).join(),
    .screamingSnake => words.map((w) => w.toUpperCase()).join('_'),
  };
}

List<String> _splitIdentifierWords(String input) {
  final words = <String>[];
  final length = input.length;
  var start = -1;

  for (var i = 0; i < length; i++) {
    final code = input.codeUnitAt(i);
    if (code == 0x5F || code == 0x2D) {
      if (start != -1) {
        words.add(input.substring(start, i));
        start = -1;
      }
      continue;
    }

    if (start == -1) {
      start = i;
      continue;
    }

    if (_isUpperAscii(code)) {
      final prev = input.codeUnitAt(i - 1);
      final nextIsLower =
          i + 1 < length && _isLowerAscii(input.codeUnitAt(i + 1));
      if (!_isUpperAscii(prev) || nextIsLower) {
        words.add(input.substring(start, i));
        start = i;
      }
    }
  }

  if (start != -1) {
    words.add(input.substring(start));
  }
  return words;
}

String _capitalizeWord(String word) {
  if (word.isEmpty) return word;
  return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
}

@pragma('vm:prefer-inline')
bool _isUpperAscii(int code) => code >= 0x41 && code <= 0x5A;

@pragma('vm:prefer-inline')
bool _isLowerAscii(int code) => code >= 0x61 && code <= 0x7A;
