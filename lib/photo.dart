import "dart:io";

import "package:camera/camera.dart";
import "package:flutter/material.dart";
import "constants.dart";

// https://docs.flutter.dev/cookbook/plugins/picture-using-camera

// A screen that allows users to take a picture using a given camera.
class Photo extends StatefulWidget {
  const Photo({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  PhotoState createState() => PhotoState();
}

class PhotoState extends State<Photo> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late var imagePath;
  static const SHOW_CAMERA = "camera";
  static const SHOW_IMAGE  = "image";
  var          showWhat    = SHOW_CAMERA;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (showWhat == SHOW_CAMERA) {
      return showCamera();
    }
    return showImage();
  }

  Scaffold showCamera() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.PHOTO_WINDOW_TITLE),
      ),

      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();
            setState((){
              imagePath = image.path;
              showWhat = SHOW_IMAGE;
            });

            // // If the picture was taken, display it on a new screen.
            // await Navigator.of(context).push(
            //   MaterialPageRoute(
            //     builder: (context) => DisplayImage2(
            //       // Pass the automatically generated path to
            //       // the DisplayPictureScreen widget.
            //       imagePath: image.path,
            //     ),
            //   ),
            // );

          } catch (e) {
            // If an error occurs, log the error to the console.
            // print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Scaffold showImage() {
    return Scaffold(
      appBar: AppBar(title: const Text(Constants.PHOTO_PREVIEW_TITLE)),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Stack(
        children: <Widget>[
          Container(
              padding: EdgeInsets.zero,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.fitWidth,
              )
          ),
          Positioned(
            left: 0.0,
            bottom: 0.0,
            child: FloatingActionButton(
              heroTag: "acceptButton",
              backgroundColor: Colors.green.shade800,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(imagePath);
              },
              child: const Icon(Icons.check_circle),
            ),
          ),
          Positioned(
            right: 0.0,
            bottom: 0.0,
            child: FloatingActionButton(
              heroTag: "cancelButton",
              backgroundColor: Colors.green.shade800,
              onPressed: () {
                File(imagePath).delete();
                setState((){
                  showWhat = SHOW_CAMERA;
                });
              },
              child: const Icon(Icons.cancel),
            ),
          ),
        ],
      ),
    );
  }
}
