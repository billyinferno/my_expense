class IncomeExpenseCategoryModel {
    IncomeExpenseCategoryModel({
      required this.expense,
      required this.income,
    });

    final List<CategoryStatsModel> expense;
    final List<CategoryStatsModel> income;

    factory IncomeExpenseCategoryModel.fromJson(Map<String, dynamic> json) => IncomeExpenseCategoryModel(
      expense: List<CategoryStatsModel>.from(json["expense"].map((x) => CategoryStatsModel.fromJson(x))),
      income: List<CategoryStatsModel>.from(json["income"].map((x) => CategoryStatsModel.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
      "expense": List<dynamic>.from(expense.map((x) => x.toJson())),
      "income": List<dynamic>.from(income.map((x) => x.toJson())),
    };
}

class CategoryStatsModel {
    CategoryStatsModel({
      required this.categoryId,
      required this.categoryName,
      required this.amount,
    });

    final int categoryId;
    final String categoryName;
    final double amount;

    factory CategoryStatsModel.fromJson(Map<String, dynamic> json) => CategoryStatsModel(
      categoryId: json["category_id"],
      categoryName: json["category_name"],
      amount: json["amount"].toDouble(),
    );

    Map<String, dynamic> toJson() => {
      "category_id": categoryId,
      "category_name": categoryName,
      "amount": amount,
    };
}