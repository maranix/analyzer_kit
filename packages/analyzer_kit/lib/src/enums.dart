import "package:analyzer/error/error.dart" show DiagnosticCode;
import "package:analyzer_kit/src/constants.dart";

/// Annotation names recognized by the plugin.
enum FeatureAnnotation {
  dataClass("DataClass"),
  copyWith("CopyWith"),
  overrideToString("OverrideToString"),
  overrideEquality("OverrideEquality"),
  serialize("Serialize"),
  deserialize("Deserialize")
  ;

  const FeatureAnnotation(this.name);

  final String name;

  static FeatureAnnotation? fromString(String name) {
    final iter = values.iterator;
    FeatureAnnotation? result;

    while (iter.moveNext()) {
      final curr = iter.current;
      if (curr.name == name) {
        result = curr;
      }
    }

    return result;
  }

  Iterable<FeatureMethod> get expectedMethods => switch (this) {
    FeatureAnnotation.copyWith => [
      FeatureMethod.copyWith,
    ],
    FeatureAnnotation.overrideToString => [
      FeatureMethod.overrideToString,
    ],
    FeatureAnnotation.serialize => [
      FeatureMethod.toMap,
    ],
    FeatureAnnotation.deserialize => [
      FeatureMethod.fromMap,
    ],
    FeatureAnnotation.overrideEquality => [
      FeatureMethod.overrideEquals,
      FeatureMethod.overrideHashCode,
    ],
    FeatureAnnotation.dataClass => [
      FeatureMethod.copyWith,
      FeatureMethod.overrideToString,
      FeatureMethod.overrideEquals,
      FeatureMethod.overrideHashCode,
      FeatureMethod.toMap,
      FeatureMethod.fromMap,
    ],
  };
}

/// Method names that each annotation expects on the class.
enum FeatureMethod {
  copyWith("copyWith"),
  overrideToString("toString"),
  overrideHashCode("hashCode"),
  overrideEquals("=="),
  operatorEquals("operator =="),
  fromMap("fromMap"),
  fromJson("fromJson"),
  toMap("toMap")
  ;

  const FeatureMethod(this.name);

  final String name;

  static FeatureMethod? fromString(String name) {
    final iter = values.iterator;
    FeatureMethod? result;

    while (iter.moveNext()) {
      final curr = iter.current;
      if (curr.name == name) {
        result = curr;
      }
    }

    return result;
  }
}

/// Maps each feature to its diagnostic code.
enum FeatureDiagnosticCode {
  dataClass(LintCodes.dataClass),
  copyWith(LintCodes.copyWith),
  overrideToString(LintCodes.overrideToString),
  overrideEquality(LintCodes.overrideEquality),
  serialize(LintCodes.serialize),
  deserialize(LintCodes.deserialize)
  ;

  const FeatureDiagnosticCode(this.diag);

  final DiagnosticCode diag;
}

/// Composite annotations that group related features.
enum CompositeFeatureAnnotation {
  dataClass([
    FeatureAnnotation.copyWith,
    FeatureAnnotation.overrideToString,
    FeatureAnnotation.overrideEquality,
    FeatureAnnotation.serialize,
    FeatureAnnotation.deserialize,
  ])
  ;

  const CompositeFeatureAnnotation(this.features);

  final Iterable<FeatureAnnotation> features;
}
