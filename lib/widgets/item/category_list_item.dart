import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class CategoryListItem extends StatelessWidget {
  final int index;
  final BudgetModel budget;
  final bool showFlagged;
  final Color flagColor;
  final bool isSelected;
  final Function(int)? onTap;
  final Function(int)? onDoubleTap;
  final Function? onDelete;
  final Function(int)? onEdit;
  final Function(int)? onSelect;
  const CategoryListItem({super.key,
    required this.index,
    required this.budget,
    this.showFlagged = false,
    this.flagColor = Colors.transparent,
    this.isSelected = false,
    this.onTap,
    this.onDoubleTap,
    this.onDelete,
    this.onEdit,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(width: 1.0, color: primaryLight)),
          color: Colors.transparent,
        ),
        child: Slidable(
          key: Key("${budget.category.id}_${budget.category.name}"),
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
                iconColor: (budget.id != -1 ? textColor : secondaryLight),
                bgColor: (budget.id != -1 ? accentColors[6] : secondaryDark),
                text: 'Edit',
                textColor: (budget.id != -1 ? textColor : secondaryLight),
                onTap: () {
                  if (onEdit != null) {
                    if (budget.id != -1) {
                      onEdit!(index);
                    }
                  }
                },
              ),
              SlideButton(
                icon: Ionicons.trash,
                iconColor: (budget.id != -1 ? textColor : secondaryLight),
                bgColor: (budget.id != -1 ? accentColors[2] : secondaryDark),
                text: 'Delete',
                textColor: (budget.id != -1 ? textColor : secondaryLight),
                onTap: () async {
                  if (onDelete != null) {
                    if (budget.id != -1) {
                      // show dialog first
                      await _showConfirmDialog(context).then((value) {
                        if (value ?? false) {
                          onDelete!();
                        }
                      });
                    }
                  }
                },
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(width: 10,),
              GestureDetector(
                onTap: () {
                  if (onSelect != null) {
                    onSelect!(index);
                  }
                },
                child: SizedBox(
                  width: 20,
                  height: 60,
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: (isSelected ? accentColors[6] : secondaryDark),
                      ),
                      child: Center(
                        child: (isSelected ? Icon(
                          Ionicons.checkmark,
                          color: Colors.white,
                          size: 12,
                        ) : const SizedBox.shrink()),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: (showFlagged ? flagColor : Colors.transparent),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          color: IconColorList.getExpenseColor(budget.category.name),
                        ),
                        child: IconColorList.getExpenseIcon(budget.category.name),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(child: Text(budget.category.name)),
                      const SizedBox(width: 10,),
                      Text(
                        (budget.id != -1 ? "${budget.currency.symbol} ${Globals.fCCY.format(budget.amount)}" : '-'),
                        style: TextStyle(
                          color: (budget.id != -1 ? textColor2 : secondaryLight),
                        ),
                      ),
                      const SizedBox(width: 5,),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    late Future<bool?> result = ShowMyDialog(
      dialogTitle: "Delete Budget",
      dialogText: "Do you want to delete ${budget.category.name}?",
      confirmText: "Delete",
      confirmColor: accentColors[2],
      cancelText: "Cancel")
    .show(context);

    return (result);
  }
}