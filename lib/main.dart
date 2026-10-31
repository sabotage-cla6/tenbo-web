import 'package:flutter/material.dart';

import 'signup_page.dart';

void main() {
  runApp(const TenboApp());
}

class TenboApp extends StatelessWidget {
  const TenboApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF245447);
    return MaterialApp(
      title: '天棒',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5EF),
      ),
      home: const SignupPage(),
    );
  }
}
