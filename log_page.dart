import 'package:flutter/material.dart';
import 'log_store.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 Print logs to the terminal
    for (var log in globalAccidentLog) {
      print("📝 LOG: $log");
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Accident Logs")),
      body: globalAccidentLog.isEmpty
          ? const Center(child: Text("No logs yet."))
          : ListView.builder(
              itemCount: globalAccidentLog.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.red),
                  title: Text(globalAccidentLog[index]),
                );
              },
            ),
    );
  }
}
