import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/transaction_stats_detail_model.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/stats_transaction_args.dart';
import 'package:my_expense/widgets/chart/budget_bar.dart';

class StatsTransactionPage extends StatefulWidget {
  final Object? args;
  const StatsTransactionPage({ Key? key, required this.args}) : super(key: key);

  @override
  _StatsTransactionPageState createState() => _StatsTransactionPageState();
}

class _StatsTransactionPageState extends State<StatsTransactionPage> {
  final fCCY = new NumberFormat("#,##0.00", "en_US");
  final transactionHttp = TransactionHTTPService();

  bool _isLoading = true;
  ScrollController _scrollController = ScrollController();
  late List<TransactionStatsDetailModel> _transactions;
  late StatsTransactionArgs _args;

  @override
  void initState() {
    super.initState();
    _args = widget.args as StatsTransactionArgs;

    // initialize all default value
    _isLoading = true;
    _transactions = [];

    // now try to fetch the transaction data
    _fetchStatsDetail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(_args.categoryName)),
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
      body: _getBody(),
    );
  }

  Widget _getBody() {
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: secondaryDark,
              border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
            ),
            child: BudgetBar(
              title: _args.categoryName,
              symbol: _args.currency.symbol,
              budgetUsed: (_args.amount < 0 ? _args.amount * (-1) : _args.amount),
              budgetTotal: (_args.total < 0 ? _args.total * (-1) : _args.total),
              barColor: (_args.type == "expense" ? getExpenseColor(_args.categoryName) : getIncomeColor(_args.categoryName)),
              showLeftText: false,
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                itemCount: _transactions.length,
                itemBuilder: (BuildContext ctx, int index) {
                  TransactionStatsDetailModel txn = _transactions[index];
                  return generateListItem(txn);
                },
              ),
            ),
          ),
          SizedBox(height: 25,),
        ],
      );
    }
  }

  Widget generateListItem(TransactionStatsDetailModel txn) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(width: 1.0, color: primaryLight))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            child: (_args.type == "expense" ? getExpenseIcon(txn.categoriesName) : getIncomeIcon(txn.categoriesName)),
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (_args.type == "expense" ? getExpenseColor(txn.categoriesName) : getIncomeColor(txn.categoriesName)),
            ),
            margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
          ),
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
                  "(" + txn.walletName + ") " + DateFormat('dd/MM/yy').format(txn.date.toLocal()),
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _args.currency.symbol + " " + fCCY.format(txn.amount),
                style: TextStyle(
                  color: (_args.type == "expense" ? accentColors[2] : accentColors[6]),
                ),
              ),
            ],
          ),
        ],
      )
    );
  }

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  void setTransactions(List<TransactionStatsDetailModel> transactions) {
    setState(() {
      _transactions = transactions;
    });
  }

  Future<void> _fetchStatsDetail() async {
    await transactionHttp.fetchIncomeExpenseCategoryDetail(
      _args.name,
      _args.search,
      _args.type,
      _args.categoryId,
      _args.currency.id,
      _args.walletId,
      _args.fromDate,
      _args.toDate,
      ).then((result) {
      //result.forEach((element) {debugPrint(element.toJson().toString());});
      //debugPrint(_args.fromDate.toString());
      setTransactions(result);
      setLoading(false);
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchStatsDetail>");
      debugPrint(error.toString());
      setLoading(false);
    });
  }
}