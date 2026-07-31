import SwiftUI

/// Guess-from-sound flashcards. Front: Thai word, Play + Reveal buttons,
/// pronunciation in Hindi + English. Reveal: the meaning plus up to three
/// detail buttons — Sentences, Similar (sound-alike traps), and Joint Word
/// (part-by-part breakdown and new words it can build). Swipe left/right
/// anywhere on the card to move between words.
struct FlashcardView: View {
    private enum Detail { case sentences, similar, joint, forms }

    @State private var deck: [ThaiWord] = Vocabulary.all.shuffled()
    @State private var index = 0
    @State private var revealed = false
    @State private var detail: Detail?

    private var current: ThaiWord { deck[index] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

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

                HStack(spacing: 12) {
                    Text("\(index + 1) / \(deck.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("· swipe ← → to change word")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 16) {
                    Button {
                        goBack()
                    } label: {
                        Label("Previous", systemImage: "arrow.left")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))

                    Button {
                        advance()
                    } label: {
                        Label("Next", systemImage: "arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))

                    Button {
                        deck.shuffle()
                        index = 0
                        revealed = false
                        detail = nil
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.headline)
                            .padding()
                    }
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .navigationTitle("Practice")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: Front — guess the meaning from sound

    private var frontSide: some View {
        VStack(spacing: 14) {
            Spacer()
            Text(current.thai)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            HStack(spacing: 12) {
                capsuleButton("Play", icon: "speaker.wave.2.fill") {
                    SpeechService.shared.speak(thai: current.thai, romanization: current.romanization)
                }
                capsuleButton("Reveal", icon: "eye.fill") {
                    withAnimation(.spring(duration: 0.35)) { revealed = true }
                }
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("🇮🇳").font(.caption)
                    Text(current.hindiPronunciation).font(.title3.weight(.medium))
                }
                HStack(spacing: 8) {
                    Text("🔤").font(.caption)
                    Text(current.romanization).font(.title3.weight(.medium))
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
        case .mid: return .gray
        case .low: return .blue
        case .falling: return .red
        case .high: return .orange
        case .rising: return .green
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
                            .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
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
                            VStack(spacing: 6) {
                                sectionLabel("BUILT FROM THESE WORDS")
                                Text(compoundNote)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
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
            .background(
                isActive ? Color.accentColor.opacity(0.3) : Color.accentColor.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
    }

    private func sentencesSection(_ sentences: [WordExample]) -> some View {
        VStack(spacing: 14) {
            sectionLabel("IN SENTENCES")
            ForEach(Array(sentences.enumerated()), id: \.offset) { _, example in
                VStack(spacing: 4) {
                    Text(example.thai)
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
                .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
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
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func capsuleButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background(Color.accentColor.opacity(0.15), in: Capsule())
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }

    private func jump(to word: ThaiWord) {
        guard let target = deck.firstIndex(where: { $0.id == word.id }) else { return }
        withAnimation(.spring(duration: 0.3)) {
            index = target
            revealed = true
            detail = nil
        }
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
}

#Preview {
    FlashcardView()
}
