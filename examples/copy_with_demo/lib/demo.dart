import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@copyWith
@serialize
@overrideEquality
@overrideToString
final class User {
  User({required this.name, required this.age});

  final String name;

  final int age;

  User copyWith({String? name, int? age}) =>
      User(name: name ?? this.name, age: age ?? this.age);

  Map<String, dynamic> toMap() => {'name': name, 'age': age};

  @override
  String toString() => 'User(name: $name, age: $age)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.name == name && other.age == age;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);
}

@copyWith
@serialize
@overrideEquality
@overrideToString
final class Todo {
  Todo({required this.id, required this.title, required this.completed});

  final int id;

  final String title;

  final bool completed;

  @override
  String toString() => 'Todo(id: $id, title: $title, completed: $completed)';

  @override
  int get hashCode => Object.hashAll([id, title, completed]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo &&
        other.id == id &&
        other.title == title &&
        other.completed == completed;
  }

  Todo copyWith({int? id, String? title, bool? completed}) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    completed: completed ?? this.completed,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'completed': completed,
  };
}
