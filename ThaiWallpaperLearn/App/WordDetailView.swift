import SwiftUI

// MARK: - Tone chips (shared by Practice card and word detail)

struct ToneChipsRow: View {
    let word: ThaiWord

    private func toneColor(_ tone: ThaiTone) -> Color {
        switch tone {
        case .mid: return ThaiTheme.toneMid
        case .low: return ThaiTheme.toneLow
        case .falling: return ThaiTheme.toneFalling
        case .high: return ThaiTheme.toneHigh
        case .rising: return ThaiTheme.toneRising
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

    var body: some View {
        let syllables = ToneAnalyzer.syllables(of: word.romanization)
        VStack(spacing: 4) {
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
}

// MARK: - Word detail — one word's full story

/// Everything the app knows about one word: pronunciation, tones, meanings,
/// example sentences (with tappable word links), forms, sound-alikes, and
/// compound breakdowns. Tapping a linked word swaps it in place, so it works
/// the same from Practice, Browse, or a widget deep link.
struct WordDetailView: View {
    @State var word: ThaiWord
    @State private var detail: Detail?

    enum Detail { case sentences, similar, joint, forms }

    var body: some View {
        let sentences = WordExtras.examples(for: word)
        let similar = WordExtras.similarSounds(for: word)
        let compoundNote = WordExtras.compoundNote(for: word)
        let related = Vocabulary.related(to: word)
        let forms = WordExtras.forms(for: word)
        let hasJoint = compoundNote != nil || !related.isEmpty

        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(word.thai)
                        .font(ThaiTheme.thai(40))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .foregroundStyle(ThaiTheme.ink)
                    Text("\(word.hindiPronunciation) · \(word.romanization)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    ToneChipsRow(word: word)
                    Button {
                        SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
                    } label: {
                        Label("Play", systemImage: "speaker.wave.2.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .background(ThaiTheme.accent, in: Capsule())
                    .buttonStyle(.plain)
                }

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        LanguageTag(kind: .hi)
                        Text(word.hindiMeaning)
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(ThaiTheme.ink)
                    }
                    HStack(spacing: 8) {
                        LanguageTag(kind: .en)
                        Text(word.englishMeaning)
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(ThaiTheme.ink)
                    }
                }
                .multilineTextAlignment(.center)

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
                    formsSection(forms)
                case .similar:
                    VStack(spacing: 8) {
                        sectionLabel("SOUNDS SIMILAR, DIFFERENT MEANING")
                        wordChips(similar)
                    }
                case .joint:
                    jointSection(compoundNote: compoundNote, related: related)
                case nil:
                    EmptyView()
                }

                Text(word.category.uppercased())
                    .font(.caption2)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .background(ThaiTheme.bgAlt)
        .onAppear { ProgressStore.shared.recordViewed(id: word.id) }
        .onChange(of: word.id) { ProgressStore.shared.recordViewed(id: word.id) }
    }

    private func show(_ target: ThaiWord) {
        withAnimation(.spring(duration: 0.3)) {
            word = target
            detail = nil
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
                isActive ? ThaiTheme.accent : ThaiTheme.surfaceSunken,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(ThaiTheme.accent2)
    }

    // MARK: Sentences with tappable word links

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
                    .background(ThaiTheme.accent.opacity(0.15), in: Circle())
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(ThaiTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            if url.scheme == "thaiword", let id = Int(url.host() ?? ""),
               let target = Vocabulary.all.first(where: { $0.id == id }) {
                show(target)
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
            if let linked = segment.word, linked.id != word.id {
                piece.link = URL(string: "thaiword://\(linked.id)")
                piece.foregroundColor = ThaiTheme.accent
                piece.underlineStyle = .single
            } else {
                piece.foregroundColor = ThaiTheme.ink
            }
            result += piece
        }
        return result
    }

    // MARK: Forms / similar / joint

    private func formsSection(_ forms: [WordForm]) -> some View {
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
                        .background(ThaiTheme.accent.opacity(0.15), in: Circle())
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
                .background(ThaiTheme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func jointSection(compoundNote: String?, related: [ThaiWord]) -> some View {
        VStack(spacing: 12) {
            if let compoundNote {
                VStack(spacing: 8) {
                    sectionLabel("BUILT FROM THESE WORDS")
                    if let parsed = FlashcardView.parseCompound(compoundNote) {
                        JointBreakdownView(parts: parsed.parts, result: parsed.result)
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
    }

    private func wordChips(_ words: [ThaiWord]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
            ForEach(words) { chipWord in
                Button {
                    show(chipWord)
                } label: {
                    VStack(spacing: 2) {
                        Text(chipWord.thai).font(.headline)
                        Text("\(chipWord.romanization) · \(chipWord.englishMeaning)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .background(ThaiTheme.surfaceSunken, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Color-coded compound breakdown (shared)

struct JointBreakdownView: View {
    let parts: [FlashcardView.CompoundPart]
    let result: String

    private static let palette: [Color] = [
        ThaiTheme.accent,
        ThaiTheme.accent2,
        ThaiTheme.accent700,
        ThaiTheme.accent400,
    ]

    var body: some View {
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
                    .foregroundStyle(Self.palette[i % Self.palette.count])
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
        .background(ThaiTheme.surfaceSunken, in: RoundedRectangle(cornerRadius: 14))
    }
}
