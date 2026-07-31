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
        ThaiWord(id: 53, thai: "เมื่อวาน",     romanization: "mûea-waan",         hindiPronunciation: "मुआ-वान",        englishMeaning: "yesterday",             hindiMeaning: "बीता कल",             category: "Time"),
        ThaiWord(id: 54, thai: "เวลา",         romanization: "wee-laa",           hindiPronunciation: "वे-ला",          englishMeaning: "time",                  hindiMeaning: "समय",                 category: "Time"),
        ThaiWord(id: 55, thai: "ชั่วโมง",      romanization: "chûa-moong",        hindiPronunciation: "चुआ-मोंग",       englishMeaning: "hour",                  hindiMeaning: "घंटा",                category: "Time"),
        ThaiWord(id: 56, thai: "นาที",         romanization: "naa-thii",          hindiPronunciation: "ना-ती",          englishMeaning: "minute",                hindiMeaning: "मिनट",                category: "Time"),
        ThaiWord(id: 57, thai: "เช้า",         romanization: "cháao",             hindiPronunciation: "चाउ",            englishMeaning: "morning",               hindiMeaning: "सुबह",                category: "Time"),
        ThaiWord(id: 58, thai: "เย็น",         romanization: "yen",               hindiPronunciation: "येन",            englishMeaning: "evening",               hindiMeaning: "शाम",                 category: "Time"),
        ThaiWord(id: 59, thai: "กลางคืน",     romanization: "klaang-khuen",      hindiPronunciation: "क्लांग-खुएन",    englishMeaning: "night",                 hindiMeaning: "रात",                 category: "Time"),
        ThaiWord(id: 60, thai: "ปี",           romanization: "pii",               hindiPronunciation: "पी",             englishMeaning: "year",                  hindiMeaning: "साल",                 category: "Time"),
        ThaiWord(id: 61, thai: "เดือน",        romanization: "duean",             hindiPronunciation: "दुअन",           englishMeaning: "month",                 hindiMeaning: "महीना",               category: "Time"),
        ThaiWord(id: 62, thai: "สัปดาห์",      romanization: "sàp-daa",           hindiPronunciation: "सप-दा",          englishMeaning: "week",                  hindiMeaning: "सप्ताह",              category: "Time"),

        // MARK: Family & people
        ThaiWord(id: 63, thai: "พ่อ",          romanization: "phôo",              hindiPronunciation: "पॉ",             englishMeaning: "father",                hindiMeaning: "पिता",                category: "Family"),
        ThaiWord(id: 64, thai: "แม่",          romanization: "mâe",               hindiPronunciation: "मै",             englishMeaning: "mother",                hindiMeaning: "माँ",                 category: "Family"),
        ThaiWord(id: 65, thai: "ลูก",          romanization: "lûuk",              hindiPronunciation: "लूक",            englishMeaning: "child (son/daughter)",  hindiMeaning: "संतान / बच्चा",       category: "Family"),
        ThaiWord(id: 66, thai: "พี่",          romanization: "phîi",              hindiPronunciation: "पी",             englishMeaning: "older sibling",         hindiMeaning: "बड़ा भाई / बड़ी बहन", category: "Family"),
        ThaiWord(id: 67, thai: "น้อง",         romanization: "nóong",             hindiPronunciation: "नोंग",           englishMeaning: "younger sibling",       hindiMeaning: "छोटा भाई / छोटी बहन", category: "Family"),
        ThaiWord(id: 68, thai: "ผู้ชาย",       romanization: "phûu-chaai",        hindiPronunciation: "पू-चाय",         englishMeaning: "man",                   hindiMeaning: "आदमी",                category: "People"),
        ThaiWord(id: 69, thai: "ผู้หญิง",      romanization: "phûu-yǐng",         hindiPronunciation: "पू-यिंग",        englishMeaning: "woman",                 hindiMeaning: "औरत",                 category: "People"),
        ThaiWord(id: 70, thai: "เด็ก",         romanization: "dèk",               hindiPronunciation: "देक",            englishMeaning: "child / kid",           hindiMeaning: "बच्चा",               category: "People"),
        ThaiWord(id: 71, thai: "ชื่อ",         romanization: "chûue",             hindiPronunciation: "चू",             englishMeaning: "name",                  hindiMeaning: "नाम",                 category: "People"),
        ThaiWord(id: 72, thai: "ครู",          romanization: "khruu",             hindiPronunciation: "क्रू",           englishMeaning: "teacher",               hindiMeaning: "शिक्षक",              category: "People"),

        // MARK: Body & health
        ThaiWord(id: 73, thai: "หัว",          romanization: "hǔa",               hindiPronunciation: "हुआ",            englishMeaning: "head",                  hindiMeaning: "सिर",                 category: "Body"),
        ThaiWord(id: 74, thai: "ตา",           romanization: "taa",               hindiPronunciation: "ता",             englishMeaning: "eye",                   hindiMeaning: "आँख",                 category: "Body"),
        ThaiWord(id: 75, thai: "มือ",          romanization: "muue",              hindiPronunciation: "मू",             englishMeaning: "hand",                  hindiMeaning: "हाथ",                 category: "Body"),
        ThaiWord(id: 76, thai: "ใจ",           romanization: "jai",               hindiPronunciation: "जाय",            englishMeaning: "heart / mind",          hindiMeaning: "दिल / मन",            category: "Body"),
        ThaiWord(id: 77, thai: "ฟัน",          romanization: "fan",               hindiPronunciation: "फन",             englishMeaning: "tooth",                 hindiMeaning: "दाँत",                category: "Body"),
        ThaiWord(id: 78, thai: "ปวด",          romanization: "pùat",              hindiPronunciation: "पुआद",           englishMeaning: "to ache / pain",        hindiMeaning: "दर्द होना",           category: "Health"),
        ThaiWord(id: 79, thai: "ป่วย",         romanization: "pùai",              hindiPronunciation: "पुआय",           englishMeaning: "sick / ill",            hindiMeaning: "बीमार",               category: "Health"),
        ThaiWord(id: 80, thai: "หมอ",          romanization: "mǒo",               hindiPronunciation: "मो",             englishMeaning: "doctor",                hindiMeaning: "डॉक्टर",              category: "Health"),
        ThaiWord(id: 81, thai: "ยา",           romanization: "yaa",               hindiPronunciation: "या",             englishMeaning: "medicine",              hindiMeaning: "दवा",                 category: "Health"),
        ThaiWord(id: 82, thai: "โรงพยาบาล",   romanization: "roong-phá-yaa-baan", hindiPronunciation: "रोंग-पया-बान",  englishMeaning: "hospital",              hindiMeaning: "अस्पताल",             category: "Health"),

        // MARK: Colors
        ThaiWord(id: 83, thai: "สี",           romanization: "sǐi",               hindiPronunciation: "सी",             englishMeaning: "color",                 hindiMeaning: "रंग",                 category: "Colors"),
        ThaiWord(id: 84, thai: "แดง",          romanization: "daeng",             hindiPronunciation: "दैंग",           englishMeaning: "red",                   hindiMeaning: "लाल",                 category: "Colors"),
        ThaiWord(id: 85, thai: "ขาว",          romanization: "khǎao",             hindiPronunciation: "खाउ",            englishMeaning: "white",                 hindiMeaning: "सफ़ेद",               category: "Colors"),
        ThaiWord(id: 86, thai: "ดำ",           romanization: "dam",               hindiPronunciation: "दम",             englishMeaning: "black",                 hindiMeaning: "काला",                category: "Colors"),
        ThaiWord(id: 87, thai: "เขียว",        romanization: "khǐao",             hindiPronunciation: "खियाउ",          englishMeaning: "green",                 hindiMeaning: "हरा",                 category: "Colors"),
        ThaiWord(id: 88, thai: "ฟ้า",          romanization: "fáa",               hindiPronunciation: "फ़ा",            englishMeaning: "blue (sky blue)",       hindiMeaning: "नीला / आसमानी",       category: "Colors"),
        ThaiWord(id: 89, thai: "เหลือง",       romanization: "lǔeang",            hindiPronunciation: "लुअंग",          englishMeaning: "yellow",                hindiMeaning: "पीला",                category: "Colors"),

        // MARK: Nature & weather
        ThaiWord(id: 90, thai: "ฝน",           romanization: "fǒn",               hindiPronunciation: "फ़ोन",           englishMeaning: "rain",                  hindiMeaning: "बारिश",               category: "Nature"),
        ThaiWord(id: 91, thai: "แดด",          romanization: "dàet",              hindiPronunciation: "दैद",            englishMeaning: "sunshine",              hindiMeaning: "धूप",                 category: "Nature"),
        ThaiWord(id: 92, thai: "ลม",           romanization: "lom",               hindiPronunciation: "लोम",            englishMeaning: "wind",                  hindiMeaning: "हवा",                 category: "Nature"),
        ThaiWord(id: 93, thai: "ทะเล",         romanization: "thá-lee",           hindiPronunciation: "त-ले",           englishMeaning: "sea",                   hindiMeaning: "समुद्र",              category: "Nature"),
        ThaiWord(id: 94, thai: "ภูเขา",        romanization: "phuu-khǎo",         hindiPronunciation: "पू-खाउ",         englishMeaning: "mountain",              hindiMeaning: "पहाड़",               category: "Nature"),
        ThaiWord(id: 95, thai: "ต้นไม้",       romanization: "tôn-mái",           hindiPronunciation: "तोन-माय",        englishMeaning: "tree",                  hindiMeaning: "पेड़",                category: "Nature"),
        ThaiWord(id: 96, thai: "ดอกไม้",       romanization: "dòk-mái",           hindiPronunciation: "दोक-माय",        englishMeaning: "flower",                hindiMeaning: "फूल",                 category: "Nature"),
        ThaiWord(id: 97, thai: "อากาศ",        romanization: "aa-kàat",           hindiPronunciation: "आ-काद",          englishMeaning: "weather / air",         hindiMeaning: "मौसम / हवा",          category: "Nature"),

        // MARK: Places
        ThaiWord(id: 98,  thai: "บ้าน",        romanization: "bâan",              hindiPronunciation: "बान",            englishMeaning: "house / home",          hindiMeaning: "घर",                  category: "Places"),
        ThaiWord(id: 99,  thai: "ตลาด",        romanization: "tà-làat",           hindiPronunciation: "त-लाद",          englishMeaning: "market",                hindiMeaning: "बाज़ार",              category: "Places"),
        ThaiWord(id: 100, thai: "ร้าน",        romanization: "ráan",              hindiPronunciation: "रान",            englishMeaning: "shop",                  hindiMeaning: "दुकान",               category: "Places"),
        ThaiWord(id: 101, thai: "ร้านอาหาร",   romanization: "ráan-aa-hǎan",      hindiPronunciation: "रान-आ-हान",     englishMeaning: "restaurant",            hindiMeaning: "रेस्टोरेंट",          category: "Places"),
        ThaiWord(id: 102, thai: "โรงเรียน",    romanization: "roong-rian",        hindiPronunciation: "रोंग-रियन",      englishMeaning: "school",                hindiMeaning: "स्कूल",               category: "Places"),
        ThaiWord(id: 103, thai: "วัด",         romanization: "wát",               hindiPronunciation: "वद",             englishMeaning: "temple",                hindiMeaning: "मंदिर",               category: "Places"),
        ThaiWord(id: 104, thai: "สนามบิน",     romanization: "sà-nǎam-bin",       hindiPronunciation: "स-नाम-बिन",     englishMeaning: "airport",               hindiMeaning: "हवाई अड्डा",          category: "Places"),
        ThaiWord(id: 105, thai: "ธนาคาร",      romanization: "thá-naa-khaan",     hindiPronunciation: "त-ना-खान",      englishMeaning: "bank",                  hindiMeaning: "बैंक",                category: "Places"),
        ThaiWord(id: 106, thai: "ถนน",         romanization: "thà-nǒn",           hindiPronunciation: "थ-नोन",          englishMeaning: "road / street",         hindiMeaning: "सड़क",                category: "Places"),
        ThaiWord(id: 107, thai: "เมือง",       romanization: "mueang",            hindiPronunciation: "मुअंग",          englishMeaning: "city / town",           hindiMeaning: "शहर",                 category: "Places"),
        ThaiWord(id: 108, thai: "ประเทศ",      romanization: "prà-thêet",         hindiPronunciation: "प्र-तेद",        englishMeaning: "country",               hindiMeaning: "देश",                 category: "Places"),

        // MARK: Money & shopping
        ThaiWord(id: 109, thai: "เงิน",        romanization: "ngoen",             hindiPronunciation: "ङर्न",             englishMeaning: "money",                 hindiMeaning: "पैसा",                category: "Money"),
        ThaiWord(id: 110, thai: "บาท",         romanization: "bàat",              hindiPronunciation: "बाद",            englishMeaning: "baht (Thai currency)",  hindiMeaning: "बात (थाई मुद्रा)",    category: "Money"),
        ThaiWord(id: 111, thai: "ซื้อ",        romanization: "súue",              hindiPronunciation: "सू",             englishMeaning: "to buy",                hindiMeaning: "खरीदना",              category: "Money"),
        ThaiWord(id: 112, thai: "ขาย",         romanization: "khǎai",             hindiPronunciation: "खाय",            englishMeaning: "to sell",               hindiMeaning: "बेचना",               category: "Money"),
        ThaiWord(id: 113, thai: "ลดราคา",      romanization: "lót-raa-khaa",      hindiPronunciation: "लोद-रा-खा",     englishMeaning: "discount",              hindiMeaning: "छूट",                 category: "Money"),
        ThaiWord(id: 114, thai: "ฟรี",         romanization: "frii",              hindiPronunciation: "फ्री",           englishMeaning: "free (no cost)",        hindiMeaning: "मुफ़्त",              category: "Money"),

        // MARK: More verbs
        ThaiWord(id: 115, thai: "พูด",         romanization: "phûut",             hindiPronunciation: "फूद",            englishMeaning: "to speak",              hindiMeaning: "बोलना",               category: "Verbs"),
        ThaiWord(id: 116, thai: "ฟัง",         romanization: "fang",              hindiPronunciation: "फंग",            englishMeaning: "to listen",             hindiMeaning: "सुनना",               category: "Verbs"),
        ThaiWord(id: 117, thai: "อ่าน",        romanization: "àan",               hindiPronunciation: "आन",             englishMeaning: "to read",               hindiMeaning: "पढ़ना",               category: "Verbs"),
        ThaiWord(id: 118, thai: "เขียน",       romanization: "khǐan",             hindiPronunciation: "खियन",           englishMeaning: "to write",              hindiMeaning: "लिखना",               category: "Verbs"),
        ThaiWord(id: 119, thai: "ดู",          romanization: "duu",               hindiPronunciation: "दू",             englishMeaning: "to look / watch",       hindiMeaning: "देखना",               category: "Verbs"),
        ThaiWord(id: 120, thai: "นอน",         romanization: "noon",              hindiPronunciation: "नोन",            englishMeaning: "to sleep",              hindiMeaning: "सोना",                category: "Verbs"),
        ThaiWord(id: 121, thai: "ตื่น",        romanization: "tùuen",             hindiPronunciation: "तून",            englishMeaning: "to wake up",            hindiMeaning: "जागना",               category: "Verbs"),
        ThaiWord(id: 122, thai: "ทำ",          romanization: "tham",              hindiPronunciation: "तम",             englishMeaning: "to do / make",          hindiMeaning: "करना",                category: "Verbs"),
        ThaiWord(id: 123, thai: "ทำงาน",       romanization: "tham-ngaan",        hindiPronunciation: "तम-ङान",        englishMeaning: "to work",               hindiMeaning: "काम करना",            category: "Verbs"),
        ThaiWord(id: 124, thai: "เดิน",        romanization: "doen",              hindiPronunciation: "दर्न",             englishMeaning: "to walk",               hindiMeaning: "चलना / टहलना",        category: "Verbs"),
        ThaiWord(id: 125, thai: "วิ่ง",        romanization: "wîng",              hindiPronunciation: "विंग",           englishMeaning: "to run",                hindiMeaning: "दौड़ना",              category: "Verbs"),
        ThaiWord(id: 126, thai: "เข้าใจ",      romanization: "khâo-jai",          hindiPronunciation: "खाउ-जाय",       englishMeaning: "to understand",         hindiMeaning: "समझना",               category: "Verbs"),
        ThaiWord(id: 127, thai: "รู้",          romanization: "rúu",               hindiPronunciation: "रू",             englishMeaning: "to know",               hindiMeaning: "जानना",               category: "Verbs"),
        ThaiWord(id: 128, thai: "คิด",         romanization: "khít",              hindiPronunciation: "खित",            englishMeaning: "to think",              hindiMeaning: "सोचना",               category: "Verbs"),
        ThaiWord(id: 129, thai: "ช่วย",        romanization: "chûai",             hindiPronunciation: "चुआय",           englishMeaning: "to help",               hindiMeaning: "मदद करना",            category: "Verbs"),
        ThaiWord(id: 130, thai: "รอ",          romanization: "roo",               hindiPronunciation: "रो",             englishMeaning: "to wait",               hindiMeaning: "इंतज़ार करना",        category: "Verbs"),
        ThaiWord(id: 131, thai: "หยุด",        romanization: "yùt",               hindiPronunciation: "युद",            englishMeaning: "to stop",               hindiMeaning: "रुकना",               category: "Verbs"),
        ThaiWord(id: 132, thai: "เปิด",        romanization: "pòet",              hindiPronunciation: "पर्द",             englishMeaning: "to open / turn on",     hindiMeaning: "खोलना / चालू करना",   category: "Verbs"),
        ThaiWord(id: 133, thai: "ปิด",         romanization: "pìt",               hindiPronunciation: "पिद",            englishMeaning: "to close / turn off",   hindiMeaning: "बंद करना",            category: "Verbs"),

        // MARK: More adjectives
        ThaiWord(id: 134, thai: "ใหม่",        romanization: "mài",               hindiPronunciation: "माय",            englishMeaning: "new",                   hindiMeaning: "नया",                 category: "Adjectives"),
        ThaiWord(id: 135, thai: "เก่า",        romanization: "kào",               hindiPronunciation: "काव",            englishMeaning: "old (things)",          hindiMeaning: "पुराना",              category: "Adjectives"),
        ThaiWord(id: 136, thai: "เร็ว",        romanization: "reo",               hindiPronunciation: "रेव",            englishMeaning: "fast",                  hindiMeaning: "तेज़",                category: "Adjectives"),
        ThaiWord(id: 137, thai: "ช้า",         romanization: "cháa",              hindiPronunciation: "चा",             englishMeaning: "slow",                  hindiMeaning: "धीमा",                category: "Adjectives"),
        ThaiWord(id: 138, thai: "ง่าย",        romanization: "ngâai",             hindiPronunciation: "ङाय",            englishMeaning: "easy",                  hindiMeaning: "आसान",                category: "Adjectives"),
        ThaiWord(id: 139, thai: "ยาก",         romanization: "yâak",              hindiPronunciation: "याक",            englishMeaning: "difficult",             hindiMeaning: "कठिन / मुश्किल",      category: "Adjectives"),
        ThaiWord(id: 140, thai: "สนุก",        romanization: "sà-nùk",            hindiPronunciation: "स-नुक",          englishMeaning: "fun / enjoyable",       hindiMeaning: "मज़ेदार",             category: "Adjectives"),
        ThaiWord(id: 141, thai: "เหนื่อย",     romanization: "nùeai",             hindiPronunciation: "नुअय",           englishMeaning: "tired",                 hindiMeaning: "थका हुआ",             category: "Adjectives"),
        ThaiWord(id: 142, thai: "หวาน",        romanization: "wǎan",              hindiPronunciation: "वान",            englishMeaning: "sweet",                 hindiMeaning: "मीठा",                category: "Adjectives"),
        ThaiWord(id: 143, thai: "ใกล้",        romanization: "klâi",              hindiPronunciation: "क्लाय",          englishMeaning: "near",                  hindiMeaning: "पास / नज़दीक",        category: "Adjectives"),
        ThaiWord(id: 144, thai: "ไกล",         romanization: "klai",              hindiPronunciation: "क्लाय",          englishMeaning: "far",                   hindiMeaning: "दूर",                 category: "Adjectives"),

        // MARK: Question words & connectors
        ThaiWord(id: 145, thai: "อะไร",        romanization: "à-rai",             hindiPronunciation: "अ-राय",          englishMeaning: "what?",                 hindiMeaning: "क्या?",               category: "Questions"),
        ThaiWord(id: 146, thai: "ที่ไหน",      romanization: "thîi-nǎi",          hindiPronunciation: "ती-नाय",         englishMeaning: "where?",                hindiMeaning: "कहाँ?",               category: "Questions"),
        ThaiWord(id: 147, thai: "เมื่อไหร่",   romanization: "mûea-rài",          hindiPronunciation: "मुआ-राय",        englishMeaning: "when?",                 hindiMeaning: "कब?",                 category: "Questions"),
        ThaiWord(id: 148, thai: "ทำไม",        romanization: "tham-mai",          hindiPronunciation: "तम-माय",         englishMeaning: "why?",                  hindiMeaning: "क्यों?",              category: "Questions"),
        ThaiWord(id: 149, thai: "ใคร",         romanization: "khrai",             hindiPronunciation: "ख्राय",          englishMeaning: "who?",                  hindiMeaning: "कौन?",                category: "Questions"),
        ThaiWord(id: 150, thai: "ยังไง",       romanization: "yang-ngai",         hindiPronunciation: "यंग-ङाय",        englishMeaning: "how?",                  hindiMeaning: "कैसे?",               category: "Questions"),
        ThaiWord(id: 151, thai: "และ",         romanization: "láe",               hindiPronunciation: "लै",             englishMeaning: "and",                   hindiMeaning: "और",                  category: "Grammar"),
        ThaiWord(id: 152, thai: "หรือ",        romanization: "rǔue",              hindiPronunciation: "रू",             englishMeaning: "or",                    hindiMeaning: "या",                  category: "Grammar"),
        ThaiWord(id: 153, thai: "แต่",         romanization: "tàe",               hindiPronunciation: "तै",             englishMeaning: "but",                   hindiMeaning: "लेकिन",               category: "Grammar"),
        ThaiWord(id: 154, thai: "นี่",         romanization: "nîi",               hindiPronunciation: "नी",             englishMeaning: "this",                  hindiMeaning: "यह",                  category: "Grammar"),
        ThaiWord(id: 155, thai: "นั่น",        romanization: "nân",               hindiPronunciation: "नन",             englishMeaning: "that",                  hindiMeaning: "वह",                  category: "Grammar"),

        // MARK: Animals
        ThaiWord(id: 156, thai: "หมา",         romanization: "mǎa",               hindiPronunciation: "मा",             englishMeaning: "dog",                   hindiMeaning: "कुत्ता",              category: "Animals"),
        ThaiWord(id: 157, thai: "แมว",         romanization: "maeo",              hindiPronunciation: "मैव",            englishMeaning: "cat",                   hindiMeaning: "बिल्ली",              category: "Animals"),
        ThaiWord(id: 158, thai: "นก",          romanization: "nók",               hindiPronunciation: "नोक",            englishMeaning: "bird",                  hindiMeaning: "चिड़िया",             category: "Animals"),
        ThaiWord(id: 159, thai: "ปลา",         romanization: "plaa",              hindiPronunciation: "प्ला",           englishMeaning: "fish",                  hindiMeaning: "मछली",                category: "Animals"),
        ThaiWord(id: 160, thai: "ช้าง",        romanization: "cháang",            hindiPronunciation: "चांग",           englishMeaning: "elephant",              hindiMeaning: "हाथी",                category: "Animals"),

        // MARK: More food
        ThaiWord(id: 161, thai: "ผลไม้",       romanization: "phǒn-lá-mái",       hindiPronunciation: "फ़ोन-ल-माय",    englishMeaning: "fruit",                 hindiMeaning: "फल",                  category: "Food"),
        ThaiWord(id: 162, thai: "ผัก",         romanization: "phàk",              hindiPronunciation: "फक",             englishMeaning: "vegetable",             hindiMeaning: "सब्ज़ी",              category: "Food"),
        ThaiWord(id: 163, thai: "ไก่",         romanization: "kài",               hindiPronunciation: "काय",            englishMeaning: "chicken",               hindiMeaning: "मुर्गी / चिकन",       category: "Food"),
        ThaiWord(id: 164, thai: "ไข่",         romanization: "khài",              hindiPronunciation: "खाय",            englishMeaning: "egg",                   hindiMeaning: "अंडा",                category: "Food"),
        ThaiWord(id: 165, thai: "นม",          romanization: "num",               hindiPronunciation: "नम",             englishMeaning: "milk",                  hindiMeaning: "दूध",                 category: "Food"),
        ThaiWord(id: 166, thai: "น้ำตาล",      romanization: "nám-taan",          hindiPronunciation: "नम-तान",        englishMeaning: "sugar",                 hindiMeaning: "चीनी",                category: "Food"),
        ThaiWord(id: 167, thai: "เกลือ",       romanization: "kluea",             hindiPronunciation: "क्लुआ",          englishMeaning: "salt",                  hindiMeaning: "नमक",                 category: "Food"),
        ThaiWord(id: 168, thai: "แกง",         romanization: "kaeng",             hindiPronunciation: "कैंग",           englishMeaning: "curry",                 hindiMeaning: "करी",                 category: "Food"),
        ThaiWord(id: 169, thai: "ก๋วยเตี๋ยว",  romanization: "kǔai-tǐao",         hindiPronunciation: "कुआय-तियाव",    englishMeaning: "noodles",               hindiMeaning: "नूडल्स",              category: "Food"),

        // MARK: Safety & essentials
        ThaiWord(id: 170, thai: "ช่วยด้วย",    romanization: "chûai-dûai",        hindiPronunciation: "चुआय-दुआय",     englishMeaning: "help! (emergency)",     hindiMeaning: "बचाओ! / मदद करो!",    category: "Safety"),
        ThaiWord(id: 171, thai: "ตำรวจ",       romanization: "tam-rùat",          hindiPronunciation: "तम-रुआद",        englishMeaning: "police",                hindiMeaning: "पुलिस",               category: "Safety"),
        ThaiWord(id: 172, thai: "อันตราย",     romanization: "an-tà-raai",        hindiPronunciation: "अन-त-राय",       englishMeaning: "danger / dangerous",    hindiMeaning: "खतरा / खतरनाक",       category: "Safety"),
        ThaiWord(id: 173, thai: "ระวัง",       romanization: "rá-wang",           hindiPronunciation: "र-वंग",          englishMeaning: "careful! / watch out",  hindiMeaning: "सावधान!",             category: "Safety"),
        ThaiWord(id: 174, thai: "โทรศัพท์",    romanization: "thoo-rá-sàp",       hindiPronunciation: "तो-र-सप",        englishMeaning: "telephone",             hindiMeaning: "फ़ोन",                category: "Safety"),

        // MARK: Directions
        ThaiWord(id: 175, thai: "ซ้าย",        romanization: "sáai",              hindiPronunciation: "साय",            englishMeaning: "left (side)",           hindiMeaning: "बायाँ",               category: "Directions"),
        ThaiWord(id: 176, thai: "ขวา",         romanization: "khwǎa",             hindiPronunciation: "ख्वा",           englishMeaning: "right (side)",          hindiMeaning: "दायाँ",               category: "Directions"),
        ThaiWord(id: 177, thai: "ตรงไป",       romanization: "trong-pai",         hindiPronunciation: "त्रोंग-पाय",     englishMeaning: "straight ahead",        hindiMeaning: "सीधे",                category: "Directions"),
        ThaiWord(id: 178, thai: "ที่นี่",      romanization: "thîi-nîi",          hindiPronunciation: "ती-नी",          englishMeaning: "here",                  hindiMeaning: "यहाँ",                category: "Directions"),
        ThaiWord(id: 179, thai: "ที่นั่น",     romanization: "thîi-nân",          hindiPronunciation: "ती-नन",          englishMeaning: "there",                 hindiMeaning: "वहाँ",                category: "Directions"),
        ThaiWord(id: 180, thai: "ข้างบน",      romanization: "khâang-bon",        hindiPronunciation: "खांग-बोन",       englishMeaning: "above / upstairs",      hindiMeaning: "ऊपर",                 category: "Directions"),
        ThaiWord(id: 181, thai: "ข้างล่าง",    romanization: "khâang-lâang",      hindiPronunciation: "खांग-लांग",      englishMeaning: "below / downstairs",    hindiMeaning: "नीचे",                category: "Directions"),

        // MARK: Compounds of earlier words (power the "related words" chips)
        ThaiWord(id: 182, thai: "น้ำแข็ง",     romanization: "nám-khǎeng",        hindiPronunciation: "नम-खैंग",       englishMeaning: "ice",                   hindiMeaning: "बर्फ़",               category: "Food"),
        ThaiWord(id: 183, thai: "ข้าวผัด",     romanization: "khâao-phàt",        hindiPronunciation: "खाउ-फद",         englishMeaning: "fried rice",            hindiMeaning: "फ्राइड राइस",         category: "Food"),
        ThaiWord(id: 184, thai: "น้ำส้ม",      romanization: "nám-sôm",           hindiPronunciation: "नम-सोम",        englishMeaning: "orange juice",          hindiMeaning: "संतरे का रस",         category: "Food"),
        ThaiWord(id: 185, thai: "ไฟ",          romanization: "fai",               hindiPronunciation: "फाय",            englishMeaning: "fire / light",          hindiMeaning: "आग / बत्ती",          category: "Basics"),
        ThaiWord(id: 186, thai: "รถไฟ",        romanization: "rót-fai",           hindiPronunciation: "रोद-फाय",        englishMeaning: "train",                 hindiMeaning: "रेलगाड़ी",            category: "Travel"),
    ]

    /// Words whose Thai spelling contains this word, or that this word
    /// contains — e.g. น้ำ → ห้องน้ำ, น้ำตาล, น้ำแข็ง. Powers the
    /// "related words" chips in Practice.
    static func related(to word: ThaiWord) -> [ThaiWord] {
        all.filter { $0.id != word.id && ($0.thai.contains(word.thai) || word.thai.contains($0.thai)) }
    }

    /// A stable, per-day rotation offset so the "word of the day" changes daily.
    static func word(forDayOffset offset: Int) -> ThaiWord {
        let index = ((offset % all.count) + all.count) % all.count
        return all[index]
    }

    /// A random word (used by the widget's rotation and the app's shuffle button).
    static func randomWord() -> ThaiWord {
        all.randomElement() ?? all[0]
    }

    /// A stable per-hour word shared by every widget, so widgets placed
    /// side by side always show the same word. The prime stride (17 is
    /// coprime with the list size) pseudo-shuffles the rotation so
    /// consecutive hours don't show consecutive list entries.
    static func word(forHour hour: Int) -> ThaiWord {
        let index = ((hour * 17) % all.count + all.count) % all.count
        return all[index]
    }

    static var categories: [String] {
        var seen = Set<String>()
        return all.compactMap { seen.insert($0.category).inserted ? $0.category : nil }
    }
}
