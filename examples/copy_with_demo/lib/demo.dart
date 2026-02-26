import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@dataClass
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
  int get hashCode =>
      Object.hashAll([name, age, deepHash(tags), deepHash(scores)]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.name == name &&
        other.age == age &&
        deepEquals(other.tags, tags) &&
        deepEquals(other.scores, scores);
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'age': age,
    'tags': tags,
    'scores': scores,
  };

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String,
      age: map['age'] as int,
      tags: map['tags'] as List<String>,
      scores: map['scores'] as Map<String, int>,
    );
  }
}
