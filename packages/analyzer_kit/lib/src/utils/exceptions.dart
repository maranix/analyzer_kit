sealed class AnnotationException implements Exception {
  const AnnotationException(this.message);

  final String message;

  @override
  String toString() => "AnnotationException: $message";
}

final class AnnotationFeatureNotFoundException extends AnnotationException {
  AnnotationFeatureNotFoundException(String featureName, String annotationName)
    : super(
        "Feature `$featureName` not found in Annotation `$annotationName`",
      );
}

final class AnnotationMultipleFeatureExpressionsException
    extends AnnotationException {
  AnnotationMultipleFeatureExpressionsException(
    String featureName,
    String annotationName,
  ) : super(
        "Multiple expressions found for feature `$featureName` in Annotation `$annotationName`",
      );
}
