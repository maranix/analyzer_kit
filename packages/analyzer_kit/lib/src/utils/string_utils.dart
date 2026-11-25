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
/// Dart string literal.
String escapeSingleQuotedString(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll(r'$', r'\$')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\r')
    .replaceAll('\t', r'\t');
