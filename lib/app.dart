import 'package:flutter/material.dart';
import 'package:milo/core/theme/app_theme.dart';
import 'package:milo/features/home/presentation/home_shell.dart';

/// Point d'entrée widget de l'application Milo.
class MiloApp extends StatelessWidget {
  const MiloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeShell(),
    );
  }
}
