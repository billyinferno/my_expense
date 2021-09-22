import 'package:my_expense/model/budget_model.dart';
import 'package:my_expense/model/currency_model.dart';

class BudgetListModel {
  final CurrencyModel currency;
  final List<BudgetModel> budgets;

  BudgetListModel({required this.currency, required this.budgets});

  factory BudgetListModel.fromJson(Map<String, dynamic> json) {
    List<BudgetModel> _budgets = [];

    json["budgets"].forEach((value) {
      BudgetModel _budget = BudgetModel.fromJson(value);
      _budgets.add(_budget);
    });
    return BudgetListModel(
      currency: CurrencyModel.fromJson(json["currency"]),
      budgets: _budgets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "currency": this.currency.toJson(),
      "budgets": List<dynamic>.from(this.budgets.map((e) => e.toJson()))
    };
  }
}