import 'package:flutter/material.dart';
import 'package:my_expense/pages/budget/budget_list.dart';
import 'package:my_expense/pages/budget/budget_stat.dart';
import 'package:my_expense/pages/budget/budget_transaction.dart';
import 'package:my_expense/pages/home.dart';
import 'package:my_expense/pages/login.dart';
import 'package:my_expense/pages/stats/stats_all.dart';
import 'package:my_expense/pages/stats/stats_details.dart';
import 'package:my_expense/pages/stats/stats_filter.dart';
import 'package:my_expense/pages/stats/stats_transaction.dart';
import 'package:my_expense/pages/transaction/transaction_add.dart';
import 'package:my_expense/pages/transaction/transaction_edit.dart';
import 'package:my_expense/pages/transaction/transaction_search.dart';
import 'package:my_expense/pages/user.dart';
import 'package:my_expense/pages/user/user_change_password.dart';
import 'package:my_expense/pages/wallet/wallet_add.dart';
import 'package:my_expense/pages/wallet/wallet_edit.dart';
import 'package:my_expense/pages/wallet/wallet_stat.dart';
import 'package:my_expense/pages/wallet/wallet_transaction.dart';
import 'package:my_expense/provider/home_provider.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/anim/page_transition.dart';
import 'package:my_expense/utils/globals.dart';
import 'package:my_expense/utils/misc/custom_scroll_behaviour.dart';
import 'package:my_expense/utils/prefs/shared_user.dart';
import 'package:provider/provider.dart';

class RouterPage extends StatefulWidget {
  @override
  _RouterPageState createState() => _RouterPageState();
}

class _RouterPageState extends State<RouterPage> {
  @override
  void initState() {
    super.initState();
  }

  bool isUserLogin() {
    String _bearerToken = UserSharedPreferences.getJWT();
    if (_bearerToken.length > 0) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HomeProvider>(
          create: (context) => HomeProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        scrollBehavior: MyCustomScrollBehavior(),
        title: 'My Expense',
        theme: Globals.themeData.copyWith(
          colorScheme: Globals.themeData.colorScheme.copyWith(
            secondary: accentColors[0],
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          // perform validation whether user already login or not when user
          // want to directly access a page from the web browser URL.
          String _routeName = (settings.name ?? '/');
          if ((_routeName != "/" || _routeName != "/login") && !isUserLogin()) {
            // user not login, force user to login
            _routeName = "/";
          }
          switch (_routeName) {
            case '/login':
            case '/':
              {
                return MaterialPageRoute(builder: (context) => new LoginPage());
              }
            case '/home':
              {
                return MaterialPageRoute(builder: (context) => new HomePage());
              }
            case '/user':
              {
                return createAnimationRoute(new UserPage());
              }
            case '/user/password':
              {
                return createAnimationRoute(new UserChangePassword());
              }
            case '/transaction/add':
              {
                return createAnimationRoute(new TransactionAddPage(settings.arguments));
              }
            case '/transaction/edit':
              {
                return createAnimationRoute(new TransactionEditPage(settings.arguments));
              }
            case '/transaction/search':
              {
                return createAnimationRoute(new TransactionSearchPage());
              }
            case '/budget/list':
              {
                return createAnimationRoute(new BudgetListPage(currencyId: settings.arguments,));
              }
            case '/budget/transaction':
              {
                return createAnimationRoute(new BudgetTransactionPage(arguments: settings.arguments,));
              }
            case '/budget/stat':
              {
                return createAnimationRoute(new BudgetStatPage(arguments: settings.arguments,));
              }
            case '/wallet/add':
              {
                return createAnimationRoute(new WalletAddPage());
              }
            case '/wallet/edit':
              {
                return createAnimationRoute(new WalletEditPage(walletData: settings.arguments,));
              }
            case '/wallet/transaction':
              {
                return createAnimationRoute(new WalletTransactionPage(wallet: settings.arguments,));
              }
            case '/wallet/stat':
              {
                return createAnimationRoute(new WalletStatPage(wallet: settings.arguments,));
              }
            case '/stats/filter':
              {
                return createAnimationRoute(new StatsFilterPage());
              }
            case '/stats/all':
              {
                return createAnimationRoute(new StatsAllPage(ccy: settings.arguments));
              }
            case '/stats/detail':
              {
                return createAnimationRoute(new StatsDetailPage(args: settings.arguments,));
              }
            case '/stats/detail/transaction':
              {
                return createAnimationRoute(new StatsTransactionPage(args: settings.arguments,));
              }
            default:
              {
                return MaterialPageRoute(builder: (context) => new LoginPage());
              }
          }
        },
      ),
    );
  }
}
