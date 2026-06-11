// lib/core/widgets/connectivity_banner.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/connectivity_service.dart';

class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  final Duration hideDelay;

  const ConnectivityBanner({
    super.key,
    required this.child,
    this.hideDelay = const Duration(seconds: 3),
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  final ConnectivityService _connectivity = ConnectivityService();
  ConnectionStatus? _status;
  Timer? _hideTimer;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _connectivity.init();
    _connectivity.connectionStatusStream.listen(_onStatusChanged);
  }

  void _onStatusChanged(ConnectionStatus status) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _showBanner = status != ConnectionStatus.connected;
    });

    // Auto-hide after delay when reconnected
    if (status == ConnectionStatus.connected) {
      _hideTimer?.cancel();
      _hideTimer = Timer(widget.hideDelay, () {
        if (mounted) {
          setState(() => _showBanner = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner && _status != null)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: _showBanner ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Material(
                elevation: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  color: _getBannerColor(),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_status == ConnectionStatus.slow)
                        TextButton(
                          onPressed: () => ConnectivityService().init(),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getBannerColor() {
    switch (_status) {
      case ConnectionStatus.disconnected:
        return Colors.red.shade600;
      case ConnectionStatus.slow:
        return Colors.orange.shade600;
      case ConnectionStatus.connected:
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case ConnectionStatus.disconnected:
        return Icons.wifi_off;
      case ConnectionStatus.slow:
        return Icons.wifi_tethering;
      case ConnectionStatus.connected:
        return Icons.wifi;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText() {
    switch (_status) {
      case ConnectionStatus.disconnected:
        return 'No internet connection. Some features may not work.';
      case ConnectionStatus.slow:
        return 'Slow connection. Loading may take longer.';
      case ConnectionStatus.connected:
        return 'Connection restored';
      default:
        return '';
    }
  }
}