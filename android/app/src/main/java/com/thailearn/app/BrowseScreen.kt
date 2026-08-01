package com.thailearn.app

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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BrowseScreen(speech: Speech) {
    val context = LocalContext.current
    val words = remember { Vocab.all(context) }
    val store = remember { ProgressStore(context) }
    var query by remember { mutableStateOf("") }
    var detail by remember { mutableStateOf<ThaiWord?>(null) }

    val filtered = remember(query) {
        if (query.isBlank()) words
        else words.filter {
            it.thai.contains(query) || it.roman.contains(query, ignoreCase = true) ||
                it.en.contains(query, ignoreCase = true) || it.hi.contains(query) ||
                it.hindiPron.contains(query)
        }
    }

    Column(Modifier.fillMaxSize()) {
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            placeholder = { Text("Search Thai, English or Hindi") },
            singleLine = true,
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp),
        )
        LazyColumn(Modifier.fillMaxSize()) {
            items(filtered, key = { it.id }) { word ->
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clickable { detail = word }
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(
                        Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(
                                when {
                                    store.box(word.id) >= 3 -> ThaiTheme.accent2
                                    store.box(word.id) > 0 -> ThaiTheme.accent400
                                    else -> ThaiTheme.hairline
                                }
                            )
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(
                        word.thai,
                        fontFamily = ThaiTheme.mitr, fontSize = 24.sp, color = ThaiTheme.ink,
                        modifier = Modifier.widthIn(min = 72.dp),
                    )
                    Spacer(Modifier.width(10.dp))
                    Column(Modifier.weight(1f)) {
                        Text(word.roman, fontSize = 14.sp, fontWeight = FontWeight.Medium, color = ThaiTheme.ink)
                        Text("${word.hi} · ${word.en}", fontSize = 12.sp, color = ThaiTheme.textMuted)
                    }
                    TextButton(onClick = { speech.speak(word.thai, word.roman) }) {
                        Text("🔊", fontSize = 16.sp)
                    }
                }
                HorizontalDivider(color = ThaiTheme.hairline, thickness = 0.5.dp)
            }
        }
    }

    detail?.let { word ->
        ModalBottomSheet(
            onDismissRequest = { detail = null },
            containerColor = ThaiTheme.bgAlt,
        ) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 22.dp)
                    .padding(bottom = 40.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Chip(word.category.uppercase())
                Spacer(Modifier.height(10.dp))
                Text(word.thai, fontFamily = ThaiTheme.mitr, fontSize = 44.sp, color = ThaiTheme.ink)
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
        }
    }
}
