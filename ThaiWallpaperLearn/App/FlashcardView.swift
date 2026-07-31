import SwiftUI

/// Guess-from-sound flashcards. Front: Thai word, Play + Reveal buttons,
/// pronunciation in Hindi + English. Reveal: the meaning plus up to three
/// detail buttons — Sentences, Similar (sound-alike traps), and Joint Word
/// (part-by-part breakdown and new words it can build). Swipe left/right
/// anywhere on the card to move between words.
struct FlashcardView: View {
    private enum Detail { case sentences, similar, joint, forms }

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
    @State private var revealed = false
    @State private var detail: Detail?

    private var current: ThaiWord { deck[index] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(ThaiTheme.cream)
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(ThaiTheme.gold.opacity(0.3), lineWidth: 1))
                        .shadow(color: ThaiTheme.ink.opacity(0.12), radius: 16, y: 8)

                    if revealed {
                        revealSide.transition(.opacity)
                    } else {
                        frontSide.transition(.opacity)
                    }
                }
                .padding(.horizontal)
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

                HStack {
                    Button {
                        goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(ThaiTheme.indigo)
                            .frame(width: 54, height: 54)
                            .background(ThaiTheme.cream, in: Circle())
                            .overlay(Circle().stroke(ThaiTheme.gold.opacity(0.4), lineWidth: 1))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(index + 1) / \(deck.count)")
                            .font(.headline)
                            .foregroundStyle(ThaiTheme.ink)
                        let stats = ProgressStore.shared.counts(in: Vocabulary.all)
                        Text("\(stats.due) due · \(stats.fresh) new · \(stats.known) known")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        advance()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(ThaiTheme.indigo.gradient, in: Circle())
                            .shadow(color: ThaiTheme.indigo.opacity(0.35), radius: 6, y: 3)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 8)
            }
            .navigationTitle("Practice")
            .background(ThaiTheme.sand)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            deck = Self.buildDeck()
                            index = 0
                            revealed = false
                            detail = nil
                        }
                    } label: {
                        Image(systemName: "shuffle")
                            .foregroundStyle(ThaiTheme.indigo)
                    }
                }
            }
        }
    }

    // MARK: Front — guess the meaning from sound

    private var frontSide: some View {
        VStack(spacing: 14) {
            Spacer()
            if let emoji = WordExtras.emoji(for: current) {
                Text(emoji).font(.system(size: 44))
            }
            Text(current.thai)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(ThaiTheme.ink)

            HStack(spacing: 12) {
                capsuleButton("Play", icon: "speaker.wave.2.fill", fill: ThaiTheme.indigo) {
                    SpeechService.shared.speak(thai: current.thai, romanization: current.romanization)
                }
                capsuleButton("Reveal", icon: "eye.fill", fill: ThaiTheme.gold) {
                    withAnimation(.spring(duration: 0.35)) { revealed = true }
                }
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("🇮🇳").font(.caption)
                    Text(current.hindiPronunciation).font(.title3.weight(.medium))
                        .foregroundStyle(ThaiTheme.orchid)
                }
                HStack(spacing: 8) {
                    Text("🔤").font(.caption)
                    Text(current.romanization).font(.title3.weight(.medium))
                        .foregroundStyle(ThaiTheme.indigo)
                }
            }

            toneRow(for: current)

            Text("Can you guess the meaning?")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(20)
    }

    // MARK: Tone chips — one colored capsule per syllable

    private func toneColor(_ tone: ThaiTone) -> Color {
        switch tone {
        case .mid: return ThaiTheme.stone
        case .low: return Color(red: 0.290, green: 0.435, blue: 0.831)
        case .falling: return Color(red: 0.820, green: 0.302, blue: 0.302)
        case .high: return Color(red: 0.902, green: 0.541, blue: 0.180)
        case .rising: return Color(red: 0.243, green: 0.647, blue: 0.424)
        }
    }

    private func toneIcon(_ tone: ThaiTone) -> String {
        switch tone {
        case .mid: return "arrow.right"
        case .low: return "arrow.down.right"
        case .falling: return "arrow.down"
        case .high: return "arrow.up"
        case .rising: return "arrow.up.right"
        }
    }

    private func toneRow(for word: ThaiWord) -> some View {
        let syllables = ToneAnalyzer.syllables(of: word.romanization)
        return VStack(spacing: 4) {
            HStack(spacing: 6) {
                ForEach(Array(syllables.enumerated()), id: \.offset) { _, syllable in
                    HStack(spacing: 4) {
                        Text(syllable.text)
                            .font(.caption.weight(.bold))
                        Image(systemName: toneIcon(syllable.tone))
                            .font(.system(size: 9, weight: .bold))
                        Text(syllable.tone.englishName.capitalized)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(.white)
                    .background(toneColor(syllable.tone).gradient, in: Capsule())
                }
            }
            Text("TONE — आवाज़ की चाल")
                .font(.system(size: 8, weight: .semibold))
                .tracking(1)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: Reveal — meaning + detail buttons

    private var revealSide: some View {
        let sentences = WordExtras.examples(for: current)
        let similar = WordExtras.similarSounds(for: current)
        let compoundNote = WordExtras.compoundNote(for: current)
        let related = Vocabulary.related(to: current)
        let forms = WordExtras.forms(for: current)
        let hasJoint = compoundNote != nil || !related.isEmpty

        return ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(current.thai)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .foregroundStyle(ThaiTheme.ink)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.35)) {
                                revealed = false
                                detail = nil
                            }
                        }
                    Text("\(current.hindiPronunciation) · \(current.romanization)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    toneRow(for: current)
                    capsuleButton("Play", icon: "speaker.wave.2.fill") {
                        SpeechService.shared.speak(thai: current.thai, romanization: current.romanization)
                    }
                }

                VStack(spacing: 6) {
                    sectionLabel("MEANING")
                    Text("🇮🇳 \(current.hindiMeaning)").font(.title3)
                    Text("🇬🇧 \(current.englishMeaning)").font(.title3)
                }

                HStack(spacing: 12) {
                    capsuleButton("Again", icon: "arrow.counterclockwise", fill: Color(red: 0.820, green: 0.302, blue: 0.302)) {
                        grade(false)
                    }
                    capsuleButton("Got it", icon: "checkmark", fill: Color(red: 0.243, green: 0.647, blue: 0.424)) {
                        grade(true)
                    }
                }

                if !sentences.isEmpty || !similar.isEmpty || hasJoint || !forms.isEmpty {
                    HStack(spacing: 8) {
                        if !sentences.isEmpty {
                            detailButton("Sentences", icon: "text.quote", target: .sentences)
                        }
                        if !forms.isEmpty {
                            detailButton("Word Forms", icon: "arrow.triangle.branch", target: .forms)
                        }
                        if !similar.isEmpty {
                            detailButton("Similar", icon: "waveform", target: .similar)
                        }
                        if hasJoint {
                            detailButton("Joint Word", icon: "puzzlepiece.extension", target: .joint)
                        }
                    }
                }

                switch detail {
                case .sentences:
                    sentencesSection(sentences)
                case .forms:
                    VStack(spacing: 10) {
                        sectionLabel("WORD FORMS")
                        ForEach(Array(forms.enumerated()), id: \.offset) { _, form in
                            VStack(spacing: 3) {
                                HStack(spacing: 8) {
                                    Text(form.thai).font(.headline)
                                    Button {
                                        SpeechService.shared.speak(thai: form.thai, romanization: form.romanization)
                                    } label: {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .font(.caption2)
                                            .padding(5)
                                    }
                                    .background(Color.accentColor.opacity(0.15), in: Circle())
                                }
                                Text(form.romanization)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("🇬🇧 \(form.english) · 🇮🇳 \(form.hindi)")
                                    .font(.caption)
                                if !form.note.isEmpty {
                                    Text(form.note)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(ThaiTheme.sand, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                case .similar:
                    VStack(spacing: 8) {
                        sectionLabel("SOUNDS SIMILAR, DIFFERENT MEANING")
                        wordChips(similar)
                    }
                case .joint:
                    VStack(spacing: 12) {
                        if let compoundNote {
                            VStack(spacing: 8) {
                                sectionLabel("BUILT FROM THESE WORDS")
                                if let parsed = Self.parseCompound(compoundNote) {
                                    colorCodedJoint(parsed.parts, result: parsed.result)
                                } else {
                                    Text(compoundNote)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        if !related.isEmpty {
                            VStack(spacing: 8) {
                                sectionLabel("MAKES / APPEARS IN THESE WORDS")
                                wordChips(related)
                            }
                        }
                    }
                case nil:
                    EmptyView()
                }

                Text(current.category.uppercased())
                    .font(.caption2)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)

                Text("Tap the Thai word to hide the answer")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
    }

    private func detailButton(_ title: String, icon: String, target: Detail) -> some View {
        let isActive = detail == target
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                detail = isActive ? nil : target
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.subheadline)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isActive ? .white : ThaiTheme.ink)
            .background(
                isActive ? ThaiTheme.indigo : ThaiTheme.parchment,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
    }

    private func sentencesSection(_ sentences: [WordExample]) -> some View {
        VStack(spacing: 14) {
            sectionLabel("IN SENTENCES")
            Text("Tap an underlined word for its details")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach(Array(sentences.enumerated()), id: \.offset) { _, example in
                VStack(spacing: 4) {
                    Text(linkedSentence(example.thai))
                        .font(.headline)
                    Text(example.romanization)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("🇬🇧 \(example.english)").font(.caption)
                    Text("🇮🇳 \(example.hindi)").font(.caption)
                    Button {
                        SpeechService.shared.speak(thai: example.thai, romanization: example.romanization)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .padding(6)
                    }
                    .background(Color.accentColor.opacity(0.15), in: Circle())
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(ThaiTheme.sand, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "thaiword", let id = Int(url.host() ?? ""),
               let word = Vocabulary.all.first(where: { $0.id == id }) {
                jump(to: word)
                return .handled
            }
            return .systemAction
        })
    }

    /// Splits a Thai sentence into vocabulary words (tappable) and glue text,
    /// using greedy longest-match against the dictionary.
    private func sentenceSegments(_ thai: String) -> [(text: String, word: ThaiWord?)] {
        let vocab = Vocabulary.all.sorted { $0.thai.count > $1.thai.count }
        var result: [(String, ThaiWord?)] = []
        var rest = Substring(thai)
        var plain = ""
        while let first = rest.first {
            if let match = vocab.first(where: { rest.hasPrefix($0.thai) }) {
                if !plain.isEmpty { result.append((plain, nil)); plain = "" }
                result.append((match.thai, match))
                rest = rest.dropFirst(match.thai.count)
            } else {
                plain.append(first)
                rest = rest.dropFirst()
            }
        }
        if !plain.isEmpty { result.append((plain, nil)) }
        return result
    }

    private func linkedSentence(_ thai: String) -> AttributedString {
        var result = AttributedString()
        for segment in sentenceSegments(thai) {
            var piece = AttributedString(segment.text)
            if let word = segment.word, word.id != current.id {
                piece.link = URL(string: "thaiword://\(word.id)")
                piece.foregroundColor = ThaiTheme.indigo
                piece.underlineStyle = .single
            } else {
                piece.foregroundColor = ThaiTheme.ink
            }
            result += piece
        }
        return result
    }

    private func wordChips(_ words: [ThaiWord]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
            ForEach(words) { word in
                Button {
                    jump(to: word)
                } label: {
                    VStack(spacing: 2) {
                        Text(word.thai).font(.headline)
                        Text("\(word.romanization) · \(word.englishMeaning)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .background(ThaiTheme.parchment, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func capsuleButton(_ title: String, icon: String, fill: Color = ThaiTheme.indigo, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background(fill, in: Capsule())
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(ThaiTheme.gold)
    }

    private func jump(to word: ThaiWord) {
        guard let target = deck.firstIndex(where: { $0.id == word.id }) else { return }
        withAnimation(.spring(duration: 0.3)) {
            index = target
            revealed = true
            detail = nil
        }
    }

    /// Records the self-assessment (the "testing effect": retrieval attempts
    /// strengthen memory) and moves on. Missed words come back tomorrow;
    /// known words come back at expanding intervals.
    private func grade(_ known: Bool) {
        ProgressStore.shared.record(id: current.id, known: known)
        advance()
    }

    private func advance() {
        withAnimation(.spring(duration: 0.3)) {
            revealed = false
            detail = nil
            index = (index + 1) % deck.count
        }
    }

    private func goBack() {
        withAnimation(.spring(duration: 0.3)) {
            revealed = false
            detail = nil
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

    private static let jointPalette: [Color] = [
        ThaiTheme.indigo,
        Color(red: 0.243, green: 0.647, blue: 0.424),
        ThaiTheme.orchid,
        ThaiTheme.gold,
    ]

    private func colorCodedJoint(_ parts: [CompoundPart], result: String) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                ForEach(Array(parts.enumerated()), id: \.offset) { i, part in
                    if i > 0 {
                        Text("+")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }
                    VStack(spacing: 2) {
                        Text(part.thai)
                            .font(.title2.weight(.bold))
                        Text(part.roman)
                            .font(.caption)
                        Text(part.english)
                            .font(.caption.weight(.medium))
                        Text(part.hindi)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Self.jointPalette[i % Self.jointPalette.count])
                    .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 6) {
                Text("=")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(result)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThaiTheme.ink)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(12)
        .background(ThaiTheme.sand, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    FlashcardView()
}
