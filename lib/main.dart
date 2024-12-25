import 'package:flutter/material.dart';
import 'package:pikit/splash.dart';
import 'package:pikit/theme/app_theme.dart';
import "package:pocketbase/pocketbase.dart";


final pb = PocketBase("YOUR_POCKETBASE_URL/");

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashPage(),
    );
  }
}
