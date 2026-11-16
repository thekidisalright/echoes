package dev.alexandre.echoes

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

/** Usa o engine compartilhado do audio_service e registra o canal SAF. */
class MainActivity : AudioServiceActivity() {
    private var safChannel: SafChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        safChannel = SafChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        safChannel?.dispose()
        safChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
