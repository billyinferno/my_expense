import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/themes/icon_list.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';

class WalletTransactionPage extends StatefulWidget {
  final Object? wallet;
  const WalletTransactionPage({ Key? key, required this.wallet }) : super(key: key);

  @override
  _WalletTransactionPageState createState() => _WalletTransactionPageState();
}

class _WalletTransactionPageState extends State<WalletTransactionPage> {
  final fCCY = new NumberFormat("#,##0.00", "en_US");
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();

  late ScrollController _scrollController;
  late WalletModel _wallet;
  late List<TransactionListModel> _transactions;

  bool _isLoading = true;
  DateTime _currentDate = DateTime.now();
  double _expenseAmount = 0.0;
  double _incomeAmount = 0.0;

  @override
  void initState() {
    super.initState();

    // init the wallet
    _wallet = widget.wallet as WalletModel;

    // fetch the transaction
    _fetchTransactionWallet(_currentDate);

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
          Container(width: 45, color: Colors.transparent,),
        ],
      ),
      body: _generateBody(),
    );
  }

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  void setTransactions(List<TransactionListModel> transactions) {
    double _income = 0.0;
    double _expense = 0.0;

    transactions.forEach((txn) {
      if(txn.type == "income") {
        _income += txn.amount;
      }
      if(txn.type == "expense") {
        _expense += (txn.amount * -1);
      }
      if(txn.type == "transfer") {
        // check whether it's from or to
        if(_wallet.id == txn.wallet.id) {
          _expense += (txn.amount * -1);
        }
        if(txn.walletTo != null) {
          if(_wallet.id == txn.walletTo!.id) {
            _income += txn.amount * txn.exchangeRate;
          }
        }
      }
    });

    setState(() {
      _transactions = transactions;
      _incomeAmount = _income;
      _expenseAmount = _expense;
    });
  }

  Future<void> _fetchTransactionWallet(DateTime fetchDate, [bool? force]) async {
    bool _force = (force ?? false);

    // get the transaction
    String _date = DateFormat("yyyy-MM-dd").format(DateTime(fetchDate.toLocal().year, fetchDate.toLocal().month, 1));
    await _transactionHttp.fetchTransactionWallet(_wallet.id, _date, _force).then((_txns) {
      setTransactions(_txns);
      setLoading(false);
    }).onError((error, stackTrace) {
      debugPrint("Error when <_fetchTransactionWallet>");
      debugPrint(error.toString());
    });
  }

  Widget _generateBody() {
    if(_isLoading) {
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
    else {
      return _generateTransactionList();
    }
  }

  Widget _generateTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 10,),
        Center(
          child: Container(
            height: 150,
            width: 250,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                  colors: <Color>[
                    (_wallet.enabled ? IconList.getColor(_wallet.walletType.type) : secondaryDark),
                    (_wallet.enabled ? lighten(IconList.getDarkColor(_wallet.walletType.type),0.1) : secondaryBackground),
                  ]
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 30,
                        width: 30,
                        child: IconList.getIcon(_wallet.walletType.type),
                      ),
                      SizedBox(width: 10,),
                      Container(
                        child:Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(_wallet.name),
                            Text(
                              _wallet.walletType.type,
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Container(
                  color: Colors.transparent,
                )),
                Container(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _wallet.currency.symbol + " " + fCCY.format(_wallet.startBalance + _wallet.changeBalance),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  // debugPrint("Previous Month");
                  DateTime _newDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);

                  // fetch the transaction for this date
                  showLoaderDialog(context);

                  await _fetchTransactionWallet(_newDate).then((_) {
                    // remove the loader
                    _setDate(_newDate);
                    Navigator.pop(context);
                  }).onError((error, stackTrace) {
                    debugPrint("Error when fetch wallet for " + DateFormat("MMMM yyyy").format(_newDate.toLocal()));
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
                      Text(DateFormat("MMMM yyyy").format(_currentDate.toLocal())),
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
                  // debugPrint("Next Month");
                  DateTime _newDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);

                  // fetch the transaction for this date
                  showLoaderDialog(context);

                  await _fetchTransactionWallet(_newDate).then((_) {
                    // remove the loader
                    _setDate(_newDate);
                    Navigator.pop(context);
                  }).onError((error, stackTrace) {
                    debugPrint("Error when fetch wallet for " + DateFormat("MMMM yyyy").format(_newDate.toLocal()));
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
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.all(10),
            child: RefreshIndicator(
              color: accentColors[6],
              onRefresh: () async {
                debugPrint("🔃 Refresh wallet");

                // fetch the transaction for this date
                showLoaderDialog(context);

                await _fetchTransactionWallet(_currentDate, true).then((_) {
                  Navigator.pop(context);
                }).onError((error, stackTrace) {
                  debugPrint("Error when refresh wallet for " + DateFormat("MMMM yyyy").format(_currentDate.toLocal()));
                  Navigator.pop(context);
                });
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
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
                            color: _getColor(_transactions[index]),
                          ),
                          child: _getIcon(_transactions[index]),
                        ),
                        SizedBox(width: 10,),
                        Expanded(
                          child: Container(
                            child: _getName(_transactions[index]),
                          )
                        ),
                        SizedBox(width: 10,),
                        _getAmount(_transactions[index]),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
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
          Text(transaction.category!.name + ", " + DateFormat("dd MMM yyyy").format(transaction.date.toLocal()),
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
            DateFormat("dd MMM yyyy").format(transaction.date.toLocal()),
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

  void _setDate(DateTime newDate) {
    setState(() {
      _currentDate = newDate;
    });
  }
}