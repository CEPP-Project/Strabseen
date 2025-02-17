import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strabismus/ui/mainmenu_screen.dart';

class SummaryScreen extends StatelessWidget {
  final dynamic result;

  const SummaryScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.containsKey('error')) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: ${result['error']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontSize: 18.0,
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      );
    }

    Map<String, dynamic> variable = result;
    bool trueValue = variable['result'][0];
    double pointEightOneValue = variable['result'][1][1];
    String percentageValue =
        '${(pointEightOneValue * 100).toStringAsFixed(0)}%';

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Strabismus Rate $percentageValue',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18.0,
              ),
            ),
            Text(
              'You are ${trueValue == true ? "" : "not"} likely to be Strabismus',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18.0,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      color: Colors.grey,
      child: FutureBuilder(
        future: _getToken(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return _returnButton(context, snapshot.data);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Widget _returnButton(BuildContext context, String? result) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        );
      },
      child: const Text('Go back to Main menu'),
    );
  }
}
