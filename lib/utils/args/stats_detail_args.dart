import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/income_expense_category_model.dart';
import 'package:my_expense/model/wallet_model.dart';

class StatsDetailArgs {
  final String type;
  final DateTime fromDate;
  final DateTime toDate;
  final CurrencyModel currency;
  final WalletModel wallet;
  final IncomeExpenseCategoryModel incomeExpenseCategory;
  final String name;
  final String search;

  StatsDetailArgs({required this.type, required this.fromDate, required this.toDate, required this.currency, required this.wallet, required this.incomeExpenseCategory, required this.name, required this.search});
}