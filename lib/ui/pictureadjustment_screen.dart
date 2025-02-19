import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:image/image.dart' as img;
import 'package:photo_view/photo_view.dart';
import 'package:strabismus/ui/loading_screen.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'dart:io'; // For using File
// import 'package:strabismus/ui/testcrop_screen.dart'; // Import this for PhotoViewController

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
  double menuGap = 0;

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

  // To store eye frame position
  final Map<String, Offset> _leftEyeFramePositionMap = {
    "left": Offset.zero,
    "middle": Offset.zero,
    "right": Offset.zero,
  };
  final Map<String, Offset> _rightEyeFramePositionMap = {
    "left": Offset.zero,
    "middle": Offset.zero,
    "right": Offset.zero,
  };

  // initial state flag
  bool _isInitialized = false;

  // Separate PhotoViewControllers for each eye type
  final PhotoViewController _leftPhotoViewController = PhotoViewController();
  final PhotoViewController _middlePhotoViewController = PhotoViewController();
  final PhotoViewController _rightPhotoViewController = PhotoViewController();

  bool _isCropping = false;

  final GlobalKey _importBtnKey = GlobalKey();
  Size importBtnSize = const Size(0, 0);

  @override
  void initState() {
    super.initState();
    // Lock the orientation for this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    menuGap = (height - 200) / 5;

    eyewidth = (width - menuSize) / 4;
    eyeheight = height / 4;

    // initial the value
    if (!_isInitialized) {
      Offset defaultLeftEyeOffset = Offset(
        5 * (width - menuSize) / 16 - eyewidth / 2,
        height / 2 - eyeheight / 2,
      );

      Offset defaultRightEyeOffset = Offset(
        11 * (width - menuSize) / 16 - eyewidth / 2,
        height / 2 - eyeheight / 2,
      );

      _leftEyeFramePositionMap.updateAll((key, value) => defaultLeftEyeOffset);
      _rightEyeFramePositionMap
          .updateAll((key, value) => defaultRightEyeOffset);

      // init only when in a landscape orientation
      if (width > height) {
        _isInitialized = true;
      }
    }
  }

  @override
  void dispose() {
    // Reset orientation when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // Set to your default orientation
    ]);
    super.dispose();
  }

  void _initializePositions() {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    menuGap = (height - 200) / 5;

    eyewidth = (width - menuSize) / 4;
    eyeheight = height / 4;

    Offset defaultLeftEyeOffset = Offset(
      5 * (width - menuSize) / 16 - eyewidth / 2,
      height / 2 - eyeheight / 2,
    );

    Offset defaultRightEyeOffset = Offset(
      11 * (width - menuSize) / 16 - eyewidth / 2,
      height / 2 - eyeheight / 2,
    );

    _leftEyeFramePositionMap.updateAll((key, value) => defaultLeftEyeOffset);
    _rightEyeFramePositionMap.updateAll((key, value) => defaultRightEyeOffset);
  }

  Future<void> _importPicture(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
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
    final List<Future<List<XFile?>>> cropFutures = [];

    if (_leftImage != null) {
      double scale = _leftPhotoViewController.scale!;
      Offset position = _leftPhotoViewController.position;
      _saveAdjustedPosition(scale, position);
      cropFutures.add(
          _cropImage(_leftImage!, _leftImagePosition, _leftImageScale, "left"));
    }
    if (_middleImage != null) {
      double scale = _middlePhotoViewController.scale!;
      Offset position = _middlePhotoViewController.position;
      _saveAdjustedPosition(scale, position);
      cropFutures.add(_cropImage(
          _middleImage!, _middleImagePosition, _middleImageScale, "middle"));
    }
    if (_rightImage != null) {
      double scale = _rightPhotoViewController.scale!;
      Offset position = _rightPhotoViewController.position;
      _saveAdjustedPosition(scale, position);
      cropFutures.add(_cropImage(
          _rightImage!, _rightImagePosition, _rightImageScale, "right"));
    }

    // Wait for all the cropping operations to complete
    final List<List<XFile?>> croppedImagePairs = await Future.wait(cropFutures);

    // Flatten the list of lists into a single list
    final List<XFile?> allCroppedImages =
        croppedImagePairs.expand((x) => x).toList();

    return allCroppedImages;
  }

  Future<List<XFile?>> _cropImage(
      XFile imageFile, Offset offset, double scale, String eye) async {
    try {
      // Load the original image (also rotate image if have exif orietation data)
      final File file =
          await FlutterExifRotation.rotateAndSaveImage(path: imageFile.path);
      final List<int> imageBytes = await file.readAsBytes();

      final List<img.Image> croppedImages =
          await compute(_performCroppingInIsolate, {
        'imageBytes': imageBytes,
        'offset': offset,
        'scale': scale,
        'viewportWidth': (width - menuSize).toInt(),
        'viewportHeight': height.toInt(),
        'eyeWidth': eyewidth,
        'eyeHeight': eyeheight,
        'leftEyePosition': _leftEyeFramePositionMap[eye]!,
        'rightEyePosition': _rightEyeFramePositionMap[eye]!
      });

      final String leftEyeTempPath =
          await _saveCroppedImage(croppedImages[0], eye, 'left');
      final String rightEyeTempPath =
          await _saveCroppedImage(croppedImages[1], eye, 'right');

      print('leftEyeTempPath: $leftEyeTempPath');
      print('rightEyeTempPath: $rightEyeTempPath');

      return [XFile(leftEyeTempPath), XFile(rightEyeTempPath)];
    } catch (e) {
      print('Error cropping image: $e');
      return [null, null];
    }
  }

  // use static cause this function run in isolate
  // perform cropping image and return list that have left eye and right eye image
  static List<img.Image> _performCroppingInIsolate(
      Map<String, dynamic> params) {
    final List<int> imageBytes = params['imageBytes'];
    final Offset offset = params['offset'];
    final double scale = params['scale'];
    final int viewportWidth = params['viewportWidth'];
    final int viewportHeight = params['viewportHeight'];
    final double eyeWidth = params['eyeWidth'];
    final double eyeHeight = params['eyeHeight'];
    final Offset leftEyePosition = params['leftEyePosition'];
    final Offset rightEyePosition = params['rightEyePosition'];

    final img.Image orientedImage = img.decodeImage(imageBytes)!;

    final int scaledWidth = (orientedImage.width * scale).toInt();
    final int scaledHeight = (orientedImage.height * scale).toInt();
    final img.Image scaledImage = img.copyResize(
      orientedImage,
      width: scaledWidth,
      height: scaledHeight,
      // interpolation: img.Interpolation.cubic // High quality but slow
    );

    final double centerX = viewportWidth / 2 + offset.dx;
    final double centerY = viewportHeight / 2 + offset.dy;

    // Define the crop area for the left eye frame
    final int leftCropX = leftEyePosition.dx.toInt();
    final int leftCropY = leftEyePosition.dy.toInt();
    final int leftCropWidth = eyeWidth.toInt();
    final int leftCropHeight = eyeHeight.toInt();

    // Define the crop area for the right eye frame
    final int rightCropX = rightEyePosition.dx.toInt();
    final int rightCropY = rightEyePosition.dy.toInt();
    final int rightCropWidth = eyeWidth.toInt();
    final int rightCropHeight = eyeHeight.toInt();

    // Crop the left eye area from the scaled image
    img.Image leftCroppedImage = img.copyCrop(
      scaledImage,
      (leftCropX - (centerX - scaledWidth / 2)).clamp(0, scaledWidth).toInt(),
      (leftCropY - (centerY - scaledHeight / 2)).clamp(0, scaledHeight).toInt(),
      leftCropWidth,
      leftCropHeight,
    );

    // Crop the right eye area from the scaled image
    img.Image rightCroppedImage = img.copyCrop(
      scaledImage,
      (rightCropX - (centerX - scaledWidth / 2)).clamp(0, scaledWidth).toInt(),
      (rightCropY - (centerY - scaledHeight / 2))
          .clamp(0, scaledHeight)
          .toInt(),
      rightCropWidth,
      rightCropHeight,
    );

    return [leftCroppedImage, rightCroppedImage];
  }

  Future<String> _saveCroppedImage(
      img.Image croppedImage, String eye, String eyeSide) async {
    final String timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('T', '_');
    final Directory tempDir = Directory.systemTemp;
    final String tempPath =
        '${tempDir.path}/${timestamp}_cropped_${eye}_$eyeSide.jpg';
    await File(tempPath).writeAsBytes(img.encodeJpg(croppedImage));
    return tempPath;
  }

  @override
  Widget build(BuildContext context) {
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
          _buildPhotoViewForEye(_leftImage, _leftPhotoViewController,
              (scale, position) {
            _saveAdjustedPosition(scale, position);
          }, _isLeftSelected),
          _buildPhotoViewForEye(_middleImage, _middlePhotoViewController,
              (scale, position) {
            _saveAdjustedPosition(scale, position);
          }, _isMiddleSelected),
          _buildPhotoViewForEye(_rightImage, _rightPhotoViewController,
              (scale, position) {
            _saveAdjustedPosition(scale, position);
          }, _isRightSelected),

          // Overlay Eye Frames
          if (currentImage != null)
            Positioned.fill(
              child: Stack(
                children: [
                  // left eye frame
                  _buildDraggableEyeFrame(
                    position: _leftEyeFramePositionMap[_currentEyeType]!,
                    onDragEnd: (newPosition) {
                      setState(() {
                        _leftEyeFramePositionMap[_currentEyeType] = newPosition;
                      });
                    },
                    borderColor: Colors.black,
                  ),
                  // right eye frame
                  _buildDraggableEyeFrame(
                    position: _rightEyeFramePositionMap[_currentEyeType]!,
                    onDragEnd: (newPosition) {
                      setState(() {
                        _rightEyeFramePositionMap[_currentEyeType] =
                            newPosition;
                      });
                    },
                    borderColor: Colors.black,
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
                      child: Padding(
                        padding: const EdgeInsets.only(
                            right: 10), // Shift entire content to the right
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.translate(
                              offset: const Offset(
                                  5, 1), // Shift icon slightly to the left
                              child: const Icon(
                                Icons.arrow_back, // Arrowhead
                                size: 30,
                              ),
                            ),
                            const Text(
                              '--------', // Line
                              style: TextStyle(fontSize: 24, letterSpacing: -2),
                            ),
                          ],
                        ),
                      ),
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
                      child: const Text('Look Straight Ahead'),
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
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 10.0), // Shift entire content to the right
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '--------', // Line
                              style: TextStyle(fontSize: 24, letterSpacing: -2),
                            ),
                            Transform.translate(
                              offset: const Offset(
                                  -5, 1), // Shift icon slightly to the left
                              child: const Icon(
                                Icons.arrow_forward, // Arrowhead
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: menuGap),
                  SizedBox(
                      width: menuSize - 20,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isCropping = true;
                          });

                          // Await the result of _cropImages() to get the cropped images
                          final List<XFile?> croppedImages =
                              await _cropImages();

                          setState(() {
                            _isCropping = false;
                          });

                          // Check if the widget is still mounted before navigating
                          if (context.mounted) {
                            if (_leftImage != null &&
                                _middleImage != null &&
                                _rightImage != null) {
                              Navigator.push(
                                context,
                                // MaterialPageRoute(
                                //   builder: (context) => TestCropScreen(
                                //     photos: croppedImages,
                                //   ),
                                // ),
                                MaterialPageRoute(
                                  builder: (context) => LoadingScreen(
                                    photos: croppedImages,
                                  ),
                                ),
                              );
                            } else {
                              // Use a new context for showing the Snackbar, which is safe
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please import all images.')),
                              );
                            }
                          }
                        },
                        child: _isCropping
                            ? const Padding(
                                padding: EdgeInsets.all(5.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Loading'),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Text('Submit'),
                      )),
                ],
              ),
            ),
          ),
          // Centered Import Picture Button
          if (currentImage == null)
            Positioned(
              left: ((width - menuSize) / 2) -
                  (importBtnSize.width.toInt() / 2), // Center horizontally
              top: (height / 2) -
                  (importBtnSize.height.toInt() / 2), // Center vertically
              child: LayoutBuilder(builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final RenderBox importBtnBox = _importBtnKey.currentContext!
                        .findRenderObject() as RenderBox;

                    setState(() {
                      importBtnSize = importBtnBox.size;
                    });
                  }
                });

                return Container(
                  key: _importBtnKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 180,
                        child: ElevatedButton.icon(
                          onPressed: () => _importPicture(ImageSource.gallery),
                          icon: const Icon(Icons.image),
                          label: const Text('Import Picture'),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      SizedBox(
                        width: 180,
                        child: ElevatedButton.icon(
                          onPressed: () => _importPicture(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Picture'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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

  Widget _buildPhotoView(
    XFile? image,
    PhotoViewController controller,
    Function onScaleChanged,
  ) {
    if (image == null) return Container();

    return PhotoView(
      controller: controller,
      imageProvider: FileImage(File(image.path)),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.transparent),
      enableRotation: false, // Disable rotation
      scaleStateChangedCallback: (scaleState) {
        // Save the scale when it changes
        double scale = controller.scale!;
        Offset position = controller.position;
        onScaleChanged(scale, position);
      },
      onScaleEnd: (context, details, controller) {
        // Save the position when tapping
        double scale = controller.scale!;
        Offset position = controller.position;
        onScaleChanged(scale, position);
      },
      onTapUp: (context, details, controller) {
        // Save the position when tapping
        double scale = controller.scale!;
        Offset position = controller.position;
        onScaleChanged(scale, position);
      },
      onTapDown: (context, details, controller) {
        // Save the position when tapping
        double scale = controller.scale!;
        Offset position = controller.position;
        onScaleChanged(scale, position);
      },
    );
  }

  Widget _buildPhotoViewForEye(
    XFile? image,
    PhotoViewController controller,
    Function onScaleChanged,
    bool isSelected,
  ) {
    if (image == null) return Container();

    return Positioned(
      left: isSelected ? 0 : -10000,
      top: 0,
      width: width - menuSize,
      height: height,
      child: _buildPhotoView(image, controller, onScaleChanged),
    );
  }

  Widget _buildDraggableEyeFrame({
    required Offset position,
    required Function(Offset) onDragEnd,
    required Color borderColor,
  }) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: eyewidth,
            height: eyeheight,
            decoration: BoxDecoration(
                color: Colors.transparent,
                border:
                    Border.all(color: borderColor.withOpacity(0.8), width: 3.0),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(30),
                  right: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.2), spreadRadius: 3),
                ]),
          ),
        ),
        childWhenDragging:
            Container(), // Hide the original frame while dragging
        onDragEnd: (details) {
          onDragEnd(Offset(
            // Ensure the frame stays within bounds
            details.offset.dx.clamp(0, (width - menuSize) - eyewidth),
            details.offset.dy.clamp(0, height - eyeheight),
          ));
        },
        child: Container(
          width: eyewidth,
          height: eyeheight,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 3.0),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(30),
              right: Radius.circular(30),
            ),
          ),
        ),
      ),
    );
  }
}
