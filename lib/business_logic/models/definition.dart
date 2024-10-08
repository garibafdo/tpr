class Definition {
  int id;
  String word;
  String definition;
  String bookName;
  int userOrder;
  int hasInflections;
  int hasRootFamily;
  int hasCompoundFamily;
  int hasWordFamily;
  int hasFreq;

  Definition({
    this.id = 0,
    this.word = "",
    this.definition = "",
    this.bookName = "",
    this.userOrder = 0,
    this.hasInflections = 0,
    this.hasRootFamily = 0,
    this.hasCompoundFamily = 0,
    this.hasWordFamily = 0,
    this.hasFreq = 0,
  });

  factory Definition.fromJson(Map<dynamic, dynamic> json) {
    return Definition(
      id: json["id"] ?? 0,
      word: json["word"] ?? "n/a",
      definition: json["definition"] ?? "n/a",
      bookName: json["name"] ?? "n/a",
      userOrder: json["user_order"] ?? 0,
      hasInflections: json["has_inflections"] ?? 0,
      hasRootFamily: json["has_root_family"] ?? 0,
      hasCompoundFamily: json["has_compound_family"] ?? 0,
      hasWordFamily: json["has_word_family"] ?? 0,
      hasFreq: json["has_freq"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "word": word,
        "definition": definition,
        "name": bookName,
        "user_order": userOrder,
        "has_inflections": hasInflections,
        "has_root_family": hasRootFamily,
        "has_compound_family": hasCompoundFamily,
        "has_word_family": hasWordFamily,
        "has_freq": hasFreq,
      };

  @override
  String toString() {
    return '$bookName: $definition';
  }
}
