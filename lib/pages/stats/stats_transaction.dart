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
  const StatsTransactionPage({ super.key, required this.args});

  @override
  State<StatsTransactionPage> createState() => _StatsTransactionPageState();
}

class _StatsTransactionPageState extends State<StatsTransactionPage> {
  final _fCCY = NumberFormat("#,##0.00", "en_US");
  final _transactionHttp = TransactionHTTPService();

  final ScrollController _scrollController = ScrollController();
  late List<TransactionStatsDetailModel> _transactions;
  late StatsTransactionArgs _args;
  late Future<bool> _getData;

  @override
  void initState() {
    super.initState();
    _args = widget.args as StatsTransactionArgs;

    // initialize all default value
    _transactions = [];

    // now try to fetch the transaction data
    _getData = _fetchStatsDetail();
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
          icon: const Icon(
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
    return FutureBuilder(
      future: _getData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: secondaryDark,
                  border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
                ),
                child: BudgetBar(
                  title: _args.categoryName,
                  symbol: _args.currency.symbol,
                  budgetUsed: (_args.amount < 0 ? _args.amount * (-1) : _args.amount),
                  budgetTotal: (_args.total < 0 ? _args.total * (-1) : _args.total),
                  barColor: (_args.type == "expense" ? IconColorList.getExpenseColor(_args.categoryName) : IconColorList.getIncomeColor(_args.categoryName)),
                  showLeftText: false,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    itemCount: _transactions.length,
                    itemBuilder: (BuildContext ctx, int index) {
                      TransactionStatsDetailModel txn = _transactions[index];
                      return _generateListItem(txn);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 25,),
            ],
          ); 
        }
        else if (snapshot.hasError) {
          return const Center(child: Text("Error when get statistic information"),);
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

  Widget _generateListItem(TransactionStatsDetailModel txn) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1.0,
            color: primaryLight
          )
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: (_args.type == "expense" ? IconColorList.getExpenseColor(txn.categoriesName) : IconColorList.getIncomeColor(txn.categoriesName)),
            ),
            margin: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            child: (_args.type == "expense" ? IconColorList.getExpenseIcon(txn.categoriesName) : IconColorList.getIncomeIcon(txn.categoriesName)),
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
                  "(${txn.walletName}) ${DateFormat('dd/MM/yy').format(txn.date.toLocal())}",
                  style: const TextStyle(
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
            children: <Widget>[
              Text(
                "${_args.currency.symbol} ${_fCCY.format(txn.amount)}",
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

  Future<bool> _fetchStatsDetail() async {
    await _transactionHttp.fetchIncomeExpenseCategoryDetail(
      _args.name,
      _args.search,
      _args.type,
      _args.categoryId,
      _args.currency.id,
      _args.walletId,
      _args.fromDate,
      _args.toDate,
    ).then((result) {
      _transactions = result;
    }).onError((error, stackTrace) {
      debugPrint("Error on <_fetchStatsDetail>");
      debugPrint(error.toString());
      throw Exception("Error when fetching statistic");
    });

    return true;
  }
}