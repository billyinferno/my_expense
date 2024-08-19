import 'package:my_expense/_index.g.dart';

class TransactionListModel {
  final int id;
  final String name;
  final String type;
  final DateTime date;
  final String description;
  final CategoryTransactionModel? category;
  final WalletTransactionModel wallet;
  final WalletTransactionModel? walletTo;
  final UserPermissionModel usersPermissionsUser;
  final bool cleared;
  final double amount;
  final double exchangeRate;

  TransactionListModel(
    this.id,
    this.name,
    this.type,
    this.date,
    this.description,
    this.category,
    this.wallet,
    this.walletTo,
    this.usersPermissionsUser,
    this.cleared,
    this.amount,
    this.exchangeRate,
  );

  factory TransactionListModel.fromJson(Map<String, dynamic> json) {
    CategoryTransactionModel? cat;
    if (json["category"] != null) {
      cat = CategoryTransactionModel.fromJson(json["category"]);
    } else {
      cat = null;
    }

    WalletTransactionModel? walletTo;
    if (json["walletTo"] != null) {
      walletTo = WalletTransactionModel.fromJson(json["walletTo"]);
    } else {
      walletTo = null;
    }

    return TransactionListModel(
      json["id"],
      json["name"],
      json["type"],
      DateTime.parse(json["date"]).toLocal(),
      json["description"],
      cat,
      WalletTransactionModel.fromJson(json["wallet"]),
      walletTo,
      UserPermissionModel.fromJson(json["users_permissions_user"]),
      json["cleared"],
      (json["amount"] ?? 0).toDouble(),
      (json["exchange_rate"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "type": type,
    "date": date.toIso8601String(),
    "description": description,
    "category": (category?.toJson()),
    "wallet": wallet.toJson(),
    "walletTo": (walletTo?.toJson()),
    "users_permissions_user": usersPermissionsUser.toJson(),
    "cleared": cleared,
    "amount": amount,
    "exchange_rate": exchangeRate,
  };
}

class CategoryTransactionModel {
  final int id;
  final String name;

  CategoryTransactionModel(this.id, this.name);

  factory CategoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return CategoryTransactionModel(
      (json["id"] ?? -1),
      (json["name"] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class WalletTransactionModel {
  final int id;
  final String name;
  final int currencyId;
  final String currency;
  final String symbol;

  WalletTransactionModel(
    this.id,
    this.name,
    this.currencyId,
    this.currency,
    this.symbol
  );

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      (json["id"] ?? -1),
      (json["name"] ?? ''),
      (json["currencyId"] ?? -1),
      (json["currency"] ?? ''),
      (json["symbol"] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "currencyId": currencyId,
    "currency": currency,
    "symbol": symbol
  };
}
