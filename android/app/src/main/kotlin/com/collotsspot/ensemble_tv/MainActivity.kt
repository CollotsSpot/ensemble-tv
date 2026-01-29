package com.collotsspot.ensemble_tv

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var keyEventHandler: KeyEventHandler? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up method channel for remote key events
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ensemble_tv/remote")
        keyEventHandler = KeyEventHandler(methodChannel!!)

        // Set up method call handler for receiving commands from Flutter
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // Handle any methods that need to go from Flutter to Android
                else -> result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        // Let the KeyEventHandler process the key event
        return keyEventHandler?.handleKeyEvent(event) == true || super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        methodChannel = null
        keyEventHandler = null
        super.onDestroy()
    }
}
