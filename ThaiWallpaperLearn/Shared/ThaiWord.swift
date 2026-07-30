import Foundation

/// A single vocabulary entry shown in the app and on the widget.
///
/// Every word carries four learning aids around the Thai script:
///  - `romanization`      → how to *say* it, written in the Latin alphabet (English pronunciation)
///  - `hindiPronunciation`→ how to *say* it, written in Devanagari (Hindi pronunciation)
///  - `englishMeaning`    → what it *means*, in English
///  - `hindiMeaning`      → what it *means*, in Hindi
struct ThaiWord: Identifiable, Codable, Hashable {
    let id: Int
    let thai: String
    let romanization: String
    let hindiPronunciation: String
    let englishMeaning: String
    let hindiMeaning: String
    let category: String
}
