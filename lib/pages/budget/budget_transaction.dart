import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

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
  final Map<DateTime, WalletTransactionExpenseIncome> _totalDate = {};
  final List<WalletTransactionList> _list = [];
  List<TransactionListModel> _transactions = [];
  late Future<bool> _getData;

  @override
  void initState() {
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

    super.initState();
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
          InkWell(
            onTap: (() async {
              // set the sorting to inverse
              _sortAscending = !_sortAscending;
              await setTransactions(_transactions);
            }),
            child: SizedBox(
              width: 50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    (_sortAscending ? Ionicons.arrow_up : Ionicons.arrow_down),
                    color: textColor,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        (_sortAscending ? "A" : "Z"),
                        style: const TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      Text(
                        (_sortAscending ? "Z" : "A"),
                        style: const TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          return const Center(
            child: Text("Error when fetch budget transaction"),
          );
        }
        else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitFadingCube(
                color: accentColors[6],
                size: 25,
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                "loading...",
                style: TextStyle(
                  color: textColor2,
                  fontSize: 10,
                ),
              ),
            ],
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
                            Globals.dfddMMMyyyy.format(header.date.toLocal())
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

  Future<void> setTransactions(List<TransactionListModel> transactions) async {
    setState(() {
      DateTime currDate;
      WalletTransactionExpenseIncome walletExpenseIncome;
      bool isLoop = false;
      int idx = 0;
      List<TransactionListModel> txnList = [];

      // copy the transaction to _transactions, and check what kind of sort we want to do?
      if (_sortAscending) {
        txnList = transactions.toList();
      }
      else {
        txnList = transactions.reversed.toList();
      }

      // clear the _totalDate before loop
      _totalDate.clear();
      for (TransactionListModel txn in txnList) {
        if (txn.type == "expense") {
          currDate = DateTime(txn.date.toLocal().year, txn.date.toLocal().month, txn.date.toLocal().day);
          if (_totalDate.containsKey(currDate)) {
            walletExpenseIncome = _totalDate[currDate]!;
          }
          else {
            walletExpenseIncome = WalletTransactionExpenseIncome();
            walletExpenseIncome.date = currDate;
          }

          // add the expense amount
          walletExpenseIncome.expense += (txn.amount * -1);

          // add this walletExpenseIcon to the _totalDate
          _totalDate[currDate] = walletExpenseIncome;
        }
      }

      // clear before we loop the total date we have
      _list.clear();

      // after this we generate the WalletTransactionList
      // loop thru the _totalDate
      _totalDate.forEach((key, value) {
        // add the header for this
        WalletTransactionList header = WalletTransactionList();
        header.type = WalletListType.header;
        header.data = value;
        _list.add(header);

        // loop thru the transactions that have the same date and add this to the list
        isLoop = true;
        while(idx < txnList.length && isLoop) {
          if (txnList[idx].date.toLocal().isSameDate(date: key.toLocal())
          ) {
            // add to the transaction list
            WalletTransactionList data = WalletTransactionList();
            data.type = WalletListType.item;
            data.data = txnList[idx];
            _list.add(data);
            
            // next transactions
            idx = idx + 1;
          }
          else {
            // already different date
            isLoop = false;
          }
        }
      },);
    });
  }
  Future<bool> _fetchBudget([bool? force]) async {
    bool isForce = (force ?? false);

    String date = Globals.dfyyyyMMdd.format(_selectedDate.toLocal());
    await _transactionHttp.fetchTransactionBudget(
      categoryId: _categoryId,
      date: date,
      currencyId: _currencyId,
      force: isForce
    ).then((value) async {
      await setTransactions(value.reversed.toList());
      _transactions = value.reversed.toList();
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when _fetchBudget",
        error: error,
        stackTrace: stackTrace,
      );

      // assume there are no data
      setTransactions([]);
      throw Exception('Error when loading budget');
    });

    return true;
  }
}