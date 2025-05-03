import 'dart:collection';
import 'package:easy_sticky_header/easy_sticky_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

enum HeaderType {
  date,
  name,
  amount,
  category,
}

class ListViewWithHeader<T> extends StatelessWidget {
  final ScrollController? controller;
  final List<TransactionListModel> data;
  final Function(TransactionListModel)? onEdit;
  final Function(TransactionListModel)? onDelete;
  final bool showHeader;
  final HeaderType headerType;
  final bool reverse;

  const ListViewWithHeader({
    super.key,
    this.controller,
    required this.data,
    this.onEdit,
    this.onDelete,
    this.showHeader = true,
    this.headerType = HeaderType.date,
    this.reverse = false,
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

  Map<T, List<TransactionListModel>> _groupData() {
    final SplayTreeMap<T, List<TransactionListModel>> mapData = SplayTreeMap<T, List<TransactionListModel>>();
    T mapKey;
    
    // let's generate the mapData based on the category
    // the data is already sorted so what we need to do is just to add it
    // on the correct category
    
    // loop on the data
    for(int i=0; i<data.length; i++) {
      // generate the map key based on the header type
      switch(headerType) {
        case HeaderType.date:
          mapKey = data[i].date as T;
          break;
        case HeaderType.name:
          mapKey = data[i].name as T;
          break;
        case HeaderType.amount:
          mapKey = data[i].amount as T;
          break;
        case HeaderType.category:
          if (data[i].type.toLowerCase() == 'transfer') {
            mapKey = 'transfer_transfer' as T;
          }
          else {
            mapKey = "${data[i].type.toLowerCase()}_${data[i].category!.name}" as T;
          }
          break;
      }

      // check if the map key already exist on the map or ot?
      if (!mapData.containsKey(mapKey)) {
        mapData[mapKey] = [];
      }

      // add data to the map data
      mapData[mapKey]!.add(data[i]);
    }

    return mapData;
  }

  List<Widget> _generateChildWidget(BuildContext context) {
    final List<Widget> widgetList = [];
    final Map<T, List<TransactionListModel>> mapData = _groupData();

    int index = 0;
    
    // check if map data is empty or not?
    if (mapData.isNotEmpty) {
      // create the current list of keys of the map
      List<T> keys = mapData.keys.toList();

      // check if this is need to be sorted as ascending or descending?
      if (reverse) {
        keys = keys.reversed.toList();
      }

      // loop thru the keys
      for(int x=0; x<keys.length; x++) {
        // check if we need to show the header or not?
        if (showHeader) {
          // create the header
          widgetList.add(_groupHeader(index: index, keys: keys[x]));

          // add index
          index = index + 1;
        }

        // loop thru the transaction for this map
        for(int i=0; i<mapData[keys[x]]!.length; i++) {
          // create the transaction data given.
          widgetList.add(
            _createItem(
              txn: mapData[keys[x]]![i],
              canEdit: (onEdit != null),
              canDelete: (onDelete != null),
              context: context,
            )
          );
        }
      }
    }

    // return the widget list
    return widgetList;
  }

  Widget _groupHeader({
    required T keys,
    required int index,
  }) {
    // as key will be dynamic based on the type passed from the parent page
    // we will need to format each key based on the header type
    String headerText = '';
    Color headerColor = textColor2;

    switch(headerType) {
      case HeaderType.date:
        headerText = Globals.dfddMMMMyyyy.format(keys as DateTime);
        break;
      case HeaderType.name:
        headerText = (keys as String).toTitleCase();
        break;
      case HeaderType.amount:
        headerText = (keys as double).formatCurrency(shorten: false, decimalNum: 2);
        break;
      case HeaderType.category:
        // category will have 2 section, 1st section will be the category type
        // 2nd one will be the actual key
        List<String> key = (keys as String).split('_');
        if (key.length == 2) {
          switch(key[0]) {
            case 'expense':
              headerColor = lightAccentColors[2];
              break;
            case 'income':
              headerColor = lightAccentColors[0];
              break;
            default:
              headerColor = lightAccentColors[4];
              break;
          }

          headerText = key[1].toTitleCase();
        }
        else {
          // default to the first one for the header text
          headerText = key[0].toTitleCase();
        }
        break;
    }

    return StickyContainerWidget(
      index: index,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                headerText,
                style: TextStyle(
                  color: headerColor,
                ),
              ),
            ),
          ],
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
    return Slidable(
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
      child: _createItemType(
        canEdit: canEdit,
        txn: txn,
      ),
    );
  }

  Widget _createItemType({
    required bool canEdit,
    required TransactionListModel txn,
  }) {
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
          onTap: () {
            if (canEdit) {
              if (onEdit != null) {
                onEdit!(txn);
              }
            }
          },
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
          onTap: () {
            if (canEdit) {
              if (onEdit != null) {
                onEdit!(txn);
              }
            }
          },
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
          onTap: () {
            if (canEdit) {
              if (onEdit != null) {
                onEdit!(txn);
              }
            }
          },
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
          onTap: () {
            if (canEdit) {
              if (onEdit != null) {
                onEdit!(txn);
              }
            }
          },
        );
    }
  }
}