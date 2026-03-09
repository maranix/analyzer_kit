import "package:analyzer_kit/src/utils/code_utils.dart";
import "package:test/test.dart";

void main() {
  group("formatCode", () {
    test("formats a simple variable declaration", () {
      final result = formatCode('String x = "hello";');
      expect(result.trim(), 'String x = "hello";');
    });

    test("formats a simple function", () {
      final result = formatCode("int add(int a, int b) => a + b;");
      expect(result.trim(), "int add(int a, int b) => a + b;");
    });

    test("normalizes whitespace in code", () {
      final result = formatCode('String   x  =  "hello" ;');
      expect(result.trim(), 'String x = "hello";');
    });
  });

  group("formatConstructor", () {
    test("formats a simple factory constructor", () {
      final code =
          "factory Foo.fromMap(Map<String, dynamic> map) { return Foo(); }";
      final result = formatConstructor(code);
      expect(result, contains("factory Foo.fromMap"));
      expect(result, contains("return Foo();"));
    });

    test("removes surrounding class wrapper", () {
      final code = "factory Foo.create() { return Foo(); }";
      final result = formatConstructor(code);
      // Should not contain class _Dummy wrapper
      expect(result, isNot(contains("class _Dummy")));
    });

    test("preserves constructor body", () {
      final code = """
factory MyClass.fromMap(Map<String, dynamic> map) {
  return MyClass(
    name: map['name'] as String
  );
}
""";
      final result = formatConstructor(code);
      expect(result, contains("factory MyClass.fromMap"));
      expect(result, contains("map['name'] as String"));
    });
  });
}
