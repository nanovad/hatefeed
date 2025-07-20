import 'package:flutter/material.dart';
import 'package:hatefeed/appearance_preferences_model.dart';
import 'package:hatefeed/post_card/widget_post_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatefeed/processed_post.dart';
import 'package:provider/provider.dart';

void main() {
  group("Layout sizing", () {
    testWidgets("Large display names / handles do not overflow boundaries",
        (tester) async {
      await tester.pumpWidget(ChangeNotifierProvider(
          create: (_) => AppearancePreferencesModel(),
          child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                  child: ConstrainedBox(
                      constraints:
                          BoxConstraints.loose(const Size.fromWidth(750.0)),
                      child: ListView(reverse: true, children: [
                        PostCard(
                          post: ProcessedPost(
                              at: DateTime.now(),
                              did: "testdid",
                              rkey: "testrkey",
                              displayName: "longdisplayname" * 100,
                              handle: "longhandle" * 100,
                              text: "sample text",
                              sentiment: -0.95,
                              tokenSentiments: [
                                TokenSentiment(token: "sample ", score: 0.0),
                                TokenSentiment(token: "text", score: 0.0),
                              ]),
                        )
                      ]))))));
    });
  });

  testWidgets("reduceLikeSpans works properly", (tester) async {
    List<TokenSentiment> sentiments = [
      TokenSentiment(token: "This ", score: 0.0),
      TokenSentiment(token: "is ", score: 0.0),
      TokenSentiment(token: "very ", score: 0.0),
      TokenSentiment(token: "long ", score: 0.0),
      TokenSentiment(token: "sample ", score: 0.0),
      TokenSentiment(token: "text   ", score: 0.0),
      TokenSentiment(token: "with ", score: 0.0),
      TokenSentiment(token: "weird ", score: 0.0),
      TokenSentiment(token: "whitespace\n", score: 0.0),
      TokenSentiment(token: "line breaks\n", score: 0.0),
      TokenSentiment(token: "and ", score: 0.0),
      TokenSentiment(token: "words ", score: 0.0),
      TokenSentiment(token: "with ", score: 0.0),
      TokenSentiment(token: "terrible ", score: -1.0),
      TokenSentiment(token: "scores.", score: 0.0),
    ];
    List<TokenSentiment> reducedSpans = [
      TokenSentiment(
          token:
              "This is very long sample text   with weird whitespace\nline breaks\nand words with ",
          score: 0.0),
      TokenSentiment(token: "terrible ", score: -1.0),
      TokenSentiment(token: "scores.", score: 0.0),
    ];
    // var body = "This is very long sample text   with weird whitespace\nline breaks\nand words with terrible scores.";

    expect(PostCard.reduceLikeSpans(sentiments), equals(reducedSpans));
  });
}
