import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/localization/app_localizations.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  int _userCount = 0;
  int _univCount = 0;
  int _appCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        Supabase.instance.client.from('profiles').select('id').timeout(const Duration(seconds: 10)),
        Supabase.instance.client.from('universities').select('id').timeout(const Duration(seconds: 10)),
        Supabase.instance.client.from('my_applications').select('id').timeout(const Duration(seconds: 10)),
      ]);
      if (!mounted) return;
      setState(() {
        _userCount = (results[0] as List).length;
        _univCount = (results[1] as List).length;
        _appCount = (results[2] as List).length;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('adminSettings')),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(24.r),
        children: [
          Text(AppLocalizations.of(context).translate('adminSettings'), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          SizedBox(height: 16.h),
          _card(
            children: [
              Text(AppLocalizations.of(context).translate('appConfig'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
              SizedBox(height: 16.h),
              _infoRow(AppLocalizations.of(context).translate('appName'), 'UniPath'),
              _infoRow(AppLocalizations.of(context).translate('version'), '1.0.0'),
              _infoRow(AppLocalizations.of(context).translate('supabaseProject'), 'marrlrggovghhnmhtbgs'),
              _infoRow(AppLocalizations.of(context).translate('environment'), 'Production'),
            ],
          ),
          SizedBox(height: 16.h),
          _card(
            children: [
              Text(AppLocalizations.of(context).translate('databaseOverview'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
              SizedBox(height: 16.h),
              _infoRow(AppLocalizations.of(context).translate('totalUsers'), _userCount.toString()),
              _infoRow(AppLocalizations.of(context).translate('totalUniversities'), _univCount.toString()),
              _infoRow(AppLocalizations.of(context).translate('totalApplications'), _appCount.toString()),
            ],
          ),
          SizedBox(height: 16.h),
          _card(
            children: [
              Text(AppLocalizations.of(context).translate('quickInfo'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
              SizedBox(height: 16.h),
              Text(
                AppLocalizations.of(context).translate('adminDescription'),
                style: TextStyle(color: Colors.grey[600], fontSize: 13.sp, height: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8.r, offset: Offset(0.r, 2.r))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 160.w,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13.sp)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp))),
        ],
      ),
    );
  }
}
