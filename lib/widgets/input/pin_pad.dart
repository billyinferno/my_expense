import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert' show utf8;

class PinPad extends StatefulWidget {
  final String hashKey;
  final String hashPin;
  final VoidCallback? onError;
  final VoidCallback? onSuccess;
  final Function(String)? getPin;

  const PinPad({ super.key, required this.hashKey, required this.hashPin, this.onError, this.onSuccess, this.getPin });

  @override
  PinPadState createState() => PinPadState();
}

class PinPadState extends State<PinPad> with SingleTickerProviderStateMixin  {
  String _pinInput = "";
  late AnimationController _wrongInputAnimationController;
  late Animation<double> _wiggleAnimation;

  @override
  void initState() {
    super.initState();

    _wrongInputAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _wrongInputAnimationController.reverse();
        }
      });

    _wiggleAnimation = Tween<double>(begin: 0.0, end: 24.0).animate(
      CurvedAnimation(
        parent: _wrongInputAnimationController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _wrongInputAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: Transform.translate(
              offset: Offset(_wiggleAnimation.value, 0.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: 25,
                    width: 25,
                    decoration: BoxDecoration(
                      color: (index < _pinInput.length ? Colors.green : Colors.white),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    margin: const EdgeInsets.all(10),
                    onEnd: (() {
                      // check pin, if user already input all the pin
                      _checkPin();
                    }),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 25,),
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "1",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("1");
                      }),
                    ),
                     _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "2",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("2");
                      }),
                    ),
                     _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "3",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("3");
                      }),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "4",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("4");
                      }),
                    ),
                     _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "5",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("5");
                      }),
                    ),
                     _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "6",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("6");
                      }),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "7",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("7");
                      }),
                    ),
                     _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "8",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("8");
                      }),
                    ),
                     _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "9",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("9");
                      }),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                    ),
                     _button(
                      height: 80,
                      value: const Center(
                        child: Text(
                          "0",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25
                          ),
                        ),
                      ),
                      onPress: (() {
                        setCurrentText("2");
                      }),
                    ),
                     _button(
                      height: 80,
                      value: const Center(
                        child: Icon(
                          CupertinoIcons.delete_left,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      onPress: (() {
                        deleteCurrentText();
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void notifyWrongInput() {
    _wrongInputAnimationController.forward();
  }

  void setCurrentText(String text) {
    if(_pinInput.length < 6) {
      setState(() {
        _pinInput = _pinInput + text;
      });
    }
  }

  void _checkPin() async {
    // check if the length of the _pinInput already 6
    if(_pinInput.length >= 6) {
      // call the function to get the current pin
      if(widget.getPin != null) {
        widget.getPin!(_pinInput);
      }

      // verify whether pin is correct or not?
      if(!_verifyPIN()) {
        // wrong PIN, reset the _pinInput into ""
        // and showed the animation
        notifyWrongInput();
        _pinInput = "";

        // if we got call for onError
        if(widget.onError != null) {
          widget.onError!();
        }
      }
      else {
        // if we got call for onSuccess
        if(widget.onSuccess != null) {
          await Future.delayed(const Duration(milliseconds: 300));
          widget.onSuccess!();
        }
      }
    }
  }

  void deleteCurrentText() {
    if(_pinInput.isNotEmpty) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
      });
    }
  }

  bool _verifyPIN() {
    var pinBytes = utf8.encode(_pinInput + widget.hashKey + _pinInput);
    var pinDigest = sha256.convert(pinBytes);

    // print("Digest as bytes: ${pinDigest.bytes}");
    // print("Digest as hex string: $pinDigest");

    // check if the pinDigest the same as the hashPin given
    if(pinDigest.toString() == widget.hashPin) {
      return true;
    }
    return false;
  }

  Widget _button({required Widget value, Color? color, double? height, int? flex, VoidCallback? onPress}) {
    Color currentColor = (color ?? Colors.transparent);
    double currentHeight = (height ?? 30);
    int flexNum = (flex ?? 1);

    return Expanded(
      flex: flexNum,
      child: GestureDetector(
        onTap: (() {
          if(onPress != null) {
            onPress();
          // ignore: empty_statements
          };
        }),
        child: Container(
          height: currentHeight,
          color: currentColor,
          child: value,
        ),
      ),
    );
  }
}