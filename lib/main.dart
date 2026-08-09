 import 'package:flutter/material.dart';

import '../features/electrical/cable_design/pages/cable_design_page_v2.dart';

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

      // เปลี่ยนบรรทัดนี้
      home: const CableDesignPageV2(),
    );
  }
}