import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import 'log_store.dart';

/// Flip to false if you want to disable SMS temporarily.
const bool kSmsEnabled = true;

class AccidentDetector extends StatefulWidget {
  const AccidentDetector({Key? key}) : super(key: key);   // ✅ public constructor

  @override
  State<AccidentDetector> createState() => _AccidentDetectorState();
}

class _AccidentDetectorState extends State<AccidentDetector> {
  /* ─── Platform channel ─────────────────────────────────────────────── */
  static const MethodChannel _smsChannel = MethodChannel('accident/sms');
  final FlutterTts _tts = FlutterTts();

  String _locationMessage = 'Fetching location…';
  bool _isLoading = false;

  /* ─── Helpers ──────────────────────────────────────────────────────── */
  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  String _now() => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  String _buildSmsBody(Position pos) {
    final maps = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    return '''
⚠️ Accident detected!
📅 ${_now()}
📍 Lat: ${pos.latitude.toStringAsFixed(5)}, Lon: ${pos.longitude.toStringAsFixed(5)}
➡️ $maps
Please send immediate assistance.''';
  }

  /* ─── Get current position ─────────────────────────────────────────── */
  Future<Position?> _getLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationMessage = '❌ Location services are disabled.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locationMessage = '❌ Location permission denied.');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationMessage = '❌ Location permanently denied.');
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationMessage =
            'Lat: ${pos.latitude.toStringAsFixed(5)}, '
            'Lon: ${pos.longitude.toStringAsFixed(5)}, '
            'Speed: ${(pos.speed * 3.6).toStringAsFixed(1)} km/h';
      });
      return pos;
    } catch (e) {
      setState(() => _locationMessage = '⚠️ Error getting location: $e');
      return null;
    }
  }

  /* ─── Accident simulation & countdown ──────────────────────────────── */
  void _simulateAccident() async {
    setState(() => _isLoading = true);
    final pos = await _getLocation();
    setState(() => _isLoading = false);
    if (!mounted || pos == null) return;

    final logEntry = '🕒 ${_now()}\n📍 $_locationMessage';
    await AccidentLogStore.add(logEntry);

    bool alertCancelled = false;
    _speak('Accident detected. Are you okay? Sending alert in 10 seconds.');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 10), () {
          if (!alertCancelled && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
            _handleAlertSend(logEntry, pos);
          }
        });

        return AlertDialog(
          title: const Text('🚨 Accident Detected'),
          content: const Text('Are you okay? Sending alert in 10 seconds…'),
          actions: [
            TextButton(
              onPressed: () {
                alertCancelled = true;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Alert cancelled.')),
                );
                _speak('Alert cancelled. Glad you\'re okay.');
              },
              child: const Text("I'm OK"),
            ),
          ],
        );
      },
    );
  }

  /* ─── After countdown: decide to send SMS ──────────────────────────── */
  Future<void> _handleAlertSend(String logEntry, Position pos) async {
    if (!kSmsEnabled) {
      await AccidentLogStore.add('❌ SMS NOT IMPLEMENTED:\n$logEntry');
      if (!mounted) return;
      _speak('SMS feature not yet implemented.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ SMS feature not yet implemented.')),
      );
      return;
    }

    await _sendEmergencyAlert(logEntry, pos);
  }

  /* ─── SMS helpers ──────────────────────────────────────────────────── */
  Future<bool> _ensureSmsPermission() async {
    var sms = await Permission.sms.status;
    var phone = await Permission.phone.status;
    if (sms.isGranted && phone.isGranted) return true;
    if (!sms.isGranted) sms = await Permission.sms.request();
    if (!phone.isGranted) phone = await Permission.phone.request();
    return sms.isGranted && phone.isGranted;
  }

  Future<void> _sendEmergencyAlert(String logEntry, Position pos) async {
    if (!await _ensureSmsPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ SMS permission denied.')),
      );
      _speak('SMS permission denied.');
      return;
    }

    const emergencyNumber = '918891467240';  // ← your emergency contact
    final message = _buildSmsBody(pos);

    try {
      print('[SMS] invoking sendSMS');
      final res = await _smsChannel.invokeMethod<String>('sendSMS', {
        'number': emergencyNumber,
        'message': message,
      });

      if (res == 'SMS_SENT' || res == 'SMS_DISPATCHED') {
        await AccidentLogStore.add('✅ ALERT SENT:\n$logEntry');
        if (!mounted) return;
        _speak('Emergency alert sent with your location.');
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('✅ Alert Sent'),
            content: Text('SMS successfully sent to $emergencyNumber.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception(res ?? 'UNKNOWN');
      }
    } on PlatformException catch (e) {
      await AccidentLogStore.add('❌ ALERT FAILED:\n$logEntry\nError: ${e.code}');
      if (!mounted) return;
      _speak('Failed to send emergency alert.');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('❌ Alert Failed'),
          content: Text('Could not send SMS.\nReason: ${e.message}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /* ─── UI ───────────────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accident Detector')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) const CircularProgressIndicator(),
              ElevatedButton(
                onPressed: _simulateAccident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simulate Accident'),
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
