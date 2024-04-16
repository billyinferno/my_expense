// To parse this JSON data, do
//
//     final transactionTopModel = transactionTopModelFromJson(jsonString);

import 'dart:convert';

TransactionTopModel transactionTopModelFromJson(String str) => TransactionTopModel.fromJson(json.decode(str));

String transactionTopModelToJson(TransactionTopModel data) => json.encode(data.toJson());

class TransactionTopModel {
  final String transactionName;
  final double transactionAmount;
  final int transactionCategoryId;
  final String transactionCategoryName;
  final int transactionWalletId;
  final String transactionWalletName;

  TransactionTopModel({
    required this.transactionName,
    required this.transactionAmount,
    required this.transactionCategoryId,
    required this.transactionCategoryName,
    required this.transactionWalletId,
    required this.transactionWalletName,
  });

  factory TransactionTopModel.fromJson(Map<String, dynamic> json) => TransactionTopModel(
    transactionName: json["transaction_name"],
    transactionAmount: json["transaction_amount"]?.toDouble(),
    transactionCategoryId: json["transaction_category_id"],
    transactionCategoryName: json["transaction_category_name"],
    transactionWalletId: json["transaction_wallet_id"],
    transactionWalletName: json["transaction_wallet_name"],
  );

  Map<String, dynamic> toJson() => {
    "transaction_name": transactionName,
    "transaction_amount": transactionAmount,
    "transaction_category_id": transactionCategoryId,
    "transaction_category_name": transactionCategoryName,
    "transaction_wallet_id": transactionWalletId,
    "transaction_wallet_name": transactionWalletName,
  };
}
