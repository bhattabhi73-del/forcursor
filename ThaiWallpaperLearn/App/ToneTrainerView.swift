import SwiftUI
import UIKit

// MARK: - Tone contour glyph

/// The five Thai tone shapes drawn as tiny pitch curves — no assets, just
/// a stroked path. Matches the arrows used by `ToneChipsRow`, but shows the
/// actual contour a learner should hear.
struct ToneContourShape: Shape {
    let tone: ThaiTone

    func path(in rect: CGRect) -> Path {
        var p = Path()
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        switch tone {
        case .mid:      // flat, middle of the range
            p.move(to: pt(0.06, 0.5))
            p.addLine(to: pt(0.94, 0.5))
        case .low:      // flat-low with a slight dip
            p.move(to: pt(0.06, 0.68))
            p.addQuadCurve(to: pt(0.94, 0.86), control: pt(0.5, 0.7))
        case .falling:  // rises briefly, then drops
            p.move(to: pt(0.06, 0.4))
            p.addQuadCurve(to: pt(0.94, 0.92), control: pt(0.55, 0.05))
        case .high:     // high and climbing
            p.move(to: pt(0.06, 0.4))
            p.addQuadCurve(to: pt(0.94, 0.12), control: pt(0.55, 0.42))
        case .rising:   // dips, then sweeps up
            p.move(to: pt(0.06, 0.85))
            p.addQuadCurve(to: pt(0.94, 0.1), control: pt(0.5, 1.0))
        }
        return p
    }
}

// MARK: - Tone trainer

/// Pure ear training: a monosyllabic word plays and the learner names its
/// tone. Only single-syllable words qualify — one syllable, one unambiguous
/// tone — and the reveal shows script, romanization, Devanagari and meaning
/// so every question doubles as a vocab rep.
struct ToneTrainerView: View {
    @Environment(\.dismiss) private var dismiss

    static let roundLength = 10

    /// All five tones in teaching order, with Hindi names for the tone row.
    static let toneChoices: [(tone: ThaiTone, hindi: String)] = [
        (.mid, "सम"), (.low, "नीचा"), (.falling, "गिरता"), (.high, "ऊँचा"), (.rising, "चढ़ता"),
    ]

    /// Ten distinct monosyllables, learning words first.
    static func buildRound() -> [ThaiWord] {
        let store = ProgressStore.shared
        let mono = Vocabulary.all.filter {
            !$0.romanization.contains("-") && !$0.romanization.contains(" ")
        }
        let seen = mono.filter { store.box(for: $0.id) > 0 }.shuffled()
        let fresh = mono.filter { store.box(for: $0.id) == 0 }.shuffled()
        return Array((seen + fresh).prefix(roundLength))
    }

    @State private var round = ToneTrainerView.buildRound()
    @State private var index = 0
    @State private var chosen: ThaiTone?
    @State private var score = 0
    @State private var missed: [ThaiWord] = []
    @State private var showSummary = false
    @State private var detailWord: ThaiWord?

    private var word: ThaiWord { round[index] }
    private var answered: Bool { chosen != nil }

    /// The tone the romanization marks encode — the answer key.
    private var correctTone: ThaiTone {
        ToneAnalyzer.syllables(of: word.romanization).first?.tone ?? .mid
    }

    private func toneColor(_ tone: ThaiTone) -> Color {
        switch tone {
        case .mid: return ThaiTheme.toneMid
        case .low: return ThaiTheme.toneLow
        case .falling: return ThaiTheme.toneFalling
        case .high: return ThaiTheme.toneHigh
        case .rising: return ThaiTheme.toneRising
        }
    }

    var body: some View {
        Group {
            if showSummary {
                PracticeRoundSummary(
                    title: "Tones done!",
                    score: score,
                    total: round.count,
                    missed: missed,
                    onWordTap: { detailWord = $0 },
                    onPlayAgain: restart,
                    onDone: { dismiss() }
                )
            } else {
                trainerBody
            }
        }
        .background(ThaiTheme.bgAlt.ignoresSafeArea())
        .sheet(item: $detailWord) { word in
            WordDetailView(word: word)
                .presentationDetents([.medium, .large])
        }
        .onAppear { autoPlay() }
    }

    private var trainerBody: some View {
        VStack(spacing: 14) {
            header
            listenCard
            toneOptions
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ThaiTheme.textMuted)
                    .frame(width: 36, height: 36)
                    .background(ThaiTheme.surfaceSunken, in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text("Tone Trainer")
                    .font(ThaiTheme.display(20, bold: true))
                    .foregroundStyle(ThaiTheme.ink)
                Text("Word \(index + 1) of \(round.count) · आवाज़ की चाल")
                    .font(.system(size: 11.5))
                    .foregroundStyle(ThaiTheme.textMuted)
            }
            Spacer()
            Text("\(score)")
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(ThaiTheme.accent2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(ThaiTheme.accent2100, in: Capsule())
        }
        .padding(.top, 10)
    }

    // MARK: Listen card — replay before the answer, full reveal after

    private var listenCard: some View {
        VStack(spacing: 10) {
            if answered {
                Text(word.thai)
                    .font(ThaiTheme.thai(44))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(ThaiTheme.ink)
                Text("\(word.hindiPronunciation) · \(word.romanization)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ThaiTheme.orchid)
                Text("\(word.hindiMeaning) · \(word.englishMeaning)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ThaiTheme.ink)
                Button {
                    play()
                } label: {
                    Label("Hear it again", systemImage: "speaker.wave.2.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(ThaiTheme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(ThaiTheme.accent100, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Text("LISTEN — WHICH TONE IS IT?")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(ThaiTheme.textMuted)
                Button {
                    play()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(ThaiTheme.bg)
                        .frame(width: 84, height: 84)
                        .background(ThaiTheme.accent.gradient, in: Circle())
                        .shadow(color: ThaiTheme.accent.opacity(0.4), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                Text("Tap to replay as often as you like")
                    .font(.system(size: 11.5))
                    .foregroundStyle(ThaiTheme.textFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(ThaiTheme.surface, in: RoundedRectangle(cornerRadius: ThaiTheme.radiusCard))
        .shadow(color: ThaiTheme.ink.opacity(0.08), radius: 10, y: 5)
    }

    // MARK: Tone options — contour glyph + EN + HI names

    private var toneOptions: some View {
        VStack(spacing: 8) {
            ForEach(Self.toneChoices, id: \.tone.englishName) { choice in
                toneRow(choice.tone, hindi: choice.hindi)
            }
        }
    }

    private func toneRow(_ tone: ThaiTone, hindi: String) -> some View {
        let isCorrect = answered && tone == correctTone
        let isWrongPick = answered && tone == chosen && tone != correctTone
        let bright = isCorrect || isWrongPick

        return Button {
            choose(tone)
        } label: {
            HStack(spacing: 14) {
                ToneContourShape(tone: tone)
                    .stroke(bright ? .white : toneColor(tone),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 46, height: 26)
                Text(tone.englishName.capitalized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(bright ? .white : ThaiTheme.ink)
                Text(hindi)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(bright ? .white.opacity(0.85) : ThaiTheme.orchid)
                Spacer()
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.white)
                } else if isWrongPick {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                isCorrect ? ThaiTheme.accent2 : isWrongPick ? ThaiTheme.danger : ThaiTheme.surface,
                in: RoundedRectangle(cornerRadius: ThaiTheme.radiusControl)
            )
            .overlay(RoundedRectangle(cornerRadius: ThaiTheme.radiusControl)
                .stroke(answered ? .clear : ThaiTheme.hairline, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(answered)
        .animation(.easeInOut(duration: 0.2), value: chosen)
    }

    // MARK: Footer

    @ViewBuilder private var footer: some View {
        if answered {
            PrimaryButton(
                title: index + 1 < round.count ? "Next" : "See results",
                icon: index + 1 < round.count ? "arrow.right" : "flag.checkered"
            ) {
                advance()
            }
        } else {
            Text("Hint: the curve is the pitch of your voice")
                .font(.system(size: 11.5))
                .foregroundStyle(ThaiTheme.textFaint)
                .padding(.bottom, 14)
        }
    }

    // MARK: Round mechanics

    private func choose(_ tone: ThaiTone) {
        guard !answered else { return }
        chosen = tone
        let correct = tone == correctTone
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
        if correct {
            score += 1
        } else {
            missed.append(word)
        }
        // Hear it once more with the answer on screen.
        play()
    }

    private func advance() {
        if index + 1 < round.count {
            withAnimation(.spring(duration: 0.3)) {
                index += 1
                chosen = nil
            }
            autoPlay()
        } else {
            showSummary = true
        }
    }

    private func restart() {
        round = Self.buildRound()
        index = 0
        chosen = nil
        score = 0
        missed = []
        showSummary = false
        autoPlay()
    }

    private func autoPlay() {
        // Slight delay so the speech doesn't race the presentation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { play() }
    }

    private func play() {
        SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
    }
}

#Preview {
    ToneTrainerView()
}
