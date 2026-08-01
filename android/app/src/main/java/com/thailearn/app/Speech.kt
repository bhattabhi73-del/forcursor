package com.thailearn.app

import android.content.Context
import android.speech.tts.TextToSpeech
import java.util.Locale

/** Thai TTS with a romanization fallback so the button is never silent. */
class Speech(context: Context) {
    private var ready = false
    private var hasThai = false
    private val tts = TextToSpeech(context) { status ->
        if (status == TextToSpeech.SUCCESS) {
            ready = true
        }
    }

    fun speak(thai: String, roman: String) {
        if (!ready) return
        val thaiResult = tts.setLanguage(Locale("th", "TH"))
        hasThai = thaiResult != TextToSpeech.LANG_MISSING_DATA &&
            thaiResult != TextToSpeech.LANG_NOT_SUPPORTED
        if (hasThai) {
            tts.speak(thai, TextToSpeech.QUEUE_FLUSH, null, "word")
        } else {
            tts.setLanguage(Locale.US)
            tts.speak(roman, TextToSpeech.QUEUE_FLUSH, null, "word")
        }
    }

    fun shutdown() = tts.shutdown()
}
