class IncomeExpenseModel {
    final Map<DateTime, double> expense;
    final Map<DateTime, double> income;

    IncomeExpenseModel({
        required this.expense,
        required this.income,
    });

    factory IncomeExpenseModel.fromJson(Map<String, dynamic> json) {
      DateTime currDate;
      Map<DateTime, double> expense = {};
      json["expense"].forEach((value) {
        IncomeExpense exp = IncomeExpense.fromJson(value);
        currDate = exp.date.toLocal();
        currDate = DateTime(currDate.year, currDate.month, currDate.day).toLocal();
        expense[DateTime(currDate.year, currDate.month, currDate.day).toLocal()] = exp.amount;
      });

      Map<DateTime, double> income = {};
      json["income"].forEach((value) {
        IncomeExpense inc = IncomeExpense.fromJson(value);
        currDate = inc.date.toLocal();
        currDate = DateTime(currDate.year, currDate.month, currDate.day).toLocal();
        income[DateTime(currDate.year, currDate.month, currDate.day).toLocal()] = inc.amount;
      });

      return IncomeExpenseModel(expense: expense, income: income);
    }

    Map<String, dynamic> toJson() {
      List<IncomeExpense> expense = [];
      List<IncomeExpense> income = [];

      this.expense.forEach((key, value) {
        IncomeExpense exp = IncomeExpense(date: key.toLocal(), amount: value);
        expense.add(exp);
      });

      this.income.forEach((key, value) {
        IncomeExpense inc = IncomeExpense(date: key.toLocal(), amount: value);
        income.add(inc);
      });

      return {
        "expense": List<dynamic>.from(expense.map((x) => x.toJson())),
        "income": List<dynamic>.from(income.map((x) => x.toJson()))
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
        date: DateTime.parse(json["date"]).toLocal(),
        amount: json["amount"].toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "date": date.toIso8601String(),
        "amount": amount,
    };
}