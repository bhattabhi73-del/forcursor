package com.thailearn.app

import android.content.Context
import org.json.JSONObject

/**
 * One vocabulary entry — mirrors the iOS `ThaiWord` in Shared/ThaiWord.swift.
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

/** An example sentence — mirrors iOS `WordExample`. */
data class WordExample(
    val thai: String,
    val roman: String,
    val en: String,
    val hi: String,
)

/** A related form of a word (plural, polite, opposite…) — mirrors iOS `WordForm`. */
data class WordForm(
    val thai: String,
    val roman: String,
    val en: String,
    val hi: String,
    val note: String,
)

/** A More-tab entry: slang, or a Hindi–Thai Sanskrit cousin. Mirrors iOS `FunWord`. */
data class FunWord(
    val thai: String,
    val roman: String,
    val meaning: String,
    val hindi: String,
    val note: String,
)

/** Two words shown side by side — opposites, or easily-confused pairs. */
data class WordPair(
    val thaiA: String, val romanA: String, val meaningA: String, val hindiA: String,
    val thaiB: String, val romanB: String, val meaningB: String, val hindiB: String,
    val note: String,
)

/** A "must-know fact" card: headline plus explanation. */
data class ThaiFact(val title: String, val body: String)

/**
 * The bundled content, decoded once — the Kotlin twin of iOS `ContentStore`.
 *
 * Both apps read the identical `content.json`, written by tools/export_json.py
 * and tools/integrate_batch.py. Before 2026-08-02 this read a flat
 * `vocabulary.json` that carried words only, which is why Android sat at 1,046
 * words with no sentences while iOS had 4,446 with all the extras.
 */
object Content {
    private var loaded: Payload? = null

    private class Payload(
        val words: List<ThaiWord>,
        val examples: Map<Int, List<WordExample>>,
        val forms: Map<Int, List<WordForm>>,
        val similar: Map<Int, List<Int>>,
        val compounds: Map<Int, String>,
        val emoji: Map<Int, String>,
        val slang: List<FunWord>,
        val cousins: List<FunWord>,
        val opposites: List<WordPair>,
        val similars: List<WordPair>,
        val facts: List<ThaiFact>,
    )

    private fun payload(context: Context): Payload = loaded ?: synchronized(this) {
        loaded ?: parse(context).also { loaded = it }
    }

    private fun parse(context: Context): Payload {
        val root = JSONObject(
            context.assets.open("content.json").bufferedReader().use { it.readText() }
        )

        val wordsArray = root.getJSONArray("words")
        val words = ArrayList<ThaiWord>(wordsArray.length())
        for (i in 0 until wordsArray.length()) {
            val o = wordsArray.getJSONObject(i)
            words.add(
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

        return Payload(
            words = words,
            examples = intMap(root, "examples") { rows ->
                List(rows.length()) { i ->
                    val o = rows.getJSONObject(i)
                    WordExample(o.getString("thai"), o.getString("roman"), o.getString("en"), o.getString("hi"))
                }
            },
            forms = intMap(root, "forms") { rows ->
                List(rows.length()) { i ->
                    val o = rows.getJSONObject(i)
                    WordForm(
                        o.getString("thai"), o.getString("roman"),
                        o.getString("en"), o.getString("hi"), o.getString("note"),
                    )
                }
            },
            similar = intMap(root, "similar") { rows -> List(rows.length()) { i -> rows.getInt(i) } },
            compounds = intStringMap(root, "compounds"),
            emoji = intStringMap(root, "emoji"),
            slang = funWords(root, "slang"),
            cousins = funWords(root, "cousins"),
            opposites = pairs(root, "opposites"),
            similars = pairs(root, "similars"),
            facts = rows(root, "facts") { ThaiFact(it.getString("title"), it.getString("body")) },
        )
    }

    private fun <T> rows(root: JSONObject, field: String, make: (JSONObject) -> T): List<T> {
        val arr = root.getJSONArray(field)
        return List(arr.length()) { i -> make(arr.getJSONObject(i)) }
    }

    private fun funWords(root: JSONObject, field: String) = rows(root, field) {
        FunWord(
            it.getString("thai"), it.getString("roman"),
            it.getString("meaning"), it.getString("hindi"), it.getString("note"),
        )
    }

    private fun pairs(root: JSONObject, field: String) = rows(root, field) {
        WordPair(
            it.getString("thaiA"), it.getString("romanA"), it.getString("meaningA"), it.getString("hindiA"),
            it.getString("thaiB"), it.getString("romanB"), it.getString("meaningB"), it.getString("hindiB"),
            it.getString("note"),
        )
    }

    /** JSON object keys are strings; everything in the app is keyed by word id. */
    private fun <T> intMap(
        root: JSONObject,
        field: String,
        transform: (org.json.JSONArray) -> T,
    ): Map<Int, T> {
        val src = root.getJSONObject(field)
        val out = HashMap<Int, T>(src.length())
        for (key in src.keys()) {
            key.toIntOrNull()?.let { out[it] = transform(src.getJSONArray(key)) }
        }
        return out
    }

    private fun intStringMap(root: JSONObject, field: String): Map<Int, String> {
        val src = root.getJSONObject(field)
        val out = HashMap<Int, String>(src.length())
        for (key in src.keys()) {
            key.toIntOrNull()?.let { out[it] = src.getString(key) }
        }
        return out
    }

    fun words(context: Context): List<ThaiWord> = payload(context).words

    fun slang(context: Context): List<FunWord> = payload(context).slang

    /** Genuine Sanskrit/Pali cognates a Hindi speaker already half-knows. */
    fun cousins(context: Context): List<FunWord> = payload(context).cousins

    fun opposites(context: Context): List<WordPair> = payload(context).opposites

    fun similarPairs(context: Context): List<WordPair> = payload(context).similars

    fun facts(context: Context): List<ThaiFact> = payload(context).facts

    fun examples(context: Context, id: Int): List<WordExample> =
        payload(context).examples[id].orEmpty()

    fun forms(context: Context, id: Int): List<WordForm> = payload(context).forms[id].orEmpty()

    fun compoundNote(context: Context, id: Int): String? = payload(context).compounds[id]

    fun emoji(context: Context, id: Int): String? = payload(context).emoji[id]

    /** Words that sound alike but mean something different — a classic learner trap. */
    fun similarSounds(context: Context, id: Int): List<ThaiWord> {
        val p = payload(context)
        val ids = p.similar[id].orEmpty().toSet()
        return p.words.filter { it.id in ids }
    }

    /**
     * Words whose Thai spelling contains this one, or that this one contains —
     * น้ำ → ห้องน้ำ, น้ำตาล. Mirrors iOS `Vocabulary.related(to:)`.
     */
    fun related(context: Context, word: ThaiWord): List<ThaiWord> =
        payload(context).words.filter {
            it.id != word.id && (it.thai.contains(word.thai) || word.thai.contains(it.thai))
        }
}

object Vocab {
    fun all(context: Context): List<ThaiWord> = Content.words(context)

    /** Deterministic daily word — same day, same word, like the iOS Today tab. */
    fun wordOfTheDay(context: Context): ThaiWord {
        val words = all(context)
        val day = (System.currentTimeMillis() / 86_400_000L).toInt()
        return words[day % words.size]
    }
}
