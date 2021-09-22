class TransactionStatsDetailModel {
    TransactionStatsDetailModel({
        required this.id,
        required this.name,
        required this.type,
        required this.date,
        required this.categoriesId,
        required this.categoriesName,
        required this.walletId,
        required this.walletName,
        required this.amount,
    });

    final int id;
    final String name;
    final String type;
    final DateTime date;
    final int categoriesId;
    final String categoriesName;
    final int walletId;
    final String walletName;
    final double amount;

    factory TransactionStatsDetailModel.fromJson(Map<String, dynamic> json) => TransactionStatsDetailModel(
        id: json["id"],
        name: json["name"],
        type: json["type"],
        date: DateTime.parse(json["date"]),
        categoriesId: json["categories_id"],
        categoriesName: json["categories_name"],
        walletId: json["wallet_from_id"],
        walletName: json["wallet_from_name"],
        amount: json["amount"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "type": type,
        "date": date.toIso8601String(),
        "categories_id": categoriesId,
        "categories_name": categoriesName,
        "wallet_from_id": walletId,
        "wallet_from_name": walletName,
        "amount": amount,
    };
}