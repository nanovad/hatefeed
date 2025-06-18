import 'package:flutter/material.dart';
import 'package:hatefeed/post_card/widget_post_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatefeed/processed_post.dart';

void main() {
  group("Layout sizing", () {
    testWidgets("Large display names / handles do not overflow boundaries",
        (tester) async {
      await tester.pumpWidget(Directionality(
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
                            sentiment: -0.95))
                  ])))));
    });
  });
}
