package com.thailearn.app

import androidx.compose.ui.graphics.Color
import java.text.Normalizer

/** The five Thai tones. Mirrors iOS `ThaiTone`. */
enum class ThaiTone(val englishName: String, val contour: String) {
    MID("mid", "→"),
    LOW("low", "↘"),
    FALLING("falling", "⌒"),
    HIGH("high", "↗"),
    RISING("rising", "⌄");

    val color: Color
        get() = when (this) {
            MID -> ThaiTheme.textMuted
            LOW -> Color(0xFF4A6FD4)
            FALLING -> ThaiTheme.danger
            HIGH -> Color(0xFFE68A2E)
            RISING -> Color(0xFF3EA56C)
        }
}

/** One spoken syllable of a romanized word with its tone. */
data class ToneSyllable(val text: String, val tone: ThaiTone)

/**
 * Reads the tone off the romanization's diacritics — the same rule as iOS
 * `ToneAnalyzer`: decompose to NFD, then look for the combining mark.
 *
 *   U+0300 grave à = low      U+0301 acute á = high
 *   U+0302 circumflex â = falling   U+030C caron ǎ = rising
 *   none = mid
 */
object ToneAnalyzer {
    fun syllables(romanization: String): List<ToneSyllable> =
        romanization
            .split('-', ' ')
            .filter { it.isNotBlank() }
            .map { syllable ->
                var tone = ThaiTone.MID
                for (ch in Normalizer.normalize(syllable, Normalizer.Form.NFD)) {
                    when (ch.code) {
                        0x300 -> tone = ThaiTone.LOW
                        0x301 -> tone = ThaiTone.HIGH
                        0x302 -> tone = ThaiTone.FALLING
                        0x30C -> tone = ThaiTone.RISING
                    }
                }
                ToneSyllable(syllable, tone)
            }

    /** The dominant tone of a whole word — the first non-mid one, else mid. */
    fun wordTone(romanization: String): ThaiTone =
        syllables(romanization).firstOrNull { it.tone != ThaiTone.MID }?.tone ?: ThaiTone.MID
}
