import 'class_annotation.dart';

/// Marks a field whose value should be redacted in `analyzer_kit` generated
/// output.
///
/// Use `@redact` or `@Redact()` on a field declaration (or primary constructor
/// declaring parameter) to render [placeholder] instead of the field's raw
/// value in `toString()` overrides (and any other configured [annotations]).
///
/// Pass a set of [ClassAnnotation] values to redact the field for specific
/// features, e.g. `@Redact({.overrideToString, .serialize})`, and optionally
/// customize [placeholder] (defaults to `'[REDACTED]'`).
///
/// Redaction applies to output-rendering features (`overrideToString` and
/// `serialize`); `copyWith`, `overrideEquality`, and `deserialize` continue to
/// include the field normally.
final class const Redact([
  /// The class-level annotations for which this field's value is redacted.
  final Set<ClassAnnotation> annotations = const {.overrideToString},

  /// The placeholder string rendered in place of the redacted field value.
  final String placeholder = '[REDACTED]',
]) {
  /// Creates a [Redact] annotation for the given [annotations] and
  /// [placeholder].
  this;
}

/// Convenience constant for `@Redact()`.
const redact = Redact();
