import "dart:core";
import "dart:io";
import "dart:typed_data";

import "package:flutter/services.dart";
import "package:gps_tracker_db/gps_tracker_db.dart";
import "package:intl/intl.dart";
import "package:latlong2/latlong.dart";
import "package:path_provider/path_provider.dart";

import "instance_vars.dart";
import "utils.dart";

class DebugWalks {
  InstanceVars iv;

  DebugWalks({required this.iv});

  void writeDebug(var param) {
    writeFile("log.txt","Debug write");
  }

  Future<void> addWalk(String walkName, List<double> lat, List<double> lon, List<WalkImage> images, List<WalkWaypoint> minuteMarkers) async
  {
    walkName = "$walkName ${DateFormat("dd-MM-yyyy HH:mm:ss").format(DateTime.now())}";

    final List<WalkTrackPoint> waypoints = [];
    double distance = 0.0;
    for (int i = 0; i < lat.length; i++) {
      if (i > 0) {
        const Distance d = Distance();
        distance += d(LatLng(lat[i - 1], lon[i - 1]), LatLng(lat[i], lon[i]));
      }
      waypoints.add(
          WalkTrackPoint(
              create_date: DateFormat("dd-MM-yyyy HH:mm:ss").format(
                  DateTime.now()),
              latitude: lat[i],
              longitude: lon[i],
              distance: distance,
              provider: "gps",
              accuracy: 0.5,
              elapsed_time: 0
          ));
    }

    try {
      await iv.db.addWalk(walkName);
    } catch (err) {
      writeDebug("Error ${err.toString()} adding walk");
    }
    try {
      await iv.db.addWalkTrackPoints(walkName, waypoints);
    } catch (err) {
      writeDebug("Error ${err.toString()} adding walk track points");
    }
    if (images.isNotEmpty) {
      try {
        await iv.db.addWalkImages(walkName, images);
      } catch (err) {
        writeDebug("Error ${err.toString()} adding walk images");
      }
    }
    if (minuteMarkers.isNotEmpty) {
      try {
        await iv.db.addWalkWaypoints(walkName, minuteMarkers);
      } catch (err) {
        writeDebug("Error ${err.toString()} adding minute markers");
      }
    }
  }

  Future<WalkImage> debugWalkImage(double lat,double lon,String img) async {
    String destPath = "";
    if (Platform.isAndroid) {
      final Directory? a = await getExternalStorageDirectory();  // OR return "/storage/emulated/0/Download";
      destPath = a!.path;
    } else if (Platform.isIOS) {
      final Directory d = await getApplicationDocumentsDirectory();
      destPath = d.path;
    }


    // final Directory docDir = await getApplicationDocumentsDirectory();
    // final String localPath = docDir.path;
    final File file = File("$destPath/${img.split(Platform.pathSeparator).last}");
    final ByteData imageBytes = await rootBundle.load(img);
    final ByteBuffer buffer = imageBytes.buffer;
    await file.writeAsBytes(
        buffer.asUint8List(imageBytes.offsetInBytes, imageBytes.lengthInBytes));



    // await sourceFile.copy(destPath);
    return WalkImage(image_name: Platform.pathSeparator + img.split("/").last,
        create_date: DateFormat("dd-MM-yyyy HH:mm:ss").format( DateTime.now()),
        latitude: lat, longitude: lon, distance: 0.05);
  }

  Future<void> addDebugWalks(var param) async
  {
    // Equator
    List<double> lat = [ 0.0, 0.0, 0.0142857142857, 0.0142857142857, 0.0];
    List<double> lon = [ 0.0, 0.01666666, 0.01666666, 0.0, 0.0];
    addWalk("Equator 1x1", lat, lon, [], []);

    lat = [ 0.0, 0.0, 0.0142857142857, 0.0142857142857, 0.0];
    lon = [ 0.0, 0.05, 0.05, 0.0, 0.0];
    addWalk("Equator 1x3", lat, lon, [], []);

    lat = [ 0.0, 0.0, 0.0428571428571, 0.0428571428571, 0.0];
    lon = [ 0.0, 0.01666666, 0.01666666, 0.0, 0.0];
    addWalk("Equator 3x1", lat, lon, [], []);

    // Edinburgh
    lat = [ 55.948612, 55.948612, 55.962999, 55.962999, 55.948612];
    lon = [ -3.200833, -3.22653, -3.22653, -3.200833, -3.200833];

    final List<WalkImage> images = [];
    WalkImage wi = await debugWalkImage(
        lat[0], lon[2] + (lon[3] - lon[2]) / 2.0, iv.landscapeImageFile);
    images.add(wi);
    wi = await debugWalkImage(
        lat[1] + (lat[2] - lat[1]) / 2.0, lon[1], iv.portraitImageFile);
    images.add(wi);
    wi = await debugWalkImage(
        lat[2], lon[2] + (lon[3] - lon[2]) / 2.0, iv.imageFile2);
    images.add(wi);
    wi = await debugWalkImage(
        lat[1] + (lat[2] - lat[1]) / 2.0, lon[3], iv.imageFile3);
    images.add(wi);

    final List<WalkWaypoint> minuteMarkers = [];
    minuteMarkers.add(WalkWaypoint(
        latitude: lat[0], longitude: lon[2] + (lon[3] - lon[2]) / 3.0));
    minuteMarkers.add(WalkWaypoint(
        latitude: lat[1] + (lat[2] - lat[1]) / 3.0, longitude: lon[1]));
    minuteMarkers.add(WalkWaypoint(
        latitude: lat[2], longitude: lon[2] + (lon[3] - lon[2]) / 3.0));
    minuteMarkers.add(WalkWaypoint(
        latitude: lat[1] + (lat[2] - lat[1]) / 3.0, longitude: lon[3]));
    addWalk("Edinburgh 1x1", lat, lon, images, minuteMarkers);

    lat = [ 55.948612, 55.948612, 55.962999, 55.962999, 55.948612];
    lon = [ -3.200833, -3.149439, -3.149439, -3.200833, -3.200833];
    addWalk("Edinburgh 1x3", lat, lon, [], []);

    // Auckland
    lat = [ -36.848461, -36.848461, -36.862848, -36.862848, -36.848461];
    lon = [ 174.763336, 174.78132, 174.78132, 174.763336, 174.763336];
    addWalk("Auckland 1x1", lat, lon, [], []);
  }

}