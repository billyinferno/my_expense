import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:lazy_loading_list/lazy_loading_list.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/pages/transaction/transaction_edit.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/color_utils.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/anim/page_transition.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';

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
  int _limit = 50; // 50 records per fetch
  int _start = 0; // start from 0 page
  int _sliding = 0;
  bool _hasMore = true;

  List<TransactionListModel> _transactions = [];

  TextEditingController _searchController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
    _scrollController.dispose();
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return LazyLoadingList(
                    initialSizeOfItems: _limit,
                    index: index,
                    hasMore: _hasMore,
                    loadMore: (() async {
                      //debugPrint("Load more...");
                      showLoaderDialog(context);
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
                    }),
                    child: _createItem(_transactions[index]),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 30,),
        ],
      ),
    );
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
          setState(() {
            _transactions[i] = txnUpdate;
          });
          break;
        }
      }
    }
  }

  Widget _createItem(TransactionListModel txn){
    return InkWell(
      onTap: (() {
        _showTransactionEditScreen(txn);
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
                  Text(txn.name),
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
    });
  }

  Future <void> _findTransaction(String searchText, String type, int limit, int start) async {
    await transactionHttp.findTransaction(type, searchText, limit, start).then((results) {
      setTransactions(results, limit, start);
      // check if the length is same or equal with limit
      // if not then no more data available on server
      if(results.length < limit) {
        _hasMore = false;
      }
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
        _hasMore = true;

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
