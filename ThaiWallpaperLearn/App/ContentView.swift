import SwiftUI
import AVFoundation

/// Speaks Thai words aloud using the system text-to-speech voice.
final class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()

    /// Best available Thai voice, or nil if none is installed on this device.
    private let thaiVoice: AVSpeechSynthesisVoice? = {
        let thaiVoices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix("th") }
        NSLog("SpeechService: Thai voices available: %@",
              thaiVoices.map(\.name).joined(separator: ", "))
        return thaiVoices.first { $0.quality == .enhanced } ?? thaiVoices.first
    }()

    var hasThaiVoice: Bool { thaiVoice != nil }

    /// Speaks the Thai script if a Thai voice exists, otherwise falls back to
    /// the romanization so the button is never silent.
    func speak(thai: String, romanization: String) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        synthesizer.stopSpeaking(at: .immediate)

        let utterance: AVSpeechUtterance
        if let thaiVoice {
            utterance = AVSpeechUtterance(string: thai)
            utterance.voice = thaiVoice
        } else {
            NSLog("SpeechService: no Thai voice installed — speaking romanization")
            utterance = AVSpeechUtterance(string: romanization)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = 0.42
        synthesizer.speak(utterance)
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            FlashcardView()
                .tabItem { Label("Practice", systemImage: "rectangle.on.rectangle.angled") }

            BrowseView()
                .tabItem { Label("Browse", systemImage: "list.bullet") }

            AlphabetView()
                .tabItem { Label("Alphabet", systemImage: "character.book.closed.fill") }

            MoreView()
                .tabItem { Label("More", systemImage: "sparkles") }
        }
        .tint(ThaiTheme.indigo)
    }
}

// MARK: - Today (word of the day)

struct TodayView: View {
    @State private var word: ThaiWord = Vocabulary.word(forDayOffset: Self.dayOffset())
    @State private var showWidgetHelp = false

    static func dayOffset() -> Int {
        // Days since a fixed reference so everyone sees the same daily word.
        let days = Int(Date().timeIntervalSince1970 / 86_400)
        return days
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Word of the day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .padding(.top, 8)

                    WordCard(word: word)

                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            word = Vocabulary.randomWord()
                        }
                    } label: {
                        Label("Shuffle another word", systemImage: "shuffle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("เรียนภาษาไทย")
            .background(ThaiTheme.sand)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWidgetHelp = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                }
            }
            .sheet(isPresented: $showWidgetHelp) { HelpView() }
        }
    }
}

// MARK: - Thai alphabet reference

/// One Thai consonant with its traditional acrophonic name (ก ไก่ …),
/// sound, and Devanagari cousin — Thai and Devanagari both descend from
/// Brahmi script, so the cousins genuinely correspond.
struct ThaiLetter: Identifiable {
    let letter: String
    let name: String
    let nameRoman: String
    let nameEnglish: String
    let nameHindi: String
    let sound: String
    let devanagari: String
    var obsolete = false

    var id: String { letter }

    /// Thai's three consonant classes — the key to the tone rules. The
    /// classic "Read Thai" trick: color-code letters by class so the tone
    /// system is absorbed visually.
    var letterClass: String {
        if "กจฎฏดตบปอ".contains(letter) { return "middle" }
        if "ขฃฉฐถผฝศษสห".contains(letter) { return "high" }
        return "low"
    }

    var classColor: Color {
        switch letterClass {
        case "middle": return ThaiTheme.indigo
        case "high": return ThaiTheme.orchid
        default: return Color(red: 0.243, green: 0.647, blue: 0.424)
        }
    }

    static let all: [ThaiLetter] = [
        ThaiLetter(letter: "ก", name: "ไก่", nameRoman: "kài", nameEnglish: "chicken", nameHindi: "मुर्गी", sound: "k", devanagari: "क"),
        ThaiLetter(letter: "ข", name: "ไข่", nameRoman: "khài", nameEnglish: "egg", nameHindi: "अंडा", sound: "kh", devanagari: "ख"),
        ThaiLetter(letter: "ฃ", name: "ขวด", nameRoman: "khùat", nameEnglish: "bottle", nameHindi: "बोतल", sound: "kh", devanagari: "ख", obsolete: true),
        ThaiLetter(letter: "ค", name: "ควาย", nameRoman: "khwaai", nameEnglish: "buffalo", nameHindi: "भैंस", sound: "kh", devanagari: "ग"),
        ThaiLetter(letter: "ฅ", name: "คน", nameRoman: "khon", nameEnglish: "person", nameHindi: "व्यक्ति", sound: "kh", devanagari: "ग", obsolete: true),
        ThaiLetter(letter: "ฆ", name: "ระฆัง", nameRoman: "rá-khang", nameEnglish: "bell", nameHindi: "घंटी", sound: "kh", devanagari: "घ"),
        ThaiLetter(letter: "ง", name: "งู", nameRoman: "nguu", nameEnglish: "snake", nameHindi: "साँप", sound: "ng", devanagari: "ङ"),
        ThaiLetter(letter: "จ", name: "จาน", nameRoman: "jaan", nameEnglish: "plate", nameHindi: "थाली", sound: "j", devanagari: "च"),
        ThaiLetter(letter: "ฉ", name: "ฉิ่ง", nameRoman: "chìng", nameEnglish: "cymbals", nameHindi: "मंजीरा", sound: "ch", devanagari: "छ"),
        ThaiLetter(letter: "ช", name: "ช้าง", nameRoman: "cháang", nameEnglish: "elephant", nameHindi: "हाथी", sound: "ch", devanagari: "ज"),
        ThaiLetter(letter: "ซ", name: "โซ่", nameRoman: "sôo", nameEnglish: "chain", nameHindi: "ज़ंजीर", sound: "s", devanagari: "ज़"),
        ThaiLetter(letter: "ฌ", name: "เฌอ", nameRoman: "choe", nameEnglish: "tree", nameHindi: "पेड़", sound: "ch", devanagari: "झ"),
        ThaiLetter(letter: "ญ", name: "หญิง", nameRoman: "yǐng", nameEnglish: "woman", nameHindi: "स्त्री", sound: "y", devanagari: "ञ"),
        ThaiLetter(letter: "ฎ", name: "ชฎา", nameRoman: "chá-daa", nameEnglish: "headdress", nameHindi: "मुकुट", sound: "d", devanagari: "ड"),
        ThaiLetter(letter: "ฏ", name: "ปฏัก", nameRoman: "pà-tàk", nameEnglish: "goad", nameHindi: "अंकुश", sound: "t", devanagari: "ट"),
        ThaiLetter(letter: "ฐ", name: "ฐาน", nameRoman: "thǎan", nameEnglish: "pedestal", nameHindi: "आधार", sound: "th", devanagari: "ठ"),
        ThaiLetter(letter: "ฑ", name: "มณโฑ", nameRoman: "mon-thoo", nameEnglish: "Montho (queen)", nameHindi: "मंथो (रानी)", sound: "th", devanagari: "ढ़"),
        ThaiLetter(letter: "ฒ", name: "ผู้เฒ่า", nameRoman: "phûu-thâo", nameEnglish: "elder", nameHindi: "बुज़ुर्ग", sound: "th", devanagari: "ढ"),
        ThaiLetter(letter: "ณ", name: "เณร", nameRoman: "neen", nameEnglish: "novice monk", nameHindi: "छोटा भिक्षु", sound: "n", devanagari: "ण"),
        ThaiLetter(letter: "ด", name: "เด็ก", nameRoman: "dèk", nameEnglish: "child", nameHindi: "बच्चा", sound: "d", devanagari: "द"),
        ThaiLetter(letter: "ต", name: "เต่า", nameRoman: "tào", nameEnglish: "turtle", nameHindi: "कछुआ", sound: "t", devanagari: "त"),
        ThaiLetter(letter: "ถ", name: "ถุง", nameRoman: "thǔng", nameEnglish: "bag", nameHindi: "थैला", sound: "th", devanagari: "थ"),
        ThaiLetter(letter: "ท", name: "ทหาร", nameRoman: "thá-hǎan", nameEnglish: "soldier", nameHindi: "सैनिक", sound: "th", devanagari: "द"),
        ThaiLetter(letter: "ธ", name: "ธง", nameRoman: "thong", nameEnglish: "flag", nameHindi: "झंडा", sound: "th", devanagari: "ध"),
        ThaiLetter(letter: "น", name: "หนู", nameRoman: "nǔu", nameEnglish: "mouse", nameHindi: "चूहा", sound: "n", devanagari: "न"),
        ThaiLetter(letter: "บ", name: "ใบไม้", nameRoman: "bai-mái", nameEnglish: "leaf", nameHindi: "पत्ता", sound: "b", devanagari: "ब"),
        ThaiLetter(letter: "ป", name: "ปลา", nameRoman: "plaa", nameEnglish: "fish", nameHindi: "मछली", sound: "p", devanagari: "प"),
        ThaiLetter(letter: "ผ", name: "ผึ้ง", nameRoman: "phûeng", nameEnglish: "bee", nameHindi: "मधुमक्खी", sound: "ph", devanagari: "फ"),
        ThaiLetter(letter: "ฝ", name: "ฝา", nameRoman: "fǎa", nameEnglish: "lid", nameHindi: "ढक्कन", sound: "f", devanagari: "फ़"),
        ThaiLetter(letter: "พ", name: "พาน", nameRoman: "phaan", nameEnglish: "tray", nameHindi: "थाल", sound: "ph", devanagari: "ब"),
        ThaiLetter(letter: "ฟ", name: "ฟัน", nameRoman: "fan", nameEnglish: "tooth", nameHindi: "दाँत", sound: "f", devanagari: "फ़"),
        ThaiLetter(letter: "ภ", name: "สำเภา", nameRoman: "sǎm-phao", nameEnglish: "sailing ship", nameHindi: "जहाज़", sound: "ph", devanagari: "भ"),
        ThaiLetter(letter: "ม", name: "ม้า", nameRoman: "máa", nameEnglish: "horse", nameHindi: "घोड़ा", sound: "m", devanagari: "म"),
        ThaiLetter(letter: "ย", name: "ยักษ์", nameRoman: "yák", nameEnglish: "giant", nameHindi: "राक्षस", sound: "y", devanagari: "य"),
        ThaiLetter(letter: "ร", name: "เรือ", nameRoman: "ruea", nameEnglish: "boat", nameHindi: "नाव", sound: "r", devanagari: "र"),
        ThaiLetter(letter: "ล", name: "ลิง", nameRoman: "ling", nameEnglish: "monkey", nameHindi: "बंदर", sound: "l", devanagari: "ल"),
        ThaiLetter(letter: "ว", name: "แหวน", nameRoman: "wǎen", nameEnglish: "ring", nameHindi: "अँगूठी", sound: "w", devanagari: "व"),
        ThaiLetter(letter: "ศ", name: "ศาลา", nameRoman: "sǎa-laa", nameEnglish: "pavilion", nameHindi: "मंडप", sound: "s", devanagari: "श"),
        ThaiLetter(letter: "ษ", name: "ฤๅษี", nameRoman: "ruue-sǐi", nameEnglish: "hermit", nameHindi: "ऋषि", sound: "s", devanagari: "ष"),
        ThaiLetter(letter: "ส", name: "เสือ", nameRoman: "sǔea", nameEnglish: "tiger", nameHindi: "बाघ", sound: "s", devanagari: "स"),
        ThaiLetter(letter: "ห", name: "หีบ", nameRoman: "hìip", nameEnglish: "chest / box", nameHindi: "संदूक", sound: "h", devanagari: "ह"),
        ThaiLetter(letter: "ฬ", name: "จุฬา", nameRoman: "jù-laa", nameEnglish: "kite", nameHindi: "पतंग", sound: "l", devanagari: "ळ"),
        ThaiLetter(letter: "อ", name: "อ่าง", nameRoman: "àang", nameEnglish: "basin", nameHindi: "तसला", sound: "(silent)", devanagari: "अ"),
        ThaiLetter(letter: "ฮ", name: "นกฮูก", nameRoman: "nók-hûuk", nameEnglish: "owl", nameHindi: "उल्लू", sound: "h", devanagari: "ह"),
    ]
}

struct AlphabetView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Label("middle", systemImage: "circle.fill").foregroundStyle(ThaiTheme.indigo)
                        Label("high", systemImage: "circle.fill").foregroundStyle(ThaiTheme.orchid)
                        Label("low", systemImage: "circle.fill").foregroundStyle(Color(red: 0.243, green: 0.647, blue: 0.424))
                    }
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .listRowBackground(ThaiTheme.parchment)
                } header: {
                    Text("Letter color = consonant class — the key to Thai tone rules")
                        .font(.caption2)
                }
                ForEach(ThaiLetter.all) { letter in
                    LetterRow(letter: letter)
                        .listRowBackground(ThaiTheme.cream)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(ThaiTheme.sand)
            .navigationTitle("Thai Alphabet")
        }
    }
}

private struct LetterRow: View {
    let letter: ThaiLetter
    @State private var expanded = false

    private var exampleWords: [ThaiWord] {
        let starts = Vocabulary.all.filter { $0.thai.hasPrefix(letter.letter) }
        let contains = Vocabulary.all.filter { !$0.thai.hasPrefix(letter.letter) && $0.thai.contains(letter.letter) }
        return Array((starts + contains).prefix(3))
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Devanagari cousin:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(letter.devanagari)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ThaiTheme.orchid)
                    if letter.obsolete {
                        Text("· no longer used")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(exampleWords) { word in
                    HStack(spacing: 10) {
                        Text(word.thai)
                            .font(.headline)
                            .foregroundStyle(ThaiTheme.ink)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(word.hindiPronunciation) · \(word.romanization)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(word.hindiMeaning) · \(word.englishMeaning)")
                                .font(.caption)
                                .foregroundStyle(ThaiTheme.ink)
                        }
                        Spacer()
                        Button {
                            SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundStyle(ThaiTheme.indigo)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                if exampleWords.isEmpty {
                    Text("A rare letter — no dictionary words yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        } label: {
            HStack(spacing: 14) {
                Text(letter.letter)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(letter.obsolete ? ThaiTheme.stone : letter.classColor)
                    .frame(width: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(letter.letter) \(letter.name) · \(letter.nameRoman)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThaiTheme.ink)
                    Text("\(letter.nameEnglish) / \(letter.nameHindi)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 3) {
                    Text(letter.sound)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(ThaiTheme.gold, in: Capsule())
                    Text(letter.letterClass)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(letter.classColor)
                }
                Button {
                    SpeechService.shared.speak(thai: "\(letter.letter) \(letter.name)", romanization: letter.nameRoman)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(ThaiTheme.indigo)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

// MARK: - Reusable word card

struct WordCard: View {
    let word: ThaiWord
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 8 : 16) {
            Text(word.thai)
                .font(.system(size: compact ? 48 : 72, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(ThaiTheme.ink)

            Button {
                SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
            } label: {
                Label("Play", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .background(ThaiTheme.indigo, in: Capsule())

            VStack(spacing: 6) {
                pronRow(flag: "🇮🇳", label: "HI", value: word.hindiPronunciation)
                pronRow(flag: "🔤", label: "EN", value: word.romanization)
            }

            Divider().padding(.horizontal, 40)

            VStack(spacing: 6) {
                meaningRow(flag: "🇮🇳", value: word.hindiMeaning)
                meaningRow(flag: "🇬🇧", value: word.englishMeaning)
            }

            Text(word.category.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(ThaiTheme.gold)
                .padding(.top, 4)
        }
        .padding(compact ? 16 : 28)
        .frame(maxWidth: .infinity)
        .background(ThaiTheme.cream, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(ThaiTheme.gold.opacity(0.3), lineWidth: 1))
        .shadow(color: ThaiTheme.ink.opacity(0.10), radius: 12, y: 6)
        .padding(.horizontal)
    }

    private func pronRow(flag: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(flag)
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.medium))
                .foregroundStyle(label == "HI" ? ThaiTheme.orchid : ThaiTheme.indigo)
        }
    }

    private func meaningRow(flag: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(flag)
            Text(value)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(ThaiTheme.ink)
        }
    }
}

// MARK: - Browse list

/// A practical grouping of words for a real-life situation, spanning
/// several raw categories plus hand-picked extras.
private struct WordCollection {
    let name: String
    let emoji: String
    let categories: Set<String>
    let extraIDs: Set<Int>
    var thaiWords: Set<String> = []

    func contains(_ word: ThaiWord) -> Bool {
        categories.contains(word.category) || extraIDs.contains(word.id) || thaiWords.contains(word.thai)
    }

    static let all: [WordCollection] = [
        WordCollection(
            name: "Tourist", emoji: "🧳",
            categories: ["Greetings", "Travel", "Directions", "Places", "Safety", "Questions", "Basics", "Time"],
            extraIDs: [48, 49, 50, 109, 110]
        ),
        WordCollection(
            name: "Restaurant", emoji: "🍜",
            categories: ["Food"],
            extraIDs: [2, 5, 6, 45, 48, 109, 110, 113, 142]
        ),
        WordCollection(
            name: "Supermarket", emoji: "🛒",
            categories: ["Money", "Food"],
            extraIDs: [48, 49, 50]
        ),
        WordCollection(
            name: "Numbers", emoji: "🔢",
            categories: ["Numbers"],
            extraIDs: []
        ),
        WordCollection(
            name: "Days", emoji: "📅",
            categories: [],
            extraIDs: [],
            thaiWords: ["วันจันทร์", "วันอังคาร", "วันพุธ", "วันพฤหัสบดี", "วันศุกร์", "วันเสาร์", "วันอาทิตย์", "สุดสัปดาห์", "วันหยุด", "วันนี้", "พรุ่งนี้", "เมื่อวาน"]
        ),
        WordCollection(
            name: "Months", emoji: "🗓️",
            categories: ["Months"],
            extraIDs: []
        ),
        WordCollection(
            name: "Colors", emoji: "🎨",
            categories: ["Colors"],
            extraIDs: []
        ),
    ]
}

struct BrowseView: View {
    private static let pageSize = 50

    @State private var query = ""
    @State private var selection = "All"
    @State private var visibleCount = BrowseView.pageSize

    private var baseList: [ThaiWord] {
        if selection == "All" { return Vocabulary.all }
        if let collection = WordCollection.all.first(where: { $0.name == selection }) {
            return Vocabulary.all.filter { collection.contains($0) }
        }
        return Vocabulary.all.filter { $0.category == selection }
    }

    private var filtered: [ThaiWord] {
        guard !query.isEmpty else { return baseList }
        let q = query.lowercased()
        return baseList.filter {
            $0.thai.contains(query) ||
            $0.romanization.lowercased().contains(q) ||
            $0.englishMeaning.lowercased().contains(q) ||
            $0.hindiMeaning.contains(query) ||
            $0.hindiPronunciation.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChips
                wordList
            }
            .searchable(text: $query, prompt: "Search Thai, English or Hindi")
            .navigationTitle("All Words")
            .onChange(of: selection) { visibleCount = Self.pageSize }
            .onChange(of: query) { visibleCount = Self.pageSize }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", label: "All")
                ForEach(WordCollection.all, id: \.name) { collection in
                    chip(collection.name, label: "\(collection.emoji) \(collection.name)")
                }
                ForEach(Vocabulary.categories.filter { category in
                    !WordCollection.all.contains { $0.name == category }
                }, id: \.self) { category in
                    chip(category, label: category)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ value: String, label: String) -> some View {
        Button {
            selection = value
        } label: {
            Text(label)
                .font(.subheadline.weight(selection == value ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(selection == value ? .white : ThaiTheme.ink)
                .background(
                    selection == value ? ThaiTheme.indigo : ThaiTheme.parchment,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private var wordList: some View {
        // Only `visibleCount` rows are materialized at once; the button at
        // the bottom pages in the next batch so scrolling stays smooth.
        List {
            ForEach(filtered.prefix(visibleCount)) { word in
                row(word)
            }
            if filtered.count > visibleCount {
                Button {
                    visibleCount += Self.pageSize
                } label: {
                    Label("Show \(min(Self.pageSize, filtered.count - visibleCount)) more words", systemImage: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.plain)
    }

    private func row(_ word: ThaiWord) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(progressColor(for: word))
                .frame(width: 8, height: 8)
            Text(word.thai)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .frame(minWidth: 64, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(word.romanization).font(.subheadline.weight(.medium))
                Text(word.hindiPronunciation).font(.subheadline).foregroundStyle(.secondary)
                Text("\(word.hindiMeaning)  ·  \(word.englishMeaning)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    /// Learning state at a glance: gray = unseen, gold = learning, jade = known.
    private func progressColor(for word: ThaiWord) -> Color {
        switch ProgressStore.shared.box(for: word.id) {
        case 0: return ThaiTheme.stone.opacity(0.35)
        case 1, 2: return ThaiTheme.gold
        default: return Color(red: 0.243, green: 0.647, blue: 0.424)
        }
    }
}

// MARK: - Widget help

struct HelpView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Put Thai words on your home & lock screen")
                        .font(.title2.bold())

                    Text("iPhone apps can't change your wallpaper directly, but the widget does the next best thing — it lives on your screen and shows a fresh Thai word that rotates through the day.")
                        .foregroundStyle(.secondary)

                    stepsSection(title: "Home Screen", steps: [
                        "Touch and hold an empty area of your Home Screen until the apps jiggle.",
                        "Tap the + button in the top-left corner.",
                        "Search for “Thai Learn” and pick a widget size.",
                        "Tap Add Widget, then Done."
                    ])

                    stepsSection(title: "Lock Screen", steps: [
                        "Touch and hold the Lock Screen, then tap Customize.",
                        "Tap the area below the clock to add widgets.",
                        "Choose “Thai Learn” and tap it to place it."
                    ])

                    Text("Tip: the widget refreshes automatically every hour or so with a new random word.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding()
            }
            .navigationTitle("Widget Setup")
        }
    }

    private func stepsSection(title: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .font(.caption.bold())
                        .frame(width: 22, height: 22)
                        .background(Color.accentColor.opacity(0.2), in: Circle())
                    Text(step)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}


// MARK: - More: slang, Hindi-Thai cousins, fun facts

struct FunWord: Identifiable {
    let thai: String
    let roman: String
    let meaning: String
    let hindi: String
    let note: String
    var id: String { thai }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    FunWordListView(title: "Thai Slang", words: MoreData.slang,
                                    intro: "What Thais actually say with friends — you won't find these in textbooks.")
                } label: {
                    moreRow(icon: "flame.fill", color: ThaiTheme.orchid, title: "Thai Slang",
                            subtitle: "จริงดิ, 555, ชิวๆ — talk like a local")
                }
                .listRowBackground(ThaiTheme.cream)

                NavigationLink {
                    FunWordListView(title: "Hindi–Thai Cousins", words: MoreData.cousins,
                                    intro: "Thai borrowed hundreds of words from Sanskrit — so Hindi speakers already half-know them. Same root, slightly different sound.")
                } label: {
                    moreRow(icon: "link", color: ThaiTheme.indigo, title: "Hindi–Thai Cousins",
                            subtitle: "ภาษา = भाषा, ครू = गुरु — words you already know")
                }
                .listRowBackground(ThaiTheme.cream)

                NavigationLink {
                    FactsView()
                } label: {
                    moreRow(icon: "lightbulb.fill", color: ThaiTheme.gold, title: "Must-Know Thai Facts",
                            subtitle: "Why Thai is easier than you think")
                }
                .listRowBackground(ThaiTheme.cream)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(ThaiTheme.sand)
            .navigationTitle("More")
        }
    }

    private func moreRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(ThaiTheme.ink)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FunWordListView: View {
    let title: String
    let words: [FunWord]
    let intro: String

    var body: some View {
        List {
            Section {
                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(ThaiTheme.parchment)
            }
            ForEach(words) { word in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Text(word.thai)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(ThaiTheme.ink)
                        Text(word.roman)
                            .font(.subheadline)
                            .foregroundStyle(ThaiTheme.indigo)
                        Spacer()
                        Button {
                            SpeechService.shared.speak(thai: word.thai, romanization: word.roman)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundStyle(ThaiTheme.indigo)
                        }
                        .buttonStyle(.borderless)
                    }
                    Text("🇬🇧 \(word.meaning) · 🇮🇳 \(word.hindi)")
                        .font(.subheadline)
                        .foregroundStyle(ThaiTheme.ink)
                    if !word.note.isEmpty {
                        Text(word.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 3)
                .listRowBackground(ThaiTheme.cream)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ThaiTheme.sand)
        .navigationTitle(title)
    }
}

struct FactsView: View {
    var body: some View {
        List {
            ForEach(Array(MoreData.facts.enumerated()), id: \.offset) { _, fact in
                VStack(alignment: .leading, spacing: 6) {
                    Text(fact.0)
                        .font(.headline)
                        .foregroundStyle(ThaiTheme.ink)
                    Text(fact.1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .listRowBackground(ThaiTheme.cream)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ThaiTheme.sand)
        .navigationTitle("Must-Know Facts")
    }
}

enum MoreData {
    static let slang: [FunWord] = [
        FunWord(thai: "555", roman: "hâa hâa hâa", meaning: "hahaha (laughing)", hindi: "हाहाहा", note: "ห้า (5) sounds like \"ha\" — Thais type 555 instead of lol"),
        FunWord(thai: "จริงดิ", roman: "jing dì", meaning: "really?!", hindi: "सच में?!", note: "Casual shortening of จริงหรือ"),
        FunWord(thai: "ชิวๆ", roman: "chiu-chiu", meaning: "chill / relaxed", hindi: "आराम से / चिल", note: "From English \"chill\""),
        FunWord(thai: "เจ๋ง", roman: "jěng", meaning: "cool / awesome", hindi: "ज़बरदस्त", note: ""),
        FunWord(thai: "ปัง", roman: "pang", meaning: "amazing / on point", hindi: "कमाल", note: "Literally the sound \"bang!\""),
        FunWord(thai: "แซ่บ", roman: "sâep", meaning: "spicy-delicious / hot (person)", hindi: "मस्त / तीखा", note: "Isaan (northeastern) word — used everywhere now"),
        FunWord(thai: "ฟิน", roman: "fin", meaning: "blissful / so satisfying", hindi: "मज़ा आ गया", note: "From English \"finale\""),
        FunWord(thai: "งง", roman: "ngong", meaning: "confused", hindi: "उलझन में", note: "Super common — \"ngong mâak\" = totally confused"),
        FunWord(thai: "เว่อร์", roman: "wôe", meaning: "over the top / exaggerating", hindi: "ज़्यादा ही", note: "From English \"over\""),
        FunWord(thai: "กิ๊ก", roman: "kík", meaning: "casual fling / side crush", hindi: "अफ़ेयर / चक्कर", note: ""),
        FunWord(thai: "เท", roman: "thee", meaning: "to dump / stand someone up", hindi: "छोड़ देना / धोखा", note: "Literally \"to pour out\""),
        FunWord(thai: "มโน", roman: "má-noo", meaning: "to imagine things / delusional", hindi: "मन में ही सोचना", note: "From Sanskrit มโน = मन (mind)! Slang and cousin-word at once"),
        FunWord(thai: "สายเปย์", roman: "sǎai pee", meaning: "big spender (on someone)", hindi: "दिल खोलकर ख़र्च करने वाला", note: "สาย = type of person + \"pay\""),
        FunWord(thai: "เกรงใจ", roman: "kreeng-jai", meaning: "not wanting to trouble anyone", hindi: "संकोच", note: "Not slang but essential — the most Thai feeling there is; untranslatable"),
    ]

    static let cousins: [FunWord] = [
        FunWord(thai: "ภาษา", roman: "phaa-sǎa", meaning: "language", hindi: "भाषा (bhāṣā)", note: "Same Sanskrit root — identical meaning"),
        FunWord(thai: "ครู", roman: "khruu", meaning: "teacher", hindi: "गुरु (guru)", note: "गुरु → khruu"),
        FunWord(thai: "อาหาร", roman: "aa-hǎan", meaning: "food", hindi: "आहार (āhār)", note: "Same word, same meaning"),
        FunWord(thai: "อากาศ", roman: "aa-kàat", meaning: "weather / air", hindi: "आकाश (ākāsh)", note: "In Hindi it means sky; in Thai, weather"),
        FunWord(thai: "ราชา", roman: "raa-chaa", meaning: "king", hindi: "राजा (rājā)", note: ""),
        FunWord(thai: "มนุษย์", roman: "má-nút", meaning: "human", hindi: "मनुष्य (manuṣya)", note: ""),
        FunWord(thai: "ชีวิต", roman: "chii-wít", meaning: "life", hindi: "जीवित (jīvit)", note: "जीवित = alive; Thai = life"),
        FunWord(thai: "สุข", roman: "sùk", meaning: "happiness", hindi: "सुख (sukh)", note: "As in สุขุมวิท Sukhumvit road!"),
        FunWord(thai: "ทุกข์", roman: "thúk", meaning: "suffering", hindi: "दुःख (duḥkh)", note: "सुख-दुःख both crossed over"),
        FunWord(thai: "กรรม", roman: "kam", meaning: "karma / deed", hindi: "कर्म (karma)", note: ""),
        FunWord(thai: "ธรรม", roman: "tham", meaning: "dharma / righteousness", hindi: "धर्म (dharm)", note: ""),
        FunWord(thai: "บุญ", roman: "bun", meaning: "merit / good deed", hindi: "पुण्य (puṇya)", note: ""),
        FunWord(thai: "เทวดา", roman: "thee-wá-daa", meaning: "deity / angel", hindi: "देवता (devtā)", note: ""),
        FunWord(thai: "อาทิตย์", roman: "aa-thít", meaning: "sun / Sunday / week", hindi: "आदित्य (āditya)", note: "आदित्य = the sun god"),
        FunWord(thai: "จันทร์", roman: "jan", meaning: "moon / Monday", hindi: "चन्द्र (chandra)", note: "All Thai weekday names are Sanskrit planets, like Hindi!"),
        FunWord(thai: "สิงห์", roman: "sǐng", meaning: "lion", hindi: "सिंह (siṃha)", note: "Yes — Singha beer means Lion, same as Singh"),
        FunWord(thai: "มหา", roman: "má-hǎa", meaning: "great", hindi: "महा (mahā)", note: "มหานคร = महानगर = metropolis"),
        FunWord(thai: "นคร", roman: "ná-khon", meaning: "city", hindi: "नगर (nagar)", note: "City names: Nakhon Pathom etc."),
        FunWord(thai: "รัตน์", roman: "rát", meaning: "jewel", hindi: "रत्न (ratna)", note: "In Bangkok's full name: Ratanakosin"),
        FunWord(thai: "วิชา", roman: "wí-chaa", meaning: "subject / knowledge", hindi: "विद्या (vidyā)", note: ""),
        FunWord(thai: "เศรษฐี", roman: "sèet-thǐi", meaning: "rich person", hindi: "सेठ (seṭh)", note: "श्रेष्ठी → seth → sèet-thǐi"),
        FunWord(thai: "สัปดาห์", roman: "sàp-daa", meaning: "week", hindi: "सप्ताह (saptāh)", note: ""),
        FunWord(thai: "ภูมิ", roman: "phuum", meaning: "land / ground", hindi: "भूमि (bhūmi)", note: "Airport: Suvarnabhumi = सुवर्णभूमि, golden land"),
        FunWord(thai: "นาม", roman: "naam", meaning: "name (formal)", hindi: "नाम (nām)", note: "นามสกุล = surname"),
    ]

    static let facts: [(String, String)] = [
        ("Thai grammar is EASY", "No verb conjugation, no plurals, no articles, no gender agreement. \"I go yesterday\" is perfectly correct Thai. The hard part is only tones and script — grammar takes days, not years."),
        ("One syllable, five meanings", "The classic: ไม้ใหม่ไม่ไหม้ใช่ไหม (mái mài mâi mâi châi mǎi) = \"New wood doesn't burn, right?\" — five different tones of \"mai\" in one sentence."),
        ("555 = hahaha", "The number 5 is pronounced \"hâa\", so Thais type 555 to laugh online. 5555555 = laughing hard."),
        ("ไปไหน is a greeting", "\"Where are you going?\" (pai nǎi) is a friendly hello, like Hindi's \"और कहाँ चले?\" — nobody expects a real answer."),
        ("No word for yes", "Thai answers with the verb: \"Do you want rice?\" → \"Want\" (เอา) or \"Not want\" (ไม่เอา). ใช่ only confirms facts."),
        ("Bangkok has the world's longest city name", "The full ceremonial name is 169 letters — Krung Thep Maha Nakhon Amon Rattanakosin... and it's full of Sanskrit a Hindi speaker can decode: महानगर, रत्न, इन्द्र, अयोध्या!"),
        ("Thai script is Devanagari's cousin", "Both descend from ancient Brahmi script. The consonant order ก ข ค ง... follows the same varga system as क ख ग घ... — that's why our Alphabet tab shows the cousins."),
        ("ครับ/ค่ะ makes everything polite", "Men end sentences with khráp, women with khâ. One syllable turns any sentence polite — the single highest-value habit for a visitor."),
        ("Spaces separate sentences, not words", "Thaiiswrittenlikethis — words run together, spaces mark sentence-like pauses. That's why learning to spot word boundaries (our tappable sentences!) matters."),
        ("Weekdays are planets, like Hindi", "Monday = วันจันทร์ (चन्द्र moon), Tuesday = อังคาร (मंगल Mars), Sunday = อาทิตย์ (आदित्य sun). If you know Hindi weekdays, you know Thai ones."),
        ("เกรงใจ — the most Thai word", "Kreng-jai: reluctance to impose on anyone. Declining a favor so the other person isn't troubled. Understand this and you understand Thai culture."),
        ("Nicknames rule", "Every Thai has a short nickname (often unrelated to their real name): Bird, Golf, Fon, Nok. Ask ชื่อเล่นอะไร (What's your nickname?) — it's friendlier than formal names."),
    ]
}

#Preview {
    ContentView()
}
