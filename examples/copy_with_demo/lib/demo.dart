import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

const dataClass = CompositeAnnotation([
  CopyWith(),
  OverrideEquality(),
  OverrideToString(),
]);

@dataClass
final class User({
  required final String name,
  required final int age,
  required final List<String> tags,
  required final Map<String, int> scores,
}) {
  User copyWith({
    String? name,
    int? age,
    List<String>? tags,
    Map<String, int>? scores,
  }) => User(
    name: name ?? this.name,
    age: age ?? this.age,
    tags: tags ?? this.tags,
    scores: scores ?? this.scores,
  );

  @override
  String toString() =>
      'User(name: $name, age: $age, tags: $tags, scores: $scores)';

  @override
  int get hashCode => Object.hash(name, age, deepHash(tags), deepHash(scores));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.name == name &&
        other.age == age &&
        deepEquals(other.tags, tags) &&
        deepEquals(other.scores, scores);
  }
}
