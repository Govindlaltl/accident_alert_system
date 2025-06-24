import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'accident_detector.dart';
import 'log_page.dart';
import 'log_store.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _sendAlertWithLocation(BuildContext context) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied.");
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final now = DateTime.now();
      final formattedTime = "${now.hour.toString().padLeft(2, '0')}:"
          "${now.minute.toString().padLeft(2, '0')}:"
          "${now.second.toString().padLeft(2, '0')} - "
          "${now.day}/${now.month}/${now.year}";

      final alertMessage = "🕒 Time: $formattedTime\n📍 "
          "Latitude: ${position.latitude.toStringAsFixed(5)}, "
          "Longitude: ${position.longitude.toStringAsFixed(5)}, "
          "Speed: ${(position.speed * 3.6).toStringAsFixed(1)} km/h";

      globalAccidentLog.add(alertMessage);
      print("🚨 EMERGENCY ALERT SENT:\n$alertMessage");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚨 Alert sent with location")),
      );
    } catch (e) {
      print("❌ Failed to send alert: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to get location")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accident Alert App"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.sensors),
              label: const Text("Start Detection"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccidentDetector()),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.warning),
              label: const Text("Send Alert"),
              onPressed: () => _sendAlertWithLocation(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text("View Logs"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogPage()),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
