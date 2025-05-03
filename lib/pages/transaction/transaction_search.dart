import 'dart:collection';

import 'package:badges/badges.dart' as badges;
import 'package:easy_sticky_header/easy_sticky_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';
import 'package:provider/provider.dart';

enum PageName { summary, all, income, expense, transfer }
enum SummaryType { name, category }

class TransactionSearchPage extends StatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  State<TransactionSearchPage> createState() => _TransactionSearchPageState();
}

class _TransactionSearchPageState extends State<TransactionSearchPage> {
  final TransactionHTTPService _transactionHttp = TransactionHTTPService();
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollControllerAll = ScrollController();
  final ScrollController _scrollControllerSummary = ScrollController();
  final ScrollController _scrollControllerIncome = ScrollController();
  final ScrollController _scrollControllerExpense = ScrollController();
  final ScrollController _scrollControllerTransfer = ScrollController();
  final ScrollController _walletController = ScrollController();

  final ScrollController _categoryController = ScrollController();

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

  final Map<PageName, Color> _resultPageColor = {
    PageName.summary: accentColors[1],
    PageName.all: accentColors[3],
    PageName.income: accentColors[6],
    PageName.expense: accentColors[2],
    PageName.transfer: accentColors[4],
  };

  String _searchText = "";
  String _categoryId = "";
  String _type = "name";

  int _resultPage = 1;
  PageName _resultPageName = PageName.all;

  late List<Widget> _expenseCategory;
  late List<Widget> _incomeCategory;

  final List<TransactionListModel> _transactions = [];
  final List<TransactionListModel> _filterTransactions = [];
  final List<TransactionListModel> _income = [];
  final List<TransactionListModel> _expense = [];
  final List<TransactionListModel> _transfer = [];

  final SplayTreeMap<String, List<TransactionListModel>> _summaryIncome = SplayTreeMap<String, List<TransactionListModel>>();
  final SplayTreeMap<String, List<TransactionListModel>> _summaryIncomeCategory = SplayTreeMap<String, List<TransactionListModel>>();
  
  final SplayTreeMap<String, List<TransactionListModel>> _summaryExpense = SplayTreeMap<String, List<TransactionListModel>>();
  final SplayTreeMap<String, List<TransactionListModel>> _summaryExpenseCategory = SplayTreeMap<String, List<TransactionListModel>>();
  
  final SplayTreeMap<String, List<TransactionListModel>> _summaryTransfer = SplayTreeMap<String, List<TransactionListModel>>();
  final SplayTreeMap<String, List<TransactionListModel>> _summaryTransferCategory = SplayTreeMap<String, List<TransactionListModel>>();

  final Map<String, double> _totalAmountTransfer = {};
  late Map<String, double> _totalAmountIncome;
  late Map<String, double> _totalAmountExpense;

  late List<Widget> _summaryList;
  final List<Widget> _summaryListName = [];
  final List<Widget> _summaryListCategory = [];

  final Map<int, CategoryModel> _categorySelected = {};
  late Map<int, CategoryModel> _categoryExpenseList;
  late Map<int, CategoryModel> _categoryIncomeList;

  late List<WalletModel> _walletList;
  final Map<int, bool> _selectedWalletList = {};

  late bool _isDescending;
  late HeaderType _filterType;
  late SummaryType _summaryType;
  final SplayTreeMap<int, Widget> _mapSubPage = SplayTreeMap<int, Widget>();
  final List<Widget> _subPage = [];

  @override
  void initState() {
    super.initState();

    // initialize variable
    _totalAmountIncome = {};
    _totalAmountExpense = {};
    
    _summaryList = [];

    _isDescending = true; // descending
    _filterType = HeaderType.date; // date
    _summaryType = SummaryType.name;

    // get the category expense and income list from shared preferences
    _categoryExpenseList = CategorySharedPreferences.getCategory(type: 'expense');
    _categoryIncomeList = CategorySharedPreferences.getCategory(type: 'income');

    // generate the icon list widget for both expense and income
    _expenseCategory = _generateExpenseIncomeCategoryWidget(data: _categoryExpenseList);
    _incomeCategory = _generateExpenseIncomeCategoryWidget(data: _categoryIncomeList);

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
    _categoryController.dispose();
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
                    screenRatio: 0.4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = HeaderType.name;
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
                          isSelected: (_filterType == HeaderType.name),
                        ),
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = HeaderType.date;
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
                          isSelected: (_filterType == HeaderType.date),
                        ),
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = HeaderType.category;
                            });
                            Navigator.pop(context);
                          }),
                          color: Colors.grey[900]!,
                          icon: Icon(
                            Ionicons.list_outline,
                            color: textColor2,
                            size: 15,
                          ),
                          title: "Category",
                          isSelected: (_filterType == HeaderType.category),
                        ),
                        SimpleItem(
                          onTap: (() {
                            setState(() {
                              _filterType = HeaderType.amount;
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
                          isSelected: (_filterType == HeaderType.amount),
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
          SortIcon(
            asc: !_isDescending,
            onPress: (() {
              setState(() {
                _isDescending = !_isDescending;
              });
            }),
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

  void _generateSubPageTplt<T>({required showHeader}) {
    // All transaction page
    _mapSubPage[PageName.all.index] = ListViewWithHeader<T>(
      controller: _scrollControllerAll,
      data: _filterTransactions,
      headerType: _filterType,
      showHeader: showHeader,
      reverse: _isDescending,
      onEdit: (txn) {
        // show the transaction edit screen
        _showTransactionEditScreen(txn);
      },
      onDelete: (txn) async {
        Log.info(message: "Delete (${txn.id}) ${txn.name}");

        // remove the transaction from the transaction list and group
        // again the transaction.
        await _deleteTransactionData(txn: txn);
      },
    );

    _mapSubPage[PageName.income.index] = ListViewWithHeader<T>(
      controller: _scrollControllerIncome,
      data: _income,
      headerType: _filterType,
      showHeader: showHeader,
      reverse: _isDescending,
      onEdit: (txn) {
        // show the transaction edit screen
        _showTransactionEditScreen(txn);
      },
      onDelete: (txn) async {
        Log.info(message: "Delete (${txn.id}) ${txn.name}");

        // remove the transaction from the transaction list and group
        // again the transaction.
        await _deleteTransactionData(txn: txn);
      },
    );

    _mapSubPage[PageName.expense.index] = ListViewWithHeader<T>(
      controller: _scrollControllerExpense,
      data: _expense,
      headerType: _filterType,
      showHeader: showHeader,
      reverse: _isDescending,
      onEdit: (txn) {
        // show the transaction edit screen
        _showTransactionEditScreen(txn);
      },
      onDelete: (txn) async {
        Log.info(message: "Delete (${txn.id}) ${txn.name}");

        // remove the transaction from the transaction list and group
        // again the transaction.
        await _deleteTransactionData(txn: txn);
      },
    );

    _mapSubPage[PageName.transfer.index] = ListViewWithHeader<T>(
      controller: _scrollControllerTransfer,
      data: _transfer,
      headerType: _filterType,
      showHeader: showHeader,
      reverse: _isDescending,
      onEdit: (txn) {
        // show the transaction edit screen
        _showTransactionEditScreen(txn);
      },
      onDelete: (txn) async {
        Log.info(message: "Delete (${txn.id}) ${txn.name}");

        // remove the transaction from the transaction list and group
        // again the transaction.
        await _deleteTransactionData(txn: txn);
      },
    );
  }

  void _generateSubPage() {
    // clear the map sub page
    _mapSubPage.clear();

    // check the header type so we knew what kind of type we can passed on the
    // list view with header.
    switch(_filterType) {
      case HeaderType.date:
        _generateSubPageTplt<DateTime>(showHeader: true);
        break;
      case HeaderType.name:
      case HeaderType.category:
        _generateSubPageTplt<String>(showHeader: true);
        break;
      case HeaderType.amount:
        _generateSubPageTplt<double>(showHeader: false);
        break;
    }

    // Summary Page
    _mapSubPage[PageName.summary.index] = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: SizedBox(
              width: (100 * _summaryItems.length).toDouble(),
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
          ),
        ),
        Expanded(
          child: StickyHeader(
            child: ListView.builder(
              controller: _scrollControllerSummary,
              itemCount: _summaryList.length,
              itemBuilder: ((context, index) {
                return _summaryList[index];
              })
            ),
          ),
        ),
      ],
    );

    // loop thru map and put on the sub page
    _subPage.clear();

    _mapSubPage.forEach((pageName, widget) {
      _subPage.add(widget);
    },);
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

    // generate the sub page
    _generateSubPage();

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
            child: IndexedStack(
              index: _resultPageName.index,
              children: _subPage,
            ),
          ),
        ],
      ),
    );
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

  Future<void> _showTransactionEditScreen(TransactionListModel txn) async {
    // go to the transaction edit for this txn
    await Navigator.pushNamed(
      context,
      '/transaction/edit',
      arguments: txn
    ).then(<TransactionListModel>(result) async {
      // check if we got return
      if (result != null) {
        // set state to rebuild the widget
        setState(() {
          // update the current transaction list based on the updated transaction
          for (int i = 0; i < _filterTransactions.length; i++) {
            // check which transaction is being updated
            if (_filterTransactions[i].id == result.id) {
              _filterTransactions[i] = result;
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
    // clear all the income, expense, and transfer
    _income.clear();
    _expense.clear();
    _transfer.clear();

    _summaryIncome.clear();
    _summaryIncomeCategory.clear();
    _totalAmountIncome.clear();

    _summaryExpense.clear();
    _summaryExpenseCategory.clear();
    _totalAmountExpense.clear();

    _summaryTransfer.clear();
    _summaryTransferCategory.clear();
    _totalAmountTransfer.clear();

    String summaryKey = "";
    String summaryKeyCategory = "";

    // now compute the summary data so we can showed it on the summary page
    // based on the income, and expense
    for (int i = 0; i < _filterTransactions.length; i++) {
      // generate the summary key
      if (
        _filterTransactions[i].type == 'expense' ||
        _filterTransactions[i].type == 'income'
      ) {
        summaryKey = "${_filterTransactions[i].wallet.currency}_${_filterTransactions[i].category != null ? _filterTransactions[i].category!.name : ''}_${_filterTransactions[i].name}_${_filterTransactions[i].type.toLowerCase()}";
        summaryKeyCategory = "${_filterTransactions[i].wallet.currency}_${_filterTransactions[i].category!.name}_${_filterTransactions[i].type.toLowerCase()}";
      } else {
        summaryKey = "${_filterTransactions[i].wallet.currency}_${_filterTransactions[i].walletTo!.currency}_${_filterTransactions[i].wallet.name}_${_filterTransactions[i].type.toLowerCase()}";
        summaryKeyCategory = "${_filterTransactions[i].wallet.currency}_${_filterTransactions[i].walletTo!.currency}_${_filterTransactions[i].type.toLowerCase()}";
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
      _generateSummaryBox(
        title: "Expense",
        color: accentColors[2],
        data: _totalAmountExpense,
        listItem: _summaryExpense,
        widget: _summaryListName,
        page: PageName.expense,
        summaryType: SummaryType.name,
      );
    }

    // check if we have expense category or not?
    if (_summaryExpenseCategory.isNotEmpty) {  
      // add the expense bar on the _summaryList
      _generateSummaryBox(
        title: "Expense",
        color: accentColors[2],
        data: _totalAmountExpense,
        listItem: _summaryExpenseCategory,
        widget: _summaryListCategory,
        page: PageName.expense,
        summaryType: SummaryType.category,
      );
    }

    // check if summary income is not empty
    if (_summaryIncome.isNotEmpty) {
      // add the income bar on the _summaryListName
      _generateSummaryBox(
        title: "Income",
        color: accentColors[6],
        data: _totalAmountIncome,
        listItem: _summaryIncome,
        widget: _summaryListName,
        page: PageName.income,
        summaryType: SummaryType.name,
      );
    }

    // check if summary income is not empty
    if (_summaryIncomeCategory.isNotEmpty) {
      // add the income bar on the _summaryListCategory
      _generateSummaryBox(
        title: "Income",
        color: accentColors[6],
        data: _totalAmountIncome,
        listItem: _summaryIncomeCategory,
        widget: _summaryListCategory,
        page: PageName.income,
        summaryType: SummaryType.category,
      );
    }

    // check if summary transfer is not empty
    if (_summaryTransfer.isNotEmpty) {
      // add the transfer bar on the _summaryListName
      _generateSummaryBox(
        title: "Transfer",
        color: accentColors[4],
        data: _totalAmountTransfer,
        listItem: _summaryTransfer,
        widget: _summaryListName,
        page: PageName.transfer,
        summaryType: SummaryType.name,
      );
    }

    // check if summary transfer is not empty
    if (_summaryTransferCategory.isNotEmpty) {
      // add the transfer bar on the _summaryListCategory
      _generateSummaryBox(
        title: "Transfer",
        color: accentColors[4],
        data: _totalAmountTransfer,
        listItem: _summaryTransferCategory,
        widget: _summaryListCategory,
        page: PageName.transfer,
        summaryType: SummaryType.category,
      );
    }

    // set initial summary list
    _setSummaryList();
  }

  void _generateSummaryBox({
    required String title,
    required Color color,
    required Map<String, double> data,
    required Map<String, List<TransactionListModel>> listItem,
    required List<Widget> widget,
    required PageName page,
    required SummaryType summaryType,
  }) {
    _generateSubSummaryBox(
      title: title,
      data: data,
      color: color,
      listItem: listItem,
      page: page,
      summaryType: summaryType,
      widget: widget,
    );
  }

  void _generateSubSummaryBox({
    required String title,
    required Map<String, double> data,
    required Color color,
    required Map<String, List<TransactionListModel>> listItem,
    required List<Widget> widget,
    required PageName page,
    required SummaryType summaryType,
  }) {
    final Map<String, Map<String, TransactionListModel>> subSummary = {};
    double amount;
    DateTime? startDate;
    DateTime? endDate;
    int count;
    int index;
    String subSummaryKey = "";
    TransactionListModel tmpSubSummaryData;

    // add the title
    widget.add(Container(
      padding: const EdgeInsets.all(10),
      color: secondaryDark,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ));

    // loop thru all the currency we have for this summary list item data
    index = 0;
    data.forEach((currencySymbol, value) {
      // add the index for the sticky header
      index = index + 1;
      
      widget.add(StickyContainerWidget(
        index: index,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
          color: primaryDark,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "Total $currencySymbol",
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
        ),
      ));

      // add for the list item for summary data
      // clear subSummary
      subSummary.clear();

      // loop thru all the list item data
      listItem.forEach((key, value) {
        // get the current currency symbol
        List<String> keyCheck = key.split('_');
        
        // check if the currencySymbol is the same as the key
        if (keyCheck[0].toLowerCase() == currencySymbol.toLowerCase()) {
          // initialize the data
          amount = 0;
          startDate = null;
          endDate = null;
          count = 0;

          // create the sub summary expense for this key
          subSummary[key] = {};

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
            if (!subSummary[key]!.containsKey(subSummaryKey)) {
              // if not exists create the 1st data
              subSummary[key]![subSummaryKey] = TransactionListModel(
                -1,
                data.name,
                data.type,
                DateTime(data.date.year, data.date.month, 1).toLocal(),
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
              tmpSubSummaryData = subSummary[key]![subSummaryKey]!;
              // and combine it with current data
              subSummary[key]![subSummaryKey] = TransactionListModel(
                -1,
                data.name,
                data.type,
                DateTime(data.date.year, data.date.month, 1).toLocal(),
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
          TransactionListModel txn;
          if (page == PageName.expense || page == PageName.income) {
            if (summaryType == SummaryType.name) {
              txn = TransactionListModel(
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
                1,
              );
            }
            else {
              txn = TransactionListModel(
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
                1,
              );
            }
          }
          else {
            if (summaryType == SummaryType.name) {
              txn = TransactionListModel(
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
                1,
              );
            }
            else {
              txn = TransactionListModel(
                -1,
                "${value[0].wallet.name} to ${value[0].walletTo!.name}",
                value[0].type,
                DateTime.now(),
                '',
                value[0].category,
                value[0].wallet,
                null,
                value[0].usersPermissionsUser,
                true,
                amount,
                1,
              );
            }
          }

          widget.add(
            TransactionExpandableItem(
              txn: txn,
              startDate: startDate!,
              endDate: endDate!,
              count: count,
              subTxn: (subSummary[key] ?? {}),
              showCategory: (summaryType != SummaryType.category),
            )
          );
        }
      });
    });
  }

  void _setTransactions({
    required List<TransactionListModel> transactions,
  }) {
    setState(() {
      _transactions.clear();
      _transactions.addAll(transactions);

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
  }) async {
    await _transactionHttp.findTransaction(
      type: type,
      name: searchText,
      category: categoryId,
    ).then((results) {
      _setTransactions(
        transactions: results,
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
    _transactions.clear();

    // try to find the transaction
    await _findTransaction(
      searchText: _searchText,
      categoryId: _categoryId,
      type: _type,
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
          child: CategoryModalSelector(
            expense: _expenseCategory,
            income: _incomeCategory
          ),
        );
      }
    );
  }

  List<Widget> _generateChipCategory() {
    List<Widget> result = [];

    // loop thru the category selected
    _categorySelected.forEach((key, category) {
      result.add(InkWell(
        onTap: (() {
          // remove this chip from the _categorySelected
          setState(() {
            _categorySelected.remove(key);
            if (category.type == 'expense') {
              _expenseCategory = _generateExpenseIncomeCategoryWidget(data: _categoryExpenseList);
            }
            else {
              _incomeCategory = _generateExpenseIncomeCategoryWidget(data: _categoryIncomeList);
            }
          });
        }),
        child: Chip(
          avatar: _categoryIcon(
            type: category.type,
            name: category.name,
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
              if (category.type == 'expense') {
                _expenseCategory = _generateExpenseIncomeCategoryWidget(data: _categoryExpenseList);
              }
              else {
                _incomeCategory = _generateExpenseIncomeCategoryWidget(data: _categoryIncomeList);
              }
            });
          },
          label: Text(category.name),
          backgroundColor: (
            category.type == 'expense' ?
            IconColorList.getExpenseColor(category.name) :
            IconColorList.getIncomeColor(category.name)
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

  List<Widget> _generateExpenseIncomeCategoryWidget({
    required Map<int, CategoryModel> data
  }) {
    List<Widget> categories = [];

    // loop thru data to generate the widget
    data.forEach((key, category) {
      categories.add(
        GestureDetector(
          onTap: () {
            // check if user already selected 10 categories or not?
            if (_categorySelected.length < 10) {
              setState(() {
                _categorySelected[category.id] = category;
                // check whether this is expense or income
                if (category.type == 'expense') {
                  _expenseCategory = _generateExpenseIncomeCategoryWidget(data: _categoryExpenseList);
                }
                else {
                  _incomeCategory = _generateExpenseIncomeCategoryWidget(data: _categoryIncomeList);
                }
              });
              Navigator.pop(context);
            }
            else {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                createSnackBar(
                  message: "Maximum selected category is 10"
                )
              );
            }
          },
          child: CategoryItem(
            category: category,
            isSelected: (_categorySelected.containsKey(category.id)),
            showText: true,
          ),
        )
      );
    },);

    return categories;
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

  Future<void> _deleteTransactionData({required TransactionListModel txn}) async {
    // show the loading function
    LoadingScreen.instance().show(context: context);
    
    // call delete API function
    await _transactionHttp.deleteTransaction(txn: txn).then((_) async {
      // if delete success, delete the transaction from the transaction list
      int txnLocation = -1;
      String txnDate = Globals.dfyyyyMMdd.formatLocal(txn.date);
      for (int i=0; i<_transactions.length; i++) {
        // check if the txn ID is the same or not?
        if (_transactions[i].id == txn.id) {
          txnLocation = i;
          break;
        }
      }

      // check and ensure that txnLocation is >= 0
      if (txnLocation >= 0) {
        // remove from _transactions list
        _transactions.removeAt(txnLocation);

        // then we can call the filter and group transaction again
        _filterTheTransaction();
        _groupTransactions();
      }

      // now try to check if we have this data on the shared preferences or not?
      List<TransactionListModel> txnListModel = TransactionSharedPreferences.getTransaction(txnDate) ?? [];
      if (txnListModel.isNotEmpty) {
        // loop thru the txnListModel to see which transaction is being delete
        // initialize back the txnLocation
        txnLocation = -1;

        // loop thru txnListModel
        for(int i=0; i<txnListModel.length; i++) {
          // check if the txn ID is the same or not?
          if (txnListModel[i].id == txn.id) {
            txnLocation = i;
            break;
          }
        }

        // check txnLocation, whether this is more than or equal to 0
        if (txnLocation >= 0) {
          txnListModel.removeAt(txnLocation);

          // stored the new txnListModel to the shared preferences
          await TransactionSharedPreferences.setTransaction(date: txnDate, txn: txnListModel);
        }
      }

      // then check whether current transaction is also showed in the home list
      // or not? if being showed, then need to notify provider to refresh the
      // home list
      DateTime currentTxnListDate = (TransactionSharedPreferences.getTransactionListCurrentDate() ?? DateTime.now().toLocal());
      if (txn.date.isSameDate(date: currentTxnListDate)) {
        // refresh also the home list
        if (mounted) {
          // pop the transaction from the provider
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).popTransactionList(transaction: txn);
        }
      }

      // once all finished we can update the information
      await _updateInformation(txn: txn);
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error when delete",
        error: error,
        stackTrace: stackTrace,
      );
    }).whenComplete(() {
      // remove the loading screen
      LoadingScreen.instance().hide();
    });

    // setState to rebuild the widget
    setState(() {
    });
  }

  Future<void> _updateInformation({
    required TransactionListModel txn
  }) async {
    String refreshDay = Globals.dfyyyyMMdd.formatLocal(
      DateTime(
        txn.date.toLocal().year,
        txn.date.toLocal().month,
        1
      )
    );

    DateTime from;
    DateTime to;
    String fromString;
    String toString;

    // get the stat date
    (from, to) = TransactionSharedPreferences.getStatDate();

    // format the from and to string
    fromString = Globals.dfyyyyMMdd.formatLocal(from);
    toString = Globals.dfyyyyMMdd.formatLocal(to);

    // delete the transaction from wallet transaction
    await TransactionSharedPreferences.deleteTransactionWallet(
      walletId: txn.wallet.id,
      date: refreshDay,
      txn: txn
    );

    if (txn.walletTo != null) {
      await TransactionSharedPreferences.deleteTransactionWallet(
        walletId: txn.walletTo!.id,
        date: refreshDay,
        txn: txn
      );
    }

    // delete the transaction from budget
    await WalletSharedPreferences.deleteWalletWorth(txn: txn);

    List<WalletModel> wallets = [];
    List<BudgetModel> budgets = [];
    await Future.wait([
      _walletHTTP.fetchWallets(
        showDisabled: true,
        force: true,
      ).then((resp) {
        wallets = resp;
      }),
      _budgetHTTP.fetchBudgetDate(
        currencyID: txn.wallet.currencyId,
        date: refreshDay
      ).then((resp) {
        budgets = resp;
      }),
    ]).then((_) {
      // update the wallets
      if (mounted) {
        Provider.of<HomeProvider>(
          context,
          listen: false
        ).setWalletList(wallets: wallets);
      }

      // store the budgets list
      if (txn.type == "expense") {
        // now loops thru budget, and see if the current category fits or not?
        for (int i = 0; i < budgets.length; i++) {
          if (txn.category!.id == budgets[i].category.id) {
            // as this is expense, subtract total transaction and the amount
            BudgetModel newBudget = BudgetModel(
              id: budgets[i].id,
              category: budgets[i].category,
              totalTransaction: (budgets[i].totalTransaction - 1),
              amount: budgets[i].amount,
              used: budgets[i].used - txn.amount,
              useForDaily: budgets[i].useForDaily,
              status: budgets[i].status,
              currency: budgets[i].currency
            );

            budgets[i] = newBudget;
            // break from for loop
            break;
          }
        }
        // now we can set the shared preferences of budget
        BudgetSharedPreferences.setBudget(
          ccyId: txn.wallet.currencyId,
          date: refreshDay,
          budgets: budgets
        );

        // only set the provider if only the current budget date is the same as the refresh day
        String currentBudgetDate = BudgetSharedPreferences.getBudgetCurrent();
        if (currentBudgetDate == refreshDay && mounted) {
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setBudgetList(budgets: budgets);
        }
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "Error on update information",
        error: error,
        stackTrace: stackTrace,
      );
      throw Exception(error.toString());
    });

    // check if the txn date is within the from and to of the stat date
    if (
      txn.date.isWithin(from: from, to: to) &&
      (txn.type == "expense" || txn.type == "income")
    ) {
      // fetch the income expense
      await _transactionHttp.fetchIncomeExpense(
        ccyId: txn.wallet.currencyId,
        from: from,
        to: to,
        force: true,
      ).then((result) {
        if (mounted) {
          // put on the provider and notify the listener
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setIncomeExpense(
            ccyId: txn.wallet.currencyId,
            data: result
          );
        }
      }).onError((error, stackTrace) {
        Log.error(
          message: "Error on fetch income expense",
          error: error,
          stackTrace: stackTrace,
        );
        throw Exception(error.toString());
      });

      // fetch the top transaction
      await _transactionHttp.fetchTransactionTop(
        type: txn.type,
        ccy: txn.wallet.currencyId,
        from: fromString,
        to: toString,
        force: true
      ).then((transactionTop) {
        if (mounted) {
          // set the provide for this
          Provider.of<HomeProvider>(
            context,
            listen: false
          ).setTopTransaction(
            ccy: txn.wallet.currencyId,
            type: txn.type,
            data: transactionTop
          );
        }
      }).onError(
        (error, stackTrace) {
          Log.error(
            message: "Error on fetch top transaction",
            error: error,
            stackTrace: stackTrace,
          );
          throw Exception(error.toString());
        },
      );
    }
  }
}
