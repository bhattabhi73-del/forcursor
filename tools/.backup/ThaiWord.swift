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
enum WordExtras {
    static func examples(for word: ThaiWord) -> [WordExample] {
        if let handWritten = examples[word.id] { return handWritten }
        return generatedExamples(for: word)
    }

    static func compoundNote(for word: ThaiWord) -> String? {
        compounds[word.id] ?? numberCompounds[word.id]
    }

    static func forms(for word: ThaiWord) -> [WordForm] { forms[word.id] ?? [] }

    /// Visual mnemonic (dual-coding research: picture + word beats word
    /// alone). Populated by the generation pipeline.
    static func emoji(for word: ThaiWord) -> String? { emojis[word.id] }

    private static let emojis: [Int: String] = [:]

    private static let forms: [Int: [WordForm]] = [
        425: [
            WordForm(thai: "อันนี้", romanization: "an níi", english: "this one", hindi: "यह वाला", note: "นี้ follows a noun or classifier; นี่ stands alone / นี้ संज्ञा के बाद आता है, นี่ अकेला"),
            WordForm(thai: "วันนี้", romanization: "wan-níi", english: "today", hindi: "आज", note: "วัน day + นี้ this → today / दिन + यह = आज"),
        ],
        426: [
            WordForm(thai: "ขอน้ำ", romanization: "khǒo náam", english: "may I have water", hindi: "पानी दीजिए", note: "ขอ + noun = may I have … / ขอ + संज्ञा = … दीजिए"),
            WordForm(thai: "ขอโทษ", romanization: "khǒo-thôot", english: "sorry / excuse me", hindi: "माफ़ कीजिए", note: "ขอ + โทษ (blame) → asking forgiveness / क्षमा माँगना"),
        ],
        427: [
            WordForm(thai: "ไปไหม", romanization: "pai mǎi", english: "are you going?", hindi: "चलोगे?", note: "statement + ไหม = yes/no question / वाक्य + ไหม = हाँ/नहीं वाला सवाल"),
            WordForm(thai: "อร่อยไหม", romanization: "à-ròi mǎi", english: "is it tasty?", hindi: "स्वादिष्ट है क्या?", note: ""),
        ],
        428: [
            WordForm(thai: "ช่วยหน่อย", romanization: "chûai nòi", english: "please help", hindi: "ज़रा मदद कीजिए", note: "verb + หน่อย softens a request / क्रिया + หน่อย अनुरोध को नरम बनाता है"),
            WordForm(thai: "รอหน่อย", romanization: "roo nòi", english: "wait a moment", hindi: "ज़रा रुकिए", note: ""),
        ],
        429: [
            WordForm(thai: "คนไทย", romanization: "khon thai", english: "Thai person", hindi: "थाई व्यक्ति", note: ""),
            WordForm(thai: "เมืองไทย", romanization: "mueang-thai", english: "Thailand (colloquial)", hindi: "थाईलैंड (बोलचाल)", note: ""),
            WordForm(thai: "อาหารไทย", romanization: "aa-hǎan thai", english: "Thai food", hindi: "थाई खाना", note: ""),
        ],
        430: [
            WordForm(thai: "ฝนตก", romanization: "fǒn tòk", english: "it's raining", hindi: "बारिश हो रही है", note: "Thai says 'rain falls' / थाई में 'बारिश गिरती है' कहते हैं"),
        ],
        431: [
            WordForm(thai: "ด้วยกัน", romanization: "dûai-kan", english: "together", hindi: "साथ में", note: ""),
            WordForm(thai: "ไปกินข้าวกัน", romanization: "pai kin khâao kan", english: "let's go eat!", hindi: "चलो खाने चलें!", note: "verb + กัน = let's … together / क्रिया + กัน = साथ में करना"),
        ],
        432: [
            WordForm(thai: "คืออะไร", romanization: "khuue à-rai", english: "what is …?", hindi: "… क्या है?", note: "คือ links two nouns: A คือ B / คือ दो संज्ञाओं को जोड़ता है"),
        ],
        433: [
            WordForm(thai: "อย่าลืม", romanization: "yàa luem", english: "don't forget", hindi: "भूलना मत", note: "อย่า + verb = don't … / อย่า + क्रिया = मत करो"),
            WordForm(thai: "อย่าไป", romanization: "yàa pai", english: "don't go", hindi: "मत जाओ", note: ""),
        ],
        434: [
            WordForm(thai: "ตอนนี้", romanization: "toon-níi", english: "now", hindi: "अभी", note: ""),
            WordForm(thai: "ตอนเช้า", romanization: "toon-cháo", english: "in the morning", hindi: "सुबह के समय", note: "ตอน + time word = during … / ตอน + समय-शब्द = उस समय"),
        ],
        435: [
            WordForm(thai: "ข้างบน", romanization: "khâang-bon", english: "above / upstairs", hindi: "ऊपर", note: ""),
        ],
        436: [
            WordForm(thai: "ที่ไหน", romanization: "thîi-nǎi", english: "where?", hindi: "कहाँ?", note: ""),
            WordForm(thai: "อันไหน", romanization: "an nǎi", english: "which one?", hindi: "कौन-सा?", note: "noun/classifier + ไหน = which … / गणक + ไหน = कौन-सा"),
        ],
        437: [
            WordForm(thai: "ล้างมือ", romanization: "láang muue", english: "wash hands", hindi: "हाथ धोना", note: ""),
            WordForm(thai: "ล้างจาน", romanization: "láang jaan", english: "do the dishes", hindi: "बर्तन धोना", note: ""),
        ],
        438: [
            WordForm(thai: "เลี้ยวซ้าย", romanization: "líao sáai", english: "turn left", hindi: "बाएँ मुड़िए", note: ""),
            WordForm(thai: "เลี้ยวขวา", romanization: "líao khwǎa", english: "turn right", hindi: "दाएँ मुड़िए", note: ""),
        ],
        439: [
            WordForm(thai: "ไม่ชอบเลย", romanization: "mâi chôp loei", english: "don't like it at all", hindi: "बिल्कुल पसंद नहीं", note: "ไม่ + verb + เลย = not at all / ไม่ + क्रिया + เลย = बिल्कुल नहीं"),
        ],
        440: [
            WordForm(thai: "อ่านหนังสือ", romanization: "àan nǎng-sǔue", english: "to read / to study", hindi: "पढ़ना / पढ़ाई करना", note: "Thai says 'read book' even for studying / पढ़ाई के लिए भी 'किताब पढ़ना' कहते हैं"),
        ],
        441: [
            WordForm(thai: "อายุเท่าไหร่", romanization: "aa-yú thâo-rài", english: "how old?", hindi: "उम्र कितनी है?", note: "Same Sanskrit root as Hindi आयु / संस्कृत से आया शब्द, हिंदी 'आयु' जैसा"),
        ],
        442: [
            WordForm(thai: "ยกมือ", romanization: "yók muue", english: "raise your hand", hindi: "हाथ उठाना", note: ""),
        ],
        443: [
            WordForm(thai: "ค่ารถ", romanization: "khâa rót", english: "fare (transport)", hindi: "गाड़ी का किराया", note: "ค่า + noun = cost of … / ค่า + संज्ञा = उसका शुल्क"),
            WordForm(thai: "ค่าห้อง", romanization: "khâa hôong", english: "room charge", hindi: "कमरे का किराया", note: "Don't confuse with ค่ะ (polite particle) / ค่ะ (आदरसूचक शब्द) से अलग है"),
        ],
        444: [
            WordForm(thai: "อีกครั้ง", romanization: "ìik khráng", english: "once more", hindi: "एक बार फिर", note: ""),
            WordForm(thai: "อีกแก้ว", romanization: "ìik kâew", english: "one more glass", hindi: "एक गिलास और", note: "อีก + classifier = one more … / อีก + गणक = एक और"),
        ],
        445: [
            WordForm(thai: "อากาศแห้ง", romanization: "aa-kàat hâeng", english: "dry weather", hindi: "सूखा मौसम", note: ""),
        ],
        446: [
            WordForm(thai: "เลิกงาน", romanization: "lôek ngaan", english: "get off work", hindi: "काम से छूटना", note: "Everyday word for finishing the workday / रोज़ काम ख़त्म होने के लिए आम शब्द"),
        ],
        447: [
            WordForm(thai: "รถคันนี้", romanization: "rót khan níi", english: "this car", hindi: "यह गाड़ी", note: "noun + classifier + นี้ = this … / संज्ञा + गणक + นี้ = यह"),
            WordForm(thai: "รถสองคัน", romanization: "rót sǒong khan", english: "two cars", hindi: "दो गाड़ियाँ", note: "noun + number + classifier / संज्ञा + संख्या + गणक"),
        ],
        448: [
            WordForm(thai: "คนอินเดีย", romanization: "khon in-dia", english: "Indian person", hindi: "भारतीय", note: ""),
            WordForm(thai: "อาหารอินเดีย", romanization: "aa-hǎan in-dia", english: "Indian food", hindi: "भारतीय खाना", note: ""),
        ],
        223: [
            WordForm(thai: "พวกเรา", romanization: "phûak-rao", english: "we / us (group)", hindi: "हम लोग", note: "พวก makes pronouns clearly plural / सर्वनाम को बहुवचन बनाता है"),
            WordForm(thai: "เราไปก่อนนะ", romanization: "rao pai kòon ná", english: "I'm off now (casual)", hindi: "मैं चलता हूँ (अनौपचारिक)", note: "Among friends เรา often means 'I' / दोस्तों में เรา का मतलब 'मैं' भी होता है"),
        ],
        224: [
            WordForm(thai: "พวกเขา", romanization: "phûak-khǎo", english: "they / them", hindi: "वे लोग", note: "One word for he and she — in speech often said kháo / 'वह' और 'वही' दोनों के लिए एक शब्द"),
        ],
        225: [
            WordForm(thai: "มันคืออะไร", romanization: "man khue à-rai", english: "what is it?", hindi: "यह क्या है?", note: "Use มัน only for things and animals — rude for people / केवल चीज़ों-जानवरों के लिए, लोगों के लिए अशिष्ट"),
        ],
        226: [
            WordForm(thai: "ของคุณ", romanization: "khǒong khun", english: "yours", hindi: "आपका", note: "Owner comes after ของ / मालिक ของ के बाद आता है"),
            WordForm(thai: "ของเขา", romanization: "khǒong khǎo", english: "his / hers", hindi: "उसका", note: ""),
        ],
        227: [
            WordForm(thai: "ข้างใน", romanization: "khâang-nai", english: "inside", hindi: "अंदर", note: "Like ข้างบน above / ข้างล่าง below / जैसे ऊपर-नीचे वैसे अंदर"),
        ],
        229: [
            WordForm(thai: "ถึงแล้ว", romanization: "thǔeng láew", english: "we've arrived!", hindi: "पहुँच गए!", note: "Very common phrase in taxis / टैक्सी में बहुत आम वाक्य"),
        ],
        230: [
            WordForm(thai: "จะไม่ไป", romanization: "jà mâi pai", english: "will not go", hindi: "नहीं जाएगा", note: "จะ + ไม่ + verb = will not / จะ के बाद ไม่ लगाने से भविष्य का नकार"),
        ],
        231: [
            WordForm(thai: "กินได้", romanization: "kin dâi", english: "can eat", hindi: "खा सकते हैं", note: "verb + ได้ = can / क्रिया के बाद ได้ = सकना"),
            WordForm(thai: "ไปไม่ได้", romanization: "pai mâi dâi", english: "cannot go", hindi: "नहीं जा सकते", note: "verb + ไม่ได้ = cannot / क्रिया + ไม่ได้ = नहीं कर सकते"),
        ],
        232: [
            WordForm(thai: "ไม่ใช่", romanization: "mâi châi", english: "is not", hindi: "नहीं है", note: "Negate เป็น with ไม่ใช่, not ไม่เป็น / เป็น का नकार ไม่ใช่ से होता है"),
        ],
        233: [
            WordForm(thai: "กินอยู่", romanization: "kin yùu", english: "is eating (right now)", hindi: "खा रहा है", note: "verb + อยู่ = -ing, action in progress / क्रिया + อยู่ = 'रहा है'"),
        ],
        234: [
            WordForm(thai: "ไม่มี", romanization: "mâi mii", english: "don't have / there is none", hindi: "नहीं है", note: "You will hear this daily in shops / दुकानों में रोज़ सुनाई देता है"),
        ],
        235: [
            WordForm(thai: "ทุกคน", romanization: "thúk khon", english: "everyone", hindi: "सब लोग", note: "ทุก + noun, never alone / ทุก हमेशा संज्ञा के साथ आता है"),
        ],
        236: [
            WordForm(thai: "บางที", romanization: "baang-thii", english: "sometimes / maybe", hindi: "कभी-कभी / शायद", note: ""),
        ],
        237: [
            WordForm(thai: "อะไรก็ได้", romanization: "à-rai kô dâi", english: "anything is fine", hindi: "कुछ भी चलेगा", note: "ก็ได้ = 'that works too', super common answer / बहुत आम जवाब"),
        ],
        238: [
            WordForm(thai: "ยังไม่กิน", romanization: "yang mâi kin", english: "haven't eaten yet", hindi: "अभी तक नहीं खाया", note: "ยังไม่ + verb = not yet / ยังไม่ + क्रिया = अभी तक नहीं"),
        ],
        241: [
            WordForm(thai: "กินแล้ว", romanization: "kin láew", english: "already ate", hindi: "खा चुका", note: "verb + แล้ว = action completed / क्रिया + แล้ว = काम पूरा हुआ"),
            WordForm(thai: "แล้วคุณล่ะ", romanization: "láew khun lâ", english: "and you?", hindi: "और आप?", note: ""),
        ],
        242: [
            WordForm(thai: "ไม่ต้องรอ", romanization: "mâi tôong roo", english: "no need to wait", hindi: "इंतज़ार की ज़रूरत नहीं", note: "ไม่ต้อง + verb = no need to / ไม่ต้อง + क्रिया = ज़रूरत नहीं"),
        ],
        243: [
            WordForm(thai: "อยากได้", romanization: "yàak dâi", english: "want (a thing)", hindi: "(चीज़) चाहिए", note: "อยาก + verb for actions; อยากได้ + noun for things / काम के लिए อยาก, चीज़ के लिए อยากได้"),
        ],
        244: [
            WordForm(thai: "ซื้อให้", romanization: "súe hâi", english: "buy for (someone)", hindi: "किसी के लिए खरीदना", note: "verb + ให้ + person = do for someone / क्रिया + ให้ = किसी के लिए करना"),
        ],
        245: [
            WordForm(thai: "คิดว่า", romanization: "khít wâa", english: "to think that...", hindi: "सोचना कि...", note: "Follows verbs of saying and thinking, just like Hindi 'कि' / बोलने-सोचने की क्रियाओं के बाद"),
        ],
        247: [
            WordForm(thai: "ขอบคุณนะ", romanization: "khòop-khun ná", english: "thanks (warm, friendly)", hindi: "धन्यवाद ना (अपनापन)", note: "Ends a sentence to make it gentle — like Hindi 'ना' / वाक्य के अंत में, हिंदी 'ना' जैसा"),
        ],
        248: [
            WordForm(thai: "ไม่เอา", romanization: "mâi ao", english: "I don't want it", hindi: "नहीं चाहिए", note: "common refusal in shops / दुकान में मना करने का आम तरीका"),
            WordForm(thai: "เอากลับบ้าน", romanization: "ao klàp bâan", english: "take home / takeaway", hindi: "पैक करके ले जाना", note: "used when ordering food / खाना ऑर्डर करते समय"),
        ],
        249: [
            WordForm(thai: "ดื่มน้ำ", romanization: "dùem náam", english: "drink water", hindi: "पानी पीना", note: "colloquially กินน้ำ (kin náam) is also common / बोलचाल में 'किन नाम' भी चलता है"),
        ],
        250: [
            WordForm(thai: "ใช้ได้", romanization: "chái dâai", english: "usable / it works", hindi: "चल जाएगा / ठीक है", note: "very common daily phrase / रोज़ बोली जाने वाली अभिव्यक्ति"),
        ],
        251: [
            WordForm(thai: "หาไม่เจอ", romanization: "hǎa mâi jer", english: "can't find it", hindi: "मिल नहीं रहा", note: "hǎa = search, jer = find / ढूँढना बनाम मिलना"),
        ],
        253: [
            WordForm(thai: "บอกว่า", romanization: "bòok wâa", english: "say that ...", hindi: "कहना कि ...", note: "wâa works like 'that' / 'कि' की तरह जोड़ता है"),
        ],
        257: [
            WordForm(thai: "เรียนภาษาไทย", romanization: "rian phaa-sǎa thai", english: "study Thai", hindi: "थाई सीखना", note: "rian + subject name / रियन + विषय का नाम"),
        ],
        260: [
            WordForm(thai: "จำได้", romanization: "jam dâai", english: "can remember", hindi: "याद है", note: "usually said with dâai / आमतौर पर 'दाइ' के साथ बोला जाता है"),
            WordForm(thai: "จำไม่ได้", romanization: "jam mâi dâai", english: "can't remember", hindi: "याद नहीं", note: "negative form / नकारात्मक रूप"),
        ],
        261: [
            WordForm(thai: "อย่าลืม", romanization: "yàa luem", english: "don't forget", hindi: "मत भूलिए", note: "yàa + verb = don't (do it) / या + क्रिया = मत करो"),
        ],
        262: [
            WordForm(thai: "เริ่มแล้ว", romanization: "rêrm láew", english: "it has started", hindi: "शुरू हो गया", note: "láew marks completion / 'लैव' पूर्ण होना दिखाता है"),
        ],
        263: [
            WordForm(thai: "เสร็จแล้ว", romanization: "sèt láew", english: "done / finished", hindi: "हो गया", note: "very common daily phrase / रोज़ बोला जाने वाला वाक्यांश"),
            WordForm(thai: "ยังไม่เสร็จ", romanization: "yang mâi sèt", english: "not done yet", hindi: "अभी नहीं हुआ", note: "yang = yet / यंग = अभी तक"),
        ],
        265: [
            WordForm(thai: "รับอะไรดี", romanization: "ráp à-rai dii", english: "what would you like?", hindi: "आप क्या लेंगे?", note: "waiters and shopkeepers say this / वेटर और दुकानदार यही पूछते हैं"),
        ],
        268: [
            WordForm(thai: "ไม่ใส่ผัก", romanization: "mâi sài phàk", english: "without vegetables", hindi: "सब्ज़ी मत डालिए", note: "useful when ordering food / खाना ऑर्डर करते समय काम आता है"),
        ],
        270: [
            WordForm(thai: "มาก ๆ", romanization: "mâak mâak", english: "very very much", hindi: "बहुत ही ज़्यादा", note: "Doubling adds emphasis / दोहराने से ज़ोर बढ़ता है"),
            WordForm(thai: "ไม่มาก", romanization: "mâi mâak", english: "not much", hindi: "ज़्यादा नहीं", note: "มาก comes after the adjective: ร้อนมาก = very hot / มาก विशेषण के बाद आता है"),
        ],
        271: [
            WordForm(thai: "นิดหน่อย", romanization: "nít nòi", english: "a little bit", hindi: "थोड़ा सा", note: "Very common in daily speech / रोज़मर्रा की बोलचाल में बहुत आम"),
        ],
        272: [
            WordForm(thai: "แย่แล้ว", romanization: "yâe láew", english: "oh no! (something went wrong)", hindi: "अरे नहीं! / गड़बड़ हो गई", note: "Common exclamation / आम बोलचाल का उद्गार"),
        ],
        277: [
            WordForm(thai: "ว่างไหม", romanization: "wâang mǎi", english: "are you free?", hindi: "खाली हो क्या?", note: "Common way to invite someone / किसी को बुलाने का आम तरीका"),
        ],
        285: [
            WordForm(thai: "เบา ๆ", romanization: "bao bao", english: "softly / gently", hindi: "धीरे से", note: "Doubled form works as adverb / दोहराने पर क्रिया-विशेषण बनता है"),
        ],
        286: [
            WordForm(thai: "คนดัง", romanization: "khon dang", english: "famous person / celebrity", hindi: "मशहूर व्यक्ति", note: "ดัง also means famous / ดัง का मतलब मशहूर भी होता है"),
        ],
        287: [
            WordForm(thai: "เงียบ ๆ", romanization: "ngîap ngîap", english: "quietly", hindi: "चुपचाप", note: "นั่งเงียบ ๆ = sit quietly / चुपचाप बैठना"),
        ],
        290: [
            WordForm(thai: "สบาย ๆ", romanization: "sà-baai sà-baai", english: "relaxed / easygoing", hindi: "आराम से / बेफ़िक्र", note: "Very common phrase for the Thai lifestyle / थाई जीवनशैली के लिए बहुत आम वाक्यांश"),
        ],
        292: [
            WordForm(thai: "พูดถูก", romanization: "phûut thùuk", english: "said it right", hindi: "सही कहा", note: "In speech ถูก alone often means correct / बोलचाल में अकेला ถูก भी 'सही' होता है"),
        ],
        293: [
            WordForm(thai: "ขอโทษ ผมผิด", romanization: "khǒo-thôot phǒm phìt", english: "sorry, my mistake", hindi: "माफ़ कीजिए, मेरी गलती", note: "Polite way to admit a mistake / गलती मानने का विनम्र तरीका"),
        ],
        294: [
            WordForm(thai: "ตัวสูง", romanization: "tua sǔung", english: "tall (of a person)", hindi: "लंबे कद का", note: "สูง for height, ยาว for length / ऊँचाई के लिए สูง, लंबाई के लिए ยาว"),
        ],
        295: [
            WordForm(thai: "ทุกวันจันทร์", romanization: "thúk wan-jan", english: "every Monday", hindi: "हर सोमवार", note: "ทุก (thúk) + day = every... / हर + दिन"),
        ],
        298: [
            WordForm(thai: "วันพฤหัส", romanization: "wan-phá-rúe-hàt", english: "Thursday (short spoken form)", hindi: "गुरुवार (बोलचाल का छोटा रूप)", note: "Everyday spoken form / रोज़मर्रा में यही बोला जाता है"),
        ],
        302: [
            WordForm(thai: "ตอนเช้า", romanization: "toon-cháao", english: "in the morning", hindi: "सुबह के समय", note: "ตอน + time of day = in the... / ตอน + दिन का समय"),
            WordForm(thai: "ตอนเย็น", romanization: "toon-yen", english: "in the evening", hindi: "शाम के समय", note: "Same pattern with evening / शाम के साथ वही पैटर्न"),
        ],
        303: [
            WordForm(thai: "บ่อย ๆ", romanization: "bòi-bòi", english: "very often / frequently", hindi: "बहुत अक्सर", note: "Doubling makes it stronger / दोहराने से ज़ोर बढ़ता है"),
        ],
        306: [
            WordForm(thai: "เคยไปไหม", romanization: "kheuy pai mái", english: "Have you ever gone?", hindi: "क्या आप कभी गए हैं?", note: "เคย alone = have ever (experience) / เคย अकेले = कभी अनुभव किया है"),
        ],
        308: [
            WordForm(thai: "ก่อนนอน", romanization: "kòon noon", english: "before bed", hindi: "सोने से पहले", note: "ก่อน + verb = before doing... / ก่อน + क्रिया = करने से पहले"),
        ],
        309: [
            WordForm(thai: "หลังอาหาร", romanization: "lǎng aa-hǎan", english: "after meals", hindi: "खाने के बाद", note: "Common on medicine labels / दवा की पर्ची पर आम"),
        ],
        310: [
            WordForm(thai: "ตื่นสาย", romanization: "tùen sǎai", english: "to wake up late", hindi: "देर से उठना", note: "Verb + สาย = do late / क्रिया + สาย = देर से करना"),
        ],
        311: [
            WordForm(thai: "เที่ยงคืน", romanization: "thîang-kheun", english: "midnight", hindi: "आधी रात", note: "เที่ยง + คืน night = midnight / เที่ยง + रात = आधी रात"),
        ],
        313: [
            WordForm(thai: "เดือนหน้า", romanization: "duean nâa", english: "next month", hindi: "अगले महीने", note: "Same pattern / वही पैटर्न"),
            WordForm(thai: "ปีหน้า", romanization: "pii nâa", english: "next year", hindi: "अगले साल", note: "Same pattern / वही पैटर्न"),
        ],
        314: [
            WordForm(thai: "เดือนที่แล้ว", romanization: "duean thîi-láew", english: "last month", hindi: "पिछले महीने", note: "Same pattern / वही पैटर्न"),
            WordForm(thai: "ปีที่แล้ว", romanization: "pii thîi-láew", english: "last year", hindi: "पिछले साल", note: "Same pattern / वही पैटर्न"),
        ],
        315: [
            WordForm(thai: "บ่ายโมง", romanization: "bàai moong", english: "1 pm", hindi: "दोपहर 1 बजे", note: "Afternoon hours count from บ่าย / दोपहर के घंटे บ่าย से गिने जाते हैं"),
            WordForm(thai: "บ่ายสาม", romanization: "bàai sǎam", english: "3 pm", hindi: "दोपहर 3 बजे", note: "บ่าย + number = pm hour / บ่าย + संख्या = दोपहर का समय"),
        ],
        316: [
            WordForm(thai: "ทุกเช้า", romanization: "thúk cháao", english: "every morning", hindi: "हर सुबह", note: "ทุก + time word = every... / ทุก + समय = हर..."),
            WordForm(thai: "ทุกคืน", romanization: "thúk kheun", english: "every night", hindi: "हर रात", note: "Same pattern / वही पैटर्न"),
        ],
        319: [
            WordForm(thai: "นาน ๆ ที", romanization: "naan-naan thii", english: "once in a long while", hindi: "कभी-कभार", note: "Doubled นาน = rarely, occasionally / दोहराया นาน = बहुत कम बार"),
        ],
        320: [
            WordForm(thai: "กี่ครั้ง", romanization: "kìi khráng", english: "how many times", hindi: "कितनी बार", note: "กี่ always needs a classifier after it / กี่ के बाद हमेशा गिनती-शब्द आता है"),
            WordForm(thai: "กี่ปี", romanization: "kìi pii", english: "how many years", hindi: "कितने साल", note: "used for age and duration / उम्र और अवधि के लिए"),
        ],
        321: [
            WordForm(thai: "ตัวนี้", romanization: "tua níi", english: "this one (animal/clothing)", hindi: "यह वाला (जानवर/कपड़ा)", note: "classifier + นี้ = this one / गिनती-शब्द + นี้ = यह वाला"),
        ],
        322: [
            WordForm(thai: "คนไทย", romanization: "khon thai", english: "Thai person", hindi: "थाई व्यक्ति", note: "คน + country = nationality / คน + देश = राष्ट्रीयता"),
        ],
        323: [
            WordForm(thai: "อันไหน", romanization: "an nǎi", english: "which one?", hindi: "कौन-सा?", note: "classifier + ไหน = which / गिनती-शब्द + ไหน = कौन-सा"),
        ],
        332: [
            WordForm(thai: "อีกครั้ง", romanization: "ìik khráng", english: "again / one more time", hindi: "फिर से / एक बार और", note: "very common request / बहुत आम अनुरोध"),
            WordForm(thai: "ครั้งแรก", romanization: "khráng râek", english: "the first time", hindi: "पहली बार", note: "ครั้ง + แรก (first) / ครั้ง + แรก (पहला)"),
        ],
        338: [
            WordForm(thai: "ครึ่งชั่วโมง", romanization: "khrûeng chûa-moong", english: "half an hour", hindi: "आधा घंटा", note: "ครึ่ง before = half of / पहले ครึ่ง = आधा"),
            WordForm(thai: "ชั่วโมงครึ่ง", romanization: "chûa-moong khrûeng", english: "an hour and a half", hindi: "डेढ़ घंटा", note: "ครึ่ง after = ...and a half; order changes meaning / क्रम से अर्थ बदलता है"),
        ],
        340: [
            WordForm(thai: "เยอะมาก", romanization: "yóe mâak", english: "a whole lot / so much", hindi: "बहुत ज़्यादा", note: "เยอะ + มาก for emphasis / ज़ोर देने के लिए"),
        ],
        342: [
            WordForm(thai: "วันละ", romanization: "wan lá", english: "per day", hindi: "प्रतिदिन", note: "time word + ละ = per / समय-शब्द + ละ = प्रति"),
            WordForm(thai: "คนละ", romanization: "khon lá", english: "each person / per person", hindi: "हर व्यक्ति", note: "used when splitting bills / बिल बाँटते समय आम"),
        ],
        344: [
            WordForm(thai: "ยี่สิบเอ็ด", romanization: "yîi-sìp-èt", english: "twenty-one", hindi: "इक्कीस", note: "21 uses เอ็ด, not หนึ่ง / 21 में เอ็ด आता है, หนึ่ง नहीं"),
            WordForm(thai: "สามสิบ", romanization: "sǎam-sìp", english: "thirty", hindi: "तीस", note: "30 onwards: number + สิบ / 30 से आगे: संख्या + สิบ"),
        ],
        345: [
            WordForm(thai: "ในห้อง", romanization: "nai hôong", english: "in the room", hindi: "कमरे में", note: "ใน (nai) = in / में"),
        ],
        346: [
            WordForm(thai: "เปิดประตู", romanization: "pèrt prà-tuu", english: "to open the door", hindi: "दरवाज़ा खोलना", note: "verb + noun pattern / क्रिया + संज्ञा"),
            WordForm(thai: "ปิดประตู", romanization: "pìt prà-tuu", english: "to close the door", hindi: "दरवाज़ा बंद करना", note: ""),
        ],
        348: [
            WordForm(thai: "บนเตียง", romanization: "bon tiang", english: "on the bed", hindi: "बिस्तर पर", note: "บน (bon) = on / पर"),
        ],
        349: [
            WordForm(thai: "บนโต๊ะ", romanization: "bon tó", english: "on the table", hindi: "मेज़ पर", note: ""),
        ],
        351: [
            WordForm(thai: "เล่นมือถือ", romanization: "lên meuu-thěuu", english: "to use one's phone", hindi: "मोबाइल चलाना", note: "เล่น (lên) lit. play — everyday phrase / आम बोलचाल"),
        ],
        353: [
            WordForm(thai: "ซักเสื้อผ้า", romanization: "sák sûea-phâa", english: "to wash clothes", hindi: "कपड़े धोना", note: "ซัก (sák) = to wash clothes / धोना"),
        ],
        357: [
            WordForm(thai: "ค่าไฟ", romanization: "khâa fai", english: "electricity bill", hindi: "बिजली का बिल", note: "ค่า (khâa) = fee / शुल्क; ไฟฟ้า is often shortened to ไฟ"),
        ],
        361: [
            WordForm(thai: "ดูทีวี", romanization: "duu thii-wii", english: "to watch TV", hindi: "टीवी देखना", note: ""),
        ],
        365: [
            WordForm(thai: "แปรงฟัน", romanization: "praeng fan", english: "to brush one's teeth", hindi: "दाँत साफ़ करना", note: "แปรง as a verb = to brush / ब्रश करना"),
        ],
        368: [
            WordForm(thai: "ห่มผ้า", romanization: "hòm phâa", english: "to cover oneself with a blanket", hindi: "कंबल ओढ़ना", note: "word order flips for the verb / क्रिया के लिए क्रम उलट जाता है"),
        ],
        370: [
            WordForm(thai: "ภาษาจีน", romanization: "phaa-sǎa-jiin", english: "Chinese language", hindi: "चीनी भाषा", note: "ภาษา + country = that country's language / भाषा + देश = उस देश की भाषा"),
        ],
        373: [
            WordForm(thai: "แปลว่า...", romanization: "plae wâa...", english: "it means...", hindi: "...मतलब है", note: "used to give the meaning of a word / किसी शब्द का अर्थ बताने के लिए"),
        ],
        375: [
            WordForm(thai: "โทรหา + คน", romanization: "thoo hǎa + person", english: "to call someone", hindi: "किसी को फ़ोन करना", note: "โทรหาแม่ (thoo hǎa mâe) = call mom / माँ को फ़ोन करना"),
        ],
        385: [
            WordForm(thai: "มีประชุม", romanization: "mii prà-chum", english: "to have a meeting", hindi: "मीटिंग होना", note: "มี (have) + ประชุม = there is a meeting / मीटिंग है"),
        ],
        387: [
            WordForm(thai: "คุยกับ + คน", romanization: "khui kàp + person", english: "to chat with someone", hindi: "किसी से बात करना", note: "คุยกับเพื่อน (khui kàp phêuan) = chat with a friend / दोस्त से बात करना"),
        ],
        388: [
            WordForm(thai: "คำใหม่ 5 คำ", romanization: "kham mài hâa kham", english: "five new words", hindi: "पाँच नए शब्द", note: "คำ is also the classifier for words / คำ शब्दों का क्लासिफ़ायर भी है"),
        ],
        389: [
            WordForm(thai: "ปวดขา", romanization: "pùat khǎa", english: "leg pain", hindi: "टांग में दर्द", note: "ปวด + body part = ache there / ปวด + अंग = वहां दर्द"),
        ],
        390: [
            WordForm(thai: "เสื้อแขนสั้น", romanization: "sûea khǎen sân", english: "short-sleeved shirt", hindi: "आधी बाजू की कमीज़", note: "แขน also means sleeve / 'आस्तीन' भी"),
        ],
        391: [
            WordForm(thai: "ปวดท้อง", romanization: "pùat thóong", english: "stomachache", hindi: "पेट दर्द", note: "very common at clinics / क्लिनिक में बहुत आम"),
            WordForm(thai: "ท้องเสีย", romanization: "thóong sǐa", english: "diarrhea", hindi: "दस्त", note: "lit. broken stomach / शाब्दिक: खराब पेट"),
        ],
        392: [
            WordForm(thai: "อ้าปาก", romanization: "âa pàak", english: "to open the mouth", hindi: "मुंह खोलना", note: "doctor's instruction / डॉक्टर का निर्देश"),
        ],
        394: [
            WordForm(thai: "หูฟัง", romanization: "hǔu-fang", english: "earphones", hindi: "ईयरफोन", note: "หู + ฟัง (listen / सुनना)"),
        ],
        395: [
            WordForm(thai: "ผิวแห้ง", romanization: "phǐw hâeng", english: "dry skin", hindi: "रूखी त्वचा", note: ""),
        ],
        396: [
            WordForm(thai: "รองเท้า", romanization: "roong-tháo", english: "shoes", hindi: "जूते", note: "รอง support / सहारा + เท้า foot"),
        ],
        397: [
            WordForm(thai: "นิ้วเท้า", romanization: "níw tháo", english: "toe", hindi: "पैर की उंगली", note: ""),
        ],
        398: [
            WordForm(thai: "เจ็บคอ", romanization: "jèp khoo", english: "sore throat", hindi: "गले में दर्द", note: ""),
        ],
        399: [
            WordForm(thai: "ข้างหน้า", romanization: "khâang nâa", english: "in front / ahead", hindi: "आगे", note: "หน้า also = front / 'सामने' भी"),
        ],
        400: [
            WordForm(thai: "เจ็บคอ", romanization: "jèp khoo", english: "sore throat", hindi: "गले में दर्द", note: "เจ็บ + body part / เจ็บ + अंग"),
        ],
        401: [
            WordForm(thai: "เป็นไข้", romanization: "pen khâi", english: "to have a fever", hindi: "बुखार होना", note: "เป็น + illness = to have it / เป็น + बीमारी"),
        ],
        402: [
            WordForm(thai: "ยาแก้ไอ", romanization: "yaa kâe ai", english: "cough medicine", hindi: "खांसी की दवा", note: ""),
        ],
        403: [
            WordForm(thai: "เป็นหวัด", romanization: "pen wàt", english: "to have a cold", hindi: "ज़ुकाम होना", note: ""),
        ],
        404: [
            WordForm(thai: "ยาแก้ปวดหัว", romanization: "yaa kâe pùat hǔa", english: "headache medicine", hindi: "सिरदर्द की दवा", note: "หัว (hǔa) = head / सिर"),
        ],
        405: [
            WordForm(thai: "แพ้อาหาร", romanization: "pháe aa-hǎan", english: "food allergy", hindi: "खाने से एलर्जी", note: "แพ้ + thing = allergic to it / แพ้ + चीज़"),
        ],
        406: [
            WordForm(thai: "เลือดออก", romanization: "lûeat òok", english: "to bleed", hindi: "खून निकलना", note: ""),
        ],
        411: [
            WordForm(thai: "ประกันสุขภาพ", romanization: "prà-kan sùk-khà-phâap", english: "health insurance", hindi: "स्वास्थ्य बीमा", note: ""),
        ],
        187: [
            WordForm(thai: "ดีใจมาก", romanization: "dii-jai mâak", english: "very happy", hindi: "बहुत खुश", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ดีใจที่ได้เจอ", romanization: "dii-jai tîi dâai jer", english: "glad to meet (you)", hindi: "मिलकर खुशी हुई", note: "ดีใจที่... = happy that... / ...की खुशी"),
        ],
        188: [
            WordForm(thai: "อย่าเสียใจ", romanization: "yàa sǐa-jai", english: "don't be sad", hindi: "दुखी मत हो", note: "อย่า (yàa) = don't / मत"),
            WordForm(thai: "เสียใจด้วย", romanization: "sǐa-jai dûai", english: "I'm sorry for you", hindi: "मुझे अफ़सोस है", note: "used to console someone / सांत्वना देने के लिए"),
        ],
        189: [
            WordForm(thai: "ไม่โกรธ", romanization: "mâi kròot", english: "not angry", hindi: "नाराज़ नहीं", note: "ไม่ (mâi) negates / नहीं से इनकार"),
            WordForm(thai: "อย่าโกรธนะ", romanization: "yàa kròot ná", english: "please don't be angry", hindi: "नाराज़ मत होना", note: "นะ (ná) softens the sentence / वाक्य को नरम बनाता है"),
        ],
        190: [
            WordForm(thai: "เบื่อแล้ว", romanization: "bùea láew", english: "bored now / already bored", hindi: "अब ऊब गया", note: "แล้ว (láew) = already / अब हो चुका"),
        ],
        191: [
            WordForm(thai: "ตื่นเต้นมาก", romanization: "tùun-tên mâak", english: "very excited", hindi: "बहुत उत्साहित", note: "มาก (mâak) = very / बहुत"),
        ],
        192: [
            WordForm(thai: "คิดถึงมาก", romanization: "kít-tǔng mâak", english: "miss (you) a lot", hindi: "बहुत याद आती है", note: "มาก (mâak) = very much / बहुत"),
            WordForm(thai: "คิดถึงบ้าน", romanization: "kít-tǔng bâan", english: "homesick", hindi: "घर की याद", note: "บ้าน (bâan) = home / घर"),
        ],
        193: [
            WordForm(thai: "เจอกัน", romanization: "jer kan", english: "see you / meet each other", hindi: "मिलते हैं", note: "กัน (gan) = each other / एक-दूसरे से"),
            WordForm(thai: "เจอกันใหม่", romanization: "jer kan mài", english: "see you again", hindi: "फिर मिलेंगे", note: "ใหม่ (mài) = again-new / फिर से"),
        ],
        194: [
            WordForm(thai: "สักครู่", romanization: "sàk-krûu", english: "just a moment", hindi: "एक क्षण", note: "can be used alone / अकेले भी बोल सकते हैं"),
        ],
        195: [
            WordForm(thai: "อาจจะไม่", romanization: "àat-jà mâi", english: "maybe not", hindi: "शायद नहीं", note: "ไม่ (mâi) after it = maybe not / शायद नहीं"),
        ],
        196: [
            WordForm(thai: "แน่นอนครับ/ค่ะ", romanization: "nâe-non kráp/kâ", english: "of course! (polite)", hindi: "बिलकुल! (विनम्र)", note: "polite yes-answer / विनम्र जवाब"),
        ],
        197: [
            WordForm(thai: "ไปด้วยกันไหม", romanization: "pai dûai-kan mǎi?", english: "shall we go together?", hindi: "क्या साथ चलें?", note: "ไหม (mǎi) makes it a question / सवाल बनाता है"),
        ],
        198: [
            WordForm(thai: "มาคนเดียว", romanization: "maa kon-diao", english: "come alone", hindi: "अकेले आना", note: "placed after the verb / क्रिया के बाद आता है"),
        ],
        199: [
            WordForm(thai: "กระเป๋าใบนี้", romanization: "krà-pǎo bai níi", english: "this bag", hindi: "यह बैग", note: "ใบ is the classifier for bags / ใบ बैग का classifier है"),
        ],
        200: [
            WordForm(thai: "เสื้อตัวนี้", romanization: "sûea tua níi", english: "this shirt", hindi: "यह शर्ट", note: "ตัว is the classifier for shirts / ตัว शर्ट का classifier है"),
        ],
        201: [
            WordForm(thai: "รองเท้าคู่นี้", romanization: "rawng-táao khûu níi", english: "this pair of shoes", hindi: "जूतों की यह जोड़ी", note: "คู่ = pair, the classifier for shoes / คู่ = जोड़ी, जूतों का classifier"),
        ],
        202: [
            WordForm(thai: "สายชาร์จ", romanization: "sǎai-châat", english: "charging cable", hindi: "चार्जिंग केबल", note: "สาย = cord, line / สาย = तार"),
        ],
        203: [
            WordForm(thai: "ต่อราคาได้ไหม", romanization: "tàw raa-khaa dâi mǎi", english: "can I bargain?", hindi: "क्या मोल-भाव कर सकते हैं?", note: "Polite way to start bargaining / मोल-भाव शुरू करने का विनम्र तरीका"),
        ],
        204: [
            WordForm(thai: "ลดได้ไหม", romanization: "lót dâi mǎi", english: "can you reduce it?", hindi: "कम कर सकते हैं?", note: "Shorter version of the phrase / वाक्यांश का छोटा रूप"),
        ],
        205: [
            WordForm(thai: "ไซส์อะไร", romanization: "sái à-rai", english: "what size?", hindi: "कौन सा साइज़?", note: "Shop staff often ask this / दुकानदार अक्सर यह पूछते हैं"),
            WordForm(thai: "เล็กไป", romanization: "lék pai", english: "too small", hindi: "बहुत छोटा (ज़रूरत से ज़्यादा)", note: "adjective + ไป = too ... / adjective + ไป = ज़रूरत से ज़्यादा"),
        ],
        206: [
            WordForm(thai: "ไม่พอดี", romanization: "mâi phaw-dii", english: "doesn't fit", hindi: "फिट नहीं है", note: "ไม่ negates it / ไม่ नकारात्मक बनाता है"),
            WordForm(thai: "พอดีเลย", romanization: "phaw-dii loei", english: "fits perfectly", hindi: "एकदम फिट", note: "เลย adds emphasis / เลย ज़ोर देता है"),
        ],
        207: [
            WordForm(thai: "ลองดู", romanization: "lawng duu", english: "give it a try", hindi: "करके देखो", note: "Very common everyday phrase / रोज़मर्रा का बहुत आम वाक्यांश"),
        ],
        209: [
            WordForm(thai: "ไม่เอาถุง", romanization: "mâi ao tǔng", english: "no bag, please", hindi: "थैली नहीं चाहिए", note: "Handy eco-friendly phrase / पर्यावरण के लिए उपयोगी वाक्यांश"),
        ],
        210: [
            WordForm(thai: "กี่โมงแล้ว", romanization: "kìi mohng láew", english: "what time is it now?", hindi: "अभी कितने बजे हैं?", note: "แล้ว = already, now / แล้ว = अब"),
        ],
        211: [
            WordForm(thai: "ที่ชายหาด", romanization: "thîi chaai-hàat", english: "at the beach", hindi: "बीच पर", note: "ที่ (thîi) + place = at / ที่ + जगह = पर"),
        ],
        213: [
            WordForm(thai: "ตั๋วหนึ่งใบ", romanization: "tǔa nʉ̀ng bai", english: "one ticket", hindi: "एक टिकट", note: "ใบ (bai) is the classifier for tickets / ใบ (bai) टिकट गिनने का शब्द है"),
        ],
        214: [
            WordForm(thai: "นั่งเรือ", romanization: "nâng rʉa", english: "to ride a boat", hindi: "नाव की सवारी करना", note: "นั่ง (sit) + vehicle = to ride it / นั่ง (बैठना) + वाहन = उसकी सवारी करना"),
        ],
        217: [
            WordForm(thai: "ส้มตำไม่เผ็ด", romanization: "sôm-tam mâi phèt", english: "som tam, not spicy", hindi: "सोम-तम, तीखा नहीं", note: "Handy when ordering it mild / कम तीखा मँगवाने के लिए कहें"),
        ],
        219: [
            WordForm(thai: "น้ำหนึ่งขวด", romanization: "náam nʉ̀ng khùat", english: "one bottle of water", hindi: "एक बोतल पानी", note: "ขวด (khùat) also works as the classifier for bottles / ขวด बोतलें गिनने का classifier भी है"),
        ],
        1: [
            WordForm(thai: "สวัสดีครับ", romanization: "sà-wàt-dii kráp", english: "hello (male speaker, polite)", hindi: "नमस्ते (पुरुष, विनम्र)", note: "ครับ (kráp) = polite ending for men / पुरुषों के लिए विनम्र शब्द"),
            WordForm(thai: "สวัสดีค่ะ", romanization: "sà-wàt-dii khâ", english: "hello (female speaker, polite)", hindi: "नमस्ते (स्त्री, विनम्र)", note: "ค่ะ (khâ) = polite ending for women / स्त्रियों के लिए विनम्र शब्द"),
        ],
        2: [
            WordForm(thai: "ขอบคุณมาก", romanization: "khòp-khun mâak", english: "thank you very much", hindi: "बहुत-बहुत धन्यवाद", note: "มาก (mâak) = very much / बहुत"),
            WordForm(thai: "ขอบคุณครับ", romanization: "khòp-khun kráp", english: "thank you (male speaker, polite)", hindi: "धन्यवाद (पुरुष, विनम्र)", note: "ครับ (kráp) = polite particle for men / पुरुषों का विनम्र शब्द"),
            WordForm(thai: "ขอบคุณค่ะ", romanization: "khòp-khun khâ", english: "thank you (female speaker, polite)", hindi: "धन्यवाद (स्त्री, विनम्र)", note: "ค่ะ (khâ) = polite particle for women / स्त्रियों का विनम्र शब्द"),
        ],
        5: [
            WordForm(thai: "ไม่ใช่", romanization: "mâi-châi", english: "no / not so", hindi: "नहीं / ऐसा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ใช่ไหม", romanization: "châi-mǎi", english: "right? / isn't it?", hindi: "है ना?", note: "ไหม (mǎi) = question particle / प्रश्न कण"),
        ],
        6: [
            WordForm(thai: "ไม่ใช่", romanization: "mâi-châi", english: "no / that's not it", hindi: "नहीं, ऐसा नहीं है", note: "ใช่ (châi) = yes / हाँ; ไม่ + ใช่ = not so / ऐसा नहीं"),
            WordForm(thai: "ไม่เป็นไร", romanization: "mâi-pen-rai", english: "it's okay / no problem", hindi: "कोई बात नहीं", note: "เป็นไร (pen-rai) = be anything; ไม่เป็นไร = no problem / कोई बात नहीं"),
        ],
        7: [
            WordForm(thai: "ไม่เป็นไรครับ", romanization: "mâi-pen-rai kráp", english: "no problem (male speaker, polite)", hindi: "कोई बात नहीं (पुरुष, विनम्र)", note: "ครับ (kráp) = polite ending for men / पुरुषों के लिए विनम्र शब्द"),
            WordForm(thai: "ไม่เป็นไรค่ะ", romanization: "mâi-pen-rai khâ", english: "no problem (female speaker, polite)", hindi: "कोई बात नहीं (स्त्री, विनम्र)", note: "ค่ะ (khâ) = polite ending for women / स्त्रियों के लिए विनम्र शब्द"),
        ],
        8: [
            WordForm(thai: "ขอโทษครับ", romanization: "khǒo-thôot kráp", english: "sorry (male speaker, polite)", hindi: "माफ़ कीजिए (पुरुष, विनम्र)", note: "ครับ (kráp) = polite particle for men / पुरुषों का विनम्र शब्द"),
            WordForm(thai: "ขอโทษนะ", romanization: "khǒo-thôot ná", english: "sorry (soft, friendly)", hindi: "माफ़ करना (नरम लहजा)", note: "นะ (ná) = softening particle / लहजा नरम करने वाला शब्द"),
            WordForm(thai: "ขอโทษจริงๆ", romanization: "khǒo-thôot jing-jing", english: "I'm really sorry", hindi: "सच में माफ़ी चाहता/चाहती हूँ", note: "จริงๆ (jing-jing) = really / सच में"),
        ],
        9: [
            WordForm(thai: "สบายดี", romanization: "sà-baai-dii", english: "I'm fine", hindi: "मैं ठीक हूँ", note: "drop ไหม (mǎi) to turn the question into the answer / ไหม (mǎi) हटाने से सवाल जवाब बन जाता है"),
            WordForm(thai: "ไม่ค่อยสบาย", romanization: "mâi khôi sà-baai", english: "not so well / a bit unwell", hindi: "ज़्यादा ठीक नहीं हूँ", note: "ไม่ค่อย (mâi khôi) = not very / ज़्यादा नहीं"),
        ],
        10: [
            WordForm(thai: "สบายดีไหม", romanization: "sà-baai-dii mǎi", english: "How are you? / Are you well?", hindi: "आप कैसे हैं?", note: "ไหม (mǎi) = question particle / प्रश्न कण"),
            WordForm(thai: "สบายดีค่ะ", romanization: "sà-baai-dii khâ", english: "I'm fine (polite, female speaker)", hindi: "मैं ठीक हूँ (विनम्र, स्त्री)", note: "ค่ะ (khâ) = polite particle (female) / आदरसूचक शब्द (स्त्री)"),
        ],
        11: [
            WordForm(thai: "ที่หนึ่ง", romanization: "thîi-nèung", english: "first / number one", hindi: "पहला / नंबर एक", note: "ที่ (thîi) = ordinal marker / क्रम-सूचक (पहला बनाता है)"),
            WordForm(thai: "หนึ่งครั้ง", romanization: "nèung-khráng", english: "one time / once", hindi: "एक बार", note: "ครั้ง (khráng) = time, occasion / बार"),
        ],
        12: [
            WordForm(thai: "สองคน", romanization: "sǒong-khon", english: "two people", hindi: "दो लोग", note: "คน (khon) = person (classifier) / व्यक्ति (गिनती शब्द)"),
            WordForm(thai: "สองร้อย", romanization: "sǒong-róoi", english: "two hundred", hindi: "दो सौ", note: "ร้อย (róoi) = hundred / सौ"),
        ],
        13: [
            WordForm(thai: "สามสิบ", romanization: "sǎam-sìp", english: "thirty", hindi: "तीस", note: "สิบ (sìp) = ten; number + สิบ = tens / संख्या + สิบ = दहाई"),
            WordForm(thai: "สามร้อย", romanization: "sǎam-rói", english: "three hundred", hindi: "तीन सौ", note: "ร้อย (rói) = hundred / सौ"),
        ],
        14: [
            WordForm(thai: "สิบสี่", romanization: "sìp-sìi", english: "fourteen", hindi: "चौदह", note: "สิบ (sìp) + สี่ = 10 + 4 / दस + चार"),
            WordForm(thai: "สี่สิบ", romanization: "sìi-sìp", english: "forty", hindi: "चालीस", note: "สี่ + สิบ (sìp) = 4 × 10 / चार × दस"),
        ],
        15: [
            WordForm(thai: "ห้าสิบ", romanization: "hâa-sìp", english: "fifty", hindi: "पचास", note: "สิบ (sìp) = ten; five-ten = 50 / สิบ (sìp) = दस; पाँच-दस = ५०"),
            WordForm(thai: "สิบห้า", romanization: "sìp-hâa", english: "fifteen", hindi: "पंद्रह", note: "สิบ (sìp) = ten; ten-five = 15 / दस-पाँच = १५"),
        ],
        16: [
            WordForm(thai: "หกสิบ", romanization: "hòk-sìp", english: "sixty", hindi: "साठ", note: "สิบ (sìp) = ten / दस"),
            WordForm(thai: "หกโมงเย็น", romanization: "hòk moong yen", english: "six o'clock in the evening (6 pm)", hindi: "शाम के छह बजे", note: "โมงเย็น (moong yen) = o'clock in the evening / शाम के बजे"),
        ],
        17: [
            WordForm(thai: "เจ็ดโมง", romanization: "jèt-moong", english: "seven o'clock (7 a.m.)", hindi: "सुबह सात बजे", note: "โมง (moong) = o'clock / बजे"),
            WordForm(thai: "เจ็ดสิบ", romanization: "jèt-sìp", english: "seventy", hindi: "सत्तर", note: "สิบ (sìp) = ten / दस"),
        ],
        18: [
            WordForm(thai: "แปดสิบ", romanization: "pàet-sìp", english: "eighty", hindi: "अस्सी", note: "สิบ (sìp) = ten / दस"),
            WordForm(thai: "แปดโมงเช้า", romanization: "pàet-moong-cháao", english: "eight in the morning (8 AM)", hindi: "सुबह आठ बजे", note: "โมงเช้า (moong-cháao) = o'clock in the morning / सुबह के बजे"),
        ],
        19: [
            WordForm(thai: "เก้าสิบ", romanization: "kâo-sìp", english: "ninety", hindi: "नब्बे", note: "สิบ (sìp) = ten; number + สิบ = tens / संख्या + สิบ = दहाई"),
            WordForm(thai: "เก้าโมง", romanization: "kâo-moong", english: "nine o'clock (9 AM)", hindi: "नौ बजे (सुबह)", note: "โมง (moong) = o'clock (daytime) / दिन के समय 'बजे'"),
        ],
        20: [
            WordForm(thai: "สิบเอ็ด", romanization: "sìp-èt", english: "eleven", hindi: "ग्यारह", note: "เอ็ด (èt) = one, special form after ten / \"एक\" का विशेष रूप दहाई के बाद"),
            WordForm(thai: "ยี่สิบ", romanization: "yîi-sìp", english: "twenty", hindi: "बीस", note: "ยี่ (yîi) = special form of \"two\" before สิบ / \"दो\" का विशेष रूप"),
        ],
        21: [
            WordForm(thai: "ของผม", romanization: "khǒong phǒm", english: "my / mine (male)", hindi: "मेरा (पुरुष)", note: "ของ (khǒong) = of / belonging to / का"),
        ],
        22: [
            WordForm(thai: "ของฉัน", romanization: "khǒong chǎn", english: "my / mine", hindi: "मेरा / मेरी", note: "ของ (khǒong) = of, possessive marker / का-की (संबंध सूचक)"),
        ],
        23: [
            WordForm(thai: "ของคุณ", romanization: "khǎawng-khun", english: "your / yours", hindi: "आपका", note: "ของ (khǎawng) = of, belonging to / का"),
            WordForm(thai: "คุณล่ะ", romanization: "khun-lâ", english: "and you?", hindi: "और आप?", note: "ล่ะ (lâ) = 'what about…?' particle / 'और…?' कण"),
        ],
        24: [
            WordForm(thai: "เพื่อนสนิท", romanization: "phûean-sà-nìt", english: "close friend", hindi: "घनिष्ठ दोस्त", note: "สนิท (sà-nìt) = close / क़रीबी"),
            WordForm(thai: "เพื่อนร่วมงาน", romanization: "phûean-rûam-ngaan", english: "colleague / co-worker", hindi: "सहकर्मी", note: "ร่วมงาน (rûam-ngaan) = work together / साथ काम करना"),
        ],
        25: [
            WordForm(thai: "ครอบครัวของฉัน", romanization: "khrôp-khrua khǒong chǎn", english: "my family", hindi: "मेरा परिवार", note: "ของ (khǒong) = of / possessive marker / का, की (संबंध सूचक)"),
        ],
        26: [
            WordForm(thai: "อาหารไทย", romanization: "aa-hǎan thai", english: "Thai food", hindi: "थाई खाना", note: "ไทย (thai) = Thai / थाई"),
            WordForm(thai: "อาหารเช้า", romanization: "aa-hǎan cháao", english: "breakfast", hindi: "नाश्ता", note: "เช้า (cháao) = morning / सुबह"),
        ],
        27: [
            WordForm(thai: "น้ำเปล่า", romanization: "náam-plàao", english: "plain water", hindi: "सादा पानी", note: "เปล่า (plàao) = plain / सादा"),
            WordForm(thai: "น้ำแข็ง", romanization: "náam-khǎeng", english: "ice", hindi: "बर्फ़", note: "แข็ง (khǎeng) = hard; 'hard water' = ice / แข็ง (khǎeng) = कठोर"),
        ],
        28: [
            WordForm(thai: "กินข้าว", romanization: "kin khâao", english: "to eat (a meal)", hindi: "खाना खाना", note: "กิน (kin) = to eat / खाना"),
            WordForm(thai: "ข้าวผัด", romanization: "khâao-phàt", english: "fried rice", hindi: "फ्राइड राइस (तला हुआ चावल)", note: "ผัด (phàt) = stir-fried / तला-भुना"),
        ],
        29: [
            WordForm(thai: "กินข้าว", romanization: "kin-khâao", english: "to eat (a meal)", hindi: "खाना खाना", note: "ข้าว (khâao) = rice, meal / चावल, भोजन"),
            WordForm(thai: "กินแล้ว", romanization: "kin-láew", english: "already eaten", hindi: "खा लिया", note: "แล้ว (láew) = already / हो चुका"),
            WordForm(thai: "ไม่กิน", romanization: "mâi-kin", english: "(I) don't eat", hindi: "नहीं खाता/खाती", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "อยากกิน", romanization: "yàak-kin", english: "want to eat", hindi: "खाना चाहता/चाहती हूँ", note: "อยาก (yàak) = want to / चाहना"),
        ],
        30: [
            WordForm(thai: "อร่อยมาก", romanization: "à-ròi-mâak", english: "very delicious", hindi: "बहुत स्वादिष्ट", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่อร่อย", romanization: "mâi-à-ròi", english: "not tasty", hindi: "स्वादिष्ट नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "อร่อยไหม", romanization: "à-ròi-mǎi", english: "Is it tasty?", hindi: "क्या यह स्वादिष्ट है?", note: "ไหม (mǎi) = question particle / प्रश्न शब्द"),
            WordForm(thai: "อร่อยที่สุด", romanization: "à-ròi-thîi-sùt", english: "the most delicious", hindi: "सबसे स्वादिष्ट", note: "ที่สุด (thîi-sùt) = the most / सबसे"),
        ],
        31: [
            WordForm(thai: "กาแฟร้อน", romanization: "kaa-fae rón", english: "hot coffee", hindi: "गरम कॉफ़ी", note: "ร้อน (rón) = hot / गरम"),
            WordForm(thai: "กาแฟเย็น", romanization: "kaa-fae yen", english: "iced coffee (Thai style)", hindi: "ठंडी (आइस्ड) कॉफ़ी", note: "เย็น (yen) = cold, iced / ठंडा"),
        ],
        32: [
            WordForm(thai: "ชาร้อน", romanization: "chaa rón", english: "hot tea", hindi: "गरम चाय", note: "ร้อน (rón) = hot / गरम"),
            WordForm(thai: "ชาเย็น", romanization: "chaa yen", english: "Thai iced tea", hindi: "थाई आइस टी (ठंडी चाय)", note: "เย็น (yen) = cold, iced / ठंडा"),
        ],
        33: [
            WordForm(thai: "เผ็ดมาก", romanization: "phèt mâak", english: "very spicy", hindi: "बहुत तीखा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่เผ็ด", romanization: "mâi phèt", english: "not spicy", hindi: "तीखा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "เผ็ดไหม", romanization: "phèt mǎi?", english: "is it spicy?", hindi: "क्या यह तीखा है?", note: "ไหม (mǎi) = yes/no question particle / हाँ-ना सवाल का शब्द"),
            WordForm(thai: "เผ็ดนิดหน่อย", romanization: "phèt nít-nòi", english: "a little spicy", hindi: "थोड़ा तीखा", note: "นิดหน่อย (nít-nòi) = a little / थोड़ा"),
        ],
        34: [
            WordForm(thai: "หิวมาก", romanization: "hǐu mâak", english: "very hungry", hindi: "बहुत भूख लगी है", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่หิว", romanization: "mâi hǐu", english: "not hungry", hindi: "भूख नहीं है", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "หิวข้าว", romanization: "hǐu khâao", english: "hungry (for food)", hindi: "खाने की भूख लगी है", note: "ข้าว (khâao) = rice, food / चावल (खाना)"),
            WordForm(thai: "หิวไหม", romanization: "hǐu mǎi", english: "Are you hungry?", hindi: "क्या भूख लगी है?", note: "ไหม (mǎi) = question particle / प्रश्न कण"),
        ],
        35: [
            WordForm(thai: "จะไป", romanization: "jà-pai", english: "will go", hindi: "जाऊँगा / जाएगा", note: "จะ (jà) = will / -गा (भविष्य)"),
            WordForm(thai: "ไปแล้ว", romanization: "pai-láew", english: "already left / gone", hindi: "चला गया", note: "แล้ว (láew) = already / हो चुका"),
            WordForm(thai: "ไม่ไป", romanization: "mâi-pai", english: "not going", hindi: "नहीं जाऊँगा", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ไปไหน", romanization: "pai-nǎi", english: "where are you going?", hindi: "कहाँ जा रहे हो?", note: "ไหน (nǎi) = where / कहाँ"),
        ],
        36: [
            WordForm(thai: "มาแล้ว", romanization: "maa-láeo", english: "(has) already come / here now", hindi: "आ गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "ไม่มา", romanization: "mâi-maa", english: "doesn't come / didn't come", hindi: "नहीं आता", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "มาจากไหน", romanization: "maa-jàak-nǎi", english: "Where do you come from?", hindi: "कहाँ से आए हो?", note: "จากไหน (jàak-nǎi) = from where / कहाँ से"),
        ],
        37: [
            WordForm(thai: "ความรัก", romanization: "khwaam-rák", english: "love (noun)", hindi: "प्रेम / मोहब्बत", note: "ความ (khwaam) = noun-maker prefix / क्रिया को संज्ञा बनाने वाला उपसर्ग"),
            WordForm(thai: "น่ารัก", romanization: "nâa-rák", english: "cute / lovable", hindi: "प्यारा", note: "น่า (nâa) = worthy of, -able / '-ने योग्य' बनाने वाला उपसर्ग"),
            WordForm(thai: "รักมาก", romanization: "rák mâak", english: "to love very much", hindi: "बहुत प्यार करना", note: "มาก (mâak) = very / बहुत"),
        ],
        38: [
            WordForm(thai: "ชอบมาก", romanization: "chôp mâak", english: "(I) like it a lot", hindi: "बहुत पसंद है", note: "มาก (mâak) = very much / बहुत"),
            WordForm(thai: "ไม่ชอบ", romanization: "mâi chôp", english: "(I) don't like it", hindi: "पसंद नहीं है", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ชอบไหม", romanization: "chôp mǎi", english: "do you like it?", hindi: "क्या पसंद है?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        39: [
            WordForm(thai: "ดีมาก", romanization: "dii mâak", english: "very good", hindi: "बहुत अच्छा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ดี", romanization: "mâi dii", english: "not good / bad", hindi: "अच्छा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ดีที่สุด", romanization: "dii thîi-sùt", english: "the best", hindi: "सबसे अच्छा", note: "ที่สุด (thîi-sùt) = the most / सबसे"),
            WordForm(thai: "ดีขึ้น", romanization: "dii khûen", english: "better / improving", hindi: "बेहतर हो रहा है", note: "ขึ้น (khûen) = up, increasingly / ऊपर, और अधिक"),
        ],
        41: [
            WordForm(thai: "ใหญ่มาก", romanization: "yài-mâak", english: "very big", hindi: "बहुत बड़ा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ใหญ่กว่า", romanization: "yài-kwàa", english: "bigger (than)", hindi: "(से) बड़ा", note: "กว่า (kwàa) = more than / से ज़्यादा"),
            WordForm(thai: "ใหญ่ที่สุด", romanization: "yài-thîi-sùt", english: "the biggest", hindi: "सबसे बड़ा", note: "ที่สุด (thîi-sùt) = most / सबसे"),
            WordForm(thai: "ไม่ใหญ่", romanization: "mâi-yài", english: "not big", hindi: "बड़ा नहीं", note: "ไม่ (mâi) = not / नहीं"),
        ],
        42: [
            WordForm(thai: "เล็กมาก", romanization: "lék-mâak", english: "very small", hindi: "बहुत छोटा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "เล็กกว่า", romanization: "lék-kwàa", english: "smaller", hindi: "से छोटा", note: "กว่า (kwàa) = more than (comparative) / से (तुलना)"),
            WordForm(thai: "เล็กที่สุด", romanization: "lék-thîi-sùt", english: "the smallest", hindi: "सबसे छोटा", note: "ที่สุด (thîi-sùt) = the most / सबसे"),
        ],
        43: [
            WordForm(thai: "ร้อนมาก", romanization: "rón mâak", english: "very hot", hindi: "बहुत गरम", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ร้อน", romanization: "mâi rón", english: "not hot", hindi: "गरम नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ร้อนไหม", romanization: "rón mǎi", english: "is it hot?", hindi: "क्या गरम है?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        44: [
            WordForm(thai: "หนาวมาก", romanization: "nǎao mâak", english: "very cold", hindi: "बहुत ठंड है", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่หนาว", romanization: "mâi nǎao", english: "not cold", hindi: "ठंड नहीं है", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "หนาวไหม", romanization: "nǎao mǎi", english: "are you cold?", hindi: "क्या ठंड लग रही है?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        45: [
            WordForm(thai: "ห้องน้ำอยู่ที่ไหน", romanization: "hông-náam yùu thîi-nǎi?", english: "where is the toilet?", hindi: "शौचालय कहाँ है?", note: "อยู่ที่ไหน (yùu thîi-nǎi) = where is / कहाँ है"),
            WordForm(thai: "เข้าห้องน้ำ", romanization: "khâo hông-náam", english: "to use the bathroom", hindi: "शौचालय जाना", note: "เข้า (khâo) = to enter / अंदर जाना"),
        ],
        46: [
            WordForm(thai: "จองโรงแรม", romanization: "joong roong-raem", english: "to book a hotel", hindi: "होटल बुक करना", note: "จอง (joong) = to book, reserve / बुक करना"),
        ],
        47: [
            WordForm(thai: "รถติด", romanization: "rót-tìt", english: "traffic jam", hindi: "ट्रैफ़िक जाम", note: "ติด (tìt) = stuck / फँसा"),
            WordForm(thai: "รถไฟ", romanization: "rót-fai", english: "train", hindi: "रेलगाड़ी / ट्रेन", note: "ไฟ (fai) = fire → รถไฟ = train / आग → रेलगाड़ी"),
        ],
        48: [
            WordForm(thai: "ราคาเท่าไหร่", romanization: "raa-khaa-thâo-rài", english: "How much is the price?", hindi: "क़ीमत कितनी है?", note: "ราคา (raa-khaa) = price / क़ीमत"),
            WordForm(thai: "อันนี้เท่าไหร่", romanization: "an-níi-thâo-rài", english: "How much is this one?", hindi: "यह कितने का है?", note: "อันนี้ (an-níi) = this one / यह वाला"),
        ],
        49: [
            WordForm(thai: "แพงมาก", romanization: "phaeng mâak", english: "very expensive", hindi: "बहुत महँगा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่แพง", romanization: "mâi phaeng", english: "not expensive", hindi: "महँगा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "แพงเกินไป", romanization: "phaeng koen-pai", english: "too expensive", hindi: "बहुत ज़्यादा महँगा", note: "เกินไป (koen-pai) = too much / हद से ज़्यादा"),
        ],
        50: [
            WordForm(thai: "ถูกมาก", romanization: "thùuk mâak", english: "very cheap", hindi: "बहुत सस्ता", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ถูกกว่า", romanization: "thùuk kwàa", english: "cheaper", hindi: "ज़्यादा सस्ता", note: "กว่า (kwàa) = more, -er (comparison) / तुलना में ज़्यादा"),
            WordForm(thai: "ถูกที่สุด", romanization: "thùuk thîi-sùt", english: "the cheapest", hindi: "सबसे सस्ता", note: "ที่สุด (thîi-sùt) = the most / सबसे"),
        ],
        52: [
            WordForm(thai: "พรุ่งนี้เช้า", romanization: "phrûng-níi cháao", english: "tomorrow morning", hindi: "कल सुबह", note: "เช้า (cháao) = morning / सुबह"),
            WordForm(thai: "เจอกันพรุ่งนี้", romanization: "joe kan phrûng-níi", english: "see you tomorrow", hindi: "कल मिलते हैं", note: "เจอกัน (joe kan) = to meet each other / एक-दूसरे से मिलना"),
        ],
        53: [
            WordForm(thai: "เมื่อวานนี้", romanization: "mûea-waan-níi", english: "yesterday (full form)", hindi: "बीता कल", note: "นี้ (níi) = this, adds emphasis / यह (ज़ोर के लिए)"),
        ],
        54: [
            WordForm(thai: "ไม่มีเวลา", romanization: "mâi-mii-wee-laa", english: "(I) have no time", hindi: "समय नहीं है", note: "ไม่มี (mâi-mii) = don't have / नहीं है"),
            WordForm(thai: "เวลาว่าง", romanization: "wee-laa-wâang", english: "free time", hindi: "खाली समय", note: "ว่าง (wâang) = free, vacant / खाली"),
        ],
        55: [
            WordForm(thai: "กี่ชั่วโมง", romanization: "kìi chûa-moong", english: "how many hours?", hindi: "कितने घंटे?", note: "กี่ (kìi) = how many / कितने"),
            WordForm(thai: "ครึ่งชั่วโมง", romanization: "khrûeng chûa-moong", english: "half an hour", hindi: "आधा घंटा", note: "ครึ่ง (khrûeng) = half / आधा"),
        ],
        56: [
            WordForm(thai: "ห้านาที", romanization: "hâa naa-thii", english: "five minutes", hindi: "पाँच मिनट", note: "ห้า (hâa) = five / पाँच"),
            WordForm(thai: "กี่นาที", romanization: "kìi naa-thii", english: "how many minutes?", hindi: "कितने मिनट?", note: "กี่ (kìi) = how many / कितने"),
        ],
        57: [
            WordForm(thai: "ตอนเช้า", romanization: "toon-cháao", english: "in the morning", hindi: "सुबह के समय", note: "ตอน (toon) = period of time / समय"),
            WordForm(thai: "เช้านี้", romanization: "cháao-níi", english: "this morning", hindi: "आज सुबह", note: "นี้ (níi) = this / यह"),
        ],
        58: [
            WordForm(thai: "ตอนเย็น", romanization: "toon yen", english: "in the evening", hindi: "शाम को", note: "ตอน (toon) = period of time / समय (के दौरान)"),
            WordForm(thai: "เย็นนี้", romanization: "yen níi", english: "this evening", hindi: "आज शाम", note: "นี้ (níi) = this / यह"),
        ],
        59: [
            WordForm(thai: "ตอนกลางคืน", romanization: "taawn-klaang-khuen", english: "at night", hindi: "रात में / रात के समय", note: "ตอน (taawn) = during, at / के समय"),
        ],
        60: [
            WordForm(thai: "ปีนี้", romanization: "pii-níi", english: "this year", hindi: "इस साल", note: "นี้ (níi) = this / यह"),
            WordForm(thai: "ปีหน้า", romanization: "pii-nâa", english: "next year", hindi: "अगले साल", note: "หน้า (nâa) = next / अगला"),
        ],
        61: [
            WordForm(thai: "เดือนนี้", romanization: "duean níi", english: "this month", hindi: "इस महीने", note: "นี้ (níi) = this / यह"),
            WordForm(thai: "เดือนหน้า", romanization: "duean nâa", english: "next month", hindi: "अगले महीने", note: "หน้า (nâa) = next / अगला"),
        ],
        62: [
            WordForm(thai: "สัปดาห์หน้า", romanization: "sàp-daa nâa", english: "next week", hindi: "अगला सप्ताह", note: "หน้า (nâa) = next / अगला"),
            WordForm(thai: "สัปดาห์ที่แล้ว", romanization: "sàp-daa thîi-láeo", english: "last week", hindi: "पिछला सप्ताह", note: "ที่แล้ว (thîi-láeo) = last, previous / पिछला"),
        ],
        63: [
            WordForm(thai: "คุณพ่อ", romanization: "khun-phôo", english: "father (polite)", hindi: "पिताजी", note: "คุณ (khun) = polite title / आदरसूचक शब्द"),
            WordForm(thai: "พ่อแม่", romanization: "phôo-mâe", english: "parents", hindi: "माता-पिता", note: "แม่ (mâe) = mother; father + mother = parents / แม่ (mâe) = माँ"),
        ],
        64: [
            WordForm(thai: "คุณแม่", romanization: "khun mâe", english: "mother (polite)", hindi: "माता जी", note: "คุณ (khun) = polite title / आदरसूचक उपाधि (जी)"),
        ],
        65: [
            WordForm(thai: "ลูกชาย", romanization: "lûuk-chaai", english: "son", hindi: "बेटा", note: "ชาย (chaai) = male / पुरुष"),
            WordForm(thai: "ลูกสาว", romanization: "lûuk-sǎao", english: "daughter", hindi: "बेटी", note: "สาว (sǎao) = girl, female / लड़की"),
        ],
        66: [
            WordForm(thai: "พี่ชาย", romanization: "phîi-chaai", english: "older brother", hindi: "बड़ा भाई", note: "ชาย (chaai) = male / पुरुष"),
            WordForm(thai: "พี่สาว", romanization: "phîi-sǎao", english: "older sister", hindi: "बड़ी बहन", note: "สาว (sǎao) = young woman, female / युवती, स्त्री"),
        ],
        67: [
            WordForm(thai: "น้องชาย", romanization: "nóong-chaai", english: "younger brother", hindi: "छोटा भाई", note: "ชาย (chaai) = male / पुरुष"),
            WordForm(thai: "น้องสาว", romanization: "nóong-sǎao", english: "younger sister", hindi: "छोटी बहन", note: "สาว (sǎao) = female, young woman / स्त्री"),
        ],
        68: [
            WordForm(thai: "ผู้ชายคนนั้น", romanization: "phûu-chaai khon nán", english: "that man", hindi: "वह आदमी", note: "คน (khon) = classifier for people + นั้น (nán) = that / लोगों का classifier + वह"),
        ],
        69: [
            WordForm(thai: "ห้องน้ำผู้หญิง", romanization: "hông-náam phûu-yǐng", english: "women's restroom", hindi: "महिला शौचालय", note: "ห้องน้ำ (hông-náam) = toilet / शौचालय"),
        ],
        70: [
            WordForm(thai: "เด็กๆ", romanization: "dèk-dèk", english: "children / kids", hindi: "बच्चे", note: "ๆ = repetition mark (plural feel) / दोहराव चिह्न (बहुवचन भाव)"),
            WordForm(thai: "เด็กผู้ชาย", romanization: "dèk phûu-chaai", english: "boy", hindi: "लड़का", note: "ผู้ชาย (phûu-chaai) = male / पुरुष"),
        ],
        71: [
            WordForm(thai: "ชื่ออะไร", romanization: "chûue-à-rai", english: "what's (your) name?", hindi: "नाम क्या है?", note: "อะไร (à-rai) = what / क्या"),
            WordForm(thai: "ชื่อเล่น", romanization: "chûue-lên", english: "nickname", hindi: "उपनाम / निकनेम", note: "เล่น (lên) = play → nickname / खेल → निकनेम"),
        ],
        72: [
            WordForm(thai: "คุณครู", romanization: "khun-khruu", english: "teacher (polite address)", hindi: "शिक्षक जी (आदरपूर्वक)", note: "คุณ (khun) = polite title / आदरसूचक शब्द"),
        ],
        73: [
            WordForm(thai: "ปวดหัว", romanization: "pùat hǔa", english: "to have a headache", hindi: "सिरदर्द होना", note: "ปวด (pùat) = to ache / दर्द होना"),
            WordForm(thai: "หัวใจ", romanization: "hǔa-jai", english: "heart (organ)", hindi: "हृदय / दिल", note: "ใจ (jai) = heart, mind / दिल; หัว + ใจ = हृदय"),
        ],
        74: [
            WordForm(thai: "ปวดตา", romanization: "pùat taa", english: "(my) eyes hurt", hindi: "आँखों में दर्द है", note: "ปวด (pùat) = to ache / दर्द होना"),
        ],
        75: [
            WordForm(thai: "ล้างมือ", romanization: "láang muue", english: "to wash one's hands", hindi: "हाथ धोना", note: "ล้าง (láang) = to wash / धोना"),
            WordForm(thai: "มือถือ", romanization: "muue-thǔue", english: "mobile phone", hindi: "मोबाइल फ़ोन", note: "ถือ (thǔue) = to hold; 'hand-held' / पकड़ना"),
        ],
        76: [
            WordForm(thai: "ใจดี", romanization: "jai-dii", english: "kind, kind-hearted", hindi: "दयालु", note: "ดี (dii) = good / अच्छा; ใจ + ดี = kind / दयालु"),
            WordForm(thai: "ดีใจ", romanization: "dii-jai", english: "glad, happy", hindi: "खुश", note: "reversed order ดี + ใจ = glad / उल्टा क्रम: खुश"),
        ],
        77: [
            WordForm(thai: "แปรงฟัน", romanization: "praeng-fan", english: "to brush one's teeth", hindi: "दाँत ब्रश करना", note: "แปรง (praeng) = to brush / ब्रश करना"),
            WordForm(thai: "ปวดฟัน", romanization: "pùat-fan", english: "toothache", hindi: "दाँत में दर्द", note: "ปวด (pùat) = to ache / दर्द होना"),
        ],
        78: [
            WordForm(thai: "ปวดหัว", romanization: "pùat-hǔa", english: "to have a headache", hindi: "सिरदर्द होना", note: "หัว (hǔa) = head / सिर"),
            WordForm(thai: "ปวดท้อง", romanization: "pùat-thóong", english: "to have a stomachache", hindi: "पेट दर्द होना", note: "ท้อง (thóong) = stomach / पेट"),
            WordForm(thai: "ปวดมาก", romanization: "pùat-mâak", english: "it hurts a lot", hindi: "बहुत दर्द है", note: "มาก (mâak) = very / बहुत"),
        ],
        79: [
            WordForm(thai: "ป่วยหนัก", romanization: "pùai nàk", english: "seriously ill", hindi: "गंभीर रूप से बीमार", note: "หนัก (nàk) = heavy, severely / गंभीर, भारी"),
            WordForm(thai: "ป่วยไหม", romanization: "pùai mǎi", english: "are you sick?", hindi: "क्या तुम बीमार हो?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        80: [
            WordForm(thai: "ไปหาหมอ", romanization: "pai hǎa mǒo", english: "to go see a doctor", hindi: "डॉक्टर के पास जाना", note: "ไปหา (pai hǎa) = to go see (someone) / किसी से मिलने जाना"),
            WordForm(thai: "หมอฟัน", romanization: "mǒo fan", english: "dentist", hindi: "दाँतों का डॉक्टर", note: "ฟัน (fan) = tooth / दाँत"),
        ],
        81: [
            WordForm(thai: "กินยา", romanization: "kin yaa", english: "to take medicine", hindi: "दवा लेना", note: "กิน (kin) = to eat, take / खाना, लेना"),
            WordForm(thai: "ร้านขายยา", romanization: "ráan-khǎai-yaa", english: "pharmacy", hindi: "दवा की दुकान", note: "ร้านขาย (ráan-khǎai) = shop that sells / बेचने वाली दुकान"),
        ],
        82: [
            WordForm(thai: "ไปโรงพยาบาล", romanization: "pai roong-phá-yaa-baan", english: "to go to the hospital", hindi: "अस्पताल जाना", note: "ไป (pai) = to go / जाना"),
        ],
        83: [
            WordForm(thai: "สีอะไร", romanization: "sǐi-à-rai", english: "what color?", hindi: "कौन सा रंग?", note: "อะไร (à-rai) = what / क्या"),
        ],
        84: [
            WordForm(thai: "สีแดง", romanization: "sǐi-daeng", english: "red color / red", hindi: "लाल रंग", note: "สี (sǐi) = color / रंग"),
        ],
        85: [
            WordForm(thai: "สีขาว", romanization: "sǐi khǎao", english: "white color", hindi: "सफ़ेद रंग", note: "สี (sǐi) = color / रंग"),
        ],
        86: [
            WordForm(thai: "สีดำ", romanization: "sǐi dam", english: "black (the color)", hindi: "काला रंग", note: "สี (sǐi) = color / रंग"),
            WordForm(thai: "กาแฟดำ", romanization: "kaa-fae dam", english: "black coffee", hindi: "ब्लैक कॉफ़ी", note: "กาแฟ (kaa-fae) = coffee / कॉफ़ी"),
        ],
        87: [
            WordForm(thai: "สีเขียว", romanization: "sǐi khǐao", english: "green (the color)", hindi: "हरा रंग", note: "สี (sǐi) = color / रंग"),
            WordForm(thai: "ไฟเขียว", romanization: "fai khǐao", english: "green light", hindi: "हरी बत्ती", note: "ไฟ (fai) = light / बत्ती"),
        ],
        88: [
            WordForm(thai: "สีฟ้า", romanization: "sǐi fáa", english: "sky-blue (color)", hindi: "आसमानी रंग", note: "สี (sǐi) = color / रंग"),
            WordForm(thai: "ท้องฟ้า", romanization: "thóong-fáa", english: "the sky", hindi: "आसमान", note: "ท้อง (thóong) + ฟ้า = the sky / आसमान"),
        ],
        89: [
            WordForm(thai: "สีเหลือง", romanization: "sǐi-lǔeang", english: "yellow (the color)", hindi: "पीला रंग", note: "สี (sǐi) = color / रंग"),
            WordForm(thai: "สีเหลืองอ่อน", romanization: "sǐi-lǔeang-àawn", english: "light yellow", hindi: "हल्का पीला", note: "อ่อน (àawn) = light, pale / हल्का"),
        ],
        90: [
            WordForm(thai: "ฝนตก", romanization: "fǒn-tòk", english: "it's raining", hindi: "बारिश हो रही है", note: "ตก (tòk) = to fall / गिरना"),
            WordForm(thai: "ฝนตกหนัก", romanization: "fǒn-tòk-nàk", english: "it's raining heavily", hindi: "तेज़ बारिश हो रही है", note: "หนัก (nàk) = heavy / भारी, तेज़"),
        ],
        91: [
            WordForm(thai: "แดดแรง", romanization: "dàet raeng", english: "strong sunshine", hindi: "तेज़ धूप", note: "แรง (raeng) = strong / तेज़"),
            WordForm(thai: "แดดออก", romanization: "dàet òok", english: "the sun is out / it's sunny", hindi: "धूप निकली है", note: "ออก (òok) = to come out / निकलना"),
        ],
        92: [
            WordForm(thai: "ลมแรง", romanization: "lom raeng", english: "strong wind", hindi: "तेज़ हवा", note: "แรง (raeng) = strong / तेज़"),
            WordForm(thai: "ลมเย็น", romanization: "lom yen", english: "cool breeze", hindi: "ठंडी हवा", note: "เย็น (yen) = cool / ठंडा"),
        ],
        93: [
            WordForm(thai: "ไปทะเล", romanization: "pai thá-lee", english: "to go to the sea / beach", hindi: "समुद्र जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "อาหารทะเล", romanization: "aa-hǎan thá-lee", english: "seafood", hindi: "समुद्री भोजन", note: "อาหาร (aa-hǎan) = food / भोजन"),
        ],
        94: [
            WordForm(thai: "ภูเขาไฟ", romanization: "phuu-khǎo-fai", english: "volcano", hindi: "ज्वालामुखी", note: "ไฟ (fai) = fire / आग"),
        ],
        95: [
            WordForm(thai: "ปลูกต้นไม้", romanization: "plùuk-tôn-mái", english: "to plant a tree", hindi: "पेड़ लगाना", note: "ปลูก (plùuk) = to plant / लगाना, उगाना"),
        ],
        96: [
            WordForm(thai: "ดอกไม้สวย", romanization: "dòk-mái-sǔai", english: "beautiful flowers", hindi: "सुंदर फूल", note: "สวย (sǔai) = beautiful / सुंदर"),
        ],
        97: [
            WordForm(thai: "อากาศดี", romanization: "aa-kàat dii", english: "nice weather", hindi: "अच्छा मौसम", note: "ดี (dii) = good / अच्छा"),
            WordForm(thai: "อากาศร้อน", romanization: "aa-kàat rón", english: "hot weather", hindi: "गरम मौसम", note: "ร้อน (rón) = hot / गरम"),
        ],
        98: [
            WordForm(thai: "กลับบ้าน", romanization: "klàp bâan", english: "to go home", hindi: "घर लौटना", note: "กลับ (klàp) = to return / लौटना"),
            WordForm(thai: "อยู่บ้าน", romanization: "yùu bâan", english: "to stay at home", hindi: "घर पर रहना", note: "อยู่ (yùu) = to stay, be at / रहना"),
        ],
        99: [
            WordForm(thai: "ไปตลาด", romanization: "pai tà-làat", english: "to go to the market", hindi: "बाज़ार जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "ตลาดนัด", romanization: "tà-làat-nát", english: "flea / weekend market", hindi: "साप्ताहिक बाज़ार", note: "นัด (nát) = appointed time; a pop-up market / नियत समय"),
        ],
        100: [
            WordForm(thai: "ร้านอาหาร", romanization: "ráan-aa-hǎan", english: "restaurant", hindi: "रेस्टोरेंट (भोजनालय)", note: "อาหาร (aa-hǎan) = food / खाना"),
            WordForm(thai: "ร้านกาแฟ", romanization: "ráan-kaa-fae", english: "coffee shop / café", hindi: "कॉफ़ी की दुकान", note: "กาแฟ (kaa-fae) = coffee / कॉफ़ी"),
        ],
        101: [
            WordForm(thai: "ร้านอาหารไทย", romanization: "ráan-aa-hǎan-thai", english: "Thai restaurant", hindi: "थाई रेस्टोरेंट", note: "ไทย (thai) = Thai / थाई"),
        ],
        102: [
            WordForm(thai: "ไปโรงเรียน", romanization: "pai-roong-rian", english: "to go to school", hindi: "स्कूल जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "ที่โรงเรียน", romanization: "thîi-roong-rian", english: "at school", hindi: "स्कूल में", note: "ที่ (thîi) = at / पर, में"),
        ],
        103: [
            WordForm(thai: "ไปวัด", romanization: "pai wát", english: "to go to the temple", hindi: "मंदिर जाना", note: "ไป (pai) = to go / जाना"),
        ],
        104: [
            WordForm(thai: "ไปสนามบิน", romanization: "pai sà-nǎam-bin", english: "to go to the airport", hindi: "हवाई अड्डे जाना", note: "ไป (pai) = to go / जाना"),
        ],
        105: [
            WordForm(thai: "ไปธนาคาร", romanization: "pai thá-naa-khaan", english: "to go to the bank", hindi: "बैंक जाना", note: "ไป (pai) = to go / जाना"),
        ],
        106: [
            WordForm(thai: "ข้ามถนน", romanization: "khâam thà-nǒn", english: "to cross the road", hindi: "सड़क पार करना", note: "ข้าม (khâam) = to cross / पार करना"),
        ],
        107: [
            WordForm(thai: "ในเมือง", romanization: "nai-mueang", english: "in town / downtown", hindi: "शहर में", note: "ใน (nai) = in / में"),
            WordForm(thai: "เมืองไทย", romanization: "mueang-thai", english: "Thailand (colloquial)", hindi: "थाईलैंड (बोलचाल)", note: "ไทย (thai) = Thai → Thailand / थाई → थाईलैंड"),
        ],
        108: [
            WordForm(thai: "ประเทศไทย", romanization: "prà-thêet-thai", english: "Thailand", hindi: "थाईलैंड", note: "ไทย (thai) = Thai / थाई"),
            WordForm(thai: "ต่างประเทศ", romanization: "tàang-prà-thêet", english: "abroad / foreign country", hindi: "विदेश", note: "ต่าง (tàang) = different, foreign / अलग, विदेशी"),
        ],
        109: [
            WordForm(thai: "ไม่มีเงิน", romanization: "mâi mii ngoen", english: "to have no money", hindi: "पैसे नहीं हैं", note: "ไม่มี (mâi mii) = to not have / नहीं होना"),
            WordForm(thai: "เงินทอน", romanization: "ngoen thoon", english: "change (money returned)", hindi: "खुले पैसे / बाकी", note: "ทอน (thoon) = to give change / बाकी लौटाना"),
        ],
        110: [
            WordForm(thai: "กี่บาท", romanization: "kìi bàat", english: "how many baht? (how much?)", hindi: "कितने बात? (कितना हुआ?)", note: "กี่ (kìi) = how many / कितने"),
            WordForm(thai: "ร้อยบาท", romanization: "rói bàat", english: "one hundred baht", hindi: "सौ बात", note: "ร้อย (rói) = hundred / सौ"),
        ],
        111: [
            WordForm(thai: "อยากซื้อ", romanization: "yàak súue", english: "want to buy", hindi: "खरीदना चाहता हूँ", note: "อยาก (yàak) = to want to / चाहना"),
            WordForm(thai: "ไม่ซื้อ", romanization: "mâi súue", english: "not buying", hindi: "नहीं खरीदूँगा", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ซื้อแล้ว", romanization: "súue láeo", english: "already bought", hindi: "खरीद लिया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "ซื้อของ", romanization: "súue khǒong", english: "to go shopping / buy things", hindi: "ख़रीदारी करना", note: "ของ (khǒong) = things / चीज़ें"),
        ],
        112: [
            WordForm(thai: "ขายดี", romanization: "khǎai dii", english: "sells well", hindi: "खूब बिकता है", note: "ดี (dii) = good, well / अच्छा"),
            WordForm(thai: "ขายหมดแล้ว", romanization: "khǎai mòt láew", english: "sold out", hindi: "सब बिक गया", note: "หมดแล้ว (mòt láew) = all gone already / सब खत्म हो गया"),
            WordForm(thai: "ไม่ขาย", romanization: "mâi khǎai", english: "not for sale / (I) don't sell it", hindi: "बेचना नहीं है", note: "ไม่ (mâi) = not / नहीं"),
        ],
        113: [
            WordForm(thai: "ลดราคาได้ไหม", romanization: "lót-raa-khaa-dâai-mǎi", english: "can you give a discount?", hindi: "क्या छूट मिल सकती है?", note: "ได้ไหม (dâai-mǎi) = can…? / क्या…सकते हैं?"),
            WordForm(thai: "กำลังลดราคา", romanization: "kam-lang-lót-raa-khaa", english: "on sale (right now)", hindi: "सेल चल रही है", note: "กำลัง (kam-lang) = -ing, in progress / चल रहा है"),
        ],
        114: [
            WordForm(thai: "ฟรีไหม", romanization: "frii-mǎi", english: "Is it free?", hindi: "क्या यह मुफ़्त है?", note: "ไหม (mǎi) = question particle / प्रश्न शब्द"),
            WordForm(thai: "ได้ฟรี", romanization: "dâi-frii", english: "got it for free", hindi: "मुफ़्त में मिला", note: "ได้ (dâi) = to get, receive / मिलना"),
        ],
        115: [
            WordForm(thai: "พูดช้าๆ", romanization: "phûut cháa-cháa", english: "speak slowly", hindi: "धीरे-धीरे बोलिए", note: "ช้าๆ (cháa-cháa) = slowly / धीरे-धीरे"),
            WordForm(thai: "พูดได้", romanization: "phûut dâi", english: "can speak", hindi: "बोल सकना", note: "ได้ (dâi) = can, able to / सकना"),
            WordForm(thai: "พูดอีกที", romanization: "phûut ìik thii", english: "say it again", hindi: "फिर से कहिए", note: "อีกที (ìik thii) = once more / एक बार फिर"),
        ],
        116: [
            WordForm(thai: "ฟังเพลง", romanization: "fang phleeng", english: "to listen to music", hindi: "गाना सुनना", note: "เพลง (phleeng) = song / गाना"),
            WordForm(thai: "ฟังอีกที", romanization: "fang ìik thii", english: "listen once more", hindi: "फिर से सुनना", note: "อีกที (ìik thii) = once more / एक बार और"),
            WordForm(thai: "ไม่ฟัง", romanization: "mâi fang", english: "(he/she) doesn't listen", hindi: "नहीं सुनता", note: "ไม่ (mâi) = not / नहीं"),
        ],
        117: [
            WordForm(thai: "อ่านหนังสือ", romanization: "àan nǎng-sǔue", english: "to read (a book)", hindi: "किताब पढ़ना", note: "หนังสือ (nǎng-sǔue) = book / किताब"),
            WordForm(thai: "อ่านแล้ว", romanization: "àan láeo", english: "already read (it)", hindi: "पढ़ लिया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "อ่านไม่ออก", romanization: "àan mâi òok", english: "can't read it", hindi: "पढ़ नहीं पाता", note: "ไม่ออก (mâi òok) = unable to (read/figure out) / नहीं कर पाना"),
        ],
        118: [
            WordForm(thai: "เขียนยังไง", romanization: "khǐan yang-ngai", english: "How do you write it?", hindi: "कैसे लिखते हैं?", note: "ยังไง (yang-ngai) = how / कैसे"),
            WordForm(thai: "เขียนไม่ได้", romanization: "khǐan mâi dâai", english: "can't write (it)", hindi: "लिख नहीं सकते", note: "ไม่ได้ (mâi dâai) = cannot / नहीं सकते"),
            WordForm(thai: "เขียนแล้ว", romanization: "khǐan láew", english: "already wrote (it)", hindi: "लिख दिया", note: "แล้ว (láew) = already / हो चुका"),
        ],
        119: [
            WordForm(thai: "ดูหนัง", romanization: "duu-nǎng", english: "to watch a movie", hindi: "फ़िल्म देखना", note: "หนัง (nǎng) = movie / फ़िल्म"),
            WordForm(thai: "ขอดูหน่อย", romanization: "khǎaw-duu-nòi", english: "may I have a look?", hindi: "ज़रा देखने दीजिए", note: "ขอ…หน่อย (khǎaw…nòi) = may I…, please / ज़रा…दीजिए"),
            WordForm(thai: "ดูแล้ว", romanization: "duu-láew", english: "already watched (it)", hindi: "देख लिया", note: "แล้ว (láew) = already / हो चुका"),
        ],
        120: [
            WordForm(thai: "ไปนอน", romanization: "pai-noon", english: "to go to bed", hindi: "सोने जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "นอนหลับ", romanization: "noon-làp", english: "to fall asleep / be asleep", hindi: "सो जाना", note: "หลับ (làp) = asleep / नींद में"),
            WordForm(thai: "ยังไม่นอน", romanization: "yang-mâi-noon", english: "not sleeping yet", hindi: "अभी नहीं सोया", note: "ยังไม่ (yang-mâi) = not yet / अभी नहीं"),
        ],
        121: [
            WordForm(thai: "ตื่นแล้ว", romanization: "tùuen láeo", english: "already awake / woke up already", hindi: "जाग गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "ตื่นเช้า", romanization: "tùuen cháao", english: "to wake up early", hindi: "सुबह जल्दी उठना", note: "เช้า (cháao) = morning, early / सुबह"),
            WordForm(thai: "ตื่นสาย", romanization: "tùuen sǎai", english: "to wake up late", hindi: "देर से उठना", note: "สาย (sǎai) = late (in the morning) / देर से"),
        ],
        122: [
            WordForm(thai: "ทำอะไร", romanization: "tham à-rai", english: "what are you doing?", hindi: "क्या कर रहे हो?", note: "อะไร (à-rai) = what / क्या"),
            WordForm(thai: "ทำได้", romanization: "tham dâai", english: "(I) can do it", hindi: "कर सकते हैं", note: "ได้ (dâai) = can / सकना"),
            WordForm(thai: "ทำไม่ได้", romanization: "tham mâi dâai", english: "(I) can't do it", hindi: "नहीं कर सकते", note: "ไม่ได้ (mâi dâai) = cannot / नहीं कर सकना"),
        ],
        123: [
            WordForm(thai: "ไปทำงาน", romanization: "pai tham-ngaan", english: "to go to work", hindi: "काम पर जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "ทำงานหนัก", romanization: "tham-ngaan nàk", english: "to work hard", hindi: "कड़ी मेहनत करना", note: "หนัก (nàk) = heavy, hard / भारी"),
            WordForm(thai: "ทำงานที่ไหน", romanization: "tham-ngaan thîi-nǎi?", english: "where do you work?", hindi: "कहाँ काम करते हैं?", note: "ที่ไหน (thîi-nǎi) = where / कहाँ"),
        ],
        124: [
            WordForm(thai: "เดินเล่น", romanization: "doen lên", english: "to take a stroll", hindi: "टहलना", note: "เล่น (lên) = for fun / मज़े के लिए"),
            WordForm(thai: "เดินไป", romanization: "doen pai", english: "to walk there / go on foot", hindi: "पैदल जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "เดินไม่ไหว", romanization: "doen mâi wǎi", english: "too tired to walk (anymore)", hindi: "और चला नहीं जा रहा", note: "ไม่ไหว (mâi wǎi) = can't manage, no strength left / बस की बात नहीं"),
        ],
        125: [
            WordForm(thai: "วิ่งเร็ว", romanization: "wîng-réo", english: "to run fast", hindi: "तेज़ दौड़ना", note: "เร็ว (réo) = fast / तेज़"),
            WordForm(thai: "ไปวิ่ง", romanization: "pai-wîng", english: "to go for a run", hindi: "दौड़ने जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "อย่าวิ่ง", romanization: "yàa-wîng", english: "don't run!", hindi: "मत दौड़ो!", note: "อย่า (yàa) = don't / मत"),
        ],
        126: [
            WordForm(thai: "ไม่เข้าใจ", romanization: "mâi-khâo-jai", english: "(I) don't understand", hindi: "समझ नहीं आया", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "เข้าใจแล้ว", romanization: "khâo-jai-láeo", english: "(I) understand now", hindi: "अब समझ गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "เข้าใจไหม", romanization: "khâo-jai-mǎi", english: "Do you understand?", hindi: "क्या समझ आया?", note: "ไหม (mǎi) = question particle / प्रश्न शब्द"),
        ],
        127: [
            WordForm(thai: "ไม่รู้", romanization: "mâi rúu", english: "(I) don't know", hindi: "पता नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "รู้แล้ว", romanization: "rúu láeo", english: "(I) already know", hindi: "पता है / जान गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "รู้จัก", romanization: "rúu-jàk", english: "to know (a person / place)", hindi: "(किसी से) परिचित होना", note: "รู้ + จัก (jàk) = to be acquainted with / जान-पहचान होना"),
        ],
        128: [
            WordForm(thai: "คิดว่า", romanization: "khít wâa", english: "to think that...", hindi: "सोचना कि...", note: "ว่า (wâa) = that (connector) / कि"),
            WordForm(thai: "คิดถึง", romanization: "khít thǔeng", english: "to miss (someone)", hindi: "याद आना (किसी की)", note: "ถึง (thǔeng) = to, of — คิดถึง = to miss / याद करना"),
            WordForm(thai: "คิดมาก", romanization: "khít mâak", english: "to overthink, worry too much", hindi: "ज़्यादा सोचना, चिंता करना", note: "มาก (mâak) = a lot — here means overthink / बहुत"),
        ],
        129: [
            WordForm(thai: "ช่วยด้วย", romanization: "chûai dûai!", english: "help!", hindi: "बचाओ! मदद करो!", note: "ด้วย (dûai) makes it an urgent cry for help / मदद की तुरंत पुकार"),
            WordForm(thai: "ช่วยหน่อย", romanization: "chûai nòi", english: "please help me", hindi: "ज़रा मदद कीजिए", note: "หน่อย (nòi) = a little, softens the request / ज़रा"),
            WordForm(thai: "ช่วยได้ไหม", romanization: "chûai dâai mǎi?", english: "can you help?", hindi: "क्या मदद कर सकते हैं?", note: "ได้ไหม (dâai mǎi) = can you? / कर सकते हैं?"),
        ],
        130: [
            WordForm(thai: "รอสักครู่", romanization: "roo sàk-khrûu", english: "please wait a moment", hindi: "एक क्षण प्रतीक्षा कीजिए", note: "สักครู่ (sàk-khrûu) = a moment / एक पल"),
            WordForm(thai: "รอเดี๋ยวนะ", romanization: "roo dǐao ná", english: "wait a sec, okay?", hindi: "ज़रा रुको", note: "เดี๋ยว (dǐao) = a moment / ज़रा; นะ (ná) = softening particle / नरम बनाने वाला कण"),
            WordForm(thai: "รอนานไหม", romanization: "roo naan mǎi", english: "Did you wait long?", hindi: "क्या बहुत देर इंतज़ार किया?", note: "นาน (naan) = a long time / देर"),
        ],
        131: [
            WordForm(thai: "วันหยุด", romanization: "wan-yùt", english: "day off / holiday", hindi: "छुट्टी का दिन", note: "วัน (wan) = day → day off / दिन → छुट्टी"),
            WordForm(thai: "หยุดก่อน", romanization: "yùt-kàawn", english: "stop first / hold on", hindi: "ज़रा रुको", note: "ก่อน (kàawn) = first / पहले"),
            WordForm(thai: "อย่าหยุด", romanization: "yàa-yùt", english: "don't stop", hindi: "मत रुको", note: "อย่า (yàa) = don't / मत"),
        ],
        132: [
            WordForm(thai: "เปิดไฟ", romanization: "pòet-fai", english: "to turn on the light", hindi: "बत्ती जलाना", note: "ไฟ (fai) = light / बत्ती"),
            WordForm(thai: "เปิดแล้ว", romanization: "pòet-láeo", english: "already open", hindi: "खुल गया है", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "เปิดกี่โมง", romanization: "pòet-kìi-moong", english: "What time does it open?", hindi: "कितने बजे खुलता है?", note: "กี่โมง (kìi-moong) = what time / कितने बजे"),
        ],
        133: [
            WordForm(thai: "ปิดแล้ว", romanization: "pìt láeo", english: "already closed", hindi: "बंद हो गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "ปิดไฟ", romanization: "pìt fai", english: "to turn off the light", hindi: "बत्ती बंद करना", note: "ไฟ (fai) = light / बत्ती"),
            WordForm(thai: "ปิดประตู", romanization: "pìt prà-tuu", english: "to close the door", hindi: "दरवाज़ा बंद करना", note: "ประตู (prà-tuu) = door / दरवाज़ा"),
        ],
        134: [
            WordForm(thai: "ปีใหม่", romanization: "pii mài", english: "New Year", hindi: "नया साल", note: "ปี (pii) = year / साल"),
            WordForm(thai: "ของใหม่", romanization: "khǒong mài", english: "a new thing, brand-new item", hindi: "नई चीज़", note: "ของ (khǒong) = thing / चीज़"),
            WordForm(thai: "ทำใหม่", romanization: "tham mài", english: "to do it again, redo", hindi: "फिर से करना", note: "verb + ใหม่ = to redo / क्रिया + ใหม่ = दोबारा करना"),
        ],
        135: [
            WordForm(thai: "เก่ามาก", romanization: "kào mâak", english: "very old", hindi: "बहुत पुराना", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "เก่าแล้ว", romanization: "kào láeo", english: "old now / already old", hindi: "पुराना हो गया", note: "แล้ว (láeo) = already / हो गया"),
            WordForm(thai: "ของเก่า", romanization: "khǒong kào", english: "old things / antiques", hindi: "पुरानी चीज़ें", note: "ของ (khǒong) = things / चीज़ें"),
        ],
        136: [
            WordForm(thai: "เร็วมาก", romanization: "reo mâak", english: "very fast", hindi: "बहुत तेज़", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "เร็วๆ หน่อย", romanization: "reo-reo nòi", english: "hurry up, please!", hindi: "ज़रा जल्दी करो!", note: "หน่อย (nòi) = a bit (softens a request) / ज़रा"),
            WordForm(thai: "เร็วที่สุด", romanization: "reo thîi-sùt", english: "the fastest", hindi: "सबसे तेज़", note: "ที่สุด (thîi-sùt) = most / सबसे"),
        ],
        137: [
            WordForm(thai: "ช้า ๆ", romanization: "cháa-cháa", english: "slowly", hindi: "धीरे-धीरे", note: "ๆ (repetition) = adverb 'slowly' / दोहराव = 'धीरे-धीरे'"),
            WordForm(thai: "ช้ามาก", romanization: "cháa-mâak", english: "very slow", hindi: "बहुत धीमा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ช้าไป", romanization: "cháa-pai", english: "too slow", hindi: "ज़रूरत से ज़्यादा धीमा", note: "ไป (pai) = too, excessively / ज़रूरत से ज़्यादा"),
        ],
        138: [
            WordForm(thai: "ง่ายมาก", romanization: "ngâai-mâak", english: "very easy", hindi: "बहुत आसान", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ง่าย", romanization: "mâi-ngâai", english: "not easy", hindi: "आसान नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ง่ายกว่า", romanization: "ngâai-kwàa", english: "easier", hindi: "से आसान", note: "กว่า (kwàa) = more than (comparative) / से (तुलना)"),
        ],
        139: [
            WordForm(thai: "ยากมาก", romanization: "yâak mâak", english: "very difficult", hindi: "बहुत मुश्किल", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ยาก", romanization: "mâi yâak", english: "not difficult", hindi: "मुश्किल नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ยากไหม", romanization: "yâak mǎi", english: "is it difficult?", hindi: "क्या मुश्किल है?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        140: [
            WordForm(thai: "สนุกมาก", romanization: "sà-nùk mâak", english: "a lot of fun", hindi: "बहुत मज़ेदार", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่สนุก", romanization: "mâi sà-nùk", english: "not fun", hindi: "मज़ा नहीं आया", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "สนุกไหม", romanization: "sà-nùk mǎi", english: "was it fun?", hindi: "क्या मज़ा आया?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        141: [
            WordForm(thai: "เหนื่อยมาก", romanization: "nùeai mâak", english: "very tired", hindi: "बहुत थका हुआ", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่เหนื่อย", romanization: "mâi nùeai", english: "not tired", hindi: "थका नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "เหนื่อยไหม", romanization: "nùeai mǎi?", english: "are you tired?", hindi: "क्या थक गए?", note: "ไหม (mǎi) = yes/no question particle / हाँ-ना सवाल का शब्द"),
            WordForm(thai: "เหนื่อยแล้ว", romanization: "nùeai láeo", english: "tired now", hindi: "थक गया हूँ", note: "แล้ว (láeo) = already, by now / हो गया"),
        ],
        142: [
            WordForm(thai: "หวานมาก", romanization: "wǎan mâak", english: "very sweet", hindi: "बहुत मीठा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่หวาน", romanization: "mâi wǎan", english: "not sweet", hindi: "मीठा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "หวานน้อย", romanization: "wǎan nói", english: "less sweet (when ordering drinks)", hindi: "कम मीठा (ऑर्डर करते समय)", note: "น้อย (nói) = little, less / कम"),
            WordForm(thai: "หวานไป", romanization: "wǎan pai", english: "too sweet", hindi: "ज़्यादा ही मीठा", note: "ไป (pai) = too, excessively / हद से ज़्यादा"),
        ],
        143: [
            WordForm(thai: "ใกล้มาก", romanization: "klâi-mâak", english: "very near", hindi: "बहुत पास", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ใกล้ ๆ", romanization: "klâi-klâi", english: "right nearby", hindi: "पास ही", note: "ๆ (repetition) = 'right around here' / दोहराव = 'पास ही'"),
            WordForm(thai: "ใกล้ที่สุด", romanization: "klâi-thîi-sùt", english: "the nearest", hindi: "सबसे पास", note: "ที่สุด (thîi-sùt) = most / सबसे"),
        ],
        144: [
            WordForm(thai: "ไกลมาก", romanization: "klai-mâak", english: "very far", hindi: "बहुत दूर", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ไกล", romanization: "mâi-klai", english: "not far", hindi: "दूर नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ไกลไหม", romanization: "klai-mǎi", english: "Is it far?", hindi: "क्या यह दूर है?", note: "ไหม (mǎi) = question particle / प्रश्न शब्द"),
        ],
        145: [
            WordForm(thai: "อะไรนะ", romanization: "à-rai ná", english: "what? / pardon?", hindi: "क्या कहा?", note: "นะ (ná) = softening particle / वाक्य को कोमल बनाने वाला शब्द"),
        ],
        146: [
            WordForm(thai: "อยู่ที่ไหน", romanization: "yùu thîi-nǎi", english: "where is it? / where are you?", hindi: "कहाँ है? / कहाँ हो?", note: "อยู่ (yùu) = to be (at a place) / होना (किसी जगह पर)"),
        ],
        149: [
            WordForm(thai: "ของใคร", romanization: "khǎawng-khrai", english: "whose?", hindi: "किसका?", note: "ของ (khǎawng) = of, belonging to / का"),
            WordForm(thai: "ใครก็ได้", romanization: "khrai-kâw-dâai", english: "anyone / anybody will do", hindi: "कोई भी", note: "ก็ได้ (kâw-dâai) = …is fine, whichever / भी चलेगा"),
        ],
        150: [
            WordForm(thai: "ไปยังไง", romanization: "pai-yang-ngai", english: "How do I get there?", hindi: "वहाँ कैसे जाऊँ?", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "ทำยังไง", romanization: "tham-yang-ngai", english: "How do I do it?", hindi: "कैसे करूँ?", note: "ทำ (tham) = to do / करना"),
        ],
        152: [
            WordForm(thai: "หรือเปล่า", romanization: "rǔue plào", english: "...or not? (question tag)", hindi: "...या नहीं?", note: "เปล่า (plào) = or not / या नहीं"),
            WordForm(thai: "หรือยัง", romanization: "rǔue yang", english: "...yet? (e.g. eaten yet?)", hindi: "...अभी तक? (क्या हो गया?)", note: "ยัง (yang) = yet / अभी तक"),
        ],
        154: [
            WordForm(thai: "นี่อะไร", romanization: "nîi à-rai", english: "What is this?", hindi: "यह क्या है?", note: "อะไร (à-rai) = what / क्या"),
        ],
        155: [
            WordForm(thai: "นั่นอะไร", romanization: "nân-à-rai", english: "what is that?", hindi: "वह क्या है?", note: "อะไร (à-rai) = what / क्या"),
            WordForm(thai: "นั่นแหละ", romanization: "nân-làe", english: "exactly / that's it", hindi: "बिल्कुल वही / वही तो", note: "แหละ (làe) = emphasis particle / ज़ोर देने वाला कण"),
        ],
        156: [
            WordForm(thai: "ลูกหมา", romanization: "lûuk-mǎa", english: "puppy", hindi: "पिल्ला", note: "ลูก (lûuk) = child, offspring (here: baby animal) / बच्चा (यहाँ: जानवर का बच्चा)"),
        ],
        157: [
            WordForm(thai: "ลูกแมว", romanization: "lûuk maeo", english: "kitten", hindi: "बिल्ली का बच्चा", note: "ลูก (lûuk) = baby (of an animal) / जानवर का बच्चा"),
        ],
        159: [
            WordForm(thai: "ปลาทอด", romanization: "plaa thôot", english: "fried fish", hindi: "तली हुई मछली", note: "ทอด (thôot) = deep-fried / तला हुआ"),
            WordForm(thai: "น้ำปลา", romanization: "náam-plaa", english: "fish sauce", hindi: "फ़िश सॉस", note: "น้ำ (náam) = water, liquid / पानी"),
        ],
        160: [
            WordForm(thai: "ขี่ช้าง", romanization: "khìi cháang", english: "to ride an elephant", hindi: "हाथी की सवारी करना", note: "ขี่ (khìi) = to ride / सवारी करना"),
        ],
        161: [
            WordForm(thai: "น้ำผลไม้", romanization: "náam-phǒn-lá-mái", english: "fruit juice", hindi: "फलों का रस / जूस", note: "น้ำ (náam) = water, juice / पानी, रस"),
        ],
        162: [
            WordForm(thai: "กินผัก", romanization: "kin-phàk", english: "to eat vegetables", hindi: "सब्ज़ी खाना", note: "กิน (kin) = to eat / खाना"),
            WordForm(thai: "ผัดผัก", romanization: "phàt-phàk", english: "stir-fried vegetables", hindi: "भुनी हुई सब्ज़ियाँ", note: "ผัด (phàt) = to stir-fry / भूनना"),
        ],
        163: [
            WordForm(thai: "ไก่ทอด", romanization: "kài thôot", english: "fried chicken", hindi: "फ्राइड चिकन", note: "ทอด (thôot) = deep-fried / तला हुआ"),
            WordForm(thai: "ไก่ย่าง", romanization: "kài yâang", english: "grilled chicken", hindi: "भुना हुआ चिकन (ग्रिल्ड)", note: "ย่าง (yâang) = grilled / भुना हुआ"),
        ],
        164: [
            WordForm(thai: "ไข่ดาว", romanization: "khài daao", english: "fried egg (sunny-side up)", hindi: "फ्राइड अंडा (सनी साइड अप)", note: "ดาว (daao) = star / तारा"),
            WordForm(thai: "ไข่เจียว", romanization: "khài jiao", english: "Thai omelette", hindi: "थाई ऑमलेट", note: "เจียว (jiao) = to fry a beaten egg / फेंटकर तलना"),
        ],
        165: [
            WordForm(thai: "นมสด", romanization: "nom-sòt", english: "fresh milk", hindi: "ताज़ा दूध", note: "สด (sòt) = fresh / ताज़ा"),
            WordForm(thai: "ชานม", romanization: "chaa-nom", english: "milk tea", hindi: "दूध वाली चाय", note: "ชา (chaa) = tea / चाय"),
        ],
        166: [
            WordForm(thai: "ไม่ใส่น้ำตาล", romanization: "mâi sài nám-taan", english: "no sugar (in it), please", hindi: "चीनी मत डालिए", note: "ไม่ใส่ (mâi sài) = don't put in / नहीं डालना"),
            WordForm(thai: "สีน้ำตาล", romanization: "sǐi nám-taan", english: "brown (color)", hindi: "भूरा रंग", note: "สี (sǐi) = color / रंग; lit. \"sugar color\" / शाब्दिक: चीनी का रंग"),
        ],
        167: [
            WordForm(thai: "ใส่เกลือ", romanization: "sài-kluea", english: "to add salt", hindi: "नमक डालना", note: "ใส่ (sài) = to put in, add / डालना"),
        ],
        168: [
            WordForm(thai: "แกงเขียวหวาน", romanization: "kaeng-khǐao-wǎan", english: "green curry", hindi: "ग्रीन करी", note: "เขียว (khǐao) = green, หวาน (wǎan) = sweet / हरा, मीठा"),
            WordForm(thai: "แกงเผ็ด", romanization: "kaeng-phèt", english: "spicy red curry", hindi: "तीखी करी", note: "เผ็ด (phèt) = spicy / तीखा"),
        ],
        169: [
            WordForm(thai: "ก๋วยเตี๋ยวน้ำ", romanization: "kǔai-tǐao náam", english: "noodle soup", hindi: "शोरबे वाले नूडल्स", note: "น้ำ (náam) = water, soup / शोरबा"),
            WordForm(thai: "ก๋วยเตี๋ยวแห้ง", romanization: "kǔai-tǐao hâeng", english: "dry noodles (no soup)", hindi: "बिना शोरबे के नूडल्स", note: "แห้ง (hâeng) = dry / सूखा"),
        ],
        171: [
            WordForm(thai: "เรียกตำรวจ", romanization: "rîak tam-rùat", english: "call the police!", hindi: "पुलिस बुलाओ!", note: "เรียก (rîak) = to call / बुलाना"),
            WordForm(thai: "สถานีตำรวจ", romanization: "sà-thǎa-nii tam-rùat", english: "police station", hindi: "पुलिस थाना", note: "สถานี (sà-thǎa-nii) = station / थाना, स्टेशन"),
        ],
        172: [
            WordForm(thai: "อันตรายมาก", romanization: "an-tà-raai mâak", english: "very dangerous", hindi: "बहुत खतरनाक", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่อันตราย", romanization: "mâi an-tà-raai", english: "not dangerous", hindi: "खतरनाक नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "อันตรายไหม", romanization: "an-tà-raai mǎi", english: "Is it dangerous?", hindi: "क्या यह खतरनाक है?", note: "ไหม (mǎi) = question particle / प्रश्न कण"),
        ],
        173: [
            WordForm(thai: "ระวังตัว", romanization: "rá-wang-tua", english: "take care of yourself / be careful", hindi: "अपना ख़याल रखना", note: "ตัว (tua) = self, body / खुद"),
            WordForm(thai: "ระวังนะ", romanization: "rá-wang-ná", english: "be careful, okay?", hindi: "सावधान रहना, ठीक?", note: "นะ (ná) = softening particle / नरमी का कण"),
        ],
        174: [
            WordForm(thai: "โทรศัพท์มือถือ", romanization: "thoo-rá-sàp-muue-thǔue", english: "mobile phone", hindi: "मोबाइल फ़ोन", note: "มือถือ (muue-thǔue) = hand-held / हाथ में रखने वाला"),
            WordForm(thai: "เบอร์โทรศัพท์", romanization: "boe-thoo-rá-sàp", english: "phone number", hindi: "फ़ोन नंबर", note: "เบอร์ (boe) = number / नंबर"),
        ],
        175: [
            WordForm(thai: "เลี้ยวซ้าย", romanization: "líao sáai", english: "turn left", hindi: "बाएँ मुड़िए", note: "เลี้ยว (líao) = to turn / मुड़ना"),
            WordForm(thai: "มือซ้าย", romanization: "muue sáai", english: "left hand", hindi: "बायाँ हाथ", note: "มือ (muue) = hand / हाथ"),
        ],
        176: [
            WordForm(thai: "เลี้ยวขวา", romanization: "líao khwǎa", english: "turn right", hindi: "दाएँ मुड़िए", note: "เลี้ยว (líao) = to turn / मुड़ना"),
            WordForm(thai: "ข้างขวา", romanization: "khâang khwǎa", english: "on the right side", hindi: "दाईं ओर", note: "ข้าง (khâang) = side / ओर"),
        ],
        177: [
            WordForm(thai: "ตรงไปเรื่อย ๆ", romanization: "trong-pai rûeai-rûeai", english: "keep going straight", hindi: "सीधे जाते रहिए", note: "เรื่อย ๆ (rûeai-rûeai) = continuously, keep on / लगातार"),
        ],
        178: [
            WordForm(thai: "มาที่นี่", romanization: "maa thîi-nîi", english: "come here", hindi: "यहाँ आओ", note: "มา (maa) = to come / आना"),
            WordForm(thai: "อยู่ที่นี่", romanization: "yùu thîi-nîi", english: "to be / stay here", hindi: "यहाँ रहना / होना", note: "อยู่ (yùu) = to be at, stay / रहना"),
        ],
        180: [
            WordForm(thai: "อยู่ข้างบน", romanization: "yùu-khâang-bon", english: "it's upstairs / up there", hindi: "ऊपर है", note: "อยู่ (yùu) = to be at (location) / होना (स्थान पर)"),
        ],
        181: [
            WordForm(thai: "อยู่ข้างล่าง", romanization: "yùu khâang-lâang", english: "it's downstairs / below", hindi: "नीचे है", note: "อยู่ (yùu) = to be (located) / (स्थान पर) होना"),
        ],
        182: [
            WordForm(thai: "ใส่น้ำแข็ง", romanization: "sài nám-khǎeng", english: "with ice (add ice)", hindi: "बर्फ़ डालकर", note: "ใส่ (sài) = to put in, add / डालना"),
            WordForm(thai: "ไม่ใส่น้ำแข็ง", romanization: "mâi sài nám-khǎeng", english: "no ice, please", hindi: "बिना बर्फ़ के", note: "ไม่ใส่ (mâi sài) = without adding / बिना डाले"),
        ],
        183: [
            WordForm(thai: "ข้าวผัดกุ้ง", romanization: "khâao-phàt kûng", english: "shrimp fried rice", hindi: "झींगा फ्राइड राइस", note: "กุ้ง (kûng) = shrimp / झींगा"),
            WordForm(thai: "ข้าวผัดไก่", romanization: "khâao-phàt kài", english: "chicken fried rice", hindi: "चिकन फ्राइड राइस", note: "ไก่ (kài) = chicken / मुर्गी"),
        ],
        184: [
            WordForm(thai: "น้ำส้มคั้น", romanization: "nám-sôm-khán", english: "freshly squeezed orange juice", hindi: "ताज़ा निचोड़ा हुआ संतरे का रस", note: "คั้น (khán) = squeezed / निचोड़ा हुआ"),
        ],
        185: [
            WordForm(thai: "เปิดไฟ", romanization: "pòet-fai", english: "to turn on the light", hindi: "बत्ती जलाना", note: "เปิด (pòet) = to open, turn on / खोलना, चालू करना"),
            WordForm(thai: "ปิดไฟ", romanization: "pìt-fai", english: "to turn off the light", hindi: "बत्ती बंद करना", note: "ปิด (pìt) = to close, turn off / बंद करना"),
        ],
        186: [
            WordForm(thai: "สถานีรถไฟ", romanization: "sà-thǎa-nii-rót-fai", english: "train station", hindi: "रेलवे स्टेशन", note: "สถานี (sà-thǎa-nii) = station / स्टेशन"),
            WordForm(thai: "นั่งรถไฟ", romanization: "nâng-rót-fai", english: "to take the train", hindi: "ट्रेन से जाना", note: "นั่ง (nâng) = to sit, ride / बैठना, सवारी करना"),
        ],
        40: [
            WordForm(thai: "สวยมาก", romanization: "sǔai mâak", english: "very beautiful", hindi: "बहुत सुंदर", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่สวย", romanization: "mâi sǔai", english: "not beautiful", hindi: "सुंदर नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "สวยที่สุด", romanization: "sǔai thîi-sùt", english: "most beautiful", hindi: "सबसे सुंदर", note: "ที่สุด (thîi-sùt) = most / सबसे"),
        ],
    ]

    /// Template sentences for grammatically uniform categories, so every
    /// number, color, place, animal, and family word has "Sentence Use"
    /// even without a hand-written entry.
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

    /// How Thai numbers combine: X + สิบ → X-ten (60), สิบ + X → teen (16),
    /// with the two irregulars (เอ็ด for 1, ยี่ for 20).
    private static let numberCompounds: [Int: String] = [
        11: "สิบ (sìp) 10 + เอ็ด (èt) → สิบเอ็ด (sìp-èt) = 11 / ग्यारह — ध्यान दें: 11 में หนึ่ง बदलकर เอ็ด बनता है · หนึ่ง + ร้อย (rói) → หนึ่งร้อย (nèung-rói) = 100 / सौ",
        12: "สอง + สิบ → ยี่สิบ (yîi-sìp) = 20 / बीस — ध्यान दें: 20 में สอง बदलकर ยี่ बनता है · สิบ + สอง → สิบสอง (sìp-sǒong) = 12 / बारह",
        13: "สาม + สิบ → สามสิบ (sǎam-sìp) = 30 / तीस · สิบ + สาม → สิบสาม (sìp-sǎam) = 13 / तेरह",
        14: "สี่ + สิบ → สี่สิบ (sìi-sìp) = 40 / चालीस · สิบ + สี่ → สิบสี่ (sìp-sìi) = 14 / चौदह",
        15: "ห้า + สิบ → ห้าสิบ (hâa-sìp) = 50 / पचास · สิบ + ห้า → สิบห้า (sìp-hâa) = 15 / पंद्रह",
        16: "หก + สิบ → หกสิบ (hòk-sìp) = 60 / साठ · สิบ + หก → สิบหก (sìp-hòk) = 16 / सोलह",
        17: "เจ็ด + สิบ → เจ็ดสิบ (jèt-sìp) = 70 / सत्तर · สิบ + เจ็ด → สิบเจ็ด (sìp-jèt) = 17 / सत्रह",
        18: "แปด + สิบ → แปดสิบ (pàet-sìp) = 80 / अस्सी · สิบ + แปด → สิบแปด (sìp-pàet) = 18 / अठारह",
        19: "เก้า + สิบ → เก้าสิบ (kâo-sìp) = 90 / नब्बे · สิบ + เก้า → สิบเก้า (sìp-kâo) = 19 / उन्नीस",
        20: "หก + สิบ → หกสิบ (hòk-sìp) = 60 / साठ · สิบ + ห้า → สิบห้า (sìp-hâa) = 15 / पंद्रह — สิบ हर बड़ी संख्या का आधार है",
    ]

    /// Words that sound alike but mean something different — a classic
    /// Thai-learner trap (tones change the meaning).
    static func similarSounds(for word: ThaiWord) -> [ThaiWord] {
        (similar[word.id] ?? []).compactMap { id in Vocabulary.all.first { $0.id == id } }
    }

    private static let similar: [Int: [Int]] = [
        6: [134],
        14: [83],
        19: [135],
        28: [85],
        32: [137],
        34: [73],
        36: [80, 156],
        46: [102],
        57: [137],
        60: [66],
        61: [124],
        66: [60],
        73: [34],
        77: [116],
        78: [79],
        79: [78],
        80: [36, 156],
        83: [14],
        85: [28],
        87: [118],
        102: [46],
        112: [164],
        116: [77],
        118: [87],
        124: [61],
        127: [152],
        132: [133],
        133: [132],
        134: [6],
        135: [19],
        137: [32, 57],
        143: [144],
        144: [143],
        146: [179],
        152: [127],
        156: [36, 80],
        163: [164],
        164: [112, 163],
        178: [179],
        179: [146, 178],
    ]

    private static let examples0: [Int: [WordExample]] = [
        425: [
            WordExample(thai: "บ้านนี้ใหญ่มาก", romanization: "bâan níi yài mâak", english: "This house is very big.", hindi: "यह घर बहुत बड़ा है।"),
            WordExample(thai: "ร้านนี้ดีมาก", romanization: "ráan níi dii mâak", english: "This shop is very good.", hindi: "यह दुकान बहुत अच्छी है।"),
        ],
        426: [
            WordExample(thai: "ขอกาแฟสองแก้วครับ", romanization: "khǒo kaa-fae sǒong kâew kráp", english: "Two coffees, please.", hindi: "दो गिलास कॉफ़ी दीजिए।"),
            WordExample(thai: "ขอน้ำแข็งค่ะ", romanization: "khǒo nám-khǎeng khâ", english: "May I have some ice?", hindi: "थोड़ी बर्फ़ दीजिए।"),
        ],
        427: [
            WordExample(thai: "คุณหิวไหม", romanization: "khun hǐu mǎi", english: "Are you hungry?", hindi: "क्या आपको भूख लगी है?"),
            WordExample(thai: "อาหารอร่อยไหม", romanization: "aa-hǎan à-ròi mǎi", english: "Is the food tasty?", hindi: "क्या खाना स्वादिष्ट है?"),
        ],
        428: [
            WordExample(thai: "ช่วยหน่อยครับ", romanization: "chûai nòi kráp", english: "Please help me a bit.", hindi: "ज़रा मदद कीजिए।"),
            WordExample(thai: "รอหน่อยนะ", romanization: "roo nòi ná", english: "Wait a moment, okay?", hindi: "ज़रा रुकिए, ठीक है?"),
        ],
        429: [
            WordExample(thai: "ผมชอบอาหารไทย", romanization: "phǒm chôp aa-hǎan thai", english: "I like Thai food.", hindi: "मुझे थाई खाना पसंद है।"),
            WordExample(thai: "เขาเป็นคนไทย", romanization: "khǎo pen khon thai", english: "He is Thai.", hindi: "वह थाई है।"),
        ],
        430: [
            WordExample(thai: "วันนี้ฝนตกมาก", romanization: "wan-níi fǒn tòk mâak", english: "It's raining a lot today.", hindi: "आज बहुत बारिश हो रही है।"),
            WordExample(thai: "ฝนตกทุกวัน", romanization: "fǒn tòk thúk-wan", english: "It rains every day.", hindi: "हर दिन बारिश होती है।"),
        ],
        431: [
            WordExample(thai: "เราไปกินข้าวกัน", romanization: "rao pai kin khâao kan", english: "Let's go eat together.", hindi: "चलो साथ में खाना खाएँ।"),
            WordExample(thai: "เขาเจอกันที่ตลาด", romanization: "khǎo joe kan thîi tà-làat", english: "They met each other at the market.", hindi: "वे बाज़ार में एक-दूसरे से मिले।"),
        ],
        432: [
            WordExample(thai: "นี่คืออะไร", romanization: "nîi khuue à-rai", english: "What is this?", hindi: "यह क्या है?"),
            WordExample(thai: "เขาคือเพื่อนของผม", romanization: "khǎo khuue phûean khǒong phǒm", english: "He is my friend.", hindi: "वह मेरा दोस्त है।"),
        ],
        433: [
            WordExample(thai: "อย่าลืมนะ", romanization: "yàa luem ná", english: "Don't forget, okay?", hindi: "भूलना मत, ठीक है?"),
            WordExample(thai: "อย่าไปที่นั่น", romanization: "yàa pai thîi-nân", english: "Don't go there.", hindi: "वहाँ मत जाओ।"),
        ],
        434: [
            WordExample(thai: "ตอนเช้าผมดื่มกาแฟ", romanization: "toon cháo phǒm dùem kaa-fae", english: "In the morning I drink coffee.", hindi: "सुबह मैं कॉफ़ी पीता हूँ।"),
            WordExample(thai: "เขามาตอนเย็น", romanization: "khǎo maa toon yen", english: "He comes in the evening.", hindi: "वह शाम को आता है।"),
        ],
        435: [
            WordExample(thai: "แมวนอนบนเตียง", romanization: "maew noon bon tiang", english: "The cat sleeps on the bed.", hindi: "बिल्ली बिस्तर पर सोती है।"),
            WordExample(thai: "มือถืออยู่บนโต๊ะ", romanization: "muue-thǔue yùu bon tó", english: "The phone is on the table.", hindi: "मोबाइल मेज़ पर है।"),
        ],
        436: [
            WordExample(thai: "ห้องน้ำอยู่ไหน", romanization: "hôong-náam yùu nǎi", english: "Where is the bathroom?", hindi: "शौचालय कहाँ है?"),
            WordExample(thai: "คุณอยู่ที่ไหน", romanization: "khun yùu thîi-nǎi", english: "Where are you?", hindi: "आप कहाँ हैं?"),
        ],
        437: [
            WordExample(thai: "ผมล้างมือก่อนกินข้าว", romanization: "phǒm láang muue kòon kin khâao", english: "I wash my hands before eating.", hindi: "मैं खाने से पहले हाथ धोता हूँ।"),
            WordExample(thai: "ฉันล้างจานทุกวัน", romanization: "chǎn láang jaan thúk-wan", english: "I wash the dishes every day.", hindi: "मैं हर दिन बर्तन धोती हूँ।"),
        ],
        438: [
            WordExample(thai: "เลี้ยวซ้ายที่ธนาคาร", romanization: "líao sáai thîi thá-naa-khaan", english: "Turn left at the bank.", hindi: "बैंक पर बाएँ मुड़िए।"),
            WordExample(thai: "เลี้ยวขวาแล้วตรงไป", romanization: "líao khwǎa láew trong-pai", english: "Turn right, then go straight.", hindi: "दाएँ मुड़िए, फिर सीधे जाइए।"),
        ],
        439: [
            WordExample(thai: "ไม่แพงเลย", romanization: "mâi phaeng loei", english: "Not expensive at all.", hindi: "बिल्कुल महँगा नहीं है।"),
            WordExample(thai: "อาหารอร่อยมากเลย", romanization: "aa-hǎan à-ròi mâak loei", english: "The food is really delicious!", hindi: "खाना सच में बहुत स्वादिष्ट है!"),
        ],
        440: [
            WordExample(thai: "ผมชอบอ่านหนังสือ", romanization: "phǒm chôp àan nǎng-sǔue", english: "I like reading books.", hindi: "मुझे किताबें पढ़ना पसंद है।"),
            WordExample(thai: "เขาซื้อหนังสือสองเล่ม", romanization: "khǎo súue nǎng-sǔue sǒong lêm", english: "He bought two books.", hindi: "उसने दो किताबें खरीदीं।"),
        ],
        441: [
            WordExample(thai: "คุณอายุเท่าไหร่", romanization: "khun aa-yú thâo-rài", english: "How old are you?", hindi: "आपकी उम्र कितनी है?"),
            WordExample(thai: "ลูกของฉันอายุห้าปี", romanization: "lûuk khǒong chǎn aa-yú hâa pii", english: "My child is five years old.", hindi: "मेरा बच्चा पाँच साल का है।"),
        ],
        442: [
            WordExample(thai: "กระเป๋าหนัก ผมยกไม่ได้", romanization: "krà-pǎo nàk phǒm yók mâi dâi", english: "The bag is heavy — I can't lift it.", hindi: "बैग भारी है — मैं उठा नहीं सकता।"),
            WordExample(thai: "เขายกมือถาม", romanization: "khǎo yók muue thǎam", english: "He raises his hand to ask.", hindi: "वह पूछने के लिए हाथ उठाता है।"),
        ],
        443: [
            WordExample(thai: "ค่าห้องเท่าไหร่", romanization: "khâa hôong thâo-rài", english: "How much is the room charge?", hindi: "कमरे का किराया कितना है?"),
            WordExample(thai: "ค่ารถแพงมาก", romanization: "khâa rót phaeng mâak", english: "The fare is very expensive.", hindi: "किराया बहुत महँगा है।"),
        ],
        444: [
            WordExample(thai: "เอากาแฟอีกแก้ว", romanization: "ao kaa-fae ìik kâew", english: "One more coffee, please.", hindi: "एक और गिलास कॉफ़ी दीजिए।"),
            WordExample(thai: "พรุ่งนี้มาอีกนะ", romanization: "phrûng-níi maa ìik ná", english: "Come again tomorrow, okay?", hindi: "कल फिर आना, ठीक है?"),
        ],
        445: [
            WordExample(thai: "เสื้อแห้งแล้ว", romanization: "sûea hâeng láew", english: "The shirt is already dry.", hindi: "शर्ट सूख गई है।"),
            WordExample(thai: "อากาศร้อนและแห้ง", romanization: "aa-kàat róon láe hâeng", english: "The weather is hot and dry.", hindi: "मौसम गरम और सूखा है।"),
        ],
        446: [
            WordExample(thai: "คุณเลิกงานกี่โมง", romanization: "khun lôek ngaan kìi-mohng", english: "What time do you finish work?", hindi: "आप कितने बजे काम से छूटते हैं?"),
            WordExample(thai: "ผมเลิกงานแล้ว", romanization: "phǒm lôek ngaan láew", english: "I've already finished work.", hindi: "मेरा काम ख़त्म हो गया है।"),
        ],
        447: [
            WordExample(thai: "ผมมีรถหนึ่งคัน", romanization: "phǒm mii rót nèung khan", english: "I have one car.", hindi: "मेरे पास एक गाड़ी है।"),
            WordExample(thai: "รถสองคันอยู่ที่บ้าน", romanization: "rót sǒong khan yùu thîi bâan", english: "Two cars are at the house.", hindi: "दो गाड़ियाँ घर पर हैं।"),
        ],
        448: [
            WordExample(thai: "ผมมาจากอินเดีย", romanization: "phǒm maa jàak in-dia", english: "I come from India.", hindi: "मैं भारत से आया हूँ।"),
            WordExample(thai: "อาหารอินเดียเผ็ดมาก", romanization: "aa-hǎan in-dia phèt mâak", english: "Indian food is very spicy.", hindi: "भारतीय खाना बहुत तीखा होता है।"),
        ],
        449: [
            WordExample(thai: "พรุ่งนี้เราไปเชียงใหม่", romanization: "phrûng-níi rao pai chiang-mài", english: "Tomorrow we go to Chiang Mai.", hindi: "कल हम चियांग माई जाएँगे।"),
            WordExample(thai: "อากาศที่เชียงใหม่ดีมาก", romanization: "aa-kàat thîi chiang-mài dii mâak", english: "The weather in Chiang Mai is very good.", hindi: "चियांग माई का मौसम बहुत अच्छा है।"),
        ],
        450: [
            WordExample(thai: "ผมอยู่ที่กรุงเทพ", romanization: "phǒm yùu thîi krung-thêep", english: "I live in Bangkok.", hindi: "मैं बैंकॉक में रहता हूँ।"),
            WordExample(thai: "เขาทำงานที่กรุงเทพ", romanization: "khǎo tham-ngaan thîi krung-thêep", english: "He works in Bangkok.", hindi: "वह बैंकॉक में काम करता है।"),
        ],
        223: [
            WordExample(thai: "เราไปตลาดด้วยกัน", romanization: "rao pai tà-làat dûai-kan", english: "We go to the market together.", hindi: "हम साथ में बाज़ार जाते हैं।"),
            WordExample(thai: "เราหิวมาก", romanization: "rao hǐu mâak", english: "We are very hungry.", hindi: "हमें बहुत भूख लगी है।"),
        ],
        224: [
            WordExample(thai: "เขาเป็นครู", romanization: "khǎo pen khruu", english: "He is a teacher.", hindi: "वह शिक्षक है।"),
            WordExample(thai: "เขาชอบกาแฟ", romanization: "khǎo chôop kaa-fae", english: "She likes coffee.", hindi: "उसे कॉफ़ी पसंद है।"),
        ],
        225: [
            WordExample(thai: "มันแพงมาก", romanization: "man phaeng mâak", english: "It is very expensive.", hindi: "यह बहुत महँगा है।"),
            WordExample(thai: "มันอร่อย", romanization: "man à-ròi", english: "It is delicious.", hindi: "यह स्वादिष्ट है।"),
        ],
        226: [
            WordExample(thai: "นี่กระเป๋าของฉัน", romanization: "nîi krà-pǎo khǒong chǎn", english: "This is my bag.", hindi: "यह मेरा बैग है।"),
            WordExample(thai: "บ้านของเขาใหญ่", romanization: "bâan khǒong khǎo yài", english: "His house is big.", hindi: "उसका घर बड़ा है।"),
        ],
        227: [
            WordExample(thai: "แมวอยู่ในบ้าน", romanization: "maew yùu nai bâan", english: "The cat is in the house.", hindi: "बिल्ली घर में है।"),
            WordExample(thai: "ในกระเป๋ามีเงิน", romanization: "nai krà-pǎo mii ngern", english: "There is money in the bag.", hindi: "बैग में पैसे हैं।"),
        ],
        228: [
            WordExample(thai: "ผมมาจากอินเดีย", romanization: "phǒm maa jàak in-dia", english: "I come from India.", hindi: "मैं भारत से आया हूँ।"),
            WordExample(thai: "เขามาจากเชียงใหม่", romanization: "khǎo maa jàak chiang-mài", english: "He comes from Chiang Mai.", hindi: "वह चियांग माई से आया है।"),
        ],
        229: [
            WordExample(thai: "เราถึงโรงแรมแล้ว", romanization: "rao thǔeng roong-raem láew", english: "We have arrived at the hotel.", hindi: "हम होटल पहुँच गए हैं।"),
            WordExample(thai: "รอถึงพรุ่งนี้ได้ไหม", romanization: "roo thǔeng phrûng-níi dâi mǎi", english: "Can you wait until tomorrow?", hindi: "क्या कल तक इंतज़ार कर सकते हैं?"),
        ],
        230: [
            WordExample(thai: "พรุ่งนี้ฉันจะไปตลาด", romanization: "phrûng-níi chǎn jà pai tà-làat", english: "Tomorrow I will go to the market.", hindi: "कल मैं बाज़ार जाऊँगी।"),
            WordExample(thai: "เขาจะมาที่นี่", romanization: "khǎo jà maa thîi-nîi", english: "He will come here.", hindi: "वह यहाँ आएगा।"),
        ],
        231: [
            WordExample(thai: "คุณพูดไทยได้ไหม", romanization: "khun phûut thai dâi mǎi", english: "Can you speak Thai?", hindi: "क्या आप थाई बोल सकते हैं?"),
            WordExample(thai: "ฉันไปได้", romanization: "chǎn pai dâi", english: "I can go.", hindi: "मैं जा सकती हूँ।"),
        ],
        232: [
            WordExample(thai: "ผมเป็นหมอ", romanization: "phǒm pen mǒo", english: "I am a doctor.", hindi: "मैं डॉक्टर हूँ।"),
            WordExample(thai: "เขาเป็นเพื่อนของฉัน", romanization: "khǎo pen phûean khǒong chǎn", english: "He is my friend.", hindi: "वह मेरा दोस्त है।"),
        ],
        233: [
            WordExample(thai: "คุณอยู่ที่ไหน", romanization: "khun yùu thîi-nǎi", english: "Where are you?", hindi: "आप कहाँ हैं?"),
            WordExample(thai: "ฉันอยู่บ้าน", romanization: "chǎn yùu bâan", english: "I am at home.", hindi: "मैं घर पर हूँ।"),
        ],
        234: [
            WordExample(thai: "ฉันมีลูกสองคน", romanization: "chǎn mii lûuk sǒong khon", english: "I have two children.", hindi: "मेरे दो बच्चे हैं।"),
            WordExample(thai: "มีห้องน้ำไหม", romanization: "mii hôong-náam mǎi", english: "Is there a bathroom?", hindi: "क्या यहाँ शौचालय है?"),
        ],
        235: [
            WordExample(thai: "ฉันกินกาแฟทุกวัน", romanization: "chǎn kin kaa-fae thúk wan", english: "I drink coffee every day.", hindi: "मैं हर दिन कॉफ़ी पीती हूँ।"),
            WordExample(thai: "ทุกคนชอบอาหารไทย", romanization: "thúk khon chôop aa-hǎan thai", english: "Everyone likes Thai food.", hindi: "सबको थाई खाना पसंद है।"),
        ],
        236: [
            WordExample(thai: "บางคนไม่ชอบเผ็ด", romanization: "baang khon mâi chôop phèt", english: "Some people don't like spicy food.", hindi: "कुछ लोग तीखा पसंद नहीं करते।"),
            WordExample(thai: "บางวันฝนตก", romanization: "baang wan fǒn tòk", english: "Some days it rains.", hindi: "कुछ दिनों में बारिश होती है।"),
        ],
        237: [
            WordExample(thai: "ฉันก็ชอบ", romanization: "chǎn kô chôop", english: "I like it too.", hindi: "मुझे भी पसंद है।"),
            WordExample(thai: "เขาไป ฉันก็ไป", romanization: "khǎo pai chǎn kô pai", english: "He goes, so I go too.", hindi: "वह जाता है तो मैं भी जाती हूँ।"),
        ],
        238: [
            WordExample(thai: "ฉันยังหิว", romanization: "chǎn yang hǐu", english: "I am still hungry.", hindi: "मुझे अभी भी भूख लगी है।"),
            WordExample(thai: "เขายังไม่มา", romanization: "khǎo yang mâi maa", english: "He has not come yet.", hindi: "वह अभी तक नहीं आया।"),
        ],
        239: [
            WordExample(thai: "ฉันไปกับเพื่อน", romanization: "chǎn pai kàp phûean", english: "I go with a friend.", hindi: "मैं दोस्त के साथ जाती हूँ।"),
            WordExample(thai: "กินข้าวกับแกงไหม", romanization: "kin khâao kàp kaeng mǎi", english: "Will you eat rice with curry?", hindi: "चावल करी के साथ खाओगे?"),
        ],
        240: [
            WordExample(thai: "เขาทำงานที่โรงพยาบาล", romanization: "khǎo tham-ngaan thîi roong-phá-yaa-baan", english: "He works at the hospital.", hindi: "वह अस्पताल में काम करता है।"),
            WordExample(thai: "ฉันรอที่ร้านกาแฟ", romanization: "chǎn roo thîi ráan kaa-fae", english: "I am waiting at the coffee shop.", hindi: "मैं कॉफ़ी शॉप पर इंतज़ार कर रही हूँ।"),
        ],
        241: [
            WordExample(thai: "ฉันกินข้าวแล้ว", romanization: "chǎn kin khâao láew", english: "I have already eaten.", hindi: "मैं खाना खा चुकी हूँ।"),
            WordExample(thai: "เขาไปแล้ว", romanization: "khǎo pai láew", english: "He has already left.", hindi: "वह जा चुका है।"),
        ],
        242: [
            WordExample(thai: "ฉันต้องไปทำงาน", romanization: "chǎn tôong pai tham-ngaan", english: "I have to go to work.", hindi: "मुझे काम पर जाना है।"),
            WordExample(thai: "คุณต้องรอที่นี่", romanization: "khun tôong roo thîi-nîi", english: "You must wait here.", hindi: "आपको यहाँ इंतज़ार करना होगा।"),
        ],
        243: [
            WordExample(thai: "ฉันอยากกินผัดไทย", romanization: "chǎn yàak kin phàt-thai", english: "I want to eat pad thai.", hindi: "मैं पैड थाई खाना चाहती हूँ।"),
            WordExample(thai: "เขาอยากไปทะเล", romanization: "khǎo yàak pai thá-lee", english: "He wants to go to the sea.", hindi: "वह समुद्र जाना चाहता है।"),
        ],
        244: [
            WordExample(thai: "แม่ให้เงินลูก", romanization: "mâe hâi ngern lûuk", english: "Mother gives money to the child.", hindi: "माँ बच्चे को पैसे देती है।"),
            WordExample(thai: "เขาซื้อกาแฟให้ฉัน", romanization: "khǎo súe kaa-fae hâi chǎn", english: "He buys coffee for me.", hindi: "वह मेरे लिए कॉफ़ी खरीदता है।"),
        ],
        245: [
            WordExample(thai: "เขาพูดว่าจะมา", romanization: "khǎo phûut wâa jà maa", english: "He said that he will come.", hindi: "उसने कहा कि वह आएगा।"),
            WordExample(thai: "ฉันคิดว่าอร่อย", romanization: "chǎn khít wâa à-ròi", english: "I think that it is delicious.", hindi: "मुझे लगता है कि यह स्वादिष्ट है।"),
        ],
        246: [
            WordExample(thai: "ฉันไปด้วย", romanization: "chǎn pai dûai", english: "I am going too.", hindi: "मैं भी जा रही हूँ।"),
            WordExample(thai: "ขอน้ำด้วย", romanization: "khǒo náam dûai", english: "Please bring water too.", hindi: "पानी भी दीजिए।"),
        ],
        247: [
            WordExample(thai: "ฉันไปก่อนนะ", romanization: "chǎn pai kòon ná", english: "I'm leaving now, okay?", hindi: "मैं अब चलती हूँ, ठीक है ना?"),
            WordExample(thai: "รอหน่อยนะ", romanization: "roo nòi ná", english: "Wait a moment, okay?", hindi: "थोड़ा रुको ना।"),
        ],
        248: [
            WordExample(thai: "เอาอันนี้ครับ", romanization: "ao an níi khráp", english: "I'll take this one.", hindi: "यह वाला दीजिए।"),
            WordExample(thai: "เอากาแฟไหม", romanization: "ao kaa-fae mái", english: "Do you want coffee?", hindi: "कॉफ़ी लेंगे?"),
        ],
        249: [
            WordExample(thai: "ผมดื่มกาแฟทุกเช้า", romanization: "phǒm dùem kaa-fae thúk cháao", english: "I drink coffee every morning.", hindi: "मैं हर सुबह कॉफ़ी पीता हूँ।"),
            WordExample(thai: "ฉันไม่ดื่มชา", romanization: "chǎn mâi dùem chaa", english: "I don't drink tea.", hindi: "मैं चाय नहीं पीती।"),
        ],
        250: [
            WordExample(thai: "ผมใช้โทรศัพท์ทุกวัน", romanization: "phǒm chái thoo-rá-sàp thúk wan", english: "I use my phone every day.", hindi: "मैं रोज़ फ़ोन इस्तेमाल करता हूँ।"),
            WordExample(thai: "ใช้ยังไง", romanization: "chái yang-ngai", english: "How do I use it?", hindi: "यह कैसे इस्तेमाल करते हैं?"),
        ],
        251: [
            WordExample(thai: "ผมหากระเป๋าไม่เจอ", romanization: "phǒm hǎa krà-pǎo mâi jer", english: "I can't find my bag.", hindi: "मुझे मेरा बैग नहीं मिल रहा।"),
            WordExample(thai: "คุณหาอะไร", romanization: "khun hǎa à-rai", english: "What are you looking for?", hindi: "आप क्या ढूँढ रहे हैं?"),
        ],
        252: [
            WordExample(thai: "ผมเห็นแมวที่ตลาด", romanization: "phǒm hěn maew thîi tà-làat", english: "I saw a cat at the market.", hindi: "मैंने बाज़ार में एक बिल्ली देखी।"),
            WordExample(thai: "คุณเห็นไหม", romanization: "khun hěn mái", english: "Do you see it?", hindi: "आपको दिख रहा है?"),
        ],
        253: [
            WordExample(thai: "บอกผมหน่อย", romanization: "bòok phǒm nòi", english: "Please tell me.", hindi: "मुझे बताइए।"),
            WordExample(thai: "แม่บอกว่าอาหารอร่อย", romanization: "mâe bòok wâa aa-hǎan à-ròi", english: "Mom said the food is delicious.", hindi: "माँ ने कहा कि खाना स्वादिष्ट है।"),
        ],
        254: [
            WordExample(thai: "ขอถามหน่อย", romanization: "khǒo thǎam nòi", english: "May I ask something?", hindi: "एक बात पूछूँ?"),
            WordExample(thai: "เขาถามชื่อผม", romanization: "kháo thǎam chûe phǒm", english: "He asked my name.", hindi: "उसने मेरा नाम पूछा।"),
        ],
        255: [
            WordExample(thai: "ผมตอบไม่ได้", romanization: "phǒm tòop mâi dâai", english: "I can't answer.", hindi: "मैं जवाब नहीं दे सकता।"),
            WordExample(thai: "ครูตอบคำถาม", romanization: "khruu tòop kham-thǎam", english: "The teacher answers the question.", hindi: "शिक्षक सवाल का जवाब देते हैं।"),
        ],
        256: [
            WordExample(thai: "เด็กๆ เล่นที่ชายหาด", romanization: "dèk-dèk lên thîi chaai-hàat", english: "The children play at the beach.", hindi: "बच्चे समुद्र-तट पर खेलते हैं।"),
            WordExample(thai: "ผมชอบเล่นโทรศัพท์", romanization: "phǒm chôop lên thoo-rá-sàp", english: "I like playing on my phone.", hindi: "मुझे फ़ोन चलाना पसंद है।"),
        ],
        257: [
            WordExample(thai: "ผมเรียนภาษาไทย", romanization: "phǒm rian phaa-sǎa thai", english: "I study Thai.", hindi: "मैं थाई भाषा सीख रहा हूँ।"),
            WordExample(thai: "น้องเรียนที่โรงเรียน", romanization: "nóong rian thîi roong-rian", english: "My younger sibling studies at school.", hindi: "मेरा छोटा भाई स्कूल में पढ़ता है।"),
        ],
        258: [
            WordExample(thai: "ครูสอนภาษาไทย", romanization: "khruu sǒon phaa-sǎa thai", english: "The teacher teaches Thai.", hindi: "शिक्षक थाई पढ़ाते हैं।"),
            WordExample(thai: "ช่วยสอนผมหน่อย", romanization: "chûai sǒon phǒm nòi", english: "Please teach me.", hindi: "मुझे सिखाइए।"),
        ],
        259: [
            WordExample(thai: "ผมจ่ายเงินแล้ว", romanization: "phǒm jàai ngern láew", english: "I already paid.", hindi: "मैंने पैसे दे दिए।"),
            WordExample(thai: "จ่ายที่ไหน", romanization: "jàai thîi-nǎi", english: "Where do I pay?", hindi: "भुगतान कहाँ करूँ?"),
        ],
        260: [
            WordExample(thai: "ผมจำชื่อคุณได้", romanization: "phǒm jam chûe khun dâai", english: "I remember your name.", hindi: "मुझे आपका नाम याद है।"),
            WordExample(thai: "ฉันจำไม่ได้", romanization: "chǎn jam mâi dâai", english: "I don't remember.", hindi: "मुझे याद नहीं आ रहा।"),
        ],
        261: [
            WordExample(thai: "ผมลืมโทรศัพท์ที่บ้าน", romanization: "phǒm luem thoo-rá-sàp thîi bâan", english: "I forgot my phone at home.", hindi: "मैं फ़ोन घर पर भूल गया।"),
            WordExample(thai: "อย่าลืมนะ", romanization: "yàa luem ná", english: "Don't forget!", hindi: "भूलना मत!"),
        ],
        262: [
            WordExample(thai: "เริ่มกี่โมง", romanization: "rêrm kìi moong", english: "What time does it start?", hindi: "कितने बजे शुरू होगा?"),
            WordExample(thai: "ฝนเริ่มตก", romanization: "fǒn rêrm tòk", english: "It's starting to rain.", hindi: "बारिश शुरू हो रही है।"),
        ],
        263: [
            WordExample(thai: "ทำงานเสร็จแล้ว", romanization: "tham-ngaan sèt láew", english: "I'm done with work.", hindi: "काम ख़त्म हो गया।"),
            WordExample(thai: "เสร็จหรือยัง", romanization: "sèt rǔe yang", english: "Are you done yet?", hindi: "हो गया क्या?"),
        ],
        264: [
            WordExample(thai: "ผมส่งเงินให้แม่", romanization: "phǒm sòng ngern hâi mâe", english: "I send money to mom.", hindi: "मैं माँ को पैसे भेजता हूँ।"),
            WordExample(thai: "ช่วยส่งช้อนให้หน่อย", romanization: "chûai sòng chóon hâi nòi", english: "Please pass me the spoon.", hindi: "ज़रा चम्मच पकड़ा दीजिए।"),
        ],
        265: [
            WordExample(thai: "รับอะไรดีคะ", romanization: "ráp à-rai dii khá", english: "What would you like (to order)?", hindi: "आप क्या लेंगे?"),
            WordExample(thai: "ผมไปรับลูกที่โรงเรียน", romanization: "phǒm pai ráp lûuk thîi roong-rian", english: "I'm going to pick up my child at school.", hindi: "मैं बच्चे को स्कूल से लेने जा रहा हूँ।"),
        ],
        266: [
            WordExample(thai: "ขอเปลี่ยนได้ไหม", romanization: "khǒo plìan dâai mái", english: "Can I change it?", hindi: "क्या मैं इसे बदल सकता हूँ?"),
            WordExample(thai: "อากาศเปลี่ยนเร็ว", romanization: "aa-kàat plìan reo", english: "The weather changes quickly.", hindi: "मौसम जल्दी बदलता है।"),
        ],
        267: [
            WordExample(thai: "เลือกอันไหนดี", romanization: "lûeak an nǎi dii", english: "Which one should I choose?", hindi: "कौन-सा चुनूँ?"),
            WordExample(thai: "ฉันเลือกสีแดง", romanization: "chǎn lûeak sǐi daeng", english: "I choose the red color.", hindi: "मैं लाल रंग चुनती हूँ।"),
        ],
        268: [
            WordExample(thai: "วันนี้ฉันใส่เสื้อสีขาว", romanization: "wan-níi chǎn sài sûea sǐi khǎao", english: "Today I'm wearing a white shirt.", hindi: "आज मैंने सफ़ेद शर्ट पहनी है।"),
            WordExample(thai: "ไม่ใส่น้ำตาลครับ", romanization: "mâi sài nám-taan khráp", english: "No sugar, please.", hindi: "चीनी मत डालिए।"),
        ],
        269: [
            WordExample(thai: "นั่งที่นี่ได้ไหม", romanization: "nâng thîi-nîi dâai mái", english: "Can I sit here?", hindi: "क्या मैं यहाँ बैठ सकता हूँ?"),
            WordExample(thai: "ผมนั่งรถไฟไปทำงาน", romanization: "phǒm nâng rót-fai pai tham-ngaan", english: "I take the train to work.", hindi: "मैं ट्रेन से काम पर जाता हूँ।"),
        ],
        270: [
            WordExample(thai: "อาหารไทยอร่อยมาก", romanization: "aa-hǎan thai à-ròi mâak", english: "Thai food is very delicious.", hindi: "थाई खाना बहुत स्वादिष्ट है।"),
            WordExample(thai: "ขอบคุณมากครับ", romanization: "khòp-khun mâak khráp", english: "Thank you very much.", hindi: "बहुत-बहुत धन्यवाद।"),
        ],
        271: [
            WordExample(thai: "ผมมีเงินน้อย", romanization: "phǒm mii ngern nói", english: "I have little money.", hindi: "मेरे पास कम पैसे हैं।"),
            WordExample(thai: "ขอน้ำตาลน้อยหน่อย", romanization: "khǒo náam-taan nói nòi", english: "A little less sugar, please.", hindi: "थोड़ी कम चीनी देना।"),
        ],
        272: [
            WordExample(thai: "วันนี้อากาศแย่มาก", romanization: "wan-níi aa-kàat yâe mâak", english: "The weather is very bad today.", hindi: "आज मौसम बहुत ख़राब है।"),
            WordExample(thai: "ผมรู้สึกแย่", romanization: "phǒm rúu-sùek yâe", english: "I feel bad.", hindi: "मुझे बुरा लग रहा है।"),
        ],
        273: [
            WordExample(thai: "ผมง่วงมาก", romanization: "phǒm ngûang mâak", english: "I am very sleepy.", hindi: "मुझे बहुत नींद आ रही है।"),
            WordExample(thai: "กินข้าวแล้วง่วงนอน", romanization: "kin khâao láew ngûang-noon", english: "After eating I feel sleepy.", hindi: "खाना खाकर नींद आती है।"),
        ],
        274: [
            WordExample(thai: "ห้องน้ำที่นี่สะอาด", romanization: "hông-náam thîi-nîi sà-àat", english: "The bathroom here is clean.", hindi: "यहाँ का बाथरूम साफ़ है।"),
            WordExample(thai: "โรงแรมนี้สะอาดมาก", romanization: "roong-raem níi sà-àat mâak", english: "This hotel is very clean.", hindi: "यह होटल बहुत साफ़ है।"),
        ],
        275: [
            WordExample(thai: "รองเท้าของผมสกปรก", romanization: "roong-tháao khǒong phǒm sòk-kà-pròk", english: "My shoes are dirty.", hindi: "मेरे जूते गंदे हैं।"),
            WordExample(thai: "ถนนนี้สกปรกมาก", romanization: "thà-nǒn níi sòk-kà-pròk mâak", english: "This street is very dirty.", hindi: "यह सड़क बहुत गंदी है।"),
        ],
        276: [
            WordExample(thai: "ผมอิ่มแล้ว ขอบคุณครับ", romanization: "phǒm ìm láew khòp-khun khráp", english: "I'm full already, thank you.", hindi: "मेरा पेट भर गया, धन्यवाद।"),
            WordExample(thai: "อิ่มมาก อาหารอร่อย", romanization: "ìm mâak aa-hǎan à-ròi", english: "I'm so full, the food was delicious.", hindi: "पेट बहुत भर गया, खाना स्वादिष्ट था।"),
        ],
        277: [
            WordExample(thai: "พรุ่งนี้คุณว่างไหม", romanization: "phrûng-níi khun wâang mǎi", english: "Are you free tomorrow?", hindi: "क्या आप कल खाली हैं?"),
            WordExample(thai: "ห้องนี้ว่าง", romanization: "hông níi wâang", english: "This room is vacant.", hindi: "यह कमरा खाली है।"),
        ],
        278: [
            WordExample(thai: "แมวของฉันอ้วนมาก", romanization: "maew khǒong chǎn ûan mâak", english: "My cat is very fat.", hindi: "मेरी बिल्ली बहुत मोटी है।"),
            WordExample(thai: "กินมากจะอ้วน", romanization: "kin mâak jà ûan", english: "Eating a lot makes you fat.", hindi: "ज़्यादा खाने से मोटे हो जाओगे।"),
        ],
        279: [
            WordExample(thai: "น้องของผมผอมมาก", romanization: "nóong khǒong phǒm phǒom mâak", english: "My younger sibling is very thin.", hindi: "मेरा छोटा भाई बहुत दुबला है।"),
            WordExample(thai: "หมาตัวนี้ผอม", romanization: "mǎa tua níi phǒom", english: "This dog is thin.", hindi: "यह कुत्ता दुबला है।"),
        ],
        280: [
            WordExample(thai: "ผมของฉันสั้น", romanization: "phǒm khǒong chǎn sân", english: "My hair is short.", hindi: "मेरे बाल छोटे हैं।"),
            WordExample(thai: "ถนนนี้สั้น", romanization: "thà-nǒn níi sân", english: "This road is short.", hindi: "यह सड़क छोटी है।"),
        ],
        281: [
            WordExample(thai: "แม่มีผมยาว", romanization: "mâe mii phǒm yaao", english: "Mom has long hair.", hindi: "माँ के बाल लंबे हैं।"),
            WordExample(thai: "ถนนนี้ยาวมาก", romanization: "thà-nǒn níi yaao mâak", english: "This road is very long.", hindi: "यह सड़क बहुत लंबी है।"),
        ],
        282: [
            WordExample(thai: "ถนนนี้กว้างมาก", romanization: "thà-nǒn níi kwâang mâak", english: "This road is very wide.", hindi: "यह सड़क बहुत चौड़ी है।"),
            WordExample(thai: "ห้องนี้กว้างและสบาย", romanization: "hông níi kwâang láe sà-baai", english: "This room is spacious and comfortable.", hindi: "यह कमरा चौड़ा और आरामदायक है।"),
        ],
        283: [
            WordExample(thai: "ถนนที่นี่แคบมาก", romanization: "thà-nǒn thîi-nîi khâep mâak", english: "The streets here are very narrow.", hindi: "यहाँ की सड़कें बहुत संकरी हैं।"),
            WordExample(thai: "ห้องน้ำแคบ", romanization: "hông-náam khâep", english: "The bathroom is narrow.", hindi: "बाथरूम तंग है।"),
        ],
        284: [
            WordExample(thai: "กระเป๋าใบนี้หนักมาก", romanization: "krà-pǎo bai níi nàk mâak", english: "This bag is very heavy.", hindi: "यह बैग बहुत भारी है।"),
            WordExample(thai: "ช้างตัวนี้ใหญ่และหนัก", romanization: "cháang tua níi yài láe nàk", english: "This elephant is big and heavy.", hindi: "यह हाथी बड़ा और भारी है।"),
        ],
        285: [
            WordExample(thai: "โทรศัพท์ของฉันเบา", romanization: "thoo-rá-sàp khǒong chǎn bao", english: "My phone is light.", hindi: "मेरा फ़ोन हल्का है।"),
            WordExample(thai: "พูดเบา ๆ หน่อย", romanization: "phûut bao bao nòi", english: "Please speak softly.", hindi: "थोड़ा धीरे बोलिए।"),
        ],
        286: [
            WordExample(thai: "ที่ตลาดเสียงดังมาก", romanization: "thîi tà-làat sǐang dang mâak", english: "It's very noisy at the market.", hindi: "बाज़ार में बहुत शोर है।"),
            WordExample(thai: "คุณพูดดังมาก", romanization: "khun phûut dang mâak", english: "You speak very loudly.", hindi: "आप बहुत ज़ोर से बोलते हैं।"),
        ],
        287: [
            WordExample(thai: "ห้องนี้เงียบมาก", romanization: "hông níi ngîap mâak", english: "This room is very quiet.", hindi: "यह कमरा बहुत शांत है।"),
            WordExample(thai: "กลางคืนที่นี่เงียบ", romanization: "klaang-khuun thîi-nîi ngîap", english: "It's quiet here at night.", hindi: "रात में यहाँ शांति रहती है।"),
        ],
        288: [
            WordExample(thai: "คุณพูดไทยเก่งมาก", romanization: "khun phûut thai kèng mâak", english: "You speak Thai very well.", hindi: "आप बहुत अच्छी थाई बोलते हैं।"),
            WordExample(thai: "ลูกของฉันเรียนเก่ง", romanization: "lûuk khǒong chǎn rian kèng", english: "My child is good at studying.", hindi: "मेरा बच्चा पढ़ाई में होशियार है।"),
        ],
        289: [
            WordExample(thai: "กาแฟหอมมาก", romanization: "kaa-fae hǒom mâak", english: "The coffee smells very good.", hindi: "कॉफ़ी की खुशबू बहुत अच्छी है।"),
            WordExample(thai: "ดอกไม้นี้หอม", romanization: "dòok-máai níi hǒom", english: "This flower is fragrant.", hindi: "यह फूल खुशबूदार है।"),
        ],
        290: [
            WordExample(thai: "โรงแรมนี้สบายมาก", romanization: "roong-raem níi sà-baai mâak", english: "This hotel is very comfortable.", hindi: "यह होटल बहुत आरामदायक है।"),
            WordExample(thai: "นอนสบายไหม", romanization: "noon sà-baai mǎi", english: "Did you sleep comfortably?", hindi: "आराम से सोए क्या?"),
        ],
        291: [
            WordExample(thai: "ครอบครัวสำคัญมาก", romanization: "khrôop-khrua sǎm-khan mâak", english: "Family is very important.", hindi: "परिवार बहुत महत्वपूर्ण है।"),
            WordExample(thai: "วันนี้เป็นวันสำคัญ", romanization: "wan-níi pen wan sǎm-khan", english: "Today is an important day.", hindi: "आज महत्वपूर्ण दिन है।"),
        ],
        292: [
            WordExample(thai: "ถูกต้องครับ", romanization: "thùuk-tông khráp", english: "That's correct.", hindi: "बिल्कुल सही।"),
            WordExample(thai: "คำตอบนี้ถูกต้อง", romanization: "kham-tòop níi thùuk-tông", english: "This answer is correct.", hindi: "यह जवाब सही है।"),
        ],
        293: [
            WordExample(thai: "ผมเข้าใจผิด", romanization: "phǒm khâo-jai phìt", english: "I misunderstood.", hindi: "मैंने गलत समझा।"),
            WordExample(thai: "คำตอบนี้ผิด", romanization: "kham-tòop níi phìt", english: "This answer is wrong.", hindi: "यह जवाब गलत है।"),
        ],
        294: [
            WordExample(thai: "ภูเขานี้สูงมาก", romanization: "phuu-khǎo níi sǔung mâak", english: "This mountain is very high.", hindi: "यह पहाड़ बहुत ऊँचा है।"),
            WordExample(thai: "พ่อของฉันสูง", romanization: "phôo khǒong chǎn sǔung", english: "My father is tall.", hindi: "मेरे पिता लंबे हैं।"),
        ],
        295: [
            WordExample(thai: "วันจันทร์ผมไปทำงาน", romanization: "wan-jan phǒm pai tham-ngaan", english: "On Monday I go to work.", hindi: "सोमवार को मैं काम पर जाता हूँ।"),
            WordExample(thai: "ร้านปิดวันจันทร์", romanization: "ráan pìt wan-jan", english: "The shop is closed on Monday.", hindi: "दुकान सोमवार को बंद रहती है।"),
        ],
        296: [
            WordExample(thai: "วันอังคารฉันเรียนภาษาไทย", romanization: "wan-ang-khaan chǎn rian phaa-sǎa-thai", english: "On Tuesday I study Thai.", hindi: "मंगलवार को मैं थाई सीखती हूँ।"),
            WordExample(thai: "พรุ่งนี้เป็นวันอังคาร", romanization: "phrûng-níi pen wan-ang-khaan", english: "Tomorrow is Tuesday.", hindi: "कल मंगलवार है।"),
        ],
        297: [
            WordExample(thai: "วันนี้เป็นวันพุธ", romanization: "wan-níi pen wan-phút", english: "Today is Wednesday.", hindi: "आज बुधवार है।"),
            WordExample(thai: "วันพุธผมไปตลาด", romanization: "wan-phút phǒm pai tà-làat", english: "On Wednesday I go to the market.", hindi: "बुधवार को मैं बाज़ार जाता हूँ।"),
        ],
        298: [
            WordExample(thai: "วันพฤหัสฉันว่าง", romanization: "wan-phá-rúe-hàt chǎn wâang", english: "On Thursday I am free.", hindi: "गुरुवार को मैं खाली हूँ।"),
            WordExample(thai: "เจอกันวันพฤหัสนะ", romanization: "jer-kan wan-phá-rúe-hàt ná", english: "See you on Thursday!", hindi: "गुरुवार को मिलते हैं!"),
        ],
        299: [
            WordExample(thai: "วันศุกร์ผมดีใจมาก", romanization: "wan-sùk phǒm dii-jai mâak", english: "On Friday I am very happy.", hindi: "शुक्रवार को मैं बहुत खुश होता हूँ।"),
            WordExample(thai: "วันศุกร์ไปกินข้าวกันไหม", romanization: "wan-sùk pai kin khâao kan mái", english: "Shall we go eat together on Friday?", hindi: "शुक्रवार को साथ खाना खाने चलें?"),
        ],
        300: [
            WordExample(thai: "วันเสาร์ฉันไม่ทำงาน", romanization: "wan-sǎo chǎn mâi tham-ngaan", english: "On Saturday I do not work.", hindi: "शनिवार को मैं काम नहीं करती।"),
            WordExample(thai: "วันเสาร์ผมไปทะเล", romanization: "wan-sǎo phǒm pai thá-lee", english: "On Saturday I go to the sea.", hindi: "शनिवार को मैं समुद्र जाता हूँ।"),
        ],
        301: [
            WordExample(thai: "วันอาทิตย์ผมตื่นสาย", romanization: "wan-aa-thít phǒm tùen sǎai", english: "On Sunday I wake up late.", hindi: "रविवार को मैं देर से उठता हूँ।"),
            WordExample(thai: "วันอาทิตย์ฉันไปวัด", romanization: "wan-aa-thít chǎn pai wát", english: "On Sunday I go to the temple.", hindi: "रविवार को मैं मंदिर जाती हूँ।"),
        ],
        302: [
            WordExample(thai: "ตอนนี้ฝนตก", romanization: "toon-níi fǒn tòk", english: "It is raining now.", hindi: "अभी बारिश हो रही है।"),
            WordExample(thai: "ตอนนี้กี่โมง", romanization: "toon-níi kìi moong", english: "What time is it now?", hindi: "अभी क्या समय हुआ है?"),
        ],
        303: [
            WordExample(thai: "ผมมาที่นี่บ่อย", romanization: "phǒm maa thîi-nîi bòi", english: "I come here often.", hindi: "मैं यहाँ अक्सर आता हूँ।"),
            WordExample(thai: "คุณกินอาหารไทยบ่อยไหม", romanization: "khun kin aa-hǎan thai bòi mái", english: "Do you eat Thai food often?", hindi: "क्या आप अक्सर थाई खाना खाते हैं?"),
        ],
        304: [
            WordExample(thai: "บางครั้งฉันคิดถึงบ้าน", romanization: "baang-khráng chǎn khít-thǔeng bâan", english: "Sometimes I miss home.", hindi: "कभी-कभी मुझे घर की याद आती है।"),
            WordExample(thai: "บางครั้งผมกินข้าวคนเดียว", romanization: "baang-khráng phǒm kin khâao khon-diao", english: "Sometimes I eat alone.", hindi: "कभी-कभी मैं अकेले खाना खाता हूँ।"),
        ],
        305: [
            WordExample(thai: "เขามาตรงเวลาเสมอ", romanization: "khǎo maa trong-wee-laa sà-měr", english: "He always comes on time.", hindi: "वह हमेशा समय पर आता है।"),
            WordExample(thai: "แม่ช่วยฉันเสมอ", romanization: "mâe chûai chǎn sà-měr", english: "Mom always helps me.", hindi: "माँ हमेशा मेरी मदद करती है।"),
        ],
        306: [
            WordExample(thai: "ผมไม่เคยไปเชียงใหม่", romanization: "phǒm mâi-kheuy pai chiang-mài", english: "I have never been to Chiang Mai.", hindi: "मैं कभी चियांग माई नहीं गया।"),
            WordExample(thai: "ฉันไม่เคยกินส้มตำ", romanization: "chǎn mâi-kheuy kin sôm-tam", english: "I have never eaten som tam.", hindi: "मैंने कभी सोम तम नहीं खाया।"),
        ],
        307: [
            WordExample(thai: "เจอกันเร็ว ๆ นี้", romanization: "jer-kan reo-reo-níi", english: "See you soon.", hindi: "जल्दी ही मिलते हैं।"),
            WordExample(thai: "ร้านใหม่จะเปิดเร็ว ๆ นี้", romanization: "ráan mài jà pèrt reo-reo-níi", english: "The new shop will open soon.", hindi: "नई दुकान जल्दी ही खुलेगी।"),
        ],
        308: [
            WordExample(thai: "กินข้าวก่อนไปทำงาน", romanization: "kin khâao kòon pai tham-ngaan", english: "Eat before going to work.", hindi: "काम पर जाने से पहले खाना खाओ।"),
            WordExample(thai: "ผมไปก่อนนะ", romanization: "phǒm pai kòon ná", english: "I am off now (leaving first).", hindi: "मैं पहले चलता हूँ।"),
        ],
        309: [
            WordExample(thai: "หลังเลิกงานผมไปตลาด", romanization: "lǎng lêrk-ngaan phǒm pai tà-làat", english: "After work I go to the market.", hindi: "काम के बाद मैं बाज़ार जाता हूँ।"),
            WordExample(thai: "หลังเลิกเรียนฉันกลับบ้าน", romanization: "lǎng lêrk-rian chǎn klàp bâan", english: "After class I go back home.", hindi: "क्लास के बाद मैं घर लौटती हूँ।"),
        ],
        310: [
            WordExample(thai: "ขอโทษ ผมมาสาย", romanization: "khǒo-thôot phǒm maa sǎai", english: "Sorry, I am late.", hindi: "माफ़ कीजिए, मुझे देर हो गई।"),
            WordExample(thai: "อย่ามาสายนะ", romanization: "yàa maa sǎai ná", english: "Do not be late!", hindi: "देर से मत आना!"),
        ],
        311: [
            WordExample(thai: "ผมกินข้าวตอนเที่ยง", romanization: "phǒm kin khâao toon thîang", english: "I eat lunch at noon.", hindi: "मैं दोपहर को खाना खाता हूँ।"),
            WordExample(thai: "ตอนนี้เที่ยงแล้ว", romanization: "toon-níi thîang láew", english: "It is already noon.", hindi: "अभी बारह बज गए हैं।"),
        ],
        312: [
            WordExample(thai: "เสาร์อาทิตย์นี้คุณทำอะไร", romanization: "sǎo-aa-thít níi khun tham à-rai", english: "What are you doing this weekend?", hindi: "इस वीकेंड आप क्या कर रहे हैं?"),
            WordExample(thai: "เสาร์อาทิตย์ผมอยู่บ้าน", romanization: "sǎo-aa-thít phǒm yùu bâan", english: "On weekends I stay home.", hindi: "वीकेंड पर मैं घर पर रहता हूँ।"),
        ],
        313: [
            WordExample(thai: "อาทิตย์หน้าฉันไปทะเล", romanization: "aa-thít-nâa chǎn pai thá-lee", english: "Next week I am going to the sea.", hindi: "अगले हफ़्ते मैं समुद्र जा रही हूँ।"),
            WordExample(thai: "เจอกันอาทิตย์หน้า", romanization: "jer-kan aa-thít-nâa", english: "See you next week.", hindi: "अगले हफ़्ते मिलते हैं।"),
        ],
        314: [
            WordExample(thai: "อาทิตย์ที่แล้วผมป่วย", romanization: "aa-thít-thîi-láew phǒm pùai", english: "Last week I was sick.", hindi: "पिछले हफ़्ते मैं बीमार था।"),
            WordExample(thai: "อาทิตย์ที่แล้วฝนตกทุกวัน", romanization: "aa-thít-thîi-láew fǒn tòk thúk-wan", english: "Last week it rained every day.", hindi: "पिछले हफ़्ते हर दिन बारिश हुई।"),
        ],
        315: [
            WordExample(thai: "บ่ายนี้ว่างไหม", romanization: "bàai níi wâang mái", english: "Are you free this afternoon?", hindi: "क्या आज दोपहर बाद आप खाली हैं?"),
            WordExample(thai: "เจอกันตอนบ่าย", romanization: "jer-kan toon bàai", english: "See you in the afternoon.", hindi: "दोपहर बाद मिलते हैं।"),
        ],
        316: [
            WordExample(thai: "ผมดื่มกาแฟทุกวัน", romanization: "phǒm dùem kaa-fae thúk-wan", english: "I drink coffee every day.", hindi: "मैं हर दिन कॉफ़ी पीता हूँ।"),
            WordExample(thai: "ฉันเรียนภาษาไทยทุกวัน", romanization: "chǎn rian phaa-sǎa-thai thúk-wan", english: "I study Thai every day.", hindi: "मैं हर दिन थाई सीखती हूँ।"),
        ],
        317: [
            WordExample(thai: "คืนนี้ไปกินข้าวกันไหม", romanization: "kheun-níi pai kin khâao kan mái", english: "Shall we go out to eat tonight?", hindi: "आज रात खाना खाने चलें?"),
            WordExample(thai: "คืนนี้ฉันนอนเร็ว", romanization: "kheun-níi chǎn noon reo", english: "Tonight I will sleep early.", hindi: "आज रात मैं जल्दी सोऊँगी।"),
        ],
        318: [
            WordExample(thai: "พรุ่งนี้เป็นวันหยุด", romanization: "phrûng-níi pen wan-yùt", english: "Tomorrow is a holiday.", hindi: "कल छुट्टी है।"),
            WordExample(thai: "วันหยุดคุณทำอะไร", romanization: "wan-yùt khun tham à-rai", english: "What do you do on your day off?", hindi: "छुट्टी के दिन आप क्या करते हैं?"),
        ],
        319: [
            WordExample(thai: "รอนานไหม", romanization: "roo naan mái", english: "Did you wait long?", hindi: "क्या बहुत देर इंतज़ार किया?"),
            WordExample(thai: "ไม่เจอกันนานเลย", romanization: "mâi jer kan naan leuy", english: "Long time no see!", hindi: "बहुत दिनों बाद मिले!"),
        ],
        320: [
            WordExample(thai: "คุณมีพี่น้องกี่คน", romanization: "khun mii phîi-nóong kìi khon", english: "How many siblings do you have?", hindi: "आपके कितने भाई-बहन हैं?"),
            WordExample(thai: "อันนี้กี่บาท", romanization: "an níi kìi bàat", english: "How many baht is this?", hindi: "यह कितने बाथ का है?"),
        ],
        321: [
            WordExample(thai: "ผมมีหมาสองตัว", romanization: "phǒm mii mǎa sǒong tua", english: "I have two dogs.", hindi: "मेरे पास दो कुत्ते हैं।"),
            WordExample(thai: "เสื้อตัวนี้สวยมาก", romanization: "sûea tua níi sǔai mâak", english: "This shirt is very beautiful.", hindi: "यह शर्ट बहुत सुंदर है।"),
        ],
        322: [
            WordExample(thai: "ครอบครัวผมมีสี่คน", romanization: "khrôop-khrua phǒm mii sìi khon", english: "My family has four people.", hindi: "मेरे परिवार में चार लोग हैं।"),
            WordExample(thai: "ที่ตลาดมีคนเยอะ", romanization: "thîi ta-làat mii khon yóe", english: "There are a lot of people at the market.", hindi: "बाज़ार में बहुत लोग हैं।"),
        ],
        323: [
            WordExample(thai: "อันนี้เท่าไหร่", romanization: "an níi thâo-rài", english: "How much is this one?", hindi: "यह वाला कितने का है?"),
            WordExample(thai: "ขออันเล็ก", romanization: "khǒo an lék", english: "I'd like the small one, please.", hindi: "छोटा वाला दीजिए।"),
        ],
        324: [
            WordExample(thai: "ขอตั๋วสองใบ", romanization: "khǒo tǔa sǒong bai", english: "Two tickets, please.", hindi: "दो टिकट दीजिए।"),
            WordExample(thai: "ผมมีกระเป๋าหนึ่งใบ", romanization: "phǒm mii kra-pǎo nùeng bai", english: "I have one bag.", hindi: "मेरे पास एक बैग है।"),
        ],
        325: [
            WordExample(thai: "ขอน้ำหนึ่งแก้ว", romanization: "khǒo náam nùeng kâew", english: "One glass of water, please.", hindi: "एक गिलास पानी दीजिए।"),
            WordExample(thai: "น้ำส้มหนึ่งแก้วเท่าไหร่", romanization: "náam-sôm nùeng kâew thâo-rài", english: "How much is a glass of orange juice?", hindi: "संतरे के जूस का एक गिलास कितने का है?"),
        ],
        326: [
            WordExample(thai: "ขอน้ำสองขวด", romanization: "khǒo náam sǒong khùat", english: "Two bottles of water, please.", hindi: "दो बोतल पानी दीजिए।"),
            WordExample(thai: "นมขวดนี้เท่าไหร่", romanization: "nom khùat níi thâo-rài", english: "How much is this bottle of milk?", hindi: "दूध की यह बोतल कितने की है?"),
        ],
        327: [
            WordExample(thai: "ขอข้าวผัดหนึ่งจาน", romanization: "khǒo khâao-phàt nùeng jaan", english: "One plate of fried rice, please.", hindi: "एक प्लेट फ्राइड राइस दीजिए।"),
            WordExample(thai: "จานนี้ใหญ่มาก", romanization: "jaan níi yài mâak", english: "This plate is very big.", hindi: "यह प्लेट बहुत बड़ी है।"),
        ],
        328: [
            WordExample(thai: "ขอแกงหนึ่งถ้วย", romanization: "khǒo kaeng nùeng thûai", english: "One bowl of curry, please.", hindi: "एक कटोरी करी दीजिए।"),
            WordExample(thai: "ถ้วยนี้สวยมาก", romanization: "thûai níi sǔai mâak", english: "This bowl is very pretty.", hindi: "यह कटोरी बहुत सुंदर है।"),
        ],
        329: [
            WordExample(thai: "รองเท้าคู่นี้เท่าไหร่", romanization: "roong-tháo khûu níi thâo-rài", english: "How much is this pair of shoes?", hindi: "जूतों की यह जोड़ी कितने की है?"),
            WordExample(thai: "ผมซื้อรองเท้าหนึ่งคู่", romanization: "phǒm súe roong-tháo nùeng khûu", english: "I bought one pair of shoes.", hindi: "मैंने एक जोड़ी जूते खरीदे।"),
        ],
        330: [
            WordExample(thai: "ขอไก่สองชิ้น", romanization: "khǒo kài sǒong chín", english: "Two pieces of chicken, please.", hindi: "चिकन के दो टुकड़े दीजिए।"),
            WordExample(thai: "เค้กชิ้นนี้อร่อยมาก", romanization: "khéek chín níi a-ròi mâak", english: "This piece of cake is delicious.", hindi: "केक का यह टुकड़ा बहुत स्वादिष्ट है।"),
        ],
        331: [
            WordExample(thai: "ผมซื้อหนังสือสองเล่ม", romanization: "phǒm súe nǎng-sǔe sǒong lêm", english: "I bought two books.", hindi: "मैंने दो किताबें खरीदीं।"),
            WordExample(thai: "หนังสือเล่มนี้ดีมาก", romanization: "nǎng-sǔe lêm níi dii mâak", english: "This book is very good.", hindi: "यह किताब बहुत अच्छी है।"),
        ],
        332: [
            WordExample(thai: "ผมมาเมืองไทยเป็นครั้งแรก", romanization: "phǒm maa mueang-thai pen khráng râek", english: "This is my first time in Thailand.", hindi: "मैं पहली बार थाईलैंड आया हूँ।"),
            WordExample(thai: "ผมมาที่นี่สองครั้ง", romanization: "phǒm maa thîi-nîi sǒong khráng", english: "I have come here two times.", hindi: "मैं यहाँ दो बार आया हूँ।"),
        ],
        333: [
            WordExample(thai: "เสื้อตัวนี้สองร้อยบาท", romanization: "sûea tua níi sǒong rói bàat", english: "This shirt is two hundred baht.", hindi: "यह शर्ट दो सौ बाथ की है।"),
            WordExample(thai: "ผมมีห้าร้อยบาท", romanization: "phǒm mii hâa rói bàat", english: "I have five hundred baht.", hindi: "मेरे पास पाँच सौ बाथ हैं।"),
        ],
        334: [
            WordExample(thai: "โรงแรมคืนละหนึ่งพันบาท", romanization: "roong-raem khuen lá nùeng phan bàat", english: "The hotel is one thousand baht per night.", hindi: "होटल एक हज़ार बाथ प्रति रात है।"),
            WordExample(thai: "ผมมีสองพันบาท", romanization: "phǒm mii sǒong phan bàat", english: "I have two thousand baht.", hindi: "मेरे पास दो हज़ार बाथ हैं।"),
        ],
        335: [
            WordExample(thai: "โทรศัพท์นี้หนึ่งหมื่นบาท", romanization: "thoo-rá-sàp níi nùeng mùen bàat", english: "This phone is ten thousand baht.", hindi: "यह फ़ोन दस हज़ार बाथ का है।"),
            WordExample(thai: "ผมมีเงินสามหมื่นบาท", romanization: "phǒm mii ngoen sǎam mùen bàat", english: "I have thirty thousand baht.", hindi: "मेरे पास तीस हज़ार बाथ हैं।"),
        ],
        336: [
            WordExample(thai: "รถนี้ห้าแสนบาท", romanization: "rót níi hâa sǎen bàat", english: "This car is five hundred thousand baht.", hindi: "यह गाड़ी पाँच लाख बाथ की है।"),
            WordExample(thai: "บ้านนี้เก้าแสนบาท", romanization: "bâan níi kâao sǎen bàat", english: "This house is nine hundred thousand baht.", hindi: "यह घर नौ लाख बाथ का है।"),
        ],
        337: [
            WordExample(thai: "บ้านนี้สามล้านบาท", romanization: "bâan níi sǎam láan bàat", english: "This house is three million baht.", hindi: "यह घर तीस लाख बाथ का है।"),
            WordExample(thai: "กรุงเทพฯมีคนสิบล้านคน", romanization: "krung-thêep mii khon sìp láan khon", english: "Bangkok has ten million people.", hindi: "बैंकॉक में एक करोड़ लोग हैं।"),
        ],
        338: [
            WordExample(thai: "รอครึ่งชั่วโมง", romanization: "roo khrûeng chûa-moong", english: "Wait half an hour.", hindi: "आधा घंटा इंतज़ार कीजिए।"),
            WordExample(thai: "ผมกินข้าวครึ่งจาน", romanization: "phǒm kin khâao khrûeng jaan", english: "I ate half a plate of rice.", hindi: "मैंने आधी प्लेट चावल खाया।"),
        ],
        339: [
            WordExample(thai: "ผมพูดภาษาไทยได้นิดหน่อย", romanization: "phǒm phûut phaa-sǎa-thai dâai nít-nòi", english: "I can speak a little Thai.", hindi: "मैं थोड़ी-सी थाई बोल सकता हूँ।"),
            WordExample(thai: "เผ็ดนิดหน่อย", romanization: "phèt nít-nòi", english: "It's a little bit spicy.", hindi: "थोड़ा-सा तीखा है।"),
        ],
        340: [
            WordExample(thai: "ผมมีเพื่อนเยอะ", romanization: "phǒm mii phûean yóe", english: "I have a lot of friends.", hindi: "मेरे बहुत सारे दोस्त हैं।"),
            WordExample(thai: "วันนี้คนเยอะมาก", romanization: "wan-níi khon yóe mâak", english: "There are so many people today.", hindi: "आज बहुत ज़्यादा लोग हैं।"),
        ],
        341: [
            WordExample(thai: "ทั้งหมดเท่าไหร่", romanization: "tháng-mòt thâo-rài", english: "How much is it altogether?", hindi: "कुल कितना हुआ?"),
            WordExample(thai: "ทั้งหมดสามร้อยบาท", romanization: "tháng-mòt sǎam rói bàat", english: "Altogether it's three hundred baht.", hindi: "कुल तीन सौ बाथ हुआ।"),
        ],
        342: [
            WordExample(thai: "อันละยี่สิบบาท", romanization: "an lá yîi-sìp bàat", english: "Twenty baht each.", hindi: "हर एक बीस बाथ का है।"),
            WordExample(thai: "กินยาวันละสามครั้ง", romanization: "kin yaa wan lá sǎam khráng", english: "Take the medicine three times a day.", hindi: "दवा दिन में तीन बार लीजिए।"),
        ],
        343: [
            WordExample(thai: "เบอร์ผมคือศูนย์แปดเก้า", romanization: "boe phǒm khue sǔun pàet kâao", english: "My number is zero-eight-nine.", hindi: "मेरा नंबर शून्य-आठ-नौ है।"),
            WordExample(thai: "นับจากศูนย์ถึงสิบ", romanization: "náp jàak sǔun thǔeng sìp", english: "Count from zero to ten.", hindi: "शून्य से दस तक गिनिए।"),
        ],
        344: [
            WordExample(thai: "ผมอายุยี่สิบปี", romanization: "phǒm aa-yú yîi-sìp pii", english: "I am twenty years old.", hindi: "मैं बीस साल का हूँ।"),
            WordExample(thai: "อันนี้ยี่สิบบาท", romanization: "an níi yîi-sìp bàat", english: "This one is twenty baht.", hindi: "यह बीस बाथ का है।"),
        ],
        345: [
            WordExample(thai: "ห้องนี้ใหญ่มาก", romanization: "hôong níi yài mâak", english: "This room is very big.", hindi: "यह कमरा बहुत बड़ा है।"),
            WordExample(thai: "ห้องของฉันอยู่ข้างบน", romanization: "hôong khǒong chǎn yùu khâang-bon", english: "My room is upstairs.", hindi: "मेरा कमरा ऊपर है।"),
        ],
        346: [
            WordExample(thai: "ช่วยเปิดประตูหน่อย", romanization: "chûai pèrt prà-tuu nòi", english: "Please open the door.", hindi: "कृपया दरवाज़ा खोल दीजिए।"),
            WordExample(thai: "ปิดประตูด้วยครับ", romanization: "pìt prà-tuu dûai khráp", english: "Please close the door.", hindi: "दरवाज़ा बंद कर दीजिए।"),
        ],
        347: [
            WordExample(thai: "เปิดหน้าต่างหน่อยได้ไหม", romanization: "pèrt nâa-tàang nòi dâi mǎi", english: "Can you open the window?", hindi: "क्या आप खिड़की खोल सकते हैं?"),
            WordExample(thai: "หน้าต่างปิดแล้ว", romanization: "nâa-tàang pìt láew", english: "The window is already closed.", hindi: "खिड़की बंद हो गई है।"),
        ],
        348: [
            WordExample(thai: "เตียงนี้นอนสบาย", romanization: "tiang níi noon sà-baai", english: "This bed is comfortable to sleep on.", hindi: "यह बिस्तर सोने में आरामदायक है।"),
            WordExample(thai: "แมวนอนบนเตียง", romanization: "maew noon bon tiang", english: "The cat sleeps on the bed.", hindi: "बिल्ली बिस्तर पर सोती है।"),
        ],
        349: [
            WordExample(thai: "กาแฟอยู่บนโต๊ะ", romanization: "kaa-fae yùu bon tó", english: "The coffee is on the table.", hindi: "कॉफ़ी मेज़ पर है।"),
            WordExample(thai: "นั่งที่โต๊ะนี้ได้ไหม", romanization: "nâng thîi tó níi dâi mǎi", english: "Can I sit at this table?", hindi: "क्या मैं इस मेज़ पर बैठ सकता हूँ?"),
        ],
        350: [
            WordExample(thai: "เก้าอี้ตัวนี้ใหม่", romanization: "kâo-îi tua níi mài", english: "This chair is new.", hindi: "यह कुर्सी नई है।"),
            WordExample(thai: "มีเก้าอี้สองตัว", romanization: "mii kâo-îi sǒong tua", english: "There are two chairs.", hindi: "दो कुर्सियाँ हैं।"),
        ],
        351: [
            WordExample(thai: "มือถือของฉันอยู่ไหน", romanization: "meuu-thěuu khǒong chǎn yùu nǎi", english: "Where is my phone?", hindi: "मेरा मोबाइल कहाँ है?"),
            WordExample(thai: "มือถือใหม่แพงมาก", romanization: "meuu-thěuu mài phaeng mâak", english: "The new phone is very expensive.", hindi: "नया मोबाइल बहुत महँगा है।"),
        ],
        352: [
            WordExample(thai: "กุญแจอยู่ในกระเป๋า", romanization: "kun-jae yùu nai krà-pǎo", english: "The key is in the bag.", hindi: "चाबी बैग में है।"),
            WordExample(thai: "ฉันลืมกุญแจ", romanization: "chǎn leuum kun-jae", english: "I forgot the key.", hindi: "मैं चाबी भूल गया।"),
        ],
        353: [
            WordExample(thai: "ฉันซื้อเสื้อผ้าใหม่", romanization: "chǎn séuu sûea-phâa mài", english: "I bought new clothes.", hindi: "मैंने नए कपड़े खरीदे।"),
            WordExample(thai: "เสื้อผ้าสวยมาก", romanization: "sûea-phâa sǔai mâak", english: "The clothes are very beautiful.", hindi: "कपड़े बहुत सुंदर हैं।"),
        ],
        354: [
            WordExample(thai: "กางเกงตัวนี้พอดี", romanization: "kaang-keeng tua níi phoo-dii", english: "These pants fit just right.", hindi: "यह पैंट एकदम फ़िट है।"),
            WordExample(thai: "ขอลองกางเกงตัวนี้หน่อย", romanization: "khǒo loong kaang-keeng tua níi nòi", english: "May I try on these pants?", hindi: "मैं यह पैंट पहनकर देखना चाहता हूँ।"),
        ],
        355: [
            WordExample(thai: "สบู่อยู่ในห้องน้ำ", romanization: "sà-bùu yùu nai hôong-náam", english: "The soap is in the bathroom.", hindi: "साबुन बाथरूम में है।"),
            WordExample(thai: "สบู่หอมมาก", romanization: "sà-bùu hǒom mâak", english: "The soap smells very nice.", hindi: "साबुन से बहुत अच्छी खुशबू आती है।"),
        ],
        356: [
            WordExample(thai: "ขอผ้าเช็ดตัวใหม่หน่อย", romanization: "khǒo phâa-chét-tua mài nòi", english: "May I have a new towel?", hindi: "कृपया एक नया तौलिया दीजिए।"),
            WordExample(thai: "ผ้าเช็ดตัวยังเปียกอยู่", romanization: "phâa-chét-tua yang pìak yùu", english: "The towel is still wet.", hindi: "तौलिया अभी भी गीला है।"),
        ],
        357: [
            WordExample(thai: "วันนี้ไฟฟ้าดับ", romanization: "wan-níi fai-fáa dàp", english: "The electricity is out today.", hindi: "आज बिजली चली गई।"),
            WordExample(thai: "ค่าไฟฟ้าแพง", romanization: "khâa fai-fáa phaeng", english: "The electricity bill is expensive.", hindi: "बिजली का बिल महँगा है।"),
        ],
        358: [
            WordExample(thai: "ช่วยเปิดแอร์หน่อย", romanization: "chûai pèrt ae nòi", english: "Please turn on the AC.", hindi: "कृपया एसी चला दीजिए।"),
            WordExample(thai: "ห้องนี้แอร์เย็นมาก", romanization: "hôong níi ae yen mâak", english: "The AC in this room is very cold.", hindi: "इस कमरे का एसी बहुत ठंडा है।"),
        ],
        359: [
            WordExample(thai: "เปิดพัดลมหน่อย", romanization: "pèrt phát-lom nòi", english: "Turn on the fan, please.", hindi: "पंखा चला दो।"),
            WordExample(thai: "พัดลมเสีย", romanization: "phát-lom sǐa", english: "The fan is broken.", hindi: "पंखा खराब है।"),
        ],
        360: [
            WordExample(thai: "นมอยู่ในตู้เย็น", romanization: "nom yùu nai tûu-yen", english: "The milk is in the fridge.", hindi: "दूध फ्रिज में है।"),
            WordExample(thai: "ช่วยปิดตู้เย็นด้วย", romanization: "chûai pìt tûu-yen dûai", english: "Please close the fridge.", hindi: "कृपया फ्रिज बंद कर दीजिए।"),
        ],
        361: [
            WordExample(thai: "ฉันดูทีวีทุกวัน", romanization: "chǎn duu thii-wii thúk wan", english: "I watch TV every day.", hindi: "मैं रोज़ टीवी देखता हूँ।"),
            WordExample(thai: "ปิดทีวีก่อนนอน", romanization: "pìt thii-wii kòon noon", english: "Turn off the TV before sleeping.", hindi: "सोने से पहले टीवी बंद करो।"),
        ],
        362: [
            WordExample(thai: "เปิดโคมไฟหน่อย", romanization: "pèrt khoom-fai nòi", english: "Turn on the lamp, please.", hindi: "लैंप जला दो।"),
            WordExample(thai: "โคมไฟอยู่ข้างเตียง", romanization: "khoom-fai yùu khâang tiang", english: "The lamp is beside the bed.", hindi: "लैंप बिस्तर के बगल में है।"),
        ],
        363: [
            WordExample(thai: "ห้องนอนของฉันเล็ก", romanization: "hôong-noon khǒong chǎn lék", english: "My bedroom is small.", hindi: "मेरा बेडरूम छोटा है।"),
            WordExample(thai: "บ้านนี้มีสองห้องนอน", romanization: "bâan níi mii sǒong hôong-noon", english: "This house has two bedrooms.", hindi: "इस घर में दो बेडरूम हैं।"),
        ],
        364: [
            WordExample(thai: "แม่อยู่ในห้องครัว", romanization: "mâe yùu nai hôong-khrua", english: "Mom is in the kitchen.", hindi: "माँ रसोई में हैं।"),
            WordExample(thai: "ห้องครัวสะอาดมาก", romanization: "hôong-khrua sà-àat mâak", english: "The kitchen is very clean.", hindi: "रसोई बहुत साफ़ है।"),
        ],
        365: [
            WordExample(thai: "ฉันต้องซื้อแปรงสีฟันใหม่", romanization: "chǎn tôong séuu praeng-sǐi-fan mài", english: "I need to buy a new toothbrush.", hindi: "मुझे नया टूथब्रश खरीदना है।"),
            WordExample(thai: "แปรงสีฟันของฉันสีฟ้า", romanization: "praeng-sǐi-fan khǒong chǎn sǐi fáa", english: "My toothbrush is blue.", hindi: "मेरा टूथब्रश नीला है।"),
        ],
        366: [
            WordExample(thai: "ยาสีฟันหมดแล้ว", romanization: "yaa-sǐi-fan mòt láew", english: "The toothpaste is finished.", hindi: "टूथपेस्ट खत्म हो गया है।"),
            WordExample(thai: "ขอซื้อยาสีฟันหนึ่งหลอด", romanization: "khǒo séuu yaa-sǐi-fan nèung lòot", english: "I'd like to buy one tube of toothpaste.", hindi: "मुझे टूथपेस्ट की एक ट्यूब चाहिए।"),
        ],
        367: [
            WordExample(thai: "ขอหมอนอีกหนึ่งใบ", romanization: "khǒo mǒon ìik nèung bai", english: "May I have one more pillow?", hindi: "एक और तकिया दीजिए।"),
            WordExample(thai: "หมอนนี้นุ่มมาก", romanization: "mǒon níi nûm mâak", english: "This pillow is very soft.", hindi: "यह तकिया बहुत मुलायम है।"),
        ],
        368: [
            WordExample(thai: "คืนนี้หนาว ขอผ้าห่มหน่อย", romanization: "kheuun níi nǎao khǒo phâa-hòm nòi", english: "It's cold tonight, may I have a blanket?", hindi: "आज रात ठंड है, एक कंबल दीजिए।"),
            WordExample(thai: "ผ้าห่มอยู่บนเตียง", romanization: "phâa-hòm yùu bon tiang", english: "The blanket is on the bed.", hindi: "कंबल बिस्तर पर है।"),
        ],
        369: [
            WordExample(thai: "ฉันส่องกระจกทุกเช้า", romanization: "chǎn sòong krà-jòk thúk cháo", english: "I look in the mirror every morning.", hindi: "मैं हर सुबह आईने में देखता हूँ।"),
            WordExample(thai: "ระวัง กระจกแตกง่าย", romanization: "rá-wang krà-jòk tàek ngâai", english: "Careful, glass breaks easily.", hindi: "सावधान, शीशा आसानी से टूट जाता है।"),
        ],
        370: [
            WordExample(thai: "คุณพูดได้กี่ภาษา", romanization: "khun phûut dâi kìi phaa-sǎa", english: "How many languages can you speak?", hindi: "आप कितनी भाषाएँ बोल सकते हैं?"),
            WordExample(thai: "ภาษานี้ไม่ยาก", romanization: "phaa-sǎa níi mâi yâak", english: "This language is not difficult.", hindi: "यह भाषा मुश्किल नहीं है।"),
        ],
        371: [
            WordExample(thai: "ผมเรียนภาษาไทยทุกวัน", romanization: "phǒm rian phaa-sǎa-thai thúk wan", english: "I study Thai every day.", hindi: "मैं हर दिन थाई भाषा पढ़ता हूँ।"),
            WordExample(thai: "คุณพูดภาษาไทยเก่งมาก", romanization: "khun phûut phaa-sǎa-thai kèng mâak", english: "You speak Thai very well.", hindi: "आप बहुत अच्छी थाई बोलते हैं।"),
        ],
        372: [
            WordExample(thai: "คุณพูดภาษาอังกฤษได้ไหม", romanization: "khun phûut phaa-sǎa-ang-krìt dâi mǎi", english: "Can you speak English?", hindi: "क्या आप अंग्रेज़ी बोल सकते हैं?"),
            WordExample(thai: "เขาสอนภาษาอังกฤษที่โรงเรียน", romanization: "khǎo sǒon phaa-sǎa-ang-krìt thîi roong-rian", english: "He teaches English at school.", hindi: "वह स्कूल में अंग्रेज़ी पढ़ाता है।"),
        ],
        373: [
            WordExample(thai: "ช่วยแปลให้หน่อยได้ไหม", romanization: "chûai plae hâi nòi dâi mǎi", english: "Can you translate for me?", hindi: "क्या आप मेरे लिए अनुवाद कर सकते हैं?"),
            WordExample(thai: "คำนี้แปลว่าอะไร", romanization: "kham níi plae wâa à-rai", english: "What does this word mean?", hindi: "इस शब्द का मतलब क्या है?"),
        ],
        374: [
            WordExample(thai: "นี่หมายความว่าอะไร", romanization: "nîi mǎai-khwaam-wâa à-rai", english: "What does this mean?", hindi: "इसका मतलब क्या है?"),
            WordExample(thai: "หมายความว่าเขาไม่มาใช่ไหม", romanization: "mǎai-khwaam-wâa khǎo mâi maa châi mǎi", english: "It means he is not coming, right?", hindi: "मतलब वह नहीं आ रहा, है ना?"),
        ],
        375: [
            WordExample(thai: "ผมจะโทรหาคุณพรุ่งนี้", romanization: "phǒm jà thoo hǎa khun phrûng-níi", english: "I will call you tomorrow.", hindi: "मैं कल आपको फ़ोन करूँगा।"),
            WordExample(thai: "แม่โทรมาเมื่อเช้า", romanization: "mâe thoo maa mêua-cháo", english: "Mom called this morning.", hindi: "माँ ने सुबह फ़ोन किया।"),
        ],
        376: [
            WordExample(thai: "ผมส่งข้อความหาคุณแล้ว", romanization: "phǒm sòng khôo-khwaam hǎa khun láew", english: "I already sent you a message.", hindi: "मैंने आपको मैसेज भेज दिया।"),
            WordExample(thai: "คุณอ่านข้อความหรือยัง", romanization: "khun àan khôo-khwaam rěu yang", english: "Have you read the message yet?", hindi: "क्या आपने मैसेज पढ़ लिया?"),
        ],
        377: [
            WordExample(thai: "อีเมลของคุณคืออะไร", romanization: "ii-meo khǒong khun kheu à-rai", english: "What is your email?", hindi: "आपका ईमेल क्या है?"),
            WordExample(thai: "ส่งอีเมลหาผมได้", romanization: "sòng ii-meo hǎa phǒm dâi", english: "You can send me an email.", hindi: "आप मुझे ईमेल भेज सकते हैं।"),
        ],
        378: [
            WordExample(thai: "ขอเบอร์หน่อยได้ไหม", romanization: "khǒo bəə nòi dâi mǎi", english: "Can I have your number?", hindi: "क्या मुझे आपका नंबर मिल सकता है?"),
            WordExample(thai: "นี่เบอร์ใหม่ของฉัน", romanization: "nîi bəə mài khǒong chǎn", english: "This is my new number.", hindi: "यह मेरा नया नंबर है।"),
        ],
        379: [
            WordExample(thai: "ที่อยู่ของคุณคืออะไร", romanization: "thîi-yùu khǒong khun kheu à-rai", english: "What is your address?", hindi: "आपका पता क्या है?"),
            WordExample(thai: "เขียนที่อยู่ที่นี่", romanization: "khǐan thîi-yùu thîi-nîi", english: "Write the address here.", hindi: "पता यहाँ लिखिए।"),
        ],
        380: [
            WordExample(thai: "ชื่อเล่นของคุณคืออะไร", romanization: "chêu-lên khǒong khun kheu à-rai", english: "What is your nickname?", hindi: "आपका निकनेम क्या है?"),
            WordExample(thai: "คนไทยมีชื่อเล่นทุกคน", romanization: "khon thai mii chêu-lên thúk khon", english: "Every Thai person has a nickname.", hindi: "हर थाई व्यक्ति का एक निकनेम होता है।"),
        ],
        381: [
            WordExample(thai: "เขียนชื่อและนามสกุล", romanization: "khǐan chêu láe naam-sà-kun", english: "Write your first and last name.", hindi: "नाम और सरनेम लिखिए।"),
            WordExample(thai: "นามสกุลของเขายาวมาก", romanization: "naam-sà-kun khǒong khǎo yaao mâak", english: "His surname is very long.", hindi: "उसका सरनेम बहुत लंबा है।"),
        ],
        382: [
            WordExample(thai: "เพื่อนบ้านของผมใจดี", romanization: "phêuan-bâan khǒong phǒm jai-dii", english: "My neighbor is kind.", hindi: "मेरा पड़ोसी दयालु है।"),
            WordExample(thai: "ฉันคุยกับเพื่อนบ้านทุกเช้า", romanization: "chǎn khui kàp phêuan-bâan thúk cháo", english: "I chat with my neighbor every morning.", hindi: "मैं हर सुबह पड़ोसी से बात करती हूँ।"),
        ],
        383: [
            WordExample(thai: "หัวหน้าของฉันใจดีมาก", romanization: "hǔa-nâa khǒong chǎn jai-dii mâak", english: "My boss is very kind.", hindi: "मेरा बॉस बहुत दयालु है।"),
            WordExample(thai: "พรุ่งนี้หัวหน้าไม่มา", romanization: "phrûng-níi hǔa-nâa mâi maa", english: "The boss is not coming tomorrow.", hindi: "कल बॉस नहीं आएगा।"),
        ],
        384: [
            WordExample(thai: "ผมกินข้าวกับเพื่อนร่วมงาน", romanization: "phǒm kin khâao kàp phêuan-rûam-ngaan", english: "I eat with my colleagues.", hindi: "मैं सहकर्मियों के साथ खाना खाता हूँ।"),
            WordExample(thai: "เพื่อนร่วมงานของฉันพูดภาษาไทยได้", romanization: "phêuan-rûam-ngaan khǒong chǎn phûut phaa-sǎa-thai dâi", english: "My colleague can speak Thai.", hindi: "मेरा सहकर्मी थाई बोल सकता है।"),
        ],
        385: [
            WordExample(thai: "วันนี้มีประชุม", romanization: "wan-níi mii prà-chum", english: "There is a meeting today.", hindi: "आज मीटिंग है।"),
            WordExample(thai: "หัวหน้าอยู่ในห้องประชุม", romanization: "hǔa-nâa yùu nai hông prà-chum", english: "The boss is in the meeting room.", hindi: "बॉस मीटिंग रूम में है।"),
        ],
        386: [
            WordExample(thai: "คุณทำงานอะไร", romanization: "khun tham-ngaan à-rai", english: "What work do you do?", hindi: "आप क्या काम करते हैं?"),
            WordExample(thai: "วันนี้งานเยอะมาก", romanization: "wan-níi ngaan yə́ mâak", english: "There is a lot of work today.", hindi: "आज बहुत काम है।"),
        ],
        387: [
            WordExample(thai: "เราคุยกันทุกวัน", romanization: "rao khui kan thúk wan", english: "We talk every day.", hindi: "हम हर दिन बात करते हैं।"),
            WordExample(thai: "ฉันชอบคุยกับเพื่อน", romanization: "chǎn chôop khui kàp phêuan", english: "I like chatting with friends.", hindi: "मुझे दोस्तों से बात करना पसंद है।"),
        ],
        388: [
            WordExample(thai: "คำนี้อ่านว่าอะไร", romanization: "kham níi àan wâa à-rai", english: "How do you read this word?", hindi: "यह शब्द कैसे पढ़ते हैं?"),
            WordExample(thai: "วันนี้ฉันเรียนคำใหม่ห้าคำ", romanization: "wan-níi chǎn rian kham mài hâa kham", english: "Today I learned five new words.", hindi: "आज मैंने पाँच नए शब्द सीखे।"),
        ],
        389: [
            WordExample(thai: "ฉันปวดขา", romanization: "chǎn pùat khǎa", english: "My leg hurts.", hindi: "मेरी टांग में दर्द है।"),
            WordExample(thai: "ขาของเขายาวมาก", romanization: "khǎa khǒong kháo yaao mâak", english: "His legs are very long.", hindi: "उसकी टांगें बहुत लंबी हैं।"),
        ],
        390: [
            WordExample(thai: "ฉันเจ็บแขน", romanization: "chǎn jèp khǎen", english: "My arm hurts.", hindi: "मेरी बांह में दर्द है।"),
            WordExample(thai: "ยกแขนขึ้นหน่อยครับ", romanization: "yók khǎen khûen nòi khráp", english: "Please raise your arm.", hindi: "कृपया अपनी बांह ऊपर उठाइए।"),
        ],
        391: [
            WordExample(thai: "ฉันปวดท้อง", romanization: "chǎn pùat thóong", english: "I have a stomachache.", hindi: "मेरे पेट में दर्द है।"),
            WordExample(thai: "ปวดท้องมาก ไปหาหมอ", romanization: "pùat thóong mâak pai hǎa mǒo", english: "My stomach hurts a lot, I am going to the doctor.", hindi: "पेट में बहुत दर्द है, डॉक्टर के पास जा रहा हूं।"),
        ],
        392: [
            WordExample(thai: "อ้าปากหน่อยครับ", romanization: "âa pàak nòi khráp", english: "Please open your mouth.", hindi: "कृपया मुंह खोलिए।"),
            WordExample(thai: "ปากของฉันแห้ง", romanization: "pàak khǒong chǎn hâeng", english: "My mouth is dry.", hindi: "मेरा मुंह सूखा है।"),
        ],
        393: [
            WordExample(thai: "จมูกของฉันเล็ก", romanization: "jà-mùuk khǒong chǎn lék", english: "My nose is small.", hindi: "मेरी नाक छोटी है।"),
            WordExample(thai: "เป็นหวัด จมูกตัน", romanization: "pen wàt jà-mùuk tan", english: "I have a cold and my nose is blocked.", hindi: "ज़ुकाम है, नाक बंद है।"),
        ],
        394: [
            WordExample(thai: "ฉันปวดหู", romanization: "chǎn pùat hǔu", english: "My ear hurts.", hindi: "मेरे कान में दर्द है।"),
            WordExample(thai: "ช้างมีหูใหญ่", romanization: "cháang mii hǔu yài", english: "Elephants have big ears.", hindi: "हाथी के कान बड़े होते हैं।"),
        ],
        395: [
            WordExample(thai: "ผิวของเขาสวยมาก", romanization: "phǐw khǒong kháo sǔai mâak", english: "Her skin is very beautiful.", hindi: "उसकी त्वचा बहुत सुंदर है।"),
            WordExample(thai: "แดดแรง ระวังผิวด้วย", romanization: "dàet raeng rá-wang phǐw dûai", english: "The sun is strong, take care of your skin.", hindi: "धूप तेज़ है, त्वचा का ध्यान रखिए।"),
        ],
        396: [
            WordExample(thai: "เดินมาก ปวดเท้า", romanization: "dern mâak pùat tháo", english: "I walked a lot and my feet hurt.", hindi: "बहुत चला, पैरों में दर्द है।"),
            WordExample(thai: "ถอดรองเท้าก่อนเข้าบ้าน", romanization: "thòt roong-tháo kòn khâo bâan", english: "Take off your shoes before entering the house.", hindi: "घर में जाने से पहले जूते उतारिए।"),
        ],
        397: [
            WordExample(thai: "ฉันเจ็บนิ้ว", romanization: "chǎn jèp níw", english: "My finger hurts.", hindi: "मेरी उंगली में दर्द है।"),
            WordExample(thai: "นิ้วของฉันบวม", romanization: "níw khǒong chǎn buam", english: "My finger is swollen.", hindi: "मेरी उंगली सूज गई है।"),
        ],
        398: [
            WordExample(thai: "ฉันเจ็บคอ", romanization: "chǎn jèp khoo", english: "I have a sore throat.", hindi: "मेरे गले में दर्द है।"),
            WordExample(thai: "คอแห้ง ขอน้ำหน่อย", romanization: "khoo hâeng khǒo náam nòi", english: "My throat is dry, some water please.", hindi: "गला सूख रहा है, थोड़ा पानी दीजिए।"),
        ],
        399: [
            WordExample(thai: "ล้างหน้าทุกเช้า", romanization: "láang nâa thúk cháo", english: "I wash my face every morning.", hindi: "मैं हर सुबह चेहरा धोता हूं।"),
            WordExample(thai: "หน้าของเขาแดง", romanization: "nâa khǒong kháo daeng", english: "His face is red.", hindi: "उसका चेहरा लाल है।"),
        ],
        400: [
            WordExample(thai: "เจ็บตรงไหน", romanization: "jèp trong nǎi", english: "Where does it hurt?", hindi: "कहां दर्द हो रहा है?"),
            WordExample(thai: "ฉันเจ็บมือ", romanization: "chǎn jèp mue", english: "My hand hurts.", hindi: "मेरे हाथ में दर्द है।"),
        ],
        401: [
            WordExample(thai: "ฉันเป็นไข้", romanization: "chǎn pen khâi", english: "I have a fever.", hindi: "मुझे बुखार है।"),
            WordExample(thai: "เขามีไข้สูง", romanization: "kháo mii khâi sǔung", english: "He has a high fever.", hindi: "उसे तेज़ बुखार है।"),
        ],
        402: [
            WordExample(thai: "ฉันไอมาก", romanization: "chǎn ai mâak", english: "I am coughing a lot.", hindi: "मुझे बहुत खांसी हो रही है।"),
            WordExample(thai: "ไอมาสองวันแล้ว", romanization: "ai maa sǒong wan láew", english: "I have been coughing for two days.", hindi: "दो दिन से खांसी है।"),
        ],
        403: [
            WordExample(thai: "ฉันเป็นหวัด", romanization: "chǎn pen wàt", english: "I have a cold.", hindi: "मुझे ज़ुकाम है।"),
            WordExample(thai: "เป็นหวัดต้องพักผ่อน", romanization: "pen wàt tông phák-phòn", english: "When you have a cold, you must rest.", hindi: "ज़ुकाम हो तो आराम करना चाहिए।"),
        ],
        404: [
            WordExample(thai: "ขอยาแก้ปวดหน่อยครับ", romanization: "khǒo yaa kâe pùat nòi khráp", english: "May I have a painkiller, please?", hindi: "कृपया एक दर्द की दवा दीजिए।"),
            WordExample(thai: "กินยาแก้ปวดหลังอาหาร", romanization: "kin yaa kâe pùat lǎng aa-hǎan", english: "Take the painkiller after meals.", hindi: "दर्द की दवा खाने के बाद लीजिए।"),
        ],
        405: [
            WordExample(thai: "ฉันแพ้กุ้ง", romanization: "chǎn pháe kûng", english: "I am allergic to shrimp.", hindi: "मुझे झींगे से एलर्जी है।"),
            WordExample(thai: "คุณแพ้ยาอะไรไหม", romanization: "khun pháe yaa à-rai mǎi", english: "Are you allergic to any medicines?", hindi: "क्या आपको किसी दवा से एलर्जी है?"),
        ],
        406: [
            WordExample(thai: "มีเลือดออก", romanization: "mii lûeat òok", english: "It is bleeding.", hindi: "खून निकल रहा है।"),
            WordExample(thai: "หมอตรวจเลือด", romanization: "mǒo trùat lûeat", english: "The doctor does a blood test.", hindi: "डॉक्टर खून की जांच करते हैं।"),
        ],
        407: [
            WordExample(thai: "ฉันมีแผลที่ขา", romanization: "chǎn mii phlǎe thîi khǎa", english: "I have a wound on my leg.", hindi: "मेरी टांग पर घाव है।"),
            WordExample(thai: "ล้างแผลด้วยน้ำสะอาด", romanization: "láang phlǎe dûai náam sà-àat", english: "Wash the wound with clean water.", hindi: "घाव को साफ पानी से धोइए।"),
        ],
        408: [
            WordExample(thai: "มีอุบัติเหตุบนถนน", romanization: "mii ù-bàt-tì-hèet bon thà-nǒn", english: "There was an accident on the road.", hindi: "सड़क पर एक दुर्घटना हुई।"),
            WordExample(thai: "เกิดอุบัติเหตุ โทรหาตำรวจ", romanization: "kèrt ù-bàt-tì-hèet thoo hǎa tam-rùat", english: "There has been an accident — call the police.", hindi: "दुर्घटना हुई है — पुलिस को फोन कीजिए।"),
        ],
        409: [
            WordExample(thai: "เรียกรถพยาบาลด้วย", romanization: "rîak rót-phá-yaa-baan dûai", english: "Call an ambulance, please!", hindi: "एम्बुलेंस बुलाइए!"),
            WordExample(thai: "รถพยาบาลมาเร็วมาก", romanization: "rót-phá-yaa-baan maa rew mâak", english: "The ambulance came very quickly.", hindi: "एम्बुलेंस बहुत जल्दी आई।"),
        ],
        410: [
            WordExample(thai: "ร้านขายยาอยู่ที่ไหน", romanization: "ráan khǎai yaa yùu thîi-nǎi", english: "Where is the pharmacy?", hindi: "दवाई की दुकान कहां है?"),
            WordExample(thai: "ฉันซื้อยาที่ร้านขายยา", romanization: "chǎn súe yaa thîi ráan khǎai yaa", english: "I buy medicine at the pharmacy.", hindi: "मैं दवाई की दुकान से दवा खरीदता हूं।"),
        ],
        411: [
            WordExample(thai: "คุณมีประกันไหม", romanization: "khun mii prà-kan mǎi", english: "Do you have insurance?", hindi: "क्या आपके पास बीमा है?"),
            WordExample(thai: "ฉันมีประกันสุขภาพ", romanization: "chǎn mii prà-kan sùk-khà-phâap", english: "I have health insurance.", hindi: "मेरे पास स्वास्थ्य बीमा है।"),
        ],
        412: [
            WordExample(thai: "คุณต้องพักผ่อนเยอะๆ", romanization: "khun tông phák-phòn yóe-yóe", english: "You need to rest a lot.", hindi: "आपको खूब आराम करना चाहिए।"),
            WordExample(thai: "วันนี้ฉันพักผ่อนที่บ้าน", romanization: "wan-níi chǎn phák-phòn thîi bâan", english: "Today I am resting at home.", hindi: "आज मैं घर पर आराम कर रहा हूं।"),
        ],
        187: [
            WordExample(thai: "วันนี้ผมดีใจมาก", romanization: "wan-níi pǒm dii-jai mâak", english: "Today I am very happy.", hindi: "आज मैं बहुत खुश हूँ।"),
            WordExample(thai: "ดีใจที่ได้เจอคุณ", romanization: "dii-jai tîi dâai jer kun", english: "I'm glad to meet you.", hindi: "आपसे मिलकर खुशी हुई।"),
        ],
        188: [
            WordExample(thai: "ฉันเสียใจมาก", romanization: "chǎn sǐa-jai mâak", english: "I am very sad.", hindi: "मैं बहुत दुखी हूँ।"),
            WordExample(thai: "อย่าเสียใจนะ", romanization: "yàa sǐa-jai ná", english: "Don't be sad, okay?", hindi: "दुखी मत हो।"),
        ],
        189: [
            WordExample(thai: "อย่าโกรธผมนะ", romanization: "yàa kròot pǒm ná", english: "Don't be angry with me.", hindi: "मुझसे नाराज़ मत हो।"),
            WordExample(thai: "แม่โกรธมาก", romanization: "mâe kròot mâak", english: "Mom is very angry.", hindi: "माँ बहुत गुस्सा हैं।"),
        ],
        190: [
            WordExample(thai: "ผมเบื่อมาก", romanization: "pǒm bùea mâak", english: "I am very bored.", hindi: "मैं बहुत बोर हो रहा हूँ।"),
            WordExample(thai: "ฉันเบื่ออาหารโรงแรม", romanization: "chǎn bùea aa-hǎan roong-raem", english: "I'm bored of the hotel food.", hindi: "मैं होटल के खाने से ऊब गई हूँ।"),
        ],
        191: [
            WordExample(thai: "ผมตื่นเต้นมาก", romanization: "pǒm tùun-tên mâak", english: "I am very excited.", hindi: "मैं बहुत उत्साहित हूँ।"),
            WordExample(thai: "เด็กๆ ตื่นเต้น", romanization: "dèk-dèk tùun-tên", english: "The children are excited.", hindi: "बच्चे उत्साहित हैं।"),
        ],
        192: [
            WordExample(thai: "ผมคิดถึงคุณ", romanization: "pǒm kít-tǔng kun", english: "I miss you.", hindi: "मुझे तुम्हारी याद आती है।"),
            WordExample(thai: "ฉันคิดถึงบ้าน", romanization: "chǎn kít-tǔng bâan", english: "I miss home.", hindi: "मुझे घर की याद आती है।"),
        ],
        193: [
            WordExample(thai: "เจอกันพรุ่งนี้", romanization: "jer kan prûng-níi", english: "See you tomorrow.", hindi: "कल मिलते हैं।"),
            WordExample(thai: "ผมเจอเพื่อนที่ตลาด", romanization: "pǒm jer pûean tîi tà-làat", english: "I met a friend at the market.", hindi: "मैं बाज़ार में दोस्त से मिला।"),
        ],
        194: [
            WordExample(thai: "รอสักครู่นะครับ", romanization: "ror-sàk-krûu ná kráp", english: "Please wait a moment.", hindi: "कृपया एक क्षण रुकिए।"),
            WordExample(thai: "รอสักครู่ อาหารกำลังมา", romanization: "ror-sàk-krûu, aa-hǎan kam-lang maa", english: "Wait a moment, the food is coming.", hindi: "एक मिनट रुकिए, खाना आ रहा है।"),
        ],
        195: [
            WordExample(thai: "พรุ่งนี้ฝนอาจจะตก", romanization: "prûng-níi fǒn àat-jà tòk", english: "It may rain tomorrow.", hindi: "कल शायद बारिश हो।"),
            WordExample(thai: "ผมอาจจะไปตลาด", romanization: "pǒm àat-jà pai tà-làat", english: "I might go to the market.", hindi: "मैं शायद बाज़ार जाऊँ।"),
        ],
        196: [
            WordExample(thai: "แน่นอนครับ", romanization: "nâe-non kráp", english: "Of course!", hindi: "बिलकुल!"),
            WordExample(thai: "อาหารที่นี่อร่อยแน่นอน", romanization: "aa-hǎan tîi-nîi à-ròi nâe-non", english: "The food here is definitely delicious.", hindi: "यहाँ का खाना पक्का स्वादिष्ट है।"),
        ],
        197: [
            WordExample(thai: "ไปกินข้าวด้วยกันไหม", romanization: "pai kin kâao dûai-kan mǎi?", english: "Shall we go eat together?", hindi: "क्या साथ में खाना खाने चलें?"),
            WordExample(thai: "เราทำงานด้วยกัน", romanization: "rao tam-ngaan dûai-kan", english: "We work together.", hindi: "हम साथ में काम करते हैं।"),
        ],
        198: [
            WordExample(thai: "ผมมาคนเดียว", romanization: "pǒm maa kon-diao", english: "I came alone.", hindi: "मैं अकेला आया हूँ।"),
            WordExample(thai: "คุณอยู่คนเดียวไหม", romanization: "kun yùu kon-diao mǎi?", english: "Do you live alone?", hindi: "क्या आप अकेले रहते हैं?"),
        ],
        199: [
            WordExample(thai: "กระเป๋าใบนี้เท่าไหร่", romanization: "krà-pǎo bai níi tâo-rài", english: "How much is this bag?", hindi: "यह बैग कितने का है?"),
            WordExample(thai: "ฉันชอบกระเป๋าใบนี้", romanization: "chǎn châwp krà-pǎo bai níi", english: "I like this bag.", hindi: "मुझे यह बैग पसंद है।"),
        ],
        200: [
            WordExample(thai: "เสื้อตัวนี้สวยมาก", romanization: "sûea tua níi sǔai mâak", english: "This shirt is very beautiful.", hindi: "यह शर्ट बहुत सुंदर है।"),
            WordExample(thai: "ฉันซื้อเสื้อใหม่", romanization: "chǎn súe sûea mài", english: "I am buying a new shirt.", hindi: "मैं नई शर्ट खरीद रही हूँ।"),
        ],
        201: [
            WordExample(thai: "รองเท้าคู่นี้เท่าไหร่", romanization: "rawng-táao khûu níi tâo-rài", english: "How much is this pair of shoes?", hindi: "जूतों की यह जोड़ी कितने की है?"),
            WordExample(thai: "ฉันชอบรองเท้าสีดำ", romanization: "chǎn châwp rawng-táao sǐi dam", english: "I like black shoes.", hindi: "मुझे काले जूते पसंद हैं।"),
        ],
        202: [
            WordExample(thai: "มีที่ชาร์จไหม", romanization: "mii tîi-châat mǎi", english: "Do you have a charger?", hindi: "क्या आपके पास चार्जर है?"),
            WordExample(thai: "ฉันซื้อที่ชาร์จใหม่", romanization: "chǎn súe tîi-châat mài", english: "I am buying a new charger.", hindi: "मैं नया चार्जर खरीद रही हूँ।"),
        ],
        203: [
            WordExample(thai: "ที่ตลาดต่อราคาได้", romanization: "tîi tà-làat tàw raa-khaa dâi", english: "You can bargain at the market.", hindi: "बाज़ार में मोल-भाव कर सकते हैं।"),
            WordExample(thai: "ฉันชอบต่อราคา", romanization: "chǎn châwp tàw raa-khaa", english: "I like to bargain.", hindi: "मुझे मोल-भाव करना पसंद है।"),
        ],
        204: [
            WordExample(thai: "แพงมาก ลดหน่อยได้ไหม", romanization: "phaeng mâak, lót nòi dâi mǎi", english: "Very expensive — can you lower it a bit?", hindi: "बहुत महँगा है, थोड़ा कम कर सकते हैं?"),
            WordExample(thai: "ลดหน่อยได้ไหมครับ", romanization: "lót nòi dâi mǎi khráp", english: "Can you give a small discount? (polite, male)", hindi: "थोड़ा कम कर देंगे? (विनम्र, पुरुष)"),
        ],
        205: [
            WordExample(thai: "มีไซส์ใหญ่ไหม", romanization: "mii sái yài mǎi", english: "Do you have a bigger size?", hindi: "क्या बड़ा साइज़ है?"),
            WordExample(thai: "ไซส์นี้เล็กไป", romanization: "sái níi lék pai", english: "This size is too small.", hindi: "यह साइज़ बहुत छोटा है।"),
        ],
        206: [
            WordExample(thai: "เสื้อตัวนี้พอดี", romanization: "sûea tua níi phaw-dii", english: "This shirt fits just right.", hindi: "यह शर्ट बिलकुल फिट है।"),
            WordExample(thai: "รองเท้าคู่นี้พอดีเลย", romanization: "rawng-táao khûu níi phaw-dii loei", english: "These shoes fit perfectly.", hindi: "ये जूते एकदम फिट हैं।"),
        ],
        207: [
            WordExample(thai: "ลองได้ไหม", romanization: "lawng dâi mǎi", english: "Can I try it on?", hindi: "क्या मैं आज़मा सकता हूँ?"),
            WordExample(thai: "ฉันลองเสื้อตัวนี้", romanization: "chǎn lawng sûea tua níi", english: "I am trying on this shirt.", hindi: "मैं यह शर्ट पहनकर देख रही हूँ।"),
        ],
        208: [
            WordExample(thai: "ขอใบเสร็จหน่อย", romanization: "khǎw bai-sèt nòi", english: "May I have the receipt, please?", hindi: "रसीद दे दीजिए।"),
            WordExample(thai: "มีใบเสร็จไหม", romanization: "mii bai-sèt mǎi", english: "Is there a receipt?", hindi: "क्या रसीद है?"),
        ],
        209: [
            WordExample(thai: "ขอถุงพลาสติกหน่อย", romanization: "khǎw tǔng pláat-sà-tìk nòi", english: "Can I have a plastic bag, please?", hindi: "एक प्लास्टिक थैली दे दीजिए।"),
            WordExample(thai: "ไม่เอาถุงพลาสติก", romanization: "mâi ao tǔng pláat-sà-tìk", english: "I don't want a plastic bag.", hindi: "मुझे प्लास्टिक थैली नहीं चाहिए।"),
        ],
        210: [
            WordExample(thai: "ร้านเปิดกี่โมง", romanization: "ráan pèrt kìi mohng", english: "What time does the shop open?", hindi: "दुकान कितने बजे खुलती है?"),
            WordExample(thai: "ตลาดปิดกี่โมง", romanization: "tà-làat pìt kìi mohng", english: "What time does the market close?", hindi: "बाज़ार कितने बजे बंद होता है?"),
        ],
        211: [
            WordExample(thai: "ชายหาดสวยมาก", romanization: "chaai-hàat sǔai mâak", english: "The beach is very beautiful.", hindi: "समुद्र तट बहुत सुंदर है।"),
            WordExample(thai: "พรุ่งนี้ผมไปชายหาด", romanization: "phrûng-níi phǒm pai chaai-hàat", english: "Tomorrow I am going to the beach.", hindi: "कल मैं बीच पर जाऊँगा।"),
        ],
        212: [
            WordExample(thai: "เกาะนี้สวยมาก", romanization: "kò níi sǔai mâak", english: "This island is very beautiful.", hindi: "यह द्वीप बहुत सुंदर है।"),
            WordExample(thai: "นั่งเรือไปเกาะ", romanization: "nâng rʉa pai kò", english: "Take a boat to the island.", hindi: "नाव से द्वीप जाते हैं।"),
        ],
        213: [
            WordExample(thai: "ขอตั๋วสองใบครับ", romanization: "khǒo tǔa sǒong bai khráp", english: "Two tickets, please.", hindi: "दो टिकट दीजिए।"),
            WordExample(thai: "ตั๋วรถไฟเท่าไหร่", romanization: "tǔa rót-fai thâo-rài", english: "How much is the train ticket?", hindi: "ट्रेन का टिकट कितने का है?"),
        ],
        214: [
            WordExample(thai: "นั่งเรือสนุกมาก", romanization: "nâng rʉa sà-nùk mâak", english: "Riding the boat is a lot of fun.", hindi: "नाव की सवारी बहुत मज़ेदार है।"),
            WordExample(thai: "เรือมาแล้ว", romanization: "rʉa maa láeo", english: "The boat has arrived.", hindi: "नाव आ गई।"),
        ],
        215: [
            WordExample(thai: "นั่งวินมอเตอร์ไซค์ไปตลาด", romanization: "nâng win-moo-ter-sai pai tà-làat", english: "Take a motorbike taxi to the market.", hindi: "बाइक टैक्सी से बाज़ार जाते हैं।"),
            WordExample(thai: "วินมอเตอร์ไซค์เร็วมาก", romanization: "win-moo-ter-sai reo mâak", english: "The motorbike taxi is very fast.", hindi: "बाइक टैक्सी बहुत तेज़ है।"),
        ],
        216: [
            WordExample(thai: "ข้าวเหนียวมะม่วงหวานมาก", romanization: "khâao-nǐao má-mûang wǎan mâak", english: "Mango sticky rice is very sweet.", hindi: "मैंगो स्टिकी राइस बहुत मीठा होता है।"),
            WordExample(thai: "ขอข้าวเหนียวมะม่วงหนึ่งที่", romanization: "khǒo khâao-nǐao má-mûang nʉ̀ng thîi", english: "One mango sticky rice, please.", hindi: "एक मैंगो स्टिकी राइस दीजिए।"),
        ],
        217: [
            WordExample(thai: "ส้มตำเผ็ดมาก", romanization: "sôm-tam phèt mâak", english: "Som tam is very spicy.", hindi: "सोम-तम बहुत तीखा होता है।"),
            WordExample(thai: "ฉันชอบส้มตำ", romanization: "chǎn chôop sôm-tam", english: "I like som tam.", hindi: "मुझे सोम-तम पसंद है।"),
        ],
        218: [
            WordExample(thai: "ขอผัดไทยหนึ่งจาน", romanization: "khǒo phàt-thai nʉ̀ng jaan", english: "One plate of pad thai, please.", hindi: "एक प्लेट पैड थाई दीजिए।"),
            WordExample(thai: "ผัดไทยอร่อยมาก", romanization: "phàt-thai à-ròi mâak", english: "Pad thai is very delicious.", hindi: "पैड थाई बहुत स्वादिष्ट है।"),
        ],
        219: [
            WordExample(thai: "ขวดน้ำอยู่ที่ไหน", romanization: "khùat náam yùu thîi-nǎi", english: "Where is the water bottle?", hindi: "पानी की बोतल कहाँ है?"),
            WordExample(thai: "ผมมีขวดน้ำ", romanization: "phǒm mii khùat náam", english: "I have a water bottle.", hindi: "मेरे पास पानी की बोतल है।"),
        ],
        220: [
            WordExample(thai: "เช็คบิลด้วยครับ", romanization: "chék-bin dûai khráp", english: "The bill, please. (male)", hindi: "बिल दीजिए। (पुरुष)"),
            WordExample(thai: "ขอเช็คบิลหน่อยค่ะ", romanization: "khǒo chék-bin nòi khâ", english: "Could I get the bill? (female)", hindi: "ज़रा बिल लाइए। (स्त्री)"),
        ],
        221: [
            WordExample(thai: "ขอช้อนหน่อยครับ", romanization: "khǒo chóon nòi khráp", english: "May I have a spoon, please?", hindi: "ज़रा एक चम्मच दीजिए।"),
            WordExample(thai: "ช้อนไม่สะอาด", romanization: "chóon mâi sà-àat", english: "The spoon is not clean.", hindi: "चम्मच साफ़ नहीं है।"),
        ],
        222: [
            WordExample(thai: "ขอส้อมหน่อยค่ะ", romanization: "khǒo sôom nòi khâ", english: "May I have a fork, please?", hindi: "ज़रा एक काँटा दीजिए।"),
            WordExample(thai: "ผมไม่มีส้อม", romanization: "phǒm mâi mii sôom", english: "I don't have a fork.", hindi: "मेरे पास काँटा नहीं है।"),
        ],
        3: [
            WordExample(thai: "สวัสดีครับ", romanization: "sà-wàt-dii kráp", english: "Hello (polite, male speaker).", hindi: "नमस्ते (पुरुष, विनम्रता से)।"),
            WordExample(thai: "ขอบคุณมากครับ", romanization: "khòp-khun mâak kráp", english: "Thank you very much.", hindi: "बहुत-बहुत धन्यवाद।"),
            WordExample(thai: "ผมเข้าใจครับ", romanization: "phǒm khâo-jai kráp", english: "I understand.", hindi: "मैं समझ गया।"),
        ],
        22: [
            WordExample(thai: "ฉันหิวค่ะ", romanization: "chǎn hǐu khâ", english: "I am hungry.", hindi: "मुझे भूख लगी है।"),
            WordExample(thai: "ฉันชอบอาหารไทยค่ะ", romanization: "chǎn chôp aa-hǎan thai khâ", english: "I like Thai food.", hindi: "मुझे थाई खाना पसंद है।"),
            WordExample(thai: "ฉันมาจากอินเดียค่ะ", romanization: "chǎn maa jàak in-dia khâ", english: "I come from India.", hindi: "मैं भारत से आई हूँ।"),
        ],
        33: [
            WordExample(thai: "ขอไม่เผ็ดครับ", romanization: "khǒo mâi phèt kráp", english: "Not spicy, please.", hindi: "तीखा नहीं चाहिए, प्लीज़।"),
            WordExample(thai: "อาหารไทยเผ็ดมาก", romanization: "aa-hǎan thai phèt mâak", english: "Thai food is very spicy.", hindi: "थाई खाना बहुत तीखा होता है।"),
        ],
        42: [
            WordExample(thai: "ห้องนี้เล็กมากครับ", romanization: "hông níi lék mâak kráp", english: "This room is very small.", hindi: "यह कमरा बहुत छोटा है।"),
            WordExample(thai: "รถคันนี้เล็ก", romanization: "rót khan níi lék", english: "This car is small.", hindi: "यह गाड़ी छोटी है।"),
        ],
        51: [
            WordExample(thai: "วันนี้อากาศดี", romanization: "wan-níi aa-kàat dii", english: "The weather is nice today.", hindi: "आज मौसम अच्छा है।"),
            WordExample(thai: "วันนี้ผมไปตลาด", romanization: "wan-níi phǒm pai tà-làat", english: "Today I am going to the market.", hindi: "आज मैं बाज़ार जा रहा हूँ।"),
            WordExample(thai: "วันนี้ร้อนมากครับ", romanization: "wan-níi rón mâak kráp", english: "It is very hot today.", hindi: "आज बहुत गर्मी है।"),
        ],
        57: [
            WordExample(thai: "ผมตื่นเช้า", romanization: "phǒm tùuen cháao", english: "I wake up early in the morning.", hindi: "मैं सुबह जल्दी उठता हूँ।"),
            WordExample(thai: "เจอกันพรุ่งนี้เช้าครับ", romanization: "joe kan phrûng-níi cháao kráp", english: "See you tomorrow morning.", hindi: "कल सुबह मिलते हैं।"),
        ],
        68: [
            WordExample(thai: "ผู้ชายคนนั้นเป็นครู", romanization: "phûu-chaai khon nân pen khruu", english: "That man is a teacher.", hindi: "वह आदमी शिक्षक है।"),
            WordExample(thai: "ห้องน้ำผู้ชายอยู่ที่ไหนครับ", romanization: "hông-náam phûu-chaai yùu thîi-nǎi kráp", english: "Where is the men's toilet?", hindi: "पुरुषों का शौचालय कहाँ है?"),
        ],
        74: [
            WordExample(thai: "ผมปวดตาครับ", romanization: "phǒm pùat taa kráp", english: "My eyes hurt.", hindi: "मेरी आँखों में दर्द है।"),
            WordExample(thai: "เธอตาสวยมาก", romanization: "thoe taa sǔai mâak", english: "She has very beautiful eyes.", hindi: "उसकी आँखें बहुत सुंदर हैं।"),
        ],
        80: [
            WordExample(thai: "ผมอยากไปหาหมอครับ", romanization: "phǒm yàak pai hǎa mǒo kráp", english: "I want to see a doctor.", hindi: "मैं डॉक्टर के पास जाना चाहता हूँ।"),
            WordExample(thai: "หมออยู่ที่โรงพยาบาล", romanization: "mǒo yùu thîi roong-phá-yaa-baan", english: "The doctor is at the hospital.", hindi: "डॉक्टर अस्पताल में हैं।"),
        ],
        92: [
            WordExample(thai: "วันนี้ลมแรงมาก", romanization: "wan-níi lom raeng mâak", english: "The wind is very strong today.", hindi: "आज हवा बहुत तेज़ है।"),
            WordExample(thai: "ที่ทะเลมีลมเย็น", romanization: "thîi thá-lee mii lom yen", english: "There is a cool breeze at the sea.", hindi: "समुद्र पर ठंडी हवा चलती है।"),
        ],
        110: [
            WordExample(thai: "อันนี้ห้าสิบบาทครับ", romanization: "an-níi hâa-sìp bàat kráp", english: "This one is fifty baht.", hindi: "यह पचास बात का है।"),
            WordExample(thai: "ทั้งหมดร้อยบาทครับ", romanization: "tháng-mòt rói bàat kráp", english: "Altogether it is one hundred baht.", hindi: "कुल मिलाकर सौ बात हुए।"),
        ],
        118: [
            WordExample(thai: "ผมเขียนภาษาไทยไม่ได้", romanization: "phǒm khǐan phaa-sǎa thai mâi dâai", english: "I cannot write Thai.", hindi: "मैं थाई नहीं लिख सकता।"),
            WordExample(thai: "ช่วยเขียนให้หน่อยครับ", romanization: "chûai khǐan hâi nòi kráp", english: "Please write it down for me.", hindi: "कृपया मेरे लिए लिख दीजिए।"),
        ],
        124: [
            WordExample(thai: "ผมเดินไปตลาด", romanization: "phǒm doen pai tà-làat", english: "I walk to the market.", hindi: "मैं पैदल बाज़ार जाता हूँ।"),
            WordExample(thai: "เดินตรงไปครับ", romanization: "doen trong-pai kráp", english: "Walk straight ahead.", hindi: "सीधे चलते जाइए।"),
        ],
        132: [
            WordExample(thai: "ช่วยเปิดไฟหน่อยครับ", romanization: "chûai pòet fai nòi kráp", english: "Please turn on the light.", hindi: "कृपया बत्ती जला दीजिए।"),
            WordExample(thai: "ร้านเปิดกี่โมงครับ", romanization: "ráan pòet kìi moong kráp", english: "What time does the shop open?", hindi: "दुकान कितने बजे खुलती है?"),
        ],
        138: [
            WordExample(thai: "ภาษาไทยไม่ง่ายครับ", romanization: "phaa-sǎa thai mâi ngâai kráp", english: "The Thai language is not easy.", hindi: "थाई भाषा आसान नहीं है।"),
            WordExample(thai: "อาหารนี้ทำง่าย", romanization: "aa-hǎan níi tham ngâai", english: "This dish is easy to make.", hindi: "यह खाना बनाना आसान है।"),
        ],
        144: [
            WordExample(thai: "สนามบินอยู่ไกลไหมครับ", romanization: "sà-nǎam-bin yùu klai mǎi kráp", english: "Is the airport far away?", hindi: "क्या हवाई अड्डा दूर है?"),
            WordExample(thai: "ไม่ไกลครับ เดินไปได้", romanization: "mâi klai kráp, doen pai dâai", english: "It is not far, you can walk there.", hindi: "दूर नहीं है, पैदल जा सकते हैं।"),
        ],
        152: [
            WordExample(thai: "เอาชาหรือกาแฟครับ", romanization: "ao chaa rǔue kaa-fae kráp", english: "Do you want tea or coffee?", hindi: "चाय लेंगे या कॉफ़ी?"),
            WordExample(thai: "ไปวันนี้หรือพรุ่งนี้ครับ", romanization: "pai wan-níi rǔue phrûng-níi kráp", english: "Are we going today or tomorrow?", hindi: "आज चलें या कल?"),
        ],
        163: [
            WordExample(thai: "ผมชอบกินข้าวผัดไก่", romanization: "phǒm chôp kin khâao-phàt kài", english: "I like eating chicken fried rice.", hindi: "मुझे चिकन फ्राइड राइस खाना पसंद है।"),
            WordExample(thai: "ขอแกงไก่หนึ่งที่ครับ", romanization: "khǒo kaeng kài nèung thîi kráp", english: "One chicken curry, please.", hindi: "एक चिकन करी दीजिए।"),
        ],
        169: [
            WordExample(thai: "ขอก๋วยเตี๋ยวหนึ่งชามครับ", romanization: "khǒo kǔai-tǐao nèung chaam kráp", english: "One bowl of noodles, please.", hindi: "एक कटोरा नूडल्स दीजिए।"),
            WordExample(thai: "ก๋วยเตี๋ยวร้านนี้อร่อยมาก", romanization: "kǔai-tǐao ráan níi à-ròi mâak", english: "The noodles at this shop are very delicious.", hindi: "इस दुकान के नूडल्स बहुत स्वादिष्ट हैं।"),
        ],
        176: [
            WordExample(thai: "เลี้ยวขวาตรงนี้ครับ", romanization: "líao khwǎa trong níi kráp", english: "Turn right here.", hindi: "यहाँ दाएँ मुड़िए।"),
            WordExample(thai: "ห้องน้ำอยู่ทางขวาครับ", romanization: "hông-náam yùu thaang khwǎa kráp", english: "The toilet is on the right.", hindi: "शौचालय दाईं ओर है।"),
        ],
        182: [
            WordExample(thai: "ขอน้ำแข็งหน่อยครับ", romanization: "khǒo nám-khǎeng nòi kráp", english: "Some ice, please.", hindi: "थोड़ी बर्फ़ दीजिए।"),
            WordExample(thai: "ไม่ใส่น้ำแข็งครับ", romanization: "mâi sài nám-khǎeng kráp", english: "No ice, please.", hindi: "बर्फ़ मत डालिए।"),
        ],
        4: [
            WordExample(thai: "สวัสดีค่ะ", romanization: "sà-wàt-dii khâ", english: "Hello. (female speaker)", hindi: "नमस्ते। (स्त्री वक्ता)"),
            WordExample(thai: "ขอบคุณมากค่ะ", romanization: "khòp-khun mâak khâ", english: "Thank you very much.", hindi: "बहुत-बहुत धन्यवाद।"),
            WordExample(thai: "ใช่ค่ะ ฉันเข้าใจ", romanization: "châi khâ chǎn khâo-jai", english: "Yes, I understand.", hindi: "हाँ, मैं समझती हूँ।"),
        ],
        23: [
            WordExample(thai: "คุณชื่ออะไรครับ", romanization: "khun chûue à-rai kráp", english: "What is your name?", hindi: "आपका नाम क्या है?"),
            WordExample(thai: "คุณสบายดีไหมครับ", romanization: "khun sà-baai-dii mǎi kráp", english: "How are you?", hindi: "आप कैसे हैं?"),
            WordExample(thai: "คุณมาจากประเทศอะไรครับ", romanization: "khun maa jàak prà-thêet à-rai kráp", english: "Which country are you from?", hindi: "आप किस देश से हैं?"),
        ],
        36: [
            WordExample(thai: "ผมมาจากอินเดียครับ", romanization: "phǒm maa jàak in-dia kráp", english: "I come from India.", hindi: "मैं भारत से आया हूँ।"),
            WordExample(thai: "เพื่อนจะมาพรุ่งนี้ครับ", romanization: "phûean jà maa phrûng-níi kráp", english: "My friend will come tomorrow.", hindi: "मेरा दोस्त कल आएगा।"),
            WordExample(thai: "มากินข้าวด้วยกันครับ", romanization: "maa kin khâao dûai-kan kráp", english: "Come eat together with us.", hindi: "आइए, साथ में खाना खाते हैं।"),
        ],
        43: [
            WordExample(thai: "วันนี้อากาศร้อนมากครับ", romanization: "wan-níi aa-kàat rón mâak kráp", english: "Today the weather is very hot.", hindi: "आज मौसम बहुत गरम है।"),
            WordExample(thai: "ขอน้ำร้อนหน่อยครับ", romanization: "khǒo nám-rón nòi kráp", english: "May I have some hot water, please?", hindi: "थोड़ा गरम पानी दीजिए।"),
        ],
        52: [
            WordExample(thai: "พรุ่งนี้ผมไปสนามบินครับ", romanization: "phrûng-níi phǒm pai sà-nǎam-bin kráp", english: "Tomorrow I am going to the airport.", hindi: "कल मैं हवाई अड्डे जाऊँगा।"),
            WordExample(thai: "เจอกันพรุ่งนี้ครับ", romanization: "joe-kan phrûng-níi kráp", english: "See you tomorrow.", hindi: "कल मिलते हैं।"),
        ],
        58: [
            WordExample(thai: "เย็นนี้ไปกินข้าวไหมครับ", romanization: "yen-níi pai kin khâao mǎi kráp", english: "Shall we go eat this evening?", hindi: "आज शाम खाना खाने चलें?"),
            WordExample(thai: "ตอนเย็นอากาศดีครับ", romanization: "toon-yen aa-kàat dii kráp", english: "In the evening the weather is nice.", hindi: "शाम को मौसम अच्छा होता है।"),
        ],
        69: [
            WordExample(thai: "ผู้หญิงคนนั้นสวยมาก", romanization: "phûu-yǐng khon nán sǔai mâak", english: "That woman is very beautiful.", hindi: "वह औरत बहुत सुंदर है।"),
            WordExample(thai: "ห้องน้ำผู้หญิงอยู่ที่ไหนครับ", romanization: "hông-náam phûu-yǐng yùu thîi-nǎi kráp", english: "Where is the women's restroom?", hindi: "महिलाओं का शौचालय कहाँ है?"),
        ],
        75: [
            WordExample(thai: "ล้างมือก่อนกินข้าวครับ", romanization: "láang muue kòon kin khâao kráp", english: "Wash your hands before eating.", hindi: "खाने से पहले हाथ धोइए।"),
            WordExample(thai: "มือของฉันเล็ก", romanization: "muue khǒong chǎn lék", english: "My hands are small.", hindi: "मेरे हाथ छोटे हैं।"),
        ],
        81: [
            WordExample(thai: "ผมต้องกินยาหลังอาหารครับ", romanization: "phǒm tông kin yaa lǎng aa-hǎan kráp", english: "I have to take medicine after meals.", hindi: "मुझे खाने के बाद दवा लेनी होती है।"),
            WordExample(thai: "ซื้อยาได้ที่ไหนครับ", romanization: "súue yaa dâi thîi-nǎi kráp", english: "Where can I buy medicine?", hindi: "दवा कहाँ खरीद सकता हूँ?"),
        ],
        93: [
            WordExample(thai: "ผมชอบไปทะเลครับ", romanization: "phǒm chôp pai thá-lee kráp", english: "I like going to the sea.", hindi: "मुझे समुद्र जाना पसंद है।"),
            WordExample(thai: "ทะเลที่นี่สวยมาก", romanization: "thá-lee thîi-nîi sǔai mâak", english: "The sea here is very beautiful.", hindi: "यहाँ का समुद्र बहुत सुंदर है।"),
        ],
        112: [
            WordExample(thai: "ที่นี่ขายอะไรครับ", romanization: "thîi-nîi khǎai à-rai kráp", english: "What do they sell here?", hindi: "यहाँ क्या बिकता है?"),
            WordExample(thai: "ร้านนี้ขายผลไม้", romanization: "ráan níi khǎai phǒn-lá-mái", english: "This shop sells fruit.", hindi: "यह दुकान फल बेचती है।"),
        ],
        119: [
            WordExample(thai: "ขอดูหน่อยครับ", romanization: "khǒo duu nòi kráp", english: "May I have a look, please?", hindi: "ज़रा देखने दीजिए।"),
            WordExample(thai: "ผมชอบดูทะเลตอนเย็น", romanization: "phǒm chôp duu thá-lee toon-yen", english: "I like watching the sea in the evening.", hindi: "मुझे शाम को समुद्र देखना पसंद है।"),
        ],
        125: [
            WordExample(thai: "ผมวิ่งทุกเช้าครับ", romanization: "phǒm wîng thúk cháao kráp", english: "I run every morning.", hindi: "मैं हर सुबह दौड़ता हूँ।"),
            WordExample(thai: "เด็ก ๆ วิ่งเร็วมาก", romanization: "dèk-dèk wîng reo mâak", english: "The children run very fast.", hindi: "बच्चे बहुत तेज़ दौड़ते हैं।"),
        ],
        133: [
            WordExample(thai: "ร้านปิดกี่โมงครับ", romanization: "ráan pìt kìi moong kráp", english: "What time does the shop close?", hindi: "दुकान कितने बजे बंद होती है?"),
            WordExample(thai: "ช่วยปิดไฟหน่อยครับ", romanization: "chûai pìt fai nòi kráp", english: "Please turn off the light.", hindi: "कृपया बत्ती बंद कर दीजिए।"),
        ],
        139: [
            WordExample(thai: "ภาษาไทยยากไหมครับ", romanization: "phaa-sǎa-thai yâak mǎi kráp", english: "Is Thai difficult?", hindi: "क्या थाई भाषा कठिन है?"),
            WordExample(thai: "ไม่ยากครับ ง่ายมาก", romanization: "mâi yâak kráp ngâai mâak", english: "It is not difficult, it is very easy.", hindi: "मुश्किल नहीं है, बहुत आसान है।"),
        ],
        147: [
            WordExample(thai: "คุณจะมาเมื่อไหร่ครับ", romanization: "khun jà maa mûea-rài kráp", english: "When will you come?", hindi: "आप कब आएँगे?"),
            WordExample(thai: "รถไฟมาเมื่อไหร่ครับ", romanization: "rót-fai maa mûea-rài kráp", english: "When does the train come?", hindi: "रेलगाड़ी कब आएगी?"),
        ],
        153: [
            WordExample(thai: "อร่อยแต่เผ็ดมากครับ", romanization: "à-ròi tàe phèt mâak kráp", english: "Delicious, but very spicy.", hindi: "स्वादिष्ट है लेकिन बहुत तीखा है।"),
            WordExample(thai: "ผมอยากไปแต่ไม่มีเวลา", romanization: "phǒm yàak pai tàe mâi mii wee-laa", english: "I want to go, but I have no time.", hindi: "मैं जाना चाहता हूँ लेकिन समय नहीं है।"),
        ],
        164: [
            WordExample(thai: "ขอไข่เจียวหนึ่งจานครับ", romanization: "khǒo khài-jiao nèung jaan kráp", english: "One omelette, please.", hindi: "एक आमलेट दीजिए।"),
            WordExample(thai: "ผมไม่กินไข่ครับ", romanization: "phǒm mâi kin khài kráp", english: "I do not eat eggs.", hindi: "मैं अंडे नहीं खाता।"),
        ],
        171: [
            WordExample(thai: "ช่วยเรียกตำรวจหน่อยครับ", romanization: "chûai rîak tam-rùat nòi kráp", english: "Please call the police.", hindi: "कृपया पुलिस बुलाइए।"),
            WordExample(thai: "สถานีตำรวจอยู่ที่ไหนครับ", romanization: "sà-thǎa-nii tam-rùat yùu thîi-nǎi kráp", english: "Where is the police station?", hindi: "पुलिस थाना कहाँ है?"),
        ],
        177: [
            WordExample(thai: "ตรงไปแล้วเลี้ยวขวาครับ", romanization: "trong-pai láeo líao khwǎa kráp", english: "Go straight, then turn right.", hindi: "सीधे जाइए, फिर दाएँ मुड़िए।"),
            WordExample(thai: "ตรงไปประมาณสองนาทีครับ", romanization: "trong-pai prà-maan sǒong naa-thii kráp", english: "Go straight for about two minutes.", hindi: "लगभग दो मिनट सीधे जाइए।"),
        ],
        183: [
            WordExample(thai: "ขอข้าวผัดไก่หนึ่งจานครับ", romanization: "khǒo khâao-phàt kài nèung jaan kráp", english: "One chicken fried rice, please.", hindi: "एक चिकन फ्राइड राइस दीजिए।"),
            WordExample(thai: "ข้าวผัดที่นี่อร่อยมาก", romanization: "khâao-phàt thîi-nîi à-ròi mâak", english: "The fried rice here is very delicious.", hindi: "यहाँ का फ्राइड राइस बहुत स्वादिष्ट है।"),
        ],
        7: [
            WordExample(thai: "ไม่เป็นไรครับ", romanization: "mâi-pen-rai kráp", english: "No problem.", hindi: "कोई बात नहीं।"),
            WordExample(thai: "ไม่เป็นไร ไม่ต้องขอโทษครับ", romanization: "mâi-pen-rai mâi tông khǒo-thôot kráp", english: "It's okay, no need to apologize.", hindi: "कोई बात नहीं, माफ़ी माँगने की ज़रूरत नहीं।"),
            WordExample(thai: "ไม่เป็นไร ผมสบายดีครับ", romanization: "mâi-pen-rai phǒm sà-baai-dii kráp", english: "It's okay, I'm fine.", hindi: "कोई बात नहीं, मैं ठीक हूँ।"),
        ],
        24: [
            WordExample(thai: "เขาเป็นเพื่อนของผมครับ", romanization: "khǎo pen phûean khǒong phǒm kráp", english: "He is my friend.", hindi: "वह मेरा दोस्त है।"),
            WordExample(thai: "ผมมากับเพื่อนครับ", romanization: "phǒm maa kàp phûean kráp", english: "I came with a friend.", hindi: "मैं दोस्त के साथ आया हूँ।"),
        ],
        38: [
            WordExample(thai: "ผมชอบอาหารไทยครับ", romanization: "phǒm chôp aa-hǎan thai kráp", english: "I like Thai food.", hindi: "मुझे थाई खाना पसंद है।"),
            WordExample(thai: "คุณชอบไหมครับ", romanization: "khun chôp mǎi kráp", english: "Do you like it?", hindi: "क्या आपको पसंद है?"),
            WordExample(thai: "ผมชอบทะเลมากครับ", romanization: "phǒm chôp thá-lee mâak kráp", english: "I really like the sea.", hindi: "मुझे समुद्र बहुत पसंद है।"),
        ],
        44: [
            WordExample(thai: "วันนี้อากาศหนาวครับ", romanization: "wan-níi aa-kàat nǎao kráp", english: "The weather is cold today.", hindi: "आज मौसम ठंडा है।"),
            WordExample(thai: "ผมหนาวมากครับ", romanization: "phǒm nǎao mâak kráp", english: "I'm very cold.", hindi: "मुझे बहुत ठंड लग रही है।"),
        ],
        53: [
            WordExample(thai: "เมื่อวานผมไปทะเลครับ", romanization: "mûea-waan phǒm pai thá-lee kráp", english: "Yesterday I went to the sea.", hindi: "कल मैं समुद्र गया था।"),
            WordExample(thai: "เมื่อวานฝนตกครับ", romanization: "mûea-waan fǒn tòk kráp", english: "It rained yesterday.", hindi: "कल बारिश हुई थी।"),
        ],
        59: [
            WordExample(thai: "กลางคืนอากาศเย็นครับ", romanization: "klaang-khuen aa-kàat yen kráp", english: "At night the weather is cool.", hindi: "रात में मौसम ठंडा रहता है।"),
            WordExample(thai: "ผมทำงานกลางคืนครับ", romanization: "phǒm tham-ngaan klaang-khuen kráp", english: "I work at night.", hindi: "मैं रात में काम करता हूँ।"),
        ],
        70: [
            WordExample(thai: "เด็กคนนี้น่ารักมากครับ", romanization: "dèk khon níi nâa-rák mâak kráp", english: "This child is very cute.", hindi: "यह बच्चा बहुत प्यारा है।"),
            WordExample(thai: "มีเด็กสองคนครับ", romanization: "mii dèk sǒong khon kráp", english: "There are two children.", hindi: "दो बच्चे हैं।"),
        ],
        76: [
            WordExample(thai: "เขาใจดีมากครับ", romanization: "khǎo jai-dii mâak kráp", english: "He is very kind (good-hearted).", hindi: "वह बहुत दयालु है।"),
            WordExample(thai: "ใจเย็นๆ นะครับ", romanization: "jai-yen-yen ná kráp", english: "Calm down, take it easy.", hindi: "शांत रहिए, जल्दबाज़ी मत कीजिए।"),
        ],
        82: [
            WordExample(thai: "โรงพยาบาลอยู่ที่ไหนครับ", romanization: "roong-phá-yaa-baan yùu thîi-nǎi kráp", english: "Where is the hospital?", hindi: "अस्पताल कहाँ है?"),
            WordExample(thai: "ผมต้องไปโรงพยาบาลครับ", romanization: "phǒm tông pai roong-phá-yaa-baan kráp", english: "I have to go to the hospital.", hindi: "मुझे अस्पताल जाना है।"),
        ],
        94: [
            WordExample(thai: "ภูเขาลูกนี้สวยมากครับ", romanization: "phuu-khǎo lûuk níi sǔai mâak kráp", english: "This mountain is very beautiful.", hindi: "यह पहाड़ बहुत सुंदर है।"),
            WordExample(thai: "พรุ่งนี้ผมจะไปภูเขาครับ", romanization: "phrûng-níi phǒm jà pai phuu-khǎo kráp", english: "Tomorrow I'll go to the mountains.", hindi: "कल मैं पहाड़ जाऊँगा।"),
        ],
        113: [
            WordExample(thai: "ลดราคาได้ไหมครับ", romanization: "lót-raa-khaa dâai mǎi kráp", english: "Can you give a discount?", hindi: "क्या कुछ छूट मिल सकती है?"),
            WordExample(thai: "วันนี้ร้านลดราคาครับ", romanization: "wan-níi ráan lót-raa-khaa kráp", english: "The shop has a discount today.", hindi: "आज दुकान में छूट चल रही है।"),
        ],
        120: [
            WordExample(thai: "ผมจะไปนอนแล้วครับ", romanization: "phǒm jà pai noon láeo kráp", english: "I'm going to bed now.", hindi: "मैं अब सोने जा रहा हूँ।"),
            WordExample(thai: "คุณนอนกี่ชั่วโมงครับ", romanization: "khun noon kìi chûa-moong kráp", english: "How many hours did you sleep?", hindi: "आप कितने घंटे सोए?"),
        ],
        127: [
            WordExample(thai: "ผมไม่รู้ครับ", romanization: "phǒm mâi rúu kráp", english: "I don't know.", hindi: "मुझे नहीं पता।"),
            WordExample(thai: "คุณรู้ไหมครับ", romanization: "khun rúu mǎi kráp", english: "Do you know?", hindi: "क्या आप जानते हैं?"),
            WordExample(thai: "ผมรู้แล้วครับ", romanization: "phǒm rúu láeo kráp", english: "I know now, got it.", hindi: "मुझे पता चल गया।"),
        ],
        134: [
            WordExample(thai: "ผมซื้อรถใหม่ครับ", romanization: "phǒm súue rót mài kráp", english: "I bought a new car.", hindi: "मैंने नई गाड़ी खरीदी।"),
            WordExample(thai: "โรงแรมนี้ใหม่มากครับ", romanization: "roong-raem níi mài mâak kráp", english: "This hotel is very new.", hindi: "यह होटल बहुत नया है।"),
            WordExample(thai: "พูดใหม่ได้ไหมครับ", romanization: "phûut mài dâai mǎi kráp", english: "Can you say that again?", hindi: "क्या फिर से कह सकते हैं?"),
        ],
        140: [
            WordExample(thai: "เมืองไทยสนุกมากครับ", romanization: "mueang-thai sà-nùk mâak kráp", english: "Thailand is a lot of fun.", hindi: "थाईलैंड में बहुत मज़ा आता है।"),
            WordExample(thai: "เมื่อวานสนุกไหมครับ", romanization: "mûea-waan sà-nùk mǎi kráp", english: "Was yesterday fun?", hindi: "क्या कल मज़ा आया?"),
        ],
        148: [
            WordExample(thai: "ทำไมแพงจังครับ", romanization: "tham-mai phaeng jang kráp", english: "Why is it so expensive?", hindi: "इतना महँगा क्यों है?"),
            WordExample(thai: "ทำไมคุณไม่ไปครับ", romanization: "tham-mai khun mâi pai kráp", english: "Why aren't you going?", hindi: "आप क्यों नहीं जा रहे हैं?"),
        ],
        154: [
            WordExample(thai: "นี่อะไรครับ", romanization: "nîi à-rai kráp", english: "What is this?", hindi: "यह क्या है?"),
            WordExample(thai: "นี่เพื่อนของผมครับ", romanization: "nîi phûean khǒong phǒm kráp", english: "This is my friend.", hindi: "यह मेरा दोस्त है।"),
        ],
        165: [
            WordExample(thai: "ขอนมหนึ่งแก้วครับ", romanization: "khǒo nom nèung kâeo kráp", english: "One glass of milk, please.", hindi: "एक गिलास दूध दीजिए।"),
            WordExample(thai: "เด็กชอบดื่มนมครับ", romanization: "dèk chôp dùuem nom kráp", english: "Children like to drink milk.", hindi: "बच्चों को दूध पीना पसंद है।"),
        ],
        172: [
            WordExample(thai: "ถนนนี้อันตรายมากครับ", romanization: "thà-nǒn níi an-tà-raai mâak kráp", english: "This road is very dangerous.", hindi: "यह सड़क बहुत खतरनाक है।"),
            WordExample(thai: "ตรงนั้นอันตราย ระวังนะครับ", romanization: "trong nân an-tà-raai rá-wang ná kráp", english: "It's dangerous over there, be careful.", hindi: "वहाँ खतरा है, सावधान रहिए।"),
        ],
        178: [
            WordExample(thai: "ที่นี่สวยมากครับ", romanization: "thîi-nîi sǔai mâak kráp", english: "It's very beautiful here.", hindi: "यह जगह बहुत सुंदर है।"),
            WordExample(thai: "จอดที่นี่ได้ไหมครับ", romanization: "jòt thîi-nîi dâai mǎi kráp", english: "Can you stop here?", hindi: "क्या यहाँ रोक सकते हैं?"),
        ],
        184: [
            WordExample(thai: "ขอน้ำส้มหนึ่งแก้วครับ", romanization: "khǒo nám-sôm nèung kâeo kráp", english: "One glass of orange juice, please.", hindi: "एक गिलास संतरे का रस दीजिए।"),
            WordExample(thai: "น้ำส้มหวานมากครับ", romanization: "nám-sôm wǎan mâak kráp", english: "The orange juice is very sweet.", hindi: "संतरे का रस बहुत मीठा है।"),
        ],
        9: [
            WordExample(thai: "สวัสดีครับ สบายดีไหมครับ", romanization: "sà-wàt-dii kráp sà-baai-dii-mǎi kráp", english: "Hello! How are you?", hindi: "नमस्ते! आप कैसे हैं?"),
            WordExample(thai: "คุณแม่สบายดีไหมครับ", romanization: "khun mâe sà-baai-dii-mǎi kráp", english: "Is your mother doing well?", hindi: "क्या आपकी माँ ठीक हैं?"),
        ],
        25: [
            WordExample(thai: "ครอบครัวผมมีสี่คนครับ", romanization: "khrôp-khrua phǒm mii sìi khon kráp", english: "My family has four people.", hindi: "मेरे परिवार में चार लोग हैं।"),
            WordExample(thai: "ผมรักครอบครัวมากครับ", romanization: "phǒm rák khrôp-khrua mâak kráp", english: "I love my family very much.", hindi: "मैं अपने परिवार से बहुत प्यार करता हूँ।"),
        ],
        39: [
            WordExample(thai: "วันนี้อากาศดีมากครับ", romanization: "wan-níi aa-kàat dii mâak kráp", english: "The weather is very good today.", hindi: "आज मौसम बहुत अच्छा है।"),
            WordExample(thai: "อาหารร้านนี้ดีมากครับ", romanization: "aa-hǎan ráan níi dii mâak kráp", english: "The food at this shop is very good.", hindi: "इस दुकान का खाना बहुत अच्छा है।"),
            WordExample(thai: "เขาเป็นคนดีครับ", romanization: "kháo pen khon dii kráp", english: "He is a good person.", hindi: "वह अच्छा इंसान है।"),
        ],
        46: [
            WordExample(thai: "โรงแรมอยู่ที่ไหนครับ", romanization: "roong-raem yùu thîi-nǎi kráp", english: "Where is the hotel?", hindi: "होटल कहाँ है?"),
            WordExample(thai: "โรงแรมนี้สวยแต่แพงครับ", romanization: "roong-raem níi sǔai tàe phaeng kráp", english: "This hotel is beautiful but expensive.", hindi: "यह होटल सुंदर है लेकिन महंगा है।"),
        ],
        54: [
            WordExample(thai: "วันนี้ผมไม่มีเวลาครับ", romanization: "wan-níi phǒm mâi mii wee-laa kráp", english: "I don't have time today.", hindi: "आज मेरे पास समय नहीं है।"),
            WordExample(thai: "คุณมีเวลาไหมครับ", romanization: "khun mii wee-laa mǎi kráp", english: "Do you have time?", hindi: "क्या आपके पास समय है?"),
        ],
        60: [
            WordExample(thai: "ผมอายุสามสิบปีครับ", romanization: "phǒm aa-yú sǎam-sìp pii kráp", english: "I am thirty years old.", hindi: "मैं तीस साल का हूँ।"),
            WordExample(thai: "สวัสดีปีใหม่ครับ", romanization: "sà-wàt-dii pii-mài kráp", english: "Happy New Year!", hindi: "नव वर्ष की शुभकामनाएँ!"),
            WordExample(thai: "ปีนี้ผมมาเมืองไทยครับ", romanization: "pii níi phǒm maa mueang-thai kráp", english: "This year I came to Thailand.", hindi: "इस साल मैं थाईलैंड आया हूँ।"),
        ],
        71: [
            WordExample(thai: "คุณชื่ออะไรครับ", romanization: "khun chûue à-rai kráp", english: "What is your name?", hindi: "आपका नाम क्या है?"),
            WordExample(thai: "ผมชื่ออามิตครับ", romanization: "phǒm chûue aa-mít kráp", english: "My name is Amit.", hindi: "मेरा नाम अमित है।"),
            WordExample(thai: "ร้านนี้ชื่ออะไรครับ", romanization: "ráan níi chûue à-rai kráp", english: "What is this shop's name?", hindi: "इस दुकान का नाम क्या है?"),
        ],
        77: [
            WordExample(thai: "ผมปวดฟันครับ", romanization: "phǒm pùat fan kráp", english: "I have a toothache.", hindi: "मेरे दाँत में दर्द है।"),
            WordExample(thai: "เด็กแปรงฟันทุกวันครับ", romanization: "dèk praeng fan thúk wan kráp", english: "The child brushes his teeth every day.", hindi: "बच्चा रोज़ दाँत ब्रश करता है।"),
        ],
        83: [
            WordExample(thai: "คุณชอบสีอะไรครับ", romanization: "khun chôp sǐi à-rai kráp", english: "What color do you like?", hindi: "आपको कौन सा रंग पसंद है?"),
            WordExample(thai: "ผมชอบสีฟ้าครับ", romanization: "phǒm chôp sǐi fáa kráp", english: "I like sky blue.", hindi: "मुझे आसमानी नीला रंग पसंद है।"),
        ],
        95: [
            WordExample(thai: "ต้นไม้ต้นนี้ใหญ่มากครับ", romanization: "tôn-mái tôn níi yài mâak kráp", english: "This tree is very big.", hindi: "यह पेड़ बहुत बड़ा है।"),
            WordExample(thai: "บ้านผมมีต้นไม้เยอะครับ", romanization: "bâan phǒm mii tôn-mái yóe kráp", english: "My house has lots of trees.", hindi: "मेरे घर में बहुत सारे पेड़ हैं।"),
        ],
        114: [
            WordExample(thai: "น้ำดื่มฟรีครับ", romanization: "náam dùuem frii kráp", english: "Drinking water is free.", hindi: "पीने का पानी मुफ़्त है।"),
            WordExample(thai: "อันนี้ฟรีไหมครับ", romanization: "an-níi frii mǎi kráp", english: "Is this one free?", hindi: "क्या यह मुफ़्त है?"),
        ],
        121: [
            WordExample(thai: "ผมตื่นหกโมงเช้าครับ", romanization: "phǒm tùuen hòk moong cháao kráp", english: "I wake up at six in the morning.", hindi: "मैं सुबह छह बजे उठता हूँ।"),
            WordExample(thai: "พรุ่งนี้ต้องตื่นเช้าครับ", romanization: "phrûng-níi tông tùuen cháao kráp", english: "Tomorrow I have to wake up early.", hindi: "कल मुझे जल्दी उठना है।"),
        ],
        128: [
            WordExample(thai: "ผมคิดว่าดีครับ", romanization: "phǒm khít wâa dii kráp", english: "I think it's good.", hindi: "मुझे लगता है कि यह अच्छा है।"),
            WordExample(thai: "คุณคิดยังไงครับ", romanization: "khun khít yang-ngai kráp", english: "What do you think?", hindi: "आप क्या सोचते हैं?"),
            WordExample(thai: "ผมคิดถึงบ้านครับ", romanization: "phǒm khít-thǔeng bâan kráp", english: "I miss home.", hindi: "मुझे घर की याद आती है।"),
        ],
        135: [
            WordExample(thai: "รถคันนี้เก่ามากครับ", romanization: "rót khan níi kào mâak kráp", english: "This car is very old.", hindi: "यह गाड़ी बहुत पुरानी है।"),
            WordExample(thai: "โรงแรมนี้เก่าแต่สวยครับ", romanization: "roong-raem níi kào tàe sǔai kráp", english: "This hotel is old but beautiful.", hindi: "यह होटल पुराना है लेकिन सुंदर है।"),
        ],
        141: [
            WordExample(thai: "วันนี้ผมเหนื่อยมากครับ", romanization: "wan-níi phǒm nùeai mâak kráp", english: "I'm very tired today.", hindi: "आज मैं बहुत थका हुआ हूँ।"),
            WordExample(thai: "คุณเหนื่อยไหมครับ", romanization: "khun nùeai mǎi kráp", english: "Are you tired?", hindi: "क्या आप थके हुए हैं?"),
        ],
        149: [
            WordExample(thai: "เขาเป็นใครครับ", romanization: "kháo pen khrai kráp", english: "Who is he?", hindi: "वह कौन है?"),
            WordExample(thai: "ใครมาครับ", romanization: "khrai maa kráp", english: "Who is coming?", hindi: "कौन आ रहा है?"),
        ],
        155: [
            WordExample(thai: "นั่นอะไรครับ", romanization: "nân à-rai kráp", english: "What is that?", hindi: "वह क्या है?"),
            WordExample(thai: "นั่นเพื่อนผมครับ", romanization: "nân phûean phǒm kráp", english: "That is my friend.", hindi: "वह मेरा दोस्त है।"),
        ],
        166: [
            WordExample(thai: "ขอน้ำตาลหน่อยครับ", romanization: "khǒo nám-taan nòi kráp", english: "Some sugar, please.", hindi: "थोड़ी चीनी दीजिए।"),
            WordExample(thai: "ไม่ใส่น้ำตาลครับ", romanization: "mâi sài nám-taan kráp", english: "No sugar, please.", hindi: "चीनी मत डालिए।"),
        ],
        173: [
            WordExample(thai: "ระวังรถครับ", romanization: "rá-wang rót kráp", english: "Watch out for the car!", hindi: "गाड़ी से सावधान!"),
            WordExample(thai: "ระวังหน่อยนะครับ", romanization: "rá-wang nòi ná kráp", english: "Please be careful.", hindi: "ज़रा सावधान रहिए।"),
        ],
        179: [
            WordExample(thai: "ห้องน้ำอยู่ที่นั่นครับ", romanization: "hông-náam yùu thîi-nân kráp", english: "The bathroom is over there.", hindi: "शौचालय वहाँ है।"),
            WordExample(thai: "พรุ่งนี้ผมไปที่นั่นครับ", romanization: "phrûng-níi phǒm pai thîi-nân kráp", english: "I'm going there tomorrow.", hindi: "कल मैं वहाँ जाऊँगा।"),
        ],
        185: [
            WordExample(thai: "เปิดไฟหน่อยครับ", romanization: "pòet fai nòi kráp", english: "Please turn on the light.", hindi: "ज़रा बत्ती जला दीजिए।"),
            WordExample(thai: "ปิดไฟด้วยครับ", romanization: "pìt fai dûai kráp", english: "Please turn off the light.", hindi: "बत्ती बंद कर दीजिए।"),
            WordExample(thai: "ไฟแดงต้องหยุดครับ", romanization: "fai daeng tông yùt kráp", english: "You must stop at a red light.", hindi: "लाल बत्ती पर रुकना ज़रूरी है।"),
        ],
        10: [
            WordExample(thai: "ผมสบายดีครับ ขอบคุณครับ", romanization: "phǒm sà-baai-dii kráp, khòp-khun kráp", english: "I'm fine, thank you.", hindi: "मैं ठीक हूँ, धन्यवाद।"),
            WordExample(thai: "วันนี้ฉันสบายดีค่ะ", romanization: "wan-níi chǎn sà-baai-dii khâ", english: "I'm fine today.", hindi: "आज मैं ठीक हूँ।"),
            WordExample(thai: "คุณสบายดีไหมครับ", romanization: "khun sà-baai-dii mǎi kráp", english: "How are you?", hindi: "आप कैसे हैं?"),
        ],
        28: [
            WordExample(thai: "ผมกินข้าวแล้วครับ", romanization: "phǒm kin khâao láew kráp", english: "I have already eaten.", hindi: "मैंने खाना खा लिया।"),
            WordExample(thai: "ขอข้าวหนึ่งจานครับ", romanization: "khǒo khâao nèung jaan kráp", english: "One plate of rice, please.", hindi: "एक प्लेट चावल दीजिए।"),
            WordExample(thai: "ข้าวร้านนี้อร่อยมาก", romanization: "khâao ráan níi à-ròi mâak", english: "The rice at this shop is very tasty.", hindi: "इस दुकान के चावल बहुत स्वादिष्ट हैं।"),
        ],
        40: [
            WordExample(thai: "ทะเลที่นี่สวยมากครับ", romanization: "thá-lee thîi-nîi sǔai mâak kráp", english: "The sea here is very beautiful.", hindi: "यहाँ का समुद्र बहुत सुंदर है।"),
            WordExample(thai: "ดอกไม้สวยจังครับ", romanization: "dòk-mái sǔai jang kráp", english: "The flowers are so beautiful!", hindi: "फूल कितने सुंदर हैं!"),
        ],
        47: [
            WordExample(thai: "รถมาแล้วครับ", romanization: "rót maa láew kráp", english: "The car has arrived.", hindi: "गाड़ी आ गई।"),
            WordExample(thai: "ระวังรถครับ", romanization: "rá-wang rót kráp", english: "Watch out for cars!", hindi: "गाड़ी से सावधान!"),
            WordExample(thai: "รถคันนี้ใหม่มากครับ", romanization: "rót khan níi mài mâak kráp", english: "This car is very new.", hindi: "यह गाड़ी बहुत नई है।"),
        ],
        55: [
            WordExample(thai: "ผมรอหนึ่งชั่วโมงแล้วครับ", romanization: "phǒm roo nèung chûa-moong láew kráp", english: "I have already waited one hour.", hindi: "मैं एक घंटे से इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "ไปสนามบินใช้เวลาหนึ่งชั่วโมง", romanization: "pai sà-nǎam-bin chái wee-laa nèung chûa-moong", english: "It takes one hour to get to the airport.", hindi: "हवाई अड्डे जाने में एक घंटा लगता है।"),
        ],
        61: [
            WordExample(thai: "ผมอยู่เมืองไทยหนึ่งเดือนครับ", romanization: "phǒm yùu mueang-thai nèung duean kráp", english: "I am staying in Thailand for one month.", hindi: "मैं एक महीने के लिए थाईलैंड में रह रहा हूँ।"),
            WordExample(thai: "เดือนหน้าผมจะมาอีกครับ", romanization: "duean nâa phǒm jà maa ìik kráp", english: "I will come again next month.", hindi: "अगले महीने मैं फिर आऊँगा।"),
        ],
        72: [
            WordExample(thai: "ครูของผมใจดีมากครับ", romanization: "khruu khǒong phǒm jai-dii mâak kráp", english: "My teacher is very kind.", hindi: "मेरे शिक्षक बहुत दयालु हैं।"),
            WordExample(thai: "คุณเป็นครูใช่ไหมครับ", romanization: "khun pen khruu châi mǎi kráp", english: "You are a teacher, right?", hindi: "आप शिक्षक हैं, है ना?"),
        ],
        78: [
            WordExample(thai: "ผมปวดหัวครับ", romanization: "phǒm pùat hǔa kráp", english: "I have a headache.", hindi: "मेरे सिर में दर्द है।"),
            WordExample(thai: "ปวดฟันมากครับ", romanization: "pùat fan mâak kráp", english: "My tooth hurts a lot.", hindi: "दाँत में बहुत दर्द है।"),
        ],
        90: [
            WordExample(thai: "วันนี้ฝนตกครับ", romanization: "wan-níi fǒn tòk kráp", english: "It is raining today.", hindi: "आज बारिश हो रही है।"),
            WordExample(thai: "ฝนตกหนักมาก", romanization: "fǒn tòk nàk mâak", english: "It is raining very hard.", hindi: "बहुत तेज़ बारिश हो रही है।"),
        ],
        96: [
            WordExample(thai: "ดอกไม้นี้สวยมากครับ", romanization: "dòk-mái níi sǔai mâak kráp", english: "This flower is very beautiful.", hindi: "यह फूल बहुत सुंदर है।"),
            WordExample(thai: "ฉันชอบดอกไม้สีแดงค่ะ", romanization: "chǎn chôp dòk-mái sǐi daeng khâ", english: "I like red flowers.", hindi: "मुझे लाल फूल पसंद हैं।"),
        ],
        116: [
            WordExample(thai: "ผมชอบฟังเพลงครับ", romanization: "phǒm chôp fang phleeng kráp", english: "I like listening to music.", hindi: "मुझे गाने सुनना पसंद है।"),
            WordExample(thai: "ผมฟังไม่เข้าใจครับ", romanization: "phǒm fang mâi khâo-jai kráp", english: "I hear it but do not understand.", hindi: "मैं सुनता हूँ पर समझ नहीं पाता।"),
        ],
        122: [
            WordExample(thai: "คุณทำอะไรครับ", romanization: "khun tham à-rai kráp", english: "What are you doing?", hindi: "आप क्या कर रहे हैं?"),
            WordExample(thai: "ผมทำเองครับ", romanization: "phǒm tham eeng kráp", english: "I made it myself.", hindi: "मैंने खुद बनाया।"),
            WordExample(thai: "ทำอาหารง่ายมาก", romanization: "tham aa-hǎan ngâai mâak", english: "Cooking is very easy.", hindi: "खाना बनाना बहुत आसान है।"),
        ],
        130: [
            WordExample(thai: "รอสักครู่ครับ", romanization: "roo sàk-khrûu kráp", english: "Please wait a moment.", hindi: "थोड़ा इंतज़ार कीजिए।"),
            WordExample(thai: "ผมรอเพื่อนอยู่ครับ", romanization: "phǒm roo phûean yùu kráp", english: "I am waiting for a friend.", hindi: "मैं दोस्त का इंतज़ार कर रहा हूँ।"),
        ],
        136: [
            WordExample(thai: "รถคันนี้เร็วมากครับ", romanization: "rót khan níi reo mâak kráp", english: "This car is very fast.", hindi: "यह गाड़ी बहुत तेज़ है।"),
            WordExample(thai: "คุณพูดเร็วมากครับ", romanization: "khun phûut reo mâak kráp", english: "You speak very fast.", hindi: "आप बहुत तेज़ बोलते हैं।"),
            WordExample(thai: "มาเร็วๆ นะครับ", romanization: "maa reo-reo ná kráp", english: "Come quickly!", hindi: "जल्दी आइए!"),
        ],
        142: [
            WordExample(thai: "น้ำส้มนี้หวานมากครับ", romanization: "nám-sôm níi wǎan mâak kráp", english: "This orange juice is very sweet.", hindi: "यह संतरे का रस बहुत मीठा है।"),
            WordExample(thai: "ขอหวานน้อยครับ", romanization: "khǒo wǎan nói kráp", english: "Less sweet, please.", hindi: "कम मीठा दीजिए।"),
        ],
        150: [
            WordExample(thai: "ไปตลาดยังไงครับ", romanization: "pai tà-làat yang-ngai kráp", english: "How do I get to the market?", hindi: "बाज़ार कैसे जाऊँ?"),
            WordExample(thai: "อันนี้กินยังไงครับ", romanization: "an-níi kin yang-ngai kráp", english: "How do you eat this?", hindi: "इसे कैसे खाते हैं?"),
        ],
        161: [
            WordExample(thai: "ผมชอบกินผลไม้ครับ", romanization: "phǒm chôp kin phǒn-lá-mái kráp", english: "I like eating fruit.", hindi: "मुझे फल खाना पसंद है।"),
            WordExample(thai: "ผลไม้ที่ตลาดถูกมาก", romanization: "phǒn-lá-mái thîi tà-làat thùuk mâak", english: "Fruit at the market is very cheap.", hindi: "बाज़ार में फल बहुत सस्ते हैं।"),
        ],
        167: [
            WordExample(thai: "ขอเกลือหน่อยครับ", romanization: "khǒo kluea nòi kráp", english: "Some salt, please.", hindi: "थोड़ा नमक दीजिए।"),
            WordExample(thai: "แกงนี้ใส่เกลือเยอะครับ", romanization: "kaeng níi sài kluea yóe kráp", english: "This curry has a lot of salt.", hindi: "इस करी में नमक ज़्यादा है।"),
        ],
        174: [
            WordExample(thai: "โทรศัพท์ของผมอยู่ที่ไหนครับ", romanization: "thoo-rá-sàp khǒong phǒm yùu thîi-nǎi kráp", english: "Where is my phone?", hindi: "मेरा फ़ोन कहाँ है?"),
            WordExample(thai: "ขอใช้โทรศัพท์ได้ไหมครับ", romanization: "khǒo chái thoo-rá-sàp dâi mǎi kráp", english: "May I use the phone?", hindi: "क्या मैं फ़ोन इस्तेमाल कर सकता हूँ?"),
        ],
        180: [
            WordExample(thai: "ห้องน้ำอยู่ข้างบนครับ", romanization: "hông-náam yùu khâang-bon kráp", english: "The bathroom is upstairs.", hindi: "शौचालय ऊपर है।"),
            WordExample(thai: "เพื่อนของผมอยู่ข้างบนครับ", romanization: "phûean khǒong phǒm yùu khâang-bon kráp", english: "My friend is upstairs.", hindi: "मेरा दोस्त ऊपर है।"),
        ],
        186: [
            WordExample(thai: "รถไฟไปเชียงใหม่ออกกี่โมงครับ", romanization: "rót-fai pai chiang-mài òok kìi moong kráp", english: "What time does the train to Chiang Mai leave?", hindi: "चियांग माई की ट्रेन कितने बजे छूटती है?"),
            WordExample(thai: "ผมชอบนั่งรถไฟครับ", romanization: "phǒm chôp nâng rót-fai kráp", english: "I like riding the train.", hindi: "मुझे ट्रेन में बैठना पसंद है।"),
        ],
        21: [
            WordExample(thai: "ผมมาจากอินเดียครับ", romanization: "phǒm maa jàak in-dia kráp", english: "I come from India.", hindi: "मैं भारत से आया हूँ।"),
            WordExample(thai: "ผมชอบอาหารไทยครับ", romanization: "phǒm chôp aa-hǎan thai kráp", english: "I like Thai food.", hindi: "मुझे थाई खाना पसंद है।"),
            WordExample(thai: "ผมไม่เข้าใจครับ", romanization: "phǒm mâi khâo-jai kráp", english: "I don't understand.", hindi: "मैं नहीं समझा।"),
        ],
        32: [
            WordExample(thai: "ขอชาร้อนหนึ่งแก้วครับ", romanization: "khǒo chaa rón nèung kâeo kráp", english: "One hot tea, please.", hindi: "एक गरम चाय दीजिए।"),
            WordExample(thai: "ชาไทยหวานมาก", romanization: "chaa thai wǎan mâak", english: "Thai tea is very sweet.", hindi: "थाई चाय बहुत मीठी होती है।"),
            WordExample(thai: "คุณชอบชาหรือกาแฟครับ", romanization: "khun chôp chaa rǔue kaa-fae kráp", english: "Do you like tea or coffee?", hindi: "आपको चाय पसंद है या कॉफ़ी?"),
        ],
        41: [
            WordExample(thai: "โรงแรมนี้ใหญ่มาก", romanization: "roong-raem níi yài mâak", english: "This hotel is very big.", hindi: "यह होटल बहुत बड़ा है।"),
            WordExample(thai: "ผมชอบเมืองใหญ่ครับ", romanization: "phǒm chôp mueang yài kráp", english: "I like big cities.", hindi: "मुझे बड़े शहर पसंद हैं।"),
        ],
        50: [
            WordExample(thai: "ร้านนี้ขายถูกมาก", romanization: "ráan níi khǎai thùuk mâak", english: "This shop sells very cheaply.", hindi: "यह दुकान बहुत सस्ते में बेचती है।"),
            WordExample(thai: "อาหารที่ตลาดถูกมาก", romanization: "aa-hǎan thîi tà-làat thùuk mâak", english: "Food at the market is very cheap.", hindi: "बाज़ार का खाना बहुत सस्ता है।"),
        ],
        56: [
            WordExample(thai: "รอห้านาทีครับ", romanization: "roo hâa naa-thii kráp", english: "Please wait five minutes.", hindi: "पाँच मिनट रुकिए।"),
            WordExample(thai: "ขอเวลาสิบนาทีครับ", romanization: "khǒo wee-laa sìp naa-thii kráp", english: "Give me ten minutes, please.", hindi: "मुझे दस मिनट दीजिए।"),
        ],
        62: [
            WordExample(thai: "ผมอยู่ที่นี่สองสัปดาห์ครับ", romanization: "phǒm yùu thîi-nîi sǒong sàp-daa kráp", english: "I'm staying here for two weeks.", hindi: "मैं यहाँ दो हफ़्ते रहूँगा।"),
            WordExample(thai: "สัปดาห์หน้าผมไปทะเลครับ", romanization: "sàp-daa nâa phǒm pai thá-lee kráp", english: "Next week I'm going to the sea.", hindi: "अगले हफ़्ते मैं समुद्र जाऊँगा।"),
        ],
        73: [
            WordExample(thai: "ผมปวดหัวครับ", romanization: "phǒm pùat hǔa kráp", english: "I have a headache.", hindi: "मेरे सिर में दर्द है।"),
            WordExample(thai: "ระวังหัวครับ", romanization: "rá-wang hǔa kráp", english: "Watch your head!", hindi: "सिर संभालिए!"),
        ],
        79: [
            WordExample(thai: "วันนี้ผมป่วยครับ", romanization: "wan-níi phǒm pùai kráp", english: "I'm sick today.", hindi: "आज मैं बीमार हूँ।"),
            WordExample(thai: "เพื่อนผมป่วยเมื่อวาน", romanization: "phûean phǒm pùai mûea-waan", english: "My friend was sick yesterday.", hindi: "मेरा दोस्त कल बीमार था।"),
        ],
        91: [
            WordExample(thai: "วันนี้แดดร้อนมาก", romanization: "wan-níi dàet rón mâak", english: "The sun is very hot today.", hindi: "आज धूप बहुत तेज़ है।"),
            WordExample(thai: "ผมไม่ชอบแดดครับ", romanization: "phǒm mâi chôp dàet kráp", english: "I don't like the sun.", hindi: "मुझे धूप पसंद नहीं है।"),
        ],
        97: [
            WordExample(thai: "วันนี้อากาศดีมาก", romanization: "wan-níi aa-kàat dii mâak", english: "The weather is very nice today.", hindi: "आज मौसम बहुत अच्छा है।"),
            WordExample(thai: "อากาศที่ภูเขาหนาวมาก", romanization: "aa-kàat thîi phuu-khǎo nǎao mâak", english: "The weather in the mountains is very cold.", hindi: "पहाड़ों का मौसम बहुत ठंडा है।"),
        ],
        117: [
            WordExample(thai: "ผมอ่านภาษาไทยไม่ได้ครับ", romanization: "phǒm àan phaa-sǎa-thai mâi dâai kráp", english: "I can't read Thai.", hindi: "मैं थाई नहीं पढ़ सकता।"),
            WordExample(thai: "คุณอ่านอันนี้ได้ไหมครับ", romanization: "khun àan an-níi dâai mǎi kráp", english: "Can you read this?", hindi: "क्या आप यह पढ़ सकते हैं?"),
        ],
        123: [
            WordExample(thai: "ผมทำงานที่ธนาคารครับ", romanization: "phǒm tham-ngaan thîi thá-naa-khaan kráp", english: "I work at a bank.", hindi: "मैं बैंक में काम करता हूँ।"),
            WordExample(thai: "พรุ่งนี้ผมไม่ทำงานครับ", romanization: "phrûng-níi phǒm mâi tham-ngaan kráp", english: "I don't work tomorrow.", hindi: "कल मैं काम नहीं करूँगा।"),
        ],
        131: [
            WordExample(thai: "หยุดที่นี่ครับ", romanization: "yùt thîi-nîi kráp", english: "Stop here, please.", hindi: "यहाँ रोकिए।"),
            WordExample(thai: "วันนี้ผมหยุดงานครับ", romanization: "wan-níi phǒm yùt ngaan kráp", english: "I'm off work today.", hindi: "आज मेरी काम से छुट्टी है।"),
        ],
        137: [
            WordExample(thai: "พูดช้าๆ หน่อยครับ", romanization: "phûut cháa-cháa nòi kráp", english: "Please speak slowly.", hindi: "कृपया थोड़ा धीरे बोलिए।"),
            WordExample(thai: "วันนี้รถไฟมาช้าครับ", romanization: "wan-níi rót-fai maa cháa kráp", english: "The train came late today.", hindi: "आज ट्रेन देर से आई।"),
        ],
        143: [
            WordExample(thai: "โรงแรมอยู่ใกล้ตลาดครับ", romanization: "roong-raem yùu klâi tà-làat kráp", english: "The hotel is near the market.", hindi: "होटल बाज़ार के पास है।"),
            WordExample(thai: "ที่นี่ใกล้ทะเลไหมครับ", romanization: "thîi-nîi klâi thá-lee mǎi kráp", english: "Is it near the sea here?", hindi: "क्या यह जगह समुद्र के पास है?"),
        ],
        151: [
            WordExample(thai: "ขอข้าวผัดและน้ำส้มครับ", romanization: "khǒo khâao-phàt láe nám-sôm kráp", english: "Fried rice and orange juice, please.", hindi: "फ्राइड राइस और संतरे का रस दीजिए।"),
            WordExample(thai: "ผมชอบทะเลและภูเขาครับ", romanization: "phǒm chôp thá-lee láe phuu-khǎo kráp", english: "I like the sea and the mountains.", hindi: "मुझे समुद्र और पहाड़ पसंद हैं।"),
            WordExample(thai: "ผมและเพื่อนไปตลาด", romanization: "phǒm láe phûean pai tà-làat", english: "My friend and I are going to the market.", hindi: "मैं और मेरा दोस्त बाज़ार जा रहे हैं।"),
        ],
        162: [
            WordExample(thai: "ผมชอบกินผักครับ", romanization: "phǒm chôp kin phàk kráp", english: "I like eating vegetables.", hindi: "मुझे सब्ज़ियाँ खाना पसंद है।"),
            WordExample(thai: "ขอไม่ใส่ผักครับ", romanization: "khǒo mâi sài phàk kráp", english: "Without vegetables, please.", hindi: "कृपया सब्ज़ी मत डालिए।"),
        ],
        168: [
            WordExample(thai: "แกงไทยเผ็ดมาก", romanization: "kaeng thai phèt mâak", english: "Thai curry is very spicy.", hindi: "थाई करी बहुत तीखी होती है।"),
            WordExample(thai: "ขอแกงไก่หนึ่งที่ครับ", romanization: "khǒo kaeng kài nèung thîi kráp", english: "One chicken curry, please.", hindi: "एक चिकन करी दीजिए।"),
        ],
        175: [
            WordExample(thai: "เลี้ยวซ้ายที่นี่ครับ", romanization: "líao sáai thîi-nîi kráp", english: "Turn left here.", hindi: "यहाँ बाएँ मुड़िए।"),
            WordExample(thai: "ห้องน้ำอยู่ทางซ้ายครับ", romanization: "hông-náam yùu thaang sáai kráp", english: "The toilet is on the left.", hindi: "शौचालय बाईं ओर है।"),
        ],
        181: [
            WordExample(thai: "ห้องน้ำอยู่ข้างล่างครับ", romanization: "hông-náam yùu khâang-lâang kráp", english: "The toilet is downstairs.", hindi: "शौचालय नीचे है।"),
            WordExample(thai: "รอผมข้างล่างนะครับ", romanization: "roo phǒm khâang-lâang ná kráp", english: "Wait for me downstairs, okay?", hindi: "नीचे मेरा इंतज़ार कीजिए।"),
        ],
        1: [
            WordExample(thai: "สวัสดีครับ ผมชื่อราหุล", romanization: "sà-wàt-dii kráp, phǒm chûue Rahul", english: "Hello, my name is Rahul.", hindi: "नमस्ते, मेरा नाम राहुल है।"),
            WordExample(thai: "สวัสดีตอนเช้า", romanization: "sà-wàt-dii toon cháao", english: "Good morning.", hindi: "सुप्रभात।"),
        ],
        2: [
            WordExample(thai: "ขอบคุณมากครับ", romanization: "khòp-khun mâak kráp", english: "Thank you very much.", hindi: "बहुत धन्यवाद।"),
            WordExample(thai: "ขอบคุณสำหรับอาหาร", romanization: "khòp-khun sǎm-ràp aa-hǎan", english: "Thank you for the food.", hindi: "खाने के लिए धन्यवाद।"),
        ],
        5: [
            WordExample(thai: "ใช่ ผมเป็นคนอินเดีย", romanization: "châi, phǒm pen khon in-dia", english: "Yes, I am Indian.", hindi: "हाँ, मैं भारतीय हूँ।"),
        ],
        6: [
            WordExample(thai: "ไม่เผ็ดนะ", romanization: "mâi phèt ná", english: "Not spicy, please.", hindi: "तीखा नहीं, प्लीज़।"),
            WordExample(thai: "ไม่เอาครับ", romanization: "mâi ao kráp", english: "I don't want it, thanks.", hindi: "मुझे नहीं चाहिए।"),
        ],
        8: [
            WordExample(thai: "ขอโทษครับ ห้องน้ำอยู่ที่ไหน", romanization: "khǒo-thôot kráp, hông-náam yùu thîi-nǎi", english: "Excuse me, where is the toilet?", hindi: "माफ़ कीजिए, शौचालय कहाँ है?"),
        ],
        26: [
            WordExample(thai: "อาหารไทยอร่อยมาก", romanization: "aa-hǎan thai à-ròi mâak", english: "Thai food is very delicious.", hindi: "थाई खाना बहुत स्वादिष्ट है।"),
        ],
        27: [
            WordExample(thai: "ขอน้ำหนึ่งแก้ว", romanization: "khǒo náam nèung kâew", english: "One glass of water, please.", hindi: "एक गिलास पानी दीजिए।"),
            WordExample(thai: "น้ำเย็นไหม", romanization: "náam yen mǎi", english: "Is the water cold?", hindi: "क्या पानी ठंडा है?"),
            WordExample(thai: "ผมอยากดื่มน้ำ", romanization: "phǒm yàak dùuem náam", english: "I want to drink water.", hindi: "मैं पानी पीना चाहता हूँ।"),
        ],
        29: [
            WordExample(thai: "คุณกินข้าวหรือยัง", romanization: "khun kin khâao rǔue yang", english: "Have you eaten yet?", hindi: "क्या आपने खाना खाया?"),
            WordExample(thai: "กินข้าวกันเถอะ", romanization: "kin khâao kan thòe", english: "Let's eat!", hindi: "चलो खाना खाते हैं!"),
            WordExample(thai: "ผมกินเผ็ดไม่ได้", romanization: "phǒm kin phèt mâi dâi", english: "I can't eat spicy food.", hindi: "मैं तीखा नहीं खा सकता।"),
        ],
        30: [
            WordExample(thai: "อร่อยมาก!", romanization: "à-ròi mâak!", english: "Very tasty!", hindi: "बहुत स्वादिष्ट!"),
        ],
        31: [
            WordExample(thai: "ขอกาแฟร้อนหนึ่งที่", romanization: "khǒo kaa-fae rón nèung thîi", english: "One hot coffee, please.", hindi: "एक गरम कॉफ़ी दीजिए।"),
        ],
        34: [
            WordExample(thai: "ผมหิวมาก", romanization: "phǒm hǐu mâak", english: "I am very hungry.", hindi: "मुझे बहुत भूख लगी है।"),
        ],
        35: [
            WordExample(thai: "ไปสนามบินเท่าไหร่", romanization: "pai sà-nǎam-bin thâo-rài", english: "How much to go to the airport?", hindi: "एयरपोर्ट जाने का कितना लगेगा?"),
            WordExample(thai: "ไปไหนครับ", romanization: "pai nǎi kráp", english: "Where are you going?", hindi: "कहाँ जा रहे हैं?"),
            WordExample(thai: "ผมจะไปตลาด", romanization: "phǒm jà pai tà-làat", english: "I will go to the market.", hindi: "मैं बाज़ार जाऊँगा।"),
        ],
        37: [
            WordExample(thai: "ผมรักเมืองไทย", romanization: "phǒm rák mueang-thai", english: "I love Thailand.", hindi: "मुझे थाईलैंड से प्यार है।"),
        ],
        45: [
            WordExample(thai: "ห้องน้ำอยู่ที่ไหน", romanization: "hông-náam yùu thîi-nǎi", english: "Where is the toilet?", hindi: "शौचालय कहाँ है?"),
            WordExample(thai: "ขอใช้ห้องน้ำได้ไหม", romanization: "khǒo chái hông-náam dâi mǎi", english: "May I use the bathroom?", hindi: "क्या मैं शौचालय इस्तेमाल कर सकता हूँ?"),
        ],
        48: [
            WordExample(thai: "อันนี้เท่าไหร่", romanization: "an-níi thâo-rài", english: "How much is this one?", hindi: "यह कितने का है?"),
            WordExample(thai: "ค่ารถเท่าไหร่", romanization: "khâa rót thâo-rài", english: "How much is the fare?", hindi: "किराया कितना है?"),
        ],
        49: [
            WordExample(thai: "แพงไป ลดได้ไหม", romanization: "phaeng pai, lót dâi mǎi", english: "Too expensive — can you lower it?", hindi: "बहुत महँगा है, कम कर सकते हैं?"),
        ],
        109: [
            WordExample(thai: "ผมไม่มีเงินสด", romanization: "phǒm mâi mii ngoen sòt", english: "I don't have cash.", hindi: "मेरे पास नकद नहीं है।"),
            WordExample(thai: "แลกเงินที่ไหน", romanization: "lâek ngoen thîi-nǎi", english: "Where can I exchange money?", hindi: "पैसे कहाँ बदल सकते हैं?"),
        ],
        111: [
            WordExample(thai: "อยากซื้ออันนี้", romanization: "yàak súue an-níi", english: "I want to buy this.", hindi: "मैं यह खरीदना चाहता हूँ।"),
        ],
        115: [
            WordExample(thai: "พูดช้าๆ ได้ไหม", romanization: "phûut cháa-cháa dâi mǎi", english: "Can you speak slowly?", hindi: "धीरे-धीरे बोल सकते हैं?"),
        ],
        126: [
            WordExample(thai: "ผมไม่เข้าใจ", romanization: "phǒm mâi khâo-jai", english: "I don't understand.", hindi: "मैं नहीं समझा।"),
            WordExample(thai: "เข้าใจแล้ว", romanization: "khâo-jai láew", english: "I understand now.", hindi: "अब समझ गया।"),
        ],
        129: [
            WordExample(thai: "ช่วยผมหน่อยได้ไหม", romanization: "chûai phǒm nòi dâi mǎi", english: "Can you help me?", hindi: "क्या आप मेरी मदद कर सकते हैं?"),
        ],
        145: [
            WordExample(thai: "นี่คืออะไร", romanization: "nîi khuue à-rai", english: "What is this?", hindi: "यह क्या है?"),
        ],
        146: [
            WordExample(thai: "โรงแรมอยู่ที่ไหน", romanization: "roong-raem yùu thîi-nǎi", english: "Where is the hotel?", hindi: "होटल कहाँ है?"),
        ],
        170: [
            WordExample(thai: "ช่วยด้วย!", romanization: "chûai-dûai!", english: "Help!", hindi: "बचाओ!"),
        ],
    ]

    // CHUNKS: sentence batches are appended as examples1, examples2, … by
    // tools/integrate_batch.py, which also maintains this merge list.
    private static let exampleChunks: [[Int: [WordExample]]] = [examples0]
    private static let examples: [Int: [WordExample]] = exampleChunks.reduce(into: [:]) { $0.merge($1) { a, _ in a } }

    // How the word combines with (or is built from) other words.
    private static let compounds: [Int: String] = [
        449: "เชียง (chiang) city (old northern word) / नगर + ใหม่ (mài) new / नया → เชียงใหม่ new city / नया शहर",
        450: "กรุง (krung) capital / राजधानी + เทพ (thêep) god / देवता → กรุงเทพ city of gods / देवताओं का शहर",
        223: "พวก (phûak) group / समूह + เรา (rao) we / हम → พวกเรา all of us / हम सब",
        226: "ของ (khǒong) of / का + ฉัน (chǎn) I / मैं → ของฉัน mine / मेरा",
        235: "ทุก (thúk) every / हर + วัน (wan) day / दिन → ทุกวัน every day / हर दिन",
        236: "บาง (baang) some / कुछ + คน (khon) person / व्यक्ति → บางคน some people / कुछ लोग",
        240: "ที่ (thîi) at / पर + นี่ (nîi) this / यह → ที่นี่ here / यहाँ",
        246: "ด้วย (dûai) also / भी + กัน (kan) each other / आपस में → ด้วยกัน together / साथ में",
        247: "ขอบคุณ (khòop-khun) thank you / धन्यवाद + นะ (ná) → ขอบคุณนะ friendly thanks / प्यार से धन्यवाद",
        249: "เครื่อง (khrûeang) thing / चीज़ + ดื่ม (dùem) drink / पीना → เครื่องดื่ม = beverage / पेय",
        250: "ใช้ (chái) use / इस्तेमाल + เงิน (ngern) money / पैसा → ใช้เงิน = to spend money / पैसे खर्च करना",
        252: "เห็น (hěn) see / दिखना + ด้วย (dûai) also / भी → เห็นด้วย = to agree / सहमत होना",
        254: "คำ (kham) word / शब्द + ถาม (thǎam) ask / पूछना → คำถาม = question / सवाल",
        255: "คำ (kham) word / शब्द + ตอบ (tòop) answer / जवाब देना → คำตอบ = answer (noun) / जवाब",
        256: "เล่น (lên) play / खेलना + น้ำ (náam) water / पानी → เล่นน้ำ = to play in the water / पानी में खेलना",
        257: "โรง (roong) building / भवन + เรียน (rian) study / पढ़ना → โรงเรียน = school / स्कूल",
        259: "จ่าย (jàai) pay / देना + เงิน (ngern) money / पैसा → จ่ายเงิน = to pay money / भुगतान करना",
        264: "ไป (pai) go / जाना + ส่ง (sòng) send / भेजना → ไปส่ง = to drop (someone) off / छोड़ने जाना",
        265: "ไป (pai) go / जाना + รับ (ráp) receive / लेना → ไปรับ = to go pick (someone) up / लेने जाना",
        266: "เปลี่ยน (plìan) change / बदलना + เสื้อ (sûea) shirt / शर्ट → เปลี่ยนเสื้อ = to change clothes / कपड़े बदलना",
        268: "ใส่ (sài) wear / पहनना + รองเท้า (roong-tháao) shoes / जूते → ใส่รองเท้า = to wear shoes / जूते पहनना",
        269: "นั่ง (nâng) sit / बैठना + รถ (rót) vehicle / गाड़ी → นั่งรถ = to ride (a vehicle) / गाड़ी से जाना",
        270: "ขอบคุณ (khòp-khun) thank you / धन्यवाद + มาก (mâak) → thank you very much / बहुत धन्यवाद",
        271: "น้อย (nói) little / कम + หน่อย (nòi) a bit / थोड़ा → น้อยหน่อย a little less / थोड़ा कम",
        273: "ง่วง (ngûang) drowsy / उनींदा + นอน (noon) to sleep / सोना → ง่วงนอน sleepy / नींद आना",
        276: "อิ่ม (ìm) full / पेट भरा + แล้ว (láew) already / हो गया → อิ่มแล้ว I'm full / पेट भर गया",
        277: "เวลา (wee-laa) time / समय + ว่าง (wâang) free / खाली → เวลาว่าง free time / खाली समय",
        279: "อ้วน (ûan) fat / मोटा ↔ ผอม (phǒom) thin / दुबला — opposite pair used for people and animals / लोगों और जानवरों के लिए",
        280: "ผม (phǒm) means both I (male) / मैं (पुरुष) and hair / बाल — ผมสั้น = short hair / छोटे बाल",
        281: "สั้น (sân) short / छोटा ↔ ยาว (yaao) long / लंबा — for length; for height use สูง (sǔung) / ऊँचाई के लिए สูง",
        283: "กว้าง (kwâang) wide / चौड़ा ↔ แคบ (khâep) narrow / संकरा",
        285: "หนัก (nàk) heavy / भारी ↔ เบา (bao) light / हल्का",
        286: "เสียง (sǐang) sound / आवाज़ + ดัง (dang) → เสียงดัง loud, noisy / तेज़ आवाज़, शोर",
        287: "ดัง (dang) loud / तेज़ ↔ เงียบ (ngîap) quiet / शांत",
        288: "พูด (phûut) speak / बोलना + เก่ง (kèng) → พูดเก่ง speaks well / अच्छा बोलता है — verb + เก่ง = good at that action / क्रिया + เก่ง = उसमें माहिर",
        289: "หอม (hǒom) fragrant / खुशबूदार + มะลิ (má-lí) jasmine / चमेली → ข้าวหอมมะลิ jasmine rice / जैस्मिन चावल",
        290: "สบาย (sà-baai) comfortable / आराम + ดี (dii) good / अच्छा → สบายดี I'm fine / मैं ठीक हूँ",
        292: "ถูก (thùuk) alone also means cheap / सस्ता — adding ต้อง (tông) makes ถูกต้อง clearly mean correct / सही",
        293: "เข้าใจ (khâo-jai) understand / समझना + ผิด (phìt) → เข้าใจผิด misunderstand / गलत समझना",
        295: "วัน (wan) day / दिन + จันทร์ (jan) moon, from Sanskrit चंद्र → Monday / सोमवार — same moon-day idea as Hindi!",
        296: "วัน (wan) day / दिन + อังคาร (ang-khaan) Mars, from Sanskrit अंगारक (मंगल ग्रह) → Tuesday / मंगलवार — same planet as Hindi!",
        297: "วัน (wan) day / दिन + พุธ (phút) Mercury, from Sanskrit बुध → Wednesday / बुधवार — exactly like Hindi!",
        298: "From Sanskrit बृहस्पति (Jupiter / गुरु ग्रह) → Thursday / गुरुवार. In speech Thais shorten it to วันพฤหัส (wan-phá-rúe-hàt).",
        299: "วัน (wan) day / दिन + ศุกร์ (sùk) Venus, from Sanskrit शुक्र → Friday / शुक्रवार — same as Hindi!",
        300: "วัน (wan) day / दिन + เสาร์ (sǎo) Saturn / शनि ग्रह → Saturday / शनिवार — same Saturn-day idea as Hindi!",
        301: "วัน (wan) day / दिन + อาทิตย์ (aa-thít) sun, from Sanskrit आदित्य (सूर्य) → Sunday / रविवार. อาทิตย์ alone also means \"week\" in everyday speech.",
        302: "ตอน (toon) period-time / समय + นี้ (níi) this / यह → now / अभी",
        303: "Goes at the end of the sentence / वाक्य के अंत में आता है: กินบ่อย (kin bòi) = eat often / अक्सर खाना",
        304: "บาง (baang) some / कुछ + ครั้ง (khráng) time-occasion / बार → sometimes / कभी-कभी. Spoken Thai also uses บางที (baang-thii).",
        305: "Goes at the end of the sentence / वाक्य के अंत में आता है — unlike English \"always\" / अंग्रेज़ी से अलग क्रम",
        306: "ไม่ (mâi) not / नहीं + เคย (kheuy) ever / कभी → never / कभी नहीं",
        307: "เร็ว (reo) fast / तेज़ + ๆ (repeat) + นี้ (níi) this / यह → soon / जल्दी ही",
        308: "ก่อน (kòon) before / पहले + นอน (noon) sleep / सोना → ก่อนนอน = before bed / सोने से पहले",
        309: "หลัง also means \"back (of the body)\" / पीठ. หลังจากนั้น (lǎng-jàak-nán) = after that / उसके बाद",
        310: "สาย = late in the morning or for appointments / सुबह या मीटिंग के लिए देर; late at night is ดึก (dùek) / रात की देरी के लिए ดึก",
        311: "ข้าว (khâao) rice / चावल + เที่ยง (thîang) noon / दोपहर → ข้าวเที่ยง = lunch / दोपहर का खाना",
        312: "เสาร์ (sǎo) Saturday / शनिवार + อาทิตย์ (aa-thít) Sunday / रविवार → weekend / वीकेंड. Formal word: วันหยุดสุดสัปดาห์.",
        313: "อาทิตย์ (aa-thít) week / हफ़्ता + หน้า (nâa) next-front / अगला → next week / अगले हफ़्ते",
        314: "อาทิตย์ (aa-thít) week / हफ़्ता + ที่แล้ว (thîi-láew) last-past / पिछला → last week / पिछले हफ़्ते",
        315: "บ่าย = roughly 1 pm to 4 pm / लगभग 1 से 4 बजे. บ่ายสอง (bàai sǒong) = 2 pm / दोपहर 2 बजे",
        316: "ทุก (thúk) every / हर + วัน (wan) day / दिन → every day / हर दिन",
        317: "คืน (kheun) night / रात + นี้ (níi) this / यह → tonight / आज रात. เมื่อคืน (mûea-kheun) = last night / कल रात",
        318: "วัน (wan) day / दिन + หยุด (yùt) stop / रुकना → holiday, day off / छुट्टी",
        319: "นานแค่ไหน (naan khâe-nǎi) = how long? / कितनी देर?",
        320: "กี่ + classifier: กี่คน (kìi khon) how many people / कितने लोग; กี่บาท (kìi bàat) how many baht / कितने बाथ",
        321: "หมา 2 ตัว (mǎa sǒong tua) = two dogs / दो कुत्ते; เสื้อ 1 ตัว (sûea nùeng tua) = one shirt / एक शर्ट",
        322: "เพื่อน 3 คน (phûean sǎam khon) = three friends / तीन दोस्त",
        323: "อันนี้ (an níi) = this one / यह वाला; อันไหน (an nǎi) = which one / कौन-सा",
        324: "ตั๋ว 2 ใบ (tǔa sǒong bai) = two tickets / दो टिकट; กระเป๋า 1 ใบ (kra-pǎo nùeng bai) = one bag / एक बैग",
        325: "น้ำ 1 แก้ว (náam nùeng kâew) = one glass of water / एक गिलास पानी",
        326: "น้ำ 2 ขวด (náam sǒong khùat) = two bottles of water / दो बोतल पानी; ขวดน้ำ (khùat náam) = water bottle / पानी की बोतल",
        327: "ข้าวผัด 1 จาน (khâao-phàt nùeng jaan) = one plate of fried rice / एक प्लेट फ्राइड राइस",
        328: "แกง 1 ถ้วย (kaeng nùeng thûai) = one bowl of curry / एक कटोरी करी",
        329: "รองเท้า 1 คู่ (roong-tháo nùeng khûu) = one pair of shoes / एक जोड़ी जूते",
        330: "ไก่ 2 ชิ้น (kài sǒong chín) = two pieces of chicken / चिकन के दो टुकड़े",
        331: "หนังสือ 1 เล่ม (nǎng-sǔe nùeng lêm) = one book / एक किताब",
        332: "อีกครั้ง (ìik khráng) = again / फिर से; ครั้งแรก (khráng râek) = first time / पहली बार",
        333: "สอง (sǒong) two / दो + ร้อย → สองร้อย (sǒong rói) = 200 / दो सौ",
        334: "หนึ่งพัน (nùeng phan) = 1,000 / एक हज़ार; ห้าพัน (hâa phan) = 5,000 / पाँच हज़ार",
        335: "หนึ่งหมื่น (nùeng mùen) = 10,000 / दस हज़ार; สองหมื่น (sǒong mùen) = 20,000 / बीस हज़ार",
        336: "หนึ่งแสน (nùeng sǎen) = 100,000 / एक लाख — same as Hindi लाख / बिल्कुल हिंदी के लाख जैसा",
        337: "หนึ่งล้าน (nùeng láan) = 1,000,000 / दस लाख; สิบล้าน (sìp láan) = 10,000,000 / एक करोड़",
        338: "ครึ่งชั่วโมง (khrûeng chûa-moong) = half an hour / आधा घंटा; ชั่วโมงครึ่ง (chûa-moong khrûeng) = one and a half hours / डेढ़ घंटा",
        339: "นิด (nít) tiny bit / ज़रा + หน่อย (nòi) a little / थोड़ा → a little bit / थोड़ा-सा",
        340: "คนเยอะ (khon yóe) = many people / बहुत लोग",
        341: "ทั้ง (tháng) whole / पूरा + หมด (mòt) finished / ख़त्म → all, total / कुल",
        342: "classifier + ละ: อันละ 10 บาท (an lá sìp bàat) = 10 baht each / हर एक दस बाथ; วันละครั้ง (wan lá khráng) = once a day / दिन में एक बार",
        343: "Thai phone numbers start with ศูนย์แปด (sǔun pàet) 08 / थाई फ़ोन नंबर 08 से शुरू होते हैं",
        344: "ยี่ (yîi) special form of two / दो का विशेष रूप + สิบ (sìp) ten / दस → 20 / बीस (not สองสิบ!)",
        345: "ห้อง (hôong) room / कमरा + น้ำ (náam) water / पानी → ห้องน้ำ bathroom / बाथरूम; + นอน (noon) sleep / सोना → ห้องนอน bedroom / बेडरूम",
        349: "โต๊ะ (tó) table / मेज़ + อาหาร (aa-hǎan) food / खाना → โต๊ะอาหาร dining table / खाने की मेज़",
        350: "เก้าอี้ 2 ตัว (kâo-îi sǒong tua) = two chairs / दो कुर्सियाँ",
        351: "มือ (meuu) hand / हाथ + ถือ (thěuu) to hold / पकड़ना → มือถือ mobile phone / मोबाइल",
        352: "กุญแจ (kun-jae) key / चाबी + ห้อง (hôong) room / कमरा → กุญแจห้อง room key / कमरे की चाबी",
        353: "เสื้อ (sûea) shirt / कमीज़ + ผ้า (phâa) cloth / कपड़ा → เสื้อผ้า clothes / कपड़े",
        354: "กางเกง (kaang-keeng) pants / पैंट + ขาสั้น (khǎa-sân) short legs / छोटी टाँगें → กางเกงขาสั้น shorts / निक्कर",
        356: "ผ้า (phâa) cloth / कपड़ा + เช็ด (chét) wipe / पोंछना + ตัว (tua) body / शरीर → towel / तौलिया",
        357: "ไฟ (fai) fire, light / आग + ฟ้า (fáa) sky / आकाश → ไฟฟ้า electricity / बिजली",
        358: "เปิดแอร์ (pèrt ae) = turn on the AC / एसी चलाना; ปิดแอร์ (pìt ae) = turn off the AC / एसी बंद करना",
        359: "พัด (phát) to fan / झलना + ลม (lom) wind / हवा → พัดลม fan / पंखा",
        360: "ตู้ (tûu) cabinet / अलमारी + เย็น (yen) cold / ठंडा → ตู้เย็น fridge / फ्रिज",
        362: "โคม (khoom) lantern / कंदील + ไฟ (fai) light / रोशनी → โคมไฟ lamp / लैंप",
        363: "ห้อง (hôong) room / कमरा + นอน (noon) to sleep / सोना → ห้องนอน bedroom / सोने का कमरा",
        364: "ห้อง (hôong) room / कमरा + ครัว (khrua) kitchen / रसोई → ห้องครัว kitchen / रसोईघर",
        365: "แปรง (praeng) brush / ब्रश + สี (sǐi) scrub / रगड़ना + ฟัน (fan) teeth / दाँत → toothbrush / टूथब्रश",
        366: "ยา (yaa) medicine / दवा + สีฟัน (sǐi-fan) scrub teeth / दाँत रगड़ना → toothpaste / टूथपेस्ट",
        367: "หมอน 2 ใบ (mǒon sǒong bai) = two pillows / दो तकिए",
        368: "ผ้า (phâa) cloth / कपड़ा + ห่ม (hòm) to cover / ओढ़ना → ผ้าห่ม blanket / कंबल",
        369: "ส่องกระจก (sòong krà-jòk) = to look in the mirror / आईना देखना",
        370: "ภาษา (phaa-sǎa) language / भाषा + ไทย (thai) Thai / थाई → Thai language / थाई भाषा",
        371: "ภาษา (phaa-sǎa) language / भाषा + ไทย (thai) Thai / थाई → Thai language / थाई भाषा",
        372: "ภาษา (phaa-sǎa) language / भाषा + อังกฤษ (ang-krìt) England / इंग्लैंड → English language / अंग्रेज़ी",
        373: "แปล (plae) translate / अनुवाद + ว่า (wâa) that / कि → แปลว่า it means / मतलब है",
        374: "หมาย (mǎai) signify / संकेत + ความ (khwaam) -ness / भाव + ว่า (wâa) that / कि → to mean that / मतलब होना",
        375: "โทร (thoo) call / फ़ोन + ศัพท์ (sàp) word / शब्द → โทรศัพท์ telephone / टेलीफ़ोन",
        376: "ข้อ (khôo) item / बिंदु + ความ (khwaam) content / बात → message / संदेश",
        378: "เบอร์ (bəə) number / नंबर + โทร (thoo) call / फ़ोन → เบอร์โทร phone number / फ़ोन नंबर",
        379: "ที่ (thîi) place / जगह + อยู่ (yùu) to live / रहना → address / पता",
        380: "ชื่อ (chêu) name / नाम + เล่น (lên) play / खेलना → nickname / निकनेम",
        382: "เพื่อน (phêuan) friend / दोस्त + บ้าน (bâan) house / घर → neighbor / पड़ोसी",
        383: "หัว (hǔa) head / सिर + หน้า (nâa) front / आगे → boss / बॉस",
        384: "เพื่อน (phêuan) friend / दोस्त + ร่วม (rûam) share / साझा + งาน (ngaan) work / काम → colleague / सहकर्मी",
        385: "ห้อง (hông) room / कमरा + ประชุม (prà-chum) meeting / मीटिंग → meeting room / मीटिंग रूम",
        386: "ทำ (tham) do / करना + งาน (ngaan) work / काम → ทำงาน to work / काम करना",
        388: "คำถาม (kham-thǎam) question / सवाल; คำตอบ (kham-tòop) answer / जवाब",
        389: "ปวด (pùat) ache / दर्द + ขา → ปวดขา leg pain / टांग में दर्द",
        390: "เสื้อ (sûea) shirt / कमीज़ + แขนสั้น (khǎen sân) short arm → short-sleeved shirt / आधी बाजू की कमीज़",
        391: "ปวด (pùat) ache / दर्द + ท้อง → ปวดท้อง stomachache / पेट दर्द",
        392: "ปากกา (pàak-kaa) = pen / कलम — a common word that starts with ปาก",
        394: "หู + ฟัง (fang) listen / सुनना → หูฟัง earphones / ईयरफोन",
        396: "รอง (roong) support / सहारा + เท้า → รองเท้า shoes / जूते",
        397: "นิ้ว + เท้า (tháo) foot / पैर → นิ้วเท้า toe / पैर की उंगली",
        398: "เจ็บ (jèp) hurt / दर्द + คอ → เจ็บคอ sore throat / गले में दर्द",
        399: "หน้า also means front: ข้างหน้า (khâang nâa) = in front / आगे",
        400: "เจ็บ + body part: เจ็บคอ (jèp khoo) sore throat / गले में दर्द",
        401: "เป็น (pen) to be / होना + ไข้ → เป็นไข้ to have a fever / बुखार होना",
        402: "ยา (yaa) medicine / दवा + แก้ (kâe) cure / ठीक करना + ไอ → ยาแก้ไอ cough medicine / खांसी की दवा",
        403: "เป็น (pen) to be / होना + หวัด → เป็นหวัด have a cold / ज़ुकाम होना; ไข้หวัดใหญ่ (khâi-wàt-yài) = flu / फ्लू",
        404: "ยา (yaa) medicine / दवा + แก้ (kâe) cure / ठीक करना + ปวด (pùat) pain / दर्द → painkiller / दर्द की दवा",
        405: "also means to lose: แพ้เกม (pháe keem) lose the game / खेल हारना",
        406: "เลือด + ออก (òok) exit / निकलना → เลือดออก to bleed / खून निकलना",
        409: "รถ (rót) vehicle / गाड़ी + พยาบาล (phá-yaa-baan) nurse / नर्स → ambulance / एम्बुलेंस",
        410: "ร้าน (ráan) shop / दुकान + ขาย (khǎai) to sell / बेचना + ยา (yaa) medicine / दवा → pharmacy / दवाई की दुकान",
        411: "ประกัน + สุขภาพ (sùk-khà-phâap) health / स्वास्थ्य → ประกันสุขภาพ health insurance / स्वास्थ्य बीमा",
        412: "พัก (phák) pause / रुकना + ผ่อน (phòn) ease / ढीला छोड़ना → to rest / आराम करना",
        187: "ดี (dii) good / अच्छा + ใจ (jai) heart / दिल → happy / खुश",
        188: "เสีย (sǐa) lost / खोया + ใจ (jai) heart / दिल → sad / दुखी",
        191: "ตื่น (dtùun) wake up / जागना + เต้น (dtên) jump-dance / कूदना → excited / उत्साहित",
        192: "คิด (kít) think / सोचना + ถึง (tǔng) to / तक → to miss / याद आना",
        194: "รอ (ror) wait / इंतज़ार + สัก (sàk) just / ज़रा + ครู่ (krûu) moment / क्षण → wait a moment / ज़रा रुकिए",
        195: "อาจ (àat) may / शायद + จะ (jà) will / -गा → maybe / शायद",
        196: "แน่ (nâe) certain / पक्का + นอน (non) lie down / लेटना → certainly (fixed idiom / रूढ़ प्रयोग)",
        197: "ด้วย (dûai) with / साथ + กัน (gan) each other / आपस में → together / साथ में",
        198: "คน (kon) person / व्यक्ति + เดียว (diao) single / एक ही → alone / अकेला",
        199: "กระเป๋า (grà-bpǎo) bag / बैग + เงิน (ngern) money / पैसा → wallet / बटुआ",
        200: "เสื้อ (sûea) shirt / शर्ट + ผ้า (pâa) cloth / कपड़ा → clothes / कपड़े",
        201: "รอง (rawng) to support / सहारा देना + เท้า (táao) foot / पैर → shoes / जूते",
        202: "ที่ (tîi) thing for / साधन + ชาร์จ (châat) to charge / चार्ज करना → charger / चार्जर",
        203: "ต่อ (dtàw) to negotiate / मोल करना + ราคา (raa-khaa) price / क़ीमत → to bargain / मोल-भाव करना",
        204: "ลด (lót) reduce / कम करना + หน่อย (nòi) a little / थोड़ा + ได้ไหม (dâi mǎi) can you? / क्या हो सकता है? → can you lower a bit? / थोड़ा कम करेंगे?",
        206: "พอ (phaw) enough / काफ़ी + ดี (dii) good / अच्छा → just right / एकदम ठीक",
        207: "ลอง (lawng) try / आज़माना + ใส่ (sài) wear / पहनना → ลองใส่ try on (clothes) / पहनकर देखना",
        208: "ใบ (bai) sheet, slip / पर्ची + เสร็จ (sèt) finished / पूरा → receipt / रसीद",
        209: "ถุง (tǔng) bag, sack / थैली + พลาสติก (pláat-sà-dtìk) plastic / प्लास्टिक → plastic bag / प्लास्टिक की थैली",
        210: "กี่ (gìi) how many / कितने + โมง (mohng) o'clock / बजे → what time? / कितने बजे?",
        211: "ชาย (chaai) edge / किनारा + หาด (hàat) sandy shore / रेतीला तट → beach / समुद्र तट",
        212: "เกาะ (gò) island / द्वीप + ช้าง (cháang) elephant / हाथी → เกาะช้าง Koh Chang (Elephant Island) / हाथी द्वीप",
        213: "ตั๋ว (dtǔa) ticket / टिकट + รถไฟ (rót-fai) train / ट्रेन → ตั๋วรถไฟ train ticket / ट्रेन टिकट",
        214: "นั่ง (nâng) to sit / बैठना + เรือ (rʉa) boat / नाव → นั่งเรือ to travel by boat / नाव से जाना",
        215: "วิน (win) taxi stand / स्टैंड + มอเตอร์ไซค์ (moo-dter-sai) motorcycle / मोटरसाइकिल → motorbike taxi / बाइक टैक्सी",
        216: "ข้าว (khâao) rice / चावल + เหนียว (nǐao) sticky / चिपचिपा + มะม่วง (má-mûang) mango / आम → mango sticky rice / मैंगो स्टिकी राइस",
        217: "ส้ม (sôm) sour / खट्टा + ตำ (dtam) pounded / कूटा हुआ → pounded papaya salad / पपीते का सलाद",
        218: "ผัด (phàt) stir-fried / भूना हुआ + ไทย (thai) Thai / थाई → Thai stir-fried noodles / थाई भुनी नूडल्स",
        219: "ขวด (khùat) bottle / बोतल + น้ำ (náam) water / पानी → water bottle / पानी की बोतल",
        220: "เช็ค (chék) check / चेक + บิล (bin) bill / बिल → 'bill, please' phrase; final ล sounds like น / अंतिम ล का उच्चारण 'न' जैसा होता है",
        221: "ช้อน (chóon) spoon / चम्मच + ส้อม (sôom) fork / काँटा → ช้อนส้อม, the usual Thai cutlery pair / थाई खाने की आम जोड़ी",
        222: "ส้อม (sôom, long vowel) fork / काँटा ≠ ส้ม (sôm, short) orange / संतरा; ช้อนส้อม (chóon-sôom) = spoon and fork / चम्मच-काँटा",
        57: "อาหาร (aa-hǎan) food / खाना + เช้า → อาหารเช้า breakfast / नाश्ता",
        68: "ผู้ (phûu) person / व्यक्ति + ชาย (chaai) male / पुरुष → \"male person\" = man / आदमी",
        74: "น้ำ (náam) water / पानी + ตา → น้ำตา tears / आँसू",
        80: "หมอ + ฟัน (fan) tooth / दाँत → หมอฟัน dentist / दाँतों का डॉक्टर",
        124: "เดิน + ทาง (thaang) way / रास्ता → เดินทาง to travel / यात्रा करना",
        163: "แกง (kaeng) curry / करी + ไก่ → แกงไก่ chicken curry / चिकन करी · ไข่ (khài) egg / अंडा + ไก่ → ไข่ไก่ hen's egg / मुर्गी का अंडा",
        182: "น้ำ (náam) water / पानी + แข็ง (khǎeng) hard / सख़्त → \"hard water\" = ice / बर्फ़",
        23: "ขอบ (khòp) + คุณ → ขอบคุณ thank you / धन्यवाद",
        43: "น้ำ (náam) water / पानी + ร้อน → น้ำร้อน hot water / गरम पानी",
        58: "น้ำ + เย็น → น้ำเย็น cold water / ठंडा पानी (เย็น also means cool / ठंडा)",
        69: "ผู้ (phûu) person / व्यक्ति + หญิง (yǐng) female / स्त्री → \"female person\" = woman / औरत",
        75: "มือ + ถือ (thǔue) to hold / पकड़ना → มือถือ mobile phone / मोबाइल फ़ोन",
        81: "ยา + สีฟัน (sǐi-fan) → ยาสีฟัน toothpaste / टूथपेस्ट",
        93: "อาหาร (aa-hǎan) food / खाना + ทะเล → อาหารทะเล seafood / समुद्री भोजन",
        119: "ดู + แล (lae) to look / देखना → ดูแล to take care of / देखभाल करना",
        147: "เมื่อ (mûea) time / जब + ไหร่ (rài) what / क्या → \"what time\" = when? / कब?",
        164: "ไข่ + เจียว (jiao) to fry / तलना → ไข่เจียว Thai omelette / आमलेट · ไข่ + ไก่ (kài) chicken / मुर्गी → ไข่ไก่ hen's egg / मुर्गी का अंडा",
        171: "สถานี (sà-thǎa-nii) station / स्टेशन + ตำรวจ → สถานีตำรวจ police station / पुलिस थाना",
        183: "ข้าว (khâao) rice / चावल + ผัด (phàt) stir-fried / भूना हुआ → \"stir-fried rice\" = fried rice / फ्राइड राइस",
        24: "เพื่อน + บ้าน (bâan) house / घर → เพื่อนบ้าน neighbor / पड़ोसी",
        44: "หน้า (nâa) season / मौसम + หนาว → หน้าหนาว winter (cold season) / सर्दी का मौसम",
        53: "เมื่อ (mûea) time when / जब + วาน (waan) yesterday / बीता दिन → \"the time of yesterday\" = yesterday / बीता कल",
        70: "เด็ก + ผู้ชาย (phûu-chaai) man → เด็กผู้ชาย boy / लड़का · เด็ก + ผู้หญิง (phûu-yǐng) woman → เด็กผู้หญิง girl / लड़की",
        76: "ใจ + ดี (dii) good / अच्छा → ใจดี kind / दयालु · เข้า (khâo) to enter / घुसना + ใจ → เข้าใจ understand / समझना",
        94: "ภู (phuu) mount / पर्वत + เขา (khǎo) hill / पहाड़ी → \"mount-hill\" = mountain / पहाड़",
        120: "ห้อง (hông) room / कमरा + นอน → ห้องนอน bedroom / सोने का कमरा",
        127: "รู้ + จัก (jàk) → รู้จัก to know (a person/place) / (किसी को) जानना",
        134: "ปี (pii) year / साल + ใหม่ → ปีใหม่ New Year / नया साल",
        148: "ทำ (tham) to do / करना + ไม (mai, short form of อะไร \"what\") / क्या → \"do what?\" = why / क्यों",
        154: "ที่ (thîi) place / जगह + นี่ → ที่นี่ here / यहाँ",
        165: "ชา (chaa) tea / चाय + นม → ชานม milk tea / दूध वाली चाय",
        178: "ที่ (thîi) place / जगह + นี่ (nîi) this / यह → \"this place\" = here / यहाँ",
        184: "น้ำ (náam) water / पानी + ส้ม (sôm) orange / संतरा → \"orange water\" = orange juice / संतरे का रस",
        9: "สบาย (sà-baai) comfortable / आराम में + ดี (dii) good / अच्छा + ไหม (mǎi) question particle / प्रश्न-शब्द → \"(are you) well?\" = how are you? / आप कैसे हैं?",
        25: "ครอบ (khrôp) to cover / ढकना + ครัว (khrua) kitchen / रसोई → \"those under one kitchen roof\" = family / परिवार",
        39: "สบาย (sà-baai) comfortable / आराम + ดี → สบายดี I'm fine / मैं ठीक हूँ · ดี + ใจ (jai) heart / दिल → ดีใจ glad / ख़ुश",
        54: "ตรง (trong) straight / सीधा + เวลา → ตรงเวลา on time / समय पर",
        60: "ปี + ใหม่ (mài) new / नया → ปีใหม่ New Year / नया साल",
        71: "ชื่อ + เล่น (lên) to play / खेलना → ชื่อเล่น nickname / उपनाम",
        77: "ปวด (pùat) to ache / दर्द + ฟัน → ปวดฟัน toothache / दाँत दर्द · แปรง (praeng) brush / ब्रश + ฟัน → แปรงฟัน to brush teeth / दाँत साफ़ करना",
        83: "สี + แดง (daeng) red / लाल → สีแดง red (color) / लाल रंग · สี + ขาว (khǎao) white / सफ़ेद → สีขาว white (color) / सफ़ेद रंग",
        121: "ตื่น + นอน (noon) to sleep / सोना → ตื่นนอน to wake up / नींद से जागना · ตื่น + เต้น (tên) to dance / नाचना → ตื่นเต้น excited / रोमांचित",
        128: "คิด + ถึง (thǔeng) to reach / तक पहुँचना → คิดถึง to miss (someone) / याद आना",
        135: "เพื่อน (phûean) friend / दोस्त + เก่า → เพื่อนเก่า old friend / पुराना दोस्त",
        141: "เหนื่อย + ใจ (jai) heart / दिल → เหนื่อยใจ disheartened / मन से थका हुआ",
        155: "ที่ (thîi) place / जगह + นั่น → ที่นั่น there / वहाँ",
        179: "ที่ (thîi) place / जगह + นั่น (nân) that / वह → \"that place\" = there / वहाँ",
        185: "รถ (rót) car / गाड़ी + ไฟ → รถไฟ train / रेलगाड़ी · ไฟ + ฟ้า (fáa) sky / आसमान → ไฟฟ้า electricity / बिजली · ไฟ + แดง (daeng) red / लाल → ไฟแดง red (traffic) light / लाल बत्ती",
        10: "สบาย (sà-baai) comfortable, well / आराम + ดี (dii) good / अच्छा → \"well and good\" = I'm fine / मैं ठीक हूँ · สบายดี + ไหม (mǎi) question word → สบายดีไหม how are you? / आप कैसे हैं?",
        40: "สวย + งาม (ngaam) graceful / शोभायमान → สวยงาม beautiful, lovely / सुंदर",
        47: "รถ + ไฟ (fai) fire / आग → รถไฟ train / रेलगाड़ी",
        55: "ชั่ว (chûa) span, period / अवधि + โมง (moong) o'clock / बजे → \"span of clock-time\" = hour / घंटा",
        61: "เดือน + หน้า (nâa) next, front / अगला → เดือนหน้า next month / अगला महीना",
        78: "ปวด + หัว (hǔa) head / सिर → ปวดหัว headache / सिरदर्द · ปวด + ฟัน (fan) tooth / दाँत → ปวดฟัน toothache / दाँत का दर्द",
        90: "ฝน + ตก (tòk) to fall / गिरना → ฝนตก it rains / बारिश होना",
        122: "ทำ + งาน (ngaan) work / काम → ทำงาน to work / काम करना · ทำ + อาหาร (aa-hǎan) food / खाना → ทำอาหาร to cook / खाना बनाना",
        142: "ของ (khǒong) thing / चीज़ + หวาน → ของหวาน dessert / मिठाई",
        150: "spoken form of อย่างไร: อย่าง (yàang) manner / ढंग + ไร (rai) what / क्या → \"in what way\" = how? / कैसे?",
        174: "โทร (thoo) far, to call / दूर + ศัพท์ (sàp) word, sound (Sanskrit शब्द) / शब्द → \"far-sound\" = telephone / टेलीफ़ोन",
        186: "รถ (rót) vehicle / गाड़ी + ไฟ (fai) fire / आग → \"fire cart\" = train / रेलगाड़ी",
        32: "ชา + ร้อน (rón) hot / गरम → ชาร้อน hot tea / गरम चाय · ชา + เย็น (yen) cool / ठंडा → ชาเย็น Thai iced tea / थाई आइस टी",
        41: "ผู้ (phûu) person / व्यक्ति + ใหญ่ → ผู้ใหญ่ (phûu-yài) adult, elder / वयस्क",
        50: "ถูก + ใจ (jai) heart / दिल → ถูกใจ (thùuk-jai) pleasing, to one's liking / मन को भाना",
        73: "หัว + ใจ (jai) heart, mind / दिल → หัวใจ (hǔa-jai) heart (organ) / हृदय",
        79: "ผู้ (phûu) person / व्यक्ति + ป่วย → ผู้ป่วย (phûu-pùai) patient / मरीज़",
        131: "วัน (wan) day / दिन + หยุด → วันหยุด (wan-yùt) holiday, day off / छुट्टी का दिन",
        168: "แกง + เขียว (khǐao) green / हरा + หวาน (wǎan) sweet / मीठा → แกงเขียวหวาน (kaeng-khǐao-wǎan) green curry / ग्रीन करी",
        175: "มือ (muue) hand / हाथ + ซ้าย → มือซ้าย (muue-sáai) left hand / बायाँ हाथ",
        7:   "ไม่ (mâi) not / नहीं + เป็น (pen) to be / होना + ไร (rai) anything / कुछ → \"it is nothing\" = no problem / कोई बात नहीं",
        27:  "น้ำ mixes into many words: ห้อง (hông) room + น้ำ → ห้องน้ำ toilet / शौचालय · น้ำ + ตาล (taan) palm → น้ำตาล sugar / चीनी · น้ำ + แข็ง (khǎeng) hard → น้ำแข็ง ice / बर्फ़",
        28:  "ข้าว + ผัด (phàt) stir-fry / भूनना → ข้าวผัด fried rice / फ्राइड राइस",
        45:  "ห้อง (hông) room / कमरा + น้ำ (náam) water / पानी → \"water room\" = toilet / शौचालय",
        46:  "โรง (roong) building / भवन + แรม (raem) to stay overnight / रात बिताना → hotel / होटल",
        51:  "วัน (wan) day / दिन + นี้ (níi) this / यह → \"this day\" = today / आज",
        52:  "พรุ่ง (phrûng) next morning + นี้ (níi) this / यह → tomorrow / आने वाला कल",
        59:  "กลาง (klaang) middle / बीच + คืน (khuen) night / रात → nighttime / रात का समय",
        82:  "โรง (roong) building / भवन + พยาบาล (phá-yaa-baan) nursing care / देखभाल → hospital / अस्पताल",
        95:  "ต้น (tôn) trunk / तना + ไม้ (mái) wood / लकड़ी → tree / पेड़",
        96:  "ดอก (dòk) blossom / फूल + ไม้ (mái) wood / लकड़ी → flower / फूल",
        101: "ร้าน (ráan) shop / दुकान + อาหาร (aa-hǎan) food / खाना → restaurant / रेस्टोरेंट",
        102: "โรง (roong) building / भवन + เรียน (rian) to study / पढ़ना → school / स्कूल",
        104: "สนาม (sà-nǎam) field / मैदान + บิน (bin) to fly / उड़ना → \"flying field\" = airport / हवाई अड्डा",
        113: "ลด (lót) reduce / घटाना + ราคา (raa-khaa) price / क़ीमत → discount / छूट",
        123: "ทำ (tham) to do / करना + งาน (ngaan) work / काम → to work / काम करना",
        161: "ผล (phǒn) fruit, result / फल + ไม้ (mái) wood, plant / पेड़ → fruit / फल",
        166: "น้ำ (náam) water / पानी + ตาล (taan) palm tree / ताड़ → \"palm water\" = sugar / चीनी",
        170: "ช่วย (chûai) help / मदद + ด้วย (dûai) please, too / भी → \"help me please!\" = emergency cry / बचाओ!",
        177: "ตรง (trong) straight / सीधा + ไป (pai) go / जाना → go straight ahead / सीधे जाइए",
        180: "ข้าง (khâang) side / तरफ़ + บน (bon) top / ऊपर → upstairs, above / ऊपर की ओर",
        181: "ข้าง (khâang) side / तरफ़ + ล่าง (lâang) bottom / नीचे → downstairs, below / नीचे की ओर",
    ]
}
