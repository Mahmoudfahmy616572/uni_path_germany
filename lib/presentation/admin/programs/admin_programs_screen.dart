import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:germany_travel/core/widgets/curtain_drop.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/localization/app_localizations.dart';

class AdminProgramsScreen extends StatefulWidget {
  const AdminProgramsScreen({super.key});

  @override
  State<AdminProgramsScreen> createState() => _AdminProgramsScreenState();
}

class _AdminProgramsScreenState extends State<AdminProgramsScreen> {
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _universities = [];
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
      final univs = await Supabase.instance.client.from('universities').select('id, name').order('name').timeout(const Duration(seconds: 10));
      final progs = await Supabase.instance.client.from('university_programs').select('*, universities(name)').order('program_name').timeout(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _universities = List<Map<String, dynamic>>.from(univs);
        _programs = List<Map<String, dynamic>>.from(progs);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client.channel('admin-programs');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'university_programs',
      callback: (_) {
        if (mounted) _load();
      },
    ).subscribe();
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
      await Supabase.instance.client.from('university_programs').delete().eq('id', id).timeout(const Duration(seconds: 10));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('programDeleted')), backgroundColor: Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportCsv() async {
    final csvData = _programs.map((p) => {
      'program_name': p['program_name'],
      'degree_type': p['degree_type'],
      'university': p['universities']?['name'],
      'major': p['major'],
      'duration': p['duration'],
      'intake_type': p['intake_type'],
      'language': p['language'],
      'instruction_language': p['instruction_language'],
      'deadline': p['deadline'],
      'required_gpa': p['required_gpa'],
      'application_fee': p['application_fee'],
      'tuition_fee_per_year': p['tuition_fee_per_year'],
      'curriculum': p['curriculum'],
      'requires_ielts': p['requires_ielts'],
      'min_ielts_score': p['min_ielts_score'],
      'accepts_moi': p['accepts_moi'],
    }).toList();
    await exportCsv(
      data: csvData,
      filename: 'programs_export',
      columns: ['program_name', 'degree_type', 'university', 'major', 'duration', 'intake_type', 'language', 'instruction_language', 'deadline', 'required_gpa', 'application_fee', 'tuition_fee_per_year', 'accepts_moi', 'requires_ielts', 'min_ielts_score'],
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
                DataColumn(label: Text(AppLocalizations.of(context).translate('programName'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('universityName'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('degree'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('major'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('duration'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('intake'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('language'))),
                DataColumn(label: Text(AppLocalizations.of(context).translate('actions'))),
              ],
              rows: _programs.map((p) => DataRow(cells: [
                DataCell(Text(p['program_name']?.toString() ?? '')),
                DataCell(Text(p['universities']?['name']?.toString() ?? '—')),
                DataCell(Text(p['degree_type']?.toString() ?? '')),
                DataCell(Text(p['major']?.toString() ?? '—')),
                DataCell(Text(p['duration']?.toString() ?? '—')),
                DataCell(Text(p['intake_type']?.toString() ?? '—')),
                DataCell(Text(p['language']?.toString() ?? '')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit_outlined, size: 20.sp), onPressed: () => _editDialog(p)),
                    IconButton(icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp), onPressed: () => _delete(p['id']?.toString() ?? '')),
                  ],
                )),
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
        title: CurtainDrop(index: 0, child: Text(AppLocalizations.of(context).translate('adminPrograms'))),
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
            : _programs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_remove_outlined, size: 48.sp, color: Colors.grey[300]),
SizedBox(height: 8.h),
                        Text(AppLocalizations.of(context).translate('noPrograms'), style: TextStyle(color: Colors.grey[500])),
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
                          itemCount: _programs.length,
                          itemBuilder: (context, i) {
                            final p = _programs[i];
                            final univName = p['universities']?['name']?.toString() ?? '—';
                            return Card(
                              margin: EdgeInsets.only(bottom: 8.h),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  child: Text((p['degree_type']?.toString().substring(0, 1).toUpperCase() ?? 'P'), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                ),
                                title: Text(p['program_name']?.toString() ?? ''),
                                subtitle: Text('$univName  •  ${p['degree_type']?.toString() ?? ''}  •  ${p['duration']?.toString() ?? ''}  •  ${p['intake_type']?.toString() ?? ''}  •  ${p['major']?.toString() ?? ''}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, size: 20.sp),
                                      onPressed: () => _editDialog(p),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, color: Colors.red, size: 20.sp),
                                      onPressed: () => _delete(p['id']?.toString() ?? ''),
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
      floatingActionButton: CurtainDrop(
        index: 3,
        child: FloatingActionButton.extended(
        onPressed: () => _editDialog(null),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).translate('addProgram')),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      ),
    );
  }

  Future<void> _editDialog(Map<String, dynamic>? existing) async {
    String? selectedUnivId = existing?['university_id']?.toString();
    final nameCtrl = TextEditingController(text: existing?['program_name']?.toString() ?? '');
    String selectedDegree = existing?['degree_type']?.toString() ?? 'Bachelor';
    String selectedDuration = existing?['duration']?.toString() ?? '4 years';
    String selectedIntake = existing?['intake_type']?.toString() ?? 'Winter';
    bool requiresIelts = existing?['requires_ielts'] == true || existing?['requires_ielts'] == 'true';
    bool acceptsMoi = existing?['accepts_moi'] == true || existing?['accepts_moi'] == 'true';
    final majorCtrl = TextEditingController(text: existing?['major']?.toString() ?? '');
    final requiredGpaCtrl = TextEditingController(text: existing?['required_gpa']?.toString() ?? '');
    final instrLangCtrl = TextEditingController(text: existing?['instruction_language']?.toString() ?? '');
    final appFeeCtrl = TextEditingController(text: existing?['application_fee']?.toString() ?? '');
    final tuitionCtrl = TextEditingController(text: existing?['tuition_fee_per_year']?.toString() ?? '');
    final ieltsScoreCtrl = TextEditingController(text: existing?['min_ielts_score']?.toString() ?? '');
    final curriculumCtrl = TextEditingController(text: existing?['curriculum']?.toString() ?? '');
    final langCtrl = TextEditingController(text: existing?['language']?.toString() ?? '');
    final deadlineCtrl = TextEditingController(text: existing?['deadline']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description']?.toString() ?? '');
    final dataSourceCtrl = TextEditingController(text: existing?['data_source']?.toString() ?? '');
    final linkCtrl = TextEditingController(text: existing?['link']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? AppLocalizations.of(context).translate('editProgram') : AppLocalizations.of(context).translate('addProgram')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedUnivId,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('universityName') + ' *', border: OutlineInputBorder()),
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  hint: Text(AppLocalizations.of(context).translate('selectUniversity'), style: TextStyle(color: Color(0xFF94A3B8))),
                  items: _universities.map((u) => DropdownMenuItem(value: u['id']?.toString(), child: Text(u['name']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF0F172A))))).toList(),
                  onChanged: (v) => setDialogState(() => selectedUnivId = v),
                  style: TextStyle(fontSize: 14.sp, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 12.h),
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('programName') + ' *', border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedDegree,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('degree') + ' *', border: OutlineInputBorder()),
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  items: ['Bachelor', 'Master', 'PhD'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Color(0xFF0F172A))))).toList(),
                  onChanged: (v) => setDialogState(() => selectedDegree = v ?? 'Bachelor'),
                  style: TextStyle(fontSize: 14.sp, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedDuration,
                  decoration: const InputDecoration(labelText: 'Duration', border: OutlineInputBorder()),
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  items: ['2 years', '3 years', '4 years'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Color(0xFF0F172A))))).toList(),
                  onChanged: (v) => setDialogState(() => selectedDuration = v ?? '4 years'),
                  style: TextStyle(fontSize: 14.sp, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 12.h),
                TextField(controller: langCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('language'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                TextField(controller: deadlineCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('deadline'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                TextField(controller: descCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('description'), border: OutlineInputBorder()), maxLines: 3, style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                TextField(controller: majorCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('major'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                TextField(controller: requiredGpaCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('requiredGpa'), border: OutlineInputBorder()), keyboardType: TextInputType.number, style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                TextField(controller: instrLangCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('languageOfInstruction'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedIntake,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('intake'), border: OutlineInputBorder()),
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  items: ['Winter', 'Summer'].map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: Color(0xFF0F172A))))).toList(),
                  onChanged: (v) => setDialogState(() => selectedIntake = v ?? 'Winter'),
                  style: TextStyle(fontSize: 14.sp, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 12.h),
                TextField(controller: appFeeCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('applicationFee'), border: OutlineInputBorder()), keyboardType: TextInputType.number, style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                TextField(controller: tuitionCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('tuitionFee'), border: OutlineInputBorder()), keyboardType: TextInputType.number, style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                TextField(controller: curriculumCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('curriculum'), border: OutlineInputBorder()), maxLines: 2, style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context).translate('ieltsRequired')),
                  value: requiresIelts,
                  onChanged: (v) => setDialogState(() => requiresIelts = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                if (requiresIelts) ...[
                  SizedBox(height: 8.h),
                  TextField(controller: ieltsScoreCtrl, decoration: const InputDecoration(labelText: 'Min IELTS Score', border: OutlineInputBorder()), keyboardType: TextInputType.number, style: TextStyle(fontSize: 14.sp)),
                  SizedBox(height: 12.h),
                ],
                CheckboxListTile(
                  title: Text(AppLocalizations.of(context).translate('moiAccepted')),
                  value: acceptsMoi,
                  onChanged: (v) => setDialogState(() => acceptsMoi = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                SizedBox(height: 12.h),
                TextField(controller: dataSourceCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('dataSource'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 12.h),
                TextField(controller: linkCtrl, decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('programUrl'), border: OutlineInputBorder()), style: TextStyle(fontSize: 14.sp)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).translate('cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context).translate('save'))),
          ],
        ),
      ),
    );

    if (result != true) return;

    final progName = nameCtrl.text.trim();

    String? error;
    if (selectedUnivId == null) {
      error = 'University is required';
    } else if (progName.isEmpty) {
      error = 'Program Name is required';
    }
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
      return;
    }

    try {
      final data = <String, dynamic>{
        'university_id': selectedUnivId,
        'program_name': progName,
        'degree_type': selectedDegree,
        'duration': selectedDuration,
        'language': langCtrl.text.trim(),
        'deadline': deadlineCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'major': majorCtrl.text.trim(),
        'required_gpa': requiredGpaCtrl.text.trim().isEmpty ? null : double.tryParse(requiredGpaCtrl.text.trim()),
        'instruction_language': instrLangCtrl.text.trim(),
        'intake_type': selectedIntake,
        'application_fee': appFeeCtrl.text.trim().isEmpty ? null : double.tryParse(appFeeCtrl.text.trim()),
        'tuition_fee_per_year': tuitionCtrl.text.trim().isEmpty ? null : double.tryParse(tuitionCtrl.text.trim()),
        'curriculum': curriculumCtrl.text.trim(),
        'requires_ielts': requiresIelts,
        'min_ielts_score': requiresIelts && ieltsScoreCtrl.text.trim().isNotEmpty ? double.tryParse(ieltsScoreCtrl.text.trim()) : null,
        'accepts_moi': acceptsMoi,
        'data_source': dataSourceCtrl.text.trim(),
        'program_url': linkCtrl.text.trim(),
      };
      if (existing != null) {
        await Supabase.instance.client.from('university_programs').update(data).eq('id', existing['id']).timeout(const Duration(seconds: 10));
      } else {
        await Supabase.instance.client.from('university_programs').insert(data).timeout(const Duration(seconds: 10));
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('programUpdated')), backgroundColor: const Color(0xFF10B981)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).translate('failedToLoad').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
    }
  }
}
