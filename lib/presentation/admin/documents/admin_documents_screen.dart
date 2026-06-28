import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/widgets/curtain_drop.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/localization/app_localizations.dart';

class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
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
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('id, username, email, has_transcripts, has_cv, has_sop, has_bachelor_cert')
          .order('username').timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client.channel('admin-documents');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      callback: (_) {
        if (mounted) _load();
      },
    ).subscribe();
  }

  Future<void> _editDialog(Map<String, dynamic> user) async {
    bool hasTranscripts = user['has_transcripts'] == true;
    bool hasCv = user['has_cv'] == true;
    bool hasSop = user['has_sop'] == true;
    bool hasBachelorCert = user['has_bachelor_cert'] == true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${AppLocalizations.of(context).translate('edit')} Document Flags'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${user['username']?.toString() ?? ''}', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 12.h),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context).translate('academicTranscripts'), style: TextStyle(fontSize: 14.sp)),
                value: hasTranscripts,
                onChanged: (v) => hasTranscripts = v ?? hasTranscripts,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context).translate('cvResume'), style: TextStyle(fontSize: 14.sp)),
                value: hasCv,
                onChanged: (v) => hasCv = v ?? hasCv,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context).translate('sopMotivationLetter'), style: TextStyle(fontSize: 14.sp)),
                value: hasSop,
                onChanged: (v) => hasSop = v ?? hasSop,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text(AppLocalizations.of(context).translate('bachelorCertificate'), style: TextStyle(fontSize: 14.sp)),
                value: hasBachelorCert,
                onChanged: (v) => hasBachelorCert = v ?? hasBachelorCert,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
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
      await Supabase.instance.client.from('profiles').update({
        'has_transcripts': hasTranscripts,
        'has_cv': hasCv,
        'has_sop': hasSop,
        'has_bachelor_cert': hasBachelorCert,
      }).eq('id', user['id']).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('applicationUpdated')), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).translate('error')}$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCsv() async {
    final csvData = _users.map((u) => {
      'username': u['username'],
      'email': u['email'],
      'transcripts': u['has_transcripts'] == true ? AppLocalizations.of(context).translate('yes') : AppLocalizations.of(context).translate('no'),
      'cv': u['has_cv'] == true ? AppLocalizations.of(context).translate('yes') : AppLocalizations.of(context).translate('no'),
      'sop': u['has_sop'] == true ? AppLocalizations.of(context).translate('yes') : AppLocalizations.of(context).translate('no'),
      'bachelor_cert': u['has_bachelor_cert'] == true ? AppLocalizations.of(context).translate('yes') : AppLocalizations.of(context).translate('no'),
    }).toList();
    await exportCsv(
      data: csvData,
      filename: 'documents_export',
      columns: ['username', 'email', 'transcripts', 'cv', 'sop', 'bachelor_cert'],
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
                DataColumn(label: Text(AppLocalizations.of(context).translate('username'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('email'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('academicTranscripts'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('cvResume'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('sopMotivationLetter'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('bachelorCertificate'))),
              ],
              rows: _users.map((u) => DataRow(cells: [
                DataCell(Text(u['username']?.toString() ?? '')),
                DataCell(Text(u['email']?.toString() ?? '')),
                DataCell(Text(u['has_transcripts'] == true ? AppLocalizations.of(context).translate('yes') : AppLocalizations.of(context).translate('no'))),
                DataCell(Text(u['has_cv'] == true ? AppLocalizations.of(context).translate('yes') : AppLocalizations.of(context).translate('no'))),
                DataCell(Text(u['has_sop'] == true ? AppLocalizations.of(context).translate('yes') : AppLocalizations.of(context).translate('no'))),
                DataCell(Text(u['has_bachelor_cert'] == true ? AppLocalizations.of(context).translate('yes') : AppLocalizations.of(context).translate('no'))),
              ])).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: CurtainDrop(index: 0, child: Text(AppLocalizations.of(context).translate('adminDocuments'))),
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
          : _users.where(_hasAnyDoc).isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open_outlined, size: 48.sp, color: Colors.grey[300]),
                      SizedBox(height: 8.h),
                      Text(AppLocalizations.of(context).translate('noDocuments'), style: TextStyle(color: Colors.grey[500])),
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
                        itemCount: _users.length,
                        itemBuilder: (context, i) {
                          final u = _users[i];
                          final docs = <String, dynamic>{
                            AppLocalizations.of(context).translate('academicTranscripts'): u['has_transcripts'],
                            AppLocalizations.of(context).translate('cvResume'): u['has_cv'],
                            AppLocalizations.of(context).translate('sopMotivationLetter'): u['has_sop'],
                            AppLocalizations.of(context).translate('bachelorCertificate'): u['has_bachelor_cert'],
                          };
                          final hasDocs = _hasAnyDoc(u);
                          if (!hasDocs) return const SizedBox.shrink();

                          return Card(
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                child: Text((u['username']?.toString().substring(0, 1).toUpperCase() ?? '?'), style: const TextStyle(color: Color(0xFF6366F1))),
                              ),
                              title: Text(u['username']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${docs.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).length} document(s) uploaded'),
                              trailing: IconButton(
                                icon: Icon(Icons.edit_outlined, size: 20.sp),
                                onPressed: () => _editDialog(u),
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: docs.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((e) => Chip(
                                      avatar: Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 18.sp),
                                      label: Text(e.key, style: TextStyle(fontSize: 12.sp)),
                                      backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    )).toList(),
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

  bool _hasAnyDoc(Map<String, dynamic> u) {
    return [u['has_transcripts'], u['has_cv'], u['has_sop'], u['has_bachelor_cert']]
        .any((v) => v != null && v.toString().isNotEmpty);
  }
}
