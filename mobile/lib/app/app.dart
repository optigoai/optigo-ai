import 'package:flutter/material.dart';
import 'theme.dart';
import '../presentation/home/home_screen.dart';

class OptigoAIApp extends StatelessWidget {
  const OptigoAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OptigoAI',
      debugShowCheckedModeBanner: false,
      theme: OptigoTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
