import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/email_tracking/email_connection_service.dart';
import '../../../core/services/services_locator.dart' as di;
import '../../../core/themes/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/curtain_drop.dart';

class EmailTrackingScreen extends StatefulWidget {
  const EmailTrackingScreen({super.key});

  @override
  State<EmailTrackingScreen> createState() => _EmailTrackingScreenState();
}

class _EmailTrackingScreenState extends State<EmailTrackingScreen> {
  final _service = di.sl<EmailConnectionService>();
  final _appLinks = AppLinks();
  List<EmailConnection> _connections = [];
  List<EmailStatusLog> _logs = [];
  bool _loadingConnections = true;
  bool _loadingLogs = true;
  bool _syncing = false;
  bool _connecting = false;
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _load();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _deepLinkSub = _appLinks.uriLinkStream.listen(_handleDeepLink, onError: (e) => log.e('Deep link stream error: $e'));
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    }).catchError((e) { log.e('getInitialLink error: $e'); });
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted) return;
    if (uri.toString().startsWith(_service.oAuthRedirectUri)) {
      final success = uri.queryParameters['success'];
      if (success == 'true') {
        if (!_service.verifyOAuthState(uri.queryParameters['state'])) {
          log.w('OAuth state mismatch — ignoring redirect');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('providerConnected').replaceAll('{provider}', uri.queryParameters['provider'] ?? ''))),
        );
        _loadConnections();
      }
    }
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
    setState(() => _connecting = true);
    final url = _service.getOAuthAuthorizeUrl(provider);

    await launchUrl(url, mode: LaunchMode.externalApplication);
    if (mounted) setState(() => _connecting = false);
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
    if (!mounted) return;
    setState(() => _syncing = false);
    await _loadLogs();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('syncCompleted'))));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('emailTracking')),
        backgroundColor: isDark ? AppColors.darkCardBg : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _syncing
                ? SizedBox(width: 20.r, height: 20.r, child: CircularProgressIndicator(strokeWidth: 2.r))
                : Icon(Icons.sync, size: 20.sp),
            onPressed: _syncing ? null : _triggerSync,
            tooltip: AppLocalizations.of(context).translate('syncNow'),
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
              _buildHint(isDark),
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
              Text(AppLocalizations.of(context).translate('connectedAccounts'), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16.h),
          if (_connecting)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_loadingConnections)
            const Center(child: CircularProgressIndicator())
          else if (_connections.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Column(
                children: [
                  Icon(Icons.mail_outline, size: 40.sp, color: Colors.grey[300]),
                  SizedBox(height: 12.h),
                  Text(AppLocalizations.of(context).translate('noEmailAccounts'), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  SizedBox(height: 4.h),
                  Text(AppLocalizations.of(context).translate('connectEmailPrompt'), style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]), textAlign: TextAlign.center),
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
                  onPressed: _connecting ? null : () => _connectEmail('gmail'),
                  icon: Icon(Icons.email, size: 16.sp),
                  label: Text(AppLocalizations.of(context).translate('connectGmail')),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _connecting ? null : () => _connectEmail('outlook'),
                  icon: Icon(Icons.email, size: 16.sp),
                  label: Text(AppLocalizations.of(context).translate('connectOutlook')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHint(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 20.sp,
            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('emailTrackingDesc'),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textMain : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  AppLocalizations.of(context).translate('emailTrackingHint'),
                  style: TextStyle(
                    fontSize: 11.sp,
                    height: 1.5,
                    color: isDark ? AppColors.textMuted : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
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
              Text(AppLocalizations.of(context).translate('recentDetections'), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
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
                  Text(AppLocalizations.of(context).translate('noStatusChanges'), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey[500])),
                  SizedBox(height: 4.h),
                  Text(AppLocalizations.of(context).translate('syncEmailPrompt'), style: TextStyle(fontSize: 12.sp, color: Colors.grey[400]), textAlign: TextAlign.center),
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
      title: Text(l.emailSubject ?? AppLocalizations.of(context).translate('unknown'), style: TextStyle(fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(l.detectedStatus != null ? AppLocalizations.of(context).translate('detected').replaceAll('{status}', l.detectedStatus!) : AppLocalizations.of(context).translate('noStatusDetected'), style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
    );
  }
}
