part of 'utils.dart';

final _codeFormatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

final _dartEmitter = DartEmitter();

/// Formats a Dart code string using the latest language version formatter.
String formatCode(String code) => _codeFormatter.format(code);

/// Formats a Dart constructor or factory code string by temporarily wrapping it in a class.
String formatConstructor(String code) {
  final wrapped = 'class _Dummy { $code }';
  final formatted = _codeFormatter.format(wrapped);
  return formatted
      .substring(formatted.indexOf('{') + 1, formatted.lastIndexOf('}'))
      .trim();
}

/// Formats one or more class member declarations in a single [DartFormatter]
/// pass by wrapping them in a temporary class.
String formatClassMembers(Iterable<String> members) {
  final joined = members.join('\n\n');
  if (joined.trim().isEmpty) return '';
  final wrapped = 'class _Dummy {\n$joined\n}';
  final formatted = _codeFormatter.format(wrapped);
  final body = formatted
      .substring(formatted.indexOf('{') + 1, formatted.lastIndexOf('}'))
      .trim();
  return '$body\n';
}
