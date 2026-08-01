import Foundation
import SwiftUI

/// Blue rebrand (from Sukhothai Gold) — pale-blue grounds, mid-blue primary
/// accent, light-blue second accent, navy ink. Old warm names stay as
/// semantic aliases (indigo → accent, gold → accent2 400, orchid → accent700,
/// jade → accent2) so every screen keeps compiling; prefer the new roles in
/// new code.
enum ThaiTheme {
    // MARK: New semantic roles

    static let bg            = Color(hex: 0xEEF3FA)  // page ground
    static let bgAlt         = Color(hex: 0xF5F8FC)  // alternate ground (quiz)
    static let surface       = Color(hex: 0xFBFDFF)  // cards, rows
    static let surfaceSunken = Color(hex: 0xE3EBF5)  // chips, pressed rows
    static let hairline      = Color(hex: 0xDCE5F0)  // dividers, empty progress

    static let accent100     = Color(hex: 0xEAF2FC)
    static let accent200     = Color(hex: 0xD8E7F8)
    static let accent300     = Color(hex: 0xAECDF0)
    static let accent400     = Color(hex: 0x6F9FE0)
    static let accent        = Color(hex: 0x2F6BC0)  // primary
    static let accent600     = Color(hex: 0x24559C)  // hover
    static let accent700     = Color(hex: 0x1B4079)  // pressed / accent text

    static let accent2100    = Color(hex: 0xE6F3FB)
    static let accent2200    = Color(hex: 0xCFE7F6)
    static let accent2300    = Color(hex: 0xA9D3EA)
    static let accent2400    = Color(hex: 0x79B6DA)
    static let accent2       = Color(hex: 0x3B7AA2)  // second voice / success
    static let accent2600    = Color(hex: 0x2C5F80)
    static let accent2800    = Color(hex: 0x1C3352)

    static let textMuted     = Color(hex: 0x64748E)
    static let textFaint     = Color(hex: 0x8C9CB4)
    static let inkDeep       = Color(hex: 0x16233D)  // dark card face

    // MARK: Warm-name aliases (legacy call sites)

    static let sand       = bg
    static let cream      = surface
    static let parchment  = surfaceSunken
    static let ink        = Color(hex: 0x101C33)
    static let indigo     = accent
    static let deepIndigo = inkDeep
    static let gold       = accent2400
    static let lightGold  = accent200
    static let orchid     = accent700   // Devanagari voice
    static let jade       = accent2
    static let plum       = Color(hex: 0x4E92BD)
    static let stone      = textMuted

    // Semantic roles — prefer these over raw RGB in UI chrome.
    static let success    = accent2
    static let danger     = Color(hex: 0xC2503F)
    static let toneMid    = textMuted
    static let toneLow    = Color(red: 0.290, green: 0.435, blue: 0.831)
    static let toneFalling = danger
    static let toneHigh   = Color(red: 0.902, green: 0.541, blue: 0.180)
    static let toneRising = Color(red: 0.243, green: 0.647, blue: 0.424)

    // Consonant classes must stay three distinguishable hues.
    static let classMiddle = accent
    static let classHigh   = accent700
    static let classLow    = accent2

    // Spacing / radius scale (8-pt grid).
    static let spaceXS: CGFloat = 4
    static let spaceSM: CGFloat = 8
    static let spaceMD: CGFloat = 12
    static let spaceLG: CGFloat = 16
    static let spaceXL: CGFloat = 24
    static let radiusControl: CGFloat = 14
    static let radiusCard: CGFloat = 24
    static let radiusChip: CGFloat = 14

    // Widget backgrounds are deliberately dark: white text stays readable
    // no matter what wallpaper sits behind or beside the widget.
    static let thaiGradient = LinearGradient(
        colors: [Color(hex: 0x101C33), Color(hex: 0x1C3352)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let englishGradient = LinearGradient(
        colors: [Color(hex: 0x16233D), Color(hex: 0x2C5F80)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: Fonts

    /// Caladea (SIL OFL) is the metric-compatible stand-in for Cambria;
    /// registered from the app bundle at launch. Use for display text only —
    /// it lacks the caron tone vowels (ǎ ǐ ǒ ǔ), so romanization stays in
    /// the system face.
    static func display(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Caladea-Bold" : "Caladea", size: size)
    }

    /// Mitr (Google, OFL) — the Thai hero voice of the blue design system.
    /// Falls back to the system face where unregistered (widgets).
    static func thai(_ size: CGFloat) -> Font {
        .custom("Mitr-Medium", size: size)
    }

    /// Quiet pale-blue wash the glass cards float on.
    static let glassWash = LinearGradient(
        colors: [sand, parchment.opacity(0.85), sand],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Color {
    /// 0xRRGGBB convenience initializer.
    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255)
    }
}

/// A single vocabulary entry shown in the app and on the widget.
///
/// Every word carries four learning aids around the Thai script:
///  - `romanization`      → how to *say* it, written in the Latin alphabet (English pronunciation)
///  - `hindiPronunciation`→ how to *say* it, written in Devanagari (Hindi pronunciation)
///  - `englishMeaning`    → what it *means*, in English
///  - `hindiMeaning`      → what it *means*, in Hindi
struct ThaiWord: Identifiable, Codable, Hashable {
    let id: Int
    let thai: String
    let romanization: String
    let hindiPronunciation: String
    let englishMeaning: String
    let hindiMeaning: String
    let category: String
}

/// A short sentence showing a word in real use, in all three languages.
struct WordExample {
    let thai: String
    let romanization: String
    let english: String
    let hindi: String
}

/// Leitner-style spaced repetition: each word lives in a box (0 = new,
/// 1-5 = learning through known). A correct answer moves it up a box and
/// schedules the next review further out (1, 3, 7, 14, 30 days); a miss
/// drops it back to box 1 and tomorrow. Based on the Ebbinghaus
/// forgetting-curve research used by Anki/SM-2.
final class ProgressStore {
    static let shared = ProgressStore()

    struct WordProgress: Codable {
        var box = 0
        var nextReview = Date.distantPast
        var reviews = 0
        var lapses = 0
    }

    private static let intervals: [TimeInterval] = [0, 1, 3, 7, 14, 30].map { $0 * 86_400 }
    private let key = "wordProgress.v1"
    private var progress: [Int: WordProgress]

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Int: WordProgress].self, from: data) {
            progress = saved
        } else {
            progress = [:]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func box(for id: Int) -> Int { progress[id]?.box ?? 0 }

    func nextReview(for id: Int) -> Date? { progress[id]?.nextReview }

    func isDue(_ id: Int) -> Bool {
        guard let p = progress[id], p.box > 0 else { return false }
        return p.nextReview <= Date()
    }

    func record(id: Int, known: Bool) {
        var p = progress[id] ?? WordProgress()
        p.reviews += 1
        if known {
            p.box = min(p.box + 1, 5)
        } else {
            p.box = 1
            p.lapses += 1
        }
        p.nextReview = Date().addingTimeInterval(Self.intervals[p.box])
        progress[id] = p
        save()
        recordPracticeToday()
        bumpReviewsToday()
    }

    // MARK: Daily goal (cards reviewed today)

    static let dailyGoal = 12

    private let reviewsDayKey = "reviewsDay.v1"
    private let reviewsCountKey = "reviewsTodayCount.v1"

    private func bumpReviewsToday() {
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let storedDay = UserDefaults.standard.double(forKey: reviewsDayKey)
        let count = storedDay == today ? UserDefaults.standard.integer(forKey: reviewsCountKey) : 0
        UserDefaults.standard.set(today, forKey: reviewsDayKey)
        UserDefaults.standard.set(count + 1, forKey: reviewsCountKey)
    }

    var reviewsToday: Int {
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        guard UserDefaults.standard.double(forKey: reviewsDayKey) == today else { return 0 }
        return UserDefaults.standard.integer(forKey: reviewsCountKey)
    }

    // MARK: Recently viewed words (Browse detail, search suggestions)

    private let recentsKey = "recentWords.v1"

    func recordViewed(id: Int) {
        var ids = (UserDefaults.standard.array(forKey: recentsKey) as? [Int]) ?? []
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        UserDefaults.standard.set(Array(ids.prefix(10)), forKey: recentsKey)
    }

    var recentlyViewed: [ThaiWord] {
        let ids = (UserDefaults.standard.array(forKey: recentsKey) as? [Int]) ?? []
        return ids.compactMap { id in Vocabulary.all.first { $0.id == id } }
    }

    // MARK: Daily practice streak

    private let streakKey = "practiceDays.v1"

    private func recordPracticeToday() {
        var days = Set(UserDefaults.standard.array(forKey: streakKey) as? [Double] ?? [])
        days.insert(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)
        UserDefaults.standard.set(Array(days), forKey: streakKey)
    }

    /// Consecutive practice days ending today — or yesterday, so a streak
    /// isn't shown as broken before today's session happens.
    func currentStreak() -> Int {
        let stored = (UserDefaults.standard.array(forKey: streakKey) as? [Double] ?? [])
        guard !stored.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(stored.map { cal.startOfDay(for: Date(timeIntervalSince1970: $0)) })
        var cursor = cal.startOfDay(for: Date())
        if !days.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while days.contains(cursor), let prev = cal.date(byAdding: .day, value: -1, to: cursor) {
            count += 1
            cursor = prev
        }
        return count
    }

    /// (due for review, never seen, known = box 3+)
    func counts(in words: [ThaiWord]) -> (due: Int, fresh: Int, known: Int) {
        var due = 0, fresh = 0, known = 0
        for w in words {
            let b = box(for: w.id)
            if b == 0 { fresh += 1 }
            else if isDue(w.id) { due += 1 }
            if b >= 3 { known += 1 }
        }
        return (due, fresh, known)
    }
}

/// Thai's five tones, detected from the tone marks in our romanization
/// (à = low, á = high, â = falling, ǎ = rising, unmarked = mid).
enum ThaiTone {
    case mid, low, falling, high, rising

    var englishName: String {
        switch self {
        case .mid: return "mid"
        case .low: return "low"
        case .falling: return "falling"
        case .high: return "high"
        case .rising: return "rising"
        }
    }
}

/// One spoken syllable of a romanized word with its tone.
struct ToneSyllable {
    let text: String
    let tone: ThaiTone
}

enum ToneAnalyzer {
    static func syllables(of romanization: String) -> [ToneSyllable] {
        romanization
            .split(whereSeparator: { $0 == "-" || $0 == " " })
            .map { syllable in
                let text = String(syllable)
                var tone = ThaiTone.mid
                for scalar in text.decomposedStringWithCanonicalMapping.unicodeScalars {
                    switch scalar.value {
                    case 0x300: tone = .low       // grave: à
                    case 0x301: tone = .high      // acute: á
                    case 0x302: tone = .falling   // circumflex: â
                    case 0x30C: tone = .rising    // caron: ǎ
                    default: break
                    }
                }
                return ToneSyllable(text: text, tone: tone)
            }
    }
}

/// A grammatical form or common pattern built on a word — like English
/// "beauty → beautiful": สวย → สวยมาก (very), ไม่สวย (not), สวยที่สุด (most).
struct WordForm {
    let thai: String
    let romanization: String
    let english: String
    let hindi: String
    let note: String
}

/// Extra learning material for selected words, keyed by `ThaiWord.id`.
/// Not every word has extras; the UI shows these sections only when present.
///
/// The data used to live here as Swift literals — 16.5k lines of them. Swift
/// type-checks a dictionary literal as one expression, and the constraint
/// solver is superlinear in its size: a single swift-frontend job reached 18 GB
/// type-checking this file and kernel-panicked an 8 GB Mac three times on
/// 2026-08-02. It all lives in `content.json` now; see `ContentStore`.
enum WordExtras {
    static func examples(for word: ThaiWord) -> [WordExample] {
        if let handWritten = ContentStore.examples[word.id] { return handWritten }
        return generatedExamples(for: word)
    }

    /// Hand-written notes win over the generated number ones; the exporter
    /// merges them in that order, so a single lookup is enough here.
    static func compoundNote(for word: ThaiWord) -> String? {
        ContentStore.compounds[word.id]
    }

    static func forms(for word: ThaiWord) -> [WordForm] { ContentStore.forms[word.id] ?? [] }

    /// Visual mnemonic (dual-coding research: picture + word beats word
    /// alone). Populated by the generation pipeline.
    static func emoji(for word: ThaiWord) -> String? { ContentStore.emoji[word.id] }

    /// Words that sound alike but mean something different — a classic
    /// Thai-learner trap (tones change the meaning).
    static func similarSounds(for word: ThaiWord) -> [ThaiWord] {
        (ContentStore.similar[word.id] ?? []).compactMap { id in Vocabulary.all.first { $0.id == id } }
    }

    private static func generatedExamples(for word: ThaiWord) -> [WordExample] {
        switch word.category {
        case "Numbers":
            return [
                WordExample(
                    thai: "คิวของคุณคือหมายเลข\(word.thai)",
                    romanization: "khiu khǒong khun khuue mǎai-lêek \(word.romanization)",
                    english: "Your queue number is \(word.englishMeaning).",
                    hindi: "आपका क्यू नंबर \(word.hindiMeaning) है।"),
                WordExample(
                    thai: "อันนี้\(word.thai)บาท",
                    romanization: "an-níi \(word.romanization) bàat",
                    english: "This one is \(word.englishMeaning) baht.",
                    hindi: "इसकी क़ीमत \(word.hindiMeaning) बाथ है।"),
            ]
        case "Colors" where word.id != 83:
            return [
                WordExample(
                    thai: "เสื้อตัวนี้สี\(word.thai)",
                    romanization: "sûuea tua níi sǐi \(word.romanization)",
                    english: "This shirt is \(word.englishMeaning).",
                    hindi: "यह शर्ट \(word.hindiMeaning) रंग की है।"),
                WordExample(
                    thai: "ผมชอบสี\(word.thai)",
                    romanization: "phǒm chôp sǐi \(word.romanization)",
                    english: "I like the color \(word.englishMeaning).",
                    hindi: "मुझे \(word.hindiMeaning) रंग पसंद है।"),
            ]
        case "Places":
            return [
                WordExample(
                    thai: "\(word.thai)อยู่ที่ไหน",
                    romanization: "\(word.romanization) yùu thîi-nǎi",
                    english: "Where is the \(word.englishMeaning)?",
                    hindi: "\(word.hindiMeaning) कहाँ है?"),
                WordExample(
                    thai: "\(word.thai)อยู่ใกล้ๆ",
                    romanization: "\(word.romanization) yùu klâi-klâi",
                    english: "The \(word.englishMeaning) is nearby.",
                    hindi: "\(word.hindiMeaning) पास में है।"),
            ]
        case "Animals":
            return [
                WordExample(
                    thai: "ผมเห็น\(word.thai)",
                    romanization: "phǒm hěn \(word.romanization)",
                    english: "I see a \(word.englishMeaning).",
                    hindi: "मुझे एक \(word.hindiMeaning) दिख रहा है।"),
                WordExample(
                    thai: "\(word.thai)ตัวนี้น่ารัก",
                    romanization: "\(word.romanization) tua níi nâa-rák",
                    english: "This \(word.englishMeaning) is cute.",
                    hindi: "यह \(word.hindiMeaning) प्यारा है।"),
            ]
        case "Family":
            return [
                WordExample(
                    thai: "นี่คือ\(word.thai)ของผม",
                    romanization: "nîi khuue \(word.romanization) khǒong phǒm",
                    english: "This is my \(word.englishMeaning).",
                    hindi: "यह मेरे \(word.hindiMeaning) हैं।"),
            ]
        default:
            return []
        }
    }
}

// MARK: - More tab types
//
// These live in Shared, not ContentView.swift, because ContentStore
// decodes them and ContentStore compiles into the widget extension too.

struct FunWord: Identifiable {
    let thai: String
    let roman: String
    let meaning: String
    let hindi: String
    let note: String
    var id: String { thai }
}

struct WordPair: Identifiable {
    let thaiA: String
    let romanA: String
    let meaningA: String
    let hindiA: String
    let thaiB: String
    let romanB: String
    let meaningB: String
    let hindiB: String
    let note: String
    var id: String { thaiA + "·" + thaiB }
}
