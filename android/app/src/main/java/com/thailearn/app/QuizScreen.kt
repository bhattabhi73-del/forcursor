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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * Ten-question round, half of them listening — the Kotlin counterpart of iOS
 * `QuizView`. Questions are drawn from the words the learner has actually
 * started, so the quiz tracks their progress rather than the whole dictionary.
 */
private const val QUESTIONS_PER_ROUND = 10

private data class Question(
    val word: ThaiWord,
    val choices: List<ThaiWord>,
    /** Listening questions hide the Thai and ask the learner to tap what they heard. */
    val listening: Boolean,
)

private fun buildRound(words: List<ThaiWord>, store: ProgressStore): List<Question> {
    // Prefer words already in a Leitner box; fall back to the front of the list
    // so a brand-new learner still gets a playable round.
    val pool = words.filter { store.box(it.id) > 0 }.ifEmpty { words.take(120) }
    val subjects = pool.shuffled().take(QUESTIONS_PER_ROUND)

    return subjects.mapIndexed { i, word ->
        val distractors = words
            .filter { it.id != word.id && it.category == word.category }
            .ifEmpty { words.filter { it.id != word.id } }
            .shuffled()
            .take(3)
        Question(
            word = word,
            choices = (distractors + word).shuffled(),
            listening = i % 2 == 1,
        )
    }
}

@Composable
fun QuizScreen(speech: Speech, onExit: () -> Unit) {
    val context = LocalContext.current
    val words = remember { Vocab.all(context) }
    val store = remember { ProgressStore(context) }

    var round by remember { mutableStateOf(buildRound(words, store)) }
    var index by remember { mutableIntStateOf(0) }
    var picked by remember { mutableStateOf<ThaiWord?>(null) }
    var correct by remember { mutableIntStateOf(0) }

    if (index >= round.size) {
        QuizComplete(correct, round.size, onAgain = {
            round = buildRound(words, store); index = 0; correct = 0; picked = null
        }, onExit = onExit)
        return
    }

    val question = round[index]

    // Speak the prompt as soon as a listening question appears.
    LaunchedEffect(index) {
        if (question.listening) speech.speak(question.word.thai, question.word.roman)
    }

    Column(
        Modifier.fillMaxSize().padding(horizontal = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(
            Modifier.fillMaxWidth().padding(vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            TextButton(onClick = onExit) { Text("‹  Practice", color = ThaiTheme.accent) }
            Spacer(Modifier.weight(1f))
            Text(
                "${index + 1} / ${round.size}",
                fontSize = 13.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.textMuted,
            )
        }
        LinearProgressIndicator(
            progress = { (index + 1f) / round.size },
            color = ThaiTheme.accent, trackColor = ThaiTheme.hairline,
            modifier = Modifier.fillMaxWidth().height(5.dp).clip(CircleShape),
        )

        Spacer(Modifier.height(28.dp))

        if (question.listening) {
            Text("What did you hear?", fontSize = 14.sp, color = ThaiTheme.textMuted)
            Spacer(Modifier.height(16.dp))
            Button(
                onClick = { speech.speak(question.word.thai, question.word.roman) },
                colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.accent),
                shape = RoundedCornerShape(999.dp),
                modifier = Modifier.height(60.dp).fillMaxWidth(0.6f),
            ) { Text("🔊  Play again", fontSize = 16.sp, fontWeight = FontWeight.Bold) }
        } else {
            Text("What does this mean?", fontSize = 14.sp, color = ThaiTheme.textMuted)
            Spacer(Modifier.height(12.dp))
            Text(
                question.word.thai,
                fontFamily = ThaiTheme.mitr, fontSize = 52.sp,
                color = ThaiTheme.ink, textAlign = TextAlign.Center,
            )
            Text(question.word.roman, fontSize = 15.sp, color = ThaiTheme.accent)
        }

        Spacer(Modifier.height(28.dp))

        question.choices.forEach { choice ->
            val isAnswer = choice.id == question.word.id
            val target = when {
                picked == null -> ThaiTheme.surface
                isAnswer -> ThaiTheme.accent2.copy(alpha = 0.18f)
                choice.id == picked?.id -> ThaiTheme.danger.copy(alpha = 0.15f)
                else -> ThaiTheme.surface
            }
            val bg by animateColorAsState(target, label = "choice")

            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(bottom = 10.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(bg)
                    .clickable(enabled = picked == null) {
                        picked = choice
                        if (isAnswer) correct++
                        store.record(question.word.id, isAnswer)
                    }
                    .padding(14.dp),
            ) {
                if (question.listening) {
                    Text(choice.thai, fontFamily = ThaiTheme.mitr, fontSize = 22.sp, color = ThaiTheme.ink)
                    Text("${choice.hi} · ${choice.en}", fontSize = 12.sp, color = ThaiTheme.textMuted)
                } else {
                    Text(choice.en, fontSize = 16.sp, fontWeight = FontWeight.Medium, color = ThaiTheme.ink)
                    Text(choice.hi, fontSize = 14.sp, color = ThaiTheme.accent700)
                }
            }
        }

        if (picked != null) {
            Spacer(Modifier.height(4.dp))
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

@Composable
private fun QuizComplete(correct: Int, total: Int, onAgain: () -> Unit, onExit: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(if (correct == total) "🎉" else "👏", fontSize = 56.sp)
        Spacer(Modifier.height(12.dp))
        Text("$correct / $total", fontSize = 40.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.ink)
        Text(
            when {
                correct == total -> "Perfect round"
                correct * 2 >= total -> "Solid — keep going"
                else -> "Worth another pass"
            },
            fontSize = 14.sp, color = ThaiTheme.textMuted,
        )
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = onAgain,
            colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.accent),
            shape = RoundedCornerShape(999.dp),
            modifier = Modifier.fillMaxWidth(0.7f).height(50.dp),
        ) { Text("Another round", fontWeight = FontWeight.Bold) }
        TextButton(onClick = onExit) { Text("Back to Practice", color = ThaiTheme.accent) }
    }
}
