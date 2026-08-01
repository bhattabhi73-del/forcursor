package com.thailearn.app

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
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
 * The More tab — the Kotlin counterpart of iOS `MoreView`.
 *
 * All five lists come from content.json, so the two apps show the identical
 * content. They lived as Swift literals in ContentView.swift until 2026-08-02,
 * which is why Android had no More tab at all.
 */
private enum class MorePage { Menu, Slang, Cousins, Opposites, Similars, Facts }

@Composable
fun MoreScreen(speech: Speech) {
    var page by remember { mutableStateOf(MorePage.Menu) }

    BackHandler(enabled = page != MorePage.Menu) { page = MorePage.Menu }

    when (page) {
        MorePage.Menu -> MoreMenu { page = it }
        MorePage.Slang -> FunWordList(
            "Slang & Chat Thai",
            "The Thai you'll see in chats and hear between friends — not in textbooks.",
            Content.slang(LocalContext.current), speech,
        ) { page = MorePage.Menu }
        MorePage.Cousins -> FunWordList(
            "Hindi–Thai Cousins",
            "Real Sanskrit and Pali cognates. If you know Hindi you already half-know these.",
            Content.cousins(LocalContext.current), speech,
        ) { page = MorePage.Menu }
        MorePage.Opposites -> PairList(
            "Opposite Words",
            "Words stick twice as fast in pairs — learn ใหญ่ and เล็ก arrives free. Tap either side to hear it.",
            Content.opposites(LocalContext.current), speech,
        ) { page = MorePage.Menu }
        MorePage.Similars -> PairList(
            "Similar Words",
            "Near-twins that trip learners up — same English translation, different Thai feel. The note tells you which to use when.",
            Content.similarPairs(LocalContext.current), speech,
        ) { page = MorePage.Menu }
        MorePage.Facts -> FactsList { page = MorePage.Menu }
    }
}

@Composable
private fun MoreMenu(onOpen: (MorePage) -> Unit) {
    val context = LocalContext.current
    val rows = listOf(
        Triple("🗣️", "Slang & Chat Thai", "555, จริงดิ, ชิวๆ — the Thai textbooks skip") to
            (MorePage.Slang to ThaiTheme.accent),
        Triple("🕉️", "Hindi–Thai Cousins", "${Content.cousins(context).size} words Hindi already taught you") to
            (MorePage.Cousins to ThaiTheme.accent700),
        Triple("↔️", "Opposite Words", "ใหญ่ ↔ เล็ก, ร้อน ↔ หนาว — learn in pairs") to
            (MorePage.Opposites to ThaiTheme.accent2),
        Triple("🟰", "Similar Words", "พูด ≈ คุย, ดู ≈ เห็น — which one when?") to
            (MorePage.Similars to ThaiTheme.accent400),
        Triple("💡", "Must-Know Thai Facts", "Why Thai is easier than you think") to
            (MorePage.Facts to ThaiTheme.accent2400),
    )

    LazyColumn(Modifier.fillMaxSize().padding(horizontal = 16.dp)) {
        item {
            Text(
                "More", fontSize = 28.sp, fontWeight = FontWeight.Bold,
                color = ThaiTheme.ink, modifier = Modifier.padding(vertical = 16.dp),
            )
        }
        items(rows) { (row, target) ->
            val (glyph, title, subtitle) = row
            val (destination, tint) = target
            Row(
                Modifier
                    .fillMaxWidth()
                    .padding(bottom = 10.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(ThaiTheme.surface)
                    .clickable { onOpen(destination) }
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Box(
                    Modifier
                        .size(40.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(tint),
                    contentAlignment = Alignment.Center,
                ) { Text(glyph, fontSize = 18.sp) }
                Spacer(Modifier.width(14.dp))
                Column {
                    Text(title, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = ThaiTheme.ink)
                    Text(subtitle, fontSize = 12.sp, color = ThaiTheme.textMuted)
                }
            }
        }
    }
}

@Composable
private fun SubPageScaffold(
    title: String,
    intro: String,
    onBack: () -> Unit,
    content: LazyListScope.() -> Unit,
) {
    Column(Modifier.fillMaxSize()) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            TextButton(onClick = onBack) { Text("‹  More", color = ThaiTheme.accent) }
        }
        Text(
            title, fontSize = 24.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.ink,
            modifier = Modifier.padding(horizontal = 16.dp),
        )
        Text(
            intro, fontSize = 13.sp, color = ThaiTheme.textMuted,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
        )
        LazyColumn(Modifier.fillMaxSize().padding(horizontal = 16.dp), content = content)
    }
}

@Composable
private fun FunWordList(
    title: String,
    intro: String,
    words: List<FunWord>,
    speech: Speech,
    onBack: () -> Unit,
) {
    SubPageScaffold(title, "$intro  (${words.size})", onBack) {
        items(words) { w ->
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(ThaiTheme.surface)
                    .clickable { speech.speak(w.thai, w.roman) }
                    .padding(14.dp),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(w.thai, fontFamily = ThaiTheme.mitr, fontSize = 24.sp, color = ThaiTheme.ink)
                    Spacer(Modifier.width(10.dp))
                    Text(w.roman, fontSize = 13.sp, color = ThaiTheme.accent)
                }
                Spacer(Modifier.height(2.dp))
                Text(w.meaning, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = ThaiTheme.ink)
                Text(w.hindi, fontSize = 15.sp, color = ThaiTheme.accent700)
                if (w.note.isNotBlank()) {
                    Spacer(Modifier.height(4.dp))
                    Text(w.note, fontSize = 12.sp, color = ThaiTheme.textMuted)
                }
            }
        }
    }
}

@Composable
private fun PairList(
    title: String,
    intro: String,
    pairs: List<WordPair>,
    speech: Speech,
    onBack: () -> Unit,
) {
    SubPageScaffold(title, "$intro  (${pairs.size})", onBack) {
        items(pairs) { p ->
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(ThaiTheme.surface)
                    .padding(14.dp),
            ) {
                Row(Modifier.fillMaxWidth()) {
                    PairSide(p.thaiA, p.romanA, p.meaningA, p.hindiA, ThaiTheme.accent, Modifier.weight(1f)) {
                        speech.speak(p.thaiA, p.romanA)
                    }
                    Text(
                        "↔", fontSize = 16.sp, color = ThaiTheme.textMuted,
                        modifier = Modifier.align(Alignment.CenterVertically).padding(horizontal = 6.dp),
                    )
                    PairSide(p.thaiB, p.romanB, p.meaningB, p.hindiB, ThaiTheme.accent2, Modifier.weight(1f)) {
                        speech.speak(p.thaiB, p.romanB)
                    }
                }
                if (p.note.isNotBlank()) {
                    Spacer(Modifier.height(8.dp))
                    Text(p.note, fontSize = 12.sp, color = ThaiTheme.textMuted)
                }
            }
        }
    }
}

@Composable
private fun PairSide(
    thai: String,
    roman: String,
    meaning: String,
    hindi: String,
    tint: Color,
    modifier: Modifier = Modifier,
    onTap: () -> Unit,
) {
    Column(
        modifier.clickable(onClick = onTap),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(thai, fontFamily = ThaiTheme.mitr, fontSize = 22.sp, color = tint)
        Text(roman, fontSize = 11.sp, color = tint)
        Text(meaning, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = ThaiTheme.ink)
        Text(hindi, fontSize = 13.sp, color = ThaiTheme.ink)
    }
}

@Composable
private fun FactsList(onBack: () -> Unit) {
    val facts = Content.facts(LocalContext.current)
    SubPageScaffold("Must-Know Thai Facts", "Why Thai is easier than you think.", onBack) {
        items(facts) { fact ->
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(ThaiTheme.surface)
                    .padding(14.dp),
            ) {
                Text(fact.title, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = ThaiTheme.ink)
                Spacer(Modifier.height(4.dp))
                Text(fact.body, fontSize = 13.sp, color = ThaiTheme.textMuted)
            }
        }
    }
}
