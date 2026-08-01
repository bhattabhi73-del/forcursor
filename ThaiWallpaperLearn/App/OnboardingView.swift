import SwiftUI
import UserNotifications

// MARK: - First-launch onboarding — three steps to the habit loop

struct OnboardingView: View {
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("สวัสดี!")
                .font(ThaiTheme.thai(52))
                .foregroundStyle(ThaiTheme.ink)
            Text("sà-wàt-dii — welcome to Thai Learn")
                .font(.headline)
                .foregroundStyle(ThaiTheme.accent)
            Text("Three small steps and Thai starts teaching itself:")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                step(number: 1, icon: "square.grid.2x2.fill",
                     title: "Add the widget",
                     detail: "Long-press your Home Screen → ＋ → Thai Learn. A new word every hour, zero effort.")
                step(number: 2, icon: "speaker.wave.2.fill",
                     title: "Hear a word",
                     detail: "Tones matter in Thai — always listen before you read. Try it:",
                     accessory: AnyView(
                        Button {
                            SpeechService.shared.speak(thai: "สวัสดี", romanization: "sà-wàt-dii")
                        } label: {
                            Label("สวัสดี — hello", systemImage: "play.fill")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(ThaiTheme.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                     ))
                step(number: 3, icon: "rectangle.on.rectangle.angled",
                     title: "Try Practice once",
                     detail: "Flip a card, grade yourself, done. \(ProgressStore.dailyGoal) cards a day builds a 450-word vocabulary.")
            }

            Spacer()

            Button {
                UserDefaults.standard.set(true, forKey: "hasOnboarded.v1")
                selectedTab = 1
                dismiss()
            } label: {
                Text("Start practicing")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(ThaiTheme.accent, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: ThaiTheme.accent.opacity(0.35), radius: 8, y: 4)
            .buttonStyle(.plain)

            Button {
                UserDefaults.standard.set(true, forKey: "hasOnboarded.v1")
                dismiss()
            } label: {
                Text("Just look around")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ThaiTheme.textMuted)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 22)
        .glassWashBackground()
        .interactiveDismissDisabled()
    }

    private func step(number: Int, icon: String, title: String, detail: String,
                      accessory: AnyView? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(ThaiTheme.accent.gradient, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text("\(number). \(title)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ThaiTheme.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let accessory {
                    accessory.padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .thaiGlass(cornerRadius: 18)
    }
}

// MARK: - Daily reminder (soft, opt-in)

enum ReminderService {
    static let enabledKey = "dailyReminder.v1"
    private static let identifier = "thailearn.dailyReminder"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    /// Toggles the 7 pm daily nudge. Requests permission on first enable;
    /// calls back with the resulting on/off state.
    static func toggle(completion: @escaping (Bool) -> Void) {
        if isEnabled {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            UserDefaults.standard.set(false, forKey: enabledKey)
            completion(false)
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                guard granted else { completion(false); return }
                schedule()
                UserDefaults.standard.set(true, forKey: enabledKey)
                completion(true)
            }
        }
    }

    private static func schedule() {
        let content = UNMutableNotificationContent()
        content.title = "\(ProgressStore.dailyGoal) cards are waiting 🔥"
        content.body = "A two-minute review keeps your streak alive. เก่งมาก awaits!"
        content.sound = .default

        var components = DateComponents()
        components.hour = 19
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
