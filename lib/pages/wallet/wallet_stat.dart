import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/model/wallet_stat_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/widgets/chart/bar.dart';
import 'package:my_expense/widgets/chart/summary_box.dart';

class WalletStatPage extends StatefulWidget {
  final Object? wallet;
  const WalletStatPage({Key? key, required this.wallet}) : super(key: key);

  @override
  State<WalletStatPage> createState() => _WalletStatPageState();
}

class _WalletStatPageState extends State<WalletStatPage> {
  final fCCY = NumberFormat("#,##0.00", "en_US");
  final dt = DateFormat("yyyy-MM");
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  bool _sortAscending = true;
  late WalletModel _wallet;
  late Future<bool> _getData;
  late List<WalletStatModel> _walletStat;
  late List<WalletStatModel> _origWalletStat;
  late double _maxAmount;
  late double _totalIncome;
  late int _countIncome;
  late double _totalExpense;
  late int _countExpense;

  @override
  void initState() {
    // get the wallet data
    _wallet = widget.wallet as WalletModel;

    // init the wallet list into empty list
    _walletStat = [];
    _origWalletStat = [];
    _totalIncome = 0;
    _countIncome = 0;
    _totalExpense = 0;
    _countExpense = 0;

    // get the data from API
    _getData = _getWalletStatData();
    super.initState();
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
            onTap: (() {
              // set the sorting to inverse
              _sortAscending = !_sortAscending;
              _sortWalletStat();
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
      body: _generateBody(),
    );
  }

  Widget _generateBody() {
    return FutureBuilder(
      future: _getData,
      builder: ((context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Icon(
                  Ionicons.warning,
                  color: Colors.red,
                  size: 25,
                ),
              ),
              const SizedBox(height: 5,),
              const Center(
                child: Text("Unable to load data from API"),
              )
            ],
          );
        }
        else if (snapshot.hasData) {
          return _generateBarChart();
        }
        else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  child: Center(
                    child: Text("Load wallet data..."),
                  ),
                ),
              )
            ],
          );
        }
      }),
    );
  }

  Widget _generateBarChart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10,),
          SizedBox(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SummaryBox(
                  color: accentColors[0],
                  text: "Income",
                  value: fCCY.format(_totalIncome),
                  count: _countIncome,
                ),
                const SizedBox(width: 10,),
                SummaryBox(
                  color: accentColors[2],
                  text: "Expense",
                  value: fCCY.format(_totalExpense),
                  count: _countExpense
                ),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _walletStat.length,
              itemBuilder: ((context, index) {
                Color indicator = Colors.white;
                if (_walletStat[index].income! > _walletStat[index].expense!) {
                  indicator = accentColors[0];
                }
                else if (_walletStat[index].income! < _walletStat[index].expense!) {
                  indicator = accentColors[2];
                }

                return Container(
                  width: double.infinity,
                  height: 50,
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      // indicator
                      Container(
                        width: 10,
                        height: 50,
                        decoration: BoxDecoration(
                          color: indicator,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5),
                          )
                        ),
                      ),
                      const SizedBox(width: 5,),
                      // date,
                      SizedBox(
                        width: 70,
                        child: Text(
                          dt.format(_walletStat[index].date),
                        ),
                      ),
                      const SizedBox(width: 5,),
                      // bar chart
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Bar(amount: _walletStat[index].income!, maxAmount: _maxAmount, text: fCCY.format(_walletStat[index].income!), color: accentColors[0]),
                            Bar(amount: _walletStat[index].expense!, maxAmount: _maxAmount, text: fCCY.format(_walletStat[index].expense!), color: accentColors[2]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5,),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _getStatData() {
    // loop thru _walletStat and get the maximum data
    _maxAmount = double.infinity * -1;

    _walletStat.forEach((data) {
      _totalIncome += data.income!;
      _totalExpense += data.expense!;

      if (data.income! > data.expense!) {
        _countIncome += 1;
      }
      else if (data.income! < data.expense!) {
        _countExpense += 1;
      }

      if (data.income! > _maxAmount) {
        _maxAmount = data.income!;
      }
      if (data.expense! > _maxAmount) {
        _maxAmount = data.expense!;
      }
    });
  }

  Future<bool> _getWalletStatData() async {
    try {
      // perform the get company detail information here
      await _walletHTTP.getStat(_wallet.id).then((resp) {
        // copy the response to company detail data
        _walletStat = resp;
        _origWalletStat.addAll(resp);

        // get the statistic data
        _getStatData();
      });
    }
    catch(error) {
      debugPrint(error.toString());
      throw 'Error when try to get the data from server';
    }

    return true;
  }

  void _sortWalletStat() {
    setState(() 
    {
      _walletStat.clear();
      if (_sortAscending) {
        _walletStat.addAll(_origWalletStat.toList());
      }
      else {
        _walletStat.addAll(_origWalletStat.reversed.toList());
      }
    });
  }
}