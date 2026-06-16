import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';

import 'package:germany_travel/core/widgets/curtain_drop.dart';
import '../../../core/utils/csv_export.dart';

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
          .order('username');
      if (!mounted) return;
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e'), backgroundColor: Colors.red));
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
        title: const Text('Edit Document Flags'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${user['username']?.toString() ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Transcripts', style: TextStyle(fontSize: 14)),
                value: hasTranscripts,
                onChanged: (v) => hasTranscripts = v ?? hasTranscripts,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('CV', style: TextStyle(fontSize: 14)),
                value: hasCv,
                onChanged: (v) => hasCv = v ?? hasCv,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('SOP', style: TextStyle(fontSize: 14)),
                value: hasSop,
                onChanged: (v) => hasSop = v ?? hasSop,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Bachelor Cert', style: TextStyle(fontSize: 14)),
                value: hasBachelorCert,
                onChanged: (v) => hasBachelorCert = v ?? hasBachelorCert,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
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
      }).eq('id', user['id']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document flags updated'), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCsv() async {
    final csvData = _users.map((u) => {
      'username': u['username'],
      'email': u['email'],
      'transcripts': u['has_transcripts'] == true ? 'Yes' : 'No',
      'cv': u['has_cv'] == true ? 'Yes' : 'No',
      'sop': u['has_sop'] == true ? 'Yes' : 'No',
      'bachelor_cert': u['has_bachelor_cert'] == true ? 'Yes' : 'No',
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
              columns: const [
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Transcripts')),
                DataColumn(label: Text('CV')),
                DataColumn(label: Text('SOP')),
                DataColumn(label: Text('Bachelor Cert')),
              ],
              rows: _users.map((u) => DataRow(cells: [
                DataCell(Text(u['username']?.toString() ?? '')),
                DataCell(Text(u['email']?.toString() ?? '')),
                DataCell(Text(u['has_transcripts'] == true ? 'Yes' : 'No')),
                DataCell(Text(u['has_cv'] == true ? 'Yes' : 'No')),
                DataCell(Text(u['has_sop'] == true ? 'Yes' : 'No')),
                DataCell(Text(u['has_bachelor_cert'] == true ? 'Yes' : 'No')),
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
        title: CurtainDrop(index: 0, child: const Text('Documents')),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          CurtainDrop(index: 1, child: IconButton(icon: const Icon(Icons.download, size: 20), tooltip: 'Export CSV', onPressed: _exportCsv)),
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
                      Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text('No documents uploaded yet', style: TextStyle(color: Colors.grey[500])),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, i) {
                          final u = _users[i];
                          final docs = <String, dynamic>{
                            'Transcripts': u['has_transcripts'],
                            'CV': u['has_cv'],
                            'SOP': u['has_sop'],
                            'Bachelor Cert': u['has_bachelor_cert'],
                          };
                          final hasDocs = _hasAnyDoc(u);
                          if (!hasDocs) return const SizedBox.shrink();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                child: Text((u['username']?.toString().substring(0, 1).toUpperCase() ?? '?'), style: const TextStyle(color: Color(0xFF6366F1))),
                              ),
                              title: Text(u['username']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${docs.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).length} document(s) uploaded'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _editDialog(u),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: docs.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((e) => Chip(
                                      avatar: Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 18),
                                      label: Text(e.key, style: const TextStyle(fontSize: 12)),
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
