import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/api/category_api.dart';
import 'package:my_expense/api/pin_api.dart';
import 'package:my_expense/api/transaction_api.dart';
import 'package:my_expense/api/user_api.dart';
import 'package:my_expense/api/wallet_api.dart';
import 'package:my_expense/model/error_model.dart';
import 'package:my_expense/model/login_model.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/misc/error_parser.dart';
import 'package:my_expense/utils/misc/show_loader_dialog.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({ Key? key }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final UserHTTPService userHttp = UserHTTPService();
  final CategoryHTTPService categoryHttp = CategoryHTTPService();
  final WalletHTTPService walletHttp = WalletHTTPService();
  final TransactionHTTPService transactionHttp = TransactionHTTPService();
  final PinHTTPService pinHttp = PinHTTPService();

  final _formKey = GlobalKey<FormState>();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  FocusNode _usernameFocus = FocusNode();
  FocusNode _passwordFocus = FocusNode();

  bool _isLoading = true;
  bool _isError = false;
  bool _isCheckLogin = false;
  bool _isFetchInfo = false;
  String _errorMessage = "";
  String _bearerToken = "";
  bool _isTokenExpired = false;

  @override
  void initState() {
    super.initState();
    // check login only after the screen is build, to ensure
    // that we will not going to call it twice.
    Future.microtask(() {
      _checkLogin();
    });
  }

  @override
  void dispose() {
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint("Building...");
    return Scaffold(
      body: _generateBody(),
    );
  }

  Future<void> _checkLogin() async {
    if(_isCheckLogin) return;
    _isCheckLogin = true;

    debugPrint("🔑 Checking User Login");
    // check if user already login or not?
    await userHttp.fetchMe().then((user) async {
      debugPrint("👨🏻 User " + user.username + " already login");
      await _getAdditionalInfo(false);
    }).onError((error, stackTrace) {
      // check whether this is due to JWT token is expired or not?
      _bearerToken = UserSharedPreferences.getJWT();
      if (_bearerToken.isNotEmpty) {
        _isTokenExpired = true;
        debugPrint("👨🏻 User token is expired");
        ScaffoldMessenger.of(context).showSnackBar(createSnackBar(message: "User token expired, please re-login"));
      }
      else {
        debugPrint("👨🏻 User not yet login");
      }
      // set loading into false, it will rebuild the widget, which
      // by right should show the login screen.
      setIsLoading(false);
    });
  }

  void setIsLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  Widget _generateBody() {
    if(_isLoading) {
      return _createSplashScreen();
    }
    else {
      // showed the login screen
      return _showLoginScreen();
    }
  }

  Widget _createSplashScreen() {
    return Center(
      child: Container(
        color: primaryBackground,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SpinKitFadingCube(
              color: accentColors[6],
            ),
            SizedBox(
              height: 25,
            ),
            Text(
              "myExpense",
              style: TextStyle(
                color: textColor2,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'version - ' + Globals.appVersion,
              style: TextStyle(
                color: textColor2,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showLoginScreen() {
    final mq = MediaQueryData.fromWindow(window);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(
          height: mq.size.height,
        ),
        child: Container(
          height: double.infinity,
          width: double.infinity,
          padding: EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Text(
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
              SizedBox(
                height: 10,
              ),
              Form(
                key: _formKey,
                child: Container(
                  height: 300,
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: primaryLight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text("Username"),
                      SizedBox(
                        height: 5,
                      ),
                      TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        validator: (val) {
                          if (val!.isNotEmpty) {
                            return null;
                          } else {
                            return "Please enter your username";
                          }
                        },
                        onTap: () {
                          setState(() {
                            FocusScope.of(context).requestFocus(_usernameFocus);
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Username",
                          prefixIcon: Icon(
                            Ionicons.person,
                            color: (_usernameFocus.hasFocus
                                ? accentColors[6]
                                : textColor2),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: (_usernameFocus.hasFocus
                                  ? accentColors[6]
                                  : textColor2),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text("password"),
                      SizedBox(
                        height: 5,
                      ),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        validator: (val) {
                          if (val!.isNotEmpty) {
                            if (val.length >= 6) {
                              return null;
                            } else {
                              return "Password length is minimum 6";
                            }
                          } else {
                            return "Please enter your password";
                          }
                        },
                        onTap: () {
                          setState(() {
                            FocusScope.of(context).requestFocus(_passwordFocus);
                          });
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          focusColor: primaryDark,
                          hoverColor: primaryDark,
                          hintText: "Password",
                          prefixIcon: Icon(
                            Ionicons.key,
                            color: (_passwordFocus.hasFocus ? accentColors[6] : textColor2),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: (_passwordFocus.hasFocus ? accentColors[6] : textColor2),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      MaterialButton(
                        onPressed: () {
                          // check if the form is validated already
                          if (_formKey.currentState!.validate()) {
                            _login(_usernameController.text, _passwordController.text);
                          }
                        },
                        height: 50,
                        child: Text(
                          "Login",
                          style: TextStyle(
                            color: textColor2,
                            fontSize: 15,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        color: accentColors[6],
                        minWidth: double.infinity,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                child: Text(
                  'version - ' + Globals.appVersion,
                  style: TextStyle(
                    color: textColor2,
                    fontSize: 8,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Visibility(
                visible: _isError,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: accentColors[2],
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login(String username, String password) async {
    // all good, showed the loading
    showLoaderDialog(context);

    // try to fetch users/me endpoint to check if we have credentials to access
    // this page or not?
    await userHttp.login(username, password).then((_loginModel) {
      // login success, now we can just store this on the shared preferences
      _storeCredentials(_loginModel);
    }).onError((error, stackTrace) {
      // check if we got "res=" on the result or not?
      // if got, it means that we got response from server, if not it's due
      // connectivity error (showed error that probably services not available)
      // print(error.toString());
      ErrorModel errModel = parseErrorMessage(error.toString());
      if (errModel.statusCode > 0) {
        _isError = true;
        _errorMessage = "Identifier or password invalid.";
        // print("This is service error, like wrong password");
      } else {
        _isError = true;
        _errorMessage = "Services unavailable, please try again later.";
        // print("This is due to services down");
      }

      // pop the loader
      Navigator.pop(context);
    });
  }

  void _storeCredentials(LoginModel _loginModel) async {
    // ensure we finished storing the credentials before we actually get the
    // additional information and navigate to home
    await UserSharedPreferences.setUserLogin(_loginModel).then((value) async {
      // when user is login, check whether this is due to token expired or not?
      // if due to token expired, then we will need to refresh the JWT token that
      // being used by each API call that we have before we call _getAdditionalInfo
      if (_isTokenExpired) {
        userHttp.refreshJWTToken();
        categoryHttp.refreshJWTToken();
        walletHttp.refreshJWTToken();
        transactionHttp.refreshJWTToken();
        pinHttp.refreshJWTToken();

        // set back the token expired as false
        _isTokenExpired = false;
      }
      
      // get additional information for user
      debugPrint("Get additional info for user");
      await _getAdditionalInfo(true);
    });
  }

  Future<void> _getAdditionalInfo(bool popLoader) async {
    if(_isFetchInfo) {
      debugPrint("⚠ Fetch already performed");
      return;
    }

    _isFetchInfo = true;
    //howManyTimes = howManyTimes + 1;
    //debugPrint("How Many Times : " + howManyTimes.toString());
    await Future.wait([
      userHttp.fetchMe().then((value) {
        debugPrint("⏳ Fetch User");
      }),
      categoryHttp.fetchCategory().then((_) {
        debugPrint("⏳ Fetch Category");
      }),
      walletHttp.fetchWalletTypes().then((_) {
        debugPrint("⏳ Fetch Wallet Types");
      }),
      walletHttp.fetchCurrency().then((_) {
        debugPrint("⏳ Fetch Currency");
      }),
      walletHttp.fetchWalletCurrencies(true).then((_) {
        debugPrint("⏳ Fetch Wallet User Currency");
      }),
      transactionHttp.fetchLastTransaction("expense").then((value) {
        debugPrint("⏳ Fetch Expense Last Transaction : " + value.length.toString());
      }),
      transactionHttp.fetchLastTransaction("income").then((value) {
        debugPrint("⏳ Fetch Income Last Transaction : " + value.length.toString());
      }),
      transactionHttp.fetchMinMaxDate().then((_) {
        debugPrint("⏳ Fetch min max transaction date");
      }),
      pinHttp.getPin(true).then((_pin) {
        debugPrint("⏳ Fetch user PIN");
        
      }),
    ]).then((_) {
      debugPrint("💯 Finished");

      if (popLoader) {
        // debugPrint("Pop the loader");
        Navigator.pop(context);
      }

      // go to home, we will handler the pin page on the home instead on the
      // login, to avoid it being called twice.
      debugPrint("🏠 Go to home");
      Navigator.pushNamed(context, "/home");
    }).onError((error, stackTrace) {
      debugPrint("🛑 Error when get additional information");
      debugPrint(error.toString());
    });
  }
}