import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';

class BudgetTransactionItem extends StatelessWidget {
  final String itemName;
  final DateTime itemDate;
  final String itemSymbol;
  final double itemAmount;
  final String categoryName;
  const BudgetTransactionItem({super.key, required this.itemName, required this.itemDate, required this.itemSymbol, required this.itemAmount, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final fCCY = NumberFormat("#,##0.00", "en_US");
    
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: IconColorList.getExpenseColor(categoryName),
            ),
            child: IconColorList.getExpenseIcon(categoryName),
          ),
          const SizedBox(width: 10,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  itemName
                ),
                Text(
                  DateFormat('E, dd MMM yyyy').format(itemDate.toLocal()),
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10,),
          Text(
            "$itemSymbol ${fCCY.format(itemAmount)}",
            style: const TextStyle(
              color: textColor2,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}