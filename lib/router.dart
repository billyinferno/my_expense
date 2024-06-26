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
  const RouterPage({super.key});

  @override
  State<RouterPage> createState() => _RouterPageState();
}

class _RouterPageState extends State<RouterPage> {
  @override
  void initState() {
    super.initState();
  }

  bool isUserLogin() {
    String bearerToken = UserSharedPreferences.getJWT();
    if (bearerToken.isNotEmpty) {
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
          String routeName = (settings.name ?? '/');
          if ((routeName != "/" || routeName != "/login") && !isUserLogin()) {
            // user not login, force user to login
            routeName = "/";
          }
          switch (routeName) {
            case '/login':
            case '/':
              {
                return MaterialPageRoute(builder: (context) => const LoginPage());
              }
            case '/home':
              {
                return MaterialPageRoute(builder: (context) => const HomePage());
              }
            case '/user':
              {
                return createAnimationRoute(const UserPage());
              }
            case '/user/password':
              {
                return createAnimationRoute(const UserChangePassword());
              }
            case '/transaction/add':
              {
                return createAnimationRoute(TransactionAddPage(params: settings.arguments,));
              }
            case '/transaction/edit':
              {
                return createAnimationRoute(TransactionEditPage(params: settings.arguments,));
              }
            case '/transaction/search':
              {
                return createAnimationRoute(const TransactionSearchPage());
              }
            case '/budget/list':
              {
                return createAnimationRoute(BudgetListPage(currencyId: settings.arguments,));
              }
            case '/budget/transaction':
              {
                return createAnimationRoute(BudgetTransactionPage(arguments: settings.arguments,));
              }
            case '/budget/stat':
              {
                return createAnimationRoute(BudgetStatPage(arguments: settings.arguments,));
              }
            case '/wallet/add':
              {
                return createAnimationRoute(const WalletAddPage());
              }
            case '/wallet/edit':
              {
                return createAnimationRoute(WalletEditPage(walletData: settings.arguments,));
              }
            case '/wallet/transaction':
              {
                return createAnimationRoute(WalletTransactionPage(wallet: settings.arguments,));
              }
            case '/wallet/stat':
              {
                return createAnimationRoute(WalletStatPage(wallet: settings.arguments,));
              }
            case '/stats/filter':
              {
                return createAnimationRoute(const StatsFilterPage());
              }
            case '/stats/all':
              {
                return createAnimationRoute(StatsAllPage(ccy: settings.arguments));
              }
            case '/stats/detail':
              {
                return createAnimationRoute(StatsDetailPage(args: settings.arguments,));
              }
            case '/stats/detail/transaction':
              {
                return createAnimationRoute(StatsTransactionPage(args: settings.arguments,));
              }
            default:
              {
                return MaterialPageRoute(builder: (context) => const LoginPage());
              }
          }
        },
      ),
    );
  }
}
