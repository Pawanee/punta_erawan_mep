import 'package:flutter/material.dart';
import 'package:mep_project/features/electrical/cable/pages/cable_size_page.dart';

class ElectricalPage extends StatelessWidget {
  const ElectricalPage({super.key});

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
                size: 40,
                color: Colors.blue,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Coming Soon"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Electrical"),
      ),
      body: Center(
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            menuCard(
              context: context,
              title: "Cable Size",
              icon: Icons.cable,
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
              title: "Voltage Drop",
              icon: Icons.bolt,
              onTap: () => comingSoon(context),
            ),
            menuCard(
              context: context,
              title: "Breaker",
              icon: Icons.electrical_services,
              onTap: () => comingSoon(context),
            ),
            menuCard(
              context: context,
              title: "Ground",
              icon: Icons.settings_input_antenna,
              onTap: () => comingSoon(context),
            ),
            menuCard(
              context: context,
              title: "Conduit",
              icon: Icons.view_stream,
              onTap: () => comingSoon(context),
            ),
            menuCard(
              context: context,
              title: "Load Schedule",
              icon: Icons.table_chart,
              onTap: () => comingSoon(context),
            ),
          ],
        ),
      ),
    );
  }
}