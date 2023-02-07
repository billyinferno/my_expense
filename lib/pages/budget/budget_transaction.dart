import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/budget_transaction_args.dart';
import 'package:my_expense/widgets/chart/budget_bar.dart';

class BudgetTransactionPage extends StatefulWidget {
  final Object? arguments;
  const BudgetTransactionPage({ Key? key, required this.arguments }) : super(key: key);

  @override
  _BudgetTransactionPageState createState() => _BudgetTransactionPageState();
}

class _BudgetTransactionPageState extends State<BudgetTransactionPage> {
  final fCCY = new NumberFormat("#,##0.00", "en_US");
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _categoryId = -1;
  String _categoryName = "";
  String _categorySymbol = "";
  double _budgetUsed = 0.0;
  double _budgetAmount = 0.0;
  int _currencyId = -1;
  bool _isLoading = true;
  List<TransactionListModel> _transactions = [];

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    
    // convert the parameter being sent from main
    BudgetTransactionArgs _args = widget.arguments as BudgetTransactionArgs;
    _selectedDate = _args.selectedDate;
    _categoryId = _args.categoryid;
    _categoryName = _args.categoryName;
    _categorySymbol = _args.categorySymbol;
    _budgetUsed = _args.budgetUsed;
    _budgetAmount = _args.budgetAmount;
    _currencyId = _args.currencyId;

    _fetchBudget(true);

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
        title: Center(child: Text(_categoryName)),
        leading: IconButton(
          icon: Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            // check if got data changed already or not?
            Navigator.maybePop(context);
          }),
        ),
        actions: <Widget>[
          Container(width: 50, color: Colors.transparent,),
        ],
      ),
      body: _createBody(),
    );
  }

  Widget _createBody() {
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
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            color: secondaryDark,
            padding: EdgeInsets.all(10),
            child: BudgetBar(
              title: _categoryName,
              symbol: _categorySymbol,
              budgetUsed: _budgetUsed,
              budgetTotal: _budgetAmount,
            )
          ),
          SizedBox(height: 10,),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              child: RefreshIndicator(
                color: accentColors[6],
                onRefresh: (() async {
                  setLoading(true);
                  await _fetchBudget(true);
                }),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    return _createItem(
                      itemName: _transactions[index].name,
                      itemDate: _transactions[index].date,
                      itemSymbol: _transactions[index].wallet.symbol,
                      itemAmount: _transactions[index].amount,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _createItem({required String itemName, required DateTime itemDate, required String itemSymbol, required double itemAmount}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: IconColorList.getExpenseColor(_categoryName),
            ),
            child: IconColorList.getExpenseIcon(_categoryName),
          ),
          SizedBox(width: 10,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  itemName
                ),
                Text(
                  DateFormat('E, dd MMM yyyy').format(itemDate.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10,),
          Text(
            itemSymbol + " " + fCCY.format(itemAmount),
            style: TextStyle(
              color: textColor2,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void setTransactions(List<TransactionListModel> transactions) {
    setState(() {
      _transactions = transactions;
    });
  }

  void setLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  Future<void> _fetchBudget([bool? force]) async {
    bool _force = (force ?? false);

    String date = DateFormat('yyyy-MM-dd').format(_selectedDate.toLocal());
    await _transactionHttp.fetchTransactionBudget(_categoryId, date, _currencyId, _force).then((value) {
      setTransactions(value);
      setLoading(false);
    }).onError((error, stackTrace) {
      debugPrint("Error when _fetchBudget");
      debugPrint(error.toString());

      // assume there are no data
      setTransactions([]);
      setLoading(false);
    });
  }
}