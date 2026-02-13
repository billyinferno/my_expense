import 'package:flutter/material.dart';

class AnimationExpand extends StatefulWidget {
  final AnimationController? controller;
  final Widget child;
  final bool expand;
  final int? duration;
  final Function(bool)? onExpand;

  const AnimationExpand({ super.key, this.controller, required this.child, required this.expand, this.duration, this.onExpand});

  @override
  State<AnimationExpand> createState() => _AnimationExpandState();
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

    // check whether we have controller being sent from parent or not?
    // if not then we can create our own controller
    if (widget.controller != null) {
      _expandController = widget.controller!;
    }
    else {
      _expandController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _duration),
      );
    }

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
      alignment: AlignmentGeometry.bottomEnd,
      sizeFactor: _animation,
      child: widget.child,
    );
  }
}