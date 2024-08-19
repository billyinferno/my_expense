import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_expense/_index.g.dart';

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
