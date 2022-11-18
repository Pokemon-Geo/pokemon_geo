import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Pages {
  static const String Home = 'home';
  static const String Settings = 'settings';
}

class Utils {
  static LatLng Munich = LatLng(48.126154762110744, 11.579897939780327);
  static const Distance distance = Distance();

  static Text distanceText(LatLng a, LatLng b) {
    var km = distance.as(LengthUnit.Kilometer, a, b);
    return Text(km > 1 ? "${km}km" : "${distance.as(LengthUnit.Meter, a, b)}m");
  }
}
