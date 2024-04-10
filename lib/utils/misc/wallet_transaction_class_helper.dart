enum WalletListType {
  none,
  header,
  item
}
class WalletTransactionList {
  WalletListType type =  WalletListType.none;
  Object? data;
}

class WalletTransactionExpenseIncome {
  DateTime date = DateTime.now();
  double expense = 0;
  double income = 0;
}