class ProcessedPost {
  DateTime at;
  String text;
  String handle;
  String displayName;
  String did;
  String rkey;
  double sentiment;

  ProcessedPost(
      {required this.at,
      required this.text,
      required this.handle,
      required this.displayName,
      required this.did,
      required this.rkey,
      required this.sentiment});

  ProcessedPost.fromJson(Map<String, dynamic> json)
      : at = DateTime.fromMicrosecondsSinceEpoch(json["at"]),
        text = json["text"],
        handle = json["handle"],
        displayName = json["displayName"],
        did = json["did"],
        rkey = json["rkey"],
        sentiment = json["sentiment"];
}
