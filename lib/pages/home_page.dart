 import 'package:flutter/material.dart';
import 'cable_size_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget menuCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 180,
      height: 120,
      child: Card(
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 42,
                color: Colors.blue,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
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

            menuCard(
              context: context,
              title: "Electrical",
              icon: Icons.electric_bolt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CableSizePage(),
                  ),
                );
              },
            ),

            menuCard(
              context: context,
              title: "Plumbing",
              icon: Icons.water_drop,
              onTap: () {},
            ),

            menuCard(
              context: context,
              title: "HVAC",
              icon: Icons.ac_unit,
              onTap: () {},
            ),

            menuCard(
              context: context,
              title: "Fire Protection",
              icon: Icons.local_fire_department,
              onTap: () {},
            ),

            menuCard(
              context: context,
              title: "Load Schedule",
              icon: Icons.table_chart,
              onTap: () {},
            ),

            menuCard(
              context: context,
              title: "BOQ",
              icon: Icons.calculate,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}