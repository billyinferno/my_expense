import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

enum PageName { summary, all, income, expense, transfer }

class TransactionSearchPage extends StatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  State<TransactionSearchPage> createState() => _TransactionSearchPageState();
}

class _TransactionSearchPageState extends State<TransactionSearchPage> {
  final _fCCY = NumberFormat("#,##0.00", "en_US");
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final int _limit =
      99999; // make it to 99999 (just fetch everything, IO is not a concern)

  String _searchText = "";
  String _categoryId = "";
  String _type = "name";
  int _start = 0; // start from 0 page

  int _resultPage = 1;
  PageName _resultPageName = PageName.all;
  final Map<PageName, Color> _resultPageColor = {
    PageName.summary: accentColors[1],
    PageName.all: accentColors[3],
    PageName.income: accentColors[6],
    PageName.expense: accentColors[2],
    PageName.transfer: accentColors[4],
  };

  List<TransactionListModel> _transactions = [];
  final List<TransactionListModel> _filterTransactions = [];
  final List<TransactionListModel> _income = [];
  final List<TransactionListModel> _expense = [];
  final List<TransactionListModel> _transfer = [];
  final Map<String, List<TransactionListModel>> _summaryIncome = {};
  final Map<String, List<TransactionListModel>> _summaryExpense = {};
  final Map<String, List<TransactionListModel>> _summaryTransfer = {};
  Map<String, double> _totalAmountIncome = {};
  Map<String, double> _totalAmountExpense = {};
  final Map<String, double> _totalAmountTransfer = {};
  final List<Widget> _summaryList = [];

  final Map<int, CategoryModel> _categorySelected = {};
  Map<int, CategoryModel> _categoryExpenseList = {};
  Map<int, CategoryModel> _categoryIncomeList = {};
  final List<Widget> _categoryExpenseIcon = [];
  final List<Widget> _categoryIncomeIcon = [];

  List<WalletModel> _walletList = [];
  final Map<int, bool> _selectedWalletList = {};

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _scrollControllerSummary = ScrollController();
  final ScrollController _scrollControllerIncome = ScrollController();
  final ScrollController _scrollControllerExpense = ScrollController();
  final ScrollController _scrollControllerTransfer = ScrollController();
  final ScrollController _walletController = ScrollController();

  @override
  void initState() {
    // get the category expense and income list from shared preferences
    _categoryExpenseList = CategorySharedPreferences.getCategory('expense');
    _categoryIncomeList = CategorySharedPreferences.getCategory('income');

    // generate the icon list widget for both expense and income
    _generateIconCategory();

    // get the wallet list
    _walletList = WalletSharedPreferences.getWallets(false);

    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _scrollControllerSummary.dispose();
    _scrollControllerIncome.dispose();
    _scrollControllerExpense.dispose();
    _scrollControllerTransfer.dispose();
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Search")),
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context, false);
          },
          icon: const Icon(
            Ionicons.close,
          ),
        ),
        actions: <Widget>[
          Container(
            width: 45,
            color: Colors.transparent,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: secondaryDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _showSearchOrSelectionWidget(),
              ],
            ),
          ),
          _getResultPage(),
          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  Widget _getResultPage() {
    // check if we got transactions or not?
    if (_transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // if got transaction we will result the transaction
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: primaryLight,
                        width: 1.0,
                        style: BorderStyle.solid))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: Center(
                      child: CupertinoSlidingSegmentedControl(
                        onValueChanged: (int? value) {
                          setState(() {
                            _resultPage = value!;
                            switch (_resultPage) {
                              case 0:
                                _resultPageName = PageName.summary;
                                break;
                              case 1:
                                _resultPageName = PageName.all;
                                break;
                              case 2:
                                _resultPageName = PageName.income;
                                break;
                              case 3:
                                _resultPageName = PageName.expense;
                                break;
                              case 4:
                                _resultPageName = PageName.transfer;
                                break;
                            }
                          });
                        },
                        groupValue: _resultPage,
                        thumbColor: (_resultPageColor[_resultPageName] ??
                            accentColors[9]),
                        children: const {
                          0: Text(
                            "Summary",
                            style: TextStyle(
                              fontFamily: '--apple-system',
                              fontSize: 11,
                            ),
                          ),
                          1: Text(
                            "All",
                            style: TextStyle(
                              fontFamily: '--apple-system',
                              fontSize: 11,
                            ),
                          ),
                          2: Text(
                            "Income",
                            style: TextStyle(
                              fontFamily: '--apple-system',
                              fontSize: 11,
                            ),
                          ),
                          3: Text(
                            "Expense",
                            style: TextStyle(
                              fontFamily: '--apple-system',
                              fontSize: 11,
                            ),
                          ),
                          4: Text(
                            "Transfer",
                            style: TextStyle(
                              fontFamily: '--apple-system',
                              fontSize: 11,
                            ),
                          ),
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                InkWell(
                  onDoubleTap: (() {
                    // clear the wallet
                    setState(() {
                      // clear the selected wallet list
                      _selectedWalletList.clear();

                      // filter and group the transaction
                      _filterTheTransaction();
                      _groupTransactions();
                    });
                  }),
                  onTap: (() {
                    showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return MyBottomSheet(
                            context: context,
                            title: "Account",
                            screenRatio: 0.45,
                            actionButton: InkWell(
                              onTap: (() {
                                if (_selectedWalletList.isNotEmpty) {
                                  setState(() {
                                    // clear the selected wallet list
                                    _selectedWalletList.clear();

                                    // filter and group the transaction
                                    _filterTheTransaction();
                                    _groupTransactions();
                                  });

                                  // close the modal dialog
                                  Navigator.pop(context);
                                }
                              }),
                              child: const SizedBox(
                                child: Icon(
                                  Ionicons.close_circle,
                                  size: 20,
                                  color: textColor,
                                ),
                              ),
                            ),
                            child: ListView.builder(
                              controller: _walletController,
                              itemCount: _walletList.length,
                              itemBuilder: (BuildContext context, int index) {
                                return SimpleItem(
                                  color: IconList.getColor(_walletList[index]
                                      .walletType
                                      .type
                                      .toLowerCase()),
                                  title: _walletList[index].name,
                                  isSelected: (_selectedWalletList[
                                          _walletList[index].id] ??
                                      false),
                                  onTap: (() {
                                    setState(() {
                                      // check if this ID previously selected or not?
                                      if (_selectedWalletList
                                          .containsKey(_walletList[index].id)) {
                                        // delete this data
                                        _selectedWalletList
                                            .remove(_walletList[index].id);
                                      } else {
                                        // new data, set this as true
                                        _selectedWalletList[
                                            _walletList[index].id] = true;
                                      }

                                      // once finished call filter the transaction
                                      // to filter the transactions that listed
                                      _filterTheTransaction();

                                      // group the transactions
                                      _groupTransactions();
                                    });
                                    Navigator.pop(context);
                                  }),
                                  icon: IconList.getIcon(_walletList[index]
                                      .walletType
                                      .type
                                      .toLowerCase()),
                                );
                              },
                            ),
                          );
                        });
                  }),
                  child: SizedBox(
                    width: 35,
                    child: badges.Badge(
                      position: badges.BadgePosition.topEnd(end: 5),
                      badgeStyle:
                          badges.BadgeStyle(badgeColor: accentColors[2]),
                      badgeContent: Text(
                        _selectedWalletList.length.toString(),
                        style: const TextStyle(color: textColor, fontSize: 10),
                      ),
                      child: const Icon(
                        Ionicons.wallet,
                        size: 15,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _getResultChild(),
          ),
        ],
      ),
    );
  }

  Widget _getResultChild() {
    switch (_resultPageName) {
      case PageName.all:
        return ListView.builder(
          controller: _scrollController,
          itemCount: _filterTransactions.length,
          itemBuilder: (context, index) {
            return _createItem(_filterTransactions[index], true);
          },
        );
      case PageName.summary:
        return ListView.builder(
            controller: _scrollControllerSummary,
            itemCount: _summaryList.length,
            itemBuilder: ((context, index) {
              return _summaryList[index];
            }));
      case PageName.income:
        return ListView.builder(
          controller: _scrollControllerIncome,
          itemCount: _income.length,
          itemBuilder: (context, index) {
            return _createItem(_income[index], false);
          },
        );
      case PageName.expense:
        return ListView.builder(
          controller: _scrollControllerExpense,
          itemCount: _expense.length,
          itemBuilder: (context, index) {
            return _createItem(_expense[index], false);
          },
        );
      case PageName.transfer:
        return ListView.builder(
          controller: _scrollControllerTransfer,
          itemCount: _transfer.length,
          itemBuilder: (context, index) {
            return _createItem(_transfer[index], false);
          },
        );
      default:
        // unknown just return SizedBox.shrink();
        return const SizedBox.shrink();
    }
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
            "${transaction.wallet.currency} ${_fCCY.format(transaction.amount)}",
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
            "${transaction.wallet.currency} ${_fCCY.format(transaction.amount)}",
            style: TextStyle(
              color: accentColors[5],
            ),
            textAlign: TextAlign.right,
          ),
          Visibility(
            visible: (transaction.walletTo != null),
            child: Text(
              "${transaction.walletTo != null ? transaction.walletTo!.currency : ''} ${_fCCY.format(transaction.amount * transaction.exchangeRate)}",
              style: TextStyle(
                color: lighten(accentColors[5], 0.25),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }
  }

  Future<void> _showTransactionEditScreen(TransactionListModel txn) async {
    // go to the transaction edit for this txn
    await Navigator.pushNamed(context, '/transaction/edit', arguments: txn)
        .then((result) async {
      // check if we got return
      if (result != null) {
        // set state to rebuild the widget
        setState(() {
          // convert result to transaction list mode
          TransactionListModel txnUpdate = result as TransactionListModel;
          // update the current transaction list based on the updated transaction
          for (int i = 0; i < _filterTransactions.length; i++) {
            // check which transaction is being updated
            if (_filterTransactions[i].id == txnUpdate.id) {
              _filterTransactions[i] = txnUpdate;
              break;
            }
          }

          // after that we will perform grouping of the transactions to income, expense, and transfer
          _groupTransactions();
        });
      }
    });
  }

  void _groupTransactions() {
    double amount;
    DateTime? startDate;
    DateTime? endDate;
    int count;

    // clear all the income, expense, and transfer
    _income.clear();
    _expense.clear();
    _transfer.clear();
    _summaryIncome.clear();
    _totalAmountIncome.clear();
    _summaryExpense.clear();
    _totalAmountExpense.clear();
    _summaryTransfer.clear();
    _totalAmountTransfer.clear();

    String summaryKey = "";

    // now compute the summary data so we can showed it on the summary page
    // based on the income, and expense
    for (int i = 0; i < _filterTransactions.length; i++) {
      // generate the summary key
      if (_filterTransactions[i].type == 'expense' ||
          _filterTransactions[i].type == 'income') {
        summaryKey =
            "${_filterTransactions[i].type.toLowerCase()}_${_filterTransactions[i].category != null ? _filterTransactions[i].category!.name : ''}_${_filterTransactions[i].name}_${_filterTransactions[i].wallet.currency}";
      } else {
        summaryKey =
            "${_filterTransactions[i].type.toLowerCase()}_${_filterTransactions[i].wallet.name}_${_filterTransactions[i].wallet.currency}";
      }

      // check which transaction is being updated
      switch (_filterTransactions[i].type.toLowerCase()) {
        case 'income':
          // check if summary key exists or not?
          if (!_summaryIncome.containsKey(summaryKey)) {
            _summaryIncome[summaryKey] = [];
          }
          _summaryIncome[summaryKey]!.add(_filterTransactions[i]);

          // check if total summary key for this ccy is exists or not?
          if (!_totalAmountIncome
              .containsKey(_filterTransactions[i].wallet.currency)) {
            _totalAmountIncome[_filterTransactions[i].wallet.currency] = 0;
          }
          _totalAmountIncome[_filterTransactions[i].wallet.currency] =
              _totalAmountIncome[_filterTransactions[i].wallet.currency]! +
                  _filterTransactions[i].amount;

          _income.add(_filterTransactions[i]);
          break;
        case 'expense':
          // check if summary key exists or not?
          if (!_summaryExpense.containsKey(summaryKey)) {
            _summaryExpense[summaryKey] = [];
          }
          _summaryExpense[summaryKey]!.add(_filterTransactions[i]);

          // check if total summary key for this ccy is exists or not?
          if (!_totalAmountExpense
              .containsKey(_filterTransactions[i].wallet.currency)) {
            _totalAmountExpense[_filterTransactions[i].wallet.currency] = 0;
          }
          _totalAmountExpense[_filterTransactions[i].wallet.currency] =
              _totalAmountExpense[_filterTransactions[i].wallet.currency]! +
                  _filterTransactions[i].amount;

          _expense.add(_filterTransactions[i]);
          break;
        case 'transfer':
          // check if summary key exists or not?
          if (!_summaryTransfer.containsKey(summaryKey)) {
            _summaryTransfer[summaryKey] = [];
          }
          _summaryTransfer[summaryKey]!.add(_filterTransactions[i]);

          // check if total summary key for this ccy is exists or not?
          if (!_totalAmountTransfer
              .containsKey(_filterTransactions[i].wallet.currency)) {
            _totalAmountTransfer[_filterTransactions[i].wallet.currency] = 0;
          }
          _totalAmountTransfer[_filterTransactions[i].wallet.currency] =
              _totalAmountTransfer[_filterTransactions[i].wallet.currency]! +
                  _filterTransactions[i].amount;

          _transfer.add(_filterTransactions[i]);
          break;
      }
    }

    // sorted the total amount income and expense
    // so it will showed in the same order on the summary list
    List<MapEntry<String, double>> sortedEntriesIncome =
        _totalAmountIncome.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    _totalAmountIncome = Map.fromEntries(sortedEntriesIncome);

    List<MapEntry<String, double>> sortedEntriesExpense =
        _totalAmountExpense.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    _totalAmountExpense = Map.fromEntries(sortedEntriesExpense);

    // clear the summary list widget
    _summaryList.clear();

    // add the expense bar on the _summaryList
    _summaryList.add(Container(
      padding: const EdgeInsets.all(10),
      color: secondaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            "Expense",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accentColors[2],
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          ..._generateSubSummaryBox(
              data: _totalAmountExpense, color: accentColors[2]),
        ],
      ),
    ));

    // loop thru all the expense data
    _summaryExpense.forEach((key, value) {
      // compute the amount
      amount = 0;
      startDate = null;
      endDate = null;
      count = 0;

      for (TransactionListModel data in value) {
        if (startDate == null) {
          startDate = data.date;
        } else {
          if (startDate!.isAfter(data.date)) {
            startDate = data.date;
          }
        }

        if (endDate == null) {
          endDate = data.date;
        } else {
          if (endDate!.isBefore(data.date)) {
            endDate = data.date;
          }
        }

        amount += data.amount;
        count++;
      }

      // create TransactionModel based on the value
      TransactionListModel txn = TransactionListModel(
          -1,
          value[0].name,
          value[0].type,
          DateTime.now(),
          '',
          value[0].category,
          value[0].wallet,
          null,
          value[0].usersPermissionsUser,
          true,
          amount,
          1);

      _summaryList.add(_createSummaryItem(
          txn: txn, startDate: startDate!, endDate: endDate!, count: count));
    });

    // add the income bar on the _summaryList
    _summaryList.add(Container(
      padding: const EdgeInsets.all(10),
      color: secondaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            "Income",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accentColors[6],
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          ..._generateSubSummaryBox(
              data: _totalAmountIncome, color: accentColors[6]),
        ],
      ),
    ));

    _summaryIncome.forEach((key, value) {
      // compute the amount
      amount = 0;
      startDate = null;
      endDate = null;
      count = 0;

      for (TransactionListModel data in value) {
        if (startDate == null) {
          startDate = data.date;
        } else {
          if (startDate!.isAfter(data.date)) {
            startDate = data.date;
          }
        }

        if (endDate == null) {
          endDate = data.date;
        } else {
          if (endDate!.isBefore(data.date)) {
            endDate = data.date;
          }
        }

        amount += data.amount;
        count++;
      }

      // create TransactionModel based on the value
      TransactionListModel txn = TransactionListModel(
          -1,
          value[0].name,
          value[0].type,
          DateTime.now(),
          '',
          value[0].category,
          value[0].wallet,
          null,
          value[0].usersPermissionsUser,
          true,
          amount,
          1);

      _summaryList.add(_createSummaryItem(
          txn: txn, startDate: startDate!, endDate: endDate!, count: count));
    });

    // add the transfer bar on the _summaryList
    _summaryList.add(Container(
      padding: const EdgeInsets.all(10),
      color: secondaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            "Transfer",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: accentColors[4],
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          ..._generateSubSummaryBox(
              data: _totalAmountTransfer, color: accentColors[4]),
        ],
      ),
    ));

    _summaryTransfer.forEach((key, value) {
      // compute the amount
      amount = 0;
      startDate = null;
      endDate = null;
      count = 0;

      for (TransactionListModel data in value) {
        if (startDate == null) {
          startDate = data.date;
        } else {
          if (startDate!.isAfter(data.date)) {
            startDate = data.date;
          }
        }

        if (endDate == null) {
          endDate = data.date;
        } else {
          if (endDate!.isBefore(data.date)) {
            endDate = data.date;
          }
        }

        amount += data.amount;
        count++;
      }

      // create TransactionModel based on the value
      TransactionListModel txn = TransactionListModel(
          -1,
          value[0].wallet.name,
          value[0].type,
          DateTime.now(),
          '',
          value[0].category,
          value[0].wallet,
          null,
          value[0].usersPermissionsUser,
          true,
          amount,
          1);

      _summaryList.add(_createSummaryItem(
          txn: txn, startDate: startDate!, endDate: endDate!, count: count));
    });
  }

  List<Widget> _generateSubSummaryBox(
      {required Map<String, double> data, required Color color}) {
    List<Widget> ret = <Widget>[];

    data.forEach((key, value) {
      ret.add(SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              "Total $key",
              style: TextStyle(
                color: color,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _fCCY.format(value),
                  style: TextStyle(
                    color: color,
                  ),
                ),
              ),
            )
          ],
        ),
      ));
    });

    return ret;
  }

  Widget _createSummaryItem({
    required TransactionListModel txn,
    required DateTime startDate,
    required DateTime endDate,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _categoryIcon(
              name: (txn.category != null ? txn.category!.name : ''),
              type: txn.type),
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
                  "${Globals.dfddMMyyyy.format(startDate.toLocal())} - ${Globals.dfddMMyyyy.format(endDate.toLocal())}",
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
                (txn.category == null
                    ? const SizedBox.shrink()
                    : Text(
                        (txn.category != null ? txn.category!.name : ''),
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                      )),
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

  Widget _createItem(TransactionListModel txn, [bool? canEdit]) {
    return InkWell(
        onTap: (() {
          if (canEdit ?? true) {
            _showTransactionEditScreen(txn);
          }
        }),
        child: _createItemType(txn));
  }

  Widget _createItemType(TransactionListModel txn) {
    switch (txn.type.toLowerCase()) {
      case "expense":
        return MyItemList(
          iconColor: IconColorList.getExpenseColor(txn.category!.name),
          icon: IconColorList.getExpenseIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: Globals.dfeddMMMyyyy.format(txn.date.toLocal()),
          subTitleStyle: const TextStyle(fontSize: 10),
          description: txn.description,
          descriptionStyle:
              const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
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
          subTitle: Globals.dfeddMMMyyyy.format(txn.date.toLocal()),
          subTitleStyle: const TextStyle(fontSize: 10),
          description: txn.description,
          descriptionStyle:
              const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
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
          subTitle: Globals.dfeddMMMyyyy.format(txn.date.toLocal()),
          subTitleStyle: const TextStyle(fontSize: 10),
          description: txn.description,
          descriptionStyle:
              const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
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
          subTitle: Globals.dfeddMMMyyyy.format(txn.date.toLocal()),
          subTitleStyle: const TextStyle(fontSize: 10),
          description: txn.description,
          descriptionStyle:
              const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[2],
        );
    }
  }

  void _setTransactions(
      List<TransactionListModel> transactions, int limit, int start) {
    setState(() {
      _transactions.clear();
      _transactions.addAll(transactions);

      // set also the start for the next transaction we need to fetch
      _start = start + limit;

      // filter the transaction
      _filterTheTransaction();

      // group the transactions
      _groupTransactions();
    });
  }

  void _filterTheTransaction() {
    // clear the filter transaction first
    _filterTransactions.clear();

    // check if we have filter enabled or not?
    if (_selectedWalletList.isEmpty) {
      _filterTransactions.addAll(_transactions);
    } else {
      // loop thru transactions and see if the wallet from and to is on the
      // selected wallet or not?
      for (int i = 0; i < _transactions.length; i++) {
        // check if the wallet from and to id is in the selected wallet list
        // or not?
        if (_selectedWalletList[_transactions[i].wallet.id] ?? false) {
          _filterTransactions.add(_transactions[i]);
        } else {
          // check if wallet to is not null
          if (_transactions[i].walletTo != null) {
            // check if the wallet to id is on the selected wallet list or not?
            if (_selectedWalletList[_transactions[i].walletTo!.id] ?? false) {
              _filterTransactions.add(_transactions[i]);
            }
          }
        }
      }
    }
  }

  Future<void> _findTransaction(String searchText, String categoryId,
      String type, int limit, int start) async {
    await _transactionHttp
        .findTransaction(type, searchText, categoryId, limit, start)
        .then((results) {
      _setTransactions(results, limit, start);
    });
  }

  Future<void> _submitSearch() async {
    // 1 will be text search only
    // 2 will be category search only
    // 3 will be both
    int determineType = 0;

    // default the category id value as empty string
    _categoryId = '';

    // check if category selected is empty or not?
    if (_categorySelected.isNotEmpty) {
      // category selected not empty
      determineType += 2;

      // generate the _categoryId based on the list of the category selected
      _categorySelected.forEach((key, value) {
        // if not the first one, then add ,
        if (_categoryId.isNotEmpty) {
          _categoryId = '$_categoryId,';
        }
        _categoryId = _categoryId + key.toString();
      });
    }

    // check if the text is empty or not?
    if (_searchController.text.trim().isNotEmpty) {
      // not empty, add 1 to the determine type
      determineType += 1;

      // set the search text as current search controller text
      _searchText = _searchController.text;
      _searchText = _searchText.trim();

      // ensure the searchText is more than 3
      if (_searchText.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(createSnackBar(
          message: "Minimum text search is 3 character",
        ));
        return;
      }
    }

    // ensure that we already determine the type when reaching here
    if (determineType == 0) {
      ScaffoldMessenger.of(context).showSnackBar(createSnackBar(
        message: "Add text or category before searching.",
      ));
      return;
    }

    // now determine the _type
    switch (determineType) {
      case 1:
        _type = "name";
        break;
      case 2:
        _type = "category";
        break;
      case 3:
        _type = "both";
        break;
    }

    // show the loader dialog
    LoadingScreen.instance().show(context: context);

    // initialize all the value
    _start = 0; // always start from 0
    _transactions.clear();
    _transactions = [];

    // try to find the transaction
    await _findTransaction(
      _searchText,
      _categoryId,
      _type,
      _limit,
      _start
    ).onError((error, stackTrace) {
      Log.error(
        message: "Error when searching transaction",
        error: error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        Navigator.pop(context);
        // showed error message
        ScaffoldMessenger.of(context).showSnackBar(createSnackBar(
          message: "Error when searching transaction",
        ));
      }
    }).whenComplete(
      () {
        // remove the loading screen
        LoadingScreen.instance().hide();
      },
    );
  }

  Widget _showSearchOrSelectionWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        CupertinoSearchTextField(
          controller: _searchController,
          style:
              const TextStyle(color: textColor2, fontFamily: '--apple-system'),
          suffixIcon: const Icon(Ionicons.arrow_forward_circle),
          onSubmitted: ((_) async {
            await _submitSearch().then((_) {
              if (mounted) {
                // remove the focus from the text
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus) {
                  currentFocus.unfocus();
                }
              }
            });
          }),
          onSuffixTap: (() async {
            await _submitSearch().then((_) {
              if (mounted) {
                // remove the focus from the text
                FocusScopeNode currentFocusSuffix = FocusScope.of(context);
                if (!currentFocusSuffix.hasPrimaryFocus) {
                  currentFocusSuffix.unfocus();
                }
              }
            });
          }),
        ),
        const SizedBox(
          height: 10,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: (() {
                      _showCategorySelectionDialog();
                    }),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                          color: primaryDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: secondaryBackground,
                            style: BorderStyle.solid,
                            width: 1.0,
                          )),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Ionicons.add,
                            size: 20,
                            color: textColor,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Center(
                                child: Text(
                              "Add",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: (() {
                      setState(() {
                        // clear the category
                        _categorySelected.clear();

                        // clear also the filter
                        _selectedWalletList.clear();

                        // then filter the transaction and group it again
                        _filterTheTransaction();
                        _groupTransactions();
                      });
                    }),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                          color: primaryDark,
                          border: Border.all(
                            color: secondaryBackground,
                            style: BorderStyle.solid,
                            width: 1.0,
                          )),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Ionicons.trash,
                            size: 20,
                            color: textColor,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Center(
                                child: Text(
                              "Clear",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: (() async {
                      await _submitSearch();
                    }),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                          color: primaryDark,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: secondaryBackground,
                            style: BorderStyle.solid,
                            width: 1.0,
                          )),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Ionicons.search,
                            size: 20,
                            color: textColor,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Center(
                                child: Text(
                              "Search",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _generateChipCategory(),
            ),
          ],
        ),
      ],
    );
  }

  void _showCategorySelectionDialog() {
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return MyBottomSheet(
            context: context,
            title: "Category",
            screenRatio: 0.75,
            child: TransactionSearchCategory(
              categoryExpense: _categoryExpenseIcon,
              categoryIncome: _categoryIncomeIcon,
            ),
          );
        });
  }

  void _generateIconCategory() {
    _categoryExpenseList.forEach((key, value) {
      _categoryExpenseIcon.add(_iconCategory(value));
    });

    _categoryIncomeList.forEach((key, value) {
      _categoryIncomeIcon.add(_iconCategory(value));
    });
  }

  Widget _iconCategory(CategoryModel category) {
    // check if this is expense or income
    Color iconColor;
    Icon icon;

    if (category.type.toLowerCase() == "expense") {
      iconColor = IconColorList.getExpenseColor(category.name.toLowerCase());
      icon = IconColorList.getExpenseIcon(category.name.toLowerCase());
    } else {
      iconColor = IconColorList.getIncomeColor(category.name.toLowerCase());
      icon = IconColorList.getIncomeIcon(category.name.toLowerCase());
    }

    return GestureDetector(
      onTap: () {
        //print("Select category");
        // check if category still less than 10
        if (_categorySelected.length < 10) {
          setState(() {
            _categorySelected[category.id] = category;
          });
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              createSnackBar(message: "Maximum selected category is 10"));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: iconColor,
                  border: Border.all(
                    color: (_categorySelected.containsKey(category.id)
                        ? accentColors[4]
                        : Colors.transparent),
                    width: 2.0,
                    style: BorderStyle.solid,
                  )),
              child: icon,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 10,
                      color: textColor,
                    ),
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _generateChipCategory() {
    List<Widget> result = [];

    // loop thru the category selected
    _categorySelected.forEach((key, value) {
      result.add(InkWell(
        onTap: (() {
          // remove this chip from the _categorySelected
          setState(() {
            _categorySelected.remove(key);
          });
        }),
        child: Chip(
          avatar: _categoryIcon(
              type: value.type,
              name: value.name,
              height: 20,
              width: 20,
              size: 15),
          label: Text(value.name),
          backgroundColor: (value.type == 'expense'
              ? IconColorList.getExpenseColor(value.name)
              : IconColorList.getIncomeColor(value.name)),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        ),
      ));
    });

    return result;
  }
}

class TransactionSearchCategory extends StatefulWidget {
  final List<Widget> categoryExpense;
  final List<Widget> categoryIncome;
  const TransactionSearchCategory(
      {super.key, required this.categoryExpense, required this.categoryIncome});

  @override
  State<TransactionSearchCategory> createState() =>
      _TransactionSearchCategoryState();
}

class _TransactionSearchCategoryState extends State<TransactionSearchCategory> {
  PageName _resultCategoryName = PageName.expense;
  final Map<PageName, Color> _resultCategoryColor = {
    PageName.expense: accentColors[2],
    PageName.income: accentColors[6],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: CupertinoSegmentedControl<PageName>(
              selectedColor: (_resultCategoryColor[_resultCategoryName] ??
                  accentColors[9]),
              // Provide horizontal padding around the children.
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // This represents a currently selected segmented control.
              groupValue: _resultCategoryName,
              // Callback that sets the selected segmented control.
              onValueChanged: (PageName value) {
                setState(() {
                  _resultCategoryName = value;
                });
              },
              children: const <PageName, Widget>{
                PageName.expense: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Expense'),
                ),
                PageName.income: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Income'),
                ),
              },
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 4,
            children: (_resultCategoryName == PageName.expense
                ? widget.categoryExpense
                : widget.categoryIncome),
          ),
        ),
      ],
    );
  }
}
