import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strabismus/ui/mainmenu_screen.dart';
import 'summary_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class LoadingScreen extends StatefulWidget {
  final List<XFile?> photos;

  const LoadingScreen({super.key, required this.photos});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _processData(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _processData(BuildContext context) async {
    // Simulate API call with a delay
    // await Future.delayed(const Duration(seconds: 3));

    // Call API HERE !!!!
    try {
      String token = '';
      await _getToken().then((result) {
        token = result;
      });
      var apiUrl =
          Uri.parse('https://mapp-api.redaxn.com/uploads/detect'); // real api
      // var apiUrl = Uri.parse('http://10.0.2.2:8000/upload-images'); // testing with emulate
      // var apiUrl = Uri.parse('http://192.168.x.x:8000/upload-images'); // testing with device on local network

      var request = http.MultipartRequest('POST', apiUrl);

      for (int i = 0; i < widget.photos.length; i++) {
        var file = File(widget.photos[i]!.path);
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();

        var multipartFile = http.MultipartFile(
          'files',
          stream,
          length,
          filename: p.basename(file.path),
          contentType: MediaType.parse(getContentType(file.path)),
        );

        // print(p.basename(file.path));
        // print('File: ${file.path}, Content Type: ${multipartFile.contentType}');

        request.files.add(multipartFile);
      }
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      var response = await request.send().timeout(const Duration(seconds: 90));
      print('Response Status Code: ${response.statusCode}');
      //print('Response Body: ${await response.stream.bytesToString()}');

      if (response.statusCode == 200) {
        // API call was successful, process the response as needed
        var responseBody = await response.stream.bytesToString();

        var result = json.decode(responseBody);
        if (context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SummaryScreen(result: result)));
        }
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Fail to Upload Image",
                    style: TextStyle(fontSize: 20)),
                content: const Text(
                    "Unknown error has occurred. Return to main menu"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MainMenuScreen()));
        }
      }
    } catch (e) {
      // Handle other errors
      print('Error uploading images: $e');
    }

    // You can pass any result to the next screen, such as processed data
    // var result = "Processed Data";
    // if(context.mounted){
    //   Navigator.of(context).push(MaterialPageRoute(builder: (context) => SummaryScreen(result: result)));
    // }
  }

  String getContentType(String filePath) {
    switch (p.extension(filePath).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpeg':
      case '.jpg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // appBar: AppBar(
      //   title: const Text('Loading Screen'),
      // ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
