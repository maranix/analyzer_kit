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
