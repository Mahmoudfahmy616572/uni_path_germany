import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget _gradientIcon(dynamic icon, double size, List<Color> colors) {
  return ShaderMask(
    shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
    blendMode: BlendMode.srcIn,
    child: FaIcon(icon, size: size, color: Colors.white),
  );
}

Widget _glow({required double size}) {
  return Center(
    child: Container(
      width: size * 0.75,
      height: size * 0.75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF5B5EF7).withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    ),
  );
}

class _ParticlesPainter extends CustomPainter {
  final Color color;
  final int count;

  _ParticlesPainter({this.color = const Color(0xFF5B5EF7), this.count = 8});

  @override
  void paint(Canvas canvas, Size size) {
    const seed = 42.0;
    final calculated = (seed * 2654435761) % 4294967296;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final x = ((calculated * (i + 1) * 7) % 10000) / 10000 * size.width;
      final y = ((calculated * (i + 1) * 13) % 10000) / 10000 * size.height;
      final r = 1.5 + ((calculated * (i + 1) * 3) % 10000) / 10000 * 2.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginIllustration extends StatelessWidget {
  const LoginIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _glow(size: 180),
          _gradientIcon(FontAwesomeIcons.shield, 100, const [Color(0xFF5B5EF7), Color(0xFFA855F7)]),
          Positioned(
            right: 42, bottom: 28,
            child: _gradientIcon(FontAwesomeIcons.lock, 28, const [Color(0xFF7C4DFF), Color(0xFFA855F7)]),
          ),
          Positioned.fill(child: CustomPaint(painter: _ParticlesPainter(count: 6))),
        ],
      ),
    );
  }
}

class RegisterIllustration extends StatelessWidget {
  const RegisterIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _glow(size: 180),
          _gradientIcon(FontAwesomeIcons.graduationCap, 85, const [Color(0xFF5B5EF7), Color(0xFFA855F7)]),
          Positioned(
            right: 35, top: 28,
            child: Transform.rotate(
              angle: math.pi / 6,
              child: _gradientIcon(FontAwesomeIcons.rocket, 34, const [Color(0xFF7C4DFF), Color(0xFFA855F7)]),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _ParticlesPainter(color: const Color(0xFFA855F7), count: 6))),
        ],
      ),
    );
  }
}

class ForgotPasswordIllustration extends StatelessWidget {
  const ForgotPasswordIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _glow(size: 180),
          _gradientIcon(FontAwesomeIcons.envelope, 90, const [Color(0xFF5B5EF7), Color(0xFFA855F7)]),
          Positioned(
            bottom: 30, right: 36,
            child: _gradientIcon(FontAwesomeIcons.lock, 22, const [Color(0xFF7C4DFF), Color(0xFFA855F7)]),
          ),
          Positioned(
            top: 35, left: 28,
            child: Transform.rotate(
              angle: -math.pi / 8,
              child: Opacity(
                opacity: 0.5,
                child: _gradientIcon(FontAwesomeIcons.envelopeOpenText, 26, const [Color(0xFF5B5EF7), Color(0xFFA855F7)]),
              ),
            ),
          ),
          Positioned(
            top: 28, right: 26,
            child: Transform.rotate(
              angle: math.pi / 6,
              child: Opacity(
                opacity: 0.4,
                child: _gradientIcon(FontAwesomeIcons.envelopeOpenText, 20, const [Color(0xFF5B5EF7), Color(0xFFA855F7)]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResetPasswordIllustration extends StatelessWidget {
  const ResetPasswordIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _glow(size: 180),
          Container(
            width: 130.w, height: 130.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5B5EF7).withValues(alpha: 0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B5EF7).withValues(alpha: 0.08),
                  blurRadius: 30.r, spreadRadius: 5.r,
                ),
              ],
            ),
          ),
          _gradientIcon(FontAwesomeIcons.shield, 70, const [Color(0xFF5B5EF7), Color(0xFF7C4DFF)]),
          Positioned(
            right: 42, bottom: 34,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: _gradientIcon(FontAwesomeIcons.key, 26, const [Color(0xFF7C4DFF), Color(0xFFA855F7)]),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _ParticlesPainter(color: const Color(0xFF7C4DFF), count: 5))),
        ],
      ),
    );
  }
}

class VerifyEmailIllustration extends StatelessWidget {
  const VerifyEmailIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _glow(size: 180),
          _gradientIcon(FontAwesomeIcons.mobileScreenButton, 85, const [Color(0xFF5B5EF7), Color(0xFFA855F7)]),
          Positioned(
            right: 26, bottom: 24,
            child: Container(
              width: 40.r, height: 40.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    blurRadius: 12.r, offset: Offset(0, 4.r),
                  ),
                ],
              ),
              child: Icon(Icons.check_rounded, color: Colors.white, size: 22.sp),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _ParticlesPainter(color: const Color(0xFF22C55E), count: 4))),
        ],
      ),
    );
  }
}
