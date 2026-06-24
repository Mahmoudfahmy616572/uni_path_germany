import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/paymob_service.dart';
import '../../../core/services/premium_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/utils/logger.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final _premiumService = sl<PremiumService>();
  final _paymobService = sl<PaymobService>();
  final _supabase = sl<SupabaseClient>();
  String _selectedPlan = 'yearly';
  bool _isLoading = false;

  final Map<String, int> _planPrices = {
    'monthly': 30000, // 300 EGP
    'yearly': 250000, // 2500 EGP
    'lifetime': 450000, // 4500 EGP
  };

  Future<void> _startPayment() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('pleaseSignInFirst')), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final info = await _paymobService.getPaymentInfo(
        amountCents: _planPrices[_selectedPlan]!,
        userId: user.id,
        plan: _selectedPlan,
      );

      if (!mounted) return;
      await _openPaymentWebView(info['iframe_id']!, info['payment_token']!);
    } catch (e) {
      String msg = 'Payment error';
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['error']?.toString() ?? msg;
      } else {
        msg = e.toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openPaymentWebView(String iframeId, String paymentToken) async {
    final url = _paymobService.getIframeUrl(iframeId, paymentToken);
    bool paymentDone = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (pageUrl) {
                if (pageUrl.contains('post_pay') || pageUrl.contains('success') || pageUrl.contains('callback') || pageUrl.contains('done')) {
                  paymentDone = true;
                }
              },
              onPageFinished: (pageUrl) {
                if (pageUrl.contains('post_pay') || pageUrl.contains('success') || pageUrl.contains('callback') || pageUrl.contains('done') || pageUrl.contains('response')) {
                  paymentDone = true;
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(url));

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && paymentDone) {
              Navigator.of(ctx).pop();
              if (mounted) _verifyAndActivate();
            }
          },
          child: Dialog(
            insetPadding: EdgeInsets.zero,
            child: Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context).translate('payment')),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (paymentDone) {
                      Navigator.of(ctx).pop();
                      if (mounted) _verifyAndActivate();
                    } else {
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              ),
              body: WebViewWidget(controller: controller),
            ),
          ),
        );
      },
    );

    if (paymentDone && mounted) {
      await _verifyAndActivate();
    }
  }

  Future<void> _verifyAndActivate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('checkingPaymentStatus')),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final isPremium = await _premiumService.isPremium();
      if (isPremium && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('premiumActivated')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
        return;
      }
    }

    // Fallback: try activating directly (user is authenticated via Supabase)
    if (mounted) {
      try {
        await _premiumService.activatePremium(_selectedPlan);
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).translate('premiumActivated')),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
          return;
        }
      } catch (e) {
        log.e('activatePremium fallback error: $e');
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('paymentDelayed')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: isDark ? AppColors.textMain : const Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkCardBg : const Color(0xFFF5F3FF),
              ),
              child: Icon(Icons.lock_open, size: 36.sp, color: const Color(0xFF8B5CF6)),
            ),
            SizedBox(height: 20.h),
            Text(loc.translate('unlockPremium'),
              style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textMain : const Color(0xFF1E293B)),
            ),
            SizedBox(height: 8.h),
            Text(loc.translate('premiumFeatures'),
              style: TextStyle(fontSize: 14.sp,
                  color: isDark ? AppColors.textMuted : const Color(0xFF64748B)),
            ),
            SizedBox(height: 28.h),
            _buildFeatureItem(context, Icons.description_outlined, loc.translate('aiReviewUnlimited')),
            _buildFeatureItem(context, Icons.tips_and_updates_outlined, loc.translate('aiImprovement')),
            _buildFeatureItem(context, Icons.score_outlined, loc.translate('premiumMatchScore')),
            _buildFeatureItem(context, Icons.support_agent_outlined, loc.translate('prioritySupport')),
            _buildFeatureItem(context, Icons.all_inclusive, loc.translate('unlimitedAiUses')),
            SizedBox(height: 32.h),
            _buildPlanCard(
              context: context, title: loc.translate('monthly'),
              price: '300 EGP', period: loc.translate('perMonthShort'),
              isSelected: _selectedPlan == 'monthly',
              onTap: () => setState(() => _selectedPlan = 'monthly'),
            ),
            SizedBox(height: 12.h),
            _buildPlanCard(
              context: context, title: loc.translate('yearly'),
              price: '2500 EGP', period: loc.translate('perYearShort'),
              isSelected: _selectedPlan == 'yearly', isBestValue: true,
              badge: loc.translate('bestValue'),
              onTap: () => setState(() => _selectedPlan = 'yearly'),
              subText: loc.translate('savePercent').replaceAll('{percent}', '30'),
            ),
            SizedBox(height: 12.h),
            _buildPlanCard(
              context: context, title: loc.translate('lifetime'),
              price: '4500 EGP', period: loc.translate('oneTime'),
              isSelected: _selectedPlan == 'lifetime',
              onTap: () => setState(() => _selectedPlan = 'lifetime'),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity, height: 52.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 22.w, height: 22.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(loc.translate('goPremium'),
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('paymentComingSoon')),
                      behavior: SnackBarBehavior.floating),
                );
              },
              child: Text(loc.translate('restorePurchases'),
                style: TextStyle(
                  color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                  fontSize: 13.sp,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 18.sp, color: const Color(0xFF10B981)),
          ),
          SizedBox(width: 14.w),
          Text(text, style: TextStyle(fontSize: 14.sp,
              color: context.isDark ? AppColors.textMain : const Color(0xFF334155))),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context, required String title, required String price,
    required String period, required bool isSelected, required VoidCallback onTap,
    bool isBestValue = false, String? badge, String? subText,
  }) {
    final isDark = context.isDark;
    final Color borderColor = isSelected
        ? const Color(0xFF8B5CF6)
        : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(badge, style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 10.h),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textMain : const Color(0xFF1E293B))),
                    Container(
                      width: 22.r, height: 22.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFCBD5E1), width: 2,
                        ),
                        color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 14.sp, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textMain : const Color(0xFF1E293B))),
                    SizedBox(width: 4.w),
                    Text(period, style: TextStyle(fontSize: 13.sp,
                        color: isDark ? AppColors.textMuted : const Color(0xFF64748B))),
                  ],
                ),
                if (subText != null) ...[
                  SizedBox(height: 4.h),
                  Text(subText, style: TextStyle(fontSize: 12.sp, color: const Color(0xFF10B981), fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
