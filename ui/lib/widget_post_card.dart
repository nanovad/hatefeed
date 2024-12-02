import 'package:flutter/material.dart';

@immutable
class PostCard extends StatelessWidget {
  final Color backgroundColor;
  final bool extreme;
  final String handle;
  final String body;
  final double sentiment;
  final Function()? onCopyPressed;
  final Function()? onSharePressed;

  const PostCard(
      {super.key,
      required this.backgroundColor,
      required this.extreme,
      required this.handle,
      required this.body,
      required this.sentiment,
      this.onCopyPressed,
      this.onSharePressed});

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
                    mainAxisSize: MainAxisSize.max,
                    // Align smaller widgets to the top of the header.
                    // This puts the handle near the top of the card.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author handle
                      Padding(
                          padding:
                              const EdgeInsets.fromLTRB(4.0, 8.0, 0.0, 0.0),
                          child: Text(handle,
                              style: const TextStyle(fontSize: 16.0))),
                      const Spacer(),
                      Row(children: [
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
                      ]),
                    ]),
                // Body
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
