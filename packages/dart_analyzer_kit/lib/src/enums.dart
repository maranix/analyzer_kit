enum CaseStyle { sensitive, insensitive }

enum Annotations {
  copyWith("CopyWith"),
  serialize("Serialize");

  final String name;

  const Annotations(this.name);
}
