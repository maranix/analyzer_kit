## 1.0.0

- Initial release.
- **Annotations:**
  - `CopyWith` — marks a class for `copyWith` method generation.
  - `OverrideEquality` — marks a class for `==` and `hashCode` generation, with optional `deepCollectionEquality` control.
  - `OverrideToString` — marks a class for `toString` override generation.
  - `DataClass` — composite annotation enabling `copyWith`, `overrideEquality`, `overrideToString`, `serialize`, and `deserialize` with individual toggle flags.
  - `Serialize` — marks a class for serialization method generation (`toMap`, `toJson`, or custom via `SerializeMethod`).
  - `Deserialize` — marks a class for deserialization factory generation (`fromMap`, `fromJson`, or custom via `DeserializeMethod`).
- **Sealed class hierarchies:**
  - `SerializeMethod` with factories: `.toMap()`, `.toJson()`, `.custom(String name)`.
  - `DeserializeMethod` with factories: `.fromMap()`, `.fromJson()`, `.custom(String name)`.
- **Runtime helpers:**
  - `deepHash(Object?)` — deep recursive collection hashing.
  - `deepEquals(Object?, Object?)` — deep recursive collection equality.
- Convenience constants for all annotations (e.g., `@dataClass`, `@copyWith`, `@serialize`).
