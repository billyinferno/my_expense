import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/budget_transaction_args.dart';
import 'package:my_expense/utils/log.dart';
import 'package:my_expense/utils/misc/wallet_transaction_class_helper.dart';
import 'package:my_expense/widgets/chart/budget_bar.dart';
import 'package:my_expense/widgets/item/budget_transaction_item.dart';
import 'package:table_calendar/table_calendar.dart';

class BudgetTransactionPage extends StatefulWidget {
  final Object? arguments;
  const BudgetTransactionPage({ super.key, required this.arguments });

  @override
  State<BudgetTransactionPage> createState() => _BudgetTransactionPageState();
}

class _BudgetTransactionPageState extends State<BudgetTransactionPage> {
  final ScrollController _scrollController = ScrollController();
  final fCCY = NumberFormat("#,##0.00", "en_US");
  final DateFormat _dtDayMonthYear = DateFormat("dd MMM yyyy");
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _categoryId = -1;
  String _categoryName = "";
  String _categorySymbol = "";
  double _budgetUsed = 0.0;
  double _budgetAmount = 0.0;
  int _currencyId = -1;
  bool _isLoading = true;
  bool _sortAscending = true;
  final Map<DateTime, WalletTransactionExpenseIncome> _totalDate = {};
  final List<WalletTransactionList> _list = [];
  List<TransactionListModel> _transactions = [];


  @override
  void initState() {
    super.initState();
    
    // convert the parameter being sent from main
    BudgetTransactionArgs args = widget.arguments as BudgetTransactionArgs;
    _selectedDate = args.selectedDate;
    _categoryId = args.categoryid;
    _categoryName = args.categoryName;
    _categorySymbol = args.currencySymbol;
    _budgetUsed = args.budgetUsed;
    _budgetAmount = args.budgetAmount;
    _currencyId = args.currencyId;

    _fetchBudget(true);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
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
    if(_isLoading) {
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
    else {
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
                _setLoading(true);
                await _fetchBudget(true);
              }),
              child: ListView.builder(
                controller: _scrollController,
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
                              _dtDayMonthYear.format(header.date.toLocal())
                            ),
                          ),
                          Text(
                            "(${fCCY.format(header.expense)})",
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
          const SizedBox(height: 30,),
        ],
      );
    }
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
          if (isSameDay(txnList[idx].date.toLocal(), key.toLocal())) {
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

  void _setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _fetchBudget([bool? force]) async {
    bool isForce = (force ?? false);

    String date = DateFormat('yyyy-MM-dd').format(_selectedDate.toLocal());
    await _transactionHttp.fetchTransactionBudget(_categoryId, date, _currencyId, isForce).then((value) async {
      await setTransactions(value.reversed.toList());
      _transactions = value.reversed.toList();

      _setLoading(false);
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when _fetchBudget",
        error: error,
        stackTrace: stackTrace,
      );

      // assume there are no data
      setTransactions([]);
      _setLoading(false);
    });
  }
}