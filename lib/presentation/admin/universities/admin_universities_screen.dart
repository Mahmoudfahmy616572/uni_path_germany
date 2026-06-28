import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/widgets/curtain_drop.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/localization/app_localizations.dart';

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
          .from('universities').select('id, name, country, rankings, description, location, website_url, image_url, city, state, street, postal_code, lat, lon, university_type, ba_ban_id, logo_url').order('name').range(0, _pageSize - 1).timeout(const Duration(seconds: 10));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
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
          .from('universities').select('id, name, country, rankings, description, location, website_url, image_url, city, state, street, postal_code, lat, lon, university_type, ba_ban_id, logo_url').order('name').range(from, to).timeout(const Duration(seconds: 10));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
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
        title: Text(AppLocalizations.of(context).translate('deleteAccount')),
        content: Text(AppLocalizations.of(context).translate('deleteWarning')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).translate('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context).translate('yesDelete'), style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('university_programs').delete().eq('university_id', id).timeout(const Duration(seconds: 10));
      await Supabase.instance.client.from('universities').delete().eq('id', id).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('universityDeleted')), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCsv() async {
    final csvData = _universities.isEmpty
        ? await Supabase.instance.client.from('universities').select('id, name, country, rankings, description, location, website_url, image_url, city, state, street, postal_code, lat, lon, university_type, ba_ban_id, logo_url').order('name').timeout(const Duration(seconds: 10))
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
              columns: [
                DataColumn(label: Text(AppLocalizations.of(context).translate('name'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('countryField'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('rank'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('location'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('actions'))),
              ],
              rows: _filtered.map((u) => DataRow(cells: [
                DataCell(Text(u['name']?.toString() ?? '')),
                DataCell(Text(u['country']?.toString() ?? '')),
                DataCell(Text(u['rankings']?.toString() ?? '—')),
                DataCell(Text(u['location']?.toString() ?? '—')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit_outlined, size: 20.sp), onPressed: () => _editDialog(u)),
                    IconButton(icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp), onPressed: () => _delete(u['id']?.toString() ?? '')),
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
        title: CurtainDrop(index: 0, child: Text(t.translate('adminUniversities'))),
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
                              Icon(Icons.school_outlined, size: 48.sp, color: Colors.grey[300]),
                              SizedBox(height: 8.h),
                              Text(_searchCtrl.text.isEmpty ? t.translate('noUniversities') : t.translate('noResults'), style: TextStyle(color: Colors.grey[500])),
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
                                        child: Text(u['name']?.toString().substring(0, 2).toUpperCase() ?? 'UN', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                                      ),
                                      title: Text(u['name']?.toString() ?? ''),
                                      subtitle: Text('${u['country']?.toString() ?? ''}  •  Rank: ${u['rankings']?.toString() ?? '—'}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined, size: 20.sp),
                                            onPressed: () => _editDialog(u),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp),
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
          ),
        ],
      ),
      floatingActionButton: CurtainDrop(
        index: 4,
        child: FloatingActionButton.extended(
        onPressed: () => _editDialog(null),
        icon: const Icon(Icons.add),
        label: Text(t.translate('addUniversity')),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
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
    final cityCtrl = TextEditingController(text: existing?['city']?.toString() ?? '');
    final stateCtrl = TextEditingController(text: existing?['state']?.toString() ?? '');
    final streetCtrl = TextEditingController(text: existing?['street']?.toString() ?? '');
    final postalCtrl = TextEditingController(text: existing?['postal_code']?.toString() ?? '');
    final latCtrl = TextEditingController(text: existing?['lat']?.toString() ?? '');
    final lonCtrl = TextEditingController(text: existing?['lon']?.toString() ?? '');
    final typeCtrl = TextEditingController(text: existing?['university_type']?.toString() ?? '');
    final baBanCtrl = TextEditingController(text: existing?['ba_ban_id']?.toString() ?? '');
    String? logoUrl = existing?['logo_url']?.toString();
    String? imageUrl = existing?['image_url']?.toString();
    bool uploadingLogo = false;
    bool uploadingImage = false;

    Future<void> pickImage(bool isLogo) async {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;
      final pickedFile = result.files.single;
      if (pickedFile.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image too large. Maximum size is 5 MB.'), backgroundColor: Colors.red));
        }
        return;
      }
      setState(() {
        if (isLogo) uploadingLogo = true; else uploadingImage = true;
      });
      if (pickedFile.path == null) {
        setState(() { if (isLogo) uploadingLogo = false; else uploadingImage = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not access file'), backgroundColor: Colors.red));
        return;
      }
      final file = File(pickedFile.path!);
      final ext = pickedFile.extension ?? 'jpg';
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
        title: Text(existing != null ? AppLocalizations.of(context).translate('editUniversity') : AppLocalizations.of(context).translate('addUniversity')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('name') + ' *', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: countryCtrl, decoration: const InputDecoration(labelText: 'Country *', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: rankCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('rank'), border: OutlineInputBorder()), keyboardType: TextInputType.number, style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: locationCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('location'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: websiteCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('website'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: uploadingLogo ? SizedBox(width: 16.w, height: 16.h, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.image, size: 18.sp),
                      label: Text(logoUrl != null ? 'Change Logo' : 'Upload Logo', style: TextStyle(fontSize: 12.sp)),
                      onPressed: uploadingLogo ? null : () => pickImage(true),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: uploadingImage ? SizedBox(width: 16.w, height: 16.h, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.photo_library, size: 18.sp),
                      label: Text(imageUrl != null ? 'Change Image' : 'Upload Image', style: TextStyle(fontSize: 12.sp)),
                      onPressed: uploadingImage ? null : () => pickImage(false),
                    ),
                  ),
                ],
              ),
              if (logoUrl != null) ...[
                SizedBox(height: 8.h),
                Text('Logo: $logoUrl', style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (imageUrl != null) ...[
                SizedBox(height: 4.h),
                Text('Image: $imageUrl', style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              SizedBox(height: 12.h),
              TextField(controller: cityCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('city'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: streetCtrl, decoration: const InputDecoration(labelText: 'Street', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: postalCtrl, decoration: const InputDecoration(labelText: 'Postal Code', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()), keyboardType: TextInputType.number, style: TextStyle(fontSize: 14.sp))),
                  SizedBox(width: 8.w),
                  Expanded(child: TextField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()), keyboardType: TextInputType.number, style: TextStyle(fontSize: 14.sp))),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'University Type', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: baBanCtrl, decoration: const InputDecoration(labelText: 'BA/BAN ID', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              SizedBox(height: 12.h),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3, style: TextStyle(fontSize: 14.sp)),
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
      final lat = double.tryParse(latCtrl.text.trim());
      final lon = double.tryParse(lonCtrl.text.trim());
      final data = <String, dynamic>{
        'name': name,
        'country': country,
        'rankings': rankText.isNotEmpty ? int.parse(rankText) : null,
        'description': descText.isNotEmpty ? descText : null,
        'website_url': websiteText.isNotEmpty ? websiteText : null,
        'logo_url': logoUrl,
        'image_url': imageUrl,
        'location': locationText.isNotEmpty ? locationText : null,
        'city': cityCtrl.text.trim(),
        'state': stateCtrl.text.trim(),
        'street': streetCtrl.text.trim(),
        'postal_code': postalCtrl.text.trim(),
        'lat': lat,
        'lon': lon,
        'university_type': typeCtrl.text.trim(),
        'ba_ban_id': baBanCtrl.text.trim(),
      };
      if (existing != null) {
        await Supabase.instance.client.from('universities').update(data).eq('id', existing['id']).timeout(const Duration(seconds: 10));
      } else {
        await Supabase.instance.client.from('universities').insert(data).timeout(const Duration(seconds: 10));
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('universityUpdated')), backgroundColor: const Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }
}
