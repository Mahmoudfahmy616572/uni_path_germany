import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymobService {
  final Dio _dio;
  final String _supabaseUrl;
  final SupabaseClient _supabase;

  PaymobService(this._dio, this._supabaseUrl, this._supabase);

  Future<Map<String, String>> getPaymentInfo({
    required int amountCents,
    required String userId,
    required String plan,
    String currency = 'EGP',
  }) async {
    final session = _supabase.auth.currentSession;
    final res = await _dio.post(
      '$_supabaseUrl/functions/v1/generate-payment-key',
      options: Options(headers: {
        'Authorization': 'Bearer ${session?.accessToken ?? ''}',
      }),
      data: {
        'amount_cents': amountCents,
        'currency': currency,
        'user_id': userId,
        'plan': plan,
      },
    );

    final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : <String, dynamic>{};
    final paymentToken = data['payment_token'] as String?;
    final iframeId = data['iframe_id'] as String?;

    if (paymentToken == null) {
      throw Exception(data['error'] as String? ?? 'Failed to generate payment token');
    }
    if (iframeId == null) {
      throw Exception('Missing iframe_id in payment response');
    }

    return {
      'payment_token': paymentToken,
      'iframe_id': iframeId,
    };
  }

  String getIframeUrl(String iframeId, String paymentToken) {
    return 'https://accept.paymob.com/api/acceptance/iframes/$iframeId?payment_token=$paymentToken';
  }
}
