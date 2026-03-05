import "package:analyzer_kit/src/rules/annotation_rule/annotation_rule.dart";
import "package:analyzer_testing/analysis_rule/analysis_rule.dart";
import "package:test/test.dart";

class DataClassRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DataClassRule();
    super.setUp();
  }
}

/// Shared DataClass annotation definition for test code.
///
/// Defines the DataClass, CopyWith, OverrideToString, OverrideEquality,
/// Serialize, and Deserialize annotations as simple inline classes.
const _annotations = r"""
class DataClass {
  const DataClass({
    this.copyWith = true,
    this.overrideEquality = true,
    this.overrideToString = true,
    this.serialize = true,
    this.deserialize = true,
    this.deepCollectionEquality,
  });
  final bool copyWith;
  final bool overrideEquality;
  final bool overrideToString;
  final bool serialize;
  final bool deserialize;
  final bool? deepCollectionEquality;
}

class CopyWith {
  const CopyWith();
}

class OverrideToString {
  const OverrideToString();
}

class OverrideEquality {
  const OverrideEquality({this.deepCollectionEquality});
  final bool? deepCollectionEquality;
}

class Serialize {
  const Serialize({this.name});
  final Object? name;
}

class Deserialize {
  const Deserialize({this.name});
  final Object? name;
}
""";

void main() {
  late DataClassRuleTest t;

  setUp(() {
    t = DataClassRuleTest();
    t.setUp();
  });

  tearDown(() => t.tearDown());

  group("DataClassRule", () {
    test(
      "reports lint when @DataClass present but all methods missing",
      () async {
        await t.assertDiagnostics(
          """
$_annotations
@DataClass()
class User {
  final String name;
  User({required this.name});
}
""",
          [t.lint(776, 12)],
        );
      },
    );

    test("no lint when all required methods are present", () async {
      await t.assertNoDiagnostics("""
$_annotations
@DataClass()
class User {
  final String name;
  User({required this.name});

  User copyWith({String? name}) => User(name: name ?? this.name);

  @override
  String toString() => 'User(name: \$name)';

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && name == other.name;

  Map<String, dynamic> toMap() => {'name': name};

  factory User.fromMap(Map<String, dynamic> map) =>
      User(name: map['name'] as String);
}
""");
    });

    test("reports lint when only some methods are present", () async {
      await t.assertDiagnostics(
        """
$_annotations
@DataClass()
class User {
  final String name;
  User({required this.name});

  User copyWith({String? name}) => User(name: name ?? this.name);
}
""",
        [t.lint(776, 12)],
      );
    });

    test(
      "no lint when copyWith is disabled and other methods present",
      () async {
        await t.assertNoDiagnostics("""
$_annotations
@DataClass(copyWith: false)
class User {
  final String name;
  User({required this.name});

  @override
  String toString() => 'User(name: \$name)';

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && name == other.name;

  Map<String, dynamic> toMap() => {'name': name};

  factory User.fromMap(Map<String, dynamic> map) =>
      User(name: map['name'] as String);
}
""");
      },
    );

    test("no lint when all features are disabled", () async {
      await t.assertNoDiagnostics("""
$_annotations
@DataClass(
  copyWith: false,
  overrideEquality: false,
  overrideToString: false,
  serialize: false,
  deserialize: false,
)
class User {
  final String name;
  User({required this.name});
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

    test("reports lint when only equality methods are missing", () async {
      await t.assertDiagnostics(
        """
$_annotations
@DataClass(
  copyWith: false,
  overrideToString: false,
  serialize: false,
  deserialize: false,
)
class User {
  final String name;
  User({required this.name});
}
""",
        [t.lint(776, 101)],
      );
    });

    test(
      "DataClass with deepCollectionEquality param does not affect rule",
      () async {
        await t.assertDiagnostics(
          """
$_annotations
@DataClass(deepCollectionEquality: true)
class User {
  final String name;
  User({required this.name});
}
""",
          [t.lint(776, 40)],
        );
      },
    );
  });
}
