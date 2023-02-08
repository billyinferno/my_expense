class WalletTransactionList {
  String type = '';
  Object? data;
}

class WalletTransactionExpenseIncome {
  DateTime date = DateTime.now();
  double expense = 0;
  double income = 0;
}