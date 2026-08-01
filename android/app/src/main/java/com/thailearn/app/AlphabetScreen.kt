package com.thailearn.app

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * The 44 consonants — the Kotlin counterpart of iOS `AlphabetView`.
 *
 * Each letter is colour-coded by consonant class, because class is what drives
 * the tone rules, and paired with its Devanagari cousin: both scripts descend
 * from Brahmi, so a Hindi reader recognises most of the row.
 */
@Composable
fun AlphabetScreen(speech: Speech) {
    val letters = Content.letters(LocalContext.current)

    LazyColumn(Modifier.fillMaxSize().padding(horizontal = 16.dp)) {
        item {
            Text(
                "Alphabet", fontSize = 28.sp, fontWeight = FontWeight.Bold,
                color = ThaiTheme.ink, modifier = Modifier.padding(top = 16.dp, bottom = 4.dp),
            )
            Text(
                "44 consonants. Colour = class, which decides the tone. " +
                    "The right column is the Devanagari cousin — same Brahmi ancestor.",
                fontSize = 13.sp, color = ThaiTheme.textMuted,
                modifier = Modifier.padding(bottom = 10.dp),
            )
            Row(Modifier.padding(bottom = 12.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ClassKey("middle", ThaiTheme.accent)
                ClassKey("high", ThaiTheme.accent700)
                ClassKey("low", ThaiTheme.accent2)
            }
        }
        items(letters) { letter ->
            val tint = classColor(letter.letterClass)
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(ThaiTheme.surface)
                    .clickable { speech.speak(letter.name, letter.nameRoman) }
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    Modifier
                        .size(48.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(tint.copy(alpha = 0.12f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        letter.letter, fontFamily = ThaiTheme.mitr,
                        fontSize = 28.sp, color = tint,
                    )
                }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(letter.name, fontFamily = ThaiTheme.mitr, fontSize = 17.sp, color = ThaiTheme.ink)
                        Spacer(Modifier.width(8.dp))
                        Text(letter.nameRoman, fontSize = 12.sp, color = tint)
                        if (letter.obsolete) {
                            Spacer(Modifier.width(6.dp))
                            Text(
                                "obsolete", fontSize = 9.sp, fontWeight = FontWeight.Bold,
                                color = ThaiTheme.textFaint,
                                modifier = Modifier
                                    .clip(RoundedCornerShape(999.dp))
                                    .background(ThaiTheme.surfaceSunken)
                                    .padding(horizontal = 6.dp, vertical = 2.dp),
                            )
                        }
                    }
                    Text(
                        "${letter.nameEnglish} · ${letter.nameHindi}",
                        fontSize = 12.sp, color = ThaiTheme.textMuted,
                    )
                    Text("sound: ${letter.sound}", fontSize = 11.sp, color = ThaiTheme.textFaint)
                }
                Text(
                    letter.devanagari, fontSize = 26.sp,
                    color = ThaiTheme.accent700, fontWeight = FontWeight.Medium,
                )
            }
        }
    }
}

private fun classColor(letterClass: String): Color = when (letterClass) {
    "middle" -> ThaiTheme.accent
    "high" -> ThaiTheme.accent700
    else -> ThaiTheme.accent2
}

@Composable
private fun ClassKey(label: String, tint: Color) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            Modifier
                .size(10.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(tint)
        )
        Spacer(Modifier.width(5.dp))
        Text(label, fontSize = 11.sp, color = ThaiTheme.textMuted)
    }
}
