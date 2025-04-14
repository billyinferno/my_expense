import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class StatsTransactionPage extends StatefulWidget {
  final Object? args;
  const StatsTransactionPage({ super.key, required this.args});

  @override
  State<StatsTransactionPage> createState() => _StatsTransactionPageState();
}

class _StatsTransactionPageState extends State<StatsTransactionPage> {
  final _transactionHttp = TransactionHTTPService();

  final ScrollController _detailScrollController = ScrollController();
  final ScrollController _summaryScrollController = ScrollController();

  final Map<int, TypeSlideItem> _typeSlideItem = {
    0: TypeSlideItem(
      text: "Summary",
      color: accentColors[4],
    ),
    1: TypeSlideItem(
      text: "Detail",
      color: accentColors[6],
    ),
  };

  late List<TransactionStatsDetailModel> _transactions;
  late List<TransactionStatsDetailModel> _transactionsSort;
  late Map<String, List<TransactionListModel>> _transactionSummary;
  late StatsTransactionArgs _args;
  late Future<bool> _getData;
  late String _filterType;
  late bool _sortType;
  late int _currentPage;
  late List<Widget> _summaryWidget;
  late List<Widget> _summaryWidgetMonth;
  late List<Widget> _summaryWidgetYear;
  late bool _showMonthSummary;

  @override
  void initState() {
    super.initState();

    _args = widget.args as StatsTransactionArgs;

    // initialize all default value
    _transactions = [];
    _transactionsSort = [];
    _transactionSummary = {};

    _filterType = "D";
    _sortType = false;

    // default to detail transaction page
    _currentPage = 1;
    _summaryWidget = [];
    _summaryWidgetMonth = [];
    _summaryWidgetYear = [];
    _showMonthSummary = false;

    // now try to fetch the transaction data
    _getData = _fetchStatsDetail();
  }

  @override
  void dispose() {
    _detailScrollController.dispose();
    _summaryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(_args.categoryName)),
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context, false);
          },
          icon: const Icon(
            Ionicons.close,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: (() {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return MyBottomSheet(
                    context: context,
                    title: "Select Filter",
                    screenRatio: 0.3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = "N";
                              _sortTransactions();
                            });
                            Navigator.pop(context);
                          }),
                          color: Colors.grey[900]!,
                          icon: Center(
                            child: Text(
                              "AN",
                              style: TextStyle(
                                color: textColor2,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          title: "Name",
                          isSelected: (_filterType == "N"),
                        ),
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = "D";
                              _sortTransactions();
                            });
                            Navigator.pop(context);
                          }),
                          color: Colors.grey[900]!,
                          icon: Icon(
                            Ionicons.calendar,
                            color: textColor2,
                            size: 15,
                          ),
                          title: "Date",
                          isSelected: (_filterType == "D"),
                        ),
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = "A";
                              _sortTransactions();
                            });
                            Navigator.pop(context);
                          }),
                          color: Colors.grey[900]!,
                          icon: Icon(
                            Ionicons.cash,
                            color: textColor2,
                            size: 15,
                          ),
                          title: "Amount",
                          isSelected: (_filterType == "A"),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            icon: Icon(
              Ionicons.funnel,
              color: textColor,
              size: 15,
            )
          ),
          SortIcon(
            asc: _sortType,
            onPress: (() {
              setState(() {
                _sortType = !_sortType;
                _sortTransactions();
              });
            }),
          ),
        ],
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    return FutureBuilder(
      future: _getData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MySafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: secondaryDark,
                    border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
                  ),
                  child: BudgetBar(
                    title: _args.categoryName,
                    symbol: _args.currency.symbol,
                    budgetUsed: (_args.amount < 0 ? _args.amount * (-1) : _args.amount),
                    budgetTotal: (_args.total < 0 ? _args.total * (-1) : _args.total),
                    barColor: (_args.type == "expense" ? IconColorList.getExpenseColor(_args.categoryName) : IconColorList.getIncomeColor(_args.categoryName)),
                    showLeftText: false,
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: 250,
                    child: TypeSlide<int>(
                      initialItem: _currentPage,
                      onValueChanged: ((index) {
                        setState(() {
                          _currentPage = index;
                        });
                      }),
                      items: _typeSlideItem
                    ),
                  ),
                ),
                Expanded(
                  child: _subPage(),
                ),
              ],
            ),
          ); 
        }
        else if (snapshot.hasError) {
          return CommonErrorPage(
            isNeedScaffold: false,
            errorText: "Error when get statistic information",
          );
        }
        else {
          return CommonLoadingPage(
            isNeedScaffold: false,
          );
        }
      },
    );
  }

  Widget _subPage() {
    if (_currentPage == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: (() {
              setState(() {
                _showMonthSummary = !_showMonthSummary;
                if (_showMonthSummary) {
                  _summaryWidget = _summaryWidgetMonth;
                }
                else {
                  _summaryWidget = _summaryWidgetYear;
                }
              });
            }),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: secondaryDark,
                border: Border(
                  bottom: BorderSide(
                    color: secondaryLight,
                    width: 1.0,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 15,
                    width: 30,
                    child: Transform.scale(
                      scale: 0.6,
                      child: CupertinoSwitch(
                        value: _showMonthSummary,
                        activeTrackColor: accentColors[0],
                        onChanged: (value) {
                          setState(() {
                            _showMonthSummary = value;
                            if (_showMonthSummary) {
                              _summaryWidget = _summaryWidgetMonth;
                            }
                            else {
                              _summaryWidget = _summaryWidgetYear;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 11,),
                  const Text(
                    "Monthly Breakdown",
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _summaryScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _summaryWidget.length,
              itemBuilder: (context, index) {
                return _summaryWidget[index];
              },
            ),
          ),
        ],
      );
    }
    else {
      return _detailPage();
    }
  }

  Widget _detailHeader({required String name}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
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
      child: Text(name),
    );
  }

  Widget _detailPage() {
    // create the widget result list
    List<Widget> detailTxn = [];

    // helper variable
    DateTime? prevDate;
    String? prevName;

    // generate the widget by loog the _transactionSort
    for(int i=0; i<_transactionsSort.length; i++) {
      if (_filterType != "A") {
        // check whether this is sort based on date or name?
        if (_filterType == "N") {
          // filter is name
          // check if previous name is null?
          if (prevName == null) {
            // create the header
            detailTxn.add(_detailHeader(name: _transactionsSort[i].name));
          }
          else {
            // check if the previous name is same as current name or not?
            if (prevName != _transactionsSort[i].name.toLowerCase().trim()) {
              // different name, create a new header
              detailTxn.add(_detailHeader(name: _transactionsSort[i].name));
            }
          }

          prevName = _transactionsSort[i].name.toLowerCase().trim();
        }
        else if (_filterType == "D") {
          // filter is date
          // check if previous date is null?
          if (prevDate == null) {
            // create the header
            detailTxn.add(_detailHeader(name: Globals.dfddMMMMyyyy.formatLocal(_transactionsSort[i].date)));
          }
          else {
            // check if previous date is not same as current date
            if (prevDate != _transactionsSort[i].date) {
              // different date, create a new header
              detailTxn.add(_detailHeader(name: Globals.dfddMMMMyyyy.formatLocal(_transactionsSort[i].date)));
            }
          }

          prevDate = _transactionsSort[i].date;
        }
      }

      // create the transaction item
      detailTxn.add(_createItem(_transactionsSort[i]));
    }

    return ListView.builder(
      controller: _detailScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: detailTxn.length,
      itemBuilder: (BuildContext ctx, int index) {
        return detailTxn[index];
      },
    );
  }

  List<Widget> _summaryItems({
    required Map<String, List<TransactionListModel>> transactions,
    required String keyType,
  }) {
    final Map<String, Map<String, TransactionListModel>> data = {};
    final List<Widget> items = [];

    DateTime? startDate;
    DateTime? endDate;
    double amount;
    int count;
    String subSummaryKey;
    TransactionListModel tmpTransaction;

    // loop thru the summary transaction map
    transactions.forEach((name, transactionList) {
      // initialize the start date and amount
      startDate = null;
      endDate = null;
      amount = 0;
      count = 0;

      // now create a new map for the sub transaction summary
      data[name] = {};

      // loop thru the transaction list for this name
      for(int i=0; i<transactionList.length; i++) {
        // check for the date
        if (startDate == null) {
          startDate = transactionList[i].date;
        }
        else {
          if (transactionList[i].date.isBefore(startDate!)) {
            startDate = transactionList[i].date;
          }
        }

        if (endDate == null) {
          endDate = transactionList[i].date;
        }
        else {
          if (transactionList[i].date.isAfter(endDate!)) {
            endDate = transactionList[i].date;
          }
        }

        // get the key for this
        if (keyType == "M") {
          subSummaryKey = Globals.dfyyyyMM.formatLocal(transactionList[i].date);
        }
        else {
          subSummaryKey = transactionList[i].date.toLocal().year.toString();
        }

        // check if we already have this key on the sub summary or not??
        if (data[name]!.containsKey(subSummaryKey)) {
          // already have previous transaction
          // get the previous data
          tmpTransaction = data[name]![subSummaryKey]!;

          // and combine with the new data
          data[name]![subSummaryKey] = TransactionListModel(
            -1,
            transactionList[i].name,
            transactionList[i].type,
            DateTime(
              transactionList[i].date.year,
              transactionList[i].date.month,
              1
            ).toLocal(),
            transactionList[i].description,
            transactionList[i].category,
            transactionList[i].wallet,
            transactionList[i].walletTo,
            transactionList[i].usersPermissionsUser,
            transactionList[i].cleared,
            (transactionList[i].amount + tmpTransaction.amount),
            transactionList[i].exchangeRate
          );
        }
        else {
          // not exists, create a new data
          data[name]![subSummaryKey] = TransactionListModel(
              -1,
              transactionList[i].name,
              transactionList[i].type,
              DateTime(
                transactionList[i].date.year,
                transactionList[i].date.month,
                1
              ).toLocal(),
              transactionList[i].description,
              transactionList[i].category,
              transactionList[i].wallet,
              transactionList[i].walletTo,
              transactionList[i].usersPermissionsUser,
              transactionList[i].cleared,
              transactionList[i].amount,
              transactionList[i].exchangeRate
            );
        }

        amount += transactionList[i].amount;
        count++;
      }

      // create the summary
      TransactionListModel txn = TransactionListModel(
        -1,
        transactionList[0].name,
        transactionList[0].type,
        DateTime.now().toLocal(),
        '',
        transactionList[0].category,
        transactionList[0].wallet,
        null,
        transactionList[0].usersPermissionsUser,
        true,
        amount,
        1,
      );

      items.add(TransactionExpandableItem(
        txn: txn,
        startDate: startDate!,
        endDate: endDate!,
        count: count,
        subTxn: (data[name] ?? {}),
      ));
    },);

    return items;
  }

  Widget _createItem(TransactionStatsDetailModel txn) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1.0,
            color: primaryLight
          )
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (_args.type == "expense" ? IconColorList.getExpenseColor(txn.categoriesName) : IconColorList.getIncomeColor(txn.categoriesName)),
            ),
            margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: (_args.type == "expense" ? IconColorList.getExpenseIcon(txn.categoriesName) : IconColorList.getIncomeIcon(txn.categoriesName)),
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
                  "(${txn.walletName}) ${Globals.dfddMMyy.formatLocal(txn.date)}",
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
            children: <Widget>[
              Text(
                "${_args.currency.symbol} ${Globals.fCCY.format(txn.amount)}",
                style: TextStyle(
                  color: (_args.type == "expense" ? accentColors[2] : accentColors[6]),
                ),
              ),
            ],
          ),
        ],
      )
    );
  }

  Future<bool> _fetchStatsDetail() async {
    await _transactionHttp.fetchIncomeExpenseCategoryDetail(
      name: _args.name,
      search: _args.search,
      type: _args.type,
      categoryId: _args.categoryId,
      ccyId: _args.currency.id,
      walletId: _args.walletId,
      from: _args.fromDate,
      to: _args.toDate,
    ).then((result) {
      _transactions = result;
      _sortTransactions();
      _summarizeTransaction();
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on <_fetchStatsDetail>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception("Error when fetching statistic");
    });

    return true;
  }

  void _summarizeTransaction() {
    String key;

    // clear the current map first
    _transactionSummary.clear();

    // loop thru _transactions to create the map
    for(int i=0; i<_transactions.length; i++) {
      // get the key for the map
      key = _transactions[i].name.trim().toLowerCase();

      // check if current key is not exists? if not exists, then it means that
      // we need to create a new list for this transaction.
      if (!_transactionSummary.containsKey(key)) {
        _transactionSummary[key] = [];
      }

      // create the transaction list model, as stat use different of model
      // for the result.
      _transactionSummary[key]!.add(TransactionListModel(
        -1,
        _transactions[i].name,
        _transactions[i].type,
        _transactions[i].date,
        '',
        CategoryTransactionModel(
          _transactions[i].categoriesId,
          _transactions[i].categoriesName
        ),
        WalletTransactionModel(
          -1,
          '',
          -1,
          _args.currency.name,
          _args.currency.symbol
        ),
        null,
        UserPermissionModel(-1, '', ''),
        true,
        _transactions[i].amount,
        1,
      ));
    }

    _transactionSummary = sortedMap(data: _transactionSummary);

    // generate the summary widget, so we don't need to keep generate the
    // widget during rebuilding
    _summaryWidgetMonth = _summaryItems(
      transactions: _transactionSummary,
      keyType: "M",
    );
    
    _summaryWidgetYear = _summaryItems(
      transactions: _transactionSummary,
      keyType: "Y",
    );

    // default the _summaryWidget to year
    _summaryWidget = _summaryWidgetYear;
  }

  void _sortTransactions() {
    // clear current transaction sort
    _transactionsSort.clear();

    // switch the filter type
    switch(_filterType) {
      case "N":
        _transactionsSort = _transactions.toList()..sort((a, b) => a.name.compareTo(b.name));
        break;
      case "D":
        _transactionsSort = _transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
        break;
      case "A":
        _transactionsSort = _transactions.toList()..sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        _transactionsSort = _transactions.toList()..sort((a, b) => a.date.compareTo(b.date));
        break;
    }

    // check whether this is ascending or descending
    if (!_sortType) {
      _transactionsSort = _transactionsSort.reversed.toList();
    }
  }
}