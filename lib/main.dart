import 'package:flutter/material.dart';
import 'package:nonton_plus/screens/AllMovies.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AllMovies(),
      ),
    );
  }
}
