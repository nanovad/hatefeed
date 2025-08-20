import 'package:flutter/material.dart';

enum FloatPopDirection { ltr, rtl }

class FloatUpAnimation extends StatefulWidget {
  final Widget child;
  final Function? onCompleted;
  final FloatPopDirection floatPopDirection;
  final AnimationController controller;

  const FloatUpAnimation(
      {super.key,
      required this.child,
      required this.floatPopDirection,
      required this.controller,
      this.onCompleted});

  @override
  State<StatefulWidget> createState() => _FloatUpAnimationState();
}

class _FloatUpAnimationState extends State<FloatUpAnimation>
    with SingleTickerProviderStateMixin {
  late Animation<double> parentAnimation;
  late Animation<double> opacityAnimation;
  late Animation<Offset> vertOffsetAnimation;
  late Animation<Offset> horizOffsetAnimation;

  @override
  void initState() {
    super.initState();
    widget.controller.resync(this);
    parentAnimation =
        Tween<double>(begin: 0, end: 1.0).animate(widget.controller)
          ..addListener(() {
            setState(() {});
            if (widget.controller.isCompleted) {
              widget.onCompleted?.call();
            }
          });

    var horizOffset = 0.0;
    if (widget.floatPopDirection == FloatPopDirection.ltr) {
      horizOffset = 1.0;
    } else if (widget.floatPopDirection == FloatPopDirection.rtl) {
      horizOffset = -1.0;
    }

    vertOffsetAnimation = MaterialPointArcTween(
            begin: Offset(0.0, 0.0), end: Offset(0.0, -2.0))
        .animate(
            CurvedAnimation(parent: parentAnimation, curve: Curves.decelerate));
    horizOffsetAnimation = MaterialPointArcTween(
            begin: Offset(0.0, 0.0), end: Offset(horizOffset, 0.0))
        .animate(CurvedAnimation(
            parent: parentAnimation, curve: Curves.easeOutCirc));

    opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10.0),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50.0),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40.0),
    ]).animate(parentAnimation);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: opacityAnimation,
        child: SlideTransition(
            position: vertOffsetAnimation,
            child: SlideTransition(
                position: horizOffsetAnimation, child: widget.child)));
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}
