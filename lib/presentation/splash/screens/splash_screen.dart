import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _dot1Controller;
  late final AnimationController _dot2Controller;
  late final AnimationController _dot3Controller;
  late final Animation<double> _dot1Scale;
  late final Animation<double> _dot2Scale;
  late final Animation<double> _dot3Scale;

  final List<String> _loadingTexts = [
    'Finding suitable universities...',
    'Loading your profile...',
    'Preparing recommendations...',
  ];

  int _currentTextIndex = 0;
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();

    _dot1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _dot2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _dot3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _dot1Scale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _dot1Controller, curve: Curves.easeInOut),
    );
    _dot2Scale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _dot2Controller, curve: Curves.easeInOut),
    );
    _dot3Scale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _dot3Controller, curve: Curves.easeInOut),
    );

    _dot1Controller.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _dot2Controller.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _dot3Controller.repeat(reverse: true);
    });

    _textTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      setState(() {
        _currentTextIndex = (_currentTextIndex + 1) % _loadingTexts.length;
      });
    });

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    _dot1Controller.dispose();
    _dot2Controller.dispose();
    _dot3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(theme),
              SizedBox(height: 24.h),
              _buildAppName(theme),
              SizedBox(height: 48.h),
              _buildLoadingText(theme),
              SizedBox(height: 32.h),
              _buildDots(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Image.asset(
      'assets/logo/unipass_icon.png',
      width: 0.3.sw,
      fit: BoxFit.contain,
    );
  }

  Widget _buildAppName(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(
                text: 'Uni',
                style: TextStyle(color: const Color(0xFF0F172A)),
              ),
              TextSpan(
                text: 'Pass',
                style: TextStyle(color: const Color(0xFF2563EB)),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'GERMANY',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 3.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingText(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        _loadingTexts[_currentTextIndex],
        key: ValueKey(_currentTextIndex),
        style: TextStyle(
          fontSize: 14.sp,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildDots(ThemeData theme) {
    final color = const Color(0xFF2563EB);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _animatedDot(_dot1Scale, color),
        SizedBox(width: 8.w),
        _animatedDot(_dot2Scale, color),
        SizedBox(width: 8.w),
        _animatedDot(_dot3Scale, color),
      ],
    );
  }

  Widget _animatedDot(Animation<double> animation, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Container(
            width: 10.r,
            height: 10.r,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
