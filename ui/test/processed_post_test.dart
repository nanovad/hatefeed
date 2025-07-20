import 'package:hatefeed/processed_post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      "JSON deserialization results in an identical object to an instantiated one",
      () {
    ProcessedPost postFromJson = ProcessedPost.fromJson({
      "at": 1746327111492108,
      "text": "Test post",
      "handle": "test.example.com",
      "displayName": "Test user",
      "did": "baddid",
      "rkey": "fakerkey",
      "sentiment": -0.75,
      "tokenSentiments": [
        {"token": "Test ", "score": 0.0},
        {"token": "post", "score": 0.0}
      ]
    });
    ProcessedPost postInstantiated = ProcessedPost(
        at: DateTime.fromMicrosecondsSinceEpoch(1746327111492108),
        text: "Test post",
        handle: "test.example.com",
        displayName: "Test user",
        did: "baddid",
        rkey: "fakerkey",
        sentiment: -0.75,
        tokenSentiments: [
          TokenSentiment(token: "Test ", score: 0.0),
          TokenSentiment(token: "post", score: 0.0),
        ]);

    expect(postFromJson, postInstantiated);
  });

  test("Round-trip ser/deser works", () {
    ProcessedPost original = ProcessedPost(
        at: DateTime.fromMicrosecondsSinceEpoch(1746327111492108),
        text: "Test post",
        handle: "test.example.com",
        displayName: "Test user",
        did: "baddid",
        rkey: "fakerkey",
        sentiment: -0.75,
        tokenSentiments: [
          TokenSentiment(token: "Test ", score: 0.0),
          TokenSentiment(token: "post", score: 0.0),
        ]);
    var originalSerialized = {
      "at": 1746327111492108,
      "text": "Test post",
      "handle": "test.example.com",
      "displayName": "Test user",
      "did": "baddid",
      "rkey": "fakerkey",
      "sentiment": -0.75,
      "tokenSentiments": [
        {"token": "Test ", "score": 0.0},
        {"token": "post", "score": 0.0}
      ]
    };
    var serialized = original.toJson();
    var deserialized = ProcessedPost.fromJson(serialized);
    expect(original, deserialized);
    expect(originalSerialized, serialized);
  });
}
