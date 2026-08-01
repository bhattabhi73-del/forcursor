package com.thailearn.app

import android.content.Context

/**
 * Leitner spaced repetition — mirrors the iOS ProgressStore: box 0 (new) to 5,
 * next-review intervals 1/3/7/14/30 days, misses drop back to box 1.
 */
class ProgressStore(context: Context) {
    private val prefs = context.getSharedPreferences("progress", Context.MODE_PRIVATE)

    companion object {
        const val DAILY_GOAL = 12
        private val INTERVALS_DAYS = intArrayOf(0, 1, 3, 7, 14, 30)
    }

    fun box(id: Int): Int = prefs.getInt("box.$id", 0)

    private fun nextReview(id: Int): Long = prefs.getLong("next.$id", 0L)

    fun isDue(id: Int): Boolean =
        box(id) > 0 && nextReview(id) <= System.currentTimeMillis()

    fun record(id: Int, known: Boolean) {
        val newBox = if (known) minOf(box(id) + 1, 5) else 1
        val next = System.currentTimeMillis() + INTERVALS_DAYS[newBox] * 86_400_000L
        prefs.edit()
            .putInt("box.$id", newBox)
            .putLong("next.$id", next)
            .putInt("reviews.today.count", reviewsToday() + 1)
            .putLong("reviews.today.day", todayStart())
            .apply()
    }

    fun reviewsToday(): Int =
        if (prefs.getLong("reviews.today.day", 0L) == todayStart())
            prefs.getInt("reviews.today.count", 0) else 0

    private fun todayStart(): Long {
        val now = java.util.Calendar.getInstance()
        now.set(java.util.Calendar.HOUR_OF_DAY, 0)
        now.set(java.util.Calendar.MINUTE, 0)
        now.set(java.util.Calendar.SECOND, 0)
        now.set(java.util.Calendar.MILLISECOND, 0)
        return now.timeInMillis
    }

    /** ThaiFlow deck: due first, then up to 20 new, then seen, then backlog. */
    fun buildDeck(words: List<ThaiWord>): List<ThaiWord> {
        val due = words.filter { isDue(it.id) }.shuffled()
        val fresh = words.filter { box(it.id) == 0 }.shuffled()
        val seen = words.filter { box(it.id) > 0 && !isDue(it.id) }.shuffled()
        return due + fresh.take(20) + seen + fresh.drop(20)
    }

    fun sessionTarget(words: List<ThaiWord>): Int {
        val due = words.count { isDue(it.id) }
        val fresh = words.count { box(it.id) == 0 }
        return maxOf(due + minOf(fresh, 20), 5)
    }
}
