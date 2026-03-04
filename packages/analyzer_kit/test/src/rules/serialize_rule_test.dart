import 'package:analyzer_kit/src/rules/annotation_rule/annotation_rule.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test/test.dart';

class SerializeRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = SerializeRule();
    super.setUp();
  }
}

void main() {
  late SerializeRuleTest t;

  setUp(() {
    t = SerializeRuleTest();
    t.setUp();
  });

  tearDown(() => t.tearDown());

  group('SerializeRule', () {
    test(
      'reports lint when @Serialize present but toMap method missing',
      () async {
        await t.assertDiagnostics(
          r'''
class Serialize {
  const Serialize({this.name});
  final Object? name;
}

@Serialize()
class User {
  final String name;
  User({required this.name});
}
''',
          [t.lint(75, 12)],
        );
      },
    );

    test('no lint when toMap method is present', () async {
      await t.assertNoDiagnostics(r'''
class Serialize {
  const Serialize({this.name});
  final Object? name;
}

@Serialize()
class User {
  final String name;
  User({required this.name});

  Map<String, dynamic> toMap() => {'name': name};
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
class Serialize {
  const Serialize({this.name});
  final Object? name;
}

@Serialize()
class User {
  final String name;
  final int age;
  final bool active;
  User({required this.name, required this.age, required this.active});
}
''',
        [t.lint(75, 12)],
      );
    });

    test('reports lint with const convenience variable', () async {
      await t.assertDiagnostics(
        r'''
class Serialize {
  const Serialize({this.name});
  final Object? name;
}
const serialize = Serialize();

@serialize
class User {
  final String name;
  User({required this.name});
}
''',
        [t.lint(106, 10)],
      );
    });

    test('case-insensitive annotation matching', () async {
      await t.assertDiagnostics(
        r'''
class serialize {
  const serialize({this.name});
  final Object? name;
}

@serialize()
class User {
  final String name;
  User({required this.name});
}
''',
        [t.lint(75, 12)],
      );
    });
  });
}
