import SwiftUI

/// Tap-to-reveal flashcards: shows the Thai word, then flips to reveal
/// pronunciations and meanings. Swipe / tap "Next" to keep practicing.
struct FlashcardView: View {
    @State private var deck: [ThaiWord] = Vocabulary.all.shuffled()
    @State private var index = 0
    @State private var revealed = false

    private var current: ThaiWord { deck[index] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)

                    if revealed {
                        WordCard(word: current)
                            .padding(-16) // card already has its own padding
                            .transition(.opacity)
                    } else {
                        VStack(spacing: 12) {
                            Text(current.thai)
                                .font(.system(size: 76, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.4)
                                .lineLimit(1)
                            Text("Tap to reveal")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
                .frame(height: 360)
                .padding(.horizontal)
                .onTapGesture {
                    withAnimation(.spring(duration: 0.35)) { revealed.toggle() }
                }

                Text("\(index + 1) / \(deck.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 16) {
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

    private func advance() {
        withAnimation(.spring(duration: 0.3)) {
            revealed = false
            index = (index + 1) % deck.count
        }
    }
}

#Preview {
    FlashcardView()
}
