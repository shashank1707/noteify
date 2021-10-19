import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:tflite/tflite.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool isLoading = true;
  var result = "";

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.high,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
    isLoading = true;
    loadModel().then((value) {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void dispose() async {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    await Tflite.close();
    super.dispose();
  }

  Future loadModel() async {
    var res;
    try {
      res = await Tflite.loadModel(
          model: "assets/model_unquant.tflite",
          labels: "assets/labels.txt",
          isAsset: true,
          useGpuDelegate: false);
    } catch (e) {
      print(e);
    }
    print(res);
    print("kolo");
  }

  Future<String> predictImage(filepath) async {
    var recognitions = await Tflite.runModelOnImage(
        path: filepath, // required
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
        );
    print(recognitions);

    if (recognitions != null) {
      return recognitions[0]['label'].toString().split(" ")[1];
    } else {
      return "Not able to identify";
    }

    // if (recognitions != null) {
    //   setState(() {
    //     result = recognitions[0]['label'].toString().split(" ")[1];
    //   });
    // } else {
    //   setState(() {
    //     result = "Not able to identify";
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.only(top: 8),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                child: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      // If the Future is complete, display the preview.
                      return CameraPreview(
                        _controller,
                      );
                    } else {
                      // Otherwise, display a loading indicator.
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
            Expanded(
                flex: 1,
                child: GestureDetector(
                    onTap: () async {
                      // Take the Picture in a try / catch block. If anything goes wrong,
                      // catch the error.
                      try {
                        // Ensure that the camera is initialized.
                        await _initializeControllerFuture;

                        // Attempt to take a picture and get the file `image`
                        // where it was saved.
                        final image = await _controller.takePicture();
                        result = await predictImage(image.path);

                        // If the picture was taken, display it on a new screen.
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DisplayPictureScreen(
                              // Pass the automatically generated path to
                              // the DisplayPictureScreen widget.
                              imagePath: image.path,
                              result: result,
                            ),
                          ),
                        );
                      } catch (e) {
                        // If an error occurs, log the error to the console.
                        print(e);
                      }
                    },
                    child: Container(
                        margin: EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(5)),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          size: 40,
                        ))))
          ],
        ),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final String result;

  const DisplayPictureScreen(
      {Key? key, required this.imagePath, required this.result})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 4, child: Image.file(File(imagePath))),
              Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      result + " Rupees",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ))
            ],
          )),
    );
  }
}
