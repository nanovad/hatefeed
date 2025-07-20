import 'dart:async';
import 'dart:developer';

import 'package:bluesky/bluesky.dart';
import 'package:bluesky/core.dart';

class TokenSentiment {
  String token;
  double score;

  TokenSentiment({required this.token, required this.score});

  @override
  int get hashCode => Object.hashAllUnordered([token, score]);

  @override
  bool operator ==(Object other) {
    return other is TokenSentiment &&
        other.token == token &&
        other.score == score;
  }

  // TokenSentiment.clone(TokenSentiment s): this(token: s.token, score: s.score);
  TokenSentiment clone() {
    return TokenSentiment(token: token, score: score);
  }

  @override
  String toString() {
    return "TokenSentiment{token: \"$token\", score $score}";
  }

  TokenSentiment.fromJson(Map<String, dynamic> json)
      : token = json["token"],
        score = json["score"];

  Map<String, dynamic> toJson() {
    return {"token": token, "score": score};
  }
}

class ProcessedPost {
  DateTime at;
  String text;
  String? handle;
  String? displayName;
  String did;
  String rkey;
  double sentiment;
  List<TokenSentiment> tokenSentiments;
  Post? fullPost;
  Function? onHydrationCompleted;

  ProcessedPost(
      {required this.at,
      required this.text,
      required this.handle,
      required this.displayName,
      required this.did,
      required this.rkey,
      required this.sentiment,
      required this.tokenSentiments});
  
  // List<TokenSentiment> deserTokenSentiments(List<Map<String, dynamic>> jsonTs) {
  //   List<TokenSentiment> sentiments = List<TokenSentiment>.from(
  //     jsonTs.map((e) => TokenSentiment.fromJson(e))
  //   );
  //   return sentiments;
  // }

  ProcessedPost.fromJson(Map<String, dynamic> json)
      : at = DateTime.fromMicrosecondsSinceEpoch(json["at"]),
        text = json["text"],
        handle = json["handle"],
        displayName = json["displayName"],
        did = json["did"],
        rkey = json["rkey"],
        sentiment = json["sentiment"],
        // List.from here ensures the type is correctly inferred, and fails
        // early if the json is in a bad format.
        // Then we deserialize each element.
        tokenSentiments = List<TokenSentiment>.from(
            json["tokenSentiments"].map((e) => TokenSentiment.fromJson(e))
    );
  Map<String, dynamic> toJson() {
    return {
      "at": at.microsecondsSinceEpoch,
      "text": text,
      "handle": handle,
      "displayName": displayName,
      "did": did,
      "rkey": rkey,
      "sentiment": sentiment,
      "tokenSentiments": List<TokenSentiment>.from(tokenSentiments.map((ts) => ts.toJson()))
    };
  }

  @override
  int get hashCode =>
      Object.hashAll([at, text, handle, displayName, did, rkey, sentiment]);

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }

  String get atUri => "at://$did/app.bsky.feed.post/$rkey";

  /// "hydrate" the post with additional details by retrieving them through the Bluesky API.
  /// This function will automatically retry with increasing backoff.
  /// If [onHydrationCompleted] is provided via the constructor, it will be
  /// called when the widget finishes hydration, even if it took a few retries.
  ///
  /// The default [timeout] is 1 second. The default [retryTimeout] is 5 seconds,
  /// increasing by 5 seconds with each successive retry attempt. Note that this
  /// function also waits 3s between retry attempts.
  Future<void> hydrate(
      {Duration? timeout,
      Duration? retryTimeout,
      int retryCount = 0,
      int retryLimit = 2}) async {
    if (retryCount > retryLimit) {
      log("Too many post hydration retries");
      return;
    }

    bool retrying = retryCount > 0;

    // If we don't have a timeout, grab a default.
    // 500ms if this is the first attempt, since it can resolve pretty quickly
    //   under normal conditions.
    // Or start retrying with a 5 second timeout (maybe their service is struggling / rate limiting)
    // This retry timeout increases with each recursive retry call.
    Duration? retrievalTimeout = timeout ?? Duration(seconds: 1);
    Duration internalRetryTimeout = retryTimeout ?? Duration(seconds: 5);
    if (retrying) {
      // Use the retry timeout if we have one
      retrievalTimeout = internalRetryTimeout;
    }

    try {
      var ctx = Bluesky.anonymous(
          service: "public.api.bsky.app", timeout: retrievalTimeout);
      var response = await ctx.feed.getPosts(uris: [AtUri(atUri)]);
      fullPost = response.data.posts[0];
      onHydrationCompleted?.call();
    } on TimeoutException {
      // Schedule a retry 3s in the future, increasing the timeout interval.
      log("Bsky post retrieval timed out after ${retrievalTimeout.inMilliseconds}ms (retry $retryCount). Scheduling retry for 3s from now");
      unawaited(Future.delayed(Duration(seconds: 3), () {
        log("Retrying failed post retrieval");
        hydrate(
            retryCount: retryCount + 1,
            timeout: internalRetryTimeout + Duration(seconds: 5));
      }));
    }
  }
}
