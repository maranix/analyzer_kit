import "package:dart_style/dart_style.dart";

final _codeFormatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

/// Formats a Dart code string using the latest language version formatter.
String formatCode(String code) => _codeFormatter.format(code);

/// Formats a Dart constructor or factory code string by temporarily wrapping it in a class.
String formatConstructor(String code) {
  final wrapped = "class _Dummy { $code }";
  final formatted = _codeFormatter.format(wrapped);
  return formatted
      .substring(formatted.indexOf("{") + 1, formatted.lastIndexOf("}"))
      .trim();
}
