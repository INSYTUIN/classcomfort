import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const ClassComfortApp());

class ClassComfortApp extends StatelessWidget {
  const ClassComfortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassComfort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}
