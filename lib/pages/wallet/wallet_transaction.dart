import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ionicons/ionicons.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

class WalletTransactionPage extends StatefulWidget {
  final Object? wallet;
  const WalletTransactionPage({ super.key, required this.wallet });

  @override
  State<WalletTransactionPage> createState() => _WalletTransactionPageState();
}

class _WalletTransactionPageState extends State<WalletTransactionPage> {
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();

  late Future<List<BudgetModel>> _futureBudgets;
  late Future<List<WalletModel>> _futureWallets;
  
  late ScrollController _scrollController;
  late WalletModel _wallet;
  late TransactionWalletMinMaxDateModel _walletMinMaxDate;

  final Map<DateTime, WalletTransactionExpenseIncome> _totalDate = {};
  final List<WalletTransactionList> _list = [];

  DateTime _currentDate = DateTime.now();
  double _expenseAmount = 0.0;
  double _incomeAmount = 0.0;
  bool _sortAscending = true;
  List<TransactionListModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  late Future<bool> _getData;

  @override
  void initState() {
    super.initState();

    // init the wallet
    _wallet = widget.wallet as WalletModel;

    // fetch the transaction
    _getData = _fetchInitData();

    // set the scroll controller
    _scrollController = ScrollController();
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
        title: Center(child: Text(_wallet.name)),
        leading: IconButton(
          icon: const Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            Navigator.pop(context);
          }),
        ),
        actions: <Widget>[
          InkWell(
            onTap: (() async {
              // set the sorting to inverse
              _sortAscending = !_sortAscending;
              await _setTransactions(_transactions);
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
      body: FutureBuilder(
        future: _getData,
        builder: (context, snapshopt) {
          if (snapshopt.hasData) {
            return MySafeArea(
              child: _generateTransactionList()
            );
          }
          else if (snapshopt.hasError) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Error When Fetching Wallet Data",
                  style: TextStyle(
                    color: accentColors[2],
                    fontSize: 10,
                  ),
                ),
              ],
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
      ),
    );
  }

  Future<void> _setTransactions(List<TransactionListModel> transactions) async {
    setState(() {
      double income = 0.0;
      double expense = 0.0;

      DateTime currDate;
      WalletTransactionExpenseIncome walletExpenseIncome;

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
        currDate = DateTime(txn.date.toLocal().year, txn.date.toLocal().month, txn.date.toLocal().day);
        if (_totalDate.containsKey(currDate)) {
          walletExpenseIncome = _totalDate[currDate]!;
        }
        else {
          walletExpenseIncome = WalletTransactionExpenseIncome();
          walletExpenseIncome.date = currDate;
        }

        if(txn.type == "income") {
          income += txn.amount;
          walletExpenseIncome.income += txn.amount;
        }
        if(txn.type == "expense") {
          expense += (txn.amount * -1);
          walletExpenseIncome.expense += (txn.amount * -1);
        }
        if(txn.type == "transfer") {
          // check whether it's from or to
          if(_wallet.id == txn.wallet.id) {
            expense += (txn.amount * -1);
            walletExpenseIncome.expense += (txn.amount * -1);
          }
          if(txn.walletTo != null) {
            if(_wallet.id == txn.walletTo!.id) {
              income += txn.amount * txn.exchangeRate;
              walletExpenseIncome.income += txn.amount * txn.exchangeRate;
            }
          }
        }

        // add this walletExpenseIcon to the _totalDate
        _totalDate[currDate] = walletExpenseIncome;
      }

      // after this we generate the WalletTransactionList
      bool isLoop = false;
      int idx = 0;
      
      // clear before we loop the total date we have
      _list.clear();

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
          if (txnList[idx].date.isSameDate(date: key)) {
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
      
      _incomeAmount = income;
      _expenseAmount = expense;
    });
  }

  Future<void> _fetchTransactionWallet({
    required DateTime fetchDate,
    bool force = false,
    bool showLoader = true
  }) async {
    // show the loading screen
    if (showLoader) {
      LoadingScreen.instance().show(context: context);
    }

    // get the transaction
    String date = Globals.dfyyyyMMdd.format(
      DateTime(
        fetchDate.toLocal().year,
        fetchDate.toLocal().month,
        1
      )
    );

    await _transactionHttp.fetchTransactionWallet(
      walletId: _wallet.id,
      date: date,
      force: force
    ).then((txns) async {
      await _setTransactions(txns);
      _transactions = txns.toList();
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when <_fetchTransactionWallet>",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception('Error when fetch wallet transaction');
    }).whenComplete(() {
      if (showLoader) {
        // remove the loading screen
        LoadingScreen.instance().hide();
      }
    },);
  }

  Future<void> _fetchWalletMinMaxDate() async {
    await _transactionHttp.fetchWalletMinMaxDate(
      walletId: _wallet.id
    ).then((walletTxnDate) async {
      _walletMinMaxDate = walletTxnDate;
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when <_fetchWalletMinMaxDate>",
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  Widget _generateTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10,),
        CardFace(
          wallet: _wallet,
          minMaxDate: _walletMinMaxDate,
        ),
        const SizedBox(height: 10,),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
            color: secondaryDark,
          ),
          child: InkWell(
            onTap: (() async {
              await showMonthPicker(
                context: context,
                initialDate: _currentDate,
                firstDate: (_walletMinMaxDate.minDate ?? DateTime.now().toLocal()),
                lastDate: (_walletMinMaxDate.maxDate ?? DateTime.now().toLocal()),
              ).then((newDate) async {
                if (newDate != null) {
                  // ensure that the new date is different date with current date
                  if (_currentDate.isAfter(newDate) || _currentDate.isBefore(newDate)) {
                    // fetch the transaction wallet for this new date
                    await _fetchTransactionWallet(fetchDate: newDate).then((_) {
                      _setDate(newDate);
                    }).onError((error, stackTrace) {
                      Log.error(
                        message: "Error when fetch wallet for ${Globals.dfMMMMyyyy.formatLocal(newDate)}",
                        error: error,
                        stackTrace: stackTrace,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          createSnackBar(
                            message: "Error when fetch wallet transaction"
                          )
                        );
                      }
                    });
                  }
                }
              });
            }),
            onDoubleTap: (() async {
              // set the date as today date
              DateTime newDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
            
              await _fetchTransactionWallet(fetchDate: newDate).then((_) {
                _setDate(newDate);
              }).onError((error, stackTrace) {
                Log.error(
                  message: "Error when fetch wallet for ${Globals.dfMMMMyyyy.formatLocal(newDate)}",
                  error: error,
                  stackTrace: stackTrace,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    createSnackBar(
                      message: "Error when fetch wallet transaction"
                    )
                  );
                }
              });
            }),
            child: Row(
              children: [
                GestureDetector(
                  onTap: (() async {
                    DateTime newDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
            
                    await _fetchTransactionWallet(fetchDate: newDate).then((_) {
                      _setDate(newDate);
                    }).onError((error, stackTrace) {
                      Log.error(
                        message: "Error when fetch wallet for ${Globals.dfMMMMyyyy.formatLocal(newDate)}",
                        error: error,
                        stackTrace: stackTrace,
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          createSnackBar(
                            message: "Error when fetch wallet transaction"
                          )
                        );
                      }
                    });
                  }),
                  child: Container(
                    width: 70,
                    height: 50,
                    color: Colors.transparent,
                    child: const Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Ionicons.caret_back,
                        color: textColor2,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(Globals.dfMMMMyyyy.formatLocal(_currentDate)),
                        RichText(
                          text: TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: "(${Globals.fCCY.format(_expenseAmount)})",
                                style: TextStyle(
                                  color: accentColors[2]
                                )
                              ),
                              const TextSpan(text: " "),
                              TextSpan(
                                text: "(${Globals.fCCY.format(_incomeAmount)})",
                                style: TextStyle(
                                  color: accentColors[6]
                                )
                              ),
                            ]
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (() async {
                    DateTime newDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
            
                    await _fetchTransactionWallet(fetchDate: newDate).then((_) {
                      _setDate(newDate);
                    }).onError((error, stackTrace) {
                      Log.error(
                        message: "Error when fetch wallet for ${Globals.dfMMMMyyyy.formatLocal(newDate)}",
                        error: error,
                        stackTrace: stackTrace,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          createSnackBar(
                            message: "Error when fetch wallet transaction"
                          )
                        );
                      }
                    });
                  }),
                  child: Container(
                    width: 70,
                    height: 50,
                    color: Colors.transparent,
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Ionicons.caret_forward,
                        color: textColor2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: accentColors[6],
            onRefresh: () async {
              Log.info(message: "🔃 Refresh wallet");

              await _fetchTransactionWallet(
                fetchDate: _currentDate,
                force: true,
              ).onError((error, stackTrace) {
                Log.error(
                  message: "Error when refresh wallet for ${Globals.dfMMMMyyyy.formatLocal(_currentDate)}",
                  error: error,
                  stackTrace: stackTrace,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    createSnackBar(
                      message: "Error when fetch wallet transaction"
                    )
                  );
                }
              },);
            },
            child: _generateTransactionListview(),
          ),
        ),
      ],
    );
  }

  Widget _generateTransactionListview() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: _list.length,
      itemBuilder: (context, index) {
        // check whether the type is header or item
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
                const SizedBox(width: 5,),
                Text(
                  "(${Globals.fCCY.format(header.income)})",
                  style: TextStyle(color: accentColors[6])
                ),
              ],
            ),
          );
        }
        else if(_list[index].type == WalletListType.item) {
          // this is item
          TransactionListModel txn = _list[index].data as TransactionListModel;

          return Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.20,
              children: <Widget>[
                SlideButton(
                  icon: Ionicons.trash,
                  iconColor: textColor,
                  bgColor: accentColors[2],
                  text: 'Delete',
                  onTap: () {
                    late Future<bool?> result = ShowMyDialog(
                      dialogTitle: "Delete Item",
                      dialogText: "Do you want to delete ${txn.name}?",
                      confirmText: "Delete",
                      confirmColor: accentColors[2],
                      cancelText: "Cancel"
                    ).show(context);

                    // check the result of the dialog box
                    result.then((value) async {
                      if (value == true) {
                        try {
                          // first delete the transaction
                          await _deleteTransaction(txn);
                          
                          // rebuild widget after finished
                          await _setTransactions(_transactions);
                        }
                        catch(error, stackTrace) {
                          Log.error(
                            message: "Error when delete transaction",
                            error: error,
                            stackTrace: stackTrace,
                          );
                        }
                      }
                    });
                  },
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, '/transaction/edit', arguments: txn).then((value) async {
                  // check if we got return
                  if (value != null) {
                    // convert value to the transaction list model
                    TransactionListModel updateTxn = value as TransactionListModel;
                    await _updateTransactions(updateTxn);
                  }
                });
              },
              child:  _generateItemList(txn),
            ),
          );
        }
        else {
          // if not header or item return as sized box shrink.
          return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _updateTransactions(TransactionListModel updateTxn) async {
    // check on the _transactions list for this transaction and
    // replace or remove it
    for(int i=0; i<_transactions.length; i++) {
      // check whether this is the same id or not?
      if (updateTxn.id == _transactions[i].id) {
        // same ID, check if all the information still the same
        // or not?
        if (updateTxn.wallet.id == _transactions[i].wallet.id) {
          // still the same, check if the walletTo is not null
          if (updateTxn.walletTo != null && _transactions[i].walletTo != null) {
            // both not null, means that we can check if the ID
            // for this transaction still the same or not?
            if (updateTxn.walletTo!.id == _transactions[i].walletTo!.id) {
              // update the _wallet
              _updateWalletBalance(false, updateTxn, _transactions[i]);
              
              // all the same means we can just replace this
              // transactions
              _transactions[i] = updateTxn;
            }
            else {
              // update the _wallet
              _updateWalletBalance(true, updateTxn, _transactions[i]);

              // it's different, remove this from the transaction
              // from the list
              _transactions.removeAt(i);
            }
          }
          else {
            // update the _wallet
            _updateWalletBalance(false, updateTxn, _transactions[i]);
            
            // same wallet, we can update the transaction list
            _transactions[i] = updateTxn;
          }
        }
        else {
          // update the _wallet
          _updateWalletBalance(true, updateTxn, _transactions[i]);

          // the wallet is change, so we can just remove this
          // from the transactions list
          _transactions.removeAt(i);
        }

        // exit from this for loop
        break;
      }
    }

    // rebuild the transaction
    await _setTransactions(_transactions);
  }

  void _updateWalletBalance(bool isRemove, TransactionListModel updateTxn, TransactionListModel currentTxn) {
    double newChangeBalance = _wallet.changeBalance;

    if (isRemove) {
      // check the transaction type
      switch(updateTxn.type.toLowerCase()) {
         case 'expense':
            // if this is expense, then add the transaction amount back to the
            // wallet
            newChangeBalance += updateTxn.amount;
            break;
         case 'income':
            // if this is income, then remove the transaction amount from the
            // walle
            newChangeBalance -= updateTxn.amount;
            break;
         case 'transfer':
            // for transfer check whether we are wallet from or to?
            if (updateTxn.wallet.id == _wallet.id) {
               // this is wallet from, means we can add back the amount back to
               // the wallet
               newChangeBalance += updateTxn.amount;
            }
            else {
               // this is wallet to, means we need to remove the amount from this
               // wallet
               newChangeBalance -= updateTxn.amount;
            }
            break;
         default:
            // nothing to do
            break;
      }
    }
    else {
      // check the transaction type
      switch(updateTxn.type.toLowerCase()) {
         case 'expense':
         case 'income':
            // for the same transaction we can just calculate the difference between
            // current and update transaction, then add on the new change balance.
            newChangeBalance += (currentTxn.amount - updateTxn.amount);
            break;
         case 'transfer':
            // first return back the amount to the wallet
            newChangeBalance += currentTxn.amount;

            // for transfer check whether we are wallet from or to?
            if (updateTxn.wallet.id == _wallet.id) {
               // this is wallet from, means we can add back the amount back to
               // the wallet
               newChangeBalance += updateTxn.amount;
            }
            else {
               // this is wallet to, means we need to remove the amount from this
               // wallet
               newChangeBalance -= updateTxn.amount;
            }
            break;
         default:
            // nothing to do
            break;
      }
    }

    // recreate the wallet
    _wallet = WalletModel(
      _wallet.id,
      _wallet.name,
      _wallet.startBalance,
      newChangeBalance,
      _wallet.futureAmount,
      _wallet.useForStats,
      _wallet.enabled,
      _wallet.walletType,
      _wallet.currency,
      _wallet.userPermissionUsers
    );
  }

  Widget _generateItemList(TransactionListModel txn) {
    switch (txn.type.toLowerCase()) {
      case "expense":
        return MyItemList(
          height: 70,
          iconColor: IconColorList.getExpenseColor(txn.category!.name),
          icon: IconColorList.getExpenseIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: "(${txn.wallet.name}) ${(txn.category!.name)}",
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[2],
        );
      case "income":
        return MyItemList(
          height: 70,
          iconColor: IconColorList.getIncomeColor(txn.category!.name),
          icon: IconColorList.getIncomeIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: "(${txn.wallet.name}) ${(txn.category!.name)}",
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[6],
        );
      case "transfer":
        return MyItemList(
          height: 70,
          iconColor: accentColors[4],
          icon: const Icon(
            Ionicons.repeat,
            color: textColor,
          ),
          type: txn.type.toLowerCase(),
          title: '-',
          subTitle: "${txn.wallet.name} > ${txn.walletTo!.name}",
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[4],
          symbolTo: txn.walletTo!.symbol,
          amountTo: (txn.amount * txn.exchangeRate),
        );
      default:
        return MyItemList(
          height: 70,
          iconColor: IconColorList.getExpenseColor(txn.category!.name),
          icon: IconColorList.getExpenseIcon((txn.category!.name)),
          type: txn.type.toLowerCase(),
          title: txn.name,
          subTitle: "(${txn.wallet.name}) ${(txn.category!.name)}",
          symbol: txn.wallet.symbol,
          amount: txn.amount,
          amountColor: accentColors[2],
        );
    }
  }

  void _setDate(DateTime newDate) {
    setState(() {
      _currentDate = newDate;
    });
  }

  Future<bool> _fetchInitData() async {
    await Future.wait([
      _fetchTransactionWallet(
        fetchDate: _currentDate,
        force: true,
        showLoader: false,
      ),
      _fetchWalletMinMaxDate(),
    ]);

    return true;
  }

  Future<void> _deleteTransaction(TransactionListModel txnDeleted) async {
    // show loading screen
    LoadingScreen.instance().show(context: context);

    await _transactionHttp.deleteTransaction(txn: txnDeleted).then((_) async {
      // get the current transaction date showed on the home list
      DateTime currentListTxnDate = (TransactionSharedPreferences.getTransactionListCurrentDate() ?? DateTime.now());

      // here we will need to remove the transaction from the list
      for(int i=0; i<_transactions.length; i++) {
        // check if the id is match
        if (_transactions[i].id == txnDeleted.id) {
          // remove the transaction
          _transactions.removeAt(i);
          // quit from the loop
          break;
        }
      }

      // once removed then we can add back the amount to the wallet
      double newChangeBalance = _wallet.changeBalance;
      if (txnDeleted.type == 'expense') {
        // add the txn delete amount back to the wallet amount
        newChangeBalance += txnDeleted.amount;
      }
      else if (txnDeleted.type == 'income') {
        // remove the txn delete amount from the wallet amount
        newChangeBalance -= txnDeleted.amount;
      }
      else {
        // this is transfer, check if we are sender or receiver?
        if (txnDeleted.wallet.id == _wallet.id) {
          // this is sender, it means we will need to credited back the amount
          // back to the wallet
          newChangeBalance += txnDeleted.amount;
        }
        else {
          // this is receiver, it means we will need to subtract back the amount
          // from the wallet
          newChangeBalance -= txnDeleted.amount;
        }
      }

      // recreate the wallet
      _wallet = WalletModel(
        _wallet.id,
        _wallet.name,
        _wallet.startBalance,
        newChangeBalance,
        _wallet.futureAmount,
        _wallet.useForStats,
        _wallet.enabled,
        _wallet.walletType,
        _wallet.currency,
        _wallet.userPermissionUsers
      );

      // check if the same date or not with the transaction date that we just
      // delete
      if (currentListTxnDate.isSameDate(date: txnDeleted.date)) {
        if (mounted) {
          // pop the transaction from the provider
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).popTransactionList(transaction: txnDeleted);

          // get the current transaction on the provider
          List<TransactionListModel> txnListModel = Provider.of<HomeProvider>(context, listen: false).transactionList;
          // save the current transaction on the provider to the shared preferences
          String date = Globals.dfyyyyMMdd.formatLocal(txnDeleted.date);
          TransactionSharedPreferences.setTransaction(date: date, txn: txnListModel);
        }
      }

      // update information for txn delete
      await _updateInformation(txnDeleted);
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when delete",
        error: error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        // show scaffold showing error
        ScaffoldMessenger.of(context).showSnackBar(createSnackBar(message: "Error when delete ${txnDeleted.name}"));
      }
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    },);
  }

  Future<void> _updateInformation(TransactionListModel txnInfo) async {
    String refreshDay = Globals.dfyyyyMMdd.format(
      DateTime(txnInfo.date.toLocal().year, txnInfo.date.toLocal().month, 1)
    );
    DateTime from;
    DateTime to;
    String fromString;
    String toString;
    int txnCurrencyId = txnInfo.wallet.currencyId;

    // get the from and to date
    (from, to) = TransactionSharedPreferences.getStatDate();

    // format the from and to string
    fromString = Globals.dfyyyyMMdd.formatLocal(from);
    toString = Globals.dfyyyyMMdd.formatLocal(to);

    // delete the transaction from wallet transaction
    await TransactionSharedPreferences.deleteTransactionWallet(
      walletId: txnInfo.wallet.id,
      date: refreshDay,
      txn: txnInfo
    );

    if (txnInfo.walletTo != null) {
      await TransactionSharedPreferences.deleteTransactionWallet(
        walletId: txnInfo.walletTo!.id,
        date: refreshDay,
        txn: txnInfo
      );
    }

    // delete the transaction from budget
    await WalletSharedPreferences.deleteWalletWorth(txn: txnInfo);

    await Future.wait([
      _futureWallets = _walletHTTP.fetchWallets(
        showDisabled: true,
        force: true
      ),
      _futureBudgets = _budgetHTTP.fetchBudgetDate(
        currencyID: txnCurrencyId,
        date: refreshDay
      ),
    ]).then((_) {
      // update the wallets
      _futureWallets.then((wallets) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setWalletList(wallets: wallets);
        }
      });

      // store the budgets list
      if(txnInfo.type == "expense") {
        _futureBudgets.then((value) {
          _budgets = value;
          // now loops thru budget, and see if the current category fits or not?
          for (int i = 0; i < _budgets.length; i++) {
            if (txnInfo.category!.id == _budgets[i].category.id) {
              // as this is expense, subtract total transaction and the amount
              BudgetModel newBudget = BudgetModel(
                  id: _budgets[i].id,
                  category: _budgets[i].category,
                  totalTransaction: (_budgets[i].totalTransaction - 1),
                  amount: _budgets[i].amount,
                  used: _budgets[i].used - txnInfo.amount,
                  status: _budgets[i].status,
                  currency: _budgets[i].currency);
              _budgets[i] = newBudget;
              // break from for loop
              break;
            }
          }
          // now we can set the shared preferences of budget
          BudgetSharedPreferences.setBudget(
            ccyId: txnCurrencyId,
            date: refreshDay,
            budgets: _budgets
          );

          // only set the provider if only the current budget date is the same as the refresh day
          String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
          if(currentBudgetDate == refreshDay && mounted) {
            Provider.of<HomeProvider>(
              context,
              listen: false
            ).setBudgetList(budgets: _budgets);
          }
        });
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on update information",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception(error.toString());
    });

    if (
        (txnInfo.date.isWithin(from: from, to: to)) &&
        (txnInfo.type == 'expense' || txnInfo.type == 'income')
      ) {
      await _transactionHttp.fetchIncomeExpense(
        ccyId: txnCurrencyId,
        from: from,
        to: to,
        force: true
      ).then((result) {
        if (mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setIncomeExpense(ccyId: txnCurrencyId, data: result);
        }
      }).onError((error, stackTrace) {
        Log.error(
          message: "Error on update information",
          error: error,
          stackTrace: stackTrace,
        );
        throw Exception(error.toString());
      });

      // refresh top transaction
      // fetch the top transaction
      await _transactionHttp.fetchTransactionTop(
        type: txnInfo.type,
        ccy: txnCurrencyId,
        from: fromString,
        to: toString,
        force: true
      ).then((transactionTop) {
        if (mounted) {
          // set the provide for this
          Provider.of<HomeProvider>(context, listen: false).setTopTransaction(
            ccy: txnCurrencyId,
            type: txnInfo.type,
            data: transactionTop
          );
        }
      }).onError((error, stackTrace) {
        Log.error(
          message: "Error on update information",
          error: error,
          stackTrace: stackTrace,
        );
        throw Exception(error.toString());
      },);
    }
  }
}