// To parse this JSON data, do
//
//     final budgetStatModel = budgetStatModelFromJson(jsonString);

import 'dart:convert';

BudgetStatModel budgetStatModelFromJson(String str) => BudgetStatModel.fromJson(json.decode(str));

String budgetStatModelToJson(BudgetStatModel data) => json.encode(data.toJson());

class BudgetStatModel {
    final List<BudgetStatDetail> monthly;
    final List<BudgetStatDetail> yearly;

    BudgetStatModel({
        required this.monthly,
        required this.yearly,
    });

    factory BudgetStatModel.fromJson(Map<String, dynamic> json) => BudgetStatModel(
        monthly: List<BudgetStatDetail>.from(json["monthly"].map((x) => BudgetStatDetail.fromJson(x))),
        yearly: List<BudgetStatDetail>.from(json["yearly"].map((x) => BudgetStatDetail.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "monthly": List<dynamic>.from(monthly.map((x) => x.toJson())),
        "yearly": List<dynamic>.from(yearly.map((x) => x.toJson())),
    };
}

class BudgetStatDetail {
    final String date;
    final double totalAmount;
    final double averageAmount;

    BudgetStatDetail({
        required this.date,
        required this.totalAmount,
        required this.averageAmount,
    });

    factory BudgetStatDetail.fromJson(Map<String, dynamic> json) => BudgetStatDetail(
        date: json["date"],
        totalAmount: json["total_amount"]?.toDouble(),
        averageAmount: json["average_amount"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "date": date,
        "total_amount": totalAmount,
        "average_amount": averageAmount,
    };
}
