import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة Supabase
  await Supabase.initialize(
    url: 'https://nrjwzdkhwcqokwlmkzem.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5yand6ZGtod2Nxb2t3bG1remVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3MTkzMjYsImV4cCI6MjA3NjI5NTMyNn0.1c8usW_rodQEo0s2G8S5Ggc2NN8iOU0GO0Qd6yFAm8g',
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'لوحة إدارة بن عقلان',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        fontFamily: 'NotoSansArabic', // الافتراضي للعربية

        textTheme: TextTheme(
            bodyMedium: TextStyle(
              fontFamilyFallback: ['RobotoLocal', 'Arial'], // fallback للإنجليزية
              fontFamily: 'NotoSansArabic',
            ),
            bodyLarge: TextStyle(
              fontFamilyFallback: ['RobotoLocal', 'Arial'],
              fontFamily: 'NotoSansArabic',
            ),
            labelLarge: TextStyle(
                fontFamilyFallback: ['RobotoLocal', 'Arial'],
                fontFamily: 'NotoSansArabic',
                ),
            ),
      ),

        home: const Directionality(
            textDirection: TextDirection.rtl,
            child: AdminLoginScreen(),
            ),
        );
    }
}