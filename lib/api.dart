import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:pokemon_geo/config.dart';

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

class API extends ChangeNotifier {
  static const String serverUrl = "de31-79-98-43-133.eu.ngrok.io";
  static const String api = "api/v1";
  Map<String, String> headers = {
    HttpHeaders.contentTypeHeader: 'application/json'
  };
  final Client _client = Client();
  List<Issue> issues = [];
  int totalXP = 100;

  Future<String> _get(String url) async {
    Response response;
    var finalURL = Uri.https(serverUrl, "$api/$url");
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
    final user = await _get("${Config.uuid}/user");
    totalXP = jsonDecode(user)["data"]["points"];
    notifyListeners();
  }

  Future<bool> postPhoto(int issueId, XFile file) async {
    final image = await file.readAsBytes();
    var request = MultipartRequest(
        "POST", Uri.https(serverUrl, "$api/${Config.uuid}/photo/$issueId"))
      ..headers.addAll(headers)
      ..fields.addAll({"file": base64Encode(image)});
    var response = await _client.send(request);
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}
