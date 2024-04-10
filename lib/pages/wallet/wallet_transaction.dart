import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_wallet_minmax_date_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/wallet_transaction_class_helper.dart';
import 'package:my_expense/widgets/item/card_face_item.dart';
import 'package:my_expense/widgets/item/item_list.dart';
import 'package:table_calendar/table_calendar.dart';

class WalletTransactionPage extends StatefulWidget {
  final Object? wallet;
  const WalletTransactionPage({ super.key, required this.wallet });

  @override
  State<WalletTransactionPage> createState() => _WalletTransactionPageState();
}

class _WalletTransactionPageState extends State<WalletTransactionPage> {
  final fCCY = NumberFormat("#,##0.00", "en_US");
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final DateFormat _dtDayMonthYear = DateFormat("dd MMM yyyy");
  final DateFormat _dtyyyyMMdd = DateFormat("yyyy-MM-dd");
  final DateFormat _dtMMMMyyyy = DateFormat("MMMM yyyy");

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
      body: FutureBuilder(
        future: _getData,
        builder: (context, snapshopt) {
          if (snapshopt.hasData) {
            return _generateTransactionList();
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

  Future<void> setTransactions(List<TransactionListModel> transactions) async {
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
      
      _incomeAmount = income;
      _expenseAmount = expense;
    });
  }

  Future<void> _fetchTransactionWallet(DateTime fetchDate, [bool? force]) async {
    bool isForce = (force ?? false);

    // get the transaction
    String date = _dtyyyyMMdd.format(DateTime(fetchDate.toLocal().year, fetchDate.toLocal().month, 1));
    await _transactionHttp.fetchTransactionWallet(_wallet.id, date, isForce).then((txns) async {
      await setTransactions(txns);
      _transactions = txns.toList();

    }).onError((error, stackTrace) {
      debugPrint("Error when <_fetchTransactionWallet>");
      debugPrint(error.toString());
    });
  }

  Future<void> _fetchWalletMinMaxDate() async {
    await _transactionHttp.fetchWalletMinMaxDate(_wallet.id).then((walletTxnDate) async {
      _walletMinMaxDate = walletTxnDate;

    }).onError((error, stackTrace) {
      debugPrint("Error when <_fetchWalletMinMaxDate>");
      debugPrint(error.toString());
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
          child: Row(
            children: [
              GestureDetector(
                onTap: (() async {
                  DateTime newDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);

                  // fetch the transaction for this date
                  showLoaderDialog(context);

                  await _fetchTransactionWallet(newDate).then((_) {
                    // remove the loader
                    _setDate(newDate);
                    Navigator.pop(context);
                  }).onError((error, stackTrace) {
                    debugPrint("Error when fetch wallet for ${_dtMMMMyyyy.format(newDate.toLocal())}");
                    Navigator.pop(context);
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
                      Text(_dtMMMMyyyy.format(_currentDate.toLocal())),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(text: "(${fCCY.format(_expenseAmount)})", style: TextStyle(color: accentColors[2])),
                            const TextSpan(text: " "),
                            TextSpan(text: "(${fCCY.format(_incomeAmount)})", style: TextStyle(color: accentColors[6])),
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

                  // fetch the transaction for this date
                  showLoaderDialog(context);

                  await _fetchTransactionWallet(newDate).then((_) {
                    // remove the loader
                    _setDate(newDate);
                    Navigator.pop(context);
                  }).onError((error, stackTrace) {
                    debugPrint("Error when fetch wallet for ${_dtMMMMyyyy.format(newDate.toLocal())}");
                    Navigator.pop(context);
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
        Expanded(
          child: RefreshIndicator(
            color: accentColors[6],
            onRefresh: () async {
              debugPrint("🔃 Refresh wallet");

              // fetch the transaction for this date
              showLoaderDialog(context);

              await _fetchTransactionWallet(_currentDate, true).then((_) {
                Navigator.pop(context);
              }).onError((error, stackTrace) {
                debugPrint("Error when refresh wallet for ${_dtMMMMyyyy.format(_currentDate.toLocal())}");
                Navigator.pop(context);
              });
            },
            child: _generateTransactionListview(),
          ),
        ),
        const SizedBox(height: 30,),
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
                    _dtDayMonthYear.format(header.date.toLocal())
                  ),
                ),
                Text(
                  "(${fCCY.format(header.expense)})",
                  style: TextStyle(color: accentColors[2])
                ),
                const SizedBox(width: 5,),
                Text(
                  "(${fCCY.format(header.income)})",
                  style: TextStyle(color: accentColors[6])
                ),
              ],
            ),
          );
        }
        else if(_list[index].type == WalletListType.item) {
          // this is item
          TransactionListModel txn = _list[index].data as TransactionListModel;

          return GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/transaction/edit', arguments: txn).then((value) async {
                // check if we got return
                if (value != null) {
                  // convert value to the transaction list model
                  TransactionListModel updateTxn = value as TransactionListModel;

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

                      // set i to more than _transactions length, so we will
                      // exit from this for loop
                      i = _transactions.length + 1;
                    }
                  }

                  // rebuild the transaction
                  await setTransactions(_transactions);
                }
              });
            },
            child: _generateItemList(txn),
          );
        }
        else {
          // if not header or item return as sized box shrink.
          return const SizedBox.shrink();
        }
      },
    );
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
        return ItemList(
          type: ItemType.expense,
          name: txn.name,
          walletName: txn.wallet.name,
          walletSymbol: txn.wallet.symbol,
          categoryName: txn.category!.name,
          amount: txn.amount
        );
      case "income":
        return ItemList(
          type: ItemType.income,
          name: txn.name,
          walletName: txn.wallet.name,
          walletSymbol: txn.wallet.symbol,
          categoryName: txn.category!.name,
          amount: txn.amount
        );
      case "transfer":
        return ItemList(
          type: ItemType.transfer,
          walletName: txn.wallet.name,
          walletSymbol: txn.wallet.symbol,
          walletToName: txn.walletTo!.name,
          walletToSymbol: txn.walletTo!.symbol,
          amount: txn.amount,
          exchangeRate: txn.exchangeRate,
        );
      default:
        return ItemList(
          type: ItemType.expense,
          name: txn.name,
          walletName: txn.wallet.name,
          walletSymbol: txn.wallet.symbol,
          categoryName: txn.category!.name,
          amount: txn.amount
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
      _fetchTransactionWallet(_currentDate),
      _fetchWalletMinMaxDate(),
    ]);

    return true;
  }
}