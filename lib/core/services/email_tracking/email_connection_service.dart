import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/logger.dart';

class EmailConnection {
  final String id;
  final String provider;
  final String email;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final DateTime? lastSyncAt;
  final bool autoSync;

  EmailConnection({
    required this.id,
    required this.provider,
    required this.email,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.lastSyncAt,
    this.autoSync = true,
  });

  factory EmailConnection.fromMap(Map<String, dynamic> map) {
    return EmailConnection(
      id: map['id']?.toString() ?? '',
      provider: map['provider']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      accessToken: map['access_token']?.toString(),
      refreshToken: map['refresh_token']?.toString(),
      tokenExpiresAt: map['token_expires_at'] != null ? DateTime.tryParse(map['token_expires_at'].toString()) : null,
      lastSyncAt: map['last_sync_at'] != null ? DateTime.tryParse(map['last_sync_at'].toString()) : null,
      autoSync: map['auto_sync'] as bool? ?? true,
    );
  }
}

class EmailStatusLog {
  final String id;
  final String? applicationId;
  final String? connectionId;
  final String? emailSubject;
  final String? emailFrom;
  final String? detectedStatus;
  final String? detectedPayment;
  final String? rawSnippet;
  final bool applied;
  final DateTime createdAt;

  EmailStatusLog({
    required this.id,
    this.applicationId,
    this.connectionId,
    this.emailSubject,
    this.emailFrom,
    this.detectedStatus,
    this.detectedPayment,
    this.rawSnippet,
    this.applied = false,
    required this.createdAt,
  });

  factory EmailStatusLog.fromMap(Map<String, dynamic> map) {
    return EmailStatusLog(
      id: map['id']?.toString() ?? '',
      applicationId: map['application_id']?.toString(),
      connectionId: map['connection_id']?.toString(),
      emailSubject: map['email_subject']?.toString(),
      emailFrom: map['email_from']?.toString(),
      detectedStatus: map['detected_status']?.toString(),
      detectedPayment: map['detected_payment']?.toString(),
      rawSnippet: map['raw_snippet']?.toString(),
      applied: map['applied'] as bool? ?? false,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }
}

class EmailConnectionService {
  final SupabaseClient client;
  List<EmailConnection> _connections = [];

  EmailConnectionService(this.client);

  /// Deep link URI that the Edge Function redirects to after OAuth completes.
  String get oAuthRedirectUri => 'com.unipath.app://email_callback';

  /// Base URL for the email-sync Edge Function.
  String get _edgeFunctionUrl {
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://marrlrggovghhnmhtbgs.supabase.co',
    );
    return '$supabaseUrl/functions/v1/email-sync';
  }

  /// Build the URL to send the user to for OAuth authorization.
  /// Opens in the system browser; the Edge Function handles the full OAuth flow
  /// and redirects back to [oAuthRedirectUri] on success.
  Uri getOAuthAuthorizeUrl(String provider) {
    final userId = client.auth.currentUser?.id ?? '';
    _lastOAuthState = _generateState();
    return Uri.parse('$_edgeFunctionUrl?action=authorize&provider=$provider&user_id=$userId&client_state=$_lastOAuthState');
  }

  String? _lastOAuthState;
  final _random = Random();

  String _generateState() =>
      List.generate(32, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[_random.nextInt(36)]).join();

  bool verifyOAuthState(String? state) =>
      state != null && _lastOAuthState != null && state == _lastOAuthState;

  Future<List<EmailConnection>> loadConnections() async {
    try {
      final data = await client.from('email_connections').select('*').order('created_at', ascending: false).timeout(const Duration(seconds: 10));
      _connections = (data as List).map((e) => EmailConnection.fromMap(Map<String, dynamic>.from(e))).toList();
      return _connections;
    } catch (e) {
      log.e('Failed to load email connections: $e');
      return [];
    }
  }

  Future<bool> saveConnection(String provider, String email, {String? accessToken, String? refreshToken}) async {
    try {
      await client.from('email_connections').upsert({
        'provider': provider,
        'email': email,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,provider').timeout(const Duration(seconds: 10));
      await loadConnections();
      return true;
    } catch (e) {
      log.e('Failed to save email connection: $e');
      return false;
    }
  }

  Future<bool> deleteConnection(String id) async {
    try {
      await client.from('email_connections').delete().eq('id', id).timeout(const Duration(seconds: 10));
      _connections.removeWhere((c) => c.id == id);
      return true;
    } catch (e) {
      log.e('Failed to delete email connection: $e');
      return false;
    }
  }

  Future<bool> toggleAutoSync(String id, bool enabled) async {
    try {
      await client.from('email_connections').update({'auto_sync': enabled}).eq('id', id).timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      log.e('Failed to toggle auto sync: $e');
      return false;
    }
  }

  Future<List<EmailStatusLog>> getStatusLogs({int limit = 20}) async {
    try {
      final data = await client.from('email_status_log').select('*').order('created_at', ascending: false).limit(limit).timeout(const Duration(seconds: 10));
      return (data as List).map((e) => EmailStatusLog.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      log.e('Failed to load email status logs: $e');
      return [];
    }
  }

  Future<bool> triggerSync() async {
    try {
      final response = await client.functions.invoke('email-sync', method: HttpMethod.post, body: {});
      log.i('Email sync triggered: ${response.data}');
      return true;
    } catch (e) {
      log.e('Failed to trigger email sync: $e');
      return false;
    }
  }
}
