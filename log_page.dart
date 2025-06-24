import 'package:flutter/material.dart';
import 'log_store.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Print logs in reverse order for latest-first display
    final reversedLogs = globalAccidentLog.reversed.toList();

    for (var log in reversedLogs) {
      print("[LogPage] 📝 $log");
    }

    return Scaffold(
      appBar: AppBar(title: const Text("📋 Accident Logs")),
      body: reversedLogs.isEmpty
          ? const Center(child: Text("No accident logs recorded yet."))
          : ListView.builder(
              itemCount: reversedLogs.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      reversedLogs[index],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
