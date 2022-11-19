import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:pokemon_geo/config.dart';
import 'package:pokemon_geo/utils.dart';

class Issue {
  int issueId;
  int imageId;
  int points;
  LatLng pos;

  Issue(this.issueId, this.imageId, this.points, this.pos);

  factory Issue.fromJson(Map<String, dynamic> data) {
    return Issue(
      data['osm_way_id'],
      data['image_id'],
      data['points'],
      LatLng(double.parse(data['lng']), double.parse(data['lat'])),
    );
  }
}

class User {
  int id;
  String name;

  User(this.id, this.name, this.points);

  int points;

  factory User.fromJson(Map<String, dynamic> data) =>
      User(data["guid"], data["name"], data["points"]);
}

class API extends ChangeNotifier {
  static const String serverUrl = "de31-79-98-43-133.eu.ngrok.io";
  static const String api = "api/v1";
  Map<String, String> headers = {
    HttpHeaders.contentTypeHeader: 'application/json'
  };
  final Client _client = Client();
  int totalXP = 0;

  int get level => Utils.level(totalXP);
  List<Issue> issues = [];
  List<User> users = [];

  Future<String> _get(String url) => _getParams(url, null);

  Future<String> _getParams(String url, Map<String, dynamic>? query) async {
    Response response;
    var finalURL = Uri.https(serverUrl, "$api/$url");
    if (kDebugMode) {
      print(finalURL);
    }
    try {
      response = await _client.get(finalURL, headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
    } catch (e) {
      throw Exception('Unable to fetch "$finalURL" from the REST API: $e');
    }
    throw Exception(
        'Bad API response ${response.statusCode} on "$finalURL": ${response.body}');
  }

  Future<void> fetchIssues() async {
    final parsed =
        json.decode(await _get("issues"))["data"].cast<Map<String, dynamic>>();
    issues = parsed.map<Issue>((json) => Issue.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> fetchScore() async {
    final user = await _get("user/${Config.uuid}");
    totalXP = jsonDecode(user)["data"]["points"];
    notifyListeners();
  }

  Future<void> fetchLeaderboard() async {
    final parsed = json
        .decode(await _get("leaderboard"))["data"]
        .cast<Map<String, dynamic>>();
    users = parsed.map<User>((json) => User.fromJson(json)).toList();
    notifyListeners();
  }

  Future<void> vote(int issueId, bool primary) async {
    await _getParams("voting/${Config.uuid}/$issueId",
        {"category": (primary ? "primary" : "footway")});
  }

  Future<String> getImageUrl(int imageId) async {
    final a = await _client.get(
        Uri.https(
            "graph.mapillary.com", "$imageId", {"fields": "thumb_1024_url"}),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              "OAuth MLY|6267347309961156|ec0c7ce7dee135a998e9c786c224caf1"
        });
    return jsonDecode(a.body)["thumb_1024_url"];
  }

  Future<void> postPhoto(int issueId, XFile file) async {
    final image = await file.readAsBytes();
    var request = MultipartRequest(
        "POST", Uri.https(serverUrl, "$api/photo/${Config.uuid}/$issueId"))
      ..headers.addAll(headers)
      ..files.add(MultipartFile.fromBytes("file", image));
    await _client.send(request);
  }
}
