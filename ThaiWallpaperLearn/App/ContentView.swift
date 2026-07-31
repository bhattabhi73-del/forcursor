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

            HelpView()
                .tabItem { Label("Widget", systemImage: "square.grid.2x2.fill") }
        }
    }
}

// MARK: - Today (word of the day)

struct TodayView: View {
    @State private var word: ThaiWord = Vocabulary.word(forDayOffset: Self.dayOffset())

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
            .background(Color(.systemGroupedBackground))
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

            Button {
                SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
            } label: {
                Label("Play", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .background(Color.accentColor.opacity(0.15), in: Capsule())

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
                .font(.caption2)
                .tracking(1.2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(compact ? 16 : 28)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
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
        }
    }

    private func meaningRow(flag: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(flag)
            Text(value)
                .font(.title3)
                .multilineTextAlignment(.center)
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

    func contains(_ word: ThaiWord) -> Bool {
        categories.contains(word.category) || extraIDs.contains(word.id)
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
            categories: ["Money", "Numbers", "Food"],
            extraIDs: [48, 49, 50]
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
                ForEach(Vocabulary.categories, id: \.self) { category in
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
                .background(
                    selection == value ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground),
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

#Preview {
    ContentView()
}
