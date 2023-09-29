import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';

late List<CameraDescription> _cameras;

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  String? filePath;
  String? result;

  CameraController? controller;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    initCamera();
  }

  void initCamera() async {
    _cameras = await availableCameras();

    controller = CameraController(_cameras[0], ResolutionPreset.low);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });

    timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      var imageCamera = await controller?.takePicture();

      filePath = imageCamera?.path;

      if (filePath != null) {
        mlProcess();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Labeling'),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 4,
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(15),
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(border: Border.all()),
                  child: controller == null
                      ? Icon(Icons.camera)
                      : CameraPreview(controller!),
                ),
              )),
          Expanded(
              flex: 1,
              child: ElevatedButton(
                  onPressed: pickImage, child: Text('Pick Image'))),
          Expanded(
              flex: 1,
              child:
                  ElevatedButton(onPressed: mlProcess, child: Text('Process'))),
          Expanded(
              flex: 2,
              child: Text(
                result == null ? 'Result Goes here' : result!,
                style: const TextStyle(fontSize: 25),
              )),
        ],
      ),
    );
  }

  void pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        filePath = image.path;
      });
    }
  }

  void mlProcess() async {
    if (filePath == null) {
      return;
    }

    final InputImage inputImage = InputImage.fromFile(File(filePath!));

    final ImageLabelerOptions options =
        ImageLabelerOptions(confidenceThreshold: 0.5);

    final imageLabeler = ImageLabeler(options: options);

    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

    String labelResults = '';

    for (ImageLabel label in labels) {
      final String text = label.label;

      labelResults = labelResults + '\n' + text;

      final int index = label.index;
      final double confidence = label.confidence;
    }

    setState(() {
      result = labelResults;
    });

    imageLabeler.close();
  }

  @override
  void dispose() {
    controller?.dispose();
    timer?.cancel();
    super.dispose();
  }
}
