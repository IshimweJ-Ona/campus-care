
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _glowController;

  late final Animation<double> _shieldOpacity;
  late final Animation<double> _shieldScale;
  late final Animation<double> _shieldRotation;

  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loadingOpacity;

  Timer? _navigationTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Main sequence: 6.5 seconds.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    // Slow, gentle glow pulse.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 1. Shield appears first.
    _shieldOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.00,
        0.28,
        curve: Curves.easeIn,
      ),
    );

    _shieldScale = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.00,
          0.35,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _shieldRotation = Tween<double>(
      begin: -0.10,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.00,
          0.38,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // 2. Title enters after the shield.
    _titleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.32,
        0.57,
        curve: Curves.easeIn,
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.32,
          0.60,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // 3. Tagline appears after the title.
    _taglineOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.60,
        0.76,
        curve: Curves.easeIn,
      ),
    );

    // 4. Loading indicator appears last.
    _loadingOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.78,
        0.96,
        curve: Curves.easeIn,
      ),
    );

    // Start the sequence.
    _introController.forward();

    // Delay the glow so it doesn't compete with the shield entrance.
    Future<void>.delayed(const Duration(milliseconds: 750), () {
      if (mounted) {
        _glowController.repeat(reverse: true);
      }
    });

    // Keep the splash visible for 8 seconds in total.
    _navigationTimer = Timer(
      const Duration(seconds: 12),
      _navigateAfterSplash,
    );
  }

  Future<void> _navigateAfterSplash() async {
    if (!mounted || _isNavigating) return;

    _isNavigating = true;

    final User? user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      context.go('/home');
    } else {
      context.go('/register');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _introController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark cinematic background.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.splashBackground,
                  Color(0xFF0B1930),
                  AppColors.splashBackground,
                ],
              ),
            ),
          ),

          // Background atmosphere.
          Positioned(
            top: -120,
            right: -100,
            child: _buildBackgroundGlow(300),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: _buildBackgroundGlow(340),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shield: fade, scale, and rotate.
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _introController,
                        _glowController,
                      ]),
                      builder: (context, child) {
                        final double pulse =
                            0.85 + (_glowController.value * 0.15);

                        return Opacity(
                          opacity: _shieldOpacity.value,
                          child: Transform.rotate(
                            angle: _shieldRotation.value,
                            child: Transform.scale(
                              scale: _shieldScale.value,
                              child: SizedBox(
                                width: 190,
                                height: 190,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Gentle pulsing glow.
                                    Container(
                                      width: 145 * pulse,
                                      height: 145 * pulse,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.glow.withValues(
                                              alpha: 0.15 +
                                                  (_glowController.value *
                                                      0.12),
                                            ),
                                            blurRadius: 45,
                                            spreadRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Shield container.
                                    Container(
                                      width: 122,
                                      height: 122,
                                      decoration: BoxDecoration(
                                        color: AppColors.splashSurface,
                                        borderRadius: BorderRadius.circular(32),
                                        border: Border.all(
                                          color: AppColors.primaryLight
                                              .withValues(alpha: 0.55),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.health_and_safety_rounded,
                                        size: 76,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Title: starts after the shield.
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          'CampusCare',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tagline: appears after the title.
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: const Text(
                        'A SAFER CAMPUS STARTS WITH YOU',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.2,
                          color: Color(0xFF9CB4D5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Loading bar: appears near the end.
                    FadeTransition(
                      opacity: _loadingOpacity,
                      child: SizedBox(
                        width: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedBuilder(
                            animation: _introController,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _introController.value,
                                minHeight: 3,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.10,
                                ),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryLight,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FadeTransition(
                      opacity: _loadingOpacity,
                      child: const Text(
                        'Preparing your campus experience...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8095B2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer appears with the rest of the interface.
          Positioned(
            bottom: 22,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineOpacity,
              child: const Text(
                'CAMPUSCARE  •  YOUR SAFETY MATTERS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: Color(0xFF60758F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow(double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.glow.withValues(alpha: 0.12),
              AppColors.glow.withValues(alpha: 0.03),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
