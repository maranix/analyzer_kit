import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@overrideEquality
final class User {
  User({required this.name, this.age});

  final String name;

  int? age;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.name == name && other.age == age;
  }

  @override
  int get hashCode => Object.hashAll([name, age]);
}
