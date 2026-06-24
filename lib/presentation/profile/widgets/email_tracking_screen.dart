import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/email_tracking/email_connection_service.dart';
import '../../../core/services/services_locator.dart' as di;
import '../../../core/themes/app_colors.dart';
import '../../../core/widgets/curtain_drop.dart';
import '../../../core/widgets/webview_screen.dart';

class EmailTrackingScreen extends StatefulWidget {
  const EmailTrackingScreen({super.key});

  @override
  State<EmailTrackingScreen> createState() => _EmailTrackingScreenState();
}

class _EmailTrackingScreenState extends State<EmailTrackingScreen> {
  final _service = di.sl<EmailConnectionService>();
  List<EmailConnection> _connections = [];
  List<EmailStatusLog> _logs = [];
  bool _loadingConnections = true;
  bool _loadingLogs = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      _loadConnections(),
      _loadLogs(),
    ]);
  }

  Future<void> _loadConnections() async {
    setState(() => _loadingConnections = true);
    final connections = await _service.loadConnections();
    if (mounted) setState(() { _connections = connections; _loadingConnections = false; });
  }

  Future<void> _loadLogs() async {
    setState(() => _loadingLogs = true);
    final logs = await _service.getStatusLogs();
    if (mounted) setState(() { _logs = logs; _loadingLogs = false; });
  }

  Future<void> _connectEmail(String provider) async {
    final url = provider == 'gmail'
        ? _service.getGmailAuthUrl(state: provider)
        : _service.getOutlookAuthUrl(state: provider);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebViewScreen(
          url: url.toString(),
          title: provider == 'gmail' ? 'Connect Gmail' : 'Connect Outlook',
          oauthRedirectUri: _service.oAuthRedirectUri,
          onOAuthCallback: (code, state) => _exchangeCode(provider, code),
        ),
      ),
    );
  }

  Future<void> _exchangeCode(String provider, String code) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.functions.invoke('email-sync', method: HttpMethod.post, body: {
        'action': 'token-exchange',
        'code': code,
        'provider': provider,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$provider connected!')));
        await _loadConnections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
      }
    }
  }

  Future<void> _toggleAutoSync(String id, bool value) async {
    await _service.toggleAutoSync(id, value);
    await _loadConnections();
  }

  Future<void> _deleteConnection(String id) async {
    await _service.deleteConnection(id);
    await _loadConnections();
  }

  Future<void> _triggerSync() async {
    setState(() => _syncing = true);
    await _service.triggerSync();
    setState(() => _syncing = false);
    await _loadLogs();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync completed')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Email Tracking'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _syncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.sync, size: 20.sp),
            onPressed: _syncing ? null : _triggerSync,
            tooltip: 'Sync now',
          ),
        ],
      ),
      body: CurtainDrop(
        index: 0,
        child: RefreshIndicator(
          onRefresh: () async {
            await _load();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.r),
            children: [
              _buildConnectedAccounts(isDark),
              SizedBox(height: 24.h),
              _buildRecentLogs(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedAccounts(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, size: 18.sp),
              SizedBox(width: 8.w),
              Text('Connected Accounts', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16.h),
          if (_loadingConnections)
            const Center(child: CircularProgressIndicator())
          else if (_connections.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Column(
                children: [
                  Icon(Icons.mail_outline, size: 40.sp, color: Colors.grey[300]),
                  SizedBox(height: 12.h),
                  Text('No email accounts connected', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  SizedBox(height: 4.h),
                  Text('Connect Gmail or Outlook to auto-detect\napplication status from your inbox.', style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]), textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ..._connections.map((c) => _connectionTile(c, isDark)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _connectEmail('gmail'),
                  icon: Icon(Icons.email, size: 16.sp),
                  label: const Text('Connect Gmail'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _connectEmail('outlook'),
                  icon: Icon(Icons.email, size: 16.sp),
                  label: const Text('Connect Outlook'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _connectionTile(EmailConnection c, bool isDark) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        leading: Icon(c.provider == 'gmail' ? Icons.email : Icons.email_outlined, color: const Color(0xFF6366F1)),
        title: Text(c.email, style: TextStyle(fontSize: 13.sp)),
        subtitle: Text(c.provider.toUpperCase(), style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: c.autoSync,
              onChanged: (v) => _toggleAutoSync(c.id, v),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp),
              onPressed: () => _deleteConnection(c.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogs(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18.sp),
              SizedBox(width: 8.w),
              Text('Recent Detections', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16.h),
          if (_loadingLogs)
            const Center(child: CircularProgressIndicator())
          else if (_logs.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40.sp, color: Colors.grey[300]),
                  SizedBox(height: 12.h),
                  Text('No status changes yet', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  SizedBox(height: 4.h),
                  Text('Sync your email to check for\napplication status updates.', style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]), textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ..._logs.map((l) => _logTile(l, isDark)),
        ],
      ),
    );
  }

  Widget _logTile(EmailStatusLog l, bool isDark) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        l.detectedStatus != null ? Icons.check_circle : Icons.email,
        size: 20.sp,
        color: l.applied ? const Color(0xFF10B981) : Colors.grey,
      ),
      title: Text(l.emailSubject ?? 'Unknown', style: TextStyle(fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(l.detectedStatus != null ? 'Detected: ${l.detectedStatus}' : 'No status detected', style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
    );
  }
}
