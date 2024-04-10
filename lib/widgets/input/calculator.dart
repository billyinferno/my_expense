import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:my_expense/themes/colors.dart';

class Calculator extends StatelessWidget {
  final Function(String) onChange;
  final String text;
  final double fontSize;
  final VoidCallback onFinished;
  final VoidCallback onClose;
  final bool isOpen;
  final Function(bool) onOpen;
  final double? height;

  const Calculator({ super.key, required this.onChange, required this.onFinished, required this.onClose, required this.isOpen, required this.onOpen, required this.text, required this.fontSize, this.height });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (() {
        if(!isOpen) {
          onOpen(true);
          showBottomSheet(
            context: context,
            builder: ((context) {
              return _numPad();
            }),
          );
        }
        else {
          onOpen(false);
        }
      }),
      child: Text(
        text,
        style: TextStyle(
          color: (text.isEmpty ? textColor.withOpacity(0.7) : textColor),
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _numPad() {
    double currentHeight = (height ?? 50);

    return Container(
      height: (5 * currentHeight) + 25, // 5 column + 25 of padding to ensure that we will have extra space on phone without touch
      color: secondaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: currentHeight,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: _num(
                    child: _text("C"),
                    value: "c",
                  )
                ),
                Expanded(
                  flex: 1,
                  child: _num(
                    child: _text("÷"),
                    value: "/",
                  )
                ),
                Expanded(
                  flex: 1,
                  child: _num(
                    child: _text("×"),
                    value: "x",
                  )
                ),
                Expanded(
                  flex: 1,
                  child: _num(
                    child: _text("-"),
                    value: "-",
                  )
                ),
              ],
            ),
          ),
          SizedBox(
            height: (currentHeight * 2),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    children: <Widget>[
                      _num(
                        child: _text("1"),
                        value: "1",
                      ),
                      _num(
                        child: _text("4"),
                        value: "4",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: <Widget>[
                      _num(
                        child: _text("2"),
                        value: "2",
                      ),
                      _num(
                        child: _text("5"),
                        value: "5",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: <Widget>[
                      _num(
                        child: _text("3"),
                        value: "3",
                      ),
                      _num(
                        child: _text("6"),
                        value: "6",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: (currentHeight * 2),
                    child: _num(
                      child: _text("+"),
                      value: "+",
                      height: (currentHeight * 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: (currentHeight * 2),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    children: <Widget>[
                      _num(
                        child: _text("7"),
                        value: "7",
                      ),
                      _num(
                        child: _text("."),
                        value: ".",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: <Widget>[
                      _num(
                        child: _text("8"),
                        value: "8",
                      ),
                      _num(
                        child: _text("0"),
                        value: "0",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: <Widget>[
                      _num(
                        child: _text("9"),
                        value: "9",
                      ),
                      _num(
                        child: _icon(Ionicons.backspace_outline),
                        value: "<",
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: (currentHeight * 2),
                    child: _num(
                      child: _icon(Ionicons.checkmark),
                      value: "v",
                      height: (currentHeight * 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25,),
        ],
      ),
    );
  }

  Widget _text(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _icon(IconData icon) {
    return Icon(
      icon,
      color: textColor,
      size: 25,
    );
  }

  Widget _num({required Widget child, required String value, double? height}) {
    double h = (height ?? 50);
    return TextFieldTapRegion(
      child: InkWell(
        onTap: (() {
          // get the value, and perform calc
          if(value == "v") {
            onFinished();
          }
          else {
            onChange(value);
          }
        }),
        child: Container(
          width: double.infinity,
          height: h,
          decoration: const BoxDecoration(
            color: secondaryDark,
            border: Border(
              left: BorderSide(color: primaryLight, width: 0.5),
              right: BorderSide(color: primaryLight, width: 0.5),
              top: BorderSide(color: primaryLight, width:0.5),
              bottom: BorderSide(color: primaryLight, width:0.5)
            )
          ),
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}