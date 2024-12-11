import 'package:flutter/material.dart';
import 'package:hatefeed/feed.dart';

@immutable
class ConnectionStateIndicator extends StatelessWidget {
  final FeedState state;
  const ConnectionStateIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String tooltip = "";
    switch (state) {
      case FeedState.initial:
        icon = Icons.timer;
        tooltip = "Not connected";
        break;
      case FeedState.connecting:
        icon = Icons.cloud_outlined;
        tooltip = "Connecting";
        break;
      case FeedState.connected:
        icon = Icons.cloud_done;
        tooltip = "Connected";
        break;
      case FeedState.disconnected:
        icon = Icons.cloud_off;
        tooltip = "Disconnected";
        break;
      default:
        icon = Icons.question_mark;
        tooltip = "Unknown";
        break;
    }
    return Tooltip(message: tooltip, child: Icon(icon));
  }
}
