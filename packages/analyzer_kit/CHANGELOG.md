## Unreleased

- Added `fieldRename` support (`FieldRename.none`, `.snake`, `.kebab`, `.pascal`, `.screamingSnake`) across `@Serialize`, `@Deserialize`, `AddCompositeMethods`, `AddSerializeMethod`, `AddDeserializeMethod`, and `checkSerializeSync` / `checkDeserializeSync`.
- Added lint warnings in `AnalyzerKitRule` for invalid `CompositeAnnotation` entries (`invalid_composite_annotation_entry`), misplaced field-level annotations on classes (`misplaced_field_annotation`), and misplaced class-level/composite annotations on fields or parameters (`misplaced_class_annotation`).
- Added support for field-level `@redact`, `@Redact()`, and `@Redact({...}, placeholder)` annotations across `AnalyzerKitRule` sync checks (`checkBodySync` / `checkSerializeSync`), `OverrideToStringMethod`, `AddSerializeMethod`, and `AddCompositeMethods` (including primary constructor parameters, body fields, and inherited fields).
- Added support for field-level `@ignore`, `@Ignore()`, and `@Ignore({...})` annotations across `AnalyzerKitRule` sync checks and all code generation quick fixes / assists (including primary constructor parameters and inherited fields).

## 2.0.0

- **Breaking:** Removed `DataClassRule`, `AddDataClassMethods`, and `data_class_annotation` in favor of `CompositeAnnotation` bundles.
- Registered all warning rules (`registerWarningRule`), so diagnostics are enabled by default without a `diagnostics:` block in `analysis_options.yaml`.
- Added `AddCompositeMethods` quick fix to generate or update all bundled methods for a `CompositeAnnotation` in one pass.
- Added support for Dart primary constructors (declaring positional and named parameters, named primary constructors, and empty `;` class bodies).
- Added out-of-sync field detection across all rules with separate `*_out_of_sync` warning diagnostics (`copy_with_out_of_sync`, `override_equality_out_of_sync`, `override_to_string_out_of_sync`, `serialize_out_of_sync`, `deserialize_out_of_sync`) showing exact missing/extra fields, plus removed-field, nullable-signature, and generic-type-argument drift detection.
- Added in-place replacement in all quick fixes and registered 6 force-regenerate IDE assists (`RegenerateCompositeMethods`, `RegenerateCopyWithMethod`, `RegenerateToStringMethod`, `RegenerateEqualityMethods`, `RegenerateSerializeMethod`, `RegenerateDeserializeMethod`).
- Updated SDK constraint to `^3.14.0` and bumped `analyzer`, `analyzer_plugin`, `analysis_server_plugin`, `code_builder`, and `dart_style`.
- Consolidated all 5 warning rules into a single-pass `AnalyzerKitRule` with cached annotation nodes and single-pass `DartFormatter` formatting for batch edits.
- Added nullable-aware `copyWith` generation (`@CopyWith(nullable: true)` using `T? Function()?` parameters) and multiline `toString()` generation (`@OverrideToString(multiline: true)`).
- Added generic class support (`Box<T>`) across `copyWith`, `==`, `fromMap`, and equality sync checks.
- Added rich serialization/deserialization for `DateTime`, `Uri`, `Duration`, `BigInt`, `Enum` (using `asNameMap()` on nullable `Enum?` fields), `double`/`double?` (`num.toDouble()` coercion), `List`, `Set`, `Iterable`, `Map`, and nested `@Serialize`/`@Deserialize` classes.
- Added constructor parameter matching for non-primary constructors, inherited superclass field extraction, automatic `analyzer_kit_annotation` import insertion for `deepHash`/`deepEquals`, prefixed annotation import support, and `abstract`/zero-field class guards.

## 1.0.0+2
- Documentation:
    - Minor documentation updates

## 1.0.0+1
- Dependencies:
  - update `analyzer`, `analyzer_plugin`, `dart_style`, `code_builder` and `analysis_server_plugin` dependencies

## 1.0.0

- Initial release.
- **Lint rules** (all at `ERROR` severity):
  - `data_class_annotation` — reports `@DataClass` when enabled methods are missing.
  - `copy_with_annotation` — reports `@CopyWith` when `copyWith` is missing.
  - `override_equality_annotation` — reports `@OverrideEquality` when `==` or `hashCode` is missing.
  - `override_to_string_annotation` — reports `@OverrideToString` when `toString` is missing.
  - `serialize_annotation` — reports `@Serialize` when the serialization method is missing.
  - `deserialize_annotation` — reports `@Deserialize` when the deserialization factory/method is missing.
- **Quick fixes** (all support Fix All via `CorrectionApplicability.automatically`):
  - `AddDataClassMethods` — generates all enabled methods for `@DataClass` in one pass.
  - `AddCopyWithMethod` — generates `copyWith` with named optional parameters.
  - `OverrideEqualityMethods` — generates `==` and `hashCode` with `deepCollectionEquality` support.
  - `OverrideToStringMethod` — generates `toString` listing all generatable fields.
  - `AddSerializeMethod` — generates serialization method with configurable name.
  - `AddDeserializeMethod` — generates deserialization factory with configurable name.
- **Architecture:**
  - Scalable `BaseAnnotationRule` / `AnnotationRule` hierarchy.
  - Code generation via `code_builder` and `dart_style`.
  - Case-insensitive annotation matching for both PascalCase and camelCase usage.
