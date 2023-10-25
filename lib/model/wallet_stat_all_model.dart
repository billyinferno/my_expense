// To parse this JSON data, do
//
//     final walletStatAllModel = walletStatAllModelFromJson(jsonString);
import 'dart:convert';

List<WalletStatAllModel> walletStatAllModelFromJson(String str) => List<WalletStatAllModel>.from(json.decode(str).map((x) => WalletStatAllModel.fromJson(x)));

String walletStatAllModelToJson(List<WalletStatAllModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class WalletStatAllModel {
    WalletStatAllModel({
        required this.ccy,
        required this.symbol,
        required this.data,
    });

    final String ccy;
    final String symbol;
    final List<Datum> data;

    factory WalletStatAllModel.fromJson(Map<String, dynamic> json) => WalletStatAllModel(
        ccy: json["ccy"],
        symbol: json["symbol"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "ccy": ccy,
        "symbol": symbol,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
    Datum({
        required this.date,
        required this.balance,
        required this.diff,
        required this.income,
        required this.expense,
    });

    final DateTime date;
    final double? balance;
    final double? diff;
    final double? income;
    final double? expense;

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        date: DateTime.parse(json["date"]).toLocal(),
        balance: (json["balance"] == null ? 0 : json["balance"]?.toDouble()),
        diff: (json["diff"] == null ? 0 : json["diff"]?.toDouble()),
        income: (json["income"] == null ? 0 : json["income"]?.toDouble()),
        expense: (json["expense"] == null ? 0 : json["expense"]?.toDouble()),
    );

    Map<String, dynamic> toJson() => {
        "date": date.toIso8601String(),
        "balance": balance,
        "diff": diff,
        "income": income,
        "expense": expense,
    };
}
