import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For using File
import 'package:photo_view/photo_view.dart';
import 'package:strabismus/ui/loading_screen.dart'; // Import this for PhotoViewController

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
      } else if (_currentEyeType == 'middle') {
        _middleImage = null;
      } else if (_currentEyeType == 'right') {
        _rightImage = null;
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

  List<XFile?> _cropImages() {
    final List<XFile?> croppedImages = [];
    if (_leftImage != null) {
      croppedImages
          .add(_cropImage(_leftImage!, _leftImagePosition, _leftImageScale));
    }
    if (_middleImage != null) {
      croppedImages.add(
          _cropImage(_middleImage!, _middleImagePosition, _middleImageScale));
    }
    if (_rightImage != null) {
      croppedImages
          .add(_cropImage(_rightImage!, _rightImagePosition, _rightImageScale));
    }
    return croppedImages;
  }

  XFile _cropImage(XFile imageFile, Offset position, double scale) {
    // Implement your cropping logic here, adjust based on position and scale
    // For demonstration purposes, return the original image
    return imageFile;
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
    PhotoViewController currentController = _leftPhotoViewController;
    if (_currentEyeType == 'left') {
      currentImage = _leftImage;
      currentController = _leftPhotoViewController;
    } else if (_currentEyeType == 'middle') {
      currentImage = _middleImage;
      currentController = _middlePhotoViewController;
    } else if (_currentEyeType == 'right') {
      currentImage = _rightImage;
      currentController = _rightPhotoViewController;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Display Imported Picture with PhotoView
          if (currentImage != null)
            Positioned(
              left: 0,
              top: 0,
              width: width - menuSize,
              height: height,
              child: PhotoView(
                controller: currentController,
                imageProvider: FileImage(File(currentImage.path)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                enableRotation: false, // Disable rotation
                scaleStateChangedCallback: (scaleState) {
                  // Save the scale when it changes
                  double scale = currentController.scale!;
                  Offset position = currentController.position;
                  _saveAdjustedPosition(scale, position);
                },
                onTapUp: (context, details, controller) {
                  // Save the position when tapping
                  double scale = currentController.scale!;
                  Offset position = currentController.position;
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
                      onPressed: () {
                        final croppedImages = _cropImages();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoadingScreen(
                              photos: croppedImages,
                            ),
                          ),
                        );
                      },
                      child: const Text('Submit'),
                    ),
                  ),
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
