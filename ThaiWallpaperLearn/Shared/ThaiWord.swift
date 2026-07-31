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
        1: [
            WordForm(thai: "สวัสดีครับ", romanization: "sà-wàt-dii kráp", english: "hello (male speaker, polite)", hindi: "नमस्ते (पुरुष, विनम्र)", note: "ครับ (kráp) = polite ending for men / पुरुषों के लिए विनम्र शब्द"),
            WordForm(thai: "สวัสดีค่ะ", romanization: "sà-wàt-dii khâ", english: "hello (female speaker, polite)", hindi: "नमस्ते (स्त्री, विनम्र)", note: "ค่ะ (khâ) = polite ending for women / स्त्रियों के लिए विनम्र शब्द"),
        ],
        2: [
            WordForm(thai: "ขอบคุณมาก", romanization: "khòp-khun mâak", english: "thank you very much", hindi: "बहुत-बहुत धन्यवाद", note: "มาก (mâak) = very much / बहुत"),
            WordForm(thai: "ขอบคุณครับ", romanization: "khòp-khun kráp", english: "thank you (male speaker, polite)", hindi: "धन्यवाद (पुरुष, विनम्र)", note: "ครับ (kráp) = polite particle for men / पुरुषों का विनम्र शब्द"),
            WordForm(thai: "ขอบคุณค่ะ", romanization: "khòp-khun khâ", english: "thank you (female speaker, polite)", hindi: "धन्यवाद (स्त्री, विनम्र)", note: "ค่ะ (khâ) = polite particle for women / स्त्रियों का विनम्र शब्द"),
        ],
        5: [
            WordForm(thai: "ไม่ใช่", romanization: "mâi-châi", english: "no / not so", hindi: "नहीं / ऐसा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ใช่ไหม", romanization: "châi-mǎi", english: "right? / isn't it?", hindi: "है ना?", note: "ไหม (mǎi) = question particle / प्रश्न कण"),
        ],
        6: [
            WordForm(thai: "ไม่ใช่", romanization: "mâi-châi", english: "no / that's not it", hindi: "नहीं, ऐसा नहीं है", note: "ใช่ (châi) = yes / हाँ; ไม่ + ใช่ = not so / ऐसा नहीं"),
            WordForm(thai: "ไม่เป็นไร", romanization: "mâi-pen-rai", english: "it's okay / no problem", hindi: "कोई बात नहीं", note: "เป็นไร (pen-rai) = be anything; ไม่เป็นไร = no problem / कोई बात नहीं"),
        ],
        7: [
            WordForm(thai: "ไม่เป็นไรครับ", romanization: "mâi-pen-rai kráp", english: "no problem (male speaker, polite)", hindi: "कोई बात नहीं (पुरुष, विनम्र)", note: "ครับ (kráp) = polite ending for men / पुरुषों के लिए विनम्र शब्द"),
            WordForm(thai: "ไม่เป็นไรค่ะ", romanization: "mâi-pen-rai khâ", english: "no problem (female speaker, polite)", hindi: "कोई बात नहीं (स्त्री, विनम्र)", note: "ค่ะ (khâ) = polite ending for women / स्त्रियों के लिए विनम्र शब्द"),
        ],
        8: [
            WordForm(thai: "ขอโทษครับ", romanization: "khǒo-thôot kráp", english: "sorry (male speaker, polite)", hindi: "माफ़ कीजिए (पुरुष, विनम्र)", note: "ครับ (kráp) = polite particle for men / पुरुषों का विनम्र शब्द"),
            WordForm(thai: "ขอโทษนะ", romanization: "khǒo-thôot ná", english: "sorry (soft, friendly)", hindi: "माफ़ करना (नरम लहजा)", note: "นะ (ná) = softening particle / लहजा नरम करने वाला शब्द"),
            WordForm(thai: "ขอโทษจริงๆ", romanization: "khǒo-thôot jing-jing", english: "I'm really sorry", hindi: "सच में माफ़ी चाहता/चाहती हूँ", note: "จริงๆ (jing-jing) = really / सच में"),
        ],
        9: [
            WordForm(thai: "สบายดี", romanization: "sà-baai-dii", english: "I'm fine", hindi: "मैं ठीक हूँ", note: "drop ไหม (mǎi) to turn the question into the answer / ไหม (mǎi) हटाने से सवाल जवाब बन जाता है"),
            WordForm(thai: "ไม่ค่อยสบาย", romanization: "mâi khôi sà-baai", english: "not so well / a bit unwell", hindi: "ज़्यादा ठीक नहीं हूँ", note: "ไม่ค่อย (mâi khôi) = not very / ज़्यादा नहीं"),
        ],
        10: [
            WordForm(thai: "สบายดีไหม", romanization: "sà-baai-dii mǎi", english: "How are you? / Are you well?", hindi: "आप कैसे हैं?", note: "ไหม (mǎi) = question particle / प्रश्न कण"),
            WordForm(thai: "สบายดีค่ะ", romanization: "sà-baai-dii khâ", english: "I'm fine (polite, female speaker)", hindi: "मैं ठीक हूँ (विनम्र, स्त्री)", note: "ค่ะ (khâ) = polite particle (female) / आदरसूचक शब्द (स्त्री)"),
        ],
        11: [
            WordForm(thai: "ที่หนึ่ง", romanization: "thîi-nèung", english: "first / number one", hindi: "पहला / नंबर एक", note: "ที่ (thîi) = ordinal marker / क्रम-सूचक (पहला बनाता है)"),
            WordForm(thai: "หนึ่งครั้ง", romanization: "nèung-khráng", english: "one time / once", hindi: "एक बार", note: "ครั้ง (khráng) = time, occasion / बार"),
        ],
        12: [
            WordForm(thai: "สองคน", romanization: "sǒong-khon", english: "two people", hindi: "दो लोग", note: "คน (khon) = person (classifier) / व्यक्ति (गिनती शब्द)"),
            WordForm(thai: "สองร้อย", romanization: "sǒong-róoi", english: "two hundred", hindi: "दो सौ", note: "ร้อย (róoi) = hundred / सौ"),
        ],
        13: [
            WordForm(thai: "สามสิบ", romanization: "sǎam-sìp", english: "thirty", hindi: "तीस", note: "สิบ (sìp) = ten; number + สิบ = tens / संख्या + สิบ = दहाई"),
            WordForm(thai: "สามร้อย", romanization: "sǎam-rói", english: "three hundred", hindi: "तीन सौ", note: "ร้อย (rói) = hundred / सौ"),
        ],
        14: [
            WordForm(thai: "สิบสี่", romanization: "sìp-sìi", english: "fourteen", hindi: "चौदह", note: "สิบ (sìp) + สี่ = 10 + 4 / दस + चार"),
            WordForm(thai: "สี่สิบ", romanization: "sìi-sìp", english: "forty", hindi: "चालीस", note: "สี่ + สิบ (sìp) = 4 × 10 / चार × दस"),
        ],
        15: [
            WordForm(thai: "ห้าสิบ", romanization: "hâa-sìp", english: "fifty", hindi: "पचास", note: "สิบ (sìp) = ten; five-ten = 50 / สิบ (sìp) = दस; पाँच-दस = ५०"),
            WordForm(thai: "สิบห้า", romanization: "sìp-hâa", english: "fifteen", hindi: "पंद्रह", note: "สิบ (sìp) = ten; ten-five = 15 / दस-पाँच = १५"),
        ],
        16: [
            WordForm(thai: "หกสิบ", romanization: "hòk-sìp", english: "sixty", hindi: "साठ", note: "สิบ (sìp) = ten / दस"),
            WordForm(thai: "หกโมงเย็น", romanization: "hòk moong yen", english: "six o'clock in the evening (6 pm)", hindi: "शाम के छह बजे", note: "โมงเย็น (moong yen) = o'clock in the evening / शाम के बजे"),
        ],
        17: [
            WordForm(thai: "เจ็ดโมง", romanization: "jèt-moong", english: "seven o'clock (7 a.m.)", hindi: "सुबह सात बजे", note: "โมง (moong) = o'clock / बजे"),
            WordForm(thai: "เจ็ดสิบ", romanization: "jèt-sìp", english: "seventy", hindi: "सत्तर", note: "สิบ (sìp) = ten / दस"),
        ],
        18: [
            WordForm(thai: "แปดสิบ", romanization: "pàet-sìp", english: "eighty", hindi: "अस्सी", note: "สิบ (sìp) = ten / दस"),
            WordForm(thai: "แปดโมงเช้า", romanization: "pàet-moong-cháao", english: "eight in the morning (8 AM)", hindi: "सुबह आठ बजे", note: "โมงเช้า (moong-cháao) = o'clock in the morning / सुबह के बजे"),
        ],
        19: [
            WordForm(thai: "เก้าสิบ", romanization: "kâo-sìp", english: "ninety", hindi: "नब्बे", note: "สิบ (sìp) = ten; number + สิบ = tens / संख्या + สิบ = दहाई"),
            WordForm(thai: "เก้าโมง", romanization: "kâo-moong", english: "nine o'clock (9 AM)", hindi: "नौ बजे (सुबह)", note: "โมง (moong) = o'clock (daytime) / दिन के समय 'बजे'"),
        ],
        20: [
            WordForm(thai: "สิบเอ็ด", romanization: "sìp-èt", english: "eleven", hindi: "ग्यारह", note: "เอ็ด (èt) = one, special form after ten / \"एक\" का विशेष रूप दहाई के बाद"),
            WordForm(thai: "ยี่สิบ", romanization: "yîi-sìp", english: "twenty", hindi: "बीस", note: "ยี่ (yîi) = special form of \"two\" before สิบ / \"दो\" का विशेष रूप"),
        ],
        21: [
            WordForm(thai: "ของผม", romanization: "khǒong phǒm", english: "my / mine (male)", hindi: "मेरा (पुरुष)", note: "ของ (khǒong) = of / belonging to / का"),
        ],
        22: [
            WordForm(thai: "ของฉัน", romanization: "khǒong chǎn", english: "my / mine", hindi: "मेरा / मेरी", note: "ของ (khǒong) = of, possessive marker / का-की (संबंध सूचक)"),
        ],
        23: [
            WordForm(thai: "ของคุณ", romanization: "khǎawng-khun", english: "your / yours", hindi: "आपका", note: "ของ (khǎawng) = of, belonging to / का"),
            WordForm(thai: "คุณล่ะ", romanization: "khun-lâ", english: "and you?", hindi: "और आप?", note: "ล่ะ (lâ) = 'what about…?' particle / 'और…?' कण"),
        ],
        24: [
            WordForm(thai: "เพื่อนสนิท", romanization: "phûean-sà-nìt", english: "close friend", hindi: "घनिष्ठ दोस्त", note: "สนิท (sà-nìt) = close / क़रीबी"),
            WordForm(thai: "เพื่อนร่วมงาน", romanization: "phûean-rûam-ngaan", english: "colleague / co-worker", hindi: "सहकर्मी", note: "ร่วมงาน (rûam-ngaan) = work together / साथ काम करना"),
        ],
        25: [
            WordForm(thai: "ครอบครัวของฉัน", romanization: "khrôp-khrua khǒong chǎn", english: "my family", hindi: "मेरा परिवार", note: "ของ (khǒong) = of / possessive marker / का, की (संबंध सूचक)"),
        ],
        26: [
            WordForm(thai: "อาหารไทย", romanization: "aa-hǎan thai", english: "Thai food", hindi: "थाई खाना", note: "ไทย (thai) = Thai / थाई"),
            WordForm(thai: "อาหารเช้า", romanization: "aa-hǎan cháao", english: "breakfast", hindi: "नाश्ता", note: "เช้า (cháao) = morning / सुबह"),
        ],
        27: [
            WordForm(thai: "น้ำเปล่า", romanization: "náam-plàao", english: "plain water", hindi: "सादा पानी", note: "เปล่า (plàao) = plain / सादा"),
            WordForm(thai: "น้ำแข็ง", romanization: "náam-khǎeng", english: "ice", hindi: "बर्फ़", note: "แข็ง (khǎeng) = hard; 'hard water' = ice / แข็ง (khǎeng) = कठोर"),
        ],
        28: [
            WordForm(thai: "กินข้าว", romanization: "kin khâao", english: "to eat (a meal)", hindi: "खाना खाना", note: "กิน (kin) = to eat / खाना"),
            WordForm(thai: "ข้าวผัด", romanization: "khâao-phàt", english: "fried rice", hindi: "फ्राइड राइस (तला हुआ चावल)", note: "ผัด (phàt) = stir-fried / तला-भुना"),
        ],
        29: [
            WordForm(thai: "กินข้าว", romanization: "kin-khâao", english: "to eat (a meal)", hindi: "खाना खाना", note: "ข้าว (khâao) = rice, meal / चावल, भोजन"),
            WordForm(thai: "กินแล้ว", romanization: "kin-láew", english: "already eaten", hindi: "खा लिया", note: "แล้ว (láew) = already / हो चुका"),
            WordForm(thai: "ไม่กิน", romanization: "mâi-kin", english: "(I) don't eat", hindi: "नहीं खाता/खाती", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "อยากกิน", romanization: "yàak-kin", english: "want to eat", hindi: "खाना चाहता/चाहती हूँ", note: "อยาก (yàak) = want to / चाहना"),
        ],
        30: [
            WordForm(thai: "อร่อยมาก", romanization: "à-ròi-mâak", english: "very delicious", hindi: "बहुत स्वादिष्ट", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่อร่อย", romanization: "mâi-à-ròi", english: "not tasty", hindi: "स्वादिष्ट नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "อร่อยไหม", romanization: "à-ròi-mǎi", english: "Is it tasty?", hindi: "क्या यह स्वादिष्ट है?", note: "ไหม (mǎi) = question particle / प्रश्न शब्द"),
            WordForm(thai: "อร่อยที่สุด", romanization: "à-ròi-thîi-sùt", english: "the most delicious", hindi: "सबसे स्वादिष्ट", note: "ที่สุด (thîi-sùt) = the most / सबसे"),
        ],
        31: [
            WordForm(thai: "กาแฟร้อน", romanization: "kaa-fae rón", english: "hot coffee", hindi: "गरम कॉफ़ी", note: "ร้อน (rón) = hot / गरम"),
            WordForm(thai: "กาแฟเย็น", romanization: "kaa-fae yen", english: "iced coffee (Thai style)", hindi: "ठंडी (आइस्ड) कॉफ़ी", note: "เย็น (yen) = cold, iced / ठंडा"),
        ],
        32: [
            WordForm(thai: "ชาร้อน", romanization: "chaa rón", english: "hot tea", hindi: "गरम चाय", note: "ร้อน (rón) = hot / गरम"),
            WordForm(thai: "ชาเย็น", romanization: "chaa yen", english: "Thai iced tea", hindi: "थाई आइस टी (ठंडी चाय)", note: "เย็น (yen) = cold, iced / ठंडा"),
        ],
        33: [
            WordForm(thai: "เผ็ดมาก", romanization: "phèt mâak", english: "very spicy", hindi: "बहुत तीखा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่เผ็ด", romanization: "mâi phèt", english: "not spicy", hindi: "तीखा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "เผ็ดไหม", romanization: "phèt mǎi?", english: "is it spicy?", hindi: "क्या यह तीखा है?", note: "ไหม (mǎi) = yes/no question particle / हाँ-ना सवाल का शब्द"),
            WordForm(thai: "เผ็ดนิดหน่อย", romanization: "phèt nít-nòi", english: "a little spicy", hindi: "थोड़ा तीखा", note: "นิดหน่อย (nít-nòi) = a little / थोड़ा"),
        ],
        34: [
            WordForm(thai: "หิวมาก", romanization: "hǐu mâak", english: "very hungry", hindi: "बहुत भूख लगी है", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่หิว", romanization: "mâi hǐu", english: "not hungry", hindi: "भूख नहीं है", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "หิวข้าว", romanization: "hǐu khâao", english: "hungry (for food)", hindi: "खाने की भूख लगी है", note: "ข้าว (khâao) = rice, food / चावल (खाना)"),
            WordForm(thai: "หิวไหม", romanization: "hǐu mǎi", english: "Are you hungry?", hindi: "क्या भूख लगी है?", note: "ไหม (mǎi) = question particle / प्रश्न कण"),
        ],
        35: [
            WordForm(thai: "จะไป", romanization: "jà-pai", english: "will go", hindi: "जाऊँगा / जाएगा", note: "จะ (jà) = will / -गा (भविष्य)"),
            WordForm(thai: "ไปแล้ว", romanization: "pai-láew", english: "already left / gone", hindi: "चला गया", note: "แล้ว (láew) = already / हो चुका"),
            WordForm(thai: "ไม่ไป", romanization: "mâi-pai", english: "not going", hindi: "नहीं जाऊँगा", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ไปไหน", romanization: "pai-nǎi", english: "where are you going?", hindi: "कहाँ जा रहे हो?", note: "ไหน (nǎi) = where / कहाँ"),
        ],
        36: [
            WordForm(thai: "มาแล้ว", romanization: "maa-láeo", english: "(has) already come / here now", hindi: "आ गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "ไม่มา", romanization: "mâi-maa", english: "doesn't come / didn't come", hindi: "नहीं आता", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "มาจากไหน", romanization: "maa-jàak-nǎi", english: "Where do you come from?", hindi: "कहाँ से आए हो?", note: "จากไหน (jàak-nǎi) = from where / कहाँ से"),
        ],
        37: [
            WordForm(thai: "ความรัก", romanization: "khwaam-rák", english: "love (noun)", hindi: "प्रेम / मोहब्बत", note: "ความ (khwaam) = noun-maker prefix / क्रिया को संज्ञा बनाने वाला उपसर्ग"),
            WordForm(thai: "น่ารัก", romanization: "nâa-rák", english: "cute / lovable", hindi: "प्यारा", note: "น่า (nâa) = worthy of, -able / '-ने योग्य' बनाने वाला उपसर्ग"),
            WordForm(thai: "รักมาก", romanization: "rák mâak", english: "to love very much", hindi: "बहुत प्यार करना", note: "มาก (mâak) = very / बहुत"),
        ],
        38: [
            WordForm(thai: "ชอบมาก", romanization: "chôp mâak", english: "(I) like it a lot", hindi: "बहुत पसंद है", note: "มาก (mâak) = very much / बहुत"),
            WordForm(thai: "ไม่ชอบ", romanization: "mâi chôp", english: "(I) don't like it", hindi: "पसंद नहीं है", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ชอบไหม", romanization: "chôp mǎi", english: "do you like it?", hindi: "क्या पसंद है?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        39: [
            WordForm(thai: "ดีมาก", romanization: "dii mâak", english: "very good", hindi: "बहुत अच्छा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ดี", romanization: "mâi dii", english: "not good / bad", hindi: "अच्छा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ดีที่สุด", romanization: "dii thîi-sùt", english: "the best", hindi: "सबसे अच्छा", note: "ที่สุด (thîi-sùt) = the most / सबसे"),
            WordForm(thai: "ดีขึ้น", romanization: "dii khûen", english: "better / improving", hindi: "बेहतर हो रहा है", note: "ขึ้น (khûen) = up, increasingly / ऊपर, और अधिक"),
        ],
        41: [
            WordForm(thai: "ใหญ่มาก", romanization: "yài-mâak", english: "very big", hindi: "बहुत बड़ा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ใหญ่กว่า", romanization: "yài-kwàa", english: "bigger (than)", hindi: "(से) बड़ा", note: "กว่า (kwàa) = more than / से ज़्यादा"),
            WordForm(thai: "ใหญ่ที่สุด", romanization: "yài-thîi-sùt", english: "the biggest", hindi: "सबसे बड़ा", note: "ที่สุด (thîi-sùt) = most / सबसे"),
            WordForm(thai: "ไม่ใหญ่", romanization: "mâi-yài", english: "not big", hindi: "बड़ा नहीं", note: "ไม่ (mâi) = not / नहीं"),
        ],
        42: [
            WordForm(thai: "เล็กมาก", romanization: "lék-mâak", english: "very small", hindi: "बहुत छोटा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "เล็กกว่า", romanization: "lék-kwàa", english: "smaller", hindi: "से छोटा", note: "กว่า (kwàa) = more than (comparative) / से (तुलना)"),
            WordForm(thai: "เล็กที่สุด", romanization: "lék-thîi-sùt", english: "the smallest", hindi: "सबसे छोटा", note: "ที่สุด (thîi-sùt) = the most / सबसे"),
        ],
        43: [
            WordForm(thai: "ร้อนมาก", romanization: "rón mâak", english: "very hot", hindi: "बहुत गरम", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ร้อน", romanization: "mâi rón", english: "not hot", hindi: "गरम नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ร้อนไหม", romanization: "rón mǎi", english: "is it hot?", hindi: "क्या गरम है?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        44: [
            WordForm(thai: "หนาวมาก", romanization: "nǎao mâak", english: "very cold", hindi: "बहुत ठंड है", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่หนาว", romanization: "mâi nǎao", english: "not cold", hindi: "ठंड नहीं है", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "หนาวไหม", romanization: "nǎao mǎi", english: "are you cold?", hindi: "क्या ठंड लग रही है?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        45: [
            WordForm(thai: "ห้องน้ำอยู่ที่ไหน", romanization: "hông-náam yùu thîi-nǎi?", english: "where is the toilet?", hindi: "शौचालय कहाँ है?", note: "อยู่ที่ไหน (yùu thîi-nǎi) = where is / कहाँ है"),
            WordForm(thai: "เข้าห้องน้ำ", romanization: "khâo hông-náam", english: "to use the bathroom", hindi: "शौचालय जाना", note: "เข้า (khâo) = to enter / अंदर जाना"),
        ],
        46: [
            WordForm(thai: "จองโรงแรม", romanization: "joong roong-raem", english: "to book a hotel", hindi: "होटल बुक करना", note: "จอง (joong) = to book, reserve / बुक करना"),
        ],
        47: [
            WordForm(thai: "รถติด", romanization: "rót-tìt", english: "traffic jam", hindi: "ट्रैफ़िक जाम", note: "ติด (tìt) = stuck / फँसा"),
            WordForm(thai: "รถไฟ", romanization: "rót-fai", english: "train", hindi: "रेलगाड़ी / ट्रेन", note: "ไฟ (fai) = fire → รถไฟ = train / आग → रेलगाड़ी"),
        ],
        48: [
            WordForm(thai: "ราคาเท่าไหร่", romanization: "raa-khaa-thâo-rài", english: "How much is the price?", hindi: "क़ीमत कितनी है?", note: "ราคา (raa-khaa) = price / क़ीमत"),
            WordForm(thai: "อันนี้เท่าไหร่", romanization: "an-níi-thâo-rài", english: "How much is this one?", hindi: "यह कितने का है?", note: "อันนี้ (an-níi) = this one / यह वाला"),
        ],
        49: [
            WordForm(thai: "แพงมาก", romanization: "phaeng mâak", english: "very expensive", hindi: "बहुत महँगा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่แพง", romanization: "mâi phaeng", english: "not expensive", hindi: "महँगा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "แพงเกินไป", romanization: "phaeng koen-pai", english: "too expensive", hindi: "बहुत ज़्यादा महँगा", note: "เกินไป (koen-pai) = too much / हद से ज़्यादा"),
        ],
        50: [
            WordForm(thai: "ถูกมาก", romanization: "thùuk mâak", english: "very cheap", hindi: "बहुत सस्ता", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ถูกกว่า", romanization: "thùuk kwàa", english: "cheaper", hindi: "ज़्यादा सस्ता", note: "กว่า (kwàa) = more, -er (comparison) / तुलना में ज़्यादा"),
            WordForm(thai: "ถูกที่สุด", romanization: "thùuk thîi-sùt", english: "the cheapest", hindi: "सबसे सस्ता", note: "ที่สุด (thîi-sùt) = the most / सबसे"),
        ],
        52: [
            WordForm(thai: "พรุ่งนี้เช้า", romanization: "phrûng-níi cháao", english: "tomorrow morning", hindi: "कल सुबह", note: "เช้า (cháao) = morning / सुबह"),
            WordForm(thai: "เจอกันพรุ่งนี้", romanization: "joe kan phrûng-níi", english: "see you tomorrow", hindi: "कल मिलते हैं", note: "เจอกัน (joe kan) = to meet each other / एक-दूसरे से मिलना"),
        ],
        53: [
            WordForm(thai: "เมื่อวานนี้", romanization: "mûea-waan-níi", english: "yesterday (full form)", hindi: "बीता कल", note: "นี้ (níi) = this, adds emphasis / यह (ज़ोर के लिए)"),
        ],
        54: [
            WordForm(thai: "ไม่มีเวลา", romanization: "mâi-mii-wee-laa", english: "(I) have no time", hindi: "समय नहीं है", note: "ไม่มี (mâi-mii) = don't have / नहीं है"),
            WordForm(thai: "เวลาว่าง", romanization: "wee-laa-wâang", english: "free time", hindi: "खाली समय", note: "ว่าง (wâang) = free, vacant / खाली"),
        ],
        55: [
            WordForm(thai: "กี่ชั่วโมง", romanization: "kìi chûa-moong", english: "how many hours?", hindi: "कितने घंटे?", note: "กี่ (kìi) = how many / कितने"),
            WordForm(thai: "ครึ่งชั่วโมง", romanization: "khrûeng chûa-moong", english: "half an hour", hindi: "आधा घंटा", note: "ครึ่ง (khrûeng) = half / आधा"),
        ],
        56: [
            WordForm(thai: "ห้านาที", romanization: "hâa naa-thii", english: "five minutes", hindi: "पाँच मिनट", note: "ห้า (hâa) = five / पाँच"),
            WordForm(thai: "กี่นาที", romanization: "kìi naa-thii", english: "how many minutes?", hindi: "कितने मिनट?", note: "กี่ (kìi) = how many / कितने"),
        ],
        57: [
            WordForm(thai: "ตอนเช้า", romanization: "toon-cháao", english: "in the morning", hindi: "सुबह के समय", note: "ตอน (toon) = period of time / समय"),
            WordForm(thai: "เช้านี้", romanization: "cháao-níi", english: "this morning", hindi: "आज सुबह", note: "นี้ (níi) = this / यह"),
        ],
        58: [
            WordForm(thai: "ตอนเย็น", romanization: "toon yen", english: "in the evening", hindi: "शाम को", note: "ตอน (toon) = period of time / समय (के दौरान)"),
            WordForm(thai: "เย็นนี้", romanization: "yen níi", english: "this evening", hindi: "आज शाम", note: "นี้ (níi) = this / यह"),
        ],
        59: [
            WordForm(thai: "ตอนกลางคืน", romanization: "taawn-klaang-khuen", english: "at night", hindi: "रात में / रात के समय", note: "ตอน (taawn) = during, at / के समय"),
        ],
        60: [
            WordForm(thai: "ปีนี้", romanization: "pii-níi", english: "this year", hindi: "इस साल", note: "นี้ (níi) = this / यह"),
            WordForm(thai: "ปีหน้า", romanization: "pii-nâa", english: "next year", hindi: "अगले साल", note: "หน้า (nâa) = next / अगला"),
        ],
        61: [
            WordForm(thai: "เดือนนี้", romanization: "duean níi", english: "this month", hindi: "इस महीने", note: "นี้ (níi) = this / यह"),
            WordForm(thai: "เดือนหน้า", romanization: "duean nâa", english: "next month", hindi: "अगले महीने", note: "หน้า (nâa) = next / अगला"),
        ],
        62: [
            WordForm(thai: "สัปดาห์หน้า", romanization: "sàp-daa nâa", english: "next week", hindi: "अगला सप्ताह", note: "หน้า (nâa) = next / अगला"),
            WordForm(thai: "สัปดาห์ที่แล้ว", romanization: "sàp-daa thîi-láeo", english: "last week", hindi: "पिछला सप्ताह", note: "ที่แล้ว (thîi-láeo) = last, previous / पिछला"),
        ],
        63: [
            WordForm(thai: "คุณพ่อ", romanization: "khun-phôo", english: "father (polite)", hindi: "पिताजी", note: "คุณ (khun) = polite title / आदरसूचक शब्द"),
            WordForm(thai: "พ่อแม่", romanization: "phôo-mâe", english: "parents", hindi: "माता-पिता", note: "แม่ (mâe) = mother; father + mother = parents / แม่ (mâe) = माँ"),
        ],
        64: [
            WordForm(thai: "คุณแม่", romanization: "khun mâe", english: "mother (polite)", hindi: "माता जी", note: "คุณ (khun) = polite title / आदरसूचक उपाधि (जी)"),
        ],
        65: [
            WordForm(thai: "ลูกชาย", romanization: "lûuk-chaai", english: "son", hindi: "बेटा", note: "ชาย (chaai) = male / पुरुष"),
            WordForm(thai: "ลูกสาว", romanization: "lûuk-sǎao", english: "daughter", hindi: "बेटी", note: "สาว (sǎao) = girl, female / लड़की"),
        ],
        66: [
            WordForm(thai: "พี่ชาย", romanization: "phîi-chaai", english: "older brother", hindi: "बड़ा भाई", note: "ชาย (chaai) = male / पुरुष"),
            WordForm(thai: "พี่สาว", romanization: "phîi-sǎao", english: "older sister", hindi: "बड़ी बहन", note: "สาว (sǎao) = young woman, female / युवती, स्त्री"),
        ],
        67: [
            WordForm(thai: "น้องชาย", romanization: "nóong-chaai", english: "younger brother", hindi: "छोटा भाई", note: "ชาย (chaai) = male / पुरुष"),
            WordForm(thai: "น้องสาว", romanization: "nóong-sǎao", english: "younger sister", hindi: "छोटी बहन", note: "สาว (sǎao) = female, young woman / स्त्री"),
        ],
        68: [
            WordForm(thai: "ผู้ชายคนนั้น", romanization: "phûu-chaai khon nán", english: "that man", hindi: "वह आदमी", note: "คน (khon) = classifier for people + นั้น (nán) = that / लोगों का classifier + वह"),
        ],
        69: [
            WordForm(thai: "ห้องน้ำผู้หญิง", romanization: "hông-náam phûu-yǐng", english: "women's restroom", hindi: "महिला शौचालय", note: "ห้องน้ำ (hông-náam) = toilet / शौचालय"),
        ],
        70: [
            WordForm(thai: "เด็กๆ", romanization: "dèk-dèk", english: "children / kids", hindi: "बच्चे", note: "ๆ = repetition mark (plural feel) / दोहराव चिह्न (बहुवचन भाव)"),
            WordForm(thai: "เด็กผู้ชาย", romanization: "dèk phûu-chaai", english: "boy", hindi: "लड़का", note: "ผู้ชาย (phûu-chaai) = male / पुरुष"),
        ],
        71: [
            WordForm(thai: "ชื่ออะไร", romanization: "chûue-à-rai", english: "what's (your) name?", hindi: "नाम क्या है?", note: "อะไร (à-rai) = what / क्या"),
            WordForm(thai: "ชื่อเล่น", romanization: "chûue-lên", english: "nickname", hindi: "उपनाम / निकनेम", note: "เล่น (lên) = play → nickname / खेल → निकनेम"),
        ],
        72: [
            WordForm(thai: "คุณครู", romanization: "khun-khruu", english: "teacher (polite address)", hindi: "शिक्षक जी (आदरपूर्वक)", note: "คุณ (khun) = polite title / आदरसूचक शब्द"),
        ],
        73: [
            WordForm(thai: "ปวดหัว", romanization: "pùat hǔa", english: "to have a headache", hindi: "सिरदर्द होना", note: "ปวด (pùat) = to ache / दर्द होना"),
            WordForm(thai: "หัวใจ", romanization: "hǔa-jai", english: "heart (organ)", hindi: "हृदय / दिल", note: "ใจ (jai) = heart, mind / दिल; หัว + ใจ = हृदय"),
        ],
        74: [
            WordForm(thai: "ปวดตา", romanization: "pùat taa", english: "(my) eyes hurt", hindi: "आँखों में दर्द है", note: "ปวด (pùat) = to ache / दर्द होना"),
        ],
        75: [
            WordForm(thai: "ล้างมือ", romanization: "láang muue", english: "to wash one's hands", hindi: "हाथ धोना", note: "ล้าง (láang) = to wash / धोना"),
            WordForm(thai: "มือถือ", romanization: "muue-thǔue", english: "mobile phone", hindi: "मोबाइल फ़ोन", note: "ถือ (thǔue) = to hold; 'hand-held' / पकड़ना"),
        ],
        76: [
            WordForm(thai: "ใจดี", romanization: "jai-dii", english: "kind, kind-hearted", hindi: "दयालु", note: "ดี (dii) = good / अच्छा; ใจ + ดี = kind / दयालु"),
            WordForm(thai: "ดีใจ", romanization: "dii-jai", english: "glad, happy", hindi: "खुश", note: "reversed order ดี + ใจ = glad / उल्टा क्रम: खुश"),
        ],
        77: [
            WordForm(thai: "แปรงฟัน", romanization: "praeng-fan", english: "to brush one's teeth", hindi: "दाँत ब्रश करना", note: "แปรง (praeng) = to brush / ब्रश करना"),
            WordForm(thai: "ปวดฟัน", romanization: "pùat-fan", english: "toothache", hindi: "दाँत में दर्द", note: "ปวด (pùat) = to ache / दर्द होना"),
        ],
        78: [
            WordForm(thai: "ปวดหัว", romanization: "pùat-hǔa", english: "to have a headache", hindi: "सिरदर्द होना", note: "หัว (hǔa) = head / सिर"),
            WordForm(thai: "ปวดท้อง", romanization: "pùat-thóong", english: "to have a stomachache", hindi: "पेट दर्द होना", note: "ท้อง (thóong) = stomach / पेट"),
            WordForm(thai: "ปวดมาก", romanization: "pùat-mâak", english: "it hurts a lot", hindi: "बहुत दर्द है", note: "มาก (mâak) = very / बहुत"),
        ],
        79: [
            WordForm(thai: "ป่วยหนัก", romanization: "pùai nàk", english: "seriously ill", hindi: "गंभीर रूप से बीमार", note: "หนัก (nàk) = heavy, severely / गंभीर, भारी"),
            WordForm(thai: "ป่วยไหม", romanization: "pùai mǎi", english: "are you sick?", hindi: "क्या तुम बीमार हो?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        80: [
            WordForm(thai: "ไปหาหมอ", romanization: "pai hǎa mǒo", english: "to go see a doctor", hindi: "डॉक्टर के पास जाना", note: "ไปหา (pai hǎa) = to go see (someone) / किसी से मिलने जाना"),
            WordForm(thai: "หมอฟัน", romanization: "mǒo fan", english: "dentist", hindi: "दाँतों का डॉक्टर", note: "ฟัน (fan) = tooth / दाँत"),
        ],
        81: [
            WordForm(thai: "กินยา", romanization: "kin yaa", english: "to take medicine", hindi: "दवा लेना", note: "กิน (kin) = to eat, take / खाना, लेना"),
            WordForm(thai: "ร้านขายยา", romanization: "ráan-khǎai-yaa", english: "pharmacy", hindi: "दवा की दुकान", note: "ร้านขาย (ráan-khǎai) = shop that sells / बेचने वाली दुकान"),
        ],
        82: [
            WordForm(thai: "ไปโรงพยาบาล", romanization: "pai roong-phá-yaa-baan", english: "to go to the hospital", hindi: "अस्पताल जाना", note: "ไป (pai) = to go / जाना"),
        ],
        83: [
            WordForm(thai: "สีอะไร", romanization: "sǐi-à-rai", english: "what color?", hindi: "कौन सा रंग?", note: "อะไร (à-rai) = what / क्या"),
        ],
        84: [
            WordForm(thai: "สีแดง", romanization: "sǐi-daeng", english: "red color / red", hindi: "लाल रंग", note: "สี (sǐi) = color / रंग"),
        ],
        85: [
            WordForm(thai: "สีขาว", romanization: "sǐi khǎao", english: "white color", hindi: "सफ़ेद रंग", note: "สี (sǐi) = color / रंग"),
        ],
        86: [
            WordForm(thai: "สีดำ", romanization: "sǐi dam", english: "black (the color)", hindi: "काला रंग", note: "สี (sǐi) = color / रंग"),
            WordForm(thai: "กาแฟดำ", romanization: "kaa-fae dam", english: "black coffee", hindi: "ब्लैक कॉफ़ी", note: "กาแฟ (kaa-fae) = coffee / कॉफ़ी"),
        ],
        87: [
            WordForm(thai: "สีเขียว", romanization: "sǐi khǐao", english: "green (the color)", hindi: "हरा रंग", note: "สี (sǐi) = color / रंग"),
            WordForm(thai: "ไฟเขียว", romanization: "fai khǐao", english: "green light", hindi: "हरी बत्ती", note: "ไฟ (fai) = light / बत्ती"),
        ],
        88: [
            WordForm(thai: "สีฟ้า", romanization: "sǐi fáa", english: "sky-blue (color)", hindi: "आसमानी रंग", note: "สี (sǐi) = color / रंग"),
            WordForm(thai: "ท้องฟ้า", romanization: "thóong-fáa", english: "the sky", hindi: "आसमान", note: "ท้อง (thóong) + ฟ้า = the sky / आसमान"),
        ],
        89: [
            WordForm(thai: "สีเหลือง", romanization: "sǐi-lǔeang", english: "yellow (the color)", hindi: "पीला रंग", note: "สี (sǐi) = color / रंग"),
            WordForm(thai: "สีเหลืองอ่อน", romanization: "sǐi-lǔeang-àawn", english: "light yellow", hindi: "हल्का पीला", note: "อ่อน (àawn) = light, pale / हल्का"),
        ],
        90: [
            WordForm(thai: "ฝนตก", romanization: "fǒn-tòk", english: "it's raining", hindi: "बारिश हो रही है", note: "ตก (tòk) = to fall / गिरना"),
            WordForm(thai: "ฝนตกหนัก", romanization: "fǒn-tòk-nàk", english: "it's raining heavily", hindi: "तेज़ बारिश हो रही है", note: "หนัก (nàk) = heavy / भारी, तेज़"),
        ],
        91: [
            WordForm(thai: "แดดแรง", romanization: "dàet raeng", english: "strong sunshine", hindi: "तेज़ धूप", note: "แรง (raeng) = strong / तेज़"),
            WordForm(thai: "แดดออก", romanization: "dàet òok", english: "the sun is out / it's sunny", hindi: "धूप निकली है", note: "ออก (òok) = to come out / निकलना"),
        ],
        92: [
            WordForm(thai: "ลมแรง", romanization: "lom raeng", english: "strong wind", hindi: "तेज़ हवा", note: "แรง (raeng) = strong / तेज़"),
            WordForm(thai: "ลมเย็น", romanization: "lom yen", english: "cool breeze", hindi: "ठंडी हवा", note: "เย็น (yen) = cool / ठंडा"),
        ],
        93: [
            WordForm(thai: "ไปทะเล", romanization: "pai thá-lee", english: "to go to the sea / beach", hindi: "समुद्र जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "อาหารทะเล", romanization: "aa-hǎan thá-lee", english: "seafood", hindi: "समुद्री भोजन", note: "อาหาร (aa-hǎan) = food / भोजन"),
        ],
        94: [
            WordForm(thai: "ภูเขาไฟ", romanization: "phuu-khǎo-fai", english: "volcano", hindi: "ज्वालामुखी", note: "ไฟ (fai) = fire / आग"),
        ],
        95: [
            WordForm(thai: "ปลูกต้นไม้", romanization: "plùuk-tôn-mái", english: "to plant a tree", hindi: "पेड़ लगाना", note: "ปลูก (plùuk) = to plant / लगाना, उगाना"),
        ],
        96: [
            WordForm(thai: "ดอกไม้สวย", romanization: "dòk-mái-sǔai", english: "beautiful flowers", hindi: "सुंदर फूल", note: "สวย (sǔai) = beautiful / सुंदर"),
        ],
        97: [
            WordForm(thai: "อากาศดี", romanization: "aa-kàat dii", english: "nice weather", hindi: "अच्छा मौसम", note: "ดี (dii) = good / अच्छा"),
            WordForm(thai: "อากาศร้อน", romanization: "aa-kàat rón", english: "hot weather", hindi: "गरम मौसम", note: "ร้อน (rón) = hot / गरम"),
        ],
        98: [
            WordForm(thai: "กลับบ้าน", romanization: "klàp bâan", english: "to go home", hindi: "घर लौटना", note: "กลับ (klàp) = to return / लौटना"),
            WordForm(thai: "อยู่บ้าน", romanization: "yùu bâan", english: "to stay at home", hindi: "घर पर रहना", note: "อยู่ (yùu) = to stay, be at / रहना"),
        ],
        99: [
            WordForm(thai: "ไปตลาด", romanization: "pai tà-làat", english: "to go to the market", hindi: "बाज़ार जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "ตลาดนัด", romanization: "tà-làat-nát", english: "flea / weekend market", hindi: "साप्ताहिक बाज़ार", note: "นัด (nát) = appointed time; a pop-up market / नियत समय"),
        ],
        100: [
            WordForm(thai: "ร้านอาหาร", romanization: "ráan-aa-hǎan", english: "restaurant", hindi: "रेस्टोरेंट (भोजनालय)", note: "อาหาร (aa-hǎan) = food / खाना"),
            WordForm(thai: "ร้านกาแฟ", romanization: "ráan-kaa-fae", english: "coffee shop / café", hindi: "कॉफ़ी की दुकान", note: "กาแฟ (kaa-fae) = coffee / कॉफ़ी"),
        ],
        101: [
            WordForm(thai: "ร้านอาหารไทย", romanization: "ráan-aa-hǎan-thai", english: "Thai restaurant", hindi: "थाई रेस्टोरेंट", note: "ไทย (thai) = Thai / थाई"),
        ],
        102: [
            WordForm(thai: "ไปโรงเรียน", romanization: "pai-roong-rian", english: "to go to school", hindi: "स्कूल जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "ที่โรงเรียน", romanization: "thîi-roong-rian", english: "at school", hindi: "स्कूल में", note: "ที่ (thîi) = at / पर, में"),
        ],
        103: [
            WordForm(thai: "ไปวัด", romanization: "pai wát", english: "to go to the temple", hindi: "मंदिर जाना", note: "ไป (pai) = to go / जाना"),
        ],
        104: [
            WordForm(thai: "ไปสนามบิน", romanization: "pai sà-nǎam-bin", english: "to go to the airport", hindi: "हवाई अड्डे जाना", note: "ไป (pai) = to go / जाना"),
        ],
        105: [
            WordForm(thai: "ไปธนาคาร", romanization: "pai thá-naa-khaan", english: "to go to the bank", hindi: "बैंक जाना", note: "ไป (pai) = to go / जाना"),
        ],
        106: [
            WordForm(thai: "ข้ามถนน", romanization: "khâam thà-nǒn", english: "to cross the road", hindi: "सड़क पार करना", note: "ข้าม (khâam) = to cross / पार करना"),
        ],
        107: [
            WordForm(thai: "ในเมือง", romanization: "nai-mueang", english: "in town / downtown", hindi: "शहर में", note: "ใน (nai) = in / में"),
            WordForm(thai: "เมืองไทย", romanization: "mueang-thai", english: "Thailand (colloquial)", hindi: "थाईलैंड (बोलचाल)", note: "ไทย (thai) = Thai → Thailand / थाई → थाईलैंड"),
        ],
        108: [
            WordForm(thai: "ประเทศไทย", romanization: "prà-thêet-thai", english: "Thailand", hindi: "थाईलैंड", note: "ไทย (thai) = Thai / थाई"),
            WordForm(thai: "ต่างประเทศ", romanization: "tàang-prà-thêet", english: "abroad / foreign country", hindi: "विदेश", note: "ต่าง (tàang) = different, foreign / अलग, विदेशी"),
        ],
        109: [
            WordForm(thai: "ไม่มีเงิน", romanization: "mâi mii ngoen", english: "to have no money", hindi: "पैसे नहीं हैं", note: "ไม่มี (mâi mii) = to not have / नहीं होना"),
            WordForm(thai: "เงินทอน", romanization: "ngoen thoon", english: "change (money returned)", hindi: "खुले पैसे / बाकी", note: "ทอน (thoon) = to give change / बाकी लौटाना"),
        ],
        110: [
            WordForm(thai: "กี่บาท", romanization: "kìi bàat", english: "how many baht? (how much?)", hindi: "कितने बात? (कितना हुआ?)", note: "กี่ (kìi) = how many / कितने"),
            WordForm(thai: "ร้อยบาท", romanization: "rói bàat", english: "one hundred baht", hindi: "सौ बात", note: "ร้อย (rói) = hundred / सौ"),
        ],
        111: [
            WordForm(thai: "อยากซื้อ", romanization: "yàak súue", english: "want to buy", hindi: "खरीदना चाहता हूँ", note: "อยาก (yàak) = to want to / चाहना"),
            WordForm(thai: "ไม่ซื้อ", romanization: "mâi súue", english: "not buying", hindi: "नहीं खरीदूँगा", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ซื้อแล้ว", romanization: "súue láeo", english: "already bought", hindi: "खरीद लिया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "ซื้อของ", romanization: "súue khǒong", english: "to go shopping / buy things", hindi: "ख़रीदारी करना", note: "ของ (khǒong) = things / चीज़ें"),
        ],
        112: [
            WordForm(thai: "ขายดี", romanization: "khǎai dii", english: "sells well", hindi: "खूब बिकता है", note: "ดี (dii) = good, well / अच्छा"),
            WordForm(thai: "ขายหมดแล้ว", romanization: "khǎai mòt láew", english: "sold out", hindi: "सब बिक गया", note: "หมดแล้ว (mòt láew) = all gone already / सब खत्म हो गया"),
            WordForm(thai: "ไม่ขาย", romanization: "mâi khǎai", english: "not for sale / (I) don't sell it", hindi: "बेचना नहीं है", note: "ไม่ (mâi) = not / नहीं"),
        ],
        113: [
            WordForm(thai: "ลดราคาได้ไหม", romanization: "lót-raa-khaa-dâai-mǎi", english: "can you give a discount?", hindi: "क्या छूट मिल सकती है?", note: "ได้ไหม (dâai-mǎi) = can…? / क्या…सकते हैं?"),
            WordForm(thai: "กำลังลดราคา", romanization: "kam-lang-lót-raa-khaa", english: "on sale (right now)", hindi: "सेल चल रही है", note: "กำลัง (kam-lang) = -ing, in progress / चल रहा है"),
        ],
        114: [
            WordForm(thai: "ฟรีไหม", romanization: "frii-mǎi", english: "Is it free?", hindi: "क्या यह मुफ़्त है?", note: "ไหม (mǎi) = question particle / प्रश्न शब्द"),
            WordForm(thai: "ได้ฟรี", romanization: "dâi-frii", english: "got it for free", hindi: "मुफ़्त में मिला", note: "ได้ (dâi) = to get, receive / मिलना"),
        ],
        115: [
            WordForm(thai: "พูดช้าๆ", romanization: "phûut cháa-cháa", english: "speak slowly", hindi: "धीरे-धीरे बोलिए", note: "ช้าๆ (cháa-cháa) = slowly / धीरे-धीरे"),
            WordForm(thai: "พูดได้", romanization: "phûut dâi", english: "can speak", hindi: "बोल सकना", note: "ได้ (dâi) = can, able to / सकना"),
            WordForm(thai: "พูดอีกที", romanization: "phûut ìik thii", english: "say it again", hindi: "फिर से कहिए", note: "อีกที (ìik thii) = once more / एक बार फिर"),
        ],
        116: [
            WordForm(thai: "ฟังเพลง", romanization: "fang phleeng", english: "to listen to music", hindi: "गाना सुनना", note: "เพลง (phleeng) = song / गाना"),
            WordForm(thai: "ฟังอีกที", romanization: "fang ìik thii", english: "listen once more", hindi: "फिर से सुनना", note: "อีกที (ìik thii) = once more / एक बार और"),
            WordForm(thai: "ไม่ฟัง", romanization: "mâi fang", english: "(he/she) doesn't listen", hindi: "नहीं सुनता", note: "ไม่ (mâi) = not / नहीं"),
        ],
        117: [
            WordForm(thai: "อ่านหนังสือ", romanization: "àan nǎng-sǔue", english: "to read (a book)", hindi: "किताब पढ़ना", note: "หนังสือ (nǎng-sǔue) = book / किताब"),
            WordForm(thai: "อ่านแล้ว", romanization: "àan láeo", english: "already read (it)", hindi: "पढ़ लिया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "อ่านไม่ออก", romanization: "àan mâi òok", english: "can't read it", hindi: "पढ़ नहीं पाता", note: "ไม่ออก (mâi òok) = unable to (read/figure out) / नहीं कर पाना"),
        ],
        118: [
            WordForm(thai: "เขียนยังไง", romanization: "khǐan yang-ngai", english: "How do you write it?", hindi: "कैसे लिखते हैं?", note: "ยังไง (yang-ngai) = how / कैसे"),
            WordForm(thai: "เขียนไม่ได้", romanization: "khǐan mâi dâai", english: "can't write (it)", hindi: "लिख नहीं सकते", note: "ไม่ได้ (mâi dâai) = cannot / नहीं सकते"),
            WordForm(thai: "เขียนแล้ว", romanization: "khǐan láew", english: "already wrote (it)", hindi: "लिख दिया", note: "แล้ว (láew) = already / हो चुका"),
        ],
        119: [
            WordForm(thai: "ดูหนัง", romanization: "duu-nǎng", english: "to watch a movie", hindi: "फ़िल्म देखना", note: "หนัง (nǎng) = movie / फ़िल्म"),
            WordForm(thai: "ขอดูหน่อย", romanization: "khǎaw-duu-nòi", english: "may I have a look?", hindi: "ज़रा देखने दीजिए", note: "ขอ…หน่อย (khǎaw…nòi) = may I…, please / ज़रा…दीजिए"),
            WordForm(thai: "ดูแล้ว", romanization: "duu-láew", english: "already watched (it)", hindi: "देख लिया", note: "แล้ว (láew) = already / हो चुका"),
        ],
        120: [
            WordForm(thai: "ไปนอน", romanization: "pai-noon", english: "to go to bed", hindi: "सोने जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "นอนหลับ", romanization: "noon-làp", english: "to fall asleep / be asleep", hindi: "सो जाना", note: "หลับ (làp) = asleep / नींद में"),
            WordForm(thai: "ยังไม่นอน", romanization: "yang-mâi-noon", english: "not sleeping yet", hindi: "अभी नहीं सोया", note: "ยังไม่ (yang-mâi) = not yet / अभी नहीं"),
        ],
        121: [
            WordForm(thai: "ตื่นแล้ว", romanization: "tùuen láeo", english: "already awake / woke up already", hindi: "जाग गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "ตื่นเช้า", romanization: "tùuen cháao", english: "to wake up early", hindi: "सुबह जल्दी उठना", note: "เช้า (cháao) = morning, early / सुबह"),
            WordForm(thai: "ตื่นสาย", romanization: "tùuen sǎai", english: "to wake up late", hindi: "देर से उठना", note: "สาย (sǎai) = late (in the morning) / देर से"),
        ],
        122: [
            WordForm(thai: "ทำอะไร", romanization: "tham à-rai", english: "what are you doing?", hindi: "क्या कर रहे हो?", note: "อะไร (à-rai) = what / क्या"),
            WordForm(thai: "ทำได้", romanization: "tham dâai", english: "(I) can do it", hindi: "कर सकते हैं", note: "ได้ (dâai) = can / सकना"),
            WordForm(thai: "ทำไม่ได้", romanization: "tham mâi dâai", english: "(I) can't do it", hindi: "नहीं कर सकते", note: "ไม่ได้ (mâi dâai) = cannot / नहीं कर सकना"),
        ],
        123: [
            WordForm(thai: "ไปทำงาน", romanization: "pai tham-ngaan", english: "to go to work", hindi: "काम पर जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "ทำงานหนัก", romanization: "tham-ngaan nàk", english: "to work hard", hindi: "कड़ी मेहनत करना", note: "หนัก (nàk) = heavy, hard / भारी"),
            WordForm(thai: "ทำงานที่ไหน", romanization: "tham-ngaan thîi-nǎi?", english: "where do you work?", hindi: "कहाँ काम करते हैं?", note: "ที่ไหน (thîi-nǎi) = where / कहाँ"),
        ],
        124: [
            WordForm(thai: "เดินเล่น", romanization: "doen lên", english: "to take a stroll", hindi: "टहलना", note: "เล่น (lên) = for fun / मज़े के लिए"),
            WordForm(thai: "เดินไป", romanization: "doen pai", english: "to walk there / go on foot", hindi: "पैदल जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "เดินไม่ไหว", romanization: "doen mâi wǎi", english: "too tired to walk (anymore)", hindi: "और चला नहीं जा रहा", note: "ไม่ไหว (mâi wǎi) = can't manage, no strength left / बस की बात नहीं"),
        ],
        125: [
            WordForm(thai: "วิ่งเร็ว", romanization: "wîng-réo", english: "to run fast", hindi: "तेज़ दौड़ना", note: "เร็ว (réo) = fast / तेज़"),
            WordForm(thai: "ไปวิ่ง", romanization: "pai-wîng", english: "to go for a run", hindi: "दौड़ने जाना", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "อย่าวิ่ง", romanization: "yàa-wîng", english: "don't run!", hindi: "मत दौड़ो!", note: "อย่า (yàa) = don't / मत"),
        ],
        126: [
            WordForm(thai: "ไม่เข้าใจ", romanization: "mâi-khâo-jai", english: "(I) don't understand", hindi: "समझ नहीं आया", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "เข้าใจแล้ว", romanization: "khâo-jai-láeo", english: "(I) understand now", hindi: "अब समझ गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "เข้าใจไหม", romanization: "khâo-jai-mǎi", english: "Do you understand?", hindi: "क्या समझ आया?", note: "ไหม (mǎi) = question particle / प्रश्न शब्द"),
        ],
        127: [
            WordForm(thai: "ไม่รู้", romanization: "mâi rúu", english: "(I) don't know", hindi: "पता नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "รู้แล้ว", romanization: "rúu láeo", english: "(I) already know", hindi: "पता है / जान गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "รู้จัก", romanization: "rúu-jàk", english: "to know (a person / place)", hindi: "(किसी से) परिचित होना", note: "รู้ + จัก (jàk) = to be acquainted with / जान-पहचान होना"),
        ],
        128: [
            WordForm(thai: "คิดว่า", romanization: "khít wâa", english: "to think that...", hindi: "सोचना कि...", note: "ว่า (wâa) = that (connector) / कि"),
            WordForm(thai: "คิดถึง", romanization: "khít thǔeng", english: "to miss (someone)", hindi: "याद आना (किसी की)", note: "ถึง (thǔeng) = to, of — คิดถึง = to miss / याद करना"),
            WordForm(thai: "คิดมาก", romanization: "khít mâak", english: "to overthink, worry too much", hindi: "ज़्यादा सोचना, चिंता करना", note: "มาก (mâak) = a lot — here means overthink / बहुत"),
        ],
        129: [
            WordForm(thai: "ช่วยด้วย", romanization: "chûai dûai!", english: "help!", hindi: "बचाओ! मदद करो!", note: "ด้วย (dûai) makes it an urgent cry for help / मदद की तुरंत पुकार"),
            WordForm(thai: "ช่วยหน่อย", romanization: "chûai nòi", english: "please help me", hindi: "ज़रा मदद कीजिए", note: "หน่อย (nòi) = a little, softens the request / ज़रा"),
            WordForm(thai: "ช่วยได้ไหม", romanization: "chûai dâai mǎi?", english: "can you help?", hindi: "क्या मदद कर सकते हैं?", note: "ได้ไหม (dâai mǎi) = can you? / कर सकते हैं?"),
        ],
        130: [
            WordForm(thai: "รอสักครู่", romanization: "roo sàk-khrûu", english: "please wait a moment", hindi: "एक क्षण प्रतीक्षा कीजिए", note: "สักครู่ (sàk-khrûu) = a moment / एक पल"),
            WordForm(thai: "รอเดี๋ยวนะ", romanization: "roo dǐao ná", english: "wait a sec, okay?", hindi: "ज़रा रुको", note: "เดี๋ยว (dǐao) = a moment / ज़रा; นะ (ná) = softening particle / नरम बनाने वाला कण"),
            WordForm(thai: "รอนานไหม", romanization: "roo naan mǎi", english: "Did you wait long?", hindi: "क्या बहुत देर इंतज़ार किया?", note: "นาน (naan) = a long time / देर"),
        ],
        131: [
            WordForm(thai: "วันหยุด", romanization: "wan-yùt", english: "day off / holiday", hindi: "छुट्टी का दिन", note: "วัน (wan) = day → day off / दिन → छुट्टी"),
            WordForm(thai: "หยุดก่อน", romanization: "yùt-kàawn", english: "stop first / hold on", hindi: "ज़रा रुको", note: "ก่อน (kàawn) = first / पहले"),
            WordForm(thai: "อย่าหยุด", romanization: "yàa-yùt", english: "don't stop", hindi: "मत रुको", note: "อย่า (yàa) = don't / मत"),
        ],
        132: [
            WordForm(thai: "เปิดไฟ", romanization: "pòet-fai", english: "to turn on the light", hindi: "बत्ती जलाना", note: "ไฟ (fai) = light / बत्ती"),
            WordForm(thai: "เปิดแล้ว", romanization: "pòet-láeo", english: "already open", hindi: "खुल गया है", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "เปิดกี่โมง", romanization: "pòet-kìi-moong", english: "What time does it open?", hindi: "कितने बजे खुलता है?", note: "กี่โมง (kìi-moong) = what time / कितने बजे"),
        ],
        133: [
            WordForm(thai: "ปิดแล้ว", romanization: "pìt láeo", english: "already closed", hindi: "बंद हो गया", note: "แล้ว (láeo) = already / हो चुका"),
            WordForm(thai: "ปิดไฟ", romanization: "pìt fai", english: "to turn off the light", hindi: "बत्ती बंद करना", note: "ไฟ (fai) = light / बत्ती"),
            WordForm(thai: "ปิดประตู", romanization: "pìt prà-tuu", english: "to close the door", hindi: "दरवाज़ा बंद करना", note: "ประตู (prà-tuu) = door / दरवाज़ा"),
        ],
        134: [
            WordForm(thai: "ปีใหม่", romanization: "pii mài", english: "New Year", hindi: "नया साल", note: "ปี (pii) = year / साल"),
            WordForm(thai: "ของใหม่", romanization: "khǒong mài", english: "a new thing, brand-new item", hindi: "नई चीज़", note: "ของ (khǒong) = thing / चीज़"),
            WordForm(thai: "ทำใหม่", romanization: "tham mài", english: "to do it again, redo", hindi: "फिर से करना", note: "verb + ใหม่ = to redo / क्रिया + ใหม่ = दोबारा करना"),
        ],
        135: [
            WordForm(thai: "เก่ามาก", romanization: "kào mâak", english: "very old", hindi: "बहुत पुराना", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "เก่าแล้ว", romanization: "kào láeo", english: "old now / already old", hindi: "पुराना हो गया", note: "แล้ว (láeo) = already / हो गया"),
            WordForm(thai: "ของเก่า", romanization: "khǒong kào", english: "old things / antiques", hindi: "पुरानी चीज़ें", note: "ของ (khǒong) = things / चीज़ें"),
        ],
        136: [
            WordForm(thai: "เร็วมาก", romanization: "reo mâak", english: "very fast", hindi: "बहुत तेज़", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "เร็วๆ หน่อย", romanization: "reo-reo nòi", english: "hurry up, please!", hindi: "ज़रा जल्दी करो!", note: "หน่อย (nòi) = a bit (softens a request) / ज़रा"),
            WordForm(thai: "เร็วที่สุด", romanization: "reo thîi-sùt", english: "the fastest", hindi: "सबसे तेज़", note: "ที่สุด (thîi-sùt) = most / सबसे"),
        ],
        137: [
            WordForm(thai: "ช้า ๆ", romanization: "cháa-cháa", english: "slowly", hindi: "धीरे-धीरे", note: "ๆ (repetition) = adverb 'slowly' / दोहराव = 'धीरे-धीरे'"),
            WordForm(thai: "ช้ามาก", romanization: "cháa-mâak", english: "very slow", hindi: "बहुत धीमा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ช้าไป", romanization: "cháa-pai", english: "too slow", hindi: "ज़रूरत से ज़्यादा धीमा", note: "ไป (pai) = too, excessively / ज़रूरत से ज़्यादा"),
        ],
        138: [
            WordForm(thai: "ง่ายมาก", romanization: "ngâai-mâak", english: "very easy", hindi: "बहुत आसान", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ง่าย", romanization: "mâi-ngâai", english: "not easy", hindi: "आसान नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ง่ายกว่า", romanization: "ngâai-kwàa", english: "easier", hindi: "से आसान", note: "กว่า (kwàa) = more than (comparative) / से (तुलना)"),
        ],
        139: [
            WordForm(thai: "ยากมาก", romanization: "yâak mâak", english: "very difficult", hindi: "बहुत मुश्किल", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ยาก", romanization: "mâi yâak", english: "not difficult", hindi: "मुश्किल नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ยากไหม", romanization: "yâak mǎi", english: "is it difficult?", hindi: "क्या मुश्किल है?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        140: [
            WordForm(thai: "สนุกมาก", romanization: "sà-nùk mâak", english: "a lot of fun", hindi: "बहुत मज़ेदार", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่สนุก", romanization: "mâi sà-nùk", english: "not fun", hindi: "मज़ा नहीं आया", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "สนุกไหม", romanization: "sà-nùk mǎi", english: "was it fun?", hindi: "क्या मज़ा आया?", note: "ไหม (mǎi) = question particle / प्रश्नसूचक शब्द"),
        ],
        141: [
            WordForm(thai: "เหนื่อยมาก", romanization: "nùeai mâak", english: "very tired", hindi: "बहुत थका हुआ", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่เหนื่อย", romanization: "mâi nùeai", english: "not tired", hindi: "थका नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "เหนื่อยไหม", romanization: "nùeai mǎi?", english: "are you tired?", hindi: "क्या थक गए?", note: "ไหม (mǎi) = yes/no question particle / हाँ-ना सवाल का शब्द"),
            WordForm(thai: "เหนื่อยแล้ว", romanization: "nùeai láeo", english: "tired now", hindi: "थक गया हूँ", note: "แล้ว (láeo) = already, by now / हो गया"),
        ],
        142: [
            WordForm(thai: "หวานมาก", romanization: "wǎan mâak", english: "very sweet", hindi: "बहुत मीठा", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่หวาน", romanization: "mâi wǎan", english: "not sweet", hindi: "मीठा नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "หวานน้อย", romanization: "wǎan nói", english: "less sweet (when ordering drinks)", hindi: "कम मीठा (ऑर्डर करते समय)", note: "น้อย (nói) = little, less / कम"),
            WordForm(thai: "หวานไป", romanization: "wǎan pai", english: "too sweet", hindi: "ज़्यादा ही मीठा", note: "ไป (pai) = too, excessively / हद से ज़्यादा"),
        ],
        143: [
            WordForm(thai: "ใกล้มาก", romanization: "klâi-mâak", english: "very near", hindi: "बहुत पास", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ใกล้ ๆ", romanization: "klâi-klâi", english: "right nearby", hindi: "पास ही", note: "ๆ (repetition) = 'right around here' / दोहराव = 'पास ही'"),
            WordForm(thai: "ใกล้ที่สุด", romanization: "klâi-thîi-sùt", english: "the nearest", hindi: "सबसे पास", note: "ที่สุด (thîi-sùt) = most / सबसे"),
        ],
        144: [
            WordForm(thai: "ไกลมาก", romanization: "klai-mâak", english: "very far", hindi: "बहुत दूर", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่ไกล", romanization: "mâi-klai", english: "not far", hindi: "दूर नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "ไกลไหม", romanization: "klai-mǎi", english: "Is it far?", hindi: "क्या यह दूर है?", note: "ไหม (mǎi) = question particle / प्रश्न शब्द"),
        ],
        145: [
            WordForm(thai: "อะไรนะ", romanization: "à-rai ná", english: "what? / pardon?", hindi: "क्या कहा?", note: "นะ (ná) = softening particle / वाक्य को कोमल बनाने वाला शब्द"),
        ],
        146: [
            WordForm(thai: "อยู่ที่ไหน", romanization: "yùu thîi-nǎi", english: "where is it? / where are you?", hindi: "कहाँ है? / कहाँ हो?", note: "อยู่ (yùu) = to be (at a place) / होना (किसी जगह पर)"),
        ],
        149: [
            WordForm(thai: "ของใคร", romanization: "khǎawng-khrai", english: "whose?", hindi: "किसका?", note: "ของ (khǎawng) = of, belonging to / का"),
            WordForm(thai: "ใครก็ได้", romanization: "khrai-kâw-dâai", english: "anyone / anybody will do", hindi: "कोई भी", note: "ก็ได้ (kâw-dâai) = …is fine, whichever / भी चलेगा"),
        ],
        150: [
            WordForm(thai: "ไปยังไง", romanization: "pai-yang-ngai", english: "How do I get there?", hindi: "वहाँ कैसे जाऊँ?", note: "ไป (pai) = to go / जाना"),
            WordForm(thai: "ทำยังไง", romanization: "tham-yang-ngai", english: "How do I do it?", hindi: "कैसे करूँ?", note: "ทำ (tham) = to do / करना"),
        ],
        152: [
            WordForm(thai: "หรือเปล่า", romanization: "rǔue plào", english: "...or not? (question tag)", hindi: "...या नहीं?", note: "เปล่า (plào) = or not / या नहीं"),
            WordForm(thai: "หรือยัง", romanization: "rǔue yang", english: "...yet? (e.g. eaten yet?)", hindi: "...अभी तक? (क्या हो गया?)", note: "ยัง (yang) = yet / अभी तक"),
        ],
        154: [
            WordForm(thai: "นี่อะไร", romanization: "nîi à-rai", english: "What is this?", hindi: "यह क्या है?", note: "อะไร (à-rai) = what / क्या"),
        ],
        155: [
            WordForm(thai: "นั่นอะไร", romanization: "nân-à-rai", english: "what is that?", hindi: "वह क्या है?", note: "อะไร (à-rai) = what / क्या"),
            WordForm(thai: "นั่นแหละ", romanization: "nân-làe", english: "exactly / that's it", hindi: "बिल्कुल वही / वही तो", note: "แหละ (làe) = emphasis particle / ज़ोर देने वाला कण"),
        ],
        156: [
            WordForm(thai: "ลูกหมา", romanization: "lûuk-mǎa", english: "puppy", hindi: "पिल्ला", note: "ลูก (lûuk) = child, offspring (here: baby animal) / बच्चा (यहाँ: जानवर का बच्चा)"),
        ],
        157: [
            WordForm(thai: "ลูกแมว", romanization: "lûuk maeo", english: "kitten", hindi: "बिल्ली का बच्चा", note: "ลูก (lûuk) = baby (of an animal) / जानवर का बच्चा"),
        ],
        159: [
            WordForm(thai: "ปลาทอด", romanization: "plaa thôot", english: "fried fish", hindi: "तली हुई मछली", note: "ทอด (thôot) = deep-fried / तला हुआ"),
            WordForm(thai: "น้ำปลา", romanization: "náam-plaa", english: "fish sauce", hindi: "फ़िश सॉस", note: "น้ำ (náam) = water, liquid / पानी"),
        ],
        160: [
            WordForm(thai: "ขี่ช้าง", romanization: "khìi cháang", english: "to ride an elephant", hindi: "हाथी की सवारी करना", note: "ขี่ (khìi) = to ride / सवारी करना"),
        ],
        161: [
            WordForm(thai: "น้ำผลไม้", romanization: "náam-phǒn-lá-mái", english: "fruit juice", hindi: "फलों का रस / जूस", note: "น้ำ (náam) = water, juice / पानी, रस"),
        ],
        162: [
            WordForm(thai: "กินผัก", romanization: "kin-phàk", english: "to eat vegetables", hindi: "सब्ज़ी खाना", note: "กิน (kin) = to eat / खाना"),
            WordForm(thai: "ผัดผัก", romanization: "phàt-phàk", english: "stir-fried vegetables", hindi: "भुनी हुई सब्ज़ियाँ", note: "ผัด (phàt) = to stir-fry / भूनना"),
        ],
        163: [
            WordForm(thai: "ไก่ทอด", romanization: "kài thôot", english: "fried chicken", hindi: "फ्राइड चिकन", note: "ทอด (thôot) = deep-fried / तला हुआ"),
            WordForm(thai: "ไก่ย่าง", romanization: "kài yâang", english: "grilled chicken", hindi: "भुना हुआ चिकन (ग्रिल्ड)", note: "ย่าง (yâang) = grilled / भुना हुआ"),
        ],
        164: [
            WordForm(thai: "ไข่ดาว", romanization: "khài daao", english: "fried egg (sunny-side up)", hindi: "फ्राइड अंडा (सनी साइड अप)", note: "ดาว (daao) = star / तारा"),
            WordForm(thai: "ไข่เจียว", romanization: "khài jiao", english: "Thai omelette", hindi: "थाई ऑमलेट", note: "เจียว (jiao) = to fry a beaten egg / फेंटकर तलना"),
        ],
        165: [
            WordForm(thai: "นมสด", romanization: "nom-sòt", english: "fresh milk", hindi: "ताज़ा दूध", note: "สด (sòt) = fresh / ताज़ा"),
            WordForm(thai: "ชานม", romanization: "chaa-nom", english: "milk tea", hindi: "दूध वाली चाय", note: "ชา (chaa) = tea / चाय"),
        ],
        166: [
            WordForm(thai: "ไม่ใส่น้ำตาล", romanization: "mâi sài nám-taan", english: "no sugar (in it), please", hindi: "चीनी मत डालिए", note: "ไม่ใส่ (mâi sài) = don't put in / नहीं डालना"),
            WordForm(thai: "สีน้ำตาล", romanization: "sǐi nám-taan", english: "brown (color)", hindi: "भूरा रंग", note: "สี (sǐi) = color / रंग; lit. \"sugar color\" / शाब्दिक: चीनी का रंग"),
        ],
        167: [
            WordForm(thai: "ใส่เกลือ", romanization: "sài-kluea", english: "to add salt", hindi: "नमक डालना", note: "ใส่ (sài) = to put in, add / डालना"),
        ],
        168: [
            WordForm(thai: "แกงเขียวหวาน", romanization: "kaeng-khǐao-wǎan", english: "green curry", hindi: "ग्रीन करी", note: "เขียว (khǐao) = green, หวาน (wǎan) = sweet / हरा, मीठा"),
            WordForm(thai: "แกงเผ็ด", romanization: "kaeng-phèt", english: "spicy red curry", hindi: "तीखी करी", note: "เผ็ด (phèt) = spicy / तीखा"),
        ],
        169: [
            WordForm(thai: "ก๋วยเตี๋ยวน้ำ", romanization: "kǔai-tǐao náam", english: "noodle soup", hindi: "शोरबे वाले नूडल्स", note: "น้ำ (náam) = water, soup / शोरबा"),
            WordForm(thai: "ก๋วยเตี๋ยวแห้ง", romanization: "kǔai-tǐao hâeng", english: "dry noodles (no soup)", hindi: "बिना शोरबे के नूडल्स", note: "แห้ง (hâeng) = dry / सूखा"),
        ],
        171: [
            WordForm(thai: "เรียกตำรวจ", romanization: "rîak tam-rùat", english: "call the police!", hindi: "पुलिस बुलाओ!", note: "เรียก (rîak) = to call / बुलाना"),
            WordForm(thai: "สถานีตำรวจ", romanization: "sà-thǎa-nii tam-rùat", english: "police station", hindi: "पुलिस थाना", note: "สถานี (sà-thǎa-nii) = station / थाना, स्टेशन"),
        ],
        172: [
            WordForm(thai: "อันตรายมาก", romanization: "an-tà-raai mâak", english: "very dangerous", hindi: "बहुत खतरनाक", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ไม่อันตราย", romanization: "mâi an-tà-raai", english: "not dangerous", hindi: "खतरनाक नहीं", note: "ไม่ (mâi) = not / नहीं"),
            WordForm(thai: "อันตรายไหม", romanization: "an-tà-raai mǎi", english: "Is it dangerous?", hindi: "क्या यह खतरनाक है?", note: "ไหม (mǎi) = question particle / प्रश्न कण"),
        ],
        173: [
            WordForm(thai: "ระวังตัว", romanization: "rá-wang-tua", english: "take care of yourself / be careful", hindi: "अपना ख़याल रखना", note: "ตัว (tua) = self, body / खुद"),
            WordForm(thai: "ระวังนะ", romanization: "rá-wang-ná", english: "be careful, okay?", hindi: "सावधान रहना, ठीक?", note: "นะ (ná) = softening particle / नरमी का कण"),
        ],
        174: [
            WordForm(thai: "โทรศัพท์มือถือ", romanization: "thoo-rá-sàp-muue-thǔue", english: "mobile phone", hindi: "मोबाइल फ़ोन", note: "มือถือ (muue-thǔue) = hand-held / हाथ में रखने वाला"),
            WordForm(thai: "เบอร์โทรศัพท์", romanization: "boe-thoo-rá-sàp", english: "phone number", hindi: "फ़ोन नंबर", note: "เบอร์ (boe) = number / नंबर"),
        ],
        175: [
            WordForm(thai: "เลี้ยวซ้าย", romanization: "líao sáai", english: "turn left", hindi: "बाएँ मुड़िए", note: "เลี้ยว (líao) = to turn / मुड़ना"),
            WordForm(thai: "มือซ้าย", romanization: "muue sáai", english: "left hand", hindi: "बायाँ हाथ", note: "มือ (muue) = hand / हाथ"),
        ],
        176: [
            WordForm(thai: "เลี้ยวขวา", romanization: "líao khwǎa", english: "turn right", hindi: "दाएँ मुड़िए", note: "เลี้ยว (líao) = to turn / मुड़ना"),
            WordForm(thai: "ข้างขวา", romanization: "khâang khwǎa", english: "on the right side", hindi: "दाईं ओर", note: "ข้าง (khâang) = side / ओर"),
        ],
        177: [
            WordForm(thai: "ตรงไปเรื่อย ๆ", romanization: "trong-pai rûeai-rûeai", english: "keep going straight", hindi: "सीधे जाते रहिए", note: "เรื่อย ๆ (rûeai-rûeai) = continuously, keep on / लगातार"),
        ],
        178: [
            WordForm(thai: "มาที่นี่", romanization: "maa thîi-nîi", english: "come here", hindi: "यहाँ आओ", note: "มา (maa) = to come / आना"),
            WordForm(thai: "อยู่ที่นี่", romanization: "yùu thîi-nîi", english: "to be / stay here", hindi: "यहाँ रहना / होना", note: "อยู่ (yùu) = to be at, stay / रहना"),
        ],
        180: [
            WordForm(thai: "อยู่ข้างบน", romanization: "yùu-khâang-bon", english: "it's upstairs / up there", hindi: "ऊपर है", note: "อยู่ (yùu) = to be at (location) / होना (स्थान पर)"),
        ],
        181: [
            WordForm(thai: "อยู่ข้างล่าง", romanization: "yùu khâang-lâang", english: "it's downstairs / below", hindi: "नीचे है", note: "อยู่ (yùu) = to be (located) / (स्थान पर) होना"),
        ],
        182: [
            WordForm(thai: "ใส่น้ำแข็ง", romanization: "sài nám-khǎeng", english: "with ice (add ice)", hindi: "बर्फ़ डालकर", note: "ใส่ (sài) = to put in, add / डालना"),
            WordForm(thai: "ไม่ใส่น้ำแข็ง", romanization: "mâi sài nám-khǎeng", english: "no ice, please", hindi: "बिना बर्फ़ के", note: "ไม่ใส่ (mâi sài) = without adding / बिना डाले"),
        ],
        183: [
            WordForm(thai: "ข้าวผัดกุ้ง", romanization: "khâao-phàt kûng", english: "shrimp fried rice", hindi: "झींगा फ्राइड राइस", note: "กุ้ง (kûng) = shrimp / झींगा"),
            WordForm(thai: "ข้าวผัดไก่", romanization: "khâao-phàt kài", english: "chicken fried rice", hindi: "चिकन फ्राइड राइस", note: "ไก่ (kài) = chicken / मुर्गी"),
        ],
        184: [
            WordForm(thai: "น้ำส้มคั้น", romanization: "nám-sôm-khán", english: "freshly squeezed orange juice", hindi: "ताज़ा निचोड़ा हुआ संतरे का रस", note: "คั้น (khán) = squeezed / निचोड़ा हुआ"),
        ],
        185: [
            WordForm(thai: "เปิดไฟ", romanization: "pòet-fai", english: "to turn on the light", hindi: "बत्ती जलाना", note: "เปิด (pòet) = to open, turn on / खोलना, चालू करना"),
            WordForm(thai: "ปิดไฟ", romanization: "pìt-fai", english: "to turn off the light", hindi: "बत्ती बंद करना", note: "ปิด (pìt) = to close, turn off / बंद करना"),
        ],
        186: [
            WordForm(thai: "สถานีรถไฟ", romanization: "sà-thǎa-nii-rót-fai", english: "train station", hindi: "रेलवे स्टेशन", note: "สถานี (sà-thǎa-nii) = station / स्टेशन"),
            WordForm(thai: "นั่งรถไฟ", romanization: "nâng-rót-fai", english: "to take the train", hindi: "ट्रेन से जाना", note: "นั่ง (nâng) = to sit, ride / बैठना, सवारी करना"),
        ],
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
        6: [134],
        14: [83],
        19: [135],
        28: [85],
        32: [137],
        34: [73],
        36: [80, 156],
        46: [102],
        57: [137],
        60: [66],
        61: [124],
        66: [60],
        73: [34],
        77: [116],
        78: [79],
        79: [78],
        80: [36, 156],
        83: [14],
        85: [28],
        87: [118],
        102: [46],
        112: [164],
        116: [77],
        118: [87],
        124: [61],
        127: [152],
        132: [133],
        133: [132],
        134: [6],
        135: [19],
        137: [32, 57],
        143: [144],
        144: [143],
        146: [179],
        152: [127],
        156: [36, 80],
        163: [164],
        164: [112, 163],
        178: [179],
        179: [146, 178],
    ]

    private static let examples: [Int: [WordExample]] = [
        3: [
            WordExample(thai: "สวัสดีครับ", romanization: "sà-wàt-dii kráp", english: "Hello (polite, male speaker).", hindi: "नमस्ते (पुरुष, विनम्रता से)।"),
            WordExample(thai: "ขอบคุณมากครับ", romanization: "khòp-khun mâak kráp", english: "Thank you very much.", hindi: "बहुत-बहुत धन्यवाद।"),
            WordExample(thai: "ผมเข้าใจครับ", romanization: "phǒm khâo-jai kráp", english: "I understand.", hindi: "मैं समझ गया।"),
        ],
        22: [
            WordExample(thai: "ฉันหิวค่ะ", romanization: "chǎn hǐu khâ", english: "I am hungry.", hindi: "मुझे भूख लगी है।"),
            WordExample(thai: "ฉันชอบอาหารไทยค่ะ", romanization: "chǎn chôp aa-hǎan thai khâ", english: "I like Thai food.", hindi: "मुझे थाई खाना पसंद है।"),
            WordExample(thai: "ฉันมาจากอินเดียค่ะ", romanization: "chǎn maa jàak in-dia khâ", english: "I come from India.", hindi: "मैं भारत से आई हूँ।"),
        ],
        33: [
            WordExample(thai: "ขอไม่เผ็ดครับ", romanization: "khǒo mâi phèt kráp", english: "Not spicy, please.", hindi: "तीखा नहीं चाहिए, प्लीज़।"),
            WordExample(thai: "อาหารไทยเผ็ดมาก", romanization: "aa-hǎan thai phèt mâak", english: "Thai food is very spicy.", hindi: "थाई खाना बहुत तीखा होता है।"),
        ],
        42: [
            WordExample(thai: "ห้องนี้เล็กมากครับ", romanization: "hông níi lék mâak kráp", english: "This room is very small.", hindi: "यह कमरा बहुत छोटा है।"),
            WordExample(thai: "รถคันนี้เล็ก", romanization: "rót khan níi lék", english: "This car is small.", hindi: "यह गाड़ी छोटी है।"),
        ],
        51: [
            WordExample(thai: "วันนี้อากาศดี", romanization: "wan-níi aa-kàat dii", english: "The weather is nice today.", hindi: "आज मौसम अच्छा है।"),
            WordExample(thai: "วันนี้ผมไปตลาด", romanization: "wan-níi phǒm pai tà-làat", english: "Today I am going to the market.", hindi: "आज मैं बाज़ार जा रहा हूँ।"),
            WordExample(thai: "วันนี้ร้อนมากครับ", romanization: "wan-níi rón mâak kráp", english: "It is very hot today.", hindi: "आज बहुत गर्मी है।"),
        ],
        57: [
            WordExample(thai: "ผมตื่นเช้า", romanization: "phǒm tùuen cháao", english: "I wake up early in the morning.", hindi: "मैं सुबह जल्दी उठता हूँ।"),
            WordExample(thai: "เจอกันพรุ่งนี้เช้าครับ", romanization: "joe kan phrûng-níi cháao kráp", english: "See you tomorrow morning.", hindi: "कल सुबह मिलते हैं।"),
        ],
        68: [
            WordExample(thai: "ผู้ชายคนนั้นเป็นครู", romanization: "phûu-chaai khon nân pen khruu", english: "That man is a teacher.", hindi: "वह आदमी शिक्षक है।"),
            WordExample(thai: "ห้องน้ำผู้ชายอยู่ที่ไหนครับ", romanization: "hông-náam phûu-chaai yùu thîi-nǎi kráp", english: "Where is the men's toilet?", hindi: "पुरुषों का शौचालय कहाँ है?"),
        ],
        74: [
            WordExample(thai: "ผมปวดตาครับ", romanization: "phǒm pùat taa kráp", english: "My eyes hurt.", hindi: "मेरी आँखों में दर्द है।"),
            WordExample(thai: "เธอตาสวยมาก", romanization: "thoe taa sǔai mâak", english: "She has very beautiful eyes.", hindi: "उसकी आँखें बहुत सुंदर हैं।"),
        ],
        80: [
            WordExample(thai: "ผมอยากไปหาหมอครับ", romanization: "phǒm yàak pai hǎa mǒo kráp", english: "I want to see a doctor.", hindi: "मैं डॉक्टर के पास जाना चाहता हूँ।"),
            WordExample(thai: "หมออยู่ที่โรงพยาบาล", romanization: "mǒo yùu thîi roong-phá-yaa-baan", english: "The doctor is at the hospital.", hindi: "डॉक्टर अस्पताल में हैं।"),
        ],
        92: [
            WordExample(thai: "วันนี้ลมแรงมาก", romanization: "wan-níi lom raeng mâak", english: "The wind is very strong today.", hindi: "आज हवा बहुत तेज़ है।"),
            WordExample(thai: "ที่ทะเลมีลมเย็น", romanization: "thîi thá-lee mii lom yen", english: "There is a cool breeze at the sea.", hindi: "समुद्र पर ठंडी हवा चलती है।"),
        ],
        110: [
            WordExample(thai: "อันนี้ห้าสิบบาทครับ", romanization: "an-níi hâa-sìp bàat kráp", english: "This one is fifty baht.", hindi: "यह पचास बात का है।"),
            WordExample(thai: "ทั้งหมดร้อยบาทครับ", romanization: "tháng-mòt rói bàat kráp", english: "Altogether it is one hundred baht.", hindi: "कुल मिलाकर सौ बात हुए।"),
        ],
        118: [
            WordExample(thai: "ผมเขียนภาษาไทยไม่ได้", romanization: "phǒm khǐan phaa-sǎa thai mâi dâai", english: "I cannot write Thai.", hindi: "मैं थाई नहीं लिख सकता।"),
            WordExample(thai: "ช่วยเขียนให้หน่อยครับ", romanization: "chûai khǐan hâi nòi kráp", english: "Please write it down for me.", hindi: "कृपया मेरे लिए लिख दीजिए।"),
        ],
        124: [
            WordExample(thai: "ผมเดินไปตลาด", romanization: "phǒm doen pai tà-làat", english: "I walk to the market.", hindi: "मैं पैदल बाज़ार जाता हूँ।"),
            WordExample(thai: "เดินตรงไปครับ", romanization: "doen trong-pai kráp", english: "Walk straight ahead.", hindi: "सीधे चलते जाइए।"),
        ],
        132: [
            WordExample(thai: "ช่วยเปิดไฟหน่อยครับ", romanization: "chûai pòet fai nòi kráp", english: "Please turn on the light.", hindi: "कृपया बत्ती जला दीजिए।"),
            WordExample(thai: "ร้านเปิดกี่โมงครับ", romanization: "ráan pòet kìi moong kráp", english: "What time does the shop open?", hindi: "दुकान कितने बजे खुलती है?"),
        ],
        138: [
            WordExample(thai: "ภาษาไทยไม่ง่ายครับ", romanization: "phaa-sǎa thai mâi ngâai kráp", english: "The Thai language is not easy.", hindi: "थाई भाषा आसान नहीं है।"),
            WordExample(thai: "อาหารนี้ทำง่าย", romanization: "aa-hǎan níi tham ngâai", english: "This dish is easy to make.", hindi: "यह खाना बनाना आसान है।"),
        ],
        144: [
            WordExample(thai: "สนามบินอยู่ไกลไหมครับ", romanization: "sà-nǎam-bin yùu klai mǎi kráp", english: "Is the airport far away?", hindi: "क्या हवाई अड्डा दूर है?"),
            WordExample(thai: "ไม่ไกลครับ เดินไปได้", romanization: "mâi klai kráp, doen pai dâai", english: "It is not far, you can walk there.", hindi: "दूर नहीं है, पैदल जा सकते हैं।"),
        ],
        152: [
            WordExample(thai: "เอาชาหรือกาแฟครับ", romanization: "ao chaa rǔue kaa-fae kráp", english: "Do you want tea or coffee?", hindi: "चाय लेंगे या कॉफ़ी?"),
            WordExample(thai: "ไปวันนี้หรือพรุ่งนี้ครับ", romanization: "pai wan-níi rǔue phrûng-níi kráp", english: "Are we going today or tomorrow?", hindi: "आज चलें या कल?"),
        ],
        163: [
            WordExample(thai: "ผมชอบกินข้าวผัดไก่", romanization: "phǒm chôp kin khâao-phàt kài", english: "I like eating chicken fried rice.", hindi: "मुझे चिकन फ्राइड राइस खाना पसंद है।"),
            WordExample(thai: "ขอแกงไก่หนึ่งที่ครับ", romanization: "khǒo kaeng kài nèung thîi kráp", english: "One chicken curry, please.", hindi: "एक चिकन करी दीजिए।"),
        ],
        169: [
            WordExample(thai: "ขอก๋วยเตี๋ยวหนึ่งชามครับ", romanization: "khǒo kǔai-tǐao nèung chaam kráp", english: "One bowl of noodles, please.", hindi: "एक कटोरा नूडल्स दीजिए।"),
            WordExample(thai: "ก๋วยเตี๋ยวร้านนี้อร่อยมาก", romanization: "kǔai-tǐao ráan níi à-ròi mâak", english: "The noodles at this shop are very delicious.", hindi: "इस दुकान के नूडल्स बहुत स्वादिष्ट हैं।"),
        ],
        176: [
            WordExample(thai: "เลี้ยวขวาตรงนี้ครับ", romanization: "líao khwǎa trong níi kráp", english: "Turn right here.", hindi: "यहाँ दाएँ मुड़िए।"),
            WordExample(thai: "ห้องน้ำอยู่ทางขวาครับ", romanization: "hông-náam yùu thaang khwǎa kráp", english: "The toilet is on the right.", hindi: "शौचालय दाईं ओर है।"),
        ],
        182: [
            WordExample(thai: "ขอน้ำแข็งหน่อยครับ", romanization: "khǒo nám-khǎeng nòi kráp", english: "Some ice, please.", hindi: "थोड़ी बर्फ़ दीजिए।"),
            WordExample(thai: "ไม่ใส่น้ำแข็งครับ", romanization: "mâi sài nám-khǎeng kráp", english: "No ice, please.", hindi: "बर्फ़ मत डालिए।"),
        ],
        4: [
            WordExample(thai: "สวัสดีค่ะ", romanization: "sà-wàt-dii khâ", english: "Hello. (female speaker)", hindi: "नमस्ते। (स्त्री वक्ता)"),
            WordExample(thai: "ขอบคุณมากค่ะ", romanization: "khòp-khun mâak khâ", english: "Thank you very much.", hindi: "बहुत-बहुत धन्यवाद।"),
            WordExample(thai: "ใช่ค่ะ ฉันเข้าใจ", romanization: "châi khâ chǎn khâo-jai", english: "Yes, I understand.", hindi: "हाँ, मैं समझती हूँ।"),
        ],
        23: [
            WordExample(thai: "คุณชื่ออะไรครับ", romanization: "khun chûue à-rai kráp", english: "What is your name?", hindi: "आपका नाम क्या है?"),
            WordExample(thai: "คุณสบายดีไหมครับ", romanization: "khun sà-baai-dii mǎi kráp", english: "How are you?", hindi: "आप कैसे हैं?"),
            WordExample(thai: "คุณมาจากประเทศอะไรครับ", romanization: "khun maa jàak prà-thêet à-rai kráp", english: "Which country are you from?", hindi: "आप किस देश से हैं?"),
        ],
        36: [
            WordExample(thai: "ผมมาจากอินเดียครับ", romanization: "phǒm maa jàak in-dia kráp", english: "I come from India.", hindi: "मैं भारत से आया हूँ।"),
            WordExample(thai: "เพื่อนจะมาพรุ่งนี้ครับ", romanization: "phûean jà maa phrûng-níi kráp", english: "My friend will come tomorrow.", hindi: "मेरा दोस्त कल आएगा।"),
            WordExample(thai: "มากินข้าวด้วยกันครับ", romanization: "maa kin khâao dûai-kan kráp", english: "Come eat together with us.", hindi: "आइए, साथ में खाना खाते हैं।"),
        ],
        43: [
            WordExample(thai: "วันนี้อากาศร้อนมากครับ", romanization: "wan-níi aa-kàat rón mâak kráp", english: "Today the weather is very hot.", hindi: "आज मौसम बहुत गरम है।"),
            WordExample(thai: "ขอน้ำร้อนหน่อยครับ", romanization: "khǒo nám-rón nòi kráp", english: "May I have some hot water, please?", hindi: "थोड़ा गरम पानी दीजिए।"),
        ],
        52: [
            WordExample(thai: "พรุ่งนี้ผมไปสนามบินครับ", romanization: "phrûng-níi phǒm pai sà-nǎam-bin kráp", english: "Tomorrow I am going to the airport.", hindi: "कल मैं हवाई अड्डे जाऊँगा।"),
            WordExample(thai: "เจอกันพรุ่งนี้ครับ", romanization: "joe-kan phrûng-níi kráp", english: "See you tomorrow.", hindi: "कल मिलते हैं।"),
        ],
        58: [
            WordExample(thai: "เย็นนี้ไปกินข้าวไหมครับ", romanization: "yen-níi pai kin khâao mǎi kráp", english: "Shall we go eat this evening?", hindi: "आज शाम खाना खाने चलें?"),
            WordExample(thai: "ตอนเย็นอากาศดีครับ", romanization: "toon-yen aa-kàat dii kráp", english: "In the evening the weather is nice.", hindi: "शाम को मौसम अच्छा होता है।"),
        ],
        69: [
            WordExample(thai: "ผู้หญิงคนนั้นสวยมาก", romanization: "phûu-yǐng khon nán sǔai mâak", english: "That woman is very beautiful.", hindi: "वह औरत बहुत सुंदर है।"),
            WordExample(thai: "ห้องน้ำผู้หญิงอยู่ที่ไหนครับ", romanization: "hông-náam phûu-yǐng yùu thîi-nǎi kráp", english: "Where is the women's restroom?", hindi: "महिलाओं का शौचालय कहाँ है?"),
        ],
        75: [
            WordExample(thai: "ล้างมือก่อนกินข้าวครับ", romanization: "láang muue kòon kin khâao kráp", english: "Wash your hands before eating.", hindi: "खाने से पहले हाथ धोइए।"),
            WordExample(thai: "มือของฉันเล็ก", romanization: "muue khǒong chǎn lék", english: "My hands are small.", hindi: "मेरे हाथ छोटे हैं।"),
        ],
        81: [
            WordExample(thai: "ผมต้องกินยาหลังอาหารครับ", romanization: "phǒm tông kin yaa lǎng aa-hǎan kráp", english: "I have to take medicine after meals.", hindi: "मुझे खाने के बाद दवा लेनी होती है।"),
            WordExample(thai: "ซื้อยาได้ที่ไหนครับ", romanization: "súue yaa dâi thîi-nǎi kráp", english: "Where can I buy medicine?", hindi: "दवा कहाँ खरीद सकता हूँ?"),
        ],
        93: [
            WordExample(thai: "ผมชอบไปทะเลครับ", romanization: "phǒm chôp pai thá-lee kráp", english: "I like going to the sea.", hindi: "मुझे समुद्र जाना पसंद है।"),
            WordExample(thai: "ทะเลที่นี่สวยมาก", romanization: "thá-lee thîi-nîi sǔai mâak", english: "The sea here is very beautiful.", hindi: "यहाँ का समुद्र बहुत सुंदर है।"),
        ],
        112: [
            WordExample(thai: "ที่นี่ขายอะไรครับ", romanization: "thîi-nîi khǎai à-rai kráp", english: "What do they sell here?", hindi: "यहाँ क्या बिकता है?"),
            WordExample(thai: "ร้านนี้ขายผลไม้", romanization: "ráan níi khǎai phǒn-lá-mái", english: "This shop sells fruit.", hindi: "यह दुकान फल बेचती है।"),
        ],
        119: [
            WordExample(thai: "ขอดูหน่อยครับ", romanization: "khǒo duu nòi kráp", english: "May I have a look, please?", hindi: "ज़रा देखने दीजिए।"),
            WordExample(thai: "ผมชอบดูทะเลตอนเย็น", romanization: "phǒm chôp duu thá-lee toon-yen", english: "I like watching the sea in the evening.", hindi: "मुझे शाम को समुद्र देखना पसंद है।"),
        ],
        125: [
            WordExample(thai: "ผมวิ่งทุกเช้าครับ", romanization: "phǒm wîng thúk cháao kráp", english: "I run every morning.", hindi: "मैं हर सुबह दौड़ता हूँ।"),
            WordExample(thai: "เด็ก ๆ วิ่งเร็วมาก", romanization: "dèk-dèk wîng reo mâak", english: "The children run very fast.", hindi: "बच्चे बहुत तेज़ दौड़ते हैं।"),
        ],
        133: [
            WordExample(thai: "ร้านปิดกี่โมงครับ", romanization: "ráan pìt kìi moong kráp", english: "What time does the shop close?", hindi: "दुकान कितने बजे बंद होती है?"),
            WordExample(thai: "ช่วยปิดไฟหน่อยครับ", romanization: "chûai pìt fai nòi kráp", english: "Please turn off the light.", hindi: "कृपया बत्ती बंद कर दीजिए।"),
        ],
        139: [
            WordExample(thai: "ภาษาไทยยากไหมครับ", romanization: "phaa-sǎa-thai yâak mǎi kráp", english: "Is Thai difficult?", hindi: "क्या थाई भाषा कठिन है?"),
            WordExample(thai: "ไม่ยากครับ ง่ายมาก", romanization: "mâi yâak kráp ngâai mâak", english: "It is not difficult, it is very easy.", hindi: "मुश्किल नहीं है, बहुत आसान है।"),
        ],
        147: [
            WordExample(thai: "คุณจะมาเมื่อไหร่ครับ", romanization: "khun jà maa mûea-rài kráp", english: "When will you come?", hindi: "आप कब आएँगे?"),
            WordExample(thai: "รถไฟมาเมื่อไหร่ครับ", romanization: "rót-fai maa mûea-rài kráp", english: "When does the train come?", hindi: "रेलगाड़ी कब आएगी?"),
        ],
        153: [
            WordExample(thai: "อร่อยแต่เผ็ดมากครับ", romanization: "à-ròi tàe phèt mâak kráp", english: "Delicious, but very spicy.", hindi: "स्वादिष्ट है लेकिन बहुत तीखा है।"),
            WordExample(thai: "ผมอยากไปแต่ไม่มีเวลา", romanization: "phǒm yàak pai tàe mâi mii wee-laa", english: "I want to go, but I have no time.", hindi: "मैं जाना चाहता हूँ लेकिन समय नहीं है।"),
        ],
        164: [
            WordExample(thai: "ขอไข่เจียวหนึ่งจานครับ", romanization: "khǒo khài-jiao nèung jaan kráp", english: "One omelette, please.", hindi: "एक आमलेट दीजिए।"),
            WordExample(thai: "ผมไม่กินไข่ครับ", romanization: "phǒm mâi kin khài kráp", english: "I do not eat eggs.", hindi: "मैं अंडे नहीं खाता।"),
        ],
        171: [
            WordExample(thai: "ช่วยเรียกตำรวจหน่อยครับ", romanization: "chûai rîak tam-rùat nòi kráp", english: "Please call the police.", hindi: "कृपया पुलिस बुलाइए।"),
            WordExample(thai: "สถานีตำรวจอยู่ที่ไหนครับ", romanization: "sà-thǎa-nii tam-rùat yùu thîi-nǎi kráp", english: "Where is the police station?", hindi: "पुलिस थाना कहाँ है?"),
        ],
        177: [
            WordExample(thai: "ตรงไปแล้วเลี้ยวขวาครับ", romanization: "trong-pai láeo líao khwǎa kráp", english: "Go straight, then turn right.", hindi: "सीधे जाइए, फिर दाएँ मुड़िए।"),
            WordExample(thai: "ตรงไปประมาณสองนาทีครับ", romanization: "trong-pai prà-maan sǒong naa-thii kráp", english: "Go straight for about two minutes.", hindi: "लगभग दो मिनट सीधे जाइए।"),
        ],
        183: [
            WordExample(thai: "ขอข้าวผัดไก่หนึ่งจานครับ", romanization: "khǒo khâao-phàt kài nèung jaan kráp", english: "One chicken fried rice, please.", hindi: "एक चिकन फ्राइड राइस दीजिए।"),
            WordExample(thai: "ข้าวผัดที่นี่อร่อยมาก", romanization: "khâao-phàt thîi-nîi à-ròi mâak", english: "The fried rice here is very delicious.", hindi: "यहाँ का फ्राइड राइस बहुत स्वादिष्ट है।"),
        ],
        7: [
            WordExample(thai: "ไม่เป็นไรครับ", romanization: "mâi-pen-rai kráp", english: "No problem.", hindi: "कोई बात नहीं।"),
            WordExample(thai: "ไม่เป็นไร ไม่ต้องขอโทษครับ", romanization: "mâi-pen-rai mâi tông khǒo-thôot kráp", english: "It's okay, no need to apologize.", hindi: "कोई बात नहीं, माफ़ी माँगने की ज़रूरत नहीं।"),
            WordExample(thai: "ไม่เป็นไร ผมสบายดีครับ", romanization: "mâi-pen-rai phǒm sà-baai-dii kráp", english: "It's okay, I'm fine.", hindi: "कोई बात नहीं, मैं ठीक हूँ।"),
        ],
        24: [
            WordExample(thai: "เขาเป็นเพื่อนของผมครับ", romanization: "khǎo pen phûean khǒong phǒm kráp", english: "He is my friend.", hindi: "वह मेरा दोस्त है।"),
            WordExample(thai: "ผมมากับเพื่อนครับ", romanization: "phǒm maa kàp phûean kráp", english: "I came with a friend.", hindi: "मैं दोस्त के साथ आया हूँ।"),
        ],
        38: [
            WordExample(thai: "ผมชอบอาหารไทยครับ", romanization: "phǒm chôp aa-hǎan thai kráp", english: "I like Thai food.", hindi: "मुझे थाई खाना पसंद है।"),
            WordExample(thai: "คุณชอบไหมครับ", romanization: "khun chôp mǎi kráp", english: "Do you like it?", hindi: "क्या आपको पसंद है?"),
            WordExample(thai: "ผมชอบทะเลมากครับ", romanization: "phǒm chôp thá-lee mâak kráp", english: "I really like the sea.", hindi: "मुझे समुद्र बहुत पसंद है।"),
        ],
        44: [
            WordExample(thai: "วันนี้อากาศหนาวครับ", romanization: "wan-níi aa-kàat nǎao kráp", english: "The weather is cold today.", hindi: "आज मौसम ठंडा है।"),
            WordExample(thai: "ผมหนาวมากครับ", romanization: "phǒm nǎao mâak kráp", english: "I'm very cold.", hindi: "मुझे बहुत ठंड लग रही है।"),
        ],
        53: [
            WordExample(thai: "เมื่อวานผมไปทะเลครับ", romanization: "mûea-waan phǒm pai thá-lee kráp", english: "Yesterday I went to the sea.", hindi: "कल मैं समुद्र गया था।"),
            WordExample(thai: "เมื่อวานฝนตกครับ", romanization: "mûea-waan fǒn tòk kráp", english: "It rained yesterday.", hindi: "कल बारिश हुई थी।"),
        ],
        59: [
            WordExample(thai: "กลางคืนอากาศเย็นครับ", romanization: "klaang-khuen aa-kàat yen kráp", english: "At night the weather is cool.", hindi: "रात में मौसम ठंडा रहता है।"),
            WordExample(thai: "ผมทำงานกลางคืนครับ", romanization: "phǒm tham-ngaan klaang-khuen kráp", english: "I work at night.", hindi: "मैं रात में काम करता हूँ।"),
        ],
        70: [
            WordExample(thai: "เด็กคนนี้น่ารักมากครับ", romanization: "dèk khon níi nâa-rák mâak kráp", english: "This child is very cute.", hindi: "यह बच्चा बहुत प्यारा है।"),
            WordExample(thai: "มีเด็กสองคนครับ", romanization: "mii dèk sǒong khon kráp", english: "There are two children.", hindi: "दो बच्चे हैं।"),
        ],
        76: [
            WordExample(thai: "เขาใจดีมากครับ", romanization: "khǎo jai-dii mâak kráp", english: "He is very kind (good-hearted).", hindi: "वह बहुत दयालु है।"),
            WordExample(thai: "ใจเย็นๆ นะครับ", romanization: "jai-yen-yen ná kráp", english: "Calm down, take it easy.", hindi: "शांत रहिए, जल्दबाज़ी मत कीजिए।"),
        ],
        82: [
            WordExample(thai: "โรงพยาบาลอยู่ที่ไหนครับ", romanization: "roong-phá-yaa-baan yùu thîi-nǎi kráp", english: "Where is the hospital?", hindi: "अस्पताल कहाँ है?"),
            WordExample(thai: "ผมต้องไปโรงพยาบาลครับ", romanization: "phǒm tông pai roong-phá-yaa-baan kráp", english: "I have to go to the hospital.", hindi: "मुझे अस्पताल जाना है।"),
        ],
        94: [
            WordExample(thai: "ภูเขาลูกนี้สวยมากครับ", romanization: "phuu-khǎo lûuk níi sǔai mâak kráp", english: "This mountain is very beautiful.", hindi: "यह पहाड़ बहुत सुंदर है।"),
            WordExample(thai: "พรุ่งนี้ผมจะไปภูเขาครับ", romanization: "phrûng-níi phǒm jà pai phuu-khǎo kráp", english: "Tomorrow I'll go to the mountains.", hindi: "कल मैं पहाड़ जाऊँगा।"),
        ],
        113: [
            WordExample(thai: "ลดราคาได้ไหมครับ", romanization: "lót-raa-khaa dâai mǎi kráp", english: "Can you give a discount?", hindi: "क्या कुछ छूट मिल सकती है?"),
            WordExample(thai: "วันนี้ร้านลดราคาครับ", romanization: "wan-níi ráan lót-raa-khaa kráp", english: "The shop has a discount today.", hindi: "आज दुकान में छूट चल रही है।"),
        ],
        120: [
            WordExample(thai: "ผมจะไปนอนแล้วครับ", romanization: "phǒm jà pai noon láeo kráp", english: "I'm going to bed now.", hindi: "मैं अब सोने जा रहा हूँ।"),
            WordExample(thai: "คุณนอนกี่ชั่วโมงครับ", romanization: "khun noon kìi chûa-moong kráp", english: "How many hours did you sleep?", hindi: "आप कितने घंटे सोए?"),
        ],
        127: [
            WordExample(thai: "ผมไม่รู้ครับ", romanization: "phǒm mâi rúu kráp", english: "I don't know.", hindi: "मुझे नहीं पता।"),
            WordExample(thai: "คุณรู้ไหมครับ", romanization: "khun rúu mǎi kráp", english: "Do you know?", hindi: "क्या आप जानते हैं?"),
            WordExample(thai: "ผมรู้แล้วครับ", romanization: "phǒm rúu láeo kráp", english: "I know now, got it.", hindi: "मुझे पता चल गया।"),
        ],
        134: [
            WordExample(thai: "ผมซื้อรถใหม่ครับ", romanization: "phǒm súue rót mài kráp", english: "I bought a new car.", hindi: "मैंने नई गाड़ी खरीदी।"),
            WordExample(thai: "โรงแรมนี้ใหม่มากครับ", romanization: "roong-raem níi mài mâak kráp", english: "This hotel is very new.", hindi: "यह होटल बहुत नया है।"),
            WordExample(thai: "พูดใหม่ได้ไหมครับ", romanization: "phûut mài dâai mǎi kráp", english: "Can you say that again?", hindi: "क्या फिर से कह सकते हैं?"),
        ],
        140: [
            WordExample(thai: "เมืองไทยสนุกมากครับ", romanization: "mueang-thai sà-nùk mâak kráp", english: "Thailand is a lot of fun.", hindi: "थाईलैंड में बहुत मज़ा आता है।"),
            WordExample(thai: "เมื่อวานสนุกไหมครับ", romanization: "mûea-waan sà-nùk mǎi kráp", english: "Was yesterday fun?", hindi: "क्या कल मज़ा आया?"),
        ],
        148: [
            WordExample(thai: "ทำไมแพงจังครับ", romanization: "tham-mai phaeng jang kráp", english: "Why is it so expensive?", hindi: "इतना महँगा क्यों है?"),
            WordExample(thai: "ทำไมคุณไม่ไปครับ", romanization: "tham-mai khun mâi pai kráp", english: "Why aren't you going?", hindi: "आप क्यों नहीं जा रहे हैं?"),
        ],
        154: [
            WordExample(thai: "นี่อะไรครับ", romanization: "nîi à-rai kráp", english: "What is this?", hindi: "यह क्या है?"),
            WordExample(thai: "นี่เพื่อนของผมครับ", romanization: "nîi phûean khǒong phǒm kráp", english: "This is my friend.", hindi: "यह मेरा दोस्त है।"),
        ],
        165: [
            WordExample(thai: "ขอนมหนึ่งแก้วครับ", romanization: "khǒo nom nèung kâeo kráp", english: "One glass of milk, please.", hindi: "एक गिलास दूध दीजिए।"),
            WordExample(thai: "เด็กชอบดื่มนมครับ", romanization: "dèk chôp dùuem nom kráp", english: "Children like to drink milk.", hindi: "बच्चों को दूध पीना पसंद है।"),
        ],
        172: [
            WordExample(thai: "ถนนนี้อันตรายมากครับ", romanization: "thà-nǒn níi an-tà-raai mâak kráp", english: "This road is very dangerous.", hindi: "यह सड़क बहुत खतरनाक है।"),
            WordExample(thai: "ตรงนั้นอันตราย ระวังนะครับ", romanization: "trong nân an-tà-raai rá-wang ná kráp", english: "It's dangerous over there, be careful.", hindi: "वहाँ खतरा है, सावधान रहिए।"),
        ],
        178: [
            WordExample(thai: "ที่นี่สวยมากครับ", romanization: "thîi-nîi sǔai mâak kráp", english: "It's very beautiful here.", hindi: "यह जगह बहुत सुंदर है।"),
            WordExample(thai: "จอดที่นี่ได้ไหมครับ", romanization: "jòt thîi-nîi dâai mǎi kráp", english: "Can you stop here?", hindi: "क्या यहाँ रोक सकते हैं?"),
        ],
        184: [
            WordExample(thai: "ขอน้ำส้มหนึ่งแก้วครับ", romanization: "khǒo nám-sôm nèung kâeo kráp", english: "One glass of orange juice, please.", hindi: "एक गिलास संतरे का रस दीजिए।"),
            WordExample(thai: "น้ำส้มหวานมากครับ", romanization: "nám-sôm wǎan mâak kráp", english: "The orange juice is very sweet.", hindi: "संतरे का रस बहुत मीठा है।"),
        ],
        9: [
            WordExample(thai: "สวัสดีครับ สบายดีไหมครับ", romanization: "sà-wàt-dii kráp sà-baai-dii-mǎi kráp", english: "Hello! How are you?", hindi: "नमस्ते! आप कैसे हैं?"),
            WordExample(thai: "คุณแม่สบายดีไหมครับ", romanization: "khun mâe sà-baai-dii-mǎi kráp", english: "Is your mother doing well?", hindi: "क्या आपकी माँ ठीक हैं?"),
        ],
        25: [
            WordExample(thai: "ครอบครัวผมมีสี่คนครับ", romanization: "khrôp-khrua phǒm mii sìi khon kráp", english: "My family has four people.", hindi: "मेरे परिवार में चार लोग हैं।"),
            WordExample(thai: "ผมรักครอบครัวมากครับ", romanization: "phǒm rák khrôp-khrua mâak kráp", english: "I love my family very much.", hindi: "मैं अपने परिवार से बहुत प्यार करता हूँ।"),
        ],
        39: [
            WordExample(thai: "วันนี้อากาศดีมากครับ", romanization: "wan-níi aa-kàat dii mâak kráp", english: "The weather is very good today.", hindi: "आज मौसम बहुत अच्छा है।"),
            WordExample(thai: "อาหารร้านนี้ดีมากครับ", romanization: "aa-hǎan ráan níi dii mâak kráp", english: "The food at this shop is very good.", hindi: "इस दुकान का खाना बहुत अच्छा है।"),
            WordExample(thai: "เขาเป็นคนดีครับ", romanization: "kháo pen khon dii kráp", english: "He is a good person.", hindi: "वह अच्छा इंसान है।"),
        ],
        46: [
            WordExample(thai: "โรงแรมอยู่ที่ไหนครับ", romanization: "roong-raem yùu thîi-nǎi kráp", english: "Where is the hotel?", hindi: "होटल कहाँ है?"),
            WordExample(thai: "โรงแรมนี้สวยแต่แพงครับ", romanization: "roong-raem níi sǔai tàe phaeng kráp", english: "This hotel is beautiful but expensive.", hindi: "यह होटल सुंदर है लेकिन महंगा है।"),
        ],
        54: [
            WordExample(thai: "วันนี้ผมไม่มีเวลาครับ", romanization: "wan-níi phǒm mâi mii wee-laa kráp", english: "I don't have time today.", hindi: "आज मेरे पास समय नहीं है।"),
            WordExample(thai: "คุณมีเวลาไหมครับ", romanization: "khun mii wee-laa mǎi kráp", english: "Do you have time?", hindi: "क्या आपके पास समय है?"),
        ],
        60: [
            WordExample(thai: "ผมอายุสามสิบปีครับ", romanization: "phǒm aa-yú sǎam-sìp pii kráp", english: "I am thirty years old.", hindi: "मैं तीस साल का हूँ।"),
            WordExample(thai: "สวัสดีปีใหม่ครับ", romanization: "sà-wàt-dii pii-mài kráp", english: "Happy New Year!", hindi: "नव वर्ष की शुभकामनाएँ!"),
            WordExample(thai: "ปีนี้ผมมาเมืองไทยครับ", romanization: "pii níi phǒm maa mueang-thai kráp", english: "This year I came to Thailand.", hindi: "इस साल मैं थाईलैंड आया हूँ।"),
        ],
        71: [
            WordExample(thai: "คุณชื่ออะไรครับ", romanization: "khun chûue à-rai kráp", english: "What is your name?", hindi: "आपका नाम क्या है?"),
            WordExample(thai: "ผมชื่ออามิตครับ", romanization: "phǒm chûue aa-mít kráp", english: "My name is Amit.", hindi: "मेरा नाम अमित है।"),
            WordExample(thai: "ร้านนี้ชื่ออะไรครับ", romanization: "ráan níi chûue à-rai kráp", english: "What is this shop's name?", hindi: "इस दुकान का नाम क्या है?"),
        ],
        77: [
            WordExample(thai: "ผมปวดฟันครับ", romanization: "phǒm pùat fan kráp", english: "I have a toothache.", hindi: "मेरे दाँत में दर्द है।"),
            WordExample(thai: "เด็กแปรงฟันทุกวันครับ", romanization: "dèk praeng fan thúk wan kráp", english: "The child brushes his teeth every day.", hindi: "बच्चा रोज़ दाँत ब्रश करता है।"),
        ],
        83: [
            WordExample(thai: "คุณชอบสีอะไรครับ", romanization: "khun chôp sǐi à-rai kráp", english: "What color do you like?", hindi: "आपको कौन सा रंग पसंद है?"),
            WordExample(thai: "ผมชอบสีฟ้าครับ", romanization: "phǒm chôp sǐi fáa kráp", english: "I like sky blue.", hindi: "मुझे आसमानी नीला रंग पसंद है।"),
        ],
        95: [
            WordExample(thai: "ต้นไม้ต้นนี้ใหญ่มากครับ", romanization: "tôn-mái tôn níi yài mâak kráp", english: "This tree is very big.", hindi: "यह पेड़ बहुत बड़ा है।"),
            WordExample(thai: "บ้านผมมีต้นไม้เยอะครับ", romanization: "bâan phǒm mii tôn-mái yóe kráp", english: "My house has lots of trees.", hindi: "मेरे घर में बहुत सारे पेड़ हैं।"),
        ],
        114: [
            WordExample(thai: "น้ำดื่มฟรีครับ", romanization: "náam dùuem frii kráp", english: "Drinking water is free.", hindi: "पीने का पानी मुफ़्त है।"),
            WordExample(thai: "อันนี้ฟรีไหมครับ", romanization: "an-níi frii mǎi kráp", english: "Is this one free?", hindi: "क्या यह मुफ़्त है?"),
        ],
        121: [
            WordExample(thai: "ผมตื่นหกโมงเช้าครับ", romanization: "phǒm tùuen hòk moong cháao kráp", english: "I wake up at six in the morning.", hindi: "मैं सुबह छह बजे उठता हूँ।"),
            WordExample(thai: "พรุ่งนี้ต้องตื่นเช้าครับ", romanization: "phrûng-níi tông tùuen cháao kráp", english: "Tomorrow I have to wake up early.", hindi: "कल मुझे जल्दी उठना है।"),
        ],
        128: [
            WordExample(thai: "ผมคิดว่าดีครับ", romanization: "phǒm khít wâa dii kráp", english: "I think it's good.", hindi: "मुझे लगता है कि यह अच्छा है।"),
            WordExample(thai: "คุณคิดยังไงครับ", romanization: "khun khít yang-ngai kráp", english: "What do you think?", hindi: "आप क्या सोचते हैं?"),
            WordExample(thai: "ผมคิดถึงบ้านครับ", romanization: "phǒm khít-thǔeng bâan kráp", english: "I miss home.", hindi: "मुझे घर की याद आती है।"),
        ],
        135: [
            WordExample(thai: "รถคันนี้เก่ามากครับ", romanization: "rót khan níi kào mâak kráp", english: "This car is very old.", hindi: "यह गाड़ी बहुत पुरानी है।"),
            WordExample(thai: "โรงแรมนี้เก่าแต่สวยครับ", romanization: "roong-raem níi kào tàe sǔai kráp", english: "This hotel is old but beautiful.", hindi: "यह होटल पुराना है लेकिन सुंदर है।"),
        ],
        141: [
            WordExample(thai: "วันนี้ผมเหนื่อยมากครับ", romanization: "wan-níi phǒm nùeai mâak kráp", english: "I'm very tired today.", hindi: "आज मैं बहुत थका हुआ हूँ।"),
            WordExample(thai: "คุณเหนื่อยไหมครับ", romanization: "khun nùeai mǎi kráp", english: "Are you tired?", hindi: "क्या आप थके हुए हैं?"),
        ],
        149: [
            WordExample(thai: "เขาเป็นใครครับ", romanization: "kháo pen khrai kráp", english: "Who is he?", hindi: "वह कौन है?"),
            WordExample(thai: "ใครมาครับ", romanization: "khrai maa kráp", english: "Who is coming?", hindi: "कौन आ रहा है?"),
        ],
        155: [
            WordExample(thai: "นั่นอะไรครับ", romanization: "nân à-rai kráp", english: "What is that?", hindi: "वह क्या है?"),
            WordExample(thai: "นั่นเพื่อนผมครับ", romanization: "nân phûean phǒm kráp", english: "That is my friend.", hindi: "वह मेरा दोस्त है।"),
        ],
        166: [
            WordExample(thai: "ขอน้ำตาลหน่อยครับ", romanization: "khǒo nám-taan nòi kráp", english: "Some sugar, please.", hindi: "थोड़ी चीनी दीजिए।"),
            WordExample(thai: "ไม่ใส่น้ำตาลครับ", romanization: "mâi sài nám-taan kráp", english: "No sugar, please.", hindi: "चीनी मत डालिए।"),
        ],
        173: [
            WordExample(thai: "ระวังรถครับ", romanization: "rá-wang rót kráp", english: "Watch out for the car!", hindi: "गाड़ी से सावधान!"),
            WordExample(thai: "ระวังหน่อยนะครับ", romanization: "rá-wang nòi ná kráp", english: "Please be careful.", hindi: "ज़रा सावधान रहिए।"),
        ],
        179: [
            WordExample(thai: "ห้องน้ำอยู่ที่นั่นครับ", romanization: "hông-náam yùu thîi-nân kráp", english: "The bathroom is over there.", hindi: "शौचालय वहाँ है।"),
            WordExample(thai: "พรุ่งนี้ผมไปที่นั่นครับ", romanization: "phrûng-níi phǒm pai thîi-nân kráp", english: "I'm going there tomorrow.", hindi: "कल मैं वहाँ जाऊँगा।"),
        ],
        185: [
            WordExample(thai: "เปิดไฟหน่อยครับ", romanization: "pòet fai nòi kráp", english: "Please turn on the light.", hindi: "ज़रा बत्ती जला दीजिए।"),
            WordExample(thai: "ปิดไฟด้วยครับ", romanization: "pìt fai dûai kráp", english: "Please turn off the light.", hindi: "बत्ती बंद कर दीजिए।"),
            WordExample(thai: "ไฟแดงต้องหยุดครับ", romanization: "fai daeng tông yùt kráp", english: "You must stop at a red light.", hindi: "लाल बत्ती पर रुकना ज़रूरी है।"),
        ],
        10: [
            WordExample(thai: "ผมสบายดีครับ ขอบคุณครับ", romanization: "phǒm sà-baai-dii kráp, khòp-khun kráp", english: "I'm fine, thank you.", hindi: "मैं ठीक हूँ, धन्यवाद।"),
            WordExample(thai: "วันนี้ฉันสบายดีค่ะ", romanization: "wan-níi chǎn sà-baai-dii khâ", english: "I'm fine today.", hindi: "आज मैं ठीक हूँ।"),
            WordExample(thai: "คุณสบายดีไหมครับ", romanization: "khun sà-baai-dii mǎi kráp", english: "How are you?", hindi: "आप कैसे हैं?"),
        ],
        28: [
            WordExample(thai: "ผมกินข้าวแล้วครับ", romanization: "phǒm kin khâao láew kráp", english: "I have already eaten.", hindi: "मैंने खाना खा लिया।"),
            WordExample(thai: "ขอข้าวหนึ่งจานครับ", romanization: "khǒo khâao nèung jaan kráp", english: "One plate of rice, please.", hindi: "एक प्लेट चावल दीजिए।"),
            WordExample(thai: "ข้าวร้านนี้อร่อยมาก", romanization: "khâao ráan níi à-ròi mâak", english: "The rice at this shop is very tasty.", hindi: "इस दुकान के चावल बहुत स्वादिष्ट हैं।"),
        ],
        40: [
            WordExample(thai: "ทะเลที่นี่สวยมากครับ", romanization: "thá-lee thîi-nîi sǔai mâak kráp", english: "The sea here is very beautiful.", hindi: "यहाँ का समुद्र बहुत सुंदर है।"),
            WordExample(thai: "ดอกไม้สวยจังครับ", romanization: "dòk-mái sǔai jang kráp", english: "The flowers are so beautiful!", hindi: "फूल कितने सुंदर हैं!"),
        ],
        47: [
            WordExample(thai: "รถมาแล้วครับ", romanization: "rót maa láew kráp", english: "The car has arrived.", hindi: "गाड़ी आ गई।"),
            WordExample(thai: "ระวังรถครับ", romanization: "rá-wang rót kráp", english: "Watch out for cars!", hindi: "गाड़ी से सावधान!"),
            WordExample(thai: "รถคันนี้ใหม่มากครับ", romanization: "rót khan níi mài mâak kráp", english: "This car is very new.", hindi: "यह गाड़ी बहुत नई है।"),
        ],
        55: [
            WordExample(thai: "ผมรอหนึ่งชั่วโมงแล้วครับ", romanization: "phǒm roo nèung chûa-moong láew kráp", english: "I have already waited one hour.", hindi: "मैं एक घंटे से इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "ไปสนามบินใช้เวลาหนึ่งชั่วโมง", romanization: "pai sà-nǎam-bin chái wee-laa nèung chûa-moong", english: "It takes one hour to get to the airport.", hindi: "हवाई अड्डे जाने में एक घंटा लगता है।"),
        ],
        61: [
            WordExample(thai: "ผมอยู่เมืองไทยหนึ่งเดือนครับ", romanization: "phǒm yùu mueang-thai nèung duean kráp", english: "I am staying in Thailand for one month.", hindi: "मैं एक महीने के लिए थाईलैंड में रह रहा हूँ।"),
            WordExample(thai: "เดือนหน้าผมจะมาอีกครับ", romanization: "duean nâa phǒm jà maa ìik kráp", english: "I will come again next month.", hindi: "अगले महीने मैं फिर आऊँगा।"),
        ],
        72: [
            WordExample(thai: "ครูของผมใจดีมากครับ", romanization: "khruu khǒong phǒm jai-dii mâak kráp", english: "My teacher is very kind.", hindi: "मेरे शिक्षक बहुत दयालु हैं।"),
            WordExample(thai: "คุณเป็นครูใช่ไหมครับ", romanization: "khun pen khruu châi mǎi kráp", english: "You are a teacher, right?", hindi: "आप शिक्षक हैं, है ना?"),
        ],
        78: [
            WordExample(thai: "ผมปวดหัวครับ", romanization: "phǒm pùat hǔa kráp", english: "I have a headache.", hindi: "मेरे सिर में दर्द है।"),
            WordExample(thai: "ปวดฟันมากครับ", romanization: "pùat fan mâak kráp", english: "My tooth hurts a lot.", hindi: "दाँत में बहुत दर्द है।"),
        ],
        90: [
            WordExample(thai: "วันนี้ฝนตกครับ", romanization: "wan-níi fǒn tòk kráp", english: "It is raining today.", hindi: "आज बारिश हो रही है।"),
            WordExample(thai: "ฝนตกหนักมาก", romanization: "fǒn tòk nàk mâak", english: "It is raining very hard.", hindi: "बहुत तेज़ बारिश हो रही है।"),
        ],
        96: [
            WordExample(thai: "ดอกไม้นี้สวยมากครับ", romanization: "dòk-mái níi sǔai mâak kráp", english: "This flower is very beautiful.", hindi: "यह फूल बहुत सुंदर है।"),
            WordExample(thai: "ฉันชอบดอกไม้สีแดงค่ะ", romanization: "chǎn chôp dòk-mái sǐi daeng khâ", english: "I like red flowers.", hindi: "मुझे लाल फूल पसंद हैं।"),
        ],
        116: [
            WordExample(thai: "ผมชอบฟังเพลงครับ", romanization: "phǒm chôp fang phleeng kráp", english: "I like listening to music.", hindi: "मुझे गाने सुनना पसंद है।"),
            WordExample(thai: "ผมฟังไม่เข้าใจครับ", romanization: "phǒm fang mâi khâo-jai kráp", english: "I hear it but do not understand.", hindi: "मैं सुनता हूँ पर समझ नहीं पाता।"),
        ],
        122: [
            WordExample(thai: "คุณทำอะไรครับ", romanization: "khun tham à-rai kráp", english: "What are you doing?", hindi: "आप क्या कर रहे हैं?"),
            WordExample(thai: "ผมทำเองครับ", romanization: "phǒm tham eeng kráp", english: "I made it myself.", hindi: "मैंने खुद बनाया।"),
            WordExample(thai: "ทำอาหารง่ายมาก", romanization: "tham aa-hǎan ngâai mâak", english: "Cooking is very easy.", hindi: "खाना बनाना बहुत आसान है।"),
        ],
        130: [
            WordExample(thai: "รอสักครู่ครับ", romanization: "roo sàk-khrûu kráp", english: "Please wait a moment.", hindi: "थोड़ा इंतज़ार कीजिए।"),
            WordExample(thai: "ผมรอเพื่อนอยู่ครับ", romanization: "phǒm roo phûean yùu kráp", english: "I am waiting for a friend.", hindi: "मैं दोस्त का इंतज़ार कर रहा हूँ।"),
        ],
        136: [
            WordExample(thai: "รถคันนี้เร็วมากครับ", romanization: "rót khan níi reo mâak kráp", english: "This car is very fast.", hindi: "यह गाड़ी बहुत तेज़ है।"),
            WordExample(thai: "คุณพูดเร็วมากครับ", romanization: "khun phûut reo mâak kráp", english: "You speak very fast.", hindi: "आप बहुत तेज़ बोलते हैं।"),
            WordExample(thai: "มาเร็วๆ นะครับ", romanization: "maa reo-reo ná kráp", english: "Come quickly!", hindi: "जल्दी आइए!"),
        ],
        142: [
            WordExample(thai: "น้ำส้มนี้หวานมากครับ", romanization: "nám-sôm níi wǎan mâak kráp", english: "This orange juice is very sweet.", hindi: "यह संतरे का रस बहुत मीठा है।"),
            WordExample(thai: "ขอหวานน้อยครับ", romanization: "khǒo wǎan nói kráp", english: "Less sweet, please.", hindi: "कम मीठा दीजिए।"),
        ],
        150: [
            WordExample(thai: "ไปตลาดยังไงครับ", romanization: "pai tà-làat yang-ngai kráp", english: "How do I get to the market?", hindi: "बाज़ार कैसे जाऊँ?"),
            WordExample(thai: "อันนี้กินยังไงครับ", romanization: "an-níi kin yang-ngai kráp", english: "How do you eat this?", hindi: "इसे कैसे खाते हैं?"),
        ],
        161: [
            WordExample(thai: "ผมชอบกินผลไม้ครับ", romanization: "phǒm chôp kin phǒn-lá-mái kráp", english: "I like eating fruit.", hindi: "मुझे फल खाना पसंद है।"),
            WordExample(thai: "ผลไม้ที่ตลาดถูกมาก", romanization: "phǒn-lá-mái thîi tà-làat thùuk mâak", english: "Fruit at the market is very cheap.", hindi: "बाज़ार में फल बहुत सस्ते हैं।"),
        ],
        167: [
            WordExample(thai: "ขอเกลือหน่อยครับ", romanization: "khǒo kluea nòi kráp", english: "Some salt, please.", hindi: "थोड़ा नमक दीजिए।"),
            WordExample(thai: "แกงนี้ใส่เกลือเยอะครับ", romanization: "kaeng níi sài kluea yóe kráp", english: "This curry has a lot of salt.", hindi: "इस करी में नमक ज़्यादा है।"),
        ],
        174: [
            WordExample(thai: "โทรศัพท์ของผมอยู่ที่ไหนครับ", romanization: "thoo-rá-sàp khǒong phǒm yùu thîi-nǎi kráp", english: "Where is my phone?", hindi: "मेरा फ़ोन कहाँ है?"),
            WordExample(thai: "ขอใช้โทรศัพท์ได้ไหมครับ", romanization: "khǒo chái thoo-rá-sàp dâi mǎi kráp", english: "May I use the phone?", hindi: "क्या मैं फ़ोन इस्तेमाल कर सकता हूँ?"),
        ],
        180: [
            WordExample(thai: "ห้องน้ำอยู่ข้างบนครับ", romanization: "hông-náam yùu khâang-bon kráp", english: "The bathroom is upstairs.", hindi: "शौचालय ऊपर है।"),
            WordExample(thai: "เพื่อนของผมอยู่ข้างบนครับ", romanization: "phûean khǒong phǒm yùu khâang-bon kráp", english: "My friend is upstairs.", hindi: "मेरा दोस्त ऊपर है।"),
        ],
        186: [
            WordExample(thai: "รถไฟไปเชียงใหม่ออกกี่โมงครับ", romanization: "rót-fai pai chiang-mài òok kìi moong kráp", english: "What time does the train to Chiang Mai leave?", hindi: "चियांग माई की ट्रेन कितने बजे छूटती है?"),
            WordExample(thai: "ผมชอบนั่งรถไฟครับ", romanization: "phǒm chôp nâng rót-fai kráp", english: "I like riding the train.", hindi: "मुझे ट्रेन में बैठना पसंद है।"),
        ],
        21: [
            WordExample(thai: "ผมมาจากอินเดียครับ", romanization: "phǒm maa jàak in-dia kráp", english: "I come from India.", hindi: "मैं भारत से आया हूँ।"),
            WordExample(thai: "ผมชอบอาหารไทยครับ", romanization: "phǒm chôp aa-hǎan thai kráp", english: "I like Thai food.", hindi: "मुझे थाई खाना पसंद है।"),
            WordExample(thai: "ผมไม่เข้าใจครับ", romanization: "phǒm mâi khâo-jai kráp", english: "I don't understand.", hindi: "मैं नहीं समझा।"),
        ],
        32: [
            WordExample(thai: "ขอชาร้อนหนึ่งแก้วครับ", romanization: "khǒo chaa rón nèung kâeo kráp", english: "One hot tea, please.", hindi: "एक गरम चाय दीजिए।"),
            WordExample(thai: "ชาไทยหวานมาก", romanization: "chaa thai wǎan mâak", english: "Thai tea is very sweet.", hindi: "थाई चाय बहुत मीठी होती है।"),
            WordExample(thai: "คุณชอบชาหรือกาแฟครับ", romanization: "khun chôp chaa rǔue kaa-fae kráp", english: "Do you like tea or coffee?", hindi: "आपको चाय पसंद है या कॉफ़ी?"),
        ],
        41: [
            WordExample(thai: "โรงแรมนี้ใหญ่มาก", romanization: "roong-raem níi yài mâak", english: "This hotel is very big.", hindi: "यह होटल बहुत बड़ा है।"),
            WordExample(thai: "ผมชอบเมืองใหญ่ครับ", romanization: "phǒm chôp mueang yài kráp", english: "I like big cities.", hindi: "मुझे बड़े शहर पसंद हैं।"),
        ],
        50: [
            WordExample(thai: "ร้านนี้ขายถูกมาก", romanization: "ráan níi khǎai thùuk mâak", english: "This shop sells very cheaply.", hindi: "यह दुकान बहुत सस्ते में बेचती है।"),
            WordExample(thai: "อาหารที่ตลาดถูกมาก", romanization: "aa-hǎan thîi tà-làat thùuk mâak", english: "Food at the market is very cheap.", hindi: "बाज़ार का खाना बहुत सस्ता है।"),
        ],
        56: [
            WordExample(thai: "รอห้านาทีครับ", romanization: "roo hâa naa-thii kráp", english: "Please wait five minutes.", hindi: "पाँच मिनट रुकिए।"),
            WordExample(thai: "ขอเวลาสิบนาทีครับ", romanization: "khǒo wee-laa sìp naa-thii kráp", english: "Give me ten minutes, please.", hindi: "मुझे दस मिनट दीजिए।"),
        ],
        62: [
            WordExample(thai: "ผมอยู่ที่นี่สองสัปดาห์ครับ", romanization: "phǒm yùu thîi-nîi sǒong sàp-daa kráp", english: "I'm staying here for two weeks.", hindi: "मैं यहाँ दो हफ़्ते रहूँगा।"),
            WordExample(thai: "สัปดาห์หน้าผมไปทะเลครับ", romanization: "sàp-daa nâa phǒm pai thá-lee kráp", english: "Next week I'm going to the sea.", hindi: "अगले हफ़्ते मैं समुद्र जाऊँगा।"),
        ],
        73: [
            WordExample(thai: "ผมปวดหัวครับ", romanization: "phǒm pùat hǔa kráp", english: "I have a headache.", hindi: "मेरे सिर में दर्द है।"),
            WordExample(thai: "ระวังหัวครับ", romanization: "rá-wang hǔa kráp", english: "Watch your head!", hindi: "सिर संभालिए!"),
        ],
        79: [
            WordExample(thai: "วันนี้ผมป่วยครับ", romanization: "wan-níi phǒm pùai kráp", english: "I'm sick today.", hindi: "आज मैं बीमार हूँ।"),
            WordExample(thai: "เพื่อนผมป่วยเมื่อวาน", romanization: "phûean phǒm pùai mûea-waan", english: "My friend was sick yesterday.", hindi: "मेरा दोस्त कल बीमार था।"),
        ],
        91: [
            WordExample(thai: "วันนี้แดดร้อนมาก", romanization: "wan-níi dàet rón mâak", english: "The sun is very hot today.", hindi: "आज धूप बहुत तेज़ है।"),
            WordExample(thai: "ผมไม่ชอบแดดครับ", romanization: "phǒm mâi chôp dàet kráp", english: "I don't like the sun.", hindi: "मुझे धूप पसंद नहीं है।"),
        ],
        97: [
            WordExample(thai: "วันนี้อากาศดีมาก", romanization: "wan-níi aa-kàat dii mâak", english: "The weather is very nice today.", hindi: "आज मौसम बहुत अच्छा है।"),
            WordExample(thai: "อากาศที่ภูเขาหนาวมาก", romanization: "aa-kàat thîi phuu-khǎo nǎao mâak", english: "The weather in the mountains is very cold.", hindi: "पहाड़ों का मौसम बहुत ठंडा है।"),
        ],
        117: [
            WordExample(thai: "ผมอ่านภาษาไทยไม่ได้ครับ", romanization: "phǒm àan phaa-sǎa-thai mâi dâai kráp", english: "I can't read Thai.", hindi: "मैं थाई नहीं पढ़ सकता।"),
            WordExample(thai: "คุณอ่านอันนี้ได้ไหมครับ", romanization: "khun àan an-níi dâai mǎi kráp", english: "Can you read this?", hindi: "क्या आप यह पढ़ सकते हैं?"),
        ],
        123: [
            WordExample(thai: "ผมทำงานที่ธนาคารครับ", romanization: "phǒm tham-ngaan thîi thá-naa-khaan kráp", english: "I work at a bank.", hindi: "मैं बैंक में काम करता हूँ।"),
            WordExample(thai: "พรุ่งนี้ผมไม่ทำงานครับ", romanization: "phrûng-níi phǒm mâi tham-ngaan kráp", english: "I don't work tomorrow.", hindi: "कल मैं काम नहीं करूँगा।"),
        ],
        131: [
            WordExample(thai: "หยุดที่นี่ครับ", romanization: "yùt thîi-nîi kráp", english: "Stop here, please.", hindi: "यहाँ रोकिए।"),
            WordExample(thai: "วันนี้ผมหยุดงานครับ", romanization: "wan-níi phǒm yùt ngaan kráp", english: "I'm off work today.", hindi: "आज मेरी काम से छुट्टी है।"),
        ],
        137: [
            WordExample(thai: "พูดช้าๆ หน่อยครับ", romanization: "phûut cháa-cháa nòi kráp", english: "Please speak slowly.", hindi: "कृपया थोड़ा धीरे बोलिए।"),
            WordExample(thai: "วันนี้รถไฟมาช้าครับ", romanization: "wan-níi rót-fai maa cháa kráp", english: "The train came late today.", hindi: "आज ट्रेन देर से आई।"),
        ],
        143: [
            WordExample(thai: "โรงแรมอยู่ใกล้ตลาดครับ", romanization: "roong-raem yùu klâi tà-làat kráp", english: "The hotel is near the market.", hindi: "होटल बाज़ार के पास है।"),
            WordExample(thai: "ที่นี่ใกล้ทะเลไหมครับ", romanization: "thîi-nîi klâi thá-lee mǎi kráp", english: "Is it near the sea here?", hindi: "क्या यह जगह समुद्र के पास है?"),
        ],
        151: [
            WordExample(thai: "ขอข้าวผัดและน้ำส้มครับ", romanization: "khǒo khâao-phàt láe nám-sôm kráp", english: "Fried rice and orange juice, please.", hindi: "फ्राइड राइस और संतरे का रस दीजिए।"),
            WordExample(thai: "ผมชอบทะเลและภูเขาครับ", romanization: "phǒm chôp thá-lee láe phuu-khǎo kráp", english: "I like the sea and the mountains.", hindi: "मुझे समुद्र और पहाड़ पसंद हैं।"),
            WordExample(thai: "ผมและเพื่อนไปตลาด", romanization: "phǒm láe phûean pai tà-làat", english: "My friend and I are going to the market.", hindi: "मैं और मेरा दोस्त बाज़ार जा रहे हैं।"),
        ],
        162: [
            WordExample(thai: "ผมชอบกินผักครับ", romanization: "phǒm chôp kin phàk kráp", english: "I like eating vegetables.", hindi: "मुझे सब्ज़ियाँ खाना पसंद है।"),
            WordExample(thai: "ขอไม่ใส่ผักครับ", romanization: "khǒo mâi sài phàk kráp", english: "Without vegetables, please.", hindi: "कृपया सब्ज़ी मत डालिए।"),
        ],
        168: [
            WordExample(thai: "แกงไทยเผ็ดมาก", romanization: "kaeng thai phèt mâak", english: "Thai curry is very spicy.", hindi: "थाई करी बहुत तीखी होती है।"),
            WordExample(thai: "ขอแกงไก่หนึ่งที่ครับ", romanization: "khǒo kaeng kài nèung thîi kráp", english: "One chicken curry, please.", hindi: "एक चिकन करी दीजिए।"),
        ],
        175: [
            WordExample(thai: "เลี้ยวซ้ายที่นี่ครับ", romanization: "líao sáai thîi-nîi kráp", english: "Turn left here.", hindi: "यहाँ बाएँ मुड़िए।"),
            WordExample(thai: "ห้องน้ำอยู่ทางซ้ายครับ", romanization: "hông-náam yùu thaang sáai kráp", english: "The toilet is on the left.", hindi: "शौचालय बाईं ओर है।"),
        ],
        181: [
            WordExample(thai: "ห้องน้ำอยู่ข้างล่างครับ", romanization: "hông-náam yùu khâang-lâang kráp", english: "The toilet is downstairs.", hindi: "शौचालय नीचे है।"),
            WordExample(thai: "รอผมข้างล่างนะครับ", romanization: "roo phǒm khâang-lâang ná kráp", english: "Wait for me downstairs, okay?", hindi: "नीचे मेरा इंतज़ार कीजिए।"),
        ],
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
        57: "อาหาร (aa-hǎan) food / खाना + เช้า → อาหารเช้า breakfast / नाश्ता",
        68: "ผู้ (phûu) person / व्यक्ति + ชาย (chaai) male / पुरुष → \"male person\" = man / आदमी",
        74: "น้ำ (náam) water / पानी + ตา → น้ำตา tears / आँसू",
        80: "หมอ + ฟัน (fan) tooth / दाँत → หมอฟัน dentist / दाँतों का डॉक्टर",
        124: "เดิน + ทาง (thaang) way / रास्ता → เดินทาง to travel / यात्रा करना",
        163: "แกง (kaeng) curry / करी + ไก่ → แกงไก่ chicken curry / चिकन करी · ไข่ (khài) egg / अंडा + ไก่ → ไข่ไก่ hen's egg / मुर्गी का अंडा",
        182: "น้ำ (náam) water / पानी + แข็ง (khǎeng) hard / सख़्त → \"hard water\" = ice / बर्फ़",
        23: "ขอบ (khòp) + คุณ → ขอบคุณ thank you / धन्यवाद",
        43: "น้ำ (náam) water / पानी + ร้อน → น้ำร้อน hot water / गरम पानी",
        58: "น้ำ + เย็น → น้ำเย็น cold water / ठंडा पानी (เย็น also means cool / ठंडा)",
        69: "ผู้ (phûu) person / व्यक्ति + หญิง (yǐng) female / स्त्री → \"female person\" = woman / औरत",
        75: "มือ + ถือ (thǔue) to hold / पकड़ना → มือถือ mobile phone / मोबाइल फ़ोन",
        81: "ยา + สีฟัน (sǐi-fan) → ยาสีฟัน toothpaste / टूथपेस्ट",
        93: "อาหาร (aa-hǎan) food / खाना + ทะเล → อาหารทะเล seafood / समुद्री भोजन",
        119: "ดู + แล (lae) to look / देखना → ดูแล to take care of / देखभाल करना",
        147: "เมื่อ (mûea) time / जब + ไหร่ (rài) what / क्या → \"what time\" = when? / कब?",
        164: "ไข่ + เจียว (jiao) to fry / तलना → ไข่เจียว Thai omelette / आमलेट · ไข่ + ไก่ (kài) chicken / मुर्गी → ไข่ไก่ hen's egg / मुर्गी का अंडा",
        171: "สถานี (sà-thǎa-nii) station / स्टेशन + ตำรวจ → สถานีตำรวจ police station / पुलिस थाना",
        183: "ข้าว (khâao) rice / चावल + ผัด (phàt) stir-fried / भूना हुआ → \"stir-fried rice\" = fried rice / फ्राइड राइस",
        24: "เพื่อน + บ้าน (bâan) house / घर → เพื่อนบ้าน neighbor / पड़ोसी",
        44: "หน้า (nâa) season / मौसम + หนาว → หน้าหนาว winter (cold season) / सर्दी का मौसम",
        53: "เมื่อ (mûea) time when / जब + วาน (waan) yesterday / बीता दिन → \"the time of yesterday\" = yesterday / बीता कल",
        70: "เด็ก + ผู้ชาย (phûu-chaai) man → เด็กผู้ชาย boy / लड़का · เด็ก + ผู้หญิง (phûu-yǐng) woman → เด็กผู้หญิง girl / लड़की",
        76: "ใจ + ดี (dii) good / अच्छा → ใจดี kind / दयालु · เข้า (khâo) to enter / घुसना + ใจ → เข้าใจ understand / समझना",
        94: "ภู (phuu) mount / पर्वत + เขา (khǎo) hill / पहाड़ी → \"mount-hill\" = mountain / पहाड़",
        120: "ห้อง (hông) room / कमरा + นอน → ห้องนอน bedroom / सोने का कमरा",
        127: "รู้ + จัก (jàk) → รู้จัก to know (a person/place) / (किसी को) जानना",
        134: "ปี (pii) year / साल + ใหม่ → ปีใหม่ New Year / नया साल",
        148: "ทำ (tham) to do / करना + ไม (mai, short form of อะไร \"what\") / क्या → \"do what?\" = why / क्यों",
        154: "ที่ (thîi) place / जगह + นี่ → ที่นี่ here / यहाँ",
        165: "ชา (chaa) tea / चाय + นม → ชานม milk tea / दूध वाली चाय",
        178: "ที่ (thîi) place / जगह + นี่ (nîi) this / यह → \"this place\" = here / यहाँ",
        184: "น้ำ (náam) water / पानी + ส้ม (sôm) orange / संतरा → \"orange water\" = orange juice / संतरे का रस",
        9: "สบาย (sà-baai) comfortable / आराम में + ดี (dii) good / अच्छा + ไหม (mǎi) question particle / प्रश्न-शब्द → \"(are you) well?\" = how are you? / आप कैसे हैं?",
        25: "ครอบ (khrôp) to cover / ढकना + ครัว (khrua) kitchen / रसोई → \"those under one kitchen roof\" = family / परिवार",
        39: "สบาย (sà-baai) comfortable / आराम + ดี → สบายดี I'm fine / मैं ठीक हूँ · ดี + ใจ (jai) heart / दिल → ดีใจ glad / ख़ुश",
        54: "ตรง (trong) straight / सीधा + เวลา → ตรงเวลา on time / समय पर",
        60: "ปี + ใหม่ (mài) new / नया → ปีใหม่ New Year / नया साल",
        71: "ชื่อ + เล่น (lên) to play / खेलना → ชื่อเล่น nickname / उपनाम",
        77: "ปวด (pùat) to ache / दर्द + ฟัน → ปวดฟัน toothache / दाँत दर्द · แปรง (praeng) brush / ब्रश + ฟัน → แปรงฟัน to brush teeth / दाँत साफ़ करना",
        83: "สี + แดง (daeng) red / लाल → สีแดง red (color) / लाल रंग · สี + ขาว (khǎao) white / सफ़ेद → สีขาว white (color) / सफ़ेद रंग",
        121: "ตื่น + นอน (noon) to sleep / सोना → ตื่นนอน to wake up / नींद से जागना · ตื่น + เต้น (tên) to dance / नाचना → ตื่นเต้น excited / रोमांचित",
        128: "คิด + ถึง (thǔeng) to reach / तक पहुँचना → คิดถึง to miss (someone) / याद आना",
        135: "เพื่อน (phûean) friend / दोस्त + เก่า → เพื่อนเก่า old friend / पुराना दोस्त",
        141: "เหนื่อย + ใจ (jai) heart / दिल → เหนื่อยใจ disheartened / मन से थका हुआ",
        155: "ที่ (thîi) place / जगह + นั่น → ที่นั่น there / वहाँ",
        179: "ที่ (thîi) place / जगह + นั่น (nân) that / वह → \"that place\" = there / वहाँ",
        185: "รถ (rót) car / गाड़ी + ไฟ → รถไฟ train / रेलगाड़ी · ไฟ + ฟ้า (fáa) sky / आसमान → ไฟฟ้า electricity / बिजली · ไฟ + แดง (daeng) red / लाल → ไฟแดง red (traffic) light / लाल बत्ती",
        10: "สบาย (sà-baai) comfortable, well / आराम + ดี (dii) good / अच्छा → \"well and good\" = I'm fine / मैं ठीक हूँ · สบายดี + ไหม (mǎi) question word → สบายดีไหม how are you? / आप कैसे हैं?",
        40: "สวย + งาม (ngaam) graceful / शोभायमान → สวยงาม beautiful, lovely / सुंदर",
        47: "รถ + ไฟ (fai) fire / आग → รถไฟ train / रेलगाड़ी",
        55: "ชั่ว (chûa) span, period / अवधि + โมง (moong) o'clock / बजे → \"span of clock-time\" = hour / घंटा",
        61: "เดือน + หน้า (nâa) next, front / अगला → เดือนหน้า next month / अगला महीना",
        78: "ปวด + หัว (hǔa) head / सिर → ปวดหัว headache / सिरदर्द · ปวด + ฟัน (fan) tooth / दाँत → ปวดฟัน toothache / दाँत का दर्द",
        90: "ฝน + ตก (tòk) to fall / गिरना → ฝนตก it rains / बारिश होना",
        122: "ทำ + งาน (ngaan) work / काम → ทำงาน to work / काम करना · ทำ + อาหาร (aa-hǎan) food / खाना → ทำอาหาร to cook / खाना बनाना",
        142: "ของ (khǒong) thing / चीज़ + หวาน → ของหวาน dessert / मिठाई",
        150: "spoken form of อย่างไร: อย่าง (yàang) manner / ढंग + ไร (rai) what / क्या → \"in what way\" = how? / कैसे?",
        174: "โทร (thoo) far, to call / दूर + ศัพท์ (sàp) word, sound (Sanskrit शब्द) / शब्द → \"far-sound\" = telephone / टेलीफ़ोन",
        186: "รถ (rót) vehicle / गाड़ी + ไฟ (fai) fire / आग → \"fire cart\" = train / रेलगाड़ी",
        32: "ชา + ร้อน (rón) hot / गरम → ชาร้อน hot tea / गरम चाय · ชา + เย็น (yen) cool / ठंडा → ชาเย็น Thai iced tea / थाई आइस टी",
        41: "ผู้ (phûu) person / व्यक्ति + ใหญ่ → ผู้ใหญ่ (phûu-yài) adult, elder / वयस्क",
        50: "ถูก + ใจ (jai) heart / दिल → ถูกใจ (thùuk-jai) pleasing, to one's liking / मन को भाना",
        73: "หัว + ใจ (jai) heart, mind / दिल → หัวใจ (hǔa-jai) heart (organ) / हृदय",
        79: "ผู้ (phûu) person / व्यक्ति + ป่วย → ผู้ป่วย (phûu-pùai) patient / मरीज़",
        131: "วัน (wan) day / दिन + หยุด → วันหยุด (wan-yùt) holiday, day off / छुट्टी का दिन",
        168: "แกง + เขียว (khǐao) green / हरा + หวาน (wǎan) sweet / मीठा → แกงเขียวหวาน (kaeng-khǐao-wǎan) green curry / ग्रीन करी",
        175: "มือ (muue) hand / हाथ + ซ้าย → มือซ้าย (muue-sáai) left hand / बायाँ हाथ",
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
