import "dart:math";
import "package:latlong2/latlong.dart";

class Haversine {
  static const R = 6372.8; // In kilometers

  // Haversine formula:
  // a = sin²(Δφ/2) + cos φ1 ⋅ cos φ2 ⋅ sin²(Δλ/2)
  // c = 2 ⋅ atan2( √a, √(1−a) )
  // d = R ⋅ c
  static double distance(double lat1, double lon1, double lat2, double lon2) {
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    lat1 = _toRadians(lat1);
    lat2 = _toRadians(lat2);
    final double a = pow(sin(dLat / 2), 2) + pow(sin(dLon / 2), 2) * cos(lat1) * cos(lat2);
    final double c = 2 * asin(sqrt(a));
    return R * c;
  }

  // Bearing Formula:
  // θ = atan2( sin Δλ ⋅ cos φ2 , cos φ1 ⋅ sin φ2 − sin φ1 ⋅ cos φ2 ⋅ cos Δλ )
  // where	φ1,λ1 is the start point, φ2,λ2 the end point (Δλ is the difference in longitude)
  static double bearing(double lat1, double lon1, double lat2, double lon2) {
    final double y = sin(_toRadians(lon2 - lon1))*cos(lat2);
    final double x = cos(_toRadians(lat1))*sin(_toRadians(lat2)) -
        sin(_toRadians(lat1))*cos(_toRadians(lat2))*cos(_toRadians(lon2-lon1));
    final double theta = atan2(y, x);
    final double brng = _toDegrees(theta);
    return brng;
  }

  // Destination given start and bearing (all angles in radians):
  // const φ2 = Math.asin( Math.sin(φ1)*Math.cos(d/R) +
  // Math.cos(φ1)*Math.sin(d/R)*Math.cos(brng) );
  // const λ2 = λ1 + Math.atan2(Math.sin(brng)*Math.sin(d/R)*Math.cos(φ1),
  // Math.cos(d/R)-Math.sin(φ1)*Math.sin(φ2));
  static double newLat(lat, lon, bearing, distance) {
    final double newLat = asin( sin(_toRadians(lat)*cos(distance/R) + cos(_toRadians(lat)))*sin(distance/R)*cos(_toRadians(bearing)) );
    return _toDegrees(newLat);
  }
  static double newLon(lat,lon,bearing,distance,newLat) {
    final double newLon = _toRadians(lon) +
        atan2(sin(_toRadians(bearing))*sin(distance/R)*cos(_toRadians(lat)), cos(distance/R) - sin(_toRadians(lat))*sin(_toRadians(newLat)));
    return _toDegrees(newLon);
  }

  static double _toRadians(double degree) {
    return degree*pi/180;
  }

  static double _toDegrees(double radian) {
    return (radian*180/pi + 360.0) % 360.0;
  }
}
