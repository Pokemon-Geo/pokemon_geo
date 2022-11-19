import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api.dart';
import '../config.dart';
import '../utils.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({Key? key}) : super(key: key);

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Leaderboard"),
        ),
        body: FutureBuilder(
            future: Provider.of<API>(context, listen: false).fetchLeaderboard(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.hasData) {
                List<Color> colors =
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.primaries
                        : Colors.accents;
                List<User> users = snapshot.data;
                users.sort((a, b) => b.points.compareTo(a.points));
                return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colors[index % colors.length],
                            child: Text(
                              Utils.level(users[index].points).toString(),
                              style: TextStyle(
                                  color: ThemeData.estimateBrightnessForColor(
                                              colors[index % colors.length]) ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white),
                            ),
                          ),
                          title: Text(name(
                              index,
                              users[index].guid == Config.uuid,
                              users[index].name)),
                          trailing: Text(users[index].points.toString()),
                        ));
              } else if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }
              return const Center(child: CircularProgressIndicator());
            }));
  }

  String name(int index, bool myself, String name) {
    String result = "";
    if (index == 0) result += "👑 ";
    result += name;
    if (myself) result += " (You)";
    return result;
  }
}
