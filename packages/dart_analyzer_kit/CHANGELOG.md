## 1.0.0

- Initial release.
- Added `unused_copy_with_annotation` lint rule with `copyWith` quick fix.
- Added `unused_override_equality_annotation` lint rule with `==` and `hashCode` quick fix.
- Added `unused_override_to_string_annotation` lint rule with `toString` quick fix.
- Added support for the `@DataClass` annotation, triggering warnings and generating `copyWith`, `==`, `hashCode`, and `toString` conditionally based on the annotation's arguments.
