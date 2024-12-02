import 'dart:collection';
import 'dart:convert';

import 'package:hatefeed/processed_post.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Feed {
  WebSocketChannel? channel;
  Feed();
  Queue queue = Queue();
  Function()? onQueueAdded;

  void connect(uri) async {
    if (channel != null) {
      throw Exception("Already connected to feed websocket");
    }

    channel = WebSocketChannel.connect(uri);

    await channel?.ready;
    channel!.sink.add("READY");


    var broadcast = channel!.stream.asBroadcastStream();

    String handshakeResponse = await broadcast.first;
    if (handshakeResponse != "OKAYLESGO") {
      throw Exception("Incorrect handshake from server");
    }

    broadcast.listen(
      (data) {
        var pp = ProcessedPost.fromJson(jsonDecode(data));
        queue.add(pp);
        onQueueAdded?.call();
      },
      onDone: () {
        channel = null;
      },
    );
  }

  void disconnect() {
    if (channel == null) {
      throw Exception("Already closed");
    }

    channel?.sink.close();
    channel = null;
  }
}
