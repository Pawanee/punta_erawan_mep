 import 'package:flutter/material.dart';
import 'package:mep_project/features/electrical/cable/models/cable_input.dart';
import 'package:mep_project/features/electrical/cable/services/cable_engine.dart';

class CableSizePage extends StatefulWidget {
  const CableSizePage({super.key});

  @override
  State<CableSizePage> createState() => _CableSizePageState();
}

class _CableSizePageState extends State<CableSizePage> {
  final TextEditingController currentController = TextEditingController();
  final TextEditingController voltageDropController = TextEditingController();

  String voltage = "400 V";
  String phase = "3 Phase";
  String cableType = "IEC01 PVC";
  String installation = "Reference Method C";
  String ambient = "30°C";
  String grouping = "1 Circuit";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cable Size Designer"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Electrical Information",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Load Current (A)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: voltage,
              decoration: const InputDecoration(
                labelText: "Voltage",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "230 V", child: Text("230 V")),
                DropdownMenuItem(value: "400 V", child: Text("400 V")),
              ],
              onChanged: (value) {
                setState(() {
                  voltage = value!;
                });
              },
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: phase,
              decoration: const InputDecoration(
                labelText: "Phase",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "1 Phase", child: Text("1 Phase")),
                DropdownMenuItem(value: "3 Phase", child: Text("3 Phase")),
              ],
              onChanged: (value) {
                setState(() {
                  phase = value!;
                });
              },
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: cableType,
              decoration: const InputDecoration(
                labelText: "Cable Type",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "IEC01 PVC", child: Text("IEC01 PVC")),
                DropdownMenuItem(value: "XLPE", child: Text("XLPE")),
                DropdownMenuItem(value: "NYY", child: Text("NYY")),
              ],
              onChanged: (value) {
                setState(() {
                  cableType = value!;
                });
              },
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: installation,
              decoration: const InputDecoration(
                labelText: "Installation Method",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Reference Method A",
                  child: Text("Reference Method A"),
                ),
                DropdownMenuItem(
                  value: "Reference Method B",
                  child: Text("Reference Method B"),
                ),
                DropdownMenuItem(
                  value: "Reference Method C",
                  child: Text("Reference Method C"),
                ),
                DropdownMenuItem(
                  value: "Reference Method D",
                  child: Text("Reference Method D"),
                ),
                DropdownMenuItem(
                  value: "Reference Method E",
                  child: Text("Reference Method E"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  installation = value!;
                });
              },
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: ambient,
              decoration: const InputDecoration(
                labelText: "Ambient Temperature",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "30°C", child: Text("30°C")),
                DropdownMenuItem(value: "35°C", child: Text("35°C")),
                DropdownMenuItem(value: "40°C", child: Text("40°C")),
                DropdownMenuItem(value: "45°C", child: Text("45°C")),
                DropdownMenuItem(value: "50°C", child: Text("50°C")),
              ],
              onChanged: (value) {
                setState(() {
                  ambient = value!;
                });
              },
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: grouping,
              decoration: const InputDecoration(
                labelText: "Grouping",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "1 Circuit", child: Text("1 Circuit")),
                DropdownMenuItem(value: "2 Circuits", child: Text("2 Circuits")),
                DropdownMenuItem(value: "3 Circuits", child: Text("3 Circuits")),
                DropdownMenuItem(value: "4 Circuits", child: Text("4 Circuits")),
              ],
              onChanged: (value) {
                setState(() {
                  grouping = value!;
                });
              },
            ),

            const SizedBox(height: 18),

            TextField(
              controller: voltageDropController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Voltage Drop (%)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
  final input = CableInput(
    loadCurrent: double.tryParse(currentController.text) ?? 0,
    voltage: voltage,
    phase: phase,
    cableType: cableType,
    installationMethod: installation,
    ambientTemperature: ambient,
    grouping: grouping,
    voltageDrop:
        double.tryParse(voltageDropController.text) ?? 0,
  );

  final result = CableEngine().calculate(input);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(
        '''
Cable Size : ${result.cableSize}
Breaker : ${result.breakerSize}
Ground : ${result.groundSize}
''',
      ),
    ),
  );
},
                icon: const Icon(Icons.calculate),
                label: const Text(
                  "CALCULATE",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}