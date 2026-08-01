import SwiftUI

// MARK: - Shareable word card

/// The branded card rendered to an image for the share sheet — a widget-style
/// navy card so shared words look like the app, not a screenshot.
struct WordShareCard: View {
    let word: ThaiWord

    var body: some View {
        VStack(spacing: 14) {
            Text(word.category.uppercased())
                .font(.system(size: 13, weight: .bold))
                .tracking(2)
                .foregroundStyle(ThaiTheme.accent2400)

            Text(word.thai)
                .font(ThaiTheme.thai(84))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(.white)

            VStack(spacing: 6) {
                Text(word.hindiPronunciation)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(ThaiTheme.accent400)
                Text(word.romanization)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(ThaiTheme.accent300)
            }

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 120, height: 1)

            VStack(spacing: 4) {
                Text(word.hindiMeaning)
                    .font(.system(size: 30, weight: .semibold))
                Text(word.englishMeaning)
                    .font(.system(size: 28, weight: .semibold))
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 13))
                Text("Thai Learn — เรียนภาษาไทย")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.55))
            .padding(.top, 8)
        }
        .padding(36)
        .frame(width: 420)
        .background(ThaiTheme.thaiGradient)
    }
}

enum ShareCardRenderer {
    /// Renders the card at 3× for a crisp shareable PNG.
    @MainActor
    static func image(for word: ThaiWord) -> Image {
        let renderer = ImageRenderer(content: WordShareCard(word: word))
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "square.and.arrow.up")
    }
}
