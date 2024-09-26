import "dart:async";
import "dart:convert" show utf8;
import "dart:core";
import "dart:io";
import "dart:typed_data";
import "dart:ui" as ui;

import "package:camera/camera.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_map_location_marker/flutter_map_location_marker.dart";
import "package:google_mobile_ads/google_mobile_ads.dart";
import "package:http/http.dart" as http;
import "package:http_parser/http_parser.dart";
import "package:intl/intl.dart";
import "package:latlong2/latlong.dart";
import "package:path_provider/path_provider.dart";
import "package:permission_handler/permission_handler.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:uuid/uuid.dart";

import "package:gps_tracker/gps_tracker.dart";
import "package:gps_tracker_db/gps_tracker_db.dart";
import 'package:package_info_plus/package_info_plus.dart';

// *** Google Ads ***
import "ad_helper.dart";
import "constants.dart";
import "gallery.dart";
import "image_editor.dart";
import "photo.dart";
import "track_painter.dart";
import "walk_window.dart";
import "state_event.dart";
import "instance_vars.dart";
import "utils.dart";
import "upload_results.dart";
import "state_event_functions_interface.dart";

// -  Break things down a lot! UI into a separate file, debug_walks into a separate file, state stuff in a separate file
// -  Document each variable (simple comment will do)
// -  Use a consistent naming strategy - currently, some are camel case and some are underscore-separated
// -  Delete image files when deleting walk
// -  Move map fails if _mapController not initialised, such as on first display
//    What to do if we're trying to move the map and it hasn't been displayed yet? How to set _cz? Work out how _cz applies to boundaries?
// -  Only enable SET DURATION if we have some points
// -  Ignore GPS updates if less than accuracy - Android phone has done 266m without moving....

// To paint an image:
// https://gist.github.com/netsmertia/9c588f23391c781fa1eb791f0dce0768#file-main-dart-L73
// Aspect ratio calculator:
// https://www.omnicalculator.com/other/aspect-ratio
// Icon maker:
// https://appiconmaker.co/   (start with a 1024x1024 icon - need to copy icons to correct place)
// Map markers:
// https://pub.dev/packages/flutter_map_marker_cluster
// OSM
// https://techblog.geekyants.com/implementing-flutter-maps-with-osm
// Zoom level
// https://stackoverflow.com/questions/6002563/android-how-do-i-set-the-zoom-level-of-map-view-to-1-km-radius-around-my-curren
// Dismiss dialog
// https://stackoverflow.com/questions/50683524/how-to-dismiss-flutter-dialog

// https://stackoverflow.com/questions/51127241/how-do-you-change-the-value-inside-of-a-textfield-flutter
// or https://abhishekdoshi26.medium.com/rebuild-your-widget-without-setstate-valuenotifier-bd7c1bf7a96b
// to update Distance
// and _mapController to move the map

// Wordpress
// add custom template (but this adds a complete page, not just a bit)
//  https://stackoverflow.com/questions/2810124/how-can-i-add-a-php-page-to-wordpress
// add a child theme which can contain custom content, eg replacing header.php
//  https://docs.zakratheme.com/en/article/how-to-add-custom-code-to-the-theme-using-child-theme-1ml5yot/
// add custom content
//   https://www.smashingmagazine.com/2015/04/extending-wordpress-custom-content-types/
// plugin which allows php snippets to be inserted into a page
//  https://wordpress.org/plugins/insert-php-code-snippet/
// using it
//  https://www.hostinger.co.uk/tutorials/wordpress/how-to-add-php-code-to-wordpress-post-or-page?ppc_campaign=google_search_generic_hosting_all&bidkw=defaultkeyword&lo=9045864&gclid=CjwKCAiA76-dBhByEiwAA0_s9UD2XP2TsYNjbKYo14hSFf7qgs7c8dh8baTIYl_Q4AfQ2AoLsnrneBoCLBsQAvD_BwE
//  https://help.xyzscripts.com/docs/insert-php-code-snippet/user-guide/
//  http://help.xyzscripts.com/docs/insert-php-code-snippet/faq/

// Diagonal distance at zoom 16 is 1.1288031160583827 km
// n 50.82223796778059 e -0.36872863769531256 s 50.813575249300385 w -0.3770971298217774
// Diagonal distance at zoom 16 is 0.28220081998896135 km
// n 50.81898285847856 e -0.37185609340667725 s 50.81681717854515 w -0.3739482164382935
// int index = 0;
// List<LatLng> centers = [
//   LatLng(50.8179,-0.3729),     // Worthing
//   LatLng(0.0, 0.0),            // Equator
//   LatLng(55.9533, -3.18833),   // Edinburgh
//   LatLng(-36.8509, 174.7645),  // Auckland
// ];
// int centerInd = 0;

class CourseWalkCompanion extends StatelessWidget {

  const CourseWalkCompanion({
    required this.showBanner,
    required this.title,
    Key? key,
  }) : super(key: key);
  final bool showBanner;
  final String title;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CourseWalkCompanionPage(title: title, showBanner: showBanner),
    );
  }
}

class CourseWalkCompanionPage extends StatefulWidget {
  const CourseWalkCompanionPage({Key? key, required this.title, required this.showBanner})
      : super(key: key);
  final String title;
  final bool showBanner;

  @override
  State<CourseWalkCompanionPage> createState() => CourseWalkCompanionState(title: title, showBanner: showBanner);
}

class CourseWalkCompanionState
    extends State<CourseWalkCompanionPage>
    with TickerProviderStateMixin, WidgetsBindingObserver
    implements StateEventFunctionInterface {
  static final InstanceVars   _iv      = InstanceVars();
  static final ChangeNotifier _repaint = ChangeNotifier();
  static final TrackPainter   _painter = TrackPainter(repaint: _repaint);

  late StateEvent     _stateEvent;
  late MapController _mapController;

  CourseWalkCompanionState({required title, required showBanner}) {
    _iv.showBanner = showBanner;
    _iv.title      = title;
    _iv.appTitle   = Text(title);
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _iv.packageName = info.packageName;
    });
  }
  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _iv.buttons[0]  = simpleButton(Constants.PROMPT_AWAIT_GPS, null);

    _stateEvent    = StateEvent(sef: this, iv: _iv);
    _stateEvent.setActions();

    WidgetsBinding.instance.addObserver(this);

    init();

    // *** Google Ads ***
    if (_iv.showBanner) {
      _loadBannerAds();
    }

    _stateEvent.addEventToQueue(Constants.EVENT_STARTUP, null);
  }

  void _loadBannerAds() {
    for (int i = 0; i < 2; i++) {
      _iv.bannerAds.add(
          BannerAd(
            adUnitId: bannerAdUnitId,
            request: const AdRequest(),
            size: AdSize.banner,
            listener: BannerAdListener(
              onAdLoaded: (_) {
                setState(() {
                  _iv.isBannerAdReady = true;
                });
              },
              onAdFailedToLoad: (Ad ad, LoadAdError err) {
                _iv.isBannerAdReady = false;
                ad.dispose();
              },
            ),
          )
      );
      _iv.bannerAds[i].load();
    }
  }

  void _listener(dynamic o) {
    final Map<dynamic,dynamic> map = o as Map;
    final reason = map["reason"];
    if (reason == "COORDINATE_UPDATE") {
      _stateEvent.addEventToQueue(Constants.EVENT_GPS_COORDS, map);
    } else {
      final bool fixValid = map["fix_valid"] as bool;
      if (fixValid)
      {
        _stateEvent.addEventToQueue(Constants.EVENT_GPS_FIX, map);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // *** Google Ads ***
    if (_iv.showBanner) {
      for (final BannerAd ad in _iv.bannerAds) {
        ad.dispose();
      }
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      GpsTracker.checkForLocationPermissionChanges();
      _stateEvent.addEventToQueue(Constants.EVENT_SWITCH_TO_FOREGROUND, null);
    } else if(state == AppLifecycleState.paused) {
      _stateEvent.addEventToQueue(Constants.EVENT_SWITCH_TO_BACKGROUND, null);
    // } else if(lifecycleState == AppLifecycleState.inactive) {
    //   print("didChangeAppLifecycleState Inactive");
    // } else if(lifecycleState == AppLifecycleState.detached) {
    //   print("didChangeAppLifecycleState Detached");
    }
  }

  Future <void> init() async {
    final ByteData dataH = await rootBundle.load(_iv.landscapeImageFile);
    _iv.landscapeImage   = await loadImage(Uint8List.view(dataH.buffer));
    final ByteData dataV = await rootBundle.load(_iv.portraitImageFile);
    _iv.portraitImage    = await loadImage(Uint8List.view(dataV.buffer));
    final ByteData data2 = await rootBundle.load(_iv.imageFile2);
    _iv.image2           = await loadImage(Uint8List.view(data2.buffer));
    final ByteData data3 = await rootBundle.load(_iv.imageFile3);
    _iv.image3           = await loadImage(Uint8List.view(data3.buffer));
    setState(() {
      _iv.isImageloaded = true;
    });

    // Read the uploaded walk name and user from the preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _iv.uploadWalkName    = prefs.getString(Constants.UPLOAD_WALK_NAME_KEY) ?? "";
    _iv.uploadWalkCountry = prefs.getString(Constants.UPLOAD_WALK_COUNTRY_KEY) ?? "";
    _iv.uploadWalkUser    = prefs.getString(Constants.UPLOAD_WALK_USER_KEY) ?? "";
    _iv.uploadWalkEmail   = prefs.getString(Constants.UPLOAD_WALK_EMAIL_KEY) ?? "";
    _iv.uploadWalkClass   = prefs.getString(Constants.UPLOAD_WALK_CLASS_KEY) ?? "";
    _iv.deviceUuid        = prefs.getString(Constants.DEVICE_UUID) ?? "";
    if (_iv.deviceUuid.isEmpty) {
      const Uuid uuid = Uuid();
      _iv.deviceUuid  = uuid.v1(); // Generate a v1 (time-based) id
      await prefs.setString(Constants.DEVICE_UUID,_iv.deviceUuid);
    }
  }

  Future<ui.Image> loadImage(Uint8List img) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  Widget buildImage() {
    if (_iv.isImageloaded) {
      return CustomPaint(
        foregroundPainter: ImageEditor(portraitImage: _iv.portraitImage, landscapeImage: _iv.landscapeImage),
        child: Container(),
      );
    } else {
      return const Center(child: Text("loading"));
    }
  }

  Widget simpleButton(String prompt, void Function()? action) {
    return ElevatedButton(
      onPressed: action,
      child: Text(prompt),
    );
  }

  Widget listenerButton(String prompt, var startAction, var stopAction) {
    return Listener(
      // onPointerDown: (event) => stopTrackingPressed(event),
      // onPointerUp: (event) => stopTrackingReleased(event),
      onPointerDown: (PointerDownEvent event) => startAction(event),
      onPointerUp: (PointerUpEvent event) => stopAction(event),
      // onPointerCancel: (event) => print('Cancel'),
      child: ElevatedButton(
        onPressed: () {},
        child: Text(prompt),
      ),
    );
  }

  Widget buildButtons() {
    final List<Widget> controls = [];
    for (final Widget? button in _iv.buttons) {
      if (button != null) {
        controls.add(
          Expanded(
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.33,
              margin: const EdgeInsets.all(1.0),
              child: button,
            ),
          ),
        );
      } else {
        controls.add(
          Expanded(
            child: Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.33,
            ),
          ),
        );
      }
    }
    return Row(children: controls);
  }

  PopupMenuItem<String> loginMenuItem() {
    return PopupMenuItem<String>(
        value: Constants.EVENT_LOGIN,
        enabled: true,
        child: const Text(Constants.MENU_PROMPT_LOGIN));
  }

  Widget buildMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String result) {
        _stateEvent.addEventToQueue(result, null);
      },
      itemBuilder: (BuildContext context) =>
      <PopupMenuEntry<String>>[
        CheckedPopupMenuItem<String>(
          checked: _iv.showMap,
          value: Constants.EVENT_TOGGLE_MAPS,
          child: const Text(Constants.MENU_PROMPT_MAPS),
        ),
        PopupMenuItem<String>(
          value: Constants.EVENT_DISPLAY_WALKS,
          enabled: _iv.displayWalksEnabled,
          child: const Text(Constants.MENU_PROMPT_WALKS),
        ),
        PopupMenuItem<String>(
          value: Constants.EVENT_CLEAR_DISPLAY,
          enabled: _iv.clearDisplayEnabled,
          child: const Text(Constants.MENU_PROMPT_CLEAR_DISPLAY),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: Constants.EVENT_SHOW_GALLERY,
          enabled: _iv.galleryEnabled,
          child: const Text(Constants.MENU_PROMPT_GALLERY),
        ),
        PopupMenuItem<String>(
          value: Constants.EVENT_SHOW_OPTIMUM_TIME_DIALOG,
          enabled: _iv.optimumTimeEnabled,
          child: const Text(Constants.MENU_PROMPT_OPTIMUM_TIME),
        ),
        PopupMenuItem<String>(
          value: Constants.EVENT_SHOW_UPLOAD_WALK_DIALOG,
          enabled: _iv.uploadWalkEnabled,
          child: const Text(Constants.MENU_PROMPT_UPLOAD),
        ),
//        loginMenuItem(),
       PopupMenuItem<String>(
    value: Constants.EVENT_LOGIN,
    enabled: true,
    child: const Text(Constants.MENU_PROMPT_LOGIN),
       ),

    const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: Constants.EVENT_CREATE_DEBUG_WALKS,
          child: Text(Constants.MENU_PROMPT_DEBUG_WALKS),
        ),
        const PopupMenuItem<String>(
          value: Constants.EVENT_DEBUG,
          child: Text(Constants.MENU_PROMPT_DEBUG),
        ),
        const PopupMenuItem<String>(
          value: Constants.EVENT_SHOW_GPS_STATUS_DIALOG,
          child: Text(Constants.MENU_PROMPT_GPS_STATUS),
        ),
      ],
    );
  }

  Widget progressBar() {
    return ValueListenableBuilder(
        valueListenable: _iv.progressNotifier,
        builder: (BuildContext context, double d ,Widget? child){
          return Align(alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: LinearProgressIndicator(
                // value: animator.value,
                minHeight: 15.0,
                value: d,
                semanticsLabel: "Linear progress indicator",
              ),
            ),
          );
        }
    );
  }

  void handleDrawTapUp(TapUpDetails details) {
    final ui.Size? size = _iv.mapKey.currentContext!.size;
    if (size != null) {
      final int imageIndex = _painter.selectedImage( details.localPosition.dx.toInt(), details.localPosition.dy.toInt(), size);
      if (imageIndex >= 0) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) =>
                DisplayImage(
                  imagePaths: _iv.imagePaths,
                  index: imageIndex,
                ),
          ),
        );
      }
    }
  }

  Expanded drawByLine() {
    _iv.mapKey = GlobalKey();
    return Expanded(
      child: GestureDetector(
        onTapUp: handleDrawTapUp,
        child: Stack(
            children: <Widget>[
              CustomPaint(
                key: _iv.mapKey,
                painter: _painter,
                child: const Center(),
              ),
              if (_iv.showProgressBar)
                progressBar(),
            ]
        ),
      ),
    )
    ;
  }

  void handleMapTap(var tapPosition, LatLng latLng) {

    // Get the screen height and width - only proceed if they're available
    final ui.Size? size = _iv.mapKey.currentContext!.size;
    if (size != null) {
      final double width  = size.width;
      final double height = size.height;

      // Get the map bounds and calculate a pixel size in lat/lon
      final LatLngBounds bounds = _mapController.bounds!;
      final double dx           = (bounds.southEast.longitude - bounds.northWest.longitude).abs();
      final double dy           = (bounds.southEast.latitude - bounds.northWest.latitude).abs();
      final double pelToLon     = dx/width;
      final double pelToLat     = dy/height;

      // Set the hit rectangle - 54 pixels wide
      final double xStart = latLng.longitude - Constants.HIT_TEST_INTERVAL*pelToLon;
      final double xEnd   = latLng.longitude + Constants.HIT_TEST_INTERVAL*pelToLon;
      final double yStart = latLng.latitude - Constants.HIT_TEST_INTERVAL*pelToLat;
      final double yEnd   = latLng.latitude + Constants.HIT_TEST_INTERVAL*pelToLat;

      // Loop over the images, checking each to see if it's been selected
      int imageIndex = -1;
      for (int i = 0; i < _iv.imageMarkers.length && imageIndex < 0; i++) {
        final LatLng marker = _iv.imageMarkers[i].point;
        if (marker.latitude  >= yStart && marker.latitude  <= yEnd &&
            marker.longitude >= xStart && marker.longitude <= xEnd) {
          imageIndex = i;
        }
      }

      // If we have an image, display it (this should go through the controller)
      if (imageIndex >= 0)
      {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => DisplayImage(
              imagePaths: _iv.imagePaths,
              index: imageIndex,
            ),
          ),
        );
      }
    }

  }

// https://github.com/fleaflet/flutter_map/issues/926
  Expanded drawByMap()
  {
    _mapController = MapController();
    _iv.mapKey     = GlobalKey();
    MapOptions mapOptions;

    if (_iv.wayPoints.isNotEmpty) {
      mapOptions = MapOptions(
        initialCameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(_iv.wayPoints)),
        onTap: handleMapTap,
        // children: [
        //   LocationMarkerPlugin(),
        // ],
      );
    } else {
      if (_iv.currentPosition.latitude == -1.0 && _iv.currentPosition.longitude == -1.0) {
        _iv.currentPosition = _iv.badminton;
      }
      final CenterZoom cz = CenterZoom(center: _iv.currentPosition, zoom: _iv.zoom);
      mapOptions = MapOptions(
        initialCenter: cz.center,
        initialZoom: cz.zoom,
        onTap: handleMapTap,
        // childen: [
        //   CurrentLocationLayer(),
        // ],
      );
    }
    return
        Expanded(
          child: Stack(
            children: <Widget> [
              FlutterMap(
                key: _iv.mapKey,
                mapController: _mapController,
                options: mapOptions,
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: _iv.packageName,
                  ),
                  PolylineLayer(polylines: [
                        Polyline(
                          points: _iv.wayPoints,
                          strokeWidth: 4.0,
                          color: Colors.purple),
                      ],
                  ),
                  MarkerLayer( markers: _iv.imageMarkers),
                  MarkerLayer( markers: _iv.minuteMarkers),
                  CurrentLocationLayer(),

                  // TileLayerOptions(
                  //   minZoom: 2,
                  //   backgroundColor: Colors.black,
                  //   // errorImage: ,
                  //   urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  //   subdomains: ["a", "b", "c"],
                  // ),
                  // PolylineLayerOptions(
                  //   polylines: [
                  //     Polyline(
                  //       points: _iv.wayPoints,
                  //       strokeWidth: 4.0,
                  //       color: Colors.purple),
                  //   ],
                  // ),
                  // MarkerLayerOptions(markers: _iv.imageMarkers),
                  // MarkerLayerOptions(markers: _iv.minuteMarkers),
                  // LocationMarkerLayerOptions(),
                  // MovingMarker(markers: _markers),

                ],
              ),
              if (_iv.showProgressBar)
                progressBar(),
            ],
          ),
        )
    ;
  }

  Expanded drawImage() {
    return
        Expanded(
          child: Stack(
              children: <Widget>[
                buildImage(),
                if (_iv.showProgressBar)
                  progressBar(),
              ]
          ),
        )
    ;
  }

  Expanded mainDisplay() {
    if (_iv.showImage) {
      return drawImage();
    } else if (_iv.showMap) {
      return drawByMap();
    }
    return drawByLine();
  }

  @override
  Widget build(BuildContext context) {
    if (_iv.showBanner && _iv.isBannerAdReady) {
      _iv.bannerAdIndex = 1 - _iv.bannerAdIndex;
    }

    return Scaffold(
      key: UniqueKey(),
      appBar: AppBar(
        title: _iv.appTitle,
        actions: [
          buildMenu(context),
        ],
      ),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(5.0),
                child: const Text("Distance :"),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(5.0),
                  child: ValueListenableBuilder(
                      valueListenable: _iv.distanceNotifier,
                      builder: (BuildContext context, int d ,Widget? child){
                        return Text("$d");
                      }
                  ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(5.0),
                child: const Text("Optimum Time :"),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(5.0),
                child: Text("${_iv.optimumMinutes}:${_iv.optimumSeconds.toString().padLeft(2,'0')}"),
              ),
            ]
          ),
          mainDisplay(),
          buildButtons(),
          // *** Google Ads ***
          if (_iv.showBanner && _iv.isBannerAdReady)
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _iv.bannerAds[_iv.bannerAdIndex].size.width.toDouble(),
                height: _iv.bannerAds[_iv.bannerAdIndex].size.height.toDouble(),
                child: AdWidget(ad: _iv.bannerAds[_iv.bannerAdIndex]),
              ),
            ),
          ],
        ),
      );
  }

  void clearButtons() {
    for (int i = 0; i < _iv.buttons.length; i++) {
      _iv.buttons[i] = null;
    }
  }

  void _dismissDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> showMessage(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(Constants.PROMPT_OK),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void stopTrackingPressed(var details) {
    _stateEvent.addEventToQueue(Constants.EVENT_STOP_TRACKING_PRESSED, null);
  }

  void stopTrackingReleased(var details) {
    _stateEvent.addEventToQueue(Constants.EVENT_STOP_TRACKING_RELEASED, null);
  }

  Future<File> moveFile(File sourceFile, String newPath) async {
    try {
      // prefer using rename as it is probably faster
      return await sourceFile.rename(newPath);
    } on FileSystemException {
      // if rename fails, copy the source file and then delete it
      final File newFile = await sourceFile.copy(newPath);
      await sourceFile.delete();
      return newFile;
    }
  }

  // Future<int> uploadImage(var url, var uid, var sequence, var image, var imagePath) async {
  Future<int> uploadImage(String url, String uid, int sequence, WalkImage image, String imagePath) async {

    final http.MultipartRequest request = http.MultipartRequest("POST", Uri.parse(url));
    // request.headers.addAll({"Authorization": "Bearer token"});
    // request.headers.addAll({"UUID": uid});
    // request.headers.addAll({"WalkKey": uid});
    // request.headers.addAll({"ImageSequence": sequence.toString()});

    request.fields["WalkKey"]       = uid;
    request.fields["ImageSequence"] = sequence.toString();
    request.fields["latitude"]      = image.latitude.toString();
    request.fields["longitude"]     = image.longitude.toString();
    request.fields["distance"]      = image.distance.toString();
    request.fields["create_date"]   = image.create_date;

    request.files.add(await http.MultipartFile.fromPath("uploaded_file", imagePath, contentType: MediaType("image","png")));

    final http.StreamedResponse response  = await request.send();
    return response.statusCode;
  }

  // ------------------------ Dialog functions ---------------------------

  @override
  Future<void> showLocationSettings(var title) async {
    showDialog(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Text(Constants.REQUEST_LOCATION_PERMISSIONS_TEXT),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Settings'),
                onPressed: () {
                  _dismissDialog();
                  openAppSettings();
                },
              ),
            ],
          );
        });
  }

  @override
  void optimumTimeDialog(var param) {
    final TextEditingController optimumMinutesController = TextEditingController(text: _iv.optimumMinutes.toString());
    final TextEditingController optimumSecondsController = TextEditingController(text: _iv.optimumSeconds.toString().padLeft(2,"0"));

    showDialog(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(Constants.OPTIMUM_TIME_DIALOG_TITLE),
            content: Row(
              children: <Widget>[
            SizedBox(
              height: 45,
              width:  80,
              child: TextField(
                controller: optimumMinutesController,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: Constants.PROMPT_OPTIMUM_TIME_MINUTES,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              height: 45,
              width:  80,
              child: TextField(
                controller: optimumSecondsController,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: Constants.PROMPT_OPTIMUM_TIME_SECONDS,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            ],
          ),

            actions: <Widget>[
              TextButton(
                  onPressed: () async {
// 1) Optimum time must not be empty
// 2) Seconds must be < 60 and >=0
                    try {
                      if (optimumMinutesController.text.isEmpty || optimumSecondsController.text.isEmpty) {
                        throw Exception(Constants.ERR_OPTIMUM_TIME_INVALID);
                      }
                      final int minutes = int.parse(optimumMinutesController.text);
                      if (minutes < 0) {
                        throw Exception(Constants.ERR_OPTIMUM_TIME_MINUTES_INVALID);
                      }
                      final int seconds = int.parse(optimumSecondsController.text);
                      if (seconds < 0 || seconds > 59) {
                        throw Exception(Constants.ERR_OPTIMUM_TIME_SECONDS_INVALID);
                      }
                      _stateEvent.addEventToQueue(Constants.EVENT_SET_OPTIMUM_TIME, minutes*60 + seconds);
                      _dismissDialog();
                    } catch (err) {
                      showMessage(Constants.ERROR_DIALOG_TITLE, err.toString());
                    }
                  },
                  child: const Text(Constants.PROMPT_SET)),
              TextButton(
                onPressed: () {
                  _dismissDialog();
                },
                child: const Text(Constants.PROMPT_CANCEL),
              )
            ],
          );
        });
  }

  @override
  void gpsStatusDialog(var param) {
    showDialog(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(Constants.GPS_STATUS_DIALOG_TITLE),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget> [
                    const SizedBox(
                      height: 45,
                      width:  90,
                      child: Text("Latitude"),
                    ),
                    SizedBox(
                      height: 45,
                      width:  100,
//                      child: Text("${_iv.currentPosition.latitude.toStringAsFixed(5)}"),
                      child: Text(_iv.currentPosition.latitude.toStringAsFixed(5)),
                    ),
                  ],
                ),
                Row(
                  children: <Widget> [
                    const SizedBox(
                      height: 45,
                      width:  90,
                      child: Text("Longitude"),
                    ),
                    SizedBox(
                      height: 45,
                      width:  100,
                      child: Text(_iv.currentPosition.longitude.toStringAsFixed(5)),
                    ),
                  ],
                ),
                Row(
                  children: <Widget> [
                    const SizedBox(
                      height: 45,
                      width:  90,
                      child: Text("State"),
                    ),
                    SizedBox(
                      height: 45,
                      width:  100,
                      child: Text(_stateEvent.state),
                    ),
                  ],
                ),
                Row(
                  children: <Widget> [
                    const SizedBox(
                      height: 45,
                      width:  90,
                      child: Text("Walk"),
                    ),
                    SizedBox(
                      height: 45,
                      width:  100,
                      child: Text(Constants.WALK_UPLOAD_URL),
                    ),
                  ],
                ),
                Row(
                  children: <Widget> [
                    const SizedBox(
                      height: 45,
                      width:  90,
                      child: Text("Image"),
                    ),
                    SizedBox(
                      height: 45,
                      width:  100,
                      child: Text(Constants.IMAGE_UPLOAD_URL),
                    ),
                  ],
                ),
              ],
            ),

            actions: <Widget>[
              TextButton(
                onPressed: () {
                  _dismissDialog();
                },
                child: const Text(Constants.PROMPT_CANCEL),
              )
            ],
          );
        });
  }

  @override
  Future<void> uploadWalkDialog(var param) async {
    final TextEditingController walkCountryController = TextEditingController(text: _iv.uploadWalkCountry);
    final TextEditingController walkNameController    = TextEditingController(text: _iv.uploadWalkName);
    final TextEditingController walkUserController    = TextEditingController(text: _iv.uploadWalkUser);
    final TextEditingController walkEmailController   = TextEditingController(text: _iv.uploadWalkEmail);
    final TextEditingController walkClassController   = TextEditingController(text: _iv.uploadWalkClass);

    // if (await ConnectivityUtils.hasConnection()) {
    if (await hasConnection()) {
      showDialog(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(Constants.UPLOAD_WALK_DIALOG_TITLE),
              scrollable: true,
              content: Container(
                constraints: const BoxConstraints(
                    maxWidth: 300, maxHeight: 300),
                // padding: const EdgeInsets.all(0),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Row(
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                          width: 200,
                          child: TextFormField(
                            controller: walkUserController,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.fromLTRB(
                                  12.0, 8.0, 12.0, 8.0),
                              labelText: Constants.PROMPT_UPLOAD_WALK_USER,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                          width: 200,
                          child: TextFormField(
                            controller: walkEmailController,
                            textAlignVertical: TextAlignVertical.center,
                            // validator: (val) => val!.isEmpty ? Constants.PROMPT_UPLOAD_WALK_EMAIL : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.fromLTRB(
                                  12.0, 8.0, 12.0, 8.0),
                              labelText: Constants.PROMPT_UPLOAD_WALK_EMAIL,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                          width: 200,
                          child: TextFormField(
                            controller: walkCountryController,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.fromLTRB(
                                  12.0, 8.0, 12.0, 8.0),
                              labelText: Constants.PROMPT_UPLOAD_WALK_COUNTRY,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                          width: 200,
                          child: TextFormField(
                            controller: walkNameController,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.fromLTRB(
                                  12.0, 8.0, 12.0, 8.0),
                              labelText: Constants.PROMPT_UPLOAD_WALK_NAME,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                          width: 200,
                          child: TextField(
                            controller: walkClassController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.fromLTRB(
                                  12.0, 8.0, 12.0, 8.0),
                              labelText: Constants.PROMPT_UPLOAD_WALK_CLASS,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              actions: <Widget>[
                TextButton(
                    onPressed: () async {
                      try {
                        if (walkNameController.text.isEmpty ||
                            walkUserController.text.isEmpty) {
                          throw Exception(Constants.ERR_WALK_NAME_AND_USER_MUST_BE_SET);
                        }
                        _iv.uploadWalkUser    = walkUserController.text;
                        _iv.uploadWalkEmail   = walkEmailController.text;
                        _iv.uploadWalkCountry = walkCountryController.text;
                        _iv.uploadWalkName    = walkNameController.text;
                        _iv.uploadWalkClass   = walkClassController.text;
                        _dismissDialog();
                        _stateEvent.addEventToQueue(Constants.EVENT_UPLOAD_WALK, "");
                      } catch (err) {
                        showMessage(
                            Constants.ERROR_DIALOG_TITLE, err.toString());
                      }
                    },
                    child: const Text(Constants.PROMPT_SET)),
                TextButton(
                  onPressed: () {
                    _dismissDialog();
                  },
                  child: const Text(Constants.PROMPT_CANCEL),
                )
              ],
            );
          });
    } else {
      showMessage(Constants.ERROR_DIALOG_TITLE, Constants.ERR_NO_CONNECTIVITY);
    }
  }

  @override
  Future<void> loginDialog() async {
    final String password = "";
    final TextEditingController usernameController = TextEditingController(text: _iv.uploadWalkUser);
    final TextEditingController passwordController = TextEditingController(text: password);

    // if (await ConnectivityUtils.hasConnection()) {
    if (await hasConnection()) {
      showDialog(
          context: context,
          barrierDismissible: false, // user must tap button!
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(Constants.UPLOAD_WALK_DIALOG_TITLE),
              scrollable: true,
              content: Container(
                constraints: const BoxConstraints(
                    maxWidth: 300, maxHeight: 300),
                // padding: const EdgeInsets.all(0),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Row(
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                          width: 200,
                          child: TextFormField(
                            controller: usernameController,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.fromLTRB(
                                  12.0, 8.0, 12.0, 8.0),
                              labelText: Constants.PROMPT_UPLOAD_WALK_USER,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        SizedBox(
                          height: 45,
                          width: 200,
                          child: TextFormField(
                            controller: passwordController,
                            textAlignVertical: TextAlignVertical.center,
                            // validator: (val) => val!.isEmpty ? Constants.PROMPT_UPLOAD_WALK_EMAIL : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.fromLTRB(
                                  12.0, 8.0, 12.0, 8.0),
                              labelText: Constants.PROMPT_UPLOAD_WALK_EMAIL,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                                  ],
                ),
              ),

              actions: <Widget>[
                TextButton(
                    onPressed: () async {
                      try {
                        if (usernameController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          throw Exception(Constants.ERR_USERNAME_AND_PASSWORD_MUST_BE_SPECIFIED);
                        }
                      //   _iv.uploadWalkUser    = walkUserController.text;
                      //   _iv.uploadWalkEmail   = walkEmailController.text;
                      //   _iv.uploadWalkCountry = walkCountryController.text;
                      //   _iv.uploadWalkName    = walkNameController.text;
                      //   _iv.uploadWalkClass   = walkClassController.text;
                      //   _dismissDialog();
                      //   _stateEvent.addEventToQueue(Constants.EVENT_UPLOAD_WALK, "");
                      } catch (err) {
                        showMessage(
                            Constants.ERROR_DIALOG_TITLE, err.toString());
                      }
                    },
                    child: const Text(Constants.PROMPT_SET)),
                TextButton(
                  onPressed: () {
                    _dismissDialog();
                  },
                  child: const Text(Constants.PROMPT_CANCEL),
                )
              ],
            );
          });
    } else {
      showMessage(Constants.ERROR_DIALOG_TITLE, Constants.ERR_NO_CONNECTIVITY);
    }
  }

  // ------------------------ State event functions ---------------------------
  @override
  Future<void> startService(var param) async
  {
    try {
      GpsTracker.addGpsListener(_listener);
      await GpsTracker.start(
        title: _iv.title,
        text: "Text",
        subText: "Subtext",
        ticker: "Ticker",
      );
    } catch (err) {
      showMessage(Constants.ERROR_DIALOG_TITLE, err.toString());
    }
  }

  @override
  Future<void> stopService(var param) async
  {
    GpsTracker.removeGpsListener(_listener);
    GpsTracker.stop();
  }

  @override
  void displayWalksWindow(var param) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) => WalkWindow(currentWalkName: _iv.walkName)),
    ).then((result) {
      if ((result as String).isNotEmpty) {
        _stateEvent.addEventToQueue(Constants.EVENT_LOAD_WALK, result);
      }
    });
  }

  @override
  void displayGallery(var param) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) => DisplayGallery(imagePaths: _iv.imagePaths)),
    );
  }

  @override
  Future<void> uploadWalk(var param) async {
    late BuildContext dialogContext; // <<----
    showDialog(
      context: context, // <<----
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return Dialog(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              Text("Loading"),
            ],
          ),
        );
      },
    );
    final UploadResults results = await doWalkUpload(param);
    // Navigator.of(dialogContext, rootNavigator: true).pop();
    Navigator.pop(dialogContext);

    if (results.status == 200) {
      showMessage(Constants.INFORMATION_DIALOG_TITLE, Constants.INFO_WALK_UPLOADED_OK);
    } else {
      if (results.message == null || results.message!.isEmpty) {
        showMessage(Constants.ERROR_DIALOG_TITLE, Constants.ERR_CANT_UPLOAD_WALK);
      } else {
        String errm = "${results.message!} - status ${results.status}";
        showMessage(Constants.ERROR_DIALOG_TITLE, errm);
      }
    }
  }

  // For HTTPS:
  // https://mtabishk999.medium.com/tls-ssl-connection-using-self-signed-certificates-with-dart-and-flutter-6e7c46ea1a36
  @override
  Future<UploadResults> doWalkUpload(var param) async {

    late UploadResults results;

    // Get the current walk
    final Walk walk  = await _iv.db.getWalk(_iv.walkName);
    const Uuid uuid  = Uuid();
    final String uid = uuid.v1(); // Generate a v1 (time-based) id

    final String json = '{"device_uuid": "${_iv.deviceUuid}","name": "${_iv.uploadWalkName}", "year": ${DateFormat("yyyy").format(DateTime.now())}, "country": "${_iv.uploadWalkCountry}", "user": "${_iv.uploadWalkUser}","email": "${_iv.uploadWalkEmail}", "class": "${_iv.uploadWalkClass}","uuid": "$uid", "walk":${walk.toJson()}}';

    const String url                = Constants.WALK_UPLOAD_URL;
    final HttpClient httpClient     = HttpClient();
    final HttpClientRequest request = await httpClient.postUrl(Uri.parse(url));
    // request.headers.set('content-type', 'application/json; charset="UTF-8"');
    request.headers.set("content-type", 'text/html; charset="UTF-8"');
    // request.add(utf8.encode(json));
    request.write(utf8.encode(json));
    // request.write(json);
    final HttpClientResponse response = await request.close();
    // todo - you should check the response.statusCode
    int status = response.statusCode;
    final String reply = await response.transform(utf8.decoder).join();
    results = UploadResults(status,reply);
    httpClient.close();

    // Upload the images
    if (status == 200) {
      const String imageUrl = Constants.IMAGE_UPLOAD_URL;
      for (int i = 0; i < walk.images.length && status == 200; i++) {
        status = await uploadImage(imageUrl, uid, i, walk.images[i], _iv.imagePaths[i]);
      }
    }
    results.status = status;

    // Write the uploaded walk name and user to the preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.UPLOAD_WALK_NAME_KEY,_iv.uploadWalkName);
    await prefs.setString(Constants.UPLOAD_WALK_COUNTRY_KEY,_iv.uploadWalkCountry);
    await prefs.setString(Constants.UPLOAD_WALK_USER_KEY,_iv.uploadWalkUser);
    await prefs.setString(Constants.UPLOAD_WALK_EMAIL_KEY,_iv.uploadWalkEmail);
    await prefs.setString(Constants.UPLOAD_WALK_CLASS_KEY,_iv.uploadWalkClass);
    return results;
  }

  @override
  void clearWalkPoints(var param) {
    _iv.imagePaths.clear();
    _iv.wayPoints.clear();
    // markers.clear();
    _iv.imageMarkers.clear();
    _iv.minuteMarkers.clear();
    _painter.clearWalkTrack();
    _repaint.notifyListeners();
    _iv.distanceNotifier.value = 0;
    _iv.optimumMinutes         = 0;
    _iv.optimumSeconds         = 0;
  }

  @override
  void clearDisplay(var param) {
    _iv.clearDisplayEnabled = false;
    setState(() {
      _iv.walkName               = "";
      _iv.distanceNotifier.value = 0;
      _iv.optimumMinutes         = 0;
      _iv.optimumSeconds         = 0;
      _iv.showImage              = !_iv.showMap;
      _iv.appTitle               = Text(_iv.title);
    });
  }

  @override
  void addCoordsToMap(Map<Object?,Object?> map) {

    try {
      // var fix_valid = map["fix_valid"] as bool;
      // var walkName  = map["walk_name"];
      final latitude = map["latitude"]! as double;
      final longitude = map["longitude"]! as double;
      // var accuracy  = map["accuracy"] as double;
      // var speed     = map["speed"] as double;
      final distance = map["distance"]! as double;
      final LatLng point = LatLng(latitude, longitude);
      // ------------------ Here I am ------------------
      _iv.wayPoints.add(point);
      // ------------------ Here I am ------------------
      _iv.distanceNotifier.value = distance.toInt();

      if (_iv.showMap) {
        final LatLngBounds bounds = LatLngBounds.fromPoints(_iv.wayPoints);
        final CenterZoom cz = _mapController.centerZoomFitBounds(bounds);
        _mapController.move(cz.center, cz.zoom);
      }

      _painter.addWalkTrackPoint(
          WalkTrackPoint(
              create_date: DateFormat("dd-MM-yyyyTHH:mm:ss").format(
                  DateTime.now()),
              latitude: map["latitude"]! as double,
              longitude: map["longitude"]! as double,
              distance: map["distance"]! as double,
              provider: "gps",
              accuracy: map["accuracy"]! as double,
              elapsed_time: 0)
      );
      if (!_iv.showMap) {
        _repaint.notifyListeners();
      }
    } catch (e) {
      writeFile("log.txt","Exception $e");
    }
  }

  @override
  void  centreDisplay(var param) {
    if (_iv.showMap) {
      setState(() {
        _iv.showImage = !(_iv.showMap || _iv.walkName != "");
      });
    } else {
      _repaint.notifyListeners();
    }
  }

  @override
  void moveMap(Map<Object?,Object?> map) {
    if (_iv.showMap) {
      // var fixValid  = map["fix_valid"] as bool;
      // var walkName  = map["walk_name"];
      final double latitude  = map["latitude"]! as double;
      final double longitude = map["longitude"]! as double;
      // var accuracy  = map["accuracy"] as double;
      // var speed     = map["speed"] as double;
      // var distance  = map["distance"];
      final LatLng point = LatLng(latitude, longitude);
      _mapController.move(point, _iv.zoom);
    }
  }

  @override
  void initialFixReceived(var param) {
    Timer(
      const Duration(seconds: Constants.FIX_SETTLE_TIMEOUT_SECONDS),
          () {_stateEvent.addEventToQueue(Constants.EVENT_FIX_SETTLE_TIMEOUT, null);},
    );
  }

  @override
  Future<void> loadWalk(var param) async {

    final Walk walk = await _iv.db.getWalk(param);
    for (final WalkTrackPoint wtp in walk.track) {
      _iv.wayPoints.add(LatLng(wtp.latitude, wtp.longitude));
    }
    _painter.addWalkTrackPoints(walk.track);
    _painter.addWalkImages(walk.images);
    _painter.addWalkMinuteMarkers(walk.waypoints);

    String localPath = "";
    if (Platform.isAndroid) {
      final Directory? a = await getExternalStorageDirectory();  // OR return "/storage/emulated/0/Download";
      localPath = a!.path  + Platform.pathSeparator;
    } else if (Platform.isIOS) {
      final Directory d = await getApplicationDocumentsDirectory();
      localPath = d.path;
    }

    for (final WalkImage walkImage in walk.images) {
      _iv.imagePaths.add(localPath + walkImage.image_name);
      _iv.imageMarkers.add(
          Marker(
            point: LatLng(walkImage.latitude,walkImage.longitude),
            child: const Icon(Icons.circle,
                size: 20,
                color: Colors.blueAccent),
          ),
      );
    }

    for (final WalkWaypoint point in walk.waypoints) {
      _iv.minuteMarkers.add(
        Marker(
          point: LatLng(point.latitude,point.longitude),
          child: const Icon(Icons.close,
              size: 20,
              color: Colors.redAccent),
        ),

      );
    }

    setState(() {
      _iv.walkName       = param;
      _iv.optimumMinutes = walk.optimum_minutes;
      _iv.optimumSeconds = walk.optimum_seconds;
      _iv.showImage      = false;
      _iv.appTitle       = Text("${_iv.title} - $param");
      if (walk.track.isNotEmpty) {
        _iv.distanceNotifier.value = walk.track[walk.track.length - 1].distance.toInt();
      } else {
        _iv.distanceNotifier.value = 0;
      }
      _iv.clearDisplayEnabled = true;
      if (_iv.imagePaths.isNotEmpty) {
        _iv.galleryEnabled = true;
      } else {
        _iv.galleryEnabled = false;
      }
    });
    _stateEvent.addEventToQueue(Constants.EVENT_WALK_LOADED, null);
  }

  @override
  void storePosition(Map<Object?, Object?> map) {
    final double latitude  = map["latitude"]! as double;
    final double longitude = map["longitude"]! as double;
    _iv.currentPosition = LatLng(latitude,longitude);
  }

  @override
  void toggleMaps(var param) {
    _iv.showMap = !_iv.showMap;
    if (!_iv.showMap) {
      setState(() {
        _iv.showImage = _iv.walkName.isEmpty;
      });
    }
  }

  @override
  Future<void> takePhoto (var param) async {
    var status = await Permission.camera.status;
    var status1 = await Permission.microphone.status;

    if (status == PermissionStatus.denied) {
      status = await Permission.camera.request();
    }
    if (status1 == PermissionStatus.denied) {
      status1 = await Permission.microphone.request();
    }
    if (status == PermissionStatus.granted) {
      // Obtain a list of the available cameras on the device.
      availableCameras().then((List<CameraDescription> cameras) {

        final CameraDescription firstCamera = cameras
            .first; // Use the first available camera

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) => Photo(camera: firstCamera),
          ),
        ).then((result) {
          if ((result as String).isNotEmpty) {
            final List<Object> param = [];
            GpsTracker.getLocation()!.then((Float64List location) {
              param.add(LatLng(location[0], location[1]));
              param.add(result);
              _stateEvent.addEventToQueue(Constants.EVENT_PHOTO_TAKEN, param);
            });
          }
        });
      });
    }
  }

  @override
  Future<void> photoTaken (List<Object?> param) async {
    final lat = (param[0]! as LatLng).latitude;
    final lon = (param[0]! as LatLng).longitude;
    final imagePath = param[1]! as String;

    String imageRelativePath = "";
    if (Platform.isAndroid) {
      final Directory? a = await getExternalStorageDirectory();  // OR return "/storage/emulated/0/Download";
      final String androidPath = a!.path;
      final List<String> pathComponents = imagePath.split(Platform.pathSeparator);
      imageRelativePath = Platform.pathSeparator + pathComponents[pathComponents.length - 1];
      await moveFile(File(imagePath),androidPath + imageRelativePath);
    } else if (Platform.isIOS) {
      final Directory d = await getApplicationDocumentsDirectory();
      imageRelativePath = imagePath.substring(d.path.length);
    }
    final double distance = await GpsTracker.getDistance();
    final String walkName = await GpsTracker.getWalkName();
    final WalkImage wi = WalkImage(
        image_name: imageRelativePath,
        create_date: DateFormat("dd-MM-yyyyTHH:mm:ss").format( DateTime.now()),
        latitude: lat,
        longitude: lon,
        distance: distance);
    final List<WalkImage> images = [
      wi
    ];
    await _iv.db.addWalkImages(walkName, images);
    _painter.addWalkTrackImage(wi);

    _iv.imagePaths.add(imagePath);
    _iv.imageMarkers.add(
      Marker(
        point: LatLng(lat, lon),
        child: const Icon(Icons.circle,
            size: 20,
            color: Colors.blueAccent),
      ),
    );

  }

  @override
  void setReadyToTrack(var param) {
    setState(() {
      clearButtons();
      _iv.buttons[0] = simpleButton(Constants.PROMPT_START_TRACKING, () {
        _stateEvent.addEventToQueue(Constants.EVENT_START_TRACKING, null);
      });
    });
  }

  @override
  Future<void> startTracking(var param) async {
    final DateTime now = DateTime.now();
    final String walkName = "Walk on ${DateFormat("yyyy-MM-dd HH:mm:ss").format(now)}";
    try {
      await _iv.db.addWalk(walkName);

      GpsTracker.startTracking(walkName);

      setState(() {
        _iv.appTitle  = Text(walkName);
        _iv.walkName  = walkName;
        _iv.showImage = false;
        clearButtons();
        _iv.buttons[0] = simpleButton(Constants.PROMPT_PAUSE, () {
          _stateEvent.addEventToQueue(Constants.EVENT_PAUSE_TRACKING, null);
        });
        _iv.buttons[2] = simpleButton(Constants.PROMPT_CAMERA, () {
          _stateEvent.addEventToQueue(Constants.EVENT_SHOW_CAMERA, null);
        });
      });
      _stateEvent.addEventToQueue(Constants.EVENT_WALK_LOADED, null);
    } catch (err) {
    //   print("Error $err adding walk '$walkName'");
    }
  }

  @override
  void pauseTracking(var param)
  {
    GpsTracker.pauseTracking();
    setState(() {
      clearButtons();
      _iv.buttons[0] = simpleButton(Constants.PROMPT_RESUME, () {
        _stateEvent.addEventToQueue(Constants.EVENT_RESUME_TRACKING,null);
      });
      _iv.buttons[1] = listenerButton(Constants.PROMPT_STOP_TRACKING, stopTrackingPressed, stopTrackingReleased);
    });
  }

  @override
  void resumeTracking(var param)
  {
    GpsTracker.resumeTracking();
    setState(() {
      clearButtons();
      _iv.buttons[0] = simpleButton(Constants.PROMPT_PAUSE, () {
        _stateEvent.addEventToQueue(Constants.EVENT_PAUSE_TRACKING,null);
      });
      _iv.buttons[2] = simpleButton(Constants.PROMPT_CAMERA, () {
        _stateEvent.addEventToQueue(Constants.EVENT_SHOW_CAMERA,null);
      });
    });
  }

  @override
  void stopTrackingPressedAction(var param) {
    const double delay = 3000.0;
    const int    tick  = 10;
    _iv.progressNotifier.value = 0.0;
    _iv.timer = Timer.periodic(
        const Duration(milliseconds: tick), (Timer timer) {
        if (_iv.progressNotifier.value >= 1.0) {
          _stateEvent.addEventToQueue(Constants.EVENT_STOP_TRACKING_TIMEOUT, null);
        } else {
          _iv.progressNotifier.value += tick/delay;
        }
    });

    setState(() {
      _iv.showProgressBar = true;
    });
  }

  @override
  void trackingStillPaused(var param) {
    _iv.timer?.cancel();

    setState(() {
      clearButtons();
      _iv.buttons[0] = simpleButton(Constants.PROMPT_RESUME, () {
        _stateEvent.addEventToQueue(Constants.EVENT_RESUME_TRACKING,null);
      });
      _iv.buttons[1] = listenerButton(Constants.PROMPT_STOP_TRACKING, stopTrackingPressed, stopTrackingReleased);
      _iv.showProgressBar = false;
    });
  }

  @override
  void trackingStopped(var param) {
    setState(() {
      clearButtons();
      _iv.timer?.cancel();
      _iv.showProgressBar = false;
      _iv.buttons[0] = simpleButton(Constants.PROMPT_START_TRACKING, () {
        _stateEvent.addEventToQueue(Constants.EVENT_START_TRACKING,null);
      });
    });
    GpsTracker.stopTracking();
  }

  @override
  void trackingStoppedAsPermissionRevoked(var param) {
    setState(() {
      clearButtons();
      _iv.timer?.cancel();
      _iv.showProgressBar = false;
      _iv.buttons[0] = simpleButton(Constants.PROMPT_AWAIT_GPS, null);
    });
    GpsTracker.stopTracking();
  }

  @override
  void permissionRevoked(var param) {
    setState(() {
      clearButtons();
      _iv.buttons[0] = simpleButton(Constants.PROMPT_AWAIT_GPS, null);
    });
    GpsTracker.stopTracking();
  }

  @override
  void actOnPermissions(var permission) {
    String event = "";
    switch (permission) {
      case GpsTracker.GRANTED:
        event = Constants.EVENT_LOCATION_GRANTED;
        break;
      case GpsTracker.DENIED:
        event = Constants.EVENT_LOCATION_NOT_YET_GRANTED;
        break;
      case GpsTracker.LOCATION_OFF:
      case GpsTracker.INACCURATE_LOCATION:
      case GpsTracker.PARTLY_DENIED:
      case GpsTracker.PERMANENTLY_DENIED:
        event = Constants.EVENT_LOCATION_DENIED;
        break;
    }
    _stateEvent.addEventToQueue(event, permission);
  }

  @override
  Future<void> checkLocationPermissions(var param) async {
    int permission = await GpsTracker.getCurrentLocationPermissions();
    actOnPermissions(permission);
  }

  @override
  Future<void> requestLocationPermissions(var param) async {
    int permission = await GpsTracker.requestLocationPermissions();
    actOnPermissions(permission);
  }

  @override
  Future<void> showLocationSettingsBeforeGranted(var param) async {
    await showLocationSettings(Constants.REQUEST_LOCATION_PERMISSIONS_BEFORE_GRANTED_TITLE);
  }

  @override
  Future<void> showLocationSettingsWhenTracking(var param) async {
    await showLocationSettings(Constants.REQUEST_LOCATION_PERMISSIONS_WHEN_TRACKING_TITLE);
  }

  @override
  Future<void> showLocationSettingsAfterGranted(var param) async {
    await showLocationSettings(Constants.REQUEST_LOCATION_PERMISSIONS_AFTER_GRANTED_TITLE);
  }

}

// class ConnectivityUtils {
// static Future<bool> hasConnection() async {
Future<bool> hasConnection() async {
    final ConnectivityResult connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi;
  }
// }
