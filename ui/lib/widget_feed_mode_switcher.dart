import 'package:flutter/material.dart';

enum FeedMode { threshold, interval }

class FeedModeSwitcher extends StatefulWidget {
  final FeedMode defaultFeedMode;
  final Function(FeedMode)? onFeedModeChanged;

  const FeedModeSwitcher(
      {super.key,
      this.defaultFeedMode = FeedMode.interval,
      this.onFeedModeChanged});

  @override
  State<FeedModeSwitcher> createState() => FeedModeSwitcherState();
}

class FeedModeSwitcherState extends State<FeedModeSwitcher> {
  FeedMode? selected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      segments: const [
        ButtonSegment<FeedMode>(
            label: Text("Threshold"),
            value: FeedMode.threshold,
            icon: Icon(Icons.line_axis)),
        ButtonSegment<FeedMode>(
            label: Text("Interval"),
            value: FeedMode.interval,
            icon: Icon(Icons.timer)),
      ],
      selected: <FeedMode>{selected ?? widget.defaultFeedMode},
      onSelectionChanged: (Set<FeedMode> s) {
        setState(() {
          var previous = selected;
          selected = s.first;
          if (previous != selected) {
            widget.onFeedModeChanged?.call(selected ?? widget.defaultFeedMode);
          }
        });
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -4.0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
