import 'package:hatefeed/processed_post.dart';

Map<String, String> expandPostForAnalyticsParams(ProcessedPost p) {
  return p
      .toJson()
      .map((key, value) => MapEntry("post_$key", value.toString()));
}
