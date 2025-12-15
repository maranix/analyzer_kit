part of 'utils.dart';

/// This assumes that provided comparable inputs are alphabets.
///
/// Comparison is done by iterating over code units(ASCII values) of both strings.
///
/// Defaults to [CaseStyle.insensitive].
bool stringsMatchByCharCode(
  String first,
  String second, {
  CaseStyle caseStyle = .insensitive,
}) {
  if (first.isEmpty && second.isEmpty) return true;
  if (first.length != second.length) return false;

  final firstAsciiIterator = first.codeUnits.iterator;
  final secondAsciiIterator = second.codeUnits.iterator;

  while (firstAsciiIterator.moveNext()) {
    if (!secondAsciiIterator.moveNext()) {
      return false;
    }

    final max = math.max(
      firstAsciiIterator.current,
      secondAsciiIterator.current,
    );
    final min = math.min(
      firstAsciiIterator.current,
      secondAsciiIterator.current,
    );

    final hasUpperLowerMatch =
        (max - min) !=
        32; // The difference between A-a is exactly 32 units and so on for each character
    final hasEqualMatch =
        (max - min) ==
        0; // The difference between the exact characters will always be zero

    if (!hasUpperLowerMatch && !hasEqualMatch) {
      return false;
    }
  }

  return true;
}
