import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class ListViewWithHeader extends StatelessWidget {
  final ScrollController? controller;
  final List<TransactionListModel> data;
  final bool canEdit;
  final Function(TransactionListModel)? editFunction;
  final bool showHeader;
  final String headerType;
  const ListViewWithHeader({
    super.key,
    this.controller,
    required this.data,
    this.canEdit = false,
    this.editFunction,
    this.showHeader = true,
    this.headerType = 'D',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No data"));
    }
    else {
      final List<Widget> wigdetList = _generateChildWidget();

      return ListView.builder(
        controller: controller,
        itemCount: wigdetList.length,
        itemBuilder: (context, index) {
          return wigdetList[index];
        },
      );
    }
  }

  List<Widget> _generateChildWidget() {
    final List<Widget> widgetList = [];
    
    // data is not empty, loop thru data
    DateTime prevDate = DateTime.now();
    String prevName = '';
    double prevAmount = 0;

    for(int i=0; i<data.length; i++) {
      // check whether we want to show header or not?
      if (showHeader) {
        // first data, add the header nonetheless
        if (i == 0) {
          switch (headerType) {
            case 'N':
              prevName = data[i].name;
              widgetList.add(
                _header(
                  text: data[i].name,
                )
              );
              break;
            case 'A':
              prevAmount = data[i].amount;
              widgetList.add(
                _header(
                  text: data[i].amount.formatCurrency(shorten: false, decimalNum: 2),
                )
              );
              break;
            default:
              prevDate = data[i].date;
              widgetList.add(
                _header(
                  text: Globals.dfddMMMMyyyy.formatLocal(prevDate),
                )
              );
              break;
          }
        }
        else {
          // check what kind of header type?
          switch (headerType) {
            case 'N':
              // check whether prev name is same as current name or not?
              if (prevName != data[i].name) {
                // prevName is not same with current name, generate a header and set
                // prevName as current name.
                prevName = data[i].name;
                widgetList.add(
                  _header(
                    text: data[i].name,
                  )
                );
              }
              break;
            case 'A':
              // check whether prev amount is same as current amount or not?
              if (prevAmount != data[i].amount) {
                // prevAmount is not same with current amount, generate a header and set
                // prevAmount as current amount.
                prevAmount = data[i].amount;
                widgetList.add(
                  _header(
                    text: data[i].amount.formatCurrency(shorten: false, decimalNum: 2),
                  )
                );
              }
              break;
            default:
              // check whether prev date is same as current date or not?
              if (!prevDate.isSameDate(date: data[i].date)) {
                // prevDate is not same with current date, generate a header and set
                // prevDate as current date.
                prevDate = data[i].date;
                widgetList.add(
                  _header(
                    text: Globals.dfddMMMMyyyy.format(prevDate),
                  )
                );
              }
              break;
          }
        }
      }

      // other than that, we can just create the item based on the transaction
      // data given.
      widgetList.add(
        _createItem(
          txn: data[i],
          canEdit: canEdit,
        )
      );
    }

    // return the widget list
    return widgetList;
  }

  Widget _header({
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: BoxDecoration(
        color: secondaryDark,
        border: Border(
          bottom: BorderSide(
            color: secondaryLight,
            width: 1.0,
            style: BorderStyle.solid,
          )
        )
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor2,
        ),
      ),
    );
  }

  Widget _createItem({
    required TransactionListModel txn,
    bool canEdit = false
  }) {
    return InkWell(
      onTap: (() {
        if (canEdit) {
          // ensure edit function is not null
          if (editFunction != null) {
            // call the edit function
            editFunction!(txn);
          }
        }
      }),
      child: _createItemType(txn)
    );
  }

  Widget _createItemType(TransactionListModel txn) {
    switch (txn.type.toLowerCase()) {
      case "expense":
        return MyItemList(
          iconColor: IconColorList.getExpenseColor(txn.category!.name),
          icon: IconColorList.getExpenseIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: Globals.dfeddMMMyyyy.formatLocal(txn.date),
          subTitleStyle: const TextStyle(fontSize: 10),
          description: txn.description,
          descriptionStyle: const TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic
          ),
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[2],
        );
      case "income":
        return MyItemList(
          iconColor: IconColorList.getIncomeColor(txn.category!.name),
          icon: IconColorList.getIncomeIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: Globals.dfeddMMMyyyy.formatLocal(txn.date),
          subTitleStyle: const TextStyle(fontSize: 10),
          description: txn.description,
          descriptionStyle: const TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic
          ),
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[6],
        );
      case "transfer":
        return MyItemList(
          iconColor: accentColors[4],
          icon: const Icon(
            Ionicons.repeat,
            color: textColor,
          ),
          type: txn.type.toLowerCase(),
          title: '-',
          subTitle: Globals.dfeddMMMyyyy.formatLocal(txn.date),
          subTitleStyle: const TextStyle(fontSize: 10),
          description: txn.description,
          descriptionStyle: const TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic
          ),
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[4],
          symbolTo: txn.walletTo!.symbol,
          amountTo: (txn.amount * txn.exchangeRate),
        );
      default:
        return MyItemList(
          iconColor: IconColorList.getExpenseColor(txn.category!.name),
          icon: IconColorList.getExpenseIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: Globals.dfeddMMMyyyy.formatLocal(txn.date),
          subTitleStyle: const TextStyle(fontSize: 10),
          description: txn.description,
          descriptionStyle: const TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic
          ),
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[2],
        );
    }
  }
}