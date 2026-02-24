import 'package:collection/collection.dart';

/// Global configuration and utility methods for `analyzer_kit`.
abstract final class AnalyzerKit {
  /// Whether generated `hashCode` and `==` overrides should use deep,
  /// recursive equality for collections by default.
  ///
  /// This serves as the global fallback when a class is annotated with
  /// `@overrideEquality` (which has no explicit value).
  ///
  /// If a class is annotated with `@OverrideEquality(deepCollectionEquality: true/false)`,
  /// that value overrides this global setting.
  ///
  /// Defaults to `false` (shallow, identity-based equality for nested collections).
  static bool deepCollectionEquality = false;

  static const _equality = DeepCollectionEquality();

  /// Hashes a [value], using deep collection equality if configured globally.
  static int deepHash(Object? value) {
    if (deepCollectionEquality) return _equality.hash(value);

    // Fallback to shallow, fast implementations
    if (value is Iterable) return Object.hashAll(value);
    if (value is Map) {
      return Object.hashAllUnordered(
        value.entries.map((e) => Object.hash(e.key, e.value)),
      );
    }
    if (value is Set) return Object.hashAllUnordered(value);
    return value.hashCode;
  }

  /// Compares two objects [a] and [b], using deep collection equality if configured globally.
  static bool deepEquals(Object? a, Object? b) {
    if (deepCollectionEquality) return _equality.equals(a, b);
    
    // Fallback to strict identity for collections (what == does by default)
    return a == b;
  }
}
