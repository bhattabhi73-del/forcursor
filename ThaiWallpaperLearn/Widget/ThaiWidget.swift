import WidgetKit
import SwiftUI

// MARK: - Timeline

struct ThaiEntry: TimelineEntry {
    let date: Date
    let word: ThaiWord
}

struct ThaiProvider: TimelineProvider {
    /// Shifts this widget's rotation so different widget kinds show
    /// different words at the same moment. Widgets meant to pair up
    /// (the left/right halves) share offset 0.
    var wordOffset = 0

    func placeholder(in context: Context) -> ThaiEntry {
        ThaiEntry(date: Date(), word: Vocabulary.word(forDayOffset: 0))
    }

    func getSnapshot(in context: Context, completion: @escaping (ThaiEntry) -> Void) {
        let hour = Int(Date().timeIntervalSince1970 / 3600)
        completion(ThaiEntry(date: Date(), word: Vocabulary.word(forHour: hour + wordOffset)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThaiEntry>) -> Void) {
        // One word per clock hour, derived from the hour number itself so
        // widgets with the same offset (like the two lock-screen halves)
        // show the same word at the same time — even while offline.
        var entries: [ThaiEntry] = []
        let hourStart = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970 / 3600) * 3600)
        let baseHour = Int(hourStart.timeIntervalSince1970 / 3600)
        for hour in 0..<24 {
            let date = hourStart.addingTimeInterval(Double(hour) * 3600)
            entries.append(ThaiEntry(date: date, word: Vocabulary.word(forHour: baseHour + hour + wordOffset)))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Views

struct ThaiWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: ThaiEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            lockScreenRectangular
        case .accessoryCircular:
            lockScreenCircular
        case .accessoryInline:
            Text("\(entry.word.thai) · \(entry.word.englishMeaning)")
        case .systemSmall:
            smallWidget
        case .systemLarge:
            largeWidget
        default:
            mediumWidget
        }
    }

    // Home screen — small: Thai on top, then pronunciation (HI + EN), then meaning (HI + EN)
    private var smallWidget: some View {
        VStack(spacing: 4) {
            Text(entry.word.thai)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            Text(entry.word.hindiPronunciation)
                .font(.footnote.weight(.medium))
            Text(entry.word.romanization)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            Divider()
            Text(entry.word.hindiMeaning)
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(entry.word.englishMeaning)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .multilineTextAlignment(.center)
        .padding(6)
        .containerBackground(for: .widget) { gradient }
    }

    // Home screen — medium
    private var mediumWidget: some View {
        VStack(spacing: 5) {
            Text(entry.word.thai)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            Text("🗣️ \(entry.word.hindiPronunciation) · \(entry.word.romanization)")
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Divider().padding(.horizontal, 24)
            Text("🇮🇳 \(entry.word.hindiMeaning)")
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("🇬🇧 \(entry.word.englishMeaning)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .multilineTextAlignment(.center)
        .padding(12)
        .containerBackground(for: .widget) { gradient }
    }

    // Home screen — large: roomiest layout, same order top to bottom
    private var largeWidget: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)
            Text(entry.word.thai)
                .font(.system(size: 76, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            VStack(spacing: 6) {
                Text("PRONUNCIATION")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Text(entry.word.hindiPronunciation)
                    .font(.title2.weight(.medium))
                Text(entry.word.romanization)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.horizontal, 40)

            VStack(spacing: 6) {
                Text("MEANING")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Text(entry.word.hindiMeaning)
                    .font(.title2)
                Text(entry.word.englishMeaning)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text(entry.word.category.uppercased())
                .font(.caption2)
                .tracking(1.2)
                .foregroundStyle(.tertiary)
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .padding(16)
        .containerBackground(for: .widget) { gradient }
    }

    // Lock screen — rectangular (tinted / monochrome by system).
    // iOS fixes this slot's size, so the goal is filling every point of it.
    private var lockScreenRectangular: some View {
        VStack(alignment: .center, spacing: -2) {
            Text(entry.word.thai)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .widgetAccentable()
            Text("\(entry.word.hindiPronunciation) · \(entry.word.romanization)")
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("\(entry.word.hindiMeaning) · \(entry.word.englishMeaning)")
                .font(.system(size: 14))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        // Frosted system backing so the text stays readable on any
        // wallpaper — including a plain white one.
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
    }

    // Lock screen — circular. Decorative "ไทย" badge; place one on each
    // side of the rectangular widget to push it into the center of the row.
    private var lockScreenCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            Text("ไทย")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .widgetAccentable()
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.16, green: 0.32, blue: 0.75).opacity(0.25),
                     Color(red: 0.86, green: 0.30, blue: 0.55).opacity(0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Paired lock-screen halves
// The below-the-clock row fits two rectangular widgets. Placing these two
// side by side fills the entire row like one wide banner: the huge Thai
// word on the left, its pronunciation and meaning on the right. They stay
// in sync because every widget derives its word from the clock hour.

struct ThaiWordHalfView: View {
    var entry: ThaiEntry

    var body: some View {
        Text(entry.word.thai)
            .font(.system(size: 58, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.3)
            .lineLimit(1)
            .widgetAccentable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
    }
}

struct ThaiMeaningHalfView: View {
    var entry: ThaiEntry

    var body: some View {
        VStack(spacing: 0) {
            Text("\(entry.word.hindiPronunciation) · \(entry.word.romanization)")
                .font(.system(size: 15, weight: .semibold))
            Text(entry.word.hindiMeaning)
                .font(.system(size: 15))
            Text(entry.word.englishMeaning)
                .font(.system(size: 15))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
    }
}

struct ThaiWordHalfWidget: Widget {
    let kind = "ThaiWordHalf"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ThaiProvider()) { entry in
            ThaiWordHalfView(entry: entry)
        }
        .configurationDisplayName("Word — Left Half")
        .description("Big Thai word. Pair with “Meaning — Right Half” to fill the whole row under the clock.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct ThaiMeaningHalfWidget: Widget {
    let kind = "ThaiMeaningHalf"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ThaiProvider()) { entry in
            ThaiMeaningHalfView(entry: entry)
        }
        .configurationDisplayName("Meaning — Right Half")
        .description("Pronunciation and meaning. Place to the right of “Word — Left Half”.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - English-first widget
// Reverse direction: the English word leads, then the Thai translation
// with its pronunciation (Devanagari + romanized), then the Hindi meaning.

struct EnglishFirstEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: ThaiEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .center, spacing: -2) {
                Text(entry.word.englishMeaning)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .widgetAccentable()
                Text("\(entry.word.thai) · \(entry.word.romanization)")
                    .font(.system(size: 15, weight: .semibold))
                Text("\(entry.word.hindiPronunciation) · \(entry.word.hindiMeaning)")
                    .font(.system(size: 14))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryInline:
            Text("\(entry.word.englishMeaning) · \(entry.word.thai)")
        default:
            homeScreen
        }
    }

    private var homeScreen: some View {
        VStack(spacing: family == .systemSmall ? 4 : 8) {
            Text(entry.word.englishMeaning)
                .font(.system(size: family == .systemSmall ? 24 : 34, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(family == .systemSmall ? 2 : 1)
            Divider().padding(.horizontal, 24)
            Text(entry.word.thai)
                .font(.system(size: family == .systemSmall ? 30 : 40, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            Text("\(entry.word.hindiPronunciation) · \(entry.word.romanization)")
                .font(family == .systemSmall ? .footnote.weight(.medium) : .subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("🇮🇳 \(entry.word.hindiMeaning)")
                .font(family == .systemSmall ? .footnote : .subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .multilineTextAlignment(.center)
        .padding(family == .systemSmall ? 8 : 12)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.55, blue: 0.45).opacity(0.25),
                         Color(red: 0.16, green: 0.32, blue: 0.75).opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct EnglishFirstWidget: Widget {
    let kind = "EnglishFirstWidget"

    var body: some WidgetConfiguration {
        // Offset 3 → always a different word than the Thai-first widgets,
        // so two widgets on screen teach two words at once.
        StaticConfiguration(kind: kind, provider: ThaiProvider(wordOffset: 3)) { entry in
            EnglishFirstEntryView(entry: entry)
        }
        .configurationDisplayName("English → Thai")
        .description("An English word with its Thai translation, pronunciation, and Hindi meaning.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Widget

struct ThaiWidget: Widget {
    let kind = "ThaiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ThaiProvider()) { entry in
            ThaiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Thai Learn")
        .description("A rotating Thai word with English & Hindi pronunciation and meaning.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}
