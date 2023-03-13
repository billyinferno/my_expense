import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/category_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/pages/transaction/transaction_edit.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/anim/page_transition.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_category.dart';
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
  String _categoryId = "";
  String _type = "name";
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
  Map<String, List<TransactionListModel>> _summaryExpense = {};
  Map<String, double> _totalAmountIncome = {};
  Map<String, double> _totalAmountExpense = {};
  List<Widget> _summaryList = [];

  Map<int, CategoryModel> _categorySelected = {};
  Map<int, CategoryModel> _categoryExpenseList = {};
  Map<int, CategoryModel> _categoryIncomeList = {};
  Map<int, CategoryModel> _categoryList = {};

  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  ScrollController _scrollControllerSummary = ScrollController();
  ScrollController _scrollControllerIncome = ScrollController();
  ScrollController _scrollControllerExpense = ScrollController();
  ScrollController _scrollControllerTransfer = ScrollController();


  @override
  void initState() {
    // get the category expense and income list from shared preferences
    _categoryExpenseList = CategorySharedPreferences.getCategory('expense');
    _categoryIncomeList = CategorySharedPreferences.getCategory('income');

    // generate category list
    _categoryExpenseList.forEach((key, value) {
      _categoryList[key] = value;
    });

    _categoryIncomeList.forEach((key, value) {
      _categoryList[key] = value;
    });

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
                          case 0: _type = "name"; break;
                          case 1: _type = "category"; break;
                          case 2: _type = "both"; break;
                        }
                      });
                    },
                    groupValue: _sliding,
                    children: {
                      0: Text(
                        "Name",
                        style: TextStyle(
                          fontFamily: '--apple-system'
                        ),
                      ),
                      1: Text(
                        "Category",
                        style: TextStyle(
                          fontFamily: '--apple-system'
                        ),
                      ),
                      2: Text(
                        "Both",
                        style: TextStyle(
                          fontFamily: '--apple-system'
                        ),
                      ),
                    },
                  ),
                ),
                SizedBox(height: 10,),
                _showSearchOrSelectionWidget(),
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
          child: ListView.builder(
            controller: _scrollControllerSummary,
            itemCount: _summaryList.length,
            itemBuilder: ((context, index) {
              return _summaryList[index];
            })
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

  Widget _categoryIcon({required String type, required String name, double? height, double? width, double? size}) {
    if(type == "expense") {
      return Container(
        height: (height ?? 40),
        width: (width ?? 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((height ?? 40)),
          color: IconColorList.getExpenseColor(name),
        ),
        child: IconColorList.getExpenseIcon(name, size),
      );
    }
    else if(type == "income") {
      return Container(
        height: (height ?? 40),
        width: (width ?? 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((height ?? 40)),
          color: IconColorList.getIncomeColor(name),
        ),
        child: IconColorList.getIncomeIcon(name, size),
      );
    }
    else {
      return Container(
        height: (height ?? 40),
        width: (width ?? 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((height ?? 40)),
          color: accentColors[4],
        ),
        child: Icon(
          Ionicons.repeat,
          color: textColor,
          size: (size ?? 20),
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
    double amount;
    DateTime? startDate;
    DateTime? endDate;
    int count;

    // clear all the income, expense, and transfer
    _income.clear();
    _expense.clear();
    _transfer.clear();
    _summaryIncome.clear();
    _totalAmountIncome.clear();
    _summaryExpense.clear();
    _totalAmountExpense.clear();

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

          // check if total summary key for this ccy is exists or not?
          if (!_totalAmountIncome.containsKey(_transactions[i].wallet.currency)) {
            _totalAmountIncome[_transactions[i].wallet.currency] = 0;
          }
          _totalAmountIncome[_transactions[i].wallet.currency] = _totalAmountIncome[_transactions[i].wallet.currency]! + _transactions[i].amount;

          _income.add(_transactions[i]);
          break;
        case 'expense':
          // check if summary key exists or not?
          if (!_summaryExpense.containsKey(summaryKey)) {
            _summaryExpense[summaryKey] = [];
          }
          _summaryExpense[summaryKey]!.add(_transactions[i]);

          // check if total summary key for this ccy is exists or not?
          if (!_totalAmountExpense.containsKey(_transactions[i].wallet.currency)) {
            _totalAmountExpense[_transactions[i].wallet.currency] = 0;
          }
          _totalAmountExpense[_transactions[i].wallet.currency] = _totalAmountExpense[_transactions[i].wallet.currency]! + _transactions[i].amount;

          _expense.add(_transactions[i]);
          break;
        case 'transfer':
          _transfer.add(_transactions[i]);
          break;
      }
    }

    // now compute the summary data so we can showed it on the summary page
    // based on the income, and expense
    _summaryList.clear();

    // add the expense bar on the _summaryList
    _summaryList.add(Container(
      padding: const EdgeInsets.all(10),
      child: Text(
        "Expense",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: accentColors[2],
        ),
      ),
    ));

    _totalAmountExpense.forEach((key, value) {
      _summaryList.add(
        Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "Total " + key,
                style: TextStyle(
                  color: accentColors[2],
                ),
              ),
              const SizedBox(width: 10,),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    fCCY.format(value),
                    style: TextStyle(
                      color: accentColors[2],
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      );
    });

    // loop thru all the expense data
    _summaryExpense.forEach((key, value) {
      // compute the amount
      amount = 0;
      startDate = null;
      endDate = null;
      count = 0;

      value.forEach((data) {
        if (startDate == null) {
          startDate = data.date;
        }
        else {
          if(startDate!.isAfter(data.date)) {
            startDate = data.date;
          }
        }
        
        if (endDate == null) {
          endDate = data.date;
        }
        else {
          if(endDate!.isAfter(data.date)) {
            endDate = data.date;
          }
        }

        amount += data.amount;
        count++;
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

      _summaryList.add(_createSummaryItem(txn: txn, startDate: startDate!, endDate: endDate!, count: count));
    });

    // add the income bar on the _summaryList
    _summaryList.add(Container(
      padding: const EdgeInsets.all(10),
      child: Text(
        "Income",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: accentColors[6],
        ),
      ),
    ));
    
    _totalAmountIncome.forEach((key, value) {
      _summaryList.add(
        Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "Total " + key,
                style: TextStyle(
                  color: accentColors[0],
                ),
              ),
              const SizedBox(width: 10,),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    fCCY.format(value),
                    style: TextStyle(
                      color: accentColors[0],
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      );
    });

    _summaryIncome.forEach((key, value) {
      // compute the amount
      amount = 0;
      startDate = null;
      endDate = null;
      count = 0;

      value.forEach((data) {
        if (startDate == null) {
          startDate = data.date;
        }
        else {
          if(startDate!.isAfter(data.date)) {
            startDate = data.date;
          }
        }
        
        if (endDate == null) {
          endDate = data.date;
        }
        else {
          if(endDate!.isAfter(data.date)) {
            endDate = data.date;
          }
        }

        amount += data.amount;
        count++;
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

      _summaryList.add(_createSummaryItem(txn: txn, startDate: startDate!, endDate: endDate!, count: count));
    });
  }

  Widget _createSummaryItem({required TransactionListModel txn, required DateTime startDate, required DateTime endDate, required int count}){
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _categoryIcon(name: txn.category!.name, type: txn.type),
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
                  DateFormat('dd/MM/yyyy').format(startDate.toLocal()) + " - " + DateFormat('dd/MM/yyyy').format(endDate.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
                Text(
                  (txn.category != null ? txn.category!.name : ''),
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 5,),
                Text(
                  count.toString() + " time(s)",
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
    );
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
            _categoryIcon(name: txn.category!.name, type: txn.type),
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

  Future <void> _findTransaction(String searchText, String categoryId, String type, int limit, int start) async {
    await transactionHttp.findTransaction(type, searchText, categoryId, limit, start).then((results) {
      setTransactions(results, limit, start);
    }).onError((error, stackTrace) {
      debugPrint("error on <_findTransaction>");
      debugPrint(error.toString());
      throw new Exception("Error when searching transaction");
    });
  }

  Future <void> _submitSearch() async {
    // generate the _categoryId based on the list of the category selected
    _categoryId = '';
    _categorySelected.forEach((key, value) {
      // if not the first one, then add ,
      if (_categoryId.isNotEmpty) {
        _categoryId = _categoryId + ',';
      }
      _categoryId = _categoryId + key.toString();
    });

    // now check if this is name, category, or both
    // all will have different kind of checking
    if (_type == "name" || _type == "both") {
      if (_searchController.text.isNotEmpty) {
        // set the search text as current search controller text
        _searchText = _searchController.text;
        _searchText = _searchText.trim();

        // ensure the searchText is more than 3
        if (_searchText.length < 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            createSnackBar(
              message: "Minimum text search is 3 character",
            )
          );
          return;
        }
      }
    }

    if (_type == "category" || _type == "both") {
      if (_categoryId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Please select category",
          )
        );
        return;
      }
    }

    // show the loader dialog
    showLoaderDialog(context);

    // initialize all the value
    _start = 0; // always start from 0
    _transactions.clear();
    _transactions = [];

    // try to find the transaction
    await _findTransaction(_searchText, _categoryId, _type, _limit, _start).then((_) {
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
  
  Widget _showSearchOrSelectionWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        (
          (_sliding == 0 || _sliding == 2) ?
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
          ) : const SizedBox.shrink()
        ),
        (_sliding == 2 ? const SizedBox(height: 10,) : const SizedBox.shrink()),
        (
          (_sliding == 1 || _sliding == 2) ?
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: (() {
                        _showCategorySelectionDialog();
                      }),
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: primaryDark,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: secondaryBackground,
                            style: BorderStyle.solid,
                            width: 1.0,
                          )
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(width: 10,),
                            Icon(
                              Ionicons.add,
                              size: 20,
                              color: textColor,
                            ),
                            const SizedBox(width: 10,),
                            Expanded(
                              child: Center(
                                child: Text(
                                  "Add",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold
                                  ),
                                )
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: (() {
                        setState(() {                      
                          _categorySelected.clear();
                        });
                      }),
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: primaryDark,
                          border: Border.all(
                            color: secondaryBackground,
                            style: BorderStyle.solid,
                            width: 1.0,
                          )
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(width: 10,),
                            Icon(
                              Ionicons.trash,
                              size: 20,
                              color: textColor,
                            ),
                            const SizedBox(width: 10,),
                            Expanded(
                              child: Center(
                                child: Text(
                                  "Clear",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold
                                  ),
                                )
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: (() async {
                        await _submitSearch();
                      }),
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: primaryDark,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: secondaryBackground,
                            style: BorderStyle.solid,
                            width: 1.0,
                          )
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(width: 10,),
                            Icon(
                              Ionicons.search,
                              size: 20,
                              color: textColor,
                            ),
                            const SizedBox(width: 10,),
                            Expanded(
                              child: Center(
                                child: Text(
                                  "Search",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold
                                  ),
                                )
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: _generateChipCategory(),
              ),
            ],
          ) : const SizedBox.shrink()
        ),
      ],
    );
  }

  void _showCategorySelectionDialog() {
    showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
      return Container(
        height: 300,
        color: secondaryDark,
        child: Column(
          children: <Widget>[
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(child: Text("Category Tab")),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10,),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                children: _generateIconCategory(),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _generateIconCategory() {
    List<Widget> _ret = [];

    // loop thru all the _currentCategoryList, and generate the category icon
    _categoryList.forEach((key, value) {
      _ret.add(_iconCategory(value));
    });

    return _ret;
  }

  Widget _iconCategory(CategoryModel category) {
    // check if this is expense or income
    Color _iconColor;
    Icon _icon;

    if(category.type.toLowerCase() == "expense") {
      _iconColor = IconColorList.getExpenseColor(category.name.toLowerCase());
      _icon = IconColorList.getExpenseIcon(category.name.toLowerCase());
    } else {
      _iconColor = IconColorList.getIncomeColor(category.name.toLowerCase());
      _icon = IconColorList.getIncomeIcon(category.name.toLowerCase());
    }

    return GestureDetector(
      onTap: () {
        //print("Select category");
        // check if category still less than 10
        if (_categorySelected.length < 10) {
          setState(() {
            _categorySelected[category.id] = category;
          });
          Navigator.pop(context);
        }
        else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(createSnackBar(message: "Maximum selected category is 10"));
        }
      },
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: _iconColor,
                  border: Border.all(
                    color: (_categorySelected.containsKey(category.id) ? accentColors[4] : Colors.transparent),
                    width: 2.0,
                    style: BorderStyle.solid,
                  )
                ),
                child: _icon,
              ),
            ),
            const SizedBox(height: 10,),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor,
                      ),
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateChipCategory() {
    List<Widget> result = [];

    // loop thru the category selected
    _categorySelected.forEach((key, value) {
      result.add(
        InkWell(
          onTap: (() {
            // remove this chip from the _categorySelected
            setState(() {            
              _categorySelected.remove(key);
            });
          }),
          child: Chip(
            avatar: _categoryIcon(type: value.type, name: value.name, height: 20, width: 20, size: 15),
            label: Text(value.name),
            backgroundColor: (value.type == 'expense' ? IconColorList.getExpenseColor(value.name) : IconColorList.getIncomeColor(value.name)),
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          ),
        )
      );  
    });

    return result;
  }
}
