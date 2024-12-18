import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class BudgetTransactionItem extends StatelessWidget {
  final String itemName;
  final DateTime itemDate;
  final String itemSymbol;
  final double itemAmount;
  final String categoryName;
  final String description;
  const BudgetTransactionItem({
    super.key,
    required this.itemName,
    required this.itemDate,
    required this.itemSymbol,
    required this.itemAmount,
    required this.categoryName,
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
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
                  Globals.dfeddMMMyyyy.formatLocal(itemDate),
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
                Visibility(
                  visible: (description.isNotEmpty),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                ),
              ],
            ),
          ),
          const SizedBox(width: 10,),
          Text(
            "$itemSymbol ${Globals.fCCY.format(itemAmount)}",
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