import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class TypeSlide extends StatefulWidget {
  final Function(String) onChange;
  //TODO: to change this to be more dynamic so we can use any widget as item instead of String only
  final Map<String, Color> items;
  final double height;
  final double width;
  final bool editable;
  final String initialItem;
  final Color textActive;
  final Color textInactive;
  const TypeSlide({
    super.key,
    required this.onChange,
    required this.items,
    this.height = 30,
    this.width = 100,
    this.editable = true,
    required this.initialItem,
    this.textActive = textColor,
    this.textInactive = primaryBackground
  });

  @override
  State<TypeSlide> createState() => _TypeSlideState();
}

class _TypeSlideState extends State<TypeSlide> {
  // animation variable
  late double _currentContainerPositioned;
  late Color _currentContainerColor;
  final _animationDuration = const Duration(milliseconds: 150);
  late double _containerWidth;
  late String _type;

  @override
  void initState() {
    super.initState();

    // ensure items is not empty
    assert(widget.items.isNotEmpty);

    // get type slide type and ensure that 
    _type = widget.initialItem;
    
    // initialize the default container position and color
    _currentContainerPositioned = 0;
    _currentContainerColor = (widget.items[widget.items.keys.elementAt(0)] ?? accentColors[2]);

    _containerWidth = (widget.width * widget.items.length);

    // call to get the positioned and color
    _getPositionedAndColor();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _containerWidth,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: secondaryBackground,
        ),
        child: Stack(
          children: <Widget>[
            AnimatedPositioned(
              left: _currentContainerPositioned,
              duration: _animationDuration,
              child: AnimatedContainer(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: _currentContainerColor,
                ),
                duration: _animationDuration,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _generateTabs(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateTabs() {
    List<Widget> tabs = [];
    double index = 0;

    widget.items.forEach((key, color) {
      double position = index * widget.width;
      Widget tab = Expanded(
        child: GestureDetector(
          onTap: () {
            if(widget.editable) {
              setState(() {
                _currentContainerColor = color;
                _currentContainerPositioned = position;
                _type = key.toLowerCase();
                widget.onChange(key.toLowerCase());
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            height: widget.height,
            child: Center(
              child: Text(
                key,
                style: TextStyle(
                  color: (
                    widget.editable || _type == key.toLowerCase() ?
                    widget.textActive :
                    widget.textInactive
                  )
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );

      tabs.add(tab);
      index = index + 1;
    });

    return tabs;
  }

  void _getPositionedAndColor() {
    // check in the map whether we got this type or not?
    // check this key is number what on map list
    String key;
    for(int i=0; i<widget.items.keys.length; i++) {
      key = widget.items.keys.elementAt(i);
      if (key.toLowerCase() == _type.toLowerCase()) {
        _currentContainerPositioned = (widget.width * i);
        _currentContainerColor = widget.items[key]!;
        break;
      }
    }
  }
}