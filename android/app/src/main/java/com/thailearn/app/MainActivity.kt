package com.thailearn.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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

class MainActivity : ComponentActivity() {
    private lateinit var speech: Speech

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        speech = Speech(this)
        setContent { ThaiLearnApp(speech) }
    }

    override fun onDestroy() {
        speech.shutdown()
        super.onDestroy()
    }
}

@Composable
fun ThaiLearnApp(speech: Speech) {
    var tab by remember { mutableIntStateOf(0) }

    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = ThaiTheme.accent,
            background = ThaiTheme.bg,
            surface = ThaiTheme.surface,
            onBackground = ThaiTheme.ink,
            onSurface = ThaiTheme.ink,
        )
    ) {
        Scaffold(
            containerColor = ThaiTheme.bg,
            bottomBar = {
                NavigationBar(containerColor = ThaiTheme.surface) {
                    listOf("Today" to "☀️", "Practice" to "🃏", "Browse" to "📖").forEachIndexed { i, (label, glyph) ->
                        NavigationBarItem(
                            selected = tab == i,
                            onClick = { tab = i },
                            icon = { Text(glyph, fontSize = 18.sp) },
                            label = { Text(label) },
                            colors = NavigationBarItemDefaults.colors(
                                selectedTextColor = ThaiTheme.accent700,
                                indicatorColor = ThaiTheme.accent100,
                            )
                        )
                    }
                }
            }
        ) { padding ->
            Box(Modifier.padding(padding)) {
                when (tab) {
                    0 -> TodayScreen(speech)
                    1 -> PracticeScreen(speech)
                    else -> BrowseScreen(speech)
                }
            }
        }
    }
}

// MARK: Today

@Composable
fun TodayScreen(speech: Speech) {
    val context = LocalContext.current
    var word by remember { mutableStateOf(Vocab.wordOfTheDay(context)) }
    val store = remember { ProgressStore(context) }
    val reviews = store.reviewsToday()

    Column(
        Modifier
            .fillMaxSize()
            .padding(horizontal = 22.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(18.dp))
        Text(
            "เรียนภาษาไทย",
            fontFamily = ThaiTheme.mitr, fontSize = 26.sp,
            color = ThaiTheme.ink, fontWeight = FontWeight.Bold,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(14.dp))

        Card(
            colors = CardDefaults.cardColors(containerColor = ThaiTheme.surface),
            shape = RoundedCornerShape(24.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
            modifier = Modifier.fillMaxWidth(),
        ) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Chip(word.category.uppercase())
                Spacer(Modifier.height(10.dp))
                Text(
                    word.thai,
                    fontFamily = ThaiTheme.mitr, fontSize = 54.sp,
                    color = ThaiTheme.ink, textAlign = TextAlign.Center,
                )
                Spacer(Modifier.height(8.dp))
                Column(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(Color.White.copy(alpha = 0.6f))
                        .padding(vertical = 10.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text("HI  ${word.hindiPron}", color = ThaiTheme.accent700, fontSize = 16.sp)
                    Text("EN  ${word.roman}", color = ThaiTheme.accent, fontSize = 16.sp)
                }
                Spacer(Modifier.height(10.dp))
                Text(word.hi, fontSize = 21.sp, color = ThaiTheme.ink, fontWeight = FontWeight.SemiBold)
                Text(word.en, fontSize = 21.sp, color = ThaiTheme.ink, fontWeight = FontWeight.SemiBold)
            }
        }

        Spacer(Modifier.height(12.dp))
        GoalStrip(reviews)
        Spacer(Modifier.height(14.dp))

        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Button(
                onClick = { speech.speak(word.thai, word.roman) },
                colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.accent),
                shape = RoundedCornerShape(18.dp),
                modifier = Modifier
                    .weight(1f)
                    .height(52.dp),
            ) {
                Text("🔊  Play", fontSize = 16.sp, fontWeight = FontWeight.Bold)
            }
            Button(
                onClick = { word = Vocab.all(context).random() },
                colors = ButtonDefaults.buttonColors(containerColor = ThaiTheme.surfaceSunken),
                shape = RoundedCornerShape(18.dp),
                modifier = Modifier.size(52.dp),
                contentPadding = PaddingValues(0.dp),
            ) {
                Text("⤨", fontSize = 18.sp, color = ThaiTheme.accent700)
            }
        }
    }
}

@Composable
fun GoalStrip(reviews: Int) {
    val done = reviews >= ProgressStore.DAILY_GOAL
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(ThaiTheme.surface)
            .padding(horizontal = 14.dp, vertical = 12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(ThaiTheme.accent2)
            )
            Spacer(Modifier.width(8.dp))
            Text(
                if (done) "Goal done — $reviews cards today 🎉" else "Today's goal",
                fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                color = if (done) ThaiTheme.accent2 else ThaiTheme.ink,
            )
            Spacer(Modifier.weight(1f))
            Text(
                "${minOf(reviews, ProgressStore.DAILY_GOAL)}/${ProgressStore.DAILY_GOAL}",
                fontSize = 12.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.textMuted,
            )
        }
        Spacer(Modifier.height(8.dp))
        LinearProgressIndicator(
            progress = { minOf(reviews.toFloat() / ProgressStore.DAILY_GOAL, 1f) },
            color = if (done) ThaiTheme.accent2 else ThaiTheme.accent,
            trackColor = ThaiTheme.hairline,
            modifier = Modifier
                .fillMaxWidth()
                .height(5.dp)
                .clip(CircleShape),
        )
    }
}

@Composable
fun Chip(text: String, bg: Color = ThaiTheme.accent200, fg: Color = ThaiTheme.accent700) {
    Text(
        text,
        fontSize = 11.sp, fontWeight = FontWeight.Bold, color = fg, letterSpacing = 1.2.sp,
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(bg)
            .padding(horizontal = 12.dp, vertical = 5.dp),
    )
}
