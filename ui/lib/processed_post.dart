class ProcessedPost {
  DateTime at;
  String text;
  String handle;
  String did;
  String rkey;
  num sentiment;

  ProcessedPost(
      {required this.at,
      required this.text,
      required this.handle,
      required this.did,
      required this.rkey,
      required this.sentiment});

  ProcessedPost.fromJson(Map<String, dynamic> json)
      : at = DateTime.fromMicrosecondsSinceEpoch(json["at"]),
        text = json["text"],
        handle = json["handle"],
        did = json["did"],
        rkey = json["rkey"],
        sentiment = json["sentiment"];
}
