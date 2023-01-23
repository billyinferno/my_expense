import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/model/pin_model.dart';
import 'package:my_expense/pages/home/home_list.dart';
import 'package:my_expense/pages/home/home_stats.dart';
import 'package:my_expense/pages/home/home_wallet.dart';
import 'package:my_expense/pages/home/home_budget.dart';
import 'package:my_expense/themes/colors.dart';
import 'package:my_expense/utils/prefs/shared_pin.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  DateTime selectedDate = DateTime.now().toLocal();

  List<Widget> pages = [];
  final List<IconData> iconItems = [
    Ionicons.calendar,
    Ionicons.stats_chart,
    Ionicons.list,
    Ionicons.wallet,
  ];
  final List<String> iconTitle = ["Calendar", "Stats", "Budget", "Account"];

  late PinModel? pin;
  bool isPinEnabled = false;
  bool isBodyShowed = false;

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
    pages.add(HomeStats());
    pages.add(HomeBudget());
    pages.add(HomeWallet());

    // check the isPinEnabled?
    // if enabled add micro task to actually showed the pin pad screen
    if(isPinEnabled) {
      Future.microtask(() {
        _showPinScreen();
      });
    }
    else {
      isBodyShowed = true;
    }
  }

  Future<void> _showPinScreen() async {
    await Navigator.pushNamed(context, '/pin');
    setBodyShowed(true);
  }

  void setBodyShowed(bool show) {
    setState(() {
      isBodyShowed = show;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 5,
        color: primaryDark,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _barButton(0),
            _barButton(1),
            Expanded(child: SizedBox()),
            _barButton(2),
            _barButton(3),
          ],
        ),
      ),
      floatingActionButton: createFloatingAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _barButton(int index) {
    return Expanded(
      child: GestureDetector(
        onTap: (() {
          setState(() {
            currentIndex = index;
          });
        }),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Icon(
                iconItems[index],
                size: 20,
                color: (currentIndex == index ? accentColors[1] : Colors.white),
              ),
              SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  iconTitle[index],
                  maxLines: 1,
                  style: TextStyle(
                    color: (currentIndex == index ? accentColors[1] : Colors.white),
                    fontSize: 10,
                  ),
                ),
              ),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    ); 
  }

  Widget getBody() {
    if(!isBodyShowed) {
      return Container();
    }
    else {
      return IndexedStack(
        index: currentIndex,
        children: pages,
      );
    }
  }

  Widget createFloatingAddButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/transaction/add', arguments: selectedDate);
      },
      child: Icon(
        Ionicons.add,
        size: 25,
        color: textColor,
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