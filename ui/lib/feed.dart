import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:hatefeed/processed_post.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum FeedState { connected, connecting, disconnected, reconnecting, initial }

class Feed {
  WebSocketChannel? channel;
  Feed();
  Queue queue = Queue();
  Function()? onQueueAdded;
  Function()? onDone;
  Function(Object error)? onError;

  Future<void> connect(uri) async {
    try {
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

      broadcast.listen((data) {
        var pp = ProcessedPost.fromJson(jsonDecode(data));
        queue.add(pp);
        onQueueAdded?.call();
      }, onDone: () {
        channel = null;
        onDone?.call();
      }, onError: (e) {
        channel = null;
        onError?.call(e);
      });
    }
    catch (any) {
      channel = null;
      rethrow;
    }
  }

  void disconnect() {
    if (channel == null) {
      throw Exception("Already closed");
    }

    channel?.sink.close();
    channel = null;
  }
}

class FeedController {
  Feed feed = Feed();
  FeedState _state = FeedState.initial;
  Uri uri;
  Duration timeout;

  set state(value) {
    if (_state != value) {
      _state = value;
      onStateChanged();
    }
  }

  get state => _state;

  Function()? onConnected;
  Function()? onConnecting;
  Function()? onDisconnected;

  FeedController({required this.uri, required this.timeout}) {
    feed.onDone = _feedOnDone;
    feed.onError = _feedOnError;
  }

  void _feedOnDone() {
    connectWithRetry();
  }

  void _feedOnError(Object error) {
    connectWithRetry();
  }

  Future<bool> connect(Uri uri) async {
    state = FeedState.connecting;
    try {
      await feed.connect(uri);
    } catch (x) {
      log("$x");
      state = FeedState.disconnected;
      return false;
    }

    state = FeedState.connected;
    return true;
  }

  Future<bool> connectWithRetry(
      {Duration step = const Duration(seconds: 2)}) async {
    // Reconnect with an exponential backoff, increasing the retry interval by
    // `step` every time an attempt fails.
    Duration delay = step;
    Duration waited = delay;

    while (!await connect(uri)) {
      log("Reconnect attempt... waiting $delay");
      await Future.delayed(delay);

      // Increase the next attempt's delay.
      delay += step;
      // Count the total amount of time we will have waited after the next
      // attempt.
      waited += delay;
      // If we exceed the timeout, the attempt has failed.
      if (waited > timeout) {
        return false;
      }
    }

    return true;
  }

  void onStateChanged() {
    if (_state == FeedState.connecting) {
      onConnecting?.call();
    } else if (_state == FeedState.connected) {
      onConnected?.call();
    } else if (_state == FeedState.disconnected) {
      onDisconnected?.call();
    }
  }
}
