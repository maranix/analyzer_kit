import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@CopyWith()
final class User {
  const User({required this.name});

  final String name;

  User copyWith({String? name}) {
    return User(name: name ?? this.name);
  }
}
