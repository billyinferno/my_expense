import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:my_expense/widgets/input/calcbutton.dart';
import 'package:my_expense/widgets/input/type_slide.dart';
import 'package:my_expense/widgets/item/expand_animation.dart';
import 'package:my_expense/widgets/item/simple_item.dart';
import 'package:table_calendar/table_calendar.dart';


enum TransactionInputType {
  add, edit
}

enum CalculatorOperation {
  none, add, subtract, multiply, divide, percentage, equal 
}

class TransactionInput extends StatefulWidget {
  final String title;
  final TransactionInputType type;
  final TransactionInputCallback saveTransaction;
  final TransactionListModel? currentTransaction;
  final DateTime? selectedDate;
  
  const TransactionInput({
    Key? key,
    required this.title,
    required this.type,
    required this.saveTransaction,
    this.currentTransaction,
    this.selectedDate
  }) : super(key: key);

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
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  
  final fCCY = new NumberFormat("0.00", "en_US");

  late UsersMeModel _userMe;

  late DateTime _currentDate;

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

  late double _currentAmountFontSize;

  late List<LastTransactionModel> _filterList;
  late List<LastTransactionModel> _lastExpense;
  late List<LastTransactionModel> _lastIncome;
  late List<WalletModel> _walletList;

  late CalculatorOperation _calcOperand;
  late double _calcMemoryAmount;
  late bool _calcAmountReset;

  late bool _showCalendar;
  late bool _showDescription;

  @override
  void initState() {
    // get ME
    _userMe = UserSharedPreferences.getUserMe();

    // check the selected date
    _currentDate = (widget.selectedDate ?? DateTime.now().toLocal());

    // text field variable
    // default font size of the amount text field to 25
    _currentAmountFontSize = 25;

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

    // initialize calculator
    _calcOperand = CalculatorOperation.none;
    _calcMemoryAmount = 0;
    _calcAmountReset = false;

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

    // amount fields
    _amountFocus.dispose();
    _amountController.dispose();

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

    // set the current amount
    _amountController.text = fCCY.format(widget.currentTransaction!.amount);

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
      _currentCategoryIcon = Icon(
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
          icon: Icon(
            Ionicons.close,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              // call parent save, all the handler on the async call should be
              // coming from the parent instead here.
              
              // first check whether we want to save future or what by compare
              // if the selected date is more than current date
              if (_currentDate.isAfter(DateTime.now().toLocal())) {
                // show the dialog to ask user if they want to add future date
                // transaction or else?
                
                late Future<bool?> result = ShowMyDialog(
                    dialogTitle: "Future Date",
                    dialogText: "Are you sure want to add a future date?.",
                    confirmText: "Add",
                    confirmColor: accentColors[0],
                    cancelText: "Cancel"
                ).show(context);

                result.then((value) {
                  // remove the dialog
                  Navigator.pop(context);

                  // check whether user press Add or Cancel
                  if(value == false) {
                    // if cancel then just return from this call
                    return;
                  }
                });
              }

              try {
                TransactionModel? gen = _generateTransaction();
                widget.saveTransaction(gen);
              }
              catch(error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  createSnackBar(
                    message: error.toString().replaceAll('Exception: ', ''),
                  )
                );
              }
            },
            icon: Icon(
              Ionicons.checkmark,
            ),
          ),
          SizedBox(width: 10,),
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
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Ionicons.swap_horizontal_sharp,
                              size: 20,
                              color: textColor,
                            ),
                            SizedBox(width: 10,),
                            Expanded(
                              child: Container(
                                child: TextFormField(
                                  controller: _exchangeController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: "1.00",
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    isCollapsed: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(12),
                                    DecimalTextInputFormatter(decimalRange: 11),
                                  ],
                                ),
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
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Ionicons.calendar_outline,
                              size: 20,
                              color: textColor,
                            ),
                            SizedBox(width: 10,),
                            Text(_calendarText()),
                          ],
                        ),
                      ),
                    ),
                    AnimationExpand(
                      child: Container(
                        height: 200,
                        child: CupertinoTheme(
                          data: CupertinoThemeData(
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
                      expand: _showCalendar,
                    ),
                    Visibility(
                      visible: (_currentType != 'transfer'),
                      child: _buildIncomeExpenseWalletSelection(),
                    ),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.checkbox_outline,
                            size: 20,
                            color: textColor,
                          ),
                          SizedBox(width: 10,),
                          Expanded(child: Text("Cleared")),
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
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Ionicons.newspaper_outline,
                              size: 20,
                              color: textColor,
                            ),
                            SizedBox(width: 10,),
                            Text("Description"),
                          ],
                        ),
                      ),
                    ),
                    AnimationExpand(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        child: TextFormField(
                          controller: _descriptionController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 8,
                          maxLength: 250,
                          decoration: InputDecoration(
                            hintText: "Input description",
                          ),
                        ),
                      ),
                      expand: _showDescription
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
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(child: Text("Category Tab")),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
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
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                enableSuggestions: false,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
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
                onFieldSubmitted: ((value) {
                  // ensure that the value got some length, before we focus
                  // on the amount controller
                  if(value.trim().length > 0) {
                    // focus directly to the amount
                    FocusScope.of(context).requestFocus(_amountFocus);
                  }
                }),
                textInputAction: TextInputAction.done,
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
          child: TextFormField(
            controller: _amountController,
            focusNode: _amountFocus,
            showCursor: true,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            // showCursor: true,
            // readOnly: true,
            decoration: InputDecoration(
              hintText: "0.00",
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
            ),
            style: TextStyle(
              fontSize: _currentAmountFontSize,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(12),
              DecimalTextInputFormatter(decimalRange: 3),
            ],
            onChanged: (value) {
              setState(() {
                // check whether this is amount reset or not?
                if (_calcAmountReset) {
                  // reset the amount controller as we will just use the last
                  // one input by user.
                  // get the last digit input by the user
                  String lastDigit = value.substring(value.length - 1);
                  double? lastDigitValue = double.tryParse(lastDigit);

                  // ensure last digit is number, otherwise we can just make
                  // it blank.
                  if ((lastDigitValue ?? 0) > 0) {
                    // set the last digit into amount controller
                    _amountController.text = lastDigit;

                    // set the cursor on the back so it will not override
                    // the current text
                    _amountController.selection = TextSelection.fromPosition(
                      TextPosition(
                        offset: _amountController.text.length
                      )
                    );
                  }
                  else {
                    // just make it blank
                    _amountController.text = "";
                  }

                  // reset the font size
                  _currentAmountFontSize = 25;

                  // reset back the amount reset into false
                  _calcAmountReset = false;
                }
                else {
                  // check what is the length of the text now, and change the
                  // fontsize based on the length
                  if(value.length > 6) {
                    // change the font size
                    // target is 15 when 12 is filled
                    _currentAmountFontSize = 25 - ((10/6) * (value.length - 6));
                  }
                  else {
                    _currentAmountFontSize = 25;
                  }
                }
              });
            },
            onFieldSubmitted: ((_) {
              // reset the calculator variable here, except calc memory amount
              _calcOperand = CalculatorOperation.none;
              _calcAmountReset = false;
            }),
            onTap: () {
              setState(() {
                // check whether we already have amount?
                // if already then we need to put that amount on the calculator
                // memory, as user probably want to perform some calculation
                // with the number
                if (_amountController.text.trim().isNotEmpty) {
                  // try to parse the amount
                  double? currentAmount = double.tryParse(_amountController.text.trim());
                  
                  // check if this is more than 0 or not?
                  if ((currentAmount ?? 0) > 0) {
                    _calcMemoryAmount = currentAmount!;
                  }
                }

                // reset all the calculator
                _calcOperand = CalculatorOperation.none;
                _calcAmountReset = false;
              });
            },
          ),
        ),
      ],
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
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(child: Text("Account")),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _walletController,
                    itemCount: _walletList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return SimpleItem(
                        color: IconList.getColor(_walletList[index].walletType.type.toLowerCase()),
                        child: IconList.getIcon(_walletList[index].walletType.type.toLowerCase()),
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
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
        ),
        child: Row(
          children: [
            Icon(
              Ionicons.wallet_outline,
              size: 20,
              color: textColor,
            ),
            SizedBox(width: 10,),
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
      decoration: BoxDecoration(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: (_currentWalletFromType.length > 0 ? IconList.getColor(_currentWalletFromType) : accentColors[4]),
                    ),
                    child: _getTransferOutIcon(_currentWalletFromType),
                  ),
                  SizedBox(height: 5,),
                  Text((_currentWalletFromName.length > 0 ? _currentWalletFromName : "From Account")),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10,),
          Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: (_currentWalletToType.length > 0 ? IconList.getColor(_currentWalletToType) : accentColors[5]),
                    ),
                    child: _getTransferInIcon(_currentWalletToType),
                  ),
                  SizedBox(height: 5,),
                  Text((_currentWalletToName.length > 0 ? _currentWalletToName : "To Account")),
                ],
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
            decoration: BoxDecoration(
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
                  child: IconList.getIcon(wallets[index].walletType.type.toLowerCase()),
                  description: wallets[index].name,
                  isSelected: (selectedId == wallets[index].id),
                  onTap: (() {
                    onTap(index);
                    Navigator.pop(context);
                  }),
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
    if(name.length > 0) {
      return IconList.getIcon(name.toLowerCase());
    }
    else {
      return Icon(
        Ionicons.download,
        size: 20,
        color: textColor,
      );
    }
  }

  Widget _getTransferOutIcon(String name) {
    if(name.length > 0) {
      return IconList.getIcon(name.toLowerCase());
    }
    else {
      return Icon(
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
    else if (_amountFocus.hasFocus) {
      return _buildCalculator();
    }
    else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildAutoComplete() {
    // if we don't have filter list then just return sized box shrink.
    if (_filterList.length <= 0) {
      return const SizedBox.shrink();
    }

    // other than that we can generate the auto complete
    return Container(
      height: 35,
      padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
      width: MediaQuery.of(context).size.width,
      color: secondaryDark,
      child: TextFieldTapRegion(
        child: ListView.builder(
          controller: _autoCompleteController,
          itemCount: (_filterList.length > 50 ? 50 : _filterList.length),
          scrollDirection: Axis.horizontal,
          itemBuilder: ((context, index) {
            return GestureDetector(
              onTap: (() {
                // set automatically the name controller text, and the category
                // based on the auto complete selection
                setState(() {
                  _nameController.text = _filterList[index].name;
                  _getCurrentCategoryIconAndColor(categoryId: _filterList[index].category.id);
                  // focus directly to the amount
                  FocusScope.of(context).requestFocus(_amountFocus);
                });
              }),
              child: Container(
                margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
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

  Widget _buildCalculator() {
    return Container(
      height: 55,
      padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
      width: MediaQuery.of(context).size.width,
      color: Colors.grey[850],
      child: TextFieldTapRegion(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            CalcButton(
              child: Center(
                child: Text(
                  "AC",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: primaryBackground,
                  ),
                )
              ),
              color: Colors.white,
              onTap: (() {
                // clear the calc memory
                setState(() {                    
                  // reset the amount      
                  _amountController.text = "";
                  _currentAmountFontSize = 25;
        
                  // reset calculator
                  _calcAmountReset = false;
                  _calcMemoryAmount = 0;
                  _calcOperand = CalculatorOperation.none;
                });
              }),
            ),
            CalcButton(
              child: Center(
                child: Text(
                  "+",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ),
              color: Colors.orange,
              onTap: (() {
                _performCalculation(CalculatorOperation.add);
              }),
            ),
            CalcButton(
              child: Center(
                child: Text(
                  "-",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ),
              color: Colors.orange,
              onTap: (() {
                _performCalculation(CalculatorOperation.subtract);
              }),
            ),
            CalcButton(
              child: Center(
                child: Text(
                  "×",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ),
              color: Colors.orange,
              onTap: (() {
                _performCalculation(CalculatorOperation.multiply);
              }),
            ),
            CalcButton(
              child: Center(
                child: Text(
                  "÷",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ),
              color: Colors.orange,
              onTap: (() {
                _performCalculation(CalculatorOperation.divide);
              }),
            ),
            CalcButton(
              child: Center(
                child: Text(
                  "%",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ),
              color: Colors.orange,
              onTap: (() {
                _performCalculation(CalculatorOperation.percentage);
              }),
            ),
            CalcButton(
              child: Center(
                child: Text(
                  "=",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ),
              color: Colors.orange,
              onTap: (() {
                _performCalculation(CalculatorOperation.equal);
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _performCalculation(CalculatorOperation operand) {
    // ensure that we have length on the controller before we perform any
    // calculation.
    if (_amountController.text.trim().length > 0) {
      // we have amount data in the amount controller, try to parse it and see
      // if this is more than 0 or not?
      double? currentAmount = double.tryParse(_amountController.text.trim());
      if ((currentAmount ?? 0) > 0) {
        // current amount is more than 0, we can perform calculation here
        
        // percentaga have special way where it will just perform calculation
        // on the current amount and put on the calculator text fields.
        if (operand == CalculatorOperation.percentage) {
          // percentage will just change what is the current amount
          // to percent format (/ 100), and put this on the amount
          // controller
          currentAmount = currentAmount! / 100;
          _amountController.text = fCCY.format(currentAmount);

          // return and no need to perform the rest
          return;
        }
        else {
          // first check the current operand
          if (_calcOperand == CalculatorOperation.none) {
            // means this is the first one.
            // store current amount to calc amount
            _calcMemoryAmount = currentAmount!;
            
            // set the amount reset, so when user type new number it will be
            // reseted from that number only
            _calcAmountReset = true;
            
            // set the calc operand to this operand
            _calcOperand = operand;
          }
          else {
            // user press operand, but if they press operand with amount reset,
            // it means that user haven't type anything and keep pressing the
            // operand button only on the calculator.
            // in this case we don't need to perform the operand
            if (!_calcAmountReset) {
              // user already type something after press operand, here we can         
              // check which operand that we will perform
              switch (operand) {
                case CalculatorOperation.add:
                case CalculatorOperation.subtract:
                case CalculatorOperation.multiply:
                case CalculatorOperation.divide:
                  // perform calculation for the previous operand, and store it
                  // on the memory.
                  _calcMemoryAmount = _performOperand(
                    operand: _calcOperand,
                    currentAmount: currentAmount!,
                    memoryAmount: _calcMemoryAmount,
                  );

                  // display the memory amount on the amount controller
                  _amountController.text = fCCY.format(_calcMemoryAmount);

                  // set the calc operand to current operand
                  _calcOperand = operand;
                  break;
                case CalculatorOperation.equal:
                  // for equal it means that we will need to perform the
                  // calculation.
                  _calcMemoryAmount = _performOperand(
                    operand: _calcOperand,
                    currentAmount: currentAmount!,
                    memoryAmount: _calcMemoryAmount,
                  );

                  // once got the total amount, then we can put it on the amount
                  // controller.
                  _amountController.text = fCCY.format(_calcMemoryAmount);

                  // reset the calculator operand to none
                  _calcOperand = CalculatorOperation.none;
                  break;
                case CalculatorOperation.percentage:
                case CalculatorOperation.none:
                  // nothing to do here
                  return;
              }

              // set the calc amount reset into true, since user can also add number
              _calcAmountReset = true;
            }
            else {
              // check if user press the same operand or not?
              // if user not pressing the same operand, it might be because they
              // want to change the operand, e.g. from add to subtract.
              if (_calcOperand != operand) {
                // change the stored operand with this
                _calcOperand = operand;
              }
            }
          }
        }
      }
    }
  }

  double _performOperand({
    required CalculatorOperation operand,
    required double currentAmount,
    required double memoryAmount}) {
    
    switch (operand) {
      case CalculatorOperation.add:
        return memoryAmount + currentAmount;
      case CalculatorOperation.subtract:
        return memoryAmount - currentAmount;
      case CalculatorOperation.multiply:
        return memoryAmount * currentAmount;
      case CalculatorOperation.divide:
        return memoryAmount / currentAmount;
      case CalculatorOperation.percentage:
      case CalculatorOperation.none:
      case CalculatorOperation.equal:
        // nothing to do for this
        break;
    }

    return 0;
  }

  List<Widget> _generateIconCategory() {
    List<Widget> _ret = [];

    // loop thru all the _currentCategoryList, and generate the category icon
    _currentCategoryList.forEach((key, value) {
      _ret.add(_iconCategory(value));
    });

    return _ret;
  }

  Widget _iconCategory(CategoryModel category) {
    // check if this is expense or income
    Color _iconColor;
    Icon _icon;

    if(category.type.toLowerCase() == "expense") {
      _iconColor = IconColorList.getExpenseColor(category.name.toLowerCase());
      _icon = IconColorList.getExpenseIcon(category.name.toLowerCase());
    } else {
      _iconColor = IconColorList.getIncomeColor(category.name.toLowerCase());
      _icon = IconColorList.getIncomeIcon(category.name.toLowerCase());
    }

    return GestureDetector(
      onTap: () {
        //print("Select category");
        setState(() {
          _currentCategoryID = category.id;
          _currentCategoryName = category.name;
          _currentCategoryColor = _iconColor;
          _currentCategoryIcon = _icon;
        });
        Navigator.pop(context);
      },
      child: Container(
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
                  color: _iconColor,
                ),
                child: _icon,
              ),
            ),
            Center(
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 10,
                  color: textColor,
                ),
                softWrap: true,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterAutoComplete(String lookup) {
    List<LastTransactionModel> _filter = [];

    // clear the last found
    _filterList.clear();

    // check what is the current type so we know which data we need to look for
    if(_currentType == "expense") {
      // look at expense
      _lastExpense.forEach((element) {
        if(element.name.toLowerCase().contains(lookup.toLowerCase())) {
          // add this element to _lastFound
          _filter.add(element);
        }
      });
    }
    else {
      _lastIncome.forEach((element) {
        if(element.name.toLowerCase().contains(lookup.toLowerCase())) {
          // add this element to _lastFound
          _filter.add(element);
        }
      });
    }

    setState(() {
      _filterList = _filter;
    });
  }

  void _getCurrentCategoryIconAndColor({int? categoryId}) {
    if (_currentType == 'transfer') {
      _currentCategoryName = "";
      _currentCategoryColor = accentColors[4];
      _currentCategoryIcon = Icon(
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
        _currentCategoryIcon = Icon(
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
    WalletCategoryTransactionModel? walletTo = null;
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
    if (_amountController.text.trim().isEmpty) {
      throw Exception('Amount cannot be empty');
    }
    else {
      // we got amount, try to convert it
      currentAmount = double.tryParse(_amountController.text);

      // check it this is more than 0?
      if ((currentAmount ?? 0) <= 0) {
        throw Exception('Amount should be more than 0');
      }
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
      currentAmount!,
      walletTo,
      _currentExchangeRate
    );
  }
}