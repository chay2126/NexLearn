import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const NexLearnApp());
}

class NexLearnApp extends StatelessWidget {
  const NexLearnApp({super.key, this.apiService});

  final ApiService? apiService;

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF7F2EA);
    const ink = Color(0xFF1F2D3D);
    const teal = Color(0xFF0F766E);
    const coral = Color(0xFFE76F51);

    return MaterialApp(
      title: 'NexLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(
          seedColor: teal,
          primary: teal,
          secondary: coral,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(color: Color(0xFF425466), height: 1.5),
        ),
      ),
      home: HomeScreen(apiService: apiService),
    );
  }
}
