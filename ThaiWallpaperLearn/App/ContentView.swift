import SwiftUI

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

            VStack(spacing: 6) {
                pronRow(flag: "🔤", label: "EN", value: word.romanization)
                pronRow(flag: "🇮🇳", label: "HI", value: word.hindiPronunciation)
            }

            Divider().padding(.horizontal, 40)

            VStack(spacing: 6) {
                meaningRow(flag: "🇬🇧", value: word.englishMeaning)
                meaningRow(flag: "🇮🇳", value: word.hindiMeaning)
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

struct BrowseView: View {
    @State private var query = ""

    var filtered: [ThaiWord] {
        guard !query.isEmpty else { return Vocabulary.all }
        let q = query.lowercased()
        return Vocabulary.all.filter {
            $0.thai.contains(query) ||
            $0.romanization.lowercased().contains(q) ||
            $0.englishMeaning.lowercased().contains(q) ||
            $0.hindiMeaning.contains(query) ||
            $0.hindiPronunciation.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { word in
                HStack(spacing: 14) {
                    Text(word.thai)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .frame(minWidth: 64, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(word.romanization).font(.subheadline.weight(.medium))
                        Text(word.hindiPronunciation).font(.subheadline).foregroundStyle(.secondary)
                        Text("\(word.englishMeaning)  ·  \(word.hindiMeaning)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .searchable(text: $query, prompt: "Search Thai, English or Hindi")
            .navigationTitle("All Words")
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

#Preview {
    ContentView()
}
