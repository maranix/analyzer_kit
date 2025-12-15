import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@CopyWith()
final class User {
  const User({required this.name, required this.age});

  final String name;
  final int age;
}

@copyWith
final class Todo {
  const Todo({required this.id, required this.title, required this.completed});

  final int id;
  final String title;
  final bool completed;
}
