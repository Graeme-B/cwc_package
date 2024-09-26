import "dart:ui" as ui;
import "package:flutter/material.dart";

class ImageEditor extends CustomPainter {

  ImageEditor({
    required this.portraitImage, required this.landscapeImage
  });

  ui.Image landscapeImage;
  ui.Image portraitImage;

  @override
  void paint(Canvas canvas, Size size) {
    final imageAR  = portraitImage.height/portraitImage.width;
    final screenAR = size.height/size.width;
    if (imageAR < screenAR) {
      final adjustment = size.width/portraitImage.width;
      final newHeight = adjustment*portraitImage.height;
      final offsetY = (size.height/2 - newHeight/2)/adjustment;
      canvas.scale(adjustment);
      canvas.drawImage(portraitImage, Offset(0.0, offsetY), Paint());
    } else {
      final adjustment = size.height/landscapeImage.height;
      final newWidth = adjustment*landscapeImage.width;
      final offsetX = (size.width/2 - newWidth/2)/adjustment;
      canvas.scale(adjustment);
      canvas.drawImage(landscapeImage, Offset(offsetX, 0.0), Paint());
    }

    // Rect rect = Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height));
    // LinearGradient lg = LinearGradient(
    //     begin: Alignment.topCenter,
    //     end: Alignment.bottomCenter,
    //     colors: [
    //       //create 2 white colors, one transparent
    //       Color.fromARGB(0, 255, 255, 255),
    //       Color.fromARGB(255, 255, 255, 255)
    //     ]);
    // Paint paint = Paint()..shader = lg.createShader(rect);
    // canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

}
