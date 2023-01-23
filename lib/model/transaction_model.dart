class TransactionModel {
  TransactionModel(
    this.name,
    this.type,
    this.category,
    this.date,
    this.wallet,
    this.cleared,
    this.description,
    this.usersPermissionsUser,
    this.amount,
    this.walletTo,
    this.exchangeRate
  );

  final String name;
  final String type;
  final WalletCategoryTransactionModel? category;
  final DateTime date;
  final WalletCategoryTransactionModel wallet;
  final bool cleared;
  final String description;
  final WalletCategoryTransactionModel usersPermissionsUser;
  final double amount;
  final WalletCategoryTransactionModel? walletTo;
  final double exchangeRate;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    WalletCategoryTransactionModel? _category;
    WalletCategoryTransactionModel? _walletTo;

    if(json["category"] != null) {
      _category = WalletCategoryTransactionModel.fromJson(json["category"]);
    }
    else {
      _category = null;
    }

    if(json["walletTo"] != null) {
      _walletTo = WalletCategoryTransactionModel.fromJson(json["walletTo"]);
    }
    else {
      _walletTo = null;
    }

    // print(json.toString());

    return TransactionModel(
      json["name"],
      json["type"],
      _category,
      DateTime.parse(json["date"]).toLocal(),
      WalletCategoryTransactionModel.fromJson(json["wallet"]),
      json["cleared"],
      json["description"],
      WalletCategoryTransactionModel.fromJson(json["users_permissions_user"]),
      json["amount"].toDouble(),
      _walletTo,
      json["exchange_rate"]
    );
  }

  Map<String, dynamic> toJson() {
    var _category = (category == null ? null : category!.toJson());
    var _walletTo = (walletTo == null ? null : walletTo!.toJson());

    return {
      "name": name,
      "type": type,
      "category": _category,
      "date": date.toUtc().toIso8601String(),
      "wallet": wallet.toJson(),
      "cleared": cleared,
      "description": description,
      "users_permissions_user": usersPermissionsUser.toJson(),
      "amount": amount,
      "walletTo": _walletTo,
      "exchange_rate": exchangeRate
    };
  }
}

class WalletCategoryTransactionModel {
  final int id;

  WalletCategoryTransactionModel(this.id);

  factory WalletCategoryTransactionModel.fromJson(Map<String, dynamic> json) => WalletCategoryTransactionModel(
    json["id"]
  );

  Map<String, dynamic> toJson() => {
    "id": id
  };
}
