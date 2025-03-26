import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class ScrollableTab extends StatefulWidget {
  final ScrollController? controller;
  final Map<String, String> data;
  final Function(String) onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double leftPadding;
  final double rightPadding;
  final bool showIcon;
  const ScrollableTab({
    super.key,
    this.controller,
    required this.data,
    required this.onTap,
    this.backgroundColor = primaryBackground,
    this.borderColor = primaryLight,
    this.leftPadding = 0,
    this.rightPadding = 0,
    this.showIcon = false,
  });

  @override
  State<ScrollableTab> createState() => _ScrollableTabState();
}

class _ScrollableTabState extends State<ScrollableTab> {
  late String _tabSelected;

  @override
  void initState() {
    super.initState();

    if (widget.data.isNotEmpty) {
      // set the tab selected as the first data
      _tabSelected = widget.data.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(0, 0, widget.rightPadding, 0),
      decoration: BoxDecoration(
        border: Border( 
          right: BorderSide(
            color: widget.borderColor,
            width: 1.0,
            style: BorderStyle.solid,
          )
        )
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onDoubleTap: (() {
              // when double tab return to the first key
              if (_tabSelected != widget.data.keys.first) {
                setState(() {
                  _tabSelected = widget.data.keys.first;
                  widget.onTap(_tabSelected);
                });
              }

              // check if controller is not null
              if (widget.controller != null) {
                // if not null then move the single child scroll view back to 0
                widget.controller!.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastOutSlowIn
                );
              }
            }),
            child: Container(
              height: 38,
              padding: EdgeInsets.fromLTRB(widget.leftPadding, 10, 10, 10),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                border: Border(
                  right: BorderSide(
                    color: widget.borderColor,
                    width: 1.0,
                    style: BorderStyle.solid,
                  )
                ),
              ),
              child: Icon(
                Ionicons.wallet,
                color: widget.borderColor,
                size: 15,
              ),
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
          ),
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
              color: (
                _tabSelected == key ? IconList.getDarkColor(key.toLowerCase()) : Colors.transparent
              ),
              border: Border.all(
                color: widget.borderColor,
                width: 1.0,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(38),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                (
                  widget.showIcon ?
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: _tabSelected == key ? Colors.transparent : IconList.getDarkColor(key.toLowerCase())
                    ),
                    child: Center(child: IconList.getIcon(key, size: 10)),
                  ) :
                  const SizedBox.shrink()
                ),
                (
                  widget.showIcon ? const SizedBox(width: 5,) : const SizedBox.shrink()
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },);

    return retWidget;
  }
}