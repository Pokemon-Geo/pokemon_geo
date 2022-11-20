import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_tile_caching/fmtc_advanced.dart';
import 'package:flutter_rounded_progress_bar/flutter_rounded_progress_bar.dart';
import 'package:flutter_rounded_progress_bar/rounded_progress_bar_style.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pokemon_geo/pages/issue.dart';
import 'package:pokemon_geo/utils.dart';
import 'package:provider/provider.dart';

import '../api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double nearZoom = 17;

  /// in meter
  static const maxTimerDistance = 3599;
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;
  MapController map = MapController();

  static const urlTemplate =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  late FMTCTileProvider tileProvider;
  late Future<List<dynamic>> loaded;

  Timer? timer;
  int seconds = -1;
  late Issue current;

  @override
  void initState() {
    super.initState();
    loaded = Future.wait([permsAndGPS(), setupCache()]);
    _centerOnLocationUpdate = CenterOnLocationUpdate.always;
    _centerCurrentLocationStreamController = StreamController<double?>();
    final api = Provider.of<API>(context, listen: false);
    api.fetchScore();
    api.fetchIssues();
  }

  @override
  void dispose() {
    _centerCurrentLocationStreamController.close();
    super.dispose();
  }

  Marker createMarker(Issue issue) => Marker(
        point: issue.pos,
        width: 40,
        height: 40,
        builder: (_) => IconButton(
            onPressed: () {
              Geolocator.getCurrentPosition().then((pos) {
                if (Utils.distanceToIssue(issue, pos) <
                    Utils.acceptableDistance) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            IssuePage(issue, timer == null ? 1 : 2),
                      ));
                }
              });
            },
            icon: Icon(Icons.location_on,
                size: 40, color: timer == null ? Colors.black : Colors.red)),
        anchorPos: AnchorPos.align(AnchorAlign.top),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<API>(
      builder: (context, api, child) => Scaffold(
        appBar: AppBar(
            title: const Text('Fix all the issues'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Pages.Leaderboard);
                },
                icon: const Icon(Icons.leaderboard),
                tooltip: "Leaderboard",
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Pages.Settings);
                },
                icon: const Icon(Icons.settings),
                tooltip: "Settings",
              )
            ]),
        body: FutureBuilder(
          future: loaded,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return FlutterMap(
                mapController: map,
                options: MapOptions(
                  center: Utils.Munich,
                  zoom: 14,
                  maxZoom: 19,
                  keepAlive: true,
                  interactiveFlags:
                      InteractiveFlag.all ^ InteractiveFlag.rotate,
                  // Stop centering the location marker on the map if user interacted with the map.
                  onPositionChanged: (MapPosition position, bool hasGesture) {
                    if (hasGesture) {
                      setState(
                        () => _centerOnLocationUpdate =
                            CenterOnLocationUpdate.never,
                      );
                    }
                  },
                ),
                // ignore: sort_child_properties_last
                children: <Widget>[
                  TileLayer(
                    urlTemplate: urlTemplate,
                    subdomains: const ['a', 'b', 'c'],
                    maxZoom: 19,
                    tileProvider: tileProvider,
                    userAgentPackageName: 'dev.banana.pokemon_geo',
                    keepBuffer: 3,
                  ),
                  CurrentLocationLayer(
                    centerCurrentLocationStream:
                        _centerCurrentLocationStreamController.stream,
                    centerOnLocationUpdate: _centerOnLocationUpdate,
                  ),
                  MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                          maxClusterRadius: 45,
                          size: const Size(40, 40),
                          anchor: AnchorPos.align(AnchorAlign.center),
                          fitBoundsOptions: const FitBoundsOptions(
                            padding: EdgeInsets.all(50),
                            maxZoom: 15,
                          ),
                          markers: timer == null
                              ? api.issues.map(createMarker).toList()
                              : [createMarker(current)],
                          builder: (context, markers) => Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Theme.of(context).primaryColor),
                                child: Center(
                                  child: Text(markers.length.toString()),
                                ),
                              ))),
                ],
                nonRotatedChildren: [
                  Row(
                    children: [
                      SizedBox(
                        height: 40 + 2 * 8,
                        width: MediaQuery.of(context).size.width - 50,
                        child: RoundedProgressBar(
                            style: RoundedProgressBarStyle(
                                borderWidth: 0, widthShadow: 0),
                            height: 40,
                            margin: const EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(24),
                            percent: 100 * Utils.progress(api.totalXP)),
                      ),
                      CircleAvatar(
                          radius: 20,
                          child: Text(
                            "${Utils.level(api.totalXP)}",
                            style: const TextStyle(fontSize: 24),
                          ))
                    ],
                  ),
                  if (Utils.canSpeedrun(api.totalXP)) speedrun(context, api)
                ],
              );
            } else if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Automatically center the location marker on the map when location updated until user interact with the map.
            setState(
              () => _centerOnLocationUpdate = CenterOnLocationUpdate.always,
            );
            // Center the location marker on the map and zoom the map.
            _centerCurrentLocationStreamController.add(nearZoom);
          },
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }

  Align speedrun(BuildContext context, API api) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          child: timer == null
              ? IconButton(
                  tooltip: "Speedrun",
                  icon: const Icon(Icons.timer),
                  onPressed: () {
                    Geolocator.getCurrentPosition().then(
                      (pos) {
                        final m = <Issue, double>{};
                        double d = double.infinity;
                        for (var issue in api.issues) {
                          m[issue] = Utils.distanceToIssue(issue, pos);
                          if (m[issue]! > 500 && m[issue]! < d) {
                            current = issue;
                            d = m[issue]!;
                          }
                        }
                        // too far away, no issue found
                        if (d >= maxTimerDistance) return;
                        current.points *= 2;
                        seconds = d.floor();
                        timer = Timer.periodic(
                          const Duration(seconds: 1),
                          (Timer timer1) {
                            if (seconds == 0) {
                              stopTimer();
                            } else {
                              setState(() {
                                seconds--;
                              });
                            }
                          },
                        );
                      },
                    );
                  })
              : ElevatedButton(
                  onPressed: stopTimer,
                  child: Text(
                    Duration(seconds: seconds).toString().substring(2, 7),
                    style: const TextStyle(fontSize: 50, color: Colors.white),
                  ),
                ),
        ));
  }

  void stopTimer() {
    setState(() {
      timer?.cancel();
      timer = null;
      current.points = (current.points / 2).floor();
    });
  }

  Future<void> permsAndGPS() async {
    LocationPermission permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        break;
      case LocationPermission.denied:
        permission = await Geolocator.requestPermission();
        break;
      case LocationPermission.deniedForever:
      case LocationPermission.unableToDetermine:
        await Geolocator.openAppSettings();
        break;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }

    // fail because user
    permission = await Geolocator.checkPermission();
    if (!(permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) ||
        !await Geolocator.isLocationServiceEnabled()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("GPS required"),
          content: const Text(
              "Please enable location services and give the permission"),
          actions: [
            TextButton(
              onPressed: () {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              },
              child: const Text("Exit App"),
            ),
            TextButton(
              onPressed: () {
                permsAndGPS();
                Navigator.of(context).pop();
              },
              child: const Text("Retry"),
            )
          ],
        ),
      );
    }
  }

  Future<void> setupCache() async {
    var rootDirectory = await RootDirectory.normalCache;
    tileProvider = FlutterMapTileCaching.initialise(rootDirectory)["cache"]
        .getTileProvider();
  }
}
