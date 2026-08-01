import SwiftUI

/// Guess-from-sound flashcards. Front: Thai word, Play + Reveal buttons,
/// pronunciation in Hindi + English. Reveal: the meaning plus up to three
/// detail buttons — Sentences, Similar (sound-alike traps), and Joint Word
/// (part-by-part breakdown and new words it can build). Swipe left/right
/// anywhere on the card to move between words.
struct FlashcardView: View {

    @State private var deck: [ThaiWord] = FlashcardView.buildDeck()

    /// The app's session algorithm ("ThaiFlow"): reviews due today come
    /// first (memory maintenance beats new input), then at most 20 unseen
    /// words (research caps effective new-word intake around 15-20/day),
    /// then already-known words as passive reinforcement, then the
    /// remaining unseen backlog.
    static func buildDeck() -> [ThaiWord] {
        let store = ProgressStore.shared
        let due = Vocabulary.all.filter { store.isDue($0.id) }.shuffled()
        let fresh = Vocabulary.all.filter { store.box(for: $0.id) == 0 }.shuffled()
        let seen = Vocabulary.all.filter { store.box(for: $0.id) > 0 && !store.isDue($0.id) }.shuffled()
        let newToday = Array(fresh.prefix(20))
        let backlog = Array(fresh.dropFirst(20))
        return due + newToday + seen + backlog
    }
    @State private var index = 0
    @State private var isFlipped = false
    @State private var showDetails = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // One "session" = today's due reviews plus the capped new words; grading
    // that many cards earns the completion screen (peak-end moment).
    @State private var sessionTarget = FlashcardView.initialSessionTarget()
    @State private var sessionReviewed = 0
    @State private var sessionCorrect = 0
    @State private var movedUp: [String] = []
    @State private var showComplete = false

    // Other practice modes open on top of the deck.
    @State private var showQuiz = false
    @State private var showToneTrainer = false
    @State private var showSpeak = false

    static func initialSessionTarget() -> Int {
        let stats = ProgressStore.shared.counts(in: Vocabulary.all)
        return max(stats.due + min(stats.fresh, 20), 5)
    }

    #if DEBUG
    // `simctl launch … -previewSessionComplete` opens the celebration screen
    // with sample stats — simulator screenshots without grading 20 cards.
    init() {
        if ProcessInfo.processInfo.arguments.contains("-previewSessionComplete") {
            _showComplete = State(initialValue: true)
            _sessionReviewed = State(initialValue: 12)
            _sessionCorrect = State(initialValue: 9)
            _movedUp = State(initialValue: ["ครู", "อาหาร"])
        }
        if ProcessInfo.processInfo.arguments.contains("-flipped") {
            _isFlipped = State(initialValue: true)
        }
        // `simctl launch … -openQuiz` / `-openTones` / `-openSpeak` jump
        // straight into a practice mode for screenshot automation.
        if ProcessInfo.processInfo.arguments.contains("-openQuiz") {
            _showQuiz = State(initialValue: true)
        }
        if ProcessInfo.processInfo.arguments.contains("-openTones") {
            _showToneTrainer = State(initialValue: true)
        }
        if ProcessInfo.processInfo.arguments.contains("-openSpeak") {
            _showSpeak = State(initialValue: true)
        }
    }
    #endif

    private var current: ThaiWord { deck[index] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                header
                modeRow
                deckProgress
                flipCard
                gradeRow
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)
            .background(
                ZStack {
                    ThaiTheme.bg
                    Circle().fill(ThaiTheme.accent200.opacity(0.55)).frame(width: 280).blur(radius: 60)
                        .offset(x: 130, y: -260)
                    Circle().fill(ThaiTheme.accent2100.opacity(0.7)).frame(width: 240).blur(radius: 70)
                        .offset(x: -140, y: 280)
                }
                .ignoresSafeArea()
            )
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showDetails) {
                WordDetailView(word: current)
                    .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $showQuiz) { QuizView() }
            .fullScreenCover(isPresented: $showToneTrainer) { ToneTrainerView() }
            .fullScreenCover(isPresented: $showSpeak) { SpeakPracticeView() }
            .fullScreenCover(isPresented: $showComplete) {
                SessionCompleteView(
                    reviewed: sessionReviewed,
                    correct: sessionCorrect,
                    movedUp: movedUp,
                    dueTomorrow: Vocabulary.all.filter {
                        let p = ProgressStore.shared
                        return p.box(for: $0.id) > 0 && !p.isDue($0.id)
                            && p.nextReview(for: $0.id).map {
                                Calendar.current.isDateInTomorrow($0) } == true
                    }.count
                ) {
                    // Next celebration after ~another day's worth of cards.
                    sessionTarget = sessionReviewed + 20
                    showComplete = false
                    advance()
                }
            }
        }
    }

    // MARK: Header — title, session line, streak pill, reshuffle

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Practice")
                    .font(ThaiTheme.display(20, bold: true))
                    .foregroundStyle(ThaiTheme.ink)
                Text("Today's deck · \(deck.count) cards")
                    .font(.system(size: 11.5))
                    .foregroundStyle(ThaiTheme.textMuted)
            }
            Spacer()
            let streak = ProgressStore.shared.currentStreak()
            if streak > 0 {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(streak)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(ThaiTheme.accent700)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ThaiTheme.accent100, in: Capsule())
            }
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    deck = Self.buildDeck()
                    index = 0
                    isFlipped = false
                }
            } label: {
                Image(systemName: "shuffle")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ThaiTheme.textMuted)
                    .frame(width: 40, height: 40)
                    .background(ThaiTheme.surfaceSunken, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
    }

    // MARK: Practice modes — the deck is home; Quiz, Tones and Speak open on top

    private var modeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                modeChip("Flip Deck", icon: "rectangle.on.rectangle.angled", selected: true) {}
                modeChip("Quiz", icon: "checklist") { showQuiz = true }
                modeChip("Tones", icon: "waveform.path.ecg") { showToneTrainer = true }
                if SpeakPracticeView.isSupported {
                    modeChip("Speak", icon: "mic.fill") { showSpeak = true }
                }
            }
        }
        .scrollClipDisabled()
    }

    private func modeChip(_ label: String, icon: String, selected: Bool = false,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(selected ? ThaiTheme.bg : ThaiTheme.accent700)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(selected ? ThaiTheme.accent : ThaiTheme.accent100, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Deck progress — one pill per session card

    private var deckProgress: some View {
        VStack(spacing: 6) {
            HStack {
                Text("TODAY'S DECK")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(ThaiTheme.textMuted)
                Spacer()
                Text("\(min(sessionReviewed, sessionTarget))/\(sessionTarget)")
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(ThaiTheme.accent700)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 12), spacing: 5) {
                ForEach(0..<sessionTarget, id: \.self) { i in
                    Capsule()
                        .fill(i < sessionReviewed ? ThaiTheme.accent
                              : i == sessionReviewed ? ThaiTheme.accent400
                              : ThaiTheme.hairline)
                        .frame(height: 7)
                        .animation(.easeInOut(duration: 0.3), value: sessionReviewed)
                }
            }
        }
    }

    // MARK: Flip card

    private var flipCard: some View {
        ZStack {
            cardFront
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(reduceMotion ? 0 : (isFlipped ? 180 : 0)),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.35)
            cardBack
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(reduceMotion ? 0 : (isFlipped ? 0 : -180)),
                                  axis: (x: 0, y: 1, z: 0), perspective: 0.35)
        }
        .frame(maxHeight: .infinity)
        .animation(reduceMotion ? .easeInOut(duration: 0.2)
                                : .spring(response: 0.45, dampingFraction: 0.8), value: isFlipped)
        .contentShape(RoundedRectangle(cornerRadius: 28))
        .onTapGesture { isFlipped.toggle() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < -50 {
                        advance()
                    } else if value.translation.width > 50 {
                        goBack()
                    }
                }
        )
    }

    private var cardFront: some View {
        VStack(spacing: 12) {
            Text(current.category.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(ThaiTheme.accent700)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(ThaiTheme.accent200, in: Capsule())

            Spacer(minLength: 0)

            if let emoji = WordExtras.emoji(for: current) {
                Text(emoji).font(.system(size: 38))
            }
            Text(current.thai)
                .font(ThaiTheme.thai(66))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(ThaiTheme.ink)

            VStack(spacing: 4) {
                Text(current.hindiPronunciation)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ThaiTheme.accent700)
                Text(current.romanization)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ThaiTheme.accent)
            }

            ToneChipsRow(word: current)

            Spacer(minLength: 0)

            Button {
                SpeechService.shared.speak(thai: current.thai, romanization: current.romanization)
            } label: {
                Label("Hear it", systemImage: "speaker.wave.2.fill")
                    .font(ThaiTheme.display(16, bold: true))
                    .foregroundStyle(ThaiTheme.bg)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(ThaiTheme.accent, in: Capsule())
                    .shadow(color: ThaiTheme.accent.opacity(0.4), radius: 6, y: 3)
            }
            .buttonStyle(.plain)

            Text("Tap card to reveal meaning")
                .font(.system(size: 11.5))
                .foregroundStyle(ThaiTheme.textFaint)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThaiTheme.surface, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: ThaiTheme.ink.opacity(0.18), radius: 20, y: 12)
    }

    private var cardBack: some View {
        VStack(spacing: 12) {
            Text(current.thai)
                .font(ThaiTheme.thai(34))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(ThaiTheme.bg)

            meaningBlock(label: "हिन्दी", labelColor: ThaiTheme.accent400,
                         meaning: current.hindiMeaning, meaningSize: 26,
                         pron: current.hindiPronunciation)
            meaningBlock(label: "ENGLISH", labelColor: ThaiTheme.accent2400,
                         meaning: current.englishMeaning, meaningSize: 24,
                         pron: current.romanization)

            if let example = WordExtras.examples(for: current).first {
                VStack(spacing: 5) {
                    Rectangle()
                        .fill(ThaiTheme.bg.opacity(0.14))
                        .frame(height: 1)
                    Text("IN A SENTENCE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(ThaiTheme.textFaint)
                    Text(example.thai)
                        .font(ThaiTheme.thai(17))
                        .foregroundStyle(ThaiTheme.bg)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                    Text(example.english)
                        .font(.system(size: 13))
                        .foregroundStyle(ThaiTheme.bg.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                showDetails = true
            } label: {
                Label("More details", systemImage: "text.book.closed")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThaiTheme.accent2400)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(ThaiTheme.bg.opacity(0.08), in: Capsule())
                    .overlay(Capsule().stroke(ThaiTheme.bg.opacity(0.16), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThaiTheme.inkDeep, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.4), radius: 20, y: 12)
    }

    private func meaningBlock(label: String, labelColor: Color,
                              meaning: String, meaningSize: CGFloat, pron: String) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(labelColor)
            Text(meaning)
                .font(.system(size: meaningSize, weight: .semibold))
                .foregroundStyle(ThaiTheme.bg)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
            Text(pron)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: 0xB3C1D4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(ThaiTheme.bg.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(ThaiTheme.bg.opacity(0.16), lineWidth: 1))
    }

    // MARK: Grade row

    private var gradeRow: some View {
        HStack(spacing: 12) {
            Button {
                grade(false)
            } label: {
                Label("Again", systemImage: "arrow.counterclockwise")
                    .font(ThaiTheme.display(16, bold: true))
                    .foregroundStyle(ThaiTheme.accent700)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(ThaiTheme.accent100, in: Capsule())
                    .overlay(Capsule().stroke(ThaiTheme.accent300, lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            Button {
                grade(true)
            } label: {
                Label("Got it", systemImage: "checkmark")
                    .font(ThaiTheme.display(16, bold: true))
                    .foregroundStyle(ThaiTheme.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(ThaiTheme.accent2, in: Capsule())
                    .shadow(color: ThaiTheme.accent2.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    private func jump(to word: ThaiWord) {
        guard let target = deck.firstIndex(where: { $0.id == word.id }) else { return }
        showDetails = false
        withAnimation(.spring(duration: 0.3)) {
            index = target
            isFlipped = true
        }
    }

    /// Records the self-assessment (the "testing effect": retrieval attempts
    /// strengthen memory) and moves on. Missed words come back tomorrow;
    /// known words come back at expanding intervals.
    private func grade(_ known: Bool) {
        let before = ProgressStore.shared.box(for: current.id)
        ProgressStore.shared.record(id: current.id, known: known)
        sessionReviewed += 1
        if known {
            sessionCorrect += 1
            if ProgressStore.shared.box(for: current.id) > before {
                movedUp.append(current.thai)
            }
        }
        if sessionReviewed >= sessionTarget {
            showComplete = true
        } else {
            advance()
        }
    }

    private func advance() {
        withAnimation(.spring(duration: 0.3)) {
            isFlipped = false
            index = (index + 1) % deck.count
        }
    }

    private func goBack() {
        withAnimation(.spring(duration: 0.3)) {
            isFlipped = false
            index = (index - 1 + deck.count) % deck.count
        }
    }

    // MARK: Color-coded compound breakdown

    struct CompoundPart {
        let thai: String
        let roman: String
        let english: String
        let hindi: String
    }

    /// Parses notes in the house format
    /// "X (rom) meaning / अर्थ + Y (rom) meaning / अर्थ → result / अर्थ".
    /// Returns nil for free-form notes, which render as plain text.
    static func parseCompound(_ note: String) -> (parts: [CompoundPart], result: String)? {
        let halves = note.components(separatedBy: "→")
        guard halves.count == 2 else { return nil }
        let partStrings = halves[0].components(separatedBy: " + ")
        guard partStrings.count >= 2, partStrings.count <= 4 else { return nil }
        var parts: [CompoundPart] = []
        for piece in partStrings {
            guard let open = piece.firstIndex(of: "("), let close = piece.firstIndex(of: ")"), open < close else { return nil }
            let thai = String(piece[..<open]).trimmingCharacters(in: .whitespaces)
            let roman = String(piece[piece.index(after: open)..<close])
            let meanings = String(piece[piece.index(after: close)...]).components(separatedBy: "/")
            guard !thai.isEmpty, meanings.count >= 2 else { return nil }
            parts.append(CompoundPart(
                thai: thai,
                roman: roman,
                english: meanings[0].trimmingCharacters(in: .whitespaces),
                hindi: meanings[1].trimmingCharacters(in: .whitespaces)))
        }
        return (parts, halves[1].trimmingCharacters(in: .whitespaces))
    }

}

// MARK: - Session complete — the peak-end moment

/// Shown after finishing a session (due reviews + today's new words).
/// The celebration itself teaches: เก่งมาก is a dictionary phrase.
struct SessionCompleteView: View {
    let reviewed: Int
    let correct: Int
    let movedUp: [String]
    let dueTomorrow: Int
    let onDone: () -> Void

    @State private var burst = false

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            Text("🎉")
                .font(.system(size: 56))
                .scaleEffect(burst ? 1 : 0.3)
                .animation(.spring(duration: 0.5, bounce: 0.5), value: burst)

            Text("เก่งมาก!")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(ThaiTheme.ink)
            Text("kèng mâak — great job!")
                .font(.headline)
                .foregroundStyle(ThaiTheme.indigo)
            Text("You showed up today. That's the whole game.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                stat("\(reviewed)", "Reviewed", ThaiTheme.gold)
                stat("\(correct)", "Got it", ThaiTheme.jade)
                stat("\(ProgressStore.shared.currentStreak())", "Day streak", ThaiTheme.orchid)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .thaiGlass(cornerRadius: 20)
            .padding(.horizontal)

            if !movedUp.isEmpty {
                Text("↑ \(movedUp.count) word\(movedUp.count == 1 ? "" : "s") moved up a box — \(movedUp.prefix(3).joined(separator: " · ")) \(movedUp.count > 3 ? "…" : "")almost yours.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(ThaiTheme.jade)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            if dueTomorrow > 0 {
                Text("\(dueTomorrow) word\(dueTomorrow == 1 ? "" : "s") come due tomorrow — see you then 🌅")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ThaiTheme.deepIndigo)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .thaiGlass(cornerRadius: 16)
            }

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(ThaiTheme.indigo.opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: ThaiTheme.indigo.opacity(0.35), radius: 8, y: 4)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .glassWashBackground()
        .onAppear { burst = true }
    }

    private func stat(_ number: String, _ caption: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(number)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(caption.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    FlashcardView()
}
