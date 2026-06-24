import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/ai/gemini_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/themes/app_colors.dart';

class GermanAssistantSheet extends StatefulWidget {
  const GermanAssistantSheet({super.key});

  @override
  State<GermanAssistantSheet> createState() => _GermanAssistantSheetState();
}

class _GermanAssistantSheetState extends State<GermanAssistantSheet> {
  final _gemini = sl<GeminiService>();
  final _messages = <_ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: 'Hallo! Ich bin Ihr Deutsch-Tutor. Schreiben Sie etwas auf Deutsch, und ich helfe Ihnen!',
      isUser: false,
    ));
    _messages.add(_ChatMessage(
      text: 'Hello! I am your German tutor. Write something in German, and I will help you!',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
    });

    try {
      final response = await _gemini.germanPractice(text);
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: response, isUser: false));
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: 'Tut mir leid, es gab einen Fehler: $e', isUser: false));
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(Icons.translate, color: Color(0xFF4F46E5), size: 20),
                  ),
                  SizedBox(width: 12.w),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('German Tutor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Practice your German', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16.r),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessage(msg, isDark);
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Write in German...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      icon: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.r),
        constraints: BoxConstraints(maxWidth: 0.8.sw),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF4F46E5) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16.r).copyWith(
            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
            bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Text(msg.text,
            style: TextStyle(
              fontSize: 14.sp,
              color: msg.isUser ? Colors.white : (isDark ? AppColors.textMain : const Color(0xFF0F172A)),
            )),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
