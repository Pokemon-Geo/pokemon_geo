import 'package:flutter/material.dart';
import 'package:pokemon_geo/pages/home.dart';
import 'package:pokemon_geo/pages/leaderboard.dart';
import 'package:pokemon_geo/pages/settings.dart';
import 'package:pokemon_geo/utils.dart';
import 'package:provider/provider.dart';

import 'api.dart';
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    Config.save();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<API>(
        create: (context) => API(),
        child: ValueListenableBuilder(
          valueListenable: darkNotifier,
          builder: (BuildContext context, bool value, Widget? child) =>
              MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Pokemon Geo',
                  theme: value ? ThemeData.dark() : ThemeData.light(),
                  initialRoute: Pages.Home,
                  routes: {
                Pages.Home: (context) => const HomePage(),
                Pages.Settings: (context) => const SettingsPage(),
                Pages.Leaderboard: (context) => const Leaderboard(),
              }),
        ));
  }
}
