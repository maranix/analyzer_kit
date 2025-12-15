part of 'utils.dart';

bool stringsMatchByCharCode(
  String first,
  String second, {
  CaseStyle caseStyle = .insensitive,
}) {
  if (caseStyle == CaseStyle.sensitive) {
    return first == second;
  } else {
    return first.toLowerCase() == second.toLowerCase();
  }
}
