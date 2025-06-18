import 'package:flutter/material.dart';

class PostCardHeader extends StatelessWidget {
  final Function()? onOpenProfileInBrowserPressed;
  final Function()? onCopyPressed;
  final Function()? onSharePressed;
  final Function()? onOpenPostInBrowserPressed;
  final String displayName;
  final String handle;

  const PostCardHeader({
    super.key,
    required this.displayName,
    required this.handle,
    this.onOpenProfileInBrowserPressed,
    this.onCopyPressed,
    this.onSharePressed,
    this.onOpenPostInBrowserPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Header row
    return Row(
        // Align smaller widgets to the top of the header.
        // This puts the handle near the top of the card.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display name and handle
          Expanded(
              child: InkWell(
                  onTap: onOpenProfileInBrowserPressed,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display name
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 16.0),
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              softWrap: false,
                            ),
                            // Handle
                            Text(
                              handle,
                              style: const TextStyle(fontSize: 12.0),
                              overflow: TextOverflow.fade,
                              maxLines: 1,
                              softWrap: false,
                            )
                          ])))),
          // A widget to take up the free space left between the display name
          // and the buttons; keeps the inkwell sized appropriately and the
          // buttons aligned to the right edge.
          Expanded(flex: 0, child: Container()),
          PostCardButtons(
              onCopyPressed: onCopyPressed,
              onSharePressed: onSharePressed,
              onOpenInBrowserPressed: onOpenPostInBrowserPressed)
        ]);
  }
}

class PostCardButtons extends StatelessWidget {
  final Function()? onCopyPressed;
  final Function()? onSharePressed;
  final Function()? onOpenInBrowserPressed;

  const PostCardButtons(
      {super.key,
      this.onCopyPressed,
      this.onSharePressed,
      this.onOpenInBrowserPressed});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      // Copy IconButton
      IconButton(
          iconSize: 24.0,
          onPressed: onCopyPressed,
          icon: const Icon(Icons.copy)),
      // Share IconButton
      IconButton(
          iconSize: 24.0,
          onPressed: onSharePressed,
          icon: const Icon(Icons.share)),
      IconButton(
          iconSize: 24.0,
          onPressed: onOpenInBrowserPressed,
          icon: const Icon(Icons.open_in_browser))
    ]);
  }
}
