import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/pages/transaction/transaction_edit.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/anim/page_transition.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
enum PageName { summary, all, income, expense, transfer }

class TransactionSearchPage extends StatefulWidget {
  const TransactionSearchPage({Key? key}) : super(key: key);

  @override
  _TransactionSearchPageState createState() => _TransactionSearchPageState();
}


class _TransactionSearchPageState extends State<TransactionSearchPage> {
  final fCCY = new NumberFormat("#,##0.00", "en_US");
  final TransactionHTTPService transactionHttp = TransactionHTTPService();

  String _searchText = "";
  String _type = "both";
  int _limit = 99999; // make it to 99999 (just fetch everything, IO is not a concern)
  int _start = 0; // start from 0 page
  int _sliding = 0;
  
  int _resultPage = 1;
  PageName _resultPageName = PageName.all;
  Map<PageName, Color> _resultPageColor = {
    PageName.summary: accentColors[1],
    PageName.all: accentColors[3],
    PageName.income: accentColors[6],
    PageName.expense: accentColors[2],
    PageName.transfer: accentColors[4],
  };

  List<TransactionListModel> _transactions = [];
  List<TransactionListModel> _income = [];
  List<TransactionListModel> _expense = [];
  List<TransactionListModel> _transfer = [];
  Map<String, List<TransactionListModel>> _summaryIncome = {};
  List<TransactionListModel> _summaryIncomeList = [];
  Map<String, List<TransactionListModel>> _summaryExpense = {};
  List<TransactionListModel> _summaryExpenseList = [];

  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  ScrollController _scrollControllerSummary = ScrollController();
  ScrollController _scrollControllerIncome = ScrollController();
  ScrollController _scrollControllerExpense = ScrollController();
  ScrollController _scrollControllerTransfer = ScrollController();


  @override
  void initState() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Search")),
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context, false);
          },
          icon: Icon(
            Ionicons.close,
          ),
        ),
        actions: <Widget>[
          Container(width: 45, color: Colors.transparent,),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            color: secondaryDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: CupertinoSlidingSegmentedControl(
                    onValueChanged: (int? value) {
                      setState(() {
                        _sliding = value!;
                        switch(_sliding) {
                          case 0: _type = "both"; break;
                          case 1: _type = "name"; break;
                          case 2: _type = "category"; break;
                        }
                      });
                    },
                    groupValue: _sliding,
                    children: {
                      0: Text(
                        "Both",
                        style: TextStyle(
                          fontFamily: '--apple-system'
                        ),
                      ),
                      1: Text(
                        "Name",
                        style: TextStyle(
                          fontFamily: '--apple-system'
                        ),
                      ),
                      2: Text(
                        "Category",
                        style: TextStyle(
                          fontFamily: '--apple-system'
                        ),
                      ),
                    },
                  ),
                ),
                SizedBox(height: 10,),
                CupertinoSearchTextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: textColor2,
                    fontFamily: '--apple-system'
                  ),
                  suffixIcon: Icon(Ionicons.arrow_forward_circle),
                  onSubmitted: ((_) async {
                    await _submitSearch().then((_) {
                      // remove the focus from the text
                      FocusScopeNode _currentFocus = FocusScope.of(context);
                      if(!_currentFocus.hasPrimaryFocus) {
                        _currentFocus.unfocus();
                      }
                    });
                  }),
                  onSuffixTap: (() async {
                    _submitSearch().then((_) {
                      // remove the focus from the text
                      FocusScopeNode _currentFocus = FocusScope.of(context);
                      if(!_currentFocus.hasPrimaryFocus) {
                        _currentFocus.unfocus();
                      }
                    });
                  }),
                ),
              ],
            ),
          ),
          _getResultPage(),
          const SizedBox(height: 30,),
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
            padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
            child: Center(
              child: CupertinoSlidingSegmentedControl(
                onValueChanged: (int? value) {
                  setState(() {
                    _resultPage = value!;
                    switch(_resultPage) {
                      case 0: _resultPageName = PageName.summary; break;
                      case 1: _resultPageName = PageName.all; break;
                      case 2: _resultPageName = PageName.income; break;
                      case 3: _resultPageName = PageName.expense; break;
                      case 4: _resultPageName = PageName.transfer; break;
                    }
                  });
                },
                groupValue: _resultPage,
                thumbColor: (_resultPageColor[_resultPageName] ?? accentColors[9]),
                children: {
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
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              return _createItem(_transactions[index], true);
            },
          ),
        );
      case PageName.summary:
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: SingleChildScrollView(
            controller: _scrollControllerSummary,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    "Expense",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColors[2],
                    ),
                  ),
                ),
                ...List<Widget>.generate(_summaryExpenseList.length, (index) {
                  return _createItem(_summaryExpenseList[index], false);
                }),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    "Income",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColors[6],
                    ),
                  ),
                ),
                ...List<Widget>.generate(_summaryIncomeList.length, (index) {
                  return _createItem(_summaryIncomeList[index], false);
                }),
              ],
            ),
          ),
        );
      case PageName.income:
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: ListView.builder(
            controller: _scrollControllerIncome,
            itemCount: _income.length,
            itemBuilder: (context, index) {
              return _createItem(_income[index], false);
            },
          ),
        );
      case PageName.expense:
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: ListView.builder(
            controller: _scrollControllerExpense,
            itemCount: _expense.length,
            itemBuilder: (context, index) {
              return _createItem(_expense[index], false);
            },
          ),
        );
      case PageName.transfer:
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: ListView.builder(
            controller: _scrollControllerTransfer,
            itemCount: _transfer.length,
            itemBuilder: (context, index) {
              return _createItem(_transfer[index], false);
            },
          ),
        );
      default:
      // unknown just return SizedBox.shrink();
      return const SizedBox.shrink();
    }
  }

  Widget _categoryIcon(TransactionListModel txn) {
    if(txn.type == "expense") {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: IconColorList.getExpenseColor(txn.category!.name),
        ),
        child: IconColorList.getExpenseIcon(txn.category!.name),
      );
    }
    else if(txn.type == "income") {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: IconColorList.getIncomeColor(txn.category!.name),
        ),
        child: IconColorList.getIncomeIcon(txn.category!.name),
      );
    }
    else {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: accentColors[4],
        ),
        child: Icon(
          Ionicons.repeat,
          color: textColor,
        ),
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

  Future<void> _showTransactionEditScreen(TransactionListModel txn) async {
    // go to the transaction edit for this txn
    final result = await Navigator.push(context, createAnimationRoute(new TransactionEditPage(txn)));
    String resultType = result.runtimeType.toString();
    if(resultType == "TransactionListModel") {
      // convert result to transaction list mode
      TransactionListModel txnUpdate = result as TransactionListModel;
      // update the current transaction list based on the updated transaction
      for(int i=0; i<_transactions.length; i++) {
        // check which transaction is being updated
        if(_transactions[i].id == txnUpdate.id) {
          _transactions[i] = txnUpdate;
          break;
        }
      }

      // after that we will perform grouping of the transactions to income, expense, and transfer
      _groupTransactions();

      setState(() {
        // set state to rebuild the widget
      });
    }
  }

  void _groupTransactions() {
    // clear all the income, expense, and transfer
    _income.clear();
    _expense.clear();
    _transfer.clear();
    _summaryIncome.clear();
    _summaryExpense.clear();

    String summaryKey;

    // loop thru transactions
    for(int i=0; i<_transactions.length; i++) {
      // generate the summary key
      summaryKey = _transactions[i].type.toLowerCase() + "_" + (_transactions[i].category != null ? _transactions[i].category!.name : '') + "_" + _transactions[i].name + "_" + _transactions[i].wallet.currency;

      // check which transaction is being updated
      switch(_transactions[i].type.toLowerCase()) {
        case 'income':
          // check if summary key exists or not?
          if (!_summaryIncome.containsKey(summaryKey)) {
            _summaryIncome[summaryKey] = [];
          }
          _summaryIncome[summaryKey]!.add(_transactions[i]);

          _income.add(_transactions[i]);
          break;
        case 'expense':
          // check if summary key exists or not?
          if (!_summaryExpense.containsKey(summaryKey)) {
            _summaryExpense[summaryKey] = [];
          }
          _summaryExpense[summaryKey]!.add(_transactions[i]);

          _expense.add(_transactions[i]);
          break;
        case 'transfer':
          _transfer.add(_transactions[i]);
          break;
      }
    }

    // now compute the summary data so we can showed it on the summary page
    // based on the income, and expense
    _summaryIncomeList.clear();
    _summaryIncome.forEach((key, value) {
      // compute the amount
      double amount = 0;
      value.forEach((data) {
        amount += data.amount;
      });
      
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
        1
      );

      _summaryIncomeList.add(txn);
    });

    _summaryExpenseList.clear();
    _summaryExpense.forEach((key, value) {
      // compute the amount
      double amount = 0;
      value.forEach((data) {
        amount += data.amount;
      });
      
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
        1
      );

      _summaryExpenseList.add(txn);
    });
  }

  Widget _createItem(TransactionListModel txn, [bool? canEdit]){
    return InkWell(
      onTap: (() {
        if (canEdit ?? true) {
          _showTransactionEditScreen(txn);
        }
      }),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _categoryIcon(txn),
            SizedBox(width: 10,),
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
                    DateFormat('E, dd MMM yyyy').format(txn.date.toLocal()),
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10,),
            _getAmount(txn),
          ],
        ),
      ),
    );
  }

  void setTransactions(List<TransactionListModel> transactions, int limit, int start) {
    setState(() {
      _transactions.addAll(transactions);
      // set also the start for the next transaction we need to fetch
      _start = start + limit;

      // group the transactions
      _groupTransactions();
    });
  }

  Future <void> _findTransaction(String searchText, String type, int limit, int start) async {
    await transactionHttp.findTransaction(type, searchText, limit, start).then((results) {
      setTransactions(results, limit, start);
    }).onError((error, stackTrace) {
      debugPrint("error on <_findTransaction>");
      debugPrint(error.toString());
      throw new Exception("Error when searching transaction");
    });
  }

  Future <void> _submitSearch() async {
    if(_searchController.text != _searchText) {
      //debugPrint("Search for " + _searchController.text);

      // set the search text as current search controller text
      _searchText = _searchController.text;
      _searchText = _searchText.trim();

      if(_searchText.length >= 3) {
        // show the loader dialog
        showLoaderDialog(context);

        // initialize all the value
        _start = 0; // always start from 0
        _transactions.clear();
        _transactions = [];

        // try to find the transaction
        await _findTransaction(_searchText, _type, _limit, _start).then((_) {
          Navigator.pop(context);
        }).onError((error, stackTrace) {
          Navigator.pop(context);
          // showed error message
          ScaffoldMessenger.of(context).showSnackBar(
            createSnackBar(
              message: "Error when searching transaction",
            )
          );
        });
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Minimum text search is 3 character",
          )
        );
      }
    }
  }
}
