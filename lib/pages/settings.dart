import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../config.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController(text: Config.uuid);
    textEditingController.addListener(() {
      if (textEditingController.text.isNotEmpty) {
        Config.uuid = textEditingController.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final api = Provider.of<API>(context, listen: false);
        api.fetchScore();
        api.fetchIssues();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Einstellungen'),
        ),
        body: ListView(children: [
          _title("General"),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: Config.darkMode,
            onChanged: (value) => setState(
                () => Config.darkMode = AppState.darkNotifier.value = value),
          ),
          ListTile(
            title: const Text("UUID"),
            subtitle: TextField(
              controller: textEditingController,
            ),
          ),
          _title("Legal"),
          const ListTile(title: Text("Map and Icon ¬©OpenStreetMap")),
          FutureBuilder(
            future: PackageInfo.fromPlatform(),
            builder: (context, data) {
              if (data.hasData) {
                return AboutListTile(
                  applicationName: data.requireData.appName,
                  applicationVersion:
                      "${data.requireData.version}-build${data.requireData.buildNumber}",
                  applicationIcon: Image.asset(
                    "assets/icon.png",
                    width: 80,
                  ),
                  applicationLegalese: "¬©2022 Banana",
                );
              }
              return const ListTile(
                title: Text("Loading..."),
              );
            },
          )
        ]),
      ),
    );
  }

  ListTile _title(String text) {
    return ListTile(
        title: Text(
      text,
      style: TextStyle(color: Theme.of(context).indicatorColor),
    ));
  }
}
