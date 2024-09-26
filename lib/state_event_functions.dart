import 'package:gps_tracker_db/gps_tracker_db.dart';
import 'event.dart';
import 'instance_vars.dart';
import 'constants.dart';

class StateEventFunctions {

  InstanceVars iv;

  StateEventFunctions({required this.iv});

  // Add an event to the queue
  void addEventToQueue(String event, var param) {
    Event e = Event(event: event, parameter: param);
    iv.eventQueueController.sink.add(e);
  }

  void disableMenuItems(var param) {
    iv.galleryEnabled = false;
    iv.optimumTimeEnabled = false;
    iv.uploadWalkEnabled = false;
    iv.displayWalksEnabled = false;
    iv.clearDisplayEnabled = false;
  }

  void enableMenuItems(var param) {
    if (iv.imagePaths.isNotEmpty) {
      iv.galleryEnabled = true;
    } else {
      iv.galleryEnabled = false;
    }
    iv.optimumTimeEnabled = true;
    iv.uploadWalkEnabled = true;
    iv.displayWalksEnabled = true;
    iv.clearDisplayEnabled = true;
  }

  void disableOptimumTimeGalleryAndUploadMenu(var param) {
    iv.optimumTimeEnabled = false;
    iv.galleryEnabled = false;
    iv.uploadWalkEnabled = false;
  }

  void enableOptimumTimeGalleryAndUploadMenu(var param) {
    iv.galleryEnabled = true;
    iv.optimumTimeEnabled = true;
    iv.uploadWalkEnabled = true;
  }

  Future<void> setOptimumTime(var param) async {
    // Get the current walk
    final Walk walk                        = await iv.db.getWalk(iv.walkName);
    final double metresPerMinute           = (iv.distanceNotifier.value/param)*60;
    double nextMarker                      = metresPerMinute;
    final List<WalkWaypoint> minuteMarkers = [];

    // Loop over the walk points setting the markers.
    // This should really interpolate between the two, but I'm lazy.....
    final WalkTrackPoint wtp1 = walk.track[0];
    for (int i = 1; i < walk.track.length; i++) {
      final WalkTrackPoint wtp2 = walk.track[i];
      if (wtp1.distance < nextMarker && wtp2.distance >= nextMarker) {
        // var distanceToMarker = nextMarker - wtp1.distance;
        // var bearing          = calculateBearing(wtp1.latitude,wtp1.longitude,wtp2.latitude,wtp2.longitude);
        // var newPos           = calculateLatLon(wtp1.latitude,wtp1.longitude,distanceToMarker,bearing);
        // minuteMarkers.add(WalkWaypoint(latitude: newPos[0],longitude: newPos[1]));
        minuteMarkers.add(WalkWaypoint(latitude: wtp2.latitude, longitude: wtp2.longitude));
        nextMarker += metresPerMinute;
      }
    }

    // Update the database and reload the walk
    await iv.db.deleteWaypointsFromWalk(iv.walkName);
    await iv.db.addWalkWaypoints(iv.walkName,minuteMarkers);
    await iv.db.updateWalkOptimumDurn(iv.walkName,(param as int)~/60, param%60);
    addEventToQueue(Constants.EVENT_LOAD_WALK, iv.walkName);
  }

}