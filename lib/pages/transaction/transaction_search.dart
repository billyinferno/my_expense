import 'package:badges/badges.dart' as badges;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

enum PageName { summary, all, income, expense, transfer }
enum SummaryType { name, category }

class TransactionSearchPage extends StatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  State<TransactionSearchPage> createState() => _TransactionSearchPageState();
}

class _TransactionSearchPageState extends State<TransactionSearchPage> {
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  //TODO: to change API service to not using limit as we are not going perform lazy loading on the transaction search
  final int _limit = 99999; // make it to 99999 (just fetch everything, IO is not a concern)

  final Map<SummaryType, TypeSlideItem> _summaryItems = <SummaryType, TypeSlideItem> {
    SummaryType.name: TypeSlideItem(
      color: accentColors[6],
      text: "Name",
    ),
    SummaryType.category: TypeSlideItem(
      color: accentColors[6],
      text: "Category",
    ),
  };

  String _searchText = "";
  String _categoryId = "";
  String _type = "name";
  int _start = 0; // start from 0 page

  int _resultPage = 1;
  PageName _resultPageName = PageName.all;
  final Map<PageName, Color> _resultPageColor = {
    PageName.summary: accentColors[1],
    PageName.all: accentColors[3],
    PageName.income: accentColors[6],
    PageName.expense: accentColors[2],
    PageName.transfer: accentColors[4],
  };

  List<TransactionListModel> _transactions = [];
  final List<TransactionListModel> _filterTransactions = [];
  final List<TransactionListModel> _income = [];
  final List<TransactionListModel> _expense = [];
  final List<TransactionListModel> _transfer = [];
  late List<TransactionListModel> _filterTransactionsSort;
  late List<TransactionListModel> _incomeSort;
  late List<TransactionListModel> _expenseSort;
  late List<TransactionListModel> _transferSort;

  final Map<String, List<TransactionListModel>> _summaryIncome = {};
  final Map<String, List<TransactionListModel>> _summaryIncomeCategory = {};
  final Map<String, Map<String, TransactionListModel>> _subSummaryIncome = {};
  final Map<String, Map<String, TransactionListModel>> _subSummaryIncomeCategory = {};
  
  final Map<String, List<TransactionListModel>> _summaryExpense = {};
  final Map<String, List<TransactionListModel>> _summaryExpenseCategory = {};
  final Map<String, Map<String, TransactionListModel>> _subSummaryExpense = {};
  final Map<String, Map<String, TransactionListModel>> _subSummaryExpenseCategory = {};
  
  final Map<String, List<TransactionListModel>> _summaryTransfer = {};
  final Map<String, List<TransactionListModel>> _summaryTransferCategory = {};
  final Map<String, Map<String, TransactionListModel>> _subSummaryTransfer = {};
  final Map<String, Map<String, TransactionListModel>> _subSummaryTransferCategory = {};

  late Map<String, double> _totalAmountIncome;
  late Map<String, double> _totalAmountExpense;
  final Map<String, double> _totalAmountTransfer = {};

  late List<Widget> _summaryList;
  final List<Widget> _summaryListName = [];
  final List<Widget> _summaryListCategory = [];

  final Map<int, CategoryModel> _categorySelected = {};
  late Map<int, CategoryModel> _categoryExpenseList;
  late Map<int, CategoryModel> _categoryIncomeList;
  final List<Widget> _categoryExpenseIcon = [];
  final List<Widget> _categoryIncomeIcon = [];

  late List<WalletModel> _walletList;
  final Map<int, bool> _selectedWalletList = {};

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollControllerAll = ScrollController();
  final ScrollController _scrollControllerSummary = ScrollController();
  final ScrollController _scrollControllerIncome = ScrollController();
  final ScrollController _scrollControllerExpense = ScrollController();
  final ScrollController _scrollControllerTransfer = ScrollController();
  final ScrollController _walletController = ScrollController();

  late bool _sortType;
  late String _filterType;
  late SummaryType _summaryType;

  @override
  void initState() {
    super.initState();

    // initialize variable
    _totalAmountIncome = {};
    _totalAmountExpense = {};
    
    _summaryList = [];

    _sortType = false; // descending
    _filterType = "D"; // date
    _summaryType = SummaryType.name;

    _filterTransactionsSort = [];
    _incomeSort = [];
    _expenseSort = [];
    _transferSort = [];

    // get the category expense and income list from shared preferences
    _categoryExpenseList = CategorySharedPreferences.getCategory(type: 'expense');
    _categoryIncomeList = CategorySharedPreferences.getCategory(type: 'income');

    // generate the icon list widget for both expense and income
    _generateIconCategory();

    // get the wallet list, show the disabled also incase we have transaction
    // that the wallet already disabled as it still being showed in the search
    // result.
    _walletList = WalletSharedPreferences.getWallets(showDisabled: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollControllerAll.dispose();
    _scrollControllerSummary.dispose();
    _scrollControllerIncome.dispose();
    _scrollControllerExpense.dispose();
    _scrollControllerTransfer.dispose();
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Search")),
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context, false);
          },
          icon: const Icon(Ionicons.close,),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: (() {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return MyBottomSheet(
                    context: context,
                    title: "Select Filter",
                    screenRatio: 0.3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = "N";
                              _generateSortedList();
                            });
                            Navigator.pop(context);
                          }),
                          color: Colors.grey[900]!,
                          icon: Center(
                            child: Text(
                              "AN",
                              style: TextStyle(
                                color: textColor2,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          title: "Name",
                          isSelected: (_filterType == "N"),
                        ),
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = "D";
                              _generateSortedList();
                            });
                            Navigator.pop(context);
                          }),
                          color: Colors.grey[900]!,
                          icon: Icon(
                            Ionicons.calendar,
                            color: textColor2,
                            size: 15,
                          ),
                          title: "Date",
                          isSelected: (_filterType == "D"),
                        ),
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = "A";
                              _generateSortedList();
                            });
                            Navigator.pop(context);
                          }),
                          color: Colors.grey[900]!,
                          icon: Icon(
                            Ionicons.cash,
                            color: textColor2,
                            size: 15,
                          ),
                          title: "Amount",
                          isSelected: (_filterType == "A"),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            icon: Icon(
              Ionicons.funnel,
              color: textColor,
              size: 15,
            )
          ),
          IconButton(
            onPressed: (() {
              setState(() {
                _sortType = !_sortType;
                _generateSortedList();
              });
            }),
            icon: SortIcon(asc: _sortType),
          ),
        ],
      ),
      body: MySafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: secondaryDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  _showSearchOrSelectionWidget(),
                ],
              ),
            ),
            _getResultPage(),
          ],
        ),
      ),
    );
  }

  Widget _getResultPage() {
    // check if we got transactions or not?
    if (_transactions.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            "Enter search text, or add category\nthen press enter or tap search icon\nto search.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }

    // if got transaction we will result the transaction
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: primaryLight,
                  width: 1.0,
                  style: BorderStyle.solid
                )
              )
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: Center(
                      child: CupertinoSlidingSegmentedControl(
                        onValueChanged: (int? value) {
                          setState(() {
                            _resultPage = value!;
                            switch (_resultPage) {
                              case 0:
                                _resultPageName = PageName.summary;
                                break;
                              case 1:
                                _resultPageName = PageName.all;
                                break;
                              case 2:
                                _resultPageName = PageName.income;
                                break;
                              case 3:
                                _resultPageName = PageName.expense;
                                break;
                              case 4:
                                _resultPageName = PageName.transfer;
                                break;
                            }
                          });
                        },
                        groupValue: _resultPage,
                        thumbColor: (_resultPageColor[_resultPageName] ?? accentColors[9]),
                        children: const {
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
                ),
                const SizedBox(
                  width: 5,
                ),
                InkWell(
                  onDoubleTap: (() {
                    // clear the wallet
                    setState(() {
                      // clear the selected wallet list
                      _selectedWalletList.clear();

                      // filter and group the transaction
                      _filterTheTransaction();
                      _groupTransactions();
                    });
                  }),
                  onTap: (() {
                    showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return MyBottomSheet(
                            context: context,
                            title: "Account",
                            screenRatio: 0.45,
                            actionButton: InkWell(
                              onTap: (() {
                                if (_selectedWalletList.isNotEmpty) {
                                  setState(() {
                                    // clear the selected wallet list
                                    _selectedWalletList.clear();

                                    // filter and group the transaction
                                    _filterTheTransaction();
                                    _groupTransactions();
                                  });

                                  // close the modal dialog
                                  Navigator.pop(context);
                                }
                              }),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: Icon(
                                  Ionicons.trash_bin_outline,
                                  size: 20,
                                  color: accentColors[2],
                                ),
                              ),
                            ),
                            child: ListView.builder(
                              controller: _walletController,
                              itemCount: _walletList.length,
                              itemBuilder: (BuildContext context, int index) {
                                return SimpleItem(
                                  color: IconList.getColor(
                                    _walletList[index].walletType.type.toLowerCase(),
                                    enabled: _walletList[index].enabled
                                  ),
                                  title: _walletList[index].name,
                                  isSelected: (
                                    _selectedWalletList[_walletList[index].id] ?? false
                                  ),
                                  onTap: (() {
                                    setState(() {
                                      // check if this ID previously selected or not?
                                      if (_selectedWalletList.containsKey(_walletList[index].id)) {
                                        // delete this data
                                        _selectedWalletList.remove(_walletList[index].id);
                                      } else {
                                        // new data, set this as true
                                        _selectedWalletList[_walletList[index].id] = true;
                                      }

                                      // once finished call filter the transaction
                                      // to filter the transactions that listed
                                      _filterTheTransaction();

                                      // group the transactions
                                      _groupTransactions();
                                    });
                                    Navigator.pop(context);
                                  }),
                                  icon: IconList.getIcon(
                                    _walletList[index].walletType.type.toLowerCase()
                                  ),
                                );
                              },
                            ),
                          );
                        });
                  }),
                  child: SizedBox(
                    width: 35,
                    height: 35,
                    child: badges.Badge(
                      position: badges.BadgePosition.topEnd(end: 5),
                      badgeStyle: badges.BadgeStyle(badgeColor: accentColors[2]),
                      badgeContent: Text(
                        _selectedWalletList.length.toString(),
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 10
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Ionicons.wallet,
                          size: 15,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
        return ListViewWithHeader(
          controller: _scrollControllerAll,
          data: _filterTransactionsSort,
          canEdit: true,
          headerType: _filterType,
          showHeader: (_filterType != 'A'),
          editFunction: (txn) {
            // show the transaction edit screen
            _showTransactionEditScreen(txn);
          },
        );
      case PageName.summary:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              child: TypeSlide<SummaryType>(
                onValueChanged: (value) {
                  setState(() {
                    _summaryType = value;
                    _setSummaryList();
                  });
                },
                items: _summaryItems,
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollControllerSummary,
                itemCount: _summaryList.length,
                itemBuilder: ((context, index) {
                  return _summaryList[index];
                })
              ),
            ),
          ],
        );
      case PageName.income:
        return ListViewWithHeader(
          controller: _scrollControllerIncome,
          data: _incomeSort,
          canEdit: false,
          headerType: _filterType,
          showHeader: (_filterType != 'A'),
        );
      case PageName.expense:
        return ListViewWithHeader(
          controller: _scrollControllerExpense,
          data: _expenseSort,
          canEdit: false,
          headerType: _filterType,
        );
      case PageName.transfer:
        return ListViewWithHeader(
          controller: _scrollControllerTransfer,
          data: _transferSort,
          canEdit: false,
          headerType: _filterType,
          showHeader: (_filterType != 'A'),
        );
    }
  }

  Widget _categoryIcon(
      {required String type,
      required String? name,
      double? height,
      double? width,
      double? size}) {
    if (type == "expense") {
      return Container(
        height: (height ?? 40),
        width: (width ?? 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((height ?? 40)),
          color: IconColorList.getExpenseColor(name!),
        ),
        child: IconColorList.getExpenseIcon(name, size),
      );
    } else if (type == "income") {
      return Container(
        height: (height ?? 40),
        width: (width ?? 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular((height ?? 40)),
          color: IconColorList.getIncomeColor(name!),
        ),
        child: IconColorList.getIncomeIcon(name, size),
      );
    } else {
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
    if (transaction.type == "expense" || transaction.type == "income") {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "${transaction.wallet.currency} ${Globals.fCCY.format(transaction.amount)}",
            style: TextStyle(
              color: (transaction.type == "expense"
                  ? accentColors[2]
                  : accentColors[0]),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "${transaction.wallet.currency} ${Globals.fCCY.format(transaction.amount)}",
            style: TextStyle(
              color: accentColors[5],
            ),
            textAlign: TextAlign.right,
          ),
          Visibility(
            visible: (transaction.walletTo != null),
            child: Text(
              "${transaction.walletTo != null ? transaction.walletTo!.currency : ''} ${Globals.fCCY.format(transaction.amount * transaction.exchangeRate)}",
              style: TextStyle(
                color: accentColors[5].lighten(amount: 0.25),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      );
    }
  }

  Future<void> _showTransactionEditScreen(TransactionListModel txn) async {
    // go to the transaction edit for this txn
    await Navigator.pushNamed(context, '/transaction/edit', arguments: txn)
        .then((result) async {
      // check if we got return
      if (result != null) {
        // set state to rebuild the widget
        setState(() {
          // convert result to transaction list mode
          TransactionListModel txnUpdate = result as TransactionListModel;
          // update the current transaction list based on the updated transaction
          for (int i = 0; i < _filterTransactions.length; i++) {
            // check which transaction is being updated
            if (_filterTransactions[i].id == txnUpdate.id) {
              _filterTransactions[i] = txnUpdate;
              break;
            }
          }

          // after that we will perform grouping of the transactions to income, expense, and transfer
          _groupTransactions();
        });
      }
    });
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
    _summaryIncomeCategory.clear();
    _subSummaryIncome.clear();
    _subSummaryIncomeCategory.clear();
    _totalAmountIncome.clear();

    _summaryExpense.clear();
    _summaryExpenseCategory.clear();
    _subSummaryExpense.clear();
    _subSummaryExpenseCategory.clear();
    _totalAmountExpense.clear();

    _summaryTransfer.clear();
    _summaryTransferCategory.clear();
    _subSummaryTransfer.clear();
    _subSummaryTransferCategory.clear();
    _totalAmountTransfer.clear();

    String summaryKey = "";
    String summaryKeyCategory = "";
    String subSummaryKey = "";

    TransactionListModel tmpSubSummaryData;

    // now compute the summary data so we can showed it on the summary page
    // based on the income, and expense
    for (int i = 0; i < _filterTransactions.length; i++) {
      // generate the summary key
      if (
        _filterTransactions[i].type == 'expense' ||
        _filterTransactions[i].type == 'income'
      ) {
        summaryKey = "${_filterTransactions[i].type.toLowerCase()}_${_filterTransactions[i].category != null ? _filterTransactions[i].category!.name : ''}_${_filterTransactions[i].name}_${_filterTransactions[i].wallet.currency}";
        summaryKeyCategory = "${_filterTransactions[i].type.toLowerCase()}_${_filterTransactions[i].category!.name}_${_filterTransactions[i].wallet.currency}";
      } else {
        summaryKey = "${_filterTransactions[i].type.toLowerCase()}_${_filterTransactions[i].wallet.name}_${_filterTransactions[i].wallet.currency}";
        summaryKeyCategory = "${_filterTransactions[i].type.toLowerCase()}_${_filterTransactions[i].wallet.currency}_${_filterTransactions[i].walletTo!.currency}";
      }

      // check which transaction is being updated
      switch (_filterTransactions[i].type.toLowerCase()) {
        case 'income':
          // check if summary key exists or not?
          if (!_summaryIncome.containsKey(summaryKey)) {
            _summaryIncome[summaryKey] = [];
          }
          _summaryIncome[summaryKey]!.add(_filterTransactions[i]);

          // check if summary key category exists or not?
          if (!_summaryIncomeCategory.containsKey(summaryKeyCategory)) {
            _summaryIncomeCategory[summaryKeyCategory] = [];
          }
          _summaryIncomeCategory[summaryKeyCategory]!.add(_filterTransactions[i]);

          // check if total summary key for this ccy is exists or not?
          if (!_totalAmountIncome.containsKey(_filterTransactions[i].wallet.currency)) {
            _totalAmountIncome[_filterTransactions[i].wallet.currency] = 0;
          }
          _totalAmountIncome[_filterTransactions[i].wallet.currency] =
            _totalAmountIncome[_filterTransactions[i].wallet.currency]! +
            _filterTransactions[i].amount;

          _income.add(_filterTransactions[i]);
          break;
        case 'expense':
          // check if summary key exists or not?
          if (!_summaryExpense.containsKey(summaryKey)) {
            _summaryExpense[summaryKey] = [];
          }
          _summaryExpense[summaryKey]!.add(_filterTransactions[i]);

          // check if summary key category exists or not?
          if (!_summaryExpenseCategory.containsKey(summaryKeyCategory)) {
            _summaryExpenseCategory[summaryKeyCategory] = [];
          }
          _summaryExpenseCategory[summaryKeyCategory]!.add(_filterTransactions[i]);

          // check if total summary key for this ccy is exists or not?
          if (!_totalAmountExpense.containsKey(_filterTransactions[i].wallet.currency)) {
            _totalAmountExpense[_filterTransactions[i].wallet.currency] = 0;
          }
          _totalAmountExpense[_filterTransactions[i].wallet.currency] =
            _totalAmountExpense[_filterTransactions[i].wallet.currency]! +
            _filterTransactions[i].amount;

          _expense.add(_filterTransactions[i]);
          break;
        case 'transfer':
          // check if summary key exists or not?
          if (!_summaryTransfer.containsKey(summaryKey)) {
            _summaryTransfer[summaryKey] = [];
          }
          _summaryTransfer[summaryKey]!.add(_filterTransactions[i]);

          // check if summary key category exists or not?
          if (!_summaryTransferCategory.containsKey(summaryKeyCategory)) {
            _summaryTransferCategory[summaryKeyCategory] = [];
          }
          _summaryTransferCategory[summaryKeyCategory]!.add(_filterTransactions[i]);

          // check if total summary key for this ccy is exists or not?
          if (!_totalAmountTransfer.containsKey(_filterTransactions[i].wallet.currency)) {
            _totalAmountTransfer[_filterTransactions[i].wallet.currency] = 0;
          }
          _totalAmountTransfer[_filterTransactions[i].wallet.currency] =
            _totalAmountTransfer[_filterTransactions[i].wallet.currency]! +
            _filterTransactions[i].amount;

          _transfer.add(_filterTransactions[i]);
          break;
      }
    }

    // generate listed of sorted income, expense, transfer
    _generateSortedList();

    // sorted the total amount income and expense
    // so it will showed in the same order on the summary list
    List<MapEntry<String, double>> sortedEntriesIncome = _totalAmountIncome.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    _totalAmountIncome = Map.fromEntries(sortedEntriesIncome);

    List<MapEntry<String, double>> sortedEntriesExpense = _totalAmountExpense.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    _totalAmountExpense = Map.fromEntries(sortedEntriesExpense);

    // clear the summary list widget
    _summaryListName.clear();
    _summaryListCategory.clear();

    // check if we have expense or not?
    if (_summaryExpense.isNotEmpty) {  
      // add the expense bar on the _summaryListName
      _summaryListName.add(
        _generateSummaryBox(
          title: "Expense",
          color: accentColors[2],
          data: _totalAmountExpense
        )
      );

      // loop thru all the expense data
      _summaryExpense.forEach((key, value) {
        // compute the amount
        amount = 0;
        startDate = null;
        endDate = null;
        count = 0;

        // create the sub summary expense for this key
        _subSummaryExpense[key] = {};

        for (TransactionListModel data in value) {
          if (startDate == null) {
            startDate = data.date;
          } else {
            if (startDate!.isAfter(data.date)) {
              startDate = data.date;
            }
          }

          if (endDate == null) {
            endDate = data.date;
          } else {
            if (endDate!.isBefore(data.date)) {
              endDate = data.date;
            }
          }

          amount += data.amount;
          count++;

          // add the transaction list on the sub summary list based on the
          // month and year
          subSummaryKey = Globals.dfyyyy.format(data.date);
          
          // check if subSummaryKey is exists or not?
          if (!_subSummaryExpense[key]!.containsKey(subSummaryKey)) {
            // if not exists create the 1st data
            _subSummaryExpense[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              data.amount,
              data.exchangeRate
            );
          }
          else {
            // exists, get the previous data
            tmpSubSummaryData = _subSummaryExpense[key]![subSummaryKey]!;
            // and combine it with current data
            _subSummaryExpense[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              (data.amount + tmpSubSummaryData.amount),
              data.exchangeRate
            );
          }
        }

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
            1);

        _summaryListName.add(
          _createExpandableItem(
            txn: txn,
            startDate: startDate!,
            endDate: endDate!,
            count: count,
            subTxn: (_subSummaryExpense[key] ?? {}),
          )
        );
      });
    }

    // check if we have expense category or not?
    if (_summaryExpenseCategory.isNotEmpty) {  
      // add the expense bar on the _summaryList
      _summaryListCategory.add(
        _generateSummaryBox(
          title: "Expense",
          color: accentColors[2],
          data: _totalAmountExpense
        )
      );

      // loop thru all the expense data
      _summaryExpenseCategory.forEach((key, value) {
        // compute the amount
        amount = 0;
        startDate = null;
        endDate = null;
        count = 0;

        // create the sub summary expense for this key
        _subSummaryExpenseCategory[key] = {};

        for (TransactionListModel data in value) {
          if (startDate == null) {
            startDate = data.date;
          } else {
            if (startDate!.isAfter(data.date)) {
              startDate = data.date;
            }
          }

          if (endDate == null) {
            endDate = data.date;
          } else {
            if (endDate!.isBefore(data.date)) {
              endDate = data.date;
            }
          }

          amount += data.amount;
          count++;

          // add the transaction list on the sub summary list based on the
          // month and year
          subSummaryKey = Globals.dfyyyy.format(data.date);
          
          // check if subSummaryKey is exists or not?
          if (!_subSummaryExpenseCategory[key]!.containsKey(subSummaryKey)) {
            // if not exists create the 1st data
            _subSummaryExpenseCategory[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.category!.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              data.amount,
              data.exchangeRate
            );
          }
          else {
            // exists, get the previous data
            tmpSubSummaryData = _subSummaryExpenseCategory[key]![subSummaryKey]!;
            // and combine it with current data
            _subSummaryExpenseCategory[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.category!.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              (data.amount + tmpSubSummaryData.amount),
              data.exchangeRate
            );
          }
        }

        // create TransactionModel based on the value
        TransactionListModel txn = TransactionListModel(
            -1,
            value[0].category!.name,
            value[0].type,
            DateTime.now(),
            '',
            value[0].category,
            value[0].wallet,
            null,
            value[0].usersPermissionsUser,
            true,
            amount,
            1);

        _summaryListCategory.add(
          _createExpandableItem(
            txn: txn,
            startDate: startDate!,
            endDate: endDate!,
            count: count,
            subTxn: (_subSummaryExpenseCategory[key] ?? {}),
            showCategory: false,
          )
        );
      });
    }

    // check if summary income is not empty
    if (_summaryIncome.isNotEmpty) {
      // add the income bar on the _summaryListName
      _summaryListName.add(
        _generateSummaryBox(
          title: "Income",
          color: accentColors[6],
          data: _totalAmountIncome
        )
      );

      _summaryIncome.forEach((key, value) {
        // compute the amount
        amount = 0;
        startDate = null;
        endDate = null;
        count = 0;

        // generate subSummaryIncome for this key
        _subSummaryIncome[key] = {};

        for (TransactionListModel data in value) {
          if (startDate == null) {
            startDate = data.date;
          } else {
            if (startDate!.isAfter(data.date)) {
              startDate = data.date;
            }
          }

          if (endDate == null) {
            endDate = data.date;
          } else {
            if (endDate!.isBefore(data.date)) {
              endDate = data.date;
            }
          }

          amount += data.amount;
          count++;

          // add the transaction list on the sub summary list based on the
          // month and year
          subSummaryKey = Globals.dfyyyy.format(data.date);
          
          // check if subSummaryKey is exists or not?
          if (!_subSummaryIncome[key]!.containsKey(subSummaryKey)) {
            // if not exists create the 1st data
            _subSummaryIncome[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              data.amount,
              data.exchangeRate
            );
          }
          else {
            // exists, get the previous data
            tmpSubSummaryData = _subSummaryIncome[key]![subSummaryKey]!;
            // and combine it with current data
            _subSummaryIncome[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              (data.amount + tmpSubSummaryData.amount),
              data.exchangeRate
            );
          }
        }

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
            1);

        _summaryListName.add(
          _createExpandableItem(
            txn: txn,
            startDate: startDate!,
            endDate: endDate!,
            count: count,
            subTxn: (_subSummaryIncome[key] ?? {}),
          )
        );
      });
    }

    // check if summary income is not empty
    if (_summaryIncomeCategory.isNotEmpty) {
      // add the income bar on the _summaryListCategory
      _summaryListCategory.add(
        _generateSummaryBox(
          title: "Income",
          color: accentColors[6],
          data: _totalAmountIncome
        )
      );

      _summaryIncomeCategory.forEach((key, value) {
        // compute the amount
        amount = 0;
        startDate = null;
        endDate = null;
        count = 0;

        // generate subSummaryIncome for this key
        _subSummaryIncomeCategory[key] = {};

        for (TransactionListModel data in value) {
          if (startDate == null) {
            startDate = data.date;
          } else {
            if (startDate!.isAfter(data.date)) {
              startDate = data.date;
            }
          }

          if (endDate == null) {
            endDate = data.date;
          } else {
            if (endDate!.isBefore(data.date)) {
              endDate = data.date;
            }
          }

          amount += data.amount;
          count++;

          // add the transaction list on the sub summary list based on the
          // month and year
          subSummaryKey = Globals.dfyyyy.format(data.date);
          
          // check if subSummaryKey is exists or not?
          if (!_subSummaryIncomeCategory[key]!.containsKey(subSummaryKey)) {
            // if not exists create the 1st data
            _subSummaryIncomeCategory[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.category!.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              data.amount,
              data.exchangeRate
            );
          }
          else {
            // exists, get the previous data
            tmpSubSummaryData = _subSummaryIncomeCategory[key]![subSummaryKey]!;
            // and combine it with current data
            _subSummaryIncomeCategory[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.category!.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              (data.amount + tmpSubSummaryData.amount),
              data.exchangeRate
            );
          }
        }

        // create TransactionModel based on the value
        TransactionListModel txn = TransactionListModel(
            -1,
            value[0].category!.name,
            value[0].type,
            DateTime.now(),
            '',
            value[0].category,
            value[0].wallet,
            null,
            value[0].usersPermissionsUser,
            true,
            amount,
            1);

        _summaryListCategory.add(
          _createExpandableItem(
            txn: txn,
            startDate: startDate!,
            endDate: endDate!,
            count: count,
            subTxn: (_subSummaryIncomeCategory[key] ?? {}),
            showCategory: false,
          )
        );
      });
    }

    // check if summary transfer is not empty
    if (_summaryTransfer.isNotEmpty) {
      // add the transfer bar on the _summaryListName
      _summaryListName.add(
        _generateSummaryBox(
          title: "Transfer",
          color: accentColors[4],
          data: _totalAmountTransfer,
        )
      );

      _summaryTransfer.forEach((key, value) {
        // compute the amount
        amount = 0;
        startDate = null;
        endDate = null;
        count = 0;

        // initialize sub summary transfer for this key
        _subSummaryTransfer[key] = {};

        for (TransactionListModel data in value) {
          if (startDate == null) {
            startDate = data.date;
          } else {
            if (startDate!.isAfter(data.date)) {
              startDate = data.date;
            }
          }

          if (endDate == null) {
            endDate = data.date;
          } else {
            if (endDate!.isBefore(data.date)) {
              endDate = data.date;
            }
          }

          amount += data.amount;
          count++;

          // add the transaction list on the sub summary list based on the
          // month and year
          subSummaryKey = Globals.dfyyyy.format(data.date);
          
          // check if subSummaryKey is exists or not?
          if (!_subSummaryTransfer[key]!.containsKey(subSummaryKey)) {
            // if not exists create the 1st data
            _subSummaryTransfer[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              data.amount,
              data.exchangeRate
            );
          }
          else {
            // exists, get the previous data
            tmpSubSummaryData = _subSummaryTransfer[key]![subSummaryKey]!;
            // and combine it with current data
            _subSummaryTransfer[key]![subSummaryKey] = TransactionListModel(
              -1,
              data.name,
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              (data.amount + tmpSubSummaryData.amount),
              data.exchangeRate
            );
          }
        }

        // create TransactionModel based on the value
        TransactionListModel txn = TransactionListModel(
            -1,
            value[0].wallet.name,
            value[0].type,
            DateTime.now(),
            '',
            value[0].category,
            value[0].wallet,
            null,
            value[0].usersPermissionsUser,
            true,
            amount,
            1);

        _summaryListName.add(
          _createExpandableItem(
            txn: txn,
            startDate: startDate!,
            endDate: endDate!,
            count: count,
            subTxn: (_subSummaryTransfer[key] ?? {}),
          )
        );
      });
    }

    // check if summary transfer is not empty
    if (_summaryTransferCategory.isNotEmpty) {
      // add the transfer bar on the _summaryListCategory
      _summaryListCategory.add(
        _generateSummaryBox(
          title: "Transfer",
          color: accentColors[4],
          data: _totalAmountTransfer,
        )
      );

      _summaryTransferCategory.forEach((key, value) {
        // compute the amount
        amount = 0;
        startDate = null;
        endDate = null;
        count = 0;

        // initialize sub summary transfer for this key
        _subSummaryTransferCategory[key] = {};

        for (TransactionListModel data in value) {
          if (startDate == null) {
            startDate = data.date;
          } else {
            if (startDate!.isAfter(data.date)) {
              startDate = data.date;
            }
          }

          if (endDate == null) {
            endDate = data.date;
          } else {
            if (endDate!.isBefore(data.date)) {
              endDate = data.date;
            }
          }

          amount += data.amount;
          count++;

          // add the transaction list on the sub summary list based on the
          // month and year
          subSummaryKey = Globals.dfyyyy.format(data.date);
          
          // check if subSummaryKey is exists or not?
          if (!_subSummaryTransferCategory[key]!.containsKey(subSummaryKey)) {
            // if not exists create the 1st data
            _subSummaryTransferCategory[key]![subSummaryKey] = TransactionListModel(
              -1,
              "${data.wallet.symbol} to ${data.walletTo!.symbol}",
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              data.amount,
              data.exchangeRate
            );
          }
          else {
            // exists, get the previous data
            tmpSubSummaryData = _subSummaryTransferCategory[key]![subSummaryKey]!;
            // and combine it with current data
            _subSummaryTransferCategory[key]![subSummaryKey] = TransactionListModel(
              -1,
              "${data.wallet.symbol} to ${data.walletTo!.symbol}",
              data.type,
              DateTime(data.date.year, data.date.month, 1),
              data.description,
              data.category,
              data.wallet,
              data.walletTo,
              data.usersPermissionsUser,
              data.cleared,
              (data.amount + tmpSubSummaryData.amount),
              data.exchangeRate
            );
          }
        }

        // create TransactionModel based on the value
        TransactionListModel txn = TransactionListModel(
            -1,
            "${value[0].wallet.symbol} to ${value[0].walletTo!.symbol}",
            value[0].type,
            DateTime.now(),
            '',
            value[0].category,
            value[0].wallet,
            null,
            value[0].usersPermissionsUser,
            true,
            amount,
            1);

        _summaryListCategory.add(
          _createExpandableItem(
            txn: txn,
            startDate: startDate!,
            endDate: endDate!,
            count: count,
            subTxn: (_subSummaryTransferCategory[key] ?? {}),
            showCategory: false,
          )
        );
      });
    }

    // set initial summary list
    _setSummaryList();
  }

  Widget _generateSummaryBox({
    required String title,
    required Color color,
    required Map<String, double> data,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: secondaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          ..._generateSubSummaryBox(
            data: data,
            color: color
          ),
        ],
      ),
    );
  }

  List<Widget> _generateSubSummaryBox(
      {required Map<String, double> data, required Color color}) {
    List<Widget> ret = <Widget>[];

    data.forEach((key, value) {
      ret.add(SizedBox(
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              "Total $key",
              style: TextStyle(
                color: color,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  Globals.fCCY.format(value),
                  style: TextStyle(
                    color: color,
                  ),
                ),
              ),
            )
          ],
        ),
      ));
    });

    return ret;
  }

  Widget _createExpandableItem({
    required TransactionListModel txn,
    required DateTime startDate,
    required DateTime endDate,
    required int count,
    required Map<String, TransactionListModel> subTxn,
    bool showCategory = true,
  }) {
    return Theme(
      data: Globals.themeData.copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ListTileTheme(
        contentPadding: const EdgeInsets.all(0),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: primaryLight,
                width: 1.0,
              )
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(0),
            childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
            backgroundColor: primaryBackground,
            collapsedBackgroundColor: primaryBackground,
            iconColor: primaryLight,
            collapsedIconColor: primaryLight,
            title: _createSummaryItem(
              txn: txn,
              startDate: startDate,
              endDate: endDate,
              count: count,
              showCategory: showCategory,
            ),
            children: _createExpandableChilds(
              subTxn: subTxn,
              showCategory: showCategory,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _createExpandableChilds({
    required Map<String, TransactionListModel> subTxn,
    bool showCategory = true,
  }) {
    List<Widget> ret = [];

    // loop thru subTxn
    subTxn.forEach((key, txn) {
      // generate an item for each key
      ret.add(
        // create container
        Container(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const SizedBox(width: 50),
              Expanded(
                child: Text(
                  key,
                ),
              ),
              const SizedBox(width: 10,),
              _getAmount(txn),
              const SizedBox(width: 35,)
            ],
          ),
        )
      );
    },);

    return ret;
  }

  Widget _createSummaryItem({
    required TransactionListModel txn,
    required DateTime startDate,
    required DateTime endDate,
    required int count,
    bool showCategory = true,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _categoryIcon(
            name: (txn.category != null ? txn.category!.name : ''),
            type: txn.type
          ),
          const SizedBox(
            width: 10,
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
                  "${Globals.dfddMMyy.formatLocal(startDate)} - ${Globals.dfddMMyy.formatLocal(endDate)}",
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
                Visibility(
                  visible: showCategory,
                  child: (txn.category == null
                      ? const SizedBox.shrink()
                      : Text(
                          (txn.category != null ? txn.category!.name : ''),
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        )),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  "${count.toString()} time${(count > 1 ? 's' : '')}",
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          _getAmount(txn),
        ],
      ),
    );
  }

  void _setTransactions({
    required List<TransactionListModel> transactions,
    required int limit,
    required int start}
  ) {
    setState(() {
      _transactions.clear();
      _transactions.addAll(transactions);

      // set also the start for the next transaction we need to fetch
      _start = start + limit;

      // filter the transaction
      _filterTheTransaction();

      // group the transactions
      _groupTransactions();
    });
  }

  void _filterTheTransaction() {
    // clear the filter transaction first
    _filterTransactions.clear();

    // check if we have filter enabled or not?
    if (_selectedWalletList.isEmpty) {
      _filterTransactions.addAll(_transactions);
    } else {
      // loop thru transactions and see if the wallet from and to is on the
      // selected wallet or not?
      for (int i = 0; i < _transactions.length; i++) {
        // check if the wallet from and to id is in the selected wallet list
        // or not?
        if (_selectedWalletList[_transactions[i].wallet.id] ?? false) {
          _filterTransactions.add(_transactions[i]);
        } else {
          // check if wallet to is not null
          if (_transactions[i].walletTo != null) {
            // check if the wallet to id is on the selected wallet list or not?
            if (_selectedWalletList[_transactions[i].walletTo!.id] ?? false) {
              _filterTransactions.add(_transactions[i]);
            }
          }
        }
      }
    }
  }

  Future<void> _findTransaction({
    required String searchText,
    required String categoryId,
    required String type,
    required int limit,
    required int start
  }) async {
    await _transactionHttp.findTransaction(
      type: type,
      name: searchText,
      category: categoryId,
      limit: limit,
      start: start
    ).then((results) {
      _setTransactions(
        transactions: results,
        limit: limit,
        start: start
      );
    });
  }

  Future<void> _submitSearch() async {
    // 1 will be text search only
    // 2 will be category search only
    // 3 will be both
    int determineType = 0;

    // default the category id value as empty string
    _categoryId = '';

    // check if category selected is empty or not?
    if (_categorySelected.isNotEmpty) {
      // category selected not empty
      determineType += 2;

      // generate the _categoryId based on the list of the category selected
      _categorySelected.forEach((key, value) {
        // if not the first one, then add ,
        if (_categoryId.isNotEmpty) {
          _categoryId = '$_categoryId,';
        }
        _categoryId = _categoryId + key.toString();
      });
    }

    // check if the text is empty or not?
    if (_searchController.text.trim().isNotEmpty) {
      // not empty, add 1 to the determine type
      determineType += 1;

      // set the search text as current search controller text
      _searchText = _searchController.text;
      _searchText = _searchText.trim();

      // ensure the searchText is more than 3
      if (_searchText.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(createSnackBar(
          message: "Minimum text search is 3 character",
        ));
        return;
      }
    }

    // ensure that we already determine the type when reaching here
    if (determineType == 0) {
      ScaffoldMessenger.of(context).showSnackBar(createSnackBar(
        message: "Add text or category before searching.",
      ));
      return;
    }

    // now determine the _type
    switch (determineType) {
      case 1:
        _type = "name";
        break;
      case 2:
        _type = "category";
        break;
      case 3:
        _type = "both";
        break;
    }

    // show the loader dialog
    LoadingScreen.instance().show(context: context);

    // initialize all the value
    _start = 0; // always start from 0
    _transactions.clear();
    _transactions = [];

    // try to find the transaction
    await _findTransaction(
      searchText: _searchText,
      categoryId: _categoryId,
      type: _type,
      limit: _limit,
      start: _start,
    ).onError((error, stackTrace) {
      Log.error(
        message: "Error when searching transaction",
        error: error,
        stackTrace: stackTrace,
      );

      if (mounted) {
        Navigator.pop(context);
        // showed error message
        ScaffoldMessenger.of(context).showSnackBar(createSnackBar(
          message: "Error when searching transaction",
        ));
      }
    }).whenComplete(
      () {
        // remove the loading screen
        LoadingScreen.instance().hide();
      },
    );
  }

  Widget _showSearchOrSelectionWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: CupertinoSearchTextField(
                controller: _searchController,
                style: const TextStyle(
                  color: textColor2,
                  fontFamily: '--apple-system'
                ),
                suffixIcon: const Icon(Ionicons.close),
                onSubmitted: ((_) async {
                  await _submitSearch().then((_) {
                    if (mounted) {
                      // remove the focus from the text
                      FocusScopeNode currentFocus = FocusScope.of(context);
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }
                    }
                  });
                }),
                onSuffixTap: (() {
                  // clear the text fields
                  _searchController.clear();
                }),
              ),
            ),
            const SizedBox(width: 5,),
            GestureDetector(
              onTap: (() async {
                await _submitSearch();
              }),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColors[6],
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: darkAccentColors[6],
                    width: 1.0,
                    style: BorderStyle.solid,
                  )
                ),
                child: const Icon(
                  Ionicons.search,
                  size: 20,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const LabelHeader(
              "Category",
              size: 15,
            ),
            const SizedBox(width: 10,),
            Expanded(
              child: InkWell(
                onTap: (() {
                  _showCategorySelectionDialog();
                }),
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryDark,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: secondaryBackground,
                      style: BorderStyle.solid,
                      width: 1.0,
                    )
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 10,
                      ),
                      Icon(
                        Ionicons.add,
                        size: 20,
                        color: textColor,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Center(
                            child: Text(
                          "Add",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
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
                    // clear the category
                    _categorySelected.clear();

                    // clear also the filter
                    _selectedWalletList.clear();

                    // then filter the transaction and group it again
                    _filterTheTransaction();
                    _groupTransactions();
                  });
                }),
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryDark,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: secondaryBackground,
                      style: BorderStyle.solid,
                      width: 1.0,
                    )
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 10,
                      ),
                      Icon(
                        Ionicons.trash,
                        size: 20,
                        color: textColor,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Center(
                            child: Text(
                          "Clear",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5,),
        Visibility(
          visible: _categorySelected.isNotEmpty,
          child: Container(
            margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _generateChipCategory(),
            ),
          ),
        ),
      ],
    );
  }

  void _showCategorySelectionDialog() {
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return MyBottomSheet(
            context: context,
            title: "Category",
            screenRatio: 0.75,
            child: TransactionSearchCategory(
              categoryExpense: _categoryExpenseIcon,
              categoryIncome: _categoryIncomeIcon,
            ),
          );
        });
  }

  void _generateIconCategory() {
    _categoryExpenseList.forEach((key, value) {
      _categoryExpenseIcon.add(_iconCategory(value));
    });

    _categoryIncomeList.forEach((key, value) {
      _categoryIncomeIcon.add(_iconCategory(value));
    });
  }

  Widget _iconCategory(CategoryModel category) {
    // check if this is expense or income
    Color iconColor;
    Icon icon;

    if (category.type.toLowerCase() == "expense") {
      iconColor = IconColorList.getExpenseColor(category.name.toLowerCase());
      icon = IconColorList.getExpenseIcon(category.name.toLowerCase());
    } else {
      iconColor = IconColorList.getIncomeColor(category.name.toLowerCase());
      icon = IconColorList.getIncomeIcon(category.name.toLowerCase());
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
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              createSnackBar(message: "Maximum selected category is 10"));
        }
      },
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
                  color: iconColor,
                  border: Border.all(
                    color: (
                      _categorySelected.containsKey(category.id) ?
                      accentColors[4] :
                      Colors.transparent
                    ),
                    width: 2.0,
                    style: BorderStyle.solid,
                  )),
              child: icon,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    category.name,
                    style: const TextStyle(
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
    );
  }

  List<Widget> _generateChipCategory() {
    List<Widget> result = [];

    // loop thru the category selected
    _categorySelected.forEach((key, value) {
      result.add(InkWell(
        onTap: (() {
          // remove this chip from the _categorySelected
          setState(() {
            _categorySelected.remove(key);
          });
        }),
        child: Chip(
          avatar: _categoryIcon(
            type: value.type,
            name: value.name,
            height: 20,
            width: 20,
            size: 15
          ),
          deleteIcon: Icon(
            Ionicons.close,
            size: 15,
          ),
          onDeleted: () {
            // remove this chip from the _categorySelected
            setState(() {
              _categorySelected.remove(key);
            });
          },
          label: Text(value.name),
          backgroundColor: (
            value.type == 'expense' ?
            IconColorList.getExpenseColor(value.name) :
            IconColorList.getIncomeColor(value.name)
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 5
          ),
        ),
      ));
    });

    return result;
  }

  void _generateSortedList() {
    // clear the sorted income, expense, and transfer first
    _incomeSort.clear();
    _expenseSort.clear();
    _transferSort.clear();

    // switch the filter type
    switch(_filterType) {
      case "N":
        _filterTransactionsSort = _filterTransactions.toList()..sort((a, b) => a.name.compareTo(b.name));
        _incomeSort = _income.toList()..sort((a, b) => a.name.compareTo(b.name));
        _expenseSort = _expense.toList()..sort((a, b) => a.name.compareTo(b.name));
        _transferSort = _transfer.toList()..sort((a, b) => a.name.compareTo(b.name));
        break;
      case "D":
        _filterTransactionsSort = _filterTransactions.toList()..sort((a, b) => a.date.compareTo(b.date));
        _incomeSort = _income.toList()..sort((a, b) => a.date.compareTo(b.date));
        _expenseSort = _expense.toList()..sort((a, b) => a.date.compareTo(b.date));
        _transferSort = _transfer.toList()..sort((a, b) => a.date.compareTo(b.date));
        break;
      case "A":
        _filterTransactionsSort = _filterTransactions.toList()..sort((a, b) => a.amount.compareTo(b.amount));
        _incomeSort = _income.toList()..sort((a, b) => a.amount.compareTo(b.amount));
        _expenseSort = _expense.toList()..sort((a, b) => a.amount.compareTo(b.amount));
        _transferSort = _transfer.toList()..sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        _filterTransactionsSort = _filterTransactions.toList()..sort((a, b) => a.date.compareTo(b.date));
        _incomeSort = _income.toList()..sort((a, b) => a.date.compareTo(b.date));
        _expenseSort = _expense.toList()..sort((a, b) => a.date.compareTo(b.date));
        _transferSort = _transfer.toList()..sort((a, b) => a.date.compareTo(b.date));
        break;
    }

    // check whether this is ascending or descending
    if (!_sortType) {
      _filterTransactionsSort = _filterTransactionsSort.reversed.toList();
      _incomeSort = _incomeSort.reversed.toList();
      _expenseSort = _expenseSort.reversed.toList();
      _transferSort = _transferSort.reversed.toList();
    }
  }

  void _setSummaryList() {
    // select which summary list we want to show
    switch(_summaryType) {
      case SummaryType.name:
        _summaryList = _summaryListName;
        break;
      case SummaryType.category:
        _summaryList = _summaryListCategory;
        break;
    }
  }
}

class TransactionSearchCategory extends StatefulWidget {
  final List<Widget> categoryExpense;
  final List<Widget> categoryIncome;
  const TransactionSearchCategory({
    super.key,
    required this.categoryExpense,
    required this.categoryIncome
  });

  @override
  State<TransactionSearchCategory> createState() => _TransactionSearchCategoryState();
}

class _TransactionSearchCategoryState extends State<TransactionSearchCategory> {
  final ScrollController _controller = ScrollController();
  late PageName _resultCategoryName;

  final Map<PageName, Color> _resultCategoryColor = {
    PageName.expense: accentColors[2],
    PageName.income: accentColors[6],
  };

  @override
  void initState() {  
    super.initState();
    _resultCategoryName = PageName.expense;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: CupertinoSegmentedControl<PageName>(
              selectedColor: (_resultCategoryColor[_resultCategoryName] ?? accentColors[9]),
              // Provide horizontal padding around the children.
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // This represents a currently selected segmented control.
              groupValue: _resultCategoryName,
              // Callback that sets the selected segmented control.
              onValueChanged: (PageName value) {
                setState(() {
                  _resultCategoryName = value;
                });
              },
              children: const <PageName, Widget>{
                PageName.expense: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Expense'),
                ),
                PageName.income: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Income'),
                ),
              },
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            controller: _controller,
            crossAxisCount: 4,
            children: (
              _resultCategoryName == PageName.expense ?
              widget.categoryExpense :
              widget.categoryIncome
            ),
          ),
        ),
      ],
    );
  }
}
