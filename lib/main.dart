import 'package:flutter/material.dart';
import 'package:pokemon_geo/pages/home.dart';
import 'package:pokemon_geo/pages/settings.dart';
import 'package:pokemon_geo/utils.dart';

import 'config.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> with WidgetsBindingObserver {
  static final ValueNotifier<bool> darkNotifier =
      ValueNotifier(Config.darkMode);

  @override
  void initState() {
    super.initState();
    Config.load();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: darkNotifier,
      builder: (BuildContext context, bool value, Widget? child) => MaterialApp(
          title: 'Mister X',
          theme: value ? ThemeData.dark() : ThemeData.light(),
          initialRoute: Pages.Home,
          routes: {
            Pages.Home: (context) => const HomePage(),
            Pages.Settings: (context) => const SettingsPage(),
          }),
    );
  }
}
