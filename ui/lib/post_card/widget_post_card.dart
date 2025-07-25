import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatefeed/analytics_helpers.dart';
import 'package:hatefeed/appearance_preferences_model.dart';
import 'package:hatefeed/post_card/header.dart';
import 'package:hatefeed/processed_post.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

@immutable
class PostCard extends StatelessWidget {
  final ProcessedPost post;

  // Use the hydrated author's display name, or the provided displayName from
  // the server. If either of those is blank (may be the case for accounts
  // that have never set a displayName), use the handle.
  // This is consistent with how Bluesky renders them.
  String get displayName {
    var displayName = post.fullPost?.author.displayName ?? post.displayName;
    if (displayName?.isEmpty ?? true) {
      displayName = handle;
    }
    return displayName!;
  }

  // Use the locally hydrated author's handle, if available, or the provided
  // handle from the server, which is allowed to be null. If it is, use a
  // default text of "pending".
  String get handle =>
      post.fullPost?.author.handle ?? post.handle ?? "<pending>";

  bool get _extreme => post.sentiment < -0.9;

  String get postLink =>
      "https://bsky.app/profile/${post.did}/post/${post.rkey}";
  String get profileLink => "https://bsky.app/profile/${post.did}";

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppearancePreferencesModel>(
        builder: (consumerContext, appearancePrefs, child) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        // Elevate each card off the background like the Material Card widget
        child: Material(
            color: Theme.of(consumerContext).colorScheme.surface,
            elevation: 5.0,
            // Give it a rounded border, colored red for extreme sentiment scores
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    width: _extreme ? 2.0 : 1.0,
                    color: _extreme ? Colors.red : Colors.transparent),
                borderRadius: const BorderRadius.all(Radius.circular(8.0))),
            // Further pad the interior of the card to give the border breathing
            // room
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                // Card body - header, divider, post text, and sentiment score
                child: Column(children: [
                  PostCardHeader(
                      onOpenProfileInBrowserPressed: () =>
                          openProfile(consumerContext),
                      onCopyPressed: () => copyPostText(consumerContext),
                      onSharePressed: () => copyShareLink(consumerContext),
                      onOpenPostInBrowserPressed: () =>
                          openPost(consumerContext),
                      avatarUrl: appearancePrefs.showAvatars
                          ? post.fullPost?.author.avatar
                              ?.replaceFirst("avatar", "avatar_thumbnail")
                          : null,
                      displayName: displayName,
                      handle: handle),
                  Divider(
                      height: 4.0, thickness: 1.0, indent: 8.0, endIndent: 8.0),
                  // Body
                  Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
                      child: Row(
                        children: [
                          // Post text
                          Expanded(
                              child: buildPostText(context, appearancePrefs)),
                          // Sentiment score
                          buildSentimentText(consumerContext, post.sentiment)
                        ],
                      )),
                ]))),
      );
    });
  }

  // Widget build helpers
  Color sentimentColor(double sentiment) {
    num lerpPoint = -sentiment;
    if (lerpPoint < 0.0) {
      lerpPoint = 0.0;
    }

    return Color.lerp(Colors.black, Colors.red, lerpPoint.toDouble())!;
  }

  Widget buildPostText(
      BuildContext context, AppearancePreferencesModel appearancePrefs) {
    return appearancePrefs.colorBodySentiment
        ? buildColoredText(context)
        : SelectableText(post.text);
  }

  static List<TokenSentiment> reduceLikeSpans(List<TokenSentiment> sentiments) {
    /// Reduce a list of token sentiments into spans of tokens with the same
    /// score. Used to reduce the number of spans the renderer has to draw.

    List<TokenSentiment> ret = List.empty(growable: true);
    TokenSentiment last = TokenSentiment(token: "", score: sentiments[0].score);

    // Build the token spans by accumulating all token text into one
    // TokenSentiment instance for each run of a specific score.
    for (var sentiment in sentiments) {
      if (sentiment.score != last.score) {
        ret.add(last);
        last = sentiment.clone();
      } else {
        last.token += sentiment.token;
      }
    }
    ret.add(last);
    return ret;
  }

  RichText buildColoredText(BuildContext context) {
    /// Build a RichText widget for the post body with words colored according
    /// to sentiment score.

    FontWeight mapFontWeight(double score) {
      if (score < -0.80) {
        return FontWeight.bold;
      } else if (score < -0.60) {
        return FontWeight.w600;
      } else if (score < -0.30) {
        return FontWeight.w500;
      }
      return FontWeight.normal;
    }

    Color bodySentimentColor(BuildContext context, double sentiment) {
      num lerpPoint = -sentiment;
      if (lerpPoint < 0.0) {
        lerpPoint = 0.0;
      }

      // Boosted color
      return Color.lerp(Theme.of(context).textTheme.bodyMedium?.color,
          Colors.red, lerpPoint.toDouble() * 2)!;
    }

    List<TextSpan> spans = reduceLikeSpans(post.tokenSentiments)
        .map((e) => TextSpan(
            text: e.token,
            style: TextStyle(
                color: bodySentimentColor(context, e.score),
                fontWeight: mapFontWeight(e.score))))
        .toList();
    return RichText(text: TextSpan(children: spans));
  }

  Widget buildSentimentText(BuildContext context, double sentiment) {
    Color color = sentimentColor(sentiment);
    bool bold = sentiment < -0.75; // TODO: Lift to a not-so-magic number
    return Text(sentiment.toStringAsFixed(2),
        style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal));
  }

  // Button callbacks
  void copyPostText(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: "$handle\n${post.text}"));
    // Make sure we are mounted in the Widget tree; if we are not, we can't
    // show a toast.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Copied post to clipboard"),
          duration: Duration(milliseconds: 1500)));
    }
    await FirebaseAnalytics.instance.logEvent(
        name: "post_copy_pressed",
        parameters: expandPostForAnalyticsParams(post));
  }

  void copyShareLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: postLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Copied link to post to clipboard"),
          duration: Duration(milliseconds: 1500)));
    }
    await FirebaseAnalytics.instance.logEvent(
        name: "post_share_pressed",
        parameters: expandPostForAnalyticsParams(post));
  }

  void openPost(BuildContext context) async {
    await launchUrl(Uri.parse(postLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Opened post in browser"),
          duration: Duration(milliseconds: 1500)));
    }
    await FirebaseAnalytics.instance.logEvent(
        name: "post_open_in_browser_pressed",
        parameters: expandPostForAnalyticsParams(post));
  }

  void openProfile(BuildContext context) async {
    await launchUrl(Uri.parse(profileLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Opened profile in browser"),
          duration: Duration(milliseconds: 1500)));
    }
    await FirebaseAnalytics.instance.logEvent(
        name: "post_open_profile_in_browser_pressed",
        parameters: expandPostForAnalyticsParams(post));
  }
}
