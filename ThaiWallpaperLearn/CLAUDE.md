# Thai Learn — project notes

iOS app teaching Thai vocabulary to Hindi + English speakers. SwiftUI app + WidgetKit extension.

## Building

- **Always build with derived data OUTSIDE this folder** (Desktop is iCloud-synced; the file provider stamps extended attributes on build products and codesign fails with "resource fork, Finder information, or similar detritus not allowed"):
  `xcodebuild -project ThaiWallpaperLearn.xcodeproj -scheme ThaiWallpaperLearn -derivedDataPath /tmp/thailearn-dd build`
- Simulator: install the built `.app` with `xcrun simctl install booted …` and launch `com.thailearn.ThaiWallpaperLearn`.

## TestFlight release

App Store Connect app **"Thai Learn - Word Widgets"** (bundle `com.thailearn.ThaiWallpaperLearn`, Team `6XDFVK5F8P`). No signing certs/Xcode account on this Mac — use cloud signing:

1. Bump `CURRENT_PROJECT_VERSION` in `project.pbxproj`.
2. Archive **unsigned**: `xcodebuild … -destination 'generic/platform=iOS' archive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`.
3. Export signed with the App Store Connect API key (`~/private_keys/AuthKey_R7DDSVPMLD.p8`, key `R7DDSVPMLD`, issuer `7bf665d8-f314-48de-bad3-9d988012de09`): `xcodebuild -exportArchive … -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates -authenticationKeyPath … -authenticationKeyID … -authenticationKeyIssuerID …` (method `app-store-connect`, automatic signing).
4. Upload: `xcrun altool --upload-app -f <ipa> -t ios --apiKey R7DDSVPMLD --apiIssuer <issuer>`.
5. Export compliance is pre-answered (`INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`); the Internal Testers group has automatic distribution, so builds go straight to testers after processing.

## Architecture

- `Shared/Vocabulary.swift` — the word list (`ThaiWord` entries, sequential ids). `Vocabulary.word(forHour:)` gives the deterministic hourly rotation shared by all widgets; `related(to:)` derives compound relationships by substring.
- `Shared/ThaiWord.swift` — `WordExtras` (example sentences, joint-word notes, similar-sound map, word forms, emoji), `ThaiTheme` (Sukhothai Gold palette + dark widget gradients), `ToneAnalyzer` (tone from romanization marks), `ProgressStore` (Leitner SRS: boxes, 1/3/7/14/30-day intervals).
- `App/ContentView.swift` — Today, Browse (collections + 50/page), Alphabet (44 consonants, class colors, Devanagari cousins), `SpeechService` (th-TH TTS with romanization fallback).
- `App/FlashcardView.swift` — Practice: guess-from-sound cards, tone chips, "ThaiFlow" deck ordering (due → ≤20 new → reinforcement → backlog), Again/Got-it grading, detail sections (Sentences with tappable word links, Word Forms, Similar, Joint Word with color-coded breakdown).
- `Widget/ThaiWidget.swift` — Thai-first widget (small/medium/large/lock), English→Thai widget, paired lock-screen halves. Each widget family displays a different word offset (+1…+7) so every surface teaches a different word; halves share one word by design.

## Content conventions (authoritative — user-corrected)

- Romanization: tone marks (à á ǎ â), hyphenated syllables, **k/t/p style** (normalize g→k, dt→t, bp→p).
- Devanagari (`hindiPronunciation`) is a **pronunciation transliteration**: น้ำ alone = นาม but **short नम inside compounds** (น้ำตาล = नम-तान); the เ-ิ "er" vowel uses र् (เปิด = पर्द, เดิน = दर्न).
- `hindiMeaning` is a translation. Joint-word notes use the parseable format `X (rom) meaning / अर्थ + Y (rom) meaning / अर्थ → result / अर्थ` (rendered color-coded).
- **Standing rule:** every Thai word used inside an example sentence must itself be a dictionary entry. Check with a greedy longest-match segmentation of all sentences against the vocab after adding content.

## Content pipeline

New words are produced by agent workflows: generate batches (with themes + the conventions above) → a "strict Thai teacher" verify agent per batch → python scripts inject Swift literals into `Vocabulary.swift` / `ThaiWord.swift` (dedupe by Thai spelling, normalize romanization, sequential ids). Never hand-edit ids.
