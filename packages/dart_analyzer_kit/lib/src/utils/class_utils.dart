part of 'utils.dart';

bool hasAnnotation(ClassElement element, Annotations annotation) =>
    element.metadata.annotations.any(
      (a) =>
          stringsMatchByCharCode(a.element?.displayName ?? "", annotation.name),
    );

bool hasMethod(ClassElement element, String methodName) =>
    element.getMethod(methodName) != null;
