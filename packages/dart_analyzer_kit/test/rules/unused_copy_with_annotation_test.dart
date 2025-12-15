import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:dart_analyzer_kit/src/rules/unused_copy_with_annotation.dart';
import 'package:test/test.dart';
import '../utils/test_utils.dart';

void main() {
  group('UnusedCopyWithAnnotation', () {
    test('reports when copyWith method is missing', () async {
      final code = '''
      const CopyWith = 1;
      
      @CopyWith
      class Test {
        final String name;
        Test(this.name);
      }
      ''';

      final count = await _checkRule(code);
      expect(count, 1);
    });

    test('does not report when copyWith method exists', () async {
      final code = '''
      const CopyWith = 1;
      
      @CopyWith
      class Test {
        final String name;
        Test(this.name);
        
        Test copyWith({String? name}) => Test(name ?? this.name);
      }
      ''';

      final count = await _checkRule(code);
      expect(count, 0);
    });

    test('does not report on unrelated annotations', () async {
      final code = '''
      const OtherAnnotation = 1;
      
      @OtherAnnotation
      class Test {
        final String name;
        Test(this.name);
      }
      ''';

      final count = await _checkRule(code);
      expect(count, 0);
    });
  });
}

Future<int> _checkRule(String code) async {
  final libResult = await getResolvedLibrary(code);
  final unitResult = libResult.units.first;

  final tracker = ReportTracker();
  final visitor = CopyWithAnnotationVisitor(tracker);
  unitResult.unit.accept(visitor);

  return tracker.count;
}

class ReportTracker extends AnalysisRule {
  int count = 0;

  ReportTracker()
    : super(
        name: 'test_tracker',
        description: 'A test tracker for counting reports',
      );

  @override
  DiagnosticCode get diagnosticCode => UnusedCopyWithAnnotation.diagCode;

  @override
  void reportAtNode(
    AstNode? node, {
    List<Object> arguments = const [],
    List<DiagnosticMessage>? contextMessages,
  }) {
    count++;
  }
}
