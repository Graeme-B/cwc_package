import "upload_results.dart";

// ------------------------ State event functions ---------------------------
abstract class StateEventFunctionInterface {
  Future<void> startService(var param);
  Future<void> stopService(var param);
  Future<void> uploadWalkDialog(var param);
  Future<void> uploadWalk(var param);
  Future<UploadResults> doWalkUpload(var param);
  Future<void> loginDialog();
  Future<void> loadWalk(var param);
  Future<void> takePhoto(var param);
  Future<void> photoTaken(List<Object?> param);
  Future<void> startTracking(var param);
  Future<void> checkLocationPermissions(var param);
  Future<void> showLocationSettingsBeforeGranted(var param);
  Future<void> showLocationSettingsWhenTracking(var param);
  Future<void> showLocationSettingsAfterGranted(var param);
  Future<void> showLocationSettings(var title);
  Future<void> requestLocationPermissions(var param);

  void optimumTimeDialog(var param);
  void gpsStatusDialog(var param);
  void displayWalksWindow(var param);
  void displayGallery(var param);
  void clearWalkPoints(var param);
  void clearDisplay(var param);
  void addCoordsToMap(Map<Object?, Object?> map);
  void centreDisplay(var param);
  void moveMap(Map<Object?, Object?> map);
  void initialFixReceived(var param);
  void storePosition(Map<Object?, Object?> map);
  void toggleMaps(var param);
  void setReadyToTrack(var param);
  void pauseTracking(var param);
  void resumeTracking(var param);
  void stopTrackingPressedAction(var param);
  void trackingStillPaused(var param);
  void trackingStopped(var param);
  void trackingStoppedAsPermissionRevoked(var param);
  void permissionRevoked(var param);
  void actOnPermissions(var permission);
}