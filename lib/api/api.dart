import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:pokemon_geo/config.dart';

class Issues {
  int id;
  String name;
  LatLng pos;

  Issues(this.id, this.name, this.pos);

  factory Issues.fromJson(Map<String, dynamic> data) {
    return Issues(
      data['id'],
      data['name'],
      LatLng.fromJson(data['pos']),
    );
  }
}

class API extends ChangeNotifier {
  static const String serverUrl =
      "https://5d0e-79-98-43-133.eu.ngrok.io/polls/api/v1";
  Map<String, String> headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
  };
  final Client _client = Client();
  List<Issues> issues = [];

  Future<String> _request(String url, Future<Response> Function() call) async {
    Response response;
    try {
      response = await call();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
    } catch (e) {
      throw Exception('Unable to fetch $url from the REST API: $e');
    }
    throw Exception(
        'Bad API response ${response.statusCode}: ${response.body}');
  }

  Future<String> _get(String url) async => _request(
      url,
      () => _client.get(Uri.https(serverUrl, "$url/${Config.uuid}/"),
          headers: headers));

  Future<String> _post(String url, Map<String, dynamic> data) async => _request(
      url,
      () => _client.post(Uri.https(serverUrl, url),
          body: jsonEncode(data), headers: headers));

  void fetchIssues() {
    _get("issues");
  }

  void postPhoto() {
    _post("upload", {});
  }
}
