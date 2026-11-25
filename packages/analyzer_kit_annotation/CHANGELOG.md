## 2.0.0

- **Breaking:**
  - Removed `DataClass` and `@dataClass` in favor of `CompositeAnnotation`, allowing users to compose reusable annotation bundles with custom configurations.
  - Updated Dart SDK constraint to `^3.14.0` (adopting primary constructors and dot-shorthand across annotation classes).
- **New Annotations & Options:**
  - Added `CompositeAnnotation([...])` for bundling any combination of class-level annotations (`CopyWith`, `OverrideEquality`, `OverrideToString`, `Serialize`, `Deserialize`, or nested `CompositeAnnotation`s).
  - Added field-level `@Ignore` (`@ignore`) accepting a `Set<ClassAnnotation>` (e.g. `@Ignore({.serialize, .overrideToString})`) to exclude fields per feature.
  - Added field-level `@Redact` (`@redact`) accepting a `Set<ClassAnnotation>` (defaulting to `{.overrideToString}`) and an optional `placeholder` (defaulting to `'[REDACTED]'`) to mask sensitive field values in generated output.
  - Added `FieldRename` (`none`, `snake`, `kebab`, `pascal`, `screamingSnake`) to `@Serialize` and `@Deserialize` for configuring map key casing.
  - Added `ClassAnnotation` enum (`copyWith`, `overrideEquality`, `overrideToString`, `serialize`, `deserialize`) shared by `@Ignore` and `@Redact`.
  - Added `nullable` option on `CopyWith` (`@CopyWith(nullable: true)`) for resetting nullable fields to `null`.
  - Added `multiline` option on `OverrideToString` (`@OverrideToString(multiline: true)`) for multi-line `toString()` formatting.
  - Added `deepCollectionEquality` option on `OverrideEquality` and switched `deepHash` / `deepEquals` to order-sensitive `DeepCollectionEquality()`.

## 1.0.0+1
- Documentation:
    - Small documentation updates related to intializing and enabling the plugin

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
