import 'package:flutter/material.dart';

@immutable
class PostCard extends StatelessWidget {
  final Color backgroundColor;
  final bool extreme;
  final String handle;
  final String displayName;
  final String body;
  final double sentiment;
  final Function()? onCopyPressed;
  final Function()? onSharePressed;
  final Function()? onOpenInBrowserPressed;
  final Function()? onOpenProfileInBrowserPressed;

  const PostCard(
      {super.key,
      required this.backgroundColor,
      required this.extreme,
      required this.handle,
      required this.displayName,
      required this.body,
      required this.sentiment,
      this.onCopyPressed,
      this.onSharePressed,
      this.onOpenInBrowserPressed,
      this.onOpenProfileInBrowserPressed});

  Color sentimentColor(double sentiment) {
    num lerpPoint = -sentiment;
    if (lerpPoint < 0.0) {
      lerpPoint = 0.0;
    }

    return Color.lerp(Colors.black, Colors.red, lerpPoint.toDouble())!;
  }

  Widget buildSentimentText(BuildContext context, double sentiment) {
    Color color = sentimentColor(sentiment);
    bool bold = sentiment < -0.75; // TODO: Lift to a not-so-magic number
    return Text(sentiment.toStringAsFixed(2),
        style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Material(
          color: backgroundColor,
          elevation: 5.0,
          shape: RoundedRectangleBorder(
              side: BorderSide(
                  width: extreme ? 2.0 : 1.0,
                  color: extreme ? Colors.red : Colors.transparent),
              borderRadius: const BorderRadius.all(Radius.circular(8.0))),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
              child: Column(children: [
                // Header row
                Row(
                    // Align smaller widgets to the top of the header.
                    // This puts the handle near the top of the card.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display name and handle
                      Expanded(
                          child: InkWell(
                              onTap: onOpenProfileInBrowserPressed,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8.0)),
                              child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Display name
                                        Text(
                                          displayName,
                                          style:
                                              const TextStyle(fontSize: 16.0),
                                          overflow: TextOverflow.fade,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                        // Handle
                                        Text(
                                          handle,
                                          style:
                                              const TextStyle(fontSize: 12.0),
                                          overflow: TextOverflow.fade,
                                          maxLines: 1,
                                          softWrap: false,
                                        )
                                      ])))),
                      Expanded(flex: 0, child: Container()),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Copy IconButton
                            IconButton(
                                iconSize: 24.0,
                                onPressed: onCopyPressed,
                                icon: const Icon(Icons.copy)),
                            // Share IconButton
                            IconButton(
                                iconSize: 24.0,
                                icon: const Icon(Icons.share),
                                onPressed: onSharePressed),
                            IconButton(
                                iconSize: 24.0,
                                onPressed: onOpenInBrowserPressed,
                                icon: const Icon(Icons.open_in_browser))
                          ]),
                    ]),
                // Body
                Divider(
                    height: 4.0, thickness: 1.0, indent: 8.0, endIndent: 8.0),
                Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
                    child: Row(
                      children: [
                        // Post body
                        Expanded(child: SelectableText(body)),
                        // Sentiment score
                        buildSentimentText(context, sentiment)
                      ],
                    )),
              ]))),
    );
  }
}
