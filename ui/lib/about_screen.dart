import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  static const String githubLink = "https://github.com/nanovad/hatefeed";

  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Hatefeed"),
      ),
      body: ListView(
        children: [
          // Version / build number
          FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder:
                  (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                if (snapshot.hasData) {
                  String? pi = snapshot.data?.version ?? "failed to retrieve";
                  String? bn = snapshot.data?.buildNumber ?? "";
                  return ListTile(
                    title: const Text("Version"),
                    subtitle: Text("$pi+$bn"),
                  );
                }
                return const CircularProgressIndicator();
              }),
          // GitHub link
          ListTile(
              title: const Text("Source code"),
              subtitle: InkWell(
                  onTap: () {
                    launchUrl(Uri.parse(githubLink));
                  },
                  child: const Text(githubLink))),
        ],
      ),
    );
  }
}
