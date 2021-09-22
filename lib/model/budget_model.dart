import 'package:my_expense/model/category_model.dart';
import 'package:my_expense/model/currency_model.dart';

class BudgetModel {
  BudgetModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.used,
    required this.currency,
  });

  final int id;
  final CategoryModel category;
  final double amount;
  final double used;
  final CurrencyModel currency;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    id: json["id"],
    category: CategoryModel.fromJson(json["category"]),
    amount: json["amount"] as double,
    used: json["used"] as double,
    currency: CurrencyModel.fromJson(json["currency"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "category": category.toJson(),
    "amount": amount,
    "used": used,
    "currency": currency.toJson(),
  };
}