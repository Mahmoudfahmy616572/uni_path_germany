import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiImprovementSheet extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final int remainingUses;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const AiImprovementSheet({
    super.key,
    required this.suggestions,
    required this.remainingUses,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 12.h),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: const Color(0xFF8B5CF6), size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'AI Suggestions',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$remainingUses left this month',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF7C3AED),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Analyzing your profile...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else if (error != null)
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48.sp, color: const Color(0xFFEF4444)),
                  SizedBox(height: 16.h),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (onRetry != null)
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            )
          else if (suggestions.isEmpty)
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48.sp, color: const Color(0xFF10B981)),
                  SizedBox(height: 16.h),
                  Text(
                    'Your profile is already well-optimized!',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final s = suggestions[index];
                  return _SuggestionCard(suggestion: s);
                },
              ),
            ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final title = suggestion['title'] as String? ?? 'Suggestion';
    final category = suggestion['category'] as String? ?? '';
    final impact = suggestion['impact'] as String? ?? '';
    final action = suggestion['action'] as String? ?? '';
    final priority = suggestion['priority'] as String? ?? 'low';

    final Color priorityColor = _cardPriorityColor(priority);
    final IconData icon = _cardCategoryIcon(category);

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 18.sp, color: const Color(0xFF7C3AED)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (impact.isNotEmpty)
                      Text(
                        impact,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            action,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _cardPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _cardCategoryIcon(String category) {
    switch (category) {
      case 'gpa':
        return Icons.grade_outlined;
      case 'major':
        return Icons.school_outlined;
      case 'ielts':
        return Icons.translate_outlined;
      case 'language':
        return Icons.language_outlined;
      case 'intake':
        return Icons.calendar_today_outlined;
      case 'documents':
        return Icons.description_outlined;
      default:
        return Icons.tips_and_updates_outlined;
    }
  }
}
