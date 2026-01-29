package com.collotsspot.ensemble_tv

import android.view.KeyEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/**
 * Handles raw key events from Shield remote control.
 * Maps remote buttons to Music Assistant player commands.
 */
class KeyEventHandler(private val channel: MethodChannel) {

    /**
     * Handle a key event from the remote control.
     * Returns true if the event was handled, false otherwise.
     */
    fun handleKeyEvent(event: KeyEvent): Boolean {
        // Only handle key down events (not up events to avoid double triggering)
        if (event.action != KeyEvent.ACTION_DOWN) {
            return false
        }

        return when (event.keyCode) {
            // Play/Pause button
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
            KeyEvent.KEYCODE_MEDIA_PLAY,
            KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                channel.invokeMethod("playPause", null)
                true
            }

            // Skip / Next button
            KeyEvent.KEYCODE_MEDIA_NEXT,
            KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD,
            KeyEvent.KEYCODE_MEDIA_FAST_FORWARD -> {
                channel.invokeMethod("next", null)
                true
            }

            // Previous button
            KeyEvent.KEYCODE_MEDIA_PREVIOUS,
            KeyEvent.KEYCODE_MEDIA_SKIP_BACKWARD,
            KeyEvent.KEYCODE_MEDIA_REWIND -> {
                channel.invokeMethod("previous", null)
                true
            }

            // Menu button - show options
            KeyEvent.KEYCODE_MENU -> {
                channel.invokeMethod("showMenu", null)
                true
            }

            // Stop button
            KeyEvent.KEYCODE_MEDIA_STOP -> {
                channel.invokeMethod("stop", null)
                true
            }

            // Don't handle these - let the system handle them
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_VOLUME_MUTE,
            KeyEvent.KEYCODE_BACK,
            KeyEvent.KEYCODE_HOME -> {
                false
            }

            // Ignore D-pad events since we don't have on-screen navigation
            KeyEvent.KEYCODE_DPAD_UP,
            KeyEvent.KEYCODE_DPAD_DOWN,
            KeyEvent.KEYCODE_DPAD_LEFT,
            KeyEvent.KEYCODE_DPAD_RIGHT,
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_ENTER -> {
                false
            }

            // Ignore other unknown keys
            else -> false
        }
    }
}
