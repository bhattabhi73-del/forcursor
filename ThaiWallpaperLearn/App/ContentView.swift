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

// MARK: - Liquid Glass surface (Layout v2)

/// Frosted glass card: Apple's real Liquid Glass on iOS 26+, a material
/// with a hairline highlight as the visually-matching fallback below.
struct ThaiGlass: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.55), lineWidth: 1))
        }
    }
}

extension View {
    func thaiGlass(cornerRadius: CGFloat = 24) -> some View {
        modifier(ThaiGlass(cornerRadius: cornerRadius))
    }

    /// The wash the glass floats on: sand gradient plus two soft color blooms.
    func glassWashBackground() -> some View {
        background(
            ZStack {
                ThaiTheme.glassWash
                Circle().fill(ThaiTheme.gold.opacity(0.22)).frame(width: 300).blur(radius: 60)
                    .offset(x: -130, y: -160)
                Circle().fill(ThaiTheme.indigo.opacity(0.16)).frame(width: 340).blur(radius: 70)
                    .offset(x: 150, y: 220)
            }
            .ignoresSafeArea()
        )
    }
}

// MARK: - Today (word of the day)

struct TodayView: View {
    @State private var word: ThaiWord = Vocabulary.word(forDayOffset: Self.dayOffset())
    @State private var showWidgetHelp = false
    @State private var streak = ProgressStore.shared.currentStreak()
    @State private var dueCounts = ProgressStore.shared.counts(in: Vocabulary.all)

    static func dayOffset() -> Int {
        // Days since a fixed reference so everyone sees the same daily word.
        let days = Int(Date().timeIntervalSince1970 / 86_400)
        return days
    }

    private static let thaiWeekday: [String] = [
        "วันอาทิตย์", "วันจันทร์", "วันอังคาร", "วันพุธ", "วันพฤหัสบดี", "วันศุกร์", "วันเสาร์",
    ]

    private var dayLine: String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let english = Date().formatted(.dateTime.weekday(.wide))
        return "\(Self.thaiWeekday[weekday - 1]) · \(english)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        Text(dayLine.uppercased())
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if streak > 0 {
                            Label("\(streak)-day streak", systemImage: "flame.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ThaiTheme.gold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .thaiGlass(cornerRadius: 14)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    WordCard(word: word)

                    practiceStrip

                    actionRow
                }
                .padding(.bottom, 24)
            }
            .glassWashBackground()
            .navigationTitle("เรียนภาษาไทย")
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
            .onAppear {
                streak = ProgressStore.shared.currentStreak()
                dueCounts = ProgressStore.shared.counts(in: Vocabulary.all)
            }
        }
    }

    /// SRS status surfaced where the day starts (tap → Practice tab).
    private var practiceStrip: some View {
        HStack(spacing: 8) {
            Circle().fill(ThaiTheme.jade).frame(width: 8, height: 8)
            Text(dueCounts.due > 0
                 ? "Practice today · \(dueCounts.due) due, \(min(dueCounts.fresh, 20)) new"
                 : "Practice today · \(min(dueCounts.fresh, 20)) new words waiting")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(ThaiTheme.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .thaiGlass(cornerRadius: 16)
        .padding(.horizontal)
    }

    /// Primary actions live in the thumb zone, not mid-card.
    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
            } label: {
                Label("Play", systemImage: "speaker.wave.2.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(ThaiTheme.indigo.opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: ThaiTheme.indigo.opacity(0.35), radius: 8, y: 4)

            Button {
                withAnimation(.spring(duration: 0.35)) {
                    word = Vocabulary.randomWord()
                }
            } label: {
                Image(systemName: "shuffle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(ThaiTheme.orchid)
                    .frame(width: 52, height: 52)
                    .thaiGlass(cornerRadius: 18)
            }
        }
        .padding(.horizontal)
        .padding(.top, 2)
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
        VStack(spacing: compact ? 8 : 14) {
            Text(word.category.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(Color(red: 0.541, green: 0.373, blue: 0.059))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(ThaiTheme.gold.opacity(0.16), in: Capsule())

            Text(word.thai)
                .font(.system(size: compact ? 48 : 68, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(ThaiTheme.ink)

            VStack(spacing: 5) {
                pronRow(flag: "🇮🇳", label: "HI", value: word.hindiPronunciation)
                pronRow(flag: "🔤", label: "EN", value: word.romanization)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.5), lineWidth: 1))

            VStack(spacing: 4) {
                meaningRow(flag: "🇮🇳", value: word.hindiMeaning)
                meaningRow(flag: "🇬🇧", value: word.englishMeaning)
            }
        }
        .padding(compact ? 16 : 22)
        .frame(maxWidth: .infinity)
        .thaiGlass(cornerRadius: 24)
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
            // Caladea (the Cambria stand-in) carries the meaning text; the
            // Devanagari half falls through to the system face by design.
            Text(value)
                .font(ThaiTheme.display(21))
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
                    WordPairListView(title: "Opposite Words", pairs: MoreData.opposites,
                                     symbol: "arrow.left.arrow.right",
                                     intro: "Words stick twice as fast in pairs — learn ใหญ่ and เล็ก arrives free. Tap either side to hear it.")
                } label: {
                    moreRow(icon: "arrow.left.arrow.right", color: ThaiTheme.jade, title: "Opposite Words",
                            subtitle: "ใหญ่ ↔ เล็ก, ร้อน ↔ หนาว — learn in pairs")
                }
                .listRowBackground(ThaiTheme.cream)

                NavigationLink {
                    WordPairListView(title: "Similar Words", pairs: MoreData.similars,
                                     symbol: "equal",
                                     intro: "Near-twins that trip learners up — same English translation, different Thai feel. The note tells you which one to use when.")
                } label: {
                    moreRow(icon: "equal.circle.fill", color: ThaiTheme.plum, title: "Similar Words",
                            subtitle: "พูด ≈ คุย, ดู ≈ เห็น — which one when?")
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
                HStack {
                    Image(systemName: "text.book.closed.fill")
                        .foregroundStyle(ThaiTheme.gold)
                    Text("\(words.count) words")
                        .font(.headline)
                        .foregroundStyle(ThaiTheme.ink)
                    Spacer()
                }
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

struct WordPairListView: View {
    let title: String
    let pairs: [WordPair]
    let symbol: String
    let intro: String

    var body: some View {
        List {
            Section {
                Text(intro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(ThaiTheme.parchment)
                HStack {
                    Image(systemName: "text.book.closed.fill")
                        .foregroundStyle(ThaiTheme.gold)
                    Text("\(pairs.count) pairs")
                        .font(.headline)
                        .foregroundStyle(ThaiTheme.ink)
                    Spacer()
                }
                .listRowBackground(ThaiTheme.parchment)
            }
            ForEach(pairs) { pair in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        pairSide(thai: pair.thaiA, roman: pair.romanA,
                                 meaning: pair.meaningA, hindi: pair.hindiA)
                        Image(systemName: symbol)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(ThaiTheme.gold)
                            .padding(.top, 6)
                        pairSide(thai: pair.thaiB, roman: pair.romanB,
                                 meaning: pair.meaningB, hindi: pair.hindiB)
                    }
                    if !pair.note.isEmpty {
                        Text(pair.note)
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

    private func pairSide(thai: String, roman: String, meaning: String, hindi: String) -> some View {
        Button {
            SpeechService.shared.speak(thai: thai, romanization: roman)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(thai)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(ThaiTheme.ink)
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption2)
                        .foregroundStyle(ThaiTheme.indigo.opacity(0.6))
                }
                Text(roman)
                    .font(.caption)
                    .foregroundStyle(ThaiTheme.indigo)
                Text(meaning)
                    .font(.caption)
                    .foregroundStyle(ThaiTheme.ink)
                Text(hindi)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        FunWord(thai: "สุวรรณ", roman: "sù-wan", meaning: "gold (classical)", hindi: "सुवर्ण (suvarṇa)", note: "Suvarnabhumi airport = सुवर्णभूमि, the golden land"),
        FunWord(thai: "ปฏิกิริยา", roman: "pà-tì-kì-rí-yaa", meaning: "reaction", hindi: "प्रतिक्रिया (pratikriyā)", note: "Long Sanskrit words survive almost intact"),
        FunWord(thai: "ปัญญา", roman: "pan-yaa", meaning: "wisdom / intellect", hindi: "प्रज्ञा (prajñā)", note: "Via Pali paññā"),
        FunWord(thai: "สตรี", roman: "sà-trǐi", meaning: "woman (formal)", hindi: "स्त्री (strī)", note: "On every women's restroom sign"),
        FunWord(thai: "บุรุษ", roman: "bù-rùt", meaning: "man (formal)", hindi: "पुरुष (puruṣa)", note: "On every men's restroom sign"),
        FunWord(thai: "ศูนย์", roman: "sǔun", meaning: "zero / center", hindi: "शून्य (śūnya)", note: "India gave zero to Thailand too"),
        FunWord(thai: "อดีต", roman: "à-dìit", meaning: "the past", hindi: "अतीत (atīt)", note: ""),
        FunWord(thai: "สามี", roman: "sǎa-mii", meaning: "husband", hindi: "स्वामी (svāmī)", note: "स्वामी (master) became \"husband\" in Thai"),
        FunWord(thai: "ภรรยา", roman: "phan-rá-yaa", meaning: "wife", hindi: "भार्या (bhāryā)", note: ""),
        FunWord(thai: "อายุ", roman: "aa-yú", meaning: "age", hindi: "आयु (āyu)", note: "อายุเท่าไหร่ = how old are you?"),
        FunWord(thai: "โรค", roman: "rôok", meaning: "disease", hindi: "रोग (rog)", note: ""),
        FunWord(thai: "โกรธ", roman: "kròot", meaning: "angry", hindi: "क्रोध (krodh)", note: "Already in our dictionary — now you know why it sounds familiar"),
        FunWord(thai: "ภัย", roman: "phai", meaning: "danger", hindi: "भय (bhay)", note: "อันตราय also = अन्तराय (obstacle)"),
        FunWord(thai: "พิเศษ", roman: "phí-sèet", meaning: "special", hindi: "विशेष (viśeṣ)", note: "Order aahaan phiset = special dish"),
        FunWord(thai: "ราตรี", roman: "raa-trii", meaning: "night (poetic)", hindi: "रात्रि (rātri)", note: "สวัสดีราตรี = good night"),
        FunWord(thai: "สวรรค์", roman: "sà-wǎn", meaning: "heaven", hindi: "स्वर्ग (svarg)", note: ""),
        FunWord(thai: "เวลา", roman: "wee-laa", meaning: "time", hindi: "वेला (velā)", note: "Same as in संध्या-वेला — already in our dictionary"),
        FunWord(thai: "ประเทศ", roman: "prà-thêet", meaning: "country", hindi: "प्रदेश (pradesh)", note: "Like Uttar Pradesh — ประเทศไทย = Thailand"),
        FunWord(thai: "มหาวิทยาลัย", roman: "má-hǎa-wít-thá-yaa-lai", meaning: "university", hindi: "महाविद्यालय (mahāvidyālaya)", note: "महा + विद्या + आलय, piece by piece"),
        FunWord(thai: "อาจารย์", roman: "aa-jaan", meaning: "professor / master", hindi: "आचार्य (āchārya)", note: ""),
        FunWord(thai: "เกษตร", roman: "kà-sèet", meaning: "agriculture", hindi: "क्षेत्र (kṣetra)", note: "क्षेत्र (field) → farming"),
        FunWord(thai: "กีฬา", roman: "kii-laa", meaning: "sport", hindi: "क्रीडा (krīḍā)", note: "क्रीडा (play) → sport"),
        FunWord(thai: "สุนัข", roman: "sù-nák", meaning: "dog (formal)", hindi: "शुनक (śunaka)", note: "Formal word for dog — everyday word is หมา. शुनक = dog in Sanskrit too (also a Vedic sage's name)"),
        FunWord(thai: "นายกรัฐมนตรี", roman: "naa-yók rát-thà-mon-trii", meaning: "Prime Minister", hindi: "नायक + राष्ट्र + मंत्री", note: "Literally 'leader of the state ministers' — three Sanskrit words in a row"),
        FunWord(thai: "รัฐมนตรี", roman: "rát-thà-mon-trii", meaning: "minister (government)", hindi: "राष्ट्र + मंत्री (rāṣṭra-mantrī)", note: "State minister — मंत्री is the same word"),
        FunWord(thai: "รัฐบาล", roman: "rát-thà-baan", meaning: "government", hindi: "राष्ट्र + पाल (rāṣṭra-pāla)", note: "'Protector of the state' — like गोपाल protects cows"),
        FunWord(thai: "ประธานาธิบดี", roman: "prà-thaa-naa-thí-bɔɔ-dii", meaning: "President", hindi: "प्रधान + अधिपति (pradhān-adhipati)", note: "'Chief overlord' — pure Sanskrit compound"),
        FunWord(thai: "กษัตริย์", roman: "kà-sàt", meaning: "king", hindi: "क्षत्रिय (kṣatriya)", note: "The warrior caste word became 'king' in Thai"),
        FunWord(thai: "มนตรี", roman: "mon-trii", meaning: "counselor / minister", hindi: "मंत्री (mantrī)", note: ""),
        FunWord(thai: "วิทยา", roman: "wít-thá-yaa", meaning: "knowledge / science", hindi: "विद्या (vidyā)", note: "วิทยาศาสตร์ = science, same root as วิชา"),
        FunWord(thai: "ประถม", roman: "prà-thǒm", meaning: "primary / first", hindi: "प्रथम (pratham)", note: "Primary school = โรงเรียนประถม"),
        FunWord(thai: "มัธยม", roman: "mát-thá-yom", meaning: "secondary / middle", hindi: "मध्यम (madhyam)", note: "Secondary school level"),
        FunWord(thai: "อักษร", roman: "àk-sǒon", meaning: "letter / alphabet", hindi: "अक्षर (akṣar)", note: ""),
        FunWord(thai: "ปรัชญา", roman: "pràt-yaa", meaning: "philosophy", hindi: "प्रज्ञा (prajñā)", note: "Same root as ปัญญา wisdom"),
        FunWord(thai: "คุณ", roman: "khun", meaning: "you / virtue", hindi: "गुण (guṇ)", note: "The polite 'you' is literally 'virtue'!"),
        FunWord(thai: "โทษ", roman: "thôot", meaning: "fault / blame / penalty", hindi: "दोष (doṣ)", note: "ขอโทษ (sorry) = asking about fault"),
        FunWord(thai: "เหตุ", roman: "hèet", meaning: "cause / reason", hindi: "हेतु (hetu)", note: ""),
        FunWord(thai: "ผล", roman: "phǒn", meaning: "result / fruit", hindi: "फल (phal)", note: "Result and fruit, both meanings like Hindi"),
        FunWord(thai: "จิต", roman: "jìt", meaning: "mind / heart", hindi: "चित्त (chitta)", note: ""),
        FunWord(thai: "สติ", roman: "sà-tì", meaning: "mindfulness / consciousness", hindi: "स्मृति (smṛti)", note: "Via Pali sati"),
        FunWord(thai: "กวี", roman: "kà-wii", meaning: "poet", hindi: "कवि (kavi)", note: ""),
        FunWord(thai: "คณิต", roman: "khá-nít", meaning: "mathematics", hindi: "गणित (gaṇit)", note: "คณิตศาสตร์ = mathematics"),
        FunWord(thai: "บท", roman: "bòt", meaning: "verse / chapter / lesson", hindi: "पद (pad)", note: ""),
        FunWord(thai: "ประวัติ", roman: "prà-wàt", meaning: "history / record", hindi: "प्रवृत्ति (pravṛtti)", note: "ประวัติศาสตร์ = history"),
        FunWord(thai: "สมมติ", roman: "sǒm-mút", meaning: "to suppose / hypothetical", hindi: "सम्मति (sammati)", note: ""),
        FunWord(thai: "วิเคราะห์", roman: "wí-khró", meaning: "to analyze", hindi: "विग्रह (vigrah)", note: "Via Pali viggaha"),
        FunWord(thai: "สังเคราะห์", roman: "sǎng-khró", meaning: "to synthesize", hindi: "संग्रह (saṅgrah)", note: ""),
        FunWord(thai: "บุตร", roman: "bùt", meaning: "son / child (formal)", hindi: "पुत्र (putra)", note: ""),
        FunWord(thai: "บุตรี", roman: "bùt-trii", meaning: "daughter (formal)", hindi: "पुत्री (putrī)", note: ""),
        FunWord(thai: "บิดา", roman: "bì-daa", meaning: "father (formal)", hindi: "पिता (pitā)", note: ""),
        FunWord(thai: "มารดา", roman: "maan-daa", meaning: "mother (formal)", hindi: "माता (mātā)", note: ""),
        FunWord(thai: "ศัตรู", roman: "sàt-truu", meaning: "enemy", hindi: "शत्रु (śatru)", note: ""),
        FunWord(thai: "มิตร", roman: "mít", meaning: "friend (formal)", hindi: "मित्र (mitra)", note: ""),
        FunWord(thai: "ประชาชน", roman: "prà-chaa-chon", meaning: "citizens / the people", hindi: "प्रजाजन (prajājan)", note: "प्रजा + जन"),
        FunWord(thai: "สังคม", roman: "sǎng-khom", meaning: "society", hindi: "संगम (saṅgam)", note: ""),
        FunWord(thai: "บริษัท", roman: "boo-rí-sàt", meaning: "company", hindi: "परिषद (pariṣad)", note: "A council became a company"),
        FunWord(thai: "ทรชน", roman: "thoo-rá-chon", meaning: "villain / wicked person", hindi: "दुर्जन (durjan)", note: ""),
        FunWord(thai: "กุมาร", roman: "kù-maan", meaning: "boy / prince", hindi: "कुमार (kumār)", note: ""),
        FunWord(thai: "กุมารี", roman: "kù-maa-rii", meaning: "girl / princess", hindi: "कुमारी (kumārī)", note: ""),
        FunWord(thai: "ทาส", roman: "thâat", meaning: "slave / servant", hindi: "दास (dās)", note: ""),
        FunWord(thai: "ชน", roman: "chon", meaning: "person / people", hindi: "जन (jan)", note: ""),
        FunWord(thai: "ตระกูล", roman: "trà-kuun", meaning: "family / clan", hindi: "कुल (kul)", note: ""),
        FunWord(thai: "ญาติ", roman: "yâat", meaning: "relative / kin", hindi: "ज्ञाति (jñāti)", note: ""),
        FunWord(thai: "บัณฑิต", roman: "ban-dìt", meaning: "graduate / scholar", hindi: "पंडित (paṇḍit)", note: "A pandit is a university graduate in Thai"),
        FunWord(thai: "สหาย", roman: "sà-hǎai", meaning: "comrade / companion", hindi: "सहाय (sahāy)", note: ""),
        FunWord(thai: "ราชธานี", roman: "râat-chá-thaa-nii", meaning: "capital city", hindi: "राजधानी (rājdhānī)", note: "Ayutthaya's full name includes this"),
        FunWord(thai: "มหานคร", roman: "má-hǎa-ná-khoon", meaning: "metropolis", hindi: "महानगर (mahānagar)", note: "Bangkok = กรุงเทพมหานคร"),
        FunWord(thai: "เขต", roman: "khèet", meaning: "district / zone", hindi: "क्षेत्र (kṣetra)", note: "Bangkok districts are เขต"),
        FunWord(thai: "สถานี", roman: "sà-thǎa-nii", meaning: "station", hindi: "स्थान (sthān)", note: "BTS สถานี = station"),
        FunWord(thai: "ปราสาท", roman: "praa-sàat", meaning: "castle / palace", hindi: "प्रासाद (prāsād)", note: ""),
        FunWord(thai: "อาคาร", roman: "aa-khaan", meaning: "building", hindi: "आगार (āgār)", note: ""),
        FunWord(thai: "วิหาร", roman: "wí-hǎan", meaning: "temple hall", hindi: "विहार (vihār)", note: "Bihar state is named from Buddhist vihāras"),
        FunWord(thai: "อุดร", roman: "ù-doon", meaning: "north (formal)", hindi: "उत्तर (uttar)", note: "Udon Thani = northern city"),
        FunWord(thai: "ทักษิณ", roman: "thák-sǐn", meaning: "south (formal)", hindi: "दक्षिण (dakṣiṇ)", note: "Yes, like the PM's name Thaksin"),
        FunWord(thai: "บูรพา", roman: "buu-rá-phaa", meaning: "east (formal)", hindi: "पूर्व (pūrva)", note: ""),
        FunWord(thai: "ปัจฉิม", roman: "pàt-chǐm", meaning: "west / final (formal)", hindi: "पश्चिम (paścim)", note: ""),
        FunWord(thai: "รัฐ", roman: "rát", meaning: "state", hindi: "राष्ट्र (rāṣṭra)", note: "รัฐบาล, รัฐมนตรี all start here"),
        FunWord(thai: "มณฑล", roman: "mon-thon", meaning: "region / circle", hindi: "मंडल (maṇḍal)", note: ""),
        FunWord(thai: "ทวีป", roman: "thá-wîip", meaning: "continent", hindi: "द्वीप (dvīp)", note: "Island (dvīp) became continent"),
        FunWord(thai: "ธานี", roman: "thaa-nii", meaning: "city (in names)", hindi: "धानी (dhānī)", note: "Udon Thani, Pathum Thani..."),
        FunWord(thai: "อาณาจักร", roman: "aa-naa-jàk", meaning: "kingdom / realm", hindi: "आज्ञा + चक्र (ājñā-cakra)", note: "Circle of command"),
        FunWord(thai: "นิคม", roman: "ní-khom", meaning: "settlement / estate", hindi: "निगम (nigam)", note: ""),
        FunWord(thai: "มรดก", roman: "moo-rá-dòk", meaning: "inheritance / heritage", hindi: "मृतक (mṛtak)", note: "From 'of the deceased' → inheritance"),
        FunWord(thai: "ศาลา", roman: "sǎa-laa", meaning: "pavilion / hall", hindi: "शाला (śālā)", note: "Like पाठशाला — the Thai sala pavilion"),
        FunWord(thai: "บรรพต", roman: "ban-phót", meaning: "mountain (poetic)", hindi: "पर्वत (parvat)", note: ""),
        FunWord(thai: "สุริยะ", roman: "sù-rí-yá", meaning: "sun / solar", hindi: "सूर्य (sūrya)", note: ""),
        FunWord(thai: "หิมะ", roman: "hì-má", meaning: "snow", hindi: "हिम (him)", note: "Himalaya = हिम + आलय, home of snow"),
        FunWord(thai: "เมฆ", roman: "mêek", meaning: "cloud", hindi: "मेघ (megh)", note: ""),
        FunWord(thai: "พายุ", roman: "phaa-yú", meaning: "storm", hindi: "वायु (vāyu)", note: "Wind god became storm"),
        FunWord(thai: "สมุทร", roman: "sà-mùt", meaning: "ocean", hindi: "समुद्र (samudra)", note: ""),
        FunWord(thai: "คงคา", roman: "khong-khaa", meaning: "river (poetic) / Ganges", hindi: "गंगा (gaṅgā)", note: "Ganga became the poetic word for any river"),
        FunWord(thai: "อนาคต", roman: "à-naa-khót", meaning: "future", hindi: "अनागत (anāgat)", note: "'Not yet arrived' = future"),
        FunWord(thai: "พฤกษา", roman: "phrúek-sǎa", meaning: "tree / flora (poetic)", hindi: "वृक्ष (vṛkṣa)", note: ""),
        FunWord(thai: "อัคนี", roman: "àk-khá-nii", meaning: "fire (poetic)", hindi: "अग्नि (agni)", note: ""),
        FunWord(thai: "วารี", roman: "waa-rii", meaning: "water (poetic)", hindi: "वारि (vāri)", note: ""),
        FunWord(thai: "ปฐพี", roman: "pà-thá-phii", meaning: "earth / land (poetic)", hindi: "पृथ्वी (pṛthvī)", note: ""),
        FunWord(thai: "ดารา", roman: "daa-raa", meaning: "star / celebrity", hindi: "तारा (tārā)", note: "In Thai it mostly means a movie star!"),
        FunWord(thai: "อังคาร", roman: "ang-khaan", meaning: "Tuesday / Mars", hindi: "अंगारक (aṅgārak)", note: ""),
        FunWord(thai: "พุธ", roman: "phút", meaning: "Wednesday / Mercury", hindi: "बुध (budh)", note: ""),
        FunWord(thai: "พฤหัสบดี", roman: "phá-rúe-hàt-sà-boo-dii", meaning: "Thursday / Jupiter", hindi: "बृहस्पति (bṛhaspati)", note: ""),
        FunWord(thai: "ศุกร์", roman: "sùk", meaning: "Friday / Venus", hindi: "शुक्र (śukra)", note: ""),
        FunWord(thai: "เสาร์", roman: "sǎo", meaning: "Saturday / Saturn", hindi: "सौरि (sauri)", note: "Sauri, son of Surya = Saturn"),
        FunWord(thai: "นาที", roman: "naa-thii", meaning: "minute", hindi: "नाडी (nāḍī)", note: "The pulse (nāḍī) became the minute"),
        FunWord(thai: "ฤดู", roman: "rúe-duu", meaning: "season", hindi: "ऋतु (ṛtu)", note: ""),
        FunWord(thai: "จักรวาล", roman: "jàk-krà-waan", meaning: "universe", hindi: "चक्रवाल (cakravāl)", note: ""),
        FunWord(thai: "โลก", roman: "lôok", meaning: "world", hindi: "लोक (lok)", note: ""),
        FunWord(thai: "เทพ", roman: "thêep", meaning: "god / deity", hindi: "देव (dev)", note: "กรุงเทพ = city of devas"),
        FunWord(thai: "เทวี", roman: "thee-wii", meaning: "goddess", hindi: "देवी (devī)", note: ""),
        FunWord(thai: "นรก", roman: "ná-rók", meaning: "hell", hindi: "नरक (narak)", note: ""),
        FunWord(thai: "สันติ", roman: "sǎn-tì", meaning: "peace", hindi: "शांति (śānti)", note: "สันติภาพ = peace"),
        FunWord(thai: "กรุณา", roman: "kà-rú-naa", meaning: "please / compassion", hindi: "करुणा (karuṇā)", note: "'Please' in Thai is literally 'have compassion'"),
        FunWord(thai: "เมตตา", roman: "mêet-taa", meaning: "loving-kindness", hindi: "मैत्री (maitrī)", note: ""),
        FunWord(thai: "ฤาษี", roman: "ruue-sǐi", meaning: "hermit / sage", hindi: "ऋषि (ṛṣi)", note: ""),
        FunWord(thai: "บารมี", roman: "baa-rá-mii", meaning: "prestige / virtue", hindi: "पारमी (pāramī)", note: ""),
        FunWord(thai: "อธิษฐาน", roman: "à-thít-thǎan", meaning: "to pray / make a wish", hindi: "अधिष्ठान (adhiṣṭhān)", note: ""),
        FunWord(thai: "กุศล", roman: "kù-sǒn", meaning: "merit / good deed", hindi: "कुशल (kuśal)", note: ""),
        FunWord(thai: "อสูร", roman: "à-sǔun", meaning: "demon", hindi: "असुर (asur)", note: "The giants guarding Thai temples"),
        FunWord(thai: "ยม", roman: "yom", meaning: "god of death", hindi: "यम (yam)", note: "พญายม = Yamraj"),
        FunWord(thai: "พรหม", roman: "phrom", meaning: "Brahma", hindi: "ब्रह्मा (brahmā)", note: "The Erawan shrine is a Brahma shrine"),
        FunWord(thai: "อวตาร", roman: "à-wá-taan", meaning: "incarnation / avatar", hindi: "अवतार (avatār)", note: ""),
        FunWord(thai: "กิเลส", roman: "kì-lèet", meaning: "defilement / desire", hindi: "क्लेश (kleś)", note: ""),
        FunWord(thai: "สัจจะ", roman: "sàt-jà", meaning: "truth / vow", hindi: "सत्य (satya)", note: ""),
        FunWord(thai: "มรณะ", roman: "moo-rá-ná", meaning: "death (formal)", hindi: "मरण (maraṇ)", note: ""),
        FunWord(thai: "ศรัทธา", roman: "sàt-thaa", meaning: "faith", hindi: "श्रद्धा (śraddhā)", note: ""),
        FunWord(thai: "สังสารวัฏ", roman: "sǎng-sǎa-rá-wát", meaning: "cycle of rebirth", hindi: "संसार (saṃsār)", note: "Thai สงสาร (pity) has the same root!"),
        FunWord(thai: "นิพพาน", roman: "níp-phaan", meaning: "nirvana", hindi: "निर्वाण (nirvāṇ)", note: ""),
        FunWord(thai: "รูป", roman: "rûup", meaning: "form / picture", hindi: "रूप (rūp)", note: "รูปภาพ = photo"),
        FunWord(thai: "รส", roman: "rót", meaning: "taste / flavor", hindi: "रस (ras)", note: "รสชาติ = flavor"),
        FunWord(thai: "กาย", roman: "kaai", meaning: "body", hindi: "काय (kāy)", note: "ร่างกาย = body"),
        FunWord(thai: "จักร", roman: "jàk", meaning: "wheel / machine", hindi: "चक्र (cakra)", note: "จักรยาน bicycle, จักรวาล universe"),
        FunWord(thai: "จักรยาน", roman: "jàk-krà-yaan", meaning: "bicycle", hindi: "चक्रयान (cakrayān)", note: "'Wheel vehicle' — pure Sanskrit bicycle"),
        FunWord(thai: "อากาศยาน", roman: "aa-kàat-sà-yaan", meaning: "aircraft", hindi: "आकाशयान (ākāśyān)", note: "'Sky vehicle'"),
        FunWord(thai: "รถ", roman: "rót", meaning: "car / vehicle", hindi: "रथ (rath)", note: "The chariot became the car"),
        FunWord(thai: "สัตว์", roman: "sàt", meaning: "animal", hindi: "सत्त्व (sattva)", note: "'Living being' became 'animal'"),
        FunWord(thai: "โฆษณา", roman: "khôot-sà-naa", meaning: "advertisement", hindi: "घोषणा (ghoṣaṇā)", note: "An announcement became an ad"),
        FunWord(thai: "สมบูรณ์", roman: "sǒm-buun", meaning: "complete / perfect", hindi: "सम्पूर्ण (sampūrṇa)", note: ""),
        FunWord(thai: "หัตถ์", roman: "hàt", meaning: "hand (royal)", hindi: "हस्त (hast)", note: "หัตถกรรม = handicraft"),
        FunWord(thai: "บาท", roman: "bàat", meaning: "baht / foot (royal)", hindi: "पाद (pād)", note: "The currency baht is Sanskrit pāda!"),
        FunWord(thai: "เนตร", roman: "nêet", meaning: "eye (poetic)", hindi: "नेत्र (netra)", note: ""),
        FunWord(thai: "กรรณ", roman: "kan", meaning: "ear (royal)", hindi: "कर्ण (karṇ)", note: ""),
        FunWord(thai: "โอษฐ์", roman: "òot", meaning: "lips (royal)", hindi: "ओष्ठ (oṣṭh)", note: ""),
        FunWord(thai: "จิตรกร", roman: "jìt-trà-koon", meaning: "painter / artist", hindi: "चित्रकार (citrakār)", note: ""),
        FunWord(thai: "วิศวกร", roman: "wít-sà-wá-koon", meaning: "engineer", hindi: "विश्वकर्मा (viśvakarmā)", note: "Named after the divine architect"),
        FunWord(thai: "แพทย์", roman: "phâet", meaning: "doctor", hindi: "वैद्य (vaidya)", note: "The vaidya became the modern doctor"),
        FunWord(thai: "เภสัช", roman: "phee-sàt", meaning: "pharmacy / medicine", hindi: "भेषज (bheṣaj)", note: ""),
        FunWord(thai: "ธนาคาร", roman: "thá-naa-khaan", meaning: "bank", hindi: "धन + आगार (dhan-āgār)", note: "'House of wealth' = bank"),
        FunWord(thai: "ชัย", roman: "chai", meaning: "victory", hindi: "जय (jay)", note: "Chiang Mai's ไชย, and จามจุรี... it is everywhere"),
        FunWord(thai: "ยุทธ", roman: "yút", meaning: "war / battle", hindi: "युद्ध (yuddh)", note: "ยุทธศาสตร์ = strategy"),
        FunWord(thai: "อาวุธ", roman: "aa-wút", meaning: "weapon", hindi: "आयुध (āyudh)", note: ""),
        FunWord(thai: "พินาศ", roman: "phí-nâat", meaning: "destruction / ruin", hindi: "विनाश (vināś)", note: ""),
        FunWord(thai: "ลักษณะ", roman: "lák-sà-nà", meaning: "characteristic", hindi: "लक्षण (lakṣaṇ)", note: ""),
        FunWord(thai: "พฤติกรรม", roman: "phrúet-tì-kam", meaning: "behavior", hindi: "वृत्ति + कर्म (vṛtti-karma)", note: ""),
        FunWord(thai: "ปฏิเสธ", roman: "pà-tì-sèet", meaning: "to deny / refuse", hindi: "प्रतिषेध (pratiṣedh)", note: ""),
        FunWord(thai: "อนุญาต", roman: "à-nú-yâat", meaning: "to permit", hindi: "अनुज्ञा (anujñā)", note: ""),
        FunWord(thai: "ประมาณ", roman: "prà-maan", meaning: "approximately / estimate", hindi: "प्रमाण (pramāṇ)", note: ""),
        FunWord(thai: "ประกาศ", roman: "prà-kàat", meaning: "to announce", hindi: "प्रकाश (prakāś)", note: "'To make light/visible' = announce"),
        FunWord(thai: "ประธาน", roman: "prà-thaan", meaning: "chairman / president", hindi: "प्रधान (pradhān)", note: ""),
        FunWord(thai: "บริการ", roman: "boo-rí-kaan", meaning: "service", hindi: "परिकार (parikār)", note: ""),
        FunWord(thai: "บริสุทธิ์", roman: "boo-rí-sùt", meaning: "pure / innocent", hindi: "परिशुद्ध (pariśuddh)", note: ""),
        FunWord(thai: "อุปสรรค", roman: "ùp-pà-sàk", meaning: "obstacle", hindi: "उपसर्ग (upasarg)", note: ""),
        FunWord(thai: "สากล", roman: "sǎa-kon", meaning: "universal / international", hindi: "सकल (sakal)", note: ""),
        FunWord(thai: "กตัญญู", roman: "kà-tan-yuu", meaning: "grateful", hindi: "कृतज्ञ (kṛtajña)", note: "A core Thai value word"),
        FunWord(thai: "ยุติธรรม", roman: "yút-tì-tham", meaning: "justice / fair", hindi: "युक्ति + धर्म (yukti-dharma)", note: ""),
        FunWord(thai: "อุดม", roman: "ù-dom", meaning: "abundant / supreme", hindi: "उत्तम (uttam)", note: "อุดมสมบูรณ์ = fertile and abundant"),
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

    static let opposites: [WordPair] = [
        WordPair(thaiA: "ใหญ่", romanA: "yài", meaningA: "big", hindiA: "बड़ा",
                 thaiB: "เล็ก", romanB: "lék", meaningB: "small", hindiB: "छोटा",
                 note: "The first pair every learner needs — sizes, rooms, portions"),
        WordPair(thaiA: "ร้อน", romanA: "rón", meaningA: "hot", hindiA: "गरम",
                 thaiB: "หนาว", romanB: "nǎao", meaningB: "cold", hindiB: "ठंडा",
                 note: "For weather and how you feel — น้ำร้อน hot water, อากาศหนาว cold weather"),
        WordPair(thaiA: "ใหม่", romanA: "mài", meaningA: "new", hindiA: "नया",
                 thaiB: "เก่า", romanB: "kào", meaningB: "old (things)", hindiB: "पुराना",
                 note: "เก่า is for things only — old people use แก่ (kàe)"),
        WordPair(thaiA: "เร็ว", romanA: "reo", meaningA: "fast", hindiA: "तेज़",
                 thaiB: "ช้า", romanB: "cháa", meaningB: "slow", hindiB: "धीमा",
                 note: "ช้า ๆ (cháa cháa) = \"slowly please!\" — say it to taxi drivers"),
        WordPair(thaiA: "ง่าย", romanA: "ngâai", meaningA: "easy", hindiA: "आसान",
                 thaiB: "ยาก", romanB: "yâak", meaningB: "difficult", hindiB: "मुश्किल",
                 note: "ภาษาไทยไม่ยาก — Thai is not hard!"),
        WordPair(thaiA: "ใกล้", romanA: "klâi", meaningA: "near", hindiA: "पास",
                 thaiB: "ไกล", romanB: "klai", meaningB: "far", hindiB: "दूर",
                 note: "Thai's cruelest joke: near and far differ ONLY by tone — falling = near, mid = far"),
        WordPair(thaiA: "แพง", romanA: "phaeng", meaningA: "expensive", hindiA: "महँगा",
                 thaiB: "ถูก", romanB: "thùuk", meaningB: "cheap", hindiB: "सस्ता",
                 note: "แพงไป (too expensive) is your bargaining opener at any market"),
        WordPair(thaiA: "มาก", romanA: "mâak", meaningA: "a lot / very", hindiA: "बहुत",
                 thaiB: "น้อย", romanB: "nói", meaningB: "little / few", hindiB: "कम",
                 note: "Both come after the word: อร่อยมาก very tasty, กินน้อย eat little"),
        WordPair(thaiA: "ดี", romanA: "dii", meaningA: "good", hindiA: "अच्छा",
                 thaiB: "แย่", romanB: "yâe", meaningB: "bad / terrible", hindiB: "बुरा",
                 note: "Thais often soften แย่ to ไม่ดี (not good) — more polite"),
        WordPair(thaiA: "สะอาด", romanA: "sà-àat", meaningA: "clean", hindiA: "साफ़",
                 thaiB: "สกปรก", romanB: "sòk-kà-pròk", meaningB: "dirty", hindiB: "गंदा",
                 note: ""),
        WordPair(thaiA: "อ้วน", romanA: "ûan", meaningA: "fat", hindiA: "मोटा",
                 thaiB: "ผอม", romanB: "phǒom", meaningB: "thin", hindiB: "दुबला",
                 note: "Thais comment on weight casually — อ้วนขึ้น (got fatter) is small talk, not an insult"),
        WordPair(thaiA: "ยาว", romanA: "yaao", meaningA: "long", hindiA: "लंबा",
                 thaiB: "สั้น", romanB: "sân", meaningB: "short (length)", hindiB: "छोटा (लंबाई)",
                 note: "For length only — a short person is เตี้ย (tîa)"),
        WordPair(thaiA: "กว้าง", romanA: "kwâang", meaningA: "wide", hindiA: "चौड़ा",
                 thaiB: "แคบ", romanB: "khâep", meaningB: "narrow", hindiB: "संकरा",
                 note: ""),
        WordPair(thaiA: "หนัก", romanA: "nàk", meaningA: "heavy", hindiA: "भारी",
                 thaiB: "เบา", romanB: "bao", meaningB: "light (weight)", hindiB: "हल्का",
                 note: "เบา ๆ = gently / softly — useful for massages and music volume"),
        WordPair(thaiA: "ดัง", romanA: "dang", meaningA: "loud", hindiA: "तेज़ (आवाज़)",
                 thaiB: "เงียบ", romanB: "ngîap", meaningB: "quiet", hindiB: "शांत",
                 note: "ดัง also means famous — คนดัง = celebrity"),
        WordPair(thaiA: "สูง", romanA: "sǔung", meaningA: "tall / high", hindiA: "ऊँचा",
                 thaiB: "ต่ำ", romanB: "tàm", meaningB: "low", hindiB: "नीचा",
                 note: "New word alert: ต่ำ — you'll see it on price boards (ราคาต่ำ low price)"),
        WordPair(thaiA: "หวาน", romanA: "wǎan", meaningA: "sweet", hindiA: "मीठा",
                 thaiB: "ขม", romanB: "khǒm", meaningB: "bitter", hindiB: "कड़वा",
                 note: "Order coffee หวานน้อย (a little sweet) or Thai default will be VERY sweet"),
        WordPair(thaiA: "แห้ง", romanA: "hâeng", meaningA: "dry", hindiA: "सूखा",
                 thaiB: "เปียก", romanB: "pìak", meaningB: "wet", hindiB: "गीला",
                 note: "Both on menus too: ก๋วยเตี๋ยวแห้ง dry noodles vs น้ำ soup version"),
        WordPair(thaiA: "เปิด", romanA: "pòet", meaningA: "open / turn on", hindiA: "खोलना",
                 thaiB: "ปิด", romanB: "pìt", meaningB: "close / turn off", hindiB: "बंद करना",
                 note: "Same pair works for shops, doors, lights and AC — เปิดแอร์ turn on the AC"),
        WordPair(thaiA: "ไป", romanA: "pai", meaningA: "to go", hindiA: "जाना",
                 thaiB: "มา", romanB: "maa", meaningB: "to come", hindiB: "आना",
                 note: "The two most-used verbs in Thai — ไปไหนมา = \"where have you been?\""),
        WordPair(thaiA: "ซื้อ", romanA: "súue", meaningA: "to buy", hindiA: "खरीदना",
                 thaiB: "ขาย", romanB: "khǎai", meaningB: "to sell", hindiB: "बेचना",
                 note: "ซื้อขาย together = trade / commerce"),
        WordPair(thaiA: "นอน", romanA: "noon", meaningA: "to sleep", hindiA: "सोना",
                 thaiB: "ตื่น", romanB: "tùuen", meaningB: "to wake up", hindiB: "जागना",
                 note: ""),
        WordPair(thaiA: "จำ", romanA: "jam", meaningA: "to remember", hindiA: "याद रखना",
                 thaiB: "ลืม", romanB: "luem", meaningB: "to forget", hindiB: "भूलना",
                 note: "จำได้ = I remember; ลืมแล้ว = I forgot already"),
        WordPair(thaiA: "เริ่ม", romanA: "rêrm", meaningA: "to begin", hindiA: "शुरू करना",
                 thaiB: "เสร็จ", romanB: "sèt", meaningB: "to finish", hindiB: "ख़त्म होना",
                 note: "เสร็จแล้ว = done! — you'll hear it everywhere"),
        WordPair(thaiA: "ถาม", romanA: "thǎam", meaningA: "to ask", hindiA: "पूछना",
                 thaiB: "ตอบ", romanB: "tòop", meaningB: "to answer", hindiB: "जवाब देना",
                 note: "คำถาม question, คำตอบ answer — just add คำ (word)"),
        WordPair(thaiA: "ส่ง", romanA: "sòng", meaningA: "to send", hindiA: "भेजना",
                 thaiB: "รับ", romanB: "ráp", meaningB: "to receive", hindiB: "पाना",
                 note: "Airport signs: ส่ง departures/drop-off, รับ arrivals/pick-up"),
        WordPair(thaiA: "เข้า", romanA: "khâo", meaningA: "to enter", hindiA: "अंदर जाना",
                 thaiB: "ออก", romanB: "òok", meaningB: "to exit", hindiB: "बाहर निकलना",
                 note: "ทางเข้า entrance, ทางออก exit — the two signs you need in every mall"),
        WordPair(thaiA: "ยืน", romanA: "yuuen", meaningA: "to stand", hindiA: "खड़ा होना",
                 thaiB: "นั่ง", romanB: "nâng", meaningB: "to sit", hindiB: "बैठना",
                 note: ""),
        WordPair(thaiA: "หัวเราะ", romanA: "hǔa-ró", meaningA: "to laugh", hindiA: "हँसना",
                 thaiB: "ร้องไห้", romanB: "róong-hâi", meaningB: "to cry", hindiB: "रोना",
                 note: "หัวเราะ literally starts with หัว (head) — laughing with your whole head"),
        WordPair(thaiA: "ซ้าย", romanA: "sáai", meaningA: "left", hindiA: "बायाँ",
                 thaiB: "ขวา", romanB: "khwǎa", meaningB: "right", hindiB: "दायाँ",
                 note: "เลี้ยวซ้าย turn left, เลี้ยวขวา turn right — taxi essentials"),
        WordPair(thaiA: "ข้างบน", romanA: "khâang-bon", meaningA: "above / upstairs", hindiA: "ऊपर",
                 thaiB: "ข้างล่าง", romanB: "khâang-lâang", meaningB: "below / downstairs", hindiB: "नीचे",
                 note: ""),
        WordPair(thaiA: "เช้า", romanA: "cháao", meaningA: "morning", hindiA: "सुबह",
                 thaiB: "เย็น", romanB: "yen", meaningB: "evening", hindiB: "शाम",
                 note: "ตอนเช้า in the morning, ตอนเย็น in the evening"),
        WordPair(thaiA: "ก่อน", romanA: "kòon", meaningA: "before", hindiA: "पहले",
                 thaiB: "หลัง", romanB: "lǎng", meaningB: "after", hindiB: "बाद",
                 note: "ก่อนกิน before eating, หลังกิน after eating — on every medicine label"),
        WordPair(thaiA: "พรุ่งนี้", romanA: "phrûng-níi", meaningA: "tomorrow", hindiA: "आने वाला कल",
                 thaiB: "เมื่อวาน", romanB: "mûea-waan", meaningB: "yesterday", hindiB: "बीता कल",
                 note: "Unlike Hindi's one कल for both, Thai keeps them separate"),
        WordPair(thaiA: "ดีใจ", romanA: "dii-jai", meaningA: "happy / glad", hindiA: "खुश",
                 thaiB: "เสียใจ", romanB: "sǐa-jai", meaningB: "sad", hindiB: "दुखी",
                 note: "Literally good-heart vs lost-heart — ใจ (heart) builds dozens of feeling words"),
        WordPair(thaiA: "หิว", romanA: "hǐu", meaningA: "hungry", hindiA: "भूखा",
                 thaiB: "อิ่ม", romanB: "ìm", meaningB: "full (after eating)", hindiB: "पेट भरा",
                 note: "อิ่มแล้ว (I'm full) is the polite way to stop a Thai host from refilling your plate"),
        WordPair(thaiA: "เสมอ", romanA: "sà-měr", meaningA: "always", hindiA: "हमेशा",
                 thaiB: "ไม่เคย", romanB: "mâi-kheuy", meaningB: "never", hindiB: "कभी नहीं",
                 note: ""),
        WordPair(thaiA: "ด้วยกัน", romanA: "dûai-kan", meaningA: "together", hindiA: "साथ में",
                 thaiB: "คนเดียว", romanB: "kon-diao", meaningB: "alone", hindiB: "अकेला",
                 note: "มาคนเดียวเหรอ — \"you came alone?\" A question solo travelers hear daily"),
        WordPair(thaiA: "ถูกต้อง", romanA: "thùuk-tông", meaningA: "correct", hindiA: "सही",
                 thaiB: "ผิด", romanB: "phìt", meaningB: "wrong", hindiB: "गलत",
                 note: "ถูก alone also means correct — same word as \"cheap\", context decides"),
        WordPair(thaiA: "ผู้ชาย", romanA: "phûu-chaai", meaningA: "man", hindiA: "आदमी",
                 thaiB: "ผู้หญิง", romanB: "phûu-yǐng", meaningB: "woman", hindiB: "औरत",
                 note: "ผู้ = person; ห้องน้ำชาย / ห้องน้ำหญิง on restroom doors drop the ผู้"),
        WordPair(thaiA: "สุข", romanA: "sùk", meaningA: "happiness", hindiA: "सुख",
                 thaiB: "ทุกข์", romanB: "thúk", meaningB: "suffering", hindiB: "दुःख",
                 note: "Straight from Sanskrit — the same सुख-दुःख pair Hindi uses. See Hindi–Thai Cousins!"),
    ]

    static let similars: [WordPair] = [
        WordPair(thaiA: "มาก", romanA: "mâak", meaningA: "very / a lot", hindiA: "बहुत",
                 thaiB: "เยอะ", romanB: "yóe", meaningB: "a lot / many", hindiB: "ढेर सारा",
                 note: "มาก intensifies (ร้อนมาก very hot); เยอะ is for amounts (คนเยอะ lots of people)"),
        WordPair(thaiA: "เล็ก", romanA: "lék", meaningA: "small (size)", hindiA: "छोटा",
                 thaiB: "น้อย", romanB: "nói", meaningB: "little (amount)", hindiB: "कम",
                 note: "บ้านเล็ก small house, but เงินน้อย little money — size vs amount"),
        WordPair(thaiA: "ดู", romanA: "duu", meaningA: "to look / watch", hindiA: "देखना",
                 thaiB: "เห็น", romanB: "hěn", meaningB: "to see", hindiB: "दिखना",
                 note: "ดู is deliberate (watch TV); เห็น just happens (I saw him) — like देखना vs दिखना"),
        WordPair(thaiA: "พูด", romanA: "phûut", meaningA: "to speak", hindiA: "बोलना",
                 thaiB: "คุย", romanB: "khui", meaningB: "to chat", hindiB: "बात करना",
                 note: "พูดภาษาไทย speak Thai; คุยกับเพื่อน chat with friends — คุย is two-way and casual"),
        WordPair(thaiA: "กิน", romanA: "kin", meaningA: "to eat", hindiA: "खाना",
                 thaiB: "ทาน", romanB: "thaan", meaningB: "to eat (polite)", hindiB: "खाना (आदरपूर्वक)",
                 note: "ทาน with elders, staff, strangers; กิน with friends. Waiters will ask ทานอะไรดี"),
        WordPair(thaiA: "รู้", romanA: "rúu", meaningA: "to know", hindiA: "जानना",
                 thaiB: "ทราบ", romanB: "sâap", meaningB: "to know (formal)", hindiB: "ज्ञात होना",
                 note: "ไม่ทราบ is the polite \"I don't know\" — use it with officials and elders"),
        WordPair(thaiA: "เจอ", romanA: "jer", meaningA: "to meet / run into", hindiA: "मिलना",
                 thaiB: "พบ", romanB: "phóp", meaningB: "to meet (formal)", hindiB: "भेंट करना",
                 note: "เจอกัน see you! (casual); พบ for appointments and news headlines"),
        WordPair(thaiA: "รอ", romanA: "roo", meaningA: "to wait", hindiA: "इंतज़ार करना",
                 thaiB: "คอย", romanB: "khoi", meaningB: "to wait / keep waiting", hindiB: "प्रतीक्षा करना",
                 note: "Nearly interchangeable; รอคอย together = to long for (song lyrics love it)"),
        WordPair(thaiA: "ชอบ", romanA: "chôp", meaningA: "to like", hindiA: "पसंद करना",
                 thaiB: "รัก", romanB: "rák", meaningB: "to love", hindiB: "प्यार करना",
                 note: "Same ladder as English — ชอบมาก (really like) sits safely between them"),
        WordPair(thaiA: "อยาก", romanA: "yàak", meaningA: "to want (to do)", hindiA: "चाहना (क्रिया)",
                 thaiB: "เอา", romanB: "ao", meaningB: "to want (a thing)", hindiB: "लेना / चाहिए",
                 note: "อยากไป want to go; เอาน้ำ want water — verb after อยาก, noun after เอา"),
        WordPair(thaiA: "ต้อง", romanA: "tôong", meaningA: "must", hindiA: "पड़ना / ज़रूरी",
                 thaiB: "ควร", romanB: "khuan", meaningB: "should", hindiB: "चाहिए",
                 note: "ต้องไป must go; ควรไป should go — obligation vs advice"),
        WordPair(thaiA: "เร็ว", romanA: "reo", meaningA: "fast", hindiA: "तेज़",
                 thaiB: "ไว", romanB: "wai", meaningB: "quick / prompt", hindiB: "फुर्तीला",
                 note: "เร็ว ๆ = hurry up!; ไว is about reacting quickly — เรียนไว = fast learner"),
        WordPair(thaiA: "ใหญ่", romanA: "yài", meaningA: "big", hindiA: "बड़ा",
                 thaiB: "โต", romanB: "too", meaningB: "big / grown-up", hindiB: "बड़ा (बढ़ा हुआ)",
                 note: "โต is about growing — โตขึ้น = to grow up; ใหญ่ is plain size"),
        WordPair(thaiA: "สวย", romanA: "sǔai", meaningA: "beautiful", hindiA: "सुंदर",
                 thaiB: "งาม", romanB: "ngaam", meaningB: "graceful / lovely", hindiB: "मनोहर",
                 note: "งาม is poetic/traditional; together สวยงาม = beautiful (formal). Careful: flat-tone suai = unlucky!"),
        WordPair(thaiA: "หนาว", romanA: "nǎao", meaningA: "cold (feeling)", hindiA: "ठंड (एहसास)",
                 thaiB: "เย็น", romanB: "yen", meaningB: "cool / cold (things)", hindiB: "ठंडा (चीज़ें)",
                 note: "You feel หนาว; drinks are เย็น — น้ำเย็น cold water, never น้ำหนาว"),
        WordPair(thaiA: "ร้อน", romanA: "rón", meaningA: "hot", hindiA: "गरम",
                 thaiB: "อุ่น", romanB: "ùn", meaningB: "warm", hindiB: "गुनगुना",
                 note: "น้ำอุ่น warm water for showers; อบอุ่น = warm-hearted / cozy"),
        WordPair(thaiA: "ปวด", romanA: "pùat", meaningA: "to ache", hindiA: "दर्द होना",
                 thaiB: "เจ็บ", romanB: "jèp", meaningB: "to hurt (sharp)", hindiB: "चोट का दर्द",
                 note: "ปวดหัว headache (dull, inside); เจ็บ for cuts and injuries — tell the pharmacy the right one"),
        WordPair(thaiA: "เหนื่อย", romanA: "nùeai", meaningA: "tired", hindiA: "थका हुआ",
                 thaiB: "ง่วง", romanB: "ngûang", meaningB: "sleepy", hindiB: "उनींदा",
                 note: "เหนื่อย after exercise; ง่วง after lunch — Thais never mix these up"),
        WordPair(thaiA: "ดี", romanA: "dii", meaningA: "good", hindiA: "अच्छा",
                 thaiB: "เก่ง", romanB: "kèng", meaningB: "good at / skilled", hindiB: "होशियार",
                 note: "คนดี good person (character); เก่ง for skills — พูดไทยเก่ง = you speak Thai well!"),
        WordPair(thaiA: "ตอนนี้", romanA: "toon-níi", meaningA: "now", hindiA: "अभी",
                 thaiB: "เดี๋ยวนี้", romanB: "dǐao-níi", meaningB: "right now!", hindiB: "अभी इसी वक़्त",
                 note: "เดี๋ยวนี้ has urgency — what a parent says the second time"),
        WordPair(thaiA: "เงิน", romanA: "ngoen", meaningA: "money", hindiA: "पैसा",
                 thaiB: "ตังค์", romanB: "tang", meaningB: "money (colloquial)", hindiB: "पैसे (बोलचाल)",
                 note: "ตังค์ from สตางค์ (satang, the coin) — ไม่มีตังค์ = I'm broke, like हिंदी का \"पैसे नहीं हैं\""),
        WordPair(thaiA: "สบาย", romanA: "sà-baai", meaningA: "comfortable / relaxed", hindiA: "आराम से",
                 thaiB: "ชิวๆ", romanB: "chiu-chiu", meaningB: "chill (slang)", hindiB: "चिल",
                 note: "Same vibe, different register — see Thai Slang for more ชิวๆ"),
        WordPair(thaiA: "อร่อย", romanA: "à-ròi", meaningA: "delicious", hindiA: "स्वादिष्ट",
                 thaiB: "แซ่บ", romanB: "sâep", meaningB: "spicy-delicious (slang)", hindiB: "मस्त-तीखा",
                 note: "แซ่บ is Isaan slang for food that's deliciously fiery — som tam is never just อร่อย"),
        WordPair(thaiA: "บอก", romanA: "bòok", meaningA: "to tell", hindiA: "बताना",
                 thaiB: "พูด", romanB: "phûut", meaningB: "to speak / say", hindiB: "बोलना",
                 note: "บอก needs a listener (tell me = บอกหน่อย); พูด is just producing words"),
    ]
}

#Preview {
    ContentView()
}
