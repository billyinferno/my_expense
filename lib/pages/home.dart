import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now().toLocal();

  final List<Widget> _pages = [];

  late PinModel? _pin;
  bool _isPinEnabled = false;

  @override
  void initState() {
    super.initState();

    // get the pin data
    _pin = PinSharedPreferences.getPin();
    if(_pin != null) {
      if(_pin!.hashKey != null && _pin!.hashPin != null) {
        _isPinEnabled = true;
      }
    }
    
    // check if login or not?
    _pages.add(HomeList(
      userIconPress: () {
        Navigator.pushNamed(context, '/user');
      },
      userDateSelect: (value) {
        _setSelectedDate(value);
      },
    ));
    _pages.add(const HomeStats());
    _pages.add(const HomeBudget());
    _pages.add(const HomeWallet());
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
            hashPin: (_pin!.hashPin ?? ''),
            hashKey: (_pin!.hashKey ?? ''),
            onError: (() async {
              await ShowMyDialog(
                cancelEnabled: false,
                confirmText: "OK",
                confirmColor: accentColors[2],
                dialogTitle: "Error",
                dialogText: "Wrong Passcode."
              ).show(context);
            }),
            onSuccess: (() {
              Log.info(message: "🏠 Show home");
              setState(() {
                _isPinEnabled = false;
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
    if (_isPinEnabled) {
      Log.info(message: '🔒 Show PIN screen');
      return _showPinScreen();
    }
    
    // there are no pin enabled, means we can just showed the home
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: MySafeArea(
        bottomPadding: 10,
        color: primaryDark,
        child: BottomAppBar(
          elevation: 0.0,
          notchMargin: 5,
          color: primaryDark,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              BarButton(
                index: 0,
                currentIndex: _currentIndex,
                icon: Ionicons.calendar,
                text: "Calendar",
                onTap: (() {
                  setState(() {
                    _currentIndex = 0;
                  });
                }),
              ),
              BarButton(
                index: 1,
                currentIndex: _currentIndex,
                icon: Ionicons.stats_chart,
                text: "Stats",
                onTap: (() {
                  setState(() {
                    _currentIndex = 1;
                  });
                }),
              ),
              const Expanded(child: SizedBox(),),
              BarButton(
                index: 2,
                currentIndex: _currentIndex,
                icon: Ionicons.list,
                text: "Budget",
                onTap: (() {
                  setState(() {
                    _currentIndex = 2;
                  });
                }),
              ),
              BarButton(
                index: 3,
                currentIndex: _currentIndex,
                icon: Ionicons.wallet,
                text: "Account",
                onTap: (() {
                  setState(() {
                    _currentIndex = 3;
                  });
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _createFloatingAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _createFloatingAddButton() {
    return FloatingActionButton(
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      onPressed: () {
        Navigator.pushNamed(context, '/transaction/add', arguments: _selectedDate);
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

  void _setSelectedDate(DateTime value) {
    setState(() {
      _selectedDate = value;
    });
  }
}