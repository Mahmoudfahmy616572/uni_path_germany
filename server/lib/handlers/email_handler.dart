import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

class EmailHandler {
  final String geminiApiKey;

  EmailHandler(this.geminiApiKey);

  Future<Response> gmailCallback(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final code = body['code'] as String?;

      if (code == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Missing authorization code'}));
      }

      // Exchange code for tokens via Google API
      final tokenResponse = await _httpPost(
        'https://oauth2.googleapis.com/token',
        {
          'code': code,
          'client_id': Platform.environment['GMAIL_CLIENT_ID'] ?? '',
          'client_secret': Platform.environment['GMAIL_CLIENT_SECRET'] ?? '',
          'redirect_uri': Platform.environment['REDIRECT_URI'] ?? '',
          'grant_type': 'authorization_code',
        },
      );

      return Response.ok(jsonEncode(tokenResponse), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> outlookCallback(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final code = body['code'] as String?;

      if (code == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Missing authorization code'}));
      }

      final tokenResponse = await _httpPost(
        'https://login.microsoftonline.com/common/oauth2/v2.0/token',
        {
          'client_id': Platform.environment['OUTLOOK_CLIENT_ID'] ?? '',
          'client_secret': Platform.environment['OUTLOOK_CLIENT_SECRET'] ?? '',
          'code': code,
          'redirect_uri': Platform.environment['REDIRECT_URI'] ?? '',
          'grant_type': 'authorization_code',
        },
      );

      return Response.ok(jsonEncode(tokenResponse), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> syncEmails(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final accessToken = body['access_token'] as String?;
      final provider = body['provider'] as String?;

      if (accessToken == null || provider == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Missing access_token or provider'}));
      }

      List<Map<String, dynamic>> emails;

      if (provider == 'gmail') {
        emails = await _fetchGmailEmails(accessToken);
      } else if (provider == 'outlook') {
        emails = await _fetchOutlookEmails(accessToken);
      } else {
        return Response.badRequest(body: jsonEncode({'error': 'Unknown provider'}));
      }

      // Classify emails for application status
      final classified = await _classifyEmails(emails);

      return Response.ok(jsonEncode({'emails': classified}), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGmailEmails(String accessToken) async {
    final response = await _httpGet(
      'https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=10&q=university+application+status+admission',
      accessToken,
    );
    final messages = response['messages'] as List? ?? [];

    final emails = <Map<String, dynamic>>[];
    for (final msg in messages.take(5)) {
      final detail = await _httpGet(
        'https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg['id']}',
        accessToken,
      );
      final headers = <String, String>{};
      for (final h in (detail['payload']['headers'] as List? ?? [])) {
        headers[(h['name'] ?? '').toString().toLowerCase()] = (h['value'] ?? '').toString();
      }
      emails.add({
        'id': msg['id'],
        'subject': headers['subject'] ?? '',
        'from': headers['from'] ?? '',
        'date': headers['date'] ?? '',
        'snippet': detail['snippet'] ?? '',
      });
    }
    return emails;
  }

  Future<List<Map<String, dynamic>>> _fetchOutlookEmails(String accessToken) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30)).toIso8601String();
    final response = await _httpGet(
      'https://graph.microsoft.com/v1.0/me/messages?\$filter=receivedDateTime+ge+$thirtyDaysAgo&\$search="university application admission status"&\$top=10&\$select=subject,from,receivedDateTime,bodyPreview',
      accessToken,
    );
    final messages = response['value'] as List? ?? [];
    return messages.map((m) => {
      'id': m['id'],
      'subject': m['subject'] ?? '',
      'from': (m['from']?['emailAddress']?['address']) ?? '',
      'date': m['receivedDateTime'] ?? '',
      'snippet': m['bodyPreview'] ?? '',
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _classifyEmails(List<Map<String, dynamic>> emails) async {
    final classified = <Map<String, dynamic>>[];
    for (final email in emails) {
      final subject = (email['subject'] ?? '').toString().toLowerCase();
      final snippet = (email['snippet'] ?? '').toString().toLowerCase();
      final combined = '$subject $snippet';

      String? detectedStatus;
      String? detectedPayment;

      if (combined.contains('accepted') || combined.contains('congratulations') || combined.contains('admitted') || combined.contains('offer')) {
        detectedStatus = 'accepted';
      } else if (combined.contains('rejected') || combined.contains('regret') || combined.contains('unfortunately') || combined.contains('declined')) {
        detectedStatus = 'rejected';
      } else if (combined.contains('acknowled') || combined.contains('received') || combined.contains('we have received')) {
        detectedStatus = 'acknowledged';
      } else if (combined.contains('submitted') || combined.contains('confirmation') || combined.contains('application complete')) {
        detectedStatus = 'submitted';
      } else if (combined.contains('pending') || combined.contains('in review') || combined.contains('under review') || combined.contains('being processed')) {
        detectedStatus = 'pending';
      }

      if (combined.contains('payment') && (combined.contains('received') || combined.contains('complete') || combined.contains('paid'))) {
        detectedPayment = 'paid';
      } else if (combined.contains('payment') && (combined.contains('waive') || combined.contains('waived'))) {
        detectedPayment = 'waived';
      }

      classified.add({
        ...email,
        'detected_status': detectedStatus,
        'detected_payment': detectedPayment,
      });
    }
    return classified;
  }

  Future<Map<String, dynamic>> _httpGet(String url, String token) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _httpPost(String url, Map<String, String> data) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.write(data.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      client.close();
    }
  }
}
