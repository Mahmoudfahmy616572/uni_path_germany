import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PolicyViewerScreen extends StatelessWidget {
  final String title;
  final String content;

  const PolicyViewerScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = content.split('\n');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(fontSize: 16.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildContentLines(lines, theme),
        ),
      ),
    );
  }

  List<Widget> _buildContentLines(List<String> lines, ThemeData theme) {
    final widgets = <Widget>[];
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        widgets.add(SizedBox(height: 8.h));
        continue;
      }

      if (line.startsWith('## ')) {
        final text = line.substring(3).trim();
        widgets.add(Padding(
          padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: EdgeInsets.only(bottom: 6.h),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.textTheme.bodyMedium?.color,
              height: 1.5,
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}
