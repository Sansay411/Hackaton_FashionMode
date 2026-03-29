import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/user.dart';

class RealtimeSyncService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pollingTimer;
  bool _isTicking = false;

  bool get isConnected => _channel != null;

  void start({
    required String baseUrl,
    required User user,
    required bool enableRealtime,
    required Duration pollingInterval,
    required Future<void> Function() onTick,
    required ValueChanged<bool> onConnectionChanged,
  }) {
    stop();
    onConnectionChanged(false);

    _pollingTimer = Timer.periodic(pollingInterval, (_) async {
      await _runTick(onTick);
    });

    if (!enableRealtime) {
      return;
    }

    final uri = _buildUri(baseUrl: baseUrl, user: user);
    _channel = WebSocketChannel.connect(uri);
    onConnectionChanged(true);
    _subscription = _channel!.stream.listen(
      (_) async => _runTick(onTick),
      onError: (_) {
        onConnectionChanged(false);
      },
      onDone: () {
        onConnectionChanged(false);
      },
      cancelOnError: false,
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isTicking = false;
  }

  Future<void> _runTick(Future<void> Function() onTick) async {
    if (_isTicking) {
      return;
    }

    _isTicking = true;
    try {
      await onTick();
    } finally {
      _isTicking = false;
    }
  }

  Uri _buildUri({
    required String baseUrl,
    required User user,
  }) {
    final uri = Uri.parse(baseUrl);
    final isSecure = uri.scheme == 'https';
    final query = <String, String>{
      'role': user.role.value,
    };

    switch (user.role) {
      case UserRole.client:
        query['user_id'] = user.id;
        break;
      case UserRole.franchisee:
      case UserRole.production:
        if (user.franchiseId != null) {
          query['franchise_id'] = user.franchiseId!;
        }
        break;
    }

    return uri.replace(
      scheme: isSecure ? 'wss' : 'ws',
      path: '/ws',
      queryParameters: query,
      fragment: '',
    );
  }
}

Map<String, dynamic> decodeRealtimePayload(dynamic event) {
  if (event is String && event.isNotEmpty) {
    try {
      return Map<String, dynamic>.from(jsonDecode(event) as Map);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  if (event is Map) {
    return Map<String, dynamic>.from(event);
  }

  return const <String, dynamic>{};
}
