import 'package:my_expense/model/currency_model.dart';

class StatsTransactionArgs {
  final String type;
  final int categoryId;
  final String categoryName;
  final CurrencyModel currency;
  final int walletId;
  final DateTime fromDate;
  final DateTime toDate;
  final double amount;
  final double total;

  StatsTransactionArgs({required this.type, required this.categoryId, required this.categoryName, required this.currency, required this.walletId, required this.fromDate, required this.toDate, required this.amount, required this.total});
}