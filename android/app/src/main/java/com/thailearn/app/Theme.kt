package com.thailearn.app

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily

/** The blue design system — same tokens as iOS ThaiTheme (blue rebrand). */
object ThaiTheme {
    val bg = Color(0xFFEEF3FA)
    val bgAlt = Color(0xFFF5F8FC)
    val surface = Color(0xFFFBFDFF)
    val surfaceSunken = Color(0xFFE3EBF5)
    val hairline = Color(0xFFDCE5F0)

    val ink = Color(0xFF101C33)
    val inkDeep = Color(0xFF16233D)
    val textMuted = Color(0xFF64748E)
    val textFaint = Color(0xFF8C9CB4)

    val accent100 = Color(0xFFEAF2FC)
    val accent200 = Color(0xFFD8E7F8)
    val accent300 = Color(0xFFAECDF0)
    val accent400 = Color(0xFF6F9FE0)
    val accent = Color(0xFF2F6BC0)
    val accent700 = Color(0xFF1B4079)

    val accent2100 = Color(0xFFE6F3FB)
    val accent2 = Color(0xFF3B7AA2)
    val accent2400 = Color(0xFF79B6DA)

    val danger = Color(0xFFC2503F)

    val mitr = FontFamily(Font(R.font.mitr_medium))
}
