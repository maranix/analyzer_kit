import 'package:analyzer_kit/src/rules/annotation_rule/annotation_rule.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test/test.dart';

class DeserializeRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DeserializeRule();
    super.setUp();
  }
}

void main() {
  late DeserializeRuleTest t;

  setUp(() {
    t = DeserializeRuleTest();
    t.setUp();
  });

  tearDown(() => t.tearDown());

  group('DeserializeRule', () {
    test(
      'reports lint when @Deserialize present but fromMap missing',
      () async {
        await t.assertDiagnostics(
          r'''
class Deserialize {
  const Deserialize({this.name});
  final Object? name;
}

@Deserialize()
class User {
  final String name;
  User({required this.name});
}
''',
          [t.lint(79, 14)],
        );
      },
    );

    test('no lint when factory fromMap constructor is present', () async {
      await t.assertNoDiagnostics(r'''
class Deserialize {
  const Deserialize({this.name});
  final Object? name;
}

@Deserialize()
class User {
  final String name;
  User({required this.name});

  factory User.fromMap(Map<String, dynamic> map) =>
      User(name: map['name'] as String);
}
''');
    });

    test('no lint when static fromMap method is present', () async {
      await t.assertNoDiagnostics(r'''
class Deserialize {
  const Deserialize({this.name});
  final Object? name;
}

@Deserialize()
class User {
  final String name;
  User({required this.name});

  static User fromMap(Map<String, dynamic> map) =>
      User(name: map['name'] as String);
}
''');
    });

    test('no lint on class without annotation', () async {
      await t.assertNoDiagnostics(r'''
class User {
  final String name;
  User({required this.name});
}
''');
    });

    test('reports lint when class has multiple fields', () async {
      await t.assertDiagnostics(
        r'''
class Deserialize {
  const Deserialize({this.name});
  final Object? name;
}

@Deserialize()
class User {
  final String name;
  final int age;
  final bool active;
  User({required this.name, required this.age, required this.active});
}
''',
        [t.lint(79, 14)],
      );
    });

    test('reports lint with const convenience variable', () async {
      await t.assertDiagnostics(
        r'''
class Deserialize {
  const Deserialize({this.name});
  final Object? name;
}
const deserialize = Deserialize();

@deserialize
class User {
  final String name;
  User({required this.name});
}
''',
        [t.lint(114, 12)],
      );
    });

    test('case-insensitive annotation matching', () async {
      await t.assertDiagnostics(
        r'''
class deserialize {
  const deserialize({this.name});
  final Object? name;
}

@deserialize()
class User {
  final String name;
  User({required this.name});
}
''',
        [t.lint(79, 14)],
      );
    });
  });
}
