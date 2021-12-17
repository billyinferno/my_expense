import 'package:flutter/material.dart';
import 'package:my_expense/themes/colors.dart';

class TypeSlide extends StatefulWidget {
  final Function(String) onChange;
  final Map<String, Color> items;
  final double? height;
  final double? width;
  final bool? editable;
  final String? type;
  final Color? textActive;
  final Color? textInactive;
  const TypeSlide({ Key? key, required this.onChange, required this.items, this.height, this.width, this.editable, this.type, this.textActive, this.textInactive }) : super(key: key);

  @override
  _TypeSlideState createState() => _TypeSlideState();
}

class _TypeSlideState extends State<TypeSlide> {
  // animation variable
  double _currentContainerPositioned = 0;
  final _animationDuration = Duration(milliseconds: 150);
  Color _currentContainerColor = accentColors[2]; // default to expense color

  late double _height;
  late double _width;
  late double _containerWidth;
  late bool _editable;
  late String _type;
  late Color _textActive;
  late Color _textInactive;

  @override
  void initState() {
    super.initState();

    _height = (widget.height ?? 30);
    _width = (widget.width ?? 100);
    _containerWidth = (_width * widget.items.length);
    _editable = (widget.editable ?? true);
    _type = (widget.type ?? "expense");
    _textActive = (widget.textActive ?? textColor);
    _textInactive = (widget.textInactive ?? primaryBackground);

    // call to get the positioned and color
    _getPositionedAndColor();
  }

  void _getPositionedAndColor() {
    // check in the map whether we got this type or not?
    // check this key is number what on map list
    int index = 0;
    for(String key in widget.items.keys) {
      if(key == _type) {
        _currentContainerPositioned = (_width * index);
        _currentContainerColor = widget.items[key]!;
        break;
      }
      else {
        // check if the index = 0, if 0 then put the default value here
        if(index == 0) {
          _currentContainerPositioned = (_width * index);
          _currentContainerColor = widget.items[key]!;
        }
        index++;
      }
    }
  }

  List<Widget> _generateTabs() {
    List<Widget> _tabs = [];
    double index = 0;

    widget.items.forEach((key, color) {
      double _position = index * _width;
      Widget _tab = Expanded(
        child: GestureDetector(
          onTap: () {
            if(_editable) {
              setState(() {
                _currentContainerColor = color;
                _currentContainerPositioned = _position;
                _type = key.toLowerCase();
                widget.onChange(key.toLowerCase());
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Text(
                key,
                style: TextStyle(
                  color: (_editable || _type == key.toLowerCase() ? _textActive : _textInactive)
                ),
              ),
            ),
            height: _height,
          ),
        ),
      );

      _tabs.add(_tab);
      index = index + 1;
    });

    return _tabs;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _containerWidth,
        height: _height,
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
                width: _width,
                height: _height,
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
}