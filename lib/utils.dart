import 'dart:math';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Pages {
  static const String Home = 'home';
  static const String Settings = 'settings';
}

class Utils {
  static LatLng Munich = LatLng(48.126154762110744, 11.579897939780327);
  static const Distance distance = Distance();
  static const int labelingLevel = 10, difficulty = 50, xpPerIssue = 100;

  static Text distanceText(LatLng a, LatLng b) {
    var km = distance.as(LengthUnit.Kilometer, a, b);
    return Text(km > 1 ? "${km}km" : "${distance.as(LengthUnit.Meter, a, b)}m");
  }

  static int level(int totalXP) {
    final solved = totalXP / xpPerIssue;
    final exponent = log(labelingLevel) / log(difficulty);
    return pow(solved, exponent).floor();
  }

  static int xpForLevel(int level) {
    final exponent = log(difficulty) / log(labelingLevel);
    return (pow(level, exponent) * xpPerIssue).floor();
  }

  static double progress(int totalXP) {
    final l = level(totalXP);
    final currentLevel = xpForLevel(l);
    final nextLevel = xpForLevel(l + 1);
    return (totalXP - currentLevel) / (nextLevel - currentLevel);
  }
}