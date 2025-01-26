// To parse this JSON data, do
//
//     final transactionUnsyncDateModel = transactionUnsyncDateModelFromJson(jsonString);

import 'dart:convert';

TransactionUnsyncDateModel transactionUnsyncDateModelFromJson(String str) => TransactionUnsyncDateModel.fromJson(json.decode(str));

String transactionUnsyncDateModelToJson(TransactionUnsyncDateModel data) => json.encode(data.toJson());

class TransactionUnsyncDateModel {
    final DateTime date;

    TransactionUnsyncDateModel({
        required this.date,
    });

    factory TransactionUnsyncDateModel.fromJson(Map<String, dynamic> json) => TransactionUnsyncDateModel(
        date: DateTime.parse(json["date"]),
    );

    Map<String, dynamic> toJson() => {
        "date": date.toIso8601String(),
    };
}
