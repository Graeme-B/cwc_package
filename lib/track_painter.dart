import "dart:math";

import "package:flutter/material.dart";
import "package:gps_tracker_db/gps_tracker_db.dart";

import "constants.dart";

class TrackPainter extends CustomPainter
{

  TrackPainter({required Listenable repaint}) : super(repaint: repaint)
  {
    // _repaint = repaint;
  }
  List<WalkTrackPoint> waypoints     = [];
  List<WalkImage>      images        = [];
  List<WalkWaypoint>   minuteMarkers = [];
  // ChangeNotifier       _repaint      = ChangeNotifier();

  void addWalkTrackPoints(List<WalkTrackPoint> waypoints)
  {
    this.waypoints = waypoints;
  }

  void addWalkTrackPoint(WalkTrackPoint waypoint)
  {
    waypoints.add(waypoint);
  }

  void clearWalkTrack()
  {
    waypoints   = [];
    images      = [];
    minuteMarkers = [];
  }

  void addWalkImages(List<WalkImage> images)
  {
    this.images = images;
  }

  void addWalkTrackImage(WalkImage image)
  {
    images.add(image);
  }

  void addWalkMinuteMarkers(List<WalkWaypoint> timeMarkers)
  {
    minuteMarkers = timeMarkers;
  }

  List<WorldToScreen> getTranslations(Size size) {
    final List<WorldToScreen> translations = [];

    // If we have more than one waypoint, calculate the axes translations and draw the points
    if (waypoints.length > 1) {
      // Find the max and min latitude and longitude by iterating over the points
      double latMin = 90;
      double latMax = -90;
      double lonMin = 180;
      double lonMax = -180;
      for (final waypoint in waypoints) {
        // var l1 = waypoint.lat;
        // var l2 = waypoint.lon;
        // print("lat $l1 lon $l2");
        if (waypoint.latitude < latMin)  latMin = waypoint.latitude;
        if (waypoint.latitude > latMax)  latMax = waypoint.latitude;
        if (waypoint.longitude < lonMin) lonMin = waypoint.longitude;
        if (waypoint.longitude > lonMax) lonMax = waypoint.longitude;
      }
      // // print("Initial latMin $latMin latMax $latMax lonMin $lonMin lonMax $lonMax");
      // double distance = 0.0;
      // int elapsed_time = 0;
      // if (waypoints.length > 0) {
      //   distance = waypoints[waypoints.length - 1].distance;
      //   elapsed_time = waypoints[waypoints.length - 1].elapsed_time;
      // }

      // Get the lat and lon mid points
      final latMid = latMin + (latMax - latMin) / 2;
      final lonMid = lonMin + (lonMax - lonMin) / 2;

      // Find the absolute distances of latitude and longitude span and the ratio
      var latDistanceInMetres = calculateDistance(
          latMin, lonMid, latMax, lonMid) * 1000;
      var lonDistanceInMetres = calculateDistance(
          latMid, lonMin, latMid, lonMax) * 1000;

      // Get the world ratio and the screen ratio
      final worldRatio = latDistanceInMetres / lonDistanceInMetres;
      final screenRatio = size.height / size.width;

      // Decide whether the X or Y span is largest compared to the screen
      // We anchor the largest and adjust the smallest to fit the screen by
      // working out how many metres this will be in the real world
      // World ratio > screen ratio ==> Y span is the largest
      // Add a 10% margin (5% each side)
      if (worldRatio > screenRatio) {
        latDistanceInMetres = latDistanceInMetres*1.1;
        lonDistanceInMetres = latDistanceInMetres/screenRatio;
      } else {
        lonDistanceInMetres = lonDistanceInMetres*1.1;
        latDistanceInMetres = lonDistanceInMetres*screenRatio;
      }

      // We now need to calculate the min lat and lon from the distance
      List<double> l1 = calculateLatLon(
          latMid, lonMid, latDistanceInMetres/2, 0);
      latMin = l1[0];
      latMax = latMin + 2*(latMid - latMin);
      l1 = calculateLatLon(latMid, lonMid, lonDistanceInMetres/2, 90);
      lonMax = l1[1];
      lonMin = lonMax - 2*(lonMax - lonMid);
      // print("Subsequent latMin $latMin latMax $latMax lonMin $lonMin lonMax $lonMax");

      // Create the translation objects
      translations.add(WorldToScreen(0, size.height, latMin, latMax));
      translations.add(WorldToScreen(0, size.width, lonMin, lonMax));
    }
    return translations;
  }

  int selectedImage(int x, int y, Size size) {
    // Clear the image index and get the coordinate translations
    var imageIndex = -1;
    final List<WorldToScreen> translations = getTranslations(size);
    final latTranslate = translations[0];
    final lonTranslate = translations[1];

    // See if the image is selected
    for (int i = 0; i < images.length && imageIndex < 0; i++) {
      final image = images[i];
      final Offset o = Offset(lonTranslate.mapWorldToScreen(image.longitude),
          latTranslate.mapWorldToScreen(image.latitude));

      if (x - Constants.HIT_TEST_INTERVAL < o.dx &&
          x + Constants.HIT_TEST_INTERVAL > o.dx &&
          y - Constants.HIT_TEST_INTERVAL < o.dy &&
          y + Constants.HIT_TEST_INTERVAL > o.dy) {
        imageIndex = i;
      }
    }

    return imageIndex;
  }

  @override
  void paint(Canvas canvas, Size size)
  {
    // Set up the paint object to do the actual drawing
    final paint = Paint();
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    // Draw an outline around the window
    final Path border = Path();
    border.moveTo(0,0);
    border.lineTo(0,size.height);
    border.lineTo(size.width,size.height);
    border.lineTo(size.width,0);
    border.lineTo(0,0);
    border.close();
    canvas.drawPath(border, paint);

    // Draw a 100 x 100 square in the middle
    // This is to prove that the X and Y coords are equivalent,
    // ie one X takes up the same space on the glass as one Y.
    // var xstart = size.width/2 - 50;
    // var ystart = size.height/2 - 50;
    //
    // Path border1 = Path();
    // border1.moveTo(xstart,ystart);
    // border1.lineTo(xstart + 100, ystart);
    // border1.lineTo(xstart + 100, ystart + 100);
    // border1.lineTo(xstart,ystart + 100);
    // border1.moveTo(xstart,ystart);
    // border1.close();
    // canvas.drawPath(border1, paint);

    final List<WorldToScreen> translations = getTranslations(size);
    if (translations.isNotEmpty) {
      final latTranslate = translations[0];
      final lonTranslate = translations[1];

        // paint.style = PaintingStyle.fill;
        // paint.color = Colors.blue;
        // Offset o = Offset(lonTranslate.mapWorldToScreen(waypoints[waypoints.length - 1].longitude),
        //   latTranslate.mapWorldToScreen(waypoints[waypoints.length - 1].latitude));
        // canvas.drawCircle(o, Constants.MARKER_SIZE, paint);

      // Draw the points
      Offset o1 = Offset(lonTranslate.mapWorldToScreen(waypoints[0].longitude),
          latTranslate.mapWorldToScreen(waypoints[0].latitude));
      for (var i = 1; i < waypoints.length; i++)
      {
        final Offset o2 = Offset(lonTranslate.mapWorldToScreen(waypoints[i].longitude),
            latTranslate.mapWorldToScreen(waypoints[i].latitude));
        canvas.drawLine(o1, o2, paint);
        o1 = o2;
      }

      // Draw the minute markers
      if (minuteMarkers.isNotEmpty) {
        paint.color = Colors.red;
        for (final marker in minuteMarkers) {
          final Offset o = Offset(lonTranslate.mapWorldToScreen(marker.longitude),
              latTranslate.mapWorldToScreen(marker.latitude));
          canvas.drawLine(Offset(o.dx - Constants.CROSS_SIZE, o.dy - Constants.CROSS_SIZE),
              Offset(o.dx + Constants.CROSS_SIZE, o.dy + Constants.CROSS_SIZE), paint);
          canvas.drawLine(Offset(o.dx + Constants.CROSS_SIZE, o.dy - Constants.CROSS_SIZE),
              Offset(o.dx - Constants.CROSS_SIZE, o.dy + Constants.CROSS_SIZE), paint);
        }
      }

      // Draw the image markers
      paint.style = PaintingStyle.fill;
      paint.color = Colors.blue;
      for (final image in images) {
        final Offset o = Offset(lonTranslate.mapWorldToScreen(image.longitude),
            latTranslate.mapWorldToScreen(image.latitude));
        canvas.drawCircle(o, Constants.MARKER_SIZE, paint);
      }
    }

  }

  @override
  bool shouldRepaint(TrackPainter oldDelegate) {
    // return (old.waypoints != null && old.waypoints.length > 0);
    return true;
  }

}

class WorldToScreen
{

  WorldToScreen(this.screenMin, this.screenMax, this.worldMin, this.worldMax);
  double screenMin;
  double screenMax;
  double worldMin;
  double worldMax;

  double mapWorldToScreen(worldCoord) {
    return (worldCoord - worldMin)*(screenMax - screenMin)/
        (worldMax - worldMin);
  }
}

double calculateDistance(lat1, lon1, lat2, lon2)
{
  const p = 0.017453292519943295;
  final a = 0.5 - cos((lat2 - lat1) * p)/2 +
      cos(lat1 * p) * cos(lat2 * p) *
          (1 - cos((lon2 - lon1) * p))/2;
  return 12742 * asin(sqrt(a));
}

List<double> calculateLatLon(lat,lon,distance,bearing)
{
  const R  = 6378.1;            // Radius of the Earth
  lat      = (lat*pi)/180;      // lat point converted from degrees to radians
  lon      = (lon*pi)/180;      // lon point converted from degrees to radians
  bearing  = (bearing*pi)/180;  // Bearing converted from degrees to radians
  distance = distance/1000;     // Distance converted from metres to kilometers

  final lat2 = asin(sin(lat)*cos(distance/R) +
      cos(lat)*sin(distance/R)*cos(bearing));
  final lon2 = lon + atan2(sin(bearing)*sin(distance/R)*cos(lat),cos(distance/R) - sin(lat)*sin(lat2));
  final List<double> retval = [lat2*180/pi,lon2*180/pi];  // lat/lon converted from radians to degrees
  return retval;
}

double calculateBearing(lat1,lon1,lat2,lon2)
{
  // φ1,λ1 is the start point, φ2,λ2 the end point (Δλ is the difference in longitude)
  final double y     = sin(lon2 - lon1)*cos(lat2);
  final double x     = cos(lat1)*sin(lat2) - sin(lat1)*cos(lat2)*cos(lon2 - lon1);
  final double theta = atan2(y,x);
  final double brng  = (theta*180/pi + 360)%360; // in degrees

  return brng;
}
