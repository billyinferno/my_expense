import 'dart:collection';
import 'package:easy_sticky_header/easy_sticky_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

enum HeaderType {
  date,
  name,
  amount
}

enum GroupBy {
  none,
  category
}

class ListViewWithHeader extends StatelessWidget {
  final ScrollController? controller;
  final List<TransactionListModel> data;
  final Function(TransactionListModel)? onEdit;
  final Function(TransactionListModel)? onDelete;
  final bool showHeader;
  final HeaderType headerType;
  //TODO: to add group by function when we generate the list view
  final GroupBy groupBy;
  const ListViewWithHeader({
    super.key,
    this.controller,
    required this.data,
    this.onEdit,
    this.onDelete,
    this.showHeader = true,
    this.headerType = HeaderType.date,
    this.groupBy = GroupBy.none,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No data"));
    }
    else {
      final List<Widget> wigdetList = _generateChildWidget(context);

      return StickyHeader(
        child: ListView.builder(
          controller: controller,
          itemCount: wigdetList.length,
          itemBuilder: (context, index) {
            return wigdetList[index];
          },
        ),
      );
    }
  }

  Map<String, List<TransactionListModel>> _groupData() {
    final SplayTreeMap<String, List<TransactionListModel>> mapData = SplayTreeMap<String, List<TransactionListModel>>();
    String mapKey;
    
    if (groupBy == GroupBy.none) {
      mapData[""] = data;
    }
    else {
      // let's generate the mapData based on the category
      // the data is already sorted so what we need to do is just to add it
      // on the correct category
      
      // loop on the data
      for(int i=0; i<data.length; i++) {
        if (data[i].type.toLowerCase() == 'transfer') {
          // we will loop transfer into single category
          if (!mapData.containsKey('transfer')) {
            // no map data transfer, create a new one
            mapData['transfer_transfer'] = [];
          }

          // add data to the map data
          mapData['transfer_transfer']!.add(data[i]);
        }
        else {
          // this is income and expense, for this we can store it based on the
          // correct category for the transaction it self

          // generate map key
          mapKey = "${data[i].type.toLowerCase()}_${data[i].category!.name.toLowerCase()}";

          // check if map key already exists or not?
          if (!mapData.containsKey(mapKey)) {
            // map key not exists, create a new list for this
            mapData[mapKey] = [];
          }

          // add data to the map data
          mapData[mapKey]!.add(data[i]);
        }
      }
    }

    return mapData;
  }

  List<Widget> _generateChildWidget(BuildContext context) {
    final List<Widget> widgetList = [];
    final Map<String, List<TransactionListModel>> mapData = _groupData();

    DateTime prevDate = DateTime.now();
    String prevName = '';
    double prevAmount = 0;
    int index = 0;
    int? parentIndex;
    
    // check if map data is empty or not?
    if (mapData.isNotEmpty) {
      // loop thru the map data
      mapData.forEach((key, transactions) {
        // check if key is not empty
        if (key.isNotEmpty) {
          // create header for the group
          widgetList.add(_groupHeader(index: index, keys: key));

          // set parent index as this index
          parentIndex = index;

          // add index since we already use this index
          index = index + 1;
        }

        // loop thru the transactions
        for(int i=0; i<transactions.length; i++) {
          // check whether we want to show header or not?
          if (showHeader) {
            // first data, add the header nonetheless
            if (i == 0) {
              switch (headerType) {
                case HeaderType.name:
                  prevName = transactions[i].name;
                  widgetList.add(
                    _header(
                      text: transactions[i].name,
                      index: index,
                      parentIndex: parentIndex,
                    )
                  );
                  break;
                case HeaderType.amount:
                  prevAmount = transactions[i].amount;
                  widgetList.add(
                    _header(
                      text: transactions[i].amount.formatCurrency(
                        shorten: false,
                        decimalNum: 2
                      ),
                      index: index,
                      parentIndex: parentIndex,
                    )
                  );
                  break;
                default:
                  prevDate = transactions[i].date;
                  widgetList.add(
                    _header(
                      text: Globals.dfddMMMMyyyy.formatLocal(prevDate),
                      index: index,
                      parentIndex: parentIndex,
                    )
                  );
                  break;
              }
            }
            else {
              // check what kind of header type?
              switch (headerType) {
                case HeaderType.name:
                  // check whether prev name is same as current name or not?
                  if (prevName != transactions[i].name) {
                    // prevName is not same with current name, generate a header
                    // and set prevName as current name.
                    prevName = transactions[i].name;
                    widgetList.add(
                      _header(
                        text: transactions[i].name,
                        index: index,
                        parentIndex: parentIndex,
                      )
                    );
                  }
                  break;
                case HeaderType.amount:
                  // check whether prev amount is same as current amount or not?
                  if (prevAmount != transactions[i].amount) {
                    // prevAmount is not same with current amount, generate a
                    // header and set prevAmount as current amount.
                    prevAmount = transactions[i].amount;
                    widgetList.add(
                      _header(
                        text: transactions[i].amount.formatCurrency(shorten: false, decimalNum: 2),
                        index: index,
                        parentIndex: parentIndex,
                      )
                    );
                  }
                  break;
                default:
                  // check whether prev date is same as current date or not?
                  if (!prevDate.isSameDate(date: transactions[i].date)) {
                    // prevDate is not same with current date, generate a header
                    // and set prevDate as current date.
                    prevDate = transactions[i].date;
                    widgetList.add(
                      _header(
                        text: Globals.dfddMMMMyyyy.formatLocal(prevDate),
                        index: index,
                        parentIndex: parentIndex,
                      )
                    );
                  }
                  break;
              }
            }

            // add index for header
            index = index + 1;
          }

          // other than that, we can just create the item based on the
          // transaction data given.
          widgetList.add(
            _createItem(
              txn: data[i],
              canEdit: (onEdit != null),
              canDelete: (onDelete != null),
              context: context,
            )
          );

          // add index
          index = index + 1;
        }
      },);
    }

    // return the widget list
    return widgetList;
  }

  Widget _groupHeader({required String keys, required int index}) {
    // split the "_" in the key
    List<String> key = keys.split('_');
    Color headerTextColor;

    // check the first key whether this is income, expense, or transfer
    // this will determine the color of the group text
    switch(key[0]) {
      case 'expense':
        headerTextColor = lightAccentColors[2];
        break;
      case 'income':
        headerTextColor = lightAccentColors[0];
        break;
      case 'transfer':
        headerTextColor = lightAccentColors[4];
        break;
      default:
        headerTextColor = textColor;
        break;
    }

    return StickyContainerWidget(
      index: index,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        decoration: BoxDecoration(
          color: primaryDark,
          border: Border(
            bottom: BorderSide(
              color: primaryLight,
              width: 1.0,
              style: BorderStyle.solid,
            )
          )
        ),
        child: Text(
          key[1].toTitleCase(),
          style: TextStyle(
            color: headerTextColor,
          ),
        ),
      ),
    );
  }

  Widget _header({
    required String text,
    required int index,
    int? parentIndex,
  }) {
    return StickyContainerWidget(
      index: index,
      parentIndex: parentIndex,
      child: Container(
        width: double.infinity,
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
      ),
    );
  }

  Widget _createItem({
    required TransactionListModel txn,
    bool canEdit = false,
    bool canDelete = false,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: (() {
        if (canEdit) {
          // ensure edit function is not null
          if (onEdit != null) {
            // call the edit function
            onEdit!(txn);
          }
        }
      }),
      child: Slidable(
        key: Key("${txn.id}_${txn.wallet.id}_${txn.type}"),
        endActionPane: (canDelete ? ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.2,
          dismissible: DismissiblePane(
            onDismissed: () async {
              // check if the onDelete function is not null or not?
              if (onDelete != null) {
                // call the onDelete function
                onDelete!(txn);
              }
            },
            confirmDismiss: () async {
              return await ShowMyDialog(
                dialogTitle: "Delete Item",
                dialogText: "Do you want to delete ${txn.name}?",
                confirmText: "Delete",
                confirmColor: accentColors[2],
                cancelText: "Cancel")
              .show(context) ?? false;
            },
          ),
          children: <Widget>[
            SlideButton(
              icon: Ionicons.trash,
              iconColor: textColor,
              bgColor: accentColors[2],
              text: 'Delete',
              onTap: () {
                // check if we can delete the transaction or not?
                late Future<bool?> result = ShowMyDialog(
                  dialogTitle: "Delete Item",
                  dialogText: "Do you want to delete ${txn.name}?",
                  confirmText: "Delete",
                  confirmColor: accentColors[2],
                  cancelText: "Cancel")
                .show(context);

                // check the result of the dialog box
                result.then((value) {
                  if (value == true) {
                    // check if the onDelete function is not null
                    if (onDelete != null) {
                      onDelete!(txn);
                    }
                  }
                });
              },
            ),
          ],
        ) : null),
        child: _createItemType(txn)
      ),
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