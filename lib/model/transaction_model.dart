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
    WalletCategoryTransactionModel? category;
    WalletCategoryTransactionModel? walletTo;

    if(json["category"] != null) {
      category = WalletCategoryTransactionModel.fromJson(json["category"]);
    }
    else {
      category = null;
    }

    if(json["walletTo"] != null) {
      walletTo = WalletCategoryTransactionModel.fromJson(json["walletTo"]);
    }
    else {
      walletTo = null;
    }

    // print(json.toString());

    return TransactionModel(
      json["name"],
      json["type"],
      category,
      DateTime.parse(json["date"]).toLocal(),
      WalletCategoryTransactionModel.fromJson(json["wallet"]),
      json["cleared"],
      json["description"],
      WalletCategoryTransactionModel.fromJson(json["users_permissions_user"]),
      json["amount"].toDouble(),
      walletTo,
      json["exchange_rate"]
    );
  }

  Map<String, dynamic> toJson() {
    // ignore: prefer_null_aware_operators
    var currentCategory = (category == null ? null : category!.toJson());
    // ignore: prefer_null_aware_operators
    var currentWalletTo = (walletTo == null ? null : walletTo!.toJson());

    return {
      "name": name,
      "type": type,
      "category": currentCategory,
      "date": date.toUtc().toIso8601String(),
      "wallet": wallet.toJson(),
      "cleared": cleared,
      "description": description,
      "users_permissions_user": usersPermissionsUser.toJson(),
      "amount": amount,
      "walletTo": currentWalletTo,
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
