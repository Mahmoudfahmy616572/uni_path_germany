import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';

import 'package:germany_travel/core/widgets/curtain_drop.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/widgets/webview_screen.dart';

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
          .from('my_applications').select('*').order('created_at', ascending: false).range(0, _pageSize - 1);
      if (!mounted) return;
      setState(() {
        _applications = List<Map<String, dynamic>>.from(data);
        _hasMore = data.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e'), backgroundColor: Colors.red));
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
          .from('my_applications').select('*').order('created_at', ascending: false).range(from, to);
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
      await Supabase.instance.client.from('my_applications').update({'status': status}).eq('id', id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status changed to $status'), backgroundColor: const Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
        title: const Text('Edit Application'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: existing['user_id']?.toString() ?? ''),
                decoration: const InputDecoration(labelText: 'User ID', border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 14),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextField(controller: universityNameCtrl, decoration: const InputDecoration(labelText: 'University Name', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextField(controller: programNameCtrl, decoration: const InputDecoration(labelText: 'Program Name', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextField(controller: universityIdCtrl, decoration: const InputDecoration(labelText: 'University ID', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextField(controller: programIdCtrl, decoration: const InputDecoration(labelText: 'Program ID', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                dropdownColor: const Color(0xFF1E293B),
                items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => status = v ?? status,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              TextField(controller: portalUrlCtrl, decoration: const InputDecoration(labelText: 'Portal URL', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: portalStatus,
                decoration: const InputDecoration(labelText: 'Portal Status', border: OutlineInputBorder()),
                dropdownColor: const Color(0xFF1E293B),
                items: _portalStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => portalStatus = v ?? portalStatus,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentStatus,
                decoration: const InputDecoration(labelText: 'Payment Status', border: OutlineInputBorder()),
                dropdownColor: const Color(0xFF1E293B),
                items: _paymentStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => paymentStatus = v ?? paymentStatus,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14), maxLines: 3),
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
      }).eq('id', existing['id']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application updated'), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('my_applications').delete().eq('id', id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application deleted'), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
              columns: const [
                DataColumn(label: Text('User ID')),
                DataColumn(label: Text('University')),
                DataColumn(label: Text('Program')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Portal')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Actions')),
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
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editDialog(a)),
                    if (a['portal_url'] != null && a['portal_url'].toString().isNotEmpty)
                      IconButton(icon: const Icon(Icons.open_in_new, size: 20), onPressed: () => _openPortal(a['portal_url'].toString())),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _delete(a['id']?.toString() ?? '')),
                  ],
                )),
              ])).toList(),
            ),
          ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _loadingMore
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load More'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600)),
    );
  }

  Widget _portalBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _portalStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, color: _portalStatusColor(status), fontWeight: FontWeight.w600)),
    );
  }

  Widget _paymentBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _paymentStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(fontSize: 11, color: _paymentStatusColor(status), fontWeight: FontWeight.w600)),
    );
  }

  void _openPortal(String url) {
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WebViewScreen(url: url)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: CurtainDrop(index: 0, child: const Text('Applications')),
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
          : _applications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text('No applications yet', style: TextStyle(color: Colors.grey[500])),
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
                        itemCount: _applications.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == _applications.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : TextButton.icon(
                                        icon: const Icon(Icons.expand_more),
                                        label: const Text('Load More'),
                                        onPressed: _loadMore,
                                      ),
                              ),
                            );
                          }
                          final a = _applications[i];
                          final userId = a['user_id']?.toString() ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              title: Text(userId.length >= 8 ? userId.substring(0, 8) : userId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text(a['university_name']?.toString() ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(a['status']?.toString() ?? '').withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(a['status']?.toString() ?? 'saved', style: TextStyle(fontSize: 11, color: _statusColor(a['status']?.toString() ?? ''), fontWeight: FontWeight.w600)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    onPressed: () => _editDialog(a),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _delete(a['id']?.toString() ?? ''),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('User: $userId', style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 8),
                                      Text('Program: ${a['program_name']?.toString() ?? ''}', style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _portalBadge(a['portal_status']?.toString() ?? 'pending'),
                                          const SizedBox(width: 8),
                                          _paymentBadge(a['payment_status']?.toString() ?? 'unpaid'),
                                        ],
                                      ),
                                      if (a['portal_url'] != null && a['portal_url'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () => _openPortal(a['portal_url'].toString()),
                                          child: Text('Portal: ${a['portal_url']}', style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), decoration: TextDecoration.underline)),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text('Notes: ${a['notes']?.toString() ?? '—'}', style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        initialValue: a['status']?.toString(),
                                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                        dropdownColor: const Color(0xFF1E293B),
                                        items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: Colors.white)))).toList(),
                                        onChanged: (v) {
                                          if (v != null) _updateStatus(a['id']?.toString() ?? '', v);
                                        },
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
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
