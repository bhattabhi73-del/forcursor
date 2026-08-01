package com.thailearn.app

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Five-tone contour drill — the Kotlin counterpart of iOS `ToneTrainerView`.
 *
 * Tone is the single hardest thing for a Hindi or English speaker, because
 * neither language uses pitch to change meaning. Hearing a word and naming its
 * tone is the drill that builds the ear.
 */
private const val TONE_ROUND = 8

@Composable
fun ToneTrainerScreen(speech: Speech, onExit: () -> Unit) {
    val context = LocalContext.current
    // Only words whose romanization actually carries a tone mark are usable —
    // an unmarked syllable is mid, and a round of all-mid teaches nothing.
    val pool = remember {
        Vocab.all(context).filter { ToneAnalyzer.syllables(it.roman).any { s -> s.tone != ThaiTone.MID } }
    }

    var round by remember { mutableStateOf(pool.shuffled().take(TONE_ROUND)) }
    var index by remember { mutableIntStateOf(0) }
    var picked by remember { mutableStateOf<ThaiTone?>(null) }
    var correct by remember { mutableIntStateOf(0) }

    if (pool.isEmpty()) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("No tone-marked words available.", color = ThaiTheme.textMuted)
        }
        return
    }

    if (index >= round.size) {
        Column(
            Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text("🎧", fontSize = 56.sp)
            Spacer(Modifier.height(12.dp))
            Text("$correct / ${round.size}", fontSize = 40.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.ink)
            Text("tones heard correctly", fontSize = 14.sp, color = ThaiTheme.textMuted)
            Spacer(Modifier.height(24.dp))
            Button(
                onClick = { round = pool.shuffled().take(TONE_ROUND); index = 0; correct = 0; picked = null },
                colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.accent),
                shape = RoundedCornerShape(999.dp),
                modifier = Modifier.fillMaxWidth(0.7f).height(50.dp),
            ) { Text("Again", fontWeight = FontWeight.Bold) }
            TextButton(onClick = onExit) { Text("Back to Practice", color = ThaiTheme.accent) }
        }
        return
    }

    val word = round[index]
    val answer = ToneAnalyzer.wordTone(word.roman)

    LaunchedEffect(index) { speech.speak(word.thai, word.roman) }

    Column(
        Modifier.fillMaxSize().padding(horizontal = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(Modifier.fillMaxWidth().padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onExit) { Text("‹  Practice", color = ThaiTheme.accent) }
            Spacer(Modifier.weight(1f))
            Text("${index + 1} / ${round.size}", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.textMuted)
        }
        LinearProgressIndicator(
            progress = { (index + 1f) / round.size },
            color = ThaiTheme.accent, trackColor = ThaiTheme.hairline,
            modifier = Modifier.fillMaxWidth().height(5.dp).clip(CircleShape),
        )

        Spacer(Modifier.height(24.dp))
        Text("Which tone?", fontSize = 14.sp, color = ThaiTheme.textMuted)
        Spacer(Modifier.height(10.dp))
        Text(
            word.thai, fontFamily = ThaiTheme.mitr, fontSize = 48.sp,
            color = ThaiTheme.ink, textAlign = TextAlign.Center,
        )
        // The romanization carries the tone mark, so it stays hidden until answered.
        if (picked != null) {
            Text(word.roman, fontSize = 16.sp, color = ThaiTheme.accent)
            Text("${word.hi} · ${word.en}", fontSize = 13.sp, color = ThaiTheme.textMuted)
        }
        Spacer(Modifier.height(14.dp))
        Button(
            onClick = { speech.speak(word.thai, word.roman) },
            colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.surfaceSunken),
            shape = RoundedCornerShape(999.dp),
        ) { Text("🔊  Play again", color = ThaiTheme.accent700, fontWeight = FontWeight.Bold) }

        Spacer(Modifier.height(24.dp))

        ThaiTone.entries.forEach { tone ->
            val target = when {
                picked == null -> ThaiTheme.surface
                tone == answer -> ThaiTheme.accent2.copy(alpha = 0.18f)
                tone == picked -> ThaiTheme.danger.copy(alpha = 0.15f)
                else -> ThaiTheme.surface
            }
            val bg by animateColorAsState(target, label = "tone")
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(bg)
                    .clickable(enabled = picked == null) {
                        picked = tone
                        if (tone == answer) correct++
                    }
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(tone.contour, fontSize = 22.sp, color = tone.color)
                Spacer(Modifier.width(14.dp))
                Text(
                    tone.englishName.replaceFirstChar { it.uppercase() },
                    fontSize = 16.sp, fontWeight = FontWeight.Medium, color = ThaiTheme.ink,
                )
            }
        }

        if (picked != null) {
            Button(
                onClick = { picked = null; index++ },
                colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.accent),
                shape = RoundedCornerShape(999.dp),
                modifier = Modifier.fillMaxWidth().height(50.dp),
            ) {
                Text(
                    if (index + 1 >= round.size) "See results" else "Next",
                    fontSize = 16.sp, fontWeight = FontWeight.Bold,
                )
            }
        }
    }
}
