/// Groups multiple `analyzer_kit` annotations into a single reusable constant.
///
/// Define a top-level `const` with [CompositeAnnotation] and apply it to any
/// class to enable all included code generation features at once:
///
/// ```dart
/// const myDataClass = CompositeAnnotation([
///   CopyWith(),
///   OverrideEquality(),
///   OverrideToString(),
///   Serialize(),
///   Deserialize(),
/// ]);
///
/// @myDataClass
/// class User {
///   final String name;
///   final int age;
///
///   User({required this.name, required this.age});
/// }
/// ```
final class CompositeAnnotation {
  /// Creates a [CompositeAnnotation] containing [annotations].
  const CompositeAnnotation(this.annotations);

  /// The annotations included in this composite bundle.
  final List<Object> annotations;
}
