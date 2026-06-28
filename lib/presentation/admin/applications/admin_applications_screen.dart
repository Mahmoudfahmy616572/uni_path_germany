import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/widgets/curtain_drop.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/localization/app_localizations.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 30;

  final _statusOptions = ['saved', 'applied', 'interview', 'accepted', 'rejected', 'withdrawn'];
  final _portalStatusOptions = ['pending', 'submitted', 'acknowledged', 'accepted', 'rejected'];
  final _paymentStatusOptions = ['unpaid', 'paid', 'waived'];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _page = 0;
      _hasMore = true;
    });
    try {
      final data = await Supabase.instance.client
          .from('my_applications').select('id, user_id, university_name, program_name, university_id, program_id, status, portal_status, payment_status, portal_url, notes, created_at').order('created_at', ascending: false).range(0, _pageSize - 1).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _applications = List<Map<String, dynamic>>.from(data);
        _hasMore = data.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client.channel('admin-applications');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'my_applications',
      callback: (_) {
        if (mounted) _load();
      },
    ).subscribe();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      _page++;
      final from = _page * _pageSize;
      final to = from + _pageSize - 1;
      final data = await Supabase.instance.client
          .from('my_applications').select('id, user_id, university_name, program_name, university_id, program_id, status, portal_status, payment_status, portal_url, notes, created_at').order('created_at', ascending: false).range(from, to).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _applications.addAll(List<Map<String, dynamic>>.from(data));
        _hasMore = data.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await Supabase.instance.client.from('my_applications').update({'status': status}).eq('id', id).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('applicationUpdated')), backgroundColor: const Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _editDialog(Map<String, dynamic> existing) async {
    final universityNameCtrl = TextEditingController(text: existing['university_name']?.toString() ?? '');
    final programNameCtrl = TextEditingController(text: existing['program_name']?.toString() ?? '');
    final universityIdCtrl = TextEditingController(text: existing['university_id']?.toString() ?? '');
    final programIdCtrl = TextEditingController(text: existing['program_id']?.toString() ?? '');
    final portalUrlCtrl = TextEditingController(text: existing['portal_url']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: existing['notes']?.toString() ?? '');
    String status = existing['status']?.toString() ?? 'saved';
    String portalStatus = existing['portal_status']?.toString() ?? 'pending';
    String paymentStatus = existing['payment_status']?.toString() ?? 'unpaid';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('editApplication')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: existing['user_id']?.toString() ?? ''),
                decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('userID'), border: OutlineInputBorder()),
                style: TextStyle(fontSize: 14.sp),
                readOnly: true,
                enabled: false,
              ),
              SizedBox(height: 12.h),
              TextField(controller: universityNameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('universityName'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: programNameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('programName'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: universityIdCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('universityID'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: programIdCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('programID'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('status'), border: OutlineInputBorder()),
                dropdownColor: const Color(0xFF1E293B),
                items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => status = v ?? status,
                style: TextStyle(fontSize: 14.sp, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 12.h),
              TextField(controller: portalUrlCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('portalUrl'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: portalStatus,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('portalStatus'), border: OutlineInputBorder()),
                dropdownColor: const Color(0xFF1E293B),
                items: _portalStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => portalStatus = v ?? portalStatus,
                style: TextStyle(fontSize: 14.sp, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: paymentStatus,
                decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('paymentStatus'), border: OutlineInputBorder()),
                dropdownColor: const Color(0xFF1E293B),
                items: _paymentStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => paymentStatus = v ?? paymentStatus,
                style: TextStyle(fontSize: 14.sp, color: Color(0xFF0F172A)),
              ),
              SizedBox(height: 12.h),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).translate('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context).translate('save'))),
        ],
      ),
    );
    if (result != true) return;

    try {
      await Supabase.instance.client.from('my_applications').update({
        'university_name': universityNameCtrl.text.trim(),
        'program_name': programNameCtrl.text.trim(),
        'university_id': universityIdCtrl.text.trim(),
        'program_id': programIdCtrl.text.trim(),
        'status': status,
        'portal_url': portalUrlCtrl.text.trim(),
        'portal_status': portalStatus,
        'payment_status': paymentStatus,
        'notes': notesCtrl.text.trim(),
      }).eq('id', existing['id']).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('applicationUpdated')), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('deleteAccount')),
        content: Text(AppLocalizations.of(context).translate('deleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).translate('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context).translate('yesDelete'), style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('my_applications').delete().eq('id', id).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('applicationDeleted')), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCsv() async {
    final csvData = _applications.map((a) => {
      'user_id': a['user_id'],
      'university_name': a['university_name'],
      'program_name': a['program_name'],
      'status': a['status'],
      'portal_status': a['portal_status'] ?? 'pending',
      'payment_status': a['payment_status'] ?? 'unpaid',
      'portal_url': a['portal_url'] ?? '',
      'created_at': a['created_at'],
    }).toList();
    await exportCsv(
      data: csvData,
      filename: 'applications_export',
      columns: ['user_id', 'university_name', 'program_name', 'status', 'portal_status', 'payment_status', 'portal_url', 'created_at'],
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(AppLocalizations.of(context).translate('userID'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('universityName'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('programName'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('status'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('portalStatus'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('paymentStatus'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('actions'))),
              ],
              rows: _applications.map((a) => DataRow(cells: [
                DataCell(Text(a['user_id']?.toString() ?? '')),
                DataCell(Text(a['university_name']?.toString() ?? '')),
                DataCell(Text(a['program_name']?.toString() ?? '')),
                DataCell(_statusBadge(a['status']?.toString() ?? 'saved')),
                DataCell(_portalBadge(a['portal_status']?.toString() ?? 'pending')),
                DataCell(_paymentBadge(a['payment_status']?.toString() ?? 'unpaid')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit_outlined, size: 20.sp), onPressed: () => _editDialog(a)),
                    if (a['portal_url'] != null && a['portal_url'].toString().isNotEmpty)
                      IconButton(icon: Icon(Icons.open_in_new, size: 20.sp), onPressed: () => _openPortal(a['portal_url'].toString())),
                    IconButton(icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp), onPressed: () => _delete(a['id']?.toString() ?? '')),
                  ],
                )),
              ])).toList(),
            ),
          ),
          if (_hasMore)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      icon: const Icon(Icons.expand_more),
                      label: Text(AppLocalizations.of(context).translate('loadMore')),
                      onPressed: _loadMore,
                    ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return const Color(0xFF10B981);
      case 'rejected': return const Color(0xFFEF4444);
      case 'interview': return const Color(0xFFF59E0B);
      case 'applied': return const Color(0xFF6366F1);
      case 'withdrawn': return Colors.grey;
      default: return const Color(0xFF94A3B8);
    }
  }

  Color _portalStatusColor(String status) {
    switch (status) {
      case 'submitted': return const Color(0xFF6366F1);
      case 'acknowledged': return const Color(0xFFF59E0B);
      case 'accepted': return const Color(0xFF10B981);
      case 'rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFF94A3B8);
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case 'paid': return const Color(0xFF10B981);
      case 'waived': return const Color(0xFF6366F1);
      default: return const Color(0xFF94A3B8);
    }
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(status, style: TextStyle(fontSize: 11.sp, color: _statusColor(status), fontWeight: FontWeight.w600)),
    );
  }

  Widget _portalBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _portalStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(status, style: TextStyle(fontSize: 11.sp, color: _portalStatusColor(status), fontWeight: FontWeight.w600)),
    );
  }

  Widget _paymentBadge(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _paymentStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(status, style: TextStyle(fontSize: 11.sp, color: _paymentStatusColor(status), fontWeight: FontWeight.w600)),
    );
  }

  void _openPortal(String url) {
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: CurtainDrop(index: 0, child: Text(AppLocalizations.of(context).translate('adminApplications'))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          CurtainDrop(index: 1, child: IconButton(icon: Icon(Icons.download, size: 20.sp), tooltip: AppLocalizations.of(context).translate('exportCsv'), onPressed: _exportCsv)),
        ],
      ),
      body: CurtainDrop(
        index: 2,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, size: 48.sp, color: Colors.grey[300]),
                      SizedBox(height: 8.h),
                      Text(AppLocalizations.of(context).translate('noApplications'), style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) {
                      return _buildDataTable();
                    }
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.r),
                        itemCount: _applications.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == _applications.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                        : TextButton.icon(
                                            icon: const Icon(Icons.expand_more),
                                            label: Text(AppLocalizations.of(context).translate('loadMore')),
                                            onPressed: _loadMore,
                                      ),
                              ),
                            );
                          }
                          final a = _applications[i];
                          final userId = a['user_id']?.toString() ?? '';
                          return Card(
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: ExpansionTile(
                              title: Text(userId.length >= 8 ? userId.substring(0, 8) : userId, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                              subtitle: Text(a['university_name']?.toString() ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: _statusColor(a['status']?.toString() ?? '').withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(a['status']?.toString() ?? 'saved', style: TextStyle(fontSize: 11.sp, color: _statusColor(a['status']?.toString() ?? ''), fontWeight: FontWeight.w600)),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 20.sp),
                                    onPressed: () => _editDialog(a),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp),
                                    onPressed: () => _delete(a['id']?.toString() ?? ''),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('User: $userId', style: TextStyle(fontSize: 13.sp)),
                                      SizedBox(height: 8.h),
                                      Text('Program: ${a['program_name']?.toString() ?? ''}', style: TextStyle(fontSize: 13.sp)),
                                      SizedBox(height: 8.h),
                                      Row(
                                        children: [
                                          _portalBadge(a['portal_status']?.toString() ?? 'pending'),
                                          SizedBox(width: 8.w),
                                          _paymentBadge(a['payment_status']?.toString() ?? 'unpaid'),
                                        ],
                                      ),
                                      if (a['portal_url'] != null && a['portal_url'].toString().isNotEmpty) ...[
                                        SizedBox(height: 8.h),
                                        InkWell(
                                          onTap: () => _openPortal(a['portal_url'].toString()),
                                          child: Text('Portal: ${a['portal_url']}', style: TextStyle(fontSize: 12.sp, color: Color(0xFF6366F1), decoration: TextDecoration.underline)),
                                        ),
                                      ],
                                      SizedBox(height: 8.h),
                                      Text('Notes: ${a['notes']?.toString() ?? '—'}', style: TextStyle(fontSize: 13.sp)),
                                      SizedBox(height: 12.h),
                                      DropdownButtonFormField<String>(
                                        initialValue: a['status']?.toString(),
                                        decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('status'), border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h)),
                                        dropdownColor: const Color(0xFF1E293B),
                                        items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                                        onChanged: (v) {
                                          if (v != null) _updateStatus(a['id']?.toString() ?? '', v);
                                        },
                                        style: TextStyle(fontSize: 13.sp, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
