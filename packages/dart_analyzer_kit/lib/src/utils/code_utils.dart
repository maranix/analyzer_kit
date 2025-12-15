part of 'utils.dart';

final _codeFormatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

String formatCode(String code) {
  return _codeFormatter.format(code);
}
