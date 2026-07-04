import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:milo/core/theme/app_colors.dart';
import 'package:milo/features/home/presentation/home_shell.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeShell(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.yellowVivid,
      body: Center(
        child: Image.asset(
          'assets/images/icon.png',
          width: 180,
          height: 180,
        )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.1, 1.1),
          duration: 800.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 500.ms)
        .then()
        .shake(duration: 400.ms, hz: 4),
      ),
    );
  }
}
