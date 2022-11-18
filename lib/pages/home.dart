import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_tile_caching/fmtc_advanced.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pokemon_geo/utils.dart';
import 'package:provider/provider.dart';

import '../api/api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double nearZoom = 17;
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;
  MapController map = MapController();

  static const urlTemplate =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  late FMTCTileProvider tileProvider;
  late Future<List<dynamic>> loaded;

  late final Timer refresh;

  @override
  void initState() {
    super.initState();
    loaded = Future.wait([permsAndGPS(), setupCache()]);
    _centerOnLocationUpdate = CenterOnLocationUpdate.always;
    _centerCurrentLocationStreamController = StreamController<double?>();
    /*refresh = Timer.periodic(const Duration(seconds: 10), (timer) {
      Provider.of<API>(context, listen: false).updatePlayers();
      Geolocator.getCurrentPosition().then((pos) =>
          Provider.of<API>(context, listen: false).sendLocalPlayerPos(pos));
    });*/
  }

  @override
  void dispose() {
    _centerCurrentLocationStreamController.close();
    refresh.cancel();
    super.dispose();
  }

  Marker createMarker(Issues issue) => Marker(
        point: issue.pos,
        width: 40,
        height: 40,
        builder: (_) => IconButton(
            onPressed: () => print("hi"),
            icon: const Icon(Icons.location_on, size: 40, color: Colors.black)),
        anchorPos: AnchorPos.align(AnchorAlign.top),
      );

  @override
  Widget build(BuildContext context) {
    return Consumer<API>(
      builder: (context, api, child) => Scaffold(
        appBar: AppBar(
            title: const Text('Fix them issues'),
            automaticallyImplyLeading: false,
            actions: [
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
                  zoom: 6,
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
                  MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                          maxClusterRadius: 45,
                          size: const Size(40, 40),
                          anchor: AnchorPos.align(AnchorAlign.center),
                          fitBoundsOptions: const FitBoundsOptions(
                            padding: EdgeInsets.all(50),
                            maxZoom: 15,
                          ),
                          markers: api.issues.map(createMarker).toList(),
                          builder: (context, markers) => Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.blue),
                                child: Center(
                                  child: Text(
                                    markers.length.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ))),
                  CurrentLocationLayer(
                    centerCurrentLocationStream:
                        _centerCurrentLocationStreamController.stream,
                    centerOnLocationUpdate: _centerOnLocationUpdate,
                  ),
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
          builder: (context) => Column(
                children: [
                  const Text("Please enable GPS and give permission"),
                  TextButton(
                    onPressed: () {
                      permsAndGPS();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Retry"),
                  )
                ],
              ));
    }
  }

  Future<void> setupCache() async {
    var rootDirectory = await RootDirectory.normalCache;
    tileProvider = FlutterMapTileCaching.initialise(rootDirectory)["cache"]
        .getTileProvider();
  }
}
