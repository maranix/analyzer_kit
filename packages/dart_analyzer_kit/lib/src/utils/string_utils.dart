part of 'utils.dart';

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

@pragma('vm:prefer-inline')
String toAsciiLower(String s) {
  final codeUnits = s.codeUnits;
  var changed = false;

  for (var i = 0; i < codeUnits.length; i++) {
    final c = codeUnits[i];
    if (c >= 0x41 && c <= 0x5A) {
      changed = true;
      break;
    }
  }

  if (!changed) return s; // Already lowercase

  final buffer = StringBuffer();
  for (final c in codeUnits) {
    buffer.writeCharCode((c >= 0x41 && c <= 0x5A) ? (c + 0x20) : c);
  }

  return buffer.toString();
}
