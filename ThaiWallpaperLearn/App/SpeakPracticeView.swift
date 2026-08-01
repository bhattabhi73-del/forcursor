import SwiftUI
import Speech
import AVFoundation
import UIKit

// MARK: - Thai speech checking

/// Wraps the th-TH speech recognizer: microphone tap → live transcript.
/// The view compares the transcript against the target word; this class
/// only knows how to listen.
final class ThaiSpeechChecker: ObservableObject {
    enum Phase: Equatable {
        case idle        // ready to record
        case listening   // engine running, transcript updating
        case denied      // mic or speech permission refused
        case unavailable // recognizer exists but can't serve right now
    }

    @Published var phase: Phase = .idle
    @Published var transcript = ""

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "th-TH"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Ask for both permissions up front so the mic button never surprises.
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    self.phase = .denied
                    return
                }
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if !granted { self.phase = .denied }
                    }
                }
            }
        }
    }

    func start() {
        guard phase != .listening else { return }
        guard let recognizer, recognizer.isAvailable else {
            phase = .unavailable
            return
        }
        transcript = ""
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement,
                                    options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.request = request

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }
            engine.prepare()
            try engine.start()
            phase = .listening

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil || result?.isFinal == true {
                        self.tearDownAudio()
                    }
                }
            }
        } catch {
            NSLog("ThaiSpeechChecker: could not start engine: %@", error.localizedDescription)
            tearDownAudio()
            phase = .unavailable
        }
    }

    /// The partial transcript is already on screen, so stopping just ends
    /// the audio — no need to wait for the recognizer's final polish.
    func stop() {
        request?.endAudio()
        tearDownAudio()
    }

    private func tearDownAudio() {
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
        request = nil
        if phase == .listening { phase = .idle }
    }
}

// MARK: - Speak practice

/// Mouth training: see a word, say it, and the th-TH recognizer judges the
/// attempt. Deliberately outside the SRS — pronunciation reps shouldn't
/// reschedule memory reviews.
struct SpeakPracticeView: View {
    /// The Practice tab only offers this mode when the device can make a
    /// Thai recognizer at all; permission problems surface inside the view.
    static var isSupported: Bool {
        SFSpeechRecognizer(locale: Locale(identifier: "th-TH")) != nil
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var checker = ThaiSpeechChecker()

    /// Same seen-words-first ordering as the quiz: say the words you're
    /// actually learning.
    static func buildDeck() -> [ThaiWord] {
        let store = ProgressStore.shared
        let seen = Vocabulary.all.filter { store.box(for: $0.id) > 0 }.shuffled()
        let fresh = Vocabulary.all.filter { store.box(for: $0.id) == 0 }.shuffled()
        return seen + fresh
    }

    @State private var deck = SpeakPracticeView.buildDeck()
    @State private var index = 0
    @State private var verdict: Verdict = .none
    @State private var saidCount = 0

    enum Verdict { case none, correct, tryAgain }

    private var word: ThaiWord { deck[index] }

    /// Contains-match on space-stripped text: the recognizer often pads an
    /// answer into a phrase (or picks a compound), and that still means the
    /// learner produced the word.
    private func matches(_ transcript: String) -> Bool {
        let heard = transcript.replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let target = word.thai.replacingOccurrences(of: " ", with: "")
        guard !heard.isEmpty else { return false }
        return heard.contains(target) || target.contains(heard)
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            if checker.phase == .denied {
                permissionCard
            } else {
                wordCard
                feedback
                Spacer(minLength: 0)
                micControls
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 12)
        .background(ThaiTheme.bgAlt.ignoresSafeArea())
        .onAppear { checker.requestPermissions() }
        .onDisappear { checker.stop() }
        .onChange(of: checker.transcript) {
            // Auto-stop the instant the word lands — instant reward.
            if checker.phase == .listening && verdict == .none && matches(checker.transcript) {
                settle()
            }
        }
        .onChange(of: checker.phase) {
            // Recognizer finished on its own (silence timeout) — judge what
            // it heard rather than leaving the button stuck.
            if checker.phase == .idle && verdict == .none && !checker.transcript.isEmpty {
                settle()
            }
        }
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
                Text("Speak")
                    .font(ThaiTheme.display(20, bold: true))
                    .foregroundStyle(ThaiTheme.ink)
                Text("Say it out loud — the app listens")
                    .font(.system(size: 11.5))
                    .foregroundStyle(ThaiTheme.textMuted)
            }
            Spacer()
            if saidCount > 0 {
                Text("\(saidCount) said")
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(ThaiTheme.accent2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ThaiTheme.accent2100, in: Capsule())
            }
        }
        .padding(.top, 10)
    }

    // MARK: Word card — everything needed to attempt the word

    private var wordCard: some View {
        VStack(spacing: 10) {
            Text(word.category.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(ThaiTheme.accent700)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(ThaiTheme.accent200, in: Capsule())

            Text(word.thai)
                .font(ThaiTheme.thai(52))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(ThaiTheme.ink)

            Text("\(word.hindiPronunciation) · \(word.romanization)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ThaiTheme.orchid)
            Text("\(word.hindiMeaning) · \(word.englishMeaning)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ThaiTheme.ink)

            Button {
                SpeechService.shared.speak(thai: word.thai, romanization: word.romanization)
            } label: {
                Label("Hear it first", systemImage: "speaker.wave.2.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ThaiTheme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(ThaiTheme.accent100, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(ThaiTheme.surface, in: RoundedRectangle(cornerRadius: ThaiTheme.radiusCard))
        .shadow(color: ThaiTheme.ink.opacity(0.08), radius: 10, y: 5)
    }

    // MARK: Feedback — heard vs target

    @ViewBuilder private var feedback: some View {
        switch verdict {
        case .none:
            if checker.phase == .listening {
                VStack(spacing: 6) {
                    Text(checker.transcript.isEmpty ? "Listening…" : checker.transcript)
                        .font(ThaiTheme.thai(22))
                        .foregroundStyle(ThaiTheme.ink)
                        .multilineTextAlignment(.center)
                    Text("Say “\(word.romanization)”")
                        .font(.system(size: 11.5))
                        .foregroundStyle(ThaiTheme.textFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .thaiGlass(cornerRadius: ThaiTheme.radiusControl)
            } else if checker.phase == .unavailable {
                Text("Thai recognition isn't available right now — try again in a moment.")
                    .font(.footnote)
                    .foregroundStyle(ThaiTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
            }
        case .correct:
            resultCard(good: true,
                       line: "Sounded right! · เก่งมาก",
                       heard: checker.transcript)
        case .tryAgain:
            resultCard(good: false,
                       line: checker.transcript.isEmpty
                             ? "Didn't catch that — get closer to the mic"
                             : "Close — compare what it heard:",
                       heard: checker.transcript)
        }
    }

    private func resultCard(good: Bool, line: String, heard: String) -> some View {
        VStack(spacing: 6) {
            Label(line, systemImage: good ? "checkmark.seal.fill" : "arrow.counterclockwise")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(good ? ThaiTheme.accent2 : ThaiTheme.danger)
            if !heard.isEmpty {
                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text("HEARD")
                            .font(.system(size: 9, weight: .semibold)).tracking(1)
                            .foregroundStyle(ThaiTheme.textFaint)
                        Text(heard)
                            .font(ThaiTheme.thai(20))
                            .foregroundStyle(ThaiTheme.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        Text("TARGET")
                            .font(.system(size: 9, weight: .semibold)).tracking(1)
                            .foregroundStyle(ThaiTheme.textFaint)
                        Text(word.thai)
                            .font(ThaiTheme.thai(20))
                            .foregroundStyle(good ? ThaiTheme.accent2 : ThaiTheme.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .thaiGlass(cornerRadius: ThaiTheme.radiusControl)
    }

    // MARK: Mic controls

    @ViewBuilder private var micControls: some View {
        VStack(spacing: 10) {
            switch verdict {
            case .none:
                Button {
                    if checker.phase == .listening {
                        settle()
                    } else {
                        checker.start()
                    }
                } label: {
                    Image(systemName: checker.phase == .listening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(ThaiTheme.bg)
                        .frame(width: 76, height: 76)
                        .background(
                            (checker.phase == .listening ? ThaiTheme.danger : ThaiTheme.accent).gradient,
                            in: Circle()
                        )
                        .shadow(color: (checker.phase == .listening ? ThaiTheme.danger : ThaiTheme.accent).opacity(0.4),
                                radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                Text(checker.phase == .listening ? "Tap to stop" : "Tap, then say the word")
                    .font(.system(size: 11.5))
                    .foregroundStyle(ThaiTheme.textFaint)

            case .correct:
                PrimaryButton(title: "Next word", icon: "arrow.right") { advance() }

            case .tryAgain:
                HStack(spacing: 12) {
                    Button {
                        verdict = .none
                        checker.start()
                    } label: {
                        Label("Try again", systemImage: "mic.fill")
                            .font(ThaiTheme.display(16, bold: true))
                            .foregroundStyle(ThaiTheme.accent700)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(ThaiTheme.accent100, in: Capsule())
                            .overlay(Capsule().stroke(ThaiTheme.accent300, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    Button {
                        advance()
                    } label: {
                        Label("Skip", systemImage: "arrow.right")
                            .font(ThaiTheme.display(16, bold: true))
                            .foregroundStyle(ThaiTheme.bg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(ThaiTheme.accent2, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Permission fallback

    private var permissionCard: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(ThaiTheme.textMuted)
            Text("Speaking practice needs the microphone")
                .font(ThaiTheme.display(20, bold: true))
                .foregroundStyle(ThaiTheme.ink)
                .multilineTextAlignment(.center)
            Text("Allow microphone and speech recognition in Settings, and the app will check your Thai pronunciation.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Open Settings", icon: "gear") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: Session mechanics

    private func settle() {
        checker.stop()
        let good = matches(checker.transcript)
        UINotificationFeedbackGenerator().notificationOccurred(good ? .success : .error)
        if good { saidCount += 1 }
        verdict = good ? .correct : .tryAgain
    }

    private func advance() {
        withAnimation(.spring(duration: 0.3)) {
            index = (index + 1) % deck.count
            verdict = .none
        }
    }
}

#Preview {
    SpeakPracticeView()
}
