class LastTransactionModel {
    final String name;
    final CategoryLastTransaction category;

    LastTransactionModel({
        required this.name,
        required this.category,
    });

    factory LastTransactionModel.fromJson(Map<String, dynamic> json) => LastTransactionModel(
        name: json["name"],
        category: CategoryLastTransaction.fromJson(json["category"]),
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "category": category.toJson(),
    };
}

class CategoryLastTransaction {
  final int id;
  final String name;

  CategoryLastTransaction({
    required this.id,
    required this.name,
  });


  factory CategoryLastTransaction.fromJson(Map<String, dynamic> json) => CategoryLastTransaction(
    id: json["id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
      "id": id,
      "name": name,
  };
}
