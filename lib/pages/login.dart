import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/budget_api.dart';
import 'package:my_expense/api/category_api.dart';
import 'package:my_expense/api/pin_api.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/user_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/currency_model.dart';
import 'package:my_expense/model/error_model.dart';
import 'package:my_expense/model/login_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/misc/error_parser.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/net/netutils.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:my_expense/utils/prefs/shared_wallet.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Connectivity _connectivity = Connectivity();
  final UserHTTPService _userHTTP = UserHTTPService();
  final CategoryHTTPService _categoryHTTP = CategoryHTTPService();
  final WalletHTTPService _walletHTTP = WalletHTTPService();
  final TransactionHTTPService _transactionHTTP = TransactionHTTPService();
  final PinHTTPService _pinHTTP = PinHTTPService();
  final BudgetHTTPService _budgetHTTP = BudgetHTTPService();

  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late DateTime _currentDate;
  late String _currentDateString;
  
  String _bearerToken = "";
  bool _isTokenExpired = false;
  List<ConnectivityResult> connectivityResult = [ConnectivityResult.wifi]; // default as already have wifi connection
  bool _isLoading = true;
  bool _isConnect = true;

  @override
  void initState() {
    // initialize variable needed for login
    _isLoading = true;
    _isConnect = true;
    _bearerToken = "";
    _isTokenExpired = false;

    // get the current date
    _currentDate = DateTime(DateTime.now().year, DateTime.now().month, 1).toLocal();
    _currentDateString = DateFormat('yyyy-MM-dd').format(_currentDate);

    Future.microtask(() async {
      await _checkLogin().then((isLogin) async {
        if (isLogin) {
          // get additional information
          debugPrint("🔓 Already login");
          await _getAdditionalInfo().then((isGetAdditionalInfo) {
            if (isGetAdditionalInfo) {
              // once finished get the additional information route this to home
              debugPrint("🏠 Redirect to home");
              Navigator.restorablePushNamedAndRemoveUntil(context, "/home", (_) => false);
            }
            else {
              // got error when get the additional info
              _setLoading(false);
            }
          });
        }
        else {
          _setLoading(false);
        }
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _usernameController.dispose();
    _passwordFocus.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _generateBody(),
    );
  }

  Widget _generateBody() {
    if (_isLoading) {
      return _generateSplashScreen();
    }
    return _generateLoginScreen();
  }

  Widget _generateSplashScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Center(
          child: SpinKitFadingCube(
            color: accentColors[6],
          ),
        ),
        const SizedBox(
          height: 25,
        ),
        const Center(
          child: Text(
            "myExpense",
            style: TextStyle(
              color: textColor2,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            'version - ${Globals.appVersion}',
            style: const TextStyle(
              color: textColor2,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _generateLoginScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    "my",
                    style: TextStyle(
                      color: textColor2,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Expense",
                    style: TextStyle(
                      color: accentColors[6],
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Form(
                key: _formKey,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text("Username"),
                      const SizedBox(height: 5,),
                      TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        validator: ((val) {
                          if (val!.isNotEmpty) {
                            return null;
                          }
                          else {
                            return "Please enter username";
                          }
                        }),
                        onTap: (() {
                          setState(() {
                            FocusScope.of(context).requestFocus(_usernameFocus);
                          });
                        }),
                        decoration: InputDecoration(
                          hintText: "username",
                          prefixIcon: Icon(
                            Ionicons.person,
                            color: (_usernameFocus.hasFocus ? accentColors[6] : textColor2),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: textColor,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: (_usernameFocus.hasFocus ? accentColors[6] : textColor2),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15,),
                      const Text("Password",),
                      const SizedBox(height: 5,),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: true,
                        validator: ((val) {
                          if (val!.isNotEmpty) {
                            if (val.length < 6) {
                              return "Password length cannot be less than 6";
                            }
                            return null;
                          }
                          else {
                            return "Please enter password";
                          }
                        }),
                        onTap: (() {
                          setState(() {
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          });
                        }),
                        decoration: InputDecoration(
                          hintText: "password",
                          prefixIcon: Icon(
                            Ionicons.key,
                            color: (_passwordFocus.hasFocus ? accentColors[6] : textColor2),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: textColor,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: (_passwordFocus.hasFocus ? accentColors[6] : textColor2),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15,),
                      MaterialButton(
                        height: 50,
                        onPressed: (() async {
                          if (_formKey.currentState!.validate()) {
                            showLoaderDialog(context);
                            await _login(_usernameController.text, _passwordController.text).then((res) async {
                              Navigator.pop(context);
                              if(res) {
                                debugPrint("🏠 Login success, redirect to home");
                                Navigator.restorablePushNamedAndRemoveUntil(context, "/home", (_) => false);
                              }
                              else {
                                debugPrint("⛔ Wrong login information");
                              }
                            });
                          }
                        }),
                        color: accentColors[6],
                        minWidth: double.infinity,
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text(
                    "version - ${Globals.appVersion}",
                    style: const TextStyle(
                      color: primaryLight,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _getAdditionalInfo() async {
    bool res = true;

    await Future.wait([
      _userHTTP.fetchMe().then((value) {
        debugPrint("⏳ Fetch User");
      }),
      _categoryHTTP.fetchCategory().then((_) {
        debugPrint("⏳ Fetch Category");
      }),
      _walletHTTP.fetchWalletTypes().then((_) {
        debugPrint("⏳ Fetch Wallet Types");
      }),
      _walletHTTP.fetchCurrency().then((_) {
        debugPrint("⏳ Fetch Currency");
      }),
      _walletHTTP.fetchWalletCurrencies(true).then((_) async {
        debugPrint("⏳ Fetch Wallet User Currency");
        await _fetchAllBudget();
      }),
      _transactionHTTP.fetchLastTransaction("expense").then((value) {
        debugPrint("⏳ Fetch Expense Last Transaction : ${value.length}");
      }),
      _transactionHTTP.fetchLastTransaction("income").then((value) {
        debugPrint("⏳ Fetch Income Last Transaction : ${value.length}");
      }),
      _transactionHTTP.fetchMinMaxDate().then((_) {
        debugPrint("⏳ Fetch min max transaction date");
      }),
      _pinHTTP.getPin(true).then((pin) {
        debugPrint("⏳ Fetch user PIN");
      }),
    ]).then((_) {
      debugPrint("💯 Finished");
      res = true;
    }).onError((error, stackTrace) {
      debugPrint("🛑 Error when get additional information");
      debugPrint(error.toString());
      res = false;
    });

    // return response
    return res;
  }

  Future<void> _fetchAllBudget() async {
    // loop thru all the currencies and get the budget
    List<CurrencyModel> ccyLists = WalletSharedPreferences.getWalletUserCurrency();
    for(CurrencyModel ccy in ccyLists) {
      // fetch the budget for this ccy
      await _budgetHTTP.fetchBudgetDate(ccy.id, _currentDateString, true);
      debugPrint("⏳ Fetch budget at $_currentDateString for ${ccy.name}");
    }
  }

  Future<bool> _checkLogin() async {
    bool res = true;
    // check for internet connection
    await _checkConnection();

    // check if we got connection or not?
    if (_isConnect) {
      debugPrint("🔐 Get Bearer Token");
      _bearerToken = UserSharedPreferences.getJWT();

      // if not empty, then we can try to fecth user information
      if (_bearerToken.isNotEmpty) {
        debugPrint("🔑 Checking User Login");
        // get user information
        await _userHTTP.fetchMe().then((user) async {
          // able to fetch information, user already login
          debugPrint("👨🏻 User ${user.username} already login");
        }).onError((error, stackTrace) {
          // set loading into false, it will rebuild the widget, which
          // by right should show the login screen.
          _setLoading(false);

          // check whether this is due to JWT token is expired or not?
          if (_bearerToken.isNotEmpty) {
            _isTokenExpired = true;
            debugPrint("👨🏻 User token is expired");
            ScaffoldMessenger.of(context).showSnackBar(createSnackBar(message: "User token expired, please re-login"));
          }
          else {
            debugPrint("👨🏻 User not yet login");
          }
          res = false;
        });
      }
      else {
        // no bearer token
        res = false;
        _setLoading(false);
        debugPrint("🔐 No bearer token");
      }
    }
    else {
      // set loading into false.
      res = false;
      _setLoading(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(createSnackBar(message: "No internet connection"));
      }
    }
    return res;
  }

  Future<void> _checkConnection() async {
    // check for internet connection
    try {
      connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.isEmpty) {
        debugPrint("⛔ No connection");
      }
      else {
        // check if got connectivity result none or not?
        _isConnect = true;
        for (ConnectivityResult result in connectivityResult) {
          if (result == ConnectivityResult.none) {
            _isConnect = false;
          }
        }

        // check whether we have connection or not?
        if (!_isConnect) {
          debugPrint("⛔ No connection");
        }
        else {
          debugPrint("🌏 Got internet connection");
        }
      }
    } on PlatformException {
      _isConnect = true;
      debugPrint("❌ Platform not supported");
    }

    // store this on the shared preferences
    await UserSharedPreferences.setUserConnection(_isConnect);
  }

  Future<void> _storeCredentials(LoginModel loginModel) async {
    // ensure we finished storing the credentials before we actually get the
    // additional information and navigate to home
    await UserSharedPreferences.setUserLogin(loginModel).then((value) async {
      // refresh JWT token with the latest JWT token that we just get after
      // login.
      NetUtils.refreshJWT();

      // as user already login again, we can reset back the isTokenExpired back
      // into false.
      if (_isTokenExpired) {
        // set back the token expired as false
        _isTokenExpired = false;
      }
      
      // get additional information for user
      debugPrint("Get additional info for user");

      showLoaderDialog(context);
      await _getAdditionalInfo().then((isGetAdditionalInfo) {
        if (isGetAdditionalInfo) {
          // once finished get the additional information route this to home
          debugPrint("🏠 Redirect to home");
          Navigator.restorablePushNamedAndRemoveUntil(context, "/home", (_) => false);
        }
        else {
          // got error when get the additional info
          _setLoading(false);
        }
      });
    });
  }

  Future<bool> _login(String username, String password) async {
    bool isError = false;
    // check for internet connection
    await _checkConnection();

    // check if connected or not?
    if (_isConnect) {
      // all good, showed the loading
      if (mounted) {
        showLoaderDialog(context);
      }

      // try to fetch users/me endpoint to check if we have credentials to access
      // this page or not?
      await _userHTTP.login(username, password).then((loginModel) {
        // login success, now we can just store this on the shared preferences
        _storeCredentials(loginModel);
      }).onError((error, stackTrace) {
        // check if we got "res=" on the result or not?
        // if got, it means that we got response from server, if not it's due
        // connectivity error (showed error that probably services not available)
        // print(error.toString());
        ErrorModel errModel = parseErrorMessage(error.toString());
        if (errModel.statusCode > 0) {
          isError = true;
          ScaffoldMessenger.of(context).showSnackBar(createSnackBar(message: "Wrong login info"));
        } else {
          isError = true;
          ScaffoldMessenger.of(context).showSnackBar(createSnackBar(message: "Services unavailable"));
        }

        // pop the loader
        Navigator.pop(context);
      });
    }
    else {
      // showed connection error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(createSnackBar(message: "No internet connection"));
      }
    }

    return isError;
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }
}