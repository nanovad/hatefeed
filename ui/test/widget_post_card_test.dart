import 'package:flutter/material.dart';
import 'package:hatefeed/widget_post_card.dart';
import 'package:flutter_test/flutter_test.dart';

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
                        backgroundColor: Colors.white,
                        extreme: true,
                        handle: "long.handle" * 100,
                        displayName: "longdisplayname" * 100,
                        body: "Sample body",
                        sentiment: -0.95)
                  ])))));
    });
  });
}
