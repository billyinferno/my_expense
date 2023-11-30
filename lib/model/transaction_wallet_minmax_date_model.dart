// To parse this JSON data, do
//
//     final transactionWalletMinMaxDateModel = transactionWalletMinMaxDateModelFromJson(jsonString);

import 'dart:convert';

TransactionWalletMinMaxDateModel transactionWalletMinMaxDateModelFromJson(String str) => TransactionWalletMinMaxDateModel.fromJson(json.decode(str));

String transactionWalletMinMaxDateModelToJson(TransactionWalletMinMaxDateModel data) => json.encode(data.toJson());

class TransactionWalletMinMaxDateModel {
    final DateTime? minDate;
    final DateTime? maxDate;

    TransactionWalletMinMaxDateModel({
        required this.minDate,
        required this.maxDate,
    });

    factory TransactionWalletMinMaxDateModel.fromJson(Map<String, dynamic> json) => TransactionWalletMinMaxDateModel(
        minDate: (json["min_date"] == null ? null : DateTime.parse(json["min_date"])),
        maxDate: (json["max_date"] == null ? null : DateTime.parse(json["max_date"])),
    );

    Map<String, dynamic> toJson() => {
        "min_date": (minDate == null ? null : minDate!.toIso8601String()),
        "max_date": (maxDate == null ? null : maxDate!.toIso8601String()),
    };
}
