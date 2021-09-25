import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_size/flutter_keyboard_size.dart';
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
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_category.dart';
import 'package:my_expense/utils/prefs/shared_transaction.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';
import 'package:my_expense/widgets/input/calcbutton.dart';
import 'package:my_expense/widgets/item/expand_animation.dart';
import 'package:table_calendar/table_calendar.dart';

class TransactionInput extends StatefulWidget {
  final String title;
  final AsyncCallback refreshCategory;
  final AsyncCallback refreshWallet;
  final TransactionInputCallback saveTransaction;
  final TransactionListModel? currentTransaction;
  final DateTime? selectedDate;

  const TransactionInput({required this.title, required this.refreshCategory, required this.refreshWallet, required this.saveTransaction, this.selectedDate, this.currentTransaction});

  @override
  _TransactionInputState createState() => _TransactionInputState();
}

class _TransactionInputState extends State<TransactionInput> {
  // animation variable
  double _currentContainerPositioned = 0;
  final _animationDuration = Duration(milliseconds: 150);
  Color _currentContainerColor = accentColors[2]; // default to expense color

  // format variable
  final fCCY = new NumberFormat("0.00", "en_US");
  double _currentAmountFontSize = 25;

  // model needed for the transaction input widget
  late Map<int, CategoryModel> _currentCategoryList;
  late UsersMeModel _userMe;
  late List<WalletModel> _walletList;
  late List<LastTransactionModel> _lastExpense;
  late List<LastTransactionModel> _lastIncome;
  List<LastTransactionModel> _lastFound = [];

  // variable to store all the transaction input widget
  late String _currentType;
  late int _currentCategoryID;
  late String _currentCategoryName;
  late Color _currentCategoryColor;
  late Icon _currentCategoryIcon;
  late double _currentAmount;
  bool _showCalendar = false;
  late DateTime _selectedDate;
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
  bool _isEditable = true;
  bool _showDescription = false;
  
  double _calcMemory = 0.0;
  double _calcAmount = 0.0;
  String _calcOperation = "";
  bool _amountReset = false;
  bool _isAmountFocus = false;
  bool _isCustomPinpad = true;

  // text field controller
  FocusNode _nameFocus = FocusNode();
  FocusNode _amountFocus = FocusNode();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  TextEditingController _exchangeController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    // get user data
    _userMe = UserSharedPreferences.getUserMe();
    _walletList = WalletSharedPreferences.getWallets(false);
    _lastExpense = (TransactionSharedPreferences.getLastTransaction("expense") ?? []);
    _lastIncome = (TransactionSharedPreferences.getLastTransaction("income") ?? []);
    // initialize the data of the widget based on the currentTransaction1
    // being sent from the widget
    if(widget.currentTransaction == null) {
      _currentType = "expense";
      _currentCategoryID = -1;
      // _currentCategoryList = CategorySharedPreferences.getCategory(_currentType);
      _getCurrentCategoryList();
      _getDefaultIconAndColor();
      _currentAmount = 0.00;
      _selectedDate = (widget.selectedDate ?? DateTime.now());
      _currentWalletFromID = -1;
      _currentWalletFromName = "";
      _currentWalletFromType = "";
      _currentWalletFromCCY = "";
      _currentWalletToID = -1;
      _currentWalletToName = "";
      _currentWalletToType = "";
      _currentWalletToCCY = "";
      if(_currentWalletFromID <= 0) {
        if(_userMe.defaultWallet != null) {
          _currentWalletFromID = _userMe.defaultWallet as int;
          // check if the wallet is still exists or not?
          // because there will be case where the wallet already deleted
          // but still set as default by user
          bool _isWalletExists = false;
          for(int i=0; i<_walletList.length; i++) {
            // check the wallet id
            if(_currentWalletFromID == _walletList[i].id) {
              _isWalletExists = true;
              break;
            }
          }

          if(!_isWalletExists) {
            // not exists, return this back to -1
            _currentWalletFromID = -1;
          }
          else {
            WalletModel _walletFrom = _walletList.firstWhere((element) => (element.id == _currentWalletFromID));
            _currentWalletFromName = _walletFrom.name;
            _currentWalletFromType = _walletFrom.walletType.type.toLowerCase();
            _currentWalletFromCCY = _walletFrom.currency.name.toLowerCase();
          }
        }
      }
      _currentClear = true;
      _currentExchangeRate = 1.00;
      _isEditable = true;
    }
    else {
      _currentType = widget.currentTransaction!.type;
      _nameController.text = widget.currentTransaction!.name;
      // _currentCategoryList = CategorySharedPreferences.getCategory(_currentType);
      if(_currentType == "expense" || _currentType == "income") {
        if(_currentType == "expense") {
          _currentCategoryID = widget.currentTransaction!.category!.id;
          if(_currentCategoryID <= 0) {
            if(_userMe.defaultCategoryExpense != null) {
              _currentCategoryID = _userMe.defaultCategoryExpense as int;
            }
          }
        }
        else {
          _currentContainerPositioned = 100;
          _currentContainerColor = accentColors[0];
          _currentCategoryID = widget.currentTransaction!.category!.id;
          if(_currentCategoryID <= 0) {
            if(_userMe.defaultCategoryIncome != null) {
              _currentCategoryID = _userMe.defaultCategoryIncome as int;
            }
          }
        }
        _getCurrentCategoryList();
        _currentCategoryName = _currentCategoryList[_currentCategoryID]!.name;
        _currentCategoryColor = getExpenseColor(_currentCategoryName);
        _currentCategoryIcon = getExpenseIcon(_currentCategoryName);
      }
      else {
        _currentCategoryID = -1;
        _currentCategoryName = "";
        _currentCategoryColor = accentColors[4];
        _currentCategoryIcon = Icon(
          Ionicons.repeat,
          color: textColor,
        );
      }
      _currentAmount = (widget.currentTransaction!.amount);
      _selectedDate = (widget.currentTransaction!.date);
      _amountController.text = fCCY.format(_currentAmount);
      _resizeAmountControllerFont();
      _currentWalletFromID = (widget.currentTransaction!.wallet.id);
      if(_currentWalletFromID > 0) {
        WalletModel _walletFrom = _walletList.firstWhere((element) => (element.id == _currentWalletFromID));
        _currentWalletFromName = _walletFrom.name;
        _currentWalletFromType = _walletFrom.walletType.type.toLowerCase();
        _currentWalletFromCCY = _walletFrom.currency.name.toLowerCase();
      }
      else {
        _currentWalletFromName = "";
        _currentWalletFromType = "";
        _currentWalletFromCCY = "";
      }
      if(_currentType == "transfer") {
        _currentContainerPositioned = 200;
        _currentContainerColor = accentColors[4];
        _currentWalletToID = (widget.currentTransaction!.walletTo!.id);
        if(_currentWalletToID > 0) {
          WalletModel _walletTo = _walletList.firstWhere((element) => (element.id == _currentWalletToID));
          _currentWalletToName = _walletTo.name;
          _currentWalletToType = _walletTo.walletType.type.toLowerCase();
          _currentWalletToCCY = _walletTo.currency.name.toLowerCase();
        }
        else {
          _currentWalletToName = "";
          _currentWalletToType = "";
          _currentWalletToCCY = "";
        }
      }
      else {
        _currentWalletToID = -1;
        _currentWalletToName = "";
        _currentWalletToType = "";
        _currentWalletToCCY = "";
        _currentClear = true;
        _currentExchangeRate = 1.00;
      }
      _currentClear = (widget.currentTransaction!.cleared);
      _currentExchangeRate = (widget.currentTransaction!.exchangeRate);
      _exchangeController.text = fCCY.format(_currentExchangeRate);
      _isEditable = false;
      _descriptionController.text = widget.currentTransaction!.description;
    }

    // add listener for amount focus
    _amountFocus.addListener(_onAmountFocusChange);
    super.initState();
  }

  void _onAmountFocusChange() {
    // check if amount has focus or not?
    setState(() {
      _isAmountFocus = _amountFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    // dispose all controller
    _nameController.dispose();
    _nameFocus.dispose();
    _amountController.dispose();
    _amountFocus.removeListener(_onAmountFocusChange);
    _amountFocus.dispose();
    _exchangeController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenHeight>(
      builder: ((context, _res, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: Text(widget.title)),
                SizedBox(width: 5,),
                IconButton(
                  onPressed: (() {
                    debugPrint("Custom Keyboard");
                    // check if the _amountFocus node is focussing
                    // if so then unfocus it
                    if(_amountFocus.hasFocus) {
                      _amountFocus.unfocus();
                    }

                    // set the custom pinpad on or off
                    setState(() {
                      _isCustomPinpad = !_isCustomPinpad;
                    });
                  }),
                  icon: Icon(
                    Ionicons.calculator_outline
                  ),
                ),
              ],
            ),
            leading: IconButton(
              onPressed: () {
                Navigator.maybePop(context, false);
              },
              icon: Icon(
                Ionicons.close,
              ),
            ),
            actions: <Widget>[
              IconButton(
                onPressed: () {
                  // check if the date is today date or not?
                  if(DateTime.now().isBefore(_selectedDate)) {
                    late Future<bool?> result = ShowMyDialog(
                        dialogTitle: "Future Date",
                        dialogText: "Are you sure want to add a future date?.",
                        confirmText: "Add",
                        cancelText: "Cancel"
                    ).show(context);

                    // check the result of the dialog box
                    result.then((res) async {
                      if(res == true) {
                        TransactionModel? _gen = generateTransaction();
                        if(_gen != null) {
                          // show the loader dialog
                          showLoaderDialog(context);

                          //print("Save Transaction");
                          widget.saveTransaction(_gen);
                          Navigator.pop(context, true);
                        }
                      }
                    });
                  }
                  else {
                    TransactionModel? _gen = generateTransaction();
                    if(_gen != null) {
                      // show the loader dialog
                      showLoaderDialog(context);

                      //print("Save Transaction");
                      widget.saveTransaction(_gen);
                      Navigator.pop(context, true);
                    }
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
            children: [
              Expanded(
                child: Stack(
                  children: <Widget>[
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(10),
                            color: secondaryDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10,),
                                _generateTypeSlide(),
                                SizedBox(height: 20,),
                                // separate this based on the type
                                _buildCategoryInput(),
                                SizedBox(height: 10,),
                              ],
                            ),
                          ),
                          _buildCategorySubInput(),
                        ],
                      ),
                    ),
                    ..._generateBottomWidget(_res.isOpen, _res.screenHeight,_res.keyboardHeight),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _filterAutoComplete(String lookup) {
    // clear the last found
    if(_currentType == "expense" || _currentType == "income") {
      List<LastTransactionModel> _filter = [];

      _lastFound.clear();

      // check what is the current type so we know which data we need to look for
      //debugPrint(_currentType);
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
        _lastFound = _filter;
      });
    }
  }

  void _setCategory(String name, int categoryId, String categoryName) {
    if(_currentType == "expense") {
      setState(() {
        _nameController.text = name;
        _currentCategoryID = categoryId;
        _currentCategoryName = categoryName;
        _currentCategoryColor = getExpenseColor(categoryName);
        _currentCategoryIcon = getExpenseIcon(categoryName);
      });
    }
    else {
      setState(() {
        _nameController.text = name;
        _currentCategoryID = categoryId;
        _currentCategoryName = categoryName;
        _currentCategoryColor = getIncomeColor(categoryName);
        _currentCategoryIcon = getIncomeIcon(categoryName);
      });
    }
  }

  void _performCalculation(String operation) {
    if(_amountController.text.length > 0 && _calcAmount > 0) {
      // check if we got _calcOperation before? if not it means that
      // we just need to store this on the _calcMemory
      if(_calcOperation == "") {
        // if the operation is "=", means we don't need to change
        // anything as this is asking for final result
        if(operation == "=") {
          return;
        }

        // store current amount to the calc memory
        _calcMemory = _calcAmount;

        // store current operation to the calc operation
        _calcOperation = operation;

        // set amount reset into true, so when user press another
        // number it will be replaced with the number
        _amountReset = true;
      }
      else {
        // it means that we already have previous data, now we need
        // to perform the calculation operation that we need to do 

        switch(_calcOperation) {
          case "+":
            _calcMemory += _calcAmount;
            break;
          case "-":
            _calcMemory -= _calcAmount;
            break;
          case "/":
            _calcMemory /= _calcAmount;
            break;
          case "*":
            _calcMemory *= _calcAmount;
            break;
          default:
            _calcMemory += _calcAmount;
            break;
        }

        // we are not accepting minus value
        // so if already less than 0, then default this into 0 instead.
        if(_calcMemory < 0) {
          _calcMemory = 0.0;
        }

        // we got the calculation, now we can showed this on the amount controller
        _amountController.text = fCCY.format(_calcMemory);

        _currentAmount = _calcMemory;
        _calcAmount = 0;

        // now we see if the operation is "=" or not?
        // if "=", means it's finished, we cal clear the _calcMemory and _calcOperation
        if(operation == "=") {
          _calcMemory = 0;
          _calcOperation = "";
          _amountReset = false;
        }
        else {
          // user want to perform another calculation for this
          // so set the next operation
          _calcOperation = operation;
          _amountReset = true;
        }

        setState(() {
          _resizeAmountControllerFont();
        });
      }
    }

    // debugPrint("Calculator:");
    // debugPrint("Memory : " + _calcMemory.toString());
    // debugPrint("Operation : " + _calcOperation);
    // debugPrint("Reset : " + _amountReset.toString());
  }

  void _resizeAmountControllerFont() {
    if(_amountController.text.length > 6) {
      _currentAmountFontSize = 25 - ((10/6) * (_amountController.text.length - 6));
    }
    else {
      _currentAmountFontSize = 25;
    }
  }

  void _setAmountControllertext(String text, [bool? force]) {
    bool _force = (force ?? false);

    setState(() {
      // check if we need to do it by force
      if(_force) {
        _amountController.text = text;
      }
      else {
        // check if we got amount reset or not?
        if(_amountReset) {
          _amountController.text = text;
          _amountReset = false;
        }
        else {
          _amountController.text = _amountController.text + text;
        }
      }
      _currentAmount = double.parse(_amountController.text);
      _resizeAmountControllerFont();
    });
  }

  void _removeAmountControllerText() {
    if(_amountController.text.length > 0) {
      setState(() {
        // check if we got amount reset?
        if(_amountReset) {
          // user press operand but not enter any number, instead pressing backspace
          // in this case we will cancel the previous operand
          _calcOperation = "";
          // and set the amount reset into false
          _amountReset = false;
        }
        
        // cut the last digit from the amount
        _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);

        _resizeAmountControllerFont();
      });
    }
  }

  void _performCustomCalc(String operand) {
    // ensure we got data when we perform calculation
    if(_amountController.text.length > 0) {      
      // debugPrint("AAAA");
      // check what is the operand?
      if(operand == "+" || operand == "-" || operand == "*" || operand == "/") {
        // debugPrint("BBBB");
        // check if we already have previous amount or not?
        if(_calcMemory > 0 && _calcOperation != "") {
          // debugPrint("DDDD");
          // get the current _calcAmount
          _calcAmount = double.parse(_amountController.text);
          switch(_calcOperation) {
            case "+":
              _calcMemory = _calcMemory + _calcAmount;
              break;
            case "-":
              _calcMemory = _calcMemory - _calcAmount;
              break;
            case "*":
              _calcMemory = _calcMemory * _calcAmount;
              break;
            case "/":
              _calcMemory = _calcMemory / _calcAmount;
              break;
            default:
              _calcMemory = _calcMemory + _calcAmount;
              break;
          }

          // now update the amount controller
          _setAmountControllertext(fCCY.format(_calcMemory), true);
          _amountReset = true;
          _calcOperation = operand;
        }
        else if(_calcOperation == "") {
          // means this is the first time
          _calcMemory = double.parse(_amountController.text);

          // set the current amount as _calcMemory
          _currentAmount = _calcMemory;

          // set the operation that user want to do
          _calcOperation = operand;
          _amountReset = true;
          // debugPrint("EEEE");
        }
      }
      else if(operand == "%") {
        // ensure we have the previous data from memory
        if(_calcMemory > 0 && _amountController.text.length > 0) {
          // now check what is the current amount on the _amountController
          _calcAmount = double.parse(_amountController.text);
          if(_calcAmount > 0) {
            // calculate the percentage
            _calcAmount = _calcMemory * (_calcAmount / 100);
            // put the calc amount on the amount controller
            _setAmountControllertext(fCCY.format(_calcAmount), true);
          }
        }
      }
      else if(operand == "=") {
        // debugPrint("CCCC");
        // we will perform calculation based on the operand
        _calcAmount = double.parse(_amountController.text);
        switch(_calcOperation) {
          case "+":
            _calcMemory = _calcMemory + _calcAmount;
            break;
          case "-":
            _calcMemory = _calcMemory - _calcAmount;
            break;
          case "*":
            _calcMemory = _calcMemory * _calcAmount;
            break;
          case "/":
            _calcMemory = _calcMemory / _calcAmount;
            break;
          default:
            _calcMemory = _calcMemory + _calcAmount;
            break;
        }

        // now update the amount controller
        _setAmountControllertext(fCCY.format(_calcMemory), true);
        
        // set the current amount as _calcMemory
        // _currentAmount = _calcMemory;
        
        // clear everything
        _calcOperation = "";
        _calcMemory = 0;
      }
    }
    // no text length, no need to perform calculation
  }

  List<Widget> _generateBottomWidget(bool isOpen, double screenHeight, double keyboardHeight) {
    List<Widget> _returnWidget = [];

    if(isOpen && _nameFocus.hasFocus) {
      _returnWidget.add(
        _generateAutoComplete(isOpen, _nameFocus.hasFocus)
      );
    }
    else if(!_isCustomPinpad && isOpen && _isAmountFocus) {
      _returnWidget.add(
        _generateCalculator(screenHeight, keyboardHeight)
      );
    }
    else if(_isCustomPinpad && _isAmountFocus && !isOpen) {
      _returnWidget.add(
        _generateCustomCalculator()
      );
    }

    return _returnWidget;
  }

  Widget _customKey({required VoidCallback onTap, required String text}) {
    return Expanded(
      child: GestureDetector(
        onTap: (() {
          onTap();
        }),
        child: Container(
          height: 45,
          margin: EdgeInsets.fromLTRB(5, 0, 5, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey[600],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _generateCustomCalculator() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 350,
        width: double.infinity,
        color: secondaryDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: (() {
                  _amountFocus.unfocus();
                }),
                child: Container(
                  height: 25,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "done",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: secondaryLight,
                      ),
                    ),
                  ),
                  margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      _calcMemory = 0;
                      _calcAmount = 0;
                      _currentAmount = 0;
                      _calcOperation = "";
                      _amountController.text = "";
                      _currentAmountFontSize = 25;
                    });
                  }),
                ),
                CalcButton(
                  child: Center(
                    child: Text(
                      "%",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: primaryBackground,
                      ),
                    )
                  ),
                  color: Colors.white,
                  onTap: (() {
                    _performCustomCalc("%");
                  }),
                ),
                  CalcButton(
                  child: Center(
                    child: Icon(
                      Ionicons.backspace_outline,
                      color: primaryBackground,
                      size: 25,
                    )
                  ),
                  color: Colors.white,
                  onTap: (() {
                    // check if got length or not?
                    _removeAmountControllerText();
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
                    _performCustomCalc("/");
                  }),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CalcButton(
                  child: Center(
                    child: Text(
                      "7",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("7");
                  }),
                ),
                CalcButton(
                  child: Center(
                    child: Text(
                      "8",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("8");
                  }),
                ),
                CalcButton(
                  child: Center(
                    child: Text(
                      "9",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("9");
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
                    _performCustomCalc("*");
                  }),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CalcButton(
                  child: Center(
                    child: Text(
                      "4",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("4");
                  }),
                ),
                CalcButton(
                  child: Center(
                    child: Text(
                      "5",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("5");
                  }),
                ),
                CalcButton(
                  child: Center(
                    child: Text(
                      "6",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("6");
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
                    _performCustomCalc("-");
                  }),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CalcButton(
                  child: Center(
                    child: Text(
                      "1",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("1");
                  }),
                ),
                CalcButton(
                  child: Center(
                    child: Text(
                      "2",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("2");
                  }),
                ),
                CalcButton(
                  child: Center(
                    child: Text(
                      "3",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    _setAmountControllertext("3");
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
                    _performCustomCalc("+");
                  }),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CalcButton(
                  child: Center(
                    child: Text(
                      ".",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    // check if we already have "." on the amount controller or not?
                    if(!_amountController.text.contains(".")) {
                      // check if this the first character?
                      if(_amountController.text.length == 0) {
                        _setAmountControllertext("0.");  
                      }
                      else {
                        _setAmountControllertext(".");
                      }
                    }
                  }),
                ),
                CalcButton(
                  flex: 2,
                  child: Center(
                    child: Text(
                      "0",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ),
                  onTap: (() {
                    if(_amountController.text.length > 0) {
                      _setAmountControllertext("0");
                    }
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
                    _performCustomCalc("=");
                  }),
                ),
              ],
            ),
            SizedBox(height: 25,),
          ],
        ),
      ),
    );
  }

  Widget _generateCalculator(double screenHeight, double keyboardHeight) {
    double _position = (screenHeight - keyboardHeight) - 110;
    return Positioned(
      top: _position,
      child: Container(
        height: 55,
        padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
        width: MediaQuery.of(context).size.width,
        color: Colors.grey[850],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _customKey(
              onTap: (() {
                // reset the amount controller, calc memory, operation
                setState(() {                  
                  _currentAmount = 0;
                  _calcAmount = 0;
                  _calcMemory = 0;
                  _amountController.text = "";
                  _calcOperation = "";
                  _currentAmountFontSize = 25;
                });
              }),
              text: "C",
            ),
            _customKey(
              onTap: (() {
                _performCalculation("+");
              }),
              text: "+",
            ),
            _customKey(
              onTap: (() {
                _performCalculation("-");
              }),
              text: "−",
            ),
            _customKey(
              onTap: (() {
                _performCalculation("*");
              }),
              text: "×",
            ),
            _customKey(
              onTap: (() {
                _performCalculation("/");
              }),
              text: "÷",
            ),
            _customKey(
              onTap: (() {
                _performCalculation("=");
              }),
              text: "=",
            ),
          ],
        ),
      )
    );
  }

  Widget _generateAutoComplete(bool isOpen, bool isFocus) {
    bool _isGotData = false;

    if(_currentType == "expense" && _lastExpense.length > 0) {
      _isGotData = true;
    }

    if(_currentType == "income" && _lastIncome.length > 0) {
      _isGotData = true;
    }

    return Visibility(
      visible: _isGotData && _lastFound.length > 0 && isOpen && isFocus,
      child: Positioned(
        bottom: 0,
        child: Container(
          height: 35,
          padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
          width: MediaQuery.of(context).size.width,
          color: secondaryDark,
          child: ListView.builder(
            itemCount: (_lastFound.length > 50 ? 50 : _lastFound.length),
            scrollDirection: Axis.horizontal,
            itemBuilder: ((context, index) {
              return GestureDetector(
                onTap: (() {
                  _setCategory(_lastFound[index].name, _lastFound[index].category.id, _lastFound[index].category.name);
                  // focus directly to the amount
                  FocusScope.of(context).requestFocus(_amountFocus);
                }),
                child: Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  padding: EdgeInsets.fromLTRB(10, 2, 10, 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(35),
                    color: (_currentType == "expense" ? getExpenseColor(_lastFound[index].category.name) : getIncomeColor(_lastFound[index].category.name)),
                  ),
                  child: Center(child: Text(_lastFound[index].name)),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  TransactionModel? generateTransaction() {
    // perform the validation before we will add the transaction to the server
    // the amount should be > 0
    if(_currentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Amount cannot be zero",
        )
      );
      return null;
    }

    // walletID cannot be empty
    if(_currentWalletFromID <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        createSnackBar(
          message: "Please select wallet"
        )
      );
      return null;
    }

    // if this is transfer the the wallet to ID need to be checked also
    if(_currentType == "transfer") {
      if(_currentWalletToID <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Please select destination wallet"
          )
        );
        return null;
      }

      // the exchange rate should be more than 0
      if(_currentExchangeRate <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Exchange rate cannot be zero"
          )
        );
        return null;
      }

      // if both have same currency then defaulted the exchange rate into 1
      if(_currentWalletFromCCY == _currentWalletToCCY) {
        _currentExchangeRate = 1;
      }
    }
    else {
      // for expense or income the transaction name should be mandatory
      // so for this, ask user to input the input name, as for transfer we can
      // generate the item name in the backend if user didn't input anything
      // as item name.
      if(_nameController.text.trim().length <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          createSnackBar(
            message: "Name is mandatory for income/expense"
          )
        );
        return null;
      }
    }

    // show the loader dialog
    showLoaderDialog(context);

    // generate the transaction model that we will put
    TransactionModel _txn;
    if(_currentType == "expense" || _currentType == "income") {
      var _data = {
        "name": _nameController.text,
        "type": _currentType,
        "category": {
          "id": _currentCategoryID
        },
        "date": DateFormat('yyyy-MM-dd').format(_selectedDate.toLocal()),
        "wallet": {
          "id": _currentWalletFromID
        },
        "cleared": (_currentClear ? true : false),
        "description": _descriptionController.text,
        "users_permissions_user": {
          "id": _userMe.id
        },
        "amount": _currentAmount,
        "walletTo": null,
        "exchange_rate": 1
      };

      _txn = TransactionModel.fromJson(_data);
    }
    else {
      var _data = {
        "name": _nameController.text,
        "type": _currentType,
        "category": {
          "id": _currentCategoryID
        },
        "date": DateFormat('yyyy-MM-dd').format(_selectedDate.toLocal()),
        "wallet": {
          "id": _currentWalletFromID
        },
        "cleared": (_currentClear ? true : false),
        "description": _descriptionController.text,
        "users_permissions_user": {
          "id": _userMe.id
        },
        "amount": _currentAmount,
        "walletTo": {
          "id": _currentWalletToID
        },
        "exchange_rate": _currentExchangeRate
      };

      _txn = TransactionModel.fromJson(_data);
    }

    return _txn;
  }

  void _getCurrentCategoryList() {
    _currentCategoryList = CategorySharedPreferences.getCategory(_currentType);
  }

  void _getDefaultIconAndColor() {
    if(_currentType == "expense") {
      // once got then get the first category name
      if(_userMe.defaultCategoryExpense != null) {
        _currentCategoryID = _userMe.defaultCategoryExpense as int;
      }
      _getCurrentCategoryList();
      // ensure _currentCategoryID > 0 before we got this
      if(_currentCategoryID > 0) {
        _currentCategoryName = _currentCategoryList[_currentCategoryID]!.name;
        _currentCategoryColor = getExpenseColor(_currentCategoryName);
        _currentCategoryIcon = getExpenseIcon(_currentCategoryName);
      }
      else {
        // make it a default icon instead
        _currentCategoryName = "Select Category";
        _currentCategoryColor = textColor2;
        _currentCategoryIcon = Icon(
          Ionicons.file_tray_full,
          color: Colors.black,
        );
      }
    }
    else if(_currentType == "income") {
      if(_userMe.defaultCategoryIncome != null) {
        _currentCategoryID = _userMe.defaultCategoryIncome as int;
      }
      _getCurrentCategoryList();
      // ensure _currentCategoryID > 0 before we got this
      if(_currentCategoryID > 0) {
        _currentCategoryName = _currentCategoryList[_currentCategoryID]!.name;
        _currentCategoryColor = getIncomeColor(_currentCategoryName);
        _currentCategoryIcon = getIncomeIcon(_currentCategoryName);
      }
      else {
        // make it a default icon instead
        _currentCategoryName = "Select Category";
        _currentCategoryColor = textColor2;
        _currentCategoryIcon = Icon(
          Ionicons.file_tray_full,
          color: Colors.black,
        );
      }
    }
    else {
      _currentCategoryName = "";
      _currentCategoryColor = accentColors[4];
      _currentCategoryIcon = Icon(
        Ionicons.repeat,
        color: textColor,
      );
    }
  }

  Widget _generateTypeSlide() {
    return Center(
      child: Container(
        width: 300,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: secondaryBackground,
        ),
        child: Stack(
          children: <Widget>[
            AnimatedPositioned(
              left: _currentContainerPositioned,
              duration: _animationDuration,
              child: AnimatedContainer(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: _currentContainerColor,
                ),
                duration: _animationDuration,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if(_isEditable) {
                        setState(() {
                          _currentContainerColor = accentColors[2];
                          _currentContainerPositioned = 0;
                          _currentType = "expense";
                          _getDefaultIconAndColor();
                        });
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          "Expense",
                          style: TextStyle(
                            color: (_isEditable || _currentType == "expense" ? textColor : primaryBackground)
                          ),
                        ),
                      ),
                      height: 30,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if(_isEditable) {
                        setState(() {
                          _currentContainerColor = accentColors[0];
                          _currentContainerPositioned = 100;
                          _currentType = "income";
                          _getDefaultIconAndColor();
                        });
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          "Income",
                          style: TextStyle(
                              color: (_isEditable || _currentType == "income" ? textColor : primaryBackground)
                          ),
                        ),
                      ),
                      height: 30,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if(_isEditable) {
                        setState(() {
                          _currentContainerColor = accentColors[4];
                          _currentContainerPositioned = 200;
                          _currentType = "transfer";
                          _getDefaultIconAndColor();
                        });
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          "Transfer",
                          style: TextStyle(
                              color: (_isEditable || _currentType == "transfer" ? textColor : primaryBackground)
                          ),
                        ),
                      ),
                      height: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInput() {
    if(_currentType.toLowerCase() == "expense" || _currentType.toLowerCase() == "income") {
      return _buildExpenseIncomeCategoryInput();
    }
    else {
      return _buildTransferInput();
    }
  }

  Widget _buildExpenseIncomeCategoryInput() {
    return Container(
      child: Row(
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
                            IconButton(
                              onPressed: () {
                                _callBackRefreshCategory();
                              },
                              icon: Icon(
                                Ionicons.refresh,
                                size: 20,
                              ),
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
            },
          ),
          SizedBox(width: 10,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  focusNode: _nameFocus,
                  controller: _nameController,
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
                    _filterAutoComplete(lookup);
                  }),
                  onTap: (() {
                    //debugPrint("tap on the name");
                    _filterAutoComplete(_nameController.text);
                  }),
                  onFieldSubmitted: ((value) {
                    // ensure that the value got some length, before we focus
                    // on the amount controller
                    if(value.trim().length > 0) {
                      //debugPrint("Enter pressed");
                      // focus directly to the amount
                      FocusScope.of(context).requestFocus(_amountFocus);
                    }
                  }),
                  textInputAction: TextInputAction.done,
                ),
                SizedBox(height: 5,),
                Text(_currentCategoryName)
              ],
            ),
          ),
          SizedBox(width: 10,),
          GestureDetector(
            onTap: (() {
              FocusScope.of(context).requestFocus(_amountFocus);
            }),
            child: Container(
              width: 120,
              child: TextFormField(
                controller: _amountController,
                focusNode: _amountFocus,
                readOnly: _isCustomPinpad,
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
                  debugPrint("On Changed");
                  String _val = value;
                  // check if we have amount reset or not?
                  if(_amountReset) {
                    // debugPrint("Amount Reset");
                    // debugPrint("Current value : " + value);
                    // debugPrint("_val : " + _val.substring(value.length-1));
                    // if like this, it means we will only stored the
                    // last digit of the data we inputted
                    _val = _val.substring(value.length-1);
                    _amountController.text = _val;
                    _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
                    setState(() {
                      _currentAmountFontSize = 25;
                      // set amount reset to false, as we already reset the amount
                      _amountReset = false;
                    });
                    FocusScope.of(context).requestFocus(_amountFocus);
                  }
                  else {
                    // check what is the length of the text now, and
                    // change the font size based on the length
                    setState(() {
                      if(_val.length > 6) {
                        // change the font size
                        // target is 15 when 12 is filled
                        _currentAmountFontSize = 25 - ((10/6) * (_val.length - 6));
                      }
                      else {
                        _currentAmountFontSize = 25;
                      }
                    });
                  }
          
                  // convert the string to double
                  if(_val.length > 0) {
                    try {
                      _currentAmount = double.parse(_val);
                    }
                    catch(e) {
                      _currentAmount = 0;
                    }
                  }
                  // set the calc amount as current amount
                  _calcAmount = _currentAmount;
                },
                onFieldSubmitted: ((_) {
                  // no more calculation needed
                  _calcMemory = 0;
                  _calcOperation = "";
                  _amountReset = false;
                }),
                onTap: (() {
                  // if got tap force the amount focus
                  FocusScope.of(context).requestFocus(_amountFocus);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferInput() {
    return Container(
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: accentColors[4],
            ),
            child: Icon(
              Ionicons.repeat,
              size: 20,
              color: textColor,
            ),
          ),
          SizedBox(width: 10,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Item name",
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                    isCollapsed: true,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10,),
          Container(
            width: 120,
            child: TextFormField(
              controller: _amountController,
              focusNode: _amountFocus,
              readOnly: _isCustomPinpad,
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
                debugPrint("On Changed");
                String _val = value;
                // check if we have amount reset or not?
                if(_amountReset) {
                  // debugPrint("Amount Reset");
                  // debugPrint("Current value : " + value);
                  // debugPrint("_val : " + _val.substring(value.length-1));
                  // if like this, it means we will only stored the
                  // last digit of the data we inputted
                  _val = _val.substring(value.length-1);
                  _amountController.text = _val;
                  _amountController.selection = TextSelection.fromPosition(TextPosition(offset: _amountController.text.length));
                  setState(() {
                    _currentAmountFontSize = 25;
                    // set amount reset to false, as we already reset the amount
                    _amountReset = false;
                  });
                  FocusScope.of(context).requestFocus(_amountFocus);
                }
                else {
                  // check what is the length of the text now, and
                  // change the font size based on the length
                  setState(() {
                    if(_val.length > 6) {
                      // change the font size
                      // target is 15 when 12 is filled
                      _currentAmountFontSize = 25 - ((10/6) * (_val.length - 6));
                    }
                    else {
                      _currentAmountFontSize = 25;
                    }
                  });
                }
        
                // convert the string to double
                if(_val.length > 0) {
                  try {
                    _currentAmount = double.parse(_val);
                  }
                  catch(e) {
                    _currentAmount = 0;
                  }
                }
                // set the calc amount as current amount
                _calcAmount = _currentAmount;
              },
              onFieldSubmitted: ((_) {
                // no more calculation needed
                _calcMemory = 0;
                _calcOperation = "";
                _amountReset = false;
              }),
              onTap: (() {
                // if got tap force the amount focus
                FocusScope.of(context).requestFocus(_amountFocus);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySubInput() {
    if(_currentType.toLowerCase() == "expense" || _currentType.toLowerCase() == "income") {
      return _buildExpenseIncomeCategorySubInput();
    }
    else {
      return _buildTransferCategorySubInput();
    }
  }

  Widget _buildExpenseIncomeCategorySubInput() {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              setState(() {
                if(_showDescription) {
                  _showDescription = false;
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
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  onDateTimeChanged: (val) {
                    setState(() {
                      _selectedDate = val;
                    });
                  },
                ),
              ),
            ),
            expand: _showCalendar,
          ),
          GestureDetector(
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
                            Expanded(
                              child: Center(child: Text("Account")),
                            ),
                            IconButton(
                              onPressed: () {
                                _callBackRefreshWallet();
                              },
                              icon: Icon(
                                Ionicons.refresh,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _walletList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    color: IconList.getColor(_walletList[index].walletType.type.toLowerCase()),
                                  ),
                                  child: IconList.getIcon(_walletList[index].walletType.type.toLowerCase()),
                                ),
                                title: Text(_walletList[index].name),
                                trailing: Visibility(
                                  visible: (_currentWalletFromID == _walletList[index].id),
                                  child: Icon(
                                    Ionicons.checkmark_circle,
                                    size: 20,
                                    color: accentColors[0],
                                  ),
                                ),
                                onTap: () {
                                  //print("Selected wallet");
                                  setState(() {
                                    _currentWalletFromID = _walletList[index].id;
                                    _currentWalletFromName = _walletList[index].name;
                                    _currentWalletFromType = _walletList[index].walletType.type.toLowerCase();
                                    _currentWalletFromCCY = _walletList[index].currency.name.toLowerCase();
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      ),
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
                  Text(_walletText()),
                ],
              ),
            ),
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
          Container(height: 100, color: Colors.transparent,),
        ],
      ),
    );
  }

  Widget _buildTransferCategorySubInput() {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: GestureDetector(
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
                                      Expanded(
                                        child: Center(child: Text("Account")),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _callBackRefreshWallet();
                                        },
                                        icon: Icon(
                                          Ionicons.refresh,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10,),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _walletList.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      return Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                                        ),
                                        child: ListTile(
                                          leading: Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(40),
                                              color: IconList.getColor(_walletList[index].walletType.type.toLowerCase()),
                                            ),
                                            child: IconList.getIcon(_walletList[index].walletType.type.toLowerCase()),
                                          ),
                                          title: Text(_walletList[index].name),
                                          trailing: Visibility(
                                            visible: (_currentWalletFromID == _walletList[index].id),
                                            child: Icon(
                                              Ionicons.checkmark_circle,
                                              size: 20,
                                              color: accentColors[0],
                                            ),
                                          ),
                                          onTap: () {
                                            //print("Selected wallet");
                                            setState(() {
                                              _currentWalletFromID = _walletList[index].id;
                                              _currentWalletFromName = _walletList[index].name;
                                              _currentWalletFromType = _walletList[index].walletType.type.toLowerCase();
                                              _currentWalletFromCCY = _walletList[index].currency.name.toLowerCase();
                                            });
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                        ),
                        child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                        )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
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
                                      Expanded(
                                        child: Center(child: Text("Account")),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _callBackRefreshWallet();
                                        },
                                        icon: Icon(
                                          Ionicons.refresh,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10,),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _walletList.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      return Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                                        ),
                                        child: ListTile(
                                          leading: Container(
                                            height: 40,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(40),
                                              color: IconList.getColor(_walletList[index].walletType.type.toLowerCase()),
                                            ),
                                            child: IconList.getIcon(_walletList[index].walletType.type.toLowerCase()),
                                          ),
                                          title: Text(_walletList[index].name),
                                          trailing: Visibility(
                                            visible: (_currentWalletToID == _walletList[index].id),
                                            child: Icon(
                                              Ionicons.checkmark_circle,
                                              size: 20,
                                              color: accentColors[0],
                                            ),
                                          ),
                                          onTap: () {
                                            //print("Selected wallet");
                                            setState(() {
                                              _currentWalletToID = _walletList[index].id;
                                              _currentWalletToName = _walletList[index].name;
                                              _currentWalletToType = _walletList[index].walletType.type.toLowerCase();
                                              _currentWalletToCCY = _walletList[index].currency.name.toLowerCase();
                                            });
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: primaryLight, width: 1.0)),
                        ),
                        child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                        )),
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                child: Container(
                  height: 100,
                  child: Center(
                    child: Container(
                      height: 40,
                      child: Icon(
                        Ionicons.git_compare_sharp,
                        size: 40,
                        color: primaryLight,
                      ),
                    ),
                  ),
                ),
                alignment: Alignment.center,
              ),
            ],
          ),
          Visibility(
            visible: ((_currentWalletFromName.length > 0 && _currentWalletToName.length > 0) && (_currentWalletFromCCY != _currentWalletToCCY)),
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
                        onChanged: (value) {
                          if(value.length > 0) {
                            try {
                              _currentExchangeRate = double.parse(value);
                            }
                            catch(e) {
                              _currentExchangeRate = 1.00;
                            }
                          }
                        },
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
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  onDateTimeChanged: (val) {
                    setState(() {
                      _selectedDate = val;
                    });
                  },
                ),
              ),
            ),
            expand: _showCalendar,
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
          Container(height: 100, color: Colors.transparent,),
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
      _iconColor = getExpenseColor(category.name.toLowerCase());
      _icon = getExpenseIcon(category.name.toLowerCase());
    } else {
      _iconColor = getIncomeColor(category.name.toLowerCase());
      _icon = getIncomeIcon(category.name.toLowerCase());
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

  String _calendarText() {
    if(isSameDay(_selectedDate, DateTime.now())) {
      return "Today";
    }
    else {
      // format selected date with Day, dd MMM yyyy
      // debugPrint(_selectedDate.toString());
      // debugPrint(_selectedDate.toLocal().toString());
      return DateFormat('E, MMMM dd, yyyy').format(_selectedDate.toLocal());
    }
  }

  String _walletText() {
    if(_currentWalletFromName.length <= 0) {
      return "Wallet";
    }
    else {
      return _currentWalletFromName;
    }
  }

  void _callBackRefreshCategory() async {
    // show the loader dialog
    showLoaderDialog(context);

    widget.refreshCategory().then((_) {
      _currentCategoryList = CategorySharedPreferences.getCategory(_currentType);
    });
  }

  void _callBackRefreshWallet() async {
    // show the loader dialog
    showLoaderDialog(context);

    widget.refreshWallet().then((_) {
      _walletList = WalletSharedPreferences.getWallets(false);
    });
  }
}
