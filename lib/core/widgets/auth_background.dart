import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF0B1020), Color(0xFF0B1020)],
                    )
                  : const LinearGradient(
                      begin: Alignment(-0.5, -0.5),
                      end: Alignment(0.5, 0.5),
                      colors: [
                        Color(0xFFF7F8FF),
                        Color(0xFFEEF2FF),
                        Color(0xFFF8FAFC),
                      ],
                    ),
            ),
          ),
        ),
        if (!isDark) ...[
          Positioned(
            top: -80.r, right: -60.r,
            child: Container(
              width: 300.r, height: 300.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF5B5EF7).withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -60.r, left: -40.r,
            child: Container(
              width: 250.r, height: 250.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFA855F7).withValues(alpha: 0.05),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
        if (isDark) ...[
          Positioned(
            top: -100.r, right: -100.r,
            child: Container(
              width: 400.r, height: 400.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                  const Color(0xFF5B5EF7).withValues(alpha: 0.05),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80.r, left: -80.r,
            child: Container(
              width: 350.r, height: 350.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF5B5EF7).withValues(alpha: 0.18),
                  const Color(0xFFA855F7).withValues(alpha: 0.04),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            top: 300.h, left: -50.r,
            child: Container(
              width: 200.r, height: 200.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFA855F7).withValues(alpha: 0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? null : Colors.white.withValues(alpha: 0.7),
                      gradient: isDark
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x0DFFFFFF), Color(0x05FFFFFF)],
                            )
                          : null,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : const Color(0xFF5B5EF7).withValues(alpha: 0.08),
                          blurRadius: 60.r,
                          offset: Offset(0, 30.r),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -120.r, right: -120.r,
                          child: Container(
                            width: 250.r, height: 250.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                const Color(0xFF7C4DFF).withValues(
                                    alpha: isDark ? 0.35 : 0.25),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -100.r, left: -100.r,
                          child: Container(
                            width: 220.r, height: 220.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                const Color(0xFF5B5EF7).withValues(
                                    alpha: isDark ? 0.25 : 0.15),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
