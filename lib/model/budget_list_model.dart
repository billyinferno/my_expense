import 'package:my_expense/_index.g.dart';

class BudgetListModel {
  final CurrencyModel currency;
  final List<BudgetModel> budgets;

  BudgetListModel({required this.currency, required this.budgets});

  factory BudgetListModel.fromJson(Map<String, dynamic> json) {
    List<BudgetModel> budgets = [];

    json["budgets"].forEach((value) {
      BudgetModel budget = BudgetModel.fromJson(value);
      budgets.add(budget);
    });
    return BudgetListModel(
      currency: CurrencyModel.fromJson(json["currency"]),
      budgets: budgets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "currency": currency.toJson(),
      "budgets": List<dynamic>.from(budgets.map((e) => e.toJson()))
    };
  }
}