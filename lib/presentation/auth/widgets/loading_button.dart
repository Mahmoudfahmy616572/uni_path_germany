import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final double height;

  const LoadingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width - 48.w;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isLoading ? height : fullWidth,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 18.r),
        gradient: backgroundColor != null
            ? LinearGradient(
                colors: [backgroundColor!, backgroundColor!],
              )
            : const LinearGradient(
                colors: [Color(0xFF5B5EF7), Color(0xFF7C4DFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius ?? 18.r),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor ?? Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: textColor ?? Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
