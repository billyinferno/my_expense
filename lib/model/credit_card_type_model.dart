class CreditCardTypeModel {
  final int id;
  final String name;
  final String type;

  CreditCardTypeModel(
    this.id,
    this.name,
    this.type
  );

  factory CreditCardTypeModel.fromJson(Map<String, dynamic> json) {
    return CreditCardTypeModel(
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
