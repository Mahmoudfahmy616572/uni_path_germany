import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../domain/entities/university_entity.dart';

class UniversityComparisonScreen extends StatelessWidget {
  final List<UniversityEntity> universities;

  const UniversityComparisonScreen({
    super.key,
    required this.universities,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('compare')),
      ),
      body: universities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.compare_arrows, size: 64.sp, color: Colors.grey[300]),
                  SizedBox(height: 16.h),
                  Text(
                    'Select universities to compare',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 24.w,
                  columns: [
                    DataColumn(
                      label: Text('Feature',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    ),
                    ...universities.map((uni) => DataColumn(
                          label: Text(uni.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                        )),
                  ],
                  rows: [
                    _buildRow('Logo', isDark, context,
                        universities.map((u) => u.logoText.isNotEmpty ? u.logoText : '-').toList()),
                    _buildRow('Location', isDark, context,
                        universities.map((u) => u.location ?? '-').toList()),
                    _buildRow('Ranking', isDark, context,
                        universities.map((u) => u.rankings?.toString() ?? '-').toList()),
                    _buildRow('Match', isDark, context,
                        universities.map((u) => '${u.matchPercentage}%').toList()),
                    _buildRow('Programs', isDark, context,
                        universities.map((u) => '${u.matchedProgramsCount}').toList()),
                    _buildRow('Status', isDark, context,
                        universities.map((u) => u.status.isNotEmpty ? u.status : '-').toList()),
                    _buildRow('Tuition', isDark, context,
                        universities.map((u) {
                          if (u.programs.isEmpty) return '-';
                          final fees = u.programs.map((p) => p.tuitionFeePerYear).toSet();
                          if (fees.length == 1) {
                            return '€${fees.first}/yr';
                          }
                          final minFee = fees.reduce((a, b) => a < b ? a : b);
                          final maxFee = fees.reduce((a, b) => a > b ? a : b);
                          return '€$minFee-€$maxFee/yr';
                        }).toList()),
                    _buildRow('Deadlines', isDark, context,
                        universities.map((u) {
                          final dates = u.programs
                              .where((p) => p.deadline != null && p.deadline!.isNotEmpty)
                              .map((p) => p.deadline!)
                              .toSet()
                              .join(', ');
                          return dates.isNotEmpty ? dates : '-';
                        }).toList()),
                    _buildRow('Application Fee', isDark, context,
                        universities.map((u) {
                          if (u.programs.isEmpty) return '-';
                          final fees = u.programs.map((p) => p.applicationFee).toSet();
                          if (fees.length == 1) return '€${fees.first}';
                          return '€${fees.join('/')}';
                        }).toList()),
                  ],
                ),
              ),
            ),
    );
  }

  DataRow _buildRow(String label, bool isDark, BuildContext context, List<String> values) {
    return DataRow(
      cells: [
        DataCell(
          Text(label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                color: isDark ? AppColors.textMain : const Color(0xFF1E293B),
              )),
        ),
        ...values.map((v) => DataCell(
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 150.w),
                child: Text(v,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                    )),
              ),
            )),
      ],
    );
  }
}
