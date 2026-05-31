import 'package:flutter/material.dart';

class PipelineMetricsHub extends StatelessWidget {
  final int upcomingDeadlines;
  final int matchAverage;

  const PipelineMetricsHub({
    super.key,
    required this.upcomingDeadlines,
    required this.matchAverage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // كارد الـ Deadlines
          Expanded(
            child: _buildMetricCard(
              icon: Icons.calendar_today_outlined,
              iconColor: const Color(0xFFEF4444),
              title: 'Upcoming Deadlines',
              value: '$upcomingDeadlines',
              subtitle: 'In the next 30 days',
            ),
          ),
          const SizedBox(width: 12),
          // كارد الـ Match Average
          Expanded(
            child: _buildMetricCard(
              icon: Icons.folder_open_outlined,
              iconColor: const Color(0xFF10B981),
              title: 'Your Match Average',
              value: '$matchAverage%',
              subtitle: 'Good Chance •',
              subtitleColor: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    Color subtitleColor = const Color(0xFF64748B),
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
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
