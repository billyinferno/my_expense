import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/pages/home/home_list.dart';
import 'package:my_expense/pages/home/home_stats.dart';
import 'package:my_expense/pages/home/home_wallet.dart';
import 'package:my_expense/pages/home/home_budget.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/misc/snack_bar.dart';
import 'package:my_expense/utils/prefs/shared_pin.dart';
import 'package:my_expense/widgets/input/bar_button.dart';
import 'package:my_expense/widgets/input/pin_pad.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  DateTime selectedDate = DateTime.now().toLocal();

  List<Widget> pages = [];

  late PinModel? pin;
  bool isPinEnabled = false;

  @override
  void initState() {
    super.initState();

    // get the pin data
    pin = PinSharedPreferences.getPin();
    if(pin != null) {
      if(pin!.hashKey != null && pin!.hashPin != null) {
        isPinEnabled = true;
      }
    }
    
    // check if login or not?
    pages.add(HomeList(
      userIconPress: () {
        Navigator.pushNamed(context, '/user');
      },
      userDateSelect: (value) {
        setSelectedDate(value);
      },
    ));
    pages.add(const HomeStats());
    pages.add(const HomeBudget());
    pages.add(const HomeWallet());
  }

  Widget _showPinScreen() {
    return Scaffold(
      backgroundColor: primaryBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            "Enter Passcode",
            style: TextStyle(
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 5,),
          const Text("Your passcode is required"),
          const SizedBox(height: 25,),
          PinPad(
            hashPin: (pin!.hashPin ?? ''),
            hashKey: (pin!.hashKey ?? ''),
            onError: (() {
              ScaffoldMessenger.of(context).showSnackBar(
                createSnackBar(
                  message: "Wrong Passcode",
                )
              );
            }),
            onSuccess: (() {
              debugPrint("🏠 Show home");
              setState(() {
                isPinEnabled = false;
              });
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // check whether we got pin enabled or not?
    // if got pin enabled then we will show the pin screen instead of home screen
    if (isPinEnabled) {
      return _showPinScreen();
    }
    
    // there are no pin enabled, means we can just showed the home
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 0.0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 5,
        color: primaryDark,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            BarButton(
              index: 0,
              currentIndex: currentIndex,
              icon: Ionicons.calendar,
              text: "Calendar",
              onTap: (() {
                setState(() {
                  currentIndex = 0;
                });
              }),
            ),
            BarButton(
              index: 1,
              currentIndex: currentIndex,
              icon: Ionicons.stats_chart,
              text: "Stats",
              onTap: (() {
                setState(() {
                  currentIndex = 1;
                });
              }),
            ),
            const Expanded(child: SizedBox(),),
            BarButton(
              index: 2,
              currentIndex: currentIndex,
              icon: Ionicons.list,
              text: "Budget",
              onTap: (() {
                setState(() {
                  currentIndex = 2;
                });
              }),
            ),
            BarButton(
              index: 3,
              currentIndex: currentIndex,
              icon: Ionicons.wallet,
              text: "Account",
              onTap: (() {
                setState(() {
                  currentIndex = 3;
                });
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: createFloatingAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget createFloatingAddButton() {
    return FloatingActionButton(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      onPressed: () {
        Navigator.pushNamed(context, '/transaction/add', arguments: selectedDate);
      },
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: accentColors[0],
          borderRadius: BorderRadius.circular(75)
        ),
        child: const Icon(
          Ionicons.add,
          size: 25,
          color: textColor,
        ),
      ),
    );
  }

  void selectedTab(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void setSelectedDate(DateTime value) {
    setState(() {
      selectedDate = value;
    });
  }
}