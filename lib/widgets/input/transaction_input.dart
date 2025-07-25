import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_simple_calculator/flutter_simple_calculator.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

enum TransactionInputType {
  add, edit
}

class TransactionInput extends StatefulWidget {
  final String title;
  final TransactionInputType type;
  final TransactionInputCallback saveTransaction;
  final TransactionListModel? currentTransaction;
  final DateTime? selectedDate;
  
  const TransactionInput({
    super.key,
    required this.title,
    required this.type,
    required this.saveTransaction,
    this.currentTransaction,
    this.selectedDate
  });

  @override
  State<TransactionInput> createState() => _TransactionInputState();
}

class _TransactionInputState extends State<TransactionInput> {
  final ScrollController _optionController = ScrollController();
  final ScrollController _autoCompleteController = ScrollController();
  final ScrollController _walletController = ScrollController();
  final ScrollController _transferFromWalletController = ScrollController();
  final ScrollController _transferToWalletController = ScrollController();
  final ScrollController _accountTypeController = ScrollController();

  final TextEditingController _nameController  = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();
  final TextEditingController _repeatController = TextEditingController();
  final TextEditingController _timesController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();

  final Map<String, TypeSlideItem> _txnTypeSlideItem = {
    "expense": TypeSlideItem(
      color: accentColors[2],
      text: "Expense",
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
    "income": TypeSlideItem(
      color: accentColors[0],
      text: "Income",
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
    "transfer": TypeSlideItem(
      color: accentColors[4],
      text: "Transfer",
      textColor: Colors.white.withValues(alpha: 0.7),
    ),
  };

  final Map<String, TypeSlideItem> _txnSingleRepeatItem = {
    "single": TypeSlideItem(
      color: accentColors[0],
      icon: Ionicons.remove_outline,
      iconColor: Colors.white.withValues(alpha: 0.7),
    ),
    "repeat": TypeSlideItem(
      color: accentColors[4],
      icon: Ionicons.repeat,
      iconColor: Colors.white.withValues(alpha: 0.7),
    ),
  };

  late UsersMeModel _userMe;

  late DateTime _currentDate;
  final DateTime _todayDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day
  );
  final Map<String, String> _repeatMap = {
    "day": "Day",
    "week": "Week",
    "month": "Month",
    "year": "Year",
  };

  late Map<int, CategoryModel> _currentCategoryList;

  late String _currentType;

  late int? _currentCategoryID;
  late String _currentCategoryName;
  late Icon _currentCategoryIcon;
  late Color _currentCategoryColor;

  late int _currentWalletFromID;
  late String _currentWalletFromName;
  late String _currentWalletFromType;
  late String _currentWalletFromCCY;

  late int _currentWalletToID;
  late String _currentWalletToName;
  late String _currentWalletToType;
  late String _currentWalletToCCY;

  late bool _currentClear;
  late String _currentTransactionRepeatType;
  late String _currentRepeatType;
  late int _currentRepeat;
  late int _currentTimes;
  late List<double> _amountList;
  late bool _fullAmount;

  late double _currentExchangeRate;

  late double _currentAmount;
  late double _conversionAmount;

  late List<LastTransactionModel> _filterList;
  late List<LastTransactionModel> _lastExpense;
  late List<LastTransactionModel> _lastIncome;
  late List<WalletModel> _walletList;
  late List<WalletModel> _walletListAll;
  late bool _isDisabled;
  
  final Map<String, List<WalletModel>> _walletMap = {};
  final Map<String, String> _accountMap = {};

  late bool _showCalendar;
  late bool _showDescription;

  @override
  void initState() {
    super.initState();

    // get ME
    _userMe = UserSharedPreferences.getUserMe();

    // check whether selected date is null or not?
    if (widget.selectedDate == null) {
      // if null then use current date
      _currentDate = _todayDate;
    }
    else {
      // if not set the current date as per selected date give by the parent
      // widget.
      _currentDate = (DateTime(widget.selectedDate!.year, widget.selectedDate!.month, widget.selectedDate!.day));
    }
    // once we got the date, convert the current date to local here
    _currentDate = _currentDate.toLocal();

    // get the default current amount
    _currentAmount = 0;
    _conversionAmount = 0;
    if (widget.currentTransaction != null) {
      _currentAmount = widget.currentTransaction!.amount;
      _conversionAmount = widget.currentTransaction!.amount * widget.currentTransaction!.exchangeRate;
    }

    // check the type by checkiung if we send current transaction or not?
    if (widget.currentTransaction == null) {
      // it means that this is add
      _currentType = "expense";
    }
    else {
      _currentType = widget.currentTransaction!.type;
    }

    // set clear as true
    _currentClear = true;

    // set repeat as single
    _currentTransactionRepeatType = 'single';

    // default repeat type as month
    _currentRepeatType = 'month';

    // initialize the filter list and get the last expense and income
    // transaction to build the auto complete
    _filterList = [];
    _lastExpense = (TransactionSharedPreferences.getLastTransaction(type: "expense") ?? []);
    _lastIncome = (TransactionSharedPreferences.getLastTransaction(type: "income") ?? []);

    // get the list of enabled wallet
    _walletList = WalletSharedPreferences.getWallets(showDisabled: false);

    // generate wallet map
    _generateWalletMap();
    
    // get the list of disabled wallet if needed
    _walletListAll = WalletSharedPreferences.getWallets(showDisabled: true);

    // default the _isDisabled to false
    _isDisabled = false;

    // set the show calendar as false
    _showCalendar = false;
    _showDescription = false;
    
    // initialize all value needed for add and edit
    switch (widget.type) {
      case TransactionInputType.add:
        _initAdd();
        break;
      case TransactionInputType.edit:
        _initEdit();
        break;
    }
  }

  @override
  void dispose() {
    _optionController.dispose();
    _autoCompleteController.dispose();
    _walletController.dispose();
    _transferFromWalletController.dispose();
    _transferToWalletController.dispose();
    _accountTypeController.dispose();

    // name fields
    _nameFocus.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _exchangeController.dispose();
    _repeatController.dispose();
    _timesController.dispose();
    
    super.dispose();
  }

  void _initAdd() {
    if (widget.currentTransaction != null) {
      // put the current item name to the name controller
      _nameController.text = widget.currentTransaction!.name;

      // set the current date as today date
      _currentDate = _todayDate;

      // set for the correct category
      // check whether this is transfer or not first.
      if (_currentType == 'transfer') {
        // default the category icon and color as transfer
        _currentCategoryName = "";
        _currentCategoryColor = accentColors[4];
        _currentCategoryIcon = const Icon(
          Ionicons.repeat,
          color: textColor,
        );
      }
      else {
        // get the actual category icon and color for this transaction
        _getCurrentCategoryIconAndColor(
          categoryId: widget.currentTransaction!.category!.id,
        );
      }
    }
    else {
      // get the current category and icon
      _getCurrentCategoryIconAndColor();
    }

    // set exchange rate as 1 (assuming that we will always send the same CCY)
    _currentExchangeRate = 1;
    _exchangeController.text = Globals.fCCY2.format(_currentExchangeRate);

    // default the repeat and times
    _repeatController.text = "1";
    _timesController.text = "3";
    _currentRepeat = 1;
    _currentTimes = 3;
    _amountList = [];
    _fullAmount = false;

    // set default user from and to
    _getUserFromWalletInfo(walletId: _userMe.defaultWallet);
    _getUserToWalletInfo(name: "To Wallet");
  }

  void _initEdit() {
    // put the current item name to the name controller
    _nameController.text = widget.currentTransaction!.name;
    
    // set the current wallet being used
    _getUserFromWalletInfo(walletId: widget.currentTransaction!.wallet.id);

    // set the selected date based on the current transaction date
    _currentDate = widget.currentTransaction!.date;

    // set the clear
    _currentClear = widget.currentTransaction!.cleared;

    // set the exchange rate
    _currentExchangeRate = widget.currentTransaction!.exchangeRate;
    _exchangeController.text = Globals.fCCY2.format(_currentExchangeRate);

    // set the description
    _descriptionController.text = widget.currentTransaction!.description;

    // check if this is transfer?
    // since for transfer we will have the To Wallet also
    if (_currentType == 'transfer') {
      // default the category icon and color as transfer
      _currentCategoryName = "";
      _currentCategoryColor = accentColors[4];
      _currentCategoryIcon = const Icon(
        Ionicons.repeat,
        color: textColor,
      );

      // get the to wallet for transfer
      _getUserToWalletInfo(walletId: widget.currentTransaction!.walletTo!.id);
    }
    else {
      // get the actual category icon and color for this transaction
      _getCurrentCategoryIconAndColor(categoryId: widget.currentTransaction!.category!.id);
      
      // just initialize the to wallet
      _getUserToWalletInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.title)),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Ionicons.close,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              // check if transaction being disabled due to one of the wallets
              // are disabled.
              if (!_isDisabled) {
                // call parent save, all the handler on the async call should be
                // coming from the parent instead here.
                try {
                  List<TransactionModel> gen = [];

                  // default isOkay to false
                  bool isOkay = false;

                  gen = _generateTransaction();

                  // if all good then check the date whether this is future date
                  // or not?
                  if (_currentDate.isAfter(_todayDate.toLocal())) {
                    // show the dialog to ask user if they want to add future date
                    // transaction or else?
                    
                    late Future<bool?> result = ShowMyDialog(
                        dialogTitle: "Future Date",
                        dialogText: "Are you sure want to ${widget.type == TransactionInputType.add ? "add" : "update"} a future date?",
                        confirmText: "Add",
                        confirmColor: accentColors[0],
                        cancelText: "Cancel"
                    ).show(context);

                    await result.then((value) {
                      // check whether user press Add or Cancel
                      if(value == true) {
                        // user still want to add so add this transaction
                        isOkay = true;
                      }
                    });
                  }
                  else {
                    // same date, so just save the transaction
                    isOkay = true;
                  }

                  // check whether generated transaction have more than 1
                  // transaction or not?
                  if (
                    widget.type == TransactionInputType.add &&
                    gen.length > 1 &&
                    isOkay
                  ) {
                    // set isOkay to false again as we will ask user wheter
                    // they want to save all transaction or not?
                    isOkay = false;

                    DateTime firstDate = gen[0].date;
                    DateTime lastDate = gen[gen.length-1].date;

                    if (context.mounted) {                        
                      late Future<bool?> result = ShowMyDialog(
                          dialogTitle: "Repeat Transaction",
                          dialogText: "This will automatically add ${gen.length} transactions from ${Globals.dfddMMyyyy.formatLocal(firstDate)} until ${Globals.dfddMMyyyy.formatLocal(lastDate)}?",
                          confirmText: "Add",
                          confirmColor: accentColors[0],
                          cancelText: "Cancel"
                      ).show(context);

                      await result.then((value) {
                        // check whether user press Add or Cancel
                        if(value == true) {
                          // user still want to add so add this transaction
                          isOkay = true;
                        }
                      });
                    }
                  }

                  // check whether it's okay or not
                  if (isOkay) {
                    // save the transaction
                    widget.saveTransaction(gen);
                  }
                }
                catch(error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      createSnackBar(
                        message: error.toString().replaceAll('Exception: ', ''),
                      )
                    );
                  }
                }
              }
            },
            icon: Icon(
              Ionicons.checkmark,
              color: (_isDisabled ? primaryLight : Colors.white),
            ),
          ),
          const SizedBox(width: 10,),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
            color: secondaryDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Visibility(
                  visible: _isDisabled,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: primaryDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text("Unable to edit wallet is disabled")
                    ),
                  ),
                ),
                const SizedBox(height: 10,),
                Center(
                  child: SizedBox(
                    width: (100 * _txnTypeSlideItem.length).toDouble(),
                    child: TypeSlide<String>(
                      initialItem: _currentType,
                      editable: (widget.type == TransactionInputType.add ? true : false),
                      onValueChanged: ((selected) {
                        setState(() {
                          _currentType = selected.toLowerCase();
                    
                          // if type is transfer, change the name into "From Wallet"
                          // instead of wallet only
                          if (_currentType == 'transfer') {
                            _getUserFromWalletInfo(
                              walletId: _currentWalletFromID,
                              name: "From Wallet"
                            );
                          }
                          else {
                            _getUserFromWalletInfo(
                              walletId: _currentWalletFromID,
                              name: "Wallet"
                            );
                          }
                          _getCurrentCategoryIconAndColor();
                        });
                      }),
                      items: _txnTypeSlideItem,
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                _buildInput(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _optionController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Visibility(
                    visible: (_currentType == 'transfer'),
                    child: _buildTransferWalletSelection()
                  ),
                  Visibility(
                    visible: (
                      _currentType == 'transfer' &&
                      (_currentWalletFromID > 0 && _currentWalletToID > 0) &&
                      (_currentWalletFromCCY != _currentWalletToCCY)
                    ),
                    child: Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10,),
                          const Icon(
                            Ionicons.swap_horizontal_sharp,
                            size: 20,
                            color: textColor,
                          ),
                          const SizedBox(width: 10,),
                          Expanded(
                            child: TextFormField(
                              controller: _exchangeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              cursorColor: primaryLight,
                              decoration: const InputDecoration(
                                hintText: "1.00",
                                hintStyle: TextStyle(
                                  color: primaryLight,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.zero,
                                isCollapsed: true,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(12),
                                DecimalTextInputFormatter(decimalRange: 11),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _currentExchangeRate = (double.tryParse(value) ?? 1);
                                  _conversionAmount = _currentAmount * _currentExchangeRate;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10,),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!_isDisabled) {
                        setState(() {
                          if (_showDescription) {
                            _showDescription = !_showDescription;
                          }
                          _showCalendar = !_showCalendar;
                        });
                      }
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Ionicons.calendar_outline,
                            size: 20,
                            color: textColor,
                          ),
                          const SizedBox(width: 10,),
                          Text(_calendarText()),
                        ],
                      ),
                    ),
                  ),
                  AnimationExpand(
                    expand: _showCalendar,
                    child: SizedBox(
                      height: 200,
                      child: ScrollDatePicker(
                        initialDate: _currentDate.toLocal(),
                        minDate: DateTime(2010, 1, 1),
                        barColor: accentColors[0],
                        selectedColor: primaryDark,
                        onDateChange: ((val) {
                          setState(() {
                            _currentDate = val.toLocal();
                          });
                        }),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: (_currentType != 'transfer'),
                    child: _buildIncomeExpenseWalletSelection(),
                  ),
                  ..._repeatTransactionInput(),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Ionicons.checkbox_outline,
                          size: 20,
                          color: textColor,
                        ),
                        const SizedBox(width: 10,),
                        const Expanded(child: Text("Cleared")),
                        CupertinoSwitch(
                          value: _currentClear,
                          activeTrackColor: accentColors[0],
                          inactiveTrackColor: primaryLight,
                          onChanged: (_isDisabled ? null : (value) {
                            setState(() {
                              _currentClear = value;
                            });
                          }),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!_isDisabled) {
                        setState(() {
                          if(_showCalendar) {
                            _showCalendar = false;
                          }
                          _showDescription = !_showDescription;
                        });
                      }
                    },
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Ionicons.newspaper_outline,
                            size: 20,
                            color: textColor,
                          ),
                          const SizedBox(width: 10,),
                          Text(
                            (_descriptionController.text.trim().isEmpty ? "Description" : _descriptionController.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimationExpand(
                    expand: _showDescription,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: TextFormField(
                        controller: _descriptionController,
                        cursorColor: textColor.withValues(alpha: 0.6),
                        keyboardType: TextInputType.multiline,
                        maxLines: 8,
                        maxLength: 250,
                        decoration: const InputDecoration(
                          hintText: "Input description",
                          hintStyle: TextStyle(
                            color: primaryLight,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: textColor,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: textColor,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    )
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    if (_currentType == 'transfer') {
      return _buildInputTransfer();
    }
    else {
      return _buildInputExpenseIncome();
    }
  }

  Widget _buildInputTransfer() {
    bool isShowConversionAmount = false;

    // check if we have transfer to account
    if (
      (_currentWalletFromID > 0 && _currentWalletToID > 0) &&
      (_currentWalletFromCCY != _currentWalletToCCY)
    ) {
      isShowConversionAmount = true;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: _currentCategoryColor,
          ),
          child: _currentCategoryIcon,
        ),
        const SizedBox(width: 10,),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const Text(
                "Transfer",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5,),
            ],
          ),
        ),
        const SizedBox(width: 5,),
        Expanded(
          flex: 4,
          child: GestureDetector(
            onTap: (() async {
              if (!_isDisabled) {
                await _showCalculator();
      
                // check if both the current exchange rate and current amount
                // is not zero
                if (_currentAmount > 0 && _currentExchangeRate > 0) {
                  // calculate the conversion amount
                  setState(() {
                    _conversionAmount = _currentAmount * _currentExchangeRate;
                  });
                }
              }
            }),
            onDoubleTap: () async {
              if (!_isDisabled) {
                if (_currentAmount > 0) {
                  await _showCalculator(currentAmount: false);
        
                  // check if both the current exchange rate and current amount
                  // is not zero
                  if (_currentAmount > 0 && _conversionAmount > 0) {
                    // calculate the conversion amount
                    setState(() {
                      _currentExchangeRate = _conversionAmount / _currentAmount;
                      _exchangeController.text = Globals.fCCY2.format(_currentExchangeRate);
                    });
                  }
                }
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                AutoSizeText(
                  (isShowConversionAmount ? "${_currentWalletFromCCY.toUpperCase()} ${Globals.fCCY.format(_currentAmount)}" : Globals.fCCY.format(_currentAmount)),
                  style: const TextStyle(
                    fontSize: 25,
                    color: textColor,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                ),
                (isShowConversionAmount ? AutoSizeText(
                  (isShowConversionAmount ? "${_currentWalletToCCY.toUpperCase()} ${Globals.fCCY.format(_conversionAmount)}" : Globals.fCCY.format(_conversionAmount)),
                  style: const TextStyle(
                    fontSize: 18,
                    color: secondaryLight,
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                ) : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputExpenseIncome() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            if (!_isDisabled) {
              // show the modal bottom sheet
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  String title = "";
                  if (_currentType == 'income') {
                    title = "Income Category";
                  }
                  else {
                    title = "Expense Category";
                  }

                  return MyBottomSheet(
                    context: context,
                    title: title,
                    screenRatio: 0.75,
                    child:  GridView.count(
                      crossAxisCount: 4,
                      children: _generateIconCategory(),
                    ),
                  );
                }
              );
            }
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: _currentCategoryColor,
            ),
            child: _currentCategoryIcon,
          ),
        ),
        const SizedBox(width: 10,),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                enabled: (!_isDisabled),
                enableSuggestions: false,
                cursorColor: textColor.withValues(alpha: 0.6),
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  hintText: "Item name",
                  hintStyle: TextStyle(
                    color: primaryLight,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
                onChanged: ((lookup) {
                  // generate the auto complete
                  _filterAutoComplete(lookup);
                }),
                onTap: (() {
                  _filterAutoComplete(_nameController.text);
                }),
                onFieldSubmitted: ((value) async {
                  // ensure that the value got some length, before we focus
                  // on the amount controller
                  if(value.trim().isNotEmpty) {
                    // check whether we already have amount or not?
                    // if already have amount, then we don't need to show the
                    // calculator again, as it might be user input the amount
                    // first, then put the name later.
                    if (_currentAmount <= 0) {
                      // show the calculator
                      await _showCalculator();
                    }
                    else {
                      // check if name has focus or not?
                      if (_nameFocus.hasFocus) {
                        // unfocus from name text field
                        _nameFocus.unfocus();
                      }
                    }
                  }
                }),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 5,),
              Container(
                padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: Text(_currentCategoryName),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5,),
        Expanded(
          flex: 4,
          child: GestureDetector(
            onTap: (() async {
              if (!_isDisabled) {
                await _showCalculator();
              }
            }),
            child: AutoSizeText(
              Globals.fCCY.format(_currentAmount),
              style: const TextStyle(
                fontSize: 25,
                color: textColor,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCalculator({bool currentAmount = true}) async {
    // check if name has focus or not?
    if (_nameFocus.hasFocus) {
      // unfocus from name text field
      _nameFocus.unfocus();
    }

    // show the calculator on the modal bottom sheet
    return showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: false,
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                color: secondaryDark,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: (() {
                      Navigator.pop(context);
                    }),
                    onDoubleTap: (() async {
                      // remove the calculator first
                      Navigator.pop(context);
                      
                      // check whether this is expense/income/transfer
                      if (_currentType == 'transfer') {
                        // show the to account selection for transfer
                        await _showAccountSelection(
                          title: "From Account",
                          selectedId: _currentWalletFromID,
                          disableID: _currentWalletToID,
                          onTap: ((wallet) async {
                            // set the current wallet from and showed the account
                            // selection for the to account directly
                            setState(() {
                              _currentWalletFromID = wallet.id;
                              _currentWalletFromName = wallet.name;
                              _currentWalletFromType = wallet.walletType.type.toLowerCase();
                              _currentWalletFromCCY = wallet.currency.name.toLowerCase();
                            });

                            // show the to account selection
                            await _showAccountSelection(
                              title: "To Account",
                              selectedId: _currentWalletToID,
                              disableID: _currentWalletFromID,
                              onTap: ((wallet) {
                                setState(() {
                                  _currentWalletToID = wallet.id;
                                  _currentWalletToName = wallet.name;
                                  _currentWalletToType = wallet.walletType.type.toLowerCase();
                                  _currentWalletToCCY = wallet.currency.name.toLowerCase();
                                });
                              })
                            );
                          }),
                        );
                      }
                      else {
                        // show the to account selection for expense/income
                        await _showAccountSelection(
                          title: "From Account",
                          selectedId: _currentWalletFromID,
                          onTap: ((wallet) {
                            setState(() {
                              _currentWalletFromID = wallet.id;
                              _currentWalletFromName = wallet.name;
                              _currentWalletFromType = wallet.walletType.type.toLowerCase();
                              _currentWalletFromCCY = wallet.currency.name.toLowerCase();
                            });
                          })
                        );
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(50, 10, 10, 10),
                      color: Colors.transparent,
                      child: const Text(
                        "DONE",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ),
                ),
              ),
              Expanded(
                child: SimpleCalculator(
                  value: (currentAmount ? _currentAmount : _conversionAmount),
                  hideExpression: false,
                  hideSurroundingBorder: true,
                  autofocus: true,
                  theme: CalculatorThemeData(
                    operatorColor: Colors.orange[600],
                    equalColor: Colors.orange[800],
                  ),
                  maximumDigits: 14,
                  numberFormat: Globals.fCCYnf,
                  onChanged: (key, value, expression) {
                    setState(() {
                      if (currentAmount) {
                        // set the current amount as previous current amount if value is null
                        _currentAmount = (value ?? _currentAmount);
                      }
                      else {
                        // it means that this is for the conversion amount
                        _conversionAmount = (value ?? _conversionAmount);
                      }

                      // generate the list amount
                      _generateListAmount();
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAccountSelection({
    required String title,
    required int selectedId,
    int disableID = -1,
    required Function(WalletModel) onTap,
  }) async {
    // IconData disableIcon;
    // Color? disableColor;
    // bool isDisabled = false;
    
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return AccountSelector(
          title: title,
          accountMap: _accountMap,
          walletMap: _walletMap,
          selectedID: selectedId,
          onTap: onTap,
          disableID: disableID,
          screenRatio: 0.50,
        );
      }
    );
  }

  Widget _buildIncomeExpenseWalletSelection() {
    return GestureDetector(
      onTap: () async {
        if (!_isDisabled) {
          await _showAccountSelection(
            title: "Account",
            selectedId: _currentWalletFromID,
            onTap: ((wallet) {
              setState(() {
                _currentWalletFromID = wallet.id;
                _currentWalletFromName = wallet.name;
                _currentWalletFromType = wallet.walletType.type.toLowerCase();
                _currentWalletFromCCY = wallet.currency.name.toLowerCase();
              });
            })
          );
        }
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
        ),
        child: Row(
          children: [
            const Icon(
              Ionicons.wallet_outline,
              size: 20,
              color: textColor,
            ),
            const SizedBox(width: 10,),
            Text(_currentWalletFromName),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferWalletSelection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(width: 30,),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (!_isDisabled) {
                  await _showAccountSelection(
                    title: "From Account",
                    selectedId: _currentWalletFromID,
                    disableID: _currentWalletToID,
                    onTap: ((wallet) async {
                      // set the current wallet from and showed the account
                      // selection for the to account directly
                      setState(() {
                        _currentWalletFromID = wallet.id;
                        _currentWalletFromName = wallet.name;
                        _currentWalletFromType = wallet.walletType.type.toLowerCase();
                        _currentWalletFromCCY = wallet.currency.name.toLowerCase();
                      });

                      // show the to account selection
                      await _showAccountSelection(
                        title: "To Account",
                        selectedId: _currentWalletToID,
                        disableID: _currentWalletFromID,
                        onTap: ((wallet) {
                          setState(() {
                            _currentWalletToID = wallet.id;
                            _currentWalletToName = wallet.name;
                            _currentWalletToType = wallet.walletType.type.toLowerCase();
                            _currentWalletToCCY = wallet.currency.name.toLowerCase();
                          });
                        })
                      );
                    }),
                  );
                }
              },
              child: Container(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: (_currentWalletFromType.isNotEmpty ? IconList.getColor(_currentWalletFromType) : accentColors[4]),
                      ),
                      child: _getTransferOutIcon(_currentWalletFromType),
                    ),
                    const SizedBox(height: 5,),
                    Text((_currentWalletFromName.isNotEmpty ? _currentWalletFromName : "From Account")),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10,),
          const SizedBox(
            height: 40,
            child: Icon(
              Ionicons.git_compare_sharp,
              size: 40,
              color: primaryLight,
            ),
          ),
          const SizedBox(width: 10,),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (!_isDisabled) {
                  await _showAccountSelection(
                    title: "To Account",
                    selectedId: _currentWalletToID,
                    disableID: _currentWalletFromID,
                    onTap: ((wallet) {
                      setState(() {
                        _currentWalletToID = wallet.id;
                        _currentWalletToName = wallet.name;
                        _currentWalletToType = wallet.walletType.type.toLowerCase();
                        _currentWalletToCCY = wallet.currency.name.toLowerCase();
                      });
                    })
                  );
                }
              },
              child: Container(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: (_currentWalletToType.isNotEmpty ? IconList.getColor(_currentWalletToType) : Colors.grey[600]),
                      ),
                      child: _getTransferInIcon(_currentWalletToType),
                    ),
                    const SizedBox(height: 5,),
                    Text((_currentWalletToName.isNotEmpty ? _currentWalletToName : "To Account")),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 30,),
        ],
      ),
    );
  }

  Widget _getTransferInIcon(String name) {
    if(name.isNotEmpty) {
      return IconList.getIcon(name.toLowerCase());
    }
    else {
      return const Icon(
        Ionicons.download,
        size: 20,
        color: textColor,
      );
    }
  }

  Widget _getTransferOutIcon(String name) {
    if(name.isNotEmpty) {
      return IconList.getIcon(name.toLowerCase());
    }
    else {
      return const Icon(
        Ionicons.push,
        size: 20,
        color: textColor,
      );
    }
  }

  Widget _buildBottomBar() {
    if (_nameFocus.hasFocus) {
      return _buildAutoComplete();
    }
    else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAutoComplete() {
    // if we don't have filter list then just return sized box shrink.
    if (_filterList.isEmpty) {
      return const SizedBox.shrink();
    }

    // other than that we can generate the auto complete
    return Container(
      height: 35,
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      width: MediaQuery.of(context).size.width,
      color: secondaryDark,
      child: TextFieldTapRegion(
        child: ListView.builder(
          controller: _autoCompleteController,
          itemCount: (_filterList.length > 50 ? 50 : _filterList.length),
          scrollDirection: Axis.horizontal,
          itemBuilder: ((context, index) {
            return GestureDetector(
              onTap: (() async {
                // set automatically the name controller text, and the category
                // based on the auto complete selection
                setState(() {
                  _nameController.text = _filterList[index].name;
                  _getCurrentCategoryIconAndColor(categoryId: _filterList[index].category.id);
                });

                // check if we already have amount or not?
                // if already have amount, then no need to showed the calculator
                // as user might be already put the amount before input name
                if (_currentAmount <= 0) {
                  // show the calculator
                  await _showCalculator();
                }
                else {
                  // check if name has focus or not?
                  if (_nameFocus.hasFocus) {
                    // unfocus from name text field
                    _nameFocus.unfocus();
                  }
                }
              }),
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                padding: const EdgeInsets.fromLTRB(2, 2, 10, 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: IconColorList.getColor(_filterList[index].category.name, _currentType),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconColorList.getIcon(
                        _filterList[index].category.name,
                        _currentType,
                        14,
                        IconColorList.getColor(_filterList[index].category.name, _currentType),
                      ),
                    ),
                    const SizedBox(width: 5,),
                    Center(child: Text(_filterList[index].name)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _generateIconCategory() {
    List<Widget> ret = [];

    // loop thru all the _currentCategoryList, and generate the category icon
    _currentCategoryList.forEach((key, value) {
      ret.add(_iconCategory(value));
    });

    return ret;
  }

  Widget _iconCategory(CategoryModel category) {
    // check if this is expense or income
    Color iconColor;
    Icon icon;

    if(category.type.toLowerCase() == "expense") {
      iconColor = IconColorList.getExpenseColor(category.name.toLowerCase());
      icon = IconColorList.getExpenseIcon(category.name.toLowerCase());
    } else {
      iconColor = IconColorList.getIncomeColor(category.name.toLowerCase());
      icon = IconColorList.getIncomeIcon(category.name.toLowerCase());
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentCategoryID = category.id;
          _currentCategoryName = category.name;
          _currentCategoryColor = iconColor;
          _currentCategoryIcon = icon;
        });
        Navigator.pop(context);
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
              ),
              child: icon,
            ),
          ),
          Center(
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
        ],
      ),
    );
  }

  List<Widget> _repeatTransactionInput() {
    // if this is edit then no need to show this
    if (widget.type != TransactionInputType.add || _currentType == 'transfer') {
      return const [SizedBox.shrink()];
    }

    List<Widget> ret = [];
    ret.add(
        Container(
        height: 50,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Ionicons.repeat,
              size: 20,
              color: textColor,
            ),
            const SizedBox(width: 10,),
            Expanded(child: Text("${_currentTransactionRepeatType.substring(0,1).toUpperCase()}${_currentTransactionRepeatType.substring(1).toLowerCase()}")),
            const SizedBox(width: 10,),
            SizedBox(
              width: 80,
              child: TypeSlide<String>(
                onValueChanged: ((value) {
                  setState(() {                
                    _currentTransactionRepeatType = value;
                  });
                }),
                items: _txnSingleRepeatItem,
                initialItem: "single",
                editable: (widget.type == TransactionInputType.add ? true : false),
              ),
            )
          ],
        ),
      ),
    );

    ret.add(
      AnimationExpand(
        expand: _currentTransactionRepeatType == 'repeat',
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text("Every"),
                  const SizedBox(width: 10,),
                  Container(
                    width: 50,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextFormField(
                      controller: _repeatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      cursorColor: primaryLight,
                      decoration: const InputDecoration(
                        hintText: "2",
                        hintStyle: TextStyle(
                          color: primaryLight,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: ((value) {
                        setState(() {                      
                          // convert the current times
                          _currentRepeat = (int.tryParse(value) ?? 0);
                          _generateListAmount();
                        });
                      }),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  MySelector(
                    data: _repeatMap,
                    initialKeys: "month",
                    onChange: ((key) {
                      setState(() {                        
                        _currentRepeatType = key;
                        _generateListAmount();
                      });
                    }),
                  ),
                  const SizedBox(width: 10,),
                  Container(
                    width: 50,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextFormField(
                      controller: _timesController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      cursorColor: primaryLight,
                      decoration: const InputDecoration(
                        hintText: "1",
                        hintStyle: TextStyle(
                          color: primaryLight,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: ((value) {
                        setState(() {                      
                          // convert the current times
                          _currentTimes = (int.tryParse(value) ?? 0);
                          _generateListAmount();
                        });
                      }),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Text("times"),
                ],
              ),
              const SizedBox(height: 5,),
              Row(
                children: [
                  const Expanded(child: Text("Same amount transaction")),
                  CupertinoSwitch(
                    value: _fullAmount,
                    activeTrackColor: accentColors[0],
                    inactiveTrackColor: primaryLight,
                    onChanged: (_isDisabled ? null : (value) {
                      setState(() {
                        _fullAmount = value;
                        _generateListAmount();
                      });
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 5,),
              _paymentList(),
            ],
          )
        ),
      )
    );

    return ret;
  }

  Widget _paymentList() {
    if (_amountList.isEmpty) {
      return const SizedBox.shrink();
    }

    DateTime date = _currentDate;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: secondaryLight,
          width: 1.0,
          style: BorderStyle.solid,
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: List<Widget>.generate(_amountList.length, (index) {
          Border border;
          if (index < (_amountList.length - 1)) {
            border = Border(
              bottom: BorderSide(
                color: secondaryLight,
                width: 1.0,
                style: BorderStyle.solid,
              )
            );
          }
          else {
            border = Border();
          }

          switch(_currentRepeatType) {
            case "day":
              date = _currentDate.add(Duration(days: (_currentRepeat * index)));
              break;
            case "week":
              date = _currentDate.add(Duration(days: ((_currentRepeat * index) * 7)));
              break;
            case "month":
              date = DateTime(
                _currentDate.year,
                _currentDate.month + index,
                _currentDate.day
              );
              break;
            case "year":
              date = DateTime(
                _currentDate.year + index,
                _currentDate.month,
                _currentDate.day
              );
              break;
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: border,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Center(child: Text("${index + 1}")),
                ),
                Expanded(
                  flex: 2,
                  child: Text(Globals.dfddMMMyyyy.formatLocal(date)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _amountList[index].formatCurrency(shorten: false, decimalNum: 2),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10,),
                GestureDetector(
                  onTap: (() {
                    if (index > 0) {
                      _swapAmountList(index - 1, index);
                    }
                  }),
                  child: Container(
                    width: 20,
                    height: 20,
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Ionicons.caret_up,
                        size: 15,
                        color: secondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5,),
                GestureDetector(
                  onTap: (() {
                    if (index < (_amountList.length - 1)) {
                      _swapAmountList(index, index + 1);
                    }
                  }),
                  child: Container(
                    width: 20,
                    height: 20,
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        Ionicons.caret_down,
                        size: 15,
                        color: secondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },),
      ),
    );
  }

  void _swapAmountList(int a, int b) {
    if (_amountList.isNotEmpty) {
      if (_amountList.length >= a && (b < _amountList.length)) {
        setState(() {
          double tmp = _amountList[a];
          _amountList[a] = _amountList[b];
          _amountList[b] = tmp;
          
        });
      }
    }
  }

  void _generateListAmount() {
    // only do for transaction add
    if (widget.type == TransactionInputType.add) {
      // ensure times more than 0
      if (
          _currentAmount > 0 &&
          _currentTimes > 1 &&
          _currentRepeat > 0
        ) {
        // clear the list amount
        _amountList.clear();

        // check if the full amount is true or not?
        if (_fullAmount) {
          _amountList = List<double>.generate(_currentTimes, (index) {
            return _currentAmount;
          },);
        }
        else {
          // get the calculated amount
          double paymentAmount = _currentAmount / _currentTimes;

          // now format the amount to double digit only
          String paymentAmountString = paymentAmount.toStringAsFixed(2);
          // convertt back from string to double
          try {
            paymentAmount = double.parse(paymentAmountString);

            // generate the list amount
            _amountList = List<double>.generate(_currentTimes, (index) {
              return paymentAmount;
            },);

            // now calculate if the total payment amount equal with the total amount
            // we need to put
            double totalPaymentAmount = paymentAmount * _currentTimes;

            double addSubPayment = 0.01;
            if (totalPaymentAmount > _currentAmount) {
              addSubPayment = -0.01;
            }

            int i = 0;
            while(_currentAmount != totalPaymentAmount && i < _amountList.length) {
              // check if i is odd
              if ((i % 2 == 1)) {
                _amountList[i] = paymentAmount + addSubPayment;
              }

              // check current totalPaymentAmount
              totalPaymentAmount = 0;
              for (double amount in _amountList) {
                totalPaymentAmount = totalPaymentAmount + amount;
              }

              // next i
              i = i + 1;
            }
          }
          catch(e) {
            throw Exception("Error when convert the payment amount");
          }
        }
      }
    }
  }

  void _filterAutoComplete(String lookup) {
    List<LastTransactionModel> filter = [];

    // clear the last found
    _filterList.clear();

    // check what is the current type so we know which data we need to look for
    if(_currentType == "expense") {
      // look at expense
      for (LastTransactionModel element in _lastExpense) {
        if(element.name.toLowerCase().contains(lookup.toLowerCase())) {
          // add this element to _lastFound
          filter.add(element);
        }
      }
    }
    else {
      for (LastTransactionModel element in _lastIncome) {
        if(element.name.toLowerCase().contains(lookup.toLowerCase())) {
          // add this element to _lastFound
          filter.add(element);
        }
      }
    }

    setState(() {
      _filterList = filter;
    });
  }

  void _getCurrentCategoryIconAndColor({int? categoryId}) {
    if (_currentType == 'transfer') {
      _currentCategoryName = "";
      _currentCategoryColor = accentColors[4];
      _currentCategoryIcon = const Icon(
        Ionicons.repeat,
        color: textColor,
      );
    }
    else {
      // get current category list based on current type
      _currentCategoryList = CategorySharedPreferences.getCategory(type: _currentType);

      // check if we got category id or not?
      if (categoryId != null) {
        _currentCategoryID  = categoryId;
      }
      else {
        // select whether this is income or expense
        if (_currentType == "expense") {
          _currentCategoryID = _userMe.defaultCategoryExpense;
        }
        else {
          _currentCategoryID = _userMe.defaultCategoryIncome;
        }
      }

      // check if we have default category or not?
      if ((_currentCategoryID ?? 0) > 0) {
        _currentCategoryName = _currentCategoryList[_currentCategoryID]!.name;
        _currentCategoryColor = IconColorList.getColor(
                                  _currentCategoryName,
                                  _currentType
                                );
        _currentCategoryIcon = IconColorList.getIcon(
                                  _currentCategoryName,
                                  _currentType
                                );
      }
      else {
        _currentCategoryName = "Select Category";
        _currentCategoryColor = textColor2;
        _currentCategoryIcon = const Icon(
          Ionicons.file_tray_full,
          color: Colors.black,
        );
      }
    }
  }

  String _calendarText() {
    if(_currentDate.isSameDate(date: DateTime.now())) {
      return "Today";
    }
    else {
      // format selected date with Day, dd MMM yyyy
      return Globals.dfeMMMMddyyyy.formatLocal(_currentDate);
    }
  }

  void _getUserFromWalletInfo({int? walletId, String? name}) {
    // default the value of wallet information
    _currentWalletFromID = -1;
    _currentWalletFromName = (name ?? "Wallet");
    _currentWalletFromType = "";
    _currentWalletFromCCY = "";

    // check if wallet ID more than 0, if so then we can default the wallet
    // with the one user selected.
    if ((walletId ?? 0) > 0) {
      // loop thru wallet list and set the correct info to the wallet
      for(int i = 0; i < _walletListAll.length; i++) {
        // check if the wallet id is the same as the one being sent?
        if (walletId! == _walletListAll[i].id) {
          _currentWalletFromID = walletId;
          _currentWalletFromName = _walletListAll[i].name;
          _currentWalletFromType = _walletListAll[i].walletType.type.toLowerCase();
          _currentWalletFromCCY = _walletListAll[i].currency.name.toLowerCase();

          // check whether this wallet is enabled or not?
          if (!_walletListAll[i].enabled) {
            _isDisabled = true;
          }
        }
      }
    }
  }

  void _getUserToWalletInfo({int? walletId, String? name}) {
    // check whether wallet ID is being set or not? and if being set ensure
    // the ID is > 0.
    if ((walletId ?? 0) <= 0) {
      // just put default value for the wallet selection.
      _currentWalletToID = -1;
      _currentWalletToName = (name ?? "Wallet");
      _currentWalletToType = "";
      _currentWalletToCCY = "";
    }
    else {
      // loop thru wallet list and set the correct info to the wallet
      for(int i = 0; i < _walletListAll.length; i++) {
        // check if the wallet id is the same as the one being sent?
        if (walletId! == _walletListAll[i].id) {
          _currentWalletToID = walletId;
          _currentWalletToName = _walletListAll[i].name;
          _currentWalletToType = _walletListAll[i].walletType.type.toLowerCase();
          _currentWalletToCCY = _walletListAll[i].currency.name.toLowerCase();

          // check whether this wallet is enabled or not?
          if (!_walletListAll[i].enabled) {
            _isDisabled = true;
          }
        }
      }
    }
  }

  void _generateWalletMap() {
    // clear wallet map and account map
    _walletMap.clear();
    _accountMap.clear();

    // add the default All in the account map
    _accountMap['all'] = 'All';

    // create list for default all tab
    _walletMap['all'] = [];

    // loop thru wallet list to get the wallet type, and add it to the wallet map
    String walletKey;
    for(int i=0; i<_walletList.length; i++) {
      // get current wallet key
      walletKey = _walletList[i].walletType.type;

      // check if this key already exists in wallet map or not?
      if (!_walletMap.containsKey(walletKey)) {
        // create the new list for this key
        _walletMap[walletKey] = [];
        _accountMap[walletKey] = walletKey;
      }

      // add this wallet to the wallet map
      _walletMap['all']!.add(_walletList[i]);
      _walletMap[walletKey]!.add(_walletList[i]);
    }
  }

  List<TransactionModel> _generateTransaction() {
    List<TransactionModel> ret = [];
    
    double? currentAmount;
    WalletCategoryTransactionModel? category;
    WalletCategoryTransactionModel walletFrom;
    WalletCategoryTransactionModel? walletTo;
    WalletCategoryTransactionModel usersPermissionsUser = WalletCategoryTransactionModel(_userMe.id);
    DateTime txnDate = _currentDate;
    String description = _descriptionController.text.trim();

    // if this is expense or income, check for name and category
    if (_currentType == 'expense' || _currentType == 'income') {
      if (_nameController.text.trim().isEmpty) {
        throw Exception('Name is mandatory for $_currentType');
      }
      else {
        // ensure the name length is >= 2
        if (_nameController.text.trim().length < 2) {
          throw Exception('Minimum length for name are 2');
        }
      }

      // check category
      if ((_currentCategoryID ?? 0) < 0) {
        throw Exception('Please select $_currentType category');
      }
      else {
        category = WalletCategoryTransactionModel(_currentCategoryID!);
      }

      // check whether this is repeat transaction or not?
      if (_currentTransactionRepeatType == 'repeat') {
        if (_currentTimes <= 1) {
          throw Exception('Repeat times should be more than 1');
        }

        if (_currentRepeat <= 0) {
          throw Exception('Repeat value should be more than 0');
        }
      }
    }

    // check if the amount is not empty
    if (_currentAmount <= 0) {
      throw Exception('Amount should be more than 0');
    }
    else {
      // we got the amount, clamp the result to 2 digit
      currentAmount = num.parse(_currentAmount.toStringAsFixed(2)).toDouble();
    }

    // check if wallet already selected or not?
    if (_currentWalletFromID <= 0) {
      // wallet not yet selected
      throw Exception('Select wallet');
    }
    else {
      walletFrom = WalletCategoryTransactionModel(_currentWalletFromID);
    }

    // if this is transfer then the to wallet should be selected also
    if (_currentType == 'transfer') {
      // check the to wallet id
      if (_currentWalletToID <= 0) {
        throw Exception('Select destination wallet');
      }
      else {
        // create the walletTo
        walletTo = WalletCategoryTransactionModel(_currentWalletToID);
      }

      // default the category as -1, since transfer doesn't have any category
      // it's just movement of money.
      category = WalletCategoryTransactionModel(-1);

      // default the _currentExchangeRate as 1
      _currentExchangeRate = 1;

      // check if wallet from and to have different currency ID
      if (_currentWalletFromCCY != _currentWalletToCCY) {
        // try to convert the exchange rate text fields
        try {
          _currentExchangeRate = double.parse(_exchangeController.text.trim());
        }
        catch (error) {
          throw Exception('Invalid exchange rate');          
        }

        // ensure exchange rate should be more than 0
        if (_currentExchangeRate <= 0) {
          // exchange rate should be more than 0
          throw Exception('Exchange rate should be more than 0');
        }
      }
    }

    // check if we have single transaction or multiple transaction?
    if (
        _currentTransactionRepeatType == 'repeat' &&
        _currentTimes > 1 &&
        _currentRepeat > 0 &&
        _currentType != 'transfer'
      ) {
      if (_currentTimes == _amountList.length) {
        // loop thru times
        for(int i=0; i<_currentTimes; i++) {
          // if times more than 1, add description automatically
          if (_currentTimes > 1) {
            description = '${_nameController.text.trim()} transaction ${i+1} of $_currentTimes\n${_descriptionController.text.trim()}';
          }

          // generate the transaction model
          ret.add(
            TransactionModel(
              _nameController.text.trim(),
              _currentType,
              category,
              txnDate,
              walletFrom,
              _currentClear,
              description,
              usersPermissionsUser,
              _amountList[i],
              walletTo,
              _currentExchangeRate
            )
          );

          // generate the next date
          switch(_currentRepeatType) {
            case "day":
              txnDate = txnDate.add(Duration(days: _currentRepeat));
              break;
            case "week":
              txnDate = txnDate.add(Duration(days: (_currentRepeat * 7)));
              break;
            case "month":
              txnDate = DateTime(
                txnDate.year,
                txnDate.month + 1,
                txnDate.day
              );
              break;
            case "year":
              txnDate = DateTime(
                txnDate.year + 1,
                txnDate.month,
                txnDate.day
              );
              break;
          }
        }
      }
      else {
        throw Exception('Amount list is not yet generated');
      }
    }
    else {
      // generate the transaction model
      ret.add(
        TransactionModel(
          _nameController.text.trim(),
          _currentType,
          category,
          txnDate,
          walletFrom,
          _currentClear,
          description,
          usersPermissionsUser,
          currentAmount,
          walletTo,
          _currentExchangeRate
        )
      );
    }

    return ret;
  }
}