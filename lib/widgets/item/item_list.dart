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

  const ItemList({ Key? key, required this.type, this.name, this.categoryName, required this.walletName, required this.walletSymbol, this.walletToName, this.walletToSymbol, required this.amount, this.exchangeRate }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: BoxDecoration(
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
    NumberFormat fCCY = new NumberFormat("#,##0.00", "en_US");
    double itemPriceConv = amount * (exchangeRate ?? 1);

    String _formatAmount = fCCY.format(amount);
    String _formatPriceConv = fCCY.format(itemPriceConv);

    switch (type) {
      case ItemType.expense:
        return _itemExpense(
          (name ?? ''),
          walletName,
          categoryName!,
          walletSymbol,
          _formatAmount);
      case ItemType.income:
        return _itemIncome(
          (name ?? ''),
          walletName,
          categoryName!,
          walletSymbol,
          _formatAmount);
      case ItemType.transfer:
        return _itemTransfer(
          walletName,
          walletToName!,
          walletSymbol,
          walletToSymbol!,
          _formatAmount,
          _formatPriceConv);
      default:
        return _itemExpense(
          (name ?? ''),
          walletName,
          categoryName!,
          walletSymbol,
          _formatAmount);
    }
  }

  Widget _itemExpense(String itemName, String itemWallet, String itemCategory, String itemCCY, String itemPrice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          child: IconColorList.getExpenseIcon(itemCategory),
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: IconColorList.getExpenseColor(itemCategory),
          ),
          margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
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
                "(" + itemWallet + ") " + itemCategory,
                style: TextStyle(
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
              itemCCY + " " + itemPrice,
              style: TextStyle(
                color: accentColors[2],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemIncome(String itemName, String itemWallet, String itemCategory, String itemCCY, String itemPrice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          child: IconColorList.getIncomeIcon(itemCategory),
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: IconColorList.getIncomeColor(itemCategory),
          ),
          margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
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
                "(" + itemWallet + ") " + itemCategory,
                style: TextStyle(
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
              itemCCY + " " + itemPrice,
              style: TextStyle(
                color: accentColors[0],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemTransfer(String walletFrom, String walletTo, String itemCCYFrom, String itemCCYTo, String itemPrice, String itemPriceConv) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          child: Icon(
            Ionicons.repeat,
            color: textColor,
          ),
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: accentColors[4],
          ),
          margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("-"),
              Text(
                walletFrom + " > " + walletTo,
                style: TextStyle(
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
              itemCCYFrom + " " + itemPrice,
              style: TextStyle(
                color: accentColors[5],
              ),
              textAlign: TextAlign.right,
            ),
            Text(
              itemCCYTo + " " + itemPriceConv,
              style: TextStyle(
                color: lighten(accentColors[5], 0.25),
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }
}