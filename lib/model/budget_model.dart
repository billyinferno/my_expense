import 'package:my_expense/_index.g.dart';

class BudgetModel {
  BudgetModel({
    required this.id,
    required this.category,
    required this.totalTransaction,
    required this.amount,
    required this.used,
    required this.useForDaily,
    required this.status,
    required this.currency,
  });

  final int id;
  final CategoryModel category;
  final int totalTransaction;
  final double amount;
  final double used;
  final bool useForDaily;
  final String status;
  final CurrencyModel currency;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json["id"],
        category: CategoryModel.fromJson(json["category"]),
        totalTransaction: (json["total_transaction"] ?? 0),
        amount: (json["amount"] ?? 0).toDouble(),
        used: (json["used"] ?? 0).toDouble(),
        useForDaily: (json["use_for_daily"] ?? true),
        status: (json["status"] ?? "in"),
        currency: CurrencyModel.fromJson(json["currency"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "category": category.toJson(),
        "total_transaction": totalTransaction,
        "amount": amount,
        "used": used,
        "use_for_daily": useForDaily,
        "status": status,
        "currency": currency.toJson(),
      };
}
