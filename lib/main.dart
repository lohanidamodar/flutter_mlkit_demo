import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(
      MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: FacePage(),
      ),
    );

class FacePage extends StatefulWidget {
  @override
  _FacePageState createState() => _FacePageState();
}

class _FacePageState extends State<FacePage> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false;
  ui.Image _image;

  _getImageAndDetectFaces() async {
    final imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      isLoading = true;
    });
    final image = FirebaseVisionImage.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(image);
    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _loadImage(imageFile);
      });
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image = value;
        isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : (_imageFile == null)
              ? Center(child: Text('No image selected'))
              : Center(
                  child: FittedBox(
                    child: SizedBox(
                      width: _image.width.toDouble(),
                      height: _image.height.toDouble(),
                      child: CustomPaint(
                        painter: SmilePainter(_image, _faces),
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImageAndDetectFaces,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

class SmilePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;

  SmilePainter(this.image, this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      canvas.drawImage(image, Offset.zero, Paint());
    }

    final paintRectStyle = Paint()
      ..color = Colors.red
      ..strokeWidth = 0.0
      ..style = PaintingStyle.stroke;

    //Draw Body
    final paint = Paint()..color = Colors.yellow;

    for (var i = 0; i < faces.length; i++) {
      final radius =
          Math.min(faces[i].boundingBox.width, faces[i].boundingBox.height) / 2;
      final center = faces[i].boundingBox.center;
      final smilePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius / 8;
      canvas.drawCircle(center, radius, paint);
      canvas.drawArc(
          Rect.fromCircle(
              center: center.translate(0, radius / 8), radius: radius / 2),
          0,
          Math.pi,
          false,
          smilePaint);
      //Draw the eyes
      canvas.drawCircle(Offset(center.dx - radius / 2, center.dy - radius / 2),
          radius / 8, Paint());
      canvas.drawCircle(Offset(center.dx + radius / 2, center.dy - radius / 2),
          radius / 8, Paint());
    }
  }

  @override
  bool shouldRepaint(SmilePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}