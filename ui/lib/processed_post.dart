class ProcessedPost {
  DateTime at;
  String text;
  String? handle;
  String? displayName;
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
  Map<String, dynamic> toJson() {
    return {
      "at": at.microsecondsSinceEpoch,
      "text": text,
      "handle": handle,
      "displayName": displayName,
      "did": did,
      "rkey": rkey,
      "sentiment": sentiment
    };
  }

  @override
  int get hashCode =>
      Object.hashAll([at, text, handle, displayName, did, rkey, sentiment]);

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }
}
