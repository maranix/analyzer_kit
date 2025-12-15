import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

Future<ResolvedLibraryResult> getResolvedLibrary(String content) async {
  final tempDir = Directory.systemTemp.createTempSync('dart_analyzer_kit_test');
  final file = File(p.join(tempDir.path, 'lib', 'test.dart'));
  file.createSync(recursive: true);
  file.writeAsStringSync(content);

  final collection = AnalysisContextCollection(
    includedPaths: [tempDir.path],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  final context = collection.contextFor(file.path);
  final result = await context.currentSession.getResolvedLibrary(file.path);

  if (result is! ResolvedLibraryResult) {
    throw StateError('Failed to resolve library: $result');
  }

  return result;
}

Future<ClassElement> getClassElement(
  String content, {
  String className = 'Test',
}) async {
  final result = await getResolvedLibrary(content);
  final element = result.element.getClass(className);
  if (element == null) {
    throw StateError('Class $className not found in test content');
  }
  return element;
}
