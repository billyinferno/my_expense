import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_simple_calculator/flutter_simple_calculator.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/model/category_model.dart';
import 'package:my_expense/model/last_transaction_model.dart';
import 'package:my_expense/model/transaction_list_model.dart';
import 'package:my_expense/model/transaction_model.dart';
import 'package:my_expense/model/users_me_model.dart';
import 'package:my_expense/model/wallet_model.dart';
import 'package:my_expense/themes/category_icon_list.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/themes/icon_list.dart';
import 'package:my_expense/utils/misc/decimal_formatter.dart';
import 'package:my_expense/utils/misc/my_callback.dart';
import 'package:my_expense/utils/misc/show_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_category.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/input/type_slide.dart';
import 'package:my_expense/widgets/item/expand_animation.dart';
import 'package:my_expense/widgets/item/simple_item.dart';
import 'package:table_calendar/table_calendar.dart';


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

  final TextEditingController _nameController  = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  
  final fCCY = NumberFormat("0.00", "en_US");

  late UsersMeModel _userMe;

  late DateTime _currentDate;
  final DateTime _todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day); 

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

  late double _currentExchangeRate;

  late double _currentAmount;
  late double _currentAmountFontSize;

  late List<LastTransactionModel> _filterList;
  late List<LastTransactionModel> _lastExpense;
  late List<LastTransactionModel> _lastIncome;
  late List<WalletModel> _walletList;

  late bool _showCalendar;
  late bool _showDescription;

  @override
  void initState() {
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
    if (widget.currentTransaction != null) {
      _currentAmount = widget.currentTransaction!.amount;
    }

    // text field variable
    // default font size of the amount text field to 25
    if (_currentAmount <= 0) {
      _currentAmountFontSize = 25;
    }
    else {
      // calculate the actual current amount font size
      _currentAmountFontSize = min(25, 25 - ((10/6) * (fCCY.format(_currentAmount).length - 6)));
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

    // initialize the filter list and get the last expense and income
    // transaction to build the auto complete
    _filterList = [];
    _lastExpense = (TransactionSharedPreferences.getLastTransaction("expense") ?? []);
    _lastIncome = (TransactionSharedPreferences.getLastTransaction("income") ?? []);

    // get the list of enabled wallet
    _walletList = WalletSharedPreferences.getWallets(false);

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

    super.initState();
  }

  @override
  void dispose() {
    _optionController.dispose();
    _autoCompleteController.dispose();
    _walletController.dispose();
    _transferFromWalletController.dispose();
    _transferToWalletController.dispose();

    // name fields
    _nameFocus.dispose();
    _nameController.dispose();

    _descriptionController.dispose();
    _exchangeController.dispose();
    
    super.dispose();
  }

  void _initAdd() {
    // get the current category and icon
    _getCurrentCategoryIconAndColor();

    // set exchange rate as 1 (assuming that we will always send the same CCY)
    _currentExchangeRate = 1;
    _exchangeController.text = fCCY.format(_currentExchangeRate);

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
    _exchangeController.text = fCCY.format(_currentExchangeRate);

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
              // call parent save, all the handler on the async call should be
              // coming from the parent instead here.
              try {
                TransactionModel? gen = _generateTransaction();

                // if all good then check the date whether this is future date
                // or not?
                if (_currentDate.isAfter(_todayDate.toLocal())) {
                  // show the dialog to ask user if they want to add future date
                  // transaction or else?
                  
                  late Future<bool?> result = ShowMyDialog(
                      dialogTitle: "Future Date",
                      dialogText: "Are you sure want to add a future date?.",
                      confirmText: "Add",
                      confirmColor: accentColors[0],
                      cancelText: "Cancel"
                  ).show(context);

                  await result.then((value) {
                    // check whether user press Add or Cancel
                    if(value == true) {
                      // user still want to add so add this transaction
                      widget.saveTransaction(gen);
                    }
                  });
                }
                else {
                  // same date, so just save the transaction
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
            },
            icon: const Icon(
              Ionicons.checkmark,
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
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            color: secondaryDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                TypeSlide(
                  type: _currentType,
                  editable: (widget.type == TransactionInputType.add ? true : false),
                  onChange: ((selected) {
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
                  items: <String, Color>{
                    "Expense": accentColors[2],
                    "Income": accentColors[0],
                    "Transfer": accentColors[4],
                  },
                ),
                const SizedBox(height: 20,),
                _buildInput(),
              ],
            ),
          ),
          const SizedBox(height: 10,),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
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
                                decoration: const InputDecoration(
                                  hintText: "1.00",
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_showDescription) {
                            _showDescription = !_showDescription;
                          }
                          _showCalendar = !_showCalendar;
                        });
                      },
                      child: Container(
                        height: 50,
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
                        child: CupertinoTheme(
                          data: const CupertinoThemeData(
                            brightness: Brightness.dark,
                            textTheme: CupertinoTextThemeData(
                              textStyle: TextStyle(
                                fontFamily: '--apple-system',
                                fontSize: 20,
                              ),
                              dateTimePickerTextStyle: TextStyle(
                                fontFamily: '--apple-system',
                                fontSize: 20,
                              ),
                            )
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: _currentDate.toLocal(),
                            onDateTimeChanged: (val) {
                              setState(() {
                                _currentDate = val.toLocal();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: (_currentType != 'transfer'),
                      child: _buildIncomeExpenseWalletSelection(),
                    ),
                    Container(
                      height: 50,
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
                            onChanged: (value) {
                              setState(() {
                                _currentClear = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if(_showCalendar) {
                            _showCalendar = false;
                          }
                          _showDescription = !_showDescription;
                        });
                      },
                      child: Container(
                        height: 50,
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
                          keyboardType: TextInputType.multiline,
                          maxLines: 8,
                          maxLength: 250,
                          decoration: const InputDecoration(
                            hintText: "Input description",
                          ),
                        ),
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: _currentCategoryColor,
            ),
            child: _currentCategoryIcon,
          ),
          onTap: () {
            // only show the modal bottom sheet if this is not transfer
            if (_currentType != 'transfer')
            {
              // show the modal bottom sheet
              showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                return Container(
                  height: 300,
                  color: secondaryDark,
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Center(child: Text("Category Tab")),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 4,
                          children: _generateIconCategory(),
                        ),
                      ),
                    ],
                  ),
                );
              });
            }
          },
        ),
        const SizedBox(width: 10,),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Visibility(
                visible: (_currentType != 'transfer'),
                child: TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  enableSuggestions: false,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    hintText: "Item name",
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
                      // show the calculator
                      await _showCalculator();
                    }
                  }),
                  textInputAction: TextInputAction.done,
                ),
              ),
              Visibility(
                visible: (_currentType == 'transfer'),
                child: const Text(
                  "Transfer",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5,),
              Visibility(
                visible: (_currentType != 'transfer'),
                child: Text(_currentCategoryName)
              ),
            ],
          ),
        ),
        const SizedBox(width: 10,),
        SizedBox(
          width: 120,
          child: GestureDetector(
            onTap: (() async {
              await _showCalculator();
            }),
            child: Text(
              fCCY.format(_currentAmount),
              style: TextStyle(
                fontSize: _currentAmountFontSize,
                color: textColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCalculator() async {
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
                  value: _currentAmount,
                  hideExpression: false,
                  hideSurroundingBorder: true,
                  autofocus: true,
                  theme: CalculatorThemeData(
                    operatorColor: Colors.orange[600],
                  ),
                  maximumDigits: 14,
                  onChanged: (key, value, expression) {
                    setState(() {
                      // set the current amount as previous current amount if value is null
                      _currentAmount = (value ?? _currentAmount);

                      // convert to fccy and convert back to current amount
                      _currentAmount = (double.tryParse(fCCY.format(_currentAmount)) ?? 0);

                      // calculate the current amount font size
                      _currentAmountFontSize = min(25, 25 - ((10/6) * (fCCY.format(_currentAmount).length - 6)));
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

  Widget _buildIncomeExpenseWalletSelection() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
          return Container(
            height: 300,
            color: secondaryDark,
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                  ),
                  child: const Center(child: Text("Account")),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _walletController,
                    itemCount: _walletList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return SimpleItem(
                        color: IconList.getColor(_walletList[index].walletType.type.toLowerCase()),
                        description: _walletList[index].name,
                        isSelected: (_currentWalletFromID == _walletList[index].id),
                        onTap: (() {
                          setState(() {
                            _currentWalletFromID = _walletList[index].id;
                            _currentWalletFromName = _walletList[index].name;
                            _currentWalletFromType = _walletList[index].walletType.type.toLowerCase();
                            _currentWalletFromCCY = _walletList[index].currency.name.toLowerCase();
                          });
                          Navigator.pop(context);
                        }),
                        child: IconList.getIcon(_walletList[index].walletType.type.toLowerCase()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20,),
              ],
            ),
          );
        });
      },
      child: Container(
        height: 50,
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
              onTap: () {
                showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                  return _transferWalletSelection(
                    controller: _transferFromWalletController,
                    title: "From Account",
                    wallets: _walletList,
                    selectedId: _currentWalletFromID,
                    onTap: (index) {
                      setState(() {
                        _currentWalletFromID = _walletList[index].id;
                        _currentWalletFromName = _walletList[index].name;
                        _currentWalletFromType = _walletList[index].walletType.type.toLowerCase();
                        _currentWalletFromCCY = _walletList[index].currency.name.toLowerCase();
                      });
                    },
                  );
                });
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
              onTap: () {
                showModalBottomSheet<void>(context: context, builder: (BuildContext context) {
                  return _transferWalletSelection(
                    controller: _transferToWalletController,
                    title: "To Account",
                    wallets: _walletList,
                    selectedId: _currentWalletFromID,
                    onTap: (index) {
                      setState(() {
                        _currentWalletToID = _walletList[index].id;
                        _currentWalletToName = _walletList[index].name;
                        _currentWalletToType = _walletList[index].walletType.type.toLowerCase();
                        _currentWalletToCCY = _walletList[index].currency.name.toLowerCase();
                      });
                    },
                  );
                });
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
                        color: (_currentWalletToType.isNotEmpty ? IconList.getColor(_currentWalletToType) : accentColors[5]),
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

  Widget _transferWalletSelection({
    required ScrollController controller,
    required String title,
    required List<WalletModel> wallets,
    required int selectedId,
    required Function(int) onTap,
  }) {
    return Container(
      height: 300,
      color: secondaryDark,
      child: Column(
        children: <Widget>[
          Container(
            height: 40,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: Text(title)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: wallets.length,
              itemBuilder: (BuildContext context, int index) {
                return SimpleItem(
                  color: IconList.getColor(wallets[index].walletType.type.toLowerCase()),
                  description: wallets[index].name,
                  isSelected: (selectedId == wallets[index].id),
                  onTap: (() {
                    onTap(index);
                    Navigator.pop(context);
                  }),
                  child: IconList.getIcon(wallets[index].walletType.type.toLowerCase()),
                );
              },
            ),
          ),
          const SizedBox(height: 20,),
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

                // show the calculator
                await _showCalculator();
              }),
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  color: IconColorList.getColor(_filterList[index].category.name, _currentType),
                ),
                child: Center(child: Text(_filterList[index].name)),
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
        //print("Select category");
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
      _currentCategoryList = CategorySharedPreferences.getCategory(_currentType);

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
    if(isSameDay(_currentDate.toLocal(), DateTime.now().toLocal())) {
      return "Today";
    }
    else {
      // format selected date with Day, dd MMM yyyy
      return DateFormat('E, MMMM dd, yyyy').format(_currentDate.toLocal());
    }
  }

  void _getUserFromWalletInfo({int? walletId, String? name}) {
    // check whether wallet ID is being set or not? and if being set ensure
    // the ID is > 0.
    if ((walletId ?? 0) <= 0) {
      // just put default value for the wallet selection.
      _currentWalletFromID = -1;
      _currentWalletFromName = (name ?? "Wallet");
      _currentWalletFromType = "";
      _currentWalletFromCCY = "";  
    }
    else {
      // loop thru wallet list and set the correct info to the wallet
      for(int i = 0; i < _walletList.length; i++) {
        // check if the wallet id is the same as the one being sent?
        if (walletId! == _walletList[i].id) {
          _currentWalletFromID = walletId;
          _currentWalletFromName = _walletList[i].name;
          _currentWalletFromType = _walletList[i].walletType.type.toLowerCase();
          _currentWalletFromCCY = _walletList[i].currency.name.toLowerCase();  
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
      for(int i = 0; i < _walletList.length; i++) {
        // check if the wallet id is the same as the one being sent?
        if (walletId! == _walletList[i].id) {
          _currentWalletToID = walletId;
          _currentWalletToName = _walletList[i].name;
          _currentWalletToType = _walletList[i].walletType.type.toLowerCase();
          _currentWalletToCCY = _walletList[i].currency.name.toLowerCase();  
        }
      }
    }
  }

  TransactionModel? _generateTransaction() {
    double? currentAmount;
    WalletCategoryTransactionModel? category;
    WalletCategoryTransactionModel walletFrom;
    WalletCategoryTransactionModel? walletTo;
    WalletCategoryTransactionModel usersPermissionsUser = WalletCategoryTransactionModel(_userMe.id);

    // if this is expense or income, check for name and category
    if (_currentType == 'expense' || _currentType == 'income') {
      if (_nameController.text.trim().isEmpty) {
        throw Exception('Name is mandatory for $_currentType');
      }
      else {
        // ensure the name length is >= 3
        if (_nameController.text.trim().length < 3) {
          throw Exception('Minimum length for name are 3');
        }
      }

      // check category
      if ((_currentCategoryID ?? 0) < 0) {
        throw Exception('Please select $_currentType category');
      }
      else {
        category = WalletCategoryTransactionModel(_currentCategoryID!);
      }
    }

    // check if the amount is not empty
    if (_currentAmount <= 0) {
      throw Exception('Amount should be more than 0');
    }
    else {
      // we got the amount
      currentAmount = _currentAmount;
    }

    // check if wallet already selected or not?
    if (_currentWalletFromID <= 0) {
      // wallet not yet selected
      throw Exception('Select wallet');
    }
    else {
      walletFrom = WalletCategoryTransactionModel(_currentWalletFromID);
    }

    // check the currency exchange
    if (_currentExchangeRate <= 0) {
      // exchange rate should be more than 0
      throw Exception('Exchange rate should be more than 0');
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
    }

    // generate the transaction model
    return TransactionModel(
      _nameController.text.trim(),
      _currentType,
      category,
      _currentDate,
      walletFrom,
      _currentClear,
      _descriptionController.text.trim(),
      usersPermissionsUser,
      currentAmount,
      walletTo,
      _currentExchangeRate
    );
  }
}