import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  int _userCount = 0;
  int _univCount = 0;
  int _appCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        Supabase.instance.client.from('profiles').select('id'),
        Supabase.instance.client.from('universities').select('id'),
        Supabase.instance.client.from('my_applications').select('id'),
      ]);
      if (!mounted) return;
      setState(() {
        _userCount = (results[0] as List).length;
        _univCount = (results[1] as List).length;
        _appCount = (results[2] as List).length;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Admin Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _card(
            children: [
              const Text('App Configuration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 16),
              _infoRow('App Name', 'UniPath'),
              _infoRow('Version', '1.0.0'),
              _infoRow('Supabase Project', 'marrlrggovghhnmhtbgs'),
              _infoRow('Environment', 'Production'),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            children: [
              const Text('Database Overview', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 16),
              _infoRow('Total Users', _userCount.toString()),
              _infoRow('Total Universities', _univCount.toString()),
              _infoRow('Total Applications', _appCount.toString()),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            children: [
              const Text('Quick Info', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 16),
              Text(
                'This admin panel manages all data in the UniPath Supabase database. Changes made here are reflected immediately.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}
