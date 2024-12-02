class ProcessedPost {
  DateTime at;
  String text;
  String handle;
  num sentiment;

  ProcessedPost(
      {required this.at,
      required this.text,
      required this.handle,
      required this.sentiment});

  ProcessedPost.fromJson(Map<String, dynamic> json)
      : at = DateTime.fromMicrosecondsSinceEpoch(json["at"]),
        text = json["text"],
        handle = json["handle"],
        sentiment = json["sentiment"];
}
