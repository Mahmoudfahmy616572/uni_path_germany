import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/widgets/curtain_drop.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/localization/app_localizations.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 30;
  final _searchCtrl = TextEditingController();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _page = 0;
      _hasMore = true;
    });
    try {
      final data = await Supabase.instance.client
          .from('profiles').select('id, username, email, role, created_at').order('created_at', ascending: false).range(0, _pageSize - 1).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _filtered = _users;
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
    _channel = Supabase.instance.client.channel('admin-users');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'profiles',
      callback: (_) {
        if (mounted) _loadUsers();
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
          .from('profiles').select('id, username, email, role, created_at').order('created_at', ascending: false).range(from, to).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _users.addAll(List<Map<String, dynamic>>.from(data));
        _filtered = _users;
        _hasMore = data.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _users;
      } else {
        final q = query.toLowerCase();
        _filtered = _users.where((u) =>
          (u['username']?.toString() ?? '').toLowerCase().contains(q) ||
          (u['email']?.toString() ?? '').toLowerCase().contains(q)
        ).toList();
      }
    });
  }

  Future<void> _toggleAdmin(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    final isAdmin = user['role'] == 'admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAdmin ? AppLocalizations.of(context).translate('revokeAdmin') : AppLocalizations.of(context).translate('promoteAdmin')),
        content: Text('${isAdmin ? AppLocalizations.of(context).translate('revokeAdmin') : AppLocalizations.of(context).translate('promoteAdmin')} ${user['username']?.toString() ?? ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).translate('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAdmin ? AppLocalizations.of(context).translate('revokeAdmin') : AppLocalizations.of(context).translate('promoteAdmin'), style: TextStyle(color: isAdmin ? Colors.orange : const Color(0xFF6366F1)))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('profiles').update({'role': isAdmin ? 'user' : 'admin'}).eq('id', id).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user['username']} ${isAdmin ? AppLocalizations.of(context).translate('userRole') : AppLocalizations.of(context).translate('adminRole')}'), backgroundColor: const Color(0xFF10B981)));
      _loadUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _editDialog(Map<String, dynamic> existing) async {
    final usernameCtrl = TextEditingController(text: existing['username']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: existing['email']?.toString() ?? '');
    String role = existing['role']?.toString() ?? 'user';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('editUser')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: usernameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('username'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: emailCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('email'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                dropdownColor: const Color(0xFF1E293B),
                items: ['user', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r == 'user' ? AppLocalizations.of(context).translate('userRole') : AppLocalizations.of(context).translate('adminRole'), style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => role = v ?? role,
                style: TextStyle(fontSize: 14.sp, color: Color(0xFF0F172A)),
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

    final name = usernameCtrl.text.trim();
    if (name.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', 'Username cannot be empty')), backgroundColor: Colors.red));
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').update({'username': name, 'role': role}).eq('id', existing['id']).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('userUpdated')), backgroundColor: Color(0xFF10B981)));
      _loadUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteUser(String id) async {
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
      await Supabase.instance.client.from('profiles').delete().eq('id', id).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('userDeleted')), backgroundColor: Color(0xFF10B981)));
      _loadUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCsv() async {
    final csvData = _users.isEmpty
        ? await Supabase.instance.client.from('profiles').select('id, username, email, role, created_at').order('created_at', ascending: false).timeout(const Duration(seconds: 10))
        : _users;
    await exportCsv(
      data: List<Map<String, dynamic>>.from(csvData),
      filename: 'users_export',
      columns: ['username', 'email', 'role', 'created_at'],
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
                DataColumn(label: Text(AppLocalizations.of(context).translate('role'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('actions'))),
              ],
              rows: _filtered.map((u) => DataRow(cells: [
                DataCell(Text(u['username']?.toString() ?? '')),
                DataCell(Text(u['email']?.toString() ?? '')),
                DataCell(u['role'] == 'admin'
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6.r)),
                        child: Text(AppLocalizations.of(context).translate('adminRole'), style: TextStyle(fontSize: 11.sp, color: Colors.amber)),
                      )
                    : Text(AppLocalizations.of(context).translate('userRole'))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(u['role'] == 'admin' ? Icons.shield : Icons.shield_outlined, color: u['role'] == 'admin' ? Colors.amber : Colors.grey, size: 20.sp),
                      tooltip: u['role'] == 'admin' ? AppLocalizations.of(context).translate('revokeAdmin') : AppLocalizations.of(context).translate('promoteAdmin'),
                      onPressed: () => _toggleAdmin(u),
                    ),
                    IconButton(icon: Icon(Icons.edit_outlined, size: 20.sp), onPressed: () => _editDialog(u)),
                    IconButton(icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp), onPressed: () => _deleteUser(u['id']?.toString() ?? '')),
                  ],
                )),
              ])).toList(),
            ),
          ),
          if (_hasMore && _searchCtrl.text.isEmpty)
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: CurtainDrop(index: 0, child: Text(t.translate('adminUsers'))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          CurtainDrop(index: 1, child: IconButton(icon: Icon(Icons.download, size: 20.sp), tooltip: t.translate('exportCsv'), onPressed: _exportCsv)),
        ],
      ),
      body: Column(
        children: [
          CurtainDrop(
            index: 2,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: t.translate('searchHint'),
                  prefixIcon: Icon(Icons.search, size: 20.sp),
                  suffixIcon: _searchCtrl.text.isEmpty ? null : IconButton(
                    icon: Icon(Icons.clear, size: 18.sp),
                    onPressed: () { _searchCtrl.clear(); _filter(''); },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                style: TextStyle(fontSize: 14.sp),
                onChanged: _filter,
              ),
            ),
          ),
          Expanded(
            child: CurtainDrop(
              index: 3,
              child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 48.sp, color: Colors.grey[300]),
                            SizedBox(height: 8.h),
                            Text(_searchCtrl.text.isEmpty ? t.translate('noUsers') : t.translate('noResults'), style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 900) {
                            return _buildDataTable();
                          }
                          return RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                              itemCount: _filtered.length + (_hasMore && _searchCtrl.text.isEmpty ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i == _filtered.length) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Center(
                                      child: _loadingMore
                                          ? const CircularProgressIndicator()
                                          : TextButton.icon(
                                              icon: const Icon(Icons.expand_more),
                                              label: Text(t.translate('loadMore')),
                                              onPressed: _loadMore,
                                            ),
                                    ),
                                  );
                                }
                                final u = _filtered[i];
                                return Card(
                                    margin: EdgeInsets.only(bottom: 8.h),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                      child: Text(
                                        (u['username']?.toString().substring(0, 1).toUpperCase() ?? '?'),
                                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(u['username']?.toString() ?? 'No Name'),
                                    subtitle: Text(u['email']?.toString() ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (u['role'] == 'admin')
                                          Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6.r)),
                        child: Text(t.translate('adminRole'), style: TextStyle(fontSize: 11.sp, color: Colors.amber)),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            u['role'] == 'admin' ? Icons.shield : Icons.shield_outlined,
                                            color: u['role'] == 'admin' ? Colors.amber : Colors.grey,
                                            size: 20.sp,
                                          ),
                                          tooltip: u['role'] == 'admin' ? t.translate('revokeAdmin') : t.translate('promoteAdmin'),
                                          onPressed: () => _toggleAdmin(u),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, size: 20.sp),
                                          onPressed: () => _editDialog(u),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp),
                                          onPressed: () => _deleteUser(u['id']?.toString() ?? ''),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
