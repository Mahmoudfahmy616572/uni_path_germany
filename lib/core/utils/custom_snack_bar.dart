import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool loading = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _SnackBarContent(
          message: message,
          isError: isError,
          loading: loading,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        padding: EdgeInsets.zero,
        duration: Duration(seconds: loading ? 60 : 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

class _SnackBarContent extends StatefulWidget {
  final String message;
  final bool isError;
  final bool loading;
  const _SnackBarContent({
    required this.message,
    required this.isError,
    this.loading = false,
  });

  @override
  State<_SnackBarContent> createState() => _SnackBarContentState();
}

class _SnackBarContentState extends State<_SnackBarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.loading ? const Duration(seconds: 60) : const Duration(seconds: 4),
    )..forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.loading
        ? const Color(0xFF1E293B)
        : widget.isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.35),
              blurRadius: 12.r,
              offset: Offset(0, 4.r),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  _AnimatedIcon(isError: widget.isError, loading: widget.loading),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14.r),
                bottomRight: Radius.circular(14.r),
              ),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: widget.loading ? null : _progressController.value,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.4),
                    ),
                    minHeight: 3,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIcon extends StatefulWidget {
  final bool isError;
  final bool loading;
  const _AnimatedIcon({required this.isError, required this.loading});

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.loading
              ? Icons.hourglass_empty_rounded
              : widget.isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}
