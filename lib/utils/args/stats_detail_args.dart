import 'package:my_expense/_index.g.dart';

class StatsDetailArgs {
  final String type;
  final DateTime fromDate;
  final DateTime toDate;
  final CurrencyModel currency;
  final WalletModel wallet;
  final IncomeExpenseCategoryModel incomeExpenseCategory;
  final String name;
  final String search;

  StatsDetailArgs({
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.currency,
    required this.wallet,
    required this.incomeExpenseCategory,
    required this.name,
    required this.search
  });
}