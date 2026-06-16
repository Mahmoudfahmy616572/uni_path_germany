import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:realtime_client/realtime_client.dart';

import 'package:germany_travel/core/widgets/curtain_drop.dart';
import '../../../core/utils/csv_export.dart';

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
          .from('profiles').select('*').order('created_at', ascending: false).range(0, _pageSize - 1);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load: $e'), backgroundColor: Colors.red));
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
          .from('profiles').select('*').order('created_at', ascending: false).range(from, to);
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
        title: Text(isAdmin ? 'Revoke Admin' : 'Promote to Admin'),
        content: Text('${isAdmin ? 'Revoke admin privileges from' : 'Grant admin privileges to'} ${user['username']?.toString() ?? 'this user'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAdmin ? 'Revoke' : 'Promote', style: TextStyle(color: isAdmin ? Colors.orange : const Color(0xFF6366F1)))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('profiles').update({'role': isAdmin ? 'user' : 'admin'}).eq('id', id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${user['username']} is now ${isAdmin ? 'a regular user' : 'an admin'}'), backgroundColor: const Color(0xFF10B981)));
      _loadUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _editDialog(Map<String, dynamic> existing) async {
    final usernameCtrl = TextEditingController(text: existing['username']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: existing['email']?.toString() ?? '');
    String role = existing['role']?.toString() ?? 'user';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                dropdownColor: const Color(0xFF1E293B),
                items: ['user', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => role = v ?? role,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
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

    final name = usernameCtrl.text.trim();
    if (name.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username cannot be empty'), backgroundColor: Colors.red));
      return;
    }

    try {
      await Supabase.instance.client.from('profiles').update({'username': name, 'role': role}).eq('id', existing['id']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User updated'), backgroundColor: Color(0xFF10B981)));
      _loadUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('profiles').delete().eq('id', id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted'), backgroundColor: Color(0xFF10B981)));
      _loadUsers();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCsv() async {
    final csvData = _users.isEmpty
        ? await Supabase.instance.client.from('profiles').select('*').order('created_at', ascending: false)
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
              columns: const [
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _filtered.map((u) => DataRow(cells: [
                DataCell(Text(u['username']?.toString() ?? '')),
                DataCell(Text(u['email']?.toString() ?? '')),
                DataCell(u['role'] == 'admin'
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Admin', style: TextStyle(fontSize: 11, color: Colors.amber)),
                      )
                    : const Text('user')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(u['role'] == 'admin' ? Icons.shield : Icons.shield_outlined, color: u['role'] == 'admin' ? Colors.amber : Colors.grey, size: 20),
                      tooltip: u['role'] == 'admin' ? 'Revoke admin' : 'Make admin',
                      onPressed: () => _toggleAdmin(u),
                    ),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editDialog(u)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteUser(u['id']?.toString() ?? '')),
                  ],
                )),
              ])).toList(),
            ),
          ),
          if (_hasMore && _searchCtrl.text.isEmpty)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: CurtainDrop(index: 0, child: const Text('Users')),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          CurtainDrop(index: 1, child: IconButton(icon: const Icon(Icons.download, size: 20), tooltip: 'Export CSV', onPressed: _exportCsv)),
        ],
      ),
      body: Column(
        children: [
          CurtainDrop(
            index: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isEmpty ? null : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () { _searchCtrl.clear(); _filter(''); },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                style: const TextStyle(fontSize: 14),
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
                            Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(_searchCtrl.text.isEmpty ? 'No users yet' : 'No results found', style: TextStyle(color: Colors.grey[500])),
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
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              itemCount: _filtered.length + (_hasMore && _searchCtrl.text.isEmpty ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (i == _filtered.length) {
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
                                final u = _filtered[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
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
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                            child: const Text('Admin', style: TextStyle(fontSize: 11, color: Colors.amber)),
                                          ),
                                        IconButton(
                                          icon: Icon(
                                            u['role'] == 'admin' ? Icons.shield : Icons.shield_outlined,
                                            color: u['role'] == 'admin' ? Colors.amber : Colors.grey,
                                            size: 20,
                                          ),
                                          tooltip: u['role'] == 'admin' ? 'Revoke admin' : 'Make admin',
                                          onPressed: () => _toggleAdmin(u),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          onPressed: () => _editDialog(u),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
