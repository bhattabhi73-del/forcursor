import SwiftUI
import UIKit

// MARK: - Quiz round model

/// One multiple-choice question. Listening is the app's major focus, so
/// half of every round is guess-from-sound; the rest split between
/// script→meaning and meaning→script.
struct QuizQuestion {
    enum Kind {
        case thaiToMeaning   // Thai script shown → pick the English meaning
        case meaningToThai   // meaning shown → pick the Thai word
        case listen          // audio only → pick the word you heard
    }

    let word: ThaiWord
    let kind: Kind
    let options: [ThaiWord]  // four, shuffled, includes `word`
}

enum QuizRound {
    static let length = 10

    /// Ten distinct target words: ones already in learning first (the quiz
    /// is a retrieval workout, and retrieval needs prior exposure), topped
    /// up with random unseen words when the learner is new.
    static func build() -> [QuizQuestion] {
        let store = ProgressStore.shared
        let seen = Vocabulary.all.filter { store.box(for: $0.id) > 0 }.shuffled()
        let fresh = Vocabulary.all.filter { store.box(for: $0.id) == 0 }.shuffled()
        let targets = Array((seen + fresh).prefix(length))

        // ~50% listen questions, remainder alternating between the two
        // reading directions, dealt to random positions.
        var kinds: [QuizQuestion.Kind] = Array(repeating: .listen, count: (targets.count + 1) / 2)
        while kinds.count < targets.count {
            kinds.append(kinds.count % 2 == 0 ? .thaiToMeaning : .meaningToThai)
        }
        kinds.shuffle()

        return zip(targets, kinds).map { word, kind in
            QuizQuestion(word: word, kind: kind, options: options(for: word))
        }
    }

    /// Three distractors from the same category when possible, topped up at
    /// random. Never the word itself, and never a duplicate meaning — two
    /// rows that both say "rice" would make the answer ambiguous.
    static func options(for word: ThaiWord) -> [ThaiWord] {
        var picks: [ThaiWord] = []
        var meanings: Set<String> = [word.englishMeaning.lowercased()]
        let candidates = Vocabulary.all.filter { $0.category == word.category }.shuffled()
            + Vocabulary.all.shuffled()
        for candidate in candidates where picks.count < 3 {
            guard candidate.id != word.id,
                  !meanings.contains(candidate.englishMeaning.lowercased()),
                  !picks.contains(where: { $0.id == candidate.id }) else { continue }
            picks.append(candidate)
            meanings.insert(candidate.englishMeaning.lowercased())
        }
        return (picks + [word]).shuffled()
    }
}

// MARK: - Quiz screen

/// Multiple-choice rounds of ten. Correct answers on words already in
/// learning move them up the SRS boxes; misses send them back — unseen
/// words never enter the review schedule from here. Every reveal speaks
/// the Thai word, so even reading questions end as listening practice.
struct QuizView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var round = QuizRound.build()
    @State private var index = 0
    @State private var chosenID: Int?
    @State private var score = 0
    @State private var missed: [ThaiWord] = []
    @State private var showSummary = false
    @State private var detailWord: ThaiWord?

    private var question: QuizQuestion { round[index] }
    private var answered: Bool { chosenID != nil }

    var body: some View {
        Group {
            if showSummary {
                PracticeRoundSummary(
                    title: "Quiz done!",
                    score: score,
                    total: round.count,
                    missed: missed,
                    onWordTap: { detailWord = $0 },
                    onPlayAgain: restart,
                    onDone: { dismiss() }
                )
            } else {
                quizBody
            }
        }
        .background(ThaiTheme.bgAlt.ignoresSafeArea())
        .sheet(item: $detailWord) { word in
            WordDetailView(word: word)
                .presentationDetents([.medium, .large])
        }
        .onAppear { autoPlayIfListening() }
    }

    private var quizBody: some View {
        VStack(spacing: 14) {
            header
            prompt
            optionsList
            Spacer(minLength: 0)
            footer
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
    }

    // MARK: Header — close, position, running score

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
                Text("Quiz")
                    .font(ThaiTheme.display(20, bold: true))
                    .foregroundStyle(ThaiTheme.ink)
                Text("Question \(index + 1) of \(round.count)")
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

    // MARK: Prompt — what the learner is asked

    @ViewBuilder private var prompt: some View {
        VStack(spacing: 10) {
            switch question.kind {
            case .thaiToMeaning:
                promptCaption("WHAT DOES IT MEAN?")
                Text(question.word.thai)
                    .font(ThaiTheme.thai(52))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .foregroundStyle(ThaiTheme.ink)
                replayButton(small: true)

            case .meaningToThai:
                promptCaption("PICK THE THAI WORD")
                Text(question.word.englishMeaning)
                    .font(.system(size: 30, weight: .semibold))
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ThaiTheme.ink)
                Text(question.word.hindiMeaning)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ThaiTheme.orchid)

            case .listen:
                promptCaption("LISTEN — TAP TO HEAR AGAIN")
                replayButton(small: false)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, question.kind == .listen ? 26 : 18)
        .background(ThaiTheme.surface, in: RoundedRectangle(cornerRadius: ThaiTheme.radiusCard))
        .shadow(color: ThaiTheme.ink.opacity(0.08), radius: 10, y: 5)
    }

    private func promptCaption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(ThaiTheme.textMuted)
    }

    private func replayButton(small: Bool) -> some View {
        Button {
            speak(question.word)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: small ? 16 : 30, weight: .bold))
                .foregroundStyle(ThaiTheme.bg)
                .frame(width: small ? 44 : 84, height: small ? 44 : 84)
                .background(ThaiTheme.accent.gradient, in: Circle())
                .shadow(color: ThaiTheme.accent.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: Options

    private var optionsList: some View {
        VStack(spacing: 10) {
            ForEach(question.options) { option in
                optionRow(option)
            }
        }
    }

    private func optionRow(_ option: ThaiWord) -> some View {
        HStack(spacing: 0) {
            Button {
                choose(option)
            } label: {
                HStack(spacing: 12) {
                    optionLabel(option)
                    Spacer(minLength: 0)
                    if answered {
                        if option.id == question.word.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                        } else if option.id == chosenID {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(answered)

            // Listening focus: meaning→Thai options can be heard before
            // choosing. (Not on listen questions — that would be the answer.)
            if question.kind == .meaningToThai && !answered {
                Button {
                    speak(option)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThaiTheme.accent)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(optionFill(option), in: RoundedRectangle(cornerRadius: ThaiTheme.radiusControl))
        .overlay(RoundedRectangle(cornerRadius: ThaiTheme.radiusControl)
            .stroke(answered ? .clear : ThaiTheme.hairline, lineWidth: 1))
        .animation(.easeInOut(duration: 0.2), value: chosenID)
    }

    @ViewBuilder private func optionLabel(_ option: ThaiWord) -> some View {
        let bright = answered && (option.id == question.word.id || option.id == chosenID)
        switch question.kind {
        case .thaiToMeaning:
            VStack(alignment: .leading, spacing: 1) {
                Text(option.englishMeaning)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(bright ? .white : ThaiTheme.ink)
                Text(option.hindiMeaning)
                    .font(.system(size: 13))
                    .foregroundStyle(bright ? .white.opacity(0.85) : ThaiTheme.orchid)
            }
        case .meaningToThai, .listen:
            VStack(alignment: .leading, spacing: 1) {
                Text(option.thai)
                    .font(ThaiTheme.thai(24))
                    .foregroundStyle(bright ? .white : ThaiTheme.ink)
                Text(option.romanization)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(bright ? .white.opacity(0.85) : ThaiTheme.accent)
            }
        }
    }

    private func optionFill(_ option: ThaiWord) -> Color {
        guard answered else { return ThaiTheme.surface }
        if option.id == question.word.id { return ThaiTheme.accent2 }
        if option.id == chosenID { return ThaiTheme.danger }
        return ThaiTheme.surfaceSunken.opacity(0.6)
    }

    // MARK: Footer — reveal line + next

    @ViewBuilder private var footer: some View {
        if answered {
            VStack(spacing: 10) {
                Text("\(question.word.thai) · \(question.word.romanization) — \(question.word.englishMeaning)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ThaiTheme.textMuted)
                    .multilineTextAlignment(.center)
                PrimaryButton(
                    title: index + 1 < round.count ? "Next" : "See results",
                    icon: index + 1 < round.count ? "arrow.right" : "flag.checkered"
                ) {
                    advance()
                }
            }
        } else {
            Text(question.kind == .listen ? "Pick the word you heard" : "Tap an answer")
                .font(.system(size: 11.5))
                .foregroundStyle(ThaiTheme.textFaint)
                .padding(.bottom, 14)
        }
    }

    // MARK: Round mechanics

    private func choose(_ option: ThaiWord) {
        guard !answered else { return }
        chosenID = option.id
        let correct = option.id == question.word.id
        UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
        if correct {
            score += 1
        } else {
            missed.append(question.word)
        }
        // Only words already in learning feed the SRS — quiz-met strangers
        // shouldn't pollute the review schedule.
        if ProgressStore.shared.box(for: question.word.id) > 0 {
            ProgressStore.shared.record(id: question.word.id, known: correct)
        }
        // Every reveal is a listening rep.
        speak(question.word)
    }

    private func advance() {
        if index + 1 < round.count {
            withAnimation(.spring(duration: 0.3)) {
                index += 1
                chosenID = nil
            }
            autoPlayIfListening()
        } else {
            showSummary = true
        }
    }

    private func restart() {
        round = QuizRound.build()
        index = 0
        chosenID = nil
        score = 0
        missed = []
        showSummary = false
        autoPlayIfListening()
    }

    private func autoPlayIfListening() {
        guard question.kind == .listen else { return }
        // Slight delay so the speech doesn't race the presentation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            speak(question.word)
        }
    }

    private func speak(_ word: ThaiWord) {
        SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
    }
}

// MARK: - Round summary (shared by Quiz and Tone Trainer)

/// Score + the words that got away. Missed rows open the full word detail —
/// a miss is the best moment to actually study a word.
struct PracticeRoundSummary: View {
    let title: String
    let score: Int
    let total: Int
    let missed: [ThaiWord]
    let onWordTap: (ThaiWord) -> Void
    let onPlayAgain: () -> Void
    let onDone: () -> Void

    private var headline: String {
        switch score {
        case total: return "เก่งมาก! Perfect round."
        case (total * 7 / 10)...: return "Strong — keep the streak going."
        default: return "Misses are the fastest teachers."
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 10)

            Text(score == total ? "🏆" : "🎯")
                .font(.system(size: 52))

            Text(title)
                .font(ThaiTheme.display(28, bold: true))
                .foregroundStyle(ThaiTheme.ink)

            Text("\(score)/\(total)")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(score == total ? ThaiTheme.accent2 : ThaiTheme.accent)

            Text(headline)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !missed.isEmpty {
                VStack(spacing: 6) {
                    SectionLabel(title: "WORDS TO REVISIT")
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(missed) { word in
                                missedRow(word)
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                }
                .padding(.horizontal)
            }

            Spacer(minLength: 10)

            VStack(spacing: 10) {
                PrimaryButton(title: "Play again", icon: "arrow.counterclockwise", action: onPlayAgain)
                Button(action: onDone) {
                    Text("Done")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThaiTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .glassWashBackground()
    }

    private func missedRow(_ word: ThaiWord) -> some View {
        Button {
            onWordTap(word)
        } label: {
            HStack(spacing: 12) {
                Text(word.thai)
                    .font(ThaiTheme.thai(24))
                    .foregroundStyle(ThaiTheme.ink)
                VStack(alignment: .leading, spacing: 1) {
                    Text(word.romanization)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ThaiTheme.accent)
                    Text(word.englishMeaning)
                        .font(.system(size: 13))
                        .foregroundStyle(ThaiTheme.textMuted)
                }
                Spacer()
                Button {
                    SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundStyle(ThaiTheme.accent)
                        .frame(width: 34, height: 34)
                        .background(ThaiTheme.accent100, in: Circle())
                }
                .buttonStyle(.plain)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ThaiTheme.textFaint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(ThaiTheme.surface, in: RoundedRectangle(cornerRadius: ThaiTheme.radiusControl))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuizView()
}
