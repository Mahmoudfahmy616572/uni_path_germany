import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  int _userCount = 0;
  int _universityCount = 0;
  int _applicationCount = 0;
  int _documentUsers = 0;
  List<Map<String, dynamic>> _recentUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    // Run each query independently so one failure doesn't kill the rest
    try { final d = await Supabase.instance.client.from('profiles').select('id'); if (mounted) _userCount = d.length; } catch (_) {}
    try { final d = await Supabase.instance.client.from('universities').select('id'); if (mounted) _universityCount = d.length; } catch (_) {}
    try { final d = await Supabase.instance.client.from('my_applications').select('id'); if (mounted) _applicationCount = d.length; } catch (_) {}
    try { final d = await Supabase.instance.client.from('profiles').select('id').or('has_transcripts.not.is.null,has_cv.not.is.null,has_sop.not.is.null,has_bachelor_cert.not.is.null'); if (mounted) _documentUsers = d.length; } catch (_) {}
    try { final d = await Supabase.instance.client.from('profiles').select('id, username, email, created_at').order('created_at', ascending: false).limit(8); if (mounted) _recentUsers = List<Map<String, dynamic>>.from(d); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Dashboard', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text('Welcome back, Admin', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 24),
            if (_loading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else ...[
              _buildStatsRow(),
              const SizedBox(height: 32),
              _buildQuickActions(context),
              const SizedBox(height: 32),
              _buildRecentActivity(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 600 ? 4 : 2;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(Icons.people_outline, 'Users', _formatCount(_userCount), const Color(0xFF6366F1)),
            _StatCard(Icons.school_outlined, 'Universities', _formatCount(_universityCount), const Color(0xFF10B981)),
            _StatCard(Icons.assignment_outlined, 'Applications', _formatCount(_applicationCount), const Color(0xFFF59E0B)),
            _StatCard(Icons.folder_outlined, 'Documents', _formatCount(_documentUsers), const Color(0xFFEF4444)),
          ].map((card) => SizedBox(width: (constraints.maxWidth - 16 * (cols - 1)) / cols, child: card)).toList(),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionChip(Icons.person_add_outlined, 'Add User', () => context.go('/admin/users')),
            _ActionChip(Icons.add_business_outlined, 'Add University', () => context.go('/admin/universities')),
            _ActionChip(Icons.playlist_add_outlined, 'Add Program', () => context.go('/admin/programs')),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: _recentUsers.isEmpty
              ? Center(child: Column(children: [
                  Icon(Icons.hourglass_empty, color: Colors.grey[400], size: 40),
                  const SizedBox(height: 8),
                  Text('No recent activity', style: TextStyle(color: Colors.grey[500])),
                ]))
              : Column(
                  children: _recentUsers.map((u) => _activityRow(u)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _activityRow(Map<String, dynamic> user) {
    final at = user['created_at']?.toString() ?? '';
    final when = at.isNotEmpty ? _timeAgo(DateTime.tryParse(at) ?? DateTime.now()) : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            child: Text(
              (user['username']?.toString().substring(0, 1).toUpperCase() ?? '?'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['username']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(user['email']?.toString() ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(when, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: const Color(0xFF1E293B),
        side: BorderSide(color: const Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
