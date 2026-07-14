import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget menu(String title, IconData icon) {
    return Card(
      child: SizedBox(
        width: 180,
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PUNTA ERAWAN MEP"),
        centerTitle: true,
      ),
      body: Center(
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            menu("Electrical", Icons.electric_bolt),
            menu("Plumbing", Icons.water_drop),
            menu("HVAC", Icons.ac_unit),
            menu("Fire Protection", Icons.local_fire_department),
            menu("Load Schedule", Icons.table_chart),
            menu("BOQ", Icons.calculate),
          ],
        ),
      ),
    );
  }
}