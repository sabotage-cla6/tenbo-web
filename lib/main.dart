import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_config.dart';
import 'signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;
  if (FirebaseConfig.isConfigured) {
    try {
      await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);
      firebaseReady = true;
    } on FirebaseException catch (error) {
      debugPrint('Firebase initialization failed: ${error.code}');
    } catch (error) {
      debugPrint('Firebase initialization failed: $error');
    }
  }

  runApp(TenboApp(firebaseReady: firebaseReady));
}

class TenboApp extends StatelessWidget {
  const TenboApp({required this.firebaseReady, super.key});

  final bool firebaseReady;

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
      home: SignupPage(firebaseReady: firebaseReady),
    );
  }
}
