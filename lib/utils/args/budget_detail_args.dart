import 'package:flutter/material.dart';

class BudgetDetailArgs {
  final int budgetId;
  final int categoryId;
  final Icon categoryIcon;
  final Color categoryColor;
  final String categoryName;
  final int currencyId;
  final String currencySymbol;
  final double budgetAmount;
  final bool useForDaily;

  BudgetDetailArgs({
    required this.budgetId,
    required this.categoryId,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryName,
    required this.currencyId,
    required this.currencySymbol,
    required this.budgetAmount,
    required this.useForDaily,
  });
}