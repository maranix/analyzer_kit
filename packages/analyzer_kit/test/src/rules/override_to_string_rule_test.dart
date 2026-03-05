import "package:analyzer_kit/src/rules/annotation_rule/annotation_rule.dart";
import "package:analyzer_testing/analysis_rule/analysis_rule.dart";
import "package:test/test.dart";

class OverrideToStringRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = OverrideToStringRule();
    super.setUp();
  }
}

void main() {
  late OverrideToStringRuleTest t;

  setUp(() {
    t = OverrideToStringRuleTest();
    t.setUp();
  });

  tearDown(() => t.tearDown());

  group("OverrideToStringRule", () {
    test(
      "reports lint when @OverrideToString present but toString missing",
      () async {
        await t.assertDiagnostics(
          r"""
class OverrideToString {
  const OverrideToString();
}

@OverrideToString()
class User {
  final String name;
  User({required this.name});
}
""",
          [t.lint(56, 19)],
        );
      },
    );

    test("no lint when toString is overridden", () async {
      await t.assertNoDiagnostics(r"""
class OverrideToString {
  const OverrideToString();
}

@OverrideToString()
class User {
  final String name;
  User({required this.name});

  @override
  String toString() => 'User(name: $name)';
}
""");
    });

    test("no lint on class without annotation", () async {
      await t.assertNoDiagnostics(r"""
class User {
  final String name;
  User({required this.name});
}
""");
    });

    test("reports lint with const convenience variable", () async {
      await t.assertDiagnostics(
        r"""
class OverrideToString {
  const OverrideToString();
}
const overrideToString = OverrideToString();

@overrideToString
class User {
  final String name;
  User({required this.name});
}
""",
        [t.lint(101, 17)],
      );
    });

    test("case-insensitive annotation matching", () async {
      await t.assertDiagnostics(
        r"""
class overridetostring {
  const overridetostring();
}

@overridetostring()
class User {
  final String name;
  User({required this.name});
}
""",
        [t.lint(56, 19)],
      );
    });
  });
}
