import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/model/income_expense_category_model.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/stats_detail_args.dart';
import 'package:my_expense/utils/args/stats_transaction_args.dart';
import 'package:my_expense/widgets/chart/budget_bar.dart';
import 'package:my_expense/widgets/pie_chart/my_pie_chart.dart';

class StatsDetailPage extends StatefulWidget {
  final Object? args;
  const StatsDetailPage({ Key? key, required this.args }) : super(key: key);

  @override
  _StatsDetailPageState createState() => _StatsDetailPageState();
}

class _StatsDetailPageState extends State<StatsDetailPage> {
  late StatsDetailArgs _stats;
  final fCCY = new NumberFormat("#,##0.00", "en_US");
  double _maxExpense = 0.0;
  double _maxIncome = 0.0;

  PageController _pageController = PageController();
  ScrollController _incomeController = ScrollController();
  ScrollController _expenseController = ScrollController();

  @override
  void initState() {
    super.initState();
    _stats = widget.args as StatsDetailArgs;
    _getMaxAmount();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    _incomeController.dispose();
    _expenseController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(_getAppBarTitle())),
        leading: IconButton(
          icon: Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            Navigator.pop(context);
          }),
        ),
        actions: <Widget>[
          // make the title to still center even without any action buttons
          Container(width: 50, color: Colors.transparent,),
        ],
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: secondaryDark,
                border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
              ),
              child: Center(child: Text(_getTitleText())),
            ),
            _generatePieChart(),
            SizedBox(height: 10,),
            Container(
              child: Expanded(
                child: PageView(
                  controller: _pageController,
                  children:_generatePageView(),
                ),
              ),
            ),
            SizedBox(height: 20,),
          ],
        ),
      ),
    );
  }

  List<Widget> _generatePageView() {
    List<Widget> _page = [];

    if(_stats.incomeExpenseCategory.income.length > 0) {
      _page.add(_generateListView("income", _stats.currency.symbol, _stats.incomeExpenseCategory.income, _incomeController));
    }
    if(_stats.incomeExpenseCategory.expense.length > 0) {
      _page.add(_generateListView("expense", _stats.currency.symbol, _stats.incomeExpenseCategory.expense, _expenseController));
    }

    if(_page.length <= 0) {
      // nothing to add? then showed no data
      _page.add(Container(
        child: Center(child: Text("No Data")),
      ));
    }

    return _page;
  }

  Widget _generateListView(String type, String ccy, List<CategoryStatsModel> data, ScrollController controller) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: controller,
      itemCount: data.length,
      itemBuilder: ((context, index) {
        return Container(
          padding: EdgeInsets.all(10),
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: (() {
                    StatsTransactionArgs _statsTransactionArgs = StatsTransactionArgs(
                      type: type,
                      categoryId: data[index].categoryId,
                      categoryName: data[index].categoryName,
                      currency: _stats.currency,
                      walletId: _stats.wallet.id,
                      fromDate: _stats.fromDate,
                      toDate: _stats.toDate,
                      amount: data[index].amount,
                      total: (type == "expense" ? _maxExpense : _maxIncome),
                      name: _stats.name,
                      search: _stats.search,
                    );

                    // go to stats transaction 
                    Navigator.pushNamed(context, '/stats/detail/transaction', arguments: _statsTransactionArgs);
                  }),
                  child: Container(
                    color: Colors.transparent,
                    child: BudgetBar(
                      title: data[index].categoryName,
                      symbol: ccy,
                      budgetUsed: (data[index].amount < 0 ? (data[index].amount * (-1)) : data[index].amount),
                      budgetTotal: (type == "expense" ? _maxExpense : _maxIncome),
                      icon: (type == "expense" ? getExpenseIcon(data[index].categoryName) : getIncomeIcon(data[index].categoryName)),
                      iconColor: (type == "expense" ? getExpenseColor(data[index].categoryName) : getIncomeColor(data[index].categoryName)),
                      showLeftText: false,
                      barColor: (type == "expense" ? getExpenseColor(data[index].categoryName) : getIncomeColor(data[index].categoryName)),
                    ),
                  ),
                ),
              ),
            ],
          )
        );
      }),
    );
  }

  List<double> _generateDataMap(List<CategoryStatsModel> _data) {
    List<double> _ret = [];
    _data.forEach((dt) {
      _ret.add(dt.amount);
    });

    return _ret;
  }

  List<Color> _generateColor(String type, List<CategoryStatsModel> _data) {
    List<Color> _ret = [];
    if(type == "expense") {
      _data.forEach((dt) {
        _ret.add(getExpenseColor(dt.categoryName));
      });
    }
    else {
      _data.forEach((dt) {
        _ret.add(getIncomeColor(dt.categoryName));
      });
    }

    return _ret;
  }

  Widget _generatePieChart() {
    List<double> _incomeDataMap = _generateDataMap(_stats.incomeExpenseCategory.income);
    List<double> _expenseDataMap = _generateDataMap(_stats.incomeExpenseCategory.expense);

    // check if both data map is empty?
    // if both empty, then we need to showed there are no data for this month
    if(_incomeDataMap.length <= 0 && _expenseDataMap.length <= 0) {
      return Expanded(
        child: Container(
          child: Center(
            child: Text("No data"),
          ),
        ),
      );
    }

    // set the visibility of each chart based on the data
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Visibility(
            visible: (_incomeDataMap.length > 0),
            child: Expanded(
              child: GestureDetector(
                onTap: (() {
                  // go to income pages
                  // income page will always going to be 1
                  changePageViewPostion(0);
                }),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: secondaryBackground, width: 0.5)),
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _createPieChart(
                        dataMap: _incomeDataMap,
                        colorList: _generateColor("income", _stats.incomeExpenseCategory.income),
                      ),
                      SizedBox(height: 5,),
                      Text(
                        "Income",
                        style: TextStyle(
                          color: lightAccentColors[6],
                        ),
                      ),
                      Text(
                        _totalAmount(_stats.currency.symbol, _stats.incomeExpenseCategory.income),
                        style: TextStyle(
                          color: accentColors[6],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: (_expenseDataMap.length > 0),
            child: Expanded(
              child: GestureDetector(
                onTap: (() {
                  // for expense, we need to see whether we have income data or not?
                  // if got income data, then it means that the page will be 2
                  if(_incomeDataMap.length > 0) {
                    changePageViewPostion(1);
                  }
                  else {
                    // we only have expense no income
                    changePageViewPostion(0);
                  }
                }),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: secondaryBackground, width: 0.5)),
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _createPieChart(
                        dataMap: _expenseDataMap,
                        colorList: _generateColor("expense", _stats.incomeExpenseCategory.expense),
                      ),
                      SizedBox(height: 5,),
                      Text(
                        "Expense",
                        style: TextStyle(
                          color: lightAccentColors[2],
                        ),
                      ),
                      Text(
                        _totalAmount(_stats.currency.symbol, _stats.incomeExpenseCategory.expense),
                        style: TextStyle(
                          color: accentColors[2],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _createPieChart({required List<double> dataMap, required List<Color> colorList, double? height, double? width}) {
    double _height = (height ?? 200);
    double _width = (width ?? 200);

    return Container(
      color: Colors.transparent,
      child: SizedBox(
        height: _height,
        width: _width,
        child: Container(
          child: PieChartView(
            backgroundColor: primaryBackground,
            chartAmount: dataMap,
            chartColors: colorList,
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if(_stats.wallet.id < 0) {
      // use currency instead of wallet name
      return _stats.currency.description;
    }
    else {
      // use wallet name
      return _stats.wallet.name;
    }
  }

  String _getTitleText() {
    if(_stats.type == "month") {
      return DateFormat("MMMM yyyy").format(_stats.toDate.toLocal());
    }
    else if(_stats.type == "year") {
      return DateFormat("yyyy").format(_stats.toDate.toLocal());
    }
    else {
      return DateFormat("dd MMM yyyy").format(_stats.fromDate.toLocal()) + " - " + DateFormat("dd MMM yyyy").format(_stats.toDate.toLocal());
    }
  }

  String _totalAmount(String symbol, List<CategoryStatsModel> _data) {
    double _total = 0.0;
    _data.forEach((dt) {
      _total += dt.amount;
    });

    if(_total < 0) {
      _total = _total * (-1);
    }

    // return the formated CCY
    return symbol + " " + fCCY.format(_total);
  }

  void _getMaxAmount() {
    _stats.incomeExpenseCategory.expense.forEach((exp) {
      _maxExpense += exp.amount;
    });
    if(_maxExpense < 0) {
      _maxExpense = _maxExpense * (-1);
    }
    _stats.incomeExpenseCategory.income.forEach((inc) {
      _maxIncome += inc.amount;
    });
  }

  void changePageViewPostion(int whichPage) {
    int itemCount = 0;
    if(_stats.incomeExpenseCategory.income.length > 0) {
      itemCount++;
    }
    if(_stats.incomeExpenseCategory.expense.length > 0) {
      itemCount++;
    }

    // check whether the item count is more than 1
    // because if only 1, what is the purpose for clicking the graph?
    if(itemCount > 1) {
      // get the current page that currently the page view showed
      int currentPage = _pageController.page!.toInt();
      int pageToGo = 0;

      currentPage = currentPage + 1;
      whichPage = whichPage + 1;

      // get the page we will go
      pageToGo = whichPage - currentPage;

      // calculate the number of jump we need to go to the page
      double jumpPosition = MediaQuery.of(context).size.width / 2;
      _pageController.jumpTo(jumpPosition * pageToGo);
    }
  }
}