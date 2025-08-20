import 'package:flutter/material.dart';
import 'package:hatefeed/keyboard_dismissible.dart';
import 'package:hatefeed/post_card/widget_post_card.dart';
import 'package:hatefeed/widget_float_up_animation.dart';

class SwipeableScreen extends StatefulWidget {
  final PostCard? Function() getNextPost;
  final Function(Duration duration)? onDismissedDislike;
  final Function(Duration duration)? onDismissedLike;

  const SwipeableScreen(
      {super.key,
      required this.getNextPost,
      this.onDismissedDislike,
      this.onDismissedLike});

  @override
  State<SwipeableScreen> createState() => _SwipeableScreenState();
}

class _SwipeableScreenState extends State<SwipeableScreen>
    with TickerProviderStateMixin {
  final Widget _loadingSpinner = const Center(
      child: SizedBox(
          height: 48.0, width: 48.0, child: CircularProgressIndicator()));
  Widget? tree1;
  Widget? tree2;
  CrossFadeState cfs = CrossFadeState.showFirst;

  late AnimationController likeAnimController;
  FloatUpAnimation? likeAnim;
  late AnimationController dislikeAnimController;
  FloatUpAnimation? dislikeAnim;

  DateTime? _viewStarted;

  @override
  void initState() {
    super.initState();
    buildAndAnimateNext();
    likeAnimController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    likeAnim = FloatUpAnimation(
      key: Key("likeAnim"),
      controller: likeAnimController,
      floatPopDirection: FloatPopDirection.rtl,
      child: const Text("😍", style: TextStyle(fontSize: 48.0)),
    );

    dislikeAnimController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    dislikeAnim = FloatUpAnimation(
      key: Key("dislikeAnim"),
      controller: dislikeAnimController,
      floatPopDirection: FloatPopDirection.ltr,
      child: const Text("🤮", style: TextStyle(fontSize: 48.0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      AnimatedCrossFade(
          firstChild: tree1 ?? _loadingSpinner,
          secondChild: tree2 ?? _loadingSpinner,
          crossFadeState: cfs,
          duration: Durations.medium2,
          layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
            return Stack(
                alignment: Alignment.center, children: [topChild, bottomChild]);
          })
    ];

    children.add(Align(
        alignment: Alignment.centerRight, child: likeAnim ?? Container()));
    children.add(Align(
        alignment: Alignment.centerLeft, child: dislikeAnim ?? Container()));

    return Stack(alignment: Alignment.center, children: children);
  }

  void onDismissed(DismissDirection dd) {
    DateTime now = DateTime.now();
    Duration viewDuration = now.difference(_viewStarted ?? now);
    if (dd == DismissDirection.startToEnd) {
      onDismissedLike(viewDuration);
    }
    if (dd == DismissDirection.endToStart) {
      onDismissedDislike(viewDuration);
    }
    buildAndAnimateNext();
  }

  void onDismissedLike(Duration viewDuration) {
    setState(() {
      likeAnimController.reset();
      likeAnimController.forward();
    });
    widget.onDismissedLike?.call(viewDuration);
  }

  void onDismissedDislike(Duration viewDuration) {
    setState(() {
      dislikeAnimController.reset();
      dislikeAnimController.forward();
    });
    widget.onDismissedDislike?.call(viewDuration);
  }

  void buildAndAnimateNext() {
    _viewStarted = DateTime.now();
    var nextPost = widget.getNextPost();
    Widget? newTree;
    if (nextPost != null) {
      newTree = buildDismissiblePostCard(nextPost);
    } else {
      Future.delayed(Duration(seconds: 1), () => buildAndAnimateNext());
      newTree = _loadingSpinner;
    }
    setState(() {
      if (cfs == CrossFadeState.showFirst) {
        tree2 = newTree!;
        cfs = CrossFadeState.showSecond;
      } else {
        tree1 = newTree!;
        cfs = CrossFadeState.showFirst;
      }
    });
  }

  Widget buildDismissiblePostCard(PostCard card) {
    return KeyboardDismissible(
      key: UniqueKey(),
      onDismissed: onDismissed,
      resizeDuration: null,
      child: Center(
        child: ConstrainedBox(
            constraints: BoxConstraints.loose(const Size.fromWidth(750.0)),
            child: card),
      ),
    );
  }

  @override
  void dispose() {
    dislikeAnimController.dispose();
    likeAnimController.dispose();
    super.dispose();
  }
}
