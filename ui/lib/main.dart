import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatefeed/about_screen.dart';
import 'package:hatefeed/analytics_helpers.dart';

import 'package:hatefeed/feed.dart';
import 'package:hatefeed/firebase_options.dart';
import 'package:hatefeed/processed_post.dart';
import 'package:hatefeed/widget_connection_state.dart';
import 'package:hatefeed/widget_feed_mode_switcher.dart';
import 'package:hatefeed/widget_post_card.dart';
import 'package:hatefeed/widget_settings_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firebase_analytics/firebase_analytics.dart';

Uri feedWebsocketUri = Uri.parse(
    kDebugMode ? "ws://localhost:8080" : "wss://hatefeed.nanovad.com/feed_ws/");
var fc = FeedController(
    uri: feedWebsocketUri,
    timeout: const Duration(seconds: 120),
    mode: FeedMode.interval,
    intervalMs: 3000,
    threshold: -0.75);
var f = fc.feed;

void main() async {
  // Activate Firebase, but only collect analytics in prod
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kReleaseMode) {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    await FirebaseAnalytics.instance.logAppOpen();
  } else {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
  }
  Timer.periodic(Duration(seconds: 30), (timer) async {
    await FirebaseAnalytics.instance.logEvent(name: "app_active");
  });

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
  Future<SharedPreferences> futurePrefs = SharedPreferences.getInstance();
  SharedPreferences? prefs;

  void onThemeModeChanged(ThemeMode s) {
    setState(() {
      themeMode = s;
    });
    prefs?.setString("theme_mode", s.name);
  }

  _MyAppState() {
    futurePrefs.then((v) {
      prefs = v;
      String? prefThemeMode = prefs?.getString("theme_mode");
      if(prefThemeMode != null) {
        try {
          // Load the theme from shared preferences.
          onThemeModeChanged(ThemeMode.values.byName(prefThemeMode));
        }
        on ArgumentError {
          // If the key was incorrect (maybe the enum got updated?)
          onThemeModeChanged(ThemeMode.system);
        }
      }
      else {
        // First run or a cache clear, probably. Set to default.
        onThemeModeChanged(ThemeMode.system);
      }

      int? intervalMs = prefs?.getInt("feed_interval");
      fc.intervalMs = intervalMs ?? fc.intervalMs;

      double? threshold = prefs?.getDouble("feed_threshold");
      fc.threshold = threshold ?? fc.threshold;

      int? feedModeSer = prefs?.getInt("feed_mode");
      // In the event that the preference is missing (or invalid,
      // i.e. n > FeedMode enum length), it will fall back to the currently set
      // FeedMode, which is probably the hard-coded default from the
      // FeedController initializer.
      FeedMode? prefsMode = FeedMode.values.elementAtOrNull(feedModeSer ?? fc.mode.index);
      fc.mode = prefsMode ?? fc.mode;

      fc.connectWithRetry();
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
          title: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.title)),
          actions: [
            Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (context) => SettingsModal(
                              feedController: fc,
                              defaultThemeMode: widget.defaultThemeMode,
                              onThemeModeChanged: widget.onThemeModeChanged));
                      FirebaseAnalytics.instance
                          .logEvent(name: "settings_modal_launched");
                    },
                    icon: const Icon(Icons.tune_outlined))),
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
                itemBuilder: (context, i) => buildPostTile(context, posts[i])),
          )))
        ]));
  }

  Widget buildPostTile(BuildContext context, ProcessedPost p) {
    return PostCard(
      backgroundColor: Theme.of(context).colorScheme.surface,
      handle: p.handle ?? "",
      displayName: p.displayName ?? "",
      body: p.text,
      extreme: p.sentiment < -0.9,
      sentiment: p.sentiment,
      onCopyPressed: () {
        Clipboard.setData(ClipboardData(text: "${p.handle}\n${p.text}"));
        // Make sure we are mounted in the Widget tree; if we are not, we can't
        // show a toast.
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
              content: Text("Copied post to clipboard"),
              duration: Duration(milliseconds: 1500)));
        }
        FirebaseAnalytics.instance.logEvent(
            name: "post_copy_pressed",
            parameters: expandPostForAnalyticsParams(p));
      },
      onSharePressed: () async {
        Clipboard.setData(ClipboardData(text: createPostLink(p)));
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
              content: Text("Copied link to post to clipboard"),
              duration: Duration(milliseconds: 1500)));
        }
        FirebaseAnalytics.instance.logEvent(
            name: "post_share_pressed",
            parameters: expandPostForAnalyticsParams(p));
      },
      onOpenInBrowserPressed: () async {
        await launchUrl(Uri.parse(createPostLink(p)));
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
              content: Text("Opened post in browser"),
              duration: Duration(milliseconds: 1500)));
        }
        FirebaseAnalytics.instance.logEvent(
            name: "post_open_in_browser_pressed",
            parameters: expandPostForAnalyticsParams(p));
      },
      onOpenProfileInBrowserPressed: () async {
        await launchUrl(Uri.parse(createProfileLink(p)));
        if (mounted) {
          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
              content: Text("Opened profile in browser"),
              duration: Duration(milliseconds: 1500)));
        }
        FirebaseAnalytics.instance.logEvent(
            name: "post_open_profile_in_browser_pressed",
            parameters: expandPostForAnalyticsParams(p));
      },
    );
  }

  Widget buildGitHubIconWidget() {
    return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
            onPressed: () {
              launchUrl(Uri.parse("https://github.com/nanovad/hatefeed"));
              FirebaseAnalytics.instance.logEvent(name: "github_link_clicked");
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
                if (paused) {
                  FirebaseAnalytics.instance.logEvent(name: "feed_paused");
                } else {
                  FirebaseAnalytics.instance.logEvent(name: "feed_unpaused");
                }
              }))
    ]);
  }

  String createPostLink(ProcessedPost p) =>
      "https://bsky.app/profile/${p.did}/post/${p.rkey}";
  String createProfileLink(ProcessedPost p) =>
      "https://bsky.app/profile/${p.did}";

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
