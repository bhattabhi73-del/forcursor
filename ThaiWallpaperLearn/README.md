# Thai Learn — iPhone app + home/lock‑screen widget

A small personal iPhone app to learn Thai. It shows Thai words with:

- **Thai script** (e.g. สวัสดี)
- **English pronunciation** (e.g. `sà-wàt-dii`)
- **Hindi pronunciation** in Devanagari (e.g. `स-वट-दी`)
- **English meaning** (e.g. *hello*)
- **Hindi meaning** in Devanagari (e.g. *नमस्ते*)

The **widget** puts a rotating random word right on your Home Screen and Lock
Screen — the closest thing iOS allows to "Thai words on your wallpaper."

---

## ⚠️ First, the honest part about "wallpaper"

An iPhone app is **not allowed to change your actual wallpaper image** — Apple
blocks that for security reasons. So instead this project gives you a **widget**:
a live tile that sits on top of your wallpaper (Home Screen and Lock Screen) and
shows a fresh Thai word that rotates through the day. For most people this is
actually nicer than a static wallpaper, because it changes and stays readable.

*(If you truly want the words burned into the wallpaper image itself, that can
only be done with the Shortcuts app + a "Set Wallpaper" automation using
pre‑made images — see the note at the bottom.)*

---

## What you need

Building any iPhone app requires Apple's tools. There is no way around this:

1. **A Mac** (macOS) with **Xcode** installed (free from the Mac App Store).
2. A **free Apple ID** — enough to run the app on your *own* iPhone.
3. A **USB cable** to connect your iPhone the first time.

You do **not** need a paid Apple Developer account just to use it yourself.

---

## How to build & run it

1. Copy the `ThaiWallpaperLearn` folder to your Mac.
2. Double‑click **`ThaiWallpaperLearn.xcodeproj`** to open it in Xcode.
3. Plug in your iPhone. At the top of Xcode, pick your iPhone as the run target.
4. Select the **ThaiWallpaperLearn** scheme (top‑left), then press **▶ Run**.
5. First time only: in Xcode go to the target's **Signing & Capabilities** tab
   and choose your Apple ID under *Team*. Do this for **both** targets
   (`ThaiWallpaperLearn` and `ThaiWidgetExtension`). Xcode will auto‑fix the
   bundle IDs if they clash — just accept its suggestion.
6. On your iPhone, the first launch may need
   **Settings → General → VPN & Device Management → Trust** your developer
   certificate.

> If the project ever refuses to open, you can regenerate it: install
> [XcodeGen](https://github.com/yonatankarni/XcodeGen) (`brew install xcodegen`),
> then run `xcodegen generate` inside the `ThaiWallpaperLearn` folder. The
> `project.yml` spec is included for exactly this.

---

## Adding the widget to your screen

**Home Screen**
1. Touch and hold an empty spot until the icons jiggle.
2. Tap **+** (top‑left) → search **"Thai Learn"**.
3. Pick a size (small or medium) → **Add Widget** → **Done**.

**Lock Screen**
1. Touch and hold the Lock Screen → **Customize** → **Lock Screen**.
2. Tap the area under the clock → choose **Thai Learn**.

The widget refreshes itself roughly every hour with a new random word. The app's
**Widget** tab has these same instructions on your phone.

---

## What's inside the app

- **Today** – a "word of the day" plus a Shuffle button for a fresh random word.
- **Practice** – tap‑to‑reveal flashcards to test yourself.
- **Browse** – the full word list, searchable in Thai, English, or Hindi.
- **Widget** – setup instructions on the device.

---

## Adding your own words

All vocabulary lives in one file: **`Shared/Vocabulary.swift`**. Each entry looks
like this:

```swift
ThaiWord(id: 53, thai: "โรงเรียน", romanization: "roong-rian",
         hindiPronunciation: "रोंग-रियन", englishMeaning: "school",
         hindiMeaning: "स्कूल / विद्यालय", category: "Places"),
```

Copy a line, bump the `id` to the next number, fill in your word, and re‑run.
The app **and** the widget both read from this one list automatically.

> The Hindi pronunciations are phonetic approximations to help you *sound out*
> Thai — Thai has tones and vowels Hindi doesn't, so treat them as a friendly
> guide, not a perfect transcription. Fix any you'd say differently.

---

## Bonus: real wallpaper via Shortcuts (optional, no coding)

If you specifically want the words *inside* the wallpaper image:

1. Make image files (one per word) — e.g. with the app's card design screenshots.
2. In the **Shortcuts** app → **Automation** → create a time‑based automation.
3. Add the **"Set Wallpaper"** action pointing at a photo album of those images.

This changes the actual wallpaper on a schedule, but it's manual to maintain.
The widget approach above is the low‑effort, always‑fresh option.
