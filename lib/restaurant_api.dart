import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

import 'haversine.dart';

const String URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?";
const double METERS_PER_MILE = 1609.34;

///data class to hold the relevant data of a single Google Places response
class Restaurant {
  String name;
  double lat;
  double long;
  double distance;

  Restaurant({@required this.name, @required this.lat, @required this.long, this.distance: 0.0});
}

Future<List<Restaurant>> getRestaurants(double distance) async {
  Map<String, double> location;
  location = await Location().getLocation();
  final lat = location['latitude'];
  final long = location['longitude'];

  final restaurants = <Restaurant>[];
  String pageToken;
  do {
    //To use real data (ensure key.json contains your API key)
    final url = await _createUrl(lat, long, distance, pageToken);
    final response = await http.get(Uri.parse(url));
    print(response.body);
    final decodedJson = jsonDecode(response.body);

    //To use the example data and simulate a delay for the animation
//      final decodedJson = jsonDecode(EXAMPLE);
//    await Future.delayed(const Duration(
//        seconds: 3));

    restaurants.addAll(_getRestaurantsFromJson(decodedJson));
    pageToken = decodedJson['next_page_token'];
    if (pageToken != null) {
      await Future.delayed(const Duration(
          seconds: 2)); //There is a slight delay between PlacesSdk 'next page' responses, 2 seconds should be safe
    }
  } while (pageToken != null);

  restaurants.forEach((restaurant) {
    restaurant.distance =
        Haversine.getDistanceBetween(lat1: lat, long1: long, lat2: restaurant.lat, long2: restaurant.long);
  });
  return restaurants;
}

Future<String> _createUrl(double lat, double long, double distance, String nextPageToken) async {
  final meterDistance = distance * METERS_PER_MILE;
  final buffer = StringBuffer(URL);
  if (nextPageToken != null) {
    buffer.write("pagetoken=$nextPageToken");
  } else {
    buffer
      ..write("location=$lat,$long")
      ..write("&radius=$meterDistance")
      ..write("&type=restaurant")
      ..write("&opennow=true");
  }
  buffer.write("&key=${await _getApiKey()}");
  return buffer.toString();
}

List<Restaurant> _getRestaurantsFromJson(dynamic decodedJson) {
  List<Restaurant> restaurants = [];
  for (final result in decodedJson['results']) {
    final location = result['geometry']['location'];
    final lat = location['lat'];
    final long = location['lng'];
    restaurants.add(Restaurant(name: result['name'], lat: lat, long: long));
  }
  return restaurants;
}

Future<String> _getApiKey() async {
  final encodedJson = await rootBundle.loadString('key.json');
  final decodedJson = jsonDecode(encodedJson);
  return decodedJson["places_key"];
}
