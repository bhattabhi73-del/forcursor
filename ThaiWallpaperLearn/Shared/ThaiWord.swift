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

/// A short sentence showing a word in real use, in all three languages.
struct WordExample {
    let thai: String
    let romanization: String
    let english: String
    let hindi: String
}

/// Thai's five tones, detected from the tone marks in our romanization
/// (à = low, á = high, â = falling, ǎ = rising, unmarked = mid).
enum ThaiTone {
    case mid, low, falling, high, rising

    var englishName: String {
        switch self {
        case .mid: return "mid"
        case .low: return "low"
        case .falling: return "falling"
        case .high: return "high"
        case .rising: return "rising"
        }
    }
}

/// One spoken syllable of a romanized word with its tone.
struct ToneSyllable {
    let text: String
    let tone: ThaiTone
}

enum ToneAnalyzer {
    static func syllables(of romanization: String) -> [ToneSyllable] {
        romanization
            .split(whereSeparator: { $0 == "-" || $0 == " " })
            .map { syllable in
                let text = String(syllable)
                var tone = ThaiTone.mid
                for scalar in text.decomposedStringWithCanonicalMapping.unicodeScalars {
                    switch scalar.value {
                    case 0x300: tone = .low       // grave: à
                    case 0x301: tone = .high      // acute: á
                    case 0x302: tone = .falling   // circumflex: â
                    case 0x30C: tone = .rising    // caron: ǎ
                    default: break
                    }
                }
                return ToneSyllable(text: text, tone: tone)
            }
    }
}

/// A grammatical form or common pattern built on a word — like English
/// "beauty → beautiful": สวย → สวยมาก (very), ไม่สวย (not), สวยที่สุด (most).
struct WordForm {
    let thai: String
    let romanization: String
    let english: String
    let hindi: String
    let note: String
}

/// Extra learning material for selected words, keyed by `ThaiWord.id`.
/// Not every word has extras; the UI shows these sections only when present.
enum WordExtras {
    static func examples(for word: ThaiWord) -> [WordExample] {
        if let handWritten = examples[word.id] { return handWritten }
        return generatedExamples(for: word)
    }

    static func compoundNote(for word: ThaiWord) -> String? {
        compounds[word.id] ?? numberCompounds[word.id]
    }

    static func forms(for word: ThaiWord) -> [WordForm] { forms[word.id] ?? [] }

    private static let forms: [Int: [WordForm]] = [
        40: [
            WordForm(thai: "สวยมาก", romanization: "sǔai mâak", english: "very beautiful", hindi: "बहुत सुंदर", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่สวย", romanization: "mâi sǔai", english: "not beautiful", hindi: "सुंदर नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "สวยที่สุด", romanization: "sǔai thîi-sùt", english: "most beautiful", hindi: "सबसे सुंदर", note: "ที่สุด (thîi-sùt) = most / सबसे"),
        ],
    ]

    /// Template sentences for grammatically uniform categories, so every
    /// number, color, place, animal, and family word has "Sentence Use"
    /// even without a hand-written entry.
    private static func generatedExamples(for word: ThaiWord) -> [WordExample] {
        switch word.category {
        case "Numbers":
            return [
                WordExample(
                    thai: "คิวของคุณคือหมายเลข\(word.thai)",
                    romanization: "khiu khǒong khun khuue mǎai-lêek \(word.romanization)",
                    english: "Your queue number is \(word.englishMeaning).",
                    hindi: "आपका क्यू नंबर \(word.hindiMeaning) है।"),
                WordExample(
                    thai: "อันนี้\(word.thai)บาท",
                    romanization: "an-níi \(word.romanization) bàat",
                    english: "This one is \(word.englishMeaning) baht.",
                    hindi: "इसकी क़ीमत \(word.hindiMeaning) बाथ है।"),
            ]
        case "Colors" where word.id != 83:
            return [
                WordExample(
                    thai: "เสื้อตัวนี้สี\(word.thai)",
                    romanization: "sûuea tua níi sǐi \(word.romanization)",
                    english: "This shirt is \(word.englishMeaning).",
                    hindi: "यह शर्ट \(word.hindiMeaning) रंग की है।"),
                WordExample(
                    thai: "ผมชอบสี\(word.thai)",
                    romanization: "phǒm chôp sǐi \(word.romanization)",
                    english: "I like the color \(word.englishMeaning).",
                    hindi: "मुझे \(word.hindiMeaning) रंग पसंद है।"),
            ]
        case "Places":
            return [
                WordExample(
                    thai: "\(word.thai)อยู่ที่ไหน",
                    romanization: "\(word.romanization) yùu thîi-nǎi",
                    english: "Where is the \(word.englishMeaning)?",
                    hindi: "\(word.hindiMeaning) कहाँ है?"),
                WordExample(
                    thai: "\(word.thai)อยู่ใกล้ๆ",
                    romanization: "\(word.romanization) yùu klâi-klâi",
                    english: "The \(word.englishMeaning) is nearby.",
                    hindi: "\(word.hindiMeaning) पास में है।"),
            ]
        case "Animals":
            return [
                WordExample(
                    thai: "ผมเห็น\(word.thai)",
                    romanization: "phǒm hěn \(word.romanization)",
                    english: "I see a \(word.englishMeaning).",
                    hindi: "मुझे एक \(word.hindiMeaning) दिख रहा है।"),
                WordExample(
                    thai: "\(word.thai)ตัวนี้น่ารัก",
                    romanization: "\(word.romanization) tua níi nâa-rák",
                    english: "This \(word.englishMeaning) is cute.",
                    hindi: "यह \(word.hindiMeaning) प्यारा है।"),
            ]
        case "Family":
            return [
                WordExample(
                    thai: "นี่คือ\(word.thai)ของผม",
                    romanization: "nîi khuue \(word.romanization) khǒong phǒm",
                    english: "This is my \(word.englishMeaning).",
                    hindi: "यह मेरे \(word.hindiMeaning) हैं।"),
            ]
        default:
            return []
        }
    }

    /// How Thai numbers combine: X + สิบ → X-ten (60), สิบ + X → teen (16),
    /// with the two irregulars (เอ็ด for 1, ยี่ for 20).
    private static let numberCompounds: [Int: String] = [
        11: "สิบ (sìp) 10 + เอ็ด (èt) → สิบเอ็ด (sìp-èt) = 11 / ग्यारह — ध्यान दें: 11 में หนึ่ง बदलकर เอ็ด बनता है · หนึ่ง + ร้อย (rói) → หนึ่งร้อย (nèung-rói) = 100 / सौ",
        12: "สอง + สิบ → ยี่สิบ (yîi-sìp) = 20 / बीस — ध्यान दें: 20 में สอง बदलकर ยี่ बनता है · สิบ + สอง → สิบสอง (sìp-sǒong) = 12 / बारह",
        13: "สาม + สิบ → สามสิบ (sǎam-sìp) = 30 / तीस · สิบ + สาม → สิบสาม (sìp-sǎam) = 13 / तेरह",
        14: "สี่ + สิบ → สี่สิบ (sìi-sìp) = 40 / चालीस · สิบ + สี่ → สิบสี่ (sìp-sìi) = 14 / चौदह",
        15: "ห้า + สิบ → ห้าสิบ (hâa-sìp) = 50 / पचास · สิบ + ห้า → สิบห้า (sìp-hâa) = 15 / पंद्रह",
        16: "หก + สิบ → หกสิบ (hòk-sìp) = 60 / साठ · สิบ + หก → สิบหก (sìp-hòk) = 16 / सोलह",
        17: "เจ็ด + สิบ → เจ็ดสิบ (jèt-sìp) = 70 / सत्तर · สิบ + เจ็ด → สิบเจ็ด (sìp-jèt) = 17 / सत्रह",
        18: "แปด + สิบ → แปดสิบ (pàet-sìp) = 80 / अस्सी · สิบ + แปด → สิบแปด (sìp-pàet) = 18 / अठारह",
        19: "เก้า + สิบ → เก้าสิบ (kâo-sìp) = 90 / नब्बे · สิบ + เก้า → สิบเก้า (sìp-kâo) = 19 / उन्नीस",
        20: "หก + สิบ → หกสิบ (hòk-sìp) = 60 / साठ · สิบ + ห้า → สิบห้า (sìp-hâa) = 15 / पंद्रह — สิบ हर बड़ी संख्या का आधार है",
    ]

    /// Words that sound alike but mean something different — a classic
    /// Thai-learner trap (tones change the meaning).
    static func similarSounds(for word: ThaiWord) -> [ThaiWord] {
        (similar[word.id] ?? []).compactMap { id in Vocabulary.all.first { $0.id == id } }
    }

    private static let similar: [Int: [Int]] = [
        143: [144], 144: [143],          // ใกล้ near ↔ ไกล far
        32:  [137], 137: [32],           // ชา tea ↔ ช้า slow
        28:  [85],  85:  [28],           // ข้าว rice ↔ ขาว white
        36:  [156, 80], 156: [36, 80], 80: [156, 36],   // มา come ↔ หมา dog ↔ หมอ doctor
        6:   [134], 134: [6],            // ไม่ not ↔ ใหม่ new
        34:  [73],  73:  [34],           // หิว hungry ↔ หัว head
    ]

    private static let examples: [Int: [WordExample]] = [
        1: [
            WordExample(thai: "สวัสดีครับ ผมชื่อราหุล", romanization: "sà-wàt-dii kráp, phǒm chûue Rahul", english: "Hello, my name is Rahul.", hindi: "नमस्ते, मेरा नाम राहुल है।"),
            WordExample(thai: "สวัสดีตอนเช้า", romanization: "sà-wàt-dii toon cháao", english: "Good morning.", hindi: "सुप्रभात।"),
        ],
        2: [
            WordExample(thai: "ขอบคุณมากครับ", romanization: "khòp-khun mâak kráp", english: "Thank you very much.", hindi: "बहुत धन्यवाद।"),
            WordExample(thai: "ขอบคุณสำหรับอาหาร", romanization: "khòp-khun sǎm-ràp aa-hǎan", english: "Thank you for the food.", hindi: "खाने के लिए धन्यवाद।"),
        ],
        5: [
            WordExample(thai: "ใช่ ผมเป็นคนอินเดีย", romanization: "châi, phǒm pen khon in-dia", english: "Yes, I am Indian.", hindi: "हाँ, मैं भारतीय हूँ।"),
        ],
        6: [
            WordExample(thai: "ไม่เผ็ดนะ", romanization: "mâi phèt ná", english: "Not spicy, please.", hindi: "तीखा नहीं, प्लीज़।"),
            WordExample(thai: "ไม่เอาครับ", romanization: "mâi ao kráp", english: "I don't want it, thanks.", hindi: "मुझे नहीं चाहिए।"),
        ],
        8: [
            WordExample(thai: "ขอโทษครับ ห้องน้ำอยู่ที่ไหน", romanization: "khǒo-thôot kráp, hông-náam yùu thîi-nǎi", english: "Excuse me, where is the toilet?", hindi: "माफ़ कीजिए, शौचालय कहाँ है?"),
        ],
        26: [
            WordExample(thai: "อาหารไทยอร่อยมาก", romanization: "aa-hǎan thai à-ròi mâak", english: "Thai food is very delicious.", hindi: "थाई खाना बहुत स्वादिष्ट है।"),
        ],
        27: [
            WordExample(thai: "ขอน้ำหนึ่งแก้ว", romanization: "khǒo náam nèung kâew", english: "One glass of water, please.", hindi: "एक गिलास पानी दीजिए।"),
            WordExample(thai: "น้ำเย็นไหม", romanization: "náam yen mǎi", english: "Is the water cold?", hindi: "क्या पानी ठंडा है?"),
            WordExample(thai: "ผมอยากดื่มน้ำ", romanization: "phǒm yàak dùuem náam", english: "I want to drink water.", hindi: "मैं पानी पीना चाहता हूँ।"),
        ],
        29: [
            WordExample(thai: "คุณกินข้าวหรือยัง", romanization: "khun kin khâao rǔue yang", english: "Have you eaten yet?", hindi: "क्या आपने खाना खाया?"),
            WordExample(thai: "กินข้าวกันเถอะ", romanization: "kin khâao kan thòe", english: "Let's eat!", hindi: "चलो खाना खाते हैं!"),
            WordExample(thai: "ผมกินเผ็ดไม่ได้", romanization: "phǒm kin phèt mâi dâi", english: "I can't eat spicy food.", hindi: "मैं तीखा नहीं खा सकता।"),
        ],
        30: [
            WordExample(thai: "อร่อยมาก!", romanization: "à-ròi mâak!", english: "Very tasty!", hindi: "बहुत स्वादिष्ट!"),
        ],
        31: [
            WordExample(thai: "ขอกาแฟร้อนหนึ่งที่", romanization: "khǒo kaa-fae rón nèung thîi", english: "One hot coffee, please.", hindi: "एक गरम कॉफ़ी दीजिए।"),
        ],
        34: [
            WordExample(thai: "ผมหิวมาก", romanization: "phǒm hǐu mâak", english: "I am very hungry.", hindi: "मुझे बहुत भूख लगी है।"),
        ],
        35: [
            WordExample(thai: "ไปสนามบินเท่าไหร่", romanization: "pai sà-nǎam-bin thâo-rài", english: "How much to go to the airport?", hindi: "एयरपोर्ट जाने का कितना लगेगा?"),
            WordExample(thai: "ไปไหนครับ", romanization: "pai nǎi kráp", english: "Where are you going?", hindi: "कहाँ जा रहे हैं?"),
            WordExample(thai: "ผมจะไปตลาด", romanization: "phǒm jà pai tà-làat", english: "I will go to the market.", hindi: "मैं बाज़ार जाऊँगा।"),
        ],
        37: [
            WordExample(thai: "ผมรักเมืองไทย", romanization: "phǒm rák mueang-thai", english: "I love Thailand.", hindi: "मुझे थाईलैंड से प्यार है।"),
        ],
        45: [
            WordExample(thai: "ห้องน้ำอยู่ที่ไหน", romanization: "hông-náam yùu thîi-nǎi", english: "Where is the toilet?", hindi: "शौचालय कहाँ है?"),
            WordExample(thai: "ขอใช้ห้องน้ำได้ไหม", romanization: "khǒo chái hông-náam dâi mǎi", english: "May I use the bathroom?", hindi: "क्या मैं शौचालय इस्तेमाल कर सकता हूँ?"),
        ],
        48: [
            WordExample(thai: "อันนี้เท่าไหร่", romanization: "an-níi thâo-rài", english: "How much is this one?", hindi: "यह कितने का है?"),
            WordExample(thai: "ค่ารถเท่าไหร่", romanization: "khâa rót thâo-rài", english: "How much is the fare?", hindi: "किराया कितना है?"),
        ],
        49: [
            WordExample(thai: "แพงไป ลดได้ไหม", romanization: "phaeng pai, lót dâi mǎi", english: "Too expensive — can you lower it?", hindi: "बहुत महँगा है, कम कर सकते हैं?"),
        ],
        109: [
            WordExample(thai: "ผมไม่มีเงินสด", romanization: "phǒm mâi mii ngoen sòt", english: "I don't have cash.", hindi: "मेरे पास नकद नहीं है।"),
            WordExample(thai: "แลกเงินที่ไหน", romanization: "lâek ngoen thîi-nǎi", english: "Where can I exchange money?", hindi: "पैसे कहाँ बदल सकते हैं?"),
        ],
        111: [
            WordExample(thai: "อยากซื้ออันนี้", romanization: "yàak súue an-níi", english: "I want to buy this.", hindi: "मैं यह खरीदना चाहता हूँ।"),
        ],
        115: [
            WordExample(thai: "พูดช้าๆ ได้ไหม", romanization: "phûut cháa-cháa dâi mǎi", english: "Can you speak slowly?", hindi: "धीरे-धीरे बोल सकते हैं?"),
        ],
        126: [
            WordExample(thai: "ผมไม่เข้าใจ", romanization: "phǒm mâi khâo-jai", english: "I don't understand.", hindi: "मैं नहीं समझा।"),
            WordExample(thai: "เข้าใจแล้ว", romanization: "khâo-jai láew", english: "I understand now.", hindi: "अब समझ गया।"),
        ],
        129: [
            WordExample(thai: "ช่วยผมหน่อยได้ไหม", romanization: "chûai phǒm nòi dâi mǎi", english: "Can you help me?", hindi: "क्या आप मेरी मदद कर सकते हैं?"),
        ],
        145: [
            WordExample(thai: "นี่คืออะไร", romanization: "nîi khuue à-rai", english: "What is this?", hindi: "यह क्या है?"),
        ],
        146: [
            WordExample(thai: "โรงแรมอยู่ที่ไหน", romanization: "roong-raem yùu thîi-nǎi", english: "Where is the hotel?", hindi: "होटल कहाँ है?"),
        ],
        170: [
            WordExample(thai: "ช่วยด้วย!", romanization: "chûai-dûai!", english: "Help!", hindi: "बचाओ!"),
        ],
    ]

    // How the word combines with (or is built from) other words.
    private static let compounds: [Int: String] = [
        7:   "ไม่ (mâi) not / नहीं + เป็น (pen) to be / होना + ไร (rai) anything / कुछ → \"it is nothing\" = no problem / कोई बात नहीं",
        27:  "น้ำ mixes into many words: ห้อง (hông) room + น้ำ → ห้องน้ำ toilet / शौचालय · น้ำ + ตาล (taan) palm → น้ำตาล sugar / चीनी · น้ำ + แข็ง (khǎeng) hard → น้ำแข็ง ice / बर्फ़",
        28:  "ข้าว + ผัด (phàt) stir-fry / भूनना → ข้าวผัด fried rice / फ्राइड राइस",
        45:  "ห้อง (hông) room / कमरा + น้ำ (náam) water / पानी → \"water room\" = toilet / शौचालय",
        46:  "โรง (roong) building / भवन + แรม (raem) to stay overnight / रात बिताना → hotel / होटल",
        51:  "วัน (wan) day / दिन + นี้ (níi) this / यह → \"this day\" = today / आज",
        52:  "พรุ่ง (phrûng) next morning + นี้ (níi) this / यह → tomorrow / आने वाला कल",
        59:  "กลาง (klaang) middle / बीच + คืน (khuen) night / रात → nighttime / रात का समय",
        82:  "โรง (roong) building / भवन + พยาบาล (phá-yaa-baan) nursing care / देखभाल → hospital / अस्पताल",
        95:  "ต้น (tôn) trunk / तना + ไม้ (mái) wood / लकड़ी → tree / पेड़",
        96:  "ดอก (dòk) blossom / फूल + ไม้ (mái) wood / लकड़ी → flower / फूल",
        101: "ร้าน (ráan) shop / दुकान + อาหาร (aa-hǎan) food / खाना → restaurant / रेस्टोरेंट",
        102: "โรง (roong) building / भवन + เรียน (rian) to study / पढ़ना → school / स्कूल",
        104: "สนาม (sà-nǎam) field / मैदान + บิน (bin) to fly / उड़ना → \"flying field\" = airport / हवाई अड्डा",
        113: "ลด (lót) reduce / घटाना + ราคา (raa-khaa) price / क़ीमत → discount / छूट",
        123: "ทำ (tham) to do / करना + งาน (ngaan) work / काम → to work / काम करना",
        161: "ผล (phǒn) fruit, result / फल + ไม้ (mái) wood, plant / पेड़ → fruit / फल",
        166: "น้ำ (náam) water / पानी + ตาล (taan) palm tree / ताड़ → \"palm water\" = sugar / चीनी",
        170: "ช่วย (chûai) help / मदद + ด้วย (dûai) please, too / भी → \"help me please!\" = emergency cry / बचाओ!",
        177: "ตรง (trong) straight / सीधा + ไป (pai) go / जाना → go straight ahead / सीधे जाइए",
        180: "ข้าง (khâang) side / तरफ़ + บน (bon) top / ऊपर → upstairs, above / ऊपर की ओर",
        181: "ข้าง (khâang) side / तरफ़ + ล่าง (lâang) bottom / नीचे → downstairs, below / नीचे की ओर",
    ]
}
