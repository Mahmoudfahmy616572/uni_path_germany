import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/themes/app_colors.dart';
import '../../../domain/entities/university_entity.dart';

class DeadlineCalendarScreen extends StatefulWidget {
  final List<UniversityEntity> applications;

  const DeadlineCalendarScreen({super.key, required this.applications});

  @override
  State<DeadlineCalendarScreen> createState() => _DeadlineCalendarScreenState();
}

class _DeadlineCalendarScreenState extends State<DeadlineCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<_DeadlineItem>> _deadlinesByDate = {};

  @override
  void initState() {
    super.initState();
    _buildDeadlinesMap();
    _selectedDay = _focusedDay;
  }

  void _buildDeadlinesMap() {
    _deadlinesByDate = {};
    for (final uni in widget.applications) {
      for (final program in uni.programs) {
        if (program.deadline == null || program.deadline!.isEmpty) continue;
        final date = _parseDeadline(program.deadline!);
        if (date == null) continue;
        final dayKey = DateTime(date.year, date.month, date.day);
        _deadlinesByDate.putIfAbsent(dayKey, () => []);
        _deadlinesByDate[dayKey]!.add(_DeadlineItem(
          universityName: uni.name,
          programName: program.programName,
          deadline: date,
        ));
      }
    }
  }

  DateTime? _parseDeadline(String deadline) {
    // Try parsing common formats
    try {
      return DateTime.parse(deadline);
    } catch (_) {}
    try {
      final parts = deadline.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDeadlines = _selectedDay != null ? (_deadlinesByDate[_selectedDay!] ?? <_DeadlineItem>[]) : <_DeadlineItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('deadlineCalendar')),
      ),
      body: Column(
        children: [
          _buildCalendar(isDark),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          _buildDeadlineList(selectedDeadlines, isDark),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    return TableCalendar<_DeadlineItem>(
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2028, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      onFormatChanged: (format) => setState(() => _calendarFormat = format),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      eventLoader: (day) => _deadlinesByDate[DateTime(day.year, day.month, day.day)] ?? <_DeadlineItem>[],
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
      ),
    );
  }

  Widget _buildDeadlineList(List<_DeadlineItem> items, bool isDark) {
    return Expanded(
      child: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 48.sp, color: Colors.grey[300]),
                  SizedBox(height: 12.h),
                  Text(
                    _selectedDay != null
                        ? AppLocalizations.of(context).translate('deadlineCalendarEmpty')
                        : AppLocalizations.of(context).translate('selectDateToSeeDeadlines'),
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: ListTile(
                    leading: Icon(Icons.event, color: Colors.redAccent),
                    title: Text(item.programName, style: TextStyle(fontSize: 14.sp)),
                    subtitle: Text(item.universityName, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    trailing: Text(
                      '${item.deadline.day}/${item.deadline.month}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DeadlineItem {
  final String universityName;
  final String programName;
  final DateTime deadline;

  _DeadlineItem({
    required this.universityName,
    required this.programName,
    required this.deadline,
  });
}
