import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const dataClass = CompositeAnnotation([
  CopyWith(),
  OverrideEquality(),
  OverrideToString(),
  Serialize(),
  Deserialize(),
]);

@dataClass
final class User({
  required final String name,
  required final int age,
  required final List<String> tags,
  required final Map<String, int> scores,
});
