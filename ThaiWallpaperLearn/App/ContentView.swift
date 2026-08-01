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
    @State private var selectedTab: Int = {
        #if DEBUG
        // `simctl launch … -openPractice` → screenshot automation lands on Practice.
        if ProcessInfo.processInfo.arguments.contains("-openPractice") { return 1 }
        #endif
        return 0
    }()

    /// Word opened from a widget tap (thailearn://word/<id>).
    @State private var deepLinkWord: ThaiWord? = {
        #if DEBUG
        // `simctl launch … -openWord=<id>` opens the detail sheet directly,
        // standing in for a widget tap in screenshot automation.
        if let arg = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("-openWord=") }),
           let id = Int(arg.dropFirst("-openWord=".count)) {
            return Vocabulary.all.first { $0.id == id }
        }
        #endif
        return nil
    }()

    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasOnboarded.v1")

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)

            FlashcardView()
                .tabItem { Label("Practice", systemImage: "rectangle.on.rectangle.angled") }
                .tag(1)

            BrowseView()
                .tabItem { Label("Browse", systemImage: "list.bullet") }
                .tag(2)

            AlphabetView()
                .tabItem { Label("Alphabet", systemImage: "character.book.closed.fill") }
                .tag(3)

            MoreView()
                .tabItem { Label("More", systemImage: "sparkles") }
                .tag(4)
        }
        .tint(ThaiTheme.indigo)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(selectedTab: $selectedTab)
        }
        .onOpenURL { url in
            guard url.scheme == "thailearn", url.host() == "word",
                  let id = Int(url.lastPathComponent),
                  let word = Vocabulary.all.first(where: { $0.id == id }) else { return }
            deepLinkWord = word
        }
        .sheet(item: $deepLinkWord) { word in
            WordDetailView(word: word)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Today (word of the day)

struct TodayView: View {
    @Binding var selectedTab: Int
    @State private var word: ThaiWord = Vocabulary.word(forDayOffset: Self.dayOffset())
    @State private var showWidgetHelp = false
    @State private var streak = ProgressStore.shared.currentStreak()
    @State private var dueCounts = ProgressStore.shared.counts(in: Vocabulary.all)
    @State private var reviewsToday = ProgressStore.shared.reviewsToday
    @State private var reminderOn = ReminderService.isEnabled

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
                VStack(spacing: ThaiTheme.spaceMD) {
                    HStack {
                        Text(dayLine)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(ThaiTheme.stone)
                        Spacer()
                        if streak > 0 {
                            Label("\(streak)-day streak", systemImage: "flame.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(ThaiTheme.gold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .thaiGlass(cornerRadius: ThaiTheme.radiusControl)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    WordCard(word: word)

                    practiceStrip

                    actionRow
                }
                .padding(.bottom, ThaiTheme.spaceXL)
            }
            .glassWashBackground()
            .navigationTitle("เรียนภาษาไทย")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: ShareCardRenderer.image(for: word),
                        preview: SharePreview("\(word.thai) — \(word.englishMeaning)",
                                              image: ShareCardRenderer.image(for: word))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        ReminderService.toggle { on in reminderOn = on }
                    } label: {
                        Image(systemName: reminderOn ? "bell.fill" : "bell")
                    }
                }
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
                reviewsToday = ProgressStore.shared.reviewsToday
            }
        }
    }

    private var goalDone: Bool { reviewsToday >= ProgressStore.dailyGoal }

    /// SRS status — taps through to the Practice tab.
    private var practiceStrip: some View {
        Button {
            selectedTab = 1
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: ThaiTheme.spaceSM) {
                    Circle().fill(ThaiTheme.jade).frame(width: 8, height: 8)
                    Text(goalDone
                         ? "Goal done — \(reviewsToday) cards today 🎉"
                         : dueCounts.due > 0
                         ? "Practice today · \(dueCounts.due) due, \(min(dueCounts.fresh, 20)) new"
                         : "Practice today · \(min(dueCounts.fresh, 20)) new words waiting")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(goalDone ? ThaiTheme.accent2 : ThaiTheme.ink)
                    Spacer()
                    Text("\(min(reviewsToday, ProgressStore.dailyGoal))/\(ProgressStore.dailyGoal)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(goalDone ? ThaiTheme.accent2 : ThaiTheme.textMuted)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ThaiTheme.hairline)
                        Capsule()
                            .fill(goalDone ? ThaiTheme.accent2 : ThaiTheme.accent)
                            .frame(width: geo.size.width *
                                   min(CGFloat(reviewsToday) / CGFloat(ProgressStore.dailyGoal), 1))
                    }
                }
                .frame(height: 5)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .thaiGlass(cornerRadius: ThaiTheme.radiusControl)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    /// Primary actions live in the thumb zone, not mid-card.
    private var actionRow: some View {
        HStack(spacing: 10) {
            PrimaryButton(title: "Play", icon: "speaker.wave.2.fill") {
                SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
            }

            IconGlassButton(systemName: "shuffle", foreground: ThaiTheme.indigo) {
                withAnimation(.spring(duration: 0.35)) {
                    word = Vocabulary.randomWord()
                }
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

struct AlphabetView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        classKey(color: ThaiTheme.indigo, label: "middle")
                        classKey(color: ThaiTheme.orchid, label: "high")
                        classKey(color: ThaiTheme.classLow, label: "low")
                    }
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

    private func classKey(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(ThaiTheme.ink)
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
                        .background(ThaiTheme.gold, in: RoundedRectangle(cornerRadius: ThaiTheme.radiusChip))
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
    @State private var detailWord: ThaiWord?

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
            .background(ThaiTheme.sand)
            .searchable(text: $query, prompt: "Search Thai, English or Hindi")
            .navigationTitle("All Words")
            .onChange(of: selection) { visibleCount = Self.pageSize }
            .onChange(of: query) { visibleCount = Self.pageSize }
            .sheet(item: $detailWord) { word in
                WordDetailView(word: word)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ThaiTheme.spaceSM) {
                FilterChip(label: "All", selected: selection == "All") { selection = "All" }
                ForEach(WordCollection.all, id: \.name) { collection in
                    FilterChip(
                        label: "\(collection.emoji) \(collection.name)",
                        selected: selection == collection.name
                    ) { selection = collection.name }
                }
                ForEach(Vocabulary.categories.filter { category in
                    !WordCollection.all.contains { $0.name == category }
                }, id: \.self) { category in
                    FilterChip(label: category, selected: selection == category) {
                        selection = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, ThaiTheme.spaceSM)
        }
        .background(ThaiTheme.sand)
    }

    private var wordList: some View {
        // Only `visibleCount` rows are materialized at once; the button at
        // the bottom pages in the next batch so scrolling stays smooth.
        List {
            if query.isEmpty {
                suggestions
            }
            ForEach(filtered.prefix(visibleCount)) { word in
                row(word)
                    .listRowBackground(ThaiTheme.cream)
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
                .listRowBackground(ThaiTheme.parchment)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(ThaiTheme.sand)
    }

    /// Quick entry points shown while the search field is empty: words due
    /// for review and recently opened details.
    @ViewBuilder private var suggestions: some View {
        let due = Vocabulary.all.filter { ProgressStore.shared.isDue($0.id) }.prefix(6)
        let recents = ProgressStore.shared.recentlyViewed.prefix(6)
        if !due.isEmpty || !recents.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if !due.isEmpty {
                    suggestionRow(label: "DUE TODAY", words: Array(due), tint: ThaiTheme.accent2)
                }
                if !recents.isEmpty {
                    suggestionRow(label: "RECENT", words: Array(recents), tint: ThaiTheme.accent)
                }
            }
            .padding(.vertical, 6)
            .listRowBackground(ThaiTheme.surfaceSunken.opacity(0.5))
        }
    }

    private func suggestionRow(label: String, words: [ThaiWord], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(ThaiTheme.textMuted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(words) { word in
                        Button {
                            detailWord = word
                        } label: {
                            Text("\(word.thai) · \(word.englishMeaning)")
                                .font(.footnote.weight(.semibold))
                                .lineLimit(1)
                                .foregroundStyle(tint)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(tint.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
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
                    .foregroundStyle(ThaiTheme.indigo)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { detailWord = word }
    }

    /// Learning state at a glance: gray = unseen, gold = learning, jade = known.
    private func progressColor(for word: ThaiWord) -> Color {
        switch ProgressStore.shared.box(for: word.id) {
        case 0: return ThaiTheme.stone.opacity(0.35)
        case 1, 2: return ThaiTheme.gold
        default: return ThaiTheme.success
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
                .background(color, in: RoundedRectangle(cornerRadius: 10))
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
                    HStack(spacing: 6) {
                        LanguageTag(kind: .en)
                        Text(word.meaning)
                            .font(.subheadline)
                            .foregroundStyle(ThaiTheme.ink)
                        Text("·")
                            .foregroundStyle(.secondary)
                        LanguageTag(kind: .hi)
                        Text(word.hindi)
                            .font(.subheadline)
                            .foregroundStyle(ThaiTheme.ink)
                    }
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
    // Lifted out of this file into content.json on 2026-08-02 so Android can
    // show the More tab too — it previously had no access to any of this.
    static let slang: [FunWord] = ContentStore.slang
    static let cousins: [FunWord] = ContentStore.cousins
    static let opposites: [WordPair] = ContentStore.opposites
    static let similars: [WordPair] = ContentStore.similars
    static let facts: [(String, String)] = ContentStore.facts
}

#Preview {
    ContentView()
}
