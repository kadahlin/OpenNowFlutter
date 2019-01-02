import 'dart:math' as math;

///Calculate the distance between two sets of coordinates and return the value in miles.
///The haversine formula accounts for the curvature of the earth
class Haversine {

  static const RADIUS = 6371000;

  static double getDistanceBetween({lat1: double ,long1: double, lat2: double, long2: double}) {
    final lat1Radians = _toRadians(lat1);
    final lat2Radians = _toRadians(lat2);
    final deltaLat = _toRadians(lat2 - lat1);
    final deltaLong = _toRadians(long2 - long1);

    final a = math.sin(deltaLat / 2.0) * math.sin(deltaLat / 2.0) + math.cos(lat1Radians) * math.cos(lat2Radians) * math.sin(deltaLong / 2.0) * math.sin(deltaLong / 2.0);
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final metersDistance = RADIUS * c;
    return metersDistance * 0.000621371;
  }

  static double _toRadians(double value) {
    return value * math.pi / 180;
  }
}