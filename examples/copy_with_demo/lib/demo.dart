import 'package:analyzer_kit_annotation/analyzer_kit_annotation.dart';

@copyWith
final class User {
  User({required this.name});

  final String name;

  User copyWith({String? name}) {
    return User(name: name ?? this.name);
  }
}
