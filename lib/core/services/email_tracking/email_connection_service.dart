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

  Future<List<EmailConnection>> loadConnections() async {
    try {
      final data = await client.from('email_connections').select('*').order('created_at', ascending: false);
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
      }, onConflict: 'user_id,provider');
      await loadConnections();
      return true;
    } catch (e) {
      log.e('Failed to save email connection: $e');
      return false;
    }
  }

  Future<bool> deleteConnection(String id) async {
    try {
      await client.from('email_connections').delete().eq('id', id);
      _connections.removeWhere((c) => c.id == id);
      return true;
    } catch (e) {
      log.e('Failed to delete email connection: $e');
      return false;
    }
  }

  Future<bool> toggleAutoSync(String id, bool enabled) async {
    try {
      await client.from('email_connections').update({'auto_sync': enabled}).eq('id', id);
      return true;
    } catch (e) {
      log.e('Failed to toggle auto sync: $e');
      return false;
    }
  }

  Future<List<EmailStatusLog>> getStatusLogs({int limit = 20}) async {
    try {
      final data = await client.from('email_status_log').select('*').order('created_at', ascending: false).limit(limit);
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

  String get oAuthRedirectUri => 'http://localhost/email_callback';

  Uri getGmailAuthUrl({String? state}) {
    final params = <String, String>{
      'client_id': const String.fromEnvironment('GMAIL_CLIENT_ID', defaultValue: ''),
      'redirect_uri': '$oAuthRedirectUri',
      'response_type': 'code',
      'scope': 'https://www.googleapis.com/auth/gmail.readonly email',
      'access_type': 'offline',
      'prompt': 'consent',
    };
    if (state != null) params['state'] = state;
    return Uri.parse('https://accounts.google.com/o/oauth2/v2/auth').replace(queryParameters: params);
  }

  Uri getOutlookAuthUrl({String? state}) {
    final params = <String, String>{
      'client_id': const String.fromEnvironment('OUTLOOK_CLIENT_ID', defaultValue: ''),
      'redirect_uri': '$oAuthRedirectUri',
      'response_type': 'code',
      'scope': 'Mail.Read User.Read offline_access',
    };
    if (state != null) params['state'] = state;
    return Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/authorize').replace(queryParameters: params);
  }
}
