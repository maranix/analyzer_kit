import 'package:dart_analyzer_toolkit/dart_analyzer_toolkit.dart';

@CopyWith()
final class User {
  const User({required this.name});

  final String name;
}
