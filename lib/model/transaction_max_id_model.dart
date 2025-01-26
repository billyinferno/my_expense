// To parse this JSON data, do
//
//     final transactionMaxIdModel = transactionMaxIdModelFromJson(jsonString);

import 'dart:convert';

TransactionMaxIdModel transactionMaxIdModelFromJson(String str) => TransactionMaxIdModel.fromJson(json.decode(str));

String transactionMaxIdModelToJson(TransactionMaxIdModel data) => json.encode(data.toJson());

class TransactionMaxIdModel {
    final int id;

    TransactionMaxIdModel({
        required this.id,
    });

    factory TransactionMaxIdModel.fromJson(Map<String, dynamic> json) => TransactionMaxIdModel(
        id: json["id"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
    };
}
