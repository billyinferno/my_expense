import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:my_expense/_index.g.dart';

class LoadingScreen {
  LoadingScreen._shareInstance();
  static final LoadingScreen _shared = LoadingScreen._shareInstance();
  factory LoadingScreen.instance() => _shared;

  LoadingScreenController? _controller;

  void show({
    required BuildContext context,
    String text = "Loading",
  }) {
    if (_controller?.update(text) ?? false) {
      return;
    }
    else {
      _controller = showOverlay(
        context: context,
        text: text,
      );
    }
  }

  void hide() {
    _controller?.close();
    _controller = null;
  }

  LoadingScreenController? showOverlay({
    required BuildContext context,
    required String text,
  }) {
    final textController = StreamController<String>();
    textController.add(text);

    final OverlayState state = Overlay.of(context);
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Size size = renderBox.size;

    final OverlayEntry overlay = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black.withAlpha(150),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: size.width * 0.8,
                maxHeight: size.width * 0.8,
                minWidth: size.width * 0.5,
              ),
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SpinKitFadingCube(
                    color: accentColors[0],
                    size: 25,
                  ),
                  const SizedBox(height: 10,),
                  StreamBuilder(
                    stream: textController.stream,
                    builder: ((context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          snapshot.requireData,
                          style: TextStyle(
                            color: darkAccentColors[0],
                            fontSize: 10,
                          ),
                        );
                      }
                      else {
                        return Container();
                      }
                    })
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );

    state.insert(overlay);

    return LoadingScreenController(
      close: (() {
        textController.close();
        overlay.remove();
        return true;
      }),
      update: ((String text) {
        textController.add(text);
        return true;
      }),
    );
  }
}