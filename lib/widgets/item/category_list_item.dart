import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/colors.dart';

class CategoryListItem extends StatelessWidget {
  final int index;
  final int budgetId;
  final int categoryId;
  final Icon categoryIcon;
  final Color categoryColor;
  final String categoryName;
  final int currencyId;
  final String currencySymbol;
  final double budgetAmount;
  final Function(int)? onTap;
  final Function(int)? onDoubleTap;
  final Function? onDelete;
  const CategoryListItem({Key? key,
    required this.index,
    required this.budgetId,
    required this.categoryId,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryName,
    required this.currencyId,
    required this.currencySymbol,
    required this.budgetAmount,
    this.onTap,
    this.onDoubleTap,
    this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fCCY = new NumberFormat("#,##0.00", "en_US");
    
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 1.0, color: primaryLight)),
        color: Colors.transparent,
      ),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.20,
          children: <SlidableAction>[
            SlidableAction(
              label: 'Delete',
              padding: const EdgeInsets.all(0),
              foregroundColor: textColor,
              backgroundColor: accentColors[2],
              icon: Ionicons.trash,
              onPressed: (_) {
                if (this.onDelete != null) {
                  this.onDelete!();
                }
              }
            ),
          ],
        ),
        child: GestureDetector(
          onTap: (() {
            if (this.onTap != null) {
              this.onTap!(this.index);
            }
          }),
          onDoubleTap: (() {
            if (this.onDoubleTap != null) {
              this.onDoubleTap!(this.index);
            }
          }),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 40,
                width: 40,
                margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: categoryColor,
                ),
                child: categoryIcon,
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(child: Text(categoryName)),
              SizedBox(width: 10,),
              Text(currencySymbol + " " + fCCY.format(budgetAmount)),
              const SizedBox(width: 5,),
            ],
          ),
        ),
      ),
    );
  }
}