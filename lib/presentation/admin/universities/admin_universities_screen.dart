import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/utils/csv_export.dart';

class AdminUniversitiesScreen extends StatefulWidget {
  const AdminUniversitiesScreen({super.key});

  @override
  State<AdminUniversitiesScreen> createState() => _AdminUniversitiesScreenState();
}

class _AdminUniversitiesScreenState extends State<AdminUniversitiesScreen> {
  List<Map<String, dynamic>> _universities = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 20;
  final _searchCtrl = TextEditingController();
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
    _searchCtrl.dispose();
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
          .from('universities').select('*').order('name').range(0, _pageSize - 1);
      if (!mounted) return;
      setState(() {
        _universities = List<Map<String, dynamic>>.from(data);
        _filtered = _universities;
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
    _channel = Supabase.instance.client.channel('admin-universities');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'universities',
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
          .from('universities').select('*').order('name').range(from, to);
      if (!mounted) return;
      setState(() {
        _universities.addAll(List<Map<String, dynamic>>.from(data));
        _filtered = _universities;
        _hasMore = data.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load more: $e'), backgroundColor: Colors.red));
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _universities;
      } else {
        final q = query.toLowerCase();
        _filtered = _universities.where((u) =>
          (u['name']?.toString() ?? '').toLowerCase().contains(q) ||
          (u['country']?.toString() ?? '').toLowerCase().contains(q) ||
          (u['description']?.toString() ?? '').toLowerCase().contains(q)
        ).toList();
      }
    });
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete University'),
        content: const Text('This will also delete all associated programs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('university_programs').delete().eq('university_id', id);
      await Supabase.instance.client.from('universities').delete().eq('id', id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('University deleted'), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCsv() async {
    final csvData = _universities.isEmpty
        ? await Supabase.instance.client.from('universities').select('*').order('name')
        : _universities;
    await exportCsv(
      data: List<Map<String, dynamic>>.from(csvData),
      filename: 'universities_export',
      columns: ['name', 'country', 'rankings', 'location', 'website_url', 'description'],
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
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Country')),
                DataColumn(label: Text('Ranking')),
                DataColumn(label: Text('Location')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _filtered.map((u) => DataRow(cells: [
                DataCell(Text(u['name']?.toString() ?? '')),
                DataCell(Text(u['country']?.toString() ?? '')),
                DataCell(Text(u['rankings']?.toString() ?? '—')),
                DataCell(Text(u['location']?.toString() ?? '—')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editDialog(u)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _delete(u['id']?.toString() ?? '')),
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
        title: const Text('Universities'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.download, size: 20), tooltip: 'Export CSV', onPressed: _exportCsv),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, country...',
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_outlined, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(_searchCtrl.text.isEmpty ? 'No universities yet' : 'No results found', style: TextStyle(color: Colors.grey[500])),
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
                                      child: Text(u['name']?.toString().substring(0, 2).toUpperCase() ?? 'UN', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(u['name']?.toString() ?? ''),
                                    subtitle: Text('${u['country']?.toString() ?? ''}  •  Rank: ${u['rankings']?.toString() ?? '—'}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 20),
                                          onPressed: () => _editDialog(u),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () => _delete(u['id']?.toString() ?? ''),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editDialog(null),
        icon: const Icon(Icons.add),
        label: const Text('Add University'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _editDialog(Map<String, dynamic>? existing) async {
    final nameCtrl = TextEditingController(text: existing?['name']?.toString() ?? '');
    final countryCtrl = TextEditingController(text: existing?['country']?.toString() ?? '');
    final rankCtrl = TextEditingController(text: existing?['rankings']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final locationCtrl = TextEditingController(text: existing?['location']?.toString() ?? '');
    final websiteCtrl = TextEditingController(text: existing?['website_url']?.toString() ?? '');
    String? logoUrl = existing?['logo_url']?.toString();
    String? imageUrl = existing?['image_url']?.toString();
    bool uploadingLogo = false;
    bool uploadingImage = false;

    Future<void> pickImage(bool isLogo) async {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;
      setState(() {
        if (isLogo) uploadingLogo = true; else uploadingImage = true;
      });
      final file = File(result.files.single.path!);
      final ext = result.files.single.extension ?? 'jpg';
      final path = '${isLogo ? 'logos' : 'images'}/${const Uuid().v4()}.$ext';
      final resultUrl = await StorageService.uploadImage(path, file);
      final isValidUrl = resultUrl != null && resultUrl.startsWith('http');
      setState(() {
        if (isLogo) { uploadingLogo = false; if (isValidUrl) logoUrl = resultUrl; }
        else { uploadingImage = false; if (isValidUrl) imageUrl = resultUrl; }
      });
      if (resultUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed — run admin_setup.sql in SQL Editor to create the storage bucket.'), backgroundColor: Colors.red));
      } else if (!isValidUrl && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resultUrl!), backgroundColor: Colors.red));
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit University' : 'Add University'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextField(controller: countryCtrl, decoration: const InputDecoration(labelText: 'Country *', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextField(controller: rankCtrl, decoration: const InputDecoration(labelText: 'Ranking', border: OutlineInputBorder()), keyboardType: TextInputType.number, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              TextField(controller: websiteCtrl, decoration: const InputDecoration(labelText: 'Website URL', border: OutlineInputBorder()), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: uploadingLogo ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.image, size: 18),
                      label: Text(logoUrl != null ? 'Change Logo' : 'Upload Logo', style: const TextStyle(fontSize: 12)),
                      onPressed: uploadingLogo ? null : () => pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: uploadingImage ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_library, size: 18),
                      label: Text(imageUrl != null ? 'Change Image' : 'Upload Image', style: const TextStyle(fontSize: 12)),
                      onPressed: uploadingImage ? null : () => pickImage(false),
                    ),
                  ),
                ],
              ),
              if (logoUrl != null) ...[
                const SizedBox(height: 8),
                Text('Logo: $logoUrl', style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (imageUrl != null) ...[
                const SizedBox(height: 4),
                Text('Image: $imageUrl', style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3, style: const TextStyle(fontSize: 14)),
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

    final name = nameCtrl.text.trim();
    final country = countryCtrl.text.trim();
    final rankText = rankCtrl.text.trim();
    final websiteText = websiteCtrl.text.trim();
    final locationText = locationCtrl.text.trim();
    final descText = descCtrl.text.trim();

    String? error;
    if (name.isEmpty) error = 'Name is required';
    else if (country.isEmpty) error = 'Country is required';
    else if (rankText.isNotEmpty && int.tryParse(rankText) == null) {
      error = 'Ranking must be a valid integer (e.g. 42)';
    } else if (websiteText.isNotEmpty) {
      final uri = Uri.tryParse(websiteText);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        error = 'Website URL must start with http:// or https://';
      }
    }
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
      return;
    }

    try {
      final data = <String, dynamic>{
        'name': name,
        'country': country,
        'rankings': rankText.isNotEmpty ? int.parse(rankText) : null,
        'description': descText.isNotEmpty ? descText : null,
        'website_url': websiteText.isNotEmpty ? websiteText : null,
        'logo_url': logoUrl,
        'image_url': imageUrl,
        'location': locationText.isNotEmpty ? locationText : null,
      };
      if (existing != null) {
        await Supabase.instance.client.from('universities').update(data).eq('id', existing['id']);
      } else {
        await Supabase.instance.client.from('universities').insert(data);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existing != null ? 'University updated' : 'University added'), backgroundColor: const Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
