import 'package:analyzer_kit/src/rules/annotation_rule/annotation_rule.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test/test.dart';

class OverrideEqualityRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = OverrideEqualityRule();
    super.setUp();
  }
}

void main() {
  late OverrideEqualityRuleTest t;

  setUp(() {
    t = OverrideEqualityRuleTest();
    t.setUp();
  });

  tearDown(() => t.tearDown());

  group('OverrideEqualityRule', () {
    test(
      'reports lint when @OverrideEquality present but == and hashCode missing',
      () async {
        await t.assertDiagnostics(
          r'''
class OverrideEquality {
  const OverrideEquality({this.deepCollectionEquality});
  final bool? deepCollectionEquality;
}

@OverrideEquality()
class User {
  final String name;
  User({required this.name});
}
''',
          [t.lint(123, 19)],
        );
      },
    );

    test('no lint when both == and hashCode are overridden', () async {
      await t.assertNoDiagnostics(r'''
class OverrideEquality {
  const OverrideEquality({this.deepCollectionEquality});
  final bool? deepCollectionEquality;
}

@OverrideEquality()
class User {
  final String name;
  User({required this.name});

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && name == other.name;
}
''');
    });

    test(
      'reports lint when only hashCode is overridden but == is missing',
      () async {
        await t.assertDiagnostics(
          r'''
class OverrideEquality {
  const OverrideEquality({this.deepCollectionEquality});
  final bool? deepCollectionEquality;
}

@OverrideEquality()
class User {
  final String name;
  User({required this.name});

  @override
  int get hashCode => name.hashCode;
}
''',
          [t.lint(123, 19)],
        );
      },
    );

    test(
      'reports lint when only == is overridden but hashCode is missing',
      () async {
        await t.assertDiagnostics(
          r'''
class OverrideEquality {
  const OverrideEquality({this.deepCollectionEquality});
  final bool? deepCollectionEquality;
}

@OverrideEquality()
class User {
  final String name;
  User({required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && name == other.name;
}
''',
          [t.lint(123, 19)],
        );
      },
    );

    test('no lint on class without annotation', () async {
      await t.assertNoDiagnostics(r'''
class User {
  final String name;
  User({required this.name});
}
''');
    });

    test('case-insensitive annotation matching', () async {
      await t.assertDiagnostics(
        r'''
class overrideequality {
  const overrideequality({this.deepCollectionEquality});
  final bool? deepCollectionEquality;
}

@overrideequality()
class User {
  final String name;
  User({required this.name});
}
''',
        [t.lint(123, 19)],
      );
    });
  });
}
