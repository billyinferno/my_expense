import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_expense/_index.g.dart';

class TypeSlideItem {
  final Color color;
  final IconData? icon;
  final Color iconColor;
  final Color iconColorActive;
  final Color iconColorDisabled;
  final String? text;
  final Color textColor;
  final Color textColorActive;
  final Color textColorDisabled;

  const TypeSlideItem({
    required this.color,
    this.icon,
    this.iconColor = Colors.grey,
    this.iconColorActive = Colors.white,
    this.iconColorDisabled = primaryBackground,
    this.text,
    this.textColor = Colors.grey,
    this.textColorActive = Colors.white,
    this.textColorDisabled = primaryBackground,
  });
}

class TypeSlide<T extends Object> extends StatefulWidget {
  final ValueChanged<T> onValueChanged;
  final Map<T, TypeSlideItem> items;
  final double height;
  final double width;
  final bool editable;
  final T? initialItem;
  const TypeSlide({
    super.key,
    required this.onValueChanged,
    required this.items,
    this.height = 30,
    this.width = 100,
    this.editable = true,
    this.initialItem,
  });

  @override
  State<TypeSlide<T>> createState() => _TypeSlideState();
}

class _TypeSlideState<T extends Object> extends State<TypeSlide<T>>
  with TickerProviderStateMixin<TypeSlide<T>> {
  // animation variable
  late double _currentContainerPositioned;
  late Color _currentContainerColor;
  final _animationDuration = const Duration(milliseconds: 150);
  late double _containerWidth;
  late T _type;

  @override
  void initState() {
    super.initState();

    // ensure items is not empty
    assert(
      widget.items.isNotEmpty,
      "TypeSlide items shouldn't be empty"
    );

    assert(
      widget.items.length >= 2,
      "Minimum items should be 2"
    );

    // get type slide type and ensure that the initial item is exists
    if (widget.initialItem != null) {
      assert(
        widget.items.containsKey(widget.initialItem),
        "initialItem should be one of the key in items map"
      );
    }

    // get the initial item, whether it's set by user or default to the first
    // key on the items map.
    _type = (widget.initialItem ?? widget.items.keys.elementAt(0));

    // ensure widget width is at least 40
    assert(widget.width >= 40);
    
    // initialize the default container position and color
    _currentContainerPositioned = 0;
    _currentContainerColor = widget.items[widget.items.keys.elementAt(0)]!.color;

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

    for(final T key in widget.items.keys) {
      Color iconColor = widget.items[key]!.iconColor;
      Color textColor = widget.items[key]!.textColor;

      if (key == _type) {
        iconColor = widget.items[key]!.iconColorActive;
        textColor = widget.items[key]!.textColorActive;
      }
      else {
        if (!widget.editable) {
          iconColor = widget.items[key]!.iconColorDisabled;
          textColor = widget.items[key]!.textColorDisabled;
        }
      }

      double position = index * widget.width;
      Widget tab = Expanded(
        child: MouseRegion(
          cursor: (kIsWeb ? SystemMouseCursors.click : MouseCursor.defer),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if(widget.editable) {
                if (_type != key) {
                  setState(() {
                    _currentContainerColor = widget.items[key]!.color;
                    _currentContainerPositioned = position;
                    _onTap(key);
                    _type = key;
                  });
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              color: Colors.transparent,
              height: widget.height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Visibility(
                    visible: (widget.items[key]!.icon != null),
                    child: Icon(
                      widget.items[key]!.icon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  Visibility(
                    visible: (
                      widget.items[key]!.icon != null &&
                      widget.items[key]!.text != null
                    ),
                    child: const SizedBox(width: 10,),
                  ),
                  Visibility(
                    visible: (widget.items[key]!.text != null),
                    child: Expanded(
                      child: Center(
                        child: Text(
                          (widget.items[key]!.text ?? ''),
                          style: TextStyle(
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      tabs.add(tab);
      index = index + 1;
    }

    return tabs;
  }

  void _getPositionedAndColor() {
    // check in the map whether we got this type or not?
    // check this key is number what on map list
    T key;
    for(int i=0; i<widget.items.keys.length; i++) {
      key = widget.items.keys.elementAt(i);
      if (key == _type) {
        _currentContainerPositioned = (widget.width * i);
        _currentContainerColor = widget.items[key]!.color;
        break;
      }
    }
  }

  void _onTap(T currentKey) {
    if (currentKey != _type) {
      widget.onValueChanged(currentKey);
    }
  }
}