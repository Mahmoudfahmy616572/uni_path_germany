import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/services/ai/ai_usage_service.dart';
import '../../../core/services/ai/gemini_service.dart';
import '../../../core/services/services_locator.dart';
import '../../../core/themes/app_colors.dart';
import '../../../domain/entities/university_entity.dart';

class _ChatMessage {
  final bool isUser;
  final String text;
  _ChatMessage({required this.isUser, required this.text});
}

class _QuickChip {
  final String emoji;
  final String label;
  const _QuickChip(this.emoji, this.label);
}

class UniPassAiSheet extends StatefulWidget {
  final UniversityEntity university;
  const UniPassAiSheet({super.key, required this.university});

  @override
  State<UniPassAiSheet> createState() => _UniPassAiSheetState();
}

class _UniPassAiSheetState extends State<UniPassAiSheet> {
  final _gemini = sl<GeminiService>();
  final _usage = sl<AiUsageService>();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  int _remainingUses = 10;
  bool _showChips = true;
  Map<String, dynamic>? _userProfile;

  static List<_QuickChip> _buildQuickChips(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    return [
      _QuickChip('📋', t('chipAdmissionReq')),
      _QuickChip('📅', t('chipDeadlineIntake')),
      _QuickChip('📄', t('chipRequiredDocs')),
      _QuickChip('🎯', t('chipImproveMatch')),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadUsage();
    _loadProfile();
  }

  Future<void> _loadUsage() async {
    final remaining = await _usage.getRemainingUses();
    if (mounted) setState(() => _remainingUses = remaining);
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('profiles')
          .select('gpa, max_gpa, target_major, degree_level, has_ielts, ielts_score, has_toefl, toefl_score, has_moi, has_german_cert, german_cert_type, german_cert_level, language_preference, intake, nationality, has_transcripts, has_bachelor_cert, has_sop, has_cv, has_language_cert, has_german_cert_doc')
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _userProfile = data);
    } catch (_) {}
  }

  static bool _isArabic(String text) {
    final arabic = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
    return arabic.hasMatch(text);
  }

  void _trimMessages() {
    if (_messages.length > 30) {
      _messages.removeRange(0, _messages.length - 30);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    if (_remainingUses <= 0) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text.trim()));
      _trimMessages();
      _isLoading = true;
      _showChips = false;
    });
    _scrollToBottom();

    final history = _messages
        .where((m) => m != _messages.last)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
        .toList();

    final langCode = _isArabic(text.trim()) ? 'ar' : 'en';

    try {
      final reply = await _gemini.askUniversityChat(
        university: widget.university,
        message: text.trim(),
        history: history,
        userProfile: _userProfile,
        languageCode: langCode,
      );
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(isUser: false, text: reply));
          _trimMessages();
          _isLoading = false;
        });
        _scrollToBottom();
      }
      await _usage.recordUsage();
      await _loadUsage();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            isUser: false,
            text: AppLocalizations.of(context).translate('aiErrorTryAgain'),
          ));
          _trimMessages();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              if (_remainingUses <= 0)
                _buildLimitBanner(context, isDark)
              else
                Expanded(
                  child: _buildBody(scrollController, isDark),
                ),
              if (_remainingUses > 0) _buildInput(context, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 20),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('uniPassAi'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: isDark ? AppColors.textMain : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).translate('usesLeft').replaceAll('{name}', widget.university.name).replaceAll('{count}', '$_remainingUses'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: isDark ? AppColors.textMuted : const Color(0xFF64748B)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitBanner(BuildContext context, bool isDark) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48.sp, color: const Color(0xFF94A3B8)),
              SizedBox(height: 16.h),
              Text(
                AppLocalizations.of(context).translate('aiQueriesUsed'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isDark ? AppColors.textMain : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context).translate('upgradePremium'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController outerController, bool isDark) {
    return ListView(
      controller: outerController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      children: [
        if (_messages.isEmpty) _buildWelcome(isDark),
        if (_showChips && _messages.isEmpty) _buildChips(),
        ..._messages.map((m) => _buildMessage(m, isDark)),
        if (_isLoading) _buildTypingIndicator(isDark),
      ],
    );
  }

  Widget _buildWelcome(bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('hiImUniPassAi'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: const Color(0xFF4F46E5),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).translate('aiWelcomeMsg').replaceAll('{name}', widget.university.name),
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? AppColors.textMuted : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    final chips = _buildQuickChips(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: chips.map((c) {
          return ActionChip(
            avatar: Text(c.emoji, style: TextStyle(fontSize: 16.sp)),
            label: Text(
              c.label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4F46E5),
              ),
            ),
            backgroundColor: const Color(0xFFEEF2FF),
            side: const BorderSide(color: Color(0xFFC7D2FE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            onPressed: () => _sendMessage(c.label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessage(_ChatMessage msg, bool isDark) {
    final isRtl = _isArabic(msg.text);
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: 0.8.sw),
        decoration: BoxDecoration(
          color: msg.isUser
              ? const Color(0xFF4F46E5)
              : isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16.r).copyWith(
            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
            bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        child: Text(
          msg.text,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(
            fontSize: 13.sp,
            color: msg.isUser ? Colors.white : (isDark ? AppColors.textMain : const Color(0xFF0F172A)),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16.r).copyWith(
            bottomLeft: Radius.zero,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(isDark),
            SizedBox(width: 4.w),
            _dot(isDark),
            SizedBox(width: 4.w),
            _dot(isDark),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool isDark) {
    return Container(
      width: 8.r,
      height: 8.r,
      decoration: BoxDecoration(
        color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInput(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 8.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isLoading,
                textInputAction: TextInputAction.send,
                onSubmitted: (v) {
                  _sendMessage(v);
                  _controller.clear();
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).translate('askAboutUni').replaceAll('{name}', widget.university.name),
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? AppColors.textMain : const Color(0xFF0F172A),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : const Color(0xFF4F46E5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                  color: Colors.white,
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        _sendMessage(_controller.text);
                        _controller.clear();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showUniPassAiSheet(BuildContext context, UniversityEntity university) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => UniPassAiSheet(university: university),
  );
}
