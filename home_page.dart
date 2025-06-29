import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import 'accident_detector.dart';  // ← matches path shown above
import 'log_page.dart';
import 'log_store.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /* ─── SMS helpers ────────────────────────────────────────── */
  static const MethodChannel _smsChannel = MethodChannel('accident/sms');

  String _now() => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  String _buildSmsBody(Position pos) {
    final maps = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    return '''
⚠️ SOS!
📅 ${_now()}
📍 Lat: ${pos.latitude.toStringAsFixed(5)}, Lon: ${pos.longitude.toStringAsFixed(5)}
➡️ $maps
''';
  }

  Future<bool> _ensureSmsPermission() async {
    var sms = await Permission.sms.status;
    var phone = await Permission.phone.status;
    if (sms.isGranted && phone.isGranted) return true;
    if (!sms.isGranted) sms = await Permission.sms.request();
    if (!phone.isGranted) phone = await Permission.phone.request();
    return sms.isGranted && phone.isGranted;
  }

  Future<void> _sendAlertWithLocation(BuildContext context) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!await _ensureSmsPermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ SMS permission denied')),
        );
        return;
      }

      const emergencyNumber = '918891467240';
      final res = await _smsChannel.invokeMethod<String>('sendSMS', {
        'number': emergencyNumber,
        'message': _buildSmsBody(pos),
      });

      if (res == 'SMS_SENT' || res == 'SMS_DISPATCHED') {
        final log = '✅ MANUAL ALERT:\n🕒 ${_now()}\n📍 '
            'Lat: ${pos.latitude.toStringAsFixed(5)}, '
            'Lon: ${pos.longitude.toStringAsFixed(5)}';
        await AccidentLogStore.add(log);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🚨 Alert SMS sent')),
        );
      } else {
        throw Exception(res ?? 'UNKNOWN');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Alert failed: $e')),
      );
    }
  }

  /* ─── UI ─────────────────────────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accident Alert App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.sensors),
              label: const Text('Start Detection'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccidentDetector()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.warning),
              label: const Text('Send Alert'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () => _sendAlertWithLocation(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('View Logs'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
