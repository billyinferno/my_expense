import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

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
  final Function(int)? onEdit;
  const CategoryListItem({super.key,
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
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 1.0, color: primaryLight)),
        color: Colors.transparent,
      ),
      child: Slidable(
        key: Key("${categoryId}_$categoryName"),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.4,
          dismissible: onDelete == null ? null : DismissiblePane(onDismissed: () async {
            if (onDelete != null) {
              onDelete!();
            }
          },
          confirmDismiss: () async {
            // show dialog first
            return await _showConfirmDialog(context) ?? false;
            
          },),
          children: <Widget>[
            SlideButton(
              icon: Ionicons.pencil,
              iconColor: textColor,
              bgColor: accentColors[6],
              text: 'Edit',
              onTap: () {
                if (onEdit != null) {
                  onEdit!(index);
                }
              },
            ),
            SlideButton(
              icon: Ionicons.trash,
              iconColor: textColor,
              bgColor: accentColors[2],
              text: 'Delete',
              onTap: () async {
                if (onDelete != null) {
                  // show dialog first
                  await _showConfirmDialog(context).then((value) {
                    if (value ?? false) {
                      onDelete!();
                    }
                  });
                }
              },
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: GestureDetector(
            onTap: (() {
              if (onTap != null) {
                onTap!(index);
              }
            }),
            onDoubleTap: (() {
              if (onDoubleTap != null) {
                onDoubleTap!(index);
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
                const SizedBox(
                  width: 10,
                ),
                Expanded(child: Text(categoryName)),
                const SizedBox(width: 10,),
                Text("$currencySymbol ${Globals.fCCY.format(budgetAmount)}"),
                const SizedBox(width: 5,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    late Future<bool?> result = ShowMyDialog(
      dialogTitle: "Delete Budget",
      dialogText: "Do you want to delete $categoryName?",
      confirmText: "Delete",
      confirmColor: accentColors[2],
      cancelText: "Cancel")
    .show(context);

    return (result);
  }
}