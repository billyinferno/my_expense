import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class ScrollableTab extends StatefulWidget {
  final ScrollController? controller;
  final Map<String, String> data;
  final Function(String) onTap;
  const ScrollableTab({
    super.key,
    this.controller,
    required this.data,
    required this.onTap,
  });

  @override
  State<ScrollableTab> createState() => _ScrollableTabState();
}

class _ScrollableTabState extends State<ScrollableTab> {
  late String _tabSelected;

  @override
  void initState() {
    if (widget.data.isNotEmpty) {
      // set the tab selected as the first data
      _tabSelected = widget.data.keys.first;
      Log.info(message: _tabSelected);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border( 
          right: BorderSide(
            color: primaryLight,
            width: 1.0,
            style: BorderStyle.solid,
          )
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 38,
            padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
            decoration: const BoxDecoration(
              color: primaryBackground,
              border: Border(
                right: BorderSide(
                  color: primaryLight,
                  width: 1.0,
                  style: BorderStyle.solid,
                )
              ),
            ),
            child: const Icon(
              Ionicons.wallet,
              color: primaryLight,
              size: 15,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: widget.controller,
              physics: const AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: _generateWalletTab(),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _generateWalletTab() {
    List<Widget> retWidget = [];

    // loop thru _accountMap
    widget.data.forEach((key, value) {
      retWidget.add(
        GestureDetector(
          onTap: (() {
            setState(() {
              _tabSelected = key;
              widget.onTap(key);
            });
          }),
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            decoration: BoxDecoration(
              color: (_tabSelected == key ? IconList.getDarkColor(key.toLowerCase()) : Colors.transparent),
              border: Border.all(
                color: primaryLight,
                width: 1.0,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(38),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    },);

    return retWidget;
  }
}