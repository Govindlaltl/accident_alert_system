import 'package:flutter/material.dart';
import 'home_page.dart';
import 'log_store.dart';          // <-- NEW

Future<void> main() async {
  // Make sure Flutter engine is ready, then load persistent logs
  WidgetsFlutterBinding.ensureInitialized();
  await AccidentLogStore.init();   // pulls saved logs from SharedPreferences
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accident Alert App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
