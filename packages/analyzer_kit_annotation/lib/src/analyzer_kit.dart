import "package:collection/collection.dart";

const _equality = DeepCollectionEquality.unordered();

/// Hashes a [value] using deep collection equality.
int deepHash(Object? value) {
  return _equality.hash(value);
}

/// Compares two objects [a] and [b] using deep collection equality.
bool deepEquals(Object? a, Object? b) {
  return _equality.equals(a, b);
}
