import 'package:flutter/material.dart';

///data class to hold the relevant data of a single Google Places response
class Restaurant {

  String name;
  double lat;
  double long;
  double distance;

  Restaurant({@required this.name, @required this.lat, @required this.long, this.distance: 0.0});
}