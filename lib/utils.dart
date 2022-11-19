import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'api.dart';

class Pages {
  static const String Home = 'home';
  static const String Settings = 'settings';
  static const String Leaderboard = 'leaderboard';
}

class Utils {
  static LatLng Munich = LatLng(48.126154762110744, 11.579897939780327);
  static const Distance distance = Distance();
  static const int votingLevel = 10,
      speedrunLevel = 5,
      difficulty = 50,
      xpPerIssue = 100;
  static const int acceptableDistance = 100000;

  static Text distanceText(LatLng a, LatLng b) {
    var km = distance.as(LengthUnit.Kilometer, a, b);
    return Text(km > 1 ? "${km}km" : "${distance.as(LengthUnit.Meter, a, b)}m");
  }

  static double distanceToIssue(Issue issue, Position pos) {
    return distance.distance(issue.pos, LatLng(pos.latitude, pos.longitude));
  }

  static bool canSpeedrun(int totalXP) {
    return level(totalXP) >= speedrunLevel;
  }

  static bool canVote(int totalXP) {
    return level(totalXP) >= votingLevel;
  }

  static int level(int totalXP) {
    final solved = totalXP / xpPerIssue;
    final exponent = log(votingLevel) / log(difficulty);
    return pow(solved, exponent).floor();
  }

  static int xpForLevel(int level) {
    final exponent = log(difficulty) / log(votingLevel);
    return (pow(level, exponent) * xpPerIssue).floor();
  }

  static int xpForNextLevel(int totalXP) {
    final l = level(totalXP);
    return totalXP - xpForLevel(l);
  }

  static double progress(int totalXP) {
    final l = level(totalXP);
    final currentLevel = xpForLevel(l);
    final nextLevel = xpForLevel(l + 1);
    return (totalXP - currentLevel) / (nextLevel - currentLevel);
  }
}
