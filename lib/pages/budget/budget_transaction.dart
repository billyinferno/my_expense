import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';
import 'package:my_expense/widgets/page/common_loading_page.dart';

class BudgetTransactionPage extends StatefulWidget {
  final Object? arguments;
  const BudgetTransactionPage({ super.key, required this.arguments });

  @override
  State<BudgetTransactionPage> createState() => _BudgetTransactionPageState();
}

class _BudgetTransactionPageState extends State<BudgetTransactionPage> {
  final ScrollController _scrollController = ScrollController();
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _categoryId = -1;
  String _categoryName = "";
  String _categorySymbol = "";
  double _budgetUsed = 0.0;
  double _budgetAmount = 0.0;
  int _currencyId = -1;
  bool _sortAscending = true;
  late List<WalletTransactionList> _list;
  late List<WalletTransactionList> _listAscending;
  late List<WalletTransactionList> _listDescending;
  late Future<bool> _getData;

  @override
  void initState() {
    super.initState();

    // initialize the list
    _list = [];
    _listAscending = [];
    _listDescending = [];

    // convert the parameter being sent from main
    BudgetTransactionArgs args = widget.arguments as BudgetTransactionArgs;
    _selectedDate = args.selectedDate;
    _categoryId = args.categoryid;
    _categoryName = args.categoryName;
    _categorySymbol = args.currencySymbol;
    _budgetUsed = args.budgetUsed;
    _budgetAmount = args.budgetAmount;
    _currencyId = args.currencyId;

    // get data from server
    _getData = _fetchBudget(true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(_categoryName)),
        leading: IconButton(
          icon: const Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            // check if got data changed already or not?
            Navigator.maybePop(context);
          }),
        ),
        actions: <Widget>[
          SortIcon(
            asc: _sortAscending,
            onPress: () async {
              setState(() {                
                // set the sorting to inverse what ever current sorting now
                _sortAscending = !_sortAscending;
                
                // check which list we need to put
                if (_sortAscending) {
                  _list = _listAscending;
                }
                else {
                  _list = _listDescending;
                }
              });
            },
          ),
        ],
      ),
      body: _createBody(),
    );
  }

  Widget _createBody() {
    return FutureBuilder(
      future: _getData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MySafeArea(
            child: _body()
          );
        }
        else if (snapshot.hasError) {
          return CommonErrorPage(
            isNeedScaffold: false,
            errorText: "Error when fetch budget transaction",
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

  Widget _body() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          color: secondaryDark,
          padding: const EdgeInsets.all(10),
          child: BudgetBar(
            title: _categoryName,
            symbol: _categorySymbol,
            budgetUsed: _budgetUsed,
            budgetTotal: _budgetAmount,
          )
        ),
        Expanded(
          child: RefreshIndicator(
            color: accentColors[6],
            onRefresh: (() async {
              _getData = _fetchBudget(true);
            }),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _list.length,
              itemBuilder: (context, index) {
                if (_list[index].type == WalletListType.header) {
                  WalletTransactionExpenseIncome header = _list[index].data as WalletTransactionExpenseIncome;
                  return Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    color: secondaryDark,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            Globals.dfddMMMyyyy.formatLocal(header.date)
                          ),
                        ),
                        Text(
                          "(${Globals.fCCY.format(header.expense)})",
                          style: TextStyle(color: accentColors[2])
                        ),
                      ],
                    ),
                  );
                }
                else if(_list[index].type == WalletListType.item) {
                  TransactionListModel currTxn = _list[index].data as TransactionListModel;
                  return BudgetTransactionItem(
                    itemName: currTxn.name,
                    itemDate: currTxn.date,
                    itemSymbol: currTxn.wallet.symbol,
                    itemAmount: currTxn.amount,
                    categoryName: _categoryName,
                  );
                }
                else {
                  // if not header or item, then just showed shrink sized box
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  List<WalletTransactionList> _generateTransactionList({required List<TransactionListModel> transactions}) {
    List<WalletTransactionList> ret = [];
    
    final Map<DateTime, WalletTransactionExpenseIncome> totalDate = {};
    DateTime currDate;
    WalletTransactionExpenseIncome walletExpenseIncome;
    bool isLoop = false;
    int idx = 0;

    for (TransactionListModel txn in transactions) {
      if (txn.type == "expense") {
        currDate = DateTime(txn.date.toLocal().year, txn.date.toLocal().month, txn.date.toLocal().day);
        if (totalDate.containsKey(currDate)) {
          walletExpenseIncome = totalDate[currDate]!;
        }
        else {
          walletExpenseIncome = WalletTransactionExpenseIncome();
          walletExpenseIncome.date = currDate;
        }

        // add the expense amount
        walletExpenseIncome.expense += (txn.amount * -1);

        // add this walletExpenseIcon to the totalDate
        totalDate[currDate] = walletExpenseIncome;
      }
    }

    // after this we generate the WalletTransactionList
    // loop thru the totalDate
    totalDate.forEach((key, value) {
      // add the header for this
      WalletTransactionList header = WalletTransactionList();
      header.type = WalletListType.header;
      header.data = value;
      ret.add(header);

      // loop thru the transactions that have the same date and add this to the list
      isLoop = true;
      while(idx < transactions.length && isLoop) {
        if (transactions[idx].date.isSameDate(date: key)
        ) {
          // add to the transaction list
          WalletTransactionList data = WalletTransactionList();
          data.type = WalletListType.item;
          data.data = transactions[idx];
          ret.add(data);
          
          // next transactions
          idx = idx + 1;
        }
        else {
          // already different date
          isLoop = false;
        }
      }
    },);

    return ret;
  }

  Future<void> _setTransactions(List<TransactionListModel> transactions) async {
    setState(() {
      // generate the list
      _listAscending = _generateTransactionList(transactions: transactions);
      _listDescending = _generateTransactionList(transactions: transactions.reversed.toList());

      // set _list to ascending one
      _list = _listAscending;
    });
  }
  Future<bool> _fetchBudget([bool? force]) async {
    bool isForce = (force ?? false);

    String date = Globals.dfyyyyMMdd.formatLocal(_selectedDate);
    await _transactionHttp.fetchTransactionBudget(
      categoryId: _categoryId,
      date: date,
      currencyId: _currencyId,
      force: isForce
    ).then((value) async {
      await _setTransactions(value.reversed.toList());
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when _fetchBudget",
        error: error,
        stackTrace: stackTrace,
      );

      // assume there are no data
      _setTransactions([]);
      throw Exception('Error when loading budget');
    });

    return true;
  }
}