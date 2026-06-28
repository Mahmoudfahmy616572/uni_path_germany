import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_theme.dart';
import '../../../core/widgets/curtain_drop.dart';

class CityCostData {
  final String name;
  final double rent;
  final double food;
  final double insurance;
  final double transport;
  final double misc;

  const CityCostData({
    required this.name,
    required this.rent,
    required this.food,
    required this.insurance,
    required this.transport,
    required this.misc,
  });

  double get total => rent + food + insurance + transport + misc;
}

const _blockedAccountMonthly = 992.0;
const _blockedAccountYearly = 11904.0;

const _cities = [
  CityCostData(name: 'Berlin', rent: 580, food: 200, insurance: 125, transport: 48, misc: 130),
  CityCostData(name: 'Munich', rent: 750, food: 200, insurance: 125, transport: 62, misc: 150),
  CityCostData(name: 'Hamburg', rent: 550, food: 200, insurance: 125, transport: 55, misc: 130),
  CityCostData(name: 'Frankfurt', rent: 570, food: 200, insurance: 125, transport: 58, misc: 130),
  CityCostData(name: 'Cologne', rent: 520, food: 200, insurance: 125, transport: 52, misc: 120),
  CityCostData(name: 'Stuttgart', rent: 560, food: 200, insurance: 125, transport: 58, misc: 130),
  CityCostData(name: 'Düsseldorf', rent: 520, food: 200, insurance: 125, transport: 55, misc: 120),
  CityCostData(name: 'Leipzig', rent: 380, food: 200, insurance: 125, transport: 45, misc: 100),
  CityCostData(name: 'Dresden', rent: 370, food: 200, insurance: 125, transport: 45, misc: 100),
  CityCostData(name: 'Bonn', rent: 460, food: 200, insurance: 125, transport: 50, misc: 110),
  CityCostData(name: 'Mannheim', rent: 460, food: 200, insurance: 125, transport: 50, misc: 110),
  CityCostData(name: 'Nuremberg', rent: 430, food: 200, insurance: 125, transport: 50, misc: 100),
  CityCostData(name: 'Hannover', rent: 430, food: 200, insurance: 125, transport: 52, misc: 100),
  CityCostData(name: 'Bremen', rent: 410, food: 200, insurance: 125, transport: 48, misc: 100),
  CityCostData(name: 'Freiburg', rent: 490, food: 200, insurance: 125, transport: 45, misc: 110),
  CityCostData(name: 'Heidelberg', rent: 510, food: 200, insurance: 125, transport: 52, misc: 120),
  CityCostData(name: 'Tübingen', rent: 490, food: 200, insurance: 125, transport: 45, misc: 110),
  CityCostData(name: 'Aachen', rent: 440, food: 200, insurance: 125, transport: 50, misc: 100),
  CityCostData(name: 'Darmstadt', rent: 460, food: 200, insurance: 125, transport: 52, misc: 110),
  CityCostData(name: 'Karlsruhe', rent: 440, food: 200, insurance: 125, transport: 50, misc: 100),
];

class CostOfLivingScreen extends StatefulWidget {
  final String? initialCity;

  const CostOfLivingScreen({super.key, this.initialCity});

  @override
  State<CostOfLivingScreen> createState() => _CostOfLivingScreenState();
}

class _CostOfLivingScreenState extends State<CostOfLivingScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    if (widget.initialCity != null) {
      final idx = _cities.indexWhere(
        (c) => c.name.toLowerCase() == widget.initialCity!.toLowerCase(),
      );
      if (idx >= 0) _selectedIndex = idx;
    }
  }

  CityCostData get _city => _cities[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = context.surfaceColor;
    final muted = context.textMutedColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('costOfLivingEstimator')),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          CurtainDrop(
            index: 0,
            child: _buildCitySelector(isDark),
          ),
          SizedBox(height: 20.h),
          CurtainDrop(
            index: 1,
            child: _buildSummaryCard(isDark),
          ),
          SizedBox(height: 20.h),
          CurtainDrop(
            index: 2,
            child: _buildBreakdown(isDark, surface, muted),
          ),
          SizedBox(height: 20.h),
          CurtainDrop(
            index: 3,
            child: _buildBlockedAccountCard(isDark, surface, muted),
          ),
          SizedBox(height: 20.h),
          CurtainDrop(
            index: 4,
            child: _buildInfoCard(isDark, surface, muted),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildCitySelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('selectCity'),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMain : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 42.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _cities.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, i) {
              final selected = i == _selectedIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF6366F1)
                        : (isDark ? AppColors.darkCardBg : Colors.white),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF6366F1)
                          : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _cities[i].name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? Colors.white
                          : (isDark ? AppColors.textMuted : const Color(0xFF475569)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    final t = _city.total;
    final ratio = t / _blockedAccountMonthly;
    final remaining = _blockedAccountMonthly - t;
    final isOver = remaining < 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
            blurRadius: 15.r,
            offset: Offset(0, 8.r),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.account_balance, color: Colors.white, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _city.name,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).translate('monthlyLivingExpenses'),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '€${t.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).translate('perMonthShort'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? const Color(0xFFEF4444) : const Color(0xFF34D399),
              ),
              minHeight: 6.h,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '€0',
                style: TextStyle(fontSize: 11.sp, color: Colors.white60),
              ),
              Text(
                isOver
                    ? '€${(-remaining).toStringAsFixed(0)} ${AppLocalizations.of(context).translate('overBlockedAccount')}'
                    : '€${remaining.toStringAsFixed(0)} ${AppLocalizations.of(context).translate('remainingAfterExpenses')}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isOver ? const Color(0xFFFCA5A5) : Colors.white70,
                ),
              ),
              Text(
                '€$_blockedAccountMonthly',
                style: TextStyle(fontSize: 11.sp, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdown(bool isDark, Color surface, Color muted) {
    final items = [
      _CostItem(label: AppLocalizations.of(context).translate('rent'), icon: Icons.home, value: _city.rent, color: const Color(0xFF6366F1)),
      _CostItem(label: AppLocalizations.of(context).translate('food'), icon: Icons.restaurant, value: _city.food, color: const Color(0xFF10B981)),
      _CostItem(label: AppLocalizations.of(context).translate('insurance'), icon: Icons.health_and_safety, value: _city.insurance, color: const Color(0xFFF59E0B)),
      _CostItem(label: AppLocalizations.of(context).translate('transport'), icon: Icons.directions_bus, value: _city.transport, color: const Color(0xFF38BDF8)),
      _CostItem(label: AppLocalizations.of(context).translate('miscellaneous'), icon: Icons.more_horiz, value: _city.misc, color: const Color(0xFF8B5CF6)),
    ];

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('costBreakdown'),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textMain : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 16.h),
          ...items.map((item) => _buildCostRow(item, isDark, muted)),
        ],
      ),
    );
  }

  Widget _buildCostRow(_CostItem item, bool isDark, Color muted) {
    final pct = item.value / _city.total;
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16.sp, color: item.color),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? AppColors.textMain : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                '€${item.value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textMain : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
              minHeight: 4.h,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAccountCard(bool isDark, Color surface, Color muted) {
    final t = _city.total;
    final remaining = _blockedAccountMonthly - t;
    final isOver = remaining < 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 20.sp, color: const Color(0xFF6366F1)),
              SizedBox(width: 8.w),
              Text(
                AppLocalizations.of(context).translate('vsBlockedAccount'),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textMain : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildCompareRow(AppLocalizations.of(context).translate('blockedAccount'), _blockedAccountMonthly, const Color(0xFF6366F1), isDark),
          SizedBox(height: 8.h),
          _buildCompareRow(AppLocalizations.of(context).translate('estMonthlyCosts'), t, isOver ? const Color(0xFFEF4444) : const Color(0xFF10B981), isDark),
          if (!isOver) ...[
            SizedBox(height: 8.h),
            Divider(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            SizedBox(height: 8.h),
            _buildCompareRow(AppLocalizations.of(context).translate('remaining'), remaining, const Color(0xFF34D399), isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildCompareRow(String label, double amount, Color color, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          '€${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark, Color surface, Color muted) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    AppLocalizations.of(context).translate('blockedAccountInfoTitle'),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${AppLocalizations.of(context).translate('blockedAccountInfoBody')} €${_blockedAccountYearly.toStringAsFixed(0)}/year (€${_blockedAccountMonthly.toStringAsFixed(0)}/month).',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CostItem {
  final String label;
  final IconData icon;
  final double value;
  final Color color;
  const _CostItem({required this.label, required this.icon, required this.value, required this.color});
}
