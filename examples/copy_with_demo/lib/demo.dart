import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@copyWith
@OverrideEquality(deepCollectionEquality: true)
@overrideToString
final class User {
  User({
    required this.name,
    required this.age,
    required this.tags,
    required this.scores,
  });

  final String name;
  final int age;
  final List<String> tags;
  final Map<String, int> scores;

  User copyWith({
    String? name,
    int? age,
    List<String>? tags,
    Map<String, int>? scores,
  }) =>
      User(
        name: name ?? this.name,
        age: age ?? this.age,
        tags: tags ?? this.tags,
        scores: scores ?? this.scores,
      );

  @override
  String toString() =>
      'User(name: $name, age: $age, tags: $tags, scores: $scores)';
}
