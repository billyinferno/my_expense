// To parse this JSON data, do
//
//     final walletStatModel = walletStatModelFromJson(jsonString);
import 'dart:convert';

List<WalletStatModel> walletStatModelFromJson(String str) =>
    List<WalletStatModel>.from(
        json.decode(str).map((x) => WalletStatModel.fromJson(x)));

String walletStatModelToJson(List<WalletStatModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class WalletStatModel {
  WalletStatModel({
    required this.date,
    this.income,
    this.expense,
  });

  final DateTime date;
  final double? income;
  final double? expense;

  factory WalletStatModel.fromJson(Map<String, dynamic> json) =>
      WalletStatModel(
        date: DateTime.parse(json["date"]),
        income: (json["income"] ?? 0).toDouble(),
        expense: (json["expense"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "date":
            "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        "income": income,
        "expense": expense,
      };
}
