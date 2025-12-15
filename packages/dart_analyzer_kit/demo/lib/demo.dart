import 'package:dart_analyzer_kit/dart_analyzer_kit.dart';

@CopyWith()
final class User {
  const User({required this.name});

  final String name;
}
