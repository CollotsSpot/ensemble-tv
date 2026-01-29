import 'package:flutter/services.dart';

/// Handles remote control key events from Android.
/// Converts method channel calls into commands that the provider can execute.
class TVRemoteHandler {
  static const _channel = MethodChannel('ensemble_tv/remote');

  final void Function(String)? onCommand;

  TVRemoteHandler({this.onCommand}) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'playPause':
        onCommand?.call('playPause');
        break;
      case 'next':
        onCommand?.call('next');
        break;
      case 'previous':
        onCommand?.call('previous');
        break;
      case 'showMenu':
        onCommand?.call('showMenu');
        break;
      case 'stop':
        onCommand?.call('stop');
        break;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}
