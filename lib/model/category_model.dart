class CategoryModel {
  final int id;
  final String name;
  final String type;

  CategoryModel(
    this.id,
    this.name,
    this.type
  );

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
        json["id"],
        json["name"],
        json["type"]
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "type": type
  };
}
