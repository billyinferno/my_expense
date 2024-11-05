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

  final ScrollController _scrollController = ScrollController();
  late List<TransactionStatsDetailModel> _transactions;
  late List<TransactionStatsDetailModel> _transactionsSort;
  late StatsTransactionArgs _args;
  late Future<bool> _getData;
  late String _filterType;
  late bool _sortType;

  @override
  void initState() {
    super.initState();

    _args = widget.args as StatsTransactionArgs;

    // initialize all default value
    _transactions = [];
    _transactionsSort = [];

    _filterType = "D";
    _sortType = false;

    // now try to fetch the transaction data
    _getData = _fetchStatsDetail();
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
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    itemCount: _transactionsSort.length,
                    itemBuilder: (BuildContext ctx, int index) {
                      TransactionStatsDetailModel txn = _transactionsSort[index];
                      return _createItem(txn);
                    },
                  ),
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