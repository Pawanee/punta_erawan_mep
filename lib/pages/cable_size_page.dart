import 'package:flutter/material.dart';

class CableSizePage extends StatelessWidget {
  const CableSizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cable Size Calculator"),
      ),
      body: const Center(
        child: Text(
          "Cable Size Engine V1",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}