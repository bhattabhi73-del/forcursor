import Foundation

/// Master list of Thai vocabulary bundled with the app.
///
/// The word list used to live here as Swift literals. It now loads from
/// `content.json`, the single source of truth shared with the Android app —
/// `tools/export_json.py` writes both copies from one run, so the two apps can
/// no longer drift (Android sat at 1,046 words while iOS had 4,446).
///
/// Loading at runtime also keeps the compiler out of it: type-checking a
/// 4,000-entry array literal was taking minutes on every clean build.
///
/// Pronunciations are phonetic approximations meant as a learning aid:
///  - `romanization`       uses a simplified Latin spelling (tones marked lightly).
///  - `hindiPronunciation` uses Devanagari so a Hindi speaker can sound the word out.

// MARK: - Bundled content

/// Decoded once, shared by `Vocabulary` and `WordExtras`.
///
/// JSON uses short keys (`roman`, `en`, `hi`) because it is the wire format
/// shared with Android; the Swift side maps them onto the fuller property
/// names the app already uses.
enum ContentStore {

    private struct Payload: Decodable {
        let words: [Word]
        let examples: [String: [Example]]
        let forms: [String: [Form]]
        let similar: [String: [Int]]
        let compounds: [String: String]
        let emoji: [String: String]

        struct Word: Decodable {
            let id: Int
            let thai: String
            let roman: String
            let hindiPron: String
            let en: String
            let hi: String
            let category: String
        }
        struct Example: Decodable {
            let thai: String
            let roman: String
            let en: String
            let hi: String
        }
        struct Form: Decodable {
            let thai: String
            let roman: String
            let en: String
            let hi: String
            let note: String
        }
    }

    private static let payload: Payload = {
        // The JSON is a bundled resource of both the app and the widget
        // extension, so `Bundle.main` resolves in either target.
        guard let url = Bundle.main.url(forResource: "content", withExtension: "json") else {
            fatalError("content.json is missing from the bundle — check it is in the target's Copy Bundle Resources phase.")
        }
        do {
            return try JSONDecoder().decode(Payload.self, from: Data(contentsOf: url))
        } catch {
            fatalError("content.json failed to decode: \(error)")
        }
    }()

    static let words: [ThaiWord] = payload.words.map {
        ThaiWord(id: $0.id,
                 thai: $0.thai,
                 romanization: $0.roman,
                 hindiPronunciation: $0.hindiPron,
                 englishMeaning: $0.en,
                 hindiMeaning: $0.hi,
                 category: $0.category)
    }

    static let examples: [Int: [WordExample]] = remap(payload.examples) { rows in
        rows.map { WordExample(thai: $0.thai, romanization: $0.roman, english: $0.en, hindi: $0.hi) }
    }

    static let forms: [Int: [WordForm]] = remap(payload.forms) { rows in
        rows.map { WordForm(thai: $0.thai, romanization: $0.roman, english: $0.en, hindi: $0.hi, note: $0.note) }
    }

    static let similar: [Int: [Int]] = remap(payload.similar) { $0 }
    static let compounds: [Int: String] = remap(payload.compounds) { $0 }
    static let emoji: [Int: String] = remap(payload.emoji) { $0 }

    /// JSON object keys are strings; the app keys everything by `ThaiWord.id`.
    private static func remap<In, Out>(_ source: [String: In],
                                       _ transform: (In) -> Out) -> [Int: Out] {
        var out: [Int: Out] = [:]
        out.reserveCapacity(source.count)
        for (key, value) in source {
            if let id = Int(key) { out[id] = transform(value) }
        }
        return out
    }
}

// MARK: - Vocabulary

enum Vocabulary {

    static let all: [ThaiWord] = ContentStore.words

    /// Words whose Thai spelling contains this word, or that this word
    /// contains — e.g. น้ำ → ห้องน้ำ, น้ำตาล, น้ำแข็ง. Powers the
    /// "related words" chips in Practice.
    static func related(to word: ThaiWord) -> [ThaiWord] {
        all.filter { $0.id != word.id && ($0.thai.contains(word.thai) || word.thai.contains($0.thai)) }
    }

    /// A stable, per-day rotation offset so the "word of the day" changes daily.
    static func word(forDayOffset offset: Int) -> ThaiWord {
        let index = ((offset % all.count) + all.count) % all.count
        return all[index]
    }

    /// A random word (used by the widget's rotation and the app's shuffle button).
    static func randomWord() -> ThaiWord {
        all.randomElement() ?? all[0]
    }

    /// A stable per-hour word shared by every widget, so widgets placed
    /// side by side always show the same word. The prime stride (17 is
    /// coprime with the list size) pseudo-shuffles the rotation so
    /// consecutive hours don't show consecutive list entries.
    static func word(forHour hour: Int) -> ThaiWord {
        let index = ((hour * 17) % all.count + all.count) % all.count
        return all[index]
    }

    static var categories: [String] {
        var seen = Set<String>()
        return all.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }
}
