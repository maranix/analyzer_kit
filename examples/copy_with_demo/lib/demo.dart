import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@copyWith
@serialize
@debugString
@overrideEquality
final class User {
  User({required this.name, required this.age});

  final String name;

  final int age;

  @override
  int get hashCode => Object.hashAll([name, age]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.name == name && other.age == age;
  }

  @override
  String toString() => 'User(name: $name, age: $age)';

  User copyWith({String? name, int? age}) =>
      User(name: name ?? this.name, age: age ?? this.age);

  Map<String, dynamic> toMap() => {'name': name, 'age': age};
}
