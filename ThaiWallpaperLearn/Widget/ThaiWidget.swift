import WidgetKit
import SwiftUI

// MARK: - Timeline

struct ThaiEntry: TimelineEntry {
    let date: Date
    let word: ThaiWord
}

struct ThaiProvider: TimelineProvider {
    func placeholder(in context: Context) -> ThaiEntry {
        ThaiEntry(date: Date(), word: Vocabulary.word(forDayOffset: 0))
    }

    func getSnapshot(in context: Context, completion: @escaping (ThaiEntry) -> Void) {
        completion(ThaiEntry(date: Date(), word: Vocabulary.randomWord()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ThaiEntry>) -> Void) {
        // Build a rotation of upcoming words, one per hour, so the screen keeps
        // showing something new even while the device is offline.
        var entries: [ThaiEntry] = []
        let now = Date()
        let shuffled = Vocabulary.all.shuffled()
        for hour in 0..<12 {
            let date = Calendar.current.date(byAdding: .hour, value: hour, to: now) ?? now
            let word = shuffled[hour % shuffled.count]
            entries.append(ThaiEntry(date: date, word: word))
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
        case .accessoryInline:
            Text("\(entry.word.thai) · \(entry.word.englishMeaning)")
        case .systemSmall:
            smallWidget
        default:
            mediumWidget
        }
    }

    // Home screen — small
    private var smallWidget: some View {
        VStack(spacing: 6) {
            Text(entry.word.thai)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            Text(entry.word.romanization)
                .font(.caption.weight(.medium))
            Text(entry.word.hindiPronunciation)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Divider()
            Text(entry.word.englishMeaning)
                .font(.caption2)
                .lineLimit(1)
            Text(entry.word.hindiMeaning)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
        .padding(8)
        .containerBackground(for: .widget) { gradient }
    }

    // Home screen — medium
    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack {
                Text(entry.word.thai)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(entry.word.category.uppercased())
                    .font(.caption2)
                    .tracking(1)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 5) {
                row("🔤", entry.word.romanization, bold: true)
                row("🇮🇳", entry.word.hindiPronunciation)
                Divider()
                row("🇬🇧", entry.word.englishMeaning)
                row("🇮🇳", entry.word.hindiMeaning)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(for: .widget) { gradient }
    }

    // Lock screen — rectangular (tinted / monochrome by system)
    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.word.thai)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .lineLimit(1)
            Text("\(entry.word.romanization) · \(entry.word.englishMeaning)")
                .font(.caption2)
                .lineLimit(1)
            Text(entry.word.hindiMeaning)
                .font(.caption2)
                .lineLimit(1)
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private func row(_ flag: String, _ value: String, bold: Bool = false) -> some View {
        HStack(spacing: 5) {
            Text(flag).font(.caption2)
            Text(value)
                .font(.caption.weight(bold ? .semibold : .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
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
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}
