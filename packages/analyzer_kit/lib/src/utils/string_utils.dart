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
