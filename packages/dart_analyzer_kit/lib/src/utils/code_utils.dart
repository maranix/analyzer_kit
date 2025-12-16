part of 'utils.dart';

// Global Singleton
final codeFormatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

// Global Singleton
final dartEmitter = DartEmitter();

String formatCode(String code) {
  return codeFormatter.format(code);
}
