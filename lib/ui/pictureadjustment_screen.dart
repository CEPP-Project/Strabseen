import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For using File
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';
import 'package:strabismus/ui/loading_screen.dart';
import 'package:strabismus/ui/testcrop_screen.dart'; // Import this for PhotoViewController

class PictureAdjustmentScreen extends StatefulWidget {
  const PictureAdjustmentScreen({super.key});

  @override
  State<PictureAdjustmentScreen> createState() =>
      _PictureAdjustmentScreenState();
}

class _PictureAdjustmentScreenState extends State<PictureAdjustmentScreen> {
  double width = 0;
  double height = 0;
  double menuSize = 200;
  double eyewidth = 0;
  double eyeheight = 0;
  final ImagePicker _picker = ImagePicker();
  XFile? _leftImage;
  XFile? _middleImage;
  XFile? _rightImage;
  String _currentEyeType = 'left'; // Track the current eye type
  bool _isLeftSelected = true;
  bool _isMiddleSelected = false;
  bool _isRightSelected = false;

  // To store the adjusted positions and scale
  Offset _leftImagePosition = Offset.zero;
  Offset _middleImagePosition = Offset.zero;
  Offset _rightImagePosition = Offset.zero;

  double _leftImageScale = 1.0;
  double _middleImageScale = 1.0;
  double _rightImageScale = 1.0;

  // Separate PhotoViewControllers for each eye type
  final PhotoViewController _leftPhotoViewController = PhotoViewController();
  final PhotoViewController _middlePhotoViewController = PhotoViewController();
  final PhotoViewController _rightPhotoViewController = PhotoViewController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lock the orientation for this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    // Reset orientation when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // Set to your default orientation
    ]);
    super.dispose();
  }

  Future<void> _importPicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (_currentEyeType == 'left') {
          _leftImage = image;
        } else if (_currentEyeType == 'middle') {
          _middleImage = image;
        } else if (_currentEyeType == 'right') {
          _rightImage = image;
        }
      });
    }
  }

  void _removePicture() {
    setState(() {
      if (_currentEyeType == 'left') {
        _leftImage = null;
        _leftPhotoViewController.reset();
      } else if (_currentEyeType == 'middle') {
        _middleImage = null;
        _middlePhotoViewController.reset();
      } else if (_currentEyeType == 'right') {
        _rightImage = null;
        _rightPhotoViewController.reset();
      }
    });
  }

  void _setEyeType(String eyeType) {
    setState(() {
      _currentEyeType = eyeType;
      _isLeftSelected = eyeType == 'left';
      _isMiddleSelected = eyeType == 'middle';
      _isRightSelected = eyeType == 'right';
    });
  }

  void _saveAdjustedPosition(double scale, Offset position) {
    setState(() {
      if (_currentEyeType == 'left') {
        _leftImagePosition = position;
        _leftImageScale = scale;
      } else if (_currentEyeType == 'middle') {
        _middleImagePosition = position;
        _middleImageScale = scale;
      } else if (_currentEyeType == 'right') {
        _rightImagePosition = position;
        _rightImageScale = scale;
      }
    });
  }

  Future<List<XFile?>> _cropImages() async {
    final List<Future<XFile?>> cropFutures = [];

    if (_leftImage != null) {
      double scale = _leftPhotoViewController.scale!;
      Offset position = _leftPhotoViewController.position;
      _saveAdjustedPosition(scale, position);
      cropFutures
          .add(_cropImage(_leftImage!, _leftImagePosition, _leftImageScale,"left"));
    }
    if (_middleImage != null) {
      double scale = _middlePhotoViewController.scale!;
      Offset position = _middlePhotoViewController.position;
      _saveAdjustedPosition(scale, position);
      cropFutures.add(
          _cropImage(_middleImage!, _middleImagePosition, _middleImageScale,"middle"));
    }
    if (_rightImage != null) {
      double scale = _rightPhotoViewController.scale!;
      Offset position = _rightPhotoViewController.position;
      _saveAdjustedPosition(scale, position);
      cropFutures
          .add(_cropImage(_rightImage!, _rightImagePosition, _rightImageScale,"right"));
    }

    // Wait for all the cropping operations to complete
    final List<XFile?> croppedImages = await Future.wait(cropFutures);

    return croppedImages;
  }

  Future<XFile> _cropImage(XFile imageFile, Offset offset, double scale, String eye) async {
    // Load the original image
    final File file = File(imageFile.path);
    final img.Image originalImage = img.decodeImage(await file.readAsBytes())!;

    // Define the viewport dimensions
    final int viewportWidth = (width - menuSize).toInt();
    final int viewportHeight = height.toInt();

    // Scale the original image
    final int scaledWidth = (originalImage.width * scale).toInt();
    final int scaledHeight = (originalImage.height * scale).toInt();
    final img.Image scaledImage = img.copyResize(
      originalImage,
      width: scaledWidth,
      height: scaledHeight,
    );

    // Calculate placement coordinates
    final double centerX = viewportWidth / 2 + offset.dx;
    final double centerY = viewportHeight / 2 + offset.dy;
    final double topLeftX = centerX - (scaledWidth / 2);
    final double topLeftY = centerY - (scaledHeight / 2);
    final double bottomRightX = centerX + (scaledWidth / 2);
    final double bottomRightY = centerY + (scaledHeight / 2);

    // Print debug variables
    // print("Viewport dimensions: $viewportWidth x $viewportHeight");
    // print("Scaled image dimensions: $scaledWidth x $scaledHeight");
    // print("Center of viewport: ($centerX, $centerY)");
    // print("Top-left corner of scaled image: ($topLeftX, $topLeftY)");
    // print("Bottom-right corner of scaled image: ($bottomRightX, $bottomRightY)");

    // Create a blank image as the viewport
    final img.Image viewportImage = img.Image(viewportWidth, viewportHeight, channels: img.Channels.rgb);

    // Determine the crop area if the scaled image is larger than the viewport
    final int cropX = max(0, -topLeftX).toInt();
    final int cropY = max(0, -topLeftY).toInt();
    final int cropWidth = min(scaledWidth-cropX,scaledWidth-cropX-(bottomRightX-viewportWidth)).toInt();
    final int cropHeight = min(scaledHeight-cropY,scaledHeight-cropY-(bottomRightY-viewportHeight)).toInt();

    // Print debug crop area variables
    // print("Crop area: ($cropX, $cropY, $cropWidth x $cropHeight)");

    // Create a cropped image based on the viewport dimensions
    img.Image croppedScaledImage = img.copyCrop(
      scaledImage,
      cropX,
      cropY,
      cropWidth,
      cropHeight,
    );

    // Calculate the position on the viewport to paste the cropped image
    final int dstX = topLeftX.clamp(0.0, viewportWidth.toDouble()).toInt();
    final int dstY = topLeftY.clamp(0.0, viewportHeight.toDouble()).toInt();

    // Print debug paste position
    // print("Paste position on viewport: ($dstX, $dstY)");

    // Paste the cropped scaled image onto the viewport image
    img.copyInto(
      viewportImage,
      croppedScaledImage,
      dstX: dstX,
      dstY: dstY,
    );

    // Save the resulting image to a temporary file
    final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('T', '_');
    final Directory tempDir = Directory.systemTemp;
    final String tempPath = '${tempDir.path}/cropped_image_${eye}_$timestamp.png';
    final File tempFile = File(tempPath)..writeAsBytesSync(img.encodePng(viewportImage));

    // Return the path of the temporary file as XFile
    return XFile(tempPath);
  }


  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    eyewidth = (width - menuSize) / 4;
    eyeheight = height / 4;
    double menuGap = (height - 200) / 5;

    // Get the current image and controller based on the selected eye type
    XFile? currentImage = _leftImage;
    // PhotoViewController currentController = _leftPhotoViewController;
    if (_currentEyeType == 'left') {
      currentImage = _leftImage;
      // currentController = _leftPhotoViewController;
    } else if (_currentEyeType == 'middle') {
      currentImage = _middleImage;
      // currentController = _middlePhotoViewController;
    } else if (_currentEyeType == 'right') {
      currentImage = _rightImage;
      // currentController = _rightPhotoViewController;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Display Imported Picture with PhotoView
          if (_leftImage != null)
            Positioned(
              left: (_currentEyeType == 'left' && _leftImage != null)
                  ? 0
                  : -10000,
              top: 0,
              width: width - menuSize,
              height: height,
              child: PhotoView(
                controller: _leftPhotoViewController,
                imageProvider: FileImage(File(_leftImage!.path)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                enableRotation: false, // Disable rotation
                scaleStateChangedCallback: (scaleState) {
                  // Save the scale when it changes
                  double scale = _leftPhotoViewController.scale!;
                  Offset position = _leftPhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onScaleEnd: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _leftPhotoViewController.scale!;
                  Offset position = _leftPhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onTapUp: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _leftPhotoViewController.scale!;
                  Offset position = _leftPhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onTapDown: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _leftPhotoViewController.scale!;
                  Offset position = _leftPhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
              ),
            ),
          if (_middleImage != null)
            Positioned(
              left: (_currentEyeType == 'middle' && _middleImage != null)
                  ? 0
                  : -10000,
              top: 0,
              width: width - menuSize,
              height: height,
              child: PhotoView(
                controller: _middlePhotoViewController,
                imageProvider: FileImage(File(_middleImage!.path)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                enableRotation: false, // Disable rotation
                scaleStateChangedCallback: (scaleState) {
                  // Save the scale when it changes
                  double scale = _middlePhotoViewController.scale!;
                  Offset position = _middlePhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onScaleEnd: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _middlePhotoViewController.scale!;
                  Offset position = _middlePhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onTapUp: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _middlePhotoViewController.scale!;
                  Offset position = _middlePhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onTapDown: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _middlePhotoViewController.scale!;
                  Offset position = _middlePhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
              ),
            ),
          if (_rightImage != null)
            Positioned(
              left: (_currentEyeType == 'right' && _rightImage != null)
                  ? 0
                  : -10000,
              top: 0,
              width: width - menuSize,
              height: height,
              child: PhotoView(
                controller: _rightPhotoViewController,
                imageProvider: FileImage(File(_rightImage!.path)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                enableRotation: false, // Disable rotation
                scaleStateChangedCallback: (scaleState) {
                  // Save the scale when it changes
                  double scale = _rightPhotoViewController.scale!;
                  Offset position = _rightPhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onScaleEnd: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _rightPhotoViewController.scale!;
                  Offset position = _rightPhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onTapUp: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _rightPhotoViewController.scale!;
                  Offset position = _rightPhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
                onTapDown: (context, details, controller) {
                  // Save the position when tapping
                  double scale = _rightPhotoViewController.scale!;
                  Offset position = _rightPhotoViewController.position;
                  // print("left $scale $position");
                  _saveAdjustedPosition(scale, position);
                },
              ),
            ),
          // Overlay Eye Frames
          if (currentImage != null)
            Positioned.fill(
              child: Stack(
                children: [
                  // left eye box
                  Positioned(
                    left: 5 * (width - menuSize) / 16 - eyewidth / 2,
                    top: height / 2 - eyeheight / 2,
                    child: Container(
                      width: eyewidth,
                      height: eyeheight,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(30),
                          right: Radius.circular(30),
                        ),
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.black,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  // right eye box
                  Positioned(
                    left: 11 * (width - menuSize) / 16 - eyewidth / 2,
                    top: height / 2 - eyeheight / 2,
                    child: Container(
                      width: eyewidth,
                      height: eyeheight,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(30),
                          right: Radius.circular(30),
                        ),
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.black,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Eye Type Buttons
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: menuSize,
              color: Colors.grey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: menuGap),
                  SizedBox(
                    width: menuSize - 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isLeftSelected ? Colors.white30 : Colors.white,
                      ),
                      onPressed: () => _setEyeType('left'),
                      child: const Text('Look Left Eyes'),
                    ),
                  ),
                  SizedBox(height: menuGap),
                  SizedBox(
                    width: menuSize - 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isMiddleSelected ? Colors.white30 : Colors.white,
                      ),
                      onPressed: () => _setEyeType('middle'),
                      child: const Text('Look Middle Eyes'),
                    ),
                  ),
                  SizedBox(height: menuGap),
                  SizedBox(
                    width: menuSize - 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRightSelected ? Colors.white30 : Colors.white,
                      ),
                      onPressed: () => _setEyeType('right'),
                      child: const Text('Look Right Eyes'),
                    ),
                  ),
                  SizedBox(height: menuGap),
                  SizedBox(
                      width: menuSize - 20,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Store the current context
                          final BuildContext context = this.context;

                          // Await the result of _cropImages() to get the cropped images
                          final List<XFile?> croppedImages =
                              await _cropImages();

                          // Check if the widget is still mounted before navigating
                          if (context.mounted) {
                            if (_leftImage != null && _middleImage != null && _rightImage != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoadingScreen(
                                    photos: croppedImages,
                                  ),
                                ),
                              );
                            } else {
                              // Use a new context for showing the Snackbar, which is safe
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please import all images.')),
                              );
                            }
                          }
                        },
                        child: const Text('Submit'),
                      )),
                ],
              ),
            ),
          ),
          // Centered Import Picture Button
          if (currentImage == null)
            Positioned(
              left: (width - menuSize) / 2, // Center horizontally
              top: height / 2 - 20, // Center vertically
              child: ElevatedButton(
                onPressed: _importPicture,
                child: const Text('Import Picture'),
              ),
            )
          else
            Positioned(
              top: menuGap,
              left: menuGap,
              child: ElevatedButton(
                onPressed: _removePicture,
                child: const Text('Remove Picture'),
              ),
            ),
        ],
      ),
    );
  }
}
