import 'package:flutter/material.dart';

class ThemeSwitcher extends StatefulWidget {
  final ThemeMode defaultThemeMode;
  final Function(ThemeMode)? onThemeModeChanged;

  const ThemeSwitcher(
      {super.key,
      this.defaultThemeMode = ThemeMode.system,
      this.onThemeModeChanged});

  @override
  State<ThemeSwitcher> createState() => ThemeSwitcherState();
}

class ThemeSwitcherState extends State<ThemeSwitcher> {
  ThemeMode? selected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton(
      segments: const [
        ButtonSegment<ThemeMode>(
            value: ThemeMode.system, icon: Icon(Icons.app_settings_alt)),
        ButtonSegment<ThemeMode>(
            value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
        ButtonSegment<ThemeMode>(
            value: ThemeMode.light, icon: Icon(Icons.light_mode))
      ],
      selected: <ThemeMode>{selected ?? widget.defaultThemeMode},
      onSelectionChanged: (Set<ThemeMode> s) {
        setState(() {
          var previous = selected;
          selected = s.first;
          if (previous != selected) {
            widget.onThemeModeChanged
                ?.call(selected ?? widget.defaultThemeMode);
          }
        });
      },
    );
  }
}
