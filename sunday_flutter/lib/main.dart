import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'views/content_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(backgroundCallback);
  runApp(const SundayApp());
}

void backgroundCallback(Uri? uri) {
  // Handle widget clicks here
}

class SundayApp extends StatelessWidget {
  const SundayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunday',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ContentView(),
    );
  }
}
