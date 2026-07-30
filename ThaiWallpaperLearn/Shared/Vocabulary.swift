import Foundation

/// Master list of Thai vocabulary bundled with the app.
///
/// Pronunciations are phonetic approximations meant as a learning aid:
///  - `romanization`       uses a simplified Latin spelling (tones marked lightly).
///  - `hindiPronunciation` uses Devanagari so a Hindi speaker can sound the word out.
enum Vocabulary {
    static let all: [ThaiWord] = [
        // MARK: Greetings & everyday phrases
        ThaiWord(id: 1,  thai: "สวัสดี",       romanization: "sà-wàt-dii",        hindiPronunciation: "स-वट-दी",       englishMeaning: "hello / hi",            hindiMeaning: "नमस्ते",              category: "Greetings"),
        ThaiWord(id: 2,  thai: "ขอบคุณ",       romanization: "khòp-khun",         hindiPronunciation: "खोब-कुन",        englishMeaning: "thank you",             hindiMeaning: "धन्यवाद",             category: "Greetings"),
        ThaiWord(id: 3,  thai: "ครับ",         romanization: "kráp",              hindiPronunciation: "क्रब",           englishMeaning: "polite particle (male)", hindiMeaning: "आदरसूचक शब्द (पुरुष)", category: "Grammar"),
        ThaiWord(id: 4,  thai: "ค่ะ",          romanization: "khâ",               hindiPronunciation: "खा",             englishMeaning: "polite particle (female)", hindiMeaning: "आदरसूचक शब्द (स्त्री)", category: "Grammar"),
        ThaiWord(id: 5,  thai: "ใช่",          romanization: "châi",              hindiPronunciation: "चाइ",            englishMeaning: "yes",                   hindiMeaning: "हाँ",                 category: "Basics"),
        ThaiWord(id: 6,  thai: "ไม่",          romanization: "mâi",               hindiPronunciation: "माइ",            englishMeaning: "no / not",              hindiMeaning: "नहीं",                category: "Basics"),
        ThaiWord(id: 7,  thai: "ไม่เป็นไร",   romanization: "mâi-pen-rai",       hindiPronunciation: "माइ-पेन-राइ",   englishMeaning: "you're welcome / no problem", hindiMeaning: "कोई बात नहीं",       category: "Greetings"),
        ThaiWord(id: 8,  thai: "ขอโทษ",        romanization: "khǒo-thôot",        hindiPronunciation: "खो-थोद",         englishMeaning: "sorry / excuse me",     hindiMeaning: "माफ़ कीजिए",          category: "Greetings"),
        ThaiWord(id: 9,  thai: "สบายดีไหม",   romanization: "sà-baai-dii-mǎi",   hindiPronunciation: "स-बाइ-दी-माइ",  englishMeaning: "how are you?",          hindiMeaning: "आप कैसे हैं?",        category: "Greetings"),
        ThaiWord(id: 10, thai: "สบายดี",       romanization: "sà-baai-dii",       hindiPronunciation: "स-बाइ-दी",      englishMeaning: "I'm fine",              hindiMeaning: "मैं ठीक हूँ",         category: "Greetings"),

        // MARK: Numbers
        ThaiWord(id: 11, thai: "หนึ่ง",        romanization: "nèung",             hindiPronunciation: "नुंग",           englishMeaning: "one",                   hindiMeaning: "एक",                  category: "Numbers"),
        ThaiWord(id: 12, thai: "สอง",          romanization: "sǒong",             hindiPronunciation: "सोंग",           englishMeaning: "two",                   hindiMeaning: "दो",                  category: "Numbers"),
        ThaiWord(id: 13, thai: "สาม",          romanization: "sǎam",              hindiPronunciation: "साम",            englishMeaning: "three",                 hindiMeaning: "तीन",                 category: "Numbers"),
        ThaiWord(id: 14, thai: "สี่",          romanization: "sìi",               hindiPronunciation: "सी",             englishMeaning: "four",                  hindiMeaning: "चार",                 category: "Numbers"),
        ThaiWord(id: 15, thai: "ห้า",          romanization: "hâa",               hindiPronunciation: "हा",             englishMeaning: "five",                  hindiMeaning: "पाँच",                category: "Numbers"),
        ThaiWord(id: 16, thai: "หก",           romanization: "hòk",               hindiPronunciation: "होक",            englishMeaning: "six",                   hindiMeaning: "छह",                  category: "Numbers"),
        ThaiWord(id: 17, thai: "เจ็ด",         romanization: "jèt",               hindiPronunciation: "जेद",            englishMeaning: "seven",                 hindiMeaning: "सात",                 category: "Numbers"),
        ThaiWord(id: 18, thai: "แปด",          romanization: "pàet",              hindiPronunciation: "पैद",            englishMeaning: "eight",                 hindiMeaning: "आठ",                  category: "Numbers"),
        ThaiWord(id: 19, thai: "เก้า",         romanization: "kâo",               hindiPronunciation: "काउ",            englishMeaning: "nine",                  hindiMeaning: "नौ",                  category: "Numbers"),
        ThaiWord(id: 20, thai: "สิบ",          romanization: "sìp",               hindiPronunciation: "सिप",            englishMeaning: "ten",                   hindiMeaning: "दस",                  category: "Numbers"),

        // MARK: People
        ThaiWord(id: 21, thai: "ผม",           romanization: "phǒm",              hindiPronunciation: "पोम",            englishMeaning: "I / me (male)",         hindiMeaning: "मैं (पुरुष)",         category: "People"),
        ThaiWord(id: 22, thai: "ฉัน",          romanization: "chǎn",              hindiPronunciation: "छान",            englishMeaning: "I / me (female)",       hindiMeaning: "मैं (स्त्री)",        category: "People"),
        ThaiWord(id: 23, thai: "คุณ",          romanization: "khun",              hindiPronunciation: "कुन",            englishMeaning: "you",                   hindiMeaning: "आप / तुम",            category: "People"),
        ThaiWord(id: 24, thai: "เพื่อน",       romanization: "phûean",            hindiPronunciation: "फुअन",           englishMeaning: "friend",                hindiMeaning: "दोस्त",               category: "People"),
        ThaiWord(id: 25, thai: "ครอบครัว",    romanization: "khrôp-khrua",       hindiPronunciation: "क्रोब-क्रुआ",   englishMeaning: "family",                hindiMeaning: "परिवार",              category: "People"),

        // MARK: Food & drink
        ThaiWord(id: 26, thai: "อาหาร",        romanization: "aa-hǎan",           hindiPronunciation: "आ-हान",          englishMeaning: "food",                  hindiMeaning: "खाना / भोजन",         category: "Food"),
        ThaiWord(id: 27, thai: "น้ำ",          romanization: "náam",              hindiPronunciation: "नाम",            englishMeaning: "water",                 hindiMeaning: "पानी",                category: "Food"),
        ThaiWord(id: 28, thai: "ข้าว",         romanization: "khâao",             hindiPronunciation: "खाउ",            englishMeaning: "rice",                  hindiMeaning: "चावल",                category: "Food"),
        ThaiWord(id: 29, thai: "กิน",          romanization: "kin",               hindiPronunciation: "किन",            englishMeaning: "to eat",                hindiMeaning: "खाना (क्रिया)",       category: "Food"),
        ThaiWord(id: 30, thai: "อร่อย",        romanization: "à-ròi",             hindiPronunciation: "अ-रोइ",          englishMeaning: "delicious",             hindiMeaning: "स्वादिष्ट",           category: "Food"),
        ThaiWord(id: 31, thai: "กาแฟ",         romanization: "kaa-fae",           hindiPronunciation: "का-फै",          englishMeaning: "coffee",                hindiMeaning: "कॉफ़ी",               category: "Food"),
        ThaiWord(id: 32, thai: "ชา",           romanization: "chaa",              hindiPronunciation: "चा",             englishMeaning: "tea",                   hindiMeaning: "चाय",                 category: "Food"),
        ThaiWord(id: 33, thai: "เผ็ด",         romanization: "phèt",              hindiPronunciation: "फेद",            englishMeaning: "spicy",                 hindiMeaning: "तीखा / मसालेदार",     category: "Food"),
        ThaiWord(id: 34, thai: "หิว",          romanization: "hǐu",               hindiPronunciation: "हिउ",            englishMeaning: "hungry",                hindiMeaning: "भूखा",                category: "Food"),

        // MARK: Verbs & adjectives
        ThaiWord(id: 35, thai: "ไป",           romanization: "pai",               hindiPronunciation: "पाइ",            englishMeaning: "to go",                 hindiMeaning: "जाना",                category: "Verbs"),
        ThaiWord(id: 36, thai: "มา",           romanization: "maa",               hindiPronunciation: "मा",             englishMeaning: "to come",               hindiMeaning: "आना",                 category: "Verbs"),
        ThaiWord(id: 37, thai: "รัก",          romanization: "rák",               hindiPronunciation: "रक",             englishMeaning: "to love",               hindiMeaning: "प्यार करना",          category: "Verbs"),
        ThaiWord(id: 38, thai: "ชอบ",          romanization: "chôp",              hindiPronunciation: "चोब",            englishMeaning: "to like",               hindiMeaning: "पसंद करना",           category: "Verbs"),
        ThaiWord(id: 39, thai: "ดี",           romanization: "dii",               hindiPronunciation: "दी",             englishMeaning: "good",                  hindiMeaning: "अच्छा",               category: "Adjectives"),
        ThaiWord(id: 40, thai: "สวย",          romanization: "sǔai",              hindiPronunciation: "सुआय",           englishMeaning: "beautiful",             hindiMeaning: "सुंदर",               category: "Adjectives"),
        ThaiWord(id: 41, thai: "ใหญ่",         romanization: "yài",               hindiPronunciation: "याय",            englishMeaning: "big",                   hindiMeaning: "बड़ा",                category: "Adjectives"),
        ThaiWord(id: 42, thai: "เล็ก",         romanization: "lék",               hindiPronunciation: "लेक",            englishMeaning: "small",                 hindiMeaning: "छोटा",                category: "Adjectives"),
        ThaiWord(id: 43, thai: "ร้อน",         romanization: "rón",               hindiPronunciation: "रोन",            englishMeaning: "hot",                   hindiMeaning: "गरम",                 category: "Adjectives"),
        ThaiWord(id: 44, thai: "หนาว",         romanization: "nǎao",              hindiPronunciation: "नाउ",            englishMeaning: "cold",                  hindiMeaning: "ठंडा",                category: "Adjectives"),

        // MARK: Travel & getting around
        ThaiWord(id: 45, thai: "ห้องน้ำ",      romanization: "hông-náam",         hindiPronunciation: "होंग-नाम",       englishMeaning: "toilet / bathroom",     hindiMeaning: "शौचालय",              category: "Travel"),
        ThaiWord(id: 46, thai: "โรงแรม",       romanization: "roong-raem",        hindiPronunciation: "रोंग-रैम",       englishMeaning: "hotel",                 hindiMeaning: "होटल",                category: "Travel"),
        ThaiWord(id: 47, thai: "รถ",           romanization: "rót",               hindiPronunciation: "रोद",            englishMeaning: "car / vehicle",         hindiMeaning: "गाड़ी",               category: "Travel"),
        ThaiWord(id: 48, thai: "เท่าไหร่",     romanization: "thâo-rài",          hindiPronunciation: "ताउ-राय",        englishMeaning: "how much?",             hindiMeaning: "कितना?",              category: "Travel"),
        ThaiWord(id: 49, thai: "แพง",          romanization: "phaeng",            hindiPronunciation: "फैंग",           englishMeaning: "expensive",             hindiMeaning: "महँगा",               category: "Travel"),
        ThaiWord(id: 50, thai: "ถูก",          romanization: "thùuk",             hindiPronunciation: "थूक",            englishMeaning: "cheap",                 hindiMeaning: "सस्ता",               category: "Travel"),

        // MARK: Time
        ThaiWord(id: 51, thai: "วันนี้",       romanization: "wan-níi",           hindiPronunciation: "वन-नी",          englishMeaning: "today",                 hindiMeaning: "आज",                  category: "Time"),
        ThaiWord(id: 52, thai: "พรุ่งนี้",     romanization: "phrûng-níi",        hindiPronunciation: "फ्रुंग-नी",      englishMeaning: "tomorrow",              hindiMeaning: "कल (आने वाला)",       category: "Time"),
    ]

    /// A stable, per-day rotation offset so the "word of the day" changes daily.
    static func word(forDayOffset offset: Int) -> ThaiWord {
        let index = ((offset % all.count) + all.count) % all.count
        return all[index]
    }

    /// A random word (used by the widget's rotation and the app's shuffle button).
    static func randomWord() -> ThaiWord {
        all.randomElement() ?? all[0]
    }

    static var categories: [String] {
        var seen = Set<String>()
        return all.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }
}
