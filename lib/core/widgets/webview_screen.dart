import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  /// If set, the WebView intercepts redirects to this URI prefix
  /// and returns the OAuth `code` via [onOAuthCallback].
  final String? oauthRedirectUri;
  final void Function(String code, String? state)? onOAuthCallback;

  const WebViewScreen({
    super.key,
    required this.url,
    this.title = '',
    this.oauthRedirectUri,
    this.onOAuthCallback,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onProgress: (progress) => setState(() => _progress = progress / 100),
          onNavigationRequest: (request) {
            final redirectUri = widget.oauthRedirectUri;
            if (redirectUri != null && request.url.startsWith(redirectUri)) {
              final uri = Uri.parse(request.url);
              final code = uri.queryParameters['code'];
              final state = uri.queryParameters['state'];
              if (code != null && widget.onOAuthCallback != null) {
                widget.onOAuthCallback!(code, state);
                Navigator.of(context).pop();
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            final redirectUri = widget.oauthRedirectUri;
            if (redirectUri != null && error.url != null && error.url!.startsWith(redirectUri)) {
              return;
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load: ${error.description}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.isNotEmpty ? widget.title : 'Website',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => _controller.goBack(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => _controller.goForward(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF8B5CF6),
              minHeight: 2.h,
            ),
        ],
      ),
    );
  }
}
