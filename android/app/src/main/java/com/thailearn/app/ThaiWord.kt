package com.thailearn.app

import android.content.Context
import org.json.JSONArray

/**
 * One vocabulary entry — mirrors the iOS `ThaiWord` in Shared/ThaiWord.swift.
 * The list itself is generated from Vocabulary.swift into assets/vocabulary.json
 * so both apps teach the identical 450 words.
 */
data class ThaiWord(
    val id: Int,
    val thai: String,
    val roman: String,
    val hindiPron: String,
    val en: String,
    val hi: String,
    val category: String,
)

object Vocab {
    private var cached: List<ThaiWord>? = null

    fun all(context: Context): List<ThaiWord> {
        cached?.let { return it }
        val json = context.assets.open("vocabulary.json").bufferedReader().readText()
        val array = JSONArray(json)
        val words = buildList {
            for (i in 0 until array.length()) {
                val o = array.getJSONObject(i)
                add(
                    ThaiWord(
                        id = o.getInt("id"),
                        thai = o.getString("thai"),
                        roman = o.getString("roman"),
                        hindiPron = o.getString("hindiPron"),
                        en = o.getString("en"),
                        hi = o.getString("hi"),
                        category = o.getString("category"),
                    )
                )
            }
        }
        cached = words
        return words
    }

    /** Deterministic daily word — same day, same word, like the iOS Today tab. */
    fun wordOfTheDay(context: Context): ThaiWord {
        val words = all(context)
        val day = (System.currentTimeMillis() / 86_400_000L).toInt()
        return words[day % words.size]
    }
}
