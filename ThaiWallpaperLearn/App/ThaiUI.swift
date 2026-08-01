import SwiftUI

// MARK: - Glass surfaces

/// Frosted glass card: Apple's real Liquid Glass on iOS 26+, a material
/// with a hairline highlight as the visually-matching fallback below.
struct ThaiGlass: ViewModifier {
    var cornerRadius: CGFloat = ThaiTheme.radiusCard

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.55), lineWidth: 1))
        }
    }
}

extension View {
    func thaiGlass(cornerRadius: CGFloat = ThaiTheme.radiusCard) -> some View {
        modifier(ThaiGlass(cornerRadius: cornerRadius))
    }

    /// Quiet sand wash — no lavender orbs.
    func glassWashBackground() -> some View {
        background(
            ThaiTheme.glassWash
                .ignoresSafeArea()
        )
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fill: Color = ThaiTheme.indigo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let icon {
                    Label(title, systemImage: icon)
                } else {
                    Text(title)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .background(fill.opacity(0.92), in: RoundedRectangle(cornerRadius: ThaiTheme.radiusControl))
        .shadow(color: fill.opacity(0.35), radius: 8, y: 4)
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var fill: Color = ThaiTheme.gold
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let icon {
                    Label(title, systemImage: icon)
                } else {
                    Text(title)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(fill, in: RoundedRectangle(cornerRadius: ThaiTheme.radiusControl))
        .buttonStyle(.plain)
    }
}

struct IconCircleButton: View {
    let systemName: String
    var foreground: Color = ThaiTheme.indigo
    var filled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.bold))
                .foregroundStyle(filled ? .white : foreground)
                .frame(width: 54, height: 54)
                .background(
                    filled ? AnyShapeStyle(ThaiTheme.indigo.gradient) : AnyShapeStyle(ThaiTheme.cream),
                    in: Circle()
                )
                .overlay(Circle().stroke(ThaiTheme.gold.opacity(filled ? 0 : 0.4), lineWidth: 1))
                .shadow(color: filled ? ThaiTheme.indigo.opacity(0.35) : .clear, radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct IconGlassButton: View {
    let systemName: String
    var foreground: Color = ThaiTheme.indigo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(foreground)
                .frame(width: 52, height: 52)
                .thaiGlass(cornerRadius: ThaiTheme.radiusControl)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chips & tags

struct FilterChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(selected ? .white : ThaiTheme.ink)
                .background(
                    selected ? ThaiTheme.indigo : ThaiTheme.parchment,
                    in: RoundedRectangle(cornerRadius: ThaiTheme.radiusChip)
                )
        }
        .buttonStyle(.plain)
    }
}

struct LanguageTag: View {
    enum Kind { case hi, en, th }

    let kind: Kind

    private var text: String {
        switch kind {
        case .hi: return "HI"
        case .en: return "EN"
        case .th: return "TH"
        }
    }

    private var color: Color {
        switch kind {
        case .hi: return ThaiTheme.orchid
        case .en: return ThaiTheme.indigo
        case .th: return ThaiTheme.gold
        }
    }

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
    }
}

struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(ThaiTheme.stone)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Progress ring (session complete)

struct ProgressRing: View {
    var progress: CGFloat  // 0…1
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(ThaiTheme.gold.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ThaiTheme.gold, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "checkmark")
                .font(.title2.weight(.bold))
                .foregroundStyle(ThaiTheme.gold)
        }
    }
}

// MARK: - Word card

struct WordCard: View {
    let word: ThaiWord
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 8 : 14) {
            Text(word.category)
                .font(.caption.weight(.medium))
                .foregroundStyle(ThaiTheme.accent700)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(ThaiTheme.accent200, in: RoundedRectangle(cornerRadius: ThaiTheme.radiusChip))

            Text(word.thai)
                .font(ThaiTheme.thai(compact ? 48 : 66))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(ThaiTheme.ink)

            VStack(spacing: 5) {
                pronRow(kind: .hi, value: word.hindiPronunciation)
                pronRow(kind: .en, value: word.romanization)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.white.opacity(0.42), in: RoundedRectangle(cornerRadius: ThaiTheme.radiusControl))
            .overlay(RoundedRectangle(cornerRadius: ThaiTheme.radiusControl).stroke(.white.opacity(0.5), lineWidth: 1))

            VStack(spacing: 4) {
                meaningRow(kind: .hi, value: word.hindiMeaning)
                meaningRow(kind: .en, value: word.englishMeaning)
            }
        }
        .padding(compact ? 16 : 22)
        .frame(maxWidth: .infinity)
        .thaiGlass(cornerRadius: ThaiTheme.radiusCard)
        .shadow(color: ThaiTheme.ink.opacity(0.10), radius: 12, y: 6)
        .padding(.horizontal)
    }

    private func pronRow(kind: LanguageTag.Kind, value: String) -> some View {
        HStack(spacing: 8) {
            LanguageTag(kind: kind)
            Text(value)
                .font(.title3.weight(.medium))
                .foregroundStyle(kind == .hi ? ThaiTheme.orchid : ThaiTheme.indigo)
        }
    }

    private func meaningRow(kind: LanguageTag.Kind, value: String) -> some View {
        HStack(spacing: 8) {
            LanguageTag(kind: kind)
            Text(value)
                .font(ThaiTheme.display(compact ? 18 : 21))
                .multilineTextAlignment(.center)
                .foregroundStyle(ThaiTheme.ink)
        }
    }
}

/// Compact Thai hero block for Practice front (shares hierarchy with WordCard).
struct ThaiHeroWord: View {
    let word: ThaiWord
    var showEmoji: Bool = true

    var body: some View {
        VStack(spacing: 10) {
            if showEmoji, let emoji = WordExtras.emoji(for: word) {
                Text(emoji).font(.system(size: 40))
            }
            Text(word.thai)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(ThaiTheme.ink)

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    LanguageTag(kind: .hi)
                    Text(word.hindiPronunciation)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(ThaiTheme.orchid)
                }
                HStack(spacing: 8) {
                    LanguageTag(kind: .en)
                    Text(word.romanization)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(ThaiTheme.indigo)
                }
            }
        }
    }
}
