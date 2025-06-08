import 'dart:collection';
import 'dart:convert';
import 'dart:developer';

import 'package:hatefeed/processed_post.dart';
import 'package:hatefeed/widget_feed_mode_switcher.dart';
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
        try {
          var pp = ProcessedPost.fromJson(jsonDecode(data));
          queue.add(pp);
          onQueueAdded?.call();
        }
        catch(_) {
          log("Failed to decode an incoming post, skipping");
        }
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
  bool _reconnecting = false;

  int intervalMs;
  double threshold;
  FeedMode mode;

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

  FeedController(
      {required this.uri,
      required this.timeout,
      required this.intervalMs,
      required this.threshold,
      required this.mode}) {
    feed.onDone = _feedOnDone;
    feed.onError = _feedOnError;
  }

  void _feedOnDone() {
    if(!_reconnecting) {
      connectWithRetry();
    }
  }

  void _feedOnError(Object error) {
    if(!_reconnecting) {
      connectWithRetry();
    }
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

    // Make sure the server and client mode/interval/threshold parameters are
    // in sync, in case we've reconnecting.
    setMode(mode);
    setInterval(intervalMs);
    setThreshold(threshold);
    return true;
  }

  Future<bool> connectWithRetry(
      {Duration step = const Duration(seconds: 2)}) async {
    _reconnecting = true;
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
        _reconnecting = false;
        return false;
      }
    }

    _reconnecting = false;
    return true;
  }

  void setInterval(int intervalMs) {
    feed.channel?.sink.add("INTERVAL $intervalMs");
    this.intervalMs = intervalMs;
  }

  void setThreshold(double threshold) {
    feed.channel?.sink.add("THRESHOLD $threshold");
    this.threshold = threshold;
  }

  void setMode(FeedMode mode) {
    var sink = feed.channel?.sink;
    if(mode == FeedMode.interval) {
      sink?.add("MODE RATE");
    }
    else if(mode == FeedMode.threshold) {
      sink?.add("MODE THRESHOLD");
    }
    this.mode = mode;
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
