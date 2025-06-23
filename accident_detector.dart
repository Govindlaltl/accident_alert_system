 import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'log_store.dart';

class AccidentDetector extends StatefulWidget {
  const AccidentDetector({super.key});

  @override
  State<AccidentDetector> createState() => _AccidentDetectorState();
}

class _AccidentDetectorState extends State<AccidentDetector> {
  String _locationMessage = "Fetching location...";
  bool _isLoading = false;

  // Fetches the current location with permission handling
  Future<Position?> _getLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() {
          _locationMessage = "❌ Location services are disabled.";
        });
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = "❌ Location permissions are denied.";
          });
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = "❌ Location permissions are permanently denied.";
        });
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationMessage =
            "Latitude: ${position.latitude.toStringAsFixed(5)}, "
            "Longitude: ${position.longitude.toStringAsFixed(5)}, "
            "Speed: ${(position.speed * 3.6).toStringAsFixed(1)} km/h";
      });

      return position;
    } catch (e) {
      setState(() {
        _locationMessage = "⚠️ Error getting location: $e";
      });
      return null;
    }
  }

  // Returns formatted time string
  String _getFormattedTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')} - "
        "${now.day}/${now.month}/${now.year}";
  }

  // Simulates accident detection
  void _simulateAccident() async {
    setState(() {
      _isLoading = true;
    });

    final position = await _getLocation();

    setState(() {
      _isLoading = false;
    });

    if (!mounted || position == null) return;

    final time = _getFormattedTime();
    final logEntry = "🕒 Time: $time\n📍 $_locationMessage";
    globalAccidentLog.add(logEntry);

    bool alertCancelled = false;

    // Show confirmation dialog safely after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          Future.delayed(const Duration(seconds: 10), () {
            if (!alertCancelled && Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
              _sendEmergencyAlert(logEntry);
            }
          });

          return AlertDialog(
            title: const Text("🚨 Accident Detected"),
            content: const Text("Are you okay? Sending alert in 10 seconds..."),
            actions: [
              TextButton(
                onPressed: () {
                  alertCancelled = true;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Alert cancelled.")),
                  );
                },
                child: const Text("I'm OK"),
              ),
            ],
          );
        },
      );
    });
  }

  // Sends emergency alert (mocked for now)
  void _sendEmergencyAlert(String logEntry) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚨 Emergency Alert Sent")),
      );
    });

    print("ALERT: $logEntry");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accident Detector")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) const CircularProgressIndicator(),
              ElevatedButton(
                onPressed: _simulateAccident,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Simulate Accident"),
              ),
              const SizedBox(height: 20),
              Text(
                _locationMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
