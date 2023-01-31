class IncomeExpenseModel {
    final Map<DateTime, double> expense;
    final Map<DateTime, double> income;

    IncomeExpenseModel({
        required this.expense,
        required this.income,
    });

    factory IncomeExpenseModel.fromJson(Map<String, dynamic> json) {
      Map<DateTime, double> _expense = {};
      json["expense"].forEach((value) {
        IncomeExpense _exp = IncomeExpense.fromJson(value);
        _expense[_exp.date.toLocal()] = _exp.amount;
      });

      Map<DateTime, double> _income = {};
      json["income"].forEach((value) {
        IncomeExpense _inc = IncomeExpense.fromJson(value);
        _income[_inc.date.toLocal()] = _inc.amount;
      });

      return IncomeExpenseModel(expense: _expense, income: _income);
    }

    Map<String, dynamic> toJson() {
      List<IncomeExpense> _expense = [];
      List<IncomeExpense> _income = [];

      this.expense.forEach((key, value) {
        IncomeExpense _exp = IncomeExpense(date: key.toLocal(), amount: value);
        _expense.add(_exp);
      });

      this.income.forEach((key, value) {
        IncomeExpense _inc = IncomeExpense(date: key.toLocal(), amount: value);
        _income.add(_inc);
      });

      return {
        "expense": List<dynamic>.from(_expense.map((x) => x.toJson())),
        "income": List<dynamic>.from(_income.map((x) => x.toJson()))
      };
    }
}

class IncomeExpense {
    IncomeExpense({
        required this.date,
        required this.amount,
    });

    final DateTime date;
    final double amount;

    factory IncomeExpense.fromJson(Map<String, dynamic> json) => IncomeExpense(
        date: DateTime.parse(json["date"]),
        amount: json["amount"].toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "date": date.toIso8601String(),
        "amount": amount,
    };
}