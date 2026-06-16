import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AiDocumentReviewSheet extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final void Function(BuildContext context, String docType, String programName)?
      onGenerateDocument;

  const AiDocumentReviewSheet({
    super.key,
    required this.reviews,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onGenerateDocument,
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
                Icon(Icons.description, color: const Color(0xFF8B5CF6), size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Document Review',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
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
                    'Reviewing your documents...',
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
          else if (reviews.isEmpty)
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48.sp, color: const Color(0xFF10B981)),
                  SizedBox(height: 16.h),
                  Text(
                    'No documents to review. Upload your documents first!',
                    textAlign: TextAlign.center,
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
                itemCount: reviews.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final r = reviews[index];
                  return _DocReviewCard(
                    review: r,
                    onGenerate: onGenerateDocument != null
                        ? () => onGenerateDocument!(
                            context,
                            r['doc_type'] as String? ?? '',
                            r['_program_name'] as String? ?? '',
                          )
                        : null,
                  );
                },
              ),
            ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class _DocReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final VoidCallback? onGenerate;

  const _DocReviewCard({required this.review, this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final docType = review['doc_type'] as String? ?? '';
    final status = review['status'] as String? ?? 'missing';
    final title = review['title'] as String? ?? 'Document';
    final tips = (review['tips'] as List?)?.cast<String>() ?? [];
    final importance = review['importance'] as String? ?? 'medium';

    final isUploaded = status == 'uploaded';
    final Color docColor = _docColor(docType);
    final IconData icon = _docIcon(docType);

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isUploaded ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: docColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 18.sp, color: docColor),
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
                    Row(
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUploaded
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          isUploaded ? 'Uploaded' : 'Missing',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isUploaded
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _importanceColor(importance).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  importance.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: _importanceColor(importance),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (tips.isNotEmpty)
            ...tips.map((tip) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: docColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              )),
            if (onGenerate != null &&
                (docType == 'cv' || docType == 'sop') &&
                isUploaded) ...[
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    'Generate ${docType == 'cv' ? 'CV' : 'SOP'} with AI',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }

  Color _importanceColor(String importance) {
    switch (importance) {
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

  Color _docColor(String docType) {
    switch (docType) {
      case 'transcripts':
        return const Color(0xFF3B82F6);
      case 'bachelor_cert':
        return const Color(0xFF8B5CF6);
      case 'sop':
        return const Color(0xFF10B981);
      case 'cv':
        return const Color(0xFFF59E0B);
      case 'language_cert':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _docIcon(String docType) {
    switch (docType) {
      case 'transcripts':
        return Icons.description_outlined;
      case 'bachelor_cert':
        return Icons.workspace_premium_outlined;
      case 'sop':
        return Icons.article_outlined;
      case 'cv':
        return Icons.person_outline;
      case 'language_cert':
        return Icons.translate_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
