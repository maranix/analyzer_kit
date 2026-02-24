part of 'utils.dart';

final _codeFormatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

final _dartEmitter = DartEmitter();

/// Formats a Dart code string using the latest language version formatter.
String formatCode(String code) => _codeFormatter.format(code);
