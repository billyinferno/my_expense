import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/model/income_expense_category_model.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/args/stats_detail_args.dart';
import 'package:my_expense/utils/args/stats_transaction_args.dart';
import 'package:my_expense/widgets/chart/budget_bar.dart';
import 'package:my_expense/widgets/chart/pie_chart/my_pie_chart.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class StatsDetailPage extends StatefulWidget {
  final Object? args;
  const StatsDetailPage({ super.key, required this.args });

  @override
  State<StatsDetailPage> createState() => _StatsDetailPageState();
}

class _StatsDetailPageState extends State<StatsDetailPage> {
  late StatsDetailArgs _stats;
  final _fCCY = NumberFormat("#,##0.00", "en_US");
  double _maxExpense = 0.0;
  double _maxIncome = 0.0;

  final PageController _pageController = PageController();
  final ScrollController _incomeController = ScrollController();
  final ScrollController _expenseController = ScrollController();

  late int _totalPage;

  @override
  void initState() {
    super.initState();
    _stats = widget.args as StatsDetailArgs;

    // get the total page we will showed
    _totalPage = 0;
    if(_stats.incomeExpenseCategory.income.isNotEmpty) {
      _totalPage += 1;
    }
    if(_stats.incomeExpenseCategory.expense.isNotEmpty) {
      _totalPage += 1;
    }
    _getMaxAmount();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _incomeController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(_getAppBarTitle())),
        leading: IconButton(
          icon: const Icon(Ionicons.close_outline, color: textColor),
          onPressed: (() {
            Navigator.pop(context);
          }),
        ),
        actions: <Widget>[
          // make the title to still center even without any action buttons
          Container(width: 50, color: Colors.transparent,),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: secondaryDark,
              border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
            ),
            child: Center(child: Text(_getTitleText())),
          ),
          _generatePieChart(),
          const SizedBox(height: 10,),
          Visibility(
            visible: (_totalPage > 0),
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _totalPage,
                effect: const WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  type: WormType.normal,
                  activeDotColor: primaryDark,
                  dotColor: secondaryBackground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10,),
          Expanded(
            child: PageView(
              controller: _pageController,
              children:_generatePageView(),
            ),
          ),
          const SizedBox(height: 20,),
        ],
      ),
    );
  }

  List<Widget> _generatePageView() {
    List<Widget> page = [];

    if(_stats.incomeExpenseCategory.income.isNotEmpty) {
      page.add(_generateListView("income", _stats.currency.symbol, _stats.incomeExpenseCategory.income, _incomeController));
    }
    if(_stats.incomeExpenseCategory.expense.isNotEmpty) {
      page.add(_generateListView("expense", _stats.currency.symbol, _stats.incomeExpenseCategory.expense, _expenseController));
    }

    if(page.isEmpty) {
      // nothing to add? then showed no data
      page.add(const Center(child: Text("No Data")));
    }

    return page;
  }

  Widget _generateListView(String type, String ccy, List<CategoryStatsModel> data, ScrollController controller) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      controller: controller,
      itemCount: data.length,
      itemBuilder: ((context, index) {
        return Container(
          padding: const EdgeInsets.all(10),
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: (() {
                    StatsTransactionArgs statsTransactionArgs = StatsTransactionArgs(
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
                    Navigator.pushNamed(context, '/stats/detail/transaction', arguments: statsTransactionArgs);
                  }),
                  child: Container(
                    color: Colors.transparent,
                    child: BudgetBar(
                      title: data[index].categoryName,
                      symbol: ccy,
                      budgetUsed: (data[index].amount < 0 ? (data[index].amount * (-1)) : data[index].amount),
                      budgetTotal: (type == "expense" ? _maxExpense : _maxIncome),
                      icon: (type == "expense" ? IconColorList.getExpenseIcon(data[index].categoryName) : IconColorList.getIncomeIcon(data[index].categoryName)),
                      iconColor: (type == "expense" ? IconColorList.getExpenseColor(data[index].categoryName) : IconColorList.getIncomeColor(data[index].categoryName)),
                      showLeftText: false,
                      barColor: (type == "expense" ? IconColorList.getExpenseColor(data[index].categoryName) : IconColorList.getIncomeColor(data[index].categoryName)),
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

  List<double> _generateDataMap(List<CategoryStatsModel> data) {
    List<double> ret = [];
    for (CategoryStatsModel dt in data) {
      ret.add(dt.amount);
    }

    return ret;
  }

  List<Color> _generateColor(String type, List<CategoryStatsModel> data) {
    List<Color> ret = [];
    if(type == "expense") {
      for (CategoryStatsModel dt in data) {
        ret.add(IconColorList.getExpenseColor(dt.categoryName));
      }
    }
    else {
      for (CategoryStatsModel dt in data) {
        ret.add(IconColorList.getIncomeColor(dt.categoryName));
      }
    }

    return ret;
  }

  Widget _generatePieChart() {
    List<double> incomeDataMap = _generateDataMap(_stats.incomeExpenseCategory.income);
    List<double> expenseDataMap = _generateDataMap(_stats.incomeExpenseCategory.expense);

    // check if both data map is empty?
    // if both empty, then we need to showed there are no data for this month
    if(incomeDataMap.isEmpty && expenseDataMap.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text("No data"),
        ),
      );
    }

    // set the visibility of each chart based on the data
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: secondaryBackground, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Visibility(
            visible: (incomeDataMap.isNotEmpty),
            child: Expanded(
              child: GestureDetector(
                onTap: (() {
                  // go to income pages
                  // income page will always going to be 1
                  _changePageViewPostion(0);
                }),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: secondaryBackground, width: 0.5)),
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _createPieChart(
                        dataMap: incomeDataMap,
                        colorList: _generateColor("income", _stats.incomeExpenseCategory.income),
                      ),
                      const SizedBox(height: 5,),
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
            visible: (expenseDataMap.isNotEmpty),
            child: Expanded(
              child: GestureDetector(
                onTap: (() {
                  // for expense, we need to see whether we have income data or not?
                  // if got income data, then it means that the page will be 2
                  if(incomeDataMap.isNotEmpty) {
                    _changePageViewPostion(1);
                  }
                  else {
                    // we only have expense no income
                    _changePageViewPostion(0);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: secondaryBackground, width: 0.5)),
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _createPieChart(
                        dataMap: expenseDataMap,
                        colorList: _generateColor("expense", _stats.incomeExpenseCategory.expense),
                      ),
                      const SizedBox(height: 5,),
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
    double currentHeight = (height ?? 200);
    double currentWidth = (width ?? 200);

    return Container(
      color: Colors.transparent,
      child: SizedBox(
        height: currentHeight,
        width: currentWidth,
        child: PieChartView(
          backgroundColor: primaryBackground,
          chartAmount: dataMap,
          chartColors: colorList,
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
      return "${DateFormat("dd MMM yyyy").format(_stats.fromDate.toLocal())} - ${DateFormat("dd MMM yyyy").format(_stats.toDate.toLocal())}";
    }
  }

  String _totalAmount(String symbol, List<CategoryStatsModel> data) {
    double total = 0.0;
    for (CategoryStatsModel dt in data) {
      total += dt.amount;
    }

    if(total < 0) {
      total = total * (-1);
    }

    // return the formated CCY
    return "$symbol ${_fCCY.format(total)}";
  }

  void _getMaxAmount() {
    for (CategoryStatsModel exp in _stats.incomeExpenseCategory.expense) {
      _maxExpense += exp.amount;
    }
    if(_maxExpense < 0) {
      _maxExpense = _maxExpense * (-1);
    }
    for (CategoryStatsModel inc in _stats.incomeExpenseCategory.income) {
      _maxIncome += inc.amount;
    }
  }

  void _changePageViewPostion(int whichPage) {
    int itemCount = 0;
    if(_stats.incomeExpenseCategory.income.isNotEmpty) {
      itemCount++;
    }
    if(_stats.incomeExpenseCategory.expense.isNotEmpty) {
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