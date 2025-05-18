import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class AccountSelector extends StatefulWidget {
  final String title;
  final double screenRatio;
  final Map<String, String> accountMap;
  final Map<String, List<WalletModel>> walletMap;
  final int disableID;
  final int selectedID;
  final String? selectedTab;
  final Function(WalletModel) onTap;
  const AccountSelector({
    super.key,
    required this.title,
    this.screenRatio = 0.45,
    required this.accountMap,
    required this.walletMap,
    this.disableID = -1,
    required this.selectedID,
    this.selectedTab,
    required this.onTap,
  });

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  final ScrollController _accountTypeController = ScrollController();
  final ScrollController _walletController = ScrollController();
  
  late String _tabSelected;

  @override
  void initState() {
    super.initState();

    // default the tab selected to the first key of account map if selected
    // tab is not being passed.
    _tabSelected = (widget.selectedTab ?? widget.accountMap.keys.first);
  }

  @override
  void dispose() {
    _accountTypeController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData disableIcon;
    Color? disableColor;
    bool isDisabled = false;

    return MyBottomSheet(
      context: context,
      title: widget.title,
      screenRatio: widget.screenRatio,
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10,),
          ScrollableTab(
            controller: _accountTypeController,
            data: widget.accountMap,
            borderColor: secondaryBackground,
            backgroundColor: secondaryDark,
            leftPadding: 10,
            rightPadding: 10,
            showIcon: true,
            onTap: ((tab) {
              setState(() {
                _tabSelected = tab;
              });
            }),
          ),
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: primaryLight,
                  width: 1.0,
                  style: BorderStyle.solid,
                )
              )
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _walletController,
              itemCount: widget.walletMap[_tabSelected]!.length,
              itemBuilder: (BuildContext context, int index) {
                isDisabled = false;
                disableIcon = Ionicons.checkmark_circle;
                disableColor = null;
            
                // check if the ID is the same with disabled ID or not?
                // if same then we dilled the disabled icon, and checkmark color
                // with red, and disable the onTap
                if (widget.disableID == widget.walletMap[_tabSelected]![index].id) {
                  disableIcon = Ionicons.alert_circle;
                  disableColor = accentColors[2];
                  isDisabled = true;
                }
            
                return SimpleItem(
                  color: (isDisabled ? Colors.grey[600]! : IconList.getColor(widget.walletMap[_tabSelected]![index].walletType.type.toLowerCase())),
                  title: widget.walletMap[_tabSelected]![index].name,
                  isSelected: (widget.selectedID == widget.walletMap[_tabSelected]![index].id || isDisabled),
                  checkmarkIcon: disableIcon,
                  checkmarkColor: disableColor,
                  isDisabled: isDisabled,
                  onTap: (() {
                    Navigator.pop(context);
                    widget.onTap(widget.walletMap[_tabSelected]![index]);
                  }),
                  icon: IconList.getIcon(widget.walletMap[_tabSelected]![index].walletType.type.toLowerCase()),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}