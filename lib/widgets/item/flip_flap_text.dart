import 'package:flutter/material.dart';

class FlipFlapText extends StatefulWidget {
  final List<Widget> children;

  const FlipFlapText({
    super.key,
    required this.children,
  });

  @override
  State<FlipFlapText> createState() => _FlipFlapTextState();
}

class _FlipFlapTextState extends State<FlipFlapText> {
  late int _index;

  @override
  void initState() {
    super.initState();

    // initialize variable
    _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: (() {
        setState(() {          
          _index = _index + 1;
          // check if index already passed the children
          if (_index > (widget.children.length - 1)) {
            // retun back index to 0
            _index = 0;
          }
        });
      }),
      child: (_index < widget.children.length ? widget.children[_index] : _resetIndex()),
    );
  }

  Widget _resetIndex() {
    _index = 0;
    return widget.children[_index];
  }
}