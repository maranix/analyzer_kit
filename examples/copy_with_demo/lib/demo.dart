import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@copyWith
@serialize
final class User {
  User({required this.name, this.age});

  final String name;

  int? age;

  User copyWith({String? name, int? age}) {
    return User(name: name ?? this.name, age: age ?? this.age);
  }

  Map<String, dynamic> toMap() => {'name': name, 'age': age};
}
