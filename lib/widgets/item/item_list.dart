import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';

enum ItemType {
  expense,
  income,
  transfer
}

class ItemList extends StatelessWidget {
  final ItemType type;
  final String? name;
  final String? categoryName;
  final String walletName;
  final String walletSymbol;
  final String? walletToName;
  final String? walletToSymbol;
  final double amount;
  final double? exchangeRate;

  const ItemList({ super.key, required this.type, this.name, this.categoryName, required this.walletName, required this.walletSymbol, this.walletToName, this.walletToSymbol, required this.amount, this.exchangeRate });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1.0,
            color: primaryLight
          )
        )
      ),
      child: _getItem(),
    );
  }

  Widget _getItem() {
    NumberFormat fCCY = NumberFormat("#,##0.00", "en_US");
    double itemPriceConv = amount * (exchangeRate ?? 1);

    String formatAmount = fCCY.format(amount);
    String formatPriceConv = fCCY.format(itemPriceConv);

    switch (type) {
      case ItemType.expense:
        return _item(
          itemName: (name ?? ''),
          itemSub: "($walletName) ${(categoryName ?? '')}",
          itemIcon: IconColorList.getExpenseIcon((categoryName ?? '')),
          itemIconColor: IconColorList.getExpenseColor((categoryName ?? '')),
          itemCCYFrom: walletSymbol,
          itemPriceFrom: formatAmount,
          itemPriceFromColor: accentColors[2],
        );
      case ItemType.income:
        return _item(
          itemName: (name ?? ''),
          itemSub: "($walletName) ${(categoryName ?? '')}",
          itemIcon: IconColorList.getIncomeIcon((categoryName ?? '')),
          itemIconColor: IconColorList.getIncomeColor((categoryName ?? '')),
          itemCCYFrom: walletSymbol,
          itemPriceFrom: formatAmount,
          itemPriceFromColor: accentColors[0],
        );
      case ItemType.transfer:
        return _item(
          itemName: (name ?? '-'),
          itemSub: "$walletName > ${(walletToName ?? '')}",
          itemIcon: const Icon(
            Ionicons.repeat,
            color: textColor,
          ),
          itemIconColor: accentColors[4],
          itemCCYFrom: walletSymbol,
          itemPriceFrom: formatAmount,
          itemPriceFromColor: accentColors[5],
          itemCCYTo: walletToSymbol,
          itemPriceTo: formatPriceConv,
          itemPriceToColor: accentColors[5],
        );
      default:
        return _item(
          itemName: (name ?? ''),
          itemSub: "($walletName) ${(categoryName ?? '')}",
          itemIcon: IconColorList.getExpenseIcon((categoryName ?? '')),
          itemIconColor: IconColorList.getExpenseColor((categoryName ?? '')),
          itemCCYFrom: walletSymbol,
          itemPriceFrom: formatAmount,
          itemPriceFromColor: accentColors[2],
        );
    }
  }

  Widget _item({
    required String itemName,
    required String itemSub,
    required Icon itemIcon,
    required Color itemIconColor,
    required String itemCCYFrom,
    required String itemPriceFrom,
    required Color itemPriceFromColor,
    String? itemCCYTo,
    String? itemPriceTo,
    Color? itemPriceToColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: itemIconColor,
            ),
            margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: itemIcon,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  itemName,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  itemSub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textColor2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$itemCCYFrom $itemPriceFrom",
                style: TextStyle(
                  color: itemPriceFromColor,
                ),
              ),
              Visibility(
                visible: (itemCCYTo != null && itemPriceTo != null),
                child: Text(
                  "${itemCCYTo ?? ''} ${itemPriceTo ?? ''}",
                  style: TextStyle(
                    color: lighten((itemPriceToColor ?? itemPriceFromColor), 0.25),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}