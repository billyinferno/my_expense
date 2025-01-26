import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

  late Future<bool> _checkIsLogin;
  late bool _isLogin;
  late String _type;
  late Color _typeColor;
  late bool _isObscure;
  late int _maxID;

  String _bearerToken = "";
  bool _isTokenExpired = false;

  @override
  void initState() {
    super.initState();

    // initialize variable needed for login
    _bearerToken = "";
    _isTokenExpired = false;

    // get the type of the application running now (whether WASM or JS)
    var (type, typeColor) = Globals.runAs();
    _type = type;
    _typeColor = typeColor;

    // get the current date
    _currentDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1
    );
    _currentDateString = Globals.dfyyyyMMdd.formatLocal(_currentDate);

    _isLogin = false;
    _isObscure = true;

    // get current max ID
    _maxID = TransactionSharedPreferences.getMaxID();

    _checkIsLogin = _checkLogin();
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
      body: FutureBuilder(
        future: _checkIsLogin,
        builder: (context, snapshot) {
          if ((snapshot.hasData || snapshot.hasError) && !_isLogin) {
            return _generateLoginScreen();
          } else {
            return _generateSplashScreen();
          }
        },
      ),
    );
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'version - ${Globals.appVersion} - run as (',
                style: const TextStyle(
                  color: textColor2,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Icon(
                Ionicons.rocket,
                color: _typeColor,
                size: 10,
              ),
              const SizedBox(width: 2,),
              Text(
                _type,
                style: TextStyle(
                  color: _typeColor,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Text(
                ')',
                style: TextStyle(
                  color: textColor2,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
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
                      const SizedBox(
                        height: 5,
                      ),
                      TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        validator: ((val) {
                          if (val!.isNotEmpty) {
                            return null;
                          } else {
                            return "Please enter username";
                          }
                        }),
                        onTap: (() {
                          setState(() {
                            FocusScope.of(context).requestFocus(_usernameFocus);
                          });
                        }),
                        cursorColor: primaryBackground,
                        cursorErrorColor: accentColors[2],
                        decoration: InputDecoration(
                          hintText: "username",
                          hintStyle: TextStyle(
                            color: textColor.withValues(alpha: 0.3),
                          ),
                          prefixIcon: Icon(
                            Ionicons.person,
                            color: (_usernameFocus.hasFocus
                                ? accentColors[6]
                                : textColor2),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: textColor,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: (_usernameFocus.hasFocus
                                  ? accentColors[6]
                                  : textColor2),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      const Text(
                        "Password",
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _isObscure,
                        cursorColor: primaryBackground,
                        cursorErrorColor: accentColors[2],
                        validator: ((val) {
                          if (val!.isNotEmpty) {
                            if (val.length < 6) {
                              return "Password length cannot be less than 6";
                            }
                            return null;
                          } else {
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
                          hintStyle: TextStyle(
                            color: textColor.withValues(alpha: 0.3),
                          ),
                          prefixIcon: Icon(
                            Ionicons.key,
                            color: (_passwordFocus.hasFocus
                                ? accentColors[6]
                                : textColor2),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: textColor,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: (_passwordFocus.hasFocus
                                  ? accentColors[6]
                                  : textColor2),
                              width: 1.0,
                            ),
                          ),
                          suffix: GestureDetector(
                            onTap: (() {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            }),
                            child: Icon(
                              (_isObscure ? Ionicons.eye : Ionicons.eye_off),
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      MaterialButton(
                        height: 50,
                        onPressed: (() async {
                          if (_formKey.currentState!.validate()) {
                            await _login(
                              username: _usernameController.text,
                              password: _passwordController.text
                            );
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
                    "version - ${Globals.appVersion}$_type",
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

  Future<void> _getAdditionalInfo() async {
    await Future.wait([
      _userHTTP.fetchMe().then((value) {
        Log.success(message: "⏳ Fetch User");
      }),
      _categoryHTTP.fetchCategory().then((_) {
        Log.success(message: "⏳ Fetch Category");
      }),
      _walletHTTP.fetchWalletTypes().then((_) {
        Log.success(message: "⏳ Fetch Wallet Types");
      }),
      _walletHTTP.fetchCurrency().then((_) {
        Log.success(message: "⏳ Fetch Currency");
      }),
      _walletHTTP.fetchWalletCurrencies(force: true).then((_) async {
        Log.success(message: "⏳ Fetch Wallet User Currency");
        await _fetchAllBudget();
      }),
      _transactionHTTP.fetchLastTransaction(type: "expense").then((value) {
        Log.success(message: "⏳ Fetch Expense Last Transaction : ${value.length}");
      }),
      _transactionHTTP.fetchLastTransaction(type: "income").then((value) {
        Log.success(message: "⏳ Fetch Income Last Transaction : ${value.length}");
      }),
      _transactionHTTP.fetchMinMaxDate().then((_) {
        Log.success(message: "⏳ Fetch min max transaction date");
      }),
      _pinHTTP.getPin(force: true).then((pin) {
        Log.success(message: "⏳ Fetch user PIN");
      }),
      _transactionHTTP.fetchMaxID(id: _maxID).then((maxID) async {
        // ensure maxID from remote is > 0
        if (maxID.id > 0) {
          // check ic stored max ID is -1, if so then just store the maxID
          if (_maxID > 0) {
            // stored max ID is not less than zero, compare it so we knew that
            // whether the data in the local storage is sync with server or not?
            if (_maxID < maxID.id) {
              Log.info(message: "⏳ Data unsyc (Local MaxID $_maxID, Remote MaxID ${maxID.id}), sync data");
              await _fetchAndSyncTransaction();
            }
          }

          // set the current max ID to shared preferences
          _maxID = maxID.id;
          TransactionSharedPreferences.setMaxID(id: _maxID);
        }
        else {
          Log.warning(message: "⚠️ Invalid Remote MaxID retrieved from server");
        }
      }),
    ]).then((_) {
      Log.success(message: "💯 Finished");

      // once finished get the additional information route this to home
      Log.info(message: "🏠 Redirect to home");
      if (mounted) {
        Navigator.restorablePushNamedAndRemoveUntil(context, "/home", (_) => false);
      }
    }).onError((error, stackTrace) {
      Log.error(
        message: "🛑 Error when get additional information",
        error: error,
        stackTrace: stackTrace,
      );
    });
  }

  Future<void> _fetchAndSyncTransaction() async {
    await _transactionHTTP.fetchUnsyncDate(id: _maxID).then((dateList) async {
      // check if we have this transaction in our shared preferences or not?
      // if got the we will need to refresh the transaction, if not we can just
      // ignore, as we will fetch it when open the transaction date.
      String txnDate;

      for(int i=0; i<dateList.length; i++) {
        txnDate = Globals.dfyyyyMMdd.formatLocal(dateList[i].date);
        if (TransactionSharedPreferences.checkTransaction(txnDate)) {
          Log.info(message: " ℹ️ Fetch for $txnDate");
          // we have this transaction in cache, refresh the transaction
          await _transactionHTTP.fetchTransaction(
            date: txnDate,
            force: true
          ).then((result) {
            // stored this to local storage
            Log.success(message: " ℹ️ Fetch for $txnDate");
            TransactionSharedPreferences.setTransaction(
              date: txnDate,
              txn: result,
            );
          },);
        }
      }
    },);
  }

  Future<void> _fetchAllBudget() async {
    // loop thru all the currencies and get the budget
    List<CurrencyModel> ccyLists =
        WalletSharedPreferences.getWalletUserCurrency();
    for (CurrencyModel ccy in ccyLists) {
      // fetch the budget for this ccy
      await _budgetHTTP.fetchBudgetDate(
        currencyID: ccy.id,
        date: _currentDateString,
        force: true
      ).then((_) {
        Log.success(message: "⏳ Fetch budget at $_currentDateString for ${ccy.name}");
      },);
    }
  }

  Future<bool> _checkLogin() async {
    bool res = true;

    Log.info(message: "🔐 Get Bearer Token");
    _bearerToken = UserSharedPreferences.getJWT();

    // if not empty, then we can try to fecth user information
    if (_bearerToken.isNotEmpty) {
      Log.info(message: "🔑 Checking User Login");
      // get user information
      await _userHTTP.fetchMe().then((user) async {
        // able to fetch information, user already login
        Log.success(message: "👨🏻 User ${user.username} already login");
      }).onError((error, stackTrace) {
        // check whether this is due to JWT token is expired or not?
        if (_bearerToken.isNotEmpty && mounted) {
          _isTokenExpired = true;
          Log.warning(message: "👨🏻 User token is expired");
          ScaffoldMessenger.of(context).showSnackBar(
            createSnackBar(
              message: "User token expired, please re-login"
            )
          );
        } else {
          Log.info(message: "👨🏻 User not yet login");
        }
        res = false;
      });

      // check if user JWT token is still active or not?
      if (res) {
        // try to get the additional information
        await _getAdditionalInfo().onError((error, stackTrace) {
          // unable to get additional information
          res = false;
        },);
      }
    } else {
      // no bearer token
      res = false;
      Log.info(message: "🔐 No bearer token");
    }

    // set the is login same as res
    _isLogin = res;

    // return rase to the caller
    return res;
  }

  Future<void> _storeCredentials(LoginModel loginModel) async {
    // ensure we finished storing the credentials before we actually get the
    // additional information and navigate to home
    await UserSharedPreferences.setUserLogin(
      login: loginModel
    ).then((value) async {
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
      Log.info(message: "ℹ️ Get additional info for user");

      await _getAdditionalInfo();
    });
  }

  Future<void> _login({
    required String username,
    required String password
  }) async {
    // all good, showed the loading
    LoadingScreen.instance().show(context: context);

    // try to fetch users/me endpoint to check if we have credentials to access
    // this page or not?
    await _userHTTP.login(
      identifier: username,
      password: password
    ).then((loginModel) async {
      // login success, now we can just store this on the shared preferences
      await _storeCredentials(loginModel);
    }).whenComplete(() {
        LoadingScreen.instance().hide();
    },).onError<NetException>((error, stackTrace) {
      if (mounted) {
        // if rejected with -1 this means that this is client error
        if (error.code == -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            createSnackBar(
              message: 'Server timeout',
            )
          );
        }
        // if rejected with -2 this means that this is generic error
        else if (error.code == -2) {
          ScaffoldMessenger.of(context).showSnackBar(
            createSnackBar(
              message: 'Error on the application',
            )
          );
        }
        // check whether this is rejected with 400
        else if (error.code == 400) {
          // then it means that the rejection is due to the invalid identifier
          ScaffoldMessenger.of(context).showSnackBar(
            createSnackBar(
              message: "Invalid identifier",
            )
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            createSnackBar(
              message: "Got error: ${error.message}",
            )
          );
        }
      }
    });
  }
}
