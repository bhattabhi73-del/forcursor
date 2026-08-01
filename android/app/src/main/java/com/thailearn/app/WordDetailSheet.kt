package com.thailearn.app

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * One word's full story — the Kotlin counterpart of iOS `WordDetailView`.
 * Sections appear only when the word actually has that content.
 */
@Composable
fun WordDetailBody(
    word: ThaiWord,
    speech: Speech,
    onOpenWord: (ThaiWord) -> Unit,
) {
    val context = LocalContext.current
    val sentences = remember(word.id) { Content.examples(context, word.id) }
    val forms = remember(word.id) { Content.forms(context, word.id) }
    val similar = remember(word.id) { Content.similarSounds(context, word.id) }
    val compoundNote = remember(word.id) { Content.compoundNote(context, word.id) }
    val related = remember(word.id) { Content.related(context, word).take(12) }
    val emoji = remember(word.id) { Content.emoji(context, word.id) }

    Column(
        Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp)
            .padding(bottom = 40.dp),
    ) {
        // Header
        Column(Modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally) {
            Chip(word.category.uppercase())
            Spacer(Modifier.height(10.dp))
            emoji?.let {
                Text(it, fontSize = 40.sp)
                Spacer(Modifier.height(4.dp))
            }
            Text(
                word.thai,
                fontFamily = ThaiTheme.mitr, fontSize = 44.sp,
                color = ThaiTheme.ink, textAlign = TextAlign.Center,
            )
            Text("${word.hindiPron} · ${word.roman}", fontSize = 15.sp, color = ThaiTheme.textMuted)
            Spacer(Modifier.height(12.dp))
            Text(word.hi, fontSize = 22.sp, fontWeight = FontWeight.SemiBold, color = ThaiTheme.ink)
            Text(word.en, fontSize = 22.sp, fontWeight = FontWeight.SemiBold, color = ThaiTheme.ink)
            Spacer(Modifier.height(16.dp))
            Button(
                onClick = { speech.speak(word.thai, word.roman) },
                colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.accent),
                shape = RoundedCornerShape(999.dp),
            ) { Text("🔊  Play", fontWeight = FontWeight.Bold) }
        }

        if (sentences.isNotEmpty()) {
            SectionLabel("Sentences")
            sentences.forEach { ex ->
                Column(
                    Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .background(ThaiTheme.surface)
                        .clickable { speech.speak(ex.thai, ex.roman) }
                        .padding(14.dp),
                ) {
                    Text(ex.thai, fontFamily = ThaiTheme.mitr, fontSize = 22.sp, color = ThaiTheme.ink)
                    Spacer(Modifier.height(4.dp))
                    Text(ex.roman, fontSize = 13.sp, color = ThaiTheme.accent)
                    Text(ex.hi, fontSize = 14.sp, color = ThaiTheme.ink)
                    Text(ex.en, fontSize = 14.sp, color = ThaiTheme.textMuted)
                }
            }
        }

        if (forms.isNotEmpty()) {
            SectionLabel("Word forms")
            forms.forEach { form ->
                Column(
                    Modifier
                        .fillMaxWidth()
                        .padding(bottom = 8.dp)
                        .clip(RoundedCornerShape(14.dp))
                        .background(ThaiTheme.surface)
                        .clickable { speech.speak(form.thai, form.roman) }
                        .padding(14.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(form.thai, fontFamily = ThaiTheme.mitr, fontSize = 20.sp, color = ThaiTheme.ink)
                        Spacer(Modifier.width(8.dp))
                        Text(form.roman, fontSize = 13.sp, color = ThaiTheme.accent)
                    }
                    Text("${form.hi} · ${form.en}", fontSize = 13.sp, color = ThaiTheme.ink)
                    if (form.note.isNotBlank()) {
                        Text(form.note, fontSize = 12.sp, color = ThaiTheme.textMuted)
                    }
                }
            }
        }

        compoundNote?.let { note ->
            SectionLabel("Joint word")
            JointBreakdown(note)
        }

        if (similar.isNotEmpty()) {
            SectionLabel("Sounds similar")
            WordChips(similar, onOpenWord)
        }

        if (related.isNotEmpty()) {
            SectionLabel("Related words")
            WordChips(related, onOpenWord)
        }
    }
}

@Composable
private fun SectionLabel(title: String) {
    Spacer(Modifier.height(20.dp))
    Text(
        title.uppercase(),
        fontSize = 11.sp, fontWeight = FontWeight.Bold,
        letterSpacing = 1.2.sp, color = ThaiTheme.textMuted,
        modifier = Modifier.padding(bottom = 8.dp),
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun WordChips(words: List<ThaiWord>, onOpenWord: (ThaiWord) -> Unit) {
    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        words.forEach { w ->
            Row(
                Modifier
                    .padding(bottom = 8.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(ThaiTheme.accent100)
                    .clickable { onOpenWord(w) }
                    .padding(horizontal = 12.dp, vertical = 7.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(w.thai, fontFamily = ThaiTheme.mitr, fontSize = 16.sp, color = ThaiTheme.accent700)
                Spacer(Modifier.width(6.dp))
                Text(w.en, fontSize = 12.sp, color = ThaiTheme.textMuted)
            }
        }
    }
}

/** One part of a compound, e.g. น้ำ (náam) water / पानी. */
private data class CompoundPart(
    val thai: String,
    val roman: String,
    val en: String,
    val hi: String,
)

/**
 * "X (rom) meaning / अर्थ + Y (rom) meaning / अर्थ → result / अर्थ".
 * Returns null for free-form notes, which render as plain text — same rule as
 * iOS `FlashcardView.parseCompound`, so both apps accept exactly the same set.
 */
private fun parseCompound(note: String): Pair<List<CompoundPart>, String>? {
    val halves = note.split("→")
    if (halves.size != 2) return null
    val pieces = halves[0].split(" + ")
    if (pieces.size !in 2..4) return null

    val parts = pieces.map { piece ->
        val open = piece.indexOf('(')
        val close = piece.indexOf(')')
        if (open < 0 || close < 0 || open > close) return null
        val thai = piece.substring(0, open).trim()
        val roman = piece.substring(open + 1, close)
        val meanings = piece.substring(close + 1).split("/")
        if (thai.isEmpty() || meanings.size < 2) return null
        CompoundPart(thai, roman, meanings[0].trim(), meanings[1].trim())
    }
    return parts to halves[1].trim()
}

@Composable
private fun JointBreakdown(note: String) {
    val palette = listOf(ThaiTheme.accent, ThaiTheme.accent2, ThaiTheme.accent700, ThaiTheme.accent400)
    val parsed = remember(note) { parseCompound(note) }

    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(ThaiTheme.surfaceSunken)
            .padding(12.dp),
    ) {
        if (parsed == null) {
            Text(note, fontSize = 14.sp, color = ThaiTheme.ink)
            return@Column
        }
        val (parts, result) = parsed
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
            parts.forEachIndexed { i, part ->
                if (i > 0) {
                    Text(
                        "+", fontSize = 18.sp, fontWeight = FontWeight.SemiBold,
                        color = ThaiTheme.textMuted,
                        modifier = Modifier.padding(top = 6.dp, start = 4.dp, end = 4.dp),
                    )
                }
                Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                    val tint: Color = palette[i % palette.size]
                    Text(part.thai, fontFamily = ThaiTheme.mitr, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = tint)
                    Text(part.roman, fontSize = 11.sp, color = tint)
                    Text(part.en, fontSize = 11.sp, fontWeight = FontWeight.Medium, color = tint, textAlign = TextAlign.Center)
                    Text(part.hi, fontSize = 11.sp, fontWeight = FontWeight.Medium, color = tint, textAlign = TextAlign.Center)
                }
            }
        }
        Spacer(Modifier.height(10.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("=", fontSize = 16.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.textMuted)
            Spacer(Modifier.width(6.dp))
            Text(result, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = ThaiTheme.ink)
        }
    }
}
