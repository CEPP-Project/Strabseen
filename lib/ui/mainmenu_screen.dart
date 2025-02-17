import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strabismus/ui/pictureadjustment_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // @override
  // void initState() {
  //   super.initState();
  //   SystemChrome.setPreferredOrientations([
  //     DeviceOrientation.portraitUp,
  //     DeviceOrientation.portraitDown,
  //   ]);
  // }
  //
  // @override
  // void dispose() {
  //   SystemChrome.setPreferredOrientations([
  //     DeviceOrientation.landscapeRight,
  //     DeviceOrientation.landscapeLeft,
  //     DeviceOrientation.portraitUp,
  //     DeviceOrientation.portraitDown,
  //   ]);
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Main Menu'),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 300.0,
              height: 50.0,
              child: TextButton(
                onPressed: () {
                  // Continue as guest no authentication
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PictureAdjustmentScreen()),
                  );
                },
                style: TextButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF222930), // Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    )),
                child: const Text(
                  'Strabseen',
                  style: TextStyle(
                    fontSize: 24.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
