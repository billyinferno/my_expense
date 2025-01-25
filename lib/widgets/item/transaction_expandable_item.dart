import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class TransactionExpandableItem extends StatelessWidget {
  final TransactionListModel txn;
  final DateTime startDate;
  final DateTime endDate;
  final int count;
  final Map<String, TransactionListModel> subTxn;
  final bool showCategory;
  const TransactionExpandableItem({
    super.key,
    required this.txn,
    required this.startDate,
    required this.endDate,
    required this.count,
    required this.subTxn,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Globals.themeData.copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ListTileTheme(
        contentPadding: const EdgeInsets.all(0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: primaryLight,
                width: 1.0,
              )
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(0),
            childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
            backgroundColor: primaryBackground,
            collapsedBackgroundColor: primaryBackground,
            iconColor: primaryLight,
            collapsedIconColor: primaryLight,
            title: _createSummaryItem(
              txn: txn,
              startDate: startDate,
              endDate: endDate,
              count: count,
              showCategory: showCategory,
            ),
            children: _createExpandableChilds(
              subTxn: subTxn,
              showCategory: showCategory,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _createExpandableChilds({
    required Map<String, TransactionListModel> subTxn,
    bool showCategory = true,
  }) {
    List<Widget> ret = [];

    // loop thru subTxn
    subTxn.forEach((key, txn) {
      // generate an item for each key
      ret.add(
        // create container
        Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(width: 50),
              Expanded(
                child: Text(
                  key,
                ),
              ),
              const SizedBox(width: 10,),
              _getAmount(txn),
              const SizedBox(width: 35,)
            ],
          ),
        )
      );
    },);

    return ret;
  }

  Widget _createSummaryItem({
    required TransactionListModel txn,
    required DateTime startDate,
    required DateTime endDate,
    required int count,
    bool showCategory = true,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _categoryIcon(
            name: (txn.category != null ? txn.category!.name : ''),
            type: txn.type
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  txn.name,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${Globals.dfddMMyy.formatLocal(startDate)} - ${Globals.dfddMMyy.formatLocal(endDate)}",
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
                Visibility(
                  visible: showCategory,
                  child: (txn.category == null
                      ? const SizedBox.shrink()
                      : Text(
                          (txn.category != null ? txn.category!.name : ''),
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        )),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "${count.toString()} time${(count > 1 ? 's' : '')}",
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          _getAmount(txn),
        ],
      ),
    );
  }

  Widget _categoryIcon(
      {required String type,
      required String? name,
      double? height,
      double? width,
      double? size}) {
    if (type == "expense") {
      return Container(
        height: (height ?? 40),
        width: (width ?? 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((height ?? 40)),
          color: IconColorList.getExpenseColor(name!),
        ),
        child: IconColorList.getExpenseIcon(name, size),
      );
    } else if (type == "income") {
      return Container(
        height: (height ?? 40),
        width: (width ?? 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((height ?? 40)),
          color: IconColorList.getIncomeColor(name!),
        ),
        child: IconColorList.getIncomeIcon(name, size),
      );
    } else {
      return Container(
        height: (height ?? 40),
        width: (width ?? 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((height ?? 40)),
          color: accentColors[4],
        ),
        child: Icon(
          Ionicons.repeat,
          color: textColor,
          size: (size ?? 20),
        ),
      );
    }
  }

  Widget _getAmount(TransactionListModel transaction) {
    if (transaction.type == "expense" || transaction.type == "income") {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "${transaction.wallet.currency} ${Globals.fCCY.format(transaction.amount)}",
            style: TextStyle(
              color: (transaction.type == "expense"
                  ? accentColors[2]
                  : accentColors[0]),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "${transaction.wallet.currency} ${Globals.fCCY.format(transaction.amount)}",
            style: TextStyle(
              color: accentColors[5],
            ),
            textAlign: TextAlign.right,
          ),
          Visibility(
            visible: (transaction.walletTo != null),
            child: Text(
              "${transaction.walletTo != null ? transaction.walletTo!.currency : ''} ${Globals.fCCY.format(transaction.amount * transaction.exchangeRate)}",
              style: TextStyle(
                color: accentColors[5].lighten(amount: 0.25),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }
  }
}