import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatefeed/about_screen.dart';

import 'package:hatefeed/feed.dart';
import 'package:hatefeed/processed_post.dart';
import 'package:hatefeed/widget_connection_state.dart';
import 'package:hatefeed/widget_post_card.dart';
import 'package:hatefeed/widget_theme_switcher.dart';
import 'package:url_launcher/url_launcher.dart';

late FeedController fc;
var f = fc.feed;

void main() {
  Uri feedWebsocketUri = Uri.parse(kDebugMode
      ? "ws://localhost:8080"
      : "wss://hatefeed.nanovad.com/feed_ws/");
  fc = FeedController(
      uri: feedWebsocketUri, timeout: const Duration(seconds: 120));
  fc.connectWithRetry();
  // fc.connectWithRetry(feedWebsocketUri, const Duration(seconds: 60));
  // f.connect(feedWebsocketUri);
  f.onQueueAdded = () {
    log("Queue message added: ${f.queue.removeFirst()}");
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;

  void onThemeModeChanged(ThemeMode s) {
    setState(() {
      themeMode = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hatefeed',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: themeMode,
      home: MyHomePage(
          title: 'Hatefeed',
          defaultThemeMode: themeMode,
          onThemeModeChanged: onThemeModeChanged),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final ThemeMode defaultThemeMode;
  final Function(ThemeMode)? onThemeModeChanged;
  const MyHomePage(
      {super.key,
      required this.title,
      required this.defaultThemeMode,
      this.onThemeModeChanged});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ProcessedPost> posts = List.empty(growable: true);
  num messagesSinceLastRefresh = 0.0;
  num messagesAverage = 0.0;
  late Timer messagesTimer;

  bool paused = false;

  _MyHomePageState() : super() {
    messagesTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        messagesAverage = messagesSinceLastRefresh / 10.0;
        messagesSinceLastRefresh = 0.0;
      });
    });
    f.onQueueAdded = postQueueHandler;
    fc.onConnected = () {
      setState(() {});
    };
    fc.onConnecting = () {
      setState(() {});
    };
    fc.onDisconnected = () {
      setState(() {});
    };
  }

  void postQueueHandler() {
    if (paused) {
      f.queue.clear();
    } else {
      setState(() {
        // Spread the new posts in queue and combine them with the existing
        // posts list
        posts = [...f.queue, ...posts];
        // Clear the queue (all items are now in posts)
        f.queue.clear();
        // Trim the posts list to 100 items max
        if (posts.length > 100) {
          posts.removeRange(100, posts.length);
        }
        messagesSinceLastRefresh += 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: ThemeSwitcher(
                    defaultThemeMode: widget.defaultThemeMode,
                    onThemeModeChanged: widget.onThemeModeChanged)),
            PopupMenuButton(
                itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text("About"),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => const AboutScreen()));
                        },
                      )
                    ])
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          padding: const EdgeInsets.all(4.0),
          height: 48.0,
          child: Row(
            children: [
              buildGitHubIconWidget(),
              Expanded(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConnectionStateIndicator(state: fc.state),
                  buildMessageRateWidget(),
                ],
              )),
              buildPauseToggle()
            ],
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        body: Column(children: [
          Expanded(
              child: Center(
                  child: ConstrainedBox(
            constraints: BoxConstraints.loose(const Size.fromWidth(750.0)),
            child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                itemCount: posts.length,
                itemBuilder: (context, i) =>
                    buildPostTile(context, posts[i])),
          )))
        ]));
  }

  Widget buildPostTile(BuildContext context, ProcessedPost p) {
    return PostCard(
      backgroundColor: Theme.of(context).colorScheme.surface,
      handle: p.handle,
      body: p.text,
      extreme: p.sentiment < -0.9,
      sentiment: p.sentiment,
      onCopyPressed: () {
        Clipboard.setData(ClipboardData(text: "${p.handle}\n${p.text}"));
        // Make sure we are mounted in the Widget tree; if we are not, we can't
        // show a toast.
        if(mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
              content: Text("Copied post to clipboard"),
              duration: Duration(milliseconds: 1500)));
        }
      },
      onSharePressed: () async {
        Clipboard.setData(ClipboardData(text: createPostLink(p)));
        if(mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
              content: Text("Copied link to post to clipboard"),
              duration: Duration(milliseconds: 1500)));
        }
      },
      onOpenInBrowserPressed: () async {
        await launchUrl(Uri.parse(createPostLink(p)));
        if(mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
              content: Text("Opened post in browser"),
              duration: Duration(milliseconds: 1500)));
        }
      },
    );
  }

  Widget buildGitHubIconWidget() {
    return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
            onPressed: () {
              launchUrl(Uri.parse("https://github.com/nanovad/hatefeed"));
            },
            icon: const ImageIcon(AssetImage("images/github-mark.png"))));
  }

  Widget buildMessageRateWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Text(
        textAlign: TextAlign.center,
        "msg/s: ${messagesAverage.toStringAsFixed(1)}",
        style: const TextStyle(fontSize: 16.0),
      ),
    );
  }

  Widget buildPauseToggle() {
    return Row(children: [
      const Padding(
          padding: EdgeInsets.only(right: 6.0),
          child: Text(
            "Pause",
            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18.0),
          )),
      Switch(
          value: paused,
          onChanged: (newState) => setState(() {
                paused = newState;
              }))
    ]);
  }

  String createPostLink(ProcessedPost p) {
    return "https://bsky.app/profile/${p.did}/post/${p.rkey}";
  }

  Color sentimentColor(num sentiment) {
    num lerpPoint = -sentiment;
    if (lerpPoint < 0.0) {
      lerpPoint = 0.0;
    }

    return Color.lerp(Colors.black, Colors.red, lerpPoint.toDouble())!;
  }

  Text buildSentimentScore(BuildContext context, num sentiment) {
    Color color = sentimentColor(sentiment);
    bool bold = sentiment < -0.75;
    return Text(sentiment.toStringAsFixed(2),
        style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal));
  }
}
