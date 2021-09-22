import 'package:flutter/material.dart';

class AnimationExpand extends StatefulWidget {
  final Widget child;
  final bool expand;
  final int? duration;
  final Function(bool)? onExpand;

  const AnimationExpand({ Key? key, required this.child, required this.expand, this.duration, this.onExpand}) : super(key: key);

  @override
  _AnimationExpandState createState() => _AnimationExpandState();
}

class _AnimationExpandState extends State<AnimationExpand> with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _animation;
  late int _duration;

  @override
  void initState() {
    super.initState();
    
    // init widget for animation
    _prepareAnimation();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimationExpand oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkIfExpanded();
  }

  void _prepareAnimation() {
    _duration = (widget.duration ?? 500);

    _expandController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _duration),
    );
    _animation = CurvedAnimation(parent: _expandController, curve: Curves.fastOutSlowIn);
  }

  void _checkIfExpanded() {
    if(widget.expand) {
      _expandController.forward();
      if(widget.onExpand != null) {
        widget.onExpand!(true);
      }
    }
    else {
      _expandController.reverse();
      if(widget.onExpand != null) {
        widget.onExpand!(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axisAlignment: 1.0,
      sizeFactor: _animation,
      child: widget.child,
    );
  }
}