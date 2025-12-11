import 'package:flutter/material.dart';
import 'screens/test_database_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExplorezVotreVille',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TestDatabaseScreen(), // ← Lance directement l'écran de test
    );
  }
}