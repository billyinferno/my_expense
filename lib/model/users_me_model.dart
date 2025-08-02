class UsersMeModel {
  final int id;
  final String username;
  final String email;
  final bool confirmed;
  final bool blocked;
  final int? defaultCategoryExpense;
  final int? defaultCategoryIncome;
  final int? defaultBudgetCurrency;
  final int? defaultWallet;
  final bool autoSyncTransaction;

  UsersMeModel(
    this.id,
    this.username,
    this.email,
    this.confirmed,
    this.blocked,
    this.defaultCategoryExpense,
    this.defaultCategoryIncome,
    this.defaultBudgetCurrency,
    this.defaultWallet,
    this.autoSyncTransaction,
  );

  factory UsersMeModel.fromJson(Map<String, dynamic> json) {
    return UsersMeModel(
      json['id'],
      json['username'],
      json['email'],
      json['confirmed'],
      json['blocked'],
      json['defaultCategoryExpense'],
      json['defaultCategoryIncome'],
      json['defaultBudgetCurrency'],
      json['defaultWallet'],
      (json['autoSyncTransaction'] ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'confirmed': confirmed,
    'blocked': blocked,
    'defaultCategoryExpense': (defaultCategoryExpense),
    'defaultCategoryIncome': (defaultCategoryIncome),
    'defaultBudgetCurrency': (defaultBudgetCurrency),
    'defaultWallet': (defaultWallet),
    'autoSyncTransaction': autoSyncTransaction,
  };
}