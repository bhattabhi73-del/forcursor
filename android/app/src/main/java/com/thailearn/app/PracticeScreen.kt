package com.thailearn.app

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** The 1a Flip Deck, matching the iOS Practice tab. */
@Composable
fun PracticeScreen(speech: Speech) {
    val context = LocalContext.current
    val store = remember { ProgressStore(context) }
    val words = remember { Vocab.all(context) }
    var deck by remember { mutableStateOf(store.buildDeck(words)) }
    var index by remember { mutableIntStateOf(0) }
    var flipped by remember { mutableStateOf(false) }
    var reviewed by remember { mutableIntStateOf(0) }
    var correct by remember { mutableIntStateOf(0) }
    var complete by remember { mutableStateOf(false) }
    val target = remember { store.sessionTarget(words) }

    val word = deck[index % deck.size]
    val rotation by animateFloatAsState(
        targetValue = if (flipped) 180f else 0f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 300f),
        label = "flip",
    )

    if (complete) {
        SessionComplete(reviewed, correct) {
            complete = false
            reviewed = 0
            correct = 0
            deck = store.buildDeck(words)
            index = 0
            flipped = false
        }
        return
    }

    Column(Modifier.fillMaxSize().padding(horizontal = 22.dp)) {
        Spacer(Modifier.height(14.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column {
                Text("Practice", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.ink)
                Text("Today's deck · ${deck.size} cards", fontSize = 12.sp, color = ThaiTheme.textMuted)
            }
            Spacer(Modifier.weight(1f))
            Chip("${minOf(reviewed, target)}/$target", ThaiTheme.accent100, ThaiTheme.accent700)
        }
        Spacer(Modifier.height(10.dp))
        LinearProgressIndicator(
            progress = { minOf(reviewed.toFloat() / target, 1f) },
            color = ThaiTheme.accent,
            trackColor = ThaiTheme.hairline,
            modifier = Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(3.dp)),
        )
        Spacer(Modifier.height(14.dp))

        Box(
            Modifier
                .weight(1f)
                .fillMaxWidth()
                .graphicsLayer {
                    rotationY = rotation
                    cameraDistance = 14f * density
                }
                .clip(RoundedCornerShape(28.dp))
                .background(if (rotation <= 90f) ThaiTheme.surface else ThaiTheme.inkDeep)
                .clickable { flipped = !flipped },
            contentAlignment = Alignment.Center,
        ) {
            if (rotation <= 90f) {
                CardFront(word)
            } else {
                Box(Modifier.graphicsLayer { rotationY = 180f }) { CardBack(word) }
            }
        }

        Spacer(Modifier.height(14.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            OutlinedButton(
                onClick = {
                    store.record(word.id, false)
                    reviewed++
                    if (reviewed >= target) complete = true else { index++; flipped = false }
                },
                shape = RoundedCornerShape(999.dp),
                colors = ButtonDefaults.outlinedButtonColors(
                    containerColor = ThaiTheme.accent100, contentColor = ThaiTheme.accent700),
                modifier = Modifier.weight(1f).height(56.dp),
            ) { Text("↺  Again", fontSize = 16.sp, fontWeight = FontWeight.Bold) }

            Button(
                onClick = {
                    store.record(word.id, true)
                    reviewed++; correct++
                    if (reviewed >= target) complete = true else { index++; flipped = false }
                },
                shape = RoundedCornerShape(999.dp),
                colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.accent2),
                modifier = Modifier.weight(1f).height(56.dp),
            ) { Text("✓  Got it", fontSize = 16.sp, fontWeight = FontWeight.Bold) }
        }
        Spacer(Modifier.height(10.dp))
        // Hear-it lives outside the flipping card so it never mirrors.
        TextButton(
            onClick = { speech.speak(word.thai, word.roman) },
            modifier = Modifier.align(Alignment.CenterHorizontally),
        ) { Text("🔊  Hear it", color = ThaiTheme.accent, fontWeight = FontWeight.Bold) }
        Spacer(Modifier.height(6.dp))
    }
}

@Composable
private fun CardFront(word: ThaiWord) {
    Column(
        Modifier.padding(24.dp).fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Chip(word.category.uppercase())
        Spacer(Modifier.height(20.dp))
        Text(
            word.thai,
            fontFamily = ThaiTheme.mitr, fontSize = 52.sp,
            color = ThaiTheme.ink, textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(10.dp))
        Text(word.hindiPron, fontSize = 15.sp, color = ThaiTheme.accent700)
        Text(word.roman, fontSize = 15.sp, color = ThaiTheme.accent)
        Spacer(Modifier.height(18.dp))
        Text("Tap card to reveal meaning", fontSize = 12.sp, color = ThaiTheme.textFaint)
    }
}

@Composable
private fun CardBack(word: ThaiWord) {
    Column(
        Modifier.padding(24.dp).fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(word.thai, fontFamily = ThaiTheme.mitr, fontSize = 30.sp, color = ThaiTheme.bg)
        Spacer(Modifier.height(16.dp))
        MeaningBlock("हिन्दी", ThaiTheme.accent400, word.hi, word.hindiPron)
        Spacer(Modifier.height(10.dp))
        MeaningBlock("ENGLISH", ThaiTheme.accent2400, word.en, word.roman)
    }
}

@Composable
private fun MeaningBlock(label: String, labelColor: Color, meaning: String, pron: String) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(ThaiTheme.bg.copy(alpha = 0.08f))
            .padding(vertical = 12.dp, horizontal = 14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(label, fontSize = 10.sp, letterSpacing = 1.2.sp, color = labelColor, fontWeight = FontWeight.Bold)
        Text(meaning, fontSize = 24.sp, color = ThaiTheme.bg, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
        Text(pron, fontSize = 14.sp, color = Color(0xFFB3C1D4))
    }
}

@Composable
private fun SessionComplete(reviewed: Int, correct: Int, onDone: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(22.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("🎉", fontSize = 52.sp)
        Text("เก่งมาก!", fontFamily = ThaiTheme.mitr, fontSize = 42.sp, color = ThaiTheme.ink)
        Text("kèng mâak — great job!", fontSize = 16.sp, color = ThaiTheme.accent, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(20.dp))
        Row(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(20.dp))
                .background(ThaiTheme.surface)
                .padding(vertical = 16.dp),
        ) {
            Stat("$reviewed", "REVIEWED", ThaiTheme.accent400, Modifier.weight(1f))
            Stat("$correct", "GOT IT", ThaiTheme.accent2, Modifier.weight(1f))
        }
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = onDone,
            colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.accent),
            shape = RoundedCornerShape(18.dp),
            modifier = Modifier.fillMaxWidth().height(52.dp),
        ) { Text("Done", fontSize = 16.sp, fontWeight = FontWeight.Bold) }
    }
}

@Composable
private fun Stat(number: String, caption: String, color: Color, modifier: Modifier = Modifier) {
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Text(number, fontSize = 28.sp, fontWeight = FontWeight.Bold, color = color)
        Text(caption, fontSize = 10.sp, letterSpacing = 1.2.sp, color = ThaiTheme.textMuted)
    }
}
