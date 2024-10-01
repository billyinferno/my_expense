import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/_index.g.dart';

class MySelector extends StatefulWidget {
  final Map<String, String> data;
  final String? initialKeys;
  final Function(String)? onChange;
  const MySelector({
    super.key,
    required this.data,
    this.initialKeys,
    this.onChange,
  });

  @override
  State<MySelector> createState() => _MySelectorState();
}

class _MySelectorState extends State<MySelector> {
  late List<String> _keys;
  late int _keyLoc;
  late String _currentKey;

  @override
  void initState() {
    super.initState();

    // generate the keys from data
    _keys = (widget.data.keys.toList());

    // check if initial keys is filled or not?
    _currentKey = _keys[0];
    _keyLoc = 0;

    if (widget.initialKeys != null) {
      // check if this keys exists on data or not?
      for(int i=0; i<_keys.length; i++) {
        if (_keys[i] == widget.initialKeys) {
          _keyLoc = i;
          _currentKey = _keys[i];
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: primaryLight,
          width: 1.0,
          style: BorderStyle.solid,
        )
      ),
      width: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: (() {
              setState(() {
                _keyLoc -= 1;
                if (_keyLoc < 0) {
                  _keyLoc = _keys.length - 1;
                }
                _currentKey = _keys[_keyLoc];

                if (widget.onChange != null) {
                  widget.onChange!(_currentKey);
                }
              });
            }),
            child: Container(
              padding: const EdgeInsets.all(5),
              color: Colors.transparent,
              width: 25,
              child: Icon(
                Ionicons.caret_back,
                size: 15,
                color: textColor2,
              ),
            ),
          ),
          Expanded(
            child: Center(child: Text(widget.data[_currentKey] ?? '')),
          ),
          GestureDetector(
            onTap: (() {
              setState(() {
                _keyLoc += 1;
                if (_keyLoc >= _keys.length) {
                  _keyLoc = 0;
                }
                _currentKey = _keys[_keyLoc];

                if (widget.onChange != null) {
                  widget.onChange!(_currentKey);
                }
              });
            }),
            child: Container(
              padding: const EdgeInsets.all(5),
              color: Colors.transparent,
              width: 25,
              child: Icon(
                Ionicons.caret_forward,
                size: 15,
                color: textColor2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}