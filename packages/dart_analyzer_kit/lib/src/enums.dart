enum CaseStyle { sensitive, insensitive }

enum Annotations {
  copyWith("CopyWith"),
  serialize("Serialize"),
  debugString("DebugString"),
  overrideEquality("OverrideEquality");

  final String name;

  const Annotations(this.name);
}
