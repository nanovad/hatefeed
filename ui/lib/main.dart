import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hatefeed/feed.dart';
import 'package:hatefeed/processed_post.dart';

Feed f = Feed();

void main() {
  Uri feedWebsocketUri = Uri.parse(kDebugMode
      ? "ws://localhost:8080"
      : "ws://hatefeed.nanovad.com:80/feed_ws/");
  f.connect(feedWebsocketUri);
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

  void onThemeModeSelected(ThemeMode s) {
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
          title: 'Hatefeed', onThemeModeSelected: onThemeModeSelected),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeSelected;
  const MyHomePage({super.key, required this.title, this.onThemeModeSelected});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ProcessedPost> posts = List.empty(growable: true);
  num messagesSinceLastRefresh = 0.0;
  num messagesAverage = 0.0;
  late Timer messagesTimer;
  ThemeMode themeMode = ThemeMode.system;

  bool paused = false;

  _MyHomePageState() : super() {
    messagesTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        messagesAverage = messagesSinceLastRefresh / 10.0;
        messagesSinceLastRefresh = 0.0;
      });
    });
    f.onQueueAdded = postQueueHandler;
  }

  void postQueueHandler() {
    if (paused) {
      f.queue.clear();
    } else {
      while (f.queue.isNotEmpty) {
        setState(() {
          posts.insert(0, f.queue.removeFirst());
          while (posts.length > 100) {
            // TODO: Make this more efficient
            posts.removeLast();
          }
          messagesSinceLastRefresh += 1.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [
            Row(children: [
              const Padding(
                  padding: EdgeInsets.only(right: 6.0),
                  child: Text(
                    "Pause",
                    style: TextStyle(
                        fontWeight: FontWeight.normal, fontSize: 18.0),
                  )),
              Switch(
                  value: paused,
                  onChanged: (newState) => setState(() {
                        paused = newState;
                      }))
            ]),
            Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: SegmentedButton(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: Icon(Icons.app_settings_alt)),
                    ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                    ButtonSegment<ThemeMode>(
                        value: ThemeMode.light, icon: Icon(Icons.light_mode))
                  ],
                  selected: <ThemeMode>{themeMode},
                  onSelectionChanged: (Set<ThemeMode> s) {
                    setState(() {
                      themeMode = s.first;
                      widget.onThemeModeSelected?.call(themeMode);
                    });
                  },
                ))
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceDim,
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "msg/s: ${messagesAverage.toStringAsFixed(1)}",
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
          Expanded(
              child: Center(
                  child: ConstrainedBox(
            constraints: BoxConstraints.loose(const Size.fromWidth(750.0)),
            child: ListView(
              reverse: true,
              children: buildTiles(context),
            ),
          )))
        ]));
  }

  List<Widget> buildTiles(BuildContext context) {
    return posts
        .map((element) => Card(
            color: Theme.of(context).colorScheme.surface,
            elevation: 2.0,
            child: ListTile(
              title: Text(element.handle),
              subtitle: Text(element.text),
              trailing: buildSentimentScore(context, element.sentiment),
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: element.sentiment < -0.75
                          ? Colors.red
                          : Colors.transparent),
                  borderRadius: const BorderRadius.all(Radius.circular(5.0))),
            )))
        .toList();
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
