import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const PuntaApp());
}

class PuntaApp extends StatelessWidget {
  const PuntaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PUNTA ERAWAN MEP',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}