import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_wallet_minmax_date_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/wallet_transaction_class_helper.dart';
import 'package:my_expense/widgets/item/card_face_item.dart';
import 'package:table_calendar/table_calendar.dart';

class WalletTransactionPage extends StatefulWidget {
  final Object? wallet;
  const WalletTransactionPage({ Key? key, required this.wallet }) : super(key: key);

  @override
  _WalletTransactionPageState createState() => _WalletTransactionPageState();
}

class _WalletTransactionPageState extends State<WalletTransactionPage> {
  final fCCY = new NumberFormat("#,##0.00", "en_US");
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final DateFormat _dtDayMonthYear = DateFormat("dd MMM yyyy");
  final DateFormat _dtyyyyMMdd = DateFormat("yyyy-MM-dd");
  final DateFormat _dtMMMMyyyy = DateFormat("MMMM yyyy");

  late ScrollController _scrollController;
  late WalletModel _wallet;
  late TransactionWalletMinMaxDateModel _walletMinMaxDate;

  DateTime _currentDate = DateTime.now();
  double _expenseAmount = 0.0;
  double _incomeAmount = 0.0;
  Map<DateTime, WalletTransactionExpenseIncome> _totalDate = {};
  List<WalletTransactionList> _list = [];
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
          icon: Icon(Ionicons.close_outline, color: textColor),
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
            child: Container(
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
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      Text(
                        (_sortAscending ? "Z" : "A"),
                        style: TextStyle(
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
            return Container(
              child: Column(
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
              ),
            ); 
          }
          else {
            return Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCube(
                    color: accentColors[6],
                    size: 25,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "loading...",
                    style: TextStyle(
                      color: textColor2,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> setTransactions(List<TransactionListModel> transactions) async {
    setState(() {
      double _income = 0.0;
      double _expense = 0.0;

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
      txnList.forEach((txn) {
        currDate = DateTime(txn.date.toLocal().year, txn.date.toLocal().month, txn.date.toLocal().day);
        if (_totalDate.containsKey(currDate)) {
          walletExpenseIncome = _totalDate[currDate]!;
        }
        else {
          walletExpenseIncome = new WalletTransactionExpenseIncome();
          walletExpenseIncome.date = currDate;
        }

        if(txn.type == "income") {
          _income += txn.amount;
          walletExpenseIncome.income += txn.amount;
        }
        if(txn.type == "expense") {
          _expense += (txn.amount * -1);
          walletExpenseIncome.expense += (txn.amount * -1);
        }
        if(txn.type == "transfer") {
          // check whether it's from or to
          if(_wallet.id == txn.wallet.id) {
            _expense += (txn.amount * -1);
            walletExpenseIncome.expense += (txn.amount * -1);
          }
          if(txn.walletTo != null) {
            if(_wallet.id == txn.walletTo!.id) {
              _income += txn.amount * txn.exchangeRate;
              walletExpenseIncome.income += txn.amount * txn.exchangeRate;
            }
          }
        }

        // add this walletExpenseIcon to the _totalDate
        _totalDate[currDate] = walletExpenseIncome;
      });

      // after this we generate the WalletTransactionList
      bool isLoop = false;
      int idx = 0;
      
      // clear before we loop the total date we have
      _list.clear();

      // loop thru the _totalDate
      _totalDate.forEach((key, value) {
        // add the header for this
        WalletTransactionList header = WalletTransactionList();
        header.type = 'header';
        header.data = value;
        _list.add(header);

        // loop thru the transactions that have the same date and add this to the list
        isLoop = true;
        while(idx < txnList.length && isLoop) {
          if (isSameDay(txnList[idx].date.toLocal(), key.toLocal())) {
            // add to the transaction list
            WalletTransactionList data = WalletTransactionList();
            data.type = 'item';
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
      
      _incomeAmount = _income;
      _expenseAmount = _expense;
    });
  }

  Future<void> _fetchTransactionWallet(DateTime fetchDate, [bool? force]) async {
    bool _force = (force ?? false);

    // get the transaction
    String _date = _dtyyyyMMdd.format(DateTime(fetchDate.toLocal().year, fetchDate.toLocal().month, 1));
    await _transactionHttp.fetchTransactionWallet(_wallet.id, _date, _force).then((_txns) async {
      await setTransactions(_txns);
      _transactions = _txns.toList();

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
        SizedBox(height: 10,),
        CardFace(
          wallet: _wallet,
          minMaxDate: _walletMinMaxDate,
        ),
        SizedBox(height: 10,),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
            color: secondaryDark,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: (() async {
                  DateTime _newDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);

                  // fetch the transaction for this date
                  showLoaderDialog(context);

                  await _fetchTransactionWallet(_newDate).then((_) {
                    // remove the loader
                    _setDate(_newDate);
                    Navigator.pop(context);
                  }).onError((error, stackTrace) {
                    debugPrint("Error when fetch wallet for " + _dtMMMMyyyy.format(_newDate.toLocal()));
                    Navigator.pop(context);
                  });
                }),
                child: Container(
                  width: 70,
                  height: 50,
                  color: Colors.transparent,
                  child: Align(
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
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(_dtMMMMyyyy.format(_currentDate.toLocal())),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(text: "(" + fCCY.format(_expenseAmount) + ")", style: TextStyle(color: accentColors[2])),
                            TextSpan(text: " "),
                            TextSpan(text: "(" + fCCY.format(_incomeAmount) + ")", style: TextStyle(color: accentColors[6])),
                          ]
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: (() async {
                  DateTime _newDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);

                  // fetch the transaction for this date
                  showLoaderDialog(context);

                  await _fetchTransactionWallet(_newDate).then((_) {
                    // remove the loader
                    _setDate(_newDate);
                    Navigator.pop(context);
                  }).onError((error, stackTrace) {
                    debugPrint("Error when fetch wallet for " + _dtMMMMyyyy.format(_newDate.toLocal()));
                    Navigator.pop(context);
                  });
                }),
                child: Container(
                  width: 70,
                  height: 50,
                  color: Colors.transparent,
                  child: Align(
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
                debugPrint("Error when refresh wallet for " + _dtMMMMyyyy.format(_currentDate.toLocal()));
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

  Color _getColor(TransactionListModel transaction) {
    if(transaction.type == "expense") {
      return IconColorList.getExpenseColor(transaction.category!.name);
    } else if(transaction.type == "income") {
      return IconColorList.getIncomeColor(transaction.category!.name);
    } else {
      // this is transfer, and this is only have 1 color
      return accentColors[4];
    }
  }

  Icon _getIcon(TransactionListModel transaction) {
    if(transaction.type == "expense") {
      return IconColorList.getExpenseIcon(transaction.category!.name);
    } else if(transaction.type == "income") {
      return IconColorList.getIncomeIcon(transaction.category!.name);
    } else {
      // this is transfer, and this is only have 1 color
      return Icon(Ionicons.repeat, color: textColor,);
    }
  }

  Widget _getName(TransactionListModel transaction) {
    if(transaction.type == "expense" || transaction.type == "income") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(transaction.name, overflow: TextOverflow.ellipsis,),
          Text(transaction.category!.name + ", " + _dtDayMonthYear.format(transaction.date.toLocal()),
            style: TextStyle(
              fontSize: 12,
              color: textColor2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(transaction.wallet.name + " > " + transaction.walletTo!.name, overflow: TextOverflow.ellipsis,),
          Text(
            _dtDayMonthYear.format(transaction.date.toLocal()),
            style: TextStyle(
              fontSize: 12,
              color: textColor2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
  }

  Widget _getAmount(TransactionListModel transaction) {
    if(transaction.type == "expense" || transaction.type == "income") {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            transaction.wallet.currency + " " + fCCY.format(transaction.amount),
            style: TextStyle(
              color: (transaction.type == "expense" ? accentColors[2] : accentColors[0]),
            ),
          ),
        ],
      );
    }
    else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            transaction.wallet.currency + " " + fCCY.format(transaction.amount),
            style: TextStyle(
              color: accentColors[5],
            ),
            textAlign: TextAlign.right,
          ),
          Text(
            transaction.walletTo!.currency + " " + fCCY.format(transaction.amount * transaction.exchangeRate),
            style: TextStyle(
              color: lighten(accentColors[5], 0.25),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      );
    }
  }

  Widget _generateTransactionListview() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: _list.length,
      itemBuilder: (context, index) {
        // check whether the type is header or item
        if (_list[index].type == 'header') {
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
                  "(" + fCCY.format(header.expense) + ")",
                  style: TextStyle(color: accentColors[2])
                ),
                const SizedBox(width: 5,),
                Text(
                  "(" + fCCY.format(header.income) + ")",
                  style: TextStyle(color: accentColors[6])
                ),
              ],
            ),
          );
        }
        else {
          // this is item
          TransactionListModel txn = _list[index].data as TransactionListModel;
          return Container(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: primaryLight, width: 1.0))
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: _getColor(txn),
                  ),
                  child: _getIcon(txn),
                ),
                SizedBox(width: 10,),
                Expanded(
                  child: Container(
                    child: _getName(txn),
                  )
                ),
                SizedBox(width: 10,),
                _getAmount(txn),
              ],
            ),
          );
        }
      },
    );
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