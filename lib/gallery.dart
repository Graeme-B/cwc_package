import "dart:io";
import "package:flutter/material.dart";
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// https://stackoverflow.com/questions/59254256/arrange-the-images-loaded-from-api-into-two-columns-in-flutter-using-listtile
class DisplayGallery extends StatelessWidget {

  const DisplayGallery({Key? key, required this.imagePaths})
      : super(key: key);
  final List<String> imagePaths;

  List<Widget> getChildren(var context, var imagePaths) {
    final List<Card> images = [];
    for (int i = 0; i < imagePaths.length; i++) {
      final image = imagePaths[i];

      images.add(
        Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(5.0))),
          child:
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DisplayImage(
                    imagePaths: imagePaths,
                    index: i,
                  ),
                ),
              );
            },
            child:
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                border: Border.all(),
                image: DecorationImage(
                    image: FileImage(File(image)),
                    fit: BoxFit.cover
                ),
              ),
            ),
          ),
        ),
      );

      // images.add(
      //   Card(
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.all(Radius.circular(5.0))),
      //     child: Container(
      //       decoration: BoxDecoration(
      //         borderRadius: BorderRadius.all(Radius.circular(5.0)),
      //         image: DecorationImage(
      //           image: new FileImage(File(image)),
      //           fit: BoxFit.cover),
      //       ),
      //     ),
      //   ),
      // );

      // images.add(
      //     Center(
      //       child:
      //       GestureDetector(
      //           onTap: () {
      //             print("onTap index $i image $image");
      //             Navigator.of(context).push(
      //               MaterialPageRoute(
      //                 builder: (context) => DisplayImage2(
      //                   imagePaths: imagePaths,
      //                   index: i,
      //                 ),
      //               ),
      //             );
      //           },
      //           child:
      //             shape: RoundedRectangleBorder(
      //                 borderRadius: BorderRadius.all(Radius.circular(5.0))),
      //             child: Container(
      //               decoration: BoxDecoration(
      //                 borderRadius: BorderRadius.all(Radius.circular(5.0)),
      //                 image: DecorationImage(
      //                   Image.file(File(imagePaths[i]))
      //                   image: NetworkImage(imagePaths[index]),
      //                   fit: BoxFit.cover),
      //               ),
      //             ),
    }

    return images;
  }

  @override
  Widget build(BuildContext context) {
    const title = "Gallery";

    return Scaffold(
      appBar: AppBar(
        title: const Text(title),
      ),
      body:Container(
        color: Colors.white,
        child:
        GridView.count(
          // Create a grid with 2 columns. If you change the scrollDirection to
          // horizontal, this produces 2 rows.
          crossAxisCount: 2,
          padding: const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
          // Generate 100 widgets that display their index in the List.
          children:
          getChildren(context,imagePaths),
        ),

        // body: StaggeredGridView.countBuilder(
        //   crossAxisCount: 4,
        //   itemCount: imagePaths.length,
        //   itemBuilder: (BuildContext context, int index) => new Card(
        //     elevation: 5.0,
        //     shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.all(Radius.circular(5.0))),
        //     child: Container(
        //       decoration: BoxDecoration(
        //         borderRadius: BorderRadius.all(Radius.circular(5.0)),
        //         image: DecorationImage(
        //             image: NetworkImage(imagePaths[index]),
        //             fit: BoxFit.cover),
        //       ),
        //     ),
        //   ),
        //   staggeredTileBuilder: (int index) =>
        //   new StaggeredTile.count(2, index.isEven ? 2 : 1.5),
        //   mainAxisSpacing: 4.0,
        //   crossAxisSpacing: 4.0,
        // ),

      ),
    );
  }
}



class DisplayImage extends StatefulWidget {

  const DisplayImage({Key? key, required this.imagePaths, required this.index})
      : super(key: key);

  final imagePaths;
  final index;

  @override
  DisplayImageState createState() => DisplayImageState(index,imagePaths);
}

class DisplayImageState extends State<DisplayImage> {

  DisplayImageState(this.index,this.imagePaths);
  late var imagePaths;
  late var index;
  bool swipeLeft = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gallery")),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.zero,
            child: GestureDetector(
              onPanEnd: (details) {
                if (swipeLeft && index < imagePaths.length - 1) {
                  setState(() {
                    index += 1;
                  });
                }
                if (!swipeLeft && index > 0) {
                  setState(() {
                    index -= 1;
                  });
                }
              },
              onPanUpdate: (details) {
                if (details.delta.dx < 0) {
                  swipeLeft = true;
                } else if (details.delta.dx > 0) {
                  swipeLeft = false;
                }
              },
              child: Image.file(
                File(imagePaths[index]),
                fit: BoxFit.fitWidth,
              )
          ),
          ),
          if (index < imagePaths.length - 1)
            Positioned(
              right: 0.0,
              bottom: 0.0,
              child: FloatingActionButton(
                heroTag: "rightButton",
                backgroundColor: Colors.green.shade800,
                // onPressed: () {print("Scroll right");},
                onPressed: () {
                  setState(() {
                    index += 1;
                  });
                },
                child: const Icon(Icons.keyboard_arrow_right_outlined),
              ),
            ),
          if (index > 0)
            Positioned(
              left: 0.0,
              bottom: 0.0,
              child: FloatingActionButton(
                heroTag: "leftButton",
                backgroundColor: Colors.green.shade800,
                // onPressed: () {print("Scroll left");},
                onPressed: () {
                  setState(() {
                    index -= 1;
                  });
                },
                child: const Icon(Icons.keyboard_arrow_left_outlined),
              ),
            ),
        ],
      ),
    );
  }
}
