import 'package:flutter/material.dart';
import 'package:hatefeed/feed.dart';
import 'package:hatefeed/widget_feed_mode_switcher.dart';
import 'package:hatefeed/widget_theme_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModal extends StatefulWidget {
  final ThemeMode defaultThemeMode;
  final FeedController feedController;

  final Function(ThemeMode)? onThemeModeChanged;

  const SettingsModal(
      {super.key,
      required this.feedController,
      required this.defaultThemeMode,
      this.onThemeModeChanged});

  @override
  State<StatefulWidget> createState() => SettingsModalState();
}

class SettingsModalState extends State<SettingsModal> {
  late FeedMode feedMode;
  late ThemeMode themeMode;
  SharedPreferences? prefs;

  @override
  void initState() {
    feedMode = widget.feedController.mode;
    themeMode = widget.defaultThemeMode;
    SharedPreferences.getInstance().then((v) {
      prefs = v;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const intervalMin = 500.0;
    const intervalMax = 10000.0;
    const intervalDivisions = (intervalMax - intervalMin) ~/ 100;
    return Column(
      children: [
        const Padding(
            padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
            child: Text("Settings", style: TextStyle(fontSize: 18.0))),
        const Divider(thickness: 1.0),
        Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Row(children: [
              const Text("Theme", style: TextStyle(fontSize: 16.0)),
              const Spacer(),
              ThemeSwitcher(
                  defaultThemeMode: themeMode,
                  onThemeModeChanged: widget.onThemeModeChanged)
            ])),
        // Feed mode and associated sliders
        Column(children: [
          // Label and segmented button
          Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: Row(
                children: [
                  const Text("Feed mode", style: TextStyle(fontSize: 16.0)),
                  const Spacer(),
                  FeedModeSwitcher(
                    defaultFeedMode: feedMode,
                    onFeedModeChanged: (selected) {
                      setState(() {
                        feedMode = selected;
                        widget.feedController.setMode(feedMode);
                        prefs?.setInt("feed_mode", feedMode.index);
                      });
                    },
                  )
                ],
              )),
          // Slider according to which mode we're in
          // Interval
          Visibility(
              visible: feedMode == FeedMode.interval,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Column(children: [
                    Row(children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 32.0),
                          child: Text("Interval:  ${renderInterval()}",
                              style: const TextStyle(fontSize: 16.0)))
                    ]),
                    Row(
                      children: [
                        const Text("${intervalMin}ms"),
                        Expanded(
                            child: Slider(
                          min: intervalMin,
                          max: intervalMax,
                          divisions: intervalDivisions,
                          value: widget.feedController.intervalMs.toDouble(),
                          label: renderInterval(),
                          onChanged: (value) => setState(() =>
                              widget.feedController.intervalMs = value.toInt()),
                          onChangeEnd: (value) {
                            widget.feedController.setInterval(value.toInt());
                                  prefs?.setInt("feed_interval",
                                      widget.feedController.intervalMs);
                          }
                        )),
                        const Text("${intervalMax}ms")
                      ],
                    )
                  ]))),
          // Threshold
          Visibility(
              visible: feedMode == FeedMode.threshold,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Column(children: [
                    Row(children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 32.0),
                          child: Text("Threshold:  ${renderThreshold()}",
                              style: const TextStyle(fontSize: 16.0)))
                    ]),
                    Row(children: [
                      const Text("-1.0"),
                      Expanded(
                          child: Slider(
                        min: -1.0,
                        max: 0.0,
                        divisions: 100,
                        value: widget.feedController.threshold,
                        label: renderThreshold(),
                        onChanged: (value) => setState(
                            () => widget.feedController.threshold = value),
                        onChangeEnd: (value) {
                            widget.feedController.setThreshold(value);
                            prefs?.setDouble("feed_threshold", value);
                        }
                      )),
                      const Text("0.0")
                    ])
                  ])))
        ])
      ],
    );
  }

  String renderInterval() {
    // Dart doesn't have a way to round to e.g. tenths, so...
    var interval =
        (widget.feedController.intervalMs.toDouble() / 10.0).round() * 10;
    return "${interval}ms";
  }

  String renderThreshold() {
    return widget.feedController.threshold.toStringAsFixed(2);
  }
}
