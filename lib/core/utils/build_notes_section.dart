import 'package:flutter/material.dart';

import '../../data/models/university_model.dart';

class BuildNotesSection extends StatefulWidget {
  final UniversityModel university;
  // 🎯 دالة Callback يتم تنفيذها عند الضغط على حفظ وتمرر النص الجديد
  final Future<void> Function(String newNotes) onSaveNotes;

  const BuildNotesSection({
    super.key,
    required this.university,
    required this.onSaveNotes, // إجباري عشان الشاشة تديله الأكشن بتاعها
  });

  @override
  State<BuildNotesSection> createState() => _BuildNotesSectionState();
}

class _BuildNotesSectionState extends State<BuildNotesSection> {
  late TextEditingController _notesController;
  bool _isEditing = false;
  bool _isLoading = false; // لمؤشر التحميل أثناء الحفظ في الـ Supabase

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.university.notes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant BuildNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // لو الـ Model اتحدث من بره، نحدث النص المكتوب
    if (oldWidget.university.notes != widget.university.notes && !_isEditing) {
      _notesController.text = widget.university.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Notes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4F46E5),
                    ),
                  )
                : TextButton(
                    onPressed: () async {
                      if (_isEditing) {
                        final newText = _notesController.text;

                        setState(() => _isLoading = true);

                        try {
                          // 🎯 نداء الدالة الممررة من الشاشة الأب بشكل آمن تماماً
                          await widget.onSaveNotes(newText);

                          setState(() {
                            _isEditing = false;
                            _isLoading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notes saved successfully! 🎉'),
                            ),
                          );
                        } catch (e) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error saving notes: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                    child: Text(
                      _isEditing ? 'Save' : 'Edit',
                      style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: _isEditing
              ? TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type your notes here...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                )
              : Text(
                  _notesController.text.isEmpty
                      ? 'No notes added yet. Click Edit to add your thoughts.'
                      : _notesController.text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
        ),
      ],
    );
  }
}
