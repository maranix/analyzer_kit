import 'package:analyzer_kit/src/rules/annotation_rule/annotation_rule.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test/test.dart';

class CopyWithRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = CopyWithRule();
    super.setUp();
  }
}

void main() {
  late CopyWithRuleTest t;

  setUp(() {
    t = CopyWithRuleTest();
    t.setUp();
  });

  tearDown(() => t.tearDown());

  group('CopyWithRule', () {
    test(
      'reports lint when @CopyWith is present but copyWith method is missing',
      () async {
        await t.assertDiagnostics(
          r'''
class CopyWith {
  const CopyWith();
}

@CopyWith()
class User {
  final String name;
  User({required this.name});
}
''',
          [t.lint(40, 11)],
        );
      },
    );

    test('no lint when copyWith method is present', () async {
      await t.assertNoDiagnostics(r'''
class CopyWith {
  const CopyWith();
}

@CopyWith()
class User {
  final String name;
  User({required this.name});

  User copyWith({String? name}) => User(name: name ?? this.name);
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

    test('no lint when annotation is not CopyWith', () async {
      await t.assertNoDiagnostics(r'''
class SomeOtherAnnotation {
  const SomeOtherAnnotation();
}

@SomeOtherAnnotation()
class User {
  final String name;
  User({required this.name});
}
''');
    });

    test('reports lint with const convenience variable annotation', () async {
      await t.assertDiagnostics(
        r'''
class CopyWith {
  const CopyWith();
}
const copyWith = CopyWith();

@copyWith
class User {
  final String name;
  User({required this.name});
}
''',
        [t.lint(69, 9)],
      );
    });

    test('reports lint when class has no fields but is annotated', () async {
      await t.assertDiagnostics(
        r'''
class CopyWith {
  const CopyWith();
}

@CopyWith()
class Empty {
  const Empty();
}
''',
        [t.lint(40, 11)],
      );
    });

    test('case-insensitive annotation matching', () async {
      await t.assertDiagnostics(
        r'''
class copywith {
  const copywith();
}

@copywith()
class User {
  final String name;
  User({required this.name});
}
''',
        [t.lint(40, 11)],
      );
    });
  });
}
