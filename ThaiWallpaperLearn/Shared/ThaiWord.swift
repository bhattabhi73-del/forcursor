import Foundation
import SwiftUI

/// Blue rebrand (from Sukhothai Gold) — pale-blue grounds, mid-blue primary
/// accent, light-blue second accent, navy ink. Old warm names stay as
/// semantic aliases (indigo → accent, gold → accent2 400, orchid → accent700,
/// jade → accent2) so every screen keeps compiling; prefer the new roles in
/// new code.
enum ThaiTheme {
    // MARK: New semantic roles

    static let bg            = Color(hex: 0xEEF3FA)  // page ground
    static let bgAlt         = Color(hex: 0xF5F8FC)  // alternate ground (quiz)
    static let surface       = Color(hex: 0xFBFDFF)  // cards, rows
    static let surfaceSunken = Color(hex: 0xE3EBF5)  // chips, pressed rows
    static let hairline      = Color(hex: 0xDCE5F0)  // dividers, empty progress

    static let accent100     = Color(hex: 0xEAF2FC)
    static let accent200     = Color(hex: 0xD8E7F8)
    static let accent300     = Color(hex: 0xAECDF0)
    static let accent400     = Color(hex: 0x6F9FE0)
    static let accent        = Color(hex: 0x2F6BC0)  // primary
    static let accent600     = Color(hex: 0x24559C)  // hover
    static let accent700     = Color(hex: 0x1B4079)  // pressed / accent text

    static let accent2100    = Color(hex: 0xE6F3FB)
    static let accent2200    = Color(hex: 0xCFE7F6)
    static let accent2300    = Color(hex: 0xA9D3EA)
    static let accent2400    = Color(hex: 0x79B6DA)
    static let accent2       = Color(hex: 0x3B7AA2)  // second voice / success
    static let accent2600    = Color(hex: 0x2C5F80)
    static let accent2800    = Color(hex: 0x1C3352)

    static let textMuted     = Color(hex: 0x64748E)
    static let textFaint     = Color(hex: 0x8C9CB4)
    static let inkDeep       = Color(hex: 0x16233D)  // dark card face

    // MARK: Warm-name aliases (legacy call sites)

    static let sand       = bg
    static let cream      = surface
    static let parchment  = surfaceSunken
    static let ink        = Color(hex: 0x101C33)
    static let indigo     = accent
    static let deepIndigo = inkDeep
    static let gold       = accent2400
    static let lightGold  = accent200
    static let orchid     = accent700   // Devanagari voice
    static let jade       = accent2
    static let plum       = Color(hex: 0x4E92BD)
    static let stone      = textMuted

    // Semantic roles — prefer these over raw RGB in UI chrome.
    static let success    = accent2
    static let danger     = Color(hex: 0xC2503F)
    static let toneMid    = textMuted
    static let toneLow    = Color(red: 0.290, green: 0.435, blue: 0.831)
    static let toneFalling = danger
    static let toneHigh   = Color(red: 0.902, green: 0.541, blue: 0.180)
    static let toneRising = Color(red: 0.243, green: 0.647, blue: 0.424)

    // Consonant classes must stay three distinguishable hues.
    static let classMiddle = accent
    static let classHigh   = accent700
    static let classLow    = accent2

    // Spacing / radius scale (8-pt grid).
    static let spaceXS: CGFloat = 4
    static let spaceSM: CGFloat = 8
    static let spaceMD: CGFloat = 12
    static let spaceLG: CGFloat = 16
    static let spaceXL: CGFloat = 24
    static let radiusControl: CGFloat = 14
    static let radiusCard: CGFloat = 24
    static let radiusChip: CGFloat = 14

    // Widget backgrounds are deliberately dark: white text stays readable
    // no matter what wallpaper sits behind or beside the widget.
    static let thaiGradient = LinearGradient(
        colors: [Color(hex: 0x101C33), Color(hex: 0x1C3352)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let englishGradient = LinearGradient(
        colors: [Color(hex: 0x16233D), Color(hex: 0x2C5F80)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: Fonts

    /// Caladea (SIL OFL) is the metric-compatible stand-in for Cambria;
    /// registered from the app bundle at launch. Use for display text only —
    /// it lacks the caron tone vowels (ǎ ǐ ǒ ǔ), so romanization stays in
    /// the system face.
    static func display(_ size: CGFloat, bold: Bool = false) -> Font {
        .custom(bold ? "Caladea-Bold" : "Caladea", size: size)
    }

    /// Mitr (Google, OFL) — the Thai hero voice of the blue design system.
    /// Falls back to the system face where unregistered (widgets).
    static func thai(_ size: CGFloat) -> Font {
        .custom("Mitr-Medium", size: size)
    }

    /// Quiet pale-blue wash the glass cards float on.
    static let glassWash = LinearGradient(
        colors: [sand, parchment.opacity(0.85), sand],
        startPoint: .topLeading, endPoint: .bottomTrailing)
}

extension Color {
    /// 0xRRGGBB convenience initializer.
    init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255)
    }
}

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

/// Leitner-style spaced repetition: each word lives in a box (0 = new,
/// 1-5 = learning through known). A correct answer moves it up a box and
/// schedules the next review further out (1, 3, 7, 14, 30 days); a miss
/// drops it back to box 1 and tomorrow. Based on the Ebbinghaus
/// forgetting-curve research used by Anki/SM-2.
final class ProgressStore {
    static let shared = ProgressStore()

    struct WordProgress: Codable {
        var box = 0
        var nextReview = Date.distantPast
        var reviews = 0
        var lapses = 0
    }

    private static let intervals: [TimeInterval] = [0, 1, 3, 7, 14, 30].map { $0 * 86_400 }
    private let key = "wordProgress.v1"
    private var progress: [Int: WordProgress]

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Int: WordProgress].self, from: data) {
            progress = saved
        } else {
            progress = [:]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func box(for id: Int) -> Int { progress[id]?.box ?? 0 }

    func nextReview(for id: Int) -> Date? { progress[id]?.nextReview }

    func isDue(_ id: Int) -> Bool {
        guard let p = progress[id], p.box > 0 else { return false }
        return p.nextReview <= Date()
    }

    func record(id: Int, known: Bool) {
        var p = progress[id] ?? WordProgress()
        p.reviews += 1
        if known {
            p.box = min(p.box + 1, 5)
        } else {
            p.box = 1
            p.lapses += 1
        }
        p.nextReview = Date().addingTimeInterval(Self.intervals[p.box])
        progress[id] = p
        save()
        recordPracticeToday()
        bumpReviewsToday()
    }

    // MARK: Daily goal (cards reviewed today)

    static let dailyGoal = 12

    private let reviewsDayKey = "reviewsDay.v1"
    private let reviewsCountKey = "reviewsTodayCount.v1"

    private func bumpReviewsToday() {
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let storedDay = UserDefaults.standard.double(forKey: reviewsDayKey)
        let count = storedDay == today ? UserDefaults.standard.integer(forKey: reviewsCountKey) : 0
        UserDefaults.standard.set(today, forKey: reviewsDayKey)
        UserDefaults.standard.set(count + 1, forKey: reviewsCountKey)
    }

    var reviewsToday: Int {
        let today = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        guard UserDefaults.standard.double(forKey: reviewsDayKey) == today else { return 0 }
        return UserDefaults.standard.integer(forKey: reviewsCountKey)
    }

    // MARK: Recently viewed words (Browse detail, search suggestions)

    private let recentsKey = "recentWords.v1"

    func recordViewed(id: Int) {
        var ids = (UserDefaults.standard.array(forKey: recentsKey) as? [Int]) ?? []
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        UserDefaults.standard.set(Array(ids.prefix(10)), forKey: recentsKey)
    }

    var recentlyViewed: [ThaiWord] {
        let ids = (UserDefaults.standard.array(forKey: recentsKey) as? [Int]) ?? []
        return ids.compactMap { id in Vocabulary.all.first { $0.id == id } }
    }

    // MARK: Daily practice streak

    private let streakKey = "practiceDays.v1"

    private func recordPracticeToday() {
        var days = Set(UserDefaults.standard.array(forKey: streakKey) as? [Double] ?? [])
        days.insert(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)
        UserDefaults.standard.set(Array(days), forKey: streakKey)
    }

    /// Consecutive practice days ending today — or yesterday, so a streak
    /// isn't shown as broken before today's session happens.
    func currentStreak() -> Int {
        let stored = (UserDefaults.standard.array(forKey: streakKey) as? [Double] ?? [])
        guard !stored.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(stored.map { cal.startOfDay(for: Date(timeIntervalSince1970: $0)) })
        var cursor = cal.startOfDay(for: Date())
        if !days.contains(cursor) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: cursor),
                  days.contains(yesterday) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while days.contains(cursor), let prev = cal.date(byAdding: .day, value: -1, to: cursor) {
            count += 1
            cursor = prev
        }
        return count
    }

    /// (due for review, never seen, known = box 3+)
    func counts(in words: [ThaiWord]) -> (due: Int, fresh: Int, known: Int) {
        var due = 0, fresh = 0, known = 0
        for w in words {
            let b = box(for: w.id)
            if b == 0 { fresh += 1 }
            else if isDue(w.id) { due += 1 }
            if b >= 3 { known += 1 }
        }
        return (due, fresh, known)
    }
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

    /// Visual mnemonic (dual-coding research: picture + word beats word
    /// alone). Populated by the generation pipeline.
    static func emoji(for word: ThaiWord) -> String? { emojis[word.id] }

    private static let emojis: [Int: String] = [
        1047: "🧳",
        1048: "🧭",
        1049: "🗺️",
        1050: "🗺️",
        1051: "📘",
        1052: "🛂",
        1053: "🧳",
        1054: "📍",
        1055: "🚆",
        1056: "🌍",
        1057: "🏠",
        1058: "🏖️",
        1059: "🔎",
        1060: "👀",
        1061: "📷",
        1062: "🎁",
        1063: "🧑‍💼",
        1064: "🚌",
        1065: "🎒",
        1066: "🚪",
        1067: "🚉",
        1068: "🚆",
        1069: "🚌",
        1070: "🚏",
        1071: "🛥️",
        1072: "✈️",
        1073: "📌",
        1074: "👮",
        1075: "🏛️",
        1076: "🖼️",
        1077: "📚",
        1078: "🌳",
        1079: "🦁",
        1080: "🎡",
        1081: "🎬",
        1082: "🎭",
        1083: "🎓",
        1084: "📮",
        1085: "🏪",
        1086: "🏬",
        1087: "⬆️",
        1088: "⬇️",
        1089: "➡️",
        1090: "⬅️",
        1091: "↔️",
        1092: "🚶",
        1093: "↩️",
        1094: "↪️",
        1095: "🔄",
        1096: "➕",
        1097: "🔄",
        1098: "🔀",
        1099: "🚸",
        1100: "🌉",
        1101: "🚇",
        1102: "🛣️",
        1103: "🚶",
        1104: "🏘️",
        1105: "🏁",
        1106: "📏",
        1107: "🚌",
        1108: "🚕",
        1109: "🚖",
        1110: "🚐",
        1111: "🏍️",
        1112: "🚲",
        1113: "🛺",
        1114: "🛺",
        1115: "🚌",
        1116: "🚄",
        1117: "🚇",
        1118: "🚅",
        1119: "🚗",
        1120: "🔑",
        1121: "🎟️",
        1122: "🧑",
        1123: "🧑‍✈️",
        1124: "🔢",
        1125: "⛽",
        1126: "🚦",
        1127: "✅",
        1128: "🚪",
        1129: "🛏️",
        1130: "🛏️",
        1131: "🛏️",
        1132: "🏨",
        1133: "📅",
        1134: "🧾",
        1135: "🛎️",
        1136: "🧑‍💼",
        1137: "💳",
        1138: "🔑",
        1139: "🛋️",
        1140: "⬇️",
        1141: "⬆️",
        1142: "🤝",
        1143: "🛎️",
        1144: "🏊",
        1145: "🏋️",
        1146: "❄️",
        1147: "✈️",
        1148: "🛫",
        1149: "🌐",
        1150: "✈️",
        1151: "🚪",
        1152: "🎫",
        1153: "🧳",
        1154: "🧳",
        1155: "🧳",
        1156: "⚖️",
        1157: "🛂",
        1158: "🛃",
        1159: "🛫",
        1160: "🛬",
        1161: "⌛",
        1162: "❌",
        1163: "🛄",
        1164: "🏢",
        1165: "🛬",
        1166: "🛩️",
        1167: "🌦️",
        1168: "🌪️",
        1169: "⛈️",
        1170: "☁️",
        1171: "☁️",
        1172: "🌩️",
        1173: "⚡",
        1174: "🌫️",
        1175: "💧",
        1176: "🌡️",
        1177: "🌡️",
        1178: "🥵",
        1179: "🥶",
        1180: "💨",
        1181: "🍃",
        1182: "🌧️",
        1183: "🌦️",
        1184: "🌈",
        1185: "🌧️",
        1186: "❄️",
        1187: "🌲",
        1188: "🌳",
        1189: "💦",
        1190: "🏞️",
        1191: "🏞️",
        1192: "⛰️",
        1193: "🪨",
        1194: "🕳️",
        1195: "🏞️",
        1196: "🏖️",
        1197: "🏝️",
        1198: "🟫",
        1199: "🏖️",
        1200: "🪨",
        1201: "🪨",
        1202: "🍃",
        1203: "🌿",
        1204: "🌱",
        1205: "🌌",
        1206: "☀️",
        1207: "🐕",
        1208: "🐇",
        1209: "🐒",
        1210: "🐅",
        1211: "🦁",
        1212: "🐄",
        1213: "🐃",
        1214: "🐎",
        1215: "🐐",
        1216: "🐑",
        1217: "🦌",
        1218: "🐻",
        1219: "🐍",
        1220: "🐊",
        1221: "🐢",
        1222: "🐸",
        1223: "🦋",
        1224: "🐝",
        1225: "🐜",
        1226: "🐬",
        1227: "🔴",
        1228: "🟢",
        1229: "🔵",
        1230: "🟡",
        1231: "⚫",
        1232: "⚪",
        1233: "🩷",
        1234: "🟣",
        1235: "🟠",
        1236: "🟤",
        1237: "👕",
        1238: "👔",
        1239: "🧥",
        1240: "🧥",
        1241: "👗",
        1242: "👗",
        1243: "🩱",
        1244: "🧢",
        1245: "🧦",
        1246: "👖",
        1250: "🏨",
        1258: "🏍️",
        1262: "⛑️",
        1263: "⚡",
        1266: "🌋",
        1267: "🏖️",
        1268: "🌱",
        1269: "🌙",
        1270: "⭐",
        1271: "🦟",
        1272: "🦆",
        1273: "🐭",
        1275: "👓",
        1276: "☂️",
        1277: "🔵",
        1280: "🧀",
        1283: "🦀",
        1285: "🍍",
        1286: "🍎",
        1288: "🥗",
        1289: "🍕",
        1290: "🍔",
        1291: "🍷",
        1292: "🧾",
        1546: "🍲",
        1547: "🍲",
        1548: "🍲",
        1549: "🍲",
        1550: "🍲",
        1551: "🍲",
        1552: "🍲",
        1553: "🍲",
        1554: "🍲",
        1555: "🍲",
        1556: "🍲",
        1557: "🍲",
        1558: "🍲",
        1559: "🍲",
        1560: "🍲",
        1561: "🍲",
        1562: "🍲",
        1563: "🍲",
        1564: "🍲",
        1565: "🍲",
        1566: "🍲",
        1567: "🍲",
        1568: "🍲",
        1569: "🍲",
        1570: "🍲",
        1571: "🍲",
        1572: "🍲",
        1573: "🍲",
        1574: "🍲",
        1575: "🍲",
        1576: "🍲",
        1577: "🍲",
        1578: "🍲",
        1579: "🍲",
        1580: "🍲",
        1581: "🍲",
        1582: "🍲",
        1583: "🍲",
        1584: "🍲",
        1585: "🍲",
        1586: "🍲",
        1587: "🍲",
        1588: "🍲",
        1589: "🍲",
        1590: "🍲",
        1591: "🍲",
        1592: "🍲",
        1593: "🍲",
        1594: "🍲",
        1595: "🍲",
        1596: "🍲",
        1597: "🍲",
        1598: "🍲",
        1599: "🍲",
        1600: "🍲",
        1601: "🍲",
        1602: "🍲",
        1603: "🍲",
        1604: "🍲",
        1605: "🍲",
        1606: "🍲",
        1607: "🍲",
        1608: "🍲",
        1609: "🍲",
        1610: "🍲",
        1611: "🍲",
        1612: "🍲",
        1613: "🍲",
        1614: "🍲",
        1615: "🍲",
        1616: "🥬",
        1617: "🥬",
        1618: "🥬",
        1619: "🥬",
        1620: "🥬",
        1621: "🥬",
        1622: "🥬",
        1623: "🥬",
        1624: "🥬",
        1625: "🥬",
        1626: "🥬",
        1627: "🥬",
        1628: "🥬",
        1629: "🥬",
        1630: "🥬",
        1631: "🥬",
        1632: "🥬",
        1633: "🥬",
        1634: "🥬",
        1635: "🥬",
        1636: "🥬",
        1637: "🥬",
        1638: "🥬",
        1639: "🥬",
        1640: "🥬",
        1641: "🥬",
        1642: "🥬",
        1643: "🥬",
        1644: "🥬",
        1645: "🥬",
        1646: "🥬",
        1647: "🥬",
        1648: "🥬",
        1649: "🥬",
        1650: "🥬",
        1651: "🥬",
        1652: "🥬",
        1653: "🥬",
        1654: "🥬",
        1655: "🥬",
        1656: "🥬",
        1657: "🥬",
        1658: "🥬",
        1659: "🥬",
        1660: "🥬",
        1661: "🥬",
        1662: "🥬",
        1663: "🥬",
        1664: "🥬",
        1665: "🥬",
        1666: "🥤",
        1667: "🥤",
        1668: "🥤",
        1669: "🥤",
        1670: "🥤",
        1671: "🥤",
        1672: "🥤",
        1673: "🥤",
        1674: "🥤",
        1675: "🥤",
        1676: "🍳",
        1677: "🍳",
        1678: "🍳",
        1679: "🍳",
        1680: "🍳",
        1681: "🍳",
        1682: "🍳",
        1683: "🍳",
        1684: "🍳",
        1685: "🍳",
        1686: "🍳",
        1687: "🍳",
        1688: "🍳",
        1689: "🍳",
        1690: "🍳",
        1691: "🍳",
        1692: "🍳",
        1693: "🍳",
        1694: "🍳",
        1695: "🍳",
        1696: "🍳",
        1697: "🍳",
        1698: "🍳",
        1699: "🍳",
        1700: "🍳",
        1701: "🍳",
        1702: "🍳",
        1703: "🍳",
        1704: "🍳",
        1705: "🍳",
        1706: "🍳",
        1707: "🍳",
        1708: "🍳",
        1709: "🍳",
        1710: "🍳",
        1711: "🍳",
        1712: "🍳",
        1713: "🍳",
        1714: "🍳",
        1715: "🍳",
        1716: "🍳",
        1717: "🍳",
        1718: "🍳",
        1719: "🍳",
        1720: "🍳",
        1721: "🍳",
        1722: "🍳",
        1723: "🍳",
        1724: "🍳",
        1725: "🍳",
        1726: "🍽️",
        1727: "🍽️",
        1728: "🍽️",
        1729: "🍽️",
        1730: "🍽️",
        1731: "🍽️",
        1732: "🍽️",
        1733: "🍽️",
        1734: "🍽️",
        1735: "🍽️",
        1736: "🍽️",
        1737: "🍽️",
        1738: "🍽️",
        1739: "🍽️",
        1740: "🍽️",
        1741: "🍽️",
        1742: "🍽️",
        1743: "🍽️",
        1744: "🍽️",
        1745: "🍽️",
        1746: "🍽️",
        1747: "🍽️",
        1748: "🍽️",
        1749: "🍽️",
        1750: "🍽️",
        1751: "🍽️",
        1752: "🍽️",
        1753: "🍽️",
        1754: "🍽️",
        1755: "🍽️",
        1756: "🍽️",
        1757: "🍽️",
        1758: "🍽️",
        1759: "🍽️",
        1760: "🍽️",
        1761: "🍽️",
        1762: "🍽️",
        1763: "🍽️",
        1764: "🍽️",
        1765: "🍽️",
        1766: "🛒",
        1767: "🛒",
        1768: "🛒",
        1769: "🛒",
        1770: "🛒",
        1771: "🛒",
        1772: "🛒",
        1773: "🛒",
        1774: "🛒",
        1775: "🛒",
        1776: "🛒",
        1777: "🛒",
        1778: "🛒",
        1779: "🛒",
        1780: "🛒",
        1781: "🛒",
        1782: "🛒",
        1783: "🛒",
        1784: "🛒",
        1785: "🛒",
        1786: "🛒",
        1787: "🛒",
        1788: "🛒",
        1789: "🛒",
        1790: "🛒",
        1791: "🛒",
        1792: "🛒",
        1793: "🛒",
        1794: "🛒",
        1795: "🛒",
        1796: "🏠",
        1797: "🛋️",
        1798: "🍽️",
        1799: "💻",
        1800: "📦",
        1801: "🏠",
        1802: "👗",
        1803: "🙏",
        1804: "🛏️",
        1805: "🚽",
        1806: "🧺",
        1807: "🍳",
        1808: "🏚️",
        1809: "🚗",
        1810: "🚶",
        1811: "📐",
        1812: "📚",
        1813: "🚪",
        1814: "🚪",
        1815: "🔒",
        1816: "🖐️",
        1817: "🔩",
        1818: "🪟",
        1819: "🪟",
        1820: "👣",
        1821: "🪝",
        1822: "👕",
        1823: "👔",
        1824: "👞",
        1825: "🗄️",
        1826: "🔐",
        1827: "📚",
        1828: "🛏️",
        1829: "🪑",
        1830: "🪑",
        1831: "🛏️",
        1832: "🛏️",
        1833: "🛏️",
        1834: "🛌",
        1835: "🪟",
        1836: "🌀",
        1837: "💡",
        1838: "🔌",
        1839: "💧",
        1840: "🛢️",
        1841: "🍳",
        1842: "🧹",
        1843: "🧽",
        1844: "🧽",
        1845: "🧹",
        1846: "🍂",
        1847: "🛏️",
        1848: "🛏️",
        1849: "🧺",
        1850: "🧺",
        1851: "👔",
        1852: "🔧",
        1853: "🛠️",
        1854: "💡",
        1855: "🔧",
        1856: "🚿",
        1857: "🚰",
        1858: "🧺",
        1859: "🧺",
        1860: "☀️",
        1861: "♻️",
        1862: "♻️",
        1863: "🗑️",
        1864: "🗑️",
        1865: "🪴",
        1866: "🌿",
        1867: "🌱",
        1868: "🌱",
        1869: "🚽",
        1870: "🚗",
        1871: "⛽",
        1872: "🍽️",
        1873: "🥛",
        1874: "🍽️",
        1875: "🔪",
        1876: "🪟",
        1877: "🪟",
        1878: "🔒",
        1879: "🔑",
        1880: "🔋",
        1881: "🔌",
        1882: "🔌",
        1883: "🔔",
        1884: "📦",
        1885: "📦",
        1886: "🛋️",
        1887: "🛠️",
        1888: "🛠️",
        1889: "📏",
        1890: "📏",
        1891: "↔️",
        1892: "📦",
        1893: "✨",
        1894: "📚",
        1895: "✨",
        1896: "🔒",
        1897: "🌬️",
        1898: "⬛",
        1899: "💡",
        1900: "🌑",
        1901: "🤫",
        1902: "🌀",
        1903: "🛡️",
        1904: "⚠️",
        1905: "🔒",
        1906: "🔧",
        1907: "💔",
        1908: "🔪",
        1909: "⚠️",
        1910: "🧷",
        1911: "🫙",
        1912: "🪚",
        1913: "⚪",
        1914: "😠",
        1915: "🤝",
        1916: "✅",
        1917: "❓",
        1918: "🚨",
        1919: "⏳",
        1920: "⏰",
        1921: "⌛",
        1922: "♾️",
        1923: "📅",
        1924: "🗓️",
        1925: "🗓️",
        1926: "📌",
        1927: "⏰",
        1928: "📆",
        1929: "✅",
        1930: "🚫",
        1931: "✅",
        1932: "📣",
        1933: "🔔",
        1934: "⚠️",
        1935: "🙋",
        1936: "💬",
        1937: "📝",
        1938: "❗",
        1939: "📋",
        1940: "⚖️",
        1941: "👍",
        1942: "👎",
        1943: "🛑",
        1944: "🤫",
        1945: "📢",
        1946: "🔊",
        1947: "🔤",
        1948: "⌨️",
        1949: "📎",
        1950: "💬",
        1951: "📞",
        1952: "📵",
        1953: "📨",
        1954: "🔑",
        1955: "🫆",
        1956: "📹",
        1957: "🚨",
        1958: "🧯",
        1959: "🚪",
        1960: "📍",
        1961: "📞",
        1962: "⚡",
        1963: "⛔",
        1964: "🚭",
        1965: "⚡",
        1966: "🏦",
        1967: "🏦",
        1968: "💰",
        1969: "💸",
        1970: "💸",
        1971: "💳",
        1972: "💳",
        1973: "💳",
        1974: "🔢",
        1975: "🏧",
        1976: "📈",
        1977: "🧾",
        1978: "💱",
        1979: "💱",
        1980: "💵",
        1981: "📄",
        1982: "💳",
        1983: "🧾",
        1984: "📉",
        1985: "🐖",
        1986: "🪪",
        1987: "📄",
        1988: "📄",
        1989: "📝",
        1990: "📝",
        1991: "✍️",
        1992: "✍️",
        1993: "🔖",
        1994: "📃",
        1995: "📑",
        1996: "📋",
        1997: "📜",
        1998: "📜",
        1999: "📌",
        2000: "📅",
        2001: "🔄",
        2002: "✅",
        2003: "🌐",
        2004: "📥",
        2005: "🪷",
        2006: "🙏",
        2007: "🙏",
        2008: "🪷",
        2009: "🏯",
        2010: "🏯",
        2011: "🏯",
        2012: "🛕",
        2013: "🔔",
        2014: "🕯️",
        2015: "🕯️",
        2016: "🌸",
        2017: "🪷",
        2018: "🙏",
        2019: "🎁",
        2020: "🥣",
        2021: "📿",
        2022: "🧘",
        2023: "🕯️",
        2024: "💦",
        2025: "🏮",
        2026: "🏮",
        2027: "🎉",
        2028: "🎂",
        2029: "🎊",
        2030: "🌄",
        2031: "🌅",
        2032: "🕙",
        2033: "🌆",
        2034: "🌙",
        2035: "🕐",
        2036: "🔜",
        2037: "↔️",
        2038: "⚡",
        2039: "⏩",
        2040: "⏰",
        2041: "📍",
        2042: "⌛",
        2043: "📋",
        2044: "📅",
        2045: "⏳",
        2046: "🎁",
        2047: "🍲",
        2048: "🍲",
        2049: "🍲",
        2050: "🍲",
        2051: "🍲",
        2052: "🍲",
        2053: "🍲",
        2054: "🍲",
        2055: "🍲",
        2056: "🍲",
        2057: "🍲",
        2058: "🍲",
        2059: "🍲",
        2060: "🍲",
        2061: "🍲",
        2062: "🍲",
        2063: "🍲",
        2064: "🍲",
        2065: "🍲",
        2066: "🍲",
        2067: "🍲",
        2068: "🍲",
        2069: "🍲",
        2070: "🍲",
        2071: "🍲",
        2072: "🍲",
        2073: "🍲",
        2074: "🍲",
        2075: "🍲",
        2076: "🍲",
        2077: "🍲",
        2078: "🍲",
        2079: "🍲",
        2080: "🍲",
        2081: "🍲",
        2082: "🍲",
        2083: "🍲",
        2084: "🍲",
        2085: "🍲",
        2086: "🍲",
        2087: "🍲",
        2088: "🍲",
        2089: "🍲",
        2090: "🍲",
        2091: "🍲",
        2092: "🍲",
        2093: "🍲",
        2094: "🍲",
        2095: "🍲",
        2096: "🍲",
        2097: "🍲",
        2098: "🍲",
        2099: "🍲",
        2100: "🍲",
        2101: "🍲",
        2102: "🍲",
        2103: "🍲",
        2104: "🍲",
        2105: "🍲",
        2106: "🍲",
        2107: "🍲",
        2108: "🍲",
        2109: "🍲",
        2110: "🍲",
        2111: "🍲",
        2112: "🍲",
        2113: "🍲",
        2114: "🍲",
        2115: "🍲",
        2116: "🍲",
        2117: "🍲",
        2118: "🍲",
        2119: "🍲",
        2120: "🍲",
        2121: "🍲",
        2122: "🍲",
        2123: "🍲",
        2124: "🍲",
        2125: "🍲",
        2126: "🍲",
        2127: "🍲",
        2128: "🍲",
        2129: "🍲",
        2130: "🍲",
        2131: "🍲",
        2132: "🍲",
        2133: "🍲",
        2134: "🍲",
        2135: "🍲",
        2136: "🍲",
        2137: "🍲",
        2138: "🍲",
        2139: "🍲",
        2140: "🍲",
        2141: "🍲",
        2142: "🍲",
        2143: "🍲",
        2144: "🍲",
        2145: "🍲",
        2146: "🍲",
        2147: "🍲",
        2148: "🍲",
        2149: "🍲",
        2150: "🍲",
        2151: "🍲",
        2152: "🍲",
        2153: "🍲",
        2154: "🍲",
        2155: "🍲",
        2156: "🍲",
        2157: "🍲",
        2158: "🍲",
        2159: "🍲",
        2160: "🍲",
        2161: "🍲",
        2162: "🍲",
        2163: "🍲",
        2164: "🍲",
        2165: "🍲",
        2166: "🍲",
        2167: "🍲",
        2168: "🍲",
        2169: "🍲",
        2170: "🍲",
        2171: "🍲",
        2172: "🍲",
        2173: "🍲",
        2174: "🍲",
        2175: "🍲",
        2176: "🍲",
        2177: "🍲",
        2178: "🍲",
        2179: "🍲",
        2180: "🍲",
        2181: "🍲",
        2182: "🍲",
        2183: "🍲",
        2184: "🍲",
        2185: "🍲",
        2186: "🍲",
        2187: "🍲",
        2188: "🍲",
        2189: "🍲",
        2190: "🍲",
        2191: "🍲",
        2192: "🍲",
        2193: "🍲",
        2194: "🍲",
        2195: "🍲",
        2196: "🍲",
        2197: "🍲",
        2198: "🍲",
        2199: "🍲",
        2200: "🍲",
        2201: "🍲",
        2202: "🍲",
        2203: "🍲",
        2204: "🍲",
        2205: "🍲",
        2206: "🍲",
        2207: "🍲",
        2208: "🍲",
        2209: "🍲",
        2210: "🍲",
        2211: "🍲",
        2212: "🍲",
        2213: "🍲",
        2214: "🍲",
        2215: "🍲",
        2216: "🍲",
        2217: "🍲",
        2218: "🍲",
        2219: "🍲",
        2220: "🍲",
        2221: "🍲",
        2222: "🍲",
        2223: "🍲",
        2224: "🍲",
        2225: "🍲",
        2226: "🍲",
        2227: "🍲",
        2228: "🍲",
        2229: "🍲",
        2230: "🍲",
        2231: "🍲",
        2232: "🍲",
        2233: "🍲",
        2234: "🍲",
        2235: "🍲",
        2236: "🍲",
        2237: "🍲",
        2238: "🍲",
        2239: "🍲",
        2240: "🍲",
        2241: "🍲",
        2242: "🍲",
        2243: "🍲",
        2244: "🍲",
        2245: "🍲",
        2246: "🍲",
    ]

    private static let forms: [Int: [WordForm]] = [
        425: [
            WordForm(thai: "อันนี้", romanization: "an níi", english: "this one", hindi: "यह वाला", note: "นี้ follows a noun or classifier; นี่ stands alone / นี้ संज्ञा के बाद आता है, นี่ अकेला"),
            WordForm(thai: "วันนี้", romanization: "wan-níi", english: "today", hindi: "आज", note: "วัน day + นี้ this → today / दिन + यह = आज"),
        ],
        426: [
            WordForm(thai: "ขอน้ำ", romanization: "khǒo náam", english: "may I have water", hindi: "पानी दीजिए", note: "ขอ + noun = may I have … / ขอ + संज्ञा = … दीजिए"),
            WordForm(thai: "ขอโทษ", romanization: "khǒo-thôot", english: "sorry / excuse me", hindi: "माफ़ कीजिए", note: "ขอ + โทษ (blame) → asking forgiveness / क्षमा माँगना"),
        ],
        427: [
            WordForm(thai: "ไปไหม", romanization: "pai mǎi", english: "are you going?", hindi: "चलोगे?", note: "statement + ไหม = yes/no question / वाक्य + ไหม = हाँ/नहीं वाला सवाल"),
            WordForm(thai: "อร่อยไหม", romanization: "à-ròi mǎi", english: "is it tasty?", hindi: "स्वादिष्ट है क्या?", note: ""),
        ],
        428: [
            WordForm(thai: "ช่วยหน่อย", romanization: "chûai nòi", english: "please help", hindi: "ज़रा मदद कीजिए", note: "verb + หน่อย softens a request / क्रिया + หน่อย अनुरोध को नरम बनाता है"),
            WordForm(thai: "รอหน่อย", romanization: "roo nòi", english: "wait a moment", hindi: "ज़रा रुकिए", note: ""),
        ],
        429: [
            WordForm(thai: "คนไทย", romanization: "khon thai", english: "Thai person", hindi: "थाई व्यक्ति", note: ""),
            WordForm(thai: "เมืองไทย", romanization: "mueang-thai", english: "Thailand (colloquial)", hindi: "थाईलैंड (बोलचाल)", note: ""),
            WordForm(thai: "อาหารไทย", romanization: "aa-hǎan thai", english: "Thai food", hindi: "थाई खाना", note: ""),
        ],
        430: [
            WordForm(thai: "ฝนตก", romanization: "fǒn tòk", english: "it's raining", hindi: "बारिश हो रही है", note: "Thai says 'rain falls' / थाई में 'बारिश गिरती है' कहते हैं"),
        ],
        431: [
            WordForm(thai: "ด้วยกัน", romanization: "dûai-kan", english: "together", hindi: "साथ में", note: ""),
            WordForm(thai: "ไปกินข้าวกัน", romanization: "pai kin khâao kan", english: "let's go eat!", hindi: "चलो खाने चलें!", note: "verb + กัน = let's … together / क्रिया + กัน = साथ में करना"),
        ],
        432: [
            WordForm(thai: "คืออะไร", romanization: "khuue à-rai", english: "what is …?", hindi: "… क्या है?", note: "คือ links two nouns: A คือ B / คือ दो संज्ञाओं को जोड़ता है"),
        ],
        433: [
            WordForm(thai: "อย่าลืม", romanization: "yàa luem", english: "don't forget", hindi: "भूलना मत", note: "อย่า + verb = don't … / อย่า + क्रिया = मत करो"),
            WordForm(thai: "อย่าไป", romanization: "yàa pai", english: "don't go", hindi: "मत जाओ", note: ""),
        ],
        434: [
            WordForm(thai: "ตอนนี้", romanization: "toon-níi", english: "now", hindi: "अभी", note: ""),
            WordForm(thai: "ตอนเช้า", romanization: "toon-cháo", english: "in the morning", hindi: "सुबह के समय", note: "ตอน + time word = during … / ตอน + समय-शब्द = उस समय"),
        ],
        435: [
            WordForm(thai: "ข้างบน", romanization: "khâang-bon", english: "above / upstairs", hindi: "ऊपर", note: ""),
        ],
        436: [
            WordForm(thai: "ที่ไหน", romanization: "thîi-nǎi", english: "where?", hindi: "कहाँ?", note: ""),
            WordForm(thai: "อันไหน", romanization: "an nǎi", english: "which one?", hindi: "कौन-सा?", note: "noun/classifier + ไหน = which … / गणक + ไหน = कौन-सा"),
        ],
        437: [
            WordForm(thai: "ล้างมือ", romanization: "láang muue", english: "wash hands", hindi: "हाथ धोना", note: ""),
            WordForm(thai: "ล้างจาน", romanization: "láang jaan", english: "do the dishes", hindi: "बर्तन धोना", note: ""),
        ],
        438: [
            WordForm(thai: "เลี้ยวซ้าย", romanization: "líao sáai", english: "turn left", hindi: "बाएँ मुड़िए", note: ""),
            WordForm(thai: "เลี้ยวขวา", romanization: "líao khwǎa", english: "turn right", hindi: "दाएँ मुड़िए", note: ""),
        ],
        439: [
            WordForm(thai: "ไม่ชอบเลย", romanization: "mâi chôp loei", english: "don't like it at all", hindi: "बिल्कुल पसंद नहीं", note: "ไม่ + verb + เลย = not at all / ไม่ + क्रिया + เลย = बिल्कुल नहीं"),
        ],
        440: [
            WordForm(thai: "อ่านหนังสือ", romanization: "àan nǎng-sǔue", english: "to read / to study", hindi: "पढ़ना / पढ़ाई करना", note: "Thai says 'read book' even for studying / पढ़ाई के लिए भी 'किताब पढ़ना' कहते हैं"),
        ],
        441: [
            WordForm(thai: "อายุเท่าไหร่", romanization: "aa-yú thâo-rài", english: "how old?", hindi: "उम्र कितनी है?", note: "Same Sanskrit root as Hindi आयु / संस्कृत से आया शब्द, हिंदी 'आयु' जैसा"),
        ],
        442: [
            WordForm(thai: "ยกมือ", romanization: "yók muue", english: "raise your hand", hindi: "हाथ उठाना", note: ""),
        ],
        443: [
            WordForm(thai: "ค่ารถ", romanization: "khâa rót", english: "fare (transport)", hindi: "गाड़ी का किराया", note: "ค่า + noun = cost of … / ค่า + संज्ञा = उसका शुल्क"),
            WordForm(thai: "ค่าห้อง", romanization: "khâa hôong", english: "room charge", hindi: "कमरे का किराया", note: "Don't confuse with ค่ะ (polite particle) / ค่ะ (आदरसूचक शब्द) से अलग है"),
        ],
        444: [
            WordForm(thai: "อีกครั้ง", romanization: "ìik khráng", english: "once more", hindi: "एक बार फिर", note: ""),
            WordForm(thai: "อีกแก้ว", romanization: "ìik kâew", english: "one more glass", hindi: "एक गिलास और", note: "อีก + classifier = one more … / อีก + गणक = एक और"),
        ],
        445: [
            WordForm(thai: "อากาศแห้ง", romanization: "aa-kàat hâeng", english: "dry weather", hindi: "सूखा मौसम", note: ""),
        ],
        446: [
            WordForm(thai: "เลิกงาน", romanization: "lôek ngaan", english: "get off work", hindi: "काम से छूटना", note: "Everyday word for finishing the workday / रोज़ काम ख़त्म होने के लिए आम शब्द"),
        ],
        447: [
            WordForm(thai: "รถคันนี้", romanization: "rót khan níi", english: "this car", hindi: "यह गाड़ी", note: "noun + classifier + นี้ = this … / संज्ञा + गणक + นี้ = यह"),
            WordForm(thai: "รถสองคัน", romanization: "rót sǒong khan", english: "two cars", hindi: "दो गाड़ियाँ", note: "noun + number + classifier / संज्ञा + संख्या + गणक"),
        ],
        448: [
            WordForm(thai: "คนอินเดีย", romanization: "khon in-dia", english: "Indian person", hindi: "भारतीय", note: ""),
            WordForm(thai: "อาหารอินเดีย", romanization: "aa-hǎan in-dia", english: "Indian food", hindi: "भारतीय खाना", note: ""),
        ],
        223: [
            WordForm(thai: "พวกเรา", romanization: "phûak-rao", english: "we / us (group)", hindi: "हम लोग", note: "พวก makes pronouns clearly plural / सर्वनाम को बहुवचन बनाता है"),
            WordForm(thai: "เราไปก่อนนะ", romanization: "rao pai kòon ná", english: "I'm off now (casual)", hindi: "मैं चलता हूँ (अनौपचारिक)", note: "Among friends เรา often means 'I' / दोस्तों में เรา का मतलब 'मैं' भी होता है"),
        ],
        224: [
            WordForm(thai: "พวกเขา", romanization: "phûak-khǎo", english: "they / them", hindi: "वे लोग", note: "One word for he and she — in speech often said kháo / 'वह' और 'वही' दोनों के लिए एक शब्द"),
        ],
        225: [
            WordForm(thai: "มันคืออะไร", romanization: "man khue à-rai", english: "what is it?", hindi: "यह क्या है?", note: "Use มัน only for things and animals — rude for people / केवल चीज़ों-जानवरों के लिए, लोगों के लिए अशिष्ट"),
        ],
        226: [
            WordForm(thai: "ของคุณ", romanization: "khǒong khun", english: "yours", hindi: "आपका", note: "Owner comes after ของ / मालिक ของ के बाद आता है"),
            WordForm(thai: "ของเขา", romanization: "khǒong khǎo", english: "his / hers", hindi: "उसका", note: ""),
        ],
        227: [
            WordForm(thai: "ข้างใน", romanization: "khâang-nai", english: "inside", hindi: "अंदर", note: "Like ข้างบน above / ข้างล่าง below / जैसे ऊपर-नीचे वैसे अंदर"),
        ],
        229: [
            WordForm(thai: "ถึงแล้ว", romanization: "thǔeng láew", english: "we've arrived!", hindi: "पहुँच गए!", note: "Very common phrase in taxis / टैक्सी में बहुत आम वाक्य"),
        ],
        230: [
            WordForm(thai: "จะไม่ไป", romanization: "jà mâi pai", english: "will not go", hindi: "नहीं जाएगा", note: "จะ + ไม่ + verb = will not / จะ के बाद ไม่ लगाने से भविष्य का नकार"),
        ],
        231: [
            WordForm(thai: "กินได้", romanization: "kin dâi", english: "can eat", hindi: "खा सकते हैं", note: "verb + ได้ = can / क्रिया के बाद ได้ = सकना"),
            WordForm(thai: "ไปไม่ได้", romanization: "pai mâi dâi", english: "cannot go", hindi: "नहीं जा सकते", note: "verb + ไม่ได้ = cannot / क्रिया + ไม่ได้ = नहीं कर सकते"),
        ],
        232: [
            WordForm(thai: "ไม่ใช่", romanization: "mâi châi", english: "is not", hindi: "नहीं है", note: "Negate เป็น with ไม่ใช่, not ไม่เป็น / เป็น का नकार ไม่ใช่ से होता है"),
        ],
        233: [
            WordForm(thai: "กินอยู่", romanization: "kin yùu", english: "is eating (right now)", hindi: "खा रहा है", note: "verb + อยู่ = -ing, action in progress / क्रिया + อยู่ = 'रहा है'"),
        ],
        234: [
            WordForm(thai: "ไม่มี", romanization: "mâi mii", english: "don't have / there is none", hindi: "नहीं है", note: "You will hear this daily in shops / दुकानों में रोज़ सुनाई देता है"),
        ],
        235: [
            WordForm(thai: "ทุกคน", romanization: "thúk khon", english: "everyone", hindi: "सब लोग", note: "ทุก + noun, never alone / ทุก हमेशा संज्ञा के साथ आता है"),
        ],
        236: [
            WordForm(thai: "บางที", romanization: "baang-thii", english: "sometimes / maybe", hindi: "कभी-कभी / शायद", note: ""),
        ],
        237: [
            WordForm(thai: "อะไรก็ได้", romanization: "à-rai kô dâi", english: "anything is fine", hindi: "कुछ भी चलेगा", note: "ก็ได้ = 'that works too', super common answer / बहुत आम जवाब"),
        ],
        238: [
            WordForm(thai: "ยังไม่กิน", romanization: "yang mâi kin", english: "haven't eaten yet", hindi: "अभी तक नहीं खाया", note: "ยังไม่ + verb = not yet / ยังไม่ + क्रिया = अभी तक नहीं"),
        ],
        241: [
            WordForm(thai: "กินแล้ว", romanization: "kin láew", english: "already ate", hindi: "खा चुका", note: "verb + แล้ว = action completed / क्रिया + แล้ว = काम पूरा हुआ"),
            WordForm(thai: "แล้วคุณล่ะ", romanization: "láew khun lâ", english: "and you?", hindi: "और आप?", note: ""),
        ],
        242: [
            WordForm(thai: "ไม่ต้องรอ", romanization: "mâi tôong roo", english: "no need to wait", hindi: "इंतज़ार की ज़रूरत नहीं", note: "ไม่ต้อง + verb = no need to / ไม่ต้อง + क्रिया = ज़रूरत नहीं"),
        ],
        243: [
            WordForm(thai: "อยากได้", romanization: "yàak dâi", english: "want (a thing)", hindi: "(चीज़) चाहिए", note: "อยาก + verb for actions; อยากได้ + noun for things / काम के लिए อยาก, चीज़ के लिए อยากได้"),
        ],
        244: [
            WordForm(thai: "ซื้อให้", romanization: "súe hâi", english: "buy for (someone)", hindi: "किसी के लिए खरीदना", note: "verb + ให้ + person = do for someone / क्रिया + ให้ = किसी के लिए करना"),
        ],
        245: [
            WordForm(thai: "คิดว่า", romanization: "khít wâa", english: "to think that...", hindi: "सोचना कि...", note: "Follows verbs of saying and thinking, just like Hindi 'कि' / बोलने-सोचने की क्रियाओं के बाद"),
        ],
        247: [
            WordForm(thai: "ขอบคุณนะ", romanization: "khòop-khun ná", english: "thanks (warm, friendly)", hindi: "धन्यवाद ना (अपनापन)", note: "Ends a sentence to make it gentle — like Hindi 'ना' / वाक्य के अंत में, हिंदी 'ना' जैसा"),
        ],
        248: [
            WordForm(thai: "ไม่เอา", romanization: "mâi ao", english: "I don't want it", hindi: "नहीं चाहिए", note: "common refusal in shops / दुकान में मना करने का आम तरीका"),
            WordForm(thai: "เอากลับบ้าน", romanization: "ao klàp bâan", english: "take home / takeaway", hindi: "पैक करके ले जाना", note: "used when ordering food / खाना ऑर्डर करते समय"),
        ],
        249: [
            WordForm(thai: "ดื่มน้ำ", romanization: "dùem náam", english: "drink water", hindi: "पानी पीना", note: "colloquially กินน้ำ (kin náam) is also common / बोलचाल में 'किन नाम' भी चलता है"),
        ],
        250: [
            WordForm(thai: "ใช้ได้", romanization: "chái dâai", english: "usable / it works", hindi: "चल जाएगा / ठीक है", note: "very common daily phrase / रोज़ बोली जाने वाली अभिव्यक्ति"),
        ],
        251: [
            WordForm(thai: "หาไม่เจอ", romanization: "hǎa mâi jer", english: "can't find it", hindi: "मिल नहीं रहा", note: "hǎa = search, jer = find / ढूँढना बनाम मिलना"),
        ],
        253: [
            WordForm(thai: "บอกว่า", romanization: "bòok wâa", english: "say that ...", hindi: "कहना कि ...", note: "wâa works like 'that' / 'कि' की तरह जोड़ता है"),
        ],
        257: [
            WordForm(thai: "เรียนภาษาไทย", romanization: "rian phaa-sǎa thai", english: "study Thai", hindi: "थाई सीखना", note: "rian + subject name / रियन + विषय का नाम"),
        ],
        260: [
            WordForm(thai: "จำได้", romanization: "jam dâai", english: "can remember", hindi: "याद है", note: "usually said with dâai / आमतौर पर 'दाइ' के साथ बोला जाता है"),
            WordForm(thai: "จำไม่ได้", romanization: "jam mâi dâai", english: "can't remember", hindi: "याद नहीं", note: "negative form / नकारात्मक रूप"),
        ],
        261: [
            WordForm(thai: "อย่าลืม", romanization: "yàa luem", english: "don't forget", hindi: "मत भूलिए", note: "yàa + verb = don't (do it) / या + क्रिया = मत करो"),
        ],
        262: [
            WordForm(thai: "เริ่มแล้ว", romanization: "rêrm láew", english: "it has started", hindi: "शुरू हो गया", note: "láew marks completion / 'लैव' पूर्ण होना दिखाता है"),
        ],
        263: [
            WordForm(thai: "เสร็จแล้ว", romanization: "sèt láew", english: "done / finished", hindi: "हो गया", note: "very common daily phrase / रोज़ बोला जाने वाला वाक्यांश"),
            WordForm(thai: "ยังไม่เสร็จ", romanization: "yang mâi sèt", english: "not done yet", hindi: "अभी नहीं हुआ", note: "yang = yet / यंग = अभी तक"),
        ],
        265: [
            WordForm(thai: "รับอะไรดี", romanization: "ráp à-rai dii", english: "what would you like?", hindi: "आप क्या लेंगे?", note: "waiters and shopkeepers say this / वेटर और दुकानदार यही पूछते हैं"),
        ],
        268: [
            WordForm(thai: "ไม่ใส่ผัก", romanization: "mâi sài phàk", english: "without vegetables", hindi: "सब्ज़ी मत डालिए", note: "useful when ordering food / खाना ऑर्डर करते समय काम आता है"),
        ],
        270: [
            WordForm(thai: "มาก ๆ", romanization: "mâak mâak", english: "very very much", hindi: "बहुत ही ज़्यादा", note: "Doubling adds emphasis / दोहराने से ज़ोर बढ़ता है"),
            WordForm(thai: "ไม่มาก", romanization: "mâi mâak", english: "not much", hindi: "ज़्यादा नहीं", note: "มาก comes after the adjective: ร้อนมาก = very hot / มาก विशेषण के बाद आता है"),
        ],
        271: [
            WordForm(thai: "นิดหน่อย", romanization: "nít nòi", english: "a little bit", hindi: "थोड़ा सा", note: "Very common in daily speech / रोज़मर्रा की बोलचाल में बहुत आम"),
        ],
        272: [
            WordForm(thai: "แย่แล้ว", romanization: "yâe láew", english: "oh no! (something went wrong)", hindi: "अरे नहीं! / गड़बड़ हो गई", note: "Common exclamation / आम बोलचाल का उद्गार"),
        ],
        277: [
            WordForm(thai: "ว่างไหม", romanization: "wâang mǎi", english: "are you free?", hindi: "खाली हो क्या?", note: "Common way to invite someone / किसी को बुलाने का आम तरीका"),
        ],
        285: [
            WordForm(thai: "เบา ๆ", romanization: "bao bao", english: "softly / gently", hindi: "धीरे से", note: "Doubled form works as adverb / दोहराने पर क्रिया-विशेषण बनता है"),
        ],
        286: [
            WordForm(thai: "คนดัง", romanization: "khon dang", english: "famous person / celebrity", hindi: "मशहूर व्यक्ति", note: "ดัง also means famous / ดัง का मतलब मशहूर भी होता है"),
        ],
        287: [
            WordForm(thai: "เงียบ ๆ", romanization: "ngîap ngîap", english: "quietly", hindi: "चुपचाप", note: "นั่งเงียบ ๆ = sit quietly / चुपचाप बैठना"),
        ],
        290: [
            WordForm(thai: "สบาย ๆ", romanization: "sà-baai sà-baai", english: "relaxed / easygoing", hindi: "आराम से / बेफ़िक्र", note: "Very common phrase for the Thai lifestyle / थाई जीवनशैली के लिए बहुत आम वाक्यांश"),
        ],
        292: [
            WordForm(thai: "พูดถูก", romanization: "phûut thùuk", english: "said it right", hindi: "सही कहा", note: "In speech ถูก alone often means correct / बोलचाल में अकेला ถูก भी 'सही' होता है"),
        ],
        293: [
            WordForm(thai: "ขอโทษ ผมผิด", romanization: "khǒo-thôot phǒm phìt", english: "sorry, my mistake", hindi: "माफ़ कीजिए, मेरी गलती", note: "Polite way to admit a mistake / गलती मानने का विनम्र तरीका"),
        ],
        294: [
            WordForm(thai: "ตัวสูง", romanization: "tua sǔung", english: "tall (of a person)", hindi: "लंबे कद का", note: "สูง for height, ยาว for length / ऊँचाई के लिए สูง, लंबाई के लिए ยาว"),
        ],
        295: [
            WordForm(thai: "ทุกวันจันทร์", romanization: "thúk wan-jan", english: "every Monday", hindi: "हर सोमवार", note: "ทุก (thúk) + day = every... / हर + दिन"),
        ],
        298: [
            WordForm(thai: "วันพฤหัส", romanization: "wan-phá-rúe-hàt", english: "Thursday (short spoken form)", hindi: "गुरुवार (बोलचाल का छोटा रूप)", note: "Everyday spoken form / रोज़मर्रा में यही बोला जाता है"),
        ],
        302: [
            WordForm(thai: "ตอนเช้า", romanization: "toon-cháao", english: "in the morning", hindi: "सुबह के समय", note: "ตอน + time of day = in the... / ตอน + दिन का समय"),
            WordForm(thai: "ตอนเย็น", romanization: "toon-yen", english: "in the evening", hindi: "शाम के समय", note: "Same pattern with evening / शाम के साथ वही पैटर्न"),
        ],
        303: [
            WordForm(thai: "บ่อย ๆ", romanization: "bòi-bòi", english: "very often / frequently", hindi: "बहुत अक्सर", note: "Doubling makes it stronger / दोहराने से ज़ोर बढ़ता है"),
        ],
        306: [
            WordForm(thai: "เคยไปไหม", romanization: "kheuy pai mái", english: "Have you ever gone?", hindi: "क्या आप कभी गए हैं?", note: "เคย alone = have ever (experience) / เคย अकेले = कभी अनुभव किया है"),
        ],
        308: [
            WordForm(thai: "ก่อนนอน", romanization: "kòon noon", english: "before bed", hindi: "सोने से पहले", note: "ก่อน + verb = before doing... / ก่อน + क्रिया = करने से पहले"),
        ],
        309: [
            WordForm(thai: "หลังอาหาร", romanization: "lǎng aa-hǎan", english: "after meals", hindi: "खाने के बाद", note: "Common on medicine labels / दवा की पर्ची पर आम"),
        ],
        310: [
            WordForm(thai: "ตื่นสาย", romanization: "tùen sǎai", english: "to wake up late", hindi: "देर से उठना", note: "Verb + สาย = do late / क्रिया + สาย = देर से करना"),
        ],
        311: [
            WordForm(thai: "เที่ยงคืน", romanization: "thîang-kheun", english: "midnight", hindi: "आधी रात", note: "เที่ยง + คืน night = midnight / เที่ยง + रात = आधी रात"),
        ],
        313: [
            WordForm(thai: "เดือนหน้า", romanization: "duean nâa", english: "next month", hindi: "अगले महीने", note: "Same pattern / वही पैटर्न"),
            WordForm(thai: "ปีหน้า", romanization: "pii nâa", english: "next year", hindi: "अगले साल", note: "Same pattern / वही पैटर्न"),
        ],
        314: [
            WordForm(thai: "เดือนที่แล้ว", romanization: "duean thîi-láew", english: "last month", hindi: "पिछले महीने", note: "Same pattern / वही पैटर्न"),
            WordForm(thai: "ปีที่แล้ว", romanization: "pii thîi-láew", english: "last year", hindi: "पिछले साल", note: "Same pattern / वही पैटर्न"),
        ],
        315: [
            WordForm(thai: "บ่ายโมง", romanization: "bàai moong", english: "1 pm", hindi: "दोपहर 1 बजे", note: "Afternoon hours count from บ่าย / दोपहर के घंटे บ่าย से गिने जाते हैं"),
            WordForm(thai: "บ่ายสาม", romanization: "bàai sǎam", english: "3 pm", hindi: "दोपहर 3 बजे", note: "บ่าย + number = pm hour / บ่าย + संख्या = दोपहर का समय"),
        ],
        316: [
            WordForm(thai: "ทุกเช้า", romanization: "thúk cháao", english: "every morning", hindi: "हर सुबह", note: "ทุก + time word = every... / ทุก + समय = हर..."),
            WordForm(thai: "ทุกคืน", romanization: "thúk kheun", english: "every night", hindi: "हर रात", note: "Same pattern / वही पैटर्न"),
        ],
        319: [
            WordForm(thai: "นาน ๆ ที", romanization: "naan-naan thii", english: "once in a long while", hindi: "कभी-कभार", note: "Doubled นาน = rarely, occasionally / दोहराया นาน = बहुत कम बार"),
        ],
        320: [
            WordForm(thai: "กี่ครั้ง", romanization: "kìi khráng", english: "how many times", hindi: "कितनी बार", note: "กี่ always needs a classifier after it / กี่ के बाद हमेशा गिनती-शब्द आता है"),
            WordForm(thai: "กี่ปี", romanization: "kìi pii", english: "how many years", hindi: "कितने साल", note: "used for age and duration / उम्र और अवधि के लिए"),
        ],
        321: [
            WordForm(thai: "ตัวนี้", romanization: "tua níi", english: "this one (animal/clothing)", hindi: "यह वाला (जानवर/कपड़ा)", note: "classifier + นี้ = this one / गिनती-शब्द + นี้ = यह वाला"),
        ],
        322: [
            WordForm(thai: "คนไทย", romanization: "khon thai", english: "Thai person", hindi: "थाई व्यक्ति", note: "คน + country = nationality / คน + देश = राष्ट्रीयता"),
        ],
        323: [
            WordForm(thai: "อันไหน", romanization: "an nǎi", english: "which one?", hindi: "कौन-सा?", note: "classifier + ไหน = which / गिनती-शब्द + ไหน = कौन-सा"),
        ],
        332: [
            WordForm(thai: "อีกครั้ง", romanization: "ìik khráng", english: "again / one more time", hindi: "फिर से / एक बार और", note: "very common request / बहुत आम अनुरोध"),
            WordForm(thai: "ครั้งแรก", romanization: "khráng râek", english: "the first time", hindi: "पहली बार", note: "ครั้ง + แรก (first) / ครั้ง + แรก (पहला)"),
        ],
        338: [
            WordForm(thai: "ครึ่งชั่วโมง", romanization: "khrûeng chûa-moong", english: "half an hour", hindi: "आधा घंटा", note: "ครึ่ง before = half of / पहले ครึ่ง = आधा"),
            WordForm(thai: "ชั่วโมงครึ่ง", romanization: "chûa-moong khrûeng", english: "an hour and a half", hindi: "डेढ़ घंटा", note: "ครึ่ง after = ...and a half; order changes meaning / क्रम से अर्थ बदलता है"),
        ],
        340: [
            WordForm(thai: "เยอะมาก", romanization: "yóe mâak", english: "a whole lot / so much", hindi: "बहुत ज़्यादा", note: "เยอะ + มาก for emphasis / ज़ोर देने के लिए"),
        ],
        342: [
            WordForm(thai: "วันละ", romanization: "wan lá", english: "per day", hindi: "प्रतिदिन", note: "time word + ละ = per / समय-शब्द + ละ = प्रति"),
            WordForm(thai: "คนละ", romanization: "khon lá", english: "each person / per person", hindi: "हर व्यक्ति", note: "used when splitting bills / बिल बाँटते समय आम"),
        ],
        344: [
            WordForm(thai: "ยี่สิบเอ็ด", romanization: "yîi-sìp-èt", english: "twenty-one", hindi: "इक्कीस", note: "21 uses เอ็ด, not หนึ่ง / 21 में เอ็ด आता है, หนึ่ง नहीं"),
            WordForm(thai: "สามสิบ", romanization: "sǎam-sìp", english: "thirty", hindi: "तीस", note: "30 onwards: number + สิบ / 30 से आगे: संख्या + สิบ"),
        ],
        345: [
            WordForm(thai: "ในห้อง", romanization: "nai hôong", english: "in the room", hindi: "कमरे में", note: "ใน (nai) = in / में"),
        ],
        346: [
            WordForm(thai: "เปิดประตู", romanization: "pèrt prà-tuu", english: "to open the door", hindi: "दरवाज़ा खोलना", note: "verb + noun pattern / क्रिया + संज्ञा"),
            WordForm(thai: "ปิดประตู", romanization: "pìt prà-tuu", english: "to close the door", hindi: "दरवाज़ा बंद करना", note: ""),
        ],
        348: [
            WordForm(thai: "บนเตียง", romanization: "bon tiang", english: "on the bed", hindi: "बिस्तर पर", note: "บน (bon) = on / पर"),
        ],
        349: [
            WordForm(thai: "บนโต๊ะ", romanization: "bon tó", english: "on the table", hindi: "मेज़ पर", note: ""),
        ],
        351: [
            WordForm(thai: "เล่นมือถือ", romanization: "lên meuu-thěuu", english: "to use one's phone", hindi: "मोबाइल चलाना", note: "เล่น (lên) lit. play — everyday phrase / आम बोलचाल"),
        ],
        353: [
            WordForm(thai: "ซักเสื้อผ้า", romanization: "sák sûea-phâa", english: "to wash clothes", hindi: "कपड़े धोना", note: "ซัก (sák) = to wash clothes / धोना"),
        ],
        357: [
            WordForm(thai: "ค่าไฟ", romanization: "khâa fai", english: "electricity bill", hindi: "बिजली का बिल", note: "ค่า (khâa) = fee / शुल्क; ไฟฟ้า is often shortened to ไฟ"),
        ],
        361: [
            WordForm(thai: "ดูทีวี", romanization: "duu thii-wii", english: "to watch TV", hindi: "टीवी देखना", note: ""),
        ],
        365: [
            WordForm(thai: "แปรงฟัน", romanization: "praeng fan", english: "to brush one's teeth", hindi: "दाँत साफ़ करना", note: "แปรง as a verb = to brush / ब्रश करना"),
        ],
        368: [
            WordForm(thai: "ห่มผ้า", romanization: "hòm phâa", english: "to cover oneself with a blanket", hindi: "कंबल ओढ़ना", note: "word order flips for the verb / क्रिया के लिए क्रम उलट जाता है"),
        ],
        370: [
            WordForm(thai: "ภาษาจีน", romanization: "phaa-sǎa-jiin", english: "Chinese language", hindi: "चीनी भाषा", note: "ภาษา + country = that country's language / भाषा + देश = उस देश की भाषा"),
        ],
        373: [
            WordForm(thai: "แปลว่า...", romanization: "plae wâa...", english: "it means...", hindi: "...मतलब है", note: "used to give the meaning of a word / किसी शब्द का अर्थ बताने के लिए"),
        ],
        375: [
            WordForm(thai: "โทรหา + คน", romanization: "thoo hǎa + person", english: "to call someone", hindi: "किसी को फ़ोन करना", note: "โทรหาแม่ (thoo hǎa mâe) = call mom / माँ को फ़ोन करना"),
        ],
        385: [
            WordForm(thai: "มีประชุม", romanization: "mii prà-chum", english: "to have a meeting", hindi: "मीटिंग होना", note: "มี (have) + ประชุม = there is a meeting / मीटिंग है"),
        ],
        387: [
            WordForm(thai: "คุยกับ + คน", romanization: "khui kàp + person", english: "to chat with someone", hindi: "किसी से बात करना", note: "คุยกับเพื่อน (khui kàp phêuan) = chat with a friend / दोस्त से बात करना"),
        ],
        388: [
            WordForm(thai: "คำใหม่ 5 คำ", romanization: "kham mài hâa kham", english: "five new words", hindi: "पाँच नए शब्द", note: "คำ is also the classifier for words / คำ शब्दों का क्लासिफ़ायर भी है"),
        ],
        389: [
            WordForm(thai: "ปวดขา", romanization: "pùat khǎa", english: "leg pain", hindi: "टांग में दर्द", note: "ปวด + body part = ache there / ปวด + अंग = वहां दर्द"),
        ],
        390: [
            WordForm(thai: "เสื้อแขนสั้น", romanization: "sûea khǎen sân", english: "short-sleeved shirt", hindi: "आधी बाजू की कमीज़", note: "แขน also means sleeve / 'आस्तीन' भी"),
        ],
        391: [
            WordForm(thai: "ปวดท้อง", romanization: "pùat thóong", english: "stomachache", hindi: "पेट दर्द", note: "very common at clinics / क्लिनिक में बहुत आम"),
            WordForm(thai: "ท้องเสีย", romanization: "thóong sǐa", english: "diarrhea", hindi: "दस्त", note: "lit. broken stomach / शाब्दिक: खराब पेट"),
        ],
        392: [
            WordForm(thai: "อ้าปาก", romanization: "âa pàak", english: "to open the mouth", hindi: "मुंह खोलना", note: "doctor's instruction / डॉक्टर का निर्देश"),
        ],
        394: [
            WordForm(thai: "หูฟัง", romanization: "hǔu-fang", english: "earphones", hindi: "ईयरफोन", note: "หู + ฟัง (listen / सुनना)"),
        ],
        395: [
            WordForm(thai: "ผิวแห้ง", romanization: "phǐw hâeng", english: "dry skin", hindi: "रूखी त्वचा", note: ""),
        ],
        396: [
            WordForm(thai: "รองเท้า", romanization: "roong-tháo", english: "shoes", hindi: "जूते", note: "รอง support / सहारा + เท้า foot"),
        ],
        397: [
            WordForm(thai: "นิ้วเท้า", romanization: "níw tháo", english: "toe", hindi: "पैर की उंगली", note: ""),
        ],
        398: [
            WordForm(thai: "เจ็บคอ", romanization: "jèp khoo", english: "sore throat", hindi: "गले में दर्द", note: ""),
        ],
        399: [
            WordForm(thai: "ข้างหน้า", romanization: "khâang nâa", english: "in front / ahead", hindi: "आगे", note: "หน้า also = front / 'सामने' भी"),
        ],
        400: [
            WordForm(thai: "เจ็บคอ", romanization: "jèp khoo", english: "sore throat", hindi: "गले में दर्द", note: "เจ็บ + body part / เจ็บ + अंग"),
        ],
        401: [
            WordForm(thai: "เป็นไข้", romanization: "pen khâi", english: "to have a fever", hindi: "बुखार होना", note: "เป็น + illness = to have it / เป็น + बीमारी"),
        ],
        402: [
            WordForm(thai: "ยาแก้ไอ", romanization: "yaa kâe ai", english: "cough medicine", hindi: "खांसी की दवा", note: ""),
        ],
        403: [
            WordForm(thai: "เป็นหวัด", romanization: "pen wàt", english: "to have a cold", hindi: "ज़ुकाम होना", note: ""),
        ],
        404: [
            WordForm(thai: "ยาแก้ปวดหัว", romanization: "yaa kâe pùat hǔa", english: "headache medicine", hindi: "सिरदर्द की दवा", note: "หัว (hǔa) = head / सिर"),
        ],
        405: [
            WordForm(thai: "แพ้อาหาร", romanization: "pháe aa-hǎan", english: "food allergy", hindi: "खाने से एलर्जी", note: "แพ้ + thing = allergic to it / แพ้ + चीज़"),
        ],
        406: [
            WordForm(thai: "เลือดออก", romanization: "lûeat òok", english: "to bleed", hindi: "खून निकलना", note: ""),
        ],
        411: [
            WordForm(thai: "ประกันสุขภาพ", romanization: "prà-kan sùk-khà-phâap", english: "health insurance", hindi: "स्वास्थ्य बीमा", note: ""),
        ],
        187: [
            WordForm(thai: "ดีใจมาก", romanization: "dii-jai mâak", english: "very happy", hindi: "बहुत खुश", note: "มาก (mâak) = very / बहुत"),
            WordForm(thai: "ดีใจที่ได้เจอ", romanization: "dii-jai tîi dâai jer", english: "glad to meet (you)", hindi: "मिलकर खुशी हुई", note: "ดีใจที่... = happy that... / ...की खुशी"),
        ],
        188: [
            WordForm(thai: "อย่าเสียใจ", romanization: "yàa sǐa-jai", english: "don't be sad", hindi: "दुखी मत हो", note: "อย่า (yàa) = don't / मत"),
            WordForm(thai: "เสียใจด้วย", romanization: "sǐa-jai dûai", english: "I'm sorry for you", hindi: "मुझे अफ़सोस है", note: "used to console someone / सांत्वना देने के लिए"),
        ],
        189: [
            WordForm(thai: "ไม่โกรธ", romanization: "mâi kròot", english: "not angry", hindi: "नाराज़ नहीं", note: "ไม่ (mâi) negates / नहीं से इनकार"),
            WordForm(thai: "อย่าโกรธนะ", romanization: "yàa kròot ná", english: "please don't be angry", hindi: "नाराज़ मत होना", note: "นะ (ná) softens the sentence / वाक्य को नरम बनाता है"),
        ],
        190: [
            WordForm(thai: "เบื่อแล้ว", romanization: "bùea láew", english: "bored now / already bored", hindi: "अब ऊब गया", note: "แล้ว (láew) = already / अब हो चुका"),
        ],
        191: [
            WordForm(thai: "ตื่นเต้นมาก", romanization: "tùun-tên mâak", english: "very excited", hindi: "बहुत उत्साहित", note: "มาก (mâak) = very / बहुत"),
        ],
        192: [
            WordForm(thai: "คิดถึงมาก", romanization: "kít-tǔng mâak", english: "miss (you) a lot", hindi: "बहुत याद आती है", note: "มาก (mâak) = very much / बहुत"),
            WordForm(thai: "คิดถึงบ้าน", romanization: "kít-tǔng bâan", english: "homesick", hindi: "घर की याद", note: "บ้าน (bâan) = home / घर"),
        ],
        193: [
            WordForm(thai: "เจอกัน", romanization: "jer kan", english: "see you / meet each other", hindi: "मिलते हैं", note: "กัน (gan) = each other / एक-दूसरे से"),
            WordForm(thai: "เจอกันใหม่", romanization: "jer kan mài", english: "see you again", hindi: "फिर मिलेंगे", note: "ใหม่ (mài) = again-new / फिर से"),
        ],
        194: [
            WordForm(thai: "สักครู่", romanization: "sàk-krûu", english: "just a moment", hindi: "एक क्षण", note: "can be used alone / अकेले भी बोल सकते हैं"),
        ],
        195: [
            WordForm(thai: "อาจจะไม่", romanization: "àat-jà mâi", english: "maybe not", hindi: "शायद नहीं", note: "ไม่ (mâi) after it = maybe not / शायद नहीं"),
        ],
        196: [
            WordForm(thai: "แน่นอนครับ/ค่ะ", romanization: "nâe-non kráp/kâ", english: "of course! (polite)", hindi: "बिलकुल! (विनम्र)", note: "polite yes-answer / विनम्र जवाब"),
        ],
        197: [
            WordForm(thai: "ไปด้วยกันไหม", romanization: "pai dûai-kan mǎi?", english: "shall we go together?", hindi: "क्या साथ चलें?", note: "ไหม (mǎi) makes it a question / सवाल बनाता है"),
        ],
        198: [
            WordForm(thai: "มาคนเดียว", romanization: "maa kon-diao", english: "come alone", hindi: "अकेले आना", note: "placed after the verb / क्रिया के बाद आता है"),
        ],
        199: [
            WordForm(thai: "กระเป๋าใบนี้", romanization: "krà-pǎo bai níi", english: "this bag", hindi: "यह बैग", note: "ใบ is the classifier for bags / ใบ बैग का classifier है"),
        ],
        200: [
            WordForm(thai: "เสื้อตัวนี้", romanization: "sûea tua níi", english: "this shirt", hindi: "यह शर्ट", note: "ตัว is the classifier for shirts / ตัว शर्ट का classifier है"),
        ],
        201: [
            WordForm(thai: "รองเท้าคู่นี้", romanization: "rawng-táao khûu níi", english: "this pair of shoes", hindi: "जूतों की यह जोड़ी", note: "คู่ = pair, the classifier for shoes / คู่ = जोड़ी, जूतों का classifier"),
        ],
        202: [
            WordForm(thai: "สายชาร์จ", romanization: "sǎai-châat", english: "charging cable", hindi: "चार्जिंग केबल", note: "สาย = cord, line / สาย = तार"),
        ],
        203: [
            WordForm(thai: "ต่อราคาได้ไหม", romanization: "tàw raa-khaa dâi mǎi", english: "can I bargain?", hindi: "क्या मोल-भाव कर सकते हैं?", note: "Polite way to start bargaining / मोल-भाव शुरू करने का विनम्र तरीका"),
        ],
        204: [
            WordForm(thai: "ลดได้ไหม", romanization: "lót dâi mǎi", english: "can you reduce it?", hindi: "कम कर सकते हैं?", note: "Shorter version of the phrase / वाक्यांश का छोटा रूप"),
        ],
        205: [
            WordForm(thai: "ไซส์อะไร", romanization: "sái à-rai", english: "what size?", hindi: "कौन सा साइज़?", note: "Shop staff often ask this / दुकानदार अक्सर यह पूछते हैं"),
            WordForm(thai: "เล็กไป", romanization: "lék pai", english: "too small", hindi: "बहुत छोटा (ज़रूरत से ज़्यादा)", note: "adjective + ไป = too ... / adjective + ไป = ज़रूरत से ज़्यादा"),
        ],
        206: [
            WordForm(thai: "ไม่พอดี", romanization: "mâi phaw-dii", english: "doesn't fit", hindi: "फिट नहीं है", note: "ไม่ negates it / ไม่ नकारात्मक बनाता है"),
            WordForm(thai: "พอดีเลย", romanization: "phaw-dii loei", english: "fits perfectly", hindi: "एकदम फिट", note: "เลย adds emphasis / เลย ज़ोर देता है"),
        ],
        207: [
            WordForm(thai: "ลองดู", romanization: "lawng duu", english: "give it a try", hindi: "करके देखो", note: "Very common everyday phrase / रोज़मर्रा का बहुत आम वाक्यांश"),
        ],
        209: [
            WordForm(thai: "ไม่เอาถุง", romanization: "mâi ao tǔng", english: "no bag, please", hindi: "थैली नहीं चाहिए", note: "Handy eco-friendly phrase / पर्यावरण के लिए उपयोगी वाक्यांश"),
        ],
        210: [
            WordForm(thai: "กี่โมงแล้ว", romanization: "kìi mohng láew", english: "what time is it now?", hindi: "अभी कितने बजे हैं?", note: "แล้ว = already, now / แล้ว = अब"),
        ],
        211: [
            WordForm(thai: "ที่ชายหาด", romanization: "thîi chaai-hàat", english: "at the beach", hindi: "बीच पर", note: "ที่ (thîi) + place = at / ที่ + जगह = पर"),
        ],
        213: [
            WordForm(thai: "ตั๋วหนึ่งใบ", romanization: "tǔa nʉ̀ng bai", english: "one ticket", hindi: "एक टिकट", note: "ใบ (bai) is the classifier for tickets / ใบ (bai) टिकट गिनने का शब्द है"),
        ],
        214: [
            WordForm(thai: "นั่งเรือ", romanization: "nâng rʉa", english: "to ride a boat", hindi: "नाव की सवारी करना", note: "นั่ง (sit) + vehicle = to ride it / นั่ง (बैठना) + वाहन = उसकी सवारी करना"),
        ],
        217: [
            WordForm(thai: "ส้มตำไม่เผ็ด", romanization: "sôm-tam mâi phèt", english: "som tam, not spicy", hindi: "सोम-तम, तीखा नहीं", note: "Handy when ordering it mild / कम तीखा मँगवाने के लिए कहें"),
        ],
        219: [
            WordForm(thai: "น้ำหนึ่งขวด", romanization: "náam nʉ̀ng khùat", english: "one bottle of water", hindi: "एक बोतल पानी", note: "ขวด (khùat) also works as the classifier for bottles / ขวด बोतलें गिनने का classifier भी है"),
        ],
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

    private static let examples0: [Int: [WordExample]] = [
        425: [
            WordExample(thai: "บ้านนี้ใหญ่มาก", romanization: "bâan níi yài mâak", english: "This house is very big.", hindi: "यह घर बहुत बड़ा है।"),
            WordExample(thai: "ร้านนี้ดีมาก", romanization: "ráan níi dii mâak", english: "This shop is very good.", hindi: "यह दुकान बहुत अच्छी है।"),
        ],
        426: [
            WordExample(thai: "ขอกาแฟสองแก้วครับ", romanization: "khǒo kaa-fae sǒong kâew kráp", english: "Two coffees, please.", hindi: "दो गिलास कॉफ़ी दीजिए।"),
            WordExample(thai: "ขอน้ำแข็งค่ะ", romanization: "khǒo nám-khǎeng khâ", english: "May I have some ice?", hindi: "थोड़ी बर्फ़ दीजिए।"),
        ],
        427: [
            WordExample(thai: "คุณหิวไหม", romanization: "khun hǐu mǎi", english: "Are you hungry?", hindi: "क्या आपको भूख लगी है?"),
            WordExample(thai: "อาหารอร่อยไหม", romanization: "aa-hǎan à-ròi mǎi", english: "Is the food tasty?", hindi: "क्या खाना स्वादिष्ट है?"),
        ],
        428: [
            WordExample(thai: "ช่วยหน่อยครับ", romanization: "chûai nòi kráp", english: "Please help me a bit.", hindi: "ज़रा मदद कीजिए।"),
            WordExample(thai: "รอหน่อยนะ", romanization: "roo nòi ná", english: "Wait a moment, okay?", hindi: "ज़रा रुकिए, ठीक है?"),
        ],
        429: [
            WordExample(thai: "ผมชอบอาหารไทย", romanization: "phǒm chôp aa-hǎan thai", english: "I like Thai food.", hindi: "मुझे थाई खाना पसंद है।"),
            WordExample(thai: "เขาเป็นคนไทย", romanization: "khǎo pen khon thai", english: "He is Thai.", hindi: "वह थाई है।"),
        ],
        430: [
            WordExample(thai: "วันนี้ฝนตกมาก", romanization: "wan-níi fǒn tòk mâak", english: "It's raining a lot today.", hindi: "आज बहुत बारिश हो रही है।"),
            WordExample(thai: "ฝนตกทุกวัน", romanization: "fǒn tòk thúk-wan", english: "It rains every day.", hindi: "हर दिन बारिश होती है।"),
        ],
        431: [
            WordExample(thai: "เราไปกินข้าวกัน", romanization: "rao pai kin khâao kan", english: "Let's go eat together.", hindi: "चलो साथ में खाना खाएँ।"),
            WordExample(thai: "เขาเจอกันที่ตลาด", romanization: "khǎo joe kan thîi tà-làat", english: "They met each other at the market.", hindi: "वे बाज़ार में एक-दूसरे से मिले।"),
        ],
        432: [
            WordExample(thai: "นี่คืออะไร", romanization: "nîi khuue à-rai", english: "What is this?", hindi: "यह क्या है?"),
            WordExample(thai: "เขาคือเพื่อนของผม", romanization: "khǎo khuue phûean khǒong phǒm", english: "He is my friend.", hindi: "वह मेरा दोस्त है।"),
        ],
        433: [
            WordExample(thai: "อย่าลืมนะ", romanization: "yàa luem ná", english: "Don't forget, okay?", hindi: "भूलना मत, ठीक है?"),
            WordExample(thai: "อย่าไปที่นั่น", romanization: "yàa pai thîi-nân", english: "Don't go there.", hindi: "वहाँ मत जाओ।"),
        ],
        434: [
            WordExample(thai: "ตอนเช้าผมดื่มกาแฟ", romanization: "toon cháo phǒm dùem kaa-fae", english: "In the morning I drink coffee.", hindi: "सुबह मैं कॉफ़ी पीता हूँ।"),
            WordExample(thai: "เขามาตอนเย็น", romanization: "khǎo maa toon yen", english: "He comes in the evening.", hindi: "वह शाम को आता है।"),
        ],
        435: [
            WordExample(thai: "แมวนอนบนเตียง", romanization: "maew noon bon tiang", english: "The cat sleeps on the bed.", hindi: "बिल्ली बिस्तर पर सोती है।"),
            WordExample(thai: "มือถืออยู่บนโต๊ะ", romanization: "muue-thǔue yùu bon tó", english: "The phone is on the table.", hindi: "मोबाइल मेज़ पर है।"),
        ],
        436: [
            WordExample(thai: "ห้องน้ำอยู่ไหน", romanization: "hôong-náam yùu nǎi", english: "Where is the bathroom?", hindi: "शौचालय कहाँ है?"),
            WordExample(thai: "คุณอยู่ที่ไหน", romanization: "khun yùu thîi-nǎi", english: "Where are you?", hindi: "आप कहाँ हैं?"),
        ],
        437: [
            WordExample(thai: "ผมล้างมือก่อนกินข้าว", romanization: "phǒm láang muue kòon kin khâao", english: "I wash my hands before eating.", hindi: "मैं खाने से पहले हाथ धोता हूँ।"),
            WordExample(thai: "ฉันล้างจานทุกวัน", romanization: "chǎn láang jaan thúk-wan", english: "I wash the dishes every day.", hindi: "मैं हर दिन बर्तन धोती हूँ।"),
        ],
        438: [
            WordExample(thai: "เลี้ยวซ้ายที่ธนาคาร", romanization: "líao sáai thîi thá-naa-khaan", english: "Turn left at the bank.", hindi: "बैंक पर बाएँ मुड़िए।"),
            WordExample(thai: "เลี้ยวขวาแล้วตรงไป", romanization: "líao khwǎa láew trong-pai", english: "Turn right, then go straight.", hindi: "दाएँ मुड़िए, फिर सीधे जाइए।"),
        ],
        439: [
            WordExample(thai: "ไม่แพงเลย", romanization: "mâi phaeng loei", english: "Not expensive at all.", hindi: "बिल्कुल महँगा नहीं है।"),
            WordExample(thai: "อาหารอร่อยมากเลย", romanization: "aa-hǎan à-ròi mâak loei", english: "The food is really delicious!", hindi: "खाना सच में बहुत स्वादिष्ट है!"),
        ],
        440: [
            WordExample(thai: "ผมชอบอ่านหนังสือ", romanization: "phǒm chôp àan nǎng-sǔue", english: "I like reading books.", hindi: "मुझे किताबें पढ़ना पसंद है।"),
            WordExample(thai: "เขาซื้อหนังสือสองเล่ม", romanization: "khǎo súue nǎng-sǔue sǒong lêm", english: "He bought two books.", hindi: "उसने दो किताबें खरीदीं।"),
        ],
        441: [
            WordExample(thai: "คุณอายุเท่าไหร่", romanization: "khun aa-yú thâo-rài", english: "How old are you?", hindi: "आपकी उम्र कितनी है?"),
            WordExample(thai: "ลูกของฉันอายุห้าปี", romanization: "lûuk khǒong chǎn aa-yú hâa pii", english: "My child is five years old.", hindi: "मेरा बच्चा पाँच साल का है।"),
        ],
        442: [
            WordExample(thai: "กระเป๋าหนัก ผมยกไม่ได้", romanization: "krà-pǎo nàk phǒm yók mâi dâi", english: "The bag is heavy — I can't lift it.", hindi: "बैग भारी है — मैं उठा नहीं सकता।"),
            WordExample(thai: "เขายกมือถาม", romanization: "khǎo yók muue thǎam", english: "He raises his hand to ask.", hindi: "वह पूछने के लिए हाथ उठाता है।"),
        ],
        443: [
            WordExample(thai: "ค่าห้องเท่าไหร่", romanization: "khâa hôong thâo-rài", english: "How much is the room charge?", hindi: "कमरे का किराया कितना है?"),
            WordExample(thai: "ค่ารถแพงมาก", romanization: "khâa rót phaeng mâak", english: "The fare is very expensive.", hindi: "किराया बहुत महँगा है।"),
        ],
        444: [
            WordExample(thai: "เอากาแฟอีกแก้ว", romanization: "ao kaa-fae ìik kâew", english: "One more coffee, please.", hindi: "एक और गिलास कॉफ़ी दीजिए।"),
            WordExample(thai: "พรุ่งนี้มาอีกนะ", romanization: "phrûng-níi maa ìik ná", english: "Come again tomorrow, okay?", hindi: "कल फिर आना, ठीक है?"),
        ],
        445: [
            WordExample(thai: "เสื้อแห้งแล้ว", romanization: "sûea hâeng láew", english: "The shirt is already dry.", hindi: "शर्ट सूख गई है।"),
            WordExample(thai: "อากาศร้อนและแห้ง", romanization: "aa-kàat róon láe hâeng", english: "The weather is hot and dry.", hindi: "मौसम गरम और सूखा है।"),
        ],
        446: [
            WordExample(thai: "คุณเลิกงานกี่โมง", romanization: "khun lôek ngaan kìi-mohng", english: "What time do you finish work?", hindi: "आप कितने बजे काम से छूटते हैं?"),
            WordExample(thai: "ผมเลิกงานแล้ว", romanization: "phǒm lôek ngaan láew", english: "I've already finished work.", hindi: "मेरा काम ख़त्म हो गया है।"),
        ],
        447: [
            WordExample(thai: "ผมมีรถหนึ่งคัน", romanization: "phǒm mii rót nèung khan", english: "I have one car.", hindi: "मेरे पास एक गाड़ी है।"),
            WordExample(thai: "รถสองคันอยู่ที่บ้าน", romanization: "rót sǒong khan yùu thîi bâan", english: "Two cars are at the house.", hindi: "दो गाड़ियाँ घर पर हैं।"),
        ],
        448: [
            WordExample(thai: "ผมมาจากอินเดีย", romanization: "phǒm maa jàak in-dia", english: "I come from India.", hindi: "मैं भारत से आया हूँ।"),
            WordExample(thai: "อาหารอินเดียเผ็ดมาก", romanization: "aa-hǎan in-dia phèt mâak", english: "Indian food is very spicy.", hindi: "भारतीय खाना बहुत तीखा होता है।"),
        ],
        449: [
            WordExample(thai: "พรุ่งนี้เราไปเชียงใหม่", romanization: "phrûng-níi rao pai chiang-mài", english: "Tomorrow we go to Chiang Mai.", hindi: "कल हम चियांग माई जाएँगे।"),
            WordExample(thai: "อากาศที่เชียงใหม่ดีมาก", romanization: "aa-kàat thîi chiang-mài dii mâak", english: "The weather in Chiang Mai is very good.", hindi: "चियांग माई का मौसम बहुत अच्छा है।"),
        ],
        450: [
            WordExample(thai: "ผมอยู่ที่กรุงเทพ", romanization: "phǒm yùu thîi krung-thêep", english: "I live in Bangkok.", hindi: "मैं बैंकॉक में रहता हूँ।"),
            WordExample(thai: "เขาทำงานที่กรุงเทพ", romanization: "khǎo tham-ngaan thîi krung-thêep", english: "He works in Bangkok.", hindi: "वह बैंकॉक में काम करता है।"),
        ],
        223: [
            WordExample(thai: "เราไปตลาดด้วยกัน", romanization: "rao pai tà-làat dûai-kan", english: "We go to the market together.", hindi: "हम साथ में बाज़ार जाते हैं।"),
            WordExample(thai: "เราหิวมาก", romanization: "rao hǐu mâak", english: "We are very hungry.", hindi: "हमें बहुत भूख लगी है।"),
        ],
        224: [
            WordExample(thai: "เขาเป็นครู", romanization: "khǎo pen khruu", english: "He is a teacher.", hindi: "वह शिक्षक है।"),
            WordExample(thai: "เขาชอบกาแฟ", romanization: "khǎo chôop kaa-fae", english: "She likes coffee.", hindi: "उसे कॉफ़ी पसंद है।"),
        ],
        225: [
            WordExample(thai: "มันแพงมาก", romanization: "man phaeng mâak", english: "It is very expensive.", hindi: "यह बहुत महँगा है।"),
            WordExample(thai: "มันอร่อย", romanization: "man à-ròi", english: "It is delicious.", hindi: "यह स्वादिष्ट है।"),
        ],
        226: [
            WordExample(thai: "นี่กระเป๋าของฉัน", romanization: "nîi krà-pǎo khǒong chǎn", english: "This is my bag.", hindi: "यह मेरा बैग है।"),
            WordExample(thai: "บ้านของเขาใหญ่", romanization: "bâan khǒong khǎo yài", english: "His house is big.", hindi: "उसका घर बड़ा है।"),
        ],
        227: [
            WordExample(thai: "แมวอยู่ในบ้าน", romanization: "maew yùu nai bâan", english: "The cat is in the house.", hindi: "बिल्ली घर में है।"),
            WordExample(thai: "ในกระเป๋ามีเงิน", romanization: "nai krà-pǎo mii ngern", english: "There is money in the bag.", hindi: "बैग में पैसे हैं।"),
        ],
        228: [
            WordExample(thai: "ผมมาจากอินเดีย", romanization: "phǒm maa jàak in-dia", english: "I come from India.", hindi: "मैं भारत से आया हूँ।"),
            WordExample(thai: "เขามาจากเชียงใหม่", romanization: "khǎo maa jàak chiang-mài", english: "He comes from Chiang Mai.", hindi: "वह चियांग माई से आया है।"),
        ],
        229: [
            WordExample(thai: "เราถึงโรงแรมแล้ว", romanization: "rao thǔeng roong-raem láew", english: "We have arrived at the hotel.", hindi: "हम होटल पहुँच गए हैं।"),
            WordExample(thai: "รอถึงพรุ่งนี้ได้ไหม", romanization: "roo thǔeng phrûng-níi dâi mǎi", english: "Can you wait until tomorrow?", hindi: "क्या कल तक इंतज़ार कर सकते हैं?"),
        ],
        230: [
            WordExample(thai: "พรุ่งนี้ฉันจะไปตลาด", romanization: "phrûng-níi chǎn jà pai tà-làat", english: "Tomorrow I will go to the market.", hindi: "कल मैं बाज़ार जाऊँगी।"),
            WordExample(thai: "เขาจะมาที่นี่", romanization: "khǎo jà maa thîi-nîi", english: "He will come here.", hindi: "वह यहाँ आएगा।"),
        ],
        231: [
            WordExample(thai: "คุณพูดไทยได้ไหม", romanization: "khun phûut thai dâi mǎi", english: "Can you speak Thai?", hindi: "क्या आप थाई बोल सकते हैं?"),
            WordExample(thai: "ฉันไปได้", romanization: "chǎn pai dâi", english: "I can go.", hindi: "मैं जा सकती हूँ।"),
        ],
        232: [
            WordExample(thai: "ผมเป็นหมอ", romanization: "phǒm pen mǒo", english: "I am a doctor.", hindi: "मैं डॉक्टर हूँ।"),
            WordExample(thai: "เขาเป็นเพื่อนของฉัน", romanization: "khǎo pen phûean khǒong chǎn", english: "He is my friend.", hindi: "वह मेरा दोस्त है।"),
        ],
        233: [
            WordExample(thai: "คุณอยู่ที่ไหน", romanization: "khun yùu thîi-nǎi", english: "Where are you?", hindi: "आप कहाँ हैं?"),
            WordExample(thai: "ฉันอยู่บ้าน", romanization: "chǎn yùu bâan", english: "I am at home.", hindi: "मैं घर पर हूँ।"),
        ],
        234: [
            WordExample(thai: "ฉันมีลูกสองคน", romanization: "chǎn mii lûuk sǒong khon", english: "I have two children.", hindi: "मेरे दो बच्चे हैं।"),
            WordExample(thai: "มีห้องน้ำไหม", romanization: "mii hôong-náam mǎi", english: "Is there a bathroom?", hindi: "क्या यहाँ शौचालय है?"),
        ],
        235: [
            WordExample(thai: "ฉันกินกาแฟทุกวัน", romanization: "chǎn kin kaa-fae thúk wan", english: "I drink coffee every day.", hindi: "मैं हर दिन कॉफ़ी पीती हूँ।"),
            WordExample(thai: "ทุกคนชอบอาหารไทย", romanization: "thúk khon chôop aa-hǎan thai", english: "Everyone likes Thai food.", hindi: "सबको थाई खाना पसंद है।"),
        ],
        236: [
            WordExample(thai: "บางคนไม่ชอบเผ็ด", romanization: "baang khon mâi chôop phèt", english: "Some people don't like spicy food.", hindi: "कुछ लोग तीखा पसंद नहीं करते।"),
            WordExample(thai: "บางวันฝนตก", romanization: "baang wan fǒn tòk", english: "Some days it rains.", hindi: "कुछ दिनों में बारिश होती है।"),
        ],
        237: [
            WordExample(thai: "ฉันก็ชอบ", romanization: "chǎn kô chôop", english: "I like it too.", hindi: "मुझे भी पसंद है।"),
            WordExample(thai: "เขาไป ฉันก็ไป", romanization: "khǎo pai chǎn kô pai", english: "He goes, so I go too.", hindi: "वह जाता है तो मैं भी जाती हूँ।"),
        ],
        238: [
            WordExample(thai: "ฉันยังหิว", romanization: "chǎn yang hǐu", english: "I am still hungry.", hindi: "मुझे अभी भी भूख लगी है।"),
            WordExample(thai: "เขายังไม่มา", romanization: "khǎo yang mâi maa", english: "He has not come yet.", hindi: "वह अभी तक नहीं आया।"),
        ],
        239: [
            WordExample(thai: "ฉันไปกับเพื่อน", romanization: "chǎn pai kàp phûean", english: "I go with a friend.", hindi: "मैं दोस्त के साथ जाती हूँ।"),
            WordExample(thai: "กินข้าวกับแกงไหม", romanization: "kin khâao kàp kaeng mǎi", english: "Will you eat rice with curry?", hindi: "चावल करी के साथ खाओगे?"),
        ],
        240: [
            WordExample(thai: "เขาทำงานที่โรงพยาบาล", romanization: "khǎo tham-ngaan thîi roong-phá-yaa-baan", english: "He works at the hospital.", hindi: "वह अस्पताल में काम करता है।"),
            WordExample(thai: "ฉันรอที่ร้านกาแฟ", romanization: "chǎn roo thîi ráan kaa-fae", english: "I am waiting at the coffee shop.", hindi: "मैं कॉफ़ी शॉप पर इंतज़ार कर रही हूँ।"),
        ],
        241: [
            WordExample(thai: "ฉันกินข้าวแล้ว", romanization: "chǎn kin khâao láew", english: "I have already eaten.", hindi: "मैं खाना खा चुकी हूँ।"),
            WordExample(thai: "เขาไปแล้ว", romanization: "khǎo pai láew", english: "He has already left.", hindi: "वह जा चुका है।"),
        ],
        242: [
            WordExample(thai: "ฉันต้องไปทำงาน", romanization: "chǎn tôong pai tham-ngaan", english: "I have to go to work.", hindi: "मुझे काम पर जाना है।"),
            WordExample(thai: "คุณต้องรอที่นี่", romanization: "khun tôong roo thîi-nîi", english: "You must wait here.", hindi: "आपको यहाँ इंतज़ार करना होगा।"),
        ],
        243: [
            WordExample(thai: "ฉันอยากกินผัดไทย", romanization: "chǎn yàak kin phàt-thai", english: "I want to eat pad thai.", hindi: "मैं पैड थाई खाना चाहती हूँ।"),
            WordExample(thai: "เขาอยากไปทะเล", romanization: "khǎo yàak pai thá-lee", english: "He wants to go to the sea.", hindi: "वह समुद्र जाना चाहता है।"),
        ],
        244: [
            WordExample(thai: "แม่ให้เงินลูก", romanization: "mâe hâi ngern lûuk", english: "Mother gives money to the child.", hindi: "माँ बच्चे को पैसे देती है।"),
            WordExample(thai: "เขาซื้อกาแฟให้ฉัน", romanization: "khǎo súe kaa-fae hâi chǎn", english: "He buys coffee for me.", hindi: "वह मेरे लिए कॉफ़ी खरीदता है।"),
        ],
        245: [
            WordExample(thai: "เขาพูดว่าจะมา", romanization: "khǎo phûut wâa jà maa", english: "He said that he will come.", hindi: "उसने कहा कि वह आएगा।"),
            WordExample(thai: "ฉันคิดว่าอร่อย", romanization: "chǎn khít wâa à-ròi", english: "I think that it is delicious.", hindi: "मुझे लगता है कि यह स्वादिष्ट है।"),
        ],
        246: [
            WordExample(thai: "ฉันไปด้วย", romanization: "chǎn pai dûai", english: "I am going too.", hindi: "मैं भी जा रही हूँ।"),
            WordExample(thai: "ขอน้ำด้วย", romanization: "khǒo náam dûai", english: "Please bring water too.", hindi: "पानी भी दीजिए।"),
        ],
        247: [
            WordExample(thai: "ฉันไปก่อนนะ", romanization: "chǎn pai kòon ná", english: "I'm leaving now, okay?", hindi: "मैं अब चलती हूँ, ठीक है ना?"),
            WordExample(thai: "รอหน่อยนะ", romanization: "roo nòi ná", english: "Wait a moment, okay?", hindi: "थोड़ा रुको ना।"),
        ],
        248: [
            WordExample(thai: "เอาอันนี้ครับ", romanization: "ao an níi khráp", english: "I'll take this one.", hindi: "यह वाला दीजिए।"),
            WordExample(thai: "เอากาแฟไหม", romanization: "ao kaa-fae mái", english: "Do you want coffee?", hindi: "कॉफ़ी लेंगे?"),
        ],
        249: [
            WordExample(thai: "ผมดื่มกาแฟทุกเช้า", romanization: "phǒm dùem kaa-fae thúk cháao", english: "I drink coffee every morning.", hindi: "मैं हर सुबह कॉफ़ी पीता हूँ।"),
            WordExample(thai: "ฉันไม่ดื่มชา", romanization: "chǎn mâi dùem chaa", english: "I don't drink tea.", hindi: "मैं चाय नहीं पीती।"),
        ],
        250: [
            WordExample(thai: "ผมใช้โทรศัพท์ทุกวัน", romanization: "phǒm chái thoo-rá-sàp thúk wan", english: "I use my phone every day.", hindi: "मैं रोज़ फ़ोन इस्तेमाल करता हूँ।"),
            WordExample(thai: "ใช้ยังไง", romanization: "chái yang-ngai", english: "How do I use it?", hindi: "यह कैसे इस्तेमाल करते हैं?"),
        ],
        251: [
            WordExample(thai: "ผมหากระเป๋าไม่เจอ", romanization: "phǒm hǎa krà-pǎo mâi jer", english: "I can't find my bag.", hindi: "मुझे मेरा बैग नहीं मिल रहा।"),
            WordExample(thai: "คุณหาอะไร", romanization: "khun hǎa à-rai", english: "What are you looking for?", hindi: "आप क्या ढूँढ रहे हैं?"),
        ],
        252: [
            WordExample(thai: "ผมเห็นแมวที่ตลาด", romanization: "phǒm hěn maew thîi tà-làat", english: "I saw a cat at the market.", hindi: "मैंने बाज़ार में एक बिल्ली देखी।"),
            WordExample(thai: "คุณเห็นไหม", romanization: "khun hěn mái", english: "Do you see it?", hindi: "आपको दिख रहा है?"),
        ],
        253: [
            WordExample(thai: "บอกผมหน่อย", romanization: "bòok phǒm nòi", english: "Please tell me.", hindi: "मुझे बताइए।"),
            WordExample(thai: "แม่บอกว่าอาหารอร่อย", romanization: "mâe bòok wâa aa-hǎan à-ròi", english: "Mom said the food is delicious.", hindi: "माँ ने कहा कि खाना स्वादिष्ट है।"),
        ],
        254: [
            WordExample(thai: "ขอถามหน่อย", romanization: "khǒo thǎam nòi", english: "May I ask something?", hindi: "एक बात पूछूँ?"),
            WordExample(thai: "เขาถามชื่อผม", romanization: "kháo thǎam chûe phǒm", english: "He asked my name.", hindi: "उसने मेरा नाम पूछा।"),
        ],
        255: [
            WordExample(thai: "ผมตอบไม่ได้", romanization: "phǒm tòop mâi dâai", english: "I can't answer.", hindi: "मैं जवाब नहीं दे सकता।"),
            WordExample(thai: "ครูตอบคำถาม", romanization: "khruu tòop kham-thǎam", english: "The teacher answers the question.", hindi: "शिक्षक सवाल का जवाब देते हैं।"),
        ],
        256: [
            WordExample(thai: "เด็กๆ เล่นที่ชายหาด", romanization: "dèk-dèk lên thîi chaai-hàat", english: "The children play at the beach.", hindi: "बच्चे समुद्र-तट पर खेलते हैं।"),
            WordExample(thai: "ผมชอบเล่นโทรศัพท์", romanization: "phǒm chôop lên thoo-rá-sàp", english: "I like playing on my phone.", hindi: "मुझे फ़ोन चलाना पसंद है।"),
        ],
        257: [
            WordExample(thai: "ผมเรียนภาษาไทย", romanization: "phǒm rian phaa-sǎa thai", english: "I study Thai.", hindi: "मैं थाई भाषा सीख रहा हूँ।"),
            WordExample(thai: "น้องเรียนที่โรงเรียน", romanization: "nóong rian thîi roong-rian", english: "My younger sibling studies at school.", hindi: "मेरा छोटा भाई स्कूल में पढ़ता है।"),
        ],
        258: [
            WordExample(thai: "ครูสอนภาษาไทย", romanization: "khruu sǒon phaa-sǎa thai", english: "The teacher teaches Thai.", hindi: "शिक्षक थाई पढ़ाते हैं।"),
            WordExample(thai: "ช่วยสอนผมหน่อย", romanization: "chûai sǒon phǒm nòi", english: "Please teach me.", hindi: "मुझे सिखाइए।"),
        ],
        259: [
            WordExample(thai: "ผมจ่ายเงินแล้ว", romanization: "phǒm jàai ngern láew", english: "I already paid.", hindi: "मैंने पैसे दे दिए।"),
            WordExample(thai: "จ่ายที่ไหน", romanization: "jàai thîi-nǎi", english: "Where do I pay?", hindi: "भुगतान कहाँ करूँ?"),
        ],
        260: [
            WordExample(thai: "ผมจำชื่อคุณได้", romanization: "phǒm jam chûe khun dâai", english: "I remember your name.", hindi: "मुझे आपका नाम याद है।"),
            WordExample(thai: "ฉันจำไม่ได้", romanization: "chǎn jam mâi dâai", english: "I don't remember.", hindi: "मुझे याद नहीं आ रहा।"),
        ],
        261: [
            WordExample(thai: "ผมลืมโทรศัพท์ที่บ้าน", romanization: "phǒm luem thoo-rá-sàp thîi bâan", english: "I forgot my phone at home.", hindi: "मैं फ़ोन घर पर भूल गया।"),
            WordExample(thai: "อย่าลืมนะ", romanization: "yàa luem ná", english: "Don't forget!", hindi: "भूलना मत!"),
        ],
        262: [
            WordExample(thai: "เริ่มกี่โมง", romanization: "rêrm kìi moong", english: "What time does it start?", hindi: "कितने बजे शुरू होगा?"),
            WordExample(thai: "ฝนเริ่มตก", romanization: "fǒn rêrm tòk", english: "It's starting to rain.", hindi: "बारिश शुरू हो रही है।"),
        ],
        263: [
            WordExample(thai: "ทำงานเสร็จแล้ว", romanization: "tham-ngaan sèt láew", english: "I'm done with work.", hindi: "काम ख़त्म हो गया।"),
            WordExample(thai: "เสร็จหรือยัง", romanization: "sèt rǔe yang", english: "Are you done yet?", hindi: "हो गया क्या?"),
        ],
        264: [
            WordExample(thai: "ผมส่งเงินให้แม่", romanization: "phǒm sòng ngern hâi mâe", english: "I send money to mom.", hindi: "मैं माँ को पैसे भेजता हूँ।"),
            WordExample(thai: "ช่วยส่งช้อนให้หน่อย", romanization: "chûai sòng chóon hâi nòi", english: "Please pass me the spoon.", hindi: "ज़रा चम्मच पकड़ा दीजिए।"),
        ],
        265: [
            WordExample(thai: "รับอะไรดีคะ", romanization: "ráp à-rai dii khá", english: "What would you like (to order)?", hindi: "आप क्या लेंगे?"),
            WordExample(thai: "ผมไปรับลูกที่โรงเรียน", romanization: "phǒm pai ráp lûuk thîi roong-rian", english: "I'm going to pick up my child at school.", hindi: "मैं बच्चे को स्कूल से लेने जा रहा हूँ।"),
        ],
        266: [
            WordExample(thai: "ขอเปลี่ยนได้ไหม", romanization: "khǒo plìan dâai mái", english: "Can I change it?", hindi: "क्या मैं इसे बदल सकता हूँ?"),
            WordExample(thai: "อากาศเปลี่ยนเร็ว", romanization: "aa-kàat plìan reo", english: "The weather changes quickly.", hindi: "मौसम जल्दी बदलता है।"),
        ],
        267: [
            WordExample(thai: "เลือกอันไหนดี", romanization: "lûeak an nǎi dii", english: "Which one should I choose?", hindi: "कौन-सा चुनूँ?"),
            WordExample(thai: "ฉันเลือกสีแดง", romanization: "chǎn lûeak sǐi daeng", english: "I choose the red color.", hindi: "मैं लाल रंग चुनती हूँ।"),
        ],
        268: [
            WordExample(thai: "วันนี้ฉันใส่เสื้อสีขาว", romanization: "wan-níi chǎn sài sûea sǐi khǎao", english: "Today I'm wearing a white shirt.", hindi: "आज मैंने सफ़ेद शर्ट पहनी है।"),
            WordExample(thai: "ไม่ใส่น้ำตาลครับ", romanization: "mâi sài nám-taan khráp", english: "No sugar, please.", hindi: "चीनी मत डालिए।"),
        ],
        269: [
            WordExample(thai: "นั่งที่นี่ได้ไหม", romanization: "nâng thîi-nîi dâai mái", english: "Can I sit here?", hindi: "क्या मैं यहाँ बैठ सकता हूँ?"),
            WordExample(thai: "ผมนั่งรถไฟไปทำงาน", romanization: "phǒm nâng rót-fai pai tham-ngaan", english: "I take the train to work.", hindi: "मैं ट्रेन से काम पर जाता हूँ।"),
        ],
        270: [
            WordExample(thai: "อาหารไทยอร่อยมาก", romanization: "aa-hǎan thai à-ròi mâak", english: "Thai food is very delicious.", hindi: "थाई खाना बहुत स्वादिष्ट है।"),
            WordExample(thai: "ขอบคุณมากครับ", romanization: "khòp-khun mâak khráp", english: "Thank you very much.", hindi: "बहुत-बहुत धन्यवाद।"),
        ],
        271: [
            WordExample(thai: "ผมมีเงินน้อย", romanization: "phǒm mii ngern nói", english: "I have little money.", hindi: "मेरे पास कम पैसे हैं।"),
            WordExample(thai: "ขอน้ำตาลน้อยหน่อย", romanization: "khǒo náam-taan nói nòi", english: "A little less sugar, please.", hindi: "थोड़ी कम चीनी देना।"),
        ],
        272: [
            WordExample(thai: "วันนี้อากาศแย่มาก", romanization: "wan-níi aa-kàat yâe mâak", english: "The weather is very bad today.", hindi: "आज मौसम बहुत ख़राब है।"),
            WordExample(thai: "ผมรู้สึกแย่", romanization: "phǒm rúu-sùek yâe", english: "I feel bad.", hindi: "मुझे बुरा लग रहा है।"),
        ],
        273: [
            WordExample(thai: "ผมง่วงมาก", romanization: "phǒm ngûang mâak", english: "I am very sleepy.", hindi: "मुझे बहुत नींद आ रही है।"),
            WordExample(thai: "กินข้าวแล้วง่วงนอน", romanization: "kin khâao láew ngûang-noon", english: "After eating I feel sleepy.", hindi: "खाना खाकर नींद आती है।"),
        ],
        274: [
            WordExample(thai: "ห้องน้ำที่นี่สะอาด", romanization: "hông-náam thîi-nîi sà-àat", english: "The bathroom here is clean.", hindi: "यहाँ का बाथरूम साफ़ है।"),
            WordExample(thai: "โรงแรมนี้สะอาดมาก", romanization: "roong-raem níi sà-àat mâak", english: "This hotel is very clean.", hindi: "यह होटल बहुत साफ़ है।"),
        ],
        275: [
            WordExample(thai: "รองเท้าของผมสกปรก", romanization: "roong-tháao khǒong phǒm sòk-kà-pròk", english: "My shoes are dirty.", hindi: "मेरे जूते गंदे हैं।"),
            WordExample(thai: "ถนนนี้สกปรกมาก", romanization: "thà-nǒn níi sòk-kà-pròk mâak", english: "This street is very dirty.", hindi: "यह सड़क बहुत गंदी है।"),
        ],
        276: [
            WordExample(thai: "ผมอิ่มแล้ว ขอบคุณครับ", romanization: "phǒm ìm láew khòp-khun khráp", english: "I'm full already, thank you.", hindi: "मेरा पेट भर गया, धन्यवाद।"),
            WordExample(thai: "อิ่มมาก อาหารอร่อย", romanization: "ìm mâak aa-hǎan à-ròi", english: "I'm so full, the food was delicious.", hindi: "पेट बहुत भर गया, खाना स्वादिष्ट था।"),
        ],
        277: [
            WordExample(thai: "พรุ่งนี้คุณว่างไหม", romanization: "phrûng-níi khun wâang mǎi", english: "Are you free tomorrow?", hindi: "क्या आप कल खाली हैं?"),
            WordExample(thai: "ห้องนี้ว่าง", romanization: "hông níi wâang", english: "This room is vacant.", hindi: "यह कमरा खाली है।"),
        ],
        278: [
            WordExample(thai: "แมวของฉันอ้วนมาก", romanization: "maew khǒong chǎn ûan mâak", english: "My cat is very fat.", hindi: "मेरी बिल्ली बहुत मोटी है।"),
            WordExample(thai: "กินมากจะอ้วน", romanization: "kin mâak jà ûan", english: "Eating a lot makes you fat.", hindi: "ज़्यादा खाने से मोटे हो जाओगे।"),
        ],
        279: [
            WordExample(thai: "น้องของผมผอมมาก", romanization: "nóong khǒong phǒm phǒom mâak", english: "My younger sibling is very thin.", hindi: "मेरा छोटा भाई बहुत दुबला है।"),
            WordExample(thai: "หมาตัวนี้ผอม", romanization: "mǎa tua níi phǒom", english: "This dog is thin.", hindi: "यह कुत्ता दुबला है।"),
        ],
        280: [
            WordExample(thai: "ผมของฉันสั้น", romanization: "phǒm khǒong chǎn sân", english: "My hair is short.", hindi: "मेरे बाल छोटे हैं।"),
            WordExample(thai: "ถนนนี้สั้น", romanization: "thà-nǒn níi sân", english: "This road is short.", hindi: "यह सड़क छोटी है।"),
        ],
        281: [
            WordExample(thai: "แม่มีผมยาว", romanization: "mâe mii phǒm yaao", english: "Mom has long hair.", hindi: "माँ के बाल लंबे हैं।"),
            WordExample(thai: "ถนนนี้ยาวมาก", romanization: "thà-nǒn níi yaao mâak", english: "This road is very long.", hindi: "यह सड़क बहुत लंबी है।"),
        ],
        282: [
            WordExample(thai: "ถนนนี้กว้างมาก", romanization: "thà-nǒn níi kwâang mâak", english: "This road is very wide.", hindi: "यह सड़क बहुत चौड़ी है।"),
            WordExample(thai: "ห้องนี้กว้างและสบาย", romanization: "hông níi kwâang láe sà-baai", english: "This room is spacious and comfortable.", hindi: "यह कमरा चौड़ा और आरामदायक है।"),
        ],
        283: [
            WordExample(thai: "ถนนที่นี่แคบมาก", romanization: "thà-nǒn thîi-nîi khâep mâak", english: "The streets here are very narrow.", hindi: "यहाँ की सड़कें बहुत संकरी हैं।"),
            WordExample(thai: "ห้องน้ำแคบ", romanization: "hông-náam khâep", english: "The bathroom is narrow.", hindi: "बाथरूम तंग है।"),
        ],
        284: [
            WordExample(thai: "กระเป๋าใบนี้หนักมาก", romanization: "krà-pǎo bai níi nàk mâak", english: "This bag is very heavy.", hindi: "यह बैग बहुत भारी है।"),
            WordExample(thai: "ช้างตัวนี้ใหญ่และหนัก", romanization: "cháang tua níi yài láe nàk", english: "This elephant is big and heavy.", hindi: "यह हाथी बड़ा और भारी है।"),
        ],
        285: [
            WordExample(thai: "โทรศัพท์ของฉันเบา", romanization: "thoo-rá-sàp khǒong chǎn bao", english: "My phone is light.", hindi: "मेरा फ़ोन हल्का है।"),
            WordExample(thai: "พูดเบา ๆ หน่อย", romanization: "phûut bao bao nòi", english: "Please speak softly.", hindi: "थोड़ा धीरे बोलिए।"),
        ],
        286: [
            WordExample(thai: "ที่ตลาดเสียงดังมาก", romanization: "thîi tà-làat sǐang dang mâak", english: "It's very noisy at the market.", hindi: "बाज़ार में बहुत शोर है।"),
            WordExample(thai: "คุณพูดดังมาก", romanization: "khun phûut dang mâak", english: "You speak very loudly.", hindi: "आप बहुत ज़ोर से बोलते हैं।"),
        ],
        287: [
            WordExample(thai: "ห้องนี้เงียบมาก", romanization: "hông níi ngîap mâak", english: "This room is very quiet.", hindi: "यह कमरा बहुत शांत है।"),
            WordExample(thai: "กลางคืนที่นี่เงียบ", romanization: "klaang-khuun thîi-nîi ngîap", english: "It's quiet here at night.", hindi: "रात में यहाँ शांति रहती है।"),
        ],
        288: [
            WordExample(thai: "คุณพูดไทยเก่งมาก", romanization: "khun phûut thai kèng mâak", english: "You speak Thai very well.", hindi: "आप बहुत अच्छी थाई बोलते हैं।"),
            WordExample(thai: "ลูกของฉันเรียนเก่ง", romanization: "lûuk khǒong chǎn rian kèng", english: "My child is good at studying.", hindi: "मेरा बच्चा पढ़ाई में होशियार है।"),
        ],
        289: [
            WordExample(thai: "กาแฟหอมมาก", romanization: "kaa-fae hǒom mâak", english: "The coffee smells very good.", hindi: "कॉफ़ी की खुशबू बहुत अच्छी है।"),
            WordExample(thai: "ดอกไม้นี้หอม", romanization: "dòok-máai níi hǒom", english: "This flower is fragrant.", hindi: "यह फूल खुशबूदार है।"),
        ],
        290: [
            WordExample(thai: "โรงแรมนี้สบายมาก", romanization: "roong-raem níi sà-baai mâak", english: "This hotel is very comfortable.", hindi: "यह होटल बहुत आरामदायक है।"),
            WordExample(thai: "นอนสบายไหม", romanization: "noon sà-baai mǎi", english: "Did you sleep comfortably?", hindi: "आराम से सोए क्या?"),
        ],
        291: [
            WordExample(thai: "ครอบครัวสำคัญมาก", romanization: "khrôop-khrua sǎm-khan mâak", english: "Family is very important.", hindi: "परिवार बहुत महत्वपूर्ण है।"),
            WordExample(thai: "วันนี้เป็นวันสำคัญ", romanization: "wan-níi pen wan sǎm-khan", english: "Today is an important day.", hindi: "आज महत्वपूर्ण दिन है।"),
        ],
        292: [
            WordExample(thai: "ถูกต้องครับ", romanization: "thùuk-tông khráp", english: "That's correct.", hindi: "बिल्कुल सही।"),
            WordExample(thai: "คำตอบนี้ถูกต้อง", romanization: "kham-tòop níi thùuk-tông", english: "This answer is correct.", hindi: "यह जवाब सही है।"),
        ],
        293: [
            WordExample(thai: "ผมเข้าใจผิด", romanization: "phǒm khâo-jai phìt", english: "I misunderstood.", hindi: "मैंने गलत समझा।"),
            WordExample(thai: "คำตอบนี้ผิด", romanization: "kham-tòop níi phìt", english: "This answer is wrong.", hindi: "यह जवाब गलत है।"),
        ],
        294: [
            WordExample(thai: "ภูเขานี้สูงมาก", romanization: "phuu-khǎo níi sǔung mâak", english: "This mountain is very high.", hindi: "यह पहाड़ बहुत ऊँचा है।"),
            WordExample(thai: "พ่อของฉันสูง", romanization: "phôo khǒong chǎn sǔung", english: "My father is tall.", hindi: "मेरे पिता लंबे हैं।"),
        ],
        295: [
            WordExample(thai: "วันจันทร์ผมไปทำงาน", romanization: "wan-jan phǒm pai tham-ngaan", english: "On Monday I go to work.", hindi: "सोमवार को मैं काम पर जाता हूँ।"),
            WordExample(thai: "ร้านปิดวันจันทร์", romanization: "ráan pìt wan-jan", english: "The shop is closed on Monday.", hindi: "दुकान सोमवार को बंद रहती है।"),
        ],
        296: [
            WordExample(thai: "วันอังคารฉันเรียนภาษาไทย", romanization: "wan-ang-khaan chǎn rian phaa-sǎa-thai", english: "On Tuesday I study Thai.", hindi: "मंगलवार को मैं थाई सीखती हूँ।"),
            WordExample(thai: "พรุ่งนี้เป็นวันอังคาร", romanization: "phrûng-níi pen wan-ang-khaan", english: "Tomorrow is Tuesday.", hindi: "कल मंगलवार है।"),
        ],
        297: [
            WordExample(thai: "วันนี้เป็นวันพุธ", romanization: "wan-níi pen wan-phút", english: "Today is Wednesday.", hindi: "आज बुधवार है।"),
            WordExample(thai: "วันพุธผมไปตลาด", romanization: "wan-phút phǒm pai tà-làat", english: "On Wednesday I go to the market.", hindi: "बुधवार को मैं बाज़ार जाता हूँ।"),
        ],
        298: [
            WordExample(thai: "วันพฤหัสฉันว่าง", romanization: "wan-phá-rúe-hàt chǎn wâang", english: "On Thursday I am free.", hindi: "गुरुवार को मैं खाली हूँ।"),
            WordExample(thai: "เจอกันวันพฤหัสนะ", romanization: "jer-kan wan-phá-rúe-hàt ná", english: "See you on Thursday!", hindi: "गुरुवार को मिलते हैं!"),
        ],
        299: [
            WordExample(thai: "วันศุกร์ผมดีใจมาก", romanization: "wan-sùk phǒm dii-jai mâak", english: "On Friday I am very happy.", hindi: "शुक्रवार को मैं बहुत खुश होता हूँ।"),
            WordExample(thai: "วันศุกร์ไปกินข้าวกันไหม", romanization: "wan-sùk pai kin khâao kan mái", english: "Shall we go eat together on Friday?", hindi: "शुक्रवार को साथ खाना खाने चलें?"),
        ],
        300: [
            WordExample(thai: "วันเสาร์ฉันไม่ทำงาน", romanization: "wan-sǎo chǎn mâi tham-ngaan", english: "On Saturday I do not work.", hindi: "शनिवार को मैं काम नहीं करती।"),
            WordExample(thai: "วันเสาร์ผมไปทะเล", romanization: "wan-sǎo phǒm pai thá-lee", english: "On Saturday I go to the sea.", hindi: "शनिवार को मैं समुद्र जाता हूँ।"),
        ],
        301: [
            WordExample(thai: "วันอาทิตย์ผมตื่นสาย", romanization: "wan-aa-thít phǒm tùen sǎai", english: "On Sunday I wake up late.", hindi: "रविवार को मैं देर से उठता हूँ।"),
            WordExample(thai: "วันอาทิตย์ฉันไปวัด", romanization: "wan-aa-thít chǎn pai wát", english: "On Sunday I go to the temple.", hindi: "रविवार को मैं मंदिर जाती हूँ।"),
        ],
        302: [
            WordExample(thai: "ตอนนี้ฝนตก", romanization: "toon-níi fǒn tòk", english: "It is raining now.", hindi: "अभी बारिश हो रही है।"),
            WordExample(thai: "ตอนนี้กี่โมง", romanization: "toon-níi kìi moong", english: "What time is it now?", hindi: "अभी क्या समय हुआ है?"),
        ],
        303: [
            WordExample(thai: "ผมมาที่นี่บ่อย", romanization: "phǒm maa thîi-nîi bòi", english: "I come here often.", hindi: "मैं यहाँ अक्सर आता हूँ।"),
            WordExample(thai: "คุณกินอาหารไทยบ่อยไหม", romanization: "khun kin aa-hǎan thai bòi mái", english: "Do you eat Thai food often?", hindi: "क्या आप अक्सर थाई खाना खाते हैं?"),
        ],
        304: [
            WordExample(thai: "บางครั้งฉันคิดถึงบ้าน", romanization: "baang-khráng chǎn khít-thǔeng bâan", english: "Sometimes I miss home.", hindi: "कभी-कभी मुझे घर की याद आती है।"),
            WordExample(thai: "บางครั้งผมกินข้าวคนเดียว", romanization: "baang-khráng phǒm kin khâao khon-diao", english: "Sometimes I eat alone.", hindi: "कभी-कभी मैं अकेले खाना खाता हूँ।"),
        ],
        305: [
            WordExample(thai: "เขามาตรงเวลาเสมอ", romanization: "khǎo maa trong-wee-laa sà-měr", english: "He always comes on time.", hindi: "वह हमेशा समय पर आता है।"),
            WordExample(thai: "แม่ช่วยฉันเสมอ", romanization: "mâe chûai chǎn sà-měr", english: "Mom always helps me.", hindi: "माँ हमेशा मेरी मदद करती है।"),
        ],
        306: [
            WordExample(thai: "ผมไม่เคยไปเชียงใหม่", romanization: "phǒm mâi-kheuy pai chiang-mài", english: "I have never been to Chiang Mai.", hindi: "मैं कभी चियांग माई नहीं गया।"),
            WordExample(thai: "ฉันไม่เคยกินส้มตำ", romanization: "chǎn mâi-kheuy kin sôm-tam", english: "I have never eaten som tam.", hindi: "मैंने कभी सोम तम नहीं खाया।"),
        ],
        307: [
            WordExample(thai: "เจอกันเร็ว ๆ นี้", romanization: "jer-kan reo-reo-níi", english: "See you soon.", hindi: "जल्दी ही मिलते हैं।"),
            WordExample(thai: "ร้านใหม่จะเปิดเร็ว ๆ นี้", romanization: "ráan mài jà pèrt reo-reo-níi", english: "The new shop will open soon.", hindi: "नई दुकान जल्दी ही खुलेगी।"),
        ],
        308: [
            WordExample(thai: "กินข้าวก่อนไปทำงาน", romanization: "kin khâao kòon pai tham-ngaan", english: "Eat before going to work.", hindi: "काम पर जाने से पहले खाना खाओ।"),
            WordExample(thai: "ผมไปก่อนนะ", romanization: "phǒm pai kòon ná", english: "I am off now (leaving first).", hindi: "मैं पहले चलता हूँ।"),
        ],
        309: [
            WordExample(thai: "หลังเลิกงานผมไปตลาด", romanization: "lǎng lêrk-ngaan phǒm pai tà-làat", english: "After work I go to the market.", hindi: "काम के बाद मैं बाज़ार जाता हूँ।"),
            WordExample(thai: "หลังเลิกเรียนฉันกลับบ้าน", romanization: "lǎng lêrk-rian chǎn klàp bâan", english: "After class I go back home.", hindi: "क्लास के बाद मैं घर लौटती हूँ।"),
        ],
        310: [
            WordExample(thai: "ขอโทษ ผมมาสาย", romanization: "khǒo-thôot phǒm maa sǎai", english: "Sorry, I am late.", hindi: "माफ़ कीजिए, मुझे देर हो गई।"),
            WordExample(thai: "อย่ามาสายนะ", romanization: "yàa maa sǎai ná", english: "Do not be late!", hindi: "देर से मत आना!"),
        ],
        311: [
            WordExample(thai: "ผมกินข้าวตอนเที่ยง", romanization: "phǒm kin khâao toon thîang", english: "I eat lunch at noon.", hindi: "मैं दोपहर को खाना खाता हूँ।"),
            WordExample(thai: "ตอนนี้เที่ยงแล้ว", romanization: "toon-níi thîang láew", english: "It is already noon.", hindi: "अभी बारह बज गए हैं।"),
        ],
        312: [
            WordExample(thai: "เสาร์อาทิตย์นี้คุณทำอะไร", romanization: "sǎo-aa-thít níi khun tham à-rai", english: "What are you doing this weekend?", hindi: "इस वीकेंड आप क्या कर रहे हैं?"),
            WordExample(thai: "เสาร์อาทิตย์ผมอยู่บ้าน", romanization: "sǎo-aa-thít phǒm yùu bâan", english: "On weekends I stay home.", hindi: "वीकेंड पर मैं घर पर रहता हूँ।"),
        ],
        313: [
            WordExample(thai: "อาทิตย์หน้าฉันไปทะเล", romanization: "aa-thít-nâa chǎn pai thá-lee", english: "Next week I am going to the sea.", hindi: "अगले हफ़्ते मैं समुद्र जा रही हूँ।"),
            WordExample(thai: "เจอกันอาทิตย์หน้า", romanization: "jer-kan aa-thít-nâa", english: "See you next week.", hindi: "अगले हफ़्ते मिलते हैं।"),
        ],
        314: [
            WordExample(thai: "อาทิตย์ที่แล้วผมป่วย", romanization: "aa-thít-thîi-láew phǒm pùai", english: "Last week I was sick.", hindi: "पिछले हफ़्ते मैं बीमार था।"),
            WordExample(thai: "อาทิตย์ที่แล้วฝนตกทุกวัน", romanization: "aa-thít-thîi-láew fǒn tòk thúk-wan", english: "Last week it rained every day.", hindi: "पिछले हफ़्ते हर दिन बारिश हुई।"),
        ],
        315: [
            WordExample(thai: "บ่ายนี้ว่างไหม", romanization: "bàai níi wâang mái", english: "Are you free this afternoon?", hindi: "क्या आज दोपहर बाद आप खाली हैं?"),
            WordExample(thai: "เจอกันตอนบ่าย", romanization: "jer-kan toon bàai", english: "See you in the afternoon.", hindi: "दोपहर बाद मिलते हैं।"),
        ],
        316: [
            WordExample(thai: "ผมดื่มกาแฟทุกวัน", romanization: "phǒm dùem kaa-fae thúk-wan", english: "I drink coffee every day.", hindi: "मैं हर दिन कॉफ़ी पीता हूँ।"),
            WordExample(thai: "ฉันเรียนภาษาไทยทุกวัน", romanization: "chǎn rian phaa-sǎa-thai thúk-wan", english: "I study Thai every day.", hindi: "मैं हर दिन थाई सीखती हूँ।"),
        ],
        317: [
            WordExample(thai: "คืนนี้ไปกินข้าวกันไหม", romanization: "kheun-níi pai kin khâao kan mái", english: "Shall we go out to eat tonight?", hindi: "आज रात खाना खाने चलें?"),
            WordExample(thai: "คืนนี้ฉันนอนเร็ว", romanization: "kheun-níi chǎn noon reo", english: "Tonight I will sleep early.", hindi: "आज रात मैं जल्दी सोऊँगी।"),
        ],
        318: [
            WordExample(thai: "พรุ่งนี้เป็นวันหยุด", romanization: "phrûng-níi pen wan-yùt", english: "Tomorrow is a holiday.", hindi: "कल छुट्टी है।"),
            WordExample(thai: "วันหยุดคุณทำอะไร", romanization: "wan-yùt khun tham à-rai", english: "What do you do on your day off?", hindi: "छुट्टी के दिन आप क्या करते हैं?"),
        ],
        319: [
            WordExample(thai: "รอนานไหม", romanization: "roo naan mái", english: "Did you wait long?", hindi: "क्या बहुत देर इंतज़ार किया?"),
            WordExample(thai: "ไม่เจอกันนานเลย", romanization: "mâi jer kan naan leuy", english: "Long time no see!", hindi: "बहुत दिनों बाद मिले!"),
        ],
        320: [
            WordExample(thai: "คุณมีพี่น้องกี่คน", romanization: "khun mii phîi-nóong kìi khon", english: "How many siblings do you have?", hindi: "आपके कितने भाई-बहन हैं?"),
            WordExample(thai: "อันนี้กี่บาท", romanization: "an níi kìi bàat", english: "How many baht is this?", hindi: "यह कितने बाथ का है?"),
        ],
        321: [
            WordExample(thai: "ผมมีหมาสองตัว", romanization: "phǒm mii mǎa sǒong tua", english: "I have two dogs.", hindi: "मेरे पास दो कुत्ते हैं।"),
            WordExample(thai: "เสื้อตัวนี้สวยมาก", romanization: "sûea tua níi sǔai mâak", english: "This shirt is very beautiful.", hindi: "यह शर्ट बहुत सुंदर है।"),
        ],
        322: [
            WordExample(thai: "ครอบครัวผมมีสี่คน", romanization: "khrôop-khrua phǒm mii sìi khon", english: "My family has four people.", hindi: "मेरे परिवार में चार लोग हैं।"),
            WordExample(thai: "ที่ตลาดมีคนเยอะ", romanization: "thîi ta-làat mii khon yóe", english: "There are a lot of people at the market.", hindi: "बाज़ार में बहुत लोग हैं।"),
        ],
        323: [
            WordExample(thai: "อันนี้เท่าไหร่", romanization: "an níi thâo-rài", english: "How much is this one?", hindi: "यह वाला कितने का है?"),
            WordExample(thai: "ขออันเล็ก", romanization: "khǒo an lék", english: "I'd like the small one, please.", hindi: "छोटा वाला दीजिए।"),
        ],
        324: [
            WordExample(thai: "ขอตั๋วสองใบ", romanization: "khǒo tǔa sǒong bai", english: "Two tickets, please.", hindi: "दो टिकट दीजिए।"),
            WordExample(thai: "ผมมีกระเป๋าหนึ่งใบ", romanization: "phǒm mii kra-pǎo nùeng bai", english: "I have one bag.", hindi: "मेरे पास एक बैग है।"),
        ],
        325: [
            WordExample(thai: "ขอน้ำหนึ่งแก้ว", romanization: "khǒo náam nùeng kâew", english: "One glass of water, please.", hindi: "एक गिलास पानी दीजिए।"),
            WordExample(thai: "น้ำส้มหนึ่งแก้วเท่าไหร่", romanization: "náam-sôm nùeng kâew thâo-rài", english: "How much is a glass of orange juice?", hindi: "संतरे के जूस का एक गिलास कितने का है?"),
        ],
        326: [
            WordExample(thai: "ขอน้ำสองขวด", romanization: "khǒo náam sǒong khùat", english: "Two bottles of water, please.", hindi: "दो बोतल पानी दीजिए।"),
            WordExample(thai: "นมขวดนี้เท่าไหร่", romanization: "nom khùat níi thâo-rài", english: "How much is this bottle of milk?", hindi: "दूध की यह बोतल कितने की है?"),
        ],
        327: [
            WordExample(thai: "ขอข้าวผัดหนึ่งจาน", romanization: "khǒo khâao-phàt nùeng jaan", english: "One plate of fried rice, please.", hindi: "एक प्लेट फ्राइड राइस दीजिए।"),
            WordExample(thai: "จานนี้ใหญ่มาก", romanization: "jaan níi yài mâak", english: "This plate is very big.", hindi: "यह प्लेट बहुत बड़ी है।"),
        ],
        328: [
            WordExample(thai: "ขอแกงหนึ่งถ้วย", romanization: "khǒo kaeng nùeng thûai", english: "One bowl of curry, please.", hindi: "एक कटोरी करी दीजिए।"),
            WordExample(thai: "ถ้วยนี้สวยมาก", romanization: "thûai níi sǔai mâak", english: "This bowl is very pretty.", hindi: "यह कटोरी बहुत सुंदर है।"),
        ],
        329: [
            WordExample(thai: "รองเท้าคู่นี้เท่าไหร่", romanization: "roong-tháo khûu níi thâo-rài", english: "How much is this pair of shoes?", hindi: "जूतों की यह जोड़ी कितने की है?"),
            WordExample(thai: "ผมซื้อรองเท้าหนึ่งคู่", romanization: "phǒm súe roong-tháo nùeng khûu", english: "I bought one pair of shoes.", hindi: "मैंने एक जोड़ी जूते खरीदे।"),
        ],
        330: [
            WordExample(thai: "ขอไก่สองชิ้น", romanization: "khǒo kài sǒong chín", english: "Two pieces of chicken, please.", hindi: "चिकन के दो टुकड़े दीजिए।"),
            WordExample(thai: "เค้กชิ้นนี้อร่อยมาก", romanization: "khéek chín níi a-ròi mâak", english: "This piece of cake is delicious.", hindi: "केक का यह टुकड़ा बहुत स्वादिष्ट है।"),
        ],
        331: [
            WordExample(thai: "ผมซื้อหนังสือสองเล่ม", romanization: "phǒm súe nǎng-sǔe sǒong lêm", english: "I bought two books.", hindi: "मैंने दो किताबें खरीदीं।"),
            WordExample(thai: "หนังสือเล่มนี้ดีมาก", romanization: "nǎng-sǔe lêm níi dii mâak", english: "This book is very good.", hindi: "यह किताब बहुत अच्छी है।"),
        ],
        332: [
            WordExample(thai: "ผมมาเมืองไทยเป็นครั้งแรก", romanization: "phǒm maa mueang-thai pen khráng râek", english: "This is my first time in Thailand.", hindi: "मैं पहली बार थाईलैंड आया हूँ।"),
            WordExample(thai: "ผมมาที่นี่สองครั้ง", romanization: "phǒm maa thîi-nîi sǒong khráng", english: "I have come here two times.", hindi: "मैं यहाँ दो बार आया हूँ।"),
        ],
        333: [
            WordExample(thai: "เสื้อตัวนี้สองร้อยบาท", romanization: "sûea tua níi sǒong rói bàat", english: "This shirt is two hundred baht.", hindi: "यह शर्ट दो सौ बाथ की है।"),
            WordExample(thai: "ผมมีห้าร้อยบาท", romanization: "phǒm mii hâa rói bàat", english: "I have five hundred baht.", hindi: "मेरे पास पाँच सौ बाथ हैं।"),
        ],
        334: [
            WordExample(thai: "โรงแรมคืนละหนึ่งพันบาท", romanization: "roong-raem khuen lá nùeng phan bàat", english: "The hotel is one thousand baht per night.", hindi: "होटल एक हज़ार बाथ प्रति रात है।"),
            WordExample(thai: "ผมมีสองพันบาท", romanization: "phǒm mii sǒong phan bàat", english: "I have two thousand baht.", hindi: "मेरे पास दो हज़ार बाथ हैं।"),
        ],
        335: [
            WordExample(thai: "โทรศัพท์นี้หนึ่งหมื่นบาท", romanization: "thoo-rá-sàp níi nùeng mùen bàat", english: "This phone is ten thousand baht.", hindi: "यह फ़ोन दस हज़ार बाथ का है।"),
            WordExample(thai: "ผมมีเงินสามหมื่นบาท", romanization: "phǒm mii ngoen sǎam mùen bàat", english: "I have thirty thousand baht.", hindi: "मेरे पास तीस हज़ार बाथ हैं।"),
        ],
        336: [
            WordExample(thai: "รถนี้ห้าแสนบาท", romanization: "rót níi hâa sǎen bàat", english: "This car is five hundred thousand baht.", hindi: "यह गाड़ी पाँच लाख बाथ की है।"),
            WordExample(thai: "บ้านนี้เก้าแสนบาท", romanization: "bâan níi kâao sǎen bàat", english: "This house is nine hundred thousand baht.", hindi: "यह घर नौ लाख बाथ का है।"),
        ],
        337: [
            WordExample(thai: "บ้านนี้สามล้านบาท", romanization: "bâan níi sǎam láan bàat", english: "This house is three million baht.", hindi: "यह घर तीस लाख बाथ का है।"),
            WordExample(thai: "กรุงเทพฯมีคนสิบล้านคน", romanization: "krung-thêep mii khon sìp láan khon", english: "Bangkok has ten million people.", hindi: "बैंकॉक में एक करोड़ लोग हैं।"),
        ],
        338: [
            WordExample(thai: "รอครึ่งชั่วโมง", romanization: "roo khrûeng chûa-moong", english: "Wait half an hour.", hindi: "आधा घंटा इंतज़ार कीजिए।"),
            WordExample(thai: "ผมกินข้าวครึ่งจาน", romanization: "phǒm kin khâao khrûeng jaan", english: "I ate half a plate of rice.", hindi: "मैंने आधी प्लेट चावल खाया।"),
        ],
        339: [
            WordExample(thai: "ผมพูดภาษาไทยได้นิดหน่อย", romanization: "phǒm phûut phaa-sǎa-thai dâai nít-nòi", english: "I can speak a little Thai.", hindi: "मैं थोड़ी-सी थाई बोल सकता हूँ।"),
            WordExample(thai: "เผ็ดนิดหน่อย", romanization: "phèt nít-nòi", english: "It's a little bit spicy.", hindi: "थोड़ा-सा तीखा है।"),
        ],
        340: [
            WordExample(thai: "ผมมีเพื่อนเยอะ", romanization: "phǒm mii phûean yóe", english: "I have a lot of friends.", hindi: "मेरे बहुत सारे दोस्त हैं।"),
            WordExample(thai: "วันนี้คนเยอะมาก", romanization: "wan-níi khon yóe mâak", english: "There are so many people today.", hindi: "आज बहुत ज़्यादा लोग हैं।"),
        ],
        341: [
            WordExample(thai: "ทั้งหมดเท่าไหร่", romanization: "tháng-mòt thâo-rài", english: "How much is it altogether?", hindi: "कुल कितना हुआ?"),
            WordExample(thai: "ทั้งหมดสามร้อยบาท", romanization: "tháng-mòt sǎam rói bàat", english: "Altogether it's three hundred baht.", hindi: "कुल तीन सौ बाथ हुआ।"),
        ],
        342: [
            WordExample(thai: "อันละยี่สิบบาท", romanization: "an lá yîi-sìp bàat", english: "Twenty baht each.", hindi: "हर एक बीस बाथ का है।"),
            WordExample(thai: "กินยาวันละสามครั้ง", romanization: "kin yaa wan lá sǎam khráng", english: "Take the medicine three times a day.", hindi: "दवा दिन में तीन बार लीजिए।"),
        ],
        343: [
            WordExample(thai: "เบอร์ผมคือศูนย์แปดเก้า", romanization: "boe phǒm khue sǔun pàet kâao", english: "My number is zero-eight-nine.", hindi: "मेरा नंबर शून्य-आठ-नौ है।"),
            WordExample(thai: "นับจากศูนย์ถึงสิบ", romanization: "náp jàak sǔun thǔeng sìp", english: "Count from zero to ten.", hindi: "शून्य से दस तक गिनिए।"),
        ],
        344: [
            WordExample(thai: "ผมอายุยี่สิบปี", romanization: "phǒm aa-yú yîi-sìp pii", english: "I am twenty years old.", hindi: "मैं बीस साल का हूँ।"),
            WordExample(thai: "อันนี้ยี่สิบบาท", romanization: "an níi yîi-sìp bàat", english: "This one is twenty baht.", hindi: "यह बीस बाथ का है।"),
        ],
        345: [
            WordExample(thai: "ห้องนี้ใหญ่มาก", romanization: "hôong níi yài mâak", english: "This room is very big.", hindi: "यह कमरा बहुत बड़ा है।"),
            WordExample(thai: "ห้องของฉันอยู่ข้างบน", romanization: "hôong khǒong chǎn yùu khâang-bon", english: "My room is upstairs.", hindi: "मेरा कमरा ऊपर है।"),
        ],
        346: [
            WordExample(thai: "ช่วยเปิดประตูหน่อย", romanization: "chûai pèrt prà-tuu nòi", english: "Please open the door.", hindi: "कृपया दरवाज़ा खोल दीजिए।"),
            WordExample(thai: "ปิดประตูด้วยครับ", romanization: "pìt prà-tuu dûai khráp", english: "Please close the door.", hindi: "दरवाज़ा बंद कर दीजिए।"),
        ],
        347: [
            WordExample(thai: "เปิดหน้าต่างหน่อยได้ไหม", romanization: "pèrt nâa-tàang nòi dâi mǎi", english: "Can you open the window?", hindi: "क्या आप खिड़की खोल सकते हैं?"),
            WordExample(thai: "หน้าต่างปิดแล้ว", romanization: "nâa-tàang pìt láew", english: "The window is already closed.", hindi: "खिड़की बंद हो गई है।"),
        ],
        348: [
            WordExample(thai: "เตียงนี้นอนสบาย", romanization: "tiang níi noon sà-baai", english: "This bed is comfortable to sleep on.", hindi: "यह बिस्तर सोने में आरामदायक है।"),
            WordExample(thai: "แมวนอนบนเตียง", romanization: "maew noon bon tiang", english: "The cat sleeps on the bed.", hindi: "बिल्ली बिस्तर पर सोती है।"),
        ],
        349: [
            WordExample(thai: "กาแฟอยู่บนโต๊ะ", romanization: "kaa-fae yùu bon tó", english: "The coffee is on the table.", hindi: "कॉफ़ी मेज़ पर है।"),
            WordExample(thai: "นั่งที่โต๊ะนี้ได้ไหม", romanization: "nâng thîi tó níi dâi mǎi", english: "Can I sit at this table?", hindi: "क्या मैं इस मेज़ पर बैठ सकता हूँ?"),
        ],
        350: [
            WordExample(thai: "เก้าอี้ตัวนี้ใหม่", romanization: "kâo-îi tua níi mài", english: "This chair is new.", hindi: "यह कुर्सी नई है।"),
            WordExample(thai: "มีเก้าอี้สองตัว", romanization: "mii kâo-îi sǒong tua", english: "There are two chairs.", hindi: "दो कुर्सियाँ हैं।"),
        ],
        351: [
            WordExample(thai: "มือถือของฉันอยู่ไหน", romanization: "meuu-thěuu khǒong chǎn yùu nǎi", english: "Where is my phone?", hindi: "मेरा मोबाइल कहाँ है?"),
            WordExample(thai: "มือถือใหม่แพงมาก", romanization: "meuu-thěuu mài phaeng mâak", english: "The new phone is very expensive.", hindi: "नया मोबाइल बहुत महँगा है।"),
        ],
        352: [
            WordExample(thai: "กุญแจอยู่ในกระเป๋า", romanization: "kun-jae yùu nai krà-pǎo", english: "The key is in the bag.", hindi: "चाबी बैग में है।"),
            WordExample(thai: "ฉันลืมกุญแจ", romanization: "chǎn leuum kun-jae", english: "I forgot the key.", hindi: "मैं चाबी भूल गया।"),
        ],
        353: [
            WordExample(thai: "ฉันซื้อเสื้อผ้าใหม่", romanization: "chǎn séuu sûea-phâa mài", english: "I bought new clothes.", hindi: "मैंने नए कपड़े खरीदे।"),
            WordExample(thai: "เสื้อผ้าสวยมาก", romanization: "sûea-phâa sǔai mâak", english: "The clothes are very beautiful.", hindi: "कपड़े बहुत सुंदर हैं।"),
        ],
        354: [
            WordExample(thai: "กางเกงตัวนี้พอดี", romanization: "kaang-keeng tua níi phoo-dii", english: "These pants fit just right.", hindi: "यह पैंट एकदम फ़िट है।"),
            WordExample(thai: "ขอลองกางเกงตัวนี้หน่อย", romanization: "khǒo loong kaang-keeng tua níi nòi", english: "May I try on these pants?", hindi: "मैं यह पैंट पहनकर देखना चाहता हूँ।"),
        ],
        355: [
            WordExample(thai: "สบู่อยู่ในห้องน้ำ", romanization: "sà-bùu yùu nai hôong-náam", english: "The soap is in the bathroom.", hindi: "साबुन बाथरूम में है।"),
            WordExample(thai: "สบู่หอมมาก", romanization: "sà-bùu hǒom mâak", english: "The soap smells very nice.", hindi: "साबुन से बहुत अच्छी खुशबू आती है।"),
        ],
        356: [
            WordExample(thai: "ขอผ้าเช็ดตัวใหม่หน่อย", romanization: "khǒo phâa-chét-tua mài nòi", english: "May I have a new towel?", hindi: "कृपया एक नया तौलिया दीजिए।"),
            WordExample(thai: "ผ้าเช็ดตัวยังเปียกอยู่", romanization: "phâa-chét-tua yang pìak yùu", english: "The towel is still wet.", hindi: "तौलिया अभी भी गीला है।"),
        ],
        357: [
            WordExample(thai: "วันนี้ไฟฟ้าดับ", romanization: "wan-níi fai-fáa dàp", english: "The electricity is out today.", hindi: "आज बिजली चली गई।"),
            WordExample(thai: "ค่าไฟฟ้าแพง", romanization: "khâa fai-fáa phaeng", english: "The electricity bill is expensive.", hindi: "बिजली का बिल महँगा है।"),
        ],
        358: [
            WordExample(thai: "ช่วยเปิดแอร์หน่อย", romanization: "chûai pèrt ae nòi", english: "Please turn on the AC.", hindi: "कृपया एसी चला दीजिए।"),
            WordExample(thai: "ห้องนี้แอร์เย็นมาก", romanization: "hôong níi ae yen mâak", english: "The AC in this room is very cold.", hindi: "इस कमरे का एसी बहुत ठंडा है।"),
        ],
        359: [
            WordExample(thai: "เปิดพัดลมหน่อย", romanization: "pèrt phát-lom nòi", english: "Turn on the fan, please.", hindi: "पंखा चला दो।"),
            WordExample(thai: "พัดลมเสีย", romanization: "phát-lom sǐa", english: "The fan is broken.", hindi: "पंखा खराब है।"),
        ],
        360: [
            WordExample(thai: "นมอยู่ในตู้เย็น", romanization: "nom yùu nai tûu-yen", english: "The milk is in the fridge.", hindi: "दूध फ्रिज में है।"),
            WordExample(thai: "ช่วยปิดตู้เย็นด้วย", romanization: "chûai pìt tûu-yen dûai", english: "Please close the fridge.", hindi: "कृपया फ्रिज बंद कर दीजिए।"),
        ],
        361: [
            WordExample(thai: "ฉันดูทีวีทุกวัน", romanization: "chǎn duu thii-wii thúk wan", english: "I watch TV every day.", hindi: "मैं रोज़ टीवी देखता हूँ।"),
            WordExample(thai: "ปิดทีวีก่อนนอน", romanization: "pìt thii-wii kòon noon", english: "Turn off the TV before sleeping.", hindi: "सोने से पहले टीवी बंद करो।"),
        ],
        362: [
            WordExample(thai: "เปิดโคมไฟหน่อย", romanization: "pèrt khoom-fai nòi", english: "Turn on the lamp, please.", hindi: "लैंप जला दो।"),
            WordExample(thai: "โคมไฟอยู่ข้างเตียง", romanization: "khoom-fai yùu khâang tiang", english: "The lamp is beside the bed.", hindi: "लैंप बिस्तर के बगल में है।"),
        ],
        363: [
            WordExample(thai: "ห้องนอนของฉันเล็ก", romanization: "hôong-noon khǒong chǎn lék", english: "My bedroom is small.", hindi: "मेरा बेडरूम छोटा है।"),
            WordExample(thai: "บ้านนี้มีสองห้องนอน", romanization: "bâan níi mii sǒong hôong-noon", english: "This house has two bedrooms.", hindi: "इस घर में दो बेडरूम हैं।"),
        ],
        364: [
            WordExample(thai: "แม่อยู่ในห้องครัว", romanization: "mâe yùu nai hôong-khrua", english: "Mom is in the kitchen.", hindi: "माँ रसोई में हैं।"),
            WordExample(thai: "ห้องครัวสะอาดมาก", romanization: "hôong-khrua sà-àat mâak", english: "The kitchen is very clean.", hindi: "रसोई बहुत साफ़ है।"),
        ],
        365: [
            WordExample(thai: "ฉันต้องซื้อแปรงสีฟันใหม่", romanization: "chǎn tôong séuu praeng-sǐi-fan mài", english: "I need to buy a new toothbrush.", hindi: "मुझे नया टूथब्रश खरीदना है।"),
            WordExample(thai: "แปรงสีฟันของฉันสีฟ้า", romanization: "praeng-sǐi-fan khǒong chǎn sǐi fáa", english: "My toothbrush is blue.", hindi: "मेरा टूथब्रश नीला है।"),
        ],
        366: [
            WordExample(thai: "ยาสีฟันหมดแล้ว", romanization: "yaa-sǐi-fan mòt láew", english: "The toothpaste is finished.", hindi: "टूथपेस्ट खत्म हो गया है।"),
            WordExample(thai: "ขอซื้อยาสีฟันหนึ่งหลอด", romanization: "khǒo séuu yaa-sǐi-fan nèung lòot", english: "I'd like to buy one tube of toothpaste.", hindi: "मुझे टूथपेस्ट की एक ट्यूब चाहिए।"),
        ],
        367: [
            WordExample(thai: "ขอหมอนอีกหนึ่งใบ", romanization: "khǒo mǒon ìik nèung bai", english: "May I have one more pillow?", hindi: "एक और तकिया दीजिए।"),
            WordExample(thai: "หมอนนี้นุ่มมาก", romanization: "mǒon níi nûm mâak", english: "This pillow is very soft.", hindi: "यह तकिया बहुत मुलायम है।"),
        ],
        368: [
            WordExample(thai: "คืนนี้หนาว ขอผ้าห่มหน่อย", romanization: "kheuun níi nǎao khǒo phâa-hòm nòi", english: "It's cold tonight, may I have a blanket?", hindi: "आज रात ठंड है, एक कंबल दीजिए।"),
            WordExample(thai: "ผ้าห่มอยู่บนเตียง", romanization: "phâa-hòm yùu bon tiang", english: "The blanket is on the bed.", hindi: "कंबल बिस्तर पर है।"),
        ],
        369: [
            WordExample(thai: "ฉันส่องกระจกทุกเช้า", romanization: "chǎn sòong krà-jòk thúk cháo", english: "I look in the mirror every morning.", hindi: "मैं हर सुबह आईने में देखता हूँ।"),
            WordExample(thai: "ระวัง กระจกแตกง่าย", romanization: "rá-wang krà-jòk tàek ngâai", english: "Careful, glass breaks easily.", hindi: "सावधान, शीशा आसानी से टूट जाता है।"),
        ],
        370: [
            WordExample(thai: "คุณพูดได้กี่ภาษา", romanization: "khun phûut dâi kìi phaa-sǎa", english: "How many languages can you speak?", hindi: "आप कितनी भाषाएँ बोल सकते हैं?"),
            WordExample(thai: "ภาษานี้ไม่ยาก", romanization: "phaa-sǎa níi mâi yâak", english: "This language is not difficult.", hindi: "यह भाषा मुश्किल नहीं है।"),
        ],
        371: [
            WordExample(thai: "ผมเรียนภาษาไทยทุกวัน", romanization: "phǒm rian phaa-sǎa-thai thúk wan", english: "I study Thai every day.", hindi: "मैं हर दिन थाई भाषा पढ़ता हूँ।"),
            WordExample(thai: "คุณพูดภาษาไทยเก่งมาก", romanization: "khun phûut phaa-sǎa-thai kèng mâak", english: "You speak Thai very well.", hindi: "आप बहुत अच्छी थाई बोलते हैं।"),
        ],
        372: [
            WordExample(thai: "คุณพูดภาษาอังกฤษได้ไหม", romanization: "khun phûut phaa-sǎa-ang-krìt dâi mǎi", english: "Can you speak English?", hindi: "क्या आप अंग्रेज़ी बोल सकते हैं?"),
            WordExample(thai: "เขาสอนภาษาอังกฤษที่โรงเรียน", romanization: "khǎo sǒon phaa-sǎa-ang-krìt thîi roong-rian", english: "He teaches English at school.", hindi: "वह स्कूल में अंग्रेज़ी पढ़ाता है।"),
        ],
        373: [
            WordExample(thai: "ช่วยแปลให้หน่อยได้ไหม", romanization: "chûai plae hâi nòi dâi mǎi", english: "Can you translate for me?", hindi: "क्या आप मेरे लिए अनुवाद कर सकते हैं?"),
            WordExample(thai: "คำนี้แปลว่าอะไร", romanization: "kham níi plae wâa à-rai", english: "What does this word mean?", hindi: "इस शब्द का मतलब क्या है?"),
        ],
        374: [
            WordExample(thai: "นี่หมายความว่าอะไร", romanization: "nîi mǎai-khwaam-wâa à-rai", english: "What does this mean?", hindi: "इसका मतलब क्या है?"),
            WordExample(thai: "หมายความว่าเขาไม่มาใช่ไหม", romanization: "mǎai-khwaam-wâa khǎo mâi maa châi mǎi", english: "It means he is not coming, right?", hindi: "मतलब वह नहीं आ रहा, है ना?"),
        ],
        375: [
            WordExample(thai: "ผมจะโทรหาคุณพรุ่งนี้", romanization: "phǒm jà thoo hǎa khun phrûng-níi", english: "I will call you tomorrow.", hindi: "मैं कल आपको फ़ोन करूँगा।"),
            WordExample(thai: "แม่โทรมาเมื่อเช้า", romanization: "mâe thoo maa mêua-cháo", english: "Mom called this morning.", hindi: "माँ ने सुबह फ़ोन किया।"),
        ],
        376: [
            WordExample(thai: "ผมส่งข้อความหาคุณแล้ว", romanization: "phǒm sòng khôo-khwaam hǎa khun láew", english: "I already sent you a message.", hindi: "मैंने आपको मैसेज भेज दिया।"),
            WordExample(thai: "คุณอ่านข้อความหรือยัง", romanization: "khun àan khôo-khwaam rěu yang", english: "Have you read the message yet?", hindi: "क्या आपने मैसेज पढ़ लिया?"),
        ],
        377: [
            WordExample(thai: "อีเมลของคุณคืออะไร", romanization: "ii-meo khǒong khun kheu à-rai", english: "What is your email?", hindi: "आपका ईमेल क्या है?"),
            WordExample(thai: "ส่งอีเมลหาผมได้", romanization: "sòng ii-meo hǎa phǒm dâi", english: "You can send me an email.", hindi: "आप मुझे ईमेल भेज सकते हैं।"),
        ],
        378: [
            WordExample(thai: "ขอเบอร์หน่อยได้ไหม", romanization: "khǒo bəə nòi dâi mǎi", english: "Can I have your number?", hindi: "क्या मुझे आपका नंबर मिल सकता है?"),
            WordExample(thai: "นี่เบอร์ใหม่ของฉัน", romanization: "nîi bəə mài khǒong chǎn", english: "This is my new number.", hindi: "यह मेरा नया नंबर है।"),
        ],
        379: [
            WordExample(thai: "ที่อยู่ของคุณคืออะไร", romanization: "thîi-yùu khǒong khun kheu à-rai", english: "What is your address?", hindi: "आपका पता क्या है?"),
            WordExample(thai: "เขียนที่อยู่ที่นี่", romanization: "khǐan thîi-yùu thîi-nîi", english: "Write the address here.", hindi: "पता यहाँ लिखिए।"),
        ],
        380: [
            WordExample(thai: "ชื่อเล่นของคุณคืออะไร", romanization: "chêu-lên khǒong khun kheu à-rai", english: "What is your nickname?", hindi: "आपका निकनेम क्या है?"),
            WordExample(thai: "คนไทยมีชื่อเล่นทุกคน", romanization: "khon thai mii chêu-lên thúk khon", english: "Every Thai person has a nickname.", hindi: "हर थाई व्यक्ति का एक निकनेम होता है।"),
        ],
        381: [
            WordExample(thai: "เขียนชื่อและนามสกุล", romanization: "khǐan chêu láe naam-sà-kun", english: "Write your first and last name.", hindi: "नाम और सरनेम लिखिए।"),
            WordExample(thai: "นามสกุลของเขายาวมาก", romanization: "naam-sà-kun khǒong khǎo yaao mâak", english: "His surname is very long.", hindi: "उसका सरनेम बहुत लंबा है।"),
        ],
        382: [
            WordExample(thai: "เพื่อนบ้านของผมใจดี", romanization: "phêuan-bâan khǒong phǒm jai-dii", english: "My neighbor is kind.", hindi: "मेरा पड़ोसी दयालु है।"),
            WordExample(thai: "ฉันคุยกับเพื่อนบ้านทุกเช้า", romanization: "chǎn khui kàp phêuan-bâan thúk cháo", english: "I chat with my neighbor every morning.", hindi: "मैं हर सुबह पड़ोसी से बात करती हूँ।"),
        ],
        383: [
            WordExample(thai: "หัวหน้าของฉันใจดีมาก", romanization: "hǔa-nâa khǒong chǎn jai-dii mâak", english: "My boss is very kind.", hindi: "मेरा बॉस बहुत दयालु है।"),
            WordExample(thai: "พรุ่งนี้หัวหน้าไม่มา", romanization: "phrûng-níi hǔa-nâa mâi maa", english: "The boss is not coming tomorrow.", hindi: "कल बॉस नहीं आएगा।"),
        ],
        384: [
            WordExample(thai: "ผมกินข้าวกับเพื่อนร่วมงาน", romanization: "phǒm kin khâao kàp phêuan-rûam-ngaan", english: "I eat with my colleagues.", hindi: "मैं सहकर्मियों के साथ खाना खाता हूँ।"),
            WordExample(thai: "เพื่อนร่วมงานของฉันพูดภาษาไทยได้", romanization: "phêuan-rûam-ngaan khǒong chǎn phûut phaa-sǎa-thai dâi", english: "My colleague can speak Thai.", hindi: "मेरा सहकर्मी थाई बोल सकता है।"),
        ],
        385: [
            WordExample(thai: "วันนี้มีประชุม", romanization: "wan-níi mii prà-chum", english: "There is a meeting today.", hindi: "आज मीटिंग है।"),
            WordExample(thai: "หัวหน้าอยู่ในห้องประชุม", romanization: "hǔa-nâa yùu nai hông prà-chum", english: "The boss is in the meeting room.", hindi: "बॉस मीटिंग रूम में है।"),
        ],
        386: [
            WordExample(thai: "คุณทำงานอะไร", romanization: "khun tham-ngaan à-rai", english: "What work do you do?", hindi: "आप क्या काम करते हैं?"),
            WordExample(thai: "วันนี้งานเยอะมาก", romanization: "wan-níi ngaan yə́ mâak", english: "There is a lot of work today.", hindi: "आज बहुत काम है।"),
        ],
        387: [
            WordExample(thai: "เราคุยกันทุกวัน", romanization: "rao khui kan thúk wan", english: "We talk every day.", hindi: "हम हर दिन बात करते हैं।"),
            WordExample(thai: "ฉันชอบคุยกับเพื่อน", romanization: "chǎn chôop khui kàp phêuan", english: "I like chatting with friends.", hindi: "मुझे दोस्तों से बात करना पसंद है।"),
        ],
        388: [
            WordExample(thai: "คำนี้อ่านว่าอะไร", romanization: "kham níi àan wâa à-rai", english: "How do you read this word?", hindi: "यह शब्द कैसे पढ़ते हैं?"),
            WordExample(thai: "วันนี้ฉันเรียนคำใหม่ห้าคำ", romanization: "wan-níi chǎn rian kham mài hâa kham", english: "Today I learned five new words.", hindi: "आज मैंने पाँच नए शब्द सीखे।"),
        ],
        389: [
            WordExample(thai: "ฉันปวดขา", romanization: "chǎn pùat khǎa", english: "My leg hurts.", hindi: "मेरी टांग में दर्द है।"),
            WordExample(thai: "ขาของเขายาวมาก", romanization: "khǎa khǒong kháo yaao mâak", english: "His legs are very long.", hindi: "उसकी टांगें बहुत लंबी हैं।"),
        ],
        390: [
            WordExample(thai: "ฉันเจ็บแขน", romanization: "chǎn jèp khǎen", english: "My arm hurts.", hindi: "मेरी बांह में दर्द है।"),
            WordExample(thai: "ยกแขนขึ้นหน่อยครับ", romanization: "yók khǎen khûen nòi khráp", english: "Please raise your arm.", hindi: "कृपया अपनी बांह ऊपर उठाइए।"),
        ],
        391: [
            WordExample(thai: "ฉันปวดท้อง", romanization: "chǎn pùat thóong", english: "I have a stomachache.", hindi: "मेरे पेट में दर्द है।"),
            WordExample(thai: "ปวดท้องมาก ไปหาหมอ", romanization: "pùat thóong mâak pai hǎa mǒo", english: "My stomach hurts a lot, I am going to the doctor.", hindi: "पेट में बहुत दर्द है, डॉक्टर के पास जा रहा हूं।"),
        ],
        392: [
            WordExample(thai: "อ้าปากหน่อยครับ", romanization: "âa pàak nòi khráp", english: "Please open your mouth.", hindi: "कृपया मुंह खोलिए।"),
            WordExample(thai: "ปากของฉันแห้ง", romanization: "pàak khǒong chǎn hâeng", english: "My mouth is dry.", hindi: "मेरा मुंह सूखा है।"),
        ],
        393: [
            WordExample(thai: "จมูกของฉันเล็ก", romanization: "jà-mùuk khǒong chǎn lék", english: "My nose is small.", hindi: "मेरी नाक छोटी है।"),
            WordExample(thai: "เป็นหวัด จมูกตัน", romanization: "pen wàt jà-mùuk tan", english: "I have a cold and my nose is blocked.", hindi: "ज़ुकाम है, नाक बंद है।"),
        ],
        394: [
            WordExample(thai: "ฉันปวดหู", romanization: "chǎn pùat hǔu", english: "My ear hurts.", hindi: "मेरे कान में दर्द है।"),
            WordExample(thai: "ช้างมีหูใหญ่", romanization: "cháang mii hǔu yài", english: "Elephants have big ears.", hindi: "हाथी के कान बड़े होते हैं।"),
        ],
        395: [
            WordExample(thai: "ผิวของเขาสวยมาก", romanization: "phǐw khǒong kháo sǔai mâak", english: "Her skin is very beautiful.", hindi: "उसकी त्वचा बहुत सुंदर है।"),
            WordExample(thai: "แดดแรง ระวังผิวด้วย", romanization: "dàet raeng rá-wang phǐw dûai", english: "The sun is strong, take care of your skin.", hindi: "धूप तेज़ है, त्वचा का ध्यान रखिए।"),
        ],
        396: [
            WordExample(thai: "เดินมาก ปวดเท้า", romanization: "dern mâak pùat tháo", english: "I walked a lot and my feet hurt.", hindi: "बहुत चला, पैरों में दर्द है।"),
            WordExample(thai: "ถอดรองเท้าก่อนเข้าบ้าน", romanization: "thòt roong-tháo kòn khâo bâan", english: "Take off your shoes before entering the house.", hindi: "घर में जाने से पहले जूते उतारिए।"),
        ],
        397: [
            WordExample(thai: "ฉันเจ็บนิ้ว", romanization: "chǎn jèp níw", english: "My finger hurts.", hindi: "मेरी उंगली में दर्द है।"),
            WordExample(thai: "นิ้วของฉันบวม", romanization: "níw khǒong chǎn buam", english: "My finger is swollen.", hindi: "मेरी उंगली सूज गई है।"),
        ],
        398: [
            WordExample(thai: "ฉันเจ็บคอ", romanization: "chǎn jèp khoo", english: "I have a sore throat.", hindi: "मेरे गले में दर्द है।"),
            WordExample(thai: "คอแห้ง ขอน้ำหน่อย", romanization: "khoo hâeng khǒo náam nòi", english: "My throat is dry, some water please.", hindi: "गला सूख रहा है, थोड़ा पानी दीजिए।"),
        ],
        399: [
            WordExample(thai: "ล้างหน้าทุกเช้า", romanization: "láang nâa thúk cháo", english: "I wash my face every morning.", hindi: "मैं हर सुबह चेहरा धोता हूं।"),
            WordExample(thai: "หน้าของเขาแดง", romanization: "nâa khǒong kháo daeng", english: "His face is red.", hindi: "उसका चेहरा लाल है।"),
        ],
        400: [
            WordExample(thai: "เจ็บตรงไหน", romanization: "jèp trong nǎi", english: "Where does it hurt?", hindi: "कहां दर्द हो रहा है?"),
            WordExample(thai: "ฉันเจ็บมือ", romanization: "chǎn jèp mue", english: "My hand hurts.", hindi: "मेरे हाथ में दर्द है।"),
        ],
        401: [
            WordExample(thai: "ฉันเป็นไข้", romanization: "chǎn pen khâi", english: "I have a fever.", hindi: "मुझे बुखार है।"),
            WordExample(thai: "เขามีไข้สูง", romanization: "kháo mii khâi sǔung", english: "He has a high fever.", hindi: "उसे तेज़ बुखार है।"),
        ],
        402: [
            WordExample(thai: "ฉันไอมาก", romanization: "chǎn ai mâak", english: "I am coughing a lot.", hindi: "मुझे बहुत खांसी हो रही है।"),
            WordExample(thai: "ไอมาสองวันแล้ว", romanization: "ai maa sǒong wan láew", english: "I have been coughing for two days.", hindi: "दो दिन से खांसी है।"),
        ],
        403: [
            WordExample(thai: "ฉันเป็นหวัด", romanization: "chǎn pen wàt", english: "I have a cold.", hindi: "मुझे ज़ुकाम है।"),
            WordExample(thai: "เป็นหวัดต้องพักผ่อน", romanization: "pen wàt tông phák-phòn", english: "When you have a cold, you must rest.", hindi: "ज़ुकाम हो तो आराम करना चाहिए।"),
        ],
        404: [
            WordExample(thai: "ขอยาแก้ปวดหน่อยครับ", romanization: "khǒo yaa kâe pùat nòi khráp", english: "May I have a painkiller, please?", hindi: "कृपया एक दर्द की दवा दीजिए।"),
            WordExample(thai: "กินยาแก้ปวดหลังอาหาร", romanization: "kin yaa kâe pùat lǎng aa-hǎan", english: "Take the painkiller after meals.", hindi: "दर्द की दवा खाने के बाद लीजिए।"),
        ],
        405: [
            WordExample(thai: "ฉันแพ้กุ้ง", romanization: "chǎn pháe kûng", english: "I am allergic to shrimp.", hindi: "मुझे झींगे से एलर्जी है।"),
            WordExample(thai: "คุณแพ้ยาอะไรไหม", romanization: "khun pháe yaa à-rai mǎi", english: "Are you allergic to any medicines?", hindi: "क्या आपको किसी दवा से एलर्जी है?"),
        ],
        406: [
            WordExample(thai: "มีเลือดออก", romanization: "mii lûeat òok", english: "It is bleeding.", hindi: "खून निकल रहा है।"),
            WordExample(thai: "หมอตรวจเลือด", romanization: "mǒo trùat lûeat", english: "The doctor does a blood test.", hindi: "डॉक्टर खून की जांच करते हैं।"),
        ],
        407: [
            WordExample(thai: "ฉันมีแผลที่ขา", romanization: "chǎn mii phlǎe thîi khǎa", english: "I have a wound on my leg.", hindi: "मेरी टांग पर घाव है।"),
            WordExample(thai: "ล้างแผลด้วยน้ำสะอาด", romanization: "láang phlǎe dûai náam sà-àat", english: "Wash the wound with clean water.", hindi: "घाव को साफ पानी से धोइए।"),
        ],
        408: [
            WordExample(thai: "มีอุบัติเหตุบนถนน", romanization: "mii ù-bàt-tì-hèet bon thà-nǒn", english: "There was an accident on the road.", hindi: "सड़क पर एक दुर्घटना हुई।"),
            WordExample(thai: "เกิดอุบัติเหตุ โทรหาตำรวจ", romanization: "kèrt ù-bàt-tì-hèet thoo hǎa tam-rùat", english: "There has been an accident — call the police.", hindi: "दुर्घटना हुई है — पुलिस को फोन कीजिए।"),
        ],
        409: [
            WordExample(thai: "เรียกรถพยาบาลด้วย", romanization: "rîak rót-phá-yaa-baan dûai", english: "Call an ambulance, please!", hindi: "एम्बुलेंस बुलाइए!"),
            WordExample(thai: "รถพยาบาลมาเร็วมาก", romanization: "rót-phá-yaa-baan maa rew mâak", english: "The ambulance came very quickly.", hindi: "एम्बुलेंस बहुत जल्दी आई।"),
        ],
        410: [
            WordExample(thai: "ร้านขายยาอยู่ที่ไหน", romanization: "ráan khǎai yaa yùu thîi-nǎi", english: "Where is the pharmacy?", hindi: "दवाई की दुकान कहां है?"),
            WordExample(thai: "ฉันซื้อยาที่ร้านขายยา", romanization: "chǎn súe yaa thîi ráan khǎai yaa", english: "I buy medicine at the pharmacy.", hindi: "मैं दवाई की दुकान से दवा खरीदता हूं।"),
        ],
        411: [
            WordExample(thai: "คุณมีประกันไหม", romanization: "khun mii prà-kan mǎi", english: "Do you have insurance?", hindi: "क्या आपके पास बीमा है?"),
            WordExample(thai: "ฉันมีประกันสุขภาพ", romanization: "chǎn mii prà-kan sùk-khà-phâap", english: "I have health insurance.", hindi: "मेरे पास स्वास्थ्य बीमा है।"),
        ],
        412: [
            WordExample(thai: "คุณต้องพักผ่อนเยอะๆ", romanization: "khun tông phák-phòn yóe-yóe", english: "You need to rest a lot.", hindi: "आपको खूब आराम करना चाहिए।"),
            WordExample(thai: "วันนี้ฉันพักผ่อนที่บ้าน", romanization: "wan-níi chǎn phák-phòn thîi bâan", english: "Today I am resting at home.", hindi: "आज मैं घर पर आराम कर रहा हूं।"),
        ],
        187: [
            WordExample(thai: "วันนี้ผมดีใจมาก", romanization: "wan-níi pǒm dii-jai mâak", english: "Today I am very happy.", hindi: "आज मैं बहुत खुश हूँ।"),
            WordExample(thai: "ดีใจที่ได้เจอคุณ", romanization: "dii-jai tîi dâai jer kun", english: "I'm glad to meet you.", hindi: "आपसे मिलकर खुशी हुई।"),
        ],
        188: [
            WordExample(thai: "ฉันเสียใจมาก", romanization: "chǎn sǐa-jai mâak", english: "I am very sad.", hindi: "मैं बहुत दुखी हूँ।"),
            WordExample(thai: "อย่าเสียใจนะ", romanization: "yàa sǐa-jai ná", english: "Don't be sad, okay?", hindi: "दुखी मत हो।"),
        ],
        189: [
            WordExample(thai: "อย่าโกรธผมนะ", romanization: "yàa kròot pǒm ná", english: "Don't be angry with me.", hindi: "मुझसे नाराज़ मत हो।"),
            WordExample(thai: "แม่โกรธมาก", romanization: "mâe kròot mâak", english: "Mom is very angry.", hindi: "माँ बहुत गुस्सा हैं।"),
        ],
        190: [
            WordExample(thai: "ผมเบื่อมาก", romanization: "pǒm bùea mâak", english: "I am very bored.", hindi: "मैं बहुत बोर हो रहा हूँ।"),
            WordExample(thai: "ฉันเบื่ออาหารโรงแรม", romanization: "chǎn bùea aa-hǎan roong-raem", english: "I'm bored of the hotel food.", hindi: "मैं होटल के खाने से ऊब गई हूँ।"),
        ],
        191: [
            WordExample(thai: "ผมตื่นเต้นมาก", romanization: "pǒm tùun-tên mâak", english: "I am very excited.", hindi: "मैं बहुत उत्साहित हूँ।"),
            WordExample(thai: "เด็กๆ ตื่นเต้น", romanization: "dèk-dèk tùun-tên", english: "The children are excited.", hindi: "बच्चे उत्साहित हैं।"),
        ],
        192: [
            WordExample(thai: "ผมคิดถึงคุณ", romanization: "pǒm kít-tǔng kun", english: "I miss you.", hindi: "मुझे तुम्हारी याद आती है।"),
            WordExample(thai: "ฉันคิดถึงบ้าน", romanization: "chǎn kít-tǔng bâan", english: "I miss home.", hindi: "मुझे घर की याद आती है।"),
        ],
        193: [
            WordExample(thai: "เจอกันพรุ่งนี้", romanization: "jer kan prûng-níi", english: "See you tomorrow.", hindi: "कल मिलते हैं।"),
            WordExample(thai: "ผมเจอเพื่อนที่ตลาด", romanization: "pǒm jer pûean tîi tà-làat", english: "I met a friend at the market.", hindi: "मैं बाज़ार में दोस्त से मिला।"),
        ],
        194: [
            WordExample(thai: "รอสักครู่นะครับ", romanization: "ror-sàk-krûu ná kráp", english: "Please wait a moment.", hindi: "कृपया एक क्षण रुकिए।"),
            WordExample(thai: "รอสักครู่ อาหารกำลังมา", romanization: "ror-sàk-krûu, aa-hǎan kam-lang maa", english: "Wait a moment, the food is coming.", hindi: "एक मिनट रुकिए, खाना आ रहा है।"),
        ],
        195: [
            WordExample(thai: "พรุ่งนี้ฝนอาจจะตก", romanization: "prûng-níi fǒn àat-jà tòk", english: "It may rain tomorrow.", hindi: "कल शायद बारिश हो।"),
            WordExample(thai: "ผมอาจจะไปตลาด", romanization: "pǒm àat-jà pai tà-làat", english: "I might go to the market.", hindi: "मैं शायद बाज़ार जाऊँ।"),
        ],
        196: [
            WordExample(thai: "แน่นอนครับ", romanization: "nâe-non kráp", english: "Of course!", hindi: "बिलकुल!"),
            WordExample(thai: "อาหารที่นี่อร่อยแน่นอน", romanization: "aa-hǎan tîi-nîi à-ròi nâe-non", english: "The food here is definitely delicious.", hindi: "यहाँ का खाना पक्का स्वादिष्ट है।"),
        ],
        197: [
            WordExample(thai: "ไปกินข้าวด้วยกันไหม", romanization: "pai kin kâao dûai-kan mǎi?", english: "Shall we go eat together?", hindi: "क्या साथ में खाना खाने चलें?"),
            WordExample(thai: "เราทำงานด้วยกัน", romanization: "rao tam-ngaan dûai-kan", english: "We work together.", hindi: "हम साथ में काम करते हैं।"),
        ],
        198: [
            WordExample(thai: "ผมมาคนเดียว", romanization: "pǒm maa kon-diao", english: "I came alone.", hindi: "मैं अकेला आया हूँ।"),
            WordExample(thai: "คุณอยู่คนเดียวไหม", romanization: "kun yùu kon-diao mǎi?", english: "Do you live alone?", hindi: "क्या आप अकेले रहते हैं?"),
        ],
        199: [
            WordExample(thai: "กระเป๋าใบนี้เท่าไหร่", romanization: "krà-pǎo bai níi tâo-rài", english: "How much is this bag?", hindi: "यह बैग कितने का है?"),
            WordExample(thai: "ฉันชอบกระเป๋าใบนี้", romanization: "chǎn châwp krà-pǎo bai níi", english: "I like this bag.", hindi: "मुझे यह बैग पसंद है।"),
        ],
        200: [
            WordExample(thai: "เสื้อตัวนี้สวยมาก", romanization: "sûea tua níi sǔai mâak", english: "This shirt is very beautiful.", hindi: "यह शर्ट बहुत सुंदर है।"),
            WordExample(thai: "ฉันซื้อเสื้อใหม่", romanization: "chǎn súe sûea mài", english: "I am buying a new shirt.", hindi: "मैं नई शर्ट खरीद रही हूँ।"),
        ],
        201: [
            WordExample(thai: "รองเท้าคู่นี้เท่าไหร่", romanization: "rawng-táao khûu níi tâo-rài", english: "How much is this pair of shoes?", hindi: "जूतों की यह जोड़ी कितने की है?"),
            WordExample(thai: "ฉันชอบรองเท้าสีดำ", romanization: "chǎn châwp rawng-táao sǐi dam", english: "I like black shoes.", hindi: "मुझे काले जूते पसंद हैं।"),
        ],
        202: [
            WordExample(thai: "มีที่ชาร์จไหม", romanization: "mii tîi-châat mǎi", english: "Do you have a charger?", hindi: "क्या आपके पास चार्जर है?"),
            WordExample(thai: "ฉันซื้อที่ชาร์จใหม่", romanization: "chǎn súe tîi-châat mài", english: "I am buying a new charger.", hindi: "मैं नया चार्जर खरीद रही हूँ।"),
        ],
        203: [
            WordExample(thai: "ที่ตลาดต่อราคาได้", romanization: "tîi tà-làat tàw raa-khaa dâi", english: "You can bargain at the market.", hindi: "बाज़ार में मोल-भाव कर सकते हैं।"),
            WordExample(thai: "ฉันชอบต่อราคา", romanization: "chǎn châwp tàw raa-khaa", english: "I like to bargain.", hindi: "मुझे मोल-भाव करना पसंद है।"),
        ],
        204: [
            WordExample(thai: "แพงมาก ลดหน่อยได้ไหม", romanization: "phaeng mâak, lót nòi dâi mǎi", english: "Very expensive — can you lower it a bit?", hindi: "बहुत महँगा है, थोड़ा कम कर सकते हैं?"),
            WordExample(thai: "ลดหน่อยได้ไหมครับ", romanization: "lót nòi dâi mǎi khráp", english: "Can you give a small discount? (polite, male)", hindi: "थोड़ा कम कर देंगे? (विनम्र, पुरुष)"),
        ],
        205: [
            WordExample(thai: "มีไซส์ใหญ่ไหม", romanization: "mii sái yài mǎi", english: "Do you have a bigger size?", hindi: "क्या बड़ा साइज़ है?"),
            WordExample(thai: "ไซส์นี้เล็กไป", romanization: "sái níi lék pai", english: "This size is too small.", hindi: "यह साइज़ बहुत छोटा है।"),
        ],
        206: [
            WordExample(thai: "เสื้อตัวนี้พอดี", romanization: "sûea tua níi phaw-dii", english: "This shirt fits just right.", hindi: "यह शर्ट बिलकुल फिट है।"),
            WordExample(thai: "รองเท้าคู่นี้พอดีเลย", romanization: "rawng-táao khûu níi phaw-dii loei", english: "These shoes fit perfectly.", hindi: "ये जूते एकदम फिट हैं।"),
        ],
        207: [
            WordExample(thai: "ลองได้ไหม", romanization: "lawng dâi mǎi", english: "Can I try it on?", hindi: "क्या मैं आज़मा सकता हूँ?"),
            WordExample(thai: "ฉันลองเสื้อตัวนี้", romanization: "chǎn lawng sûea tua níi", english: "I am trying on this shirt.", hindi: "मैं यह शर्ट पहनकर देख रही हूँ।"),
        ],
        208: [
            WordExample(thai: "ขอใบเสร็จหน่อย", romanization: "khǎw bai-sèt nòi", english: "May I have the receipt, please?", hindi: "रसीद दे दीजिए।"),
            WordExample(thai: "มีใบเสร็จไหม", romanization: "mii bai-sèt mǎi", english: "Is there a receipt?", hindi: "क्या रसीद है?"),
        ],
        209: [
            WordExample(thai: "ขอถุงพลาสติกหน่อย", romanization: "khǎw tǔng pláat-sà-tìk nòi", english: "Can I have a plastic bag, please?", hindi: "एक प्लास्टिक थैली दे दीजिए।"),
            WordExample(thai: "ไม่เอาถุงพลาสติก", romanization: "mâi ao tǔng pláat-sà-tìk", english: "I don't want a plastic bag.", hindi: "मुझे प्लास्टिक थैली नहीं चाहिए।"),
        ],
        210: [
            WordExample(thai: "ร้านเปิดกี่โมง", romanization: "ráan pèrt kìi mohng", english: "What time does the shop open?", hindi: "दुकान कितने बजे खुलती है?"),
            WordExample(thai: "ตลาดปิดกี่โมง", romanization: "tà-làat pìt kìi mohng", english: "What time does the market close?", hindi: "बाज़ार कितने बजे बंद होता है?"),
        ],
        211: [
            WordExample(thai: "ชายหาดสวยมาก", romanization: "chaai-hàat sǔai mâak", english: "The beach is very beautiful.", hindi: "समुद्र तट बहुत सुंदर है।"),
            WordExample(thai: "พรุ่งนี้ผมไปชายหาด", romanization: "phrûng-níi phǒm pai chaai-hàat", english: "Tomorrow I am going to the beach.", hindi: "कल मैं बीच पर जाऊँगा।"),
        ],
        212: [
            WordExample(thai: "เกาะนี้สวยมาก", romanization: "kò níi sǔai mâak", english: "This island is very beautiful.", hindi: "यह द्वीप बहुत सुंदर है।"),
            WordExample(thai: "นั่งเรือไปเกาะ", romanization: "nâng rʉa pai kò", english: "Take a boat to the island.", hindi: "नाव से द्वीप जाते हैं।"),
        ],
        213: [
            WordExample(thai: "ขอตั๋วสองใบครับ", romanization: "khǒo tǔa sǒong bai khráp", english: "Two tickets, please.", hindi: "दो टिकट दीजिए।"),
            WordExample(thai: "ตั๋วรถไฟเท่าไหร่", romanization: "tǔa rót-fai thâo-rài", english: "How much is the train ticket?", hindi: "ट्रेन का टिकट कितने का है?"),
        ],
        214: [
            WordExample(thai: "นั่งเรือสนุกมาก", romanization: "nâng rʉa sà-nùk mâak", english: "Riding the boat is a lot of fun.", hindi: "नाव की सवारी बहुत मज़ेदार है।"),
            WordExample(thai: "เรือมาแล้ว", romanization: "rʉa maa láeo", english: "The boat has arrived.", hindi: "नाव आ गई।"),
        ],
        215: [
            WordExample(thai: "นั่งวินมอเตอร์ไซค์ไปตลาด", romanization: "nâng win-moo-ter-sai pai tà-làat", english: "Take a motorbike taxi to the market.", hindi: "बाइक टैक्सी से बाज़ार जाते हैं।"),
            WordExample(thai: "วินมอเตอร์ไซค์เร็วมาก", romanization: "win-moo-ter-sai reo mâak", english: "The motorbike taxi is very fast.", hindi: "बाइक टैक्सी बहुत तेज़ है।"),
        ],
        216: [
            WordExample(thai: "ข้าวเหนียวมะม่วงหวานมาก", romanization: "khâao-nǐao má-mûang wǎan mâak", english: "Mango sticky rice is very sweet.", hindi: "मैंगो स्टिकी राइस बहुत मीठा होता है।"),
            WordExample(thai: "ขอข้าวเหนียวมะม่วงหนึ่งที่", romanization: "khǒo khâao-nǐao má-mûang nʉ̀ng thîi", english: "One mango sticky rice, please.", hindi: "एक मैंगो स्टिकी राइस दीजिए।"),
        ],
        217: [
            WordExample(thai: "ส้มตำเผ็ดมาก", romanization: "sôm-tam phèt mâak", english: "Som tam is very spicy.", hindi: "सोम-तम बहुत तीखा होता है।"),
            WordExample(thai: "ฉันชอบส้มตำ", romanization: "chǎn chôop sôm-tam", english: "I like som tam.", hindi: "मुझे सोम-तम पसंद है।"),
        ],
        218: [
            WordExample(thai: "ขอผัดไทยหนึ่งจาน", romanization: "khǒo phàt-thai nʉ̀ng jaan", english: "One plate of pad thai, please.", hindi: "एक प्लेट पैड थाई दीजिए।"),
            WordExample(thai: "ผัดไทยอร่อยมาก", romanization: "phàt-thai à-ròi mâak", english: "Pad thai is very delicious.", hindi: "पैड थाई बहुत स्वादिष्ट है।"),
        ],
        219: [
            WordExample(thai: "ขวดน้ำอยู่ที่ไหน", romanization: "khùat náam yùu thîi-nǎi", english: "Where is the water bottle?", hindi: "पानी की बोतल कहाँ है?"),
            WordExample(thai: "ผมมีขวดน้ำ", romanization: "phǒm mii khùat náam", english: "I have a water bottle.", hindi: "मेरे पास पानी की बोतल है।"),
        ],
        220: [
            WordExample(thai: "เช็คบิลด้วยครับ", romanization: "chék-bin dûai khráp", english: "The bill, please. (male)", hindi: "बिल दीजिए। (पुरुष)"),
            WordExample(thai: "ขอเช็คบิลหน่อยค่ะ", romanization: "khǒo chék-bin nòi khâ", english: "Could I get the bill? (female)", hindi: "ज़रा बिल लाइए। (स्त्री)"),
        ],
        221: [
            WordExample(thai: "ขอช้อนหน่อยครับ", romanization: "khǒo chóon nòi khráp", english: "May I have a spoon, please?", hindi: "ज़रा एक चम्मच दीजिए।"),
            WordExample(thai: "ช้อนไม่สะอาด", romanization: "chóon mâi sà-àat", english: "The spoon is not clean.", hindi: "चम्मच साफ़ नहीं है।"),
        ],
        222: [
            WordExample(thai: "ขอส้อมหน่อยค่ะ", romanization: "khǒo sôom nòi khâ", english: "May I have a fork, please?", hindi: "ज़रा एक काँटा दीजिए।"),
            WordExample(thai: "ผมไม่มีส้อม", romanization: "phǒm mâi mii sôom", english: "I don't have a fork.", hindi: "मेरे पास काँटा नहीं है।"),
        ],
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
        // Batch 1
        451: [
            WordExample(thai: "หมูอร่อยมาก", romanization: "mǔu à-ròi mâak", english: "The pork is very delicious", hindi: "पोर्क बहुत स्वादिष्ट है"),
            WordExample(thai: "ผมกินหมูครับ", romanization: "phǒm kin mǔu khráp", english: "I eat pork", hindi: "मैं पोर्क खाता हूँ"),
        ],
        452: [
            WordExample(thai: "เนื้ออร่อยมาก", romanization: "núea à-ròi mâak", english: "The beef is very delicious", hindi: "बीफ़ बहुत स्वादिष्ट है"),
            WordExample(thai: "ฉันไม่กินเนื้อ", romanization: "chǎn mâi kin núea", english: "I do not eat beef", hindi: "मैं बीफ़ नहीं खाती"),
        ],
        453: [
            WordExample(thai: "กุ้งอร่อยมาก", romanization: "kûng à-ròi mâak", english: "The shrimp is very delicious", hindi: "झींगा बहुत स्वादिष्ट है"),
            WordExample(thai: "ผมชอบกินกุ้ง", romanization: "phǒm chôop kin kûng", english: "I like eating shrimp", hindi: "मुझे झींगा खाना पसंद है"),
        ],
        454: [
            WordExample(thai: "ต้มยำเผ็ดมาก", romanization: "tôm-yam phèt mâak", english: "Tom yum is very spicy", hindi: "टॉम यम बहुत तीखा है"),
            WordExample(thai: "ฉันชอบต้มยำ", romanization: "chǎn chôop tôm-yam", english: "I like tom yum", hindi: "मुझे टॉम यम पसंद है"),
        ],
        455: [
            WordExample(thai: "ข้าวเหนียวอร่อยมาก", romanization: "khâao-nǐao à-ròi mâak", english: "Sticky rice is very delicious", hindi: "स्टिकी राइस बहुत स्वादिष्ट है"),
            WordExample(thai: "ผมกินข้าวเหนียว", romanization: "phǒm kin khâao-nǐao", english: "I eat sticky rice", hindi: "मैं स्टिकी राइस खाता हूँ"),
        ],
        456: [
            WordExample(thai: "ส้มตำเปรี้ยวมาก", romanization: "sôm-tam prîao mâak", english: "Som tam is very sour", hindi: "सोम तम बहुत खट्टा है"),
            WordExample(thai: "ฉันไม่ชอบเปรี้ยว", romanization: "chǎn mâi chôop prîao", english: "I do not like sour", hindi: "मुझे खट्टा पसंद नहीं है"),
        ],
        457: [
            WordExample(thai: "แกงเค็มมาก", romanization: "kaeng khem mâak", english: "The curry is very salty", hindi: "करी बहुत नमकीन है"),
            WordExample(thai: "ปลาเค็มมาก", romanization: "plaa khem mâak", english: "The fish is very salty", hindi: "मछली बहुत नमकीन है"),
        ],
        458: [
            WordExample(thai: "ขนมอร่อยมาก", romanization: "khà-nǒm à-ròi mâak", english: "The dessert is very tasty", hindi: "मिठाई बहुत स्वादिष्ट है"),
            WordExample(thai: "เขาชอบกินขนม", romanization: "khǎo chôop kin khà-nǒm", english: "He likes eating snacks", hindi: "उसे मिठाई खाना पसंद है"),
        ],
        459: [
            WordExample(thai: "ผมกินขนมปัง", romanization: "phǒm kin khà-nǒm-pang", english: "I eat bread", hindi: "मैं ब्रेड खाता हूँ"),
            WordExample(thai: "ขนมปังอร่อยดี", romanization: "khà-nǒm-pang à-ròi dii", english: "The bread is quite tasty", hindi: "ब्रेड काफ़ी स्वादिष्ट है"),
        ],
        460: [
            WordExample(thai: "กล้วยหวานมาก", romanization: "klûai wǎan mâak", english: "The banana is very sweet", hindi: "केला बहुत मीठा है"),
            WordExample(thai: "ฉันกินกล้วย", romanization: "chǎn kin klûai", english: "I eat a banana", hindi: "मैं केला खाती हूँ"),
        ],
        461: [
            WordExample(thai: "มะม่วงหวานมาก", romanization: "má-mûang wǎan mâak", english: "The mango is very sweet", hindi: "आम बहुत मीठा है"),
            WordExample(thai: "ผมชอบกินมะม่วง", romanization: "phǒm chôop kin má-mûang", english: "I like eating mango", hindi: "मुझे आम खाना पसंद है"),
        ],
        462: [
            WordExample(thai: "แตงโมหวานดี", romanization: "taeng-moo wǎan dii", english: "The watermelon is nicely sweet", hindi: "तरबूज़ अच्छा मीठा है"),
            WordExample(thai: "ฉันชอบกินแตงโม", romanization: "chǎn chôop kin taeng-moo", english: "I like eating watermelon", hindi: "मुझे तरबूज़ खाना पसंद है"),
        ],
        463: [
            WordExample(thai: "สับปะรดหวานมาก", romanization: "sàp-pà-rót wǎan mâak", english: "The pineapple is very sweet", hindi: "अनानास बहुत मीठा है"),
            WordExample(thai: "ผมชอบสับปะรด", romanization: "phǒm chôop sàp-pà-rót", english: "I like pineapple", hindi: "मुझे अनानास पसंद है"),
        ],
        464: [
            WordExample(thai: "น้ำมะพร้าวอร่อยมาก", romanization: "nám-má-práao à-ròi mâak", english: "Coconut water is very tasty", hindi: "नारियल पानी बहुत स्वादिष्ट है"),
            WordExample(thai: "ฉันชอบมะพร้าว", romanization: "chǎn chôop má-práao", english: "I like coconut", hindi: "मुझे नारियल पसंद है"),
        ],
        465: [
            WordExample(thai: "น้ำปลาเค็มมาก", romanization: "nám-plaa khem mâak", english: "Fish sauce is very salty", hindi: "फ़िश सॉस बहुत नमकीन है"),
            WordExample(thai: "เขาชอบน้ำปลา", romanization: "khǎo chôop nám-plaa", english: "He likes fish sauce", hindi: "उसे फ़िश सॉस पसंद है"),
        ],
        466: [
            WordExample(thai: "พริกเผ็ดมาก", romanization: "phrík phèt mâak", english: "The chili is very spicy", hindi: "मिर्च बहुत तीखी है"),
            WordExample(thai: "ฉันไม่กินพริก", romanization: "chǎn mâi kin phrík", english: "I do not eat chili", hindi: "मैं मिर्च नहीं खाती"),
        ],
        467: [
            WordExample(thai: "ขอเมนูครับ", romanization: "khǎaw mee-nuu khráp", english: "The menu, please", hindi: "मेन्यू दीजिए"),
            WordExample(thai: "เมนูอยู่ที่นี่", romanization: "mee-nuu yùu thîi-nîi", english: "The menu is here", hindi: "मेन्यू यहाँ है"),
        ],
        468: [
            WordExample(thai: "ขอน้ำเปล่าครับ", romanization: "khǎaw nám-plàao khráp", english: "Plain water, please", hindi: "सादा पानी दीजिए"),
            WordExample(thai: "ฉันดื่มน้ำเปล่า", romanization: "chǎn dùuem nám-plàao", english: "I drink plain water", hindi: "मैं सादा पानी पीती हूँ"),
        ],
        469: [
            WordExample(thai: "ไอศกรีมหวานมาก", romanization: "ai-sà-kriim wǎan mâak", english: "The ice cream is very sweet", hindi: "आइसक्रीम बहुत मीठी है"),
            WordExample(thai: "เขาชอบกินไอศกรีม", romanization: "khǎo chôop kin ai-sà-kriim", english: "He likes eating ice cream", hindi: "उसे आइसक्रीम खाना पसंद है"),
        ],
        470: [
            WordExample(thai: "ผมชอบข้าวผัด", romanization: "phǒm chôop khâao-phàt", english: "I like fried rice", hindi: "मुझे फ्राइड राइस पसंद है"),
            WordExample(thai: "ผัดผักอร่อยดี", romanization: "phàt-phàk à-ròi dii", english: "Stir-fried vegetables are tasty", hindi: "भुनी सब्ज़ी स्वादिष्ट है"),
        ],
        471: [
            WordExample(thai: "ไก่ทอดอร่อยมาก", romanization: "kài-thâawt à-ròi mâak", english: "Fried chicken is very tasty", hindi: "फ्राइड चिकन बहुत स्वादिष्ट है"),
            WordExample(thai: "ฉันชอบปลาทอด", romanization: "chǎn chôop plaa-thâawt", english: "I like fried fish", hindi: "मुझे तली हुई मछली पसंद है"),
        ],
        472: [
            WordExample(thai: "ผมกินอาหารเช้า", romanization: "phǒm kin aa-hǎan-cháao", english: "I eat breakfast", hindi: "मैं नाश्ता करता हूँ"),
            WordExample(thai: "อาหารเช้าอร่อยมาก", romanization: "aa-hǎan-cháao à-ròi mâak", english: "Breakfast is very tasty", hindi: "नाश्ता बहुत स्वादिष्ट है"),
        ],
        473: [
            WordExample(thai: "ผมหิวน้ำมาก", romanization: "phǒm hǐu-náam mâak", english: "I am very thirsty", hindi: "मुझे बहुत प्यास लगी है"),
            WordExample(thai: "คุณหิวน้ำไหม", romanization: "khun hǐu-náam mǎi", english: "Are you thirsty?", hindi: "क्या आपको प्यास लगी है?"),
        ],
        474: [
            WordExample(thai: "ส้มอร่อยมาก", romanization: "sôm à-ròi mâak", english: "Oranges are very delicious.", hindi: "संतरा बहुत स्वादिष्ट है।"),
            WordExample(thai: "คุณชอบส้มไหมครับ", romanization: "khun chôp sôm mǎi khráp", english: "Do you like oranges?", hindi: "क्या आपको संतरा पसंद है?"),
        ],
        475: [
            WordExample(thai: "มะละกออร่อยมาก", romanization: "má-lá-kaw à-ròi mâak", english: "Papaya is very delicious.", hindi: "पपीता बहुत स्वादिष्ट है।"),
            WordExample(thai: "ฉันไม่ชอบมะละกอค่ะ", romanization: "chǎn mâi chôp má-lá-kaw khâ", english: "I do not like papaya.", hindi: "मुझे पपीता पसंद नहीं है।"),
        ],
        476: [
            WordExample(thai: "ทุเรียนอยู่ที่นี่", romanization: "thú-rian yùu thîi-nîi", english: "The durian is here.", hindi: "ड्यूरियन यहाँ है।"),
            WordExample(thai: "ผมไม่ชอบทุเรียนครับ", romanization: "pǒm mâi chôp thú-rian khráp", english: "I do not like durian.", hindi: "मुझे ड्यूरियन पसंद नहीं है।"),
        ],
        477: [
            WordExample(thai: "มังคุดอร่อยมาก", romanization: "mang-khút à-ròi mâak", english: "Mangosteen is very delicious.", hindi: "मैंगोस्टीन बहुत स्वादिष्ट है।"),
            WordExample(thai: "เขาชอบกินมังคุด", romanization: "khǎo chôp kin mang-khút", english: "He likes eating mangosteen.", hindi: "उसे मैंगोस्टीन खाना पसंद है।"),
        ],
        478: [
            WordExample(thai: "เงาะนี้ดีมาก", romanization: "ngáw níi dii mâak", english: "This rambutan is very good.", hindi: "यह रामबूतान बहुत अच्छा है।"),
            WordExample(thai: "ฉันชอบกินเงาะค่ะ", romanization: "chǎn chôp kin ngáw khâ", english: "I like eating rambutan.", hindi: "मुझे रामबूतान खाना पसंद है।"),
        ],
        479: [
            WordExample(thai: "ลำไยอร่อยมาก", romanization: "lam-yai à-ròi mâak", english: "Longan is very delicious.", hindi: "लोंगन बहुत स्वादिष्ट है।"),
            WordExample(thai: "คุณชอบลำไยไหมครับ", romanization: "khun chôp lam-yai mǎi khráp", english: "Do you like longan?", hindi: "क्या आपको लोंगन पसंद है?"),
        ],
        480: [
            WordExample(thai: "ฉันชอบกินลิ้นจี่ค่ะ", romanization: "chǎn chôp kin lín-chìi khâ", english: "I like eating lychee.", hindi: "मुझे लीची खाना पसंद है।"),
            WordExample(thai: "ลิ้นจี่ที่นี่ดีมาก", romanization: "lín-chìi thîi-nîi dii mâak", english: "The lychee here is very good.", hindi: "यहाँ की लीची बहुत अच्छी है।"),
        ],
        481: [
            WordExample(thai: "ผมกินฝรั่งครับ", romanization: "pǒm kin fà-ràng khráp", english: "I eat guava.", hindi: "मैं अमरूद खाता हूँ।"),
            WordExample(thai: "ฝรั่งนี้อร่อยมาก", romanization: "fà-ràng níi à-ròi mâak", english: "This guava is very delicious.", hindi: "यह अमरूद बहुत स्वादिष्ट है।"),
        ],
        482: [
            WordExample(thai: "ฉันกินแอปเปิ้ลค่ะ", romanization: "chǎn kin áep-pêrn khâ", english: "I eat an apple.", hindi: "मैं सेब खाती हूँ।"),
            WordExample(thai: "แอปเปิ้ลดีมาก", romanization: "áep-pêrn dii mâak", english: "Apples are very good.", hindi: "सेब बहुत अच्छा है।"),
        ],
        483: [
            WordExample(thai: "องุ่นอร่อยมาก", romanization: "à-ngùn à-ròi mâak", english: "Grapes are very delicious.", hindi: "अंगूर बहुत स्वादिष्ट हैं।"),
            WordExample(thai: "เขาชอบกินองุ่นมาก", romanization: "khǎo chôp kin à-ngùn mâak", english: "He really likes eating grapes.", hindi: "उसे अंगूर खाना बहुत पसंद है।"),
        ],
        484: [
            WordExample(thai: "น้ำมะนาวอร่อยมาก", romanization: "nám-má-naao à-ròi mâak", english: "Lime juice is very delicious.", hindi: "नींबू पानी बहुत स्वादिष्ट है।"),
            WordExample(thai: "มะนาวอยู่ที่นี่", romanization: "má-naao yùu thîi-nîi", english: "The limes are here.", hindi: "नींबू यहाँ है।"),
        ],
        485: [
            WordExample(thai: "ขนุนอร่อยมาก", romanization: "khà-nǔn à-ròi mâak", english: "Jackfruit is very delicious.", hindi: "कटहल बहुत स्वादिष्ट है।"),
            WordExample(thai: "ผมชอบกินขนุนครับ", romanization: "pǒm chôp kin khà-nǔn khráp", english: "I like eating jackfruit.", hindi: "मुझे कटहल खाना पसंद है।"),
        ],
        486: [
            WordExample(thai: "แก้วมังกรอยู่ที่นี่", romanization: "kâew-mang-kawn yùu thîi-nîi", english: "The dragon fruit is here.", hindi: "ड्रैगन फ्रूट यहाँ है।"),
            WordExample(thai: "ฉันชอบแก้วมังกรค่ะ", romanization: "chǎn chôp kâew-mang-kawn khâ", english: "I like dragon fruit.", hindi: "मुझे ड्रैगन फ्रूट पसंद है।"),
        ],
        487: [
            WordExample(thai: "มะเขือเทศนี้ดีมาก", romanization: "má-khǔea-thêet níi dii mâak", english: "This tomato is very good.", hindi: "यह टमाटर बहुत अच्छा है।"),
            WordExample(thai: "ฉันกินมะเขือเทศค่ะ", romanization: "chǎn kin má-khǔea-thêet khâ", english: "I eat tomatoes.", hindi: "मैं टमाटर खाती हूँ।"),
        ],
        488: [
            WordExample(thai: "แตงกวาอยู่ที่นี่", romanization: "taeng-kwaa yùu thîi-nîi", english: "The cucumber is here.", hindi: "खीरा यहाँ है।"),
            WordExample(thai: "ผมกินแตงกวาครับ", romanization: "pǒm kin taeng-kwaa khráp", english: "I eat cucumber.", hindi: "मैं खीरा खाता हूँ।"),
        ],
        489: [
            WordExample(thai: "กระเทียมอยู่ที่นี่", romanization: "krà-thiam yùu thîi-nîi", english: "The garlic is here.", hindi: "लहसुन यहाँ है।"),
            WordExample(thai: "ผมชอบกระเทียมครับ", romanization: "pǒm chôp krà-thiam khráp", english: "I like garlic.", hindi: "मुझे लहसुन पसंद है।"),
        ],
        490: [
            WordExample(thai: "หัวหอมอยู่ที่นี่", romanization: "hǔa-hǎwm yùu thîi-nîi", english: "The onions are here.", hindi: "प्याज यहाँ है।"),
            WordExample(thai: "ฉันไม่ชอบหัวหอมค่ะ", romanization: "chǎn mâi chôp hǔa-hǎwm khâ", english: "I do not like onions.", hindi: "मुझे प्याज पसंद नहीं है।"),
        ],
        491: [
            WordExample(thai: "ชาขิงอร่อยมาก", romanization: "chaa-khǐng à-ròi mâak", english: "Ginger tea is very delicious.", hindi: "अदरक की चाय बहुत स्वादिष्ट है।"),
            WordExample(thai: "ผมไม่กินขิงครับ", romanization: "pǒm mâi kin khǐng khráp", english: "I do not eat ginger.", hindi: "मैं अदरक नहीं खाता।"),
        ],
        492: [
            WordExample(thai: "ฉันชอบกินผักบุ้งค่ะ", romanization: "chǎn chôp kin phàk-bûng khâ", english: "I like eating morning glory.", hindi: "मुझे कलमी साग खाना पसंद है।"),
            WordExample(thai: "ผักบุ้งดีมาก", romanization: "phàk-bûng dii mâak", english: "Morning glory is very good.", hindi: "कलमी साग बहुत अच्छा है।"),
        ],
        493: [
            WordExample(thai: "กะหล่ำปลีอยู่ที่นี่", romanization: "kà-làm-plii yùu thîi-nîi", english: "The cabbage is here.", hindi: "पत्ता गोभी यहाँ है।"),
            WordExample(thai: "ฉันกินกะหล่ำปลีค่ะ", romanization: "chǎn kin kà-làm-plii khâ", english: "I eat cabbage.", hindi: "मैं पत्ता गोभी खाती हूँ।"),
        ],
        494: [
            WordExample(thai: "แครอทดีมาก", romanization: "khae-ràwt dii mâak", english: "Carrots are very good.", hindi: "गाजर बहुत अच्छी है।"),
            WordExample(thai: "เขาชอบกินแครอท", romanization: "khǎo chôp kin khae-ràwt", english: "He likes eating carrots.", hindi: "उसे गाजर खाना पसंद है।"),
        ],
        495: [
            WordExample(thai: "เห็ดอร่อยมาก", romanization: "hèt à-ròi mâak", english: "Mushrooms are very delicious.", hindi: "मशरूम बहुत स्वादिष्ट है।"),
            WordExample(thai: "คุณชอบเห็ดไหมครับ", romanization: "khun chôp hèt mǎi khráp", english: "Do you like mushrooms?", hindi: "क्या आपको मशरूम पसंद है?"),
        ],
        496: [
            WordExample(thai: "ข้าวโพดอร่อยมาก", romanization: "khâao-phôot à-ròi mâak", english: "Corn is very delicious.", hindi: "मक्का बहुत स्वादिष्ट है।"),
            WordExample(thai: "ผมชอบกินข้าวโพดครับ", romanization: "pǒm chôp kin khâao-phôot khráp", english: "I like eating corn.", hindi: "मुझे मक्का खाना पसंद है।"),
        ],
        497: [
            WordExample(thai: "แกงฟักทองอร่อยมาก", romanization: "kaeng fák-thawng à-ròi mâak", english: "Pumpkin curry is very delicious.", hindi: "कद्दू की करी बहुत स्वादिष्ट है।"),
            WordExample(thai: "ฉันชอบฟักทองค่ะ", romanization: "chǎn chôp fák-thawng khâ", english: "I like pumpkin.", hindi: "मुझे कद्दू पसंद है।"),
        ],
        498: [
            WordExample(thai: "แม่ทำอาหารอร่อยมาก", romanization: "mâe tham-aa-hǎan à-ròi mâak", english: "Mom cooks very delicious food.", hindi: "माँ बहुत स्वादिष्ट खाना बनाती हैं।"),
            WordExample(thai: "ผมชอบทำอาหารไทย", romanization: "phǒm chôrp tham-aa-hǎan thai", english: "I like cooking Thai food.", hindi: "मुझे थाई खाना बनाना पसंद है।"),
        ],
        499: [
            WordExample(thai: "ต้มไข่ให้หน่อย", romanization: "tôm khài hâi nòi", english: "Boil an egg for me please.", hindi: "मेरे लिए अंडा उबाल दो।"),
            WordExample(thai: "เขาต้มน้ำอยู่", romanization: "khǎo tôm náam yùu", english: "He is boiling water.", hindi: "वह पानी उबाल रहा है।"),
        ],
        500: [
            WordExample(thai: "ปลานึ่งอร่อยมาก", romanization: "plaa nûeng à-ròi mâak", english: "Steamed fish is very delicious.", hindi: "भाप में पकी मछली बहुत स्वादिष्ट है।"),
            WordExample(thai: "แม่นึ่งข้าวเหนียว", romanization: "mâe nûeng khâao-nǐao", english: "Mom steams sticky rice.", hindi: "माँ चिपचिपा चावल भाप में पकाती हैं।"),
        ],
        501: [
            WordExample(thai: "ไก่ย่างอร่อยมาก", romanization: "kài yâang à-ròi mâak", english: "Grilled chicken is very delicious.", hindi: "ग्रिल्ड चिकन बहुत स्वादिष्ट है।"),
            WordExample(thai: "เขาย่างปลาที่นี่", romanization: "khǎo yâang plaa thîi-nîi", english: "He grills fish here.", hindi: "वह यहाँ मछली ग्रिल करता है।"),
        ],
        502: [
            WordExample(thai: "ฉันหั่นผักในครัว", romanization: "chǎn hàn phàk nai khrua", english: "I cut vegetables in the kitchen.", hindi: "मैं रसोई में सब्ज़ियाँ काटती हूँ।"),
            WordExample(thai: "หั่นพริกให้หน่อย", romanization: "hàn phrík hâi nòi", english: "Please cut the chilies for me.", hindi: "मेरे लिए मिर्च काट दो।"),
        ],
        503: [
            WordExample(thai: "แม่อยู่ในครัว", romanization: "mâe yùu nai khrua", english: "Mom is in the kitchen.", hindi: "माँ रसोई में हैं।"),
            WordExample(thai: "ครัวนี้สะอาดมาก", romanization: "khrua níi sà-àat mâak", english: "This kitchen is very clean.", hindi: "यह रसोई बहुत साफ़ है।"),
        ],
        504: [
            WordExample(thai: "มีดนี้คมมาก", romanization: "mîit níi khom mâak", english: "This knife is very sharp.", hindi: "यह चाकू बहुत तेज़ है।"),
            WordExample(thai: "ผมใช้มีดหั่นผัก", romanization: "phǒm chái mîit hàn phàk", english: "I use a knife to cut vegetables.", hindi: "मैं सब्ज़ी काटने के लिए चाकू इस्तेमाल करता हूँ।"),
        ],
        505: [
            WordExample(thai: "ก๋วยเตี๋ยวชามใหญ่", romanization: "kǔai-tǐao chaam yài", english: "A big bowl of noodles.", hindi: "नूडल्स का बड़ा कटोरा।"),
            WordExample(thai: "ขอชามหน่อยค่ะ", romanization: "khǒr chaam nòi khâ", english: "May I have a bowl please.", hindi: "एक कटोरा देना।"),
        ],
        506: [
            WordExample(thai: "หม้อนี้ร้อนมาก", romanization: "môr níi rórn mâak", english: "This pot is very hot.", hindi: "यह पतीला बहुत गरम है।"),
            WordExample(thai: "แม่ต้มแกงในหม้อ", romanization: "mâe tôm kaeng nai môr", english: "Mom boils curry in the pot.", hindi: "माँ पतीले में करी पकाती हैं।"),
        ],
        507: [
            WordExample(thai: "กระทะร้อนแล้ว", romanization: "krà-thá rórn láew", english: "The pan is hot already.", hindi: "कड़ाही गरम हो गई है।"),
            WordExample(thai: "ผมผัดข้าวในกระทะ", romanization: "phǒm phàt khâao nai krà-thá", english: "I fry rice in the pan.", hindi: "मैं कड़ाही में चावल भूनता हूँ।"),
        ],
        508: [
            WordExample(thai: "ผมใช้ตะเกียบไม่เป็น", romanization: "phǒm chái tà-kìap mâi pen", english: "I cannot use chopsticks.", hindi: "मुझे चॉपस्टिक चलाना नहीं आता।"),
            WordExample(thai: "ขอตะเกียบหน่อยครับ", romanization: "khǒr tà-kìap nòi khráp", english: "Chopsticks please.", hindi: "चॉपस्टिक देना।"),
        ],
        509: [
            WordExample(thai: "เตานี้ร้อนมาก", romanization: "tao níi rórn mâak", english: "This stove is very hot.", hindi: "यह चूल्हा बहुत गरम है।"),
            WordExample(thai: "หม้ออยู่บนเตา", romanization: "môr yùu bon tao", english: "The pot is on the stove.", hindi: "पतीला चूल्हे पर है।"),
        ],
        510: [
            WordExample(thai: "ใส่น้ำมันหน่อย", romanization: "sài nám-man nòi", english: "Add a little oil.", hindi: "थोड़ा तेल डालो।"),
            WordExample(thai: "น้ำมันร้อนแล้ว", romanization: "nám-man rórn láew", english: "The oil is hot already.", hindi: "तेल गरम हो गया है।"),
        ],
        511: [
            WordExample(thai: "ขอซอสหน่อยครับ", romanization: "khǒr sórt nòi khráp", english: "Some sauce please.", hindi: "थोड़ा सॉस देना।"),
            WordExample(thai: "ซอสนี้อร่อยมาก", romanization: "sórt níi à-ròi mâak", english: "This sauce is very delicious.", hindi: "यह सॉस बहुत स्वादिष्ट है।"),
        ],
        512: [
            WordExample(thai: "ไก่อบอร่อยมาก", romanization: "kài òp à-ròi mâak", english: "Baked chicken is very delicious.", hindi: "बेक किया चिकन बहुत स्वादिष्ट है।"),
            WordExample(thai: "แม่อบขนมอยู่", romanization: "mâe òp khà-nǒm yùu", english: "Mom is baking sweets.", hindi: "माँ मिठाई बेक कर रही हैं।"),
        ],
        513: [
            WordExample(thai: "ชิมหน่อยไหม", romanization: "chim nòi mǎi", english: "Want to taste a little?", hindi: "थोड़ा चखोगे?"),
            WordExample(thai: "ฉันชิมแกงแล้ว", romanization: "chǎn chim kaeng láew", english: "I already tasted the curry.", hindi: "मैंने करी चख ली है।"),
        ],
        514: [
            WordExample(thai: "ข้าวสุกแล้ว", romanization: "khâao sùk láew", english: "The rice is cooked.", hindi: "चावल पक गया है।"),
            WordExample(thai: "ไก่ยังไม่สุก", romanization: "kài yang mâi sùk", english: "The chicken is not cooked yet.", hindi: "चिकन अभी पका नहीं है।"),
        ],
        515: [
            WordExample(thai: "ผมไม่กินปลาดิบ", romanization: "phǒm mâi kin plaa dìp", english: "I do not eat raw fish.", hindi: "मैं कच्ची मछली नहीं खाता।"),
            WordExample(thai: "ผักนี้ยังดิบอยู่", romanization: "phàk níi yang dìp yùu", english: "These vegetables are still raw.", hindi: "यह सब्ज़ी अभी कच्ची है।"),
        ],
        516: [
            WordExample(thai: "อุ่นข้าวให้หน่อย", romanization: "ùn khâao hâi nòi", english: "Please warm up the rice.", hindi: "चावल थोड़ा गरम कर दो।"),
            WordExample(thai: "ฉันชอบน้ำอุ่น", romanization: "chǎn chôrp náam ùn", english: "I like warm water.", hindi: "मुझे गुनगुना पानी पसंद है।"),
        ],
        517: [
            WordExample(thai: "ขอข้าวเปล่าครับ", romanization: "khǒo khâao plào khráp", english: "Plain rice, please", hindi: "सादा चावल दीजिए"),
            WordExample(thai: "เขากินข้าวเปล่า", romanization: "kháo kin khâao plào", english: "He eats plain rice", hindi: "वह सादा चावल खाता है"),
        ],
        518: [
            WordExample(thai: "ไปร้านกาแฟไหม", romanization: "pai ráan-kaa-fae mǎi", english: "Shall we go to the coffee shop?", hindi: "कॉफ़ी शॉप चलें?"),
            WordExample(thai: "ร้านกาแฟนี้ดีมาก", romanization: "ráan-kaa-fae níi dii mâak", english: "This coffee shop is very good", hindi: "यह कॉफ़ी शॉप बहुत अच्छी है"),
        ],
        519: [
            WordExample(thai: "คุณสั่งอะไร", romanization: "khun sàng à-rai", english: "What did you order?", hindi: "आपने क्या ऑर्डर किया?"),
            WordExample(thai: "ผมสั่งกาแฟร้อน", romanization: "phǒm sàng kaa-fae rón", english: "I order hot coffee", hindi: "मैं गरम कॉफ़ी ऑर्डर करता हूँ"),
        ],
        520: [
            WordExample(thai: "กาแฟดำขมมาก", romanization: "kaa-fae-dam khǒm mâak", english: "Black coffee is very bitter", hindi: "ब्लैक कॉफ़ी बहुत कड़वी होती है"),
            WordExample(thai: "ชานี้ขมมาก", romanization: "chaa níi khǒm mâak", english: "This tea is very bitter", hindi: "यह चाय बहुत कड़वी है"),
        ],
        521: [
            WordExample(thai: "ขอชาเย็นหวานน้อย", romanization: "khǒo chaa-yen wǎan-nói", english: "Thai iced tea, less sweet please", hindi: "थाई ठंडी चाय कम मीठी दीजिए"),
            WordExample(thai: "เอาหวานน้อยครับ", romanization: "ao wǎan-nói khráp", english: "Less sweet, please", hindi: "कम मीठा कीजिए"),
        ],
        522: [
            WordExample(thai: "ขอเพิ่มน้ำแข็งหน่อย", romanization: "khǒo phêrm nám-khǎeng nòi", english: "Please add more ice", hindi: "थोड़ी और बर्फ़ डालिए"),
            WordExample(thai: "เพิ่มนมได้ไหม", romanization: "phêrm num dâi mǎi", english: "Can you add milk?", hindi: "क्या दूध बढ़ा सकते हैं?"),
        ],
        523: [
            WordExample(thai: "ฉันชอบน้ำผลไม้", romanization: "chǎn chôp nám-phǒn-lá-mái", english: "I like fruit juice", hindi: "मुझे फलों का रस पसंद है"),
            WordExample(thai: "ขอน้ำผลไม้หนึ่งแก้ว", romanization: "khǒo nám-phǒn-lá-mái nèung kâew", english: "One glass of fruit juice, please", hindi: "फलों के रस का एक गिलास दीजिए"),
        ],
        524: [
            WordExample(thai: "ขอน้ำมะนาวเย็น", romanization: "khǒo nám-má-naao yen", english: "An iced lime juice, please", hindi: "ठंडा नींबू पानी दीजिए"),
            WordExample(thai: "น้ำมะนาวอร่อยมาก", romanization: "nám-má-naao à-ròi mâak", english: "Lime juice is very tasty", hindi: "नींबू पानी बहुत स्वादिष्ट है"),
        ],
        525: [
            WordExample(thai: "น้ำมะพร้าวเย็นอร่อย", romanization: "nám-má-phráao yen à-ròi", english: "Cold coconut water is tasty", hindi: "ठंडा नारियल पानी स्वादिष्ट है"),
            WordExample(thai: "ขอน้ำมะพร้าวครับ", romanization: "khǒo nám-má-phráao khráp", english: "Coconut water, please", hindi: "नारियल पानी दीजिए"),
        ],
        526: [
            WordExample(thai: "เขาชอบน้ำอัดลม", romanization: "kháo chôp nám-àt-lom", english: "He likes soft drinks", hindi: "उसे कोल्ड ड्रिंक पसंद है"),
            WordExample(thai: "น้ำอัดลมหวานมาก", romanization: "nám-àt-lom wǎan mâak", english: "Soft drinks are very sweet", hindi: "कोल्ड ड्रिंक बहुत मीठी होती है"),
        ],
        527: [
            WordExample(thai: "ขอน้ำปั่นหนึ่งแก้ว", romanization: "khǒo nám-pàn nèung kâew", english: "One smoothie, please", hindi: "एक स्मूदी दीजिए"),
            WordExample(thai: "น้ำปั่นเย็นมาก", romanization: "nám-pàn yen mâak", english: "The smoothie is very cold", hindi: "स्मूदी बहुत ठंडी है"),
        ],
        528: [
            WordExample(thai: "ชาเย็นหวานมาก", romanization: "chaa-yen wǎan mâak", english: "Thai iced tea is very sweet", hindi: "थाई ठंडी चाय बहुत मीठी होती है"),
            WordExample(thai: "ขอชาเย็นหนึ่งแก้ว", romanization: "khǒo chaa-yen nèung kâew", english: "One Thai iced tea, please", hindi: "एक थाई ठंडी चाय दीजिए"),
        ],
        529: [
            WordExample(thai: "ฉันชอบชานมมาก", romanization: "chǎn chôp chaa-num mâak", english: "I like milk tea a lot", hindi: "मुझे दूध वाली चाय बहुत पसंद है"),
            WordExample(thai: "ชานมแก้วนี้อร่อย", romanization: "chaa-num kâew níi à-ròi", english: "This glass of milk tea is tasty", hindi: "दूध वाली चाय का यह गिलास स्वादिष्ट है"),
        ],
        530: [
            WordExample(thai: "ชาเขียวร้อนหอมมาก", romanization: "chaa-khǐao rón hǒom mâak", english: "Hot green tea is very fragrant", hindi: "गरम ग्रीन टी बहुत खुशबूदार है"),
            WordExample(thai: "คุณชอบชาเขียวไหม", romanization: "khun chôp chaa-khǐao mǎi", english: "Do you like green tea?", hindi: "क्या आपको ग्रीन टी पसंद है?"),
        ],
        531: [
            WordExample(thai: "ขอกาแฟเย็นครับ", romanization: "khǒo kaa-fae-yen khráp", english: "An iced coffee, please", hindi: "ठंडी कॉफ़ी दीजिए"),
            WordExample(thai: "กาแฟเย็นหวานมาก", romanization: "kaa-fae-yen wǎan mâak", english: "Iced coffee is very sweet", hindi: "ठंडी कॉफ़ी बहुत मीठी होती है"),
        ],
        532: [
            WordExample(thai: "ผมดื่มกาแฟดำ", romanization: "phǒm dùem kaa-fae-dam", english: "I drink black coffee", hindi: "मैं ब्लैक कॉफ़ी पीता हूँ"),
            WordExample(thai: "กาแฟดำไม่หวาน", romanization: "kaa-fae-dam mâi wǎan", english: "Black coffee is not sweet", hindi: "ब्लैक कॉफ़ी मीठी नहीं होती"),
        ],
        533: [
            WordExample(thai: "นมเย็นหวานอร่อย", romanization: "num-yen wǎan à-ròi", english: "Pink milk is sweet and tasty", hindi: "गुलाबी दूध मीठा और स्वादिष्ट है"),
            WordExample(thai: "ขอนมเย็นหนึ่งแก้ว", romanization: "khǒo num-yen nèung kâew", english: "One pink milk, please", hindi: "एक गुलाबी दूध दीजिए"),
        ],
        534: [
            WordExample(thai: "โกโก้ร้อนอร่อยมาก", romanization: "koo-kôo rón à-ròi mâak", english: "Hot cocoa is very tasty", hindi: "गरम कोको बहुत स्वादिष्ट है"),
            WordExample(thai: "เขาชอบโกโก้เย็น", romanization: "kháo chôp koo-kôo yen", english: "He likes iced cocoa", hindi: "उसे ठंडा कोको पसंद है"),
        ],
        535: [
            WordExample(thai: "ผมไม่ดื่มเบียร์", romanization: "phǒm mâi dùem bia", english: "I do not drink beer", hindi: "मैं बीयर नहीं पीता"),
            WordExample(thai: "เบียร์แก้วนี้เย็นมาก", romanization: "bia kâew níi yen mâak", english: "This glass of beer is very cold", hindi: "बीयर का यह गिलास बहुत ठंडा है"),
        ],
        536: [
            WordExample(thai: "เค้กนี้อร่อยมาก", romanization: "khéek níi à-ròi mâak", english: "This cake is very tasty", hindi: "यह केक बहुत स्वादिष्ट है"),
            WordExample(thai: "ฉันกินเค้กกับชา", romanization: "chǎn kin khéek kàp chaa", english: "I eat cake with tea", hindi: "मैं चाय के साथ केक खाती हूँ"),
        ],
        537: [
            WordExample(thai: "ขอหลอดหน่อยครับ", romanization: "khǒo lòot nòi khráp", english: "A straw, please", hindi: "एक स्ट्रॉ दीजिए"),
            WordExample(thai: "ไม่เอาหลอดค่ะ", romanization: "mâi ao lòot khâ", english: "No straw, please", hindi: "स्ट्रॉ नहीं चाहिए"),
        ],
        538: [
            WordExample(thai: "แกงนี้มีข่า", romanization: "kaeng níi mii khàa", english: "This curry has galangal.", hindi: "इस करी में कुलंजन है।"),
            WordExample(thai: "ข่าไม่ใช่ขิง", romanization: "khàa mâi châi khǐng", english: "Galangal is not ginger.", hindi: "कुलंजन अदरक नहीं है।"),
        ],
        539: [
            WordExample(thai: "ตะไคร้หอมมาก", romanization: "tà-khrái hǒm mâak", english: "Lemongrass is very fragrant.", hindi: "लेमनग्रास बहुत खुशबूदार है।"),
            WordExample(thai: "อาหารนี้มีตะไคร้", romanization: "aa-hǎan níi mii tà-khrái", english: "This food has lemongrass.", hindi: "इस खाने में लेमनग्रास है।"),
        ],
        540: [
            WordExample(thai: "แกงมีใบมะกรูด", romanization: "kaeng mii bai-má-krùut", english: "The curry has kaffir lime leaves.", hindi: "करी में काफिर नींबू के पत्ते हैं।"),
            WordExample(thai: "ใบมะกรูดหอมมาก", romanization: "bai-má-krùut hǒm mâak", english: "Kaffir lime leaves are very fragrant.", hindi: "काफिर नींबू के पत्ते बहुत खुशबूदार हैं।"),
        ],
        541: [
            WordExample(thai: "ผมชอบโหระพาครับ", romanization: "phǒm chôp hǒo-rá-phaa khráp", english: "I like Thai basil.", hindi: "मुझे थाई तुलसी पसंद है।"),
            WordExample(thai: "ใส่โหระพาหน่อยค่ะ", romanization: "sài hǒo-rá-phaa nòi khâ", english: "Please add some Thai basil.", hindi: "थोड़ी थाई तुलसी डालिए।"),
        ],
        542: [
            WordExample(thai: "ผมชอบกะเพรามาก", romanization: "phǒm chôp kà-phrao mâak", english: "I like holy basil a lot.", hindi: "मुझे होली बेसिल बहुत पसंद है।"),
            WordExample(thai: "กะเพราเผ็ดนิดหน่อย", romanization: "kà-phrao phèt nít-nòi", english: "Holy basil is a little spicy.", hindi: "होली बेसिल थोड़ी तीखी है।"),
        ],
        543: [
            WordExample(thai: "ไม่ใส่ผักชีครับ", romanization: "mâi sài phàk-chii khráp", english: "No coriander, please.", hindi: "धनिया मत डालिए।"),
            WordExample(thai: "คุณชอบผักชีไหม", romanization: "khun chôp phàk-chii mǎi", english: "Do you like coriander?", hindi: "क्या आपको धनिया पसंद है?"),
        ],
        544: [
            WordExample(thai: "สะระแหน่หอมดี", romanization: "sà-rá-nàe hǒm dii", english: "Mint is nicely fragrant.", hindi: "पुदीना अच्छा खुशबूदार है।"),
            WordExample(thai: "ฉันชอบสะระแหน่ค่ะ", romanization: "chǎn chôp sà-rá-nàe khâ", english: "I like mint.", hindi: "मुझे पुदीना पसंद है।"),
        ],
        545: [
            WordExample(thai: "ขอพริกไทยหน่อยครับ", romanization: "khǒo phrík-thai nòi khráp", english: "Some pepper, please.", hindi: "थोड़ी काली मिर्च दीजिए।"),
            WordExample(thai: "พริกไทยเผ็ดนิดหน่อย", romanization: "phrík-thai phèt nít-nòi", english: "Pepper is a little spicy.", hindi: "काली मिर्च थोड़ी तीखी है।"),
        ],
        546: [
            WordExample(thai: "ใส่ซีอิ๊วหน่อยครับ", romanization: "sài sii-íu nòi khráp", english: "Add a little soy sauce.", hindi: "थोड़ा सोया सॉस डालिए।"),
            WordExample(thai: "ผมชอบซีอิ๊วครับ", romanization: "phǒm chôp sii-íu khráp", english: "I like soy sauce.", hindi: "मुझे सोया सॉस पसंद है।"),
        ],
        547: [
            WordExample(thai: "อาหารนี้มีน้ำมันหอย", romanization: "aa-hǎan níi mii nám-man-hǒi", english: "This dish has oyster sauce.", hindi: "इस खाने में ऑयस्टर सॉस है।"),
            WordExample(thai: "น้ำมันหอยอร่อยมาก", romanization: "nám-man-hǒi à-ròi mâak", english: "Oyster sauce is very tasty.", hindi: "ऑयस्टर सॉस बहुत स्वादिष्ट है।"),
        ],
        548: [
            WordExample(thai: "กะปิหอมมาก", romanization: "kà-pì hǒm mâak", english: "Shrimp paste is very fragrant.", hindi: "झींगा पेस्ट बहुत खुशबूदार है।"),
            WordExample(thai: "ฉันไม่กินกะปิค่ะ", romanization: "chǎn mâi kin kà-pì khâ", english: "I do not eat shrimp paste.", hindi: "मैं झींगा पेस्ट नहीं खाती।"),
        ],
        549: [
            WordExample(thai: "ขอน้ำจิ้มหน่อยครับ", romanization: "khǒo nám-jîm nòi khráp", english: "Some dipping sauce, please.", hindi: "थोड़ी डिपिंग सॉस दीजिए।"),
            WordExample(thai: "น้ำจิ้มนี้อร่อยมาก", romanization: "nám-jîm níi à-ròi mâak", english: "This dipping sauce is delicious.", hindi: "यह डिपिंग सॉस बहुत स्वादिष्ट है।"),
        ],
        550: [
            WordExample(thai: "มะขามเปรี้ยวนิดหน่อย", romanization: "má-khǎam prîao nít-nòi", english: "Tamarind is a bit sour.", hindi: "इमली थोड़ी खट्टी है।"),
            WordExample(thai: "ผมชอบมะขามครับ", romanization: "phǒm chôp má-khǎam khráp", english: "I like tamarind.", hindi: "मुझे इमली पसंद है।"),
        ],
        551: [
            WordExample(thai: "ขมิ้นดีมาก", romanization: "khà-mîn dii mâak", english: "Turmeric is very good.", hindi: "हल्दी बहुत अच्छी है।"),
            WordExample(thai: "แกงนี้มีขมิ้น", romanization: "kaeng níi mii khà-mîn", english: "This curry has turmeric.", hindi: "इस करी में हल्दी है।"),
        ],
        552: [
            WordExample(thai: "อบเชยหอมมาก", romanization: "òp-choei hǒm mâak", english: "Cinnamon is very fragrant.", hindi: "दालचीनी बहुत खुशबूदार है।"),
            WordExample(thai: "ชานี้มีอบเชย", romanization: "chaa níi mii òp-choei", english: "This tea has cinnamon.", hindi: "इस चाय में दालचीनी है।"),
        ],
        553: [
            WordExample(thai: "แกงนี้มียี่หร่า", romanization: "kaeng níi mii yîi-ràa", english: "This curry has cumin.", hindi: "इस करी में जीरा है।"),
            WordExample(thai: "ยี่หร่าหอมดี", romanization: "yîi-ràa hǒm dii", english: "Cumin is nicely fragrant.", hindi: "जीरा अच्छा खुशबूदार है।"),
        ],
        554: [
            WordExample(thai: "อาหารนี้มีหอมแดง", romanization: "aa-hǎan níi mii hǒm-daeng", english: "This dish has shallots.", hindi: "इस खाने में छोटे प्याज हैं।"),
            WordExample(thai: "หอมแดงอยู่ที่นี่", romanization: "hǒm-daeng yùu thîi-nîi", english: "The shallots are here.", hindi: "छोटे प्याज यहाँ हैं।"),
        ],
        555: [
            WordExample(thai: "ไม่ใส่ต้นหอมค่ะ", romanization: "mâi sài tôn-hǒm khâ", english: "No spring onion, please.", hindi: "हरा प्याज मत डालिए।"),
            WordExample(thai: "ต้นหอมอยู่ที่นี่", romanization: "tôn-hǒm yùu thîi-nîi", english: "The spring onions are here.", hindi: "हरा प्याज यहाँ है।"),
        ],
        556: [
            WordExample(thai: "พริกแห้งเผ็ดมาก", romanization: "phrík-hâeng phèt mâak", english: "Dried chilies are very spicy.", hindi: "सूखी मिर्च बहुत तीखी है।"),
            WordExample(thai: "ผมไม่กินพริกแห้งครับ", romanization: "phǒm mâi kin phrík-hâeng khráp", english: "I do not eat dried chili.", hindi: "मैं सूखी मिर्च नहीं खाता।"),
        ],
        557: [
            WordExample(thai: "ขอพริกป่นหน่อยครับ", romanization: "khǒo phrík-pòn nòi khráp", english: "Some chili powder, please.", hindi: "थोड़ा मिर्च पाउडर दीजिए।"),
            WordExample(thai: "พริกป่นเผ็ดมาก", romanization: "phrík-pòn phèt mâak", english: "Chili powder is very spicy.", hindi: "मिर्च पाउडर बहुत तीखा है।"),
        ],
        558: [
            WordExample(thai: "ขอน้ำส้มสายชูหน่อยค่ะ", romanization: "khǒo nám-sôm-sǎai-chuu nòi khâ", english: "Some vinegar, please.", hindi: "थोड़ा सिरका दीजिए।"),
            WordExample(thai: "น้ำส้มสายชูเปรี้ยวมาก", romanization: "nám-sôm-sǎai-chuu prîao mâak", english: "Vinegar is very sour.", hindi: "सिरका बहुत खट्टा है।"),
        ],
        559: [
            WordExample(thai: "น้ำพริกเผ็ดมาก", romanization: "nám-phrík phèt mâak", english: "Chili dip is very spicy.", hindi: "मिर्च की चटनी बहुत तीखी है।"),
            WordExample(thai: "ฉันชอบน้ำพริกค่ะ", romanization: "chǎn chôp nám-phrík khâ", english: "I like chili dip.", hindi: "मुझे मिर्च की चटनी पसंद है।"),
        ],
        560: [
            WordExample(thai: "อาหารไทยมีเครื่องเทศมาก", romanization: "aa-hǎan thai mii khrûeang-thêet mâak", english: "Thai food has many spices.", hindi: "थाई खाने में बहुत मसाले हैं।"),
            WordExample(thai: "ผมชอบเครื่องเทศครับ", romanization: "phǒm chôp khrûeang-thêet khráp", english: "I like spices.", hindi: "मुझे मसाले पसंद हैं।"),
        ],
        561: [
            WordExample(thai: "สมุนไพรดีมาก", romanization: "sà-mǔn-phrai dii mâak", english: "Herbs are very good.", hindi: "जड़ी-बूटियाँ बहुत अच्छी हैं।"),
            WordExample(thai: "แกงนี้มีสมุนไพร", romanization: "kaeng níi mii sà-mǔn-phrai", english: "This curry has herbs.", hindi: "इस करी में जड़ी-बूटियाँ हैं।"),
        ],
        562: [
            WordExample(thai: "ขนมนี้มีงา", romanization: "khà-nǒm níi mii ngaa", english: "This snack has sesame.", hindi: "इस मिठाई में तिल हैं।"),
            WordExample(thai: "ผมชอบงาครับ", romanization: "phǒm chôp ngaa khráp", english: "I like sesame.", hindi: "मुझे तिल पसंद है।"),
        ],
        563: [
            WordExample(thai: "ที่นี่ดีมากๆ", romanization: "tîi-nîi dii mâak-mâak", english: "This place is very, very good.", hindi: "यह जगह बहुत ही अच्छी है।"),
            WordExample(thai: "ผมชอบมากๆครับ", romanization: "pǒm chôop mâak-mâak kráp", english: "I like it very much.", hindi: "मुझे बहुत ही पसंद है।"),
        ],
        564: [
            WordExample(thai: "วันนี้ผมกินมาก", romanization: "wan-níi pǒm kin mâak", english: "Today I ate a lot.", hindi: "आज मैंने बहुत खाया।"),
            WordExample(thai: "วันนั้นเขามาที่นี่", romanization: "wan nán kǎo maa tîi-nîi", english: "That day he came here.", hindi: "उस दिन वह यहाँ आया।"),
        ],
        565: [
            WordExample(thai: "เดินตรงไปครับ", romanization: "dern trong pai kráp", english: "Walk straight ahead.", hindi: "सीधे चलते जाइए।"),
            WordExample(thai: "บ้านอยู่ตรงนั้น", romanization: "bâan yùu trong nán", english: "The house is right there.", hindi: "घर ठीक वहीं है।"),
        ],
        566: [
            WordExample(thai: "วันพฤหัสผมไม่มา", romanization: "wan-pá-réu-hàt pǒm mâi maa", english: "On Thursday I am not coming.", hindi: "गुरुवार को मैं नहीं आऊँगा।"),
            WordExample(thai: "เขามาวันพฤหัสครับ", romanization: "kǎo maa wan-pá-réu-hàt kráp", english: "He is coming on Thursday.", hindi: "वह गुरुवार को आएगा।"),
        ],
        567: [
            WordExample(thai: "ฝนตกแรงมาก", romanization: "fǒn tòk raeng mâak", english: "It is raining very hard.", hindi: "बहुत ज़ोर से बारिश हो रही है।"),
            WordExample(thai: "วันนี้ลมแรงมาก", romanization: "wan-níi lom raeng mâak", english: "The wind is very strong today.", hindi: "आज हवा बहुत तेज़ है।"),
        ],
        568: [
            WordExample(thai: "เขาออกไปแล้ว", romanization: "kǎo òok pai láew", english: "He has already gone out.", hindi: "वह बाहर जा चुका है।"),
            WordExample(thai: "ผมออกไปกินครับ", romanization: "pǒm òok pai kin kráp", english: "I am going out to eat.", hindi: "मैं खाने के लिए बाहर जा रहा हूँ।"),
        ],
        569: [
            WordExample(thai: "คนนั้นดีมาก", romanization: "kon nán dii mâak", english: "That person is very good.", hindi: "वह व्यक्ति बहुत अच्छा है।"),
            WordExample(thai: "วันนั้นผมไม่มา", romanization: "wan nán pǒm mâi maa", english: "That day I did not come.", hindi: "उस दिन मैं नहीं आया।"),
        ],
        570: [
            WordExample(thai: "ไปทางนี้ครับ", romanization: "pai taang níi kráp", english: "Go this way.", hindi: "इस रास्ते से जाइए।"),
            WordExample(thai: "ทางนั้นไม่ดี", romanization: "taang nán mâi dii", english: "That way is not good.", hindi: "वह रास्ता अच्छा नहीं है।"),
        ],
        571: [
            WordExample(thai: "อร่อยจังครับ", romanization: "à-ròi jang kráp", english: "So delicious!", hindi: "बहुत ही स्वादिष्ट है!"),
            WordExample(thai: "ที่นี่ดีจังค่ะ", romanization: "tîi-nîi dii jang kâ", english: "This place is so nice.", hindi: "यह जगह बहुत ही अच्छी है।"),
        ],
    ]

    private static let examples1: [Int: [WordExample]] = [
        // Batch 2
        572: [
            WordExample(thai: "ฉันชอบกินของหวาน", romanization: "chǎn chôp kin khǒong-wǎan", english: "I like eating dessert", hindi: "मुझे मिठाई खाना पसंद है"),
            WordExample(thai: "ของหวานที่นี่อร่อย", romanization: "khǒong-wǎan thîi-nîi à-ròi", english: "The dessert here is delicious", hindi: "यहाँ की मिठाई स्वादिष्ट है"),
        ],
        573: [
            WordExample(thai: "ผมกินของว่าง", romanization: "phǒm kin khǒong-wâang", english: "I eat a snack", hindi: "मैं नाश्ता खाता हूँ"),
            WordExample(thai: "เขาชอบของว่าง", romanization: "khǎo chôp khǒong-wâang", english: "He likes snacks", hindi: "उसे स्नैक्स पसंद हैं"),
        ],
        574: [
            WordExample(thai: "ฉันชอบลูกอม", romanization: "chǎn chôp lûuk-om", english: "I like candy", hindi: "मुझे कैंडी पसंद है"),
            WordExample(thai: "ลูกอมหวานมาก", romanization: "lûuk-om wǎan mâak", english: "The candy is very sweet", hindi: "कैंडी बहुत मीठी है"),
        ],
        575: [
            WordExample(thai: "ฉันชอบกินช็อกโกแลต", romanization: "chǎn chôp kin chók-koo-láet", english: "I like eating chocolate", hindi: "मुझे चॉकलेट खाना पसंद है"),
            WordExample(thai: "ช็อกโกแลตอร่อยมาก", romanization: "chók-koo-láet à-ròi mâak", english: "Chocolate is very delicious", hindi: "चॉकलेट बहुत स्वादिष्ट है"),
        ],
        576: [
            WordExample(thai: "ผมกินคุกกี้", romanization: "phǒm kin khúk-kîi", english: "I eat cookies", hindi: "मैं कुकी खाता हूँ"),
            WordExample(thai: "คุกกี้ที่นี่อร่อย", romanization: "khúk-kîi thîi-nîi à-ròi", english: "The cookies here are delicious", hindi: "यहाँ की कुकी स्वादिष्ट है"),
        ],
        577: [
            WordExample(thai: "เขาชอบโดนัท", romanization: "khǎo chôp doo-nát", english: "He likes donuts", hindi: "उसे डोनट पसंद है"),
            WordExample(thai: "โดนัทหวานมาก", romanization: "doo-nát wǎan mâak", english: "The donut is very sweet", hindi: "डोनट बहुत मीठा है"),
        ],
        578: [
            WordExample(thai: "ฉันชอบเนย", romanization: "chǎn chôp noei", english: "I like butter", hindi: "मुझे मक्खन पसंद है"),
            WordExample(thai: "ขนมปังกับเนยอร่อย", romanization: "khà-nǒm-pang kàp noei à-ròi", english: "Bread with butter is delicious", hindi: "मक्खन के साथ ब्रेड स्वादिष्ट है"),
        ],
        579: [
            WordExample(thai: "ฉันกินขนมปังกับแยม", romanization: "chǎn kin khà-nǒm-pang kàp yaem", english: "I eat bread with jam", hindi: "मैं जैम के साथ ब्रेड खाती हूँ"),
            WordExample(thai: "แยมหวานมาก", romanization: "yaem wǎan mâak", english: "The jam is very sweet", hindi: "जैम बहुत मीठा है"),
        ],
        580: [
            WordExample(thai: "น้ำผึ้งหวานมาก", romanization: "nám-phûeng wǎan mâak", english: "Honey is very sweet", hindi: "शहद बहुत मीठा होता है"),
            WordExample(thai: "ฉันชอบชากับน้ำผึ้ง", romanization: "chǎn chôp chaa kàp nám-phûeng", english: "I like tea with honey", hindi: "मुझे शहद वाली चाय पसंद है"),
        ],
        581: [
            WordExample(thai: "แกงนี้มีกะทิ", romanization: "kaeng níi mii kà-thí", english: "This curry has coconut milk", hindi: "इस करी में नारियल का दूध है"),
            WordExample(thai: "ฉันชอบกะทิ", romanization: "chǎn chôp kà-thí", english: "I like coconut milk", hindi: "मुझे नारियल का दूध पसंद है"),
        ],
        582: [
            WordExample(thai: "ผมชอบกินถั่ว", romanization: "phǒm chôp kin thùa", english: "I like eating nuts", hindi: "मुझे मेवे खाना पसंद है"),
            WordExample(thai: "ถั่วดีมาก", romanization: "thùa dii mâak", english: "Nuts are very good", hindi: "मेवे बहुत अच्छे होते हैं"),
        ],
        583: [
            WordExample(thai: "ฉันชอบถั่วลิสง", romanization: "chǎn chôp thùa-lí-sǒng", english: "I like peanuts", hindi: "मुझे मूँगफली पसंद है"),
            WordExample(thai: "ถั่วลิสงอร่อยมาก", romanization: "thùa-lí-sǒng à-ròi mâak", english: "Peanuts are very tasty", hindi: "मूँगफली बहुत स्वादिष्ट होती है"),
        ],
        584: [
            WordExample(thai: "กล้วยทอดอร่อยมาก", romanization: "klûai-thôt à-ròi mâak", english: "Fried banana is very delicious", hindi: "तला केला बहुत स्वादिष्ट है"),
            WordExample(thai: "ผมกินกล้วยทอดที่นี่", romanization: "phǒm kin klûai-thôt thîi-nîi", english: "I eat fried banana here", hindi: "मैं यहाँ तला केला खाता हूँ"),
        ],
        585: [
            WordExample(thai: "ฉันชอบขนมครก", romanization: "chǎn chôp khà-nǒm-khrók", english: "I like khanom krok", hindi: "मुझे खानोम क्रोक पसंद है"),
            WordExample(thai: "ขนมครกหวานมาก", romanization: "khà-nǒm-khrók wǎan mâak", english: "Khanom krok is very sweet", hindi: "खानोम क्रोक बहुत मीठा है"),
        ],
        586: [
            WordExample(thai: "โรตีกล้วยอร่อย", romanization: "roo-tii klûai à-ròi", english: "Banana roti is delicious", hindi: "केले वाली रोटी स्वादिष्ट है"),
            WordExample(thai: "เขาชอบกินโรตี", romanization: "khǎo chôp kin roo-tii", english: "He likes eating roti", hindi: "उसे रोटी खाना पसंद है"),
        ],
        587: [
            WordExample(thai: "ผมกินปาท่องโก๋กับกาแฟ", romanization: "phǒm kin paa-thông-kǒo kàp kaa-fae", english: "I eat patongko with coffee", hindi: "मैं कॉफ़ी के साथ पातोंग्को खाता हूँ"),
            WordExample(thai: "ปาท่องโก๋อร่อยมาก", romanization: "paa-thông-kǒo à-ròi mâak", english: "Patongko is very delicious", hindi: "पातोंग्को बहुत स्वादिष्ट है"),
        ],
        588: [
            WordExample(thai: "ฉันชอบซาลาเปา", romanization: "chǎn chôp saa-laa-pao", english: "I like salapao", hindi: "मुझे सालापाओ पसंद है"),
            WordExample(thai: "ซาลาเปาที่นี่อร่อยมาก", romanization: "saa-laa-pao thîi-nîi à-ròi mâak", english: "The salapao here is very delicious", hindi: "यहाँ का सालापाओ बहुत स्वादिष्ट है"),
        ],
        589: [
            WordExample(thai: "หมูปิ้งอร่อยมาก", romanization: "mǔu-pîng à-ròi mâak", english: "Grilled pork is very delicious", hindi: "ग्रिल्ड पोर्क बहुत स्वादिष्ट है"),
            WordExample(thai: "ผมกินหมูปิ้งกับข้าวเหนียว", romanization: "phǒm kin mǔu-pîng kàp khâao-nǐao", english: "I eat grilled pork with sticky rice", hindi: "मैं स्टिकी राइस के साथ ग्रिल्ड पोर्क खाता हूँ"),
        ],
        590: [
            WordExample(thai: "ฉันชอบกินลูกชิ้น", romanization: "chǎn chôp kin lûuk-chín", english: "I like eating meatballs", hindi: "मुझे मीटबॉल खाना पसंद है"),
            WordExample(thai: "ลูกชิ้นที่นี่อร่อย", romanization: "lûuk-chín thîi-nîi à-ròi", english: "The meatballs here are delicious", hindi: "यहाँ के मीटबॉल स्वादिष्ट हैं"),
        ],
        591: [
            WordExample(thai: "เขากินไส้กรอก", romanization: "khǎo kin sâi-kròk", english: "He eats sausage", hindi: "वह सॉसेज खाता है"),
            WordExample(thai: "ไส้กรอกอร่อยมาก", romanization: "sâi-kròk à-ròi mâak", english: "The sausage is very delicious", hindi: "सॉसेज बहुत स्वादिष्ट है"),
        ],
        592: [
            WordExample(thai: "ฉันชอบมันฝรั่งทอด", romanization: "chǎn chôp man-fà-ràng-thôt", english: "I like french fries", hindi: "मुझे फ्रेंच फ्राइज़ पसंद हैं"),
            WordExample(thai: "มันฝรั่งทอดเค็มมาก", romanization: "man-fà-ràng-thôt khem mâak", english: "The fries are very salty", hindi: "फ्राइज़ बहुत नमकीन हैं"),
        ],
        593: [
            WordExample(thai: "ฉันชอบข้าวโพดคั่ว", romanization: "chǎn chôp khâao-phôot-khûa", english: "I like popcorn", hindi: "मुझे पॉपकॉर्न पसंद है"),
            WordExample(thai: "ข้าวโพดคั่วอร่อยมาก", romanization: "khâao-phôot-khûa à-ròi mâak", english: "Popcorn is very delicious", hindi: "पॉपकॉर्न बहुत स्वादिष्ट है"),
        ],
        594: [
            WordExample(thai: "ฉันชอบกินเฉาก๊วย", romanization: "chǎn chôp kin chǎo-kúai", english: "I like eating grass jelly", hindi: "मुझे ग्रास जेली खाना पसंद है"),
            WordExample(thai: "เฉาก๊วยอร่อยมาก", romanization: "chǎo-kúai à-ròi mâak", english: "Grass jelly is very delicious", hindi: "ग्रास जेली बहुत स्वादिष्ट है"),
        ],
        595: [
            WordExample(thai: "บัวลอยมีกะทิ", romanization: "bua-loi mii kà-thí", english: "Bua loi has coconut milk", hindi: "बुआ लॉय में नारियल का दूध होता है"),
            WordExample(thai: "ฉันชอบกินบัวลอย", romanization: "chǎn chôp kin bua-loi", english: "I like eating bua loi", hindi: "मुझे बुआ लॉय खाना पसंद है"),
        ],
        596: [
            WordExample(thai: "ขนมปังกับสังขยาอร่อย", romanization: "khà-nǒm-pang kàp sǎng-khà-yǎa à-ròi", english: "Bread with custard is delicious", hindi: "कस्टर्ड के साथ ब्रेड स्वादिष्ट है"),
            WordExample(thai: "สังขยาหวานมาก", romanization: "sǎng-khà-yǎa wǎan mâak", english: "The custard is very sweet", hindi: "कस्टर्ड बहुत मीठा है"),
        ],
        597: [
            WordExample(thai: "ฉันชอบกินวุ้น", romanization: "chǎn chôp kin wún", english: "I like eating jelly", hindi: "मुझे जेली खाना पसंद है"),
            WordExample(thai: "วุ้นหวานดี", romanization: "wún wǎan dii", english: "The jelly is nicely sweet", hindi: "जेली अच्छी मीठी है"),
        ],
        598: [
            WordExample(thai: "ฉันชอบกินน้ำแข็งไส", romanization: "chǎn chôp kin nám-khǎeng-sǎi", english: "I like eating shaved ice", hindi: "मुझे शेव्ड आइस खाना पसंद है"),
            WordExample(thai: "น้ำแข็งไสหวานมาก", romanization: "nám-khǎeng-sǎi wǎan mâak", english: "The shaved ice is very sweet", hindi: "शेव्ड आइस बहुत मीठा है"),
        ],
        599: [
            WordExample(thai: "ผมกินขนมปังปิ้งกับเนย", romanization: "phǒm kin khà-nǒm-pang-pîng kàp noei", english: "I eat toast with butter", hindi: "मैं मक्खन के साथ टोस्ट खाता हूँ"),
            WordExample(thai: "ขนมปังปิ้งอร่อยดี", romanization: "khà-nǒm-pang-pîng à-ròi dii", english: "The toast is quite tasty", hindi: "टोस्ट काफ़ी स्वादिष्ट है"),
        ],
        600: [
            WordExample(thai: "กล้วยทอดกรอบมาก", romanization: "klûai-thôt kròp mâak", english: "The fried banana is very crispy", hindi: "तला केला बहुत कुरकुरा है"),
            WordExample(thai: "คุกกี้กรอบดี", romanization: "khúk-kîi kròp dii", english: "The cookie is nicely crispy", hindi: "कुकी अच्छी कुरकुरी है"),
        ],
        601: [
            WordExample(thai: "เส้นอร่อยมาก", romanization: "sên à-ròi mâak", english: "The noodles are very delicious", hindi: "नूडल्स बहुत स्वादिष्ट हैं"),
            WordExample(thai: "ผมชอบเส้นนี้", romanization: "phǒm chôop sên níi", english: "I like these noodles", hindi: "मुझे ये नूडल्स पसंद हैं"),
        ],
        602: [
            WordExample(thai: "ผมสั่งเส้นเล็กครับ", romanization: "phǒm sàng sên-lék khráp", english: "I order thin noodles", hindi: "मैं पतले नूडल्स ऑर्डर करता हूँ"),
            WordExample(thai: "เส้นเล็กอร่อยมาก", romanization: "sên-lék à-ròi mâak", english: "Thin noodles are very delicious", hindi: "पतले नूडल्स बहुत स्वादिष्ट हैं"),
        ],
        603: [
            WordExample(thai: "ผมชอบกินเส้นใหญ่", romanization: "phǒm chôop kin sên-yài", english: "I like eating wide noodles", hindi: "मुझे चौड़े नूडल्स खाना पसंद है"),
            WordExample(thai: "เส้นใหญ่อร่อยดี", romanization: "sên-yài à-ròi dii", english: "Wide noodles are quite tasty", hindi: "चौड़े नूडल्स काफ़ी स्वादिष्ट हैं"),
        ],
        604: [
            WordExample(thai: "เส้นหมี่อร่อยมาก", romanization: "sên-mìi à-ròi mâak", english: "Rice vermicelli is very delicious", hindi: "चावल की सेवइयाँ बहुत स्वादिष्ट हैं"),
            WordExample(thai: "ฉันชอบกินเส้นหมี่", romanization: "chǎn chôop kin sên-mìi", english: "I like eating rice vermicelli", hindi: "मुझे चावल की सेवइयाँ खाना पसंद है"),
        ],
        605: [
            WordExample(thai: "ผมชอบกินวุ้นเส้น", romanization: "phǒm chôop kin wún-sên", english: "I like eating glass noodles", hindi: "मुझे ग्लास नूडल्स खाना पसंद है"),
            WordExample(thai: "วุ้นเส้นอร่อยมาก", romanization: "wún-sên à-ròi mâak", english: "Glass noodles are very delicious", hindi: "ग्लास नूडल्स बहुत स्वादिष्ट हैं"),
        ],
        606: [
            WordExample(thai: "ผมสั่งบะหมี่ครับ", romanization: "phǒm sàng bà-mìi khráp", english: "I order egg noodles", hindi: "मैं अंडे वाले नूडल्स ऑर्डर करता हूँ"),
            WordExample(thai: "บะหมี่อร่อยมาก", romanization: "bà-mìi à-ròi mâak", english: "Egg noodles are very delicious", hindi: "अंडे वाले नूडल्स बहुत स्वादिष्ट हैं"),
        ],
        607: [
            WordExample(thai: "ขนมจีนอร่อยมาก", romanization: "khà-nǒm-jiin à-ròi mâak", english: "Khanom jeen is very delicious", hindi: "खनोम चीन बहुत स्वादिष्ट है"),
            WordExample(thai: "ฉันชอบกินขนมจีน", romanization: "chǎn chôop kin khà-nǒm-jiin", english: "I like eating khanom jeen", hindi: "मुझे खनोम चीन खाना पसंद है"),
        ],
        608: [
            WordExample(thai: "ผมกินข้าวสวย", romanization: "phǒm kin khâao-sǔai", english: "I eat steamed rice", hindi: "मैं भाप में पका चावल खाता हूँ"),
            WordExample(thai: "ผมสั่งข้าวสวยครับ", romanization: "phǒm sàng khâao-sǔai khráp", english: "I order steamed rice", hindi: "मैं भाप में पका चावल ऑर्डर करता हूँ"),
        ],
        609: [
            WordExample(thai: "ผมสั่งข้าวเปล่าครับ", romanization: "phǒm sàng khâao-plàao khráp", english: "I order plain rice", hindi: "मैं सादा चावल ऑर्डर करता हूँ"),
            WordExample(thai: "ฉันกินข้าวเปล่า", romanization: "chǎn kin khâao-plàao", english: "I eat plain rice", hindi: "मैं सादा चावल खाती हूँ"),
        ],
        610: [
            WordExample(thai: "ข้าวต้มอร่อยมาก", romanization: "khâao-tôm à-ròi mâak", english: "Boiled rice soup is very delicious", hindi: "उबले चावल का सूप बहुत स्वादिष्ट है"),
            WordExample(thai: "ฉันกินข้าวต้มที่นี่", romanization: "chǎn kin khâao-tôm thîi-nîi", english: "I eat boiled rice soup here", hindi: "मैं यहाँ उबले चावल का सूप खाती हूँ"),
        ],
        611: [
            WordExample(thai: "ผมชอบกินโจ๊ก", romanization: "phǒm chôop kin jóok", english: "I like eating congee", hindi: "मुझे काँजी खाना पसंद है"),
            WordExample(thai: "โจ๊กไม่เผ็ด", romanization: "jóok mâi phèt", english: "Congee is not spicy", hindi: "काँजी तीखी नहीं है"),
        ],
        612: [
            WordExample(thai: "ข้าวมันไก่อร่อยมาก", romanization: "khâao-man-kài à-ròi mâak", english: "Chicken rice is very delicious", hindi: "चिकन राइस बहुत स्वादिष्ट है"),
            WordExample(thai: "ผมสั่งข้าวมันไก่ครับ", romanization: "phǒm sàng khâao-man-kài khráp", english: "I order chicken rice", hindi: "मैं चिकन राइस ऑर्डर करता हूँ"),
        ],
        613: [
            WordExample(thai: "เขาชอบข้าวขาหมู", romanization: "khǎo chôop khâao-khǎa-mǔu", english: "He likes pork leg rice", hindi: "उसे पोर्क लेग राइस पसंद है"),
            WordExample(thai: "ข้าวขาหมูอร่อยมาก", romanization: "khâao-khǎa-mǔu à-ròi mâak", english: "Pork leg rice is very delicious", hindi: "पोर्क लेग राइस बहुत स्वादिष्ट है"),
        ],
        614: [
            WordExample(thai: "ผมกินข้าวหมูแดง", romanization: "phǒm kin khâao-mǔu-daeng", english: "I eat red pork rice", hindi: "मैं रेड पोर्क राइस खाता हूँ"),
            WordExample(thai: "ข้าวหมูแดงอร่อยดี", romanization: "khâao-mǔu-daeng à-ròi dii", english: "Red pork rice is quite tasty", hindi: "रेड पोर्क राइस काफ़ी स्वादिष्ट है"),
        ],
        615: [
            WordExample(thai: "ฉันกินข้าวราดแกง", romanization: "chǎn kin khâao-râat-kaeng", english: "I eat rice with curry", hindi: "मैं करी वाला चावल खाती हूँ"),
            WordExample(thai: "ข้าวราดแกงเผ็ดมาก", romanization: "khâao-râat-kaeng phèt mâak", english: "Rice with curry is very spicy", hindi: "करी वाला चावल बहुत तीखा है"),
        ],
        616: [
            WordExample(thai: "ผัดกะเพราเผ็ดมาก", romanization: "phàt-kà-phrao phèt mâak", english: "Basil stir-fry is very spicy", hindi: "बेसिल स्टर-फ्राई बहुत तीखा है"),
            WordExample(thai: "ผมสั่งผัดกะเพราครับ", romanization: "phǒm sàng phàt-kà-phrao khráp", english: "I order basil stir-fry", hindi: "मैं बेसिल स्टर-फ्राई ऑर्डर करता हूँ"),
        ],
        617: [
            WordExample(thai: "ข้าวไข่เจียวอร่อยดี", romanization: "khâao-khài-jiao à-ròi dii", english: "Omelette rice is quite tasty", hindi: "ऑमलेट राइस काफ़ी स्वादिष्ट है"),
            WordExample(thai: "ฉันชอบข้าวไข่เจียว", romanization: "chǎn chôop khâao-khài-jiao", english: "I like omelette rice", hindi: "मुझे ऑमलेट राइस पसंद है"),
        ],
        618: [
            WordExample(thai: "ผัดซีอิ๊วไม่เผ็ด", romanization: "phàt-sii-íu mâi phèt", english: "Pad see ew is not spicy", hindi: "पैड सी यू तीखा नहीं है"),
            WordExample(thai: "ผมชอบกินผัดซีอิ๊ว", romanization: "phǒm chôop kin phàt-sii-íu", english: "I like eating pad see ew", hindi: "मुझे पैड सी यू खाना पसंद है"),
        ],
        619: [
            WordExample(thai: "ราดหน้าอร่อยมาก", romanization: "râat-nâa à-ròi mâak", english: "Rad na is very delicious", hindi: "राद ना बहुत स्वादिष्ट है"),
            WordExample(thai: "เขาสั่งราดหน้า", romanization: "khǎo sàng râat-nâa", english: "He orders rad na", hindi: "वह राद ना ऑर्डर करता है"),
        ],
        620: [
            WordExample(thai: "ผัดขี้เมาเผ็ดมาก", romanization: "phàt-khîi-mao phèt mâak", english: "Drunken noodles are very spicy", hindi: "ड्रंकन नूडल्स बहुत तीखे हैं"),
            WordExample(thai: "ผมชอบผัดขี้เมา", romanization: "phǒm chôop phàt-khîi-mao", english: "I like drunken noodles", hindi: "मुझे ड्रंकन नूडल्स पसंद हैं"),
        ],
        621: [
            WordExample(thai: "ผมสั่งก๋วยเตี๋ยวน้ำ", romanization: "phǒm sàng kǔai-tǐao-náam", english: "I order noodle soup", hindi: "मैं नूडल सूप ऑर्डर करता हूँ"),
            WordExample(thai: "ก๋วยเตี๋ยวน้ำอร่อยมาก", romanization: "kǔai-tǐao-náam à-ròi mâak", english: "Noodle soup is very delicious", hindi: "नूडल सूप बहुत स्वादिष्ट है"),
        ],
        622: [
            WordExample(thai: "ฉันชอบก๋วยเตี๋ยวแห้ง", romanization: "chǎn chôop kǔai-tǐao-hâeng", english: "I like dry noodles", hindi: "मुझे सूखे नूडल्स पसंद हैं"),
            WordExample(thai: "เขาสั่งก๋วยเตี๋ยวแห้ง", romanization: "khǎo sàng kǔai-tǐao-hâeng", english: "He orders dry noodles", hindi: "वह सूखे नूडल्स ऑर्डर करता है"),
        ],
        623: [
            WordExample(thai: "ก๋วยเตี๋ยวเรืออร่อยมาก", romanization: "kǔai-tǐao-ruea à-ròi mâak", english: "Boat noodles are very delicious", hindi: "बोट नूडल्स बहुत स्वादिष्ट हैं"),
            WordExample(thai: "ผมชอบกินก๋วยเตี๋ยวเรือ", romanization: "phǒm chôop kin kǔai-tǐao-ruea", english: "I like eating boat noodles", hindi: "मुझे बोट नूडल्स खाना पसंद है"),
        ],
        624: [
            WordExample(thai: "ข้าวซอยอร่อยมาก", romanization: "khâao-soi à-ròi mâak", english: "Khao soi is very delicious", hindi: "खाओ सोई बहुत स्वादिष्ट है"),
            WordExample(thai: "ฉันกินข้าวซอยที่นี่", romanization: "chǎn kin khâao-soi thîi-nîi", english: "I eat khao soi here", hindi: "मैं यहाँ खाओ सोई खाती हूँ"),
        ],
        625: [
            WordExample(thai: "ผมกินมาม่า", romanization: "phǒm kin maa-mâa", english: "I eat instant noodles", hindi: "मैं इंस्टेंट नूडल्स खाता हूँ"),
            WordExample(thai: "เขาชอบกินมาม่า", romanization: "khǎo chôop kin maa-mâa", english: "He likes eating instant noodles", hindi: "उसे इंस्टेंट नूडल्स खाना पसंद है"),
        ],
        626: [
            WordExample(thai: "ฉันกินข้าวกล้อง", romanization: "chǎn kin khâao-klông", english: "I eat brown rice", hindi: "मैं ब्राउन राइस खाती हूँ"),
            WordExample(thai: "ข้าวกล้องดีมาก", romanization: "khâao-klông dii mâak", english: "Brown rice is very good", hindi: "ब्राउन राइस बहुत अच्छा है"),
        ],
        627: [
            WordExample(thai: "ข้าวหอมมะลิอร่อยมาก", romanization: "khâao-hǒm-má-lí à-ròi mâak", english: "Jasmine rice is very delicious", hindi: "जैस्मिन चावल बहुत स्वादिष्ट है"),
            WordExample(thai: "ผมชอบข้าวหอมมะลิ", romanization: "phǒm chôop khâao-hǒm-má-lí", english: "I like jasmine rice", hindi: "मुझे जैस्मिन चावल पसंद है"),
        ],
        628: [
            WordExample(thai: "เกี๊ยวอร่อยมาก", romanization: "kíao à-ròi mâak", english: "Wontons are very delicious", hindi: "वॉनटन बहुत स्वादिष्ट हैं"),
            WordExample(thai: "ผมสั่งเกี๊ยวครับ", romanization: "phǒm sàng kíao khráp", english: "I order wontons", hindi: "मैं वॉनटन ऑर्डर करता हूँ"),
        ],
        629: [
            WordExample(thai: "เขาหุงข้าวอยู่", romanization: "khǎo hǔng-khâao yùu", english: "He is cooking rice", hindi: "वह चावल पका रहा है"),
            WordExample(thai: "ฉันหุงข้าวที่นี่", romanization: "chǎn hǔng-khâao thîi-nîi", english: "I cook rice here", hindi: "मैं यहाँ चावल पकाती हूँ"),
        ],
        630: [
            WordExample(thai: "อาหารนี้จืดมาก", romanization: "aa-hǎan níi jùet mâak", english: "This food is very bland.", hindi: "यह खाना बहुत फीका है।"),
            WordExample(thai: "ฉันไม่ชอบอาหารจืด", romanization: "chǎn mâi chôp aa-hǎan jùet", english: "I do not like bland food.", hindi: "मुझे फीका खाना पसंद नहीं है।"),
        ],
        631: [
            WordExample(thai: "ปลานี้สดมาก", romanization: "plaa níi sòt mâak", english: "This fish is very fresh.", hindi: "यह मछली बहुत ताज़ी है।"),
            WordExample(thai: "ฉันชอบผักสด", romanization: "chǎn chôp phàk sòt", english: "I like fresh vegetables.", hindi: "मुझे ताज़ी सब्ज़ी पसंद है।"),
        ],
        632: [
            WordExample(thai: "ปลานี้เหม็นมาก", romanization: "plaa níi měn mâak", english: "This fish smells very bad.", hindi: "यह मछली बहुत बदबूदार है।"),
            WordExample(thai: "ห้องนี้เหม็น", romanization: "hâwng níi měn", english: "This room smells bad.", hindi: "इस कमरे में बदबू है।"),
        ],
        633: [
            WordExample(thai: "ปลานี้คาวมาก", romanization: "plaa níi khaao mâak", english: "This fish is very fishy.", hindi: "यह मछली बहुत बास मारती है।"),
            WordExample(thai: "ฉันไม่ชอบกลิ่นคาว", romanization: "chǎn mâi chôp klìn khaao", english: "I do not like fishy smell.", hindi: "मुझे मछली की बास पसंद नहीं है।"),
        ],
        634: [
            WordExample(thai: "ข้าวนี้นุ่มมาก", romanization: "khâao níi nûm mâak", english: "This rice is very soft.", hindi: "यह चावल बहुत मुलायम है।"),
            WordExample(thai: "เนื้อนุ่มอร่อยมาก", romanization: "núea nûm à-ròi mâak", english: "Tender meat is very delicious.", hindi: "मुलायम मांस बहुत स्वादिष्ट है।"),
        ],
        635: [
            WordExample(thai: "ขนมปังนี้นิ่มมาก", romanization: "khà-nǒm-pang níi nîm mâak", english: "This bread is very soft.", hindi: "यह ब्रेड बहुत नरम है।"),
            WordExample(thai: "เตียงนี้นิ่มดี", romanization: "tiang níi nîm dii", english: "This bed is nicely soft.", hindi: "यह बिस्तर अच्छा नरम है।"),
        ],
        636: [
            WordExample(thai: "ขนมปังนี้แข็งมาก", romanization: "khà-nǒm-pang níi khǎeng mâak", english: "This bread is very hard.", hindi: "यह ब्रेड बहुत सख़्त है।"),
            WordExample(thai: "เนื้อนี้แข็งมาก", romanization: "núea níi khǎeng mâak", english: "This meat is very tough.", hindi: "यह मांस बहुत सख़्त है।"),
        ],
        637: [
            WordExample(thai: "ข้าวเหนียวอร่อยมาก", romanization: "khâao nǐao à-ròi mâak", english: "Sticky rice is very delicious.", hindi: "चिपचिपा चावल बहुत स्वादिष्ट है।"),
            WordExample(thai: "เนื้อนี้เหนียวมาก", romanization: "núea níi nǐao mâak", english: "This meat is very chewy.", hindi: "यह मांस बहुत चीमड़ है।"),
        ],
        638: [
            WordExample(thai: "ส้มนี้ฉ่ำมาก", romanization: "sôm níi chàm mâak", english: "This orange is very juicy.", hindi: "यह संतरा बहुत रसीला है।"),
            WordExample(thai: "แตงโมฉ่ำมาก", romanization: "taeng-moo chàm mâak", english: "The watermelon is very juicy.", hindi: "तरबूज़ बहुत रसीला है।"),
        ],
        639: [
            WordExample(thai: "กล้วยนี้เละแล้ว", romanization: "klûai níi lé láeo", english: "This banana is mushy already.", hindi: "यह केला गल गया है।"),
            WordExample(thai: "ข้าวเละไม่อร่อย", romanization: "khâao lé mâi à-ròi", english: "Mushy rice is not tasty.", hindi: "गला चावल स्वादिष्ट नहीं होता।"),
        ],
        640: [
            WordExample(thai: "ขนมปังแฉะแล้ว", romanization: "khà-nǒm-pang chàe láeo", english: "The bread is soggy now.", hindi: "ब्रेड गीली हो गई है।"),
            WordExample(thai: "ถนนแฉะมาก", romanization: "thà-nǒn chàe mâak", english: "The road is very wet.", hindi: "सड़क बहुत गीली है।"),
        ],
        641: [
            WordExample(thai: "แกงนี้ข้นมาก", romanization: "kaeng níi khôn mâak", english: "This curry is very thick.", hindi: "यह करी बहुत गाढ़ी है।"),
            WordExample(thai: "ฉันชอบซุปข้น", romanization: "chǎn chôp súp khôn", english: "I like thick soup.", hindi: "मुझे गाढ़ा सूप पसंद है।"),
        ],
        642: [
            WordExample(thai: "ซุปนี้เหลวมาก", romanization: "súp níi lěo mâak", english: "This soup is very runny.", hindi: "यह सूप बहुत पतला है।"),
            WordExample(thai: "ไข่นี้ยังเหลวอยู่", romanization: "khài níi yang lěo yùu", english: "This egg is still runny.", hindi: "यह अंडा अभी भी पतला है।"),
        ],
        643: [
            WordExample(thai: "น้ำนี้ใสมาก", romanization: "náam níi sǎi mâak", english: "This water is very clear.", hindi: "यह पानी बहुत साफ़ है।"),
            WordExample(thai: "ซุปใสอร่อยดี", romanization: "súp sǎi à-ròi dii", english: "Clear soup is nicely tasty.", hindi: "साफ़ सूप अच्छा स्वादिष्ट है।"),
        ],
        644: [
            WordExample(thai: "ผิวเขาเนียนมาก", romanization: "phǐu khǎo nian mâak", english: "Her skin is very smooth.", hindi: "उसकी त्वचा बहुत चिकनी है।"),
            WordExample(thai: "ขนมนี้เนียนนุ่ม", romanization: "khà-nǒm níi nian nûm", english: "This dessert is smooth and soft.", hindi: "यह मिठाई चिकनी और मुलायम है।"),
        ],
        645: [
            WordExample(thai: "ผ้านี้หยาบมาก", romanization: "phâa níi yàap mâak", english: "This cloth is very rough.", hindi: "यह कपड़ा बहुत खुरदुरा है।"),
            WordExample(thai: "น้ำตาลนี้หยาบ", romanization: "nám-taan níi yàap", english: "This sugar is coarse.", hindi: "यह चीनी दरदरी है।"),
        ],
        646: [
            WordExample(thai: "เนื้อเปื่อยนุ่มมาก", romanization: "núea pùeai nûm mâak", english: "The stewed meat is very tender.", hindi: "गला हुआ मांस बहुत मुलायम है।"),
            WordExample(thai: "หมูเปื่อยอร่อยมาก", romanization: "mǔu pùeai à-ròi mâak", english: "Tender pork is very delicious.", hindi: "गला हुआ पोर्क बहुत स्वादिष्ट है।"),
        ],
        647: [
            WordExample(thai: "แกงนี้กลมกล่อมมาก", romanization: "kaeng níi klom-klòm mâak", english: "This curry is very well balanced.", hindi: "इस करी का स्वाद बहुत संतुलित है।"),
            WordExample(thai: "รสชาติกลมกล่อมดี", romanization: "rót-châat klom-klòm dii", english: "The flavour is nicely balanced.", hindi: "स्वाद अच्छा संतुलित है।"),
        ],
        648: [
            WordExample(thai: "กาแฟนี้เข้มข้นมาก", romanization: "kaa-fae níi khêm-khôn mâak", english: "This coffee is very strong.", hindi: "यह कॉफ़ी बहुत तेज़ है।"),
            WordExample(thai: "ซุปนี้เข้มข้นอร่อย", romanization: "súp níi khêm-khôn à-ròi", english: "This soup is rich and tasty.", hindi: "यह सूप गाढ़ा और स्वादिष्ट है।"),
        ],
        649: [
            WordExample(thai: "อาหารนี้เลี่ยนมาก", romanization: "aa-hǎan níi lîan mâak", english: "This food is very greasy.", hindi: "यह खाना बहुत चिकनाई भरा है।"),
            WordExample(thai: "ขนมนี้หวานเลี่ยน", romanization: "khà-nǒm níi wǎan lîan", english: "This dessert is sickly sweet.", hindi: "यह मिठाई हद से ज़्यादा मीठी है।"),
        ],
        650: [
            WordExample(thai: "เค้กนี้แน่นมาก", romanization: "khéek níi nâen mâak", english: "This cake is very dense.", hindi: "यह केक बहुत ठोस है।"),
            WordExample(thai: "เนื้อปลาแน่นดี", romanization: "núea plaa nâen dii", english: "The fish flesh is nicely firm.", hindi: "मछली का मांस अच्छा ठोस है।"),
        ],
        651: [
            WordExample(thai: "ชานี้ฝาดมาก", romanization: "chaa níi fàat mâak", english: "This tea is very astringent.", hindi: "यह चाय बहुत कसैली है।"),
            WordExample(thai: "กล้วยดิบฝาดมาก", romanization: "klûai dìp fàat mâak", english: "Raw banana is very astringent.", hindi: "कच्चा केला बहुत कसैला होता है।"),
        ],
        652: [
            WordExample(thai: "น้ำอัดลมซ่ามาก", romanization: "nám-àt-lom sâa mâak", english: "The soda is very fizzy.", hindi: "सोडा बहुत झनझनाता है।"),
            WordExample(thai: "เบียร์นี้ไม่ซ่าแล้ว", romanization: "bia níi mâi sâa láeo", english: "This beer is not fizzy anymore.", hindi: "यह बियर अब झागदार नहीं है।"),
        ],
        653: [
            WordExample(thai: "ขนมปังนี้ฟูมาก", romanization: "khà-nǒm-pang níi fuu mâak", english: "This bread is very fluffy.", hindi: "यह ब्रेड बहुत फूली हुई है।"),
            WordExample(thai: "เค้กนี้ฟูนุ่ม", romanization: "khéek níi fuu nûm", english: "This cake is fluffy and soft.", hindi: "यह केक फूला और मुलायम है।"),
        ],
        654: [
            WordExample(thai: "ผลไม้นี้เน่าแล้ว", romanization: "phǒn-lá-máai níi nâo láeo", english: "This fruit is rotten already.", hindi: "यह फल सड़ गया है।"),
            WordExample(thai: "กล้วยเน่าเหม็นมาก", romanization: "klûai nâo měn mâak", english: "The rotten banana smells very bad.", hindi: "सड़ा केला बहुत बदबूदार है।"),
        ],
        655: [
            WordExample(thai: "นมนี้บูดแล้ว", romanization: "nom níi bùut láeo", english: "This milk has gone bad.", hindi: "यह दूध ख़राब हो गया है।"),
            WordExample(thai: "อาหารบูดกินไม่ได้", romanization: "aa-hǎan bùut kin mâi dâai", english: "Spoiled food cannot be eaten.", hindi: "ख़राब खाना नहीं खा सकते।"),
        ],
        656: [
            WordExample(thai: "น้ำตาลนี้ละเอียดมาก", romanization: "nám-taan níi lá-ìat mâak", english: "This sugar is very fine.", hindi: "यह चीनी बहुत महीन है।"),
            WordExample(thai: "แป้งนี้ละเอียดดี", romanization: "pâeng níi lá-ìat dii", english: "This flour is nicely fine.", hindi: "यह आटा अच्छा महीन है।"),
        ],
        657: [
            WordExample(thai: "ข้าวนี้ร่วนดี", romanization: "khâao níi rûan dii", english: "This rice is nicely fluffy.", hindi: "यह चावल अच्छे खिले-खिले हैं।"),
            WordExample(thai: "ขนมนี้ร่วนกรอบ", romanization: "khà-nǒm níi rûan kròp", english: "This snack is crumbly and crisp.", hindi: "यह स्नैक भुरभुरा और कुरकुरा है।"),
        ],
        658: [
            WordExample(thai: "น้ำผึ้งหนืดมาก", romanization: "nám-phûeng nùet mâak", english: "Honey is very viscous.", hindi: "शहद बहुत गाढ़ा-चिपचिपा होता है।"),
            WordExample(thai: "ซอสนี้หนืดมาก", romanization: "sáwt níi nùet mâak", english: "This sauce is very thick and sticky.", hindi: "यह सॉस बहुत गाढ़ा है।"),
        ],
        659: [
            WordExample(thai: "ผมจองโต๊ะแล้ว", romanization: "pǒm jong tó láew", english: "I already reserved a table.", hindi: "मैंने मेज़ बुक कर ली है।"),
            WordExample(thai: "จองโต๊ะได้ไหมครับ", romanization: "jong tó dâai mǎi kráp", english: "Can I reserve a table?", hindi: "क्या मैं मेज़ बुक कर सकता हूँ?"),
        ],
        660: [
            WordExample(thai: "ขอเงินทอนด้วยครับ", romanization: "kǒr ngern-torn dûai kráp", english: "My change, please.", hindi: "मेरे बाकी पैसे दीजिए।"),
            WordExample(thai: "นี่เงินทอนของคุณ", romanization: "nîi ngern-torn kǒng kun", english: "Here is your change.", hindi: "ये आपके बाकी पैसे हैं।"),
        ],
        661: [
            WordExample(thai: "ราคาเท่าไหร่ครับ", romanization: "raa-kaa tâo-rài kráp", english: "How much is the price?", hindi: "दाम कितना है?"),
            WordExample(thai: "ราคาไม่แพง", romanization: "raa-kaa mâi paeng", english: "The price is not expensive.", hindi: "दाम महँगा नहीं है।"),
        ],
        662: [
            WordExample(thai: "พนักงานใจดีมาก", romanization: "pá-nák-ngaan jai-dii mâak", english: "The staff is very kind.", hindi: "कर्मचारी बहुत अच्छे हैं।"),
            WordExample(thai: "เรียกพนักงานหน่อย", romanization: "rîak pá-nák-ngaan nòi", english: "Please call the waiter.", hindi: "वेटर को बुलाइए।"),
        ],
        663: [
            WordExample(thai: "ข้าวผัดหมดแล้วค่ะ", romanization: "kâao-pàt mòt láew kâ", english: "Fried rice is sold out.", hindi: "फ्राइड राइस ख़त्म हो गया।"),
            WordExample(thai: "น้ำหมดแล้ว", romanization: "náam mòt láew", english: "The water is finished.", hindi: "पानी ख़त्म हो गया।"),
        ],
        664: [
            WordExample(thai: "แนะนำอะไรดีครับ", romanization: "náe-nam à-rai dii kráp", english: "What do you recommend?", hindi: "आप क्या सुझाव देंगे?"),
            WordExample(thai: "ผมแนะนำต้มยำ", romanization: "pǒm náe-nam tôm-yam", english: "I recommend tom yum.", hindi: "मैं टॉम यम की सिफ़ारिश करता हूँ।"),
        ],
        665: [
            WordExample(thai: "ขอข้าวผัดพิเศษ", romanization: "kǒr kâao-pàt pí-sèet", english: "Fried rice, extra large, please.", hindi: "स्पेशल फ्राइड राइस दीजिए।"),
            WordExample(thai: "วันนี้มีเมนูพิเศษ", romanization: "wan-níi mii mee-nuu pí-sèet", english: "Today there is a special menu.", hindi: "आज स्पेशल मेन्यू है।"),
        ],
        666: [
            WordExample(thai: "เอาธรรมดาครับ", romanization: "ao tam-má-daa kráp", english: "The regular one, please.", hindi: "नॉर्मल वाला दीजिए।"),
            WordExample(thai: "อันนี้ธรรมดาหรือพิเศษ", romanization: "an-níi tam-má-daa rǔe pí-sèet", english: "Is this regular or special?", hindi: "यह नॉर्मल है या स्पेशल?"),
        ],
        667: [
            WordExample(thai: "ห่อกลับบ้านครับ", romanization: "hòr klàp bâan kráp", english: "Wrap it to take home, please.", hindi: "पैक कर दीजिए, घर ले जाना है।"),
            WordExample(thai: "ห่อได้ไหมคะ", romanization: "hòr dâai mǎi ká", english: "Can you wrap it?", hindi: "क्या पैक कर सकते हैं?"),
        ],
        668: [
            WordExample(thai: "รับเครื่องดื่มอะไรคะ", romanization: "ráp krûeang-dùuem à-rai ká", english: "What drink would you like?", hindi: "आप कौन-सा पेय लेंगे?"),
            WordExample(thai: "เครื่องดื่มอยู่ที่นี่", romanization: "krûeang-dùuem yùu tîi-nîi", english: "The drinks are here.", hindi: "पेय यहाँ हैं।"),
        ],
        669: [
            WordExample(thai: "กินอาหารเย็นกันไหม", romanization: "kin aa-hǎan-yen kan mǎi", english: "Shall we have dinner together?", hindi: "साथ में रात का खाना खाएँ?"),
            WordExample(thai: "อาหารเย็นวันนี้อร่อย", romanization: "aa-hǎan-yen wan-níi à-ròi", english: "Tonight's dinner is delicious.", hindi: "आज का रात का खाना स्वादिष्ट है।"),
        ],
        670: [
            WordExample(thai: "กินอาหารกลางวันหรือยัง", romanization: "kin aa-hǎan-klaang-wan rǔe-yang", english: "Have you had lunch yet?", hindi: "क्या आपने दोपहर का खाना खाया?"),
            WordExample(thai: "อาหารกลางวันที่นี่ถูก", romanization: "aa-hǎan-klaang-wan tîi-nîi tùuk", english: "Lunch here is cheap.", hindi: "यहाँ दोपहर का खाना सस्ता है।"),
        ],
        671: [
            WordExample(thai: "คุณชอบอาหารทะเลไหม", romanization: "kun chôp aa-hǎan-tá-lee mǎi", english: "Do you like seafood?", hindi: "क्या आपको सीफ़ूड पसंद है?"),
            WordExample(thai: "อาหารทะเลที่นี่สดมาก", romanization: "aa-hǎan-tá-lee thîi-nîi sòt mâak", english: "The seafood here is very fresh.", hindi: "यहाँ का सीफ़ूड बहुत ताज़ा है।"),
        ],
        672: [
            WordExample(thai: "แม่ค้าขายส้มตำ", romanization: "mâe-kháa khǎai sôm-tam", english: "The vendor sells papaya salad.", hindi: "दुकानदारनी सोम-तम बेचती है।"),
            WordExample(thai: "แม่ค้าอยู่ที่ตลาด", romanization: "mâe-kháa yùu thîi tà-làat", english: "The vendor is at the market.", hindi: "दुकानदारनी बाज़ार में है।"),
        ],
        673: [
            WordExample(thai: "พ่อค้าขายไก่ย่าง", romanization: "phôo-kháa khǎai kài-yâang", english: "The vendor sells grilled chicken.", hindi: "दुकानदार ग्रिल्ड चिकन बेचता है।"),
            WordExample(thai: "พ่อค้าคนนี้ขายถูก", romanization: "phôo-kháa khon níi khǎai thùuk", english: "This vendor sells cheap.", hindi: "यह दुकानदार सस्ता बेचता है।"),
        ],
        674: [
            WordExample(thai: "วันนี้มีลูกค้ามาก", romanization: "wan-níi mii lûuk-kháa mâak", english: "Today there are many customers.", hindi: "आज ग्राहक बहुत हैं।"),
            WordExample(thai: "ลูกค้าชอบร้านนี้", romanization: "lûuk-kháa châawp ráan níi", english: "Customers like this shop.", hindi: "ग्राहक यह दुकान पसंद करते हैं।"),
        ],
        675: [
            WordExample(thai: "หมูกิโลเท่าไหร่", romanization: "mǔu kì-loo thâo-rài", english: "How much is a kilo of pork?", hindi: "पोर्क किलो कितने का है?"),
            WordExample(thai: "ขอหนึ่งกิโลครับ", romanization: "khǒo nùeng kì-loo khráp", english: "One kilo, please.", hindi: "एक किलो दीजिए।"),
        ],
        676: [
            WordExample(thai: "ขอหมูสองขีด", romanization: "khǒo mǔu sǎawng khìit", english: "200 grams of pork, please.", hindi: "दो सौ ग्राम पोर्क दीजिए।"),
            WordExample(thai: "หนึ่งขีดยี่สิบบาท", romanization: "nùeng khìit yîi-sìp bàat", english: "One khiit is twenty baht.", hindi: "सौ ग्राम बीस बात का है।"),
        ],
        677: [
            WordExample(thai: "ขอไข่หนึ่งโหล", romanization: "khǒo khài nùeng lǒo", english: "A dozen eggs, please.", hindi: "एक दर्जन अंडे दीजिए।"),
            WordExample(thai: "หนึ่งโหลมีสิบสองอัน", romanization: "nùeng lǒo mii sìp-sǎawng an", english: "One dozen has twelve pieces.", hindi: "एक दर्जन में बारह होते हैं।"),
        ],
        678: [
            WordExample(thai: "แถมหนึ่งอันได้ไหม", romanization: "thǎem nùeng an dâi mái", english: "Can you throw in one free?", hindi: "एक मुफ़्त दे सकते हैं?"),
            WordExample(thai: "แม่ค้าแถมส้มตำให้", romanization: "mâe-kháa thǎem sôm-tam hâi", english: "The vendor threw in papaya salad free.", hindi: "दुकानदारनी ने सोम-तम मुफ़्त दिया।"),
        ],
        679: [
            WordExample(thai: "ลดได้ไหมครับ", romanization: "lót dâi mái khráp", english: "Can you lower it?", hindi: "क्या कम कर सकते हैं?"),
            WordExample(thai: "ลดสิบบาทได้ไหม", romanization: "lót sìp bàat dâi mái", english: "Can you reduce it by ten baht?", hindi: "दस बात कम कर सकते हैं?"),
        ],
        680: [
            WordExample(thai: "คิดเงินด้วยครับ", romanization: "khít-ngoen dûai khráp", english: "The bill, please.", hindi: "बिल कर दीजिए।"),
        ],
        681: [
            WordExample(thai: "แลกแบงค์ได้ไหม", romanization: "lâek báeng dâi mái", english: "Can you break a banknote?", hindi: "क्या नोट का छुट्टा मिल सकता है?"),
            WordExample(thai: "ขอแลกเงินหน่อย", romanization: "khǒo lâek ngoen nòi", english: "I would like to exchange money.", hindi: "ज़रा पैसे बदल दीजिए।"),
        ],
        682: [
            WordExample(thai: "ฉันมีเหรียญสิบบาท", romanization: "chǎn mii rǐan sìp bàat", english: "I have a ten-baht coin.", hindi: "मेरे पास दस बात का सिक्का है।"),
            WordExample(thai: "มีเหรียญไหมครับ", romanization: "mii rǐan mái khráp", english: "Do you have coins?", hindi: "क्या सिक्के हैं?"),
        ],
        683: [
            WordExample(thai: "มีแบงค์ร้อยไหม", romanization: "mii báeng rói mái", english: "Do you have a hundred note?", hindi: "क्या सौ का नोट है?"),
            WordExample(thai: "แบงค์นี้ใช้ได้ไหม", romanization: "báeng níi chái dâi mái", english: "Can this note be used?", hindi: "क्या यह नोट चलेगा?"),
        ],
        684: [
            WordExample(thai: "ฉันชอบไปตลาดนัด", romanization: "chǎn châawp pai tà-làat-nát", english: "I like going to the flea market.", hindi: "मुझे साप्ताहिक बाज़ार जाना पसंद है।"),
            WordExample(thai: "ตลาดนัดขายถูกมาก", romanization: "tà-làat-nát khǎai thùuk mâak", english: "The flea market sells very cheap.", hindi: "साप्ताहिक बाज़ार में बहुत सस्ता मिलता है।"),
        ],
        685: [
            WordExample(thai: "ตลาดน้ำอยู่ที่ไหน", romanization: "tà-làat-nám yùu thîi-nǎi", english: "Where is the floating market?", hindi: "फ़्लोटिंग मार्केट कहाँ है?"),
            WordExample(thai: "ฉันอยากไปตลาดน้ำ", romanization: "chǎn yàak pai tà-làat-nám", english: "I want to go to the floating market.", hindi: "मैं फ़्लोटिंग मार्केट जाना चाहती हूँ।"),
        ],
        686: [
            WordExample(thai: "ฉันซื้อของฝากที่ตลาด", romanization: "chǎn súue khǒong-fàak thîi tà-làat", english: "I buy souvenirs at the market.", hindi: "मैं बाज़ार से सौगात खरीदती हूँ।"),
            WordExample(thai: "ของฝากร้านนี้ดีมาก", romanization: "khǒong-fàak ráan níi dii mâak", english: "This shop's souvenirs are very good.", hindi: "इस दुकान की सौगात बहुत अच्छी है।"),
        ],
        687: [
            WordExample(thai: "แผงลอยขายส้มตำ", romanization: "phǎeng-laawy khǎai sôm-tam", english: "The stall sells papaya salad.", hindi: "स्टॉल पर सोम-तम बिकता है।"),
            WordExample(thai: "ที่นี่มีแผงลอยมาก", romanization: "thîi-nîi mii phǎeng-laawy mâak", english: "There are many stalls here.", hindi: "यहाँ बहुत स्टॉल हैं।"),
        ],
        688: [
            WordExample(thai: "ไก่ย่างกับข้าวเหนียว", romanization: "kài-yâang kàp khâao-nǐao", english: "Grilled chicken with sticky rice.", hindi: "ग्रिल्ड चिकन और स्टिकी राइस।"),
            WordExample(thai: "ฉันชอบกินไก่ย่าง", romanization: "chǎn châawp kin kài-yâang", english: "I like eating grilled chicken.", hindi: "मुझे ग्रिल्ड चिकन खाना पसंद है।"),
        ],
        689: [
            WordExample(thai: "อันนี้เท่าไหร่ครับ", romanization: "an-níi thâo-rài khráp", english: "How much is this one?", hindi: "यह वाला कितने का है?"),
            WordExample(thai: "ฉันเอาอันนี้", romanization: "chǎn ao an-níi", english: "I will take this one.", hindi: "मैं यह वाला लूँगी।"),
        ],
        690: [
            WordExample(thai: "อันไหนอร่อย", romanization: "an-nǎi à-ròi", english: "Which one is tasty?", hindi: "कौन-सा वाला स्वादिष्ट है?"),
            WordExample(thai: "คุณชอบอันไหน", romanization: "khun châawp an-nǎi", english: "Which one do you like?", hindi: "आपको कौन-सा पसंद है?"),
        ],
        691: [
            WordExample(thai: "ฉันไปซื้อของที่ตลาด", romanization: "chǎn pai súue-khǒong thîi tà-làat", english: "I go shopping at the market.", hindi: "मैं बाज़ार में ख़रीदारी करने जाती हूँ।"),
            WordExample(thai: "วันนี้ไปซื้อของไหม", romanization: "wan-níi pai súue-khǒong mái", english: "Going shopping today?", hindi: "आज ख़रीदारी करने चलें?"),
        ],
        692: [
            WordExample(thai: "ราคานี้คุ้มมาก", romanization: "raa-khaa níi khúm mâak", english: "This price is great value.", hindi: "यह दाम बहुत वसूल है।"),
            WordExample(thai: "ซื้อที่นี่คุ้มมาก", romanization: "súue thîi-nîi khúm mâak", english: "Buying here is worth it.", hindi: "यहाँ खरीदना पैसा वसूल है।"),
        ],
        // Batch 3
        693: [
            WordExample(thai: "ปู่อยู่ที่บ้าน", romanization: "pùu yùu tîi bâan", english: "Grandpa is at home", hindi: "दादा घर पर हैं"),
            WordExample(thai: "ปู่ใจดีมาก", romanization: "pùu jai-dii mâak", english: "Grandpa is very kind", hindi: "दादा बहुत दयालु हैं"),
        ],
        694: [
            WordExample(thai: "ย่าอยู่ที่นี่ค่ะ", romanization: "yâa yùu tîi nîi kâ", english: "Grandma is here", hindi: "दादी यहाँ हैं"),
            WordExample(thai: "ฉันรักย่ามาก", romanization: "chǎn rák yâa mâak", english: "I love grandma very much", hindi: "मैं दादी से बहुत प्यार करती हूँ"),
        ],
        695: [
            WordExample(thai: "ยายมาที่นี่ค่ะ", romanization: "yaai maa tîi nîi kâ", english: "Grandma comes here", hindi: "नानी यहाँ आती हैं"),
            WordExample(thai: "ฉันรักยายมาก", romanization: "chǎn rák yaai mâak", english: "I love grandma very much", hindi: "मैं नानी से बहुत प्यार करती हूँ"),
        ],
        696: [
            WordExample(thai: "ลุงมาบ้านผม", romanization: "lung maa bâan pǒm", english: "Uncle comes to my house", hindi: "ताऊ मेरे घर आते हैं"),
            WordExample(thai: "ลุงใจดีมาก", romanization: "lung jai-dii mâak", english: "Uncle is very kind", hindi: "ताऊ बहुत दयालु हैं"),
        ],
        697: [
            WordExample(thai: "ป้าอยู่ที่บ้าน", romanization: "pâa yùu tîi bâan", english: "Auntie is at home", hindi: "ताई घर पर हैं"),
            WordExample(thai: "ฉันชอบป้ามาก", romanization: "chǎn chôp pâa mâak", english: "I like auntie a lot", hindi: "मुझे ताई बहुत पसंद हैं"),
        ],
        698: [
            WordExample(thai: "น้าอยู่ที่นี่", romanization: "náa yùu tîi nîi", english: "Uncle is here", hindi: "मामा यहाँ हैं"),
            WordExample(thai: "น้าใจดีมาก", romanization: "náa jai-dii mâak", english: "Uncle is very kind", hindi: "मामा बहुत दयालु हैं"),
        ],
        699: [
            WordExample(thai: "อาไม่อยู่ครับ", romanization: "aa mâi yùu kráp", english: "Uncle is not in", hindi: "चाचा घर पर नहीं हैं"),
            WordExample(thai: "อาใจดีมาก", romanization: "aa jai-dii mâak", english: "Uncle is very kind", hindi: "चाचा बहुत दयालु हैं"),
        ],
        700: [
            WordExample(thai: "สามีฉันไม่อยู่ค่ะ", romanization: "sǎa-mii chǎn mâi yùu kâ", english: "My husband is not in", hindi: "मेरे पति घर पर नहीं हैं"),
            WordExample(thai: "สามีฉันใจดีมาก", romanization: "sǎa-mii chǎn jai-dii mâak", english: "My husband is very kind", hindi: "मेरे पति बहुत दयालु हैं"),
        ],
        701: [
            WordExample(thai: "ภรรยาผมอยู่ที่บ้าน", romanization: "pan-rá-yaa pǒm yùu tîi bâan", english: "My wife is at home", hindi: "मेरी पत्नी घर पर हैं"),
            WordExample(thai: "ผมรักภรรยามาก", romanization: "pǒm rák pan-rá-yaa mâak", english: "I love my wife very much", hindi: "मैं अपनी पत्नी से बहुत प्यार करता हूँ"),
        ],
        702: [
            WordExample(thai: "คุณมีแฟนไหม", romanization: "kun mii faen mǎi", english: "Do you have a partner?", hindi: "क्या आपका कोई प्रेमी या प्रेमिका है?"),
            WordExample(thai: "แฟนผมใจดีมาก", romanization: "faen pǒm jai-dii mâak", english: "My girlfriend is very kind", hindi: "मेरी प्रेमिका बहुत दयालु है"),
        ],
        703: [
            WordExample(thai: "ผมมีลูกชายสองคน", romanization: "pǒm mii lûuk-chaai sǒng kon", english: "I have two sons", hindi: "मेरे दो बेटे हैं"),
            WordExample(thai: "ลูกชายอยู่ที่บ้าน", romanization: "lûuk-chaai yùu tîi bâan", english: "My son is at home", hindi: "बेटा घर पर है"),
        ],
        704: [
            WordExample(thai: "ฉันมีลูกสาวสองคน", romanization: "chǎn mii lûuk-sǎao sǒng kon", english: "I have two daughters", hindi: "मेरी दो बेटियाँ हैं"),
            WordExample(thai: "ลูกสาวฉันน่ารักมาก", romanization: "lûuk-sǎao chǎn nâa-rák mâak", english: "My daughter is very cute", hindi: "मेरी बेटी बहुत प्यारी है"),
        ],
        705: [
            WordExample(thai: "ผมมีพี่ชายสองคน", romanization: "pǒm mii pîi-chaai sǒng kon", english: "I have two older brothers", hindi: "मेरे दो बड़े भाई हैं"),
            WordExample(thai: "พี่ชายใจดีมาก", romanization: "pîi-chaai jai-dii mâak", english: "My older brother is very kind", hindi: "बड़ा भाई बहुत दयालु है"),
        ],
        706: [
            WordExample(thai: "พี่สาวอยู่ที่บ้าน", romanization: "pîi-sǎao yùu tîi bâan", english: "My older sister is at home", hindi: "बड़ी बहन घर पर है"),
            WordExample(thai: "ฉันรักพี่สาวมาก", romanization: "chǎn rák pîi-sǎao mâak", english: "I love my older sister very much", hindi: "मैं अपनी बड़ी बहन से बहुत प्यार करती हूँ"),
        ],
        707: [
            WordExample(thai: "น้องชายอยู่ที่นี่", romanization: "nóng-chaai yùu tîi nîi", english: "My younger brother is here", hindi: "छोटा भाई यहाँ है"),
            WordExample(thai: "ผมมีน้องชายสองคน", romanization: "pǒm mii nóng-chaai sǒng kon", english: "I have two younger brothers", hindi: "मेरे दो छोटे भाई हैं"),
        ],
        708: [
            WordExample(thai: "น้องสาวฉันน่ารักมาก", romanization: "nóng-sǎao chǎn nâa-rák mâak", english: "My younger sister is very cute", hindi: "मेरी छोटी बहन बहुत प्यारी है"),
            WordExample(thai: "น้องสาวไม่อยู่ค่ะ", romanization: "nóng-sǎao mâi yùu kâ", english: "My younger sister is not in", hindi: "छोटी बहन घर पर नहीं है"),
        ],
        709: [
            WordExample(thai: "หลานน่ารักมาก", romanization: "lǎan nâa-rák mâak", english: "The grandchild is very cute", hindi: "पोता बहुत प्यारा है"),
            WordExample(thai: "ยายรักหลานมาก", romanization: "yaai rák lǎan mâak", english: "Grandma loves her grandchildren very much", hindi: "नानी पोते-पोतियों से बहुत प्यार करती हैं"),
        ],
        710: [
            WordExample(thai: "ญาติมาที่บ้าน", romanization: "yâat maa tîi bâan", english: "Relatives come to the house", hindi: "रिश्तेदार घर आते हैं"),
            WordExample(thai: "ญาติผมอยู่ที่นี่", romanization: "yâat pǒm yùu tîi nîi", english: "My relatives live here", hindi: "मेरे रिश्तेदार यहाँ रहते हैं"),
        ],
        711: [
            WordExample(thai: "ผมรักพ่อแม่มาก", romanization: "pǒm rák pôr-mâe mâak", english: "I love my parents very much", hindi: "मैं माता-पिता से बहुत प्यार करता हूँ"),
            WordExample(thai: "พ่อแม่อยู่ที่บ้าน", romanization: "pôr-mâe yùu tîi bâan", english: "My parents are at home", hindi: "माता-पिता घर पर हैं"),
        ],
        712: [
            WordExample(thai: "คุณมีพี่น้องไหม", romanization: "kun mii pîi-nóng mǎi", english: "Do you have siblings?", hindi: "क्या आपके भाई-बहन हैं?"),
            WordExample(thai: "ผมมีพี่น้องสองคน", romanization: "pǒm mii pîi-nóng sǒng kon", english: "I have two siblings", hindi: "मेरे दो भाई-बहन हैं"),
        ],
        713: [
            WordExample(thai: "เขามีลูกฝาแฝด", romanization: "kǎo mii lûuk fǎa-fàet", english: "They have twin children", hindi: "उनके जुड़वाँ बच्चे हैं"),
            WordExample(thai: "ฝาแฝดน่ารักมาก", romanization: "fǎa-fàet nâa-rák mâak", english: "The twins are very cute", hindi: "जुड़वाँ बहुत प्यारे हैं"),
        ],
        714: [
            WordExample(thai: "เขาเป็นลูกพี่ลูกน้องผม", romanization: "kǎo pen lûuk-pîi-lûuk-nóng pǒm", english: "He is my cousin", hindi: "वह मेरा कज़िन है"),
            WordExample(thai: "ลูกพี่ลูกน้องมาที่บ้าน", romanization: "lûuk-pîi-lûuk-nóng maa tîi bâan", english: "My cousins come to the house", hindi: "कज़िन घर आते हैं"),
        ],
        715: [
            WordExample(thai: "เมียผมอยู่ที่บ้าน", romanization: "mia pǒm yùu tîi bâan", english: "My wife is at home", hindi: "मेरी बीवी घर पर है"),
            WordExample(thai: "ผมรักเมียมาก", romanization: "pǒm rák mia mâak", english: "I love my wife very much", hindi: "मैं अपनी बीवी से बहुत प्यार करता हूँ"),
        ],
        716: [
            WordExample(thai: "ผัวฉันไม่อยู่ค่ะ", romanization: "pǔa chǎn mâi yùu kâ", english: "My husband is not in", hindi: "मेरे पति घर पर नहीं हैं"),
            WordExample(thai: "ผัวฉันใจดีมาก", romanization: "pǔa chǎn jai-dii mâak", english: "My husband is very kind", hindi: "मेरे पति बहुत दयालु हैं"),
        ],
        717: [
            WordExample(thai: "เขาแต่งงานแล้ว", romanization: "kǎo tàeng-ngaan láew", english: "He is already married", hindi: "उसकी शादी हो चुकी है"),
            WordExample(thai: "ผมแต่งงานแล้วครับ", romanization: "pǒm tàeng-ngaan láew kráp", english: "I am married", hindi: "मेरी शादी हो चुकी है"),
        ],
        718: [
            WordExample(thai: "พ่อตาใจดีมาก", romanization: "pôr-taa jai-dii mâak", english: "My father-in-law is very kind", hindi: "ससुर बहुत दयालु हैं"),
            WordExample(thai: "พ่อตาอยู่ที่บ้าน", romanization: "pôr-taa yùu tîi bâan", english: "My father-in-law is at home", hindi: "ससुर घर पर हैं"),
        ],
        719: [
            WordExample(thai: "แม่ยายมาที่บ้าน", romanization: "mâe-yaai maa tîi bâan", english: "My mother-in-law comes to the house", hindi: "सास घर आती हैं"),
            WordExample(thai: "แม่ยายใจดีมาก", romanization: "mâe-yaai jai-dii mâak", english: "My mother-in-law is very kind", hindi: "सास बहुत दयालु हैं"),
        ],
        720: [
            WordExample(thai: "เธอเป็นเพื่อนฉัน", romanization: "ter pen pʉ̂an chǎn", english: "She is my friend.", hindi: "वह मेरी दोस्त है।"),
            WordExample(thai: "เธอชื่ออะไร", romanization: "ter chʉ̂ʉ à-rai", english: "What is your name?", hindi: "तुम्हारा नाम क्या है?"),
        ],
        721: [
            WordExample(thai: "พวกเขาอยู่ที่นี่", romanization: "pûak-kǎo yùu tîi nîi", english: "They are here.", hindi: "वे यहाँ हैं।"),
            WordExample(thai: "พวกเขาเป็นเพื่อนผม", romanization: "pûak-kǎo pen pʉ̂an pǒm", english: "They are my friends.", hindi: "वे मेरे दोस्त हैं।"),
        ],
        722: [
            WordExample(thai: "เขาเป็นเพื่อนสนิทผม", romanization: "kǎo pen pʉ̂an-sà-nìt pǒm", english: "He is my close friend.", hindi: "वह मेरा पक्का दोस्त है।"),
            WordExample(thai: "ฉันมีเพื่อนสนิทสองคน", romanization: "chǎn mii pʉ̂an-sà-nìt sɔ̌ɔng kon", english: "I have two close friends.", hindi: "मेरे दो पक्के दोस्त हैं।"),
        ],
        723: [
            WordExample(thai: "เขาเป็นคนไทย", romanization: "kǎo pen kon-tai", english: "He is Thai.", hindi: "वह थाई है।"),
            WordExample(thai: "คนไทยใจดีมาก", romanization: "kon-tai jai-dii mâak", english: "Thai people are very kind.", hindi: "थाई लोग बहुत दयालु होते हैं।"),
        ],
        724: [
            WordExample(thai: "วันนี้มีแขกมาบ้าน", romanization: "wan-níi mii kɛ̀ɛk maa bâan", english: "Guests came to the house today.", hindi: "आज घर मेहमान आए हैं।"),
            WordExample(thai: "แขกกินข้าวแล้ว", romanization: "kɛ̀ɛk kin kâao lɛ́ɛo", english: "The guests have eaten.", hindi: "मेहमान खाना खा चुके हैं।"),
        ],
        725: [
            WordExample(thai: "เขาเป็นผู้ใหญ่แล้ว", romanization: "kǎo pen pûu-yài lɛ́ɛo", english: "He is an adult now.", hindi: "वह अब बड़ा हो गया है।"),
            WordExample(thai: "ผู้ใหญ่อยู่ที่บ้าน", romanization: "pûu-yài yùu tîi bâan", english: "The adults are at home.", hindi: "बड़े लोग घर पर हैं।"),
        ],
        726: [
            WordExample(thai: "เขาเป็นวัยรุ่น", romanization: "kǎo pen wai-rûn", english: "He is a teenager.", hindi: "वह किशोर है।"),
            WordExample(thai: "วัยรุ่นชอบมาที่นี่", romanization: "wai-rûn chɔ̂ɔp maa tîi nîi", english: "Teenagers like coming here.", hindi: "किशोरों को यहाँ आना पसंद है।"),
        ],
        727: [
            WordExample(thai: "ทุกคนมาแล้ว", romanization: "túk-kon maa lɛ́ɛo", english: "Everyone has arrived.", hindi: "सब लोग आ गए हैं।"),
            WordExample(thai: "ทุกคนสบายดี", romanization: "túk-kon sà-baai-dii", english: "Everyone is fine.", hindi: "सब लोग ठीक हैं।"),
        ],
        728: [
            WordExample(thai: "ยินดีที่ได้รู้จัก", romanization: "yin-dii tîi dâai rúu-jàk", english: "Nice to meet you.", hindi: "आपसे मिलकर खुशी हुई।"),
            WordExample(thai: "ผมยินดีมาก", romanization: "pǒm yin-dii mâak", english: "I am very glad.", hindi: "मैं बहुत खुश हूँ।"),
        ],
        729: [
            WordExample(thai: "ยินดีที่ได้พบคุณ", romanization: "yin-dii tîi dâai póp kun", english: "Glad to meet you.", hindi: "आपसे मिलकर खुशी हुई।"),
            WordExample(thai: "เราพบกันที่นี่", romanization: "rao póp kan tîi nîi", english: "We meet here.", hindi: "हम यहाँ मिलते हैं।"),
        ],
        730: [
            WordExample(thai: "คุณรู้จักเขาไหม", romanization: "kun rúu-jàk kǎo mǎi", english: "Do you know him?", hindi: "क्या तुम उसे जानते हो?"),
            WordExample(thai: "ผมรู้จักเขาดี", romanization: "pǒm rúu-jàk kǎo dii", english: "I know him well.", hindi: "मैं उसे अच्छी तरह जानता हूँ।"),
        ],
        731: [
            WordExample(thai: "เพื่อนชวนผมไปกินข้าว", romanization: "pʉ̂an chuan pǒm pai kin kâao", english: "My friend invited me to eat.", hindi: "दोस्त ने मुझे खाने पर बुलाया।"),
            WordExample(thai: "ฉันชวนเขามาบ้าน", romanization: "chǎn chuan kǎo maa bâan", english: "I invited him home.", hindi: "मैंने उसे घर बुलाया।"),
        ],
        732: [
            WordExample(thai: "เรานัดเจอกันวันนี้", romanization: "rao nát jer kan wan-níi", english: "We arranged to meet today.", hindi: "हमने आज मिलना तय किया।"),
            WordExample(thai: "ผมมีนัดกับเพื่อน", romanization: "pǒm mii nát kàp pʉ̂an", english: "I have a meet-up with a friend.", hindi: "मेरी दोस्त से मिलने की योजना है।"),
        ],
        733: [
            WordExample(thai: "เขายิ้มให้ฉัน", romanization: "kǎo yím hâi chǎn", english: "He smiled at me.", hindi: "वह मुझे देखकर मुस्कुराया।"),
            WordExample(thai: "คนไทยชอบยิ้ม", romanization: "kon-tai chɔ̂ɔp yím", english: "Thai people like to smile.", hindi: "थाई लोग मुस्कुराना पसंद करते हैं।"),
        ],
        734: [
            WordExample(thai: "คืนนี้มีปาร์ตี้", romanization: "kʉʉn-níi mii paa-tîi", english: "There is a party tonight.", hindi: "आज रात पार्टी है।"),
            WordExample(thai: "ไปปาร์ตี้กันไหม", romanization: "pai paa-tîi kan mǎi", english: "Shall we go to the party?", hindi: "पार्टी चलें क्या?"),
        ],
        735: [
            WordExample(thai: "ฉันเป็นพยาบาลค่ะ", romanization: "chǎn pen phá-yaa-baan khâ", english: "I am a nurse", hindi: "मैं नर्स हूँ"),
            WordExample(thai: "พยาบาลใจดีมาก", romanization: "phá-yaa-baan jai-dii mâak", english: "The nurse is very kind", hindi: "नर्स बहुत दयालु है"),
        ],
        736: [
            WordExample(thai: "พ่อเป็นทหาร", romanization: "phôr pen thá-hǎan", english: "Father is a soldier", hindi: "पिता सैनिक हैं"),
            WordExample(thai: "ทหารมาที่นี่", romanization: "thá-hǎan maa thîi-nîi", english: "The soldier comes here", hindi: "सैनिक यहाँ आता है"),
        ],
        737: [
            WordExample(thai: "ผมเป็นนักเรียน", romanization: "phǒm pen nák-rian", english: "I am a student", hindi: "मैं विद्यार्थी हूँ"),
            WordExample(thai: "นักเรียนไปโรงเรียน", romanization: "nák-rian pai roong-rian", english: "The student goes to school", hindi: "विद्यार्थी स्कूल जाता है"),
        ],
        738: [
            WordExample(thai: "เขาเป็นนักศึกษา", romanization: "khǎo pen nák-sùek-sǎa", english: "He is a university student", hindi: "वह कॉलेज का विद्यार्थी है"),
            WordExample(thai: "นักศึกษาอยู่ที่นี่", romanization: "nák-sùek-sǎa yùu thîi-nîi", english: "The students are here", hindi: "विद्यार्थी यहाँ हैं"),
        ],
        739: [
            WordExample(thai: "อาจารย์ใจดีมาก", romanization: "aa-jaan jai-dii mâak", english: "The professor is very kind", hindi: "प्रोफेसर बहुत दयालु हैं"),
            WordExample(thai: "เขาเป็นอาจารย์", romanization: "khǎo pen aa-jaan", english: "He is a professor", hindi: "वह प्रोफेसर है"),
        ],
        740: [
            WordExample(thai: "เขาเป็นคนขับรถ", romanization: "khǎo pen khon-khàp-rót", english: "He is a driver", hindi: "वह ड्राइवर है"),
            WordExample(thai: "คนขับรถมาแล้ว", romanization: "khon-khàp-rót maa láew", english: "The driver has come", hindi: "ड्राइवर आ गया"),
        ],
        741: [
            WordExample(thai: "ชาวนาทำงานมาก", romanization: "chaao-naa tham-ngaan mâak", english: "Farmers work a lot", hindi: "किसान बहुत काम करते हैं"),
            WordExample(thai: "เขาเป็นชาวนา", romanization: "khǎo pen chaao-naa", english: "He is a farmer", hindi: "वह किसान है"),
        ],
        742: [
            WordExample(thai: "พ่อครัวทำอาหารอร่อย", romanization: "phôr-khrua tham aa-hǎan à-ròi", english: "The cook makes delicious food", hindi: "रसोइया स्वादिष्ट खाना बनाता है"),
            WordExample(thai: "เขาเป็นพ่อครัว", romanization: "khǎo pen phôr-khrua", english: "He is a cook", hindi: "वह रसोइया है"),
        ],
        743: [
            WordExample(thai: "ผมไปหาหมอฟัน", romanization: "phǒm pai hǎa mǒr-fan", english: "I go to the dentist", hindi: "मैं दाँतों के डॉक्टर के पास जाता हूँ"),
            WordExample(thai: "หมอฟันใจดีมาก", romanization: "mǒr-fan jai-dii mâak", english: "The dentist is very kind", hindi: "दाँतों का डॉक्टर बहुत दयालु है"),
        ],
        744: [
            WordExample(thai: "เขาเป็นวิศวกร", romanization: "khǎo pen wít-sà-wá-kon", english: "He is an engineer", hindi: "वह इंजीनियर है"),
            WordExample(thai: "วิศวกรทำงานที่นี่", romanization: "wít-sà-wá-kon tham-ngaan thîi-nîi", english: "The engineer works here", hindi: "इंजीनियर यहाँ काम करता है"),
        ],
        745: [
            WordExample(thai: "เขาเป็นนักธุรกิจ", romanization: "khǎo pen nák-thú-rá-kìt", english: "He is a businessman", hindi: "वह व्यापारी है"),
            WordExample(thai: "นักธุรกิจคนนี้รวยมาก", romanization: "nák-thú-rá-kìt khon-níi ruai mâak", english: "This businessman is very rich", hindi: "यह व्यापारी बहुत अमीर है"),
        ],
        746: [
            WordExample(thai: "ฉันชอบนักร้องคนนี้", romanization: "chǎn chôrp nák-róng khon-níi", english: "I like this singer", hindi: "मुझे यह गायक पसंद है"),
            WordExample(thai: "เขาเป็นนักร้อง", romanization: "khǎo pen nák-róng", english: "He is a singer", hindi: "वह गायक है"),
        ],
        747: [
            WordExample(thai: "เขาเป็นนักแสดง", romanization: "khǎo pen nák-sà-daeng", english: "He is an actor", hindi: "वह अभिनेता है"),
            WordExample(thai: "ฉันชอบนักแสดงคนนี้", romanization: "chǎn chôrp nák-sà-daeng khon-níi", english: "I like this actor", hindi: "मुझे यह अभिनेता पसंद है"),
        ],
        748: [
            WordExample(thai: "เขาเป็นนักกีฬา", romanization: "khǎo pen nák-kii-laa", english: "He is an athlete", hindi: "वह खिलाड़ी है"),
            WordExample(thai: "นักกีฬากินมาก", romanization: "nák-kii-laa kin mâak", english: "Athletes eat a lot", hindi: "खिलाड़ी बहुत खाते हैं"),
        ],
        749: [
            WordExample(thai: "เขาเป็นนักเขียน", romanization: "khǎo pen nák-khǐan", english: "He is a writer", hindi: "वह लेखक है"),
            WordExample(thai: "นักเขียนคนนี้ดีมาก", romanization: "nák-khǐan khon-níi dii mâak", english: "This writer is very good", hindi: "यह लेखक बहुत अच्छा है"),
        ],
        750: [
            WordExample(thai: "ช่างมาแล้ว", romanization: "châang maa láew", english: "The technician has come", hindi: "मिस्त्री आ गया"),
            WordExample(thai: "เขาเป็นช่าง", romanization: "khǎo pen châang", english: "He is a technician", hindi: "वह मिस्त्री है"),
        ],
        751: [
            WordExample(thai: "ผมไปหาช่างตัดผม", romanization: "phǒm pai hǎa châang-tàt-phǒm", english: "I go to the barber", hindi: "मैं नाई के पास जाता हूँ"),
            WordExample(thai: "ช่างตัดผมอยู่ที่นี่", romanization: "châang-tàt-phǒm yùu thîi-nîi", english: "The barber is here", hindi: "नाई यहाँ है"),
        ],
        752: [
            WordExample(thai: "เขาเป็นนักบิน", romanization: "khǎo pen nák-bin", english: "He is a pilot", hindi: "वह पायलट है"),
            WordExample(thai: "นักบินไม่อยู่ที่นี่", romanization: "nák-bin mâi yùu thîi-nîi", english: "The pilot is not here", hindi: "पायलट यहाँ नहीं है"),
        ],
        753: [
            WordExample(thai: "แม่เป็นแม่บ้าน", romanization: "mâe pen mâe-bâan", english: "Mother is a housewife", hindi: "माँ गृहिणी हैं"),
            WordExample(thai: "แม่บ้านทำงานมาก", romanization: "mâe-bâan tham-ngaan mâak", english: "The housekeeper works a lot", hindi: "गृहिणी बहुत काम करती है"),
        ],
        754: [
            WordExample(thai: "ยามอยู่ที่นี่", romanization: "yaam yùu thîi-nîi", english: "The guard is here", hindi: "चौकीदार यहाँ है"),
            WordExample(thai: "เขาเป็นยาม", romanization: "khǎo pen yaam", english: "He is a guard", hindi: "वह चौकीदार है"),
        ],
        755: [
            WordExample(thai: "คนงานทำงานมาก", romanization: "khon-ngaan tham-ngaan mâak", english: "The workers work a lot", hindi: "मज़दूर बहुत काम करते हैं"),
            WordExample(thai: "คนงานมาแล้ว", romanization: "khon-ngaan maa láew", english: "The workers have come", hindi: "मज़दूर आ गए"),
        ],
        756: [
            WordExample(thai: "เจ้านายใจดีมาก", romanization: "jâo-naai jai-dii mâak", english: "The boss is very kind", hindi: "बॉस बहुत दयालु है"),
            WordExample(thai: "เจ้านายไม่อยู่", romanization: "jâo-naai mâi yùu", english: "The boss is not in", hindi: "बॉस नहीं हैं"),
        ],
        757: [
            WordExample(thai: "เขาเป็นทนายความ", romanization: "khǎo pen thá-naai-khwaam", english: "He is a lawyer", hindi: "वह वकील है"),
            WordExample(thai: "ผมไปหาทนายความ", romanization: "phǒm pai hǎa thá-naai-khwaam", english: "I go to see a lawyer", hindi: "मैं वकील के पास जाता हूँ"),
        ],
        758: [
            WordExample(thai: "เขาเป็นผู้จัดการ", romanization: "khǎo pen phûu-jàt-kaan", english: "He is the manager", hindi: "वह मैनेजर है"),
            WordExample(thai: "ผู้จัดการมาแล้ว", romanization: "phûu-jàt-kaan maa láew", english: "The manager has come", hindi: "मैनेजर आ गया"),
        ],
        759: [
            WordExample(thai: "ไกด์คนนี้ดีมาก", romanization: "kái khon-níi dii mâak", english: "This guide is very good", hindi: "यह गाइड बहुत अच्छा है"),
            WordExample(thai: "เขาเป็นไกด์", romanization: "khǎo pen kái", english: "He is a tour guide", hindi: "वह गाइड है"),
        ],
        760: [
            WordExample(thai: "เขาเป็นเด็กผู้ชาย", romanization: "kǎo pen dèk-pûu-chaai", english: "He is a boy.", hindi: "वह लड़का है।"),
            WordExample(thai: "เด็กผู้ชายชอบกินมาก", romanization: "dèk-pûu-chaai châwp kin mâak", english: "The boy likes to eat a lot.", hindi: "लड़के को खाना बहुत पसंद है।"),
        ],
        761: [
            WordExample(thai: "เด็กผู้หญิงอยู่ที่นี่", romanization: "dèk-pûu-yǐng yùu tîi-nîi", english: "The girl is here.", hindi: "लड़की यहाँ है।"),
            WordExample(thai: "ฉันชอบเด็กผู้หญิงคนนี้", romanization: "chǎn châwp dèk-pûu-yǐng kon níi", english: "I like this girl.", hindi: "मुझे यह लड़की पसंद है।"),
        ],
        762: [
            WordExample(thai: "ทารกนอนอยู่", romanization: "taa-rók nawn yùu", english: "The baby is sleeping.", hindi: "शिशु सो रहा है।"),
            WordExample(thai: "ทารกน่ารักมาก", romanization: "taa-rók nâa-rák mâak", english: "The baby is very cute.", hindi: "शिशु बहुत प्यारा है।"),
        ],
        763: [
            WordExample(thai: "คนแก่อยู่ที่บ้าน", romanization: "kon-kàe yùu tîi bâan", english: "The old person is at home.", hindi: "बुज़ुर्ग घर पर हैं।"),
            WordExample(thai: "คนแก่เดินมาที่นี่", romanization: "kon-kàe dəən maa tîi-nîi", english: "The old person walks here.", hindi: "बुज़ुर्ग चलकर यहाँ आते हैं।"),
        ],
        764: [
            WordExample(thai: "เขาเป็นผู้สูงอายุ", romanization: "kǎo pen pûu-sǔung-aa-yú", english: "He is an elderly person.", hindi: "वे वरिष्ठ नागरिक हैं।"),
            WordExample(thai: "ผู้สูงอายุชอบมาที่นี่", romanization: "pûu-sǔung-aa-yú châwp maa tîi-nîi", english: "Elderly people like to come here.", hindi: "वरिष्ठ नागरिक यहाँ आना पसंद करते हैं।"),
        ],
        765: [
            WordExample(thai: "เขาเป็นคนหนุ่ม", romanization: "kǎo pen kon nùm", english: "He is a young man.", hindi: "वह जवान आदमी है।"),
            WordExample(thai: "ผู้ชายหนุ่มคนนี้ดีมาก", romanization: "pûu-chaai nùm kon níi dii mâak", english: "This young man is very nice.", hindi: "यह जवान आदमी बहुत अच्छा है।"),
        ],
        766: [
            WordExample(thai: "เขาเป็นสาวสวย", romanization: "kǎo pen sǎao sǔai", english: "She is a beautiful young woman.", hindi: "वह सुंदर युवती है।"),
            WordExample(thai: "สาวคนนี้ชื่ออะไร", romanization: "sǎao kon níi chûe à-rai", english: "What is this young woman's name?", hindi: "इस युवती का नाम क्या है?"),
        ],
        767: [
            WordExample(thai: "ลูกเกิดที่นี่", romanization: "lûuk kə̀ət tîi-nîi", english: "The child was born here.", hindi: "बच्चा यहाँ पैदा हुआ।"),
            WordExample(thai: "เขาเกิดที่บ้าน", romanization: "kǎo kə̀ət tîi bâan", english: "He was born at home.", hindi: "वह घर पर पैदा हुआ।"),
        ],
        768: [
            WordExample(thai: "ลูกอายุสามขวบ", romanization: "lûuk aa-yú sǎam kùap", english: "My child is three years old.", hindi: "मेरा बच्चा तीन साल का है।"),
            WordExample(thai: "เด็กคนนี้สองขวบ", romanization: "dèk kon níi sǎwng kùap", english: "This child is two years old.", hindi: "यह बच्चा दो साल का है।"),
        ],
        769: [
            WordExample(thai: "เขาแก่แล้ว", romanization: "kǎo kàe láew", english: "He is old now.", hindi: "वह बूढ़ा हो गया है।"),
            WordExample(thai: "คุณไม่แก่", romanization: "kun mâi kàe", english: "You are not old.", hindi: "आप बूढ़े नहीं हैं।"),
        ],
        770: [
            WordExample(thai: "เขาอยู่ในวัยเด็ก", romanization: "kǎo yùu nai wai-dèk", english: "He is in childhood.", hindi: "वह बचपन की उम्र में है।"),
            WordExample(thai: "วัยนี้ดีมาก", romanization: "wai níi dii mâak", english: "This age is very good.", hindi: "यह उम्र बहुत अच्छी है।"),
        ],
        771: [
            WordExample(thai: "วัยเด็กของผมดีมาก", romanization: "wai-dèk kǎwng pǒm dii mâak", english: "My childhood was very good.", hindi: "मेरा बचपन बहुत अच्छा था।"),
            WordExample(thai: "ฉันคิดถึงวัยเด็ก", romanization: "chǎn kít-tǔeng wai-dèk", english: "I miss my childhood.", hindi: "मुझे बचपन की याद आती है।"),
        ],
        772: [
            WordExample(thai: "ชีวิตดีมาก", romanization: "chii-wít dii mâak", english: "Life is very good.", hindi: "ज़िंदगी बहुत अच्छी है।"),
            WordExample(thai: "ผมชอบชีวิตที่นี่", romanization: "pǒm châwp chii-wít tîi-nîi", english: "I like life here.", hindi: "मुझे यहाँ की ज़िंदगी पसंद है।"),
        ],
        773: [
            WordExample(thai: "ลูกโตแล้ว", romanization: "lûuk too láew", english: "The child has grown up.", hindi: "बच्चा बड़ा हो गया है।"),
            WordExample(thai: "เด็กโตเร็วมาก", romanization: "dèk too reo mâak", english: "Children grow up very fast.", hindi: "बच्चे बहुत जल्दी बड़े होते हैं।"),
        ],
        774: [
            WordExample(thai: "เขาเกษียณแล้ว", romanization: "kǎo kà-sǐan láew", english: "He has retired.", hindi: "वह रिटायर हो गए हैं।"),
            WordExample(thai: "ครูเกษียณปีนี้", romanization: "kruu kà-sǐan pii níi", english: "The teacher retires this year.", hindi: "शिक्षक इस साल रिटायर होंगे।"),
        ],
        775: [
            WordExample(thai: "เขาเป็นคนรุ่นใหม่", romanization: "kǎo pen kon rûn mài", english: "He is a new-generation person.", hindi: "वह नई पीढ़ी का आदमी है।"),
            WordExample(thai: "ผมชอบคนรุ่นนี้", romanization: "pǒm châwp kon rûn níi", english: "I like this generation.", hindi: "मुझे यह पीढ़ी पसंद है।"),
        ],
        776: [
            WordExample(thai: "ผมยังโสด", romanization: "pǒm yang sòot", english: "I am still single.", hindi: "मैं अभी अविवाहित हूँ।"),
            WordExample(thai: "คุณโสดไหม", romanization: "kun sòot mǎi", english: "Are you single?", hindi: "क्या आप अविवाहित हैं?"),
        ],
        777: [
            WordExample(thai: "เขาตายแล้ว", romanization: "kǎo taai láew", english: "He has died.", hindi: "वह मर गया है।"),
            WordExample(thai: "ปลาตายแล้ว", romanization: "plaa taai láew", english: "The fish died.", hindi: "मछली मर गई।"),
        ],
        778: [
            WordExample(thai: "วันนี้ฉันเศร้ามาก", romanization: "wan-níi chǎn sâo mâak", english: "Today I am very sad", hindi: "आज मैं बहुत उदास हूँ"),
            WordExample(thai: "อย่าเศร้าเลยนะ", romanization: "yàa sâo loei ná", english: "Don't be sad, okay?", hindi: "उदास मत हो ना"),
        ],
        779: [
            WordExample(thai: "แม่โมโหผมมาก", romanization: "mâe moo-hǒo phǒm mâak", english: "Mom is very angry at me", hindi: "माँ मुझसे बहुत नाराज़ हैं"),
            WordExample(thai: "อย่าโมโหผมเลย", romanization: "yàa moo-hǒo phǒm loei", english: "Don't be angry at me", hindi: "मुझसे गुस्सा मत हो"),
        ],
        780: [
            WordExample(thai: "เด็กกลัวหมามาก", romanization: "dèk klua mǎa mâak", english: "The child is very afraid of dogs", hindi: "बच्चा कुत्ते से बहुत डरता है"),
            WordExample(thai: "คุณกลัวอะไร", romanization: "khun klua à-rai", english: "What are you afraid of?", hindi: "आप किससे डरते हैं?"),
        ],
        781: [
            WordExample(thai: "วันนี้ผมเหงามาก", romanization: "wan-níi phǒm ngǎo mâak", english: "Today I feel very lonely", hindi: "आज मैं बहुत अकेला महसूस कर रहा हूँ"),
            WordExample(thai: "อยู่ที่นี่ไม่เหงา", romanization: "yùu thîi-nîi mâi ngǎo", english: "Staying here is not lonely", hindi: "यहाँ रहने पर अकेलापन नहीं लगता"),
        ],
        782: [
            WordExample(thai: "ตอนนี้ผมเครียดมาก", romanization: "toon-níi phǒm khrîat mâak", english: "Right now I am very stressed", hindi: "अभी मैं बहुत तनाव में हूँ"),
            WordExample(thai: "อย่าเครียดนะ", romanization: "yàa khrîat ná", english: "Don't stress, okay?", hindi: "तनाव मत लो ना"),
        ],
        783: [
            WordExample(thai: "แม่กังวลมาก", romanization: "mâe kang-won mâak", english: "Mom is very worried", hindi: "माँ बहुत चिंतित हैं"),
            WordExample(thai: "ฉันกังวลนิดหน่อย", romanization: "chǎn kang-won nít-nòi", english: "I am a little worried", hindi: "मैं थोड़ी चिंतित हूँ"),
        ],
        784: [
            WordExample(thai: "เด็กอายมาก", romanization: "dèk aai mâak", english: "The child is very shy", hindi: "बच्चा बहुत शर्मीला है"),
            WordExample(thai: "ผมอายนิดหน่อย", romanization: "phǒm aai nít-nòi", english: "I am a little shy", hindi: "मैं थोड़ा शर्मा रहा हूँ"),
        ],
        785: [
            WordExample(thai: "ฉันตกใจมากเลย", romanization: "chǎn tòk-jai mâak loei", english: "I was really startled", hindi: "मैं सच में चौंक गई"),
            WordExample(thai: "เขาตกใจนิดหน่อย", romanization: "khǎo tòk-jai nít-nòi", english: "He was a little startled", hindi: "वह थोड़ा चौंक गया"),
        ],
        786: [
            WordExample(thai: "ผมแปลกใจมาก", romanization: "phǒm plàek-jai mâak", english: "I am very surprised", hindi: "मैं बहुत हैरान हूँ"),
            WordExample(thai: "ทำไมคุณแปลกใจ", romanization: "tham-mai khun plàek-jai", english: "Why are you surprised?", hindi: "आप हैरान क्यों हैं?"),
        ],
        787: [
            WordExample(thai: "พ่อภูมิใจมาก", romanization: "phôo phuum-jai mâak", english: "Dad is very proud", hindi: "पिता को बहुत गर्व है"),
            WordExample(thai: "ผมภูมิใจที่ทำได้", romanization: "phǒm phuum-jai thîi tham dâi", english: "I am proud that I could do it", hindi: "मुझे गर्व है कि मैं कर सका"),
        ],
        788: [
            WordExample(thai: "ฉันอิจฉาคุณนิดหน่อย", romanization: "chǎn ìt-chǎa khun nít-nòi", english: "I envy you a little", hindi: "मुझे आपसे थोड़ी जलन होती है"),
            WordExample(thai: "อย่าอิจฉาเขาเลย", romanization: "yàa ìt-chǎa khǎo loei", english: "Don't be jealous of him", hindi: "उससे जलन मत करो"),
        ],
        789: [
            WordExample(thai: "ผมไม่เกลียดคุณ", romanization: "phǒm mâi klìat khun", english: "I do not hate you", hindi: "मैं आपसे नफ़रत नहीं करता"),
            WordExample(thai: "ทำไมคุณเกลียดเขา", romanization: "tham-mai khun klìat khǎo", english: "Why do you hate him?", hindi: "आप उससे नफ़रत क्यों करते हैं?"),
        ],
        790: [
            WordExample(thai: "ฉันสงสารเขามาก", romanization: "chǎn sǒng-sǎan khǎo mâak", english: "I feel very sorry for him", hindi: "मुझे उस पर बहुत तरस आता है"),
            WordExample(thai: "อย่าสงสารผมเลย", romanization: "yàa sǒng-sǎan phǒm loei", english: "Don't pity me", hindi: "मुझ पर तरस मत खाओ"),
        ],
        791: [
            WordExample(thai: "เสียดายมากเลยครับ", romanization: "sǐa-daai mâak loei khráp", english: "What a great pity", hindi: "बहुत अफ़सोस है"),
            WordExample(thai: "ผมเสียดายที่ไม่ได้ไป", romanization: "phǒm sǐa-daai thîi mâi dâi pai", english: "I regret that I could not go", hindi: "मुझे अफ़सोस है कि मैं नहीं जा सका"),
        ],
        792: [
            WordExample(thai: "ผมผิดหวังมาก", romanization: "phǒm phìt-wǎng mâak", english: "I am very disappointed", hindi: "मैं बहुत निराश हूँ"),
            WordExample(thai: "พ่อผิดหวังนิดหน่อย", romanization: "phôo phìt-wǎng nít-nòi", english: "Dad is a little disappointed", hindi: "पिता थोड़े निराश हैं"),
        ],
        793: [
            WordExample(thai: "ฉันพอใจมากค่ะ", romanization: "chǎn phoo-jai mâak khâ", english: "I am very satisfied", hindi: "मैं बहुत संतुष्ट हूँ"),
            WordExample(thai: "เขาพอใจกับงาน", romanization: "khǎo phoo-jai kàp ngaan", english: "He is satisfied with the work", hindi: "वह काम से संतुष्ट है"),
        ],
        794: [
            WordExample(thai: "ตอนนี้ฉันสบายใจ", romanization: "toon-níi chǎn sà-baai-jai", english: "Now I feel at ease", hindi: "अब मेरा मन हल्का है"),
            WordExample(thai: "อยู่ที่นี่สบายใจมาก", romanization: "yùu thîi-nîi sà-baai-jai mâak", english: "It feels very peaceful staying here", hindi: "यहाँ रहकर मन बहुत हल्का रहता है"),
        ],
        795: [
            WordExample(thai: "ผมมีความสุขมาก", romanization: "phǒm mii-khwaam-sùk mâak", english: "I am very happy", hindi: "मैं बहुत खुश हूँ"),
            WordExample(thai: "อยู่กับคุณมีความสุข", romanization: "yùu kàp khun mii-khwaam-sùk", english: "Being with you makes me happy", hindi: "आपके साथ रहकर खुशी मिलती है"),
        ],
        796: [
            WordExample(thai: "ความสุขอยู่ที่นี่", romanization: "khwaam-sùk yùu thîi-nîi", english: "Happiness is right here", hindi: "खुशी यहीं है"),
            WordExample(thai: "แม่คือความสุขของฉัน", romanization: "mâe khuue khwaam-sùk khǒong chǎn", english: "Mom is my happiness", hindi: "माँ मेरी खुशी हैं"),
        ],
        797: [
            WordExample(thai: "ผมรู้สึกดีมาก", romanization: "phǒm rúu-sùek dii mâak", english: "I feel very good", hindi: "मैं बहुत अच्छा महसूस करता हूँ"),
            WordExample(thai: "ฉันรู้สึกไม่ดีเลย", romanization: "chǎn rúu-sùek mâi dii loei", english: "I feel really unwell", hindi: "मैं बिल्कुल ठीक महसूस नहीं कर रही"),
        ],
        798: [
            WordExample(thai: "วันนี้อารมณ์ดีมาก", romanization: "wan-níi aa-rom dii mâak", english: "Today the mood is very good", hindi: "आज मूड बहुत अच्छा है"),
            WordExample(thai: "เขาอารมณ์ไม่ดี", romanization: "khǎo aa-rom mâi dii", english: "He is in a bad mood", hindi: "उसका मूड अच्छा नहीं है"),
        ],
        799: [
            WordExample(thai: "แม่อารมณ์ดีวันนี้", romanization: "mâe aa-rom-dii wan-níi", english: "Mom is in a good mood today", hindi: "माँ आज अच्छे मूड में हैं"),
            WordExample(thai: "ผมอารมณ์ดีมากเลย", romanization: "phǒm aa-rom-dii mâak loei", english: "I am in a really good mood", hindi: "मैं बहुत अच्छे मूड में हूँ"),
        ],
        800: [
            WordExample(thai: "อย่าอารมณ์เสียเลยนะ", romanization: "yàa aa-rom-sǐa loei ná", english: "Don't be upset, okay?", hindi: "मूड खराब मत करो ना"),
            WordExample(thai: "เขาอารมณ์เสียมาก", romanization: "khǎo aa-rom-sǐa mâak", english: "He is very upset", hindi: "उसका मूड बहुत खराब है"),
        ],
        801: [
            WordExample(thai: "วันนี้ฉันหงุดหงิดมาก", romanization: "wan-níi chǎn ngùt-ngìt mâak", english: "Today I am very irritable", hindi: "आज मैं बहुत चिड़चिड़ी हूँ"),
            WordExample(thai: "อย่าหงุดหงิดกับเด็ก", romanization: "yàa ngùt-ngìt kàp dèk", english: "Don't be grumpy with the child", hindi: "बच्चे पर मत चिड़चिड़ाओ"),
        ],
        802: [
            WordExample(thai: "ผมรำคาญมากเลย", romanization: "phǒm ram-khaan mâak loei", english: "I am really annoyed", hindi: "मैं बहुत खीज गया हूँ"),
            WordExample(thai: "ฉันรำคาญเขานิดหน่อย", romanization: "chǎn ram-khaan khǎo nít-nòi", english: "I am a little annoyed with him", hindi: "मैं उससे थोड़ी खीजी हुई हूँ"),
        ],
        803: [
            WordExample(thai: "ใจเย็นหน่อยนะครับ", romanization: "jai-yen nòi ná khráp", english: "Please calm down a bit", hindi: "ज़रा शांत हो जाइए"),
            WordExample(thai: "แม่เป็นคนใจเย็น", romanization: "mâe pen khon jai-yen", english: "Mom is a calm person", hindi: "माँ शांत स्वभाव की हैं"),
        ],
        804: [
            WordExample(thai: "อย่าใจร้อนเลย", romanization: "yàa jai-rón loei", english: "Don't be impatient", hindi: "जल्दबाज़ी मत करो"),
            WordExample(thai: "เขาเป็นคนใจร้อน", romanization: "khǎo pen khon jai-rón", english: "He is a hot-tempered person", hindi: "वह गरम मिज़ाज का है"),
        ],
        805: [
            WordExample(thai: "แม่เป็นห่วงคุณมาก", romanization: "mâe pen-hùang khun mâak", english: "Mom worries about you a lot", hindi: "माँ को आपकी बहुत फ़िक्र है"),
            WordExample(thai: "อย่าเป็นห่วงผมเลย", romanization: "yàa pen-hùang phǒm loei", english: "Don't worry about me", hindi: "मेरी फ़िक्र मत करो"),
        ],
        806: [
            WordExample(thai: "เด็กร้องไห้มาก", romanization: "dèk róng-hâi mâak", english: "The child cries a lot", hindi: "बच्चा बहुत रोता है"),
            WordExample(thai: "อย่าร้องไห้นะ", romanization: "yàa róng-hâi ná", english: "Don't cry, okay?", hindi: "रोओ मत ना"),
        ],
        807: [
            WordExample(thai: "ซุปอร่อยมาก", romanization: "súp à-ròi mâak", english: "The soup is very tasty", hindi: "सूप बहुत स्वादिष्ट है"),
            WordExample(thai: "ผมชอบกินซุป", romanization: "phǒm chôp kin súp", english: "I like eating soup", hindi: "मुझे सूप खाना पसंद है"),
        ],
        808: [
            WordExample(thai: "อร่อยไหมคะ", romanization: "à-ròi mǎi khá", english: "Is it tasty?", hindi: "क्या यह स्वादिष्ट है?"),
            WordExample(thai: "คุณไปไหนคะ", romanization: "khun pai nǎi khá", english: "Where are you going?", hindi: "आप कहाँ जा रहे हैं?"),
        ],
        809: [
            WordExample(thai: "ผมกลับบ้าน", romanization: "phǒm klàp bâan", english: "I go back home", hindi: "मैं घर लौटता हूँ"),
            WordExample(thai: "เขากลับมาแล้ว", romanization: "khǎo klàp maa láew", english: "He already came back", hindi: "वह वापस आ गया है"),
        ],
        // Batch 4
        810: [
            WordExample(thai: "เขาใจดีมาก", romanization: "khǎo jai-dii mâak", english: "He is very kind.", hindi: "वह बहुत दयालु है।"),
            WordExample(thai: "แม่ของฉันใจดี", romanization: "mâe khǒong chǎn jai-dii", english: "My mother is kind.", hindi: "मेरी माँ दयालु हैं।"),
        ],
        811: [
            WordExample(thai: "ผมขี้เกียจมาก", romanization: "phǒm khîi-kìat mâak", english: "I am very lazy.", hindi: "मैं बहुत आलसी हूँ।"),
            WordExample(thai: "เขาขี้เกียจทำงาน", romanization: "khǎo khîi-kìat tham-ngaan", english: "He is too lazy to work.", hindi: "वह काम करने में आलसी है।"),
        ],
        812: [
            WordExample(thai: "เขาขยันมาก", romanization: "khǎo khà-yǎn mâak", english: "He is very hardworking.", hindi: "वह बहुत मेहनती है।"),
            WordExample(thai: "เด็กคนนี้ขยันเรียน", romanization: "dèk khon níi khà-yǎn rian", english: "This child studies hard.", hindi: "यह बच्चा मेहनत से पढ़ता है।"),
        ],
        813: [
            WordExample(thai: "เพื่อนของผมตลกมาก", romanization: "phêuan khǒong phǒm tà-lòk mâak", english: "My friend is very funny.", hindi: "मेरा दोस्त बहुत मज़ाकिया है।"),
            WordExample(thai: "เขาชอบพูดตลก", romanization: "khǎo chôop phûut tà-lòk", english: "He likes to joke.", hindi: "उसे मज़ाक करना पसंद है।"),
        ],
        814: [
            WordExample(thai: "เขาใจร้ายมาก", romanization: "khǎo jai-ráai mâak", english: "He is very mean.", hindi: "वह बहुत निर्दयी है।"),
            WordExample(thai: "อย่าใจร้ายกับฉัน", romanization: "yàa jai-ráai kàp chǎn", english: "Do not be mean to me.", hindi: "मेरे साथ निर्दयी मत बनो।"),
        ],
        815: [
            WordExample(thai: "น้องของฉันขี้อาย", romanization: "nóong khǒong chǎn khîi-aai", english: "My younger sibling is shy.", hindi: "मेरा छोटा भाई शर्मीला है।"),
            WordExample(thai: "ผมขี้อายมาก", romanization: "phǒm khîi-aai mâak", english: "I am very shy.", hindi: "मैं बहुत शर्मीला हूँ।"),
        ],
        816: [
            WordExample(thai: "เขาเป็นคนซื่อสัตย์", romanization: "khǎo pen khon sûe-sàt", english: "He is an honest person.", hindi: "वह ईमानदार इंसान है।"),
            WordExample(thai: "เพื่อนของฉันซื่อสัตย์มาก", romanization: "phêuan khǒong chǎn sûe-sàt mâak", english: "My friend is very honest.", hindi: "मेरा दोस्त बहुत ईमानदार है।"),
        ],
        817: [
            WordExample(thai: "เด็กคนนี้ฉลาดมาก", romanization: "dèk khon níi chà-làat mâak", english: "This child is very clever.", hindi: "यह बच्चा बहुत होशियार है।"),
            WordExample(thai: "เขาฉลาดจริงๆ", romanization: "khǎo chà-làat jing-jing", english: "He is really smart.", hindi: "वह सचमुच होशियार है।"),
        ],
        818: [
            WordExample(thai: "ผมไม่โง่นะ", romanization: "phǒm mâi ngôo ná", english: "I am not stupid.", hindi: "मैं बेवकूफ़ नहीं हूँ।"),
            WordExample(thai: "อย่าพูดว่าเขาโง่", romanization: "yàa phûut wâa khǎo ngôo", english: "Do not say he is stupid.", hindi: "मत कहो कि वह बेवकूफ़ है।"),
        ],
        819: [
            WordExample(thai: "พ่อของเขาขี้โมโห", romanization: "phôo khǒong khǎo khîi-moo-hǒo", english: "His father is quick-tempered.", hindi: "उसके पिता गुस्सैल हैं।"),
            WordExample(thai: "อย่าขี้โมโหนะ", romanization: "yàa khîi-moo-hǒo ná", english: "Do not be so quick-tempered.", hindi: "इतना गुस्सा मत किया करो।"),
        ],
        820: [
            WordExample(thai: "แม่ของฉันขี้ลืม", romanization: "mâe khǒong chǎn khîi-luem", english: "My mother is forgetful.", hindi: "मेरी माँ भुलक्कड़ हैं।"),
            WordExample(thai: "ผมขี้ลืมมาก", romanization: "phǒm khîi-luem mâak", english: "I am very forgetful.", hindi: "मैं बहुत भुलक्कड़ हूँ।"),
        ],
        821: [
            WordExample(thai: "เขาขี้บ่นมาก", romanization: "khǎo khîi-bòn mâak", english: "He complains a lot.", hindi: "वह बहुत शिकायत करता है।"),
            WordExample(thai: "แม่ขี้บ่นนิดหน่อย", romanization: "mâe khîi-bòn nít-nòi", english: "Mom nags a little.", hindi: "माँ थोड़ी बड़बड़ाती हैं।"),
        ],
        822: [
            WordExample(thai: "เขาขี้เหนียวมาก", romanization: "khǎo khîi-nǐao mâak", english: "He is very stingy.", hindi: "वह बहुत कंजूस है।"),
            WordExample(thai: "อย่าขี้เหนียวสิ", romanization: "yàa khîi-nǐao sì", english: "Do not be stingy.", hindi: "कंजूसी मत करो।"),
        ],
        823: [
            WordExample(thai: "เขาเป็นคนใจกว้าง", romanization: "khǎo pen khon jai-kwâang", english: "He is a generous person.", hindi: "वह दरियादिल इंसान है।"),
            WordExample(thai: "ครูของฉันใจกว้างมาก", romanization: "khruu khǒong chǎn jai-kwâang mâak", english: "My teacher is very generous.", hindi: "मेरे शिक्षक बहुत उदार हैं।"),
        ],
        824: [
            WordExample(thai: "เขาพูดสุภาพมาก", romanization: "khǎo phûut sù-phâap mâak", english: "He speaks very politely.", hindi: "वह बहुत विनम्रता से बोलता है।"),
            WordExample(thai: "เด็กคนนี้สุภาพ", romanization: "dèk khon níi sù-phâap", english: "This child is polite.", hindi: "यह बच्चा विनम्र है।"),
        ],
        825: [
            WordExample(thai: "เขาหยิ่งมาก", romanization: "khǎo yìng mâak", english: "He is very arrogant.", hindi: "वह बहुत घमंडी है।"),
            WordExample(thai: "ฉันไม่ชอบคนหยิ่ง", romanization: "chǎn mâi chôop khon yìng", english: "I do not like arrogant people.", hindi: "मुझे घमंडी लोग पसंद नहीं।"),
        ],
        826: [
            WordExample(thai: "เด็กคนนี้ร่าเริงมาก", romanization: "dèk khon níi râa-roeng mâak", english: "This child is very cheerful.", hindi: "यह बच्चा बहुत हँसमुख है।"),
            WordExample(thai: "วันนี้เขาร่าเริงดี", romanization: "wan-níi khǎo râa-roeng dii", english: "He is quite cheerful today.", hindi: "आज वह खूब खुशमिज़ाज है।"),
        ],
        827: [
            WordExample(thai: "น้องของผมขี้เล่นมาก", romanization: "nóong khǒong phǒm khîi-lên mâak", english: "My younger sibling is very playful.", hindi: "मेरा छोटा भाई बहुत खिलंदड़ है।"),
            WordExample(thai: "แมวตัวนี้ขี้เล่น", romanization: "maew tua níi khîi-lên", english: "This cat is playful.", hindi: "यह बिल्ली चंचल है।"),
        ],
        828: [
            WordExample(thai: "เด็กคนนี้น่ารักมาก", romanization: "dèk khon níi nâa-rák mâak", english: "This child is very cute.", hindi: "यह बच्चा बहुत प्यारा है।"),
            WordExample(thai: "เขาน่ารักกับทุกคน", romanization: "khǎo nâa-rák kàp thúk khon", english: "He is sweet to everyone.", hindi: "वह सबके साथ प्यार से पेश आता है।"),
        ],
        829: [
            WordExample(thai: "คนไทยเป็นมิตรมาก", romanization: "khon thai pen-mít mâak", english: "Thai people are very friendly.", hindi: "थाई लोग बहुत मिलनसार हैं।"),
            WordExample(thai: "เขาเป็นมิตรกับทุกคน", romanization: "khǎo pen-mít kàp thúk khon", english: "He is friendly with everyone.", hindi: "वह सबके साथ मिलनसार है।"),
        ],
        830: [
            WordExample(thai: "น้องขี้กลัวมาก", romanization: "nóong khîi-klua mâak", english: "My little sibling is very timid.", hindi: "छोटा भाई बहुत डरपोक है।"),
            WordExample(thai: "ฉันขี้กลัวนิดหน่อย", romanization: "chǎn khîi-klua nít-nòi", english: "I am a bit timid.", hindi: "मैं थोड़ी डरपोक हूँ।"),
        ],
        831: [
            WordExample(thai: "เขากล้าหาญมาก", romanization: "khǎo klâa-hǎan mâak", english: "He is very brave.", hindi: "वह बहुत बहादुर है।"),
            WordExample(thai: "เด็กคนนี้กล้าหาญจริงๆ", romanization: "dèk khon níi klâa-hǎan jing-jing", english: "This child is really brave.", hindi: "यह बच्चा सचमुच बहादुर है।"),
        ],
        832: [
            WordExample(thai: "แม่ของฉันอดทนมาก", romanization: "mâe khǒong chǎn òt-thon mâak", english: "My mother is very patient.", hindi: "मेरी माँ बहुत धैर्यवान हैं।"),
            WordExample(thai: "เราต้องอดทน", romanization: "rao tông òt-thon", english: "We must be patient.", hindi: "हमें धैर्य रखना होगा।"),
        ],
        833: [
            WordExample(thai: "เด็กคนนี้ซนมาก", romanization: "dèk khon níi son mâak", english: "This child is very naughty.", hindi: "यह बच्चा बहुत शरारती है।"),
            WordExample(thai: "แมวของฉันซน", romanization: "maew khǒong chǎn son", english: "My cat is mischievous.", hindi: "मेरी बिल्ली शरारती है।"),
        ],
        834: [
            WordExample(thai: "เขาเป็นคนเจ้าชู้", romanization: "khǎo pen khon jâo-chúu", english: "He is a flirt.", hindi: "वह दिलफेंक इंसान है।"),
            WordExample(thai: "ฉันไม่ชอบคนเจ้าชู้", romanization: "chǎn mâi chôop khon jâo-chúu", english: "I do not like flirty people.", hindi: "मुझे दिलफेंक लोग पसंद नहीं।"),
        ],
        835: [
            WordExample(thai: "เขาเห็นแก่ตัวมาก", romanization: "khǎo hěn-kàe-tua mâak", english: "He is very selfish.", hindi: "वह बहुत स्वार्थी है।"),
            WordExample(thai: "อย่าเห็นแก่ตัวสิ", romanization: "yàa hěn-kàe-tua sì", english: "Do not be selfish.", hindi: "स्वार्थी मत बनो।"),
        ],
        836: [
            WordExample(thai: "เขาเป็นคนจริงใจ", romanization: "khǎo pen khon jing-jai", english: "He is a sincere person.", hindi: "वह सच्चा इंसान है।"),
            WordExample(thai: "เพื่อนของฉันจริงใจมาก", romanization: "phêuan khǒong chǎn jing-jai mâak", english: "My friend is very sincere.", hindi: "मेरा दोस्त बहुत सच्चा है।"),
        ],
        837: [
            WordExample(thai: "แม่ของเขาอ่อนโยนมาก", romanization: "mâe khǒong khǎo òon-yoon mâak", english: "His mother is very gentle.", hindi: "उसकी माँ बहुत सौम्य हैं।"),
            WordExample(thai: "เขาพูดอ่อนโยน", romanization: "khǎo phûut òon-yoon", english: "He speaks gently.", hindi: "वह नरमी से बोलता है।"),
        ],
        838: [
            WordExample(thai: "นี่คือความรัก", romanization: "nîi khuue khwaam-rák", english: "This is love.", hindi: "यह प्यार है।"),
            WordExample(thai: "ความรักสำคัญมาก", romanization: "khwaam-rák sǎm-khan mâak", english: "Love is very important.", hindi: "प्यार बहुत महत्वपूर्ण है।"),
        ],
        839: [
            WordExample(thai: "ที่รัก กินข้าวไหม", romanization: "thîi-rák kin khâao mǎi", english: "Darling, do you want to eat?", hindi: "जानू, खाना खाओगे?"),
            WordExample(thai: "คิดถึงนะที่รัก", romanization: "khít-thǔeng ná thîi-rák", english: "I miss you, darling.", hindi: "तुम्हारी याद आती है, जानू।"),
        ],
        840: [
            WordExample(thai: "เขาเป็นคนรักของฉัน", romanization: "khǎo pen khon-rák khǎwng chǎn", english: "He is my sweetheart.", hindi: "वह मेरा प्रियतम है।"),
            WordExample(thai: "คนรักของผมอยู่ที่นี่", romanization: "khon-rák khǎwng pǒm yùu thîi-nîi", english: "My sweetheart is here.", hindi: "मेरी प्रियतमा यहाँ है।"),
        ],
        841: [
            WordExample(thai: "เขาเป็นคู่รักกัน", romanization: "khǎo pen khûu-rák kan", english: "They are a couple.", hindi: "वे एक प्रेमी जोड़ा हैं।"),
            WordExample(thai: "คู่รักชอบมาที่นี่", romanization: "khûu-rák châwp maa thîi-nîi", english: "Couples like to come here.", hindi: "प्रेमी जोड़े यहाँ आना पसंद करते हैं।"),
        ],
        842: [
            WordExample(thai: "เขาจีบฉัน", romanization: "khǎo jìip chǎn", english: "He is flirting with me.", hindi: "वह मुझसे फ्लर्ट कर रहा है।"),
            WordExample(thai: "ผมอยากจีบเขา", romanization: "pǒm yàak jìip khǎo", english: "I want to court her.", hindi: "मैं उसे रिझाना चाहता हूँ।"),
        ],
        843: [
            WordExample(thai: "ฉันแอบชอบเขา", romanization: "chǎn àep-châwp khǎo", english: "I secretly like him.", hindi: "मैं उसे चुपके से पसंद करती हूँ।"),
            WordExample(thai: "เขาแอบชอบคุณนะ", romanization: "khǎo àep-châwp khun ná", english: "He secretly likes you.", hindi: "वह तुम्हें चुपके से पसंद करता है।"),
        ],
        844: [
            WordExample(thai: "ผมหลงรักเขา", romanization: "pǒm lǒng-rák khǎo", english: "I fell in love with her.", hindi: "मुझे उससे प्यार हो गया।"),
            WordExample(thai: "เขาหลงรักคุณมาก", romanization: "khǎo lǒng-rák khun mâak", english: "He is deeply in love with you.", hindi: "वह तुमसे बहुत प्यार करता है।"),
        ],
        845: [
            WordExample(thai: "ฉันตกหลุมรักเขา", romanization: "chǎn tòk-lǔm-rák khǎo", english: "I fell in love with him.", hindi: "मैं उसके प्यार में पड़ गई।"),
            WordExample(thai: "เขาตกหลุมรักฉัน", romanization: "khǎo tòk-lǔm-rák chǎn", english: "He fell in love with me.", hindi: "वह मेरे प्यार में पड़ गया।"),
        ],
        846: [
            WordExample(thai: "ไปเดทกันไหม", romanization: "pai dèet kan mǎi", english: "Shall we go on a date?", hindi: "क्या हम डेट पर चलें?"),
            WordExample(thai: "คืนนี้ผมมีเดท", romanization: "khuuen-níi pǒm mii dèet", english: "Tonight I have a date.", hindi: "आज रात मेरी डेट है।"),
        ],
        847: [
            WordExample(thai: "เราคบกันสองปี", romanization: "rao khóp kan sǎwng pii", english: "We have been dating for two years.", hindi: "हम दो साल से रिश्ते में हैं।"),
            WordExample(thai: "คุณคบกับเขาไหม", romanization: "khun khóp kàp khǎo mǎi", english: "Are you dating him?", hindi: "क्या तुम उसके साथ रिश्ते में हो?"),
        ],
        848: [
            WordExample(thai: "กอดฉันหน่อย", romanization: "kàwt chǎn nàwy", english: "Hug me, please.", hindi: "मुझे गले लगा लो।"),
            WordExample(thai: "ผมอยากกอดคุณ", romanization: "pǒm yàak kàwt khun", english: "I want to hug you.", hindi: "मैं तुम्हें गले लगाना चाहता हूँ।"),
        ],
        849: [
            WordExample(thai: "เขาจูบฉัน", romanization: "khǎo jùup chǎn", english: "He kissed me.", hindi: "उसने मुझे चूमा।"),
            WordExample(thai: "ผมจูบแฟนทุกวัน", romanization: "pǒm jùup faen thúk-wan", english: "I kiss my girlfriend every day.", hindi: "मैं अपनी गर्लफ्रेंड को रोज़ चूमता हूँ।"),
        ],
        850: [
            WordExample(thai: "อย่างอนนะ", romanization: "yàa ngawn ná", english: "Do not sulk, okay?", hindi: "रूठो मत।"),
            WordExample(thai: "เขางอนง่ายมาก", romanization: "khǎo ngawn ngâai mâak", english: "She sulks very easily.", hindi: "वह बहुत जल्दी रूठ जाती है।"),
        ],
        851: [
            WordExample(thai: "ผมไปง้อแฟน", romanization: "pǒm pai ngáw faen", english: "I went to make up with my girlfriend.", hindi: "मैं अपनी गर्लफ्रेंड को मनाने गया।"),
            WordExample(thai: "เขามาง้อฉัน", romanization: "khǎo maa ngáw chǎn", english: "He came to appease me.", hindi: "वह मुझे मनाने आया।"),
        ],
        852: [
            WordExample(thai: "แฟนฉันหึงมาก", romanization: "faen chǎn hǔeng mâak", english: "My boyfriend is very jealous.", hindi: "मेरा बॉयफ्रेंड बहुत जलता है।"),
            WordExample(thai: "อย่าหึงฉันนะ", romanization: "yàa hǔeng chǎn ná", english: "Do not be jealous of me.", hindi: "मुझसे जलन मत करो।"),
        ],
        853: [
            WordExample(thai: "เราทะเลาะกันบ่อย", romanization: "rao thá-láw kan bàwy", english: "We quarrel often.", hindi: "हम अक्सर झगड़ते हैं।"),
            WordExample(thai: "อย่าทะเลาะกันนะ", romanization: "yàa thá-láw kan ná", english: "Do not quarrel with each other.", hindi: "आपस में झगड़ो मत।"),
        ],
        854: [
            WordExample(thai: "เราคืนดีกันแล้ว", romanization: "rao khuuen-dii kan láeo", english: "We have made up.", hindi: "हमारी सुलह हो गई है।"),
            WordExample(thai: "ไปคืนดีกับแฟนนะ", romanization: "pai khuuen-dii kàp faen ná", english: "Go make up with your girlfriend.", hindi: "जाओ, अपनी गर्लफ्रेंड से सुलह कर लो।"),
        ],
        855: [
            WordExample(thai: "เราเลิกกันแล้ว", romanization: "rao lêrk-kan láeo", english: "We have broken up.", hindi: "हमारा ब्रेकअप हो गया है।"),
            WordExample(thai: "อย่าเลิกกันเลยนะ", romanization: "yàa lêrk-kan loei ná", english: "Please do not break up.", hindi: "प्लीज़ ब्रेकअप मत करो।"),
        ],
        856: [
            WordExample(thai: "ผมอกหักครับ", romanization: "pǒm òk-hàk khráp", english: "I am heartbroken.", hindi: "मेरा दिल टूट गया है।"),
            WordExample(thai: "ฉันเคยอกหัก", romanization: "chǎn khoei òk-hàk", english: "I have been heartbroken before.", hindi: "मेरा दिल पहले टूट चुका है।"),
        ],
        857: [
            WordExample(thai: "เขาเป็นแฟนเก่าของฉัน", romanization: "khǎo pen faen-kào khǎwng chǎn", english: "He is my ex.", hindi: "वह मेरा एक्स है।"),
            WordExample(thai: "ผมเจอแฟนเก่าเมื่อวาน", romanization: "pǒm jer faen-kào mûea-waan", english: "I met my ex yesterday.", hindi: "कल मैं अपनी एक्स से मिला।"),
        ],
        858: [
            WordExample(thai: "เขานอกใจฉัน", romanization: "khǎo nâwk-jai chǎn", english: "He cheated on me.", hindi: "उसने मुझे धोखा दिया।"),
            WordExample(thai: "อย่านอกใจแฟนนะ", romanization: "yàa nâwk-jai faen ná", english: "Do not cheat on your partner.", hindi: "अपने पार्टनर को धोखा मत दो।"),
        ],
        859: [
            WordExample(thai: "เราหมั้นกันแล้ว", romanization: "rao mân kan láeo", english: "We are engaged.", hindi: "हमारी सगाई हो गई है।"),
            WordExample(thai: "เขาเพิ่งหมั้นกัน", romanization: "khǎo phêrng mân kan", english: "They just got engaged.", hindi: "उनकी अभी-अभी सगाई हुई है।"),
        ],
        860: [
            WordExample(thai: "เขาขอฉันแต่งงาน", romanization: "khǎo khǎw chǎn tàeng-ngaan", english: "He proposed to me.", hindi: "उसने मुझे शादी के लिए प्रपोज़ किया।"),
            WordExample(thai: "ผมจะขอแฟนแต่งงาน", romanization: "pǒm jà khǎw faen tàeng-ngaan", english: "I will propose to my girlfriend.", hindi: "मैं अपनी गर्लफ्रेंड को प्रपोज़ करूँगा।"),
        ],
        861: [
            WordExample(thai: "เขาโรแมนติกมาก", romanization: "khǎo roo-maen-tìk mâak", english: "He is very romantic.", hindi: "वह बहुत रोमांटिक है।"),
            WordExample(thai: "ที่นี่โรแมนติกมาก", romanization: "thîi-nîi roo-maen-tìk mâak", english: "This place is very romantic.", hindi: "यह जगह बहुत रोमांटिक है।"),
        ],
        862: [
            WordExample(thai: "ฉันเจ็บลิ้น", romanization: "chǎn jèp lín", english: "My tongue hurts", hindi: "मेरी जीभ में दर्द है"),
            WordExample(thai: "กินเผ็ดมากเจ็บลิ้น", romanization: "kin pèt mâak jèp lín", english: "Eating very spicy hurts the tongue", hindi: "बहुत तीखा खाने से जीभ जलती है"),
        ],
        863: [
            WordExample(thai: "ฉันเจ็บไหล่มาก", romanization: "chǎn jèp lài mâak", english: "My shoulder hurts a lot", hindi: "मेरे कंधे में बहुत दर्द है"),
            WordExample(thai: "นวดไหล่สบายมาก", romanization: "nûat lài sà-baai mâak", english: "A shoulder massage feels very good", hindi: "कंधे की मालिश बहुत आराम देती है"),
        ],
        864: [
            WordExample(thai: "ฉันเจ็บเข่า", romanization: "chǎn jèp kào", english: "My knee hurts", hindi: "मेरे घुटने में दर्द है"),
            WordExample(thai: "เข่าของเขาไม่ดี", romanization: "kào kǒng kǎo mâi dii", english: "His knee is not good", hindi: "उसका घुटना ठीक नहीं है"),
        ],
        865: [
            WordExample(thai: "ฉันเจ็บศอก", romanization: "chǎn jèp sòok", english: "My elbow hurts", hindi: "मेरी कोहनी में दर्द है"),
            WordExample(thai: "ศอกของฉันมีแผล", romanization: "sòok kǒng chǎn mii plǎe", english: "My elbow has a wound", hindi: "मेरी कोहनी पर घाव है"),
        ],
        866: [
            WordExample(thai: "ฉันเจ็บนิ้วเท้า", romanization: "chǎn jèp níw-táo", english: "My toe hurts", hindi: "मेरे पैर की उंगली में दर्द है"),
            WordExample(thai: "นิ้วเท้าของเขาเล็ก", romanization: "níw-táo kǒng kǎo lék", english: "His toes are small", hindi: "उसके पैर की उंगलियां छोटी हैं"),
        ],
        867: [
            WordExample(thai: "ฉันตัดเล็บ", romanization: "chǎn tàt lép", english: "I cut my nails", hindi: "मैं नाखून काटती हूं"),
            WordExample(thai: "เล็บของเขาสวยมาก", romanization: "lép kǒng kǎo sǔai mâak", english: "Her nails are very pretty", hindi: "उसके नाखून बहुत सुंदर हैं"),
        ],
        868: [
            WordExample(thai: "คิ้วของเขาสวย", romanization: "kíw kǒng kǎo sǔai", english: "Her eyebrows are pretty", hindi: "उसकी भौंहें सुंदर हैं"),
            WordExample(thai: "คิ้วของฉันยาว", romanization: "kíw kǒng chǎn yaao", english: "My eyebrows are long", hindi: "मेरी भौंहें लंबी हैं"),
        ],
        869: [
            WordExample(thai: "ขนตาของเขายาวมาก", romanization: "kǒn-taa kǒng kǎo yaao mâak", english: "Her eyelashes are very long", hindi: "उसकी पलकें बहुत लंबी हैं"),
            WordExample(thai: "ขนตาของฉันสั้น", romanization: "kǒn-taa kǒng chǎn sân", english: "My eyelashes are short", hindi: "मेरी पलकें छोटी हैं"),
        ],
        870: [
            WordExample(thai: "แก้มของเขาแดง", romanization: "kâem kǒng kǎo daeng", english: "His cheeks are red", hindi: "उसके गाल लाल हैं"),
            WordExample(thai: "เด็กคนนี้แก้มน่ารัก", romanization: "dèk kon níi kâem nâa-rák", english: "This child has cute cheeks", hindi: "इस बच्चे के गाल प्यारे हैं"),
        ],
        871: [
            WordExample(thai: "ฉันเจ็บคาง", romanization: "chǎn jèp kaang", english: "My chin hurts", hindi: "मेरी ठोड़ी में दर्द है"),
            WordExample(thai: "คางของเขายาว", romanization: "kaang kǒng kǎo yaao", english: "His chin is long", hindi: "उसकी ठोड़ी लंबी है"),
        ],
        872: [
            WordExample(thai: "หน้าผากของฉันร้อน", romanization: "nâa-pàak kǒng chǎn róon", english: "My forehead is hot", hindi: "मेरा माथा गरम है"),
            WordExample(thai: "เขามีแผลที่หน้าผาก", romanization: "kǎo mii plǎe tîi nâa-pàak", english: "He has a wound on his forehead", hindi: "उसके माथे पर घाव है"),
        ],
        873: [
            WordExample(thai: "ริมฝีปากของฉันแห้ง", romanization: "rim-fǐi-pàak kǒng chǎn hâeng", english: "My lips are dry", hindi: "मेरे होंठ सूखे हैं"),
            WordExample(thai: "ริมฝีปากของเขาสวย", romanization: "rim-fǐi-pàak kǒng kǎo sǔai", english: "Her lips are pretty", hindi: "उसके होंठ सुंदर हैं"),
        ],
        874: [
            WordExample(thai: "ฉันเจ็บเอว", romanization: "chǎn jèp eo", english: "My waist hurts", hindi: "मेरी कमर में दर्द है"),
            WordExample(thai: "เอวของเขาเล็ก", romanization: "eo kǒng kǎo lék", english: "Her waist is small", hindi: "उसकी कमर पतली है"),
        ],
        875: [
            WordExample(thai: "ฉันเจ็บสะโพก", romanization: "chǎn jèp sà-pôok", english: "My hip hurts", hindi: "मेरे कूल्हे में दर्द है"),
            WordExample(thai: "สะโพกของเขาใหญ่", romanization: "sà-pôok kǒng kǎo yài", english: "His hips are big", hindi: "उसके कूल्हे बड़े हैं"),
        ],
        876: [
            WordExample(thai: "นั่งนานก้นเจ็บ", romanization: "nâng naan kôn jèp", english: "Sitting long makes the bottom hurt", hindi: "देर तक बैठने से नितंब दुखते हैं"),
            WordExample(thai: "ฉันเจ็บก้น", romanization: "chǎn jèp kôn", english: "My bottom hurts", hindi: "मेरे नितंब में दर्द है"),
        ],
        877: [
            WordExample(thai: "ฉันเจ็บหน้าอก", romanization: "chǎn jèp nâa-òk", english: "My chest hurts", hindi: "मेरी छाती में दर्द है"),
            WordExample(thai: "หน้าอกของเขาใหญ่", romanization: "nâa-òk kǒng kǎo yài", english: "His chest is big", hindi: "उसकी छाती चौड़ी है"),
        ],
        878: [
            WordExample(thai: "กระดูกของฉันแข็งแรง", romanization: "krà-dùuk kǒng chǎn kǎeng-raeng", english: "My bones are strong", hindi: "मेरी हड्डियां मजबूत हैं"),
            WordExample(thai: "หมอดูกระดูกของเขา", romanization: "mǒo duu krà-dùuk kǒng kǎo", english: "The doctor looks at his bones", hindi: "डॉक्टर उसकी हड्डियां देखते हैं"),
        ],
        879: [
            WordExample(thai: "กล้ามเนื้อของเขาใหญ่", romanization: "klâam-núea kǒng kǎo yài", english: "His muscles are big", hindi: "उसकी मांसपेशियां बड़ी हैं"),
            WordExample(thai: "ฉันเจ็บกล้ามเนื้อ", romanization: "chǎn jèp klâam-núea", english: "My muscles hurt", hindi: "मेरी मांसपेशियों में दर्द है"),
        ],
        880: [
            WordExample(thai: "สมองของเขาดีมาก", romanization: "sà-mǒong kǒng kǎo dii mâak", english: "His brain is very good", hindi: "उसका दिमाग बहुत अच्छा है"),
            WordExample(thai: "ฉันใช้สมองมาก", romanization: "chǎn chái sà-mǒong mâak", english: "I use my brain a lot", hindi: "मैं दिमाग बहुत इस्तेमाल करती हूं"),
        ],
        881: [
            WordExample(thai: "ปอดของเขาแข็งแรง", romanization: "pòot kǒng kǎo kǎeng-raeng", english: "His lungs are strong", hindi: "उसके फेफड़े मजबूत हैं"),
            WordExample(thai: "หมอดูปอดของฉัน", romanization: "mǒo duu pòot kǒng chǎn", english: "The doctor checks my lungs", hindi: "डॉक्टर मेरे फेफड़े देखते हैं"),
        ],
        882: [
            WordExample(thai: "ฉันเจ็บข้อมือ", romanization: "chǎn jèp kôo-muue", english: "My wrist hurts", hindi: "मेरी कलाई में दर्द है"),
            WordExample(thai: "ข้อมือของเขาเล็ก", romanization: "kôo-muue kǒng kǎo lék", english: "Her wrist is small", hindi: "उसकी कलाई पतली है"),
        ],
        883: [
            WordExample(thai: "ฉันเจ็บข้อเท้า", romanization: "chǎn jèp kôo-táo", english: "My ankle hurts", hindi: "मेरे टखने में दर्द है"),
            WordExample(thai: "ข้อเท้าของเขาบวม", romanization: "kôo-táo kǒng kǎo buam", english: "His ankle is swollen", hindi: "उसका टखना सूजा है"),
        ],
        884: [
            WordExample(thai: "ส้นเท้าของฉันเจ็บ", romanization: "sôn-táo kǒng chǎn jèp", english: "My heel hurts", hindi: "मेरी एड़ी में दर्द है"),
            WordExample(thai: "ส้นเท้าของเขาแห้ง", romanization: "sôn-táo kǒng kǎo hâeng", english: "His heels are dry", hindi: "उसकी एड़ियां सूखी हैं"),
        ],
        885: [
            WordExample(thai: "ฝ่ามือของฉันร้อน", romanization: "fàa-muue kǒng chǎn róon", english: "My palm is hot", hindi: "मेरी हथेली गरम है"),
            WordExample(thai: "เขาดูฝ่ามือของฉัน", romanization: "kǎo duu fàa-muue kǒng chǎn", english: "He looks at my palm", hindi: "वह मेरी हथेली देखता है"),
        ],
        886: [
            WordExample(thai: "ฉันเจ็บนิ้วโป้ง", romanization: "chǎn jèp níw-pôong", english: "My thumb hurts", hindi: "मेरे अंगूठे में दर्द है"),
            WordExample(thai: "นิ้วโป้งของเขาใหญ่", romanization: "níw-pôong kǒng kǎo yài", english: "His thumb is big", hindi: "उसका अंगूठा बड़ा है"),
        ],
        887: [
            WordExample(thai: "เขามีหนวดยาว", romanization: "kǎo mii nùat yaao", english: "He has a long mustache", hindi: "उसकी मूंछें लंबी हैं"),
            WordExample(thai: "พ่อของฉันมีหนวด", romanization: "pôo kǒng chǎn mii nùat", english: "My father has a mustache", hindi: "मेरे पिता की मूंछें हैं"),
        ],
        888: [
            WordExample(thai: "เขามีเครายาว", romanization: "kǎo mii krao yaao", english: "He has a long beard", hindi: "उसकी दाढ़ी लंबी है"),
            WordExample(thai: "ฉันไม่ชอบเครา", romanization: "chǎn mâi chôop krao", english: "I do not like beards", hindi: "मुझे दाढ़ी पसंद नहीं है"),
        ],
        889: [
            WordExample(thai: "ร่างกายของเขาแข็งแรงมาก", romanization: "râang-kaai kǒng kǎo kǎeng-raeng mâak", english: "His body is very strong", hindi: "उसका शरीर बहुत मजबूत है"),
            WordExample(thai: "ฉันดูแลร่างกาย", romanization: "chǎn duu-lae râang-kaai", english: "I take care of my body", hindi: "मैं अपने शरीर का ख्याल रखती हूं"),
        ],
        890: [
            WordExample(thai: "ผมจามมากครับ", romanization: "phǒm jaam mâak khráp", english: "I sneeze a lot", hindi: "मुझे बहुत छींकें आ रही हैं"),
            WordExample(thai: "ฉันเป็นหวัดและจาม", romanization: "chǎn pen wàt láe jaam", english: "I have a cold and sneeze", hindi: "मुझे जुकाम है और छींकें आती हैं"),
        ],
        891: [
            WordExample(thai: "ผมเจ็บคอมากครับ", romanization: "phǒm jèp-khoo mâak khráp", english: "My throat hurts a lot", hindi: "मेरे गले में बहुत दर्द है"),
            WordExample(thai: "ฉันเจ็บคอวันนี้", romanization: "chǎn jèp-khoo wan-níi", english: "I have a sore throat today", hindi: "आज मेरे गले में दर्द है"),
        ],
        892: [
            WordExample(thai: "ผมปวดหัวมาก", romanization: "phǒm pùat-hǔa mâak", english: "I have a bad headache", hindi: "मुझे बहुत सिरदर्द है"),
            WordExample(thai: "เขาปวดหัวอยู่", romanization: "khǎo pùat-hǔa yùu", english: "He has a headache", hindi: "उसे सिरदर्द हो रहा है"),
        ],
        893: [
            WordExample(thai: "ฉันปวดท้องค่ะ", romanization: "chǎn pùat-thóong khâ", english: "I have a stomachache", hindi: "मुझे पेट में दर्द है"),
            WordExample(thai: "กินมากแล้วปวดท้อง", romanization: "kin mâak láew pùat-thóong", english: "Ate too much and got a stomachache", hindi: "ज़्यादा खाया और पेट दर्द हो गया"),
        ],
        894: [
            WordExample(thai: "ผมปวดฟันมากครับ", romanization: "phǒm pùat-fan mâak khráp", english: "I have a bad toothache", hindi: "मुझे दांत में बहुत दर्द है"),
            WordExample(thai: "ปวดฟันไปหาหมอ", romanization: "pùat-fan pai hǎa mǒo", english: "Toothache, go see the doctor", hindi: "दांत दर्द है, डॉक्टर के पास जाओ"),
        ],
        895: [
            WordExample(thai: "ผมท้องเสียครับ", romanization: "phǒm thóong-sǐa khráp", english: "I have diarrhea", hindi: "मुझे दस्त हैं"),
            WordExample(thai: "กินแล้วท้องเสีย", romanization: "kin láew thóong-sǐa", english: "Ate and got an upset stomach", hindi: "खाने के बाद पेट खराब हो गया"),
        ],
        896: [
            WordExample(thai: "เขาอาเจียนมาก", romanization: "khǎo aa-jian mâak", english: "He vomits a lot", hindi: "उसे बहुत उल्टी हो रही है"),
            WordExample(thai: "ฉันอาเจียนและเวียนหัว", romanization: "chǎn aa-jian láe wian-hǔa", english: "I vomit and feel dizzy", hindi: "मुझे उल्टी और चक्कर आ रहे हैं"),
        ],
        897: [
            WordExample(thai: "ผมเวียนหัวครับ", romanization: "phǒm wian-hǔa khráp", english: "I feel dizzy", hindi: "मुझे चक्कर आ रहा है"),
            WordExample(thai: "เขาเวียนหัวมากวันนี้", romanization: "khǎo wian-hǔa mâak wan-níi", english: "He feels very dizzy today", hindi: "आज उसे बहुत चक्कर आ रहे हैं"),
        ],
        898: [
            WordExample(thai: "ผมมีน้ำมูกครับ", romanization: "phǒm mii nám-mûuk khráp", english: "I have a runny nose", hindi: "मेरी नाक बह रही है"),
            WordExample(thai: "เขาเป็นหวัดมีน้ำมูก", romanization: "khǎo pen wàt mii nám-mûuk", english: "He has a cold with a runny nose", hindi: "उसे जुकाम है और नाक बह रही है"),
        ],
        899: [
            WordExample(thai: "วันนี้ผมไม่สบาย", romanization: "wan-níi phǒm mâi-sà-baai", english: "Today I am unwell", hindi: "आज मेरी तबीयत खराब है"),
            WordExample(thai: "เขาไม่สบายอยู่ที่บ้าน", romanization: "khǎo mâi-sà-baai yùu thîi bâan", english: "He is unwell at home", hindi: "वह बीमार है और घर पर है"),
        ],
        900: [
            WordExample(thai: "อาการดีขึ้นแล้ว", romanization: "aa-kaan dii-khûen láew", english: "The symptoms are better now", hindi: "लक्षण अब बेहतर हैं"),
            WordExample(thai: "อาการไม่ดีครับ", romanization: "aa-kaan mâi dii khráp", english: "The condition is not good", hindi: "हालत ठीक नहीं है"),
        ],
        901: [
            WordExample(thai: "สุขภาพดีมากครับ", romanization: "sùk-khà-phâap dii mâak khráp", english: "Very good health", hindi: "सेहत बहुत अच्छी है"),
            WordExample(thai: "สุขภาพของเขาดี", romanization: "sùk-khà-phâap khǒong khǎo dii", english: "His health is good", hindi: "उसकी सेहत अच्छी है"),
        ],
        902: [
            WordExample(thai: "เขาแข็งแรงมาก", romanization: "khǎo khǎeng-raeng mâak", english: "He is very healthy", hindi: "वह बहुत तंदुरुस्त है"),
            WordExample(thai: "ผมอยากแข็งแรง", romanization: "phǒm yàak khǎeng-raeng", english: "I want to be healthy", hindi: "मैं तंदुरुस्त होना चाहता हूँ"),
        ],
        903: [
            WordExample(thai: "ผมหายแล้วครับ", romanization: "phǒm hǎai láew khráp", english: "I have recovered", hindi: "मैं ठीक हो गया हूँ"),
            WordExample(thai: "เขายังไม่หาย", romanization: "khǎo yang mâi hǎai", english: "He has not recovered yet", hindi: "वह अभी ठीक नहीं हुआ है"),
        ],
        904: [
            WordExample(thai: "วันนี้ดีขึ้นมากค่ะ", romanization: "wan-níi dii-khûen mâak khâ", english: "Today it is much better", hindi: "आज बहुत बेहतर है"),
            WordExample(thai: "อาการเขาดีขึ้น", romanization: "aa-kaan khǎo dii-khûen", english: "His condition is better", hindi: "उसकी हालत बेहतर है"),
        ],
        905: [
            WordExample(thai: "ผมหายใจไม่ออก", romanization: "phǒm hǎai-jai mâi òok", english: "I cannot breathe", hindi: "मुझे सांस नहीं आ रही है"),
            WordExample(thai: "หายใจดีขึ้นแล้ว", romanization: "hǎai-jai dii-khûen láew", english: "Breathing is better now", hindi: "अब सांस बेहतर चल रही है"),
        ],
        906: [
            WordExample(thai: "คลินิกอยู่ที่นี่", romanization: "khlii-ník yùu thîi-nîi", english: "The clinic is here", hindi: "क्लिनिक यहाँ है"),
            WordExample(thai: "ผมไปคลินิกครับ", romanization: "phǒm pai khlii-ník khráp", english: "I am going to the clinic", hindi: "मैं क्लिनिक जा रहा हूँ"),
        ],
        907: [
            WordExample(thai: "ผมไม่ชอบฉีดยา", romanization: "phǒm mâi chôop chìit-yaa", english: "I do not like injections", hindi: "मुझे इंजेक्शन पसंद नहीं है"),
            WordExample(thai: "หมอฉีดยาให้ผม", romanization: "mǒo chìit-yaa hâi phǒm", english: "The doctor gave me an injection", hindi: "डॉक्टर ने मुझे इंजेक्शन लगाया"),
        ],
        908: [
            WordExample(thai: "คนไข้อยู่ที่นี่", romanization: "khon-khâi yùu thîi nîi", english: "The patient is here", hindi: "मरीज़ यहाँ है"),
            WordExample(thai: "วันนี้มีคนไข้มาก", romanization: "wan-níi mii khon-khâi mâak", english: "Today there are many patients", hindi: "आज बहुत मरीज़ हैं"),
        ],
        909: [
            WordExample(thai: "กินยาเม็ดนี้", romanization: "kin yaa-mét níi", english: "Take this pill", hindi: "यह गोली खाओ"),
            WordExample(thai: "ยาเม็ดนี้ขมมาก", romanization: "yaa-mét níi khǒm mâak", english: "This pill is very bitter", hindi: "यह गोली बहुत कड़वी है"),
        ],
        910: [
            WordExample(thai: "ผมไปฉีดวัคซีน", romanization: "pǒm pai chìit wák-siin", english: "I go to get vaccinated", hindi: "मैं टीका लगवाने जाता हूँ"),
            WordExample(thai: "วัคซีนนี้ดีมาก", romanization: "wák-siin níi dii mâak", english: "This vaccine is very good", hindi: "यह टीका बहुत अच्छा है"),
        ],
        911: [
            WordExample(thai: "หมอตรวจคนไข้", romanization: "mǒr trùat khon-khâi", english: "The doctor examines the patient", hindi: "डॉक्टर मरीज़ की जांच करता है"),
            WordExample(thai: "ผมไปตรวจที่โรงพยาบาล", romanization: "pǒm pai trùat thîi roong-phá-yaa-baan", english: "I go for a checkup at the hospital", hindi: "मैं जांच के लिए अस्पताल जाता हूँ"),
        ],
        912: [
            WordExample(thai: "เขาต้องผ่าตัด", romanization: "khǎo tông phàa-tàt", english: "He needs surgery", hindi: "उसका ऑपरेशन होना है"),
            WordExample(thai: "หมอผ่าตัดวันนี้", romanization: "mǒr phàa-tàt wan-níi", english: "The doctor operates today", hindi: "डॉक्टर आज ऑपरेशन करता है"),
        ],
        913: [
            WordExample(thai: "ผมใส่หน้ากาก", romanization: "pǒm sài nâa-kàak", english: "I wear a mask", hindi: "मैं मास्क पहनता हूँ"),
            WordExample(thai: "ใส่หน้ากากนะครับ", romanization: "sài nâa-kàak ná khráp", english: "Please wear a mask", hindi: "मास्क पहनिए"),
        ],
        // Batch 5
        914: [
            WordExample(thai: "ฉันอาบน้ำทุกวัน", romanization: "chǎn àap-náam thúk-wan", english: "I shower every day.", hindi: "मैं रोज़ नहाती हूँ।"),
            WordExample(thai: "เขาไปอาบน้ำ", romanization: "khǎo pai àap-náam", english: "He went to take a shower.", hindi: "वह नहाने गया।"),
        ],
        915: [
            WordExample(thai: "แชมพูหอมมาก", romanization: "chaem-phuu hǒm mâak", english: "The shampoo smells very nice.", hindi: "शैम्पू बहुत खुशबूदार है।"),
            WordExample(thai: "ฉันซื้อแชมพูใหม่", romanization: "chǎn súe chaem-phuu mài", english: "I bought new shampoo.", hindi: "मैंने नया शैम्पू खरीदा।"),
        ],
        916: [
            WordExample(thai: "ฝักบัวอยู่ในห้องน้ำ", romanization: "fàk-bua yùu nai hông-náam", english: "The shower is in the bathroom.", hindi: "शावर बाथरूम में है।"),
            WordExample(thai: "ฝักบัวเสีย", romanization: "fàk-bua sǐa", english: "The shower is broken.", hindi: "शावर खराब है।"),
        ],
        917: [
            WordExample(thai: "ชักโครกเสีย", romanization: "chák-khrôok sǐa", english: "The toilet is broken.", hindi: "कमोड खराब है।"),
            WordExample(thai: "ชักโครกสะอาดดี", romanization: "chák-khrôok sà-àat dii", english: "The toilet is nice and clean.", hindi: "कमोड साफ़-सुथरा है।"),
        ],
        918: [
            WordExample(thai: "อ่างล้างหน้าสะอาดมาก", romanization: "àang-láang-nâa sà-àat mâak", english: "The washbasin is very clean.", hindi: "वॉशबेसिन बहुत साफ़ है।"),
            WordExample(thai: "ฉันล้างมือที่อ่างล้างหน้า", romanization: "chǎn láang-mue thîi àang-láang-nâa", english: "I wash my hands at the washbasin.", hindi: "मैं वॉशबेसिन पर हाथ धोती हूँ।"),
        ],
        919: [
            WordExample(thai: "อ่างอาบน้ำใหญ่มาก", romanization: "àang-àap-náam yài mâak", english: "The bathtub is very big.", hindi: "बाथटब बहुत बड़ा है।"),
            WordExample(thai: "ฉันชอบอ่างอาบน้ำ", romanization: "chǎn chôp àang-àap-náam", english: "I like the bathtub.", hindi: "मुझे बाथटब पसंद है।"),
        ],
        920: [
            WordExample(thai: "ก๊อกน้ำเสีย", romanization: "kók-náam sǐa", english: "The tap is broken.", hindi: "नल खराब है।"),
            WordExample(thai: "ฉันเปิดก๊อกน้ำ", romanization: "chǎn pèrt kók-náam", english: "I turn on the tap.", hindi: "मैं नल खोलती हूँ।"),
        ],
        921: [
            WordExample(thai: "ขอทิชชู่หน่อย", romanization: "khǒ thít-chûu nòi", english: "Some tissue please.", hindi: "थोड़ा टिशू देना।"),
            WordExample(thai: "ทิชชู่หมดแล้ว", romanization: "thít-chûu mòt láew", english: "The tissue is finished.", hindi: "टिशू खत्म हो गया।"),
        ],
        922: [
            WordExample(thai: "กระดาษชำระหมดแล้ว", romanization: "krà-dàat-cham-rá mòt láew", english: "The toilet paper is finished.", hindi: "टॉयलेट पेपर खत्म हो गया।"),
            WordExample(thai: "ฉันซื้อกระดาษชำระ", romanization: "chǎn súe krà-dàat-cham-rá", english: "I buy toilet paper.", hindi: "मैं टॉयलेट पेपर खरीदती हूँ।"),
        ],
        923: [
            WordExample(thai: "ล้างมือก่อนกินข้าว", romanization: "láang-mue kòn kin khâo", english: "Wash your hands before eating.", hindi: "खाने से पहले हाथ धोओ।"),
            WordExample(thai: "ฉันไปล้างมือ", romanization: "chǎn pai láang-mue", english: "I am going to wash my hands.", hindi: "मैं हाथ धोने जा रही हूँ।"),
        ],
        924: [
            WordExample(thai: "ฉันล้างหน้าทุกเช้า", romanization: "chǎn láang-nâa thúk cháo", english: "I wash my face every morning.", hindi: "मैं हर सुबह चेहरा धोती हूँ।"),
            WordExample(thai: "เขาล้างหน้าด้วยสบู่", romanization: "khǎo láang-nâa dûai sà-bùu", english: "He washes his face with soap.", hindi: "वह साबुन से चेहरा धोता है।"),
        ],
        925: [
            WordExample(thai: "ฉันแปรงฟันทุกวัน", romanization: "chǎn praeng-fan thúk-wan", english: "I brush my teeth every day.", hindi: "मैं रोज़ दाँत ब्रश करती हूँ।"),
            WordExample(thai: "แปรงฟันก่อนนอน", romanization: "praeng-fan kòn non", english: "Brush your teeth before bed.", hindi: "सोने से पहले दाँत ब्रश करो।"),
        ],
        926: [
            WordExample(thai: "ฉันสระผมทุกวัน", romanization: "chǎn sà-phǒm thúk-wan", english: "I wash my hair every day.", hindi: "मैं रोज़ बाल धोती हूँ।"),
            WordExample(thai: "เขาสระผมด้วยแชมพู", romanization: "khǎo sà-phǒm dûai chaem-phuu", english: "He washes his hair with shampoo.", hindi: "वह शैम्पू से बाल धोता है।"),
        ],
        927: [
            WordExample(thai: "หวีอยู่ที่ไหน", romanization: "wǐi yùu thîi-nǎi", english: "Where is the comb?", hindi: "कंघी कहाँ है?"),
            WordExample(thai: "ฉันซื้อหวีใหม่", romanization: "chǎn súe wǐi mài", english: "I bought a new comb.", hindi: "मैंने नई कंघी खरीदी।"),
        ],
        928: [
            WordExample(thai: "มีดโกนอยู่ในห้องน้ำ", romanization: "mîit-koon yùu nai hông-náam", english: "The razor is in the bathroom.", hindi: "रेज़र बाथरूम में है।"),
            WordExample(thai: "ฉันซื้อมีดโกนใหม่", romanization: "chǎn súe mîit-koon mài", english: "I bought a new razor.", hindi: "मैंने नया रेज़र खरीदा।"),
        ],
        929: [
            WordExample(thai: "เขาโกนหนวดทุกเช้า", romanization: "khǎo koon-nùat thúk cháo", english: "He shaves every morning.", hindi: "वह हर सुबह दाढ़ी बनाता है।"),
            WordExample(thai: "ผมโกนหนวดแล้ว", romanization: "phǒm koon-nùat láew", english: "I have already shaved.", hindi: "मैंने दाढ़ी बना ली।"),
        ],
        930: [
            WordExample(thai: "โลชั่นหอมมาก", romanization: "loo-chân hǒm mâak", english: "The lotion smells very nice.", hindi: "लोशन बहुत खुशबूदार है।"),
            WordExample(thai: "ฉันใช้โลชั่นทุกวัน", romanization: "chǎn chái loo-chân thúk-wan", english: "I use lotion every day.", hindi: "मैं रोज़ लोशन लगाती हूँ।"),
        ],
        931: [
            WordExample(thai: "ฉันชอบน้ำหอมนี้", romanization: "chǎn chôp nám-hǒm níi", english: "I like this perfume.", hindi: "मुझे यह परफ़्यूम पसंद है।"),
            WordExample(thai: "คุณใช้น้ำหอมไหม", romanization: "khun chái nám-hǒm mái", english: "Do you use perfume?", hindi: "क्या आप परफ़्यूम लगाते हैं?"),
        ],
        932: [
            WordExample(thai: "ฉันล้างจานด้วยฟองน้ำ", romanization: "chǎn láang jaan dûai fong-náam", english: "I wash dishes with a sponge.", hindi: "मैं स्पंज से बर्तन धोती हूँ।"),
            WordExample(thai: "ฟองน้ำอยู่ที่ไหน", romanization: "fong-náam yùu thîi-nǎi", english: "Where is the sponge?", hindi: "स्पंज कहाँ है?"),
        ],
        933: [
            WordExample(thai: "วันนี้ไม่มีน้ำร้อน", romanization: "wan-níi mâi mii nám-rón", english: "There is no hot water today.", hindi: "आज गरम पानी नहीं है।"),
            WordExample(thai: "ขอน้ำร้อนหน่อย", romanization: "khǒ nám-rón nòi", english: "Some hot water please.", hindi: "थोड़ा गरम पानी देना।"),
        ],
        934: [
            WordExample(thai: "ฉันชอบอาบน้ำอุ่น", romanization: "chǎn chôp àap nám-ùn", english: "I like warm showers.", hindi: "मुझे गुनगुने पानी से नहाना पसंद है।"),
            WordExample(thai: "ขอน้ำอุ่นหน่อย", romanization: "khǒ nám-ùn nòi", english: "Some warm water please.", hindi: "थोड़ा गुनगुना पानी देना।"),
        ],
        935: [
            WordExample(thai: "ผมเปียกแล้ว", romanization: "phǒm pìak láew", english: "My hair is wet.", hindi: "मेरे बाल गीले हैं।"),
            WordExample(thai: "เสื้อผ้าเปียกมาก", romanization: "sûea-phâa pìak mâak", english: "The clothes are very wet.", hindi: "कपड़े बहुत गीले हैं।"),
        ],
        936: [
            WordExample(thai: "ฉันเช็ดโต๊ะ", romanization: "chǎn chét tó", english: "I wipe the table.", hindi: "मैं मेज़ पोंछती हूँ।"),
            WordExample(thai: "เขาเช็ดกระจก", romanization: "khǎo chét krà-jòk", english: "He wipes the mirror.", hindi: "वह आईना पोंछता है।"),
        ],
        937: [
            WordExample(thai: "ห้องนั่งเล่นใหญ่มาก", romanization: "hôong-nâng-lên yài mâak", english: "The living room is very big", hindi: "लिविंग रूम बहुत बड़ा है"),
            WordExample(thai: "เขาอยู่ในห้องนั่งเล่น", romanization: "khǎo yùu nai hôong-nâng-lên", english: "He is in the living room", hindi: "वह लिविंग रूम में है"),
        ],
        938: [
            WordExample(thai: "บ้านนี้มีระเบียง", romanization: "bâan níi mii rá-biang", english: "This house has a balcony", hindi: "इस घर में बालकनी है"),
            WordExample(thai: "ฉันชอบนั่งที่ระเบียง", romanization: "chán chôop nâng thîi rá-biang", english: "I like sitting on the balcony", hindi: "मुझे बालकनी पर बैठना पसंद है"),
        ],
        939: [
            WordExample(thai: "บันไดอยู่ที่นี่", romanization: "ban-dai yùu thîi-nîi", english: "The stairs are here", hindi: "सीढ़ियाँ यहाँ हैं"),
            WordExample(thai: "ผมเดินขึ้นบันได", romanization: "phǒm dern khûen ban-dai", english: "I walk up the stairs", hindi: "मैं सीढ़ियाँ चढ़ता हूँ"),
        ],
        940: [
            WordExample(thai: "หลังคาบ้านสีแดง", romanization: "lǎng-khaa bâan sǐi deeng", english: "The house roof is red", hindi: "घर की छत लाल है"),
            WordExample(thai: "หลังคาเก่ามาก", romanization: "lǎng-khaa kào mâak", english: "The roof is very old", hindi: "छत बहुत पुरानी है"),
        ],
        941: [
            WordExample(thai: "ผนังสีขาว", romanization: "phà-nǎng sǐi khǎao", english: "The wall is white", hindi: "दीवार सफ़ेद है"),
            WordExample(thai: "ผนังห้องนี้สวย", romanization: "phà-nǎng hôong níi sǔai", english: "The wall of this room is beautiful", hindi: "इस कमरे की दीवार सुंदर है"),
        ],
        942: [
            WordExample(thai: "พื้นสะอาดมาก", romanization: "phúen sà-àat mâak", english: "The floor is very clean", hindi: "फ़र्श बहुत साफ़ है"),
            WordExample(thai: "พื้นห้องนอนเย็น", romanization: "phúen hôong-noon yen", english: "The bedroom floor is cool", hindi: "बेडरूम का फ़र्श ठंडा है"),
        ],
        943: [
            WordExample(thai: "เพดานสูงมาก", romanization: "phee-daan sǔung mâak", english: "The ceiling is very high", hindi: "सीलिंग बहुत ऊँची है"),
            WordExample(thai: "พัดลมอยู่ที่เพดาน", romanization: "phát-lom yùu thîi phee-daan", english: "The fan is on the ceiling", hindi: "पंखा सीलिंग पर है"),
        ],
        944: [
            WordExample(thai: "บ้านนี้มีรั้ว", romanization: "bâan níi mii rúa", english: "This house has a fence", hindi: "इस घर में बाड़ है"),
            WordExample(thai: "รั้วบ้านสีเขียว", romanization: "rúa bâan sǐi khǐao", english: "The house fence is green", hindi: "घर की बाड़ हरी है"),
        ],
        945: [
            WordExample(thai: "บ้านฉันมีสวนเล็ก", romanization: "bâan chán mii sǔan lék", english: "My house has a small garden", hindi: "मेरे घर में छोटा बगीचा है"),
            WordExample(thai: "ฉันชอบนั่งในสวน", romanization: "chán chôop nâng nai sǔan", english: "I like sitting in the garden", hindi: "मुझे बगीचे में बैठना पसंद है"),
        ],
        946: [
            WordExample(thai: "ห้องผมอยู่ชั้นสาม", romanization: "hôong phǒm yùu chán sǎam", english: "My room is on the third floor", hindi: "मेरा कमरा तीसरी मंज़िल पर है"),
            WordExample(thai: "บ้านนี้มีสองชั้น", romanization: "bâan níi mii sǒong chán", english: "This house has two floors", hindi: "इस घर में दो मंज़िलें हैं"),
        ],
        947: [
            WordExample(thai: "ลิฟต์อยู่ที่ไหนครับ", romanization: "líp yùu thîi-nǎi khráp", english: "Where is the elevator", hindi: "लिफ़्ट कहाँ है"),
            WordExample(thai: "ตึกนี้ไม่มีลิฟต์", romanization: "tùek níi mâi mii líp", english: "This building has no elevator", hindi: "इस इमारत में लिफ़्ट नहीं है"),
        ],
        948: [
            WordExample(thai: "ที่จอดรถอยู่ข้างล่าง", romanization: "thîi-jòot-rót yùu khâang-lâang", english: "The parking is downstairs", hindi: "पार्किंग नीचे है"),
            WordExample(thai: "คอนโดนี้มีที่จอดรถ", romanization: "khoon-doo níi mii thîi-jòot-rót", english: "This condo has parking", hindi: "इस कॉन्डो में पार्किंग है"),
        ],
        949: [
            WordExample(thai: "ฉันอยู่คอนโด", romanization: "chán yùu khoon-doo", english: "I live in a condo", hindi: "मैं कॉन्डो में रहती हूँ"),
            WordExample(thai: "คอนโดนี้แพงมาก", romanization: "khoon-doo níi pheeng mâak", english: "This condo is very expensive", hindi: "यह कॉन्डो बहुत महँगा है"),
        ],
        950: [
            WordExample(thai: "เขาอยู่หอพัก", romanization: "khǎo yùu hǒo-phák", english: "He lives in a dormitory", hindi: "वह हॉस्टल में रहता है"),
            WordExample(thai: "หอพักนี้ถูกมาก", romanization: "hǒo-phák níi thùuk mâak", english: "This dormitory is very cheap", hindi: "यह हॉस्टल बहुत सस्ता है"),
        ],
        951: [
            WordExample(thai: "ผมเช่าห้องที่นี่", romanization: "phǒm châo hôong thîi-nîi", english: "I rent a room here", hindi: "मैं यहाँ कमरा किराये पर लेता हूँ"),
            WordExample(thai: "เขาเช่าบ้านใหญ่", romanization: "khǎo châo bâan yài", english: "He rents a big house", hindi: "वह बड़ा घर किराये पर लेता है"),
        ],
        952: [
            WordExample(thai: "ค่าเช่าแพงมาก", romanization: "khâa-châo pheeng mâak", english: "The rent is very expensive", hindi: "किराया बहुत महँगा है"),
            WordExample(thai: "ค่าเช่าห้องนี้ถูก", romanization: "khâa-châo hôong níi thùuk", english: "The rent for this room is cheap", hindi: "इस कमरे का किराया सस्ता है"),
        ],
        953: [
            WordExample(thai: "ค่าน้ำเดือนนี้ถูก", romanization: "khâa-náam duean níi thùuk", english: "This month the water bill is cheap", hindi: "इस महीने पानी का बिल सस्ता है"),
            WordExample(thai: "ค่าน้ำไม่แพง", romanization: "khâa-náam mâi pheeng", english: "The water bill is not expensive", hindi: "पानी का बिल महँगा नहीं है"),
        ],
        954: [
            WordExample(thai: "ค่าไฟเดือนนี้แพง", romanization: "khâa-fai duean níi pheeng", english: "This month the electricity bill is expensive", hindi: "इस महीने बिजली का बिल महँगा है"),
            WordExample(thai: "ค่าไฟบ้านฉันถูก", romanization: "khâa-fai bâan chán thùuk", english: "My house electricity bill is cheap", hindi: "मेरे घर का बिजली का बिल सस्ता है"),
        ],
        955: [
            WordExample(thai: "เจ้าของบ้านใจดีมาก", romanization: "jâo-khǒong-bâan jai-dii mâak", english: "The landlord is very kind", hindi: "मकान मालिक बहुत दयालु हैं"),
            WordExample(thai: "เจ้าของบ้านอยู่ชั้นหนึ่ง", romanization: "jâo-khǒong-bâan yùu chán nùeng", english: "The landlord lives on the first floor", hindi: "मकान मालिक पहली मंज़िल पर रहते हैं"),
        ],
        956: [
            WordExample(thai: "โซฟานี้นั่งสบาย", romanization: "soo-faa níi nâng sà-baai", english: "This sofa is comfortable to sit on", hindi: "यह सोफ़ा बैठने में आरामदायक है"),
            WordExample(thai: "แมวนอนบนโซฟา", romanization: "meeo noon bon soo-faa", english: "The cat sleeps on the sofa", hindi: "बिल्ली सोफ़े पर सोती है"),
        ],
        957: [
            WordExample(thai: "เสื้อผ้าอยู่ในตู้เสื้อผ้า", romanization: "sûea-phâa yùu nai tûu-sûea-phâa", english: "The clothes are in the wardrobe", hindi: "कपड़े अलमारी में हैं"),
            WordExample(thai: "ตู้เสื้อผ้าใหญ่มาก", romanization: "tûu-sûea-phâa yài mâak", english: "The wardrobe is very big", hindi: "अलमारी बहुत बड़ी है"),
        ],
        958: [
            WordExample(thai: "ม่านสีฟ้าสวย", romanization: "mâan sǐi fáa sǔai", english: "The blue curtain is pretty", hindi: "नीला पर्दा सुंदर है"),
            WordExample(thai: "ช่วยเปิดม่านหน่อย", romanization: "chûai pèrt mâan nòi", english: "Please open the curtain", hindi: "ज़रा पर्दा खोल दीजिए"),
        ],
        959: [
            WordExample(thai: "พรมนุ่มมาก", romanization: "phrom nûm mâak", english: "The carpet is very soft", hindi: "कालीन बहुत मुलायम है"),
            WordExample(thai: "พรมอยู่ในห้องนอน", romanization: "phrom yùu nai hôong-noon", english: "The carpet is in the bedroom", hindi: "कालीन बेडरूम में है"),
        ],
        960: [
            WordExample(thai: "ถังขยะอยู่ในห้องครัว", romanization: "thǎng-khà-yà yùu nai hôong-khrua", english: "The trash bin is in the kitchen", hindi: "कूड़ेदान रसोई में है"),
            WordExample(thai: "ถังขยะเต็มแล้ว", romanization: "thǎng-khà-yà tem léeo", english: "The trash bin is full", hindi: "कूड़ेदान भर गया है"),
        ],
        961: [
            WordExample(thai: "ผมจะย้ายบ้านเดือนนี้", romanization: "phǒm jà yáai-bâan duean níi", english: "I will move house this month", hindi: "मैं इस महीने घर बदलूँगा"),
            WordExample(thai: "เขาย้ายบ้านแล้ว", romanization: "khǎo yáai-bâan léeo", english: "He has already moved house", hindi: "वह घर बदल चुका है"),
        ],
        962: [
            WordExample(thai: "ตู้อยู่ในห้องนอน", romanization: "tûu yùu nai hông-noon", english: "The cabinet is in the bedroom", hindi: "अलमारी बेडरूम में है"),
            WordExample(thai: "ตู้นี้ใหม่มาก", romanization: "tûu níi mài mâak", english: "This cabinet is very new", hindi: "यह अलमारी बहुत नई है"),
        ],
        963: [
            WordExample(thai: "ที่นอนนี้ดีมาก", romanization: "tîi-noon níi dii mâak", english: "This mattress is very good", hindi: "यह गद्दा बहुत अच्छा है"),
            WordExample(thai: "ฉันซื้อที่นอนใหม่", romanization: "chǎn súe tîi-noon mài", english: "I bought a new mattress", hindi: "मैंने नया गद्दा खरीदा"),
        ],
        964: [
            WordExample(thai: "นาฬิกาอยู่ที่นี่", romanization: "naa-lí-kaa yùu tîi-nîi", english: "The clock is here", hindi: "घड़ी यहाँ है"),
            WordExample(thai: "นาฬิกานี้สวยมาก", romanization: "naa-lí-kaa níi sǔai mâak", english: "This clock is very beautiful", hindi: "यह घड़ी बहुत सुंदर है"),
        ],
        965: [
            WordExample(thai: "กาต้มน้ำอยู่ที่นี่", romanization: "kaa-tôm-náam yùu tîi-nîi", english: "The kettle is here", hindi: "केतली यहाँ है"),
            WordExample(thai: "ฉันใช้กาต้มน้ำทุกวัน", romanization: "chǎn chái kaa-tôm-náam túk-wan", english: "I use the kettle every day", hindi: "मैं रोज केतली इस्तेमाल करती हूँ"),
        ],
        966: [
            WordExample(thai: "บ้านผมมีเครื่องซักผ้า", romanization: "bâan pǒm mii krûeang-sák-pâa", english: "My house has a washing machine", hindi: "मेरे घर में वॉशिंग मशीन है"),
            WordExample(thai: "เครื่องซักผ้าใหม่มาก", romanization: "krûeang-sák-pâa mài mâak", english: "The washing machine is very new", hindi: "वॉशिंग मशीन बहुत नई है"),
        ],
        967: [
            WordExample(thai: "เตารีดอยู่ที่นี่", romanization: "tao-rîit yùu tîi-nîi", english: "The iron is here", hindi: "इस्त्री यहाँ है"),
            WordExample(thai: "ฉันใช้เตารีดทุกวัน", romanization: "chǎn chái tao-rîit túk-wan", english: "I use the iron every day", hindi: "मैं रोज इस्त्री इस्तेमाल करती हूँ"),
        ],
        968: [
            WordExample(thai: "ไม้กวาดอยู่ที่นี่", romanization: "máai-kwàat yùu tîi-nîi", english: "The broom is here", hindi: "झाड़ू यहाँ है"),
            WordExample(thai: "ฉันซื้อไม้กวาดใหม่", romanization: "chǎn súe máai-kwàat mài", english: "I bought a new broom", hindi: "मैंने नया झाड़ू खरीदा"),
        ],
        969: [
            WordExample(thai: "หลอดไฟอยู่ในห้องนอน", romanization: "lòot-fai yùu nai hông-noon", english: "The light bulb is in the bedroom", hindi: "बल्ब बेडरूम में है"),
            WordExample(thai: "ฉันซื้อหลอดไฟใหม่", romanization: "chǎn súe lòot-fai mài", english: "I bought a new light bulb", hindi: "मैंने नया बल्ब खरीदा"),
        ],
        970: [
            WordExample(thai: "ปลั๊กไฟอยู่ที่นี่", romanization: "plák-fai yùu tîi-nîi", english: "The outlet is here", hindi: "प्लग यहाँ है"),
            WordExample(thai: "ห้องนอนมีปลั๊กไฟ", romanization: "hông-noon mii plák-fai", english: "The bedroom has an outlet", hindi: "बेडरूम में प्लग है"),
        ],
        971: [
            WordExample(thai: "กุญแจอยู่ในลิ้นชัก", romanization: "kun-jae yùu nai lín-chák", english: "The key is in the drawer", hindi: "चाबी दराज में है"),
            WordExample(thai: "ลิ้นชักนี้เล็กมาก", romanization: "lín-chák níi lék mâak", english: "This drawer is very small", hindi: "यह दराज बहुत छोटी है"),
        ],
        972: [
            WordExample(thai: "ไมโครเวฟอยู่ที่ห้องครัว", romanization: "mai-khroo-wéep yùu thîi hôong-khrua", english: "The microwave is in the kitchen", hindi: "माइक्रोवेव रसोई में है"),
            WordExample(thai: "ผมใช้ไมโครเวฟทุกวัน", romanization: "phǒm chái mai-khroo-wéep thúk-wan", english: "I use the microwave every day", hindi: "मैं रोज़ माइक्रोवेव इस्तेमाल करता हूँ"),
        ],
        973: [
            WordExample(thai: "ฉันมีหม้อหุงข้าวที่บ้าน", romanization: "chǎn mii môr-hǔng-khâao thîi bâan", english: "I have a rice cooker at home", hindi: "मेरे घर में राइस कुकर है"),
            WordExample(thai: "หม้อหุงข้าวใหม่มาก", romanization: "môr-hǔng-khâao mài mâak", english: "The rice cooker is very new", hindi: "राइस कुकर बहुत नया है"),
        ],
        974: [
            WordExample(thai: "เตาแก๊สอยู่ในห้องครัว", romanization: "tao-káet yùu nai hôong-khrua", english: "The gas stove is in the kitchen", hindi: "गैस चूल्हा रसोई में है"),
            WordExample(thai: "แม่ใช้เตาแก๊สทุกวัน", romanization: "mâe chái tao-káet thúk-wan", english: "Mom uses the gas stove every day", hindi: "माँ रोज़ गैस चूल्हा इस्तेमाल करती हैं"),
        ],
        975: [
            WordExample(thai: "เตาอบร้อนมาก", romanization: "tao-òp róon mâak", english: "The oven is very hot", hindi: "ओवन बहुत गरम है"),
            WordExample(thai: "บ้านผมไม่มีเตาอบ", romanization: "bâan phǒm mâi mii tao-òp", english: "My house has no oven", hindi: "मेरे घर में ओवन नहीं है"),
        ],
        976: [
            WordExample(thai: "จานอยู่ในอ่างล้างจาน", romanization: "jaan yùu nai àang-láang-jaan", english: "The plates are in the sink", hindi: "प्लेटें सिंक में हैं"),
            WordExample(thai: "อ่างล้างจานสะอาดดี", romanization: "àang-láang-jaan sà-àat dii", english: "The sink is nice and clean", hindi: "सिंक अच्छा साफ़ है"),
        ],
        977: [
            WordExample(thai: "น้ำยาล้างจานหมดแล้ว", romanization: "nám-yaa-láang-jaan mòt láew", english: "The dish soap is finished", hindi: "बर्तन का साबुन ख़त्म हो गया"),
            WordExample(thai: "ผมไปซื้อน้ำยาล้างจาน", romanization: "phǒm pai súe nám-yaa-láang-jaan", english: "I go buy dish soap", hindi: "मैं बर्तन का साबुन खरीदने जाता हूँ"),
        ],
        978: [
            WordExample(thai: "เขียงอยู่บนโต๊ะ", romanization: "khǐang yùu bon tó", english: "The cutting board is on the table", hindi: "चॉपिंग बोर्ड मेज़ पर है"),
            WordExample(thai: "เขียงอันนี้ใหญ่มาก", romanization: "khǐang an-níi yài mâak", english: "This cutting board is very big", hindi: "यह चॉपिंग बोर्ड बहुत बड़ा है"),
        ],
        979: [
            WordExample(thai: "ทัพพีอยู่ในหม้อ", romanization: "tháp-phii yùu nai môr", english: "The ladle is in the pot", hindi: "करछुल पतीले में है"),
            WordExample(thai: "ฉันใช้ทัพพีตักข้าว", romanization: "chǎn chái tháp-phii tàk khâao", english: "I use a ladle to scoop rice", hindi: "मैं करछुल से चावल निकालती हूँ"),
        ],
        980: [
            WordExample(thai: "ตะหลิวอยู่ที่เตา", romanization: "tà-lǐu yùu thîi tao", english: "The spatula is at the stove", hindi: "पलटा चूल्हे के पास है"),
            WordExample(thai: "ผมใช้ตะหลิวทอดไข่", romanization: "phǒm chái tà-lǐu thôot khài", english: "I fry an egg with a spatula", hindi: "मैं पलटे से अंडा तलता हूँ"),
        ],
        981: [
            WordExample(thai: "ครกอยู่ในห้องครัว", romanization: "khrók yùu nai hôong-khrua", english: "The mortar is in the kitchen", hindi: "ओखली रसोई में है"),
            WordExample(thai: "แม่ทำส้มตำด้วยครก", romanization: "mâe tham sôm-tam dûay khrók", english: "Mom makes som tam with a mortar", hindi: "माँ ओखली से सोम-तम बनाती हैं"),
        ],
        982: [
            WordExample(thai: "สากอยู่ในครก", romanization: "sàak yùu nai khrók", english: "The pestle is in the mortar", hindi: "मूसल ओखली में है"),
            WordExample(thai: "สากอันนี้หนักมาก", romanization: "sàak an-níi nàk mâak", english: "This pestle is very heavy", hindi: "यह मूसल बहुत भारी है"),
        ],
        983: [
            WordExample(thai: "ถาดอยู่บนโต๊ะ", romanization: "thàat yùu bon tó", english: "The tray is on the table", hindi: "ट्रे मेज़ पर है"),
            WordExample(thai: "ฉันวางแก้วบนถาด", romanization: "chǎn waang kâew bon thàat", english: "I place the glass on the tray", hindi: "मैं गिलास ट्रे पर रखती हूँ"),
        ],
        984: [
            WordExample(thai: "ฝาหม้ออยู่ไหน", romanization: "fǎa môr yùu nǎi", english: "Where is the pot lid?", hindi: "पतीले का ढक्कन कहाँ है?"),
            WordExample(thai: "ปิดฝาหม้อด้วยครับ", romanization: "pìt fǎa môr dûay khráp", english: "Please close the pot lid", hindi: "पतीले का ढक्कन बंद कर दीजिए"),
        ],
        985: [
            WordExample(thai: "ฉันมีกระติกน้ำใหม่", romanization: "chǎn mii krà-tìk-náam mài", english: "I have a new flask", hindi: "मेरे पास नया थर्मस है"),
            WordExample(thai: "กระติกน้ำของผมสีฟ้า", romanization: "krà-tìk-náam khǒong phǒm sǐi-fáa", english: "My flask is blue", hindi: "मेरा थर्मस नीला है"),
        ],
        986: [
            WordExample(thai: "เครื่องปั่นเสียงดังมาก", romanization: "khrûeang-pàn sǐang dang mâak", english: "The blender is very loud", hindi: "ब्लेंडर बहुत आवाज़ करता है"),
            WordExample(thai: "ฉันปั่นผลไม้ด้วยเครื่องปั่น", romanization: "chǎn pàn phǒn-lá-mái dûay khrûeang-pàn", english: "I blend fruit with the blender", hindi: "मैं ब्लेंडर में फल पीसती हूँ"),
        ],
        987: [
            WordExample(thai: "ที่เปิดขวดอยู่ไหน", romanization: "thîi-pèrt-khùat yùu nǎi", english: "Where is the bottle opener?", hindi: "बोतल ओपनर कहाँ है?"),
            WordExample(thai: "ขอที่เปิดขวดหน่อยครับ", romanization: "khǒo thîi-pèrt-khùat nòi khráp", english: "May I have the bottle opener?", hindi: "ज़रा बोतल ओपनर दीजिए"),
        ],
        988: [
            WordExample(thai: "กรรไกรอยู่ในกล่อง", romanization: "kan-krai yùu nai klòng", english: "The scissors are in the box", hindi: "कैंची डिब्बे में है"),
            WordExample(thai: "กรรไกรอันนี้คมมาก", romanization: "kan-krai an-níi khom mâak", english: "These scissors are very sharp", hindi: "यह कैंची बहुत तेज़ है"),
        ],
        989: [
            WordExample(thai: "แม่ใส่ผ้ากันเปื้อน", romanization: "mâe sài phâa-kan-pûean", english: "Mom wears an apron", hindi: "माँ एप्रन पहनती हैं"),
            WordExample(thai: "ผ้ากันเปื้อนสีขาว", romanization: "phâa-kan-pûean sǐi khǎao", english: "The apron is white", hindi: "एप्रन सफ़ेद है"),
        ],
        990: [
            WordExample(thai: "แก้วอยู่บนชั้นวางของ", romanization: "kâew yùu bon chán-waang-khǒong", english: "The glass is on the shelf", hindi: "गिलास शेल्फ पर है"),
            WordExample(thai: "ชั้นวางของสูงมาก", romanization: "chán-waang-khǒong sǔung mâak", english: "The shelf is very tall", hindi: "शेल्फ बहुत ऊँची है"),
        ],
        991: [
            WordExample(thai: "แก๊สหมดแล้ว", romanization: "káet mòt láew", english: "The gas is finished", hindi: "गैस ख़त्म हो गई"),
            WordExample(thai: "บ้านผมใช้เตาแก๊ส", romanization: "bâan phǒm chái tao-káet", english: "My house uses a gas stove", hindi: "मेरे घर में गैस चूल्हा चलता है"),
        ],
        992: [
            WordExample(thai: "ขอถุงหน่อยครับ", romanization: "khǒo thǔng nòi khráp", english: "A bag please", hindi: "ज़रा एक थैली दीजिए"),
            WordExample(thai: "ถุงนี้ใหญ่มาก", romanization: "thǔng níi yài mâak", english: "This bag is very big", hindi: "यह थैली बहुत बड़ी है"),
        ],
        993: [
            WordExample(thai: "ข้าวอยู่ในกล่อง", romanization: "khâao yùu nai klòng", english: "The rice is in the box", hindi: "चावल डिब्बे में है"),
            WordExample(thai: "กล่องนี้เล็กมาก", romanization: "klòng níi lék mâak", english: "This box is very small", hindi: "यह डिब्बा बहुत छोटा है"),
        ],
        994: [
            WordExample(thai: "เหยือกน้ำอยู่บนโต๊ะ", romanization: "yùeak náam yùu bon tó", english: "The water jug is on the table", hindi: "पानी का जग मेज़ पर है"),
            WordExample(thai: "เหยือกนี้สวยมาก", romanization: "yùeak níi sǔay mâak", english: "This jug is very pretty", hindi: "यह जग बहुत सुंदर है"),
        ],
        995: [
            WordExample(thai: "ปลาอยู่ในกระป๋อง", romanization: "plaa yùu nai krà-pǒng", english: "The fish is in the can", hindi: "मछली कैन में है"),
            WordExample(thai: "ผมเปิดกระป๋องไม่ได้", romanization: "phǒm pèrt krà-pǒng mâi dâi", english: "I cannot open the can", hindi: "मैं कैन नहीं खोल पाता"),
        ],
        996: [
            WordExample(thai: "กระชอนอยู่ในตู้", romanization: "krà-choon yùu nai tûu", english: "The strainer is in the cupboard", hindi: "छलनी अलमारी में है"),
            WordExample(thai: "ฉันล้างผักด้วยกระชอน", romanization: "chǎn láang phàk dûay krà-choon", english: "I wash vegetables with a strainer", hindi: "मैं छलनी में सब्ज़ी धोती हूँ"),
        ],
        997: [
            WordExample(thai: "ฉันทำความสะอาดบ้าน", romanization: "chǎn tam-kwaam-sà-àat bâan", english: "I clean the house", hindi: "मैं घर साफ़ करती हूँ"),
            WordExample(thai: "เขาทำความสะอาดห้องนอน", romanization: "kǎo tam-kwaam-sà-àat hôong-noon", english: "He cleans the bedroom", hindi: "वह बेडरूम साफ़ करता है"),
        ],
        998: [
            WordExample(thai: "ฉันไม่ชอบงานบ้าน", romanization: "chǎn mâi chôop ngaan-bâan", english: "I do not like housework", hindi: "मुझे घर का काम पसंद नहीं है"),
            WordExample(thai: "เขาทำงานบ้าน", romanization: "kǎo tam ngaan-bâan", english: "He does housework", hindi: "वह घर का काम करता है"),
        ],
        999: [
            WordExample(thai: "ฉันกวาดบ้าน", romanization: "chǎn kwàat bâan", english: "I sweep the house", hindi: "मैं घर में झाड़ू लगाती हूँ"),
            WordExample(thai: "เขากวาดห้องนอน", romanization: "kǎo kwàat hôong-noon", english: "He sweeps the bedroom", hindi: "वह बेडरूम में झाड़ू लगाता है"),
        ],
        1000: [
            WordExample(thai: "ฉันถูพื้นห้องครัว", romanization: "chǎn tǔu péun hôong-krua", english: "I mop the kitchen floor", hindi: "मैं रसोई का फ़र्श पोंछती हूँ"),
            WordExample(thai: "เขาถูพื้นบ้าน", romanization: "kǎo tǔu péun bâan", english: "He mops the house floor", hindi: "वह घर का फ़र्श पोंछता है"),
        ],
        1001: [
            WordExample(thai: "ฉันซักผ้าที่บ้าน", romanization: "chǎn sák-pâa tîi bâan", english: "I do laundry at home", hindi: "मैं घर पर कपड़े धोती हूँ"),
            WordExample(thai: "เขาไม่ชอบซักผ้า", romanization: "kǎo mâi chôop sák-pâa", english: "He does not like doing laundry", hindi: "उसे कपड़े धोना पसंद नहीं है"),
        ],
        1002: [
            WordExample(thai: "ฉันล้างจานที่ห้องครัว", romanization: "chǎn láang-jaan tîi hôong-krua", english: "I wash dishes in the kitchen", hindi: "मैं रसोई में बर्तन धोती हूँ"),
            WordExample(thai: "ผมไม่ชอบล้างจาน", romanization: "pǒm mâi chôop láang-jaan", english: "I do not like washing dishes", hindi: "मुझे बर्तन धोना पसंद नहीं है"),
        ],
        1003: [
            WordExample(thai: "ไม้ถูพื้นอยู่ที่ห้องครัว", romanization: "máai-tǔu-péun yùu tîi hôong-krua", english: "The mop is in the kitchen", hindi: "पोछा रसोई में है"),
            WordExample(thai: "ฉันมีไม้ถูพื้นที่บ้าน", romanization: "chǎn mii máai-tǔu-péun tîi bâan", english: "I have a mop at home", hindi: "मेरे घर पर पोछा है"),
        ],
        1004: [
            WordExample(thai: "ผ้าขี้ริ้วสกปรกมาก", romanization: "pâa-kîi-ríu sòk-kà-pròk mâak", english: "The rag is very dirty", hindi: "सफ़ाई का कपड़ा बहुत गंदा है"),
            WordExample(thai: "ผ้าขี้ริ้วอยู่ที่นี่", romanization: "pâa-kîi-ríu yùu tîi-nîi", english: "The rag is here", hindi: "सफ़ाई का कपड़ा यहाँ है"),
        ],
        1005: [
            WordExample(thai: "ที่นี่มีขยะมาก", romanization: "tîi-nîi mii kà-yà mâak", english: "There is a lot of trash here", hindi: "यहाँ बहुत कूड़ा है"),
            WordExample(thai: "ฉันทิ้งขยะ", romanization: "chǎn tíng kà-yà", english: "I throw away the trash", hindi: "मैं कूड़ा फेंकती हूँ"),
        ],
        1006: [
            WordExample(thai: "เขาทิ้งขยะที่นี่", romanization: "kǎo tíng kà-yà tîi-nîi", english: "He throws trash here", hindi: "वह यहाँ कूड़ा फेंकता है"),
            WordExample(thai: "ฉันไปทิ้งขยะ", romanization: "chǎn pai tíng kà-yà", english: "I go throw away the trash", hindi: "मैं कूड़ा फेंकने जाती हूँ"),
        ],
        1007: [
            WordExample(thai: "โต๊ะมีฝุ่นมาก", romanization: "tó mii fùn mâak", english: "The table has a lot of dust", hindi: "मेज़ पर बहुत धूल है"),
            WordExample(thai: "ฉันเช็ดฝุ่นที่โต๊ะ", romanization: "chǎn chét fùn tîi tó", english: "I wipe the dust on the table", hindi: "मैं मेज़ की धूल पोंछती हूँ"),
        ],
        1008: [
            WordExample(thai: "ฉันมีเครื่องดูดฝุ่นที่บ้าน", romanization: "chǎn mii krêuang-dùut-fùn tîi bâan", english: "I have a vacuum cleaner at home", hindi: "मेरे घर पर वैक्यूम क्लीनर है"),
            WordExample(thai: "เครื่องดูดฝุ่นดีมาก", romanization: "krêuang-dùut-fùn dii mâak", english: "The vacuum cleaner is very good", hindi: "वैक्यूम क्लीनर बहुत अच्छा है"),
        ],
        1009: [
            WordExample(thai: "ผงซักฟอกอยู่ที่นี่", romanization: "pǒng-sák-fôok yùu tîi-nîi", english: "The detergent is here", hindi: "कपड़े धोने का पाउडर यहाँ है"),
            WordExample(thai: "ฉันมีผงซักฟอกที่บ้าน", romanization: "chǎn mii pǒng-sák-fôok tîi bâan", english: "I have detergent at home", hindi: "मेरे घर पर कपड़े धोने का पाउडर है"),
        ],
        1010: [
            WordExample(thai: "ฉันตากผ้าที่บ้าน", romanization: "chǎn tàak-pâa tîi bâan", english: "I hang clothes to dry at home", hindi: "मैं घर पर कपड़े सुखाती हूँ"),
            WordExample(thai: "เขาไปตากผ้า", romanization: "kǎo pai tàak-pâa", english: "He goes to hang the laundry", hindi: "वह कपड़े सुखाने जाता है"),
        ],
        1011: [
            WordExample(thai: "ฉันไม่ชอบรีดผ้า", romanization: "chǎn mâi chôop rîit-pâa", english: "I do not like ironing", hindi: "मुझे इस्त्री करना पसंद नहीं है"),
            WordExample(thai: "เขารีดผ้าที่ห้องนอน", romanization: "kǎo rîit-pâa tîi hôong-noon", english: "He irons clothes in the bedroom", hindi: "वह बेडरूम में कपड़े इस्त्री करता है"),
        ],
        1012: [
            WordExample(thai: "ฉันพับผ้าที่ห้องนอน", romanization: "chǎn páp-pâa tîi hôong-noon", english: "I fold clothes in the bedroom", hindi: "मैं बेडरूम में कपड़े तह करती हूँ"),
            WordExample(thai: "เขาพับผ้าห่ม", romanization: "kǎo páp pâa-hòm", english: "He folds the blanket", hindi: "वह कंबल तह करता है"),
        ],
        1013: [
            WordExample(thai: "ฉันเก็บเสื้อผ้า", romanization: "chǎn kèp sêua-pâa", english: "I put away the clothes", hindi: "मैं कपड़े समेट कर रखती हूँ"),
            WordExample(thai: "เขาเก็บห้องนอน", romanization: "kǎo kèp hôong-noon", english: "He tidies the bedroom", hindi: "वह बेडरूम समेटता है"),
        ],
        1014: [
            WordExample(thai: "ถังน้ำอยู่ที่นี่", romanization: "tǎng-náam yùu tîi-nîi", english: "The bucket is here", hindi: "बाल्टी यहाँ है"),
            WordExample(thai: "ถังน้ำมีน้ำมาก", romanization: "tǎng-náam mii náam mâak", english: "The bucket has a lot of water", hindi: "बाल्टी में बहुत पानी है"),
        ],
        1015: [
            WordExample(thai: "แปรงอยู่ที่นี่", romanization: "praeng yùu tîi-nîi", english: "The brush is here", hindi: "ब्रश यहाँ है"),
            WordExample(thai: "ฉันมีแปรงที่บ้าน", romanization: "chǎn mii praeng tîi bâan", english: "I have a brush at home", hindi: "मेरे घर पर ब्रश है"),
        ],
        1016: [
            WordExample(thai: "ขาผมบวมมาก", romanization: "khǎa phǒm buam mâak", english: "My leg is very swollen", hindi: "मेरा पैर बहुत सूजा हुआ है"),
            WordExample(thai: "ตาฉันบวมค่ะ", romanization: "taa chǎn buam khâ", english: "My eye is swollen", hindi: "मेरी आँख सूजी हुई है"),
        ],
        1017: [
            WordExample(thai: "อร่อยจริงค่ะ", romanization: "à-ròi jing khâ", english: "It is really delicious", hindi: "सच में स्वादिष्ट है"),
            WordExample(thai: "เขาดีจริงครับ", romanization: "khǎo dii jing khráp", english: "He is really good", hindi: "वह सच में अच्छा है"),
        ],
        1018: [
            WordExample(thai: "กินสิครับ", romanization: "kin sì khráp", english: "Go ahead, eat!", hindi: "खाओ न!"),
            WordExample(thai: "มาที่นี่สิ", romanization: "maa thîi-nîi sì", english: "Come here!", hindi: "यहाँ आओ न!"),
        ],
        1019: [
            WordExample(thai: "แม่น้ำนี้ใหญ่มาก", romanization: "mâe-náam níi yài mâak", english: "This river is very big", hindi: "यह नदी बहुत बड़ी है"),
            WordExample(thai: "บ้านฉันอยู่ใกล้แม่น้ำ", romanization: "bâan chǎn yùu klâi mâe-náam", english: "My house is near the river", hindi: "मेरा घर नदी के पास है"),
        ],
        1020: [
            WordExample(thai: "ฉันเห็นน้ำตาของเขา", romanization: "chǎn hěn nám-taa kǒng kǎo", english: "I see her tears", hindi: "मैं उसके आँसू देखती हूँ"),
            WordExample(thai: "ทำไมคุณมีน้ำตา", romanization: "tam-mai kun mii nám-taa", english: "Why do you have tears", hindi: "तुम्हारी आँखों में आँसू क्यों हैं"),
        ],
        1021: [
            WordExample(thai: "คนไทยมีน้ำใจมาก", romanization: "kon tai mii nám-jai mâak", english: "Thai people are very generous", hindi: "थाई लोग बहुत दरियादिल होते हैं"),
            WordExample(thai: "เขามีน้ำใจกับทุกคน", romanization: "kǎo mii nám-jai kàp túk kon", english: "He is generous to everyone", hindi: "वह सबके साथ उदार है"),
        ],
        1022: [
            WordExample(thai: "เขาหน้าตาดีมาก", romanization: "kǎo nâa-taa dii mâak", english: "He is very good-looking", hindi: "वह देखने में बहुत अच्छा है"),
            WordExample(thai: "น้องฉันหน้าตาสวย", romanization: "nóng chǎn nâa-taa sǔai", english: "My little sister has a pretty face", hindi: "मेरी छोटी बहन की सूरत सुंदर है"),
        ],
        1023: [
            WordExample(thai: "หมอถามน้ำหนักของผม", romanization: "mǒo tǎam nám-nàk kǒng pǒm", english: "The doctor asks my weight", hindi: "डॉक्टर मेरा वज़न पूछते हैं"),
            WordExample(thai: "น้ำหนักเยอะไม่ดีนะ", romanization: "nám-nàk yóe mâi dii ná", english: "Too much weight is not good", hindi: "ज़्यादा वज़न अच्छा नहीं है"),
        ],
        1024: [
            WordExample(thai: "ผมเป็นไข้หวัดครับ", romanization: "pǒm pen kâi-wàt kráp", english: "I have a cold", hindi: "मुझे ज़ुकाम है"),
            WordExample(thai: "เด็กเป็นไข้หวัดบ่อย", romanization: "dèk pen kâi-wàt bòi", english: "Children often catch colds", hindi: "बच्चों को अक्सर ज़ुकाम होता है"),
        ],
        1025: [
            WordExample(thai: "ผมนั่งรถไฟฟ้าไปทำงาน", romanization: "pǒm nâng rót-fai-fáa pai tam-ngaan", english: "I take the skytrain to work", hindi: "मैं मेट्रो से काम पर जाता हूँ"),
            WordExample(thai: "รถไฟฟ้ามาเร็วมาก", romanization: "rót-fai-fáa maa reo mâak", english: "The skytrain comes very fast", hindi: "मेट्रो बहुत जल्दी आती है"),
        ],
        1026: [
            WordExample(thai: "ต้องหยุดที่ไฟแดง", romanization: "tông yùt tîi fai-daeng", english: "You must stop at the red light", hindi: "रेड लाइट पर रुकना ज़रूरी है"),
            WordExample(thai: "ไฟแดงแล้ว รอก่อนนะ", romanization: "fai-daeng láeo roo kòn ná", english: "It is red now, wait first", hindi: "रेड लाइट है, पहले रुको"),
        ],
        1027: [
            WordExample(thai: "เราไปถนนคนเดินไหม", romanization: "rao pai tà-nǒn-kon-dern mǎi", english: "Shall we go to the walking street", hindi: "क्या हम वॉकिंग स्ट्रीट चलें"),
            WordExample(thai: "ถนนคนเดินมีของขายเยอะ", romanization: "tà-nǒn-kon-dern mii kǒng kǎai yóe", english: "The walking street has many things for sale", hindi: "वॉकिंग स्ट्रीट पर बहुत चीज़ें बिकती हैं"),
        ],
        1028: [
            WordExample(thai: "หน้าฝนมาแล้ว", romanization: "nâa-fǒn maa láeo", english: "The rainy season is here", hindi: "बरसात का मौसम आ गया"),
            WordExample(thai: "ฉันไม่ชอบหน้าฝน", romanization: "chǎn mâi chôp nâa-fǒn", english: "I do not like the rainy season", hindi: "मुझे बरसात का मौसम पसंद नहीं"),
        ],
        1029: [
            WordExample(thai: "หน้าร้อนเราไปทะเล", romanization: "nâa-rón rao pai tá-lee", english: "In summer we go to the sea", hindi: "गर्मियों में हम समुद्र जाते हैं"),
            WordExample(thai: "หน้าร้อนร้อนมาก", romanization: "nâa-rón rón mâak", english: "The hot season is very hot", hindi: "गर्मी के मौसम में बहुत गर्मी होती है"),
        ],
        1030: [
            WordExample(thai: "หน้าหนาวอากาศดีมาก", romanization: "nâa-nǎao aa-kàat dii mâak", english: "In winter the weather is very nice", hindi: "सर्दियों में मौसम बहुत अच्छा होता है"),
            WordExample(thai: "ฉันชอบหน้าหนาว", romanization: "chǎn chôp nâa-nǎao", english: "I like the cool season", hindi: "मुझे सर्दी का मौसम पसंद है"),
        ],
        1031: [
            WordExample(thai: "ผมได้เงินเดือนแล้ว", romanization: "pǒm dâi ngern-duean láeo", english: "I already got my salary", hindi: "मुझे तनख्वाह मिल गई"),
            WordExample(thai: "เงินเดือนของเขาดีมาก", romanization: "ngern-duean kǒng kǎo dii mâak", english: "His salary is very good", hindi: "उसकी तनख्वाह बहुत अच्छी है"),
        ],
        1032: [
            WordExample(thai: "เขาว่างงานมานานแล้ว", romanization: "kǎo wâang-ngaan maa naan láeo", english: "He has been unemployed for a long time", hindi: "वह लंबे समय से बेरोज़गार है"),
            WordExample(thai: "ผมไม่อยากว่างงาน", romanization: "pǒm mâi yàak wâang-ngaan", english: "I do not want to be unemployed", hindi: "मैं बेरोज़गार नहीं होना चाहता"),
        ],
        1033: [
            WordExample(thai: "เขามีลูกน้องห้าคน", romanization: "kǎo mii lûuk-nóng hâa kon", english: "He has five staff members", hindi: "उसके पाँच मातहत कर्मचारी हैं"),
            WordExample(thai: "ลูกน้องของผมเก่งมาก", romanization: "lûuk-nóng kǒng pǒm kèng mâak", english: "My staff are very capable", hindi: "मेरे कर्मचारी बहुत काबिल हैं"),
        ],
        1034: [
            WordExample(thai: "ครูอยู่ในห้องเรียน", romanization: "kruu yùu nai hông-rian", english: "The teacher is in the classroom", hindi: "शिक्षक कक्षा में हैं"),
            WordExample(thai: "ห้องเรียนนี้กว้างมาก", romanization: "hông-rian níi kwâang mâak", english: "This classroom is very spacious", hindi: "यह कक्षा बहुत बड़ी है"),
        ],
        1035: [
            WordExample(thai: "ผมมีคำถามครับ", romanization: "pǒm mii kam-tǎam kráp", english: "I have a question", hindi: "मेरा एक सवाल है"),
            WordExample(thai: "คำถามนี้ยากมาก", romanization: "kam-tǎam níi yâak mâak", english: "This question is very difficult", hindi: "यह सवाल बहुत कठिन है"),
        ],
        1036: [
            WordExample(thai: "ฉันรู้คำตอบแล้ว", romanization: "chǎn rúu kam-tòp láeo", english: "I already know the answer", hindi: "मुझे जवाब पता है"),
            WordExample(thai: "คำตอบของคุณถูก", romanization: "kam-tòp kǒng kun tùuk", english: "Your answer is right", hindi: "तुम्हारा जवाब सही है"),
        ],
        1037: [
            WordExample(thai: "อ่านคู่มือก่อนใช้", romanization: "àan kûu-mue kòn chái", english: "Read the manual before using", hindi: "इस्तेमाल से पहले मैनुअल पढ़ो"),
            WordExample(thai: "คู่มือนี้ง่ายมาก", romanization: "kûu-mue níi ngâai mâak", english: "This manual is very easy", hindi: "यह मैनुअल बहुत आसान है"),
        ],
        1038: [
            WordExample(thai: "ขอเบอร์โทรหน่อยครับ", romanization: "kǒo ber-too nòi kráp", english: "May I have your phone number", hindi: "ज़रा अपना फ़ोन नंबर दीजिए"),
            WordExample(thai: "นี่เบอร์โทรของฉัน", romanization: "nîi ber-too kǒng chǎn", english: "This is my phone number", hindi: "यह मेरा फ़ोन नंबर है"),
        ],
        1039: [
            WordExample(thai: "ลูกชอบของเล่นใหม่", romanization: "lûuk chôp kǒng-lên mài", english: "The child likes the new toy", hindi: "बच्चे को नया खिलौना पसंद है"),
            WordExample(thai: "ของเล่นนี้ถูกมาก", romanization: "kǒng-lên níi tùuk mâak", english: "This toy is very cheap", hindi: "यह खिलौना बहुत सस्ता है"),
        ],
        1040: [
            WordExample(thai: "ผมซื้อรถมือสอง", romanization: "pǒm súe rót mue-sǒng", english: "I buy a secondhand car", hindi: "मैं सेकंड-हैंड गाड़ी खरीदता हूँ"),
            WordExample(thai: "เสื้อมือสองถูกมาก", romanization: "sûea mue-sǒng tùuk mâak", english: "Secondhand shirts are very cheap", hindi: "सेकंड-हैंड शर्ट बहुत सस्ती होती हैं"),
        ],
        1041: [
            WordExample(thai: "ผมเป็นมือใหม่ครับ", romanization: "pǒm pen mue-mài kráp", english: "I am a beginner", hindi: "मैं नौसिखिया हूँ"),
            WordExample(thai: "มือใหม่ต้องเรียนก่อน", romanization: "mue-mài tông rian kòn", english: "A beginner must learn first", hindi: "नौसिखिए को पहले सीखना चाहिए"),
        ],
        1042: [
            WordExample(thai: "ขอแก้วน้ำหน่อยครับ", romanization: "kǒo kâeo-náam nòi kráp", english: "May I have a glass of water", hindi: "ज़रा एक गिलास पानी दीजिए"),
            WordExample(thai: "แก้วน้ำอยู่ที่โต๊ะ", romanization: "kâeo-náam yùu tîi tó", english: "The glass is on the table", hindi: "गिलास मेज़ पर है"),
        ],
        1043: [
            WordExample(thai: "ขอช้อนส้อมหน่อยครับ", romanization: "kǒo chón-sôm nòi kráp", english: "May I have a spoon and fork", hindi: "ज़रा चम्मच-काँटा दीजिए"),
            WordExample(thai: "ช้อนส้อมสะอาดมาก", romanization: "chón-sôm sà-àat mâak", english: "The cutlery is very clean", hindi: "चम्मच-काँटा बहुत साफ़ है"),
        ],
        1044: [
            WordExample(thai: "เตียงนอนใหญ่และสบาย", romanization: "tiang-non yài láe sà-baai", english: "The bed is big and comfortable", hindi: "बिस्तर बड़ा और आरामदायक है"),
            WordExample(thai: "ผมซื้อเตียงนอนใหม่", romanization: "pǒm súe tiang-non mài", english: "I am buying a new bed", hindi: "मैं नया बिस्तर खरीद रहा हूँ"),
        ],
        1045: [
            WordExample(thai: "เขาเป็นลูกครึ่งไทย", romanization: "kǎo pen lûuk-krûeng tai", english: "He is half Thai", hindi: "वह आधा थाई है"),
            WordExample(thai: "น้องเป็นลูกครึ่งใช่ไหม", romanization: "nóng pen lûuk-krûeng châi mǎi", english: "The little one is mixed, right", hindi: "बच्चा मिश्रित मूल का है ना"),
        ],
        1046: [
            WordExample(thai: "แมวน้ำอยู่ในทะเล", romanization: "maeo-náam yùu nai tá-lee", english: "Seals live in the sea", hindi: "सील समुद्र में रहती है"),
            WordExample(thai: "แมวน้ำตัวใหญ่มาก", romanization: "maeo-náam tua yài mâak", english: "The seal is very big", hindi: "सील बहुत बड़ी होती है"),
        ],
    ]


    private static let examples3: [Int: [WordExample]] = [
        1047: [
            WordExample(thai: "ผมชอบท่องเที่ยว", romanization: "phǒm chôp tâwng-thîao", english: "I like travel", hindi: "मुझे यात्रा पसंद है"),
            WordExample(thai: "นี่คือท่องเที่ยว", romanization: "nîi khuue tâwng-thîao", english: "This is travel", hindi: "यह यात्रा है"),
        ],
        1048: [
            WordExample(thai: "ผมชอบนักท่องเที่ยว", romanization: "phǒm chôp nák-thâwng-thîao", english: "I like tourist", hindi: "मुझे पर्यटक पसंद है"),
            WordExample(thai: "นี่คือนักท่องเที่ยว", romanization: "nîi khuue nák-thâwng-thîao", english: "This is tourist", hindi: "यह पर्यटक है"),
        ],
        1049: [
            WordExample(thai: "ผมชอบทริป", romanization: "phǒm chôp tríp", english: "I like trip", hindi: "मुझे यात्रा पसंद है"),
            WordExample(thai: "นี่คือทริป", romanization: "nîi khuue tríp", english: "This is trip", hindi: "यह यात्रा है"),
        ],
        1050: [
            WordExample(thai: "ผมชอบแผนที่", romanization: "phǒm chôp phǎen-thîi", english: "I like map", hindi: "मुझे नक्शा पसंद है"),
            WordExample(thai: "นี่คือแผนที่", romanization: "nîi khuue phǎen-thîi", english: "This is map", hindi: "यह नक्शा है"),
        ],
        1051: [
            WordExample(thai: "ผมชอบหนังสือเดินทาง", romanization: "phǒm chôp nǎng-sʉ̌ʉ doen-thaang", english: "I like passport", hindi: "मुझे पासपोर्ट पसंद है"),
            WordExample(thai: "นี่คือหนังสือเดินทาง", romanization: "nîi khuue nǎng-sʉ̌ʉ doen-thaang", english: "This is passport", hindi: "यह पासपोर्ट है"),
        ],
        1052: [
            WordExample(thai: "ผมชอบวีซ่า", romanization: "phǒm chôp wii-sâa", english: "I like visa", hindi: "मुझे वीज़ा पसंद है"),
            WordExample(thai: "นี่คือวีซ่า", romanization: "nîi khuue wii-sâa", english: "This is visa", hindi: "यह वीज़ा है"),
        ],
        1053: [
            WordExample(thai: "ผมชอบกระเป๋าเดินทาง", romanization: "phǒm chôp krà-bpǎo doen-thaang", english: "I like suitcase", hindi: "मुझे सूटकेस पसंद है"),
            WordExample(thai: "นี่คือกระเป๋าเดินทาง", romanization: "nîi khuue krà-bpǎo doen-thaang", english: "This is suitcase", hindi: "यह सूटकेस है"),
        ],
        1054: [
            WordExample(thai: "ผมชอบจุดหมายปลายทาง", romanization: "phǒm chôp jùt-mǎai bplaaai-thaang", english: "I like destination", hindi: "मुझे गंतव्य पसंद है"),
            WordExample(thai: "นี่คือจุดหมายปลายทาง", romanization: "nîi khuue jùt-mǎai bplaaai-thaang", english: "This is destination", hindi: "यह गंतव्य है"),
        ],
        1055: [
            WordExample(thai: "ผมชอบการเดินทาง", romanization: "phǒm chôp gaan doen-thaang", english: "I like travel, transportation", hindi: "मुझे यात्रा पसंद है"),
            WordExample(thai: "นี่คือการเดินทาง", romanization: "nîi khuue gaan doen-thaang", english: "This is travel, transportation", hindi: "यह यात्रा है"),
        ],
        1056: [
            WordExample(thai: "ผมชอบต่างประเทศ", romanization: "phǒm chôp dtàang bprà-thêet", english: "I like foreign country", hindi: "मुझे विदेश पसंद है"),
            WordExample(thai: "นี่คือต่างประเทศ", romanization: "nîi khuue dtàang bprà-thêet", english: "This is foreign country", hindi: "यह विदेश है"),
        ],
        1057: [
            WordExample(thai: "ผมชอบภายในประเทศ", romanization: "phǒm chôp phaai nai bprà-thêet", english: "I like domestic", hindi: "मुझे घरेलू पसंद है"),
            WordExample(thai: "นี่คือภายในประเทศ", romanization: "nîi khuue phaai nai bprà-thêet", english: "This is domestic", hindi: "यह घरेलू है"),
        ],
        1058: [
            WordExample(thai: "ผมชอบวันหยุดยาว", romanization: "phǒm chôp wan yùt yaao", english: "I like long holiday", hindi: "मुझे लंबी छुट्टी पसंद है"),
            WordExample(thai: "นี่คือวันหยุดยาว", romanization: "nîi khuue wan yùt yaao", english: "This is long holiday", hindi: "यह लंबी छुट्टी है"),
        ],
        1059: [
            WordExample(thai: "ผมชอบสำรวจ", romanization: "phǒm chôp sǎm-rùat", english: "I like explore", hindi: "मुझे खोज करना पसंद है"),
            WordExample(thai: "นี่คือสำรวจ", romanization: "nîi khuue sǎm-rùat", english: "This is explore", hindi: "यह खोज करना है"),
        ],
        1060: [
            WordExample(thai: "ผมชอบเยี่ยมชม", romanization: "phǒm chôp yîam-chom", english: "I like visit", hindi: "मुझे भ्रमण करना पसंद है"),
            WordExample(thai: "นี่คือเยี่ยมชม", romanization: "nîi khuue yîam-chom", english: "This is visit", hindi: "यह भ्रमण करना है"),
        ],
        1061: [
            WordExample(thai: "ผมชอบถ่ายรูป", romanization: "phǒm chôp thàai rûup", english: "I like take photos", hindi: "मुझे तस्वीर लेना पसंद है"),
            WordExample(thai: "นี่คือถ่ายรูป", romanization: "nîi khuue thàai rûup", english: "This is take photos", hindi: "यह तस्वीर लेना है"),
        ],
        1062: [
            WordExample(thai: "ผมชอบของที่ระลึก", romanization: "phǒm chôp khǎawng thîi rá-lʉ́k", english: "I like souvenir", hindi: "मुझे स्मारिका पसंद है"),
            WordExample(thai: "นี่คือของที่ระลึก", romanization: "nîi khuue khǎawng thîi rá-lʉ́k", english: "This is souvenir", hindi: "यह स्मारिका है"),
        ],
        1063: [
            WordExample(thai: "ผมชอบไกด์นำเที่ยว", romanization: "phǒm chôp gài nam-thîao", english: "I like tour guide", hindi: "मुझे पर्यटक गाइड पसंद है"),
            WordExample(thai: "นี่คือไกด์นำเที่ยว", romanization: "nîi khuue gài nam-thîao", english: "This is tour guide", hindi: "यह पर्यटक गाइड है"),
        ],
        1064: [
            WordExample(thai: "ผมชอบทัวร์", romanization: "phǒm chôp thuaa", english: "I like tour", hindi: "मुझे दौरा पसंद है"),
            WordExample(thai: "นี่คือทัวร์", romanization: "nîi khuue thuaa", english: "This is tour", hindi: "यह दौरा है"),
        ],
        1065: [
            WordExample(thai: "ผมชอบจัดกระเป๋า", romanization: "phǒm chôp jàt krà-bpǎo", english: "I like pack a bag", hindi: "मुझे बैग पैक करना पसंद है"),
            WordExample(thai: "นี่คือจัดกระเป๋า", romanization: "nîi khuue jàt krà-bpǎo", english: "This is pack a bag", hindi: "यह बैग पैक करना है"),
        ],
        1066: [
            WordExample(thai: "ผมชอบออกเดินทาง", romanization: "phǒm chôp àawk doen-thaang", english: "I like depart", hindi: "मुझे रवाना होना पसंद है"),
            WordExample(thai: "นี่คือออกเดินทาง", romanization: "nîi khuue àawk doen-thaang", english: "This is depart", hindi: "यह रवाना होना है"),
        ],
        1067: [
            WordExample(thai: "ผมชอบสถานี", romanization: "phǒm chôp sà-thǎa-nii", english: "I like station", hindi: "मुझे स्टेशन पसंद है"),
            WordExample(thai: "นี่คือสถานี", romanization: "nîi khuue sà-thǎa-nii", english: "This is station", hindi: "यह स्टेशन है"),
        ],
        1068: [
            WordExample(thai: "ผมชอบสถานีรถไฟ", romanization: "phǒm chôp sà-thǎa-nii rót-fai", english: "I like train station", hindi: "मुझे रेलवे स्टेशन पसंद है"),
            WordExample(thai: "นี่คือสถานีรถไฟ", romanization: "nîi khuue sà-thǎa-nii rót-fai", english: "This is train station", hindi: "यह रेलवे स्टेशन है"),
        ],
        1069: [
            WordExample(thai: "ผมชอบสถานีขนส่ง", romanization: "phǒm chôp sà-thǎa-nii khǒn-sòng", english: "I like bus terminal", hindi: "मुझे बस टर्मिनल पसंद है"),
            WordExample(thai: "นี่คือสถานีขนส่ง", romanization: "nîi khuue sà-thǎa-nii khǒn-sòng", english: "This is bus terminal", hindi: "यह बस टर्मिनल है"),
        ],
        1070: [
            WordExample(thai: "ผมชอบป้ายรถเมล์", romanization: "phǒm chôp bpàai rót-mee", english: "I like bus stop", hindi: "मुझे बस स्टॉप पसंद है"),
            WordExample(thai: "นี่คือป้ายรถเมล์", romanization: "nîi khuue bpàai rót-mee", english: "This is bus stop", hindi: "यह बस स्टॉप है"),
        ],
        1071: [
            WordExample(thai: "ผมชอบท่าเรือ", romanization: "phǒm chôp thâa rʉʉa", english: "I like pier", hindi: "मुझे घाट पसंद है"),
            WordExample(thai: "นี่คือท่าเรือ", romanization: "nîi khuue thâa rʉʉa", english: "This is pier", hindi: "यह घाट है"),
        ],
        1072: [
            WordExample(thai: "ผมชอบท่าอากาศยาน", romanization: "phǒm chôp thâa aa-gàat yaan", english: "I like airport", hindi: "मुझे हवाई अड्डा पसंद है"),
            WordExample(thai: "นี่คือท่าอากาศยาน", romanization: "nîi khuue thâa aa-gàat yaan", english: "This is airport", hindi: "यह हवाई अड्डा है"),
        ],
        1073: [
            WordExample(thai: "ผมชอบสถานที่", romanization: "phǒm chôp sà-thǎa-n-thîi", english: "I like place", hindi: "मुझे स्थान पसंद है"),
            WordExample(thai: "นี่คือสถานที่", romanization: "nîi khuue sà-thǎa-n-thîi", english: "This is place", hindi: "यह स्थान है"),
        ],
        1074: [
            WordExample(thai: "ผมชอบสถานีตำรวจ", romanization: "phǒm chôp sà-thǎa-nii dtam-rùat", english: "I like police station", hindi: "मुझे पुलिस थाना पसंद है"),
            WordExample(thai: "นี่คือสถานีตำรวจ", romanization: "nîi khuue sà-thǎa-nii dtam-rùat", english: "This is police station", hindi: "यह पुलिस थाना है"),
        ],
        1075: [
            WordExample(thai: "ผมชอบพิพิธภัณฑ์", romanization: "phǒm chôp phí-phít-thá-phan", english: "I like museum", hindi: "मुझे संग्रहालय पसंद है"),
            WordExample(thai: "นี่คือพิพิธภัณฑ์", romanization: "nîi khuue phí-phít-thá-phan", english: "This is museum", hindi: "यह संग्रहालय है"),
        ],
        1076: [
            WordExample(thai: "ผมชอบหอศิลป์", romanization: "phǒm chôp hǎaw-sǐn", english: "I like art gallery", hindi: "मुझे कला दीर्घा पसंद है"),
            WordExample(thai: "นี่คือหอศิลป์", romanization: "nîi khuue hǎaw-sǐn", english: "This is art gallery", hindi: "यह कला दीर्घा है"),
        ],
        1077: [
            WordExample(thai: "ผมชอบห้องสมุด", romanization: "phǒm chôp hâawng sà-mùt", english: "I like library", hindi: "मुझे पुस्तकालय पसंद है"),
            WordExample(thai: "นี่คือห้องสมุด", romanization: "nîi khuue hâawng sà-mùt", english: "This is library", hindi: "यह पुस्तकालय है"),
        ],
        1078: [
            WordExample(thai: "ผมชอบสวนสาธารณะ", romanization: "phǒm chôp sǔan sǎa-thaa-rá-ná", english: "I like public park", hindi: "मुझे सार्वजनिक पार्क पसंद है"),
            WordExample(thai: "นี่คือสวนสาธารณะ", romanization: "nîi khuue sǔan sǎa-thaa-rá-ná", english: "This is public park", hindi: "यह सार्वजनिक पार्क है"),
        ],
        1079: [
            WordExample(thai: "ผมชอบสวนสัตว์", romanization: "phǒm chôp sǔan-sàt", english: "I like zoo", hindi: "मुझे चिड़ियाघर पसंद है"),
            WordExample(thai: "นี่คือสวนสัตว์", romanization: "nîi khuue sǔan-sàt", english: "This is zoo", hindi: "यह चिड़ियाघर है"),
        ],
        1080: [
            WordExample(thai: "ผมชอบสวนสนุก", romanization: "phǒm chôp sǔan-sà-nùk", english: "I like amusement park", hindi: "मुझे मनोरंजन पार्क पसंद है"),
            WordExample(thai: "นี่คือสวนสนุก", romanization: "nîi khuue sǔan-sà-nùk", english: "This is amusement park", hindi: "यह मनोरंजन पार्क है"),
        ],
        1081: [
            WordExample(thai: "ผมชอบโรงภาพยนตร์", romanization: "phǒm chôp roong-phâap-pha-yon", english: "I like cinema", hindi: "मुझे सिनेमा पसंद है"),
            WordExample(thai: "นี่คือโรงภาพยนตร์", romanization: "nîi khuue roong-phâap-pha-yon", english: "This is cinema", hindi: "यह सिनेमा है"),
        ],
        1082: [
            WordExample(thai: "ผมชอบโรงละคร", romanization: "phǒm chôp roong lá-khaawn", english: "I like theater", hindi: "मुझे रंगमंच पसंद है"),
            WordExample(thai: "นี่คือโรงละคร", romanization: "nîi khuue roong lá-khaawn", english: "This is theater", hindi: "यह रंगमंच है"),
        ],
        1083: [
            WordExample(thai: "ผมชอบมหาวิทยาลัย", romanization: "phǒm chôp má-hǎa-wít-tha-yaa-lai", english: "I like university", hindi: "मुझे विश्वविद्यालय पसंद है"),
            WordExample(thai: "นี่คือมหาวิทยาลัย", romanization: "nîi khuue má-hǎa-wít-tha-yaa-lai", english: "This is university", hindi: "यह विश्वविद्यालय है"),
        ],
        1084: [
            WordExample(thai: "ผมชอบไปรษณีย์", romanization: "phǒm chôp bprai-sà-nii", english: "I like post office", hindi: "मुझे डाकघर पसंद है"),
            WordExample(thai: "นี่คือไปรษณีย์", romanization: "nîi khuue bprai-sà-nii", english: "This is post office", hindi: "यह डाकघर है"),
        ],
        1085: [
            WordExample(thai: "ผมชอบร้านสะดวกซื้อ", romanization: "phǒm chôp ráan sà-dùak-sʉ́ʉ", english: "I like convenience store", hindi: "मुझे सुविधा स्टोर पसंद है"),
            WordExample(thai: "นี่คือร้านสะดวกซื้อ", romanization: "nîi khuue ráan sà-dùak-sʉ́ʉ", english: "This is convenience store", hindi: "यह सुविधा स्टोर है"),
        ],
        1086: [
            WordExample(thai: "ผมชอบห้างสรรพสินค้า", romanization: "phǒm chôp hâang sàp-pha-sǐn-kháa", english: "I like department store", hindi: "मुझे डिपार्टमेंट स्टोर पसंद है"),
            WordExample(thai: "นี่คือห้างสรรพสินค้า", romanization: "nîi khuue hâang sàp-pha-sǐn-kháa", english: "This is department store", hindi: "यह डिपार्टमेंट स्टोर है"),
        ],
        1087: [
            WordExample(thai: "ผมชอบทิศเหนือ", romanization: "phǒm chôp thít nʉ̌ʉa", english: "I like north", hindi: "मुझे उत्तर पसंद है"),
            WordExample(thai: "นี่คือทิศเหนือ", romanization: "nîi khuue thít nʉ̌ʉa", english: "This is north", hindi: "यह उत्तर है"),
        ],
        1088: [
            WordExample(thai: "ผมชอบทิศใต้", romanization: "phǒm chôp thít dtâai", english: "I like south", hindi: "मुझे दक्षिण पसंद है"),
            WordExample(thai: "นี่คือทิศใต้", romanization: "nîi khuue thít dtâai", english: "This is south", hindi: "यह दक्षिण है"),
        ],
        1089: [
            WordExample(thai: "ผมชอบทิศตะวันออก", romanization: "phǒm chôp thít dtà-wan-àawk", english: "I like east", hindi: "मुझे पूर्व पसंद है"),
            WordExample(thai: "นี่คือทิศตะวันออก", romanization: "nîi khuue thít dtà-wan-àawk", english: "This is east", hindi: "यह पूर्व है"),
        ],
        1090: [
            WordExample(thai: "ผมชอบทิศตะวันตก", romanization: "phǒm chôp thít dtà-wan-dtòk", english: "I like west", hindi: "मुझे पश्चिम पसंद है"),
            WordExample(thai: "นี่คือทิศตะวันตก", romanization: "nîi khuue thít dtà-wan-dtòk", english: "This is west", hindi: "यह पश्चिम है"),
        ],
        1091: [
            WordExample(thai: "ผมชอบตรงข้าม", romanization: "phǒm chôp dtrong-khâam", english: "I like opposite", hindi: "मुझे सामने पसंद है"),
            WordExample(thai: "นี่คือตรงข้าม", romanization: "nîi khuue dtrong-khâam", english: "This is opposite", hindi: "यह सामने है"),
        ],
        1092: [
            WordExample(thai: "ผมชอบข้าม", romanization: "phǒm chôp khâam", english: "I like cross", hindi: "मुझे पार करना पसंद है"),
            WordExample(thai: "นี่คือข้าม", romanization: "nîi khuue khâam", english: "This is cross", hindi: "यह पार करना है"),
        ],
        1093: [
            WordExample(thai: "ผมชอบเลี้ยวซ้าย", romanization: "phǒm chôp líao-sáai", english: "I like turn left", hindi: "मुझे बाएँ मुड़ना पसंद है"),
            WordExample(thai: "นี่คือเลี้ยวซ้าย", romanization: "nîi khuue líao-sáai", english: "This is turn left", hindi: "यह बाएँ मुड़ना है"),
        ],
        1094: [
            WordExample(thai: "ผมชอบเลี้ยวขวา", romanization: "phǒm chôp líao-khwǎa", english: "I like turn right", hindi: "मुझे दाएँ मुड़ना पसंद है"),
            WordExample(thai: "นี่คือเลี้ยวขวา", romanization: "nîi khuue líao-khwǎa", english: "This is turn right", hindi: "यह दाएँ मुड़ना है"),
        ],
        1095: [
            WordExample(thai: "ผมชอบยูเทิร์น", romanization: "phǒm chôp yuu-thəən", english: "I like U-turn", hindi: "मुझे यू-टर्न पसंद है"),
            WordExample(thai: "นี่คือยูเทิร์น", romanization: "nîi khuue yuu-thəən", english: "This is U-turn", hindi: "यह यू-टर्न है"),
        ],
        1096: [
            WordExample(thai: "ผมชอบสี่แยก", romanization: "phǒm chôp sìi-yâaek", english: "I like intersection", hindi: "मुझे चौराहा पसंद है"),
            WordExample(thai: "นี่คือสี่แยก", romanization: "nîi khuue sìi-yâaek", english: "This is intersection", hindi: "यह चौराहा है"),
        ],
        1097: [
            WordExample(thai: "ผมชอบวงเวียน", romanization: "phǒm chôp wong-wian", english: "I like roundabout", hindi: "मुझे गोलचक्कर पसंद है"),
            WordExample(thai: "นี่คือวงเวียน", romanization: "nîi khuue wong-wian", english: "This is roundabout", hindi: "यह गोलचक्कर है"),
        ],
        1098: [
            WordExample(thai: "ผมชอบทางแยก", romanization: "phǒm chôp thaang-yâaek", english: "I like junction", hindi: "मुझे मोड़ पसंद है"),
            WordExample(thai: "นี่คือทางแยก", romanization: "nîi khuue thaang-yâaek", english: "This is junction", hindi: "यह मोड़ है"),
        ],
        1099: [
            WordExample(thai: "ผมชอบทางม้าลาย", romanization: "phǒm chôp thaang-máa-laai", english: "I like crosswalk", hindi: "मुझे ज़ेब्रा क्रॉसिंग पसंद है"),
            WordExample(thai: "นี่คือทางม้าลาย", romanization: "nîi khuue thaang-máa-laai", english: "This is crosswalk", hindi: "यह ज़ेब्रा क्रॉसिंग है"),
        ],
        1100: [
            WordExample(thai: "ผมชอบสะพาน", romanization: "phǒm chôp sà-phaan", english: "I like bridge", hindi: "मुझे पुल पसंद है"),
            WordExample(thai: "นี่คือสะพาน", romanization: "nîi khuue sà-phaan", english: "This is bridge", hindi: "यह पुल है"),
        ],
        1101: [
            WordExample(thai: "ผมชอบอุโมงค์", romanization: "phǒm chôp ù-mohng", english: "I like tunnel", hindi: "मुझे सुरंग पसंद है"),
            WordExample(thai: "นี่คืออุโมงค์", romanization: "nîi khuue ù-mohng", english: "This is tunnel", hindi: "यह सुरंग है"),
        ],
        1102: [
            WordExample(thai: "ผมชอบทางด่วน", romanization: "phǒm chôp thaang-dùan", english: "I like expressway", hindi: "मुझे एक्सप्रेसवे पसंद है"),
            WordExample(thai: "นี่คือทางด่วน", romanization: "nîi khuue thaang-dùan", english: "This is expressway", hindi: "यह एक्सप्रेसवे है"),
        ],
        1103: [
            WordExample(thai: "ผมชอบทางเท้า", romanization: "phǒm chôp thaang-tháao", english: "I like sidewalk", hindi: "मुझे फुटपाथ पसंद है"),
            WordExample(thai: "นี่คือทางเท้า", romanization: "nîi khuue thaang-tháao", english: "This is sidewalk", hindi: "यह फुटपाथ है"),
        ],
        1104: [
            WordExample(thai: "ผมชอบซอย", romanization: "phǒm chôp sɔɔi", english: "I like side street", hindi: "मुझे गली पसंद है"),
            WordExample(thai: "นี่คือซอย", romanization: "nîi khuue sɔɔi", english: "This is side street", hindi: "यह गली है"),
        ],
        1105: [
            WordExample(thai: "ผมชอบปลายทาง", romanization: "phǒm chôp bplaai-thaang", english: "I like end point", hindi: "मुझे अंतिम गंतव्य पसंद है"),
            WordExample(thai: "นี่คือปลายทาง", romanization: "nîi khuue bplaai-thaang", english: "This is end point", hindi: "यह अंतिम गंतव्य है"),
        ],
        1106: [
            WordExample(thai: "ผมชอบระยะทาง", romanization: "phǒm chôp rá-yá-thaang", english: "I like distance", hindi: "मुझे दूरी पसंद है"),
            WordExample(thai: "นี่คือระยะทาง", romanization: "nîi khuue rá-yá-thaang", english: "This is distance", hindi: "यह दूरी है"),
        ],
        1107: [
            WordExample(thai: "ผมชอบรถเมล์", romanization: "phǒm chôp rót-mee", english: "I like bus", hindi: "मुझे बस पसंद है"),
            WordExample(thai: "นี่คือรถเมล์", romanization: "nîi khuue rót-mee", english: "This is bus", hindi: "यह बस है"),
        ],
        1108: [
            WordExample(thai: "ผมชอบรถแท็กซี่", romanization: "phǒm chôp rót-tháek-sîi", english: "I like taxi", hindi: "मुझे टैक्सी पसंद है"),
            WordExample(thai: "นี่คือรถแท็กซี่", romanization: "nîi khuue rót-tháek-sîi", english: "This is taxi", hindi: "यह टैक्सी है"),
        ],
        1109: [
            WordExample(thai: "ผมชอบแท็กซี่", romanization: "phǒm chôp tháek-sîi", english: "I like taxi", hindi: "मुझे टैक्सी पसंद है"),
            WordExample(thai: "นี่คือแท็กซี่", romanization: "nîi khuue tháek-sîi", english: "This is taxi", hindi: "यह टैक्सी है"),
        ],
        1110: [
            WordExample(thai: "ผมชอบรถตู้", romanization: "phǒm chôp rót-dtûu", english: "I like van", hindi: "मुझे वैन पसंद है"),
            WordExample(thai: "นี่คือรถตู้", romanization: "nîi khuue rót-dtûu", english: "This is van", hindi: "यह वैन है"),
        ],
        1111: [
            WordExample(thai: "ผมชอบรถจักรยานยนต์", romanization: "phǒm chôp rót jàk-grà-yaan yon", english: "I like motorcycle", hindi: "मुझे मोटरसाइकिल पसंद है"),
            WordExample(thai: "นี่คือรถจักรยานยนต์", romanization: "nîi khuue rót jàk-grà-yaan yon", english: "This is motorcycle", hindi: "यह मोटरसाइकिल है"),
        ],
        1112: [
            WordExample(thai: "ผมชอบจักรยาน", romanization: "phǒm chôp jàk-grà-yaan", english: "I like bicycle", hindi: "मुझे साइकिल पसंद है"),
            WordExample(thai: "นี่คือจักรยาน", romanization: "nîi khuue jàk-grà-yaan", english: "This is bicycle", hindi: "यह साइकिल है"),
        ],
        1113: [
            WordExample(thai: "ผมชอบรถสามล้อ", romanization: "phǒm chôp rót sǎam-láaw", english: "I like three-wheeler", hindi: "मुझे तीन पहिया पसंद है"),
            WordExample(thai: "นี่คือรถสามล้อ", romanization: "nîi khuue rót sǎam-láaw", english: "This is three-wheeler", hindi: "यह तीन पहिया है"),
        ],
        1114: [
            WordExample(thai: "ผมชอบตุ๊กตุ๊ก", romanization: "phǒm chôp dtúk-dtúk", english: "I like tuk-tuk", hindi: "मुझे टुक-टुक पसंद है"),
            WordExample(thai: "นี่คือตุ๊กตุ๊ก", romanization: "nîi khuue dtúk-dtúk", english: "This is tuk-tuk", hindi: "यह टुक-टुक है"),
        ],
        1115: [
            WordExample(thai: "ผมชอบรถบัส", romanization: "phǒm chôp rót-bát", english: "I like bus", hindi: "मुझे बस पसंद है"),
            WordExample(thai: "นี่คือรถบัส", romanization: "nîi khuue rót-bát", english: "This is bus", hindi: "यह बस है"),
        ],
        1116: [
            WordExample(thai: "ผมชอบรถด่วน", romanization: "phǒm chôp rót-dùan", english: "I like express train", hindi: "मुझे तेज़ रेल पसंद है"),
            WordExample(thai: "นี่คือรถด่วน", romanization: "nîi khuue rót-dùan", english: "This is express train", hindi: "यह तेज़ रेल है"),
        ],
        1117: [
            WordExample(thai: "ผมชอบรถไฟใต้ดิน", romanization: "phǒm chôp rót-fai dtâai-din", english: "I like subway", hindi: "मुझे मेट्रो पसंद है"),
            WordExample(thai: "นี่คือรถไฟใต้ดิน", romanization: "nîi khuue rót-fai dtâai-din", english: "This is subway", hindi: "यह मेट्रो है"),
        ],
        1118: [
            WordExample(thai: "ผมชอบรถไฟความเร็วสูง", romanization: "phǒm chôp rót-fai khwaam reo sǔung", english: "I like high-speed train", hindi: "मुझे बुलेट ट्रेन पसंद है"),
            WordExample(thai: "นี่คือรถไฟความเร็วสูง", romanization: "nîi khuue rót-fai khwaam reo sǔung", english: "This is high-speed train", hindi: "यह बुलेट ट्रेन है"),
        ],
        1119: [
            WordExample(thai: "ผมชอบรถเช่า", romanization: "phǒm chôp rót-châo", english: "I like rental car", hindi: "मुझे किराये की कार पसंद है"),
            WordExample(thai: "นี่คือรถเช่า", romanization: "nîi khuue rót-châo", english: "This is rental car", hindi: "यह किराये की कार है"),
        ],
        1120: [
            WordExample(thai: "ผมชอบเช่ารถ", romanization: "phǒm chôp châo-rót", english: "I like rent a car", hindi: "मुझे कार किराये पर लेना पसंद है"),
            WordExample(thai: "นี่คือเช่ารถ", romanization: "nîi khuue châo-rót", english: "This is rent a car", hindi: "यह कार किराये पर लेना है"),
        ],
        1121: [
            WordExample(thai: "ผมชอบโดยสาร", romanization: "phǒm chôp dooi-sǎan", english: "I like travel as passenger", hindi: "मुझे सवारी करना पसंद है"),
            WordExample(thai: "นี่คือโดยสาร", romanization: "nîi khuue dooi-sǎan", english: "This is travel as passenger", hindi: "यह सवारी करना है"),
        ],
        1122: [
            WordExample(thai: "ผมชอบผู้โดยสาร", romanization: "phǒm chôp phûu-dooi-sǎan", english: "I like passenger", hindi: "मुझे यात्री पसंद है"),
            WordExample(thai: "นี่คือผู้โดยสาร", romanization: "nîi khuue phûu-dooi-sǎan", english: "This is passenger", hindi: "यह यात्री है"),
        ],
        1123: [
            WordExample(thai: "ผมชอบคนขับ", romanization: "phǒm chôp khon-khàp", english: "I like driver", hindi: "मुझे चालक पसंद है"),
            WordExample(thai: "นี่คือคนขับ", romanization: "nîi khuue khon-khàp", english: "This is driver", hindi: "यह चालक है"),
        ],
        1124: [
            WordExample(thai: "ผมชอบป้ายทะเบียน", romanization: "phǒm chôp bpàai thá-bian", english: "I like license plate", hindi: "मुझे नंबर प्लेट पसंद है"),
            WordExample(thai: "นี่คือป้ายทะเบียน", romanization: "nîi khuue bpàai thá-bian", english: "This is license plate", hindi: "यह नंबर प्लेट है"),
        ],
        1125: [
            WordExample(thai: "ผมชอบน้ำมันเชื้อเพลิง", romanization: "phǒm chôp náam-man chʉ́ʉa-phloeng", english: "I like fuel", hindi: "मुझे ईंधन पसंद है"),
            WordExample(thai: "นี่คือน้ำมันเชื้อเพลิง", romanization: "nîi khuue náam-man chʉ́ʉa-phloeng", english: "This is fuel", hindi: "यह ईंधन है"),
        ],
        1126: [
            WordExample(thai: "ผมชอบการจราจร", romanization: "phǒm chôp gaan jà-raa-jon", english: "I like traffic", hindi: "मुझे यातायात पसंद है"),
            WordExample(thai: "นี่คือการจราจร", romanization: "nîi khuue gaan jà-raa-jon", english: "This is traffic", hindi: "यह यातायात है"),
        ],
        1127: [
            WordExample(thai: "ผมชอบเช็กอิน", romanization: "phǒm chôp chék-in", english: "I like check in", hindi: "मुझे चेक-इन करना पसंद है"),
            WordExample(thai: "นี่คือเช็กอิน", romanization: "nîi khuue chék-in", english: "This is check in", hindi: "यह चेक-इन करना है"),
        ],
        1128: [
            WordExample(thai: "ผมชอบเช็กเอาต์", romanization: "phǒm chôp chék-àao", english: "I like check out", hindi: "मुझे चेक-आउट करना पसंद है"),
            WordExample(thai: "นี่คือเช็กเอาต์", romanization: "nîi khuue chék-àao", english: "This is check out", hindi: "यह चेक-आउट करना है"),
        ],
        1129: [
            WordExample(thai: "ผมชอบห้องพัก", romanization: "phǒm chôp hâawng-phák", english: "I like guest room", hindi: "मुझे कमरा पसंद है"),
            WordExample(thai: "นี่คือห้องพัก", romanization: "nîi khuue hâawng-phák", english: "This is guest room", hindi: "यह कमरा है"),
        ],
        1130: [
            WordExample(thai: "ผมชอบห้องเดี่ยว", romanization: "phǒm chôp hâawng-dìao", english: "I like single room", hindi: "मुझे सिंगल कमरा पसंद है"),
            WordExample(thai: "นี่คือห้องเดี่ยว", romanization: "nîi khuue hâawng-dìao", english: "This is single room", hindi: "यह सिंगल कमरा है"),
        ],
        1131: [
            WordExample(thai: "ผมชอบห้องคู่", romanization: "phǒm chôp hâawng-khûu", english: "I like double room", hindi: "मुझे डबल कमरा पसंद है"),
            WordExample(thai: "นี่คือห้องคู่", romanization: "nîi khuue hâawng-khûu", english: "This is double room", hindi: "यह डबल कमरा है"),
        ],
        1132: [
            WordExample(thai: "ผมชอบห้องสวีท", romanization: "phǒm chôp hâawng sà-wìit", english: "I like suite", hindi: "मुझे सुइट पसंद है"),
            WordExample(thai: "นี่คือห้องสวีท", romanization: "nîi khuue hâawng sà-wìit", english: "This is suite", hindi: "यह सुइट है"),
        ],
        1133: [
            WordExample(thai: "ผมชอบการจอง", romanization: "phǒm chôp gaan-jawng", english: "I like reservation", hindi: "मुझे आरक्षण पसंद है"),
            WordExample(thai: "นี่คือการจอง", romanization: "nîi khuue gaan-jawng", english: "This is reservation", hindi: "यह आरक्षण है"),
        ],
        1134: [
            WordExample(thai: "ผมชอบใบจอง", romanization: "phǒm chôp bai-jawng", english: "I like booking confirmation", hindi: "मुझे बुकिंग पर्ची पसंद है"),
            WordExample(thai: "นี่คือใบจอง", romanization: "nîi khuue bai-jawng", english: "This is booking confirmation", hindi: "यह बुकिंग पर्ची है"),
        ],
        1135: [
            WordExample(thai: "ผมชอบแผนกต้อนรับ", romanization: "phǒm chôp phà-naek dtâawn-ráp", english: "I like reception desk", hindi: "मुझे रिसेप्शन पसंद है"),
            WordExample(thai: "นี่คือแผนกต้อนรับ", romanization: "nîi khuue phà-naek dtâawn-ráp", english: "This is reception desk", hindi: "यह रिसेप्शन है"),
        ],
        1136: [
            WordExample(thai: "ผมชอบพนักงานต้อนรับ", romanization: "phǒm chôp phá-nák-ngaan dtâawn-ráp", english: "I like receptionist", hindi: "मुझे रिसेप्शनिस्ट पसंद है"),
            WordExample(thai: "นี่คือพนักงานต้อนรับ", romanization: "nîi khuue phá-nák-ngaan dtâawn-ráp", english: "This is receptionist", hindi: "यह रिसेप्शनिस्ट है"),
        ],
        1137: [
            WordExample(thai: "ผมชอบคีย์การ์ด", romanization: "phǒm chôp khii-gaat", english: "I like key card", hindi: "मुझे की कार्ड पसंद है"),
            WordExample(thai: "นี่คือคีย์การ์ด", romanization: "nîi khuue khii-gaat", english: "This is key card", hindi: "यह की कार्ड है"),
        ],
        1138: [
            WordExample(thai: "ผมชอบบัตรห้องพัก", romanization: "phǒm chôp bàt hâawng-phák", english: "I like room key card", hindi: "मुझे रूम कार्ड पसंद है"),
            WordExample(thai: "นี่คือบัตรห้องพัก", romanization: "nîi khuue bàt hâawng-phák", english: "This is room key card", hindi: "यह रूम कार्ड है"),
        ],
        1139: [
            WordExample(thai: "ผมชอบล็อบบี้", romanization: "phǒm chôp lɔ́p-bîi", english: "I like lobby", hindi: "मुझे लॉबी पसंद है"),
            WordExample(thai: "นี่คือล็อบบี้", romanization: "nîi khuue lɔ́p-bîi", english: "This is lobby", hindi: "यह लॉबी है"),
        ],
        1140: [
            WordExample(thai: "ผมชอบชั้นล่าง", romanization: "phǒm chôp chán-lâang", english: "I like ground floor", hindi: "मुझे नीचे की मंज़िल पसंद है"),
            WordExample(thai: "นี่คือชั้นล่าง", romanization: "nîi khuue chán-lâang", english: "This is ground floor", hindi: "यह नीचे की मंज़िल है"),
        ],
        1141: [
            WordExample(thai: "ผมชอบชั้นบน", romanization: "phǒm chôp chán-bon", english: "I like upper floor", hindi: "मुझे ऊपरी मंज़िल पसंद है"),
            WordExample(thai: "นี่คือชั้นบน", romanization: "nîi khuue chán-bon", english: "This is upper floor", hindi: "यह ऊपरी मंज़िल है"),
        ],
        1142: [
            WordExample(thai: "ผมชอบบริการ", romanization: "phǒm chôp baw-rí-gaan", english: "I like service", hindi: "मुझे सेवा पसंद है"),
            WordExample(thai: "นี่คือบริการ", romanization: "nîi khuue baw-rí-gaan", english: "This is service", hindi: "यह सेवा है"),
        ],
        1143: [
            WordExample(thai: "ผมชอบรูมเซอร์วิส", romanization: "phǒm chôp ruum-səə-wít", english: "I like room service", hindi: "मुझे रूम सर्विस पसंद है"),
            WordExample(thai: "นี่คือรูมเซอร์วิส", romanization: "nîi khuue ruum-səə-wít", english: "This is room service", hindi: "यह रूम सर्विस है"),
        ],
        1144: [
            WordExample(thai: "ผมชอบสระว่ายน้ำ", romanization: "phǒm chôp sà-wàai-náam", english: "I like swimming pool", hindi: "मुझे स्विमिंग पूल पसंद है"),
            WordExample(thai: "นี่คือสระว่ายน้ำ", romanization: "nîi khuue sà-wàai-náam", english: "This is swimming pool", hindi: "यह स्विमिंग पूल है"),
        ],
        1145: [
            WordExample(thai: "ผมชอบฟิตเนส", romanization: "phǒm chôp fít-nèet", english: "I like fitness center", hindi: "मुझे फिटनेस केंद्र पसंद है"),
            WordExample(thai: "นี่คือฟิตเนส", romanization: "nîi khuue fít-nèet", english: "This is fitness center", hindi: "यह फिटनेस केंद्र है"),
        ],
        1146: [
            WordExample(thai: "ผมชอบเครื่องปรับอากาศ", romanization: "phǒm chôp khrʉ̂ang bpràp aa-gàat", english: "I like air conditioner", hindi: "मुझे एयर कंडीशनर पसंद है"),
            WordExample(thai: "นี่คือเครื่องปรับอากาศ", romanization: "nîi khuue khrʉ̂ang bpràp aa-gàat", english: "This is air conditioner", hindi: "यह एयर कंडीशनर है"),
        ],
        1147: [
            WordExample(thai: "ผมชอบเที่ยวบิน", romanization: "phǒm chôp thîao-bin", english: "I like flight", hindi: "मुझे उड़ान पसंद है"),
            WordExample(thai: "นี่คือเที่ยวบิน", romanization: "nîi khuue thîao-bin", english: "This is flight", hindi: "यह उड़ान है"),
        ],
        1148: [
            WordExample(thai: "ผมชอบเที่ยวบินภายในประเทศ", romanization: "phǒm chôp thîao-bin phaai nai bprà-thêet", english: "I like domestic flight", hindi: "मुझे घरेलू उड़ान पसंद है"),
            WordExample(thai: "นี่คือเที่ยวบินภายในประเทศ", romanization: "nîi khuue thîao-bin phaai nai bprà-thêet", english: "This is domestic flight", hindi: "यह घरेलू उड़ान है"),
        ],
        1149: [
            WordExample(thai: "ผมชอบเที่ยวบินระหว่างประเทศ", romanization: "phǒm chôp thîao-bin rá-wàang bprà-thêet", english: "I like international flight", hindi: "मुझे अंतरराष्ट्रीय उड़ान पसंद है"),
            WordExample(thai: "นี่คือเที่ยวบินระหว่างประเทศ", romanization: "nîi khuue thîao-bin rá-wàang bprà-thêet", english: "This is international flight", hindi: "यह अंतरराष्ट्रीय उड़ान है"),
        ],
        1150: [
            WordExample(thai: "ผมชอบสายการบิน", romanization: "phǒm chôp sǎai-gaan-bin", english: "I like airline", hindi: "मुझे विमान कंपनी पसंद है"),
            WordExample(thai: "นี่คือสายการบิน", romanization: "nîi khuue sǎai-gaan-bin", english: "This is airline", hindi: "यह विमान कंपनी है"),
        ],
        1151: [
            WordExample(thai: "ผมชอบประตูขึ้นเครื่อง", romanization: "phǒm chôp bprà-dtuu khʉ̂n khrʉ̂ang", english: "I like boarding gate", hindi: "मुझे बोर्डिंग गेट पसंद है"),
            WordExample(thai: "นี่คือประตูขึ้นเครื่อง", romanization: "nîi khuue bprà-dtuu khʉ̂n khrʉ̂ang", english: "This is boarding gate", hindi: "यह बोर्डिंग गेट है"),
        ],
        1152: [
            WordExample(thai: "ผมชอบบัตรขึ้นเครื่อง", romanization: "phǒm chôp bàt khʉ̂n khrʉ̂ang", english: "I like boarding pass", hindi: "मुझे बोर्डिंग पास पसंद है"),
            WordExample(thai: "นี่คือบัตรขึ้นเครื่อง", romanization: "nîi khuue bàt khʉ̂n khrʉ̂ang", english: "This is boarding pass", hindi: "यह बोर्डिंग पास है"),
        ],
        1153: [
            WordExample(thai: "ผมชอบเคาน์เตอร์เช็กอิน", romanization: "phǒm chôp khao-dtəə chék-in", english: "I like check-in counter", hindi: "मुझे चेक-इन काउंटर पसंद है"),
            WordExample(thai: "นี่คือเคาน์เตอร์เช็กอิน", romanization: "nîi khuue khao-dtəə chék-in", english: "This is check-in counter", hindi: "यह चेक-इन काउंटर है"),
        ],
        1154: [
            WordExample(thai: "ผมชอบสัมภาระ", romanization: "phǒm chôp sǎm-phaa-rá", english: "I like luggage", hindi: "मुझे सामान पसंद है"),
            WordExample(thai: "นี่คือสัมภาระ", romanization: "nîi khuue sǎm-phaa-rá", english: "This is luggage", hindi: "यह सामान है"),
        ],
        1155: [
            WordExample(thai: "ผมชอบกระเป๋าโหลด", romanization: "phǒm chôp krà-bpǎo lòot", english: "I like checked bag", hindi: "मुझे चेक किया बैग पसंद है"),
            WordExample(thai: "นี่คือกระเป๋าโหลด", romanization: "nîi khuue krà-bpǎo lòot", english: "This is checked bag", hindi: "यह चेक किया बैग है"),
        ],
        1156: [
            WordExample(thai: "ผมชอบน้ำหนักกระเป๋า", romanization: "phǒm chôp náam-nàk krà-bpǎo", english: "I like baggage weight", hindi: "मुझे बैग का वज़न पसंद है"),
            WordExample(thai: "นี่คือน้ำหนักกระเป๋า", romanization: "nîi khuue náam-nàk krà-bpǎo", english: "This is baggage weight", hindi: "यह बैग का वज़न है"),
        ],
        1157: [
            WordExample(thai: "ผมชอบตรวจคนเข้าเมือง", romanization: "phǒm chôp dtrùat khon khâo mʉang", english: "I like immigration", hindi: "मुझे आप्रवासन पसंद है"),
            WordExample(thai: "นี่คือตรวจคนเข้าเมือง", romanization: "nîi khuue dtrùat khon khâo mʉang", english: "This is immigration", hindi: "यह आप्रवासन है"),
        ],
        1158: [
            WordExample(thai: "ผมชอบศุลกากร", romanization: "phǒm chôp sǔn-lá-gaa-gawn", english: "I like customs", hindi: "मुझे सीमा शुल्क पसंद है"),
            WordExample(thai: "นี่คือศุลกากร", romanization: "nîi khuue sǔn-lá-gaa-gawn", english: "This is customs", hindi: "यह सीमा शुल्क है"),
        ],
        1159: [
            WordExample(thai: "ผมชอบขาออก", romanization: "phǒm chôp khǎa-àawk", english: "I like departures", hindi: "मुझे प्रस्थान पसंद है"),
            WordExample(thai: "นี่คือขาออก", romanization: "nîi khuue khǎa-àawk", english: "This is departures", hindi: "यह प्रस्थान है"),
        ],
        1160: [
            WordExample(thai: "ผมชอบขาเข้า", romanization: "phǒm chôp khǎa-khâo", english: "I like arrivals", hindi: "मुझे आगमन पसंद है"),
            WordExample(thai: "นี่คือขาเข้า", romanization: "nîi khuue khǎa-khâo", english: "This is arrivals", hindi: "यह आगमन है"),
        ],
        1161: [
            WordExample(thai: "ผมชอบเที่ยวบินล่าช้า", romanization: "phǒm chôp thîao-bin lâa-cháa", english: "I like delayed flight", hindi: "मुझे देरी से उड़ान पसंद है"),
            WordExample(thai: "นี่คือเที่ยวบินล่าช้า", romanization: "nîi khuue thîao-bin lâa-cháa", english: "This is delayed flight", hindi: "यह देरी से उड़ान है"),
        ],
        1162: [
            WordExample(thai: "ผมชอบยกเลิกเที่ยวบิน", romanization: "phǒm chôp yók-ləək thîao-bin", english: "I like cancel a flight", hindi: "मुझे उड़ान रद्द करना पसंद है"),
            WordExample(thai: "นี่คือยกเลิกเที่ยวบิน", romanization: "nîi khuue yók-ləək thîao-bin", english: "This is cancel a flight", hindi: "यह उड़ान रद्द करना है"),
        ],
        1163: [
            WordExample(thai: "ผมชอบจุดรับกระเป๋า", romanization: "phǒm chôp jùt ráp krà-bpǎo", english: "I like baggage claim", hindi: "मुझे बैग लेने की जगह पसंद है"),
            WordExample(thai: "นี่คือจุดรับกระเป๋า", romanization: "nîi khuue jùt ráp krà-bpǎo", english: "This is baggage claim", hindi: "यह बैग लेने की जगह है"),
        ],
        1164: [
            WordExample(thai: "ผมชอบเทอร์มินัล", romanization: "phǒm chôp thəə-mə-nan", english: "I like terminal", hindi: "मुझे टर्मिनल पसंद है"),
            WordExample(thai: "นี่คือเทอร์มินัล", romanization: "nîi khuue thəə-mə-nan", english: "This is terminal", hindi: "यह टर्मिनल है"),
        ],
        1165: [
            WordExample(thai: "ผมชอบรันเวย์", romanization: "phǒm chôp ran-wee", english: "I like runway", hindi: "मुझे रनवे पसंद है"),
            WordExample(thai: "นี่คือรันเวย์", romanization: "nîi khuue ran-wee", english: "This is runway", hindi: "यह रनवे है"),
        ],
        1166: [
            WordExample(thai: "ผมชอบเครื่องบิน", romanization: "phǒm chôp khrʉ̂ang-bin", english: "I like airplane", hindi: "मुझे हवाई जहाज़ पसंद है"),
            WordExample(thai: "นี่คือเครื่องบิน", romanization: "nîi khuue khrʉ̂ang-bin", english: "This is airplane", hindi: "यह हवाई जहाज़ है"),
        ],
        1167: [
            WordExample(thai: "ผมชอบพยากรณ์อากาศ", romanization: "phǒm chôp phá-yaa-gawn aa-gàat", english: "I like weather forecast", hindi: "मुझे मौसम पूर्वानुमान पसंद है"),
            WordExample(thai: "นี่คือพยากรณ์อากาศ", romanization: "nîi khuue phá-yaa-gawn aa-gàat", english: "This is weather forecast", hindi: "यह मौसम पूर्वानुमान है"),
        ],
        1168: [
            WordExample(thai: "ผมชอบพายุ", romanization: "phǒm chôp phaa-yú", english: "I like storm", hindi: "मुझे तूफान पसंद है"),
            WordExample(thai: "นี่คือพายุ", romanization: "nîi khuue phaa-yú", english: "This is storm", hindi: "यह तूफान है"),
        ],
        1169: [
            WordExample(thai: "ผมชอบพายุฝน", romanization: "phǒm chôp phaa-yú fǒn", english: "I like rainstorm", hindi: "मुझे बारिश का तूफान पसंद है"),
            WordExample(thai: "นี่คือพายุฝน", romanization: "nîi khuue phaa-yú fǒn", english: "This is rainstorm", hindi: "यह बारिश का तूफान है"),
        ],
        1170: [
            WordExample(thai: "ผมชอบเมฆ", romanization: "phǒm chôp mêek", english: "I like cloud", hindi: "मुझे बादल पसंद है"),
            WordExample(thai: "นี่คือเมฆ", romanization: "nîi khuue mêek", english: "This is cloud", hindi: "यह बादल है"),
        ],
        1171: [
            WordExample(thai: "ผมชอบมีเมฆมาก", romanization: "phǒm chôp mii mêek mâak", english: "I like cloudy", hindi: "मुझे बादलों भरा पसंद है"),
            WordExample(thai: "นี่คือมีเมฆมาก", romanization: "nîi khuue mii mêek mâak", english: "This is cloudy", hindi: "यह बादलों भरा है"),
        ],
        1172: [
            WordExample(thai: "ผมชอบฟ้าร้อง", romanization: "phǒm chôp fáa-ráawng", english: "I like thunder", hindi: "मुझे गरज पसंद है"),
            WordExample(thai: "นี่คือฟ้าร้อง", romanization: "nîi khuue fáa-ráawng", english: "This is thunder", hindi: "यह गरज है"),
        ],
        1173: [
            WordExample(thai: "ผมชอบฟ้าแลบ", romanization: "phǒm chôp fáa-lâaep", english: "I like lightning", hindi: "मुझे बिजली पसंद है"),
            WordExample(thai: "นี่คือฟ้าแลบ", romanization: "nîi khuue fáa-lâaep", english: "This is lightning", hindi: "यह बिजली है"),
        ],
        1174: [
            WordExample(thai: "ผมชอบหมอก", romanization: "phǒm chôp màawk", english: "I like fog", hindi: "मुझे कोहरा पसंद है"),
            WordExample(thai: "นี่คือหมอก", romanization: "nîi khuue màawk", english: "This is fog", hindi: "यह कोहरा है"),
        ],
        1175: [
            WordExample(thai: "ผมชอบความชื้น", romanization: "phǒm chôp khwaam-chʉ́ʉn", english: "I like humidity", hindi: "मुझे नमी पसंद है"),
            WordExample(thai: "นี่คือความชื้น", romanization: "nîi khuue khwaam-chʉ́ʉn", english: "This is humidity", hindi: "यह नमी है"),
        ],
        1176: [
            WordExample(thai: "ผมชอบอุณหภูมิ", romanization: "phǒm chôp un-hà-phuum", english: "I like temperature", hindi: "मुझे तापमान पसंद है"),
            WordExample(thai: "นี่คืออุณหภูมิ", romanization: "nîi khuue un-hà-phuum", english: "This is temperature", hindi: "यह तापमान है"),
        ],
        1177: [
            WordExample(thai: "ผมชอบองศา", romanization: "phǒm chôp ong-sǎa", english: "I like degree", hindi: "मुझे डिग्री पसंद है"),
            WordExample(thai: "นี่คือองศา", romanization: "nîi khuue ong-sǎa", english: "This is degree", hindi: "यह डिग्री है"),
        ],
        1178: [
            WordExample(thai: "ผมชอบร้อนจัด", romanization: "phǒm chôp ráawn-jàt", english: "I like very hot", hindi: "मुझे बहुत गर्म पसंद है"),
            WordExample(thai: "นี่คือร้อนจัด", romanization: "nîi khuue ráawn-jàt", english: "This is very hot", hindi: "यह बहुत गर्म है"),
        ],
        1179: [
            WordExample(thai: "ผมชอบหนาวจัด", romanization: "phǒm chôp nǎao-jàt", english: "I like very cold", hindi: "मुझे बहुत ठंडा पसंद है"),
            WordExample(thai: "นี่คือหนาวจัด", romanization: "nîi khuue nǎao-jàt", english: "This is very cold", hindi: "यह बहुत ठंडा है"),
        ],
        1180: [
            WordExample(thai: "ผมชอบลมแรง", romanization: "phǒm chôp lom-raaeng", english: "I like strong wind", hindi: "मुझे तेज़ हवा पसंद है"),
            WordExample(thai: "นี่คือลมแรง", romanization: "nîi khuue lom-raaeng", english: "This is strong wind", hindi: "यह तेज़ हवा है"),
        ],
        1181: [
            WordExample(thai: "ผมชอบลมพัด", romanization: "phǒm chôp lom-phát", english: "I like wind blows", hindi: "मुझे हवा चलती है पसंद है"),
            WordExample(thai: "นี่คือลมพัด", romanization: "nîi khuue lom-phát", english: "This is wind blows", hindi: "यह हवा चलती है है"),
        ],
        1182: [
            WordExample(thai: "ผมชอบฝนตก", romanization: "phǒm chôp fǒn-dtòk", english: "I like rain", hindi: "मुझे बारिश होना पसंद है"),
            WordExample(thai: "นี่คือฝนตก", romanization: "nîi khuue fǒn-dtòk", english: "This is rain", hindi: "यह बारिश होना है"),
        ],
        1183: [
            WordExample(thai: "ผมชอบฝนปรอย", romanization: "phǒm chôp fǒn-bprɔɔi", english: "I like drizzle", hindi: "मुझे फुहार पसंद है"),
            WordExample(thai: "นี่คือฝนปรอย", romanization: "nîi khuue fǒn-bprɔɔi", english: "This is drizzle", hindi: "यह फुहार है"),
        ],
        1184: [
            WordExample(thai: "ผมชอบรุ้งกินน้ำ", romanization: "phǒm chôp rúng gin náam", english: "I like rainbow", hindi: "मुझे इंद्रधनुष पसंद है"),
            WordExample(thai: "นี่คือรุ้งกินน้ำ", romanization: "nîi khuue rúng gin náam", english: "This is rainbow", hindi: "यह इंद्रधनुष है"),
        ],
        1185: [
            WordExample(thai: "ผมชอบฤดูฝน", romanization: "phǒm chôp réu-duu fǒn", english: "I like rainy season", hindi: "मुझे बरसात का मौसम पसंद है"),
            WordExample(thai: "นี่คือฤดูฝน", romanization: "nîi khuue réu-duu fǒn", english: "This is rainy season", hindi: "यह बरसात का मौसम है"),
        ],
        1186: [
            WordExample(thai: "ผมชอบฤดูหนาว", romanization: "phǒm chôp réu-duu nǎao", english: "I like winter", hindi: "मुझे सर्दी का मौसम पसंद है"),
            WordExample(thai: "นี่คือฤดูหนาว", romanization: "nîi khuue réu-duu nǎao", english: "This is winter", hindi: "यह सर्दी का मौसम है"),
        ],
        1187: [
            WordExample(thai: "ผมชอบป่า", romanization: "phǒm chôp bpàa", english: "I like forest", hindi: "मुझे जंगल पसंद है"),
            WordExample(thai: "นี่คือป่า", romanization: "nîi khuue bpàa", english: "This is forest", hindi: "यह जंगल है"),
        ],
        1188: [
            WordExample(thai: "ผมชอบป่าไม้", romanization: "phǒm chôp bpàa-máai", english: "I like forest", hindi: "मुझे वन पसंद है"),
            WordExample(thai: "นี่คือป่าไม้", romanization: "nîi khuue bpàa-máai", english: "This is forest", hindi: "यह वन है"),
        ],
        1189: [
            WordExample(thai: "ผมชอบน้ำตก", romanization: "phǒm chôp náam-dtòk", english: "I like waterfall", hindi: "मुझे झरना पसंद है"),
            WordExample(thai: "นี่คือน้ำตก", romanization: "nîi khuue náam-dtòk", english: "This is waterfall", hindi: "यह झरना है"),
        ],
        1190: [
            WordExample(thai: "ผมชอบลำธาร", romanization: "phǒm chôp lam-thaan", english: "I like stream", hindi: "मुझे नाला पसंद है"),
            WordExample(thai: "นี่คือลำธาร", romanization: "nîi khuue lam-thaan", english: "This is stream", hindi: "यह नाला है"),
        ],
        1191: [
            WordExample(thai: "ผมชอบหุบเขา", romanization: "phǒm chôp hùp-khǎo", english: "I like valley", hindi: "मुझे घाटी पसंद है"),
            WordExample(thai: "นี่คือหุบเขา", romanization: "nîi khuue hùp-khǎo", english: "This is valley", hindi: "यह घाटी है"),
        ],
        1192: [
            WordExample(thai: "ผมชอบเนินเขา", romanization: "phǒm chôp noen-khǎo", english: "I like hill", hindi: "मुझे पहाड़ी पसंद है"),
            WordExample(thai: "นี่คือเนินเขา", romanization: "nîi khuue noen-khǎo", english: "This is hill", hindi: "यह पहाड़ी है"),
        ],
        1193: [
            WordExample(thai: "ผมชอบหน้าผา", romanization: "phǒm chôp nâa-phǎa", english: "I like cliff", hindi: "मुझे चट्टान पसंद है"),
            WordExample(thai: "นี่คือหน้าผา", romanization: "nîi khuue nâa-phǎa", english: "This is cliff", hindi: "यह चट्टान है"),
        ],
        1194: [
            WordExample(thai: "ผมชอบถ้ำ", romanization: "phǒm chôp thâm", english: "I like cave", hindi: "मुझे गुफा पसंद है"),
            WordExample(thai: "นี่คือถ้ำ", romanization: "nîi khuue thâm", english: "This is cave", hindi: "यह गुफा है"),
        ],
        1195: [
            WordExample(thai: "ผมชอบทะเลสาบ", romanization: "phǒm chôp tha-lee-sàap", english: "I like lake", hindi: "मुझे झील पसंद है"),
            WordExample(thai: "นี่คือทะเลสาบ", romanization: "nîi khuue tha-lee-sàap", english: "This is lake", hindi: "यह झील है"),
        ],
        1196: [
            WordExample(thai: "ผมชอบชายฝั่ง", romanization: "phǒm chôp chaai-fàng", english: "I like coast", hindi: "मुझे तट पसंद है"),
            WordExample(thai: "นี่คือชายฝั่ง", romanization: "nîi khuue chaai-fàng", english: "This is coast", hindi: "यह तट है"),
        ],
        1197: [
            WordExample(thai: "ผมชอบเกาะแก่ง", romanization: "phǒm chôp gàaw-gàaeng", english: "I like islets and rapids", hindi: "मुझे टापू और तेज़ धार पसंद है"),
            WordExample(thai: "นี่คือเกาะแก่ง", romanization: "nîi khuue gàaw-gàaeng", english: "This is islets and rapids", hindi: "यह टापू और तेज़ धार है"),
        ],
        1198: [
            WordExample(thai: "ผมชอบดิน", romanization: "phǒm chôp din", english: "I like soil", hindi: "मुझे मिट्टी पसंद है"),
            WordExample(thai: "นี่คือดิน", romanization: "nîi khuue din", english: "This is soil", hindi: "यह मिट्टी है"),
        ],
        1199: [
            WordExample(thai: "ผมชอบทราย", romanization: "phǒm chôp saai", english: "I like sand", hindi: "मुझे रेत पसंद है"),
            WordExample(thai: "นี่คือทราย", romanization: "nîi khuue saai", english: "This is sand", hindi: "यह रेत है"),
        ],
        1200: [
            WordExample(thai: "ผมชอบหิน", romanization: "phǒm chôp hǐn", english: "I like stone", hindi: "मुझे पत्थर पसंद है"),
            WordExample(thai: "นี่คือหิน", romanization: "nîi khuue hǐn", english: "This is stone", hindi: "यह पत्थर है"),
        ],
        1201: [
            WordExample(thai: "ผมชอบก้อนหิน", romanization: "phǒm chôp gâawn-hǐn", english: "I like rock", hindi: "मुझे चट्टान पसंद है"),
            WordExample(thai: "นี่คือก้อนหิน", romanization: "nîi khuue gâawn-hǐn", english: "This is rock", hindi: "यह चट्टान है"),
        ],
        1202: [
            WordExample(thai: "ผมชอบใบไม้", romanization: "phǒm chôp bai-máai", english: "I like leaf", hindi: "मुझे पत्ता पसंद है"),
            WordExample(thai: "นี่คือใบไม้", romanization: "nîi khuue bai-máai", english: "This is leaf", hindi: "यह पत्ता है"),
        ],
        1203: [
            WordExample(thai: "ผมชอบกิ่งไม้", romanization: "phǒm chôp gìng-máai", english: "I like branch", hindi: "मुझे डाल पसंद है"),
            WordExample(thai: "นี่คือกิ่งไม้", romanization: "nîi khuue gìng-máai", english: "This is branch", hindi: "यह डाल है"),
        ],
        1204: [
            WordExample(thai: "ผมชอบรากไม้", romanization: "phǒm chôp râak-máai", english: "I like root", hindi: "मुझे जड़ पसंद है"),
            WordExample(thai: "นี่คือรากไม้", romanization: "nîi khuue râak-máai", english: "This is root", hindi: "यह जड़ है"),
        ],
        1205: [
            WordExample(thai: "ผมชอบท้องฟ้า", romanization: "phǒm chôp tháawng-fáa", english: "I like sky", hindi: "मुझे आकाश पसंद है"),
            WordExample(thai: "นี่คือท้องฟ้า", romanization: "nîi khuue tháawng-fáa", english: "This is sky", hindi: "यह आकाश है"),
        ],
        1206: [
            WordExample(thai: "ผมชอบพระอาทิตย์", romanization: "phǒm chôp phrá-aa-thít", english: "I like sun", hindi: "मुझे सूरज पसंद है"),
            WordExample(thai: "นี่คือพระอาทิตย์", romanization: "nîi khuue phrá-aa-thít", english: "This is sun", hindi: "यह सूरज है"),
        ],
        1207: [
            WordExample(thai: "ผมชอบสุนัข", romanization: "phǒm chôp sù-nák", english: "I like dog", hindi: "मुझे कुत्ता पसंद है"),
            WordExample(thai: "นี่คือสุนัข", romanization: "nîi khuue sù-nák", english: "This is dog", hindi: "यह कुत्ता है"),
        ],
        1208: [
            WordExample(thai: "ผมชอบกระต่าย", romanization: "phǒm chôp krà-dtàai", english: "I like rabbit", hindi: "मुझे खरगोश पसंद है"),
            WordExample(thai: "นี่คือกระต่าย", romanization: "nîi khuue krà-dtàai", english: "This is rabbit", hindi: "यह खरगोश है"),
        ],
        1209: [
            WordExample(thai: "ผมชอบลิง", romanization: "phǒm chôp ling", english: "I like monkey", hindi: "मुझे बंदर पसंद है"),
            WordExample(thai: "นี่คือลิง", romanization: "nîi khuue ling", english: "This is monkey", hindi: "यह बंदर है"),
        ],
        1210: [
            WordExample(thai: "ผมชอบเสือ", romanization: "phǒm chôp sʉ̌ʉa", english: "I like tiger", hindi: "मुझे बाघ पसंद है"),
            WordExample(thai: "นี่คือเสือ", romanization: "nîi khuue sʉ̌ʉa", english: "This is tiger", hindi: "यह बाघ है"),
        ],
        1211: [
            WordExample(thai: "ผมชอบสิงโต", romanization: "phǒm chôp sǐng-dtoo", english: "I like lion", hindi: "मुझे शेर पसंद है"),
            WordExample(thai: "นี่คือสิงโต", romanization: "nîi khuue sǐng-dtoo", english: "This is lion", hindi: "यह शेर है"),
        ],
        1212: [
            WordExample(thai: "ผมชอบวัว", romanization: "phǒm chôp wua", english: "I like cow", hindi: "मुझे गाय पसंद है"),
            WordExample(thai: "นี่คือวัว", romanization: "nîi khuue wua", english: "This is cow", hindi: "यह गाय है"),
        ],
        1213: [
            WordExample(thai: "ผมชอบควาย", romanization: "phǒm chôp khwaai", english: "I like buffalo", hindi: "मुझे भैंस पसंद है"),
            WordExample(thai: "นี่คือควาย", romanization: "nîi khuue khwaai", english: "This is buffalo", hindi: "यह भैंस है"),
        ],
        1214: [
            WordExample(thai: "ผมชอบม้า", romanization: "phǒm chôp máa", english: "I like horse", hindi: "मुझे घोड़ा पसंद है"),
            WordExample(thai: "นี่คือม้า", romanization: "nîi khuue máa", english: "This is horse", hindi: "यह घोड़ा है"),
        ],
        1215: [
            WordExample(thai: "ผมชอบแพะ", romanization: "phǒm chôp phé", english: "I like goat", hindi: "मुझे बकरी पसंद है"),
            WordExample(thai: "นี่คือแพะ", romanization: "nîi khuue phé", english: "This is goat", hindi: "यह बकरी है"),
        ],
        1216: [
            WordExample(thai: "ผมชอบแกะ", romanization: "phǒm chôp gàe", english: "I like sheep", hindi: "मुझे भेड़ पसंद है"),
            WordExample(thai: "นี่คือแกะ", romanization: "nîi khuue gàe", english: "This is sheep", hindi: "यह भेड़ है"),
        ],
        1217: [
            WordExample(thai: "ผมชอบกวาง", romanization: "phǒm chôp gwaang", english: "I like deer", hindi: "मुझे हिरन पसंद है"),
            WordExample(thai: "นี่คือกวาง", romanization: "nîi khuue gwaang", english: "This is deer", hindi: "यह हिरन है"),
        ],
        1218: [
            WordExample(thai: "ผมชอบหมี", romanization: "phǒm chôp mǐi", english: "I like bear", hindi: "मुझे भालू पसंद है"),
            WordExample(thai: "นี่คือหมี", romanization: "nîi khuue mǐi", english: "This is bear", hindi: "यह भालू है"),
        ],
        1219: [
            WordExample(thai: "ผมชอบงู", romanization: "phǒm chôp nguu", english: "I like snake", hindi: "मुझे साँप पसंद है"),
            WordExample(thai: "นี่คืองู", romanization: "nîi khuue nguu", english: "This is snake", hindi: "यह साँप है"),
        ],
        1220: [
            WordExample(thai: "ผมชอบจระเข้", romanization: "phǒm chôp jaw-rá-khêe", english: "I like crocodile", hindi: "मुझे मगरमच्छ पसंद है"),
            WordExample(thai: "นี่คือจระเข้", romanization: "nîi khuue jaw-rá-khêe", english: "This is crocodile", hindi: "यह मगरमच्छ है"),
        ],
        1221: [
            WordExample(thai: "ผมชอบเต่า", romanization: "phǒm chôp dtào", english: "I like turtle", hindi: "मुझे कछुआ पसंद है"),
            WordExample(thai: "นี่คือเต่า", romanization: "nîi khuue dtào", english: "This is turtle", hindi: "यह कछुआ है"),
        ],
        1222: [
            WordExample(thai: "ผมชอบกบ", romanization: "phǒm chôp gòp", english: "I like frog", hindi: "मुझे मेंढक पसंद है"),
            WordExample(thai: "นี่คือกบ", romanization: "nîi khuue gòp", english: "This is frog", hindi: "यह मेंढक है"),
        ],
        1223: [
            WordExample(thai: "ผมชอบผีเสื้อ", romanization: "phǒm chôp phǐi-sʉ̂ʉa", english: "I like butterfly", hindi: "मुझे तितली पसंद है"),
            WordExample(thai: "นี่คือผีเสื้อ", romanization: "nîi khuue phǐi-sʉ̂ʉa", english: "This is butterfly", hindi: "यह तितली है"),
        ],
        1224: [
            WordExample(thai: "ผมชอบผึ้ง", romanization: "phǒm chôp phʉ̂ng", english: "I like bee", hindi: "मुझे मधुमक्खी पसंद है"),
            WordExample(thai: "นี่คือผึ้ง", romanization: "nîi khuue phʉ̂ng", english: "This is bee", hindi: "यह मधुमक्खी है"),
        ],
        1225: [
            WordExample(thai: "ผมชอบมด", romanization: "phǒm chôp mót", english: "I like ant", hindi: "मुझे चींटी पसंद है"),
            WordExample(thai: "นี่คือมด", romanization: "nîi khuue mót", english: "This is ant", hindi: "यह चींटी है"),
        ],
        1226: [
            WordExample(thai: "ผมชอบปลาโลมา", romanization: "phǒm chôp bplaa-loh-maa", english: "I like dolphin", hindi: "मुझे डॉल्फ़िन पसंद है"),
            WordExample(thai: "นี่คือปลาโลมา", romanization: "nîi khuue bplaa-loh-maa", english: "This is dolphin", hindi: "यह डॉल्फ़िन है"),
        ],
        1227: [
            WordExample(thai: "ผมชอบสีแดง", romanization: "phǒm chôp sǐi-daaeng", english: "I like red", hindi: "मुझे लाल पसंद है"),
            WordExample(thai: "นี่คือสีแดง", romanization: "nîi khuue sǐi-daaeng", english: "This is red", hindi: "यह लाल है"),
        ],
        1228: [
            WordExample(thai: "ผมชอบสีเขียว", romanization: "phǒm chôp sǐi-khǐao", english: "I like green", hindi: "मुझे हरा पसंद है"),
            WordExample(thai: "นี่คือสีเขียว", romanization: "nîi khuue sǐi-khǐao", english: "This is green", hindi: "यह हरा है"),
        ],
        1229: [
            WordExample(thai: "ผมชอบสีฟ้า", romanization: "phǒm chôp sǐi-fáa", english: "I like blue", hindi: "मुझे नीला पसंद है"),
            WordExample(thai: "นี่คือสีฟ้า", romanization: "nîi khuue sǐi-fáa", english: "This is blue", hindi: "यह नीला है"),
        ],
        1230: [
            WordExample(thai: "ผมชอบสีเหลือง", romanization: "phǒm chôp sǐi-lʉ̌ang", english: "I like yellow", hindi: "मुझे पीला पसंद है"),
            WordExample(thai: "นี่คือสีเหลือง", romanization: "nîi khuue sǐi-lʉ̌ang", english: "This is yellow", hindi: "यह पीला है"),
        ],
        1231: [
            WordExample(thai: "ผมชอบสีดำ", romanization: "phǒm chôp sǐi-dam", english: "I like black", hindi: "मुझे काला पसंद है"),
            WordExample(thai: "นี่คือสีดำ", romanization: "nîi khuue sǐi-dam", english: "This is black", hindi: "यह काला है"),
        ],
        1232: [
            WordExample(thai: "ผมชอบสีขาว", romanization: "phǒm chôp sǐi-khǎao", english: "I like white", hindi: "मुझे सफेद पसंद है"),
            WordExample(thai: "นี่คือสีขาว", romanization: "nîi khuue sǐi-khǎao", english: "This is white", hindi: "यह सफेद है"),
        ],
        1233: [
            WordExample(thai: "ผมชอบสีชมพู", romanization: "phǒm chôp sǐi-chom-phuu", english: "I like pink", hindi: "मुझे गुलाबी पसंद है"),
            WordExample(thai: "นี่คือสีชมพู", romanization: "nîi khuue sǐi-chom-phuu", english: "This is pink", hindi: "यह गुलाबी है"),
        ],
        1234: [
            WordExample(thai: "ผมชอบสีม่วง", romanization: "phǒm chôp sǐi-mûang", english: "I like purple", hindi: "मुझे बैंगनी पसंद है"),
            WordExample(thai: "นี่คือสีม่วง", romanization: "nîi khuue sǐi-mûang", english: "This is purple", hindi: "यह बैंगनी है"),
        ],
        1235: [
            WordExample(thai: "ผมชอบสีส้ม", romanization: "phǒm chôp sǐi-sôm", english: "I like orange", hindi: "मुझे नारंगी पसंद है"),
            WordExample(thai: "นี่คือสีส้ม", romanization: "nîi khuue sǐi-sôm", english: "This is orange", hindi: "यह नारंगी है"),
        ],
        1236: [
            WordExample(thai: "ผมชอบสีน้ำตาล", romanization: "phǒm chôp sǐi-náam-dtaan", english: "I like brown", hindi: "मुझे भूरा पसंद है"),
            WordExample(thai: "นี่คือสีน้ำตาล", romanization: "nîi khuue sǐi-náam-dtaan", english: "This is brown", hindi: "यह भूरा है"),
        ],
        1237: [
            WordExample(thai: "ผมชอบเสื้อยืด", romanization: "phǒm chôp sʉ̂ʉa-yʉ̂ʉt", english: "I like T-shirt", hindi: "मुझे टी-शर्ट पसंद है"),
            WordExample(thai: "นี่คือเสื้อยืด", romanization: "nîi khuue sʉ̂ʉa-yʉ̂ʉt", english: "This is T-shirt", hindi: "यह टी-शर्ट है"),
        ],
        1238: [
            WordExample(thai: "ผมชอบเสื้อเชิ้ต", romanization: "phǒm chôp sʉ̂ʉa-chóet", english: "I like shirt", hindi: "मुझे कमीज़ पसंद है"),
            WordExample(thai: "นี่คือเสื้อเชิ้ต", romanization: "nîi khuue sʉ̂ʉa-chóet", english: "This is shirt", hindi: "यह कमीज़ है"),
        ],
        1239: [
            WordExample(thai: "ผมชอบเสื้อกันหนาว", romanization: "phǒm chôp sʉ̂ʉa gan-nǎao", english: "I like sweater", hindi: "मुझे स्वेटर पसंद है"),
            WordExample(thai: "นี่คือเสื้อกันหนาว", romanization: "nîi khuue sʉ̂ʉa gan-nǎao", english: "This is sweater", hindi: "यह स्वेटर है"),
        ],
        1240: [
            WordExample(thai: "ผมชอบเสื้อแจ็กเก็ต", romanization: "phǒm chôp sʉ̂ʉa jáek-gèt", english: "I like jacket", hindi: "मुझे जैकेट पसंद है"),
            WordExample(thai: "นี่คือเสื้อแจ็กเก็ต", romanization: "nîi khuue sʉ̂ʉa jáek-gèt", english: "This is jacket", hindi: "यह जैकेट है"),
        ],
        1241: [
            WordExample(thai: "ผมชอบกระโปรง", romanization: "phǒm chôp krà-bproong", english: "I like skirt", hindi: "मुझे स्कर्ट पसंद है"),
            WordExample(thai: "นี่คือกระโปรง", romanization: "nîi khuue krà-bproong", english: "This is skirt", hindi: "यह स्कर्ट है"),
        ],
        1242: [
            WordExample(thai: "ผมชอบชุดเดรส", romanization: "phǒm chôp chút-dreet", english: "I like dress", hindi: "मुझे ड्रेस पसंद है"),
            WordExample(thai: "นี่คือชุดเดรส", romanization: "nîi khuue chút-dreet", english: "This is dress", hindi: "यह ड्रेस है"),
        ],
        1243: [
            WordExample(thai: "ผมชอบชุดว่ายน้ำ", romanization: "phǒm chôp chút wàai-náam", english: "I like swimsuit", hindi: "मुझे स्विमसूट पसंद है"),
            WordExample(thai: "นี่คือชุดว่ายน้ำ", romanization: "nîi khuue chút wàai-náam", english: "This is swimsuit", hindi: "यह स्विमसूट है"),
        ],
        1244: [
            WordExample(thai: "ผมชอบหมวก", romanization: "phǒm chôp mùak", english: "I like hat", hindi: "मुझे टोपी पसंद है"),
            WordExample(thai: "นี่คือหมวก", romanization: "nîi khuue mùak", english: "This is hat", hindi: "यह टोपी है"),
        ],
        1245: [
            WordExample(thai: "ผมชอบถุงเท้า", romanization: "phǒm chôp thǔng-tháao", english: "I like socks", hindi: "मुझे मोज़े पसंद है"),
            WordExample(thai: "นี่คือถุงเท้า", romanization: "nîi khuue thǔng-tháao", english: "This is socks", hindi: "यह मोज़े है"),
        ],
        1246: [
            WordExample(thai: "ผมชอบเข็มขัด", romanization: "phǒm chôp khěm-khàt", english: "I like belt", hindi: "मुझे बेल्ट पसंद है"),
            WordExample(thai: "นี่คือเข็มขัด", romanization: "nîi khuue khěm-khàt", english: "This is belt", hindi: "यह बेल्ट है"),
        ],
        1247: [
            WordExample(thai: "ผมชอบสถานีรถเมล์", romanization: "phǒm chôp sà-thǎa-nii rót-mee", english: "I like bus station", hindi: "मुझे बस स्टेशन पसंद है"),
            WordExample(thai: "นี่คือสถานีรถเมล์", romanization: "nîi khuue sà-thǎa-nii rót-mee", english: "This is bus station", hindi: "यह बस स्टेशन है"),
        ],
        1248: [
            WordExample(thai: "ผมชอบเช็คอิน", romanization: "phǒm chôp chék-in", english: "I like check-in", hindi: "मुझे चेक-इन पसंद है"),
            WordExample(thai: "นี่คือเช็คอิน", romanization: "nîi khuue chék-in", english: "This is check-in", hindi: "यह चेक-इन है"),
        ],
        1249: [
            WordExample(thai: "ผมชอบเช็คเอาท์", romanization: "phǒm chôp chék-áo", english: "I like check-out", hindi: "मुझे चेक-आउट पसंद है"),
            WordExample(thai: "นี่คือเช็คเอาท์", romanization: "nîi khuue chék-áo", english: "This is check-out", hindi: "यह चेक-आउट है"),
        ],
        1250: [
            WordExample(thai: "ผมชอบที่พัก", romanization: "phǒm chôp thîi-phák", english: "I like accommodation", hindi: "मुझे ठहरने की जगह पसंद है"),
            WordExample(thai: "นี่คือที่พัก", romanization: "nîi khuue thîi-phák", english: "This is accommodation", hindi: "यह ठहरने की जगह है"),
        ],
        1251: [
            WordExample(thai: "ผมชอบเกสต์เฮาส์", romanization: "phǒm chôp kèt-háao", english: "I like guesthouse", hindi: "मुझे गेस्टहाउस पसंद है"),
            WordExample(thai: "นี่คือเกสต์เฮาส์", romanization: "nîi khuue kèt-háao", english: "This is guesthouse", hindi: "यह गेस्टहाउस है"),
        ],
        1252: [
            WordExample(thai: "ผมชอบจีพีเอส", romanization: "phǒm chôp jii-phii-èt", english: "I like GPS", hindi: "मुझे जीपीएस पसंद है"),
            WordExample(thai: "นี่คือจีพีเอส", romanization: "nîi khuue jii-phii-èt", english: "This is GPS", hindi: "यह जीपीएस है"),
        ],
        1253: [
            WordExample(thai: "ผมชอบทิศทาง", romanization: "phǒm chôp thít-thaang", english: "I like direction", hindi: "मुझे दिशा पसंद है"),
            WordExample(thai: "นี่คือทิศทาง", romanization: "nîi khuue thít-thaang", english: "This is direction", hindi: "यह दिशा है"),
        ],
        1254: [
            WordExample(thai: "ผมชอบแยก", romanization: "phǒm chôp yâek", english: "I like intersection", hindi: "मुझे चौराहा पसंद है"),
            WordExample(thai: "นี่คือแยก", romanization: "nîi khuue yâek", english: "This is intersection", hindi: "यह चौराहा है"),
        ],
        1255: [
            WordExample(thai: "ผมชอบไฟเขียว", romanization: "phǒm chôp fai-khǐao", english: "I like green light", hindi: "मुझे हरी बत्ती पसंद है"),
            WordExample(thai: "นี่คือไฟเขียว", romanization: "nîi khuue fai-khǐao", english: "This is green light", hindi: "यह हरी बत्ती है"),
        ],
        1256: [
            WordExample(thai: "ผมชอบจราจร", romanization: "phǒm chôp jà-raa-jon", english: "I like traffic", hindi: "मुझे ट्रैफ़िक पसंद है"),
            WordExample(thai: "นี่คือจราจร", romanization: "nîi khuue jà-raa-jon", english: "This is traffic", hindi: "यह ट्रैफ़िक है"),
        ],
        1257: [
            WordExample(thai: "ผมชอบรถติด", romanization: "phǒm chôp rót-tìt", english: "I like traffic jam", hindi: "मुझे ट्रैफ़िक जाम पसंद है"),
            WordExample(thai: "นี่คือรถติด", romanization: "nîi khuue rót-tìt", english: "This is traffic jam", hindi: "यह ट्रैफ़िक जाम है"),
        ],
        1258: [
            WordExample(thai: "ผมชอบมอเตอร์ไซค์", romanization: "phǒm chôp mɔɔ-təə-sai", english: "I like motorcycle", hindi: "मुझे मोटरसाइकिल पसंद है"),
            WordExample(thai: "นี่คือมอเตอร์ไซค์", romanization: "nîi khuue mɔɔ-təə-sai", english: "This is motorcycle", hindi: "यह मोटरसाइकिल है"),
        ],
        1259: [
            WordExample(thai: "ผมชอบเรือเฟอร์รี่", romanization: "phǒm chôp ruea-fəə-rîi", english: "I like ferry", hindi: "मुझे फेरी पसंद है"),
            WordExample(thai: "นี่คือเรือเฟอร์รี่", romanization: "nîi khuue ruea-fəə-rîi", english: "This is ferry", hindi: "यह फेरी है"),
        ],
        1260: [
            WordExample(thai: "ผมชอบที่นั่ง", romanization: "phǒm chôp thîi-nâng", english: "I like seat", hindi: "मुझे सीट पसंद है"),
            WordExample(thai: "นี่คือที่นั่ง", romanization: "nîi khuue thîi-nâng", english: "This is seat", hindi: "यह सीट है"),
        ],
        1261: [
            WordExample(thai: "ผมชอบเข็มขัดนิรภัย", romanization: "phǒm chôp khěm-khàt ní-rá-phai", english: "I like seat belt", hindi: "मुझे सीट बेल्ट पसंद है"),
            WordExample(thai: "นี่คือเข็มขัดนิรภัย", romanization: "nîi khuue khěm-khàt ní-rá-phai", english: "This is seat belt", hindi: "यह सीट बेल्ट है"),
        ],
        1262: [
            WordExample(thai: "ผมชอบหมวกกันน็อก", romanization: "phǒm chôp mùak-kan-nók", english: "I like helmet", hindi: "मुझे हेलमेट पसंद है"),
            WordExample(thai: "นี่คือหมวกกันน็อก", romanization: "nîi khuue mùak-kan-nók", english: "This is helmet", hindi: "यह हेलमेट है"),
        ],
        1263: [
            WordExample(thai: "ผมชอบฟ้าผ่า", romanization: "phǒm chôp fáa-phàa", english: "I like lightning", hindi: "मुझे बिजली चमकना पसंद है"),
            WordExample(thai: "นี่คือฟ้าผ่า", romanization: "nîi khuue fáa-phàa", english: "This is lightning", hindi: "यह बिजली चमकना है"),
        ],
        1264: [
            WordExample(thai: "ผมชอบน้ำท่วม", romanization: "phǒm chôp náam-thûam", english: "I like flood", hindi: "मुझे बाढ़ पसंद है"),
            WordExample(thai: "นี่คือน้ำท่วม", romanization: "nîi khuue náam-thûam", english: "This is flood", hindi: "यह बाढ़ है"),
        ],
        1265: [
            WordExample(thai: "ผมชอบแผ่นดินไหว", romanization: "phǒm chôp phàen-din-wǎi", english: "I like earthquake", hindi: "मुझे भूकंप पसंद है"),
            WordExample(thai: "นี่คือแผ่นดินไหว", romanization: "nîi khuue phàen-din-wǎi", english: "This is earthquake", hindi: "यह भूकंप है"),
        ],
        1266: [
            WordExample(thai: "ผมชอบภูเขาไฟ", romanization: "phǒm chôp phuu-khǎo-fai", english: "I like volcano", hindi: "मुझे ज्वालामुखी पसंद है"),
            WordExample(thai: "นี่คือภูเขาไฟ", romanization: "nîi khuue phuu-khǎo-fai", english: "This is volcano", hindi: "यह ज्वालामुखी है"),
        ],
        1267: [
            WordExample(thai: "ผมชอบหาด", romanization: "phǒm chôp hàat", english: "I like beach", hindi: "मुझे समुद्र तट पसंद है"),
            WordExample(thai: "นี่คือหาด", romanization: "nîi khuue hàat", english: "This is beach", hindi: "यह समुद्र तट है"),
        ],
        1268: [
            WordExample(thai: "ผมชอบหญ้า", romanization: "phǒm chôp yâa", english: "I like grass", hindi: "मुझे घास पसंद है"),
            WordExample(thai: "นี่คือหญ้า", romanization: "nîi khuue yâa", english: "This is grass", hindi: "यह घास है"),
        ],
        1269: [
            WordExample(thai: "ผมชอบพระจันทร์", romanization: "phǒm chôp phrá-jan", english: "I like the moon", hindi: "मुझे चाँद पसंद है"),
            WordExample(thai: "นี่คือพระจันทร์", romanization: "nîi khuue phrá-jan", english: "This is the moon", hindi: "यह चाँद है"),
        ],
        1270: [
            WordExample(thai: "ผมชอบดาว", romanization: "phǒm chôp daao", english: "I like star", hindi: "मुझे तारा पसंद है"),
            WordExample(thai: "นี่คือดาว", romanization: "nîi khuue daao", english: "This is star", hindi: "यह तारा है"),
        ],
        1271: [
            WordExample(thai: "ผมชอบยุง", romanization: "phǒm chôp yung", english: "I like mosquito", hindi: "मुझे मच्छर पसंद है"),
            WordExample(thai: "นี่คือยุง", romanization: "nîi khuue yung", english: "This is mosquito", hindi: "यह मच्छर है"),
        ],
        1272: [
            WordExample(thai: "ผมชอบเป็ด", romanization: "phǒm chôp pèt", english: "I like duck", hindi: "मुझे बत्तख पसंद है"),
            WordExample(thai: "นี่คือเป็ด", romanization: "nîi khuue pèt", english: "This is duck", hindi: "यह बत्तख है"),
        ],
        1273: [
            WordExample(thai: "ผมชอบหนู", romanization: "phǒm chôp nǔu", english: "I like mouse", hindi: "मुझे चूहा पसंद है"),
            WordExample(thai: "นี่คือหนู", romanization: "nîi khuue nǔu", english: "This is mouse", hindi: "यह चूहा है"),
        ],
        1274: [
            WordExample(thai: "ผมชอบชุด", romanization: "phǒm chôp chút", english: "I like outfit", hindi: "मुझे पोशाक पसंद है"),
            WordExample(thai: "นี่คือชุด", romanization: "nîi khuue chút", english: "This is outfit", hindi: "यह पोशाक है"),
        ],
        1275: [
            WordExample(thai: "ผมชอบแว่นตา", romanization: "phǒm chôp wâen-taa", english: "I like glasses", hindi: "मुझे चश्मा पसंद है"),
            WordExample(thai: "นี่คือแว่นตา", romanization: "nîi khuue wâen-taa", english: "This is glasses", hindi: "यह चश्मा है"),
        ],
        1276: [
            WordExample(thai: "ผมชอบร่ม", romanization: "phǒm chôp rôm", english: "I like umbrella", hindi: "मुझे छाता पसंद है"),
            WordExample(thai: "นี่คือร่ม", romanization: "nîi khuue rôm", english: "This is umbrella", hindi: "यह छाता है"),
        ],
        1277: [
            WordExample(thai: "ผมชอบสีน้ำเงิน", romanization: "phǒm chôp sǐi-nám-ngern", english: "I like blue", hindi: "मुझे नीला पसंद है"),
            WordExample(thai: "นี่คือสีน้ำเงิน", romanization: "nîi khuue sǐi-nám-ngern", english: "This is blue", hindi: "यह नीला है"),
        ],
        1278: [
            WordExample(thai: "ผมชอบสีเทา", romanization: "phǒm chôp sǐi-thao", english: "I like gray", hindi: "मुझे धूसर पसंद है"),
            WordExample(thai: "นี่คือสีเทา", romanization: "nîi khuue sǐi-thao", english: "This is gray", hindi: "यह धूसर है"),
        ],
        1279: [
            WordExample(thai: "ผมชอบแกงเขียวหวาน", romanization: "phǒm chôp kaeng-khǐao-wǎan", english: "I like green curry", hindi: "मुझे ग्रीन करी पसंद है"),
            WordExample(thai: "นี่คือแกงเขียวหวาน", romanization: "nîi khuue kaeng-khǐao-wǎan", english: "This is green curry", hindi: "यह ग्रीन करी है"),
        ],
        1280: [
            WordExample(thai: "ผมชอบชีส", romanization: "phǒm chôp chîis", english: "I like cheese", hindi: "मुझे पनीर पसंद है"),
            WordExample(thai: "นี่คือชีส", romanization: "nîi khuue chîis", english: "This is cheese", hindi: "यह पनीर है"),
        ],
        1281: [
            WordExample(thai: "ผมชอบโยเกิร์ต", romanization: "phǒm chôp yoo-kə̂ət", english: "I like yogurt", hindi: "मुझे दही पसंद है"),
            WordExample(thai: "นี่คือโยเกิร์ต", romanization: "nîi khuue yoo-kə̂ət", english: "This is yogurt", hindi: "यह दही है"),
        ],
        1282: [
            WordExample(thai: "ผมชอบไข่เจียว", romanization: "phǒm chôp khài-jiao", english: "I like omelette", hindi: "मुझे ऑमलेट पसंद है"),
            WordExample(thai: "นี่คือไข่เจียว", romanization: "nîi khuue khài-jiao", english: "This is omelette", hindi: "यह ऑमलेट है"),
        ],
        1283: [
            WordExample(thai: "ผมชอบปู", romanization: "phǒm chôp puu", english: "I like crab", hindi: "मुझे केकड़ा पसंद है"),
            WordExample(thai: "นี่คือปู", romanization: "nîi khuue puu", english: "This is crab", hindi: "यह केकड़ा है"),
        ],
        1284: [
            WordExample(thai: "ผมชอบหมึก", romanization: "phǒm chôp mùek", english: "I like squid", hindi: "मुझे स्क्विड पसंद है"),
            WordExample(thai: "นี่คือหมึก", romanization: "nîi khuue mùek", english: "This is squid", hindi: "यह स्क्विड है"),
        ],
        1285: [
            WordExample(thai: "ผมชอบสัปปะรด", romanization: "phǒm chôp sàp-pà-rót", english: "I like pineapple", hindi: "मुझे अनानास पसंद है"),
            WordExample(thai: "นี่คือสัปปะรด", romanization: "nîi khuue sàp-pà-rót", english: "This is pineapple", hindi: "यह अनानास है"),
        ],
        1286: [
            WordExample(thai: "ผมชอบแอปเปิล", romanization: "phǒm chôp áep-pəən", english: "I like apple", hindi: "मुझे सेब पसंद है"),
            WordExample(thai: "นี่คือแอปเปิล", romanization: "nîi khuue áep-pəən", english: "This is apple", hindi: "यह सेब है"),
        ],
        1287: [
            WordExample(thai: "ผมชอบหอมใหญ่", romanization: "phǒm chôp hǒom-yài", english: "I like onion", hindi: "मुझे प्याज़ पसंद है"),
            WordExample(thai: "นี่คือหอมใหญ่", romanization: "nîi khuue hǒom-yài", english: "This is onion", hindi: "यह प्याज़ है"),
        ],
        1288: [
            WordExample(thai: "ผมชอบสลัด", romanization: "phǒm chôp sà-làt", english: "I like salad", hindi: "मुझे सलाद पसंद है"),
            WordExample(thai: "นี่คือสลัด", romanization: "nîi khuue sà-làt", english: "This is salad", hindi: "यह सलाद है"),
        ],
        1289: [
            WordExample(thai: "ผมชอบพิซซ่า", romanization: "phǒm chôp phít-sâa", english: "I like pizza", hindi: "मुझे पिज़्ज़ा पसंद है"),
            WordExample(thai: "นี่คือพิซซ่า", romanization: "nîi khuue phít-sâa", english: "This is pizza", hindi: "यह पिज़्ज़ा है"),
        ],
        1290: [
            WordExample(thai: "ผมชอบแฮมเบอร์เกอร์", romanization: "phǒm chôp hǎem-bəə-gə̂ə", english: "I like hamburger", hindi: "मुझे बर्गर पसंद है"),
            WordExample(thai: "นี่คือแฮมเบอร์เกอร์", romanization: "nîi khuue hǎem-bəə-gə̂ə", english: "This is hamburger", hindi: "यह बर्गर है"),
        ],
        1291: [
            WordExample(thai: "ผมชอบไวน์", romanization: "phǒm chôp waai", english: "I like wine", hindi: "मुझे वाइन पसंद है"),
            WordExample(thai: "นี่คือไวน์", romanization: "nîi khuue waai", english: "This is wine", hindi: "यह वाइन है"),
        ],
        1292: [
            WordExample(thai: "ผมชอบบิล", romanization: "phǒm chôp bin", english: "I like bill", hindi: "मुझे बिल पसंद है"),
            WordExample(thai: "นี่คือบิล", romanization: "nîi khuue bin", english: "This is bill", hindi: "यह बिल है"),
        ],
        1293: [
            WordExample(thai: "ผมชอบทิป", romanization: "phǒm chôp thíp", english: "I like tip (gratuity)", hindi: "मुझे टिप पसंद है"),
            WordExample(thai: "นี่คือทิป", romanization: "nîi khuue thíp", english: "This is tip (gratuity)", hindi: "यह टिप है"),
        ],
        1294: [
            WordExample(thai: "ผมชอบจองโต๊ะ", romanization: "phǒm chôp jɔɔng-tó", english: "I like reserve a table", hindi: "मुझे टेबल बुक करना पसंद है"),
            WordExample(thai: "นี่คือจองโต๊ะ", romanization: "nîi khuue jɔɔng-tó", english: "This is reserve a table", hindi: "यह टेबल बुक करना है"),
        ],
        1295: [
            WordExample(thai: "ผมชอบบุฟเฟต์", romanization: "phǒm chôp búf-fé", english: "I like buffet", hindi: "मुझे बुफ़े पसंद है"),
            WordExample(thai: "นี่คือบุฟเฟต์", romanization: "nîi khuue búf-fé", english: "This is buffet", hindi: "यह बुफ़े है"),
        ],
        1296: [
            WordExample(thai: "ฉันเตรียมพาสปอร์ตไว้แล้ว", romanization: "chǎn dtriam phâat-sà-pàwt wái-láew", english: "I have prepared the passport.", hindi: "मैंने पासपोर्ट तैयार कर लिया है।"),
            WordExample(thai: "คำว่าพาสปอร์ตใช้บ่อย", romanization: "kham-wâa phâat-sà-pàwt chái bàwy", english: "The word for passport is commonly used.", hindi: "पासपोर्ट के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1297: [
            WordExample(thai: "ฉันเตรียมวีซ่าท่องเที่ยวไว้แล้ว", romanization: "chǎn dtriam wii-sâa thâwng-thîao wái-láew", english: "I have prepared the tourist visa.", hindi: "मैंने पर्यटक वीज़ा तैयार कर लिया है।"),
            WordExample(thai: "คำว่าวีซ่าท่องเที่ยวใช้บ่อย", romanization: "kham-wâa wii-sâa thâwng-thîao chái bàwy", english: "The word for tourist visa is commonly used.", hindi: "पर्यटक वीज़ा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1298: [
            WordExample(thai: "ฉันเตรียมตารางเดินทางไว้แล้ว", romanization: "chǎn dtriam dtaa-raang dəən-thaang wái-láew", english: "I have prepared the travel itinerary.", hindi: "मैंने यात्रा कार्यक्रम तैयार कर लिया है।"),
            WordExample(thai: "คำว่าตารางเดินทางใช้บ่อย", romanization: "kham-wâa dtaa-raang dəən-thaang chái bàwy", english: "The word for travel itinerary is commonly used.", hindi: "यात्रा कार्यक्रम के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1299: [
            WordExample(thai: "ฉันเตรียมจุดนัดพบไว้แล้ว", romanization: "chǎn dtriam jùt-nát-phóp wái-láew", english: "I have prepared the meeting point.", hindi: "मैंने मिलने का स्थान तैयार कर लिया है।"),
            WordExample(thai: "คำว่าจุดนัดพบใช้บ่อย", romanization: "kham-wâa jùt-nát-phóp chái bàwy", english: "The word for meeting point is commonly used.", hindi: "मिलने का स्थान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1300: [
            WordExample(thai: "ฉันเตรียมแผนการเดินทางไว้แล้ว", romanization: "chǎn dtriam phǎen-gaan dəən-thaang wái-láew", english: "I have prepared the travel plan.", hindi: "मैंने यात्रा योजना तैयार कर लिया है।"),
            WordExample(thai: "คำว่าแผนการเดินทางใช้บ่อย", romanization: "kham-wâa phǎen-gaan dəən-thaang chái bàwy", english: "The word for travel plan is commonly used.", hindi: "यात्रा योजना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1301: [
            WordExample(thai: "ฉันเตรียมเดินทางคนเดียวไว้แล้ว", romanization: "chǎn dtriam dəən-thaang khon-diao wái-láew", english: "I have prepared the travel alone.", hindi: "मैंने अकेले यात्रा करना तैयार कर लिया है।"),
            WordExample(thai: "คำว่าเดินทางคนเดียวใช้บ่อย", romanization: "kham-wâa dəən-thaang khon-diao chái bàwy", english: "The word for travel alone is commonly used.", hindi: "अकेले यात्रा करना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1302: [
            WordExample(thai: "ฉันเตรียมท่องเที่ยวเชิงนิเวศไว้แล้ว", romanization: "chǎn dtriam thâwng-thîao chəəng ní-wét wái-láew", english: "I have prepared the ecotourism.", hindi: "मैंने पर्यावरण पर्यटन तैयार कर लिया है।"),
            WordExample(thai: "คำว่าท่องเที่ยวเชิงนิเวศใช้บ่อย", romanization: "kham-wâa thâwng-thîao chəəng ní-wét chái bàwy", english: "The word for ecotourism is commonly used.", hindi: "पर्यावरण पर्यटन के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1303: [
            WordExample(thai: "ฉันเตรียมไกด์ท้องถิ่นไว้แล้ว", romanization: "chǎn dtriam gài tháwng-thìn wái-láew", english: "I have prepared the local guide.", hindi: "मैंने स्थानीय गाइड तैयार कर लिया है।"),
            WordExample(thai: "คำว่าไกด์ท้องถิ่นใช้บ่อย", romanization: "kham-wâa gài tháwng-thìn chái bàwy", english: "The word for local guide is commonly used.", hindi: "स्थानीय गाइड के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1304: [
            WordExample(thai: "ฉันเตรียมกลุ่มทัวร์ไว้แล้ว", romanization: "chǎn dtriam glùm thua wái-láew", english: "I have prepared the tour group.", hindi: "मैंने पर्यटन दल तैयार कर लिया है।"),
            WordExample(thai: "คำว่ากลุ่มทัวร์ใช้บ่อย", romanization: "kham-wâa glùm thua chái bàwy", english: "The word for tour group is commonly used.", hindi: "पर्यटन दल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1305: [
            WordExample(thai: "ฉันเตรียมค่าธรรมเนียมเข้าไว้แล้ว", romanization: "chǎn dtriam khâa tham-niiam khâo wái-láew", english: "I have prepared the admission fee.", hindi: "मैंने प्रवेश शुल्क तैयार कर लिया है।"),
            WordExample(thai: "คำว่าค่าธรรมเนียมเข้าใช้บ่อย", romanization: "kham-wâa khâa tham-niiam khâo chái bàwy", english: "The word for admission fee is commonly used.", hindi: "प्रवेश शुल्क के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1306: [
            WordExample(thai: "ฉันเตรียมบัตรโดยสารไว้แล้ว", romanization: "chǎn dtriam bàt dooi-sǎan wái-láew", english: "I have prepared the travel pass.", hindi: "मैंने यात्रा पास तैयार कर लिया है।"),
            WordExample(thai: "คำว่าบัตรโดยสารใช้บ่อย", romanization: "kham-wâa bàt dooi-sǎan chái bàwy", english: "The word for travel pass is commonly used.", hindi: "यात्रा पास के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1307: [
            WordExample(thai: "ฉันเตรียมตั๋วไปกลับไว้แล้ว", romanization: "chǎn dtriam dtǔa bpai-glàp wái-láew", english: "I have prepared the round-trip ticket.", hindi: "मैंने आने-जाने का टिकट तैयार कर लिया है।"),
            WordExample(thai: "คำว่าตั๋วไปกลับใช้บ่อย", romanization: "kham-wâa dtǔa bpai-glàp chái bàwy", english: "The word for round-trip ticket is commonly used.", hindi: "आने-जाने का टिकट के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1308: [
            WordExample(thai: "ฉันเตรียมเที่ยวเดียวไว้แล้ว", romanization: "chǎn dtriam thîao-diao wái-láew", english: "I have prepared the one-way trip.", hindi: "मैंने एकतरफ़ा यात्रा तैयार कर लिया है।"),
            WordExample(thai: "คำว่าเที่ยวเดียวใช้บ่อย", romanization: "kham-wâa thîao-diao chái bàwy", english: "The word for one-way trip is commonly used.", hindi: "एकतरफ़ा यात्रा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1309: [
            WordExample(thai: "ฉันเตรียมกำหนดการไว้แล้ว", romanization: "chǎn dtriam gam-nòt-gaan wái-láew", english: "I have prepared the schedule.", hindi: "मैंने निर्धारित कार्यक्रम तैयार कर लिया है।"),
            WordExample(thai: "คำว่ากำหนดการใช้บ่อย", romanization: "kham-wâa gam-nòt-gaan chái bàwy", english: "The word for schedule is commonly used.", hindi: "निर्धारित कार्यक्रम के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1310: [
            WordExample(thai: "ฉันเตรียมจุดแวะพักไว้แล้ว", romanization: "chǎn dtriam jùt wáe-phák wái-láew", english: "I have prepared the rest stop.", hindi: "मैंने विश्राम स्थल तैयार कर लिया है।"),
            WordExample(thai: "คำว่าจุดแวะพักใช้บ่อย", romanization: "kham-wâa jùt wáe-phák chái bàwy", english: "The word for rest stop is commonly used.", hindi: "विश्राम स्थल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1311: [
            WordExample(thai: "ฉันเตรียมจุดชมวิวไว้แล้ว", romanization: "chǎn dtriam jùt chom-wiw wái-láew", english: "I have prepared the viewpoint.", hindi: "मैंने दृश्य स्थल तैयार कर लिया है।"),
            WordExample(thai: "คำว่าจุดชมวิวใช้บ่อย", romanization: "kham-wâa jùt chom-wiw chái bàwy", english: "The word for viewpoint is commonly used.", hindi: "दृश्य स्थल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1312: [
            WordExample(thai: "ฉันเตรียมเวลานัดหมายไว้แล้ว", romanization: "chǎn dtriam wee-laa nát-mǎai wái-láew", english: "I have prepared the appointment time.", hindi: "मैंने मिलने का समय तैयार कर लिया है।"),
            WordExample(thai: "คำว่าเวลานัดหมายใช้บ่อย", romanization: "kham-wâa wee-laa nát-mǎai chái bàwy", english: "The word for appointment time is commonly used.", hindi: "मिलने का समय के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1313: [
            WordExample(thai: "ฉันเตรียมการผจญภัยไว้แล้ว", romanization: "chǎn dtriam gaan phà-john-phai wái-láew", english: "I have prepared the adventure.", hindi: "मैंने साहसिक यात्रा तैयार कर लिया है।"),
            WordExample(thai: "คำว่าการผจญภัยใช้บ่อย", romanization: "kham-wâa gaan phà-john-phai chái bàwy", english: "The word for adventure is commonly used.", hindi: "साहसिक यात्रा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1314: [
            WordExample(thai: "ฉันเตรียมทริปวันเดียวไว้แล้ว", romanization: "chǎn dtriam tríp wan-diao wái-láew", english: "I have prepared the day trip.", hindi: "मैंने एक दिन की यात्रा तैयार कर लिया है।"),
            WordExample(thai: "คำว่าทริปวันเดียวใช้บ่อย", romanization: "kham-wâa tríp wan-diao chái bàwy", english: "The word for day trip is commonly used.", hindi: "एक दिन की यात्रा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1315: [
            WordExample(thai: "ฉันเตรียมทริปสุดสัปดาห์ไว้แล้ว", romanization: "chǎn dtriam tríp sùt-sàp-daa wái-láew", english: "I have prepared the weekend trip.", hindi: "मैंने सप्ताहांत यात्रा तैयार कर लिया है।"),
            WordExample(thai: "คำว่าทริปสุดสัปดาห์ใช้บ่อย", romanization: "kham-wâa tríp sùt-sàp-daa chái bàwy", english: "The word for weekend trip is commonly used.", hindi: "सप्ताहांत यात्रा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1316: [
            WordExample(thai: "ฉันเตรียมแหล่งท่องเที่ยวไว้แล้ว", romanization: "chǎn dtriam làeng thâwng-thîao wái-láew", english: "I have prepared the tourist attraction.", hindi: "मैंने पर्यटन स्थल तैयार कर लिया है।"),
            WordExample(thai: "คำว่าแหล่งท่องเที่ยวใช้บ่อย", romanization: "kham-wâa làeng thâwng-thîao chái bàwy", english: "The word for tourist attraction is commonly used.", hindi: "पर्यटन स्थल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1317: [
            WordExample(thai: "ฉันเตรียมข้อมูลท่องเที่ยวไว้แล้ว", romanization: "chǎn dtriam khâw-muun thâwng-thîao wái-láew", english: "I have prepared the tourist information.", hindi: "मैंने पर्यटन जानकारी तैयार कर लिया है।"),
            WordExample(thai: "คำว่าข้อมูลท่องเที่ยวใช้บ่อย", romanization: "kham-wâa khâw-muun thâwng-thîao chái bàwy", english: "The word for tourist information is commonly used.", hindi: "पर्यटन जानकारी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1318: [
            WordExample(thai: "ฉันเตรียมผู้ร่วมทริปไว้แล้ว", romanization: "chǎn dtriam phûu rûam tríp wái-láew", english: "I have prepared the fellow traveler.", hindi: "मैंने सहयात्री तैयार कर लिया है।"),
            WordExample(thai: "คำว่าผู้ร่วมทริปใช้บ่อย", romanization: "kham-wâa phûu rûam tríp chái bàwy", english: "The word for fellow traveler is commonly used.", hindi: "सहयात्री के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1319: [
            WordExample(thai: "ฉันเตรียมจองล่วงหน้าไว้แล้ว", romanization: "chǎn dtriam jawng lûang-nâa wái-láew", english: "I have prepared the book in advance.", hindi: "मैंने पहले से बुक करना तैयार कर लिया है।"),
            WordExample(thai: "คำว่าจองล่วงหน้าใช้บ่อย", romanization: "kham-wâa jawng lûang-nâa chái bàwy", english: "The word for book in advance is commonly used.", hindi: "पहले से बुक करना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1320: [
            WordExample(thai: "ฉันเตรียมประกันการเดินทางไว้แล้ว", romanization: "chǎn dtriam bpra-gan gaan dəən-thaang wái-láew", english: "I have prepared the travel insurance.", hindi: "मैंने यात्रा बीमा तैयार कर लिया है।"),
            WordExample(thai: "คำว่าประกันการเดินทางใช้บ่อย", romanization: "kham-wâa bpra-gan gaan dəən-thaang chái bàwy", english: "The word for travel insurance is commonly used.", hindi: "यात्रा बीमा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1321: [
            WordExample(thai: "เราอยู่ที่ย่าน", romanization: "rao yùu thîi yâan", english: "We are at the neighborhood.", hindi: "हम इलाका में हैं।"),
            WordExample(thai: "คำว่าย่านใช้บ่อย", romanization: "kham-wâa yâan chái bàwy", english: "The word for neighborhood is commonly used.", hindi: "इलाका के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1322: [
            WordExample(thai: "เราอยู่ที่ชุมชน", romanization: "rao yùu thîi chum-chon", english: "We are at the community.", hindi: "हम समुदाय में हैं।"),
            WordExample(thai: "คำว่าชุมชนใช้บ่อย", romanization: "kham-wâa chum-chon chái bàwy", english: "The word for community is commonly used.", hindi: "समुदाय के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1323: [
            WordExample(thai: "เราอยู่ที่ตัวเมือง", romanization: "rao yùu thîi dtua-mueang", english: "We are at the city center.", hindi: "हम शहर का केंद्र में हैं।"),
            WordExample(thai: "คำว่าตัวเมืองใช้บ่อย", romanization: "kham-wâa dtua-mueang chái bàwy", english: "The word for city center is commonly used.", hindi: "शहर का केंद्र के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1324: [
            WordExample(thai: "เราอยู่ที่ชานเมือง", romanization: "rao yùu thîi chaan-mueang", english: "We are at the suburb.", hindi: "हम उपनगर में हैं।"),
            WordExample(thai: "คำว่าชานเมืองใช้บ่อย", romanization: "kham-wâa chaan-mueang chái bàwy", english: "The word for suburb is commonly used.", hindi: "उपनगर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1325: [
            WordExample(thai: "เราอยู่ที่ใจกลางเมือง", romanization: "rao yùu thîi jai-glaang-mueang", english: "We are at the downtown.", hindi: "हम नगर का बीच में हैं।"),
            WordExample(thai: "คำว่าใจกลางเมืองใช้บ่อย", romanization: "kham-wâa jai-glaang-mueang chái bàwy", english: "The word for downtown is commonly used.", hindi: "नगर का बीच के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1326: [
            WordExample(thai: "เราอยู่ที่เขต", romanization: "rao yùu thîi khèet", english: "We are at the district.", hindi: "हम ज़िला में हैं।"),
            WordExample(thai: "คำว่าเขตใช้บ่อย", romanization: "kham-wâa khèet chái bàwy", english: "The word for district is commonly used.", hindi: "ज़िला के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1327: [
            WordExample(thai: "เราอยู่ที่จังหวัด", romanization: "rao yùu thîi jang-wàt", english: "We are at the province.", hindi: "हम प्रांत में हैं।"),
            WordExample(thai: "คำว่าจังหวัดใช้บ่อย", romanization: "kham-wâa jang-wàt chái bàwy", english: "The word for province is commonly used.", hindi: "प्रांत के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1328: [
            WordExample(thai: "เราอยู่ที่อำเภอ", romanization: "rao yùu thîi am-phəə", english: "We are at the county district.", hindi: "हम तहसील में हैं।"),
            WordExample(thai: "คำว่าอำเภอใช้บ่อย", romanization: "kham-wâa am-phəə chái bàwy", english: "The word for county district is commonly used.", hindi: "तहसील के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1329: [
            WordExample(thai: "เราอยู่ที่หมู่บ้าน", romanization: "rao yùu thîi mùu-bâan", english: "We are at the village.", hindi: "हम गाँव में हैं।"),
            WordExample(thai: "คำว่าหมู่บ้านใช้บ่อย", romanization: "kham-wâa mùu-bâan chái bàwy", english: "The word for village is commonly used.", hindi: "गाँव के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1330: [
            WordExample(thai: "เราอยู่ที่ชนบท", romanization: "rao yùu thîi chon-ná-bòt", english: "We are at the countryside.", hindi: "हम ग्रामीण क्षेत्र में हैं।"),
            WordExample(thai: "คำว่าชนบทใช้บ่อย", romanization: "kham-wâa chon-ná-bòt chái bàwy", english: "The word for countryside is commonly used.", hindi: "ग्रामीण क्षेत्र के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1331: [
            WordExample(thai: "เราอยู่ที่จัตุรัส", romanization: "rao yùu thîi jàt-dtù-ràt", english: "We are at the square.", hindi: "हम चौराहा में हैं।"),
            WordExample(thai: "คำว่าจัตุรัสใช้บ่อย", romanization: "kham-wâa jàt-dtù-ràt chái bàwy", english: "The word for square is commonly used.", hindi: "चौराहा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1332: [
            WordExample(thai: "เราอยู่ที่ลาน", romanization: "rao yùu thîi laan", english: "We are at the plaza.", hindi: "हम खुला मैदान में हैं।"),
            WordExample(thai: "คำว่าลานใช้บ่อย", romanization: "kham-wâa laan chái bàwy", english: "The word for plaza is commonly used.", hindi: "खुला मैदान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1333: [
            WordExample(thai: "เราอยู่ที่ลานจอดรถ", romanization: "rao yùu thîi laan-jawt rót", english: "We are at the parking lot.", hindi: "हम पार्किंग स्थल में हैं।"),
            WordExample(thai: "คำว่าลานจอดรถใช้บ่อย", romanization: "kham-wâa laan-jawt rót chái bàwy", english: "The word for parking lot is commonly used.", hindi: "पार्किंग स्थल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1334: [
            WordExample(thai: "เราอยู่ที่ทางเข้าหลัก", romanization: "rao yùu thîi thaang khâo-làk", english: "We are at the main entrance.", hindi: "हम मुख्य प्रवेश द्वार में हैं।"),
            WordExample(thai: "คำว่าทางเข้าหลักใช้บ่อย", romanization: "kham-wâa thaang khâo-làk chái bàwy", english: "The word for main entrance is commonly used.", hindi: "मुख्य प्रवेश द्वार के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1335: [
            WordExample(thai: "เราอยู่ที่ทางออกฉุกเฉิน", romanization: "rao yùu thîi thaang àwk chùk-chə̌ən", english: "We are at the emergency exit.", hindi: "हम आपातकालीन निकास में हैं।"),
            WordExample(thai: "คำว่าทางออกฉุกเฉินใช้บ่อย", romanization: "kham-wâa thaang àwk chùk-chə̌ən chái bàwy", english: "The word for emergency exit is commonly used.", hindi: "आपातकालीन निकास के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1336: [
            WordExample(thai: "เราอยู่ที่ประตูทางเข้า", romanization: "rao yùu thîi bpra-dtuu thaang-khâo", english: "We are at the entrance gate.", hindi: "हम प्रवेश द्वार में हैं।"),
            WordExample(thai: "คำว่าประตูทางเข้าใช้บ่อย", romanization: "kham-wâa bpra-dtuu thaang-khâo chái bàwy", english: "The word for entrance gate is commonly used.", hindi: "प्रवेश द्वार के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1337: [
            WordExample(thai: "เราอยู่ที่จุดบริการ", romanization: "rao yùu thîi jùt baw-ri-gaan", english: "We are at the service point.", hindi: "हम सेवा केंद्र में हैं।"),
            WordExample(thai: "คำว่าจุดบริการใช้บ่อย", romanization: "kham-wâa jùt baw-ri-gaan chái bàwy", english: "The word for service point is commonly used.", hindi: "सेवा केंद्र के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1338: [
            WordExample(thai: "เราอยู่ที่ศูนย์ข้อมูล", romanization: "rao yùu thîi sǔun khâw-muun", english: "We are at the information center.", hindi: "हम सूचना केंद्र में हैं।"),
            WordExample(thai: "คำว่าศูนย์ข้อมูลใช้บ่อย", romanization: "kham-wâa sǔun khâw-muun chái bàwy", english: "The word for information center is commonly used.", hindi: "सूचना केंद्र के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1339: [
            WordExample(thai: "เราอยู่ที่ศูนย์นักท่องเที่ยว", romanization: "rao yùu thîi sǔun nák-thâwng-thîao", english: "We are at the visitor center.", hindi: "हम पर्यटक केंद्र में हैं।"),
            WordExample(thai: "คำว่าศูนย์นักท่องเที่ยวใช้บ่อย", romanization: "kham-wâa sǔun nák-thâwng-thîao chái bàwy", english: "The word for visitor center is commonly used.", hindi: "पर्यटक केंद्र के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1340: [
            WordExample(thai: "เราอยู่ที่ป้อมตำรวจ", romanization: "rao yùu thîi bpàwm dtam-rùat", english: "We are at the police booth.", hindi: "हम पुलिस चौकी में हैं।"),
            WordExample(thai: "คำว่าป้อมตำรวจใช้บ่อย", romanization: "kham-wâa bpàwm dtam-rùat chái bàwy", english: "The word for police booth is commonly used.", hindi: "पुलिस चौकी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1341: [
            WordExample(thai: "เราอยู่ที่ร้านขายของที่ระลึก", romanization: "rao yùu thîi ráan khǎai khǎawng-thîi rá-léuk", english: "We are at the souvenir shop.", hindi: "हम स्मृति-चिह्न की दुकान में हैं।"),
            WordExample(thai: "คำว่าร้านขายของที่ระลึกใช้บ่อย", romanization: "kham-wâa ráan khǎai khǎawng-thîi rá-léuk chái bàwy", english: "The word for souvenir shop is commonly used.", hindi: "स्मृति-चिह्न की दुकान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1342: [
            WordExample(thai: "เราอยู่ที่ร้านแลกเงิน", romanization: "rao yùu thîi ráan lâek ngoen", english: "We are at the currency exchange shop.", hindi: "हम मुद्रा विनिमय दुकान में हैं।"),
            WordExample(thai: "คำว่าร้านแลกเงินใช้บ่อย", romanization: "kham-wâa ráan lâek ngoen chái bàwy", english: "The word for currency exchange shop is commonly used.", hindi: "मुद्रा विनिमय दुकान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1343: [
            WordExample(thai: "เราอยู่ที่สำนักงาน", romanization: "rao yùu thîi sǎm-nák-ngaan", english: "We are at the office.", hindi: "हम कार्यालय में हैं।"),
            WordExample(thai: "คำว่าสำนักงานใช้บ่อย", romanization: "kham-wâa sǎm-nák-ngaan chái bàwy", english: "The word for office is commonly used.", hindi: "कार्यालय के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1344: [
            WordExample(thai: "เราอยู่ที่อาคาร", romanization: "rao yùu thîi aa-khaan", english: "We are at the building.", hindi: "हम इमारत में हैं।"),
            WordExample(thai: "คำว่าอาคารใช้บ่อย", romanization: "kham-wâa aa-khaan chái bàwy", english: "The word for building is commonly used.", hindi: "इमारत के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1345: [
            WordExample(thai: "เราอยู่ที่ชุมทาง", romanization: "rao yùu thîi chum-thaang", english: "We are at the junction.", hindi: "हम संगम स्थल में हैं।"),
            WordExample(thai: "คำว่าชุมทางใช้บ่อย", romanization: "kham-wâa chum-thaang chái bàwy", english: "The word for junction is commonly used.", hindi: "संगम स्थल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1346: [
            WordExample(thai: "ไปตามเลี้ยวกลับ", romanization: "bpai dtaam líao-glàp", english: "Go via the make a U-turn.", hindi: "यू-टर्न लेना के अनुसार जाइए।"),
            WordExample(thai: "คำว่าเลี้ยวกลับใช้บ่อย", romanization: "kham-wâa líao-glàp chái bàwy", english: "The word for make a U-turn is commonly used.", hindi: "यू-टर्न लेना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1347: [
            WordExample(thai: "ไปตามเดินตรง", romanization: "bpai dtaam dəən dtrong", english: "Go via the walk straight.", hindi: "सीधे चलना के अनुसार जाइए।"),
            WordExample(thai: "คำว่าเดินตรงใช้บ่อย", romanization: "kham-wâa dəən dtrong chái bàwy", english: "The word for walk straight is commonly used.", hindi: "सीधे चलना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1348: [
            WordExample(thai: "ไปตามเดินผ่าน", romanization: "bpai dtaam dəən phàan", english: "Go via the walk past.", hindi: "के पास से चलना के अनुसार जाइए।"),
            WordExample(thai: "คำว่าเดินผ่านใช้บ่อย", romanization: "kham-wâa dəən phàan chái bàwy", english: "The word for walk past is commonly used.", hindi: "के पास से चलना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1349: [
            WordExample(thai: "ไปตามข้ามถนน", romanization: "bpai dtaam khâam thà-nǒn", english: "Go via the cross the road.", hindi: "सड़क पार करना के अनुसार जाइए।"),
            WordExample(thai: "คำว่าข้ามถนนใช้บ่อย", romanization: "kham-wâa khâam thà-nǒn chái bàwy", english: "The word for cross the road is commonly used.", hindi: "सड़क पार करना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1350: [
            WordExample(thai: "ไปตามขึ้นบันได", romanization: "bpai dtaam khûen ban-dai", english: "Go via the go up the stairs.", hindi: "सीढ़ियाँ चढ़ना के अनुसार जाइए।"),
            WordExample(thai: "คำว่าขึ้นบันไดใช้บ่อย", romanization: "kham-wâa khûen ban-dai chái bàwy", english: "The word for go up the stairs is commonly used.", hindi: "सीढ़ियाँ चढ़ना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1351: [
            WordExample(thai: "ไปตามลงบันได", romanization: "bpai dtaam long ban-dai", english: "Go via the go down the stairs.", hindi: "सीढ़ियाँ उतरना के अनुसार जाइए।"),
            WordExample(thai: "คำว่าลงบันไดใช้บ่อย", romanization: "kham-wâa long ban-dai chái bàwy", english: "The word for go down the stairs is commonly used.", hindi: "सीढ़ियाँ उतरना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1352: [
            WordExample(thai: "ไปตามตามทาง", romanization: "bpai dtaam dtaam thaang", english: "Go via the follow the path.", hindi: "रास्ते के अनुसार के अनुसार जाइए।"),
            WordExample(thai: "คำว่าตามทางใช้บ่อย", romanization: "kham-wâa dtaam thaang chái bàwy", english: "The word for follow the path is commonly used.", hindi: "रास्ते के अनुसार के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1353: [
            WordExample(thai: "ไปตามทางลัด", romanization: "bpai dtaam thaang-lát", english: "Go via the shortcut.", hindi: "छोटा रास्ता के अनुसार जाइए।"),
            WordExample(thai: "คำว่าทางลัดใช้บ่อย", romanization: "kham-wâa thaang-lát chái bàwy", english: "The word for shortcut is commonly used.", hindi: "छोटा रास्ता के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1354: [
            WordExample(thai: "ไปตามปลายถนน", romanization: "bpai dtaam bplaai thà-nǒn", english: "Go via the end of the road.", hindi: "सड़क का अंत के अनुसार जाइए।"),
            WordExample(thai: "คำว่าปลายถนนใช้บ่อย", romanization: "kham-wâa bplaai thà-nǒn chái bàwy", english: "The word for end of the road is commonly used.", hindi: "सड़क का अंत के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1355: [
            WordExample(thai: "ไปตามหัวมุม", romanization: "bpai dtaam hǔa-mum", english: "Go via the corner.", hindi: "कोना के अनुसार जाइए।"),
            WordExample(thai: "คำว่าหัวมุมใช้บ่อย", romanization: "kham-wâa hǔa-mum chái bàwy", english: "The word for corner is commonly used.", hindi: "कोना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1356: [
            WordExample(thai: "ไปตามมุมถนน", romanization: "bpai dtaam mum thà-nǒn", english: "Go via the street corner.", hindi: "सड़क का मोड़ के अनुसार जाइए।"),
            WordExample(thai: "คำว่ามุมถนนใช้บ่อย", romanization: "kham-wâa mum thà-nǒn chái bàwy", english: "The word for street corner is commonly used.", hindi: "सड़क का मोड़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1357: [
            WordExample(thai: "ไปตามแยกซ้าย", romanization: "bpai dtaam yâek sáai", english: "Go via the left fork.", hindi: "बायाँ मोड़ के अनुसार जाइए।"),
            WordExample(thai: "คำว่าแยกซ้ายใช้บ่อย", romanization: "kham-wâa yâek sáai chái bàwy", english: "The word for left fork is commonly used.", hindi: "बायाँ मोड़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1358: [
            WordExample(thai: "ไปตามแยกขวา", romanization: "bpai dtaam yâek kwǎa", english: "Go via the right fork.", hindi: "दायाँ मोड़ के अनुसार जाइए।"),
            WordExample(thai: "คำว่าแยกขวาใช้บ่อย", romanization: "kham-wâa yâek kwǎa chái bàwy", english: "The word for right fork is commonly used.", hindi: "दायाँ मोड़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1359: [
            WordExample(thai: "ไปตามทางออก", romanization: "bpai dtaam thaang-àwk", english: "Go via the exit way.", hindi: "बाहर जाने का रास्ता के अनुसार जाइए।"),
            WordExample(thai: "คำว่าทางออกใช้บ่อย", romanization: "kham-wâa thaang-àwk chái bàwy", english: "The word for exit way is commonly used.", hindi: "बाहर जाने का रास्ता के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1360: [
            WordExample(thai: "ไปตามทางเข้า", romanization: "bpai dtaam thaang-khâo", english: "Go via the entrance way.", hindi: "अंदर जाने का रास्ता के अनुसार जाइए।"),
            WordExample(thai: "คำว่าทางเข้าใช้บ่อย", romanization: "kham-wâa thaang-khâo chái bàwy", english: "The word for entrance way is commonly used.", hindi: "अंदर जाने का रास्ता के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1361: [
            WordExample(thai: "ไปตามใกล้เคียง", romanization: "bpai dtaam glâi-khiang", english: "Go via the nearby.", hindi: "निकटवर्ती के अनुसार जाइए।"),
            WordExample(thai: "คำว่าใกล้เคียงใช้บ่อย", romanization: "kham-wâa glâi-khiang chái bàwy", english: "The word for nearby is commonly used.", hindi: "निकटवर्ती के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1362: [
            WordExample(thai: "ไปตามห่างออกไป", romanization: "bpai dtaam hàang àwk-bpai", english: "Go via the far away.", hindi: "दूर स्थित के अनुसार जाइए।"),
            WordExample(thai: "คำว่าห่างออกไปใช้บ่อย", romanization: "kham-wâa hàang àwk-bpai chái bàwy", english: "The word for far away is commonly used.", hindi: "दूर स्थित के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1363: [
            WordExample(thai: "ไปตามระหว่างทาง", romanization: "bpai dtaam rá-wàang thaang", english: "Go via the on the way.", hindi: "रास्ते में के अनुसार जाइए।"),
            WordExample(thai: "คำว่าระหว่างทางใช้บ่อย", romanization: "kham-wâa rá-wàang thaang chái bàwy", english: "The word for on the way is commonly used.", hindi: "रास्ते में के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1364: [
            WordExample(thai: "ไปตามด้านหน้า", romanization: "bpai dtaam dâan nâa", english: "Go via the in front.", hindi: "सामने के अनुसार जाइए।"),
            WordExample(thai: "คำว่าด้านหน้าใช้บ่อย", romanization: "kham-wâa dâan nâa chái bàwy", english: "The word for in front is commonly used.", hindi: "सामने के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1365: [
            WordExample(thai: "ไปตามด้านหลัง", romanization: "bpai dtaam dâan lǎng", english: "Go via the at the back.", hindi: "पीछे के अनुसार जाइए।"),
            WordExample(thai: "คำว่าด้านหลังใช้บ่อย", romanization: "kham-wâa dâan lǎng chái bàwy", english: "The word for at the back is commonly used.", hindi: "पीछे के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1366: [
            WordExample(thai: "ไปตามด้านซ้าย", romanization: "bpai dtaam dâan sáai", english: "Go via the on the left.", hindi: "बाईं ओर के अनुसार जाइए।"),
            WordExample(thai: "คำว่าด้านซ้ายใช้บ่อย", romanization: "kham-wâa dâan sáai chái bàwy", english: "The word for on the left is commonly used.", hindi: "बाईं ओर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1367: [
            WordExample(thai: "ไปตามด้านขวา", romanization: "bpai dtaam dâan kwǎa", english: "Go via the on the right.", hindi: "दाईं ओर के अनुसार जाइए।"),
            WordExample(thai: "คำว่าด้านขวาใช้บ่อย", romanization: "kham-wâa dâan kwǎa chái bàwy", english: "The word for on the right is commonly used.", hindi: "दाईं ओर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1368: [
            WordExample(thai: "ไปตามข้างหน้า", romanization: "bpai dtaam khâang-nâa", english: "Go via the ahead.", hindi: "आगे के अनुसार जाइए।"),
            WordExample(thai: "คำว่าข้างหน้าใช้บ่อย", romanization: "kham-wâa khâang-nâa chái bàwy", english: "The word for ahead is commonly used.", hindi: "आगे के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1369: [
            WordExample(thai: "ไปตามข้างๆ", romanization: "bpai dtaam khâang-khâang", english: "Go via the beside.", hindi: "बगल में के अनुसार जाइए।"),
            WordExample(thai: "คำว่าข้างๆใช้บ่อย", romanization: "kham-wâa khâang-khâang chái bàwy", english: "The word for beside is commonly used.", hindi: "बगल में के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1370: [
            WordExample(thai: "ไปตามทางเหนือไป", romanization: "bpai dtaam thaang nǔea-bpai", english: "Go via the go north.", hindi: "उत्तर की ओर जाना के अनुसार जाइए।"),
            WordExample(thai: "คำว่าทางเหนือไปใช้บ่อย", romanization: "kham-wâa thaang nǔea-bpai chái bàwy", english: "The word for go north is commonly used.", hindi: "उत्तर की ओर जाना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1371: [
            WordExample(thai: "ฉันรอรถไฟด่วน", romanization: "chǎn raw rót-fai dùan", english: "I am waiting for the express train.", hindi: "मैं तेज़ रेलगाड़ी का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่ารถไฟด่วนใช้บ่อย", romanization: "kham-wâa rót-fai dùan chái bàwy", english: "The word for express train is commonly used.", hindi: "तेज़ रेलगाड़ी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1372: [
            WordExample(thai: "ฉันรอรถไฟท้องถิ่น", romanization: "chǎn raw rót-fai tháwng-thìn", english: "I am waiting for the local train.", hindi: "मैं स्थानीय रेलगाड़ी का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่ารถไฟท้องถิ่นใช้บ่อย", romanization: "kham-wâa rót-fai tháwng-thìn chái bàwy", english: "The word for local train is commonly used.", hindi: "स्थानीय रेलगाड़ी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1373: [
            WordExample(thai: "ฉันรอรถไฟนอน", romanization: "chǎn raw rót-fai nawn", english: "I am waiting for the sleeper train.", hindi: "मैं शयन रेलगाड़ी का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่ารถไฟนอนใช้บ่อย", romanization: "kham-wâa rót-fai nawn chái bàwy", english: "The word for sleeper train is commonly used.", hindi: "शयन रेलगाड़ी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1374: [
            WordExample(thai: "ฉันรอรถไฟชานเมือง", romanization: "chǎn raw rót-fai chaan-mueang", english: "I am waiting for the commuter train.", hindi: "मैं उपनगरीय रेलगाड़ी का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่ารถไฟชานเมืองใช้บ่อย", romanization: "kham-wâa rót-fai chaan-mueang chái bàwy", english: "The word for commuter train is commonly used.", hindi: "उपनगरीय रेलगाड़ी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1375: [
            WordExample(thai: "ฉันรอขบวนรถ", romanization: "chǎn raw khà-buan rót", english: "I am waiting for the train service.", hindi: "मैं रेल का डिब्बा समूह का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าขบวนรถใช้บ่อย", romanization: "kham-wâa khà-buan rót chái bàwy", english: "The word for train service is commonly used.", hindi: "रेल का डिब्बा समूह के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1376: [
            WordExample(thai: "ฉันรอโบกี้รถไฟ", romanization: "chǎn raw boo-gîi rót-fai", english: "I am waiting for the railway carriage.", hindi: "मैं रेल डिब्बा का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าโบกี้รถไฟใช้บ่อย", romanization: "kham-wâa boo-gîi rót-fai chái bàwy", english: "The word for railway carriage is commonly used.", hindi: "रेल डिब्बा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1377: [
            WordExample(thai: "ฉันรอชานชาลา", romanization: "chǎn raw chaan-chá-laa", english: "I am waiting for the platform.", hindi: "मैं रेल मंच का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าชานชาลาใช้บ่อย", romanization: "kham-wâa chaan-chá-laa chái bàwy", english: "The word for platform is commonly used.", hindi: "रेल मंच के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1378: [
            WordExample(thai: "ฉันรอตั๋วโดยสาร", romanization: "chǎn raw dtǔa dooi-sǎan", english: "I am waiting for the fare ticket.", hindi: "मैं यात्रा टिकट का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าตั๋วโดยสารใช้บ่อย", romanization: "kham-wâa dtǔa dooi-sǎan chái bàwy", english: "The word for fare ticket is commonly used.", hindi: "यात्रा टिकट के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1379: [
            WordExample(thai: "ฉันรอประตูรถ", romanization: "chǎn raw bpra-dtuu rót", english: "I am waiting for the vehicle door.", hindi: "मैं वाहन का दरवाज़ा का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าประตูรถใช้บ่อย", romanization: "kham-wâa bpra-dtuu rót chái bàwy", english: "The word for vehicle door is commonly used.", hindi: "वाहन का दरवाज़ा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1380: [
            WordExample(thai: "ฉันรอที่เก็บสัมภาระ", romanization: "chǎn raw thîi-gèp sǎm-phaa-rá", english: "I am waiting for the luggage storage.", hindi: "मैं सामान रखने की जगह का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าที่เก็บสัมภาระใช้บ่อย", romanization: "kham-wâa thîi-gèp sǎm-phaa-rá chái bàwy", english: "The word for luggage storage is commonly used.", hindi: "सामान रखने की जगह के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1381: [
            WordExample(thai: "ฉันรอรางรถไฟ", romanization: "chǎn raw raang rót-fai", english: "I am waiting for the railway track.", hindi: "मैं रेल पटरी का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่ารางรถไฟใช้บ่อย", romanization: "kham-wâa raang rót-fai chái bàwy", english: "The word for railway track is commonly used.", hindi: "रेल पटरी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1382: [
            WordExample(thai: "ฉันรอป้ายปลายทาง", romanization: "chǎn raw bpàai bplaai-thaang", english: "I am waiting for the destination sign.", hindi: "मैं गंतव्य संकेत का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าป้ายปลายทางใช้บ่อย", romanization: "kham-wâa bpàai bplaai-thaang chái bàwy", english: "The word for destination sign is commonly used.", hindi: "गंतव्य संकेत के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1383: [
            WordExample(thai: "ฉันรอจุดจอด", romanization: "chǎn raw jùt-jawt", english: "I am waiting for the stop point.", hindi: "मैं रुकने का स्थान का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าจุดจอดใช้บ่อย", romanization: "kham-wâa jùt-jawt chái bàwy", english: "The word for stop point is commonly used.", hindi: "रुकने का स्थान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1384: [
            WordExample(thai: "ฉันรอรถรับส่ง", romanization: "chǎn raw rót ráp-sòng", english: "I am waiting for the shuttle vehicle.", hindi: "मैं शटल वाहन का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่ารถรับส่งใช้บ่อย", romanization: "kham-wâa rót ráp-sòng chái bàwy", english: "The word for shuttle vehicle is commonly used.", hindi: "शटल वाहन के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1385: [
            WordExample(thai: "ฉันรอรถสองแถว", romanization: "chǎn raw rót sǎawng-thǎew", english: "I am waiting for the shared pickup taxi.", hindi: "मैं साझा पिकअप टैक्सी का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่ารถสองแถวใช้บ่อย", romanization: "kham-wâa rót sǎawng-thǎew chái bàwy", english: "The word for shared pickup taxi is commonly used.", hindi: "साझा पिकअप टैक्सी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1386: [
            WordExample(thai: "ฉันรอเรือด่วน", romanization: "chǎn raw ruea dùan", english: "I am waiting for the express boat.", hindi: "मैं तेज़ नाव का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าเรือด่วนใช้บ่อย", romanization: "kham-wâa ruea dùan chái bàwy", english: "The word for express boat is commonly used.", hindi: "तेज़ नाव के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1387: [
            WordExample(thai: "ฉันรอเรือหางยาว", romanization: "chǎn raw ruea hǎang-yaao", english: "I am waiting for the long-tail boat.", hindi: "मैं लंबी पूँछ वाली नाव का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าเรือหางยาวใช้บ่อย", romanization: "kham-wâa ruea hǎang-yaao chái bàwy", english: "The word for long-tail boat is commonly used.", hindi: "लंबी पूँछ वाली नाव के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1388: [
            WordExample(thai: "ฉันรอเรือโดยสาร", romanization: "chǎn raw ruea dooi-sǎan", english: "I am waiting for the passenger boat.", hindi: "मैं यात्री नाव का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าเรือโดยสารใช้บ่อย", romanization: "kham-wâa ruea dooi-sǎan chái bàwy", english: "The word for passenger boat is commonly used.", hindi: "यात्री नाव के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1389: [
            WordExample(thai: "ฉันรอท่าเทียบเรือ", romanization: "chǎn raw thâa-thîap ruea", english: "I am waiting for the pier.", hindi: "मैं नाव घाट का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าท่าเทียบเรือใช้บ่อย", romanization: "kham-wâa thâa-thîap ruea chái bàwy", english: "The word for pier is commonly used.", hindi: "नाव घाट के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1390: [
            WordExample(thai: "ฉันรอค่าโดยสาร", romanization: "chǎn raw khâa dooi-sǎan", english: "I am waiting for the fare.", hindi: "मैं किराया का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าค่าโดยสารใช้บ่อย", romanization: "kham-wâa khâa dooi-sǎan chái bàwy", english: "The word for fare is commonly used.", hindi: "किराया के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1391: [
            WordExample(thai: "ฉันรอค่าแท็กซี่", romanization: "chǎn raw khâa thék-sîi", english: "I am waiting for the taxi fare.", hindi: "मैं टैक्सी किराया का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าค่าแท็กซี่ใช้บ่อย", romanization: "kham-wâa khâa thék-sîi chái bàwy", english: "The word for taxi fare is commonly used.", hindi: "टैक्सी किराया के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1392: [
            WordExample(thai: "ฉันรอมิเตอร์แท็กซี่", romanization: "chǎn raw míi-dtəə thék-sîi", english: "I am waiting for the taxi meter.", hindi: "मैं टैक्सी मीटर का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่ามิเตอร์แท็กซี่ใช้บ่อย", romanization: "kham-wâa míi-dtəə thék-sîi chái bàwy", english: "The word for taxi meter is commonly used.", hindi: "टैक्सी मीटर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1393: [
            WordExample(thai: "ฉันรอไฟเลี้ยว", romanization: "chǎn raw fai-líao", english: "I am waiting for the turn signal.", hindi: "मैं मोड़ संकेतक का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าไฟเลี้ยวใช้บ่อย", romanization: "kham-wâa fai-líao chái bàwy", english: "The word for turn signal is commonly used.", hindi: "मोड़ संकेतक के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1394: [
            WordExample(thai: "ฉันรอที่นั่งริมหน้าต่าง", romanization: "chǎn raw thîi-nâng rim nâa-dtàang", english: "I am waiting for the window seat.", hindi: "मैं खिड़की वाली सीट का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าที่นั่งริมหน้าต่างใช้บ่อย", romanization: "kham-wâa thîi-nâng rim nâa-dtàang chái bàwy", english: "The word for window seat is commonly used.", hindi: "खिड़की वाली सीट के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1395: [
            WordExample(thai: "ฉันรอประตูขึ้นรถ", romanization: "chǎn raw bpra-dtuu khûen rót", english: "I am waiting for the boarding door.", hindi: "मैं चढ़ने का दरवाज़ा का इंतज़ार कर रहा हूँ।"),
            WordExample(thai: "คำว่าประตูขึ้นรถใช้บ่อย", romanization: "kham-wâa bpra-dtuu khûen rót chái bàwy", english: "The word for boarding door is commonly used.", hindi: "चढ़ने का दरवाज़ा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1396: [
            WordExample(thai: "โรงแรมมีการจองห้องพัก", romanization: "roong-raem mii gaan jawng hâawng-phák", english: "The hotel has room reservation.", hindi: "होटल में कमरा आरक्षण है।"),
            WordExample(thai: "คำว่าการจองห้องพักใช้บ่อย", romanization: "kham-wâa gaan jawng hâawng-phák chái bàwy", english: "The word for room reservation is commonly used.", hindi: "कमरा आरक्षण के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1397: [
            WordExample(thai: "โรงแรมมีห้องปลอดบุหรี่", romanization: "roong-raem mii hâawng bplàawt-bù-rìi", english: "The hotel has non-smoking room.", hindi: "होटल में धूम्रपान रहित कमरा है।"),
            WordExample(thai: "คำว่าห้องปลอดบุหรี่ใช้บ่อย", romanization: "kham-wâa hâawng bplàawt-bù-rìi chái bàwy", english: "The word for non-smoking room is commonly used.", hindi: "धूम्रपान रहित कमरा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1398: [
            WordExample(thai: "โรงแรมมีห้องสูบบุหรี่", romanization: "roong-raem mii hâawng sùup bù-rìi", english: "The hotel has smoking room.", hindi: "होटल में धूम्रपान कमरा है।"),
            WordExample(thai: "คำว่าห้องสูบบุหรี่ใช้บ่อย", romanization: "kham-wâa hâawng sùup bù-rìi chái bàwy", english: "The word for smoking room is commonly used.", hindi: "धूम्रपान कमरा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1399: [
            WordExample(thai: "โรงแรมมีห้องวิวทะเล", romanization: "roong-raem mii hâawng wiw thá-lee", english: "The hotel has sea-view room.", hindi: "होटल में समुद्र-दृश्य कमरा है।"),
            WordExample(thai: "คำว่าห้องวิวทะเลใช้บ่อย", romanization: "kham-wâa hâawng wiw thá-lee chái bàwy", english: "The word for sea-view room is commonly used.", hindi: "समुद्र-दृश्य कमरा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1400: [
            WordExample(thai: "โรงแรมมีห้องวิวเมือง", romanization: "roong-raem mii hâawng wiw-mueang", english: "The hotel has city-view room.", hindi: "होटल में शहर-दृश्य कमरा है।"),
            WordExample(thai: "คำว่าห้องวิวเมืองใช้บ่อย", romanization: "kham-wâa hâawng wiw-mueang chái bàwy", english: "The word for city-view room is commonly used.", hindi: "शहर-दृश्य कमरा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1401: [
            WordExample(thai: "โรงแรมมีห้องเชื่อมต่อ", romanization: "roong-raem mii hâawng chûeam-dtàaw", english: "The hotel has connecting room.", hindi: "होटल में जुड़ा हुआ कमरा है।"),
            WordExample(thai: "คำว่าห้องเชื่อมต่อใช้บ่อย", romanization: "kham-wâa hâawng chûeam-dtàaw chái bàwy", english: "The word for connecting room is commonly used.", hindi: "जुड़ा हुआ कमरा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1402: [
            WordExample(thai: "โรงแรมมีเตียงคู่", romanization: "roong-raem mii dtiang khûu", english: "The hotel has double bed.", hindi: "होटल में डबल बिस्तर है।"),
            WordExample(thai: "คำว่าเตียงคู่ใช้บ่อย", romanization: "kham-wâa dtiang khûu chái bàwy", english: "The word for double bed is commonly used.", hindi: "डबल बिस्तर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1403: [
            WordExample(thai: "โรงแรมมีเตียงเสริม", romanization: "roong-raem mii dtiang sə̌əm", english: "The hotel has extra bed.", hindi: "होटल में अतिरिक्त बिस्तर है।"),
            WordExample(thai: "คำว่าเตียงเสริมใช้บ่อย", romanization: "kham-wâa dtiang sə̌əm chái bàwy", english: "The word for extra bed is commonly used.", hindi: "अतिरिक्त बिस्तर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1404: [
            WordExample(thai: "โรงแรมมีครีมนวดผม", romanization: "roong-raem mii khriim nûat phǒm", english: "The hotel has hair conditioner.", hindi: "होटल में बाल कंडीशनर है।"),
            WordExample(thai: "คำว่าครีมนวดผมใช้บ่อย", romanization: "kham-wâa khriim nûat phǒm chái bàwy", english: "The word for hair conditioner is commonly used.", hindi: "बाल कंडीशनर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1405: [
            WordExample(thai: "โรงแรมมีอาหารเช้ารวม", romanization: "roong-raem mii aa-hǎan cháo ruam", english: "The hotel has breakfast included.", hindi: "होटल में नाश्ता शामिल है।"),
            WordExample(thai: "คำว่าอาหารเช้ารวมใช้บ่อย", romanization: "kham-wâa aa-hǎan cháo ruam chái bàwy", english: "The word for breakfast included is commonly used.", hindi: "नाश्ता शामिल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1406: [
            WordExample(thai: "โรงแรมมีเวลาเช็กอิน", romanization: "roong-raem mii wee-laa chék-in", english: "The hotel has check-in time.", hindi: "होटल में चेक-इन समय है।"),
            WordExample(thai: "คำว่าเวลาเช็กอินใช้บ่อย", romanization: "kham-wâa wee-laa chék-in chái bàwy", english: "The word for check-in time is commonly used.", hindi: "चेक-इन समय के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1407: [
            WordExample(thai: "โรงแรมมีเวลาเช็กเอาต์", romanization: "roong-raem mii wee-laa chék-áwt", english: "The hotel has check-out time.", hindi: "होटल में चेक-आउट समय है।"),
            WordExample(thai: "คำว่าเวลาเช็กเอาต์ใช้บ่อย", romanization: "kham-wâa wee-laa chék-áwt chái bàwy", english: "The word for check-out time is commonly used.", hindi: "चेक-आउट समय के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1408: [
            WordExample(thai: "โรงแรมมีแผนกแม่บ้าน", romanization: "roong-raem mii phà-nàek mâe-bâan", english: "The hotel has housekeeping department.", hindi: "होटल में हाउसकीपिंग विभाग है।"),
            WordExample(thai: "คำว่าแผนกแม่บ้านใช้บ่อย", romanization: "kham-wâa phà-nàek mâe-bâan chái bàwy", english: "The word for housekeeping department is commonly used.", hindi: "हाउसकीपिंग विभाग के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1409: [
            WordExample(thai: "โรงแรมมีบริการซักรีด", romanization: "roong-raem mii baw-ri-gaan sák-rîit", english: "The hotel has laundry service.", hindi: "होटल में कपड़े धोने की सेवा है।"),
            WordExample(thai: "คำว่าบริการซักรีดใช้บ่อย", romanization: "kham-wâa baw-ri-gaan sák-rîit chái bàwy", english: "The word for laundry service is commonly used.", hindi: "कपड़े धोने की सेवा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1410: [
            WordExample(thai: "โรงแรมมีบริการรับฝากกระเป๋า", romanization: "roong-raem mii baw-ri-gaan ráp fàak grà-bpǎo", english: "The hotel has luggage deposit service.", hindi: "होटल में सामान जमा सेवा है।"),
            WordExample(thai: "คำว่าบริการรับฝากกระเป๋าใช้บ่อย", romanization: "kham-wâa baw-ri-gaan ráp fàak grà-bpǎo chái bàwy", english: "The word for luggage deposit service is commonly used.", hindi: "सामान जमा सेवा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1411: [
            WordExample(thai: "โรงแรมมีบริการปลุก", romanization: "roong-raem mii baw-ri-gaan bplùk", english: "The hotel has wake-up service.", hindi: "होटल में जगाने की सेवा है।"),
            WordExample(thai: "คำว่าบริการปลุกใช้บ่อย", romanization: "kham-wâa baw-ri-gaan bplùk chái bàwy", english: "The word for wake-up service is commonly used.", hindi: "जगाने की सेवा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1412: [
            WordExample(thai: "โรงแรมมีรหัสไวไฟ", romanization: "roong-raem mii rá-hàt wai-fai", english: "The hotel has Wi-Fi password.", hindi: "होटल में वाई-फाई पासवर्ड है।"),
            WordExample(thai: "คำว่ารหัสไวไฟใช้บ่อย", romanization: "kham-wâa rá-hàt wai-fai chái bàwy", english: "The word for Wi-Fi password is commonly used.", hindi: "वाई-फाई पासवर्ड के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1413: [
            WordExample(thai: "โรงแรมมีอินเทอร์เน็ตไร้สาย", romanization: "roong-raem mii in-thəə-nét ráai-sǎai", english: "The hotel has wireless internet.", hindi: "होटल में बेतार इंटरनेट है।"),
            WordExample(thai: "คำว่าอินเทอร์เน็ตไร้สายใช้บ่อย", romanization: "kham-wâa in-thəə-nét ráai-sǎai chái bàwy", english: "The word for wireless internet is commonly used.", hindi: "बेतार इंटरनेट के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1414: [
            WordExample(thai: "โรงแรมมีบัตรกุญแจ", romanization: "roong-raem mii bàt gun-jae", english: "The hotel has key card.", hindi: "होटल में चाबी कार्ड है।"),
            WordExample(thai: "คำว่าบัตรกุญแจใช้บ่อย", romanization: "kham-wâa bàt gun-jae chái bàwy", english: "The word for key card is commonly used.", hindi: "चाबी कार्ड के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1415: [
            WordExample(thai: "โรงแรมมีประตูห้อง", romanization: "roong-raem mii bpra-dtuu hâawng", english: "The hotel has room door.", hindi: "होटल में कमरे का दरवाज़ा है।"),
            WordExample(thai: "คำว่าประตูห้องใช้บ่อย", romanization: "kham-wâa bpra-dtuu hâawng chái bàwy", english: "The word for room door is commonly used.", hindi: "कमरे का दरवाज़ा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1416: [
            WordExample(thai: "โรงแรมมีหมายเลขห้อง", romanization: "roong-raem mii mǎai-lék hâawng", english: "The hotel has room number.", hindi: "होटल में कमरा नंबर है।"),
            WordExample(thai: "คำว่าหมายเลขห้องใช้บ่อย", romanization: "kham-wâa mǎai-lék hâawng chái bàwy", english: "The word for room number is commonly used.", hindi: "कमरा नंबर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1417: [
            WordExample(thai: "โรงแรมมีห้องประชุม", romanization: "roong-raem mii hâawng bpra-chum", english: "The hotel has meeting room.", hindi: "होटल में बैठक कक्ष है।"),
            WordExample(thai: "คำว่าห้องประชุมใช้บ่อย", romanization: "kham-wâa hâawng bpra-chum chái bàwy", english: "The word for meeting room is commonly used.", hindi: "बैठक कक्ष के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1418: [
            WordExample(thai: "โรงแรมมีห้องออกกำลังกาย", romanization: "roong-raem mii hâawng àwk-gam-lang-gaai", english: "The hotel has gym room.", hindi: "होटल में व्यायाम कक्ष है।"),
            WordExample(thai: "คำว่าห้องออกกำลังกายใช้บ่อย", romanization: "kham-wâa hâawng àwk-gam-lang-gaai chái bàwy", english: "The word for gym room is commonly used.", hindi: "व्यायाम कक्ष के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1419: [
            WordExample(thai: "โรงแรมมีผ้าเช็ดหน้า", romanization: "roong-raem mii phâa chét-nâa", english: "The hotel has face towel.", hindi: "होटल में चेहरा पोंछने का तौलिया है।"),
            WordExample(thai: "คำว่าผ้าเช็ดหน้าใช้บ่อย", romanization: "kham-wâa phâa chét-nâa chái bàwy", english: "The word for face towel is commonly used.", hindi: "चेहरा पोंछने का तौलिया के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1420: [
            WordExample(thai: "โรงแรมมีเครื่องทำน้ำอุ่น", romanization: "roong-raem mii khrûeang tham-náam ùn", english: "The hotel has water heater.", hindi: "होटल में पानी गरम करने का यंत्र है।"),
            WordExample(thai: "คำว่าเครื่องทำน้ำอุ่นใช้บ่อย", romanization: "kham-wâa khrûeang tham-náam ùn chái bàwy", english: "The word for water heater is commonly used.", hindi: "पानी गरम करने का यंत्र के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1421: [
            WordExample(thai: "วันนี้อากาศร้อน", romanization: "wan-níi aa-gàat ráawn", english: "Today there is hot weather.", hindi: "आज गर्म मौसम है।"),
            WordExample(thai: "คำว่าอากาศร้อนใช้บ่อย", romanization: "kham-wâa aa-gàat ráawn chái bàwy", english: "The word for hot weather is commonly used.", hindi: "गर्म मौसम के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1422: [
            WordExample(thai: "วันนี้อากาศหนาว", romanization: "wan-níi aa-gàat nǎao", english: "Today there is cold weather.", hindi: "आज ठंडा मौसम है।"),
            WordExample(thai: "คำว่าอากาศหนาวใช้บ่อย", romanization: "kham-wâa aa-gàat nǎao chái bàwy", english: "The word for cold weather is commonly used.", hindi: "ठंडा मौसम के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1423: [
            WordExample(thai: "วันนี้อากาศเย็น", romanization: "wan-níi aa-gàat yen", english: "Today there is cool weather.", hindi: "आज सुहावना मौसम है।"),
            WordExample(thai: "คำว่าอากาศเย็นใช้บ่อย", romanization: "kham-wâa aa-gàat yen chái bàwy", english: "The word for cool weather is commonly used.", hindi: "सुहावना मौसम के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1424: [
            WordExample(thai: "วันนี้อากาศชื้น", romanization: "wan-níi aa-gàat chʉ́ʉn", english: "Today there is humid weather.", hindi: "आज नम मौसम है।"),
            WordExample(thai: "คำว่าอากาศชื้นใช้บ่อย", romanization: "kham-wâa aa-gàat chʉ́ʉn chái bàwy", english: "The word for humid weather is commonly used.", hindi: "नम मौसम के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1425: [
            WordExample(thai: "วันนี้อากาศแห้ง", romanization: "wan-níi aa-gàat hâeng", english: "Today there is dry weather.", hindi: "आज शुष्क मौसम है।"),
            WordExample(thai: "คำว่าอากาศแห้งใช้บ่อย", romanization: "kham-wâa aa-gàat hâeng chái bàwy", english: "The word for dry weather is commonly used.", hindi: "शुष्क मौसम के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1426: [
            WordExample(thai: "วันนี้เมฆครึ้ม", romanization: "wan-níi mêek khrʉ́m", english: "Today there is overcast clouds.", hindi: "आज घने बादल है।"),
            WordExample(thai: "คำว่าเมฆครึ้มใช้บ่อย", romanization: "kham-wâa mêek khrʉ́m chái bàwy", english: "The word for overcast clouds is commonly used.", hindi: "घने बादल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1427: [
            WordExample(thai: "วันนี้ท้องฟ้าโปร่ง", romanization: "wan-níi tháwng-fáa bpròhng", english: "Today there is clear sky.", hindi: "आज साफ़ आकाश है।"),
            WordExample(thai: "คำว่าท้องฟ้าโปร่งใช้บ่อย", romanization: "kham-wâa tháwng-fáa bpròhng chái bàwy", english: "The word for clear sky is commonly used.", hindi: "साफ़ आकाश के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1428: [
            WordExample(thai: "วันนี้ฝนหนัก", romanization: "wan-níi fǒn nàk", english: "Today there is heavy rain.", hindi: "आज तेज़ बारिश है।"),
            WordExample(thai: "คำว่าฝนหนักใช้บ่อย", romanization: "kham-wâa fǒn nàk chái bàwy", english: "The word for heavy rain is commonly used.", hindi: "तेज़ बारिश के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1429: [
            WordExample(thai: "วันนี้ฝนเบา", romanization: "wan-níi fǒn bao", english: "Today there is light rain.", hindi: "आज हल्की बारिश है।"),
            WordExample(thai: "คำว่าฝนเบาใช้บ่อย", romanization: "kham-wâa fǒn bao chái bàwy", english: "The word for light rain is commonly used.", hindi: "हल्की बारिश के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1430: [
            WordExample(thai: "วันนี้ลมกระโชก", romanization: "wan-níi lom grà-chôhk", english: "Today there is wind gust.", hindi: "आज हवा का झोंका है।"),
            WordExample(thai: "คำว่าลมกระโชกใช้บ่อย", romanization: "kham-wâa lom grà-chôhk chái bàwy", english: "The word for wind gust is commonly used.", hindi: "हवा का झोंका के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1431: [
            WordExample(thai: "วันนี้ลมหนาว", romanization: "wan-níi lom nǎao", english: "Today there is cold wind.", hindi: "आज ठंडी हवा है।"),
            WordExample(thai: "คำว่าลมหนาวใช้บ่อย", romanization: "kham-wâa lom nǎao chái bàwy", english: "The word for cold wind is commonly used.", hindi: "ठंडी हवा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1432: [
            WordExample(thai: "วันนี้ลมทะเล", romanization: "wan-níi lom thá-lee", english: "Today there is sea breeze.", hindi: "आज समुद्री हवा है।"),
            WordExample(thai: "คำว่าลมทะเลใช้บ่อย", romanization: "kham-wâa lom thá-lee chái bàwy", english: "The word for sea breeze is commonly used.", hindi: "समुद्री हवा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1433: [
            WordExample(thai: "วันนี้อุณหภูมิสูง", romanization: "wan-níi un-hà-phuum sǔung", english: "Today there is high temperature.", hindi: "आज उच्च तापमान है।"),
            WordExample(thai: "คำว่าอุณหภูมิสูงใช้บ่อย", romanization: "kham-wâa un-hà-phuum sǔung chái bàwy", english: "The word for high temperature is commonly used.", hindi: "उच्च तापमान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1434: [
            WordExample(thai: "วันนี้อุณหภูมิต่ำ", romanization: "wan-níi un-hà-phuum dtàm", english: "Today there is low temperature.", hindi: "आज निम्न तापमान है।"),
            WordExample(thai: "คำว่าอุณหภูมิต่ำใช้บ่อย", romanization: "kham-wâa un-hà-phuum dtàm chái bàwy", english: "The word for low temperature is commonly used.", hindi: "निम्न तापमान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1435: [
            WordExample(thai: "วันนี้ระดับความชื้น", romanization: "wan-níi rá-dàp khwaam-chʉ́ʉn", english: "Today there is humidity level.", hindi: "आज नमी का स्तर है।"),
            WordExample(thai: "คำว่าระดับความชื้นใช้บ่อย", romanization: "kham-wâa rá-dàp khwaam-chʉ́ʉn chái bàwy", english: "The word for humidity level is commonly used.", hindi: "नमी का स्तर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1436: [
            WordExample(thai: "วันนี้แสงแดด", romanization: "wan-níi sǎeng dàet", english: "Today there is sunlight.", hindi: "आज धूप है।"),
            WordExample(thai: "คำว่าแสงแดดใช้บ่อย", romanization: "kham-wâa sǎeng dàet chái bàwy", english: "The word for sunlight is commonly used.", hindi: "धूप के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1437: [
            WordExample(thai: "วันนี้แดดจัด", romanization: "wan-níi dàet jàt", english: "Today there is intense sunshine.", hindi: "आज तेज़ धूप है।"),
            WordExample(thai: "คำว่าแดดจัดใช้บ่อย", romanization: "kham-wâa dàet jàt chái bàwy", english: "The word for intense sunshine is commonly used.", hindi: "तेज़ धूप के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1438: [
            WordExample(thai: "วันนี้แดดอ่อน", romanization: "wan-níi dàet àawn", english: "Today there is gentle sunshine.", hindi: "आज हल्की धूप है।"),
            WordExample(thai: "คำว่าแดดอ่อนใช้บ่อย", romanization: "kham-wâa dàet àawn chái bàwy", english: "The word for gentle sunshine is commonly used.", hindi: "हल्की धूप के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1439: [
            WordExample(thai: "วันนี้ร่มครึ้ม", romanization: "wan-níi rôm-khrʉ́m", english: "Today there is shady and overcast.", hindi: "आज छायादार और घना है।"),
            WordExample(thai: "คำว่าร่มครึ้มใช้บ่อย", romanization: "kham-wâa rôm-khrʉ́m chái bàwy", english: "The word for shady and overcast is commonly used.", hindi: "छायादार और घना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1440: [
            WordExample(thai: "วันนี้ฤดูร้อน", romanization: "wan-níi réu-duu ráawn", english: "Today there is summer season.", hindi: "आज गर्मी का मौसम है।"),
            WordExample(thai: "คำว่าฤดูร้อนใช้บ่อย", romanization: "kham-wâa réu-duu ráawn chái bàwy", english: "The word for summer season is commonly used.", hindi: "गर्मी का मौसम के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1441: [
            WordExample(thai: "วันนี้ฤดูใบไม้ผลิ", romanization: "wan-níi réu-duu bai-máai-phlì", english: "Today there is spring season.", hindi: "आज वसंत ऋतु है।"),
            WordExample(thai: "คำว่าฤดูใบไม้ผลิใช้บ่อย", romanization: "kham-wâa réu-duu bai-máai-phlì chái bàwy", english: "The word for spring season is commonly used.", hindi: "वसंत ऋतु के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1442: [
            WordExample(thai: "วันนี้ฤดูใบไม้ร่วง", romanization: "wan-níi réu-duu bai-máai-rûang", english: "Today there is autumn season.", hindi: "आज पतझड़ ऋतु है।"),
            WordExample(thai: "คำว่าฤดูใบไม้ร่วงใช้บ่อย", romanization: "kham-wâa réu-duu bai-máai-rûang chái bàwy", english: "The word for autumn season is commonly used.", hindi: "पतझड़ ऋतु के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1443: [
            WordExample(thai: "วันนี้ลูกเห็บ", romanization: "wan-níi lûuk-hèp", english: "Today there is hailstone.", hindi: "आज ओला है।"),
            WordExample(thai: "คำว่าลูกเห็บใช้บ่อย", romanization: "kham-wâa lûuk-hèp chái bàwy", english: "The word for hailstone is commonly used.", hindi: "ओला के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1444: [
            WordExample(thai: "วันนี้พายุหมุน", romanization: "wan-níi phaa-yú mǔn", english: "Today there is cyclone.", hindi: "आज चक्रवात है।"),
            WordExample(thai: "คำว่าพายุหมุนใช้บ่อย", romanization: "kham-wâa phaa-yú mǔn chái bàwy", english: "The word for cyclone is commonly used.", hindi: "चक्रवात के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1445: [
            WordExample(thai: "วันนี้คลื่นความร้อน", romanization: "wan-níi khlʉ̂ʉn khwaam-ráawn", english: "Today there is heat wave.", hindi: "आज लू की लहर है।"),
            WordExample(thai: "คำว่าคลื่นความร้อนใช้บ่อย", romanization: "kham-wâa khlʉ̂ʉn khwaam-ráawn chái bàwy", english: "The word for heat wave is commonly used.", hindi: "लू की लहर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1446: [
            WordExample(thai: "เราไปดูคลอง", romanization: "rao bpai duu khlawng", english: "We went to see the canal.", hindi: "हम नहर देखने गए।"),
            WordExample(thai: "คำว่าคลองใช้บ่อย", romanization: "kham-wâa khlawng chái bàwy", english: "The word for canal is commonly used.", hindi: "नहर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1447: [
            WordExample(thai: "เราไปดูน้ำพุ", romanization: "rao bpai duu náam-phú", english: "We went to see the fountain.", hindi: "हम फव्वारा देखने गए।"),
            WordExample(thai: "คำว่าน้ำพุใช้บ่อย", romanization: "kham-wâa náam-phú chái bàwy", english: "The word for fountain is commonly used.", hindi: "फव्वारा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1448: [
            WordExample(thai: "เราไปดูน้ำพุร้อน", romanization: "rao bpai duu náam-phú ráawn", english: "We went to see the hot spring.", hindi: "हम गरम पानी का झरना देखने गए।"),
            WordExample(thai: "คำว่าน้ำพุร้อนใช้บ่อย", romanization: "kham-wâa náam-phú ráawn chái bàwy", english: "The word for hot spring is commonly used.", hindi: "गरम पानी का झरना के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1449: [
            WordExample(thai: "เราไปดูน้ำตกชั้น", romanization: "rao bpai duu náam-dtòk chán", english: "We went to see the waterfall tier.", hindi: "हम झरने की परत देखने गए।"),
            WordExample(thai: "คำว่าน้ำตกชั้นใช้บ่อย", romanization: "kham-wâa náam-dtòk chán chái bàwy", english: "The word for waterfall tier is commonly used.", hindi: "झरने की परत के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1450: [
            WordExample(thai: "เราไปดูหน้าผาสูง", romanization: "rao bpai duu nâa-phǎa sǔung", english: "We went to see the high cliff.", hindi: "हम ऊँची चट्टान देखने गए।"),
            WordExample(thai: "คำว่าหน้าผาสูงใช้บ่อย", romanization: "kham-wâa nâa-phǎa sǔung chái bàwy", english: "The word for high cliff is commonly used.", hindi: "ऊँची चट्टान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1451: [
            WordExample(thai: "เราไปดูถ้ำหินปูน", romanization: "rao bpai duu thâm hǐn-bpuun", english: "We went to see the limestone cave.", hindi: "हम चूना पत्थर की गुफा देखने गए।"),
            WordExample(thai: "คำว่าถ้ำหินปูนใช้บ่อย", romanization: "kham-wâa thâm hǐn-bpuun chái bàwy", english: "The word for limestone cave is commonly used.", hindi: "चूना पत्थर की गुफा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1452: [
            WordExample(thai: "เราไปดูแนวปะการัง", romanization: "rao bpai duu naew bpà-gaa-rang", english: "We went to see the coral reef.", hindi: "हम प्रवाल भित्ति देखने गए।"),
            WordExample(thai: "คำว่าแนวปะการังใช้บ่อย", romanization: "kham-wâa naew bpà-gaa-rang chái bàwy", english: "The word for coral reef is commonly used.", hindi: "प्रवाल भित्ति के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1453: [
            WordExample(thai: "เราไปดูปะการัง", romanization: "rao bpai duu bpà-gaa-rang", english: "We went to see the coral.", hindi: "हम प्रवाल देखने गए।"),
            WordExample(thai: "คำว่าปะการังใช้บ่อย", romanization: "kham-wâa bpà-gaa-rang chái bàwy", english: "The word for coral is commonly used.", hindi: "प्रवाल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1454: [
            WordExample(thai: "เราไปดูอ่าว", romanization: "rao bpai duu àao", english: "We went to see the bay.", hindi: "हम खाड़ी देखने गए।"),
            WordExample(thai: "คำว่าอ่าวใช้บ่อย", romanization: "kham-wâa àao chái bàwy", english: "The word for bay is commonly used.", hindi: "खाड़ी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1455: [
            WordExample(thai: "เราไปดูแหลม", romanization: "rao bpai duu lǎem", english: "We went to see the cape.", hindi: "हम अंतरीप देखने गए।"),
            WordExample(thai: "คำว่าแหลมใช้บ่อย", romanization: "kham-wâa lǎem chái bàwy", english: "The word for cape is commonly used.", hindi: "अंतरीप के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1456: [
            WordExample(thai: "เราไปดูเกาะเล็ก", romanization: "rao bpai duu gàw lék", english: "We went to see the small island.", hindi: "हम छोटा द्वीप देखने गए।"),
            WordExample(thai: "คำว่าเกาะเล็กใช้บ่อย", romanization: "kham-wâa gàw lék chái bàwy", english: "The word for small island is commonly used.", hindi: "छोटा द्वीप के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1457: [
            WordExample(thai: "เราไปดูเกาะใหญ่", romanization: "rao bpai duu gàw yài", english: "We went to see the large island.", hindi: "हम बड़ा द्वीप देखने गए।"),
            WordExample(thai: "คำว่าเกาะใหญ่ใช้บ่อย", romanization: "kham-wâa gàw yài chái bàwy", english: "The word for large island is commonly used.", hindi: "बड़ा द्वीप के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1458: [
            WordExample(thai: "เราไปดูป่าดิบชื้น", romanization: "rao bpai duu bpàa-dìp chʉ́ʉn", english: "We went to see the rainforest.", hindi: "हम वर्षावन देखने गए।"),
            WordExample(thai: "คำว่าป่าดิบชื้นใช้บ่อย", romanization: "kham-wâa bpàa-dìp chʉ́ʉn chái bàwy", english: "The word for rainforest is commonly used.", hindi: "वर्षावन के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1459: [
            WordExample(thai: "เราไปดูป่าสน", romanization: "rao bpai duu bpàa sǒn", english: "We went to see the pine forest.", hindi: "हम चीड़ का जंगल देखने गए।"),
            WordExample(thai: "คำว่าป่าสนใช้บ่อย", romanization: "kham-wâa bpàa sǒn chái bàwy", english: "The word for pine forest is commonly used.", hindi: "चीड़ का जंगल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1460: [
            WordExample(thai: "เราไปดูทุ่งหญ้า", romanization: "rao bpai duu thûng-yâa", english: "We went to see the grassland.", hindi: "हम घास का मैदान देखने गए।"),
            WordExample(thai: "คำว่าทุ่งหญ้าใช้บ่อย", romanization: "kham-wâa thûng-yâa chái bàwy", english: "The word for grassland is commonly used.", hindi: "घास का मैदान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1461: [
            WordExample(thai: "เราไปดูทุ่งนา", romanization: "rao bpai duu thûng naa", english: "We went to see the rice field.", hindi: "हम धान का खेत देखने गए।"),
            WordExample(thai: "คำว่าทุ่งนาใช้บ่อย", romanization: "kham-wâa thûng naa chái bàwy", english: "The word for rice field is commonly used.", hindi: "धान का खेत के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1462: [
            WordExample(thai: "เราไปดูไร่ชา", romanization: "rao bpai duu rài chaa", english: "We went to see the tea plantation.", hindi: "हम चाय का बागान देखने गए।"),
            WordExample(thai: "คำว่าไร่ชาใช้บ่อย", romanization: "kham-wâa rài chaa chái bàwy", english: "The word for tea plantation is commonly used.", hindi: "चाय का बागान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1463: [
            WordExample(thai: "เราไปดูสวนผลไม้", romanization: "rao bpai duu sǔan phǒn-lá-máai", english: "We went to see the orchard.", hindi: "हम फलों का बाग देखने गए।"),
            WordExample(thai: "คำว่าสวนผลไม้ใช้บ่อย", romanization: "kham-wâa sǔan phǒn-lá-máai chái bàwy", english: "The word for orchard is commonly used.", hindi: "फलों का बाग के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1464: [
            WordExample(thai: "เราไปดูธารน้ำแข็ง", romanization: "rao bpai duu thaan náam-khǎeng", english: "We went to see the glacier.", hindi: "हम हिमनद देखने गए।"),
            WordExample(thai: "คำว่าธารน้ำแข็งใช้บ่อย", romanization: "kham-wâa thaan náam-khǎeng chái bàwy", english: "The word for glacier is commonly used.", hindi: "हिमनद के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1465: [
            WordExample(thai: "เราไปดูน้ำขึ้น", romanization: "rao bpai duu náam khûen", english: "We went to see the high tide.", hindi: "हम ज्वार देखने गए।"),
            WordExample(thai: "คำว่าน้ำขึ้นใช้บ่อย", romanization: "kham-wâa náam khûen chái bàwy", english: "The word for high tide is commonly used.", hindi: "ज्वार के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1466: [
            WordExample(thai: "เราไปดูน้ำลง", romanization: "rao bpai duu náam long", english: "We went to see the low tide.", hindi: "हम भाटा देखने गए।"),
            WordExample(thai: "คำว่าน้ำลงใช้บ่อย", romanization: "kham-wâa náam long chái bàwy", english: "The word for low tide is commonly used.", hindi: "भाटा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1467: [
            WordExample(thai: "เราไปดูคลื่นทะเล", romanization: "rao bpai duu khlʉ̂ʉn thá-lee", english: "We went to see the sea wave.", hindi: "हम समुद्री लहर देखने गए।"),
            WordExample(thai: "คำว่าคลื่นทะเลใช้บ่อย", romanization: "kham-wâa khlʉ̂ʉn thá-lee chái bàwy", english: "The word for sea wave is commonly used.", hindi: "समुद्री लहर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1468: [
            WordExample(thai: "เราไปดูริมแม่น้ำ", romanization: "rao bpai duu rim mâe-náam", english: "We went to see the riverbank.", hindi: "हम नदी किनारा देखने गए।"),
            WordExample(thai: "คำว่าริมแม่น้ำใช้บ่อย", romanization: "kham-wâa rim mâe-náam chái bàwy", english: "The word for riverbank is commonly used.", hindi: "नदी किनारा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1469: [
            WordExample(thai: "เราไปดูต้นสน", romanization: "rao bpai duu dtôn sǒn", english: "We went to see the pine tree.", hindi: "हम चीड़ का पेड़ देखने गए।"),
            WordExample(thai: "คำว่าต้นสนใช้บ่อย", romanization: "kham-wâa dtôn sǒn chái bàwy", english: "The word for pine tree is commonly used.", hindi: "चीड़ का पेड़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1470: [
            WordExample(thai: "เราไปดูพุ่มไม้", romanization: "rao bpai duu phûm-máai", english: "We went to see the bush.", hindi: "हम झाड़ी देखने गए।"),
            WordExample(thai: "คำว่าพุ่มไม้ใช้บ่อย", romanization: "kham-wâa phûm-máai chái bàwy", english: "The word for bush is commonly used.", hindi: "झाड़ी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1471: [
            WordExample(thai: "ฉันเห็นนกแก้ว", romanization: "chǎn hěn nók gâew", english: "I see a parrot.", hindi: "मैं तोता देखता हूँ।"),
            WordExample(thai: "คำว่านกแก้วใช้บ่อย", romanization: "kham-wâa nók gâew chái bàwy", english: "The word for parrot is commonly used.", hindi: "तोता के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1472: [
            WordExample(thai: "ฉันเห็นนกอินทรี", romanization: "chǎn hěn nók in-sii", english: "I see a eagle.", hindi: "मैं गरुड़ देखता हूँ।"),
            WordExample(thai: "คำว่านกอินทรีใช้บ่อย", romanization: "kham-wâa nók in-sii chái bàwy", english: "The word for eagle is commonly used.", hindi: "गरुड़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1473: [
            WordExample(thai: "ฉันเห็นนกฮูก", romanization: "chǎn hěn nók hûuk", english: "I see a owl.", hindi: "मैं उल्लू देखता हूँ।"),
            WordExample(thai: "คำว่านกฮูกใช้บ่อย", romanization: "kham-wâa nók hûuk chái bàwy", english: "The word for owl is commonly used.", hindi: "उल्लू के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1474: [
            WordExample(thai: "ฉันเห็นนกกระจอก", romanization: "chǎn hěn nók grà-jàawk", english: "I see a sparrow.", hindi: "मैं गौरैया देखता हूँ।"),
            WordExample(thai: "คำว่านกกระจอกใช้บ่อย", romanization: "kham-wâa nók grà-jàawk chái bàwy", english: "The word for sparrow is commonly used.", hindi: "गौरैया के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1475: [
            WordExample(thai: "ฉันเห็นนกพิราบ", romanization: "chǎn hěn nók phí-râap", english: "I see a pigeon.", hindi: "मैं कबूतर देखता हूँ।"),
            WordExample(thai: "คำว่านกพิราบใช้บ่อย", romanization: "kham-wâa nók phí-râap chái bàwy", english: "The word for pigeon is commonly used.", hindi: "कबूतर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1476: [
            WordExample(thai: "ฉันเห็นค่าง", romanization: "chǎn hěn khâang", english: "I see a langur.", hindi: "मैं लंगूर देखता हूँ।"),
            WordExample(thai: "คำว่าค่างใช้บ่อย", romanization: "kham-wâa khâang chái bàwy", english: "The word for langur is commonly used.", hindi: "लंगूर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1477: [
            WordExample(thai: "ฉันเห็นชะนี", romanization: "chǎn hěn chá-nii", english: "I see a gibbon.", hindi: "मैं गिबन देखता हूँ।"),
            WordExample(thai: "คำว่าชะนีใช้บ่อย", romanization: "kham-wâa chá-nii chái bàwy", english: "The word for gibbon is commonly used.", hindi: "गिबन के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1478: [
            WordExample(thai: "ฉันเห็นเสือดาว", romanization: "chǎn hěn sʉ̌ʉa-daao", english: "I see a leopard.", hindi: "मैं तेंदुआ देखता हूँ।"),
            WordExample(thai: "คำว่าเสือดาวใช้บ่อย", romanization: "kham-wâa sʉ̌ʉa-daao chái bàwy", english: "The word for leopard is commonly used.", hindi: "तेंदुआ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1479: [
            WordExample(thai: "ฉันเห็นม้าลาย", romanization: "chǎn hěn máa-laai", english: "I see a zebra.", hindi: "मैं ज़ेब्रा देखता हूँ।"),
            WordExample(thai: "คำว่าม้าลายใช้บ่อย", romanization: "kham-wâa máa-laai chái bàwy", english: "The word for zebra is commonly used.", hindi: "ज़ेब्रा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1480: [
            WordExample(thai: "ฉันเห็นยีราฟ", romanization: "chǎn hěn yii-râap", english: "I see a giraffe.", hindi: "मैं जिराफ़ देखता हूँ।"),
            WordExample(thai: "คำว่ายีราฟใช้บ่อย", romanization: "kham-wâa yii-râap chái bàwy", english: "The word for giraffe is commonly used.", hindi: "जिराफ़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1481: [
            WordExample(thai: "ฉันเห็นฮิปโป", romanization: "chǎn hěn híp-bpoo", english: "I see a hippopotamus.", hindi: "मैं दरियाई घोड़ा देखता हूँ।"),
            WordExample(thai: "คำว่าฮิปโปใช้บ่อย", romanization: "kham-wâa híp-bpoo chái bàwy", english: "The word for hippopotamus is commonly used.", hindi: "दरियाई घोड़ा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1482: [
            WordExample(thai: "ฉันเห็นแรด", romanization: "chǎn hěn râet", english: "I see a rhinoceros.", hindi: "मैं गैंडा देखता हूँ।"),
            WordExample(thai: "คำว่าแรดใช้บ่อย", romanization: "kham-wâa râet chái bàwy", english: "The word for rhinoceros is commonly used.", hindi: "गैंडा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1483: [
            WordExample(thai: "ฉันเห็นกระรอก", romanization: "chǎn hěn grà-ràawk", english: "I see a squirrel.", hindi: "मैं गिलहरी देखता हूँ।"),
            WordExample(thai: "คำว่ากระรอกใช้บ่อย", romanization: "kham-wâa grà-ràawk chái bàwy", english: "The word for squirrel is commonly used.", hindi: "गिलहरी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1484: [
            WordExample(thai: "ฉันเห็นเม่น", romanization: "chǎn hěn mèn", english: "I see a porcupine.", hindi: "मैं साही देखता हूँ।"),
            WordExample(thai: "คำว่าเม่นใช้บ่อย", romanization: "kham-wâa mèn chái bàwy", english: "The word for porcupine is commonly used.", hindi: "साही के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1485: [
            WordExample(thai: "ฉันเห็นค้างคาว", romanization: "chǎn hěn kháang-khaao", english: "I see a bat.", hindi: "मैं चमगादड़ देखता हूँ।"),
            WordExample(thai: "คำว่าค้างคาวใช้บ่อย", romanization: "kham-wâa kháang-khaao chái bàwy", english: "The word for bat is commonly used.", hindi: "चमगादड़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1486: [
            WordExample(thai: "ฉันเห็นนาก", romanization: "chǎn hěn nâak", english: "I see a otter.", hindi: "मैं ऊदबिलाव देखता हूँ।"),
            WordExample(thai: "คำว่านากใช้บ่อย", romanization: "kham-wâa nâak chái bàwy", english: "The word for otter is commonly used.", hindi: "ऊदबिलाव के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1487: [
            WordExample(thai: "ฉันเห็นเต่าทะเล", romanization: "chǎn hěn dtào thá-lee", english: "I see a sea turtle.", hindi: "मैं समुद्री कछुआ देखता हूँ।"),
            WordExample(thai: "คำว่าเต่าทะเลใช้บ่อย", romanization: "kham-wâa dtào thá-lee chái bàwy", english: "The word for sea turtle is commonly used.", hindi: "समुद्री कछुआ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1488: [
            WordExample(thai: "ฉันเห็นปลาวาฬ", romanization: "chǎn hěn bplaa-waan", english: "I see a whale.", hindi: "मैं व्हेल देखता हूँ।"),
            WordExample(thai: "คำว่าปลาวาฬใช้บ่อย", romanization: "kham-wâa bplaa-waan chái bàwy", english: "The word for whale is commonly used.", hindi: "व्हेल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1489: [
            WordExample(thai: "ฉันเห็นฉลาม", romanization: "chǎn hěn chà-làam", english: "I see a shark.", hindi: "मैं शार्क देखता हूँ।"),
            WordExample(thai: "คำว่าฉลามใช้บ่อย", romanization: "kham-wâa chà-làam chái bàwy", english: "The word for shark is commonly used.", hindi: "शार्क के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1490: [
            WordExample(thai: "ฉันเห็นปลากระเบน", romanization: "chǎn hěn bplaa grà-been", english: "I see a stingray.", hindi: "मैं स्टिंगरे देखता हूँ।"),
            WordExample(thai: "คำว่าปลากระเบนใช้บ่อย", romanization: "kham-wâa bplaa grà-been chái bàwy", english: "The word for stingray is commonly used.", hindi: "स्टिंगरे के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1491: [
            WordExample(thai: "ฉันเห็นนกเพนกวิน", romanization: "chǎn hěn nók phen-gwin", english: "I see a penguin.", hindi: "मैं पेंगुइन देखता हूँ।"),
            WordExample(thai: "คำว่านกเพนกวินใช้บ่อย", romanization: "kham-wâa nók phen-gwin chái bàwy", english: "The word for penguin is commonly used.", hindi: "पेंगुइन के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1492: [
            WordExample(thai: "ฉันเห็นแมลงปอ", romanization: "chǎn hěn má-laeng-bpɔɔ", english: "I see a dragonfly.", hindi: "मैं व्याध पतंग देखता हूँ।"),
            WordExample(thai: "คำว่าแมลงปอใช้บ่อย", romanization: "kham-wâa má-laeng-bpɔɔ chái bàwy", english: "The word for dragonfly is commonly used.", hindi: "व्याध पतंग के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1493: [
            WordExample(thai: "ฉันเห็นหอยทาก", romanization: "chǎn hěn hǎawii-thâak", english: "I see a snail.", hindi: "मैं घोंघा देखता हूँ।"),
            WordExample(thai: "คำว่าหอยทากใช้บ่อย", romanization: "kham-wâa hǎawii-thâak chái bàwy", english: "The word for snail is commonly used.", hindi: "घोंघा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1494: [
            WordExample(thai: "ฉันเห็นวัวแดง", romanization: "chǎn hěn wua daeng", english: "I see a banteng.", hindi: "मैं जंगली बैल देखता हूँ।"),
            WordExample(thai: "คำว่าวัวแดงใช้บ่อย", romanization: "kham-wâa wua daeng chái bàwy", english: "The word for banteng is commonly used.", hindi: "जंगली बैल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1495: [
            WordExample(thai: "ฉันเห็นตัวนิ่ม", romanization: "chǎn hěn dtua nîm", english: "I see a pangolin.", hindi: "मैं पैंगोलिन देखता हूँ।"),
            WordExample(thai: "คำว่าตัวนิ่มใช้บ่อย", romanization: "kham-wâa dtua nîm chái bàwy", english: "The word for pangolin is commonly used.", hindi: "पैंगोलिन के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1496: [
            WordExample(thai: "ฉันใส่เสื้อแขนยาว", romanization: "chǎn sài sʉ̂ʉa khǎen-yaao", english: "I am wearing long-sleeved shirt.", hindi: "मैं लंबी बाँह की कमीज़ पहनता हूँ।"),
            WordExample(thai: "คำว่าเสื้อแขนยาวใช้บ่อย", romanization: "kham-wâa sʉ̂ʉa khǎen-yaao chái bàwy", english: "The word for long-sleeved shirt is commonly used.", hindi: "लंबी बाँह की कमीज़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1497: [
            WordExample(thai: "ฉันใส่เสื้อแขนสั้น", romanization: "chǎn sài sʉ̂ʉa khǎen-sân", english: "I am wearing short-sleeved shirt.", hindi: "मैं छोटी बाँह की कमीज़ पहनता हूँ।"),
            WordExample(thai: "คำว่าเสื้อแขนสั้นใช้บ่อย", romanization: "kham-wâa sʉ̂ʉa khǎen-sân chái bàwy", english: "The word for short-sleeved shirt is commonly used.", hindi: "छोटी बाँह की कमीज़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1498: [
            WordExample(thai: "ฉันใส่เสื้อกันฝน", romanization: "chǎn sài sʉ̂ʉa gan-fǒn", english: "I am wearing raincoat.", hindi: "मैं बरसाती पहनता हूँ।"),
            WordExample(thai: "คำว่าเสื้อกันฝนใช้บ่อย", romanization: "kham-wâa sʉ̂ʉa gan-fǒn chái bàwy", english: "The word for raincoat is commonly used.", hindi: "बरसाती के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1499: [
            WordExample(thai: "ฉันใส่เสื้อกั๊ก", romanization: "chǎn sài sʉ̂ʉa gák", english: "I am wearing vest.", hindi: "मैं बनियान पहनता हूँ।"),
            WordExample(thai: "คำว่าเสื้อกั๊กใช้บ่อย", romanization: "kham-wâa sʉ̂ʉa gák chái bàwy", english: "The word for vest is commonly used.", hindi: "बनियान के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1500: [
            WordExample(thai: "ฉันใส่เสื้อฮู้ด", romanization: "chǎn sài sʉ̂ʉa hûut", english: "I am wearing hoodie.", hindi: "मैं हुडी पहनता हूँ।"),
            WordExample(thai: "คำว่าเสื้อฮู้ดใช้บ่อย", romanization: "kham-wâa sʉ̂ʉa hûut chái bàwy", english: "The word for hoodie is commonly used.", hindi: "हुडी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1501: [
            WordExample(thai: "ฉันใส่เสื้อกล้าม", romanization: "chǎn sài sʉ̂ʉa glâam", english: "I am wearing sleeveless shirt.", hindi: "मैं बिना बाँह की कमीज़ पहनता हूँ।"),
            WordExample(thai: "คำว่าเสื้อกล้ามใช้บ่อย", romanization: "kham-wâa sʉ̂ʉa glâam chái bàwy", english: "The word for sleeveless shirt is commonly used.", hindi: "बिना बाँह की कमीज़ के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1502: [
            WordExample(thai: "ฉันใส่กางเกงขาสั้น", romanization: "chǎn sài gaang-gaeng khǎa-sân", english: "I am wearing shorts.", hindi: "मैं निकर पहनता हूँ।"),
            WordExample(thai: "คำว่ากางเกงขาสั้นใช้บ่อย", romanization: "kham-wâa gaang-gaeng khǎa-sân chái bàwy", english: "The word for shorts is commonly used.", hindi: "निकर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1503: [
            WordExample(thai: "ฉันใส่กางเกงขายาว", romanization: "chǎn sài gaang-gaeng khǎa-yaao", english: "I am wearing long trousers.", hindi: "मैं लंबी पैंट पहनता हूँ।"),
            WordExample(thai: "คำว่ากางเกงขายาวใช้บ่อย", romanization: "kham-wâa gaang-gaeng khǎa-yaao chái bàwy", english: "The word for long trousers is commonly used.", hindi: "लंबी पैंट के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1504: [
            WordExample(thai: "ฉันใส่กางเกงยีนส์", romanization: "chǎn sài gaang-gaeng yiin", english: "I am wearing jeans.", hindi: "मैं जीन्स पहनता हूँ।"),
            WordExample(thai: "คำว่ากางเกงยีนส์ใช้บ่อย", romanization: "kham-wâa gaang-gaeng yiin chái bàwy", english: "The word for jeans is commonly used.", hindi: "जीन्स के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1505: [
            WordExample(thai: "ฉันใส่กางเกงใน", romanization: "chǎn sài gaang-gaeng nai", english: "I am wearing underwear.", hindi: "मैं अंडरवियर पहनता हूँ।"),
            WordExample(thai: "คำว่ากางเกงในใช้บ่อย", romanization: "kham-wâa gaang-gaeng nai chái bàwy", english: "The word for underwear is commonly used.", hindi: "अंडरवियर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1506: [
            WordExample(thai: "ฉันใส่ชุดนอน", romanization: "chǎn sài chút-nawn", english: "I am wearing pajamas.", hindi: "मैं रात के कपड़े पहनता हूँ।"),
            WordExample(thai: "คำว่าชุดนอนใช้บ่อย", romanization: "kham-wâa chút-nawn chái bàwy", english: "The word for pajamas is commonly used.", hindi: "रात के कपड़े के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1507: [
            WordExample(thai: "ฉันใส่ชุดกีฬา", romanization: "chǎn sài chút gii-laa", english: "I am wearing sportswear.", hindi: "मैं खेल के कपड़े पहनता हूँ।"),
            WordExample(thai: "คำว่าชุดกีฬาใช้บ่อย", romanization: "kham-wâa chút gii-laa chái bàwy", english: "The word for sportswear is commonly used.", hindi: "खेल के कपड़े के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1508: [
            WordExample(thai: "ฉันใส่ชุดนักเรียน", romanization: "chǎn sài chút nák-rian", english: "I am wearing school uniform.", hindi: "मैं स्कूल की वर्दी पहनता हूँ।"),
            WordExample(thai: "คำว่าชุดนักเรียนใช้บ่อย", romanization: "kham-wâa chút nák-rian chái bàwy", english: "The word for school uniform is commonly used.", hindi: "स्कूल की वर्दी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1509: [
            WordExample(thai: "ฉันใส่ชุดทำงาน", romanization: "chǎn sài chút tham-ngaan", english: "I am wearing work clothes.", hindi: "मैं काम के कपड़े पहनता हूँ।"),
            WordExample(thai: "คำว่าชุดทำงานใช้บ่อย", romanization: "kham-wâa chút tham-ngaan chái bàwy", english: "The word for work clothes is commonly used.", hindi: "काम के कपड़े के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1510: [
            WordExample(thai: "ฉันใส่รองเท้าผ้าใบ", romanization: "chǎn sài rawng-tháao phâa-bai", english: "I am wearing sneakers.", hindi: "मैं खेल के जूते पहनता हूँ।"),
            WordExample(thai: "คำว่ารองเท้าผ้าใบใช้บ่อย", romanization: "kham-wâa rawng-tháao phâa-bai chái bàwy", english: "The word for sneakers is commonly used.", hindi: "खेल के जूते के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1511: [
            WordExample(thai: "ฉันใส่รองเท้าหนัง", romanization: "chǎn sài rawng-tháao nǎng", english: "I am wearing leather shoes.", hindi: "मैं चमड़े के जूते पहनता हूँ।"),
            WordExample(thai: "คำว่ารองเท้าหนังใช้บ่อย", romanization: "kham-wâa rawng-tháao nǎng chái bàwy", english: "The word for leather shoes is commonly used.", hindi: "चमड़े के जूते के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1512: [
            WordExample(thai: "ฉันใส่รองเท้าแตะ", romanization: "chǎn sài rawng-tháao dtàe", english: "I am wearing sandals.", hindi: "मैं चप्पल पहनता हूँ।"),
            WordExample(thai: "คำว่ารองเท้าแตะใช้บ่อย", romanization: "kham-wâa rawng-tháao dtàe chái bàwy", english: "The word for sandals is commonly used.", hindi: "चप्पल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1513: [
            WordExample(thai: "ฉันใส่รองเท้าบูต", romanization: "chǎn sài rawng-tháao bùut", english: "I am wearing boots.", hindi: "मैं बूट पहनता हूँ।"),
            WordExample(thai: "คำว่ารองเท้าบูตใช้บ่อย", romanization: "kham-wâa rawng-tháao bùut chái bàwy", english: "The word for boots is commonly used.", hindi: "बूट के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1514: [
            WordExample(thai: "ฉันใส่ถุงมือ", romanization: "chǎn sài thǔng-mue", english: "I am wearing gloves.", hindi: "मैं दस्ताने पहनता हूँ।"),
            WordExample(thai: "คำว่าถุงมือใช้บ่อย", romanization: "kham-wâa thǔng-mue chái bàwy", english: "The word for gloves is commonly used.", hindi: "दस्ताने के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1515: [
            WordExample(thai: "ฉันใส่ผ้าพันคอ", romanization: "chǎn sài phâa-phan-khaw", english: "I am wearing scarf.", hindi: "मैं गले का दुपट्टा पहनता हूँ।"),
            WordExample(thai: "คำว่าผ้าพันคอใช้บ่อย", romanization: "kham-wâa phâa-phan-khaw chái bàwy", english: "The word for scarf is commonly used.", hindi: "गले का दुपट्टा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1516: [
            WordExample(thai: "ฉันใส่เนคไท", romanization: "chǎn sài nék-thai", english: "I am wearing necktie.", hindi: "मैं टाई पहनता हूँ।"),
            WordExample(thai: "คำว่าเนคไทใช้บ่อย", romanization: "kham-wâa nék-thai chái bàwy", english: "The word for necktie is commonly used.", hindi: "टाई के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1517: [
            WordExample(thai: "ฉันใส่หมวกแก๊ป", romanization: "chǎn sài mùak-gáep", english: "I am wearing baseball cap.", hindi: "मैं कैप पहनता हूँ।"),
            WordExample(thai: "คำว่าหมวกแก๊ปใช้บ่อย", romanization: "kham-wâa mùak-gáep chái bàwy", english: "The word for baseball cap is commonly used.", hindi: "कैप के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1518: [
            WordExample(thai: "ฉันใส่หมวกไหมพรม", romanization: "chǎn sài mùak mǎi-phrom", english: "I am wearing wool hat.", hindi: "मैं ऊन की टोपी पहनता हूँ।"),
            WordExample(thai: "คำว่าหมวกไหมพรมใช้บ่อย", romanization: "kham-wâa mùak mǎi-phrom chái bàwy", english: "The word for wool hat is commonly used.", hindi: "ऊन की टोपी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1519: [
            WordExample(thai: "ฉันใส่แว่นกันแดด", romanization: "chǎn sài wâen gan-dàet", english: "I am wearing sunglasses.", hindi: "मैं धूप का चश्मा पहनता हूँ।"),
            WordExample(thai: "คำว่าแว่นกันแดดใช้บ่อย", romanization: "kham-wâa wâen gan-dàet chái bàwy", english: "The word for sunglasses is commonly used.", hindi: "धूप का चश्मा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1520: [
            WordExample(thai: "ฉันใส่ชุดยูนิฟอร์ม", romanization: "chǎn sài chút yuu-ni-fawm", english: "I am wearing uniform.", hindi: "मैं वर्दी पहनता हूँ।"),
            WordExample(thai: "คำว่าชุดยูนิฟอร์มใช้บ่อย", romanization: "kham-wâa chút yuu-ni-fawm chái bàwy", english: "The word for uniform is commonly used.", hindi: "वर्दी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1521: [
            WordExample(thai: "ฉันชอบสีกรมท่า", romanization: "chǎn châwp sǐi grom-thâa", english: "I like navy blue.", hindi: "मुझे गहरा नीला पसंद है।"),
            WordExample(thai: "คำว่าสีกรมท่าใช้บ่อย", romanization: "kham-wâa sǐi grom-thâa chái bàwy", english: "The word for navy blue is commonly used.", hindi: "गहरा नीला के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1522: [
            WordExample(thai: "ฉันชอบสีเบจ", romanization: "chǎn châwp sǐi bèet", english: "I like beige.", hindi: "मुझे बेज पसंद है।"),
            WordExample(thai: "คำว่าสีเบจใช้บ่อย", romanization: "kham-wâa sǐi bèet chái bàwy", english: "The word for beige is commonly used.", hindi: "बेज के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1523: [
            WordExample(thai: "ฉันชอบสีทอง", romanization: "chǎn châwp sǐi-thaawng", english: "I like gold.", hindi: "मुझे सुनहरा पसंद है।"),
            WordExample(thai: "คำว่าสีทองใช้บ่อย", romanization: "kham-wâa sǐi-thaawng chái bàwy", english: "The word for gold is commonly used.", hindi: "सुनहरा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1524: [
            WordExample(thai: "ฉันชอบสีเงิน", romanization: "chǎn châwp sǐi-ngoen", english: "I like silver.", hindi: "मुझे चाँदी रंग पसंद है।"),
            WordExample(thai: "คำว่าสีเงินใช้บ่อย", romanization: "kham-wâa sǐi-ngoen chái bàwy", english: "The word for silver is commonly used.", hindi: "चाँदी रंग के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1525: [
            WordExample(thai: "ฉันชอบสีครีม", romanization: "chǎn châwp sǐi khriim", english: "I like cream.", hindi: "मुझे क्रीम रंग पसंद है।"),
            WordExample(thai: "คำว่าสีครีมใช้บ่อย", romanization: "kham-wâa sǐi khriim chái bàwy", english: "The word for cream is commonly used.", hindi: "क्रीम रंग के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1526: [
            WordExample(thai: "ฉันชอบสีแดงเข้ม", romanization: "chǎn châwp sǐi daeng-khêm", english: "I like dark red.", hindi: "मुझे गहरा लाल पसंद है।"),
            WordExample(thai: "คำว่าสีแดงเข้มใช้บ่อย", romanization: "kham-wâa sǐi daeng-khêm chái bàwy", english: "The word for dark red is commonly used.", hindi: "गहरा लाल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1527: [
            WordExample(thai: "ฉันชอบสีแดงอ่อน", romanization: "chǎn châwp sǐi daeng-àawn", english: "I like light red.", hindi: "मुझे हल्का लाल पसंद है।"),
            WordExample(thai: "คำว่าสีแดงอ่อนใช้บ่อย", romanization: "kham-wâa sǐi daeng-àawn chái bàwy", english: "The word for light red is commonly used.", hindi: "हल्का लाल के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1528: [
            WordExample(thai: "ฉันชอบสีเขียวเข้ม", romanization: "chǎn châwp sǐi khǐao-khêm", english: "I like dark green.", hindi: "मुझे गहरा हरा पसंद है।"),
            WordExample(thai: "คำว่าสีเขียวเข้มใช้บ่อย", romanization: "kham-wâa sǐi khǐao-khêm chái bàwy", english: "The word for dark green is commonly used.", hindi: "गहरा हरा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1529: [
            WordExample(thai: "ฉันชอบสีเขียวอ่อน", romanization: "chǎn châwp sǐi khǐao-àawn", english: "I like light green.", hindi: "मुझे हल्का हरा पसंद है।"),
            WordExample(thai: "คำว่าสีเขียวอ่อนใช้บ่อย", romanization: "kham-wâa sǐi khǐao-àawn chái bàwy", english: "The word for light green is commonly used.", hindi: "हल्का हरा के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1530: [
            WordExample(thai: "ฉันชอบสีฟ้าเข้ม", romanization: "chǎn châwp sǐi fáa-khêm", english: "I like dark sky blue.", hindi: "मुझे गहरा आसमानी पसंद है।"),
            WordExample(thai: "คำว่าสีฟ้าเข้มใช้บ่อย", romanization: "kham-wâa sǐi fáa-khêm chái bàwy", english: "The word for dark sky blue is commonly used.", hindi: "गहरा आसमानी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1531: [
            WordExample(thai: "ฉันชอบสีฟ้าอ่อน", romanization: "chǎn châwp sǐi fáa-àawn", english: "I like light sky blue.", hindi: "मुझे हल्का आसमानी पसंद है।"),
            WordExample(thai: "คำว่าสีฟ้าอ่อนใช้บ่อย", romanization: "kham-wâa sǐi fáa-àawn chái bàwy", english: "The word for light sky blue is commonly used.", hindi: "हल्का आसमानी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1532: [
            WordExample(thai: "ฉันชอบสีม่วงเข้ม", romanization: "chǎn châwp sǐi mûang-khêm", english: "I like dark purple.", hindi: "मुझे गहरा बैंगनी पसंद है।"),
            WordExample(thai: "คำว่าสีม่วงเข้มใช้บ่อย", romanization: "kham-wâa sǐi mûang-khêm chái bàwy", english: "The word for dark purple is commonly used.", hindi: "गहरा बैंगनी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1533: [
            WordExample(thai: "ฉันชอบสีม่วงอ่อน", romanization: "chǎn châwp sǐi mûang-àawn", english: "I like light purple.", hindi: "मुझे हल्का बैंगनी पसंद है।"),
            WordExample(thai: "คำว่าสีม่วงอ่อนใช้บ่อย", romanization: "kham-wâa sǐi mûang-àawn chái bàwy", english: "The word for light purple is commonly used.", hindi: "हल्का बैंगनी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1534: [
            WordExample(thai: "ฉันชอบสีน้ำเงินเข้ม", romanization: "chǎn châwp sǐi náam-ngoen-khêm", english: "I like dark blue.", hindi: "मुझे गहरा नीला पसंद है।"),
            WordExample(thai: "คำว่าสีน้ำเงินเข้มใช้บ่อย", romanization: "kham-wâa sǐi náam-ngoen-khêm chái bàwy", english: "The word for dark blue is commonly used.", hindi: "गहरा नीला के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1535: [
            WordExample(thai: "ฉันชอบสีน้ำเงินอ่อน", romanization: "chǎn châwp sǐi náam-ngoen-àawn", english: "I like light blue.", hindi: "मुझे हल्का नीला पसंद है।"),
            WordExample(thai: "คำว่าสีน้ำเงินอ่อนใช้บ่อย", romanization: "kham-wâa sǐi náam-ngoen-àawn chái bàwy", english: "The word for light blue is commonly used.", hindi: "हल्का नीला के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1536: [
            WordExample(thai: "ฉันชอบสีส้มเข้ม", romanization: "chǎn châwp sǐi sôm-khêm", english: "I like dark orange.", hindi: "मुझे गहरा नारंगी पसंद है।"),
            WordExample(thai: "คำว่าสีส้มเข้มใช้บ่อย", romanization: "kham-wâa sǐi sôm-khêm chái bàwy", english: "The word for dark orange is commonly used.", hindi: "गहरा नारंगी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1537: [
            WordExample(thai: "ฉันชอบสีเหลืองอ่อน", romanization: "chǎn châwp sǐi lʉ̌ʉang-àawn", english: "I like light yellow.", hindi: "मुझे हल्का पीला पसंद है।"),
            WordExample(thai: "คำว่าสีเหลืองอ่อนใช้บ่อย", romanization: "kham-wâa sǐi lʉ̌ʉang-àawn chái bàwy", english: "The word for light yellow is commonly used.", hindi: "हल्का पीला के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1538: [
            WordExample(thai: "ฉันชอบสีเหลืองเข้ม", romanization: "chǎn châwp sǐi lʉ̌ʉang-khêm", english: "I like dark yellow.", hindi: "मुझे गहरा पीला पसंद है।"),
            WordExample(thai: "คำว่าสีเหลืองเข้มใช้บ่อย", romanization: "kham-wâa sǐi lʉ̌ʉang-khêm chái bàwy", english: "The word for dark yellow is commonly used.", hindi: "गहरा पीला के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1539: [
            WordExample(thai: "ฉันชอบสีชมพูอ่อน", romanization: "chǎn châwp sǐi chom-phuu-àawn", english: "I like light pink.", hindi: "मुझे हल्का गुलाबी पसंद है।"),
            WordExample(thai: "คำว่าสีชมพูอ่อนใช้บ่อย", romanization: "kham-wâa sǐi chom-phuu-àawn chái bàwy", english: "The word for light pink is commonly used.", hindi: "हल्का गुलाबी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1540: [
            WordExample(thai: "ฉันชอบสีชมพูเข้ม", romanization: "chǎn châwp sǐi chom-phuu-khêm", english: "I like dark pink.", hindi: "मुझे गहरा गुलाबी पसंद है।"),
            WordExample(thai: "คำว่าสีชมพูเข้มใช้บ่อย", romanization: "kham-wâa sǐi chom-phuu-khêm chái bàwy", english: "The word for dark pink is commonly used.", hindi: "गहरा गुलाबी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1541: [
            WordExample(thai: "ฉันชอบสีดำสนิท", romanization: "chǎn châwp sǐi dam-sà-nìt", english: "I like jet black.", hindi: "मुझे गहरा काला पसंद है।"),
            WordExample(thai: "คำว่าสีดำสนิทใช้บ่อย", romanization: "kham-wâa sǐi dam-sà-nìt chái bàwy", english: "The word for jet black is commonly used.", hindi: "गहरा काला के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1542: [
            WordExample(thai: "ฉันชอบสีขาวนวล", romanization: "chǎn châwp sǐi khǎao-nuan", english: "I like ivory white.", hindi: "मुझे हाथीदांत सफ़ेद पसंद है।"),
            WordExample(thai: "คำว่าสีขาวนวลใช้บ่อย", romanization: "kham-wâa sǐi khǎao-nuan chái bàwy", english: "The word for ivory white is commonly used.", hindi: "हाथीदांत सफ़ेद के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1543: [
            WordExample(thai: "ฉันชอบสีเทาเข้ม", romanization: "chǎn châwp sǐi thao-khêm", english: "I like dark gray.", hindi: "मुझे गहरा धूसर पसंद है।"),
            WordExample(thai: "คำว่าสีเทาเข้มใช้บ่อย", romanization: "kham-wâa sǐi thao-khêm chái bàwy", english: "The word for dark gray is commonly used.", hindi: "गहरा धूसर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1544: [
            WordExample(thai: "ฉันชอบสีเทาอ่อน", romanization: "chǎn châwp sǐi thao-àawn", english: "I like light gray.", hindi: "मुझे हल्का धूसर पसंद है।"),
            WordExample(thai: "คำว่าสีเทาอ่อนใช้บ่อย", romanization: "kham-wâa sǐi thao-àawn chái bàwy", english: "The word for light gray is commonly used.", hindi: "हल्का धूसर के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1545: [
            WordExample(thai: "ฉันชอบสีรุ้ง", romanization: "chǎn châwp sǐi-rúng", english: "I like rainbow-colored.", hindi: "मुझे इंद्रधनुषी पसंद है।"),
            WordExample(thai: "คำว่าสีรุ้งใช้บ่อย", romanization: "kham-wâa sǐi-rúng chái bàwy", english: "The word for rainbow-colored is commonly used.", hindi: "इंद्रधनुषी के लिए शब्द अक्सर इस्तेमाल होता है।"),
        ],
        1546: [
            WordExample(thai: "ฉันชอบข้าวเหนียวหมูปิ้ง", romanization: "chǎn chɔ̂ɔp khâao nǐao mǔu pîng", english: "I like grilled pork with sticky rice.", hindi: "मुझे चिपचिपे चावल के साथ ग्रिल किया सूअर का मांस पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวเหนียวหมูปิ้ง", romanization: "wan-níi chǎn gin khâao nǐao mǔu pîng", english: "Today I am having grilled pork with sticky rice.", hindi: "आज मैं चिपचिपे चावल के साथ ग्रिल किया सूअर का मांस खा या पी रहा हूँ।"),
        ],
        1547: [
            WordExample(thai: "ฉันชอบข้าวหมกไก่", romanization: "chǎn chɔ̂ɔp khâao mòk kài", english: "I like Thai Muslim chicken biryani.", hindi: "मुझे थाई मुस्लिम चिकन बिरयानी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวหมกไก่", romanization: "wan-níi chǎn gin khâao mòk kài", english: "Today I am having Thai Muslim chicken biryani.", hindi: "आज मैं थाई मुस्लिम चिकन बिरयानी खा या पी रहा हूँ।"),
        ],
        1548: [
            WordExample(thai: "ฉันชอบข้าวคลุกกะปิ", romanization: "chǎn chɔ̂ɔp khâao khlúk kà-pì", english: "I like rice mixed with shrimp paste.", hindi: "मुझे झींगा पेस्ट के साथ मिला चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวคลุกกะปิ", romanization: "wan-níi chǎn gin khâao khlúk kà-pì", english: "Today I am having rice mixed with shrimp paste.", hindi: "आज मैं झींगा पेस्ट के साथ मिला चावल खा या पी रहा हूँ।"),
        ],
        1549: [
            WordExample(thai: "ฉันชอบข้าวแช่", romanization: "chǎn chɔ̂ɔp khâao châe", english: "I like rice soaked in jasmine-scented water.", hindi: "मुझे चमेली-सुगंधित पानी में भिगोया चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวแช่", romanization: "wan-níi chǎn gin khâao châe", english: "Today I am having rice soaked in jasmine-scented water.", hindi: "आज मैं चमेली-सुगंधित पानी में भिगोया चावल खा या पी रहा हूँ।"),
        ],
        1550: [
            WordExample(thai: "ฉันชอบข้าวยำ", romanization: "chǎn chɔ̂ɔp khâao yam", english: "I like southern Thai herb rice salad.", hindi: "मुझे दक्षिणी थाई जड़ी-बूटी चावल सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวยำ", romanization: "wan-níi chǎn gin khâao yam", english: "Today I am having southern Thai herb rice salad.", hindi: "आज मैं दक्षिणी थाई जड़ी-बूटी चावल सलाद खा या पी रहा हूँ।"),
        ],
        1551: [
            WordExample(thai: "ฉันชอบข้าวหน้าเป็ด", romanization: "chǎn chɔ̂ɔp khâao nâa pèt", english: "I like rice topped with roasted duck.", hindi: "मुझे भुने बतख के साथ चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวหน้าเป็ด", romanization: "wan-níi chǎn gin khâao nâa pèt", english: "Today I am having rice topped with roasted duck.", hindi: "आज मैं भुने बतख के साथ चावल खा या पी रहा हूँ।"),
        ],
        1552: [
            WordExample(thai: "ฉันชอบข้าวหมูกรอบ", romanization: "chǎn chɔ̂ɔp khâao mǔu krɔ̀ɔp", english: "I like rice with crispy pork belly.", hindi: "मुझे कुरकुरी पोर्क बेली के साथ चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวหมูกรอบ", romanization: "wan-níi chǎn gin khâao mǔu krɔ̀ɔp", english: "Today I am having rice with crispy pork belly.", hindi: "आज मैं कुरकुरी पोर्क बेली के साथ चावल खा या पी रहा हूँ।"),
        ],
        1553: [
            WordExample(thai: "ฉันชอบข้าวหน้าไก่", romanization: "chǎn chɔ̂ɔp khâao nâa kài", english: "I like rice with braised chicken topping.", hindi: "मुझे दम किए चिकन की टॉपिंग वाला चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวหน้าไก่", romanization: "wan-níi chǎn gin khâao nâa kài", english: "Today I am having rice with braised chicken topping.", hindi: "आज मैं दम किए चिकन की टॉपिंग वाला चावल खा या पी रहा हूँ।"),
        ],
        1554: [
            WordExample(thai: "ฉันชอบข้าวต้มปลา", romanization: "chǎn chɔ̂ɔp khâao tôm plaa", english: "I like rice soup with fish.", hindi: "मुझे मछली वाला चावल का सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวต้มปลา", romanization: "wan-níi chǎn gin khâao tôm plaa", english: "Today I am having rice soup with fish.", hindi: "आज मैं मछली वाला चावल का सूप खा या पी रहा हूँ।"),
        ],
        1555: [
            WordExample(thai: "ฉันชอบข้าวต้มกุ้ง", romanization: "chǎn chɔ̂ɔp khâao tôm kûng", english: "I like rice soup with shrimp.", hindi: "मुझे झींगे वाला चावल का सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวต้มกุ้ง", romanization: "wan-níi chǎn gin khâao tôm kûng", english: "Today I am having rice soup with shrimp.", hindi: "आज मैं झींगे वाला चावल का सूप खा या पी रहा हूँ।"),
        ],
        1556: [
            WordExample(thai: "ฉันชอบข้าวผัดปู", romanization: "chǎn chɔ̂ɔp khâao phàt puu", english: "I like crab fried rice.", hindi: "मुझे केकड़े वाला तला चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวผัดปู", romanization: "wan-níi chǎn gin khâao phàt puu", english: "Today I am having crab fried rice.", hindi: "आज मैं केकड़े वाला तला चावल खा या पी रहा हूँ।"),
        ],
        1557: [
            WordExample(thai: "ฉันชอบข้าวผัดกุ้ง", romanization: "chǎn chɔ̂ɔp khâao phàt kûng", english: "I like shrimp fried rice.", hindi: "मुझे झींगे वाला तला चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวผัดกุ้ง", romanization: "wan-níi chǎn gin khâao phàt kûng", english: "Today I am having shrimp fried rice.", hindi: "आज मैं झींगे वाला तला चावल खा या पी रहा हूँ।"),
        ],
        1558: [
            WordExample(thai: "ฉันชอบข้าวผัดหมู", romanization: "chǎn chɔ̂ɔp khâao phàt mǔu", english: "I like pork fried rice.", hindi: "मुझे पोर्क वाला तला चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวผัดหมู", romanization: "wan-níi chǎn gin khâao phàt mǔu", english: "Today I am having pork fried rice.", hindi: "आज मैं पोर्क वाला तला चावल खा या पी रहा हूँ।"),
        ],
        1559: [
            WordExample(thai: "ฉันชอบข้าวผัดอเมริกัน", romanization: "chǎn chɔ̂ɔp khâao phàt a-mee-rí-gan", english: "I like American-style Thai fried rice.", hindi: "मुझे अमेरिकी शैली का थाई तला चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวผัดอเมริกัน", romanization: "wan-níi chǎn gin khâao phàt a-mee-rí-gan", english: "Today I am having American-style Thai fried rice.", hindi: "आज मैं अमेरिकी शैली का थाई तला चावल खा या पी रहा हूँ।"),
        ],
        1560: [
            WordExample(thai: "ฉันชอบข้าวไข่ข้น", romanization: "chǎn chɔ̂ɔp khâao khài khôn", english: "I like rice with creamy soft omelet.", hindi: "मुझे मुलायम मलाईदार ऑमलेट के साथ चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวไข่ข้น", romanization: "wan-níi chǎn gin khâao khài khôn", english: "Today I am having rice with creamy soft omelet.", hindi: "आज मैं मुलायम मलाईदार ऑमलेट के साथ चावल खा या पी रहा हूँ।"),
        ],
        1561: [
            WordExample(thai: "ฉันชอบข้าวแกงกะหรี่", romanization: "chǎn chɔ̂ɔp khâao gaeng gà-rìi", english: "I like rice with Thai curry.", hindi: "मुझे थाई करी के साथ चावल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวแกงกะหรี่", romanization: "wan-níi chǎn gin khâao gaeng gà-rìi", english: "Today I am having rice with Thai curry.", hindi: "आज मैं थाई करी के साथ चावल खा या पी रहा हूँ।"),
        ],
        1562: [
            WordExample(thai: "ฉันชอบโจ๊กหมู", romanization: "chǎn chɔ̂ɔp jóok mǔu", english: "I like rice porridge with minced pork.", hindi: "मुझे कीमा पोर्क वाला चावल दलिया पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินโจ๊กหมู", romanization: "wan-níi chǎn gin jóok mǔu", english: "Today I am having rice porridge with minced pork.", hindi: "आज मैं कीमा पोर्क वाला चावल दलिया खा या पी रहा हूँ।"),
        ],
        1563: [
            WordExample(thai: "ฉันชอบโจ๊กไก่", romanization: "chǎn chɔ̂ɔp jóok kài", english: "I like rice porridge with chicken.", hindi: "मुझे चिकन वाला चावल दलिया पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินโจ๊กไก่", romanization: "wan-níi chǎn gin jóok kài", english: "Today I am having rice porridge with chicken.", hindi: "आज मैं चिकन वाला चावल दलिया खा या पी रहा हूँ।"),
        ],
        1564: [
            WordExample(thai: "ฉันชอบขนมจีนน้ำยา", romanization: "chǎn chɔ̂ɔp khà-nǒm jiin náam yaa", english: "I like rice noodles with fish curry sauce.", hindi: "मुझे मछली करी सॉस वाले चावल नूडल्स पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินขนมจีนน้ำยา", romanization: "wan-níi chǎn gin khà-nǒm jiin náam yaa", english: "Today I am having rice noodles with fish curry sauce.", hindi: "आज मैं मछली करी सॉस वाले चावल नूडल्स खा या पी रहा हूँ।"),
        ],
        1565: [
            WordExample(thai: "ฉันชอบขนมจีนน้ำเงี้ยว", romanization: "chǎn chɔ̂ɔp khà-nǒm jiin náam ngíao", english: "I like northern rice noodles in pork-tomato broth.", hindi: "मुझे पोर्क-टमाटर शोरबे वाले उत्तरी चावल नूडल्स पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินขนมจีนน้ำเงี้ยว", romanization: "wan-níi chǎn gin khà-nǒm jiin náam ngíao", english: "Today I am having northern rice noodles in pork-tomato broth.", hindi: "आज मैं पोर्क-टमाटर शोरबे वाले उत्तरी चावल नूडल्स खा या पी रहा हूँ।"),
        ],
        1566: [
            WordExample(thai: "ฉันชอบขนมจีนน้ำพริก", romanization: "chǎn chɔ̂ɔp khà-nǒm jiin náam phrík", english: "I like rice noodles with peanut curry sauce.", hindi: "मुझे मूंगफली करी सॉस वाले चावल नूडल्स पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินขนมจีนน้ำพริก", romanization: "wan-níi chǎn gin khà-nǒm jiin náam phrík", english: "Today I am having rice noodles with peanut curry sauce.", hindi: "आज मैं मूंगफली करी सॉस वाले चावल नूडल्स खा या पी रहा हूँ।"),
        ],
        1567: [
            WordExample(thai: "ฉันชอบก๋วยเตี๋ยวต้มยำ", romanization: "chǎn chɔ̂ɔp gǔai-dtǐao tôm yam", english: "I like tom yum noodle soup.", hindi: "मुझे तोम याम नूडल सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินก๋วยเตี๋ยวต้มยำ", romanization: "wan-níi chǎn gin gǔai-dtǐao tôm yam", english: "Today I am having tom yum noodle soup.", hindi: "आज मैं तोम याम नूडल सूप खा या पी रहा हूँ।"),
        ],
        1568: [
            WordExample(thai: "ฉันชอบก๋วยเตี๋ยวคั่วไก่", romanization: "chǎn chɔ̂ɔp gǔai-dtǐao khûa kài", english: "I like stir-fried flat noodles with chicken.", hindi: "मुझे चिकन के साथ तले चौड़े नूडल्स पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินก๋วยเตี๋ยวคั่วไก่", romanization: "wan-níi chǎn gin gǔai-dtǐao khûa kài", english: "Today I am having stir-fried flat noodles with chicken.", hindi: "आज मैं चिकन के साथ तले चौड़े नूडल्स खा या पी रहा हूँ।"),
        ],
        1569: [
            WordExample(thai: "ฉันชอบก๋วยเตี๋ยวหลอด", romanization: "chǎn chɔ̂ɔp gǔai-dtǐao lɔ̀ɔt", english: "I like steamed rice-noodle rolls.", hindi: "मुझे भाप में बने चावल नूडल रोल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินก๋วยเตี๋ยวหลอด", romanization: "wan-níi chǎn gin gǔai-dtǐao lɔ̀ɔt", english: "Today I am having steamed rice-noodle rolls.", hindi: "आज मैं भाप में बने चावल नूडल रोल खा या पी रहा हूँ।"),
        ],
        1570: [
            WordExample(thai: "ฉันชอบเย็นตาโฟ", romanization: "chǎn chɔ̂ɔp yen dtaa-foh", english: "I like pink fermented-bean-curd noodle soup.", hindi: "मुझे गुलाबी फर्मेंटेड बीन कर्ड नूडल सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินเย็นตาโฟ", romanization: "wan-níi chǎn gin yen dtaa-foh", english: "Today I am having pink fermented-bean-curd noodle soup.", hindi: "आज मैं गुलाबी फर्मेंटेड बीन कर्ड नूडल सूप खा या पी रहा हूँ।"),
        ],
        1571: [
            WordExample(thai: "ฉันชอบราดหน้าหมี่กรอบ", romanization: "chǎn chɔ̂ɔp râat nâa mii krɔ̀ɔp", english: "I like crispy noodles with gravy.", hindi: "मुझे ग्रेवी के साथ कुरकुरे नूडल्स पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินราดหน้าหมี่กรอบ", romanization: "wan-níi chǎn gin râat nâa mii krɔ̀ɔp", english: "Today I am having crispy noodles with gravy.", hindi: "आज मैं ग्रेवी के साथ कुरकुरे नूडल्स खा या पी रहा हूँ।"),
        ],
        1572: [
            WordExample(thai: "ฉันชอบสุกี้น้ำ", romanization: "chǎn chɔ̂ɔp sù-gîi náam", english: "I like Thai sukiyaki noodle soup.", hindi: "मुझे थाई सुकीयाकी नूडल सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินสุกี้น้ำ", romanization: "wan-níi chǎn gin sù-gîi náam", english: "Today I am having Thai sukiyaki noodle soup.", hindi: "आज मैं थाई सुकीयाकी नूडल सूप खा या पी रहा हूँ।"),
        ],
        1573: [
            WordExample(thai: "ฉันชอบสุกี้แห้ง", romanization: "chǎn chɔ̂ɔp sù-gîi hâeng", english: "I like dry Thai sukiyaki noodles.", hindi: "मुझे सूखे थाई सुकीयाकी नूडल्स पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินสุกี้แห้ง", romanization: "wan-níi chǎn gin sù-gîi hâeng", english: "Today I am having dry Thai sukiyaki noodles.", hindi: "आज मैं सूखे थाई सुकीयाकी नूडल्स खा या पी रहा हूँ।"),
        ],
        1574: [
            WordExample(thai: "ฉันชอบข้าวซอยไก่", romanization: "chǎn chɔ̂ɔp khâao sɔɔi kài", english: "I like northern curry noodles with chicken.", hindi: "मुझे चिकन वाले उत्तरी करी नूडल्स पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินข้าวซอยไก่", romanization: "wan-níi chǎn gin khâao sɔɔi kài", english: "Today I am having northern curry noodles with chicken.", hindi: "आज मैं चिकन वाले उत्तरी करी नूडल्स खा या पी रहा हूँ।"),
        ],
        1575: [
            WordExample(thai: "ฉันชอบขนมปังหน้าหมู", romanization: "chǎn chɔ̂ɔp khà-nǒm pang nâa mǔu", english: "I like fried bread with minced pork topping.", hindi: "मुझे कीमा पोर्क टॉपिंग वाली तली ब्रेड पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินขนมปังหน้าหมู", romanization: "wan-níi chǎn gin khà-nǒm pang nâa mǔu", english: "Today I am having fried bread with minced pork topping.", hindi: "आज मैं कीमा पोर्क टॉपिंग वाली तली ब्रेड खा या पी रहा हूँ।"),
        ],
        1576: [
            WordExample(thai: "ฉันชอบหมูสะเต๊ะ", romanization: "chǎn chɔ̂ɔp mǔu sà-dté", english: "I like grilled pork satay skewers.", hindi: "मुझे ग्रिल किए पोर्क साते सीख पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินหมูสะเต๊ะ", romanization: "wan-níi chǎn gin mǔu sà-dté", english: "Today I am having grilled pork satay skewers.", hindi: "आज मैं ग्रिल किए पोर्क साते सीख खा या पी रहा हूँ।"),
        ],
        1577: [
            WordExample(thai: "ฉันชอบไก่สะเต๊ะ", romanization: "chǎn chɔ̂ɔp kài sà-dté", english: "I like grilled chicken satay skewers.", hindi: "मुझे ग्रिल किए चिकन साते सीख पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินไก่สะเต๊ะ", romanization: "wan-níi chǎn gin kài sà-dté", english: "Today I am having grilled chicken satay skewers.", hindi: "आज मैं ग्रिल किए चिकन साते सीख खा या पी रहा हूँ।"),
        ],
        1578: [
            WordExample(thai: "ฉันชอบไก่ทอดหาดใหญ่", romanization: "chǎn chɔ̂ɔp kài thɔ̂ɔt hàat yài", english: "I like Hat Yai-style fried chicken.", hindi: "मुझे हाट याइ शैली का तला चिकन पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินไก่ทอดหาดใหญ่", romanization: "wan-níi chǎn gin kài thɔ̂ɔt hàat yài", english: "Today I am having Hat Yai-style fried chicken.", hindi: "आज मैं हाट याइ शैली का तला चिकन खा या पी रहा हूँ।"),
        ],
        1579: [
            WordExample(thai: "ฉันชอบคอหมูย่าง", romanization: "chǎn chɔ̂ɔp khɔɔ mǔu yâang", english: "I like grilled pork neck.", hindi: "मुझे ग्रिल किया पोर्क नेक पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินคอหมูย่าง", romanization: "wan-níi chǎn gin khɔɔ mǔu yâang", english: "Today I am having grilled pork neck.", hindi: "आज मैं ग्रिल किया पोर्क नेक खा या पी रहा हूँ।"),
        ],
        1580: [
            WordExample(thai: "ฉันชอบหมูแดดเดียว", romanization: "chǎn chɔ̂ɔp mǔu dàet diao", english: "I like sun-dried fried pork.", hindi: "मुझे धूप में सुखाया तला पोर्क पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินหมูแดดเดียว", romanization: "wan-níi chǎn gin mǔu dàet diao", english: "Today I am having sun-dried fried pork.", hindi: "आज मैं धूप में सुखाया तला पोर्क खा या पी रहा हूँ।"),
        ],
        1581: [
            WordExample(thai: "ฉันชอบเนื้อแดดเดียว", romanization: "chǎn chɔ̂ɔp nʉ́a dàet diao", english: "I like sun-dried fried beef.", hindi: "मुझे धूप में सुखाया तला बीफ पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินเนื้อแดดเดียว", romanization: "wan-níi chǎn gin nʉ́a dàet diao", english: "Today I am having sun-dried fried beef.", hindi: "आज मैं धूप में सुखाया तला बीफ खा या पी रहा हूँ।"),
        ],
        1582: [
            WordExample(thai: "ฉันชอบลาบหมู", romanization: "chǎn chɔ̂ɔp lâap mǔu", english: "I like spicy minced pork salad.", hindi: "मुझे मसालेदार कीमा पोर्क सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินลาบหมู", romanization: "wan-níi chǎn gin lâap mǔu", english: "Today I am having spicy minced pork salad.", hindi: "आज मैं मसालेदार कीमा पोर्क सलाद खा या पी रहा हूँ।"),
        ],
        1583: [
            WordExample(thai: "ฉันชอบลาบไก่", romanization: "chǎn chɔ̂ɔp lâap kài", english: "I like spicy minced chicken salad.", hindi: "मुझे मसालेदार कीमा चिकन सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินลาบไก่", romanization: "wan-níi chǎn gin lâap kài", english: "Today I am having spicy minced chicken salad.", hindi: "आज मैं मसालेदार कीमा चिकन सलाद खा या पी रहा हूँ।"),
        ],
        1584: [
            WordExample(thai: "ฉันชอบน้ำตกหมู", romanization: "chǎn chɔ̂ɔp náam dtòk mǔu", english: "I like spicy grilled pork salad.", hindi: "मुझे मसालेदार ग्रिल्ड पोर्क सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำตกหมู", romanization: "wan-níi chǎn gin náam dtòk mǔu", english: "Today I am having spicy grilled pork salad.", hindi: "आज मैं मसालेदार ग्रिल्ड पोर्क सलाद खा या पी रहा हूँ।"),
        ],
        1585: [
            WordExample(thai: "ฉันชอบยำวุ้นเส้น", romanization: "chǎn chɔ̂ɔp yam wún-sên", english: "I like spicy glass-noodle salad.", hindi: "मुझे मसालेदार ग्लास नूडल सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินยำวุ้นเส้น", romanization: "wan-níi chǎn gin yam wún-sên", english: "Today I am having spicy glass-noodle salad.", hindi: "आज मैं मसालेदार ग्लास नूडल सलाद खा या पी रहा हूँ।"),
        ],
        1586: [
            WordExample(thai: "ฉันชอบยำมะม่วง", romanization: "chǎn chɔ̂ɔp yam má-mûang", english: "I like spicy green mango salad.", hindi: "मुझे मसालेदार कच्चे आम का सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินยำมะม่วง", romanization: "wan-níi chǎn gin yam má-mûang", english: "Today I am having spicy green mango salad.", hindi: "आज मैं मसालेदार कच्चे आम का सलाद खा या पी रहा हूँ।"),
        ],
        1587: [
            WordExample(thai: "ฉันชอบยำไข่ดาว", romanization: "chǎn chɔ̂ɔp yam khài daao", english: "I like spicy fried-egg salad.", hindi: "मुझे मसालेदार तले अंडे का सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินยำไข่ดาว", romanization: "wan-níi chǎn gin yam khài daao", english: "Today I am having spicy fried-egg salad.", hindi: "आज मैं मसालेदार तले अंडे का सलाद खा या पी रहा हूँ।"),
        ],
        1588: [
            WordExample(thai: "ฉันชอบยำปลากระป๋อง", romanization: "chǎn chɔ̂ɔp yam plaa grà-pɔ̌ɔng", english: "I like spicy canned-fish salad.", hindi: "मुझे मसालेदार डिब्बाबंद मछली सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินยำปลากระป๋อง", romanization: "wan-níi chǎn gin yam plaa grà-pɔ̌ɔng", english: "Today I am having spicy canned-fish salad.", hindi: "आज मैं मसालेदार डिब्बाबंद मछली सलाद खा या पी रहा हूँ।"),
        ],
        1589: [
            WordExample(thai: "ฉันชอบตำแตง", romanization: "chǎn chɔ̂ɔp dtam dtàeng", english: "I like spicy cucumber salad.", hindi: "मुझे मसालेदार खीरे का सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินตำแตง", romanization: "wan-níi chǎn gin dtam dtàeng", english: "Today I am having spicy cucumber salad.", hindi: "आज मैं मसालेदार खीरे का सलाद खा या पी रहा हूँ।"),
        ],
        1590: [
            WordExample(thai: "ฉันชอบตำไทย", romanization: "chǎn chɔ̂ɔp dtam thai", english: "I like Thai-style papaya salad with peanuts.", hindi: "मुझे मूंगफली वाला थाई पपीता सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินตำไทย", romanization: "wan-níi chǎn gin dtam thai", english: "Today I am having Thai-style papaya salad with peanuts.", hindi: "आज मैं मूंगफली वाला थाई पपीता सलाद खा या पी रहा हूँ।"),
        ],
        1591: [
            WordExample(thai: "ฉันชอบตำปูปลาร้า", romanization: "chǎn chɔ̂ɔp dtam puu plaa-ráa", english: "I like papaya salad with crab and fermented fish.", hindi: "मुझे केकड़े और फर्मेंटेड मछली वाला पपीता सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินตำปูปลาร้า", romanization: "wan-níi chǎn gin dtam puu plaa-ráa", english: "Today I am having papaya salad with crab and fermented fish.", hindi: "आज मैं केकड़े और फर्मेंटेड मछली वाला पपीता सलाद खा या पी रहा हूँ।"),
        ],
        1592: [
            WordExample(thai: "ฉันชอบตำข้าวโพด", romanization: "chǎn chɔ̂ɔp dtam khâao phôot", english: "I like spicy corn salad.", hindi: "मुझे मसालेदार मकई सलाद पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินตำข้าวโพด", romanization: "wan-níi chǎn gin dtam khâao phôot", english: "Today I am having spicy corn salad.", hindi: "आज मैं मसालेदार मकई सलाद खा या पी रहा हूँ।"),
        ],
        1593: [
            WordExample(thai: "ฉันชอบแกงมัสมั่น", romanization: "chǎn chɔ̂ɔp gaeng mát-sà-màn", english: "I like rich Muslim-style Massaman curry.", hindi: "मुझे गाढ़ी मुस्लिम शैली की मस्समन करी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงมัสมั่น", romanization: "wan-níi chǎn gin gaeng mát-sà-màn", english: "Today I am having rich Muslim-style Massaman curry.", hindi: "आज मैं गाढ़ी मुस्लिम शैली की मस्समन करी खा या पी रहा हूँ।"),
        ],
        1594: [
            WordExample(thai: "ฉันชอบแกงพะแนง", romanization: "chǎn chɔ̂ɔp gaeng phá-naeng", english: "I like thick peanut curry.", hindi: "मुझे गाढ़ी मूंगफली करी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงพะแนง", romanization: "wan-níi chǎn gin gaeng phá-naeng", english: "Today I am having thick peanut curry.", hindi: "आज मैं गाढ़ी मूंगफली करी खा या पी रहा हूँ।"),
        ],
        1595: [
            WordExample(thai: "ฉันชอบแกงจืดเต้าหู้หมูสับ", romanization: "chǎn chɔ̂ɔp gaeng jʉ̀ʉt dtâo-hûu mǔu sàp", english: "I like clear soup with tofu and minced pork.", hindi: "मुझे टोफू और कीमा पोर्क का साफ सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงจืดเต้าหู้หมูสับ", romanization: "wan-níi chǎn gin gaeng jʉ̀ʉt dtâo-hûu mǔu sàp", english: "Today I am having clear soup with tofu and minced pork.", hindi: "आज मैं टोफू और कीमा पोर्क का साफ सूप खा या पी रहा हूँ।"),
        ],
        1596: [
            WordExample(thai: "ฉันชอบแกงเลียง", romanization: "chǎn chɔ̂ɔp gaeng lîang", english: "I like herbal vegetable soup.", hindi: "मुझे जड़ी-बूटी वाली सब्जी का सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงเลียง", romanization: "wan-níi chǎn gin gaeng lîang", english: "Today I am having herbal vegetable soup.", hindi: "आज मैं जड़ी-बूटी वाली सब्जी का सूप खा या पी रहा हूँ।"),
        ],
        1597: [
            WordExample(thai: "ฉันชอบแกงส้ม", romanization: "chǎn chɔ̂ɔp gaeng sôm", english: "I like sour orange curry.", hindi: "मुझे खट्टी नारंगी करी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงส้ม", romanization: "wan-níi chǎn gin gaeng sôm", english: "Today I am having sour orange curry.", hindi: "आज मैं खट्टी नारंगी करी खा या पी रहा हूँ।"),
        ],
        1598: [
            WordExample(thai: "ฉันชอบแกงป่า", romanization: "chǎn chɔ̂ɔp gaeng bpàa", english: "I like spicy jungle curry.", hindi: "मुझे तीखी जंगल करी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงป่า", romanization: "wan-níi chǎn gin gaeng bpàa", english: "Today I am having spicy jungle curry.", hindi: "आज मैं तीखी जंगल करी खा या पी रहा हूँ।"),
        ],
        1599: [
            WordExample(thai: "ฉันชอบแกงเผ็ด", romanization: "chǎn chɔ̂ɔp gaeng phèt", english: "I like spicy red curry.", hindi: "मुझे तीखी लाल करी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงเผ็ด", romanization: "wan-níi chǎn gin gaeng phèt", english: "Today I am having spicy red curry.", hindi: "आज मैं तीखी लाल करी खा या पी रहा हूँ।"),
        ],
        1600: [
            WordExample(thai: "ฉันชอบแกงฮังเล", romanization: "chǎn chɔ̂ɔp gaeng hang-lay", english: "I like northern pork belly curry.", hindi: "मुझे उत्तरी पोर्क बेली करी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงฮังเล", romanization: "wan-níi chǎn gin gaeng hang-lay", english: "Today I am having northern pork belly curry.", hindi: "आज मैं उत्तरी पोर्क बेली करी खा या पी रहा हूँ।"),
        ],
        1601: [
            WordExample(thai: "ฉันชอบพะแนงหมู", romanization: "chǎn chɔ̂ɔp phá-naeng mǔu", english: "I like pork Panang curry.", hindi: "मुझे पोर्क पनांग करी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินพะแนงหมู", romanization: "wan-níi chǎn gin phá-naeng mǔu", english: "Today I am having pork Panang curry.", hindi: "आज मैं पोर्क पनांग करी खा या पी रहा हूँ।"),
        ],
        1602: [
            WordExample(thai: "ฉันชอบแกงเขียวหวานไก่", romanization: "chǎn chɔ̂ɔp gaeng khǐao wǎan kài", english: "I like green chicken curry.", hindi: "मुझे हरी चिकन करी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินแกงเขียวหวานไก่", romanization: "wan-níi chǎn gin gaeng khǐao wǎan kài", english: "Today I am having green chicken curry.", hindi: "आज मैं हरी चिकन करी खा या पी रहा हूँ।"),
        ],
        1603: [
            WordExample(thai: "ฉันชอบต้มข่าไก่", romanization: "chǎn chɔ̂ɔp tôm khàa kài", english: "I like coconut galangal chicken soup.", hindi: "मुझे नारियल और गलांगल चिकन सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินต้มข่าไก่", romanization: "wan-níi chǎn gin tôm khàa kài", english: "Today I am having coconut galangal chicken soup.", hindi: "आज मैं नारियल और गलांगल चिकन सूप खा या पी रहा हूँ।"),
        ],
        1604: [
            WordExample(thai: "ฉันชอบต้มจับฉ่าย", romanization: "chǎn chɔ̂ɔp tôm jàp-chài", english: "I like Chinese-Thai mixed vegetable stew.", hindi: "मुझे चीनी-थाई मिली सब्जी स्ट्यू पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินต้มจับฉ่าย", romanization: "wan-níi chǎn gin tôm jàp-chài", english: "Today I am having Chinese-Thai mixed vegetable stew.", hindi: "आज मैं चीनी-थाई मिली सब्जी स्ट्यू खा या पी रहा हूँ।"),
        ],
        1605: [
            WordExample(thai: "ฉันชอบต้มเลือดหมู", romanization: "chǎn chɔ̂ɔp tôm lʉ̂at mǔu", english: "I like pork blood soup.", hindi: "मुझे पोर्क रक्त का सूप पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินต้มเลือดหมู", romanization: "wan-níi chǎn gin tôm lʉ̂at mǔu", english: "Today I am having pork blood soup.", hindi: "आज मैं पोर्क रक्त का सूप खा या पी रहा हूँ।"),
        ],
        1606: [
            WordExample(thai: "ฉันชอบพะโล้", romanization: "chǎn chɔ̂ɔp phá-lóh", english: "I like five-spice braised egg and pork stew.", hindi: "मुझे पाँच-मसाला ब्रेज़्ड अंडा और पोर्क स्ट्यू पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินพะโล้", romanization: "wan-níi chǎn gin phá-lóh", english: "Today I am having five-spice braised egg and pork stew.", hindi: "आज मैं पाँच-मसाला ब्रेज़्ड अंडा और पोर्क स्ट्यू खा या पी रहा हूँ।"),
        ],
        1607: [
            WordExample(thai: "ฉันชอบไข่พะโล้", romanization: "chǎn chɔ̂ɔp khài phá-lóh", english: "I like five-spice braised eggs.", hindi: "मुझे पाँच-मसाला ब्रेज़्ड अंडे पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินไข่พะโล้", romanization: "wan-níi chǎn gin khài phá-lóh", english: "Today I am having five-spice braised eggs.", hindi: "आज मैं पाँच-मसाला ब्रेज़्ड अंडे खा या पी रहा हूँ।"),
        ],
        1608: [
            WordExample(thai: "ฉันชอบหมูหวาน", romanization: "chǎn chɔ̂ɔp mǔu wǎan", english: "I like sweet braised pork.", hindi: "मुझे मीठा ब्रेज़्ड पोर्क पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินหมูหวาน", romanization: "wan-níi chǎn gin mǔu wǎan", english: "Today I am having sweet braised pork.", hindi: "आज मैं मीठा ब्रेज़्ड पोर्क खा या पी रहा हूँ।"),
        ],
        1609: [
            WordExample(thai: "ฉันชอบปลาทอดน้ำปลา", romanization: "chǎn chɔ̂ɔp plaa thɔ̂ɔt náam plaa", english: "I like fried fish with fish-sauce glaze.", hindi: "मुझे फिश सॉस ग्लेज़ वाली तली मछली पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินปลาทอดน้ำปลา", romanization: "wan-níi chǎn gin plaa thɔ̂ɔt náam plaa", english: "Today I am having fried fish with fish-sauce glaze.", hindi: "आज मैं फिश सॉस ग्लेज़ वाली तली मछली खा या पी रहा हूँ।"),
        ],
        1610: [
            WordExample(thai: "ฉันชอบปลานึ่งมะนาว", romanization: "chǎn chɔ̂ɔp plaa nʉ̂ng má-naao", english: "I like steamed fish with lime and chili.", hindi: "मुझे नींबू और मिर्च के साथ भाप में बनी मछली पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินปลานึ่งมะนาว", romanization: "wan-níi chǎn gin plaa nʉ̂ng má-naao", english: "Today I am having steamed fish with lime and chili.", hindi: "आज मैं नींबू और मिर्च के साथ भाप में बनी मछली खा या पी रहा हूँ।"),
        ],
        1611: [
            WordExample(thai: "ฉันชอบปลากะพงทอดน้ำปลา", romanization: "chǎn chɔ̂ɔp plaa grà-phong thɔ̂ɔt náam plaa", english: "I like fried sea bass with fish sauce.", hindi: "मुझे फिश सॉस के साथ तली सी बास पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินปลากะพงทอดน้ำปลา", romanization: "wan-níi chǎn gin plaa grà-phong thɔ̂ɔt náam plaa", english: "Today I am having fried sea bass with fish sauce.", hindi: "आज मैं फिश सॉस के साथ तली सी बास खा या पी रहा हूँ।"),
        ],
        1612: [
            WordExample(thai: "ฉันชอบปูผัดผงกะหรี่", romanization: "chǎn chɔ̂ɔp puu phàt phǒng gà-rìi", english: "I like crab stir-fried with curry powder.", hindi: "मुझे करी पाउडर के साथ तला केकड़ा पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินปูผัดผงกะหรี่", romanization: "wan-níi chǎn gin puu phàt phǒng gà-rìi", english: "Today I am having crab stir-fried with curry powder.", hindi: "आज मैं करी पाउडर के साथ तला केकड़ा खा या पी रहा हूँ।"),
        ],
        1613: [
            WordExample(thai: "ฉันชอบกุ้งอบวุ้นเส้น", romanization: "chǎn chɔ̂ɔp kûng òp wún-sên", english: "I like baked shrimp with glass noodles.", hindi: "मुझे ग्लास नूडल्स के साथ बेक्ड झींगे पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินกุ้งอบวุ้นเส้น", romanization: "wan-níi chǎn gin kûng òp wún-sên", english: "Today I am having baked shrimp with glass noodles.", hindi: "आज मैं ग्लास नूडल्स के साथ बेक्ड झींगे खा या पी रहा हूँ।"),
        ],
        1614: [
            WordExample(thai: "ฉันชอบกุ้งแช่น้ำปลา", romanization: "chǎn chɔ̂ɔp kûng châe náam plaa", english: "I like raw shrimp in spicy fish sauce.", hindi: "मुझे मसालेदार फिश सॉस में कच्चे झींगे पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินกุ้งแช่น้ำปลา", romanization: "wan-níi chǎn gin kûng châe náam plaa", english: "Today I am having raw shrimp in spicy fish sauce.", hindi: "आज मैं मसालेदार फिश सॉस में कच्चे झींगे खा या पी रहा हूँ।"),
        ],
        1615: [
            WordExample(thai: "ฉันชอบหอยทอด", romanization: "chǎn chɔ̂ɔp hɔ̌ɔi thɔ̂ɔt", english: "I like crispy mussel omelet.", hindi: "मुझे कुरकुरा मसल ऑमलेट पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินหอยทอด", romanization: "wan-níi chǎn gin hɔ̌ɔi thɔ̂ɔt", english: "Today I am having crispy mussel omelet.", hindi: "आज मैं कुरकुरा मसल ऑमलेट खा या पी रहा हूँ।"),
        ],
        1616: [
            WordExample(thai: "ฉันชอบมะพร้าวอ่อน", romanization: "chǎn chɔ̂ɔp má-phráao ɔ̀ɔn", english: "I like young coconut.", hindi: "मुझे कोमल नारियल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินมะพร้าวอ่อน", romanization: "wan-níi chǎn gin má-phráao ɔ̀ɔn", english: "Today I am having young coconut.", hindi: "आज मैं कोमल नारियल खा या पी रहा हूँ।"),
        ],
        1617: [
            WordExample(thai: "ฉันชอบยอดมะพร้าว", romanization: "chǎn chɔ̂ɔp yɔ̂ɔt má-phráao", english: "I like coconut palm heart.", hindi: "मुझे नारियल ताड़ का कोमल गूदा पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินยอดมะพร้าว", romanization: "wan-níi chǎn gin yɔ̂ɔt má-phráao", english: "Today I am having coconut palm heart.", hindi: "आज मैं नारियल ताड़ का कोमल गूदा खा या पी रहा हूँ।"),
        ],
        1618: [
            WordExample(thai: "ฉันชอบมะเขือเปราะ", romanization: "chǎn chɔ̂ɔp má-khʉ̌a bprɔ̀", english: "I like Thai round eggplant.", hindi: "मुझे थाई गोल बैंगन पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินมะเขือเปราะ", romanization: "wan-níi chǎn gin má-khʉ̌a bprɔ̀", english: "Today I am having Thai round eggplant.", hindi: "आज मैं थाई गोल बैंगन खा या पी रहा हूँ।"),
        ],
        1619: [
            WordExample(thai: "ฉันชอบมะเขือยาว", romanization: "chǎn chɔ̂ɔp má-khʉ̌a yaao", english: "I like long eggplant.", hindi: "मुझे लंबा बैंगन पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินมะเขือยาว", romanization: "wan-níi chǎn gin má-khʉ̌a yaao", english: "Today I am having long eggplant.", hindi: "आज मैं लंबा बैंगन खा या पी रहा हूँ।"),
        ],
        1620: [
            WordExample(thai: "ฉันชอบมะเขือพวง", romanization: "chǎn chɔ̂ɔp má-khʉ̌a phûang", english: "I like pea eggplant.", hindi: "मुझे छोटा मटर बैंगन पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินมะเขือพวง", romanization: "wan-níi chǎn gin má-khʉ̌a phûang", english: "Today I am having pea eggplant.", hindi: "आज मैं छोटा मटर बैंगन खा या पी रहा हूँ।"),
        ],
        1621: [
            WordExample(thai: "ฉันชอบถั่วฝักยาว", romanization: "chǎn chɔ̂ɔp thùa fák yaao", english: "I like yardlong beans.", hindi: "मुझे लंबी फली वाली सेम पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินถั่วฝักยาว", romanization: "wan-níi chǎn gin thùa fák yaao", english: "Today I am having yardlong beans.", hindi: "आज मैं लंबी फली वाली सेम खा या पी रहा हूँ।"),
        ],
        1622: [
            WordExample(thai: "ฉันชอบถั่วงอก", romanization: "chǎn chɔ̂ɔp thùa ngɔ̂ɔk", english: "I like bean sprouts.", hindi: "मुझे अंकुरित मूंग पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินถั่วงอก", romanization: "wan-níi chǎn gin thùa ngɔ̂ɔk", english: "Today I am having bean sprouts.", hindi: "आज मैं अंकुरित मूंग खा या पी रहा हूँ।"),
        ],
        1623: [
            WordExample(thai: "ฉันชอบถั่วลันเตา", romanization: "chǎn chɔ̂ɔp thùa lan-dtao", english: "I like snow peas.", hindi: "मुझे स्नो पीज़ पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินถั่วลันเตา", romanization: "wan-níi chǎn gin thùa lan-dtao", english: "Today I am having snow peas.", hindi: "आज मैं स्नो पीज़ खा या पी रहा हूँ।"),
        ],
        1624: [
            WordExample(thai: "ฉันชอบถั่วแขก", romanization: "chǎn chɔ̂ɔp thùa khàek", english: "I like French beans.", hindi: "मुझे फ्रेंच बीन्स पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินถั่วแขก", romanization: "wan-níi chǎn gin thùa khàek", english: "Today I am having French beans.", hindi: "आज मैं फ्रेंच बीन्स खा या पी रहा हूँ।"),
        ],
        1625: [
            WordExample(thai: "ฉันชอบถั่วดำ", romanization: "chǎn chɔ̂ɔp thùa dam", english: "I like black beans.", hindi: "मुझे काली फलियाँ पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินถั่วดำ", romanization: "wan-níi chǎn gin thùa dam", english: "Today I am having black beans.", hindi: "आज मैं काली फलियाँ खा या पी रहा हूँ।"),
        ],
        1626: [
            WordExample(thai: "ฉันชอบถั่วเหลือง", romanization: "chǎn chɔ̂ɔp thùa lʉ̌ang", english: "I like soybeans.", hindi: "मुझे सोयाबीन पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินถั่วเหลือง", romanization: "wan-níi chǎn gin thùa lʉ̌ang", english: "Today I am having soybeans.", hindi: "आज मैं सोयाबीन खा या पी रहा हूँ।"),
        ],
        1627: [
            WordExample(thai: "ฉันชอบถั่วเขียว", romanization: "chǎn chɔ̂ɔp thùa khǐao", english: "I like mung beans.", hindi: "मुझे मूंग दाल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินถั่วเขียว", romanization: "wan-níi chǎn gin thùa khǐao", english: "Today I am having mung beans.", hindi: "आज मैं मूंग दाल खा या पी रहा हूँ।"),
        ],
        1628: [
            WordExample(thai: "ฉันชอบดอกแค", romanization: "chǎn chɔ̂ɔp dɔ̀ɔk khae", english: "I like sesbania flowers.", hindi: "मुझे अगस्ता के फूल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินดอกแค", romanization: "wan-níi chǎn gin dɔ̀ɔk khae", english: "Today I am having sesbania flowers.", hindi: "आज मैं अगस्ता के फूल खा या पी रहा हूँ।"),
        ],
        1629: [
            WordExample(thai: "ฉันชอบดอกกุยช่าย", romanization: "chǎn chɔ̂ɔp dɔ̀ɔk gui-chài", english: "I like garlic chive flowers.", hindi: "मुझे लहसुन चाइव के फूल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินดอกกุยช่าย", romanization: "wan-níi chǎn gin dɔ̀ɔk gui-chài", english: "Today I am having garlic chive flowers.", hindi: "आज मैं लहसुन चाइव के फूल खा या पी रहा हूँ।"),
        ],
        1630: [
            WordExample(thai: "ฉันชอบผักกาดขาว", romanization: "chǎn chɔ̂ɔp phàk gàat khǎao", english: "I like napa cabbage.", hindi: "मुझे नापा पत्तागोभी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผักกาดขาว", romanization: "wan-níi chǎn gin phàk gàat khǎao", english: "Today I am having napa cabbage.", hindi: "आज मैं नापा पत्तागोभी खा या पी रहा हूँ।"),
        ],
        1631: [
            WordExample(thai: "ฉันชอบผักกาดหอม", romanization: "chǎn chɔ̂ɔp phàk gàat hɔ̌ɔm", english: "I like lettuce.", hindi: "मुझे सलाद पत्ता पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผักกาดหอม", romanization: "wan-níi chǎn gin phàk gàat hɔ̌ɔm", english: "Today I am having lettuce.", hindi: "आज मैं सलाद पत्ता खा या पी रहा हूँ।"),
        ],
        1632: [
            WordExample(thai: "ฉันชอบผักคะน้า", romanization: "chǎn chɔ̂ɔp phàk khá-náa", english: "I like Chinese kale.", hindi: "मुझे चीनी केल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผักคะน้า", romanization: "wan-níi chǎn gin phàk khá-náa", english: "Today I am having Chinese kale.", hindi: "आज मैं चीनी केल खा या पी रहा हूँ।"),
        ],
        1633: [
            WordExample(thai: "ฉันชอบผักหวาน", romanization: "chǎn chɔ̂ɔp phàk wǎan", english: "I like sweet leaf vegetable.", hindi: "मुझे मीठी पत्ती वाली सब्जी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผักหวาน", romanization: "wan-níi chǎn gin phàk wǎan", english: "Today I am having sweet leaf vegetable.", hindi: "आज मैं मीठी पत्ती वाली सब्जी खा या पी रहा हूँ।"),
        ],
        1634: [
            WordExample(thai: "ฉันชอบผักแพว", romanization: "chǎn chɔ̂ɔp phàk phɛɛo", english: "I like Vietnamese coriander.", hindi: "मुझे वियतनामी धनिया पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผักแพว", romanization: "wan-níi chǎn gin phàk phɛɛo", english: "Today I am having Vietnamese coriander.", hindi: "आज मैं वियतनामी धनिया खा या पी रहा हूँ।"),
        ],
        1635: [
            WordExample(thai: "ฉันชอบผักติ้ว", romanization: "chǎn chɔ̂ɔp phàk dtîao", english: "I like sour leaf vegetable.", hindi: "मुझे खट्टी पत्ती वाली सब्जी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผักติ้ว", romanization: "wan-níi chǎn gin phàk dtîao", english: "Today I am having sour leaf vegetable.", hindi: "आज मैं खट्टी पत्ती वाली सब्जी खा या पी रहा हूँ।"),
        ],
        1636: [
            WordExample(thai: "ฉันชอบยอดฟักแม้ว", romanization: "chǎn chɔ̂ɔp yɔ̂ɔt fák mɛ̂ɛo", english: "I like chayote shoots.", hindi: "मुझे चायोट के अंकुर पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินยอดฟักแม้ว", romanization: "wan-níi chǎn gin yɔ̂ɔt fák mɛ̂ɛo", english: "Today I am having chayote shoots.", hindi: "आज मैं चायोट के अंकुर खा या पी रहा हूँ।"),
        ],
        1637: [
            WordExample(thai: "ฉันชอบหน่อไม้", romanization: "chǎn chɔ̂ɔp nɔ̀ɔ mái", english: "I like bamboo shoots.", hindi: "मुझे बाँस के अंकुर पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินหน่อไม้", romanization: "wan-níi chǎn gin nɔ̀ɔ mái", english: "Today I am having bamboo shoots.", hindi: "आज मैं बाँस के अंकुर खा या पी रहा हूँ।"),
        ],
        1638: [
            WordExample(thai: "ฉันชอบหัวปลี", romanization: "chǎn chɔ̂ɔp hǔa bplii", english: "I like banana blossom.", hindi: "मुझे केले का फूल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินหัวปลี", romanization: "wan-níi chǎn gin hǔa bplii", english: "Today I am having banana blossom.", hindi: "आज मैं केले का फूल खा या पी रहा हूँ।"),
        ],
        1639: [
            WordExample(thai: "ฉันชอบใบยี่หร่า", romanization: "chǎn chɔ̂ɔp bai yîi-ràa", english: "I like cumin leaves.", hindi: "मुझे जीरे की पत्तियाँ पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินใบยี่หร่า", romanization: "wan-níi chǎn gin bai yîi-ràa", english: "Today I am having cumin leaves.", hindi: "आज मैं जीरे की पत्तियाँ खा या पी रहा हूँ।"),
        ],
        1640: [
            WordExample(thai: "ฉันชอบใบโหระพา", romanization: "chǎn chɔ̂ɔp bai hŏo-rá-phaa", english: "I like Thai sweet basil leaves.", hindi: "मुझे थाई मीठी तुलसी की पत्तियाँ पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินใบโหระพา", romanization: "wan-níi chǎn gin bai hŏo-rá-phaa", english: "Today I am having Thai sweet basil leaves.", hindi: "आज मैं थाई मीठी तुलसी की पत्तियाँ खा या पी रहा हूँ।"),
        ],
        1641: [
            WordExample(thai: "ฉันชอบใบเตย", romanization: "chǎn chɔ̂ɔp bai dtooey", english: "I like pandan leaves.", hindi: "मुझे पानदान की पत्तियाँ पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินใบเตย", romanization: "wan-níi chǎn gin bai dtooey", english: "Today I am having pandan leaves.", hindi: "आज मैं पानदान की पत्तियाँ खा या पी रहा हूँ।"),
        ],
        1642: [
            WordExample(thai: "ฉันชอบใบชะพลู", romanization: "chǎn chɔ̂ɔp bai chá-phluu", english: "I like wild betel leaves.", hindi: "मुझे जंगली पान की पत्तियाँ पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินใบชะพลู", romanization: "wan-níi chǎn gin bai chá-phluu", english: "Today I am having wild betel leaves.", hindi: "आज मैं जंगली पान की पत्तियाँ खा या पी रहा हूँ।"),
        ],
        1643: [
            WordExample(thai: "ฉันชอบผิวมะกรูด", romanization: "chǎn chɔ̂ɔp phǐu má-grùut", english: "I like kaffir lime zest.", hindi: "मुझे काफिर लाइम का छिलका पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผิวมะกรูด", romanization: "wan-níi chǎn gin phǐu má-grùut", english: "Today I am having kaffir lime zest.", hindi: "आज मैं काफिर लाइम का छिलका खा या पी रहा हूँ।"),
        ],
        1644: [
            WordExample(thai: "ฉันชอบกระชาย", romanization: "chǎn chɔ̂ɔp grà-chaai", english: "I like fingerroot.", hindi: "मुझे फिंगररूट पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินกระชาย", romanization: "wan-níi chǎn gin grà-chaai", english: "Today I am having fingerroot.", hindi: "आज मैं फिंगररूट खा या पी रहा हूँ।"),
        ],
        1645: [
            WordExample(thai: "ฉันชอบกระชายดำ", romanization: "chǎn chɔ̂ɔp grà-chaai dam", english: "I like black ginger.", hindi: "मुझे काला अदरक पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินกระชายดำ", romanization: "wan-níi chǎn gin grà-chaai dam", english: "Today I am having black ginger.", hindi: "आज मैं काला अदरक खा या पी रहा हूँ।"),
        ],
        1646: [
            WordExample(thai: "ฉันชอบขมิ้นขาว", romanization: "chǎn chɔ̂ɔp khà-mîn khǎao", english: "I like white turmeric.", hindi: "मुझे सफेद हल्दी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินขมิ้นขาว", romanization: "wan-níi chǎn gin khà-mîn khǎao", english: "Today I am having white turmeric.", hindi: "आज मैं सफेद हल्दी खा या पी रहा हूँ।"),
        ],
        1647: [
            WordExample(thai: "ฉันชอบพริกชี้ฟ้า", romanization: "chǎn chɔ̂ɔp phrík chíi fáa", english: "I like large spur chili.", hindi: "मुझे लंबी स्पर मिर्च पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินพริกชี้ฟ้า", romanization: "wan-níi chǎn gin phrík chíi fáa", english: "Today I am having large spur chili.", hindi: "आज मैं लंबी स्पर मिर्च खा या पी रहा हूँ।"),
        ],
        1648: [
            WordExample(thai: "ฉันชอบพริกขี้หนู", romanization: "chǎn chɔ̂ɔp phrík khîi nǔu", english: "I like bird's-eye chili.", hindi: "मुझे बर्ड्स-आई मिर्च पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินพริกขี้หนู", romanization: "wan-níi chǎn gin phrík khîi nǔu", english: "Today I am having bird's-eye chili.", hindi: "आज मैं बर्ड्स-आई मिर्च खा या पी रहा हूँ।"),
        ],
        1649: [
            WordExample(thai: "ฉันชอบพริกหยวก", romanization: "chǎn chɔ̂ɔp phrík yùak", english: "I like sweet bell pepper.", hindi: "मुझे मीठी शिमला मिर्च पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินพริกหยวก", romanization: "wan-níi chǎn gin phrík yùak", english: "Today I am having sweet bell pepper.", hindi: "आज मैं मीठी शिमला मिर्च खा या पी रहा हूँ।"),
        ],
        1650: [
            WordExample(thai: "ฉันชอบพริกแกง", romanization: "chǎn chɔ̂ɔp phrík gaeng", english: "I like curry paste.", hindi: "मुझे करी पेस्ट पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินพริกแกง", romanization: "wan-níi chǎn gin phrík gaeng", english: "Today I am having curry paste.", hindi: "आज मैं करी पेस्ट खा या पी रहा हूँ।"),
        ],
        1651: [
            WordExample(thai: "ฉันชอบพริกแกงแดง", romanization: "chǎn chɔ̂ɔp phrík gaeng daeng", english: "I like red curry paste.", hindi: "मुझे लाल करी पेस्ट पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินพริกแกงแดง", romanization: "wan-níi chǎn gin phrík gaeng daeng", english: "Today I am having red curry paste.", hindi: "आज मैं लाल करी पेस्ट खा या पी रहा हूँ।"),
        ],
        1652: [
            WordExample(thai: "ฉันชอบพริกแกงเขียวหวาน", romanization: "chǎn chɔ̂ɔp phrík gaeng khǐao wǎan", english: "I like green curry paste.", hindi: "मुझे हरी करी पेस्ट पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินพริกแกงเขียวหวาน", romanization: "wan-níi chǎn gin phrík gaeng khǐao wǎan", english: "Today I am having green curry paste.", hindi: "आज मैं हरी करी पेस्ट खा या पी रहा हूँ।"),
        ],
        1653: [
            WordExample(thai: "ฉันชอบผงกะหรี่", romanization: "chǎn chɔ̂ɔp phǒng gà-rìi", english: "I like curry powder.", hindi: "मुझे करी पाउडर पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผงกะหรี่", romanization: "wan-níi chǎn gin phǒng gà-rìi", english: "Today I am having curry powder.", hindi: "आज मैं करी पाउडर खा या पी रहा हूँ।"),
        ],
        1654: [
            WordExample(thai: "ฉันชอบผงพะโล้", romanization: "chǎn chɔ̂ɔp phǒng phá-lóh", english: "I like five-spice powder.", hindi: "मुझे पाँच-मसाला पाउडर पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินผงพะโล้", romanization: "wan-níi chǎn gin phǒng phá-lóh", english: "Today I am having five-spice powder.", hindi: "आज मैं पाँच-मसाला पाउडर खा या पी रहा हूँ।"),
        ],
        1655: [
            WordExample(thai: "ฉันชอบงาขาว", romanization: "chǎn chɔ̂ɔp ngaa khǎao", english: "I like white sesame seeds.", hindi: "मुझे सफेद तिल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินงาขาว", romanization: "wan-níi chǎn gin ngaa khǎao", english: "Today I am having white sesame seeds.", hindi: "आज मैं सफेद तिल खा या पी रहा हूँ।"),
        ],
        1656: [
            WordExample(thai: "ฉันชอบงาดำ", romanization: "chǎn chɔ̂ɔp ngaa dam", english: "I like black sesame seeds.", hindi: "मुझे काला तिल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินงาดำ", romanization: "wan-níi chǎn gin ngaa dam", english: "Today I am having black sesame seeds.", hindi: "आज मैं काला तिल खा या पी रहा हूँ।"),
        ],
        1657: [
            WordExample(thai: "ฉันชอบเม็ดมะม่วงหิมพานต์", romanization: "chǎn chɔ̂ɔp mét má-mûang hǐm-má-phaan", english: "I like cashew nuts.", hindi: "मुझे काजू पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินเม็ดมะม่วงหิมพานต์", romanization: "wan-níi chǎn gin mét má-mûang hǐm-má-phaan", english: "Today I am having cashew nuts.", hindi: "आज मैं काजू खा या पी रहा हूँ।"),
        ],
        1658: [
            WordExample(thai: "ฉันชอบกานพลู", romanization: "chǎn chɔ̂ɔp gaan-phluu", english: "I like cloves.", hindi: "मुझे लौंग पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินกานพลู", romanization: "wan-níi chǎn gin gaan-phluu", english: "Today I am having cloves.", hindi: "आज मैं लौंग खा या पी रहा हूँ।"),
        ],
        1659: [
            WordExample(thai: "ฉันชอบลูกจันทน์", romanization: "chǎn chɔ̂ɔp lûuk jan", english: "I like nutmeg.", hindi: "मुझे जायफल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินลูกจันทน์", romanization: "wan-níi chǎn gin lûuk jan", english: "Today I am having nutmeg.", hindi: "आज मैं जायफल खा या पी रहा हूँ।"),
        ],
        1660: [
            WordExample(thai: "ฉันชอบโป๊ยกั๊ก", romanization: "chǎn chɔ̂ɔp bpóoi-gák", english: "I like star anise.", hindi: "मुझे चक्र फूल पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินโป๊ยกั๊ก", romanization: "wan-níi chǎn gin bpóoi-gák", english: "Today I am having star anise.", hindi: "आज मैं चक्र फूल खा या पी रहा हूँ।"),
        ],
        1661: [
            WordExample(thai: "ฉันชอบอบเชยป่น", romanization: "chǎn chɔ̂ɔp òp-choei bpòn", english: "I like ground cinnamon.", hindi: "मुझे पिसी दालचीनी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินอบเชยป่น", romanization: "wan-níi chǎn gin òp-choei bpòn", english: "Today I am having ground cinnamon.", hindi: "आज मैं पिसी दालचीनी खा या पी रहा हूँ।"),
        ],
        1662: [
            WordExample(thai: "ฉันชอบน้ำมะขามเปียก", romanization: "chǎn chɔ̂ɔp náam má-khǎam bpìak", english: "I like tamarind juice.", hindi: "मुझे इमली का गूदा पानी पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำมะขามเปียก", romanization: "wan-níi chǎn gin náam má-khǎam bpìak", english: "Today I am having tamarind juice.", hindi: "आज मैं इमली का गूदा पानी खा या पी रहा हूँ।"),
        ],
        1663: [
            WordExample(thai: "ฉันชอบน้ำกะทิ", romanization: "chǎn chɔ̂ɔp náam gà-thí", english: "I like coconut cream sauce.", hindi: "मुझे नारियल क्रीम सॉस पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำกะทิ", romanization: "wan-níi chǎn gin náam gà-thí", english: "Today I am having coconut cream sauce.", hindi: "आज मैं नारियल क्रीम सॉस खा या पी रहा हूँ।"),
        ],
        1664: [
            WordExample(thai: "ฉันชอบหัวกะทิ", romanization: "chǎn chɔ̂ɔp hǔa gà-thí", english: "I like thick coconut cream.", hindi: "मुझे गाढ़ी नारियल क्रीम पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินหัวกะทิ", romanization: "wan-níi chǎn gin hǔa gà-thí", english: "Today I am having thick coconut cream.", hindi: "आज मैं गाढ़ी नारियल क्रीम खा या पी रहा हूँ।"),
        ],
        1665: [
            WordExample(thai: "ฉันชอบน้ำตาลปี๊บ", romanization: "chǎn chɔ̂ɔp náam-dtaan bpíip", english: "I like palm sugar paste.", hindi: "मुझे ताड़ की चीनी का पेस्ट पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำตาลปี๊บ", romanization: "wan-níi chǎn gin náam-dtaan bpíip", english: "Today I am having palm sugar paste.", hindi: "आज मैं ताड़ की चीनी का पेस्ट खा या पी रहा हूँ।"),
        ],
        1666: [
            WordExample(thai: "ฉันชอบเครื่องดื่มเย็น", romanization: "chǎn chɔ̂ɔp khrʉ̂ang-dʉ̀ʉm yen", english: "I like cold beverage.", hindi: "मुझे ठंडा पेय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินเครื่องดื่มเย็น", romanization: "wan-níi chǎn gin khrʉ̂ang-dʉ̀ʉm yen", english: "Today I am having cold beverage.", hindi: "आज मैं ठंडा पेय खा या पी रहा हूँ।"),
        ],
        1667: [
            WordExample(thai: "ฉันชอบน้ำอัญชัน", romanization: "chǎn chɔ̂ɔp náam an-chan", english: "I like butterfly-pea drink.", hindi: "मुझे अपराजिता का पेय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำอัญชัน", romanization: "wan-níi chǎn gin náam an-chan", english: "Today I am having butterfly-pea drink.", hindi: "आज मैं अपराजिता का पेय खा या पी रहा हूँ।"),
        ],
        1668: [
            WordExample(thai: "ฉันชอบน้ำเก๊กฮวย", romanization: "chǎn chɔ̂ɔp náam gék-huai", english: "I like chrysanthemum tea.", hindi: "मुझे गुलदाउदी की चाय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำเก๊กฮวย", romanization: "wan-níi chǎn gin náam gék-huai", english: "Today I am having chrysanthemum tea.", hindi: "आज मैं गुलदाउदी की चाय खा या पी रहा हूँ।"),
        ],
        1669: [
            WordExample(thai: "ฉันชอบน้ำกระเจี๊ยบ", romanization: "chǎn chɔ̂ɔp náam grà-jíap", english: "I like roselle drink.", hindi: "मुझे रोज़ेल का पेय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำกระเจี๊ยบ", romanization: "wan-níi chǎn gin náam grà-jíap", english: "Today I am having roselle drink.", hindi: "आज मैं रोज़ेल का पेय खा या पी रहा हूँ।"),
        ],
        1670: [
            WordExample(thai: "ฉันชอบน้ำใบเตย", romanization: "chǎn chɔ̂ɔp náam bai dtooey", english: "I like pandan drink.", hindi: "मुझे पानदान का पेय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำใบเตย", romanization: "wan-níi chǎn gin náam bai dtooey", english: "Today I am having pandan drink.", hindi: "आज मैं पानदान का पेय खा या पी रहा हूँ।"),
        ],
        1671: [
            WordExample(thai: "ฉันชอบน้ำลำไย", romanization: "chǎn chɔ̂ɔp náam lam-yai", english: "I like longan drink.", hindi: "मुझे लॉन्गन का पेय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำลำไย", romanization: "wan-níi chǎn gin náam lam-yai", english: "Today I am having longan drink.", hindi: "आज मैं लॉन्गन का पेय खा या पी रहा हूँ।"),
        ],
        1672: [
            WordExample(thai: "ฉันชอบน้ำมะตูม", romanization: "chǎn chɔ̂ɔp náam má-dtum", english: "I like bael fruit drink.", hindi: "मुझे बेल फल का पेय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำมะตูม", romanization: "wan-níi chǎn gin náam má-dtum", english: "Today I am having bael fruit drink.", hindi: "आज मैं बेल फल का पेय खा या पी रहा हूँ।"),
        ],
        1673: [
            WordExample(thai: "ฉันชอบน้ำขิง", romanization: "chǎn chɔ̂ɔp náam khǐng", english: "I like ginger tea.", hindi: "मुझे अदरक की चाय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินน้ำขิง", romanization: "wan-níi chǎn gin náam khǐng", english: "Today I am having ginger tea.", hindi: "आज मैं अदरक की चाय खा या पी रहा हूँ।"),
        ],
        1674: [
            WordExample(thai: "ฉันชอบชาดำเย็น", romanization: "chǎn chɔ̂ɔp chaa dam yen", english: "I like iced black tea.", hindi: "मुझे ठंडी काली चाय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินชาดำเย็น", romanization: "wan-níi chǎn gin chaa dam yen", english: "Today I am having iced black tea.", hindi: "आज मैं ठंडी काली चाय खा या पी रहा हूँ।"),
        ],
        1675: [
            WordExample(thai: "ฉันชอบชามะนาว", romanization: "chǎn chɔ̂ɔp chaa má-naao", english: "I like lime iced tea.", hindi: "मुझे नींबू वाली ठंडी चाय पसंद है।"),
            WordExample(thai: "วันนี้ฉันกินชามะนาว", romanization: "wan-níi chǎn gin chaa má-naao", english: "Today I am having lime iced tea.", hindi: "आज मैं नींबू वाली ठंडी चाय खा या पी रहा हूँ।"),
        ],
        1676: [
            WordExample(thai: "ฉันใช้เครื่องปรุง", romanization: "chǎn chái khrʉ̂ang bprung", english: "I use seasonings and condiments.", hindi: "मैं मसाले और चटनियाँ का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดเครื่องปรุง", romanization: "bproht khrʉ̂ang bprung", english: "Please seasonings and condiments.", hindi: "कृपया मसाले और चटनियाँ।"),
        ],
        1677: [
            WordExample(thai: "ฉันใช้ครกหิน", romanization: "chǎn chái khrók hǐn", english: "I use stone mortar.", hindi: "मैं पत्थर की ओखली का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดครกหิน", romanization: "bproht khrók hǐn", english: "Please stone mortar.", hindi: "कृपया पत्थर की ओखली।"),
        ],
        1678: [
            WordExample(thai: "ฉันใช้สากไม้", romanization: "chǎn chái sàak mái", english: "I use wooden pestle.", hindi: "मैं लकड़ी का मूसल का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดสากไม้", romanization: "bproht sàak mái", english: "Please wooden pestle.", hindi: "कृपया लकड़ी का मूसल।"),
        ],
        1679: [
            WordExample(thai: "ฉันใช้มีดปอก", romanization: "chǎn chái mîit bpɔ̀ɔk", english: "I use paring knife.", hindi: "मैं छीलने का चाकू का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดมีดปอก", romanization: "bproht mîit bpɔ̀ɔk", english: "Please paring knife.", hindi: "कृपया छीलने का चाकू।"),
        ],
        1680: [
            WordExample(thai: "ฉันใช้มีดหั่น", romanization: "chǎn chái mîit hàn", english: "I use slicing knife.", hindi: "मैं काटने का चाकू का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดมีดหั่น", romanization: "bproht mîit hàn", english: "Please slicing knife.", hindi: "कृपया काटने का चाकू।"),
        ],
        1681: [
            WordExample(thai: "ฉันใช้ที่ปอกเปลือก", romanization: "chǎn chái thîi bpɔ̀ɔk bplʉ̀ak", english: "I use vegetable peeler.", hindi: "मैं सब्जी छीलने वाला का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดที่ปอกเปลือก", romanization: "bproht thîi bpɔ̀ɔk bplʉ̀ak", english: "Please vegetable peeler.", hindi: "कृपया सब्जी छीलने वाला।"),
        ],
        1682: [
            WordExample(thai: "ฉันใช้ที่คีบ", romanization: "chǎn chái thîi khîip", english: "I use kitchen tongs.", hindi: "मैं रसोई चिमटा का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดที่คีบ", romanization: "bproht thîi khîip", english: "Please kitchen tongs.", hindi: "कृपया रसोई चिमटा।"),
        ],
        1683: [
            WordExample(thai: "ฉันใช้ที่ตีไข่", romanization: "chǎn chái thîi dtii khài", english: "I use egg whisk.", hindi: "मैं अंडा फेंटने का व्हिस्क का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดที่ตีไข่", romanization: "bproht thîi dtii khài", english: "Please egg whisk.", hindi: "कृपया अंडा फेंटने का व्हिस्क।"),
        ],
        1684: [
            WordExample(thai: "ฉันใช้ตะแกรง", romanization: "chǎn chái dtà-graeng", english: "I use wire rack.", hindi: "मैं तार की जाली का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดตะแกรง", romanization: "bproht dtà-graeng", english: "Please wire rack.", hindi: "कृपया तार की जाली।"),
        ],
        1685: [
            WordExample(thai: "ฉันใช้ตะแกรงลวก", romanization: "chǎn chái dtà-graeng lûak", english: "I use noodle blanching basket.", hindi: "मैं नूडल्स उबालने की टोकरी का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดตะแกรงลวก", romanization: "bproht dtà-graeng lûak", english: "Please noodle blanching basket.", hindi: "कृपया नूडल्स उबालने की टोकरी।"),
        ],
        1686: [
            WordExample(thai: "ฉันใช้กระชอนตาถี่", romanization: "chǎn chái grà-chɔɔn dtaa thìi", english: "I use fine-mesh strainer.", hindi: "मैं बारीक जाली की छलनी का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดกระชอนตาถี่", romanization: "bproht grà-chɔɔn dtaa thìi", english: "Please fine-mesh strainer.", hindi: "कृपया बारीक जाली की छलनी।"),
        ],
        1687: [
            WordExample(thai: "ฉันใช้ที่กรอง", romanization: "chǎn chái thîi grɔɔng", english: "I use filter strainer.", hindi: "मैं छानने की छलनी का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดที่กรอง", romanization: "bproht thîi grɔɔng", english: "Please filter strainer.", hindi: "कृपया छानने की छलनी।"),
        ],
        1688: [
            WordExample(thai: "ฉันใช้ที่ขูด", romanization: "chǎn chái thîi khùut", english: "I use grater.", hindi: "मैं कद्दूकस का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดที่ขูด", romanization: "bproht thîi khùut", english: "Please grater.", hindi: "कृपया कद्दूकस।"),
        ],
        1689: [
            WordExample(thai: "ฉันใช้ที่เปิดกระป๋อง", romanization: "chǎn chái thîi bpə̀ət grà-pɔ̌ɔng", english: "I use can opener.", hindi: "मैं कैन खोलने वाला का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดที่เปิดกระป๋อง", romanization: "bproht thîi bpə̀ət grà-pɔ̌ɔng", english: "Please can opener.", hindi: "कृपया कैन खोलने वाला।"),
        ],
        1690: [
            WordExample(thai: "ฉันใช้ที่คั้นน้ำ", romanization: "chǎn chái thîi khán náam", english: "I use citrus juicer.", hindi: "मैं नींबू निचोड़ने वाला का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดที่คั้นน้ำ", romanization: "bproht thîi khán náam", english: "Please citrus juicer.", hindi: "कृपया नींबू निचोड़ने वाला।"),
        ],
        1691: [
            WordExample(thai: "ฉันใช้พิมพ์ขนม", romanization: "chǎn chái phim khà-nǒm", english: "I use dessert mold.", hindi: "मैं मिठाई का साँचा का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดพิมพ์ขนม", romanization: "bproht phim khà-nǒm", english: "Please dessert mold.", hindi: "कृपया मिठाई का साँचा।"),
        ],
        1692: [
            WordExample(thai: "ฉันใช้หม้อนึ่ง", romanization: "chǎn chái mɔ̂ɔ nʉ̂ng", english: "I use steamer pot.", hindi: "मैं भाप पकाने का बर्तन का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดหม้อนึ่ง", romanization: "bproht mɔ̂ɔ nʉ̂ng", english: "Please steamer pot.", hindi: "कृपया भाप पकाने का बर्तन।"),
        ],
        1693: [
            WordExample(thai: "ฉันใช้หม้อแรงดัน", romanization: "chǎn chái mɔ̂ɔ raeng-dan", english: "I use pressure cooker.", hindi: "मैं प्रेशर कुकर का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดหม้อแรงดัน", romanization: "bproht mɔ̂ɔ raeng-dan", english: "Please pressure cooker.", hindi: "कृपया प्रेशर कुकर।"),
        ],
        1694: [
            WordExample(thai: "ฉันใช้หม้อตุ๋น", romanization: "chǎn chái mɔ̂ɔ dtǔn", english: "I use slow stew pot.", hindi: "मैं धीमी आँच का स्ट्यू पॉट का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดหม้อตุ๋น", romanization: "bproht mɔ̂ɔ dtǔn", english: "Please slow stew pot.", hindi: "कृपया धीमी आँच का स्ट्यू पॉट।"),
        ],
        1695: [
            WordExample(thai: "ฉันใช้กระทะก้นลึก", romanization: "chǎn chái grà-thá gôn lʉ́k", english: "I use deep wok.", hindi: "मैं गहरी कड़ाही का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดกระทะก้นลึก", romanization: "bproht grà-thá gôn lʉ́k", english: "Please deep wok.", hindi: "कृपया गहरी कड़ाही।"),
        ],
        1696: [
            WordExample(thai: "ฉันใช้กระทะย่าง", romanization: "chǎn chái grà-thá yâang", english: "I use grill pan.", hindi: "मैं ग्रिल पैन का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดกระทะย่าง", romanization: "bproht grà-thá yâang", english: "Please grill pan.", hindi: "कृपया ग्रिल पैन।"),
        ],
        1697: [
            WordExample(thai: "ฉันใช้หม้อทอดไร้น้ำมัน", romanization: "chǎn chái mɔ̂ɔ thɔ̂ɔt rái náam-man", english: "I use air fryer.", hindi: "मैं एयर फ्रायर का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดหม้อทอดไร้น้ำมัน", romanization: "bproht mɔ̂ɔ thɔ̂ɔt rái náam-man", english: "Please air fryer.", hindi: "कृपया एयर फ्रायर।"),
        ],
        1698: [
            WordExample(thai: "ฉันใช้ตู้แช่แข็ง", romanization: "chǎn chái dtûu châe khǎeng", english: "I use freezer.", hindi: "मैं फ्रीज़र का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดตู้แช่แข็ง", romanization: "bproht dtûu châe khǎeng", english: "Please freezer.", hindi: "कृपया फ्रीज़र।"),
        ],
        1699: [
            WordExample(thai: "ฉันใช้กล่องถนอมอาหาร", romanization: "chǎn chái glɔ̀ɔng thà-nɔ̌ɔm aa-hǎan", english: "I use food storage container.", hindi: "मैं खाना रखने का डिब्बा का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดกล่องถนอมอาหาร", romanization: "bproht glɔ̀ɔng thà-nɔ̌ɔm aa-hǎan", english: "Please food storage container.", hindi: "कृपया खाना रखने का डिब्बा।"),
        ],
        1700: [
            WordExample(thai: "ฉันใช้พลาสติกแรป", romanization: "chǎn chái phláat-dtìk rɛ́ɛp", english: "I use plastic food wrap.", hindi: "मैं प्लास्टिक फूड रैप का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดพลาสติกแรป", romanization: "bproht phláat-dtìk rɛ́ɛp", english: "Please plastic food wrap.", hindi: "कृपया प्लास्टिक फूड रैप।"),
        ],
        1701: [
            WordExample(thai: "ฉันใช้ฟอยล์อะลูมิเนียม", romanization: "chǎn chái fɔɔi à-luu-mí-niam", english: "I use aluminum foil.", hindi: "मैं एल्युमिनियम फॉइल का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดฟอยล์อะลูมิเนียม", romanization: "bproht fɔɔi à-luu-mí-niam", english: "Please aluminum foil.", hindi: "कृपया एल्युमिनियम फॉइल।"),
        ],
        1702: [
            WordExample(thai: "ฉันใช้กระดาษรองอบ", romanization: "chǎn chái grà-dàat rɔɔng òp", english: "I use baking paper.", hindi: "मैं बेकिंग पेपर का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดกระดาษรองอบ", romanization: "bproht grà-dàat rɔɔng òp", english: "Please baking paper.", hindi: "कृपया बेकिंग पेपर।"),
        ],
        1703: [
            WordExample(thai: "ฉันใช้ถุงมือกันร้อน", romanization: "chǎn chái thǔng mʉʉ gan rɔ́ɔn", english: "I use heat-resistant oven mitt.", hindi: "मैं गर्मी से बचाने वाला ओवन मिट का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดถุงมือกันร้อน", romanization: "bproht thǔng mʉʉ gan rɔ́ɔn", english: "Please heat-resistant oven mitt.", hindi: "कृपया गर्मी से बचाने वाला ओवन मिट।"),
        ],
        1704: [
            WordExample(thai: "ฉันใช้ผ้ารองจาน", romanization: "chǎn chái phâa rɔɔng jaan", english: "I use table placemat.", hindi: "मैं मेज़ का प्लेसमैट का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดผ้ารองจาน", romanization: "bproht phâa rɔɔng jaan", english: "Please table placemat.", hindi: "कृपया मेज़ का प्लेसमैट।"),
        ],
        1705: [
            WordExample(thai: "ฉันใช้ชามผสม", romanization: "chǎn chái chǎam phà-sǒm", english: "I use mixing bowl.", hindi: "मैं मिलाने का कटोरा का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดชามผสม", romanization: "bproht chǎam phà-sǒm", english: "Please mixing bowl.", hindi: "कृपया मिलाने का कटोरा।"),
        ],
        1706: [
            WordExample(thai: "ฉันใช้เหยือกตวง", romanization: "chǎn chái yʉ̀ak dtuaŋ", english: "I use measuring jug.", hindi: "मैं मापने का जग का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดเหยือกตวง", romanization: "bproht yʉ̀ak dtuaŋ", english: "Please measuring jug.", hindi: "कृपया मापने का जग।"),
        ],
        1707: [
            WordExample(thai: "ฉันใช้ถ้วยตวง", romanization: "chǎn chái thûai dtuaŋ", english: "I use measuring cup.", hindi: "मैं मापने का कप का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดถ้วยตวง", romanization: "bproht thûai dtuaŋ", english: "Please measuring cup.", hindi: "कृपया मापने का कप।"),
        ],
        1708: [
            WordExample(thai: "ฉันใช้ช้อนตวง", romanization: "chǎn chái chɔ́ɔn dtuaŋ", english: "I use measuring spoon.", hindi: "मैं मापने का चम्मच का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดช้อนตวง", romanization: "bproht chɔ́ɔn dtuaŋ", english: "Please measuring spoon.", hindi: "कृपया मापने का चम्मच।"),
        ],
        1709: [
            WordExample(thai: "ฉันใช้ไม้พาย", romanization: "chǎn chái mái phaai", english: "I use spatula scraper.", hindi: "मैं स्पैटुला स्क्रेपर का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดไม้พาย", romanization: "bproht mái phaai", english: "Please spatula scraper.", hindi: "कृपया स्पैटुला स्क्रेपर।"),
        ],
        1710: [
            WordExample(thai: "ฉันใช้ไม้คลึงแป้ง", romanization: "chǎn chái mái khlʉʉng bpɛ̂ɛng", english: "I use rolling pin.", hindi: "मैं बेलन का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดไม้คลึงแป้ง", romanization: "bproht mái khlʉʉng bpɛ̂ɛng", english: "Please rolling pin.", hindi: "कृपया बेलन।"),
        ],
        1711: [
            WordExample(thai: "ฉันใช้ตะกร้อลวด", romanization: "chǎn chái dtà-grɔ̂ɔ lûat", english: "I use wire whisk.", hindi: "मैं तार का व्हिस्क का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดตะกร้อลวด", romanization: "bproht dtà-grɔ̂ɔ lûat", english: "Please wire whisk.", hindi: "कृपया तार का व्हिस्क।"),
        ],
        1712: [
            WordExample(thai: "ฉันใช้เครื่องชั่ง", romanization: "chǎn chái khrʉ̂ang chàng", english: "I use kitchen scale.", hindi: "मैं रसोई तराजू का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดเครื่องชั่ง", romanization: "bproht khrʉ̂ang chàng", english: "Please kitchen scale.", hindi: "कृपया रसोई तराजू।"),
        ],
        1713: [
            WordExample(thai: "ฉันใช้เครื่องบด", romanization: "chǎn chái khrʉ̂ang bòot", english: "I use food grinder.", hindi: "मैं खाना पीसने की मशीन का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดเครื่องบด", romanization: "bproht khrʉ̂ang bòot", english: "Please food grinder.", hindi: "कृपया खाना पीसने की मशीन।"),
        ],
        1714: [
            WordExample(thai: "ฉันใช้เครื่องหั่น", romanization: "chǎn chái khrʉ̂ang hàn", english: "I use food slicer.", hindi: "मैं खाना काटने की मशीन का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดเครื่องหั่น", romanization: "bproht khrʉ̂ang hàn", english: "Please food slicer.", hindi: "कृपया खाना काटने की मशीन।"),
        ],
        1715: [
            WordExample(thai: "ฉันใช้เตาแม่เหล็กไฟฟ้า", romanization: "chǎn chái dtao mɛ̂ɛ-lék fai-fáa", english: "I use induction cooktop.", hindi: "मैं इंडक्शन कुकटॉप का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดเตาแม่เหล็กไฟฟ้า", romanization: "bproht dtao mɛ̂ɛ-lék fai-fáa", english: "Please induction cooktop.", hindi: "कृपया इंडक्शन कुकटॉप।"),
        ],
        1716: [
            WordExample(thai: "ฉันใช้เตาถ่าน", romanization: "chǎn chái dtao thàn", english: "I use charcoal stove.", hindi: "मैं कोयले का चूल्हा का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดเตาถ่าน", romanization: "bproht dtao thàn", english: "Please charcoal stove.", hindi: "कृपया कोयले का चूल्हा।"),
        ],
        1717: [
            WordExample(thai: "ฉันใช้ตะแกรงย่าง", romanization: "chǎn chái dtà-graeng yâang", english: "I use grilling rack.", hindi: "मैं ग्रिलिंग रैक का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดตะแกรงย่าง", romanization: "bproht dtà-graeng yâang", english: "Please grilling rack.", hindi: "कृपया ग्रिलिंग रैक।"),
        ],
        1718: [
            WordExample(thai: "ฉันใช้ไม้เสียบ", romanization: "chǎn chái mái sìap", english: "I use skewer.", hindi: "मैं सीख का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดไม้เสียบ", romanization: "bproht mái sìap", english: "Please skewer.", hindi: "कृपया सीख।"),
        ],
        1719: [
            WordExample(thai: "ฉันใช้จานรอง", romanization: "chǎn chái jaan rɔɔng", english: "I use serving plate.", hindi: "मैं परोसने की प्लेट का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดจานรอง", romanization: "bproht jaan rɔɔng", english: "Please serving plate.", hindi: "कृपया परोसने की प्लेट।"),
        ],
        1720: [
            WordExample(thai: "ฉันใช้ชามก๋วยเตี๋ยว", romanization: "chǎn chái chǎam gǔai-dtǐao", english: "I use noodle bowl.", hindi: "मैं नूडल कटोरा का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดชามก๋วยเตี๋ยว", romanization: "bproht chǎam gǔai-dtǐao", english: "Please noodle bowl.", hindi: "कृपया नूडल कटोरा।"),
        ],
        1721: [
            WordExample(thai: "ฉันใช้ถาดเสิร์ฟ", romanization: "chǎn chái thàat sə̀əp", english: "I use serving tray.", hindi: "मैं परोसने की ट्रे का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดถาดเสิร์ฟ", romanization: "bproht thàat sə̀əp", english: "Please serving tray.", hindi: "कृपया परोसने की ट्रे।"),
        ],
        1722: [
            WordExample(thai: "ฉันใช้ผ้าเช็ดมือ", romanization: "chǎn chái phâa chét mʉʉ", english: "I use hand towel.", hindi: "मैं हाथ पोंछने का तौलिया का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดผ้าเช็ดมือ", romanization: "bproht phâa chét mʉʉ", english: "Please hand towel.", hindi: "कृपया हाथ पोंछने का तौलिया।"),
        ],
        1723: [
            WordExample(thai: "ฉันใช้หมัก", romanization: "chǎn chái màk", english: "I use to marinate or ferment.", hindi: "मैं मैरिनेट या फर्मेंट करना का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดหมัก", romanization: "bproht màk", english: "Please to marinate or ferment.", hindi: "कृपया मैरिनेट या फर्मेंट करना।"),
        ],
        1724: [
            WordExample(thai: "ฉันใช้บด", romanization: "chǎn chái bòt", english: "I use to grind into pieces.", hindi: "मैं पीसना का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดบด", romanization: "bproht bòt", english: "Please to grind into pieces.", hindi: "कृपया पीसना।"),
        ],
        1725: [
            WordExample(thai: "ฉันใช้โขลก", romanization: "chǎn chái khlòok", english: "I use to pound in a mortar.", hindi: "मैं ओखली में कूटना का उपयोग करता हूँ।"),
            WordExample(thai: "โปรดโขลก", romanization: "bproht khlòok", english: "Please to pound in a mortar.", hindi: "कृपया ओखली में कूटना।"),
        ],
        1726: [
            WordExample(thai: "ฉันต้องการโต๊ะอาหาร", romanization: "chǎn dtɔ̂ng-gaan dtó aa-hǎan", english: "I need dining table.", hindi: "मुझे खाने की मेज़ चाहिए।"),
            WordExample(thai: "วันนี้มีโต๊ะอาหาร", romanization: "wan-níi mii dtó aa-hǎan", english: "Today there is dining table.", hindi: "आज खाने की मेज़ उपलब्ध है।"),
        ],
        1727: [
            WordExample(thai: "ฉันต้องการเก้าอี้เด็ก", romanization: "chǎn dtɔ̂ng-gaan gâo-îi dèk", english: "I need high chair for a child.", hindi: "मुझे बच्चे की ऊँची कुर्सी चाहिए।"),
            WordExample(thai: "วันนี้มีเก้าอี้เด็ก", romanization: "wan-níi mii gâo-îi dèk", english: "Today there is high chair for a child.", hindi: "आज बच्चे की ऊँची कुर्सी उपलब्ध है।"),
        ],
        1728: [
            WordExample(thai: "ฉันต้องการโต๊ะริมหน้าต่าง", romanization: "chǎn dtɔ̂ng-gaan dtó rim nâa-dtàang", english: "I need table by the window.", hindi: "मुझे खिड़की के पास की मेज़ चाहिए।"),
            WordExample(thai: "วันนี้มีโต๊ะริมหน้าต่าง", romanization: "wan-níi mii dtó rim nâa-dtàang", english: "Today there is table by the window.", hindi: "आज खिड़की के पास की मेज़ उपलब्ध है।"),
        ],
        1729: [
            WordExample(thai: "ฉันต้องการโต๊ะด้านนอก", romanization: "chǎn dtɔ̂ng-gaan dtó dâan nɔ̂ɔk", english: "I need outdoor table.", hindi: "मुझे बाहर की मेज़ चाहिए।"),
            WordExample(thai: "วันนี้มีโต๊ะด้านนอก", romanization: "wan-níi mii dtó dâan nɔ̂ɔk", english: "Today there is outdoor table.", hindi: "आज बाहर की मेज़ उपलब्ध है।"),
        ],
        1730: [
            WordExample(thai: "ฉันต้องการโต๊ะว่าง", romanization: "chǎn dtɔ̂ng-gaan dtó wâang", english: "I need available table.", hindi: "मुझे खाली मेज़ चाहिए।"),
            WordExample(thai: "วันนี้มีโต๊ะว่าง", romanization: "wan-níi mii dtó wâang", english: "Today there is available table.", hindi: "आज खाली मेज़ उपलब्ध है।"),
        ],
        1731: [
            WordExample(thai: "ฉันต้องการรับบัตรเครดิตไหม", romanization: "chǎn dtɔ̂ng-gaan ráp bàt khré-dit mái", english: "I need do you accept credit cards?.", hindi: "मुझे क्या आप क्रेडिट कार्ड लेते हैं? चाहिए।"),
            WordExample(thai: "วันนี้มีรับบัตรเครดิตไหม", romanization: "wan-níi mii ráp bàt khré-dit mái", english: "Today there is do you accept credit cards?.", hindi: "आज क्या आप क्रेडिट कार्ड लेते हैं? उपलब्ध है।"),
        ],
        1732: [
            WordExample(thai: "ฉันต้องการคิดค่าบริการ", romanization: "chǎn dtɔ̂ng-gaan khít khâa bɔɔ-rí-gaan", english: "I need charge a service fee.", hindi: "मुझे सेवा शुल्क लेना चाहिए।"),
            WordExample(thai: "วันนี้มีคิดค่าบริการ", romanization: "wan-níi mii khít khâa bɔɔ-rí-gaan", english: "Today there is charge a service fee.", hindi: "आज सेवा शुल्क लेना उपलब्ध है।"),
        ],
        1733: [
            WordExample(thai: "ฉันต้องการไม่ใส่ผักชี", romanization: "chǎn dtɔ̂ng-gaan mâi sài phàk chii", english: "I need no cilantro, please.", hindi: "मुझे कृपया धनिया न डालें चाहिए।"),
            WordExample(thai: "วันนี้มีไม่ใส่ผักชี", romanization: "wan-níi mii mâi sài phàk chii", english: "Today there is no cilantro, please.", hindi: "आज कृपया धनिया न डालें उपलब्ध है।"),
        ],
        1734: [
            WordExample(thai: "ฉันต้องการไม่ใส่ถั่วลิสง", romanization: "chǎn dtɔ̂ng-gaan mâi sài thùa lí-sòng", english: "I need no peanuts, please.", hindi: "मुझे कृपया मूंगफली न डालें चाहिए।"),
            WordExample(thai: "วันนี้มีไม่ใส่ถั่วลิสง", romanization: "wan-níi mii mâi sài thùa lí-sòng", english: "Today there is no peanuts, please.", hindi: "आज कृपया मूंगफली न डालें उपलब्ध है।"),
        ],
        1735: [
            WordExample(thai: "ฉันต้องการไม่ใส่น้ำตาล", romanization: "chǎn dtɔ̂ng-gaan mâi sài náam-dtaan", english: "I need no sugar, please.", hindi: "मुझे कृपया चीनी न डालें चाहिए।"),
            WordExample(thai: "วันนี้มีไม่ใส่น้ำตาล", romanization: "wan-níi mii mâi sài náam-dtaan", english: "Today there is no sugar, please.", hindi: "आज कृपया चीनी न डालें उपलब्ध है।"),
        ],
        1736: [
            WordExample(thai: "ฉันต้องการไม่ใส่นม", romanization: "chǎn dtɔ̂ng-gaan mâi sài nom", english: "I need no milk, please.", hindi: "मुझे कृपया दूध न डालें चाहिए।"),
            WordExample(thai: "วันนี้มีไม่ใส่นม", romanization: "wan-níi mii mâi sài nom", english: "Today there is no milk, please.", hindi: "आज कृपया दूध न डालें उपलब्ध है।"),
        ],
        1737: [
            WordExample(thai: "ฉันต้องการไม่เผ็ดเลย", romanization: "chǎn dtɔ̂ng-gaan mâi phèt loei", english: "I need not spicy at all.", hindi: "मुझे बिल्कुल तीखा नहीं चाहिए।"),
            WordExample(thai: "วันนี้มีไม่เผ็ดเลย", romanization: "wan-níi mii mâi phèt loei", english: "Today there is not spicy at all.", hindi: "आज बिल्कुल तीखा नहीं उपलब्ध है।"),
        ],
        1738: [
            WordExample(thai: "ฉันต้องการเผ็ดนิดเดียว", romanization: "chǎn dtɔ̂ng-gaan phèt nít diao", english: "I need only slightly spicy.", hindi: "मुझे बस थोड़ा तीखा चाहिए।"),
            WordExample(thai: "วันนี้มีเผ็ดนิดเดียว", romanization: "wan-níi mii phèt nít diao", english: "Today there is only slightly spicy.", hindi: "आज बस थोड़ा तीखा उपलब्ध है।"),
        ],
        1739: [
            WordExample(thai: "ฉันต้องการเผ็ดกลางๆ", romanization: "chǎn dtɔ̂ng-gaan phèt glaang-glaang", english: "I need medium spicy.", hindi: "मुझे मध्यम तीखा चाहिए।"),
            WordExample(thai: "วันนี้มีเผ็ดกลางๆ", romanization: "wan-níi mii phèt glaang-glaang", english: "Today there is medium spicy.", hindi: "आज मध्यम तीखा उपलब्ध है।"),
        ],
        1740: [
            WordExample(thai: "ฉันต้องการเผ็ดมากๆ", romanization: "chǎn dtɔ̂ng-gaan phèt mâak-mâak", english: "I need very spicy.", hindi: "मुझे बहुत तीखा चाहिए।"),
            WordExample(thai: "วันนี้มีเผ็ดมากๆ", romanization: "wan-níi mii phèt mâak-mâak", english: "Today there is very spicy.", hindi: "आज बहुत तीखा उपलब्ध है।"),
        ],
        1741: [
            WordExample(thai: "ฉันต้องการหวานปกติ", romanization: "chǎn dtɔ̂ng-gaan wǎan bpà-gà-dtì", english: "I need regular sweetness.", hindi: "मुझे सामान्य मिठास चाहिए।"),
            WordExample(thai: "วันนี้มีหวานปกติ", romanization: "wan-níi mii wǎan bpà-gà-dtì", english: "Today there is regular sweetness.", hindi: "आज सामान्य मिठास उपलब्ध है।"),
        ],
        1742: [
            WordExample(thai: "ฉันต้องการเพิ่มไข่ดาว", romanization: "chǎn dtɔ̂ng-gaan phə̂əm khài daao", english: "I need add a fried egg.", hindi: "मुझे एक तला अंडा जोड़ें चाहिए।"),
            WordExample(thai: "วันนี้มีเพิ่มไข่ดาว", romanization: "wan-níi mii phə̂əm khài daao", english: "Today there is add a fried egg.", hindi: "आज एक तला अंडा जोड़ें उपलब्ध है।"),
        ],
        1743: [
            WordExample(thai: "ฉันต้องการเพิ่มข้าว", romanization: "chǎn dtɔ̂ng-gaan phə̂əm khâao", english: "I need add more rice.", hindi: "मुझे और चावल जोड़ें चाहिए।"),
            WordExample(thai: "วันนี้มีเพิ่มข้าว", romanization: "wan-níi mii phə̂əm khâao", english: "Today there is add more rice.", hindi: "आज और चावल जोड़ें उपलब्ध है।"),
        ],
        1744: [
            WordExample(thai: "ฉันต้องการเพิ่มเส้น", romanization: "chǎn dtɔ̂ng-gaan phə̂əm sên", english: "I need add more noodles.", hindi: "मुझे और नूडल्स जोड़ें चाहिए।"),
            WordExample(thai: "วันนี้มีเพิ่มเส้น", romanization: "wan-níi mii phə̂əm sên", english: "Today there is add more noodles.", hindi: "आज और नूडल्स जोड़ें उपलब्ध है।"),
        ],
        1745: [
            WordExample(thai: "ฉันต้องการแยกน้ำซุป", romanization: "chǎn dtɔ̂ng-gaan yâek náam súp", english: "I need serve the soup separately.", hindi: "मुझे सूप अलग परोसें चाहिए।"),
            WordExample(thai: "วันนี้มีแยกน้ำซุป", romanization: "wan-níi mii yâek náam súp", english: "Today there is serve the soup separately.", hindi: "आज सूप अलग परोसें उपलब्ध है।"),
        ],
        1746: [
            WordExample(thai: "ฉันต้องการแยกน้ำแข็ง", romanization: "chǎn dtɔ̂ng-gaan yâek náam khǎeng", english: "I need serve ice separately.", hindi: "मुझे बर्फ अलग दें चाहिए।"),
            WordExample(thai: "วันนี้มีแยกน้ำแข็ง", romanization: "wan-níi mii yâek náam khǎeng", english: "Today there is serve ice separately.", hindi: "आज बर्फ अलग दें उपलब्ध है।"),
        ],
        1747: [
            WordExample(thai: "ฉันต้องการใส่กล่องกลับบ้าน", romanization: "chǎn dtɔ̂ng-gaan sài glɔ̀ɔng glàp bâan", english: "I need pack it in a takeaway box.", hindi: "मुझे इसे टेकअवे डिब्बे में पैक करें चाहिए।"),
            WordExample(thai: "วันนี้มีใส่กล่องกลับบ้าน", romanization: "wan-níi mii sài glɔ̀ɔng glàp bâan", english: "Today there is pack it in a takeaway box.", hindi: "आज इसे टेकअवे डिब्बे में पैक करें उपलब्ध है।"),
        ],
        1748: [
            WordExample(thai: "ฉันต้องการห่อกลับบ้าน", romanization: "chǎn dtɔ̂ng-gaan hɔ̀ɔ glàp bâan", english: "I need wrap it to take home.", hindi: "मुझे घर ले जाने के लिए पैक करें चाहिए।"),
            WordExample(thai: "วันนี้มีห่อกลับบ้าน", romanization: "wan-níi mii hɔ̀ɔ glàp bâan", english: "Today there is wrap it to take home.", hindi: "आज घर ले जाने के लिए पैक करें उपलब्ध है।"),
        ],
        1749: [
            WordExample(thai: "ฉันต้องการขอช้อนเพิ่ม", romanization: "chǎn dtɔ̂ng-gaan khɔ̌ɔ chɔ́ɔn phə̂əm", english: "I need more spoons, please.", hindi: "मुझे कृपया और चम्मच दें चाहिए।"),
            WordExample(thai: "วันนี้มีขอช้อนเพิ่ม", romanization: "wan-níi mii khɔ̌ɔ chɔ́ɔn phə̂əm", english: "Today there is more spoons, please.", hindi: "आज कृपया और चम्मच दें उपलब्ध है।"),
        ],
        1750: [
            WordExample(thai: "ฉันต้องการขอจานเพิ่ม", romanization: "chǎn dtɔ̂ng-gaan khɔ̌ɔ jaan phə̂əm", english: "I need more plates, please.", hindi: "मुझे कृपया और प्लेटें दें चाहिए।"),
            WordExample(thai: "วันนี้มีขอจานเพิ่ม", romanization: "wan-níi mii khɔ̌ɔ jaan phə̂əm", english: "Today there is more plates, please.", hindi: "आज कृपया और प्लेटें दें उपलब्ध है।"),
        ],
        1751: [
            WordExample(thai: "ฉันต้องการขอน้ำเปล่า", romanization: "chǎn dtɔ̂ng-gaan khɔ̌ɔ náam bplào", english: "I need water, please.", hindi: "मुझे कृपया सादा पानी दें चाहिए।"),
            WordExample(thai: "วันนี้มีขอน้ำเปล่า", romanization: "wan-níi mii khɔ̌ɔ náam bplào", english: "Today there is water, please.", hindi: "आज कृपया सादा पानी दें उपलब्ध है।"),
        ],
        1752: [
            WordExample(thai: "ฉันต้องการขอน้ำแข็งเพิ่ม", romanization: "chǎn dtɔ̂ng-gaan khɔ̌ɔ náam khǎeng phə̂əm", english: "I need more ice, please.", hindi: "मुझे कृपया और बर्फ दें चाहिए।"),
            WordExample(thai: "วันนี้มีขอน้ำแข็งเพิ่ม", romanization: "wan-níi mii khɔ̌ɔ náam khǎeng phə̂əm", english: "Today there is more ice, please.", hindi: "आज कृपया और बर्फ दें उपलब्ध है।"),
        ],
        1753: [
            WordExample(thai: "ฉันต้องการขอเมนูภาษาอังกฤษ", romanization: "chǎn dtɔ̂ng-gaan khɔ̌ɔ mee-nuu phaa-sǎa ang-grìt", english: "I need an English menu, please.", hindi: "मुझे कृपया अंग्रेज़ी मेनू दें चाहिए।"),
            WordExample(thai: "วันนี้มีขอเมนูภาษาอังกฤษ", romanization: "wan-níi mii khɔ̌ɔ mee-nuu phaa-sǎa ang-grìt", english: "Today there is an English menu, please.", hindi: "आज कृपया अंग्रेज़ी मेनू दें उपलब्ध है।"),
        ],
        1754: [
            WordExample(thai: "ฉันต้องการมีเมนูมังสวิรัติไหม", romanization: "chǎn dtɔ̂ng-gaan mii mee-nuu mang-sà-wí-rát mái", english: "I need do you have a vegetarian menu?.", hindi: "मुझे क्या शाकाहारी मेनू है? चाहिए।"),
            WordExample(thai: "วันนี้มีมีเมนูมังสวิรัติไหม", romanization: "wan-níi mii mii mee-nuu mang-sà-wí-rát mái", english: "Today there is do you have a vegetarian menu?.", hindi: "आज क्या शाकाहारी मेनू है? उपलब्ध है।"),
        ],
        1755: [
            WordExample(thai: "ฉันต้องการแพ้อาหารทะเล", romanization: "chǎn dtɔ̂ng-gaan phɛ́ɛ aa-hǎan tha-lay", english: "I need allergic to seafood.", hindi: "मुझे समुद्री भोजन से एलर्जी है चाहिए।"),
            WordExample(thai: "วันนี้มีแพ้อาหารทะเล", romanization: "wan-níi mii phɛ́ɛ aa-hǎan tha-lay", english: "Today there is allergic to seafood.", hindi: "आज समुद्री भोजन से एलर्जी है उपलब्ध है।"),
        ],
        1756: [
            WordExample(thai: "ฉันต้องการแพ้ถั่วลิสง", romanization: "chǎn dtɔ̂ng-gaan phɛ́ɛ thùa lí-sòng", english: "I need allergic to peanuts.", hindi: "मुझे मूंगफली से एलर्जी है चाहिए।"),
            WordExample(thai: "วันนี้มีแพ้ถั่วลิสง", romanization: "wan-níi mii phɛ́ɛ thùa lí-sòng", english: "Today there is allergic to peanuts.", hindi: "आज मूंगफली से एलर्जी है उपलब्ध है।"),
        ],
        1757: [
            WordExample(thai: "ฉันต้องการแพ้นม", romanization: "chǎn dtɔ̂ng-gaan phɛ́ɛ nom", english: "I need allergic to milk.", hindi: "मुझे दूध से एलर्जी है चाहिए।"),
            WordExample(thai: "วันนี้มีแพ้นม", romanization: "wan-níi mii phɛ́ɛ nom", english: "Today there is allergic to milk.", hindi: "आज दूध से एलर्जी है उपलब्ध है।"),
        ],
        1758: [
            WordExample(thai: "ฉันต้องการไม่กินหมู", romanization: "chǎn dtɔ̂ng-gaan mâi gin mǔu", english: "I need I do not eat pork.", hindi: "मुझे मैं पोर्क नहीं खाता हूँ चाहिए।"),
            WordExample(thai: "วันนี้มีไม่กินหมู", romanization: "wan-níi mii mâi gin mǔu", english: "Today there is I do not eat pork.", hindi: "आज मैं पोर्क नहीं खाता हूँ उपलब्ध है।"),
        ],
        1759: [
            WordExample(thai: "ฉันต้องการไม่กินเนื้อวัว", romanization: "chǎn dtɔ̂ng-gaan mâi gin nʉ́a wua", english: "I need I do not eat beef.", hindi: "मुझे मैं गोमांस नहीं खाता हूँ चाहिए।"),
            WordExample(thai: "วันนี้มีไม่กินเนื้อวัว", romanization: "wan-níi mii mâi gin nʉ́a wua", english: "Today there is I do not eat beef.", hindi: "आज मैं गोमांस नहीं खाता हूँ उपलब्ध है।"),
        ],
        1760: [
            WordExample(thai: "ฉันต้องการไม่กินเนื้อสัตว์", romanization: "chǎn dtɔ̂ng-gaan mâi gin nʉ́a sàt", english: "I need I do not eat meat.", hindi: "मुझे मैं मांस नहीं खाता हूँ चाहिए।"),
            WordExample(thai: "วันนี้มีไม่กินเนื้อสัตว์", romanization: "wan-níi mii mâi gin nʉ́a sàt", english: "Today there is I do not eat meat.", hindi: "आज मैं मांस नहीं खाता हूँ उपलब्ध है।"),
        ],
        1761: [
            WordExample(thai: "ฉันต้องการอาหารตามสั่ง", romanization: "chǎn dtɔ̂ng-gaan aa-hǎan dtaam sàng", english: "I need made-to-order food.", hindi: "मुझे ऑर्डर पर बना भोजन चाहिए।"),
            WordExample(thai: "วันนี้มีอาหารตามสั่ง", romanization: "wan-níi mii aa-hǎan dtaam sàng", english: "Today there is made-to-order food.", hindi: "आज ऑर्डर पर बना भोजन उपलब्ध है।"),
        ],
        1762: [
            WordExample(thai: "ฉันต้องการร้านก๋วยเตี๋ยว", romanization: "chǎn dtɔ̂ng-gaan ráan gǔai-dtǐao", english: "I need noodle shop.", hindi: "मुझे नूडल की दुकान चाहिए।"),
            WordExample(thai: "วันนี้มีร้านก๋วยเตี๋ยว", romanization: "wan-níi mii ráan gǔai-dtǐao", english: "Today there is noodle shop.", hindi: "आज नूडल की दुकान उपलब्ध है।"),
        ],
        1763: [
            WordExample(thai: "ฉันต้องการร้านข้าวแกง", romanization: "chǎn dtɔ̂ng-gaan ráan khâao gaeng", english: "I need curry-and-rice shop.", hindi: "मुझे करी-चावल की दुकान चाहिए।"),
            WordExample(thai: "วันนี้มีร้านข้าวแกง", romanization: "wan-níi mii ráan khâao gaeng", english: "Today there is curry-and-rice shop.", hindi: "आज करी-चावल की दुकान उपलब्ध है।"),
        ],
        1764: [
            WordExample(thai: "ฉันต้องการร้านส้มตำ", romanization: "chǎn dtɔ̂ng-gaan ráan sôm dtam", english: "I need papaya-salad shop.", hindi: "मुझे पपीता सलाद की दुकान चाहिए।"),
            WordExample(thai: "วันนี้มีร้านส้มตำ", romanization: "wan-níi mii ráan sôm dtam", english: "Today there is papaya-salad shop.", hindi: "आज पपीता सलाद की दुकान उपलब्ध है।"),
        ],
        1765: [
            WordExample(thai: "ฉันต้องการร้านอาหารเจ", romanization: "chǎn dtɔ̂ng-gaan ráan aa-hǎan jee", english: "I need vegetarian Thai restaurant.", hindi: "मुझे शाकाहारी थाई रेस्तराँ चाहिए।"),
            WordExample(thai: "วันนี้มีร้านอาหารเจ", romanization: "wan-níi mii ráan aa-hǎan jee", english: "Today there is vegetarian Thai restaurant.", hindi: "आज शाकाहारी थाई रेस्तराँ उपलब्ध है।"),
        ],
        1766: [
            WordExample(thai: "ฉันต้องการราคาเท่าไร", romanization: "chǎn dtɔ̂ng-gaan raa-khaa thâo-rài", english: "I need how much does it cost?.", hindi: "मुझे इसकी कीमत कितनी है? चाहिए।"),
            WordExample(thai: "วันนี้มีราคาเท่าไร", romanization: "wan-níi mii raa-khaa thâo-rài", english: "Today there is how much does it cost?.", hindi: "आज इसकी कीमत कितनी है? उपलब्ध है।"),
        ],
        1767: [
            WordExample(thai: "ฉันต้องการขายเป็นกิโล", romanization: "chǎn dtɔ̂ng-gaan khǎai bpen gii-loo", english: "I need sold by the kilogram.", hindi: "मुझे किलोग्राम के हिसाब से बिकता है चाहिए।"),
            WordExample(thai: "วันนี้มีขายเป็นกิโล", romanization: "wan-níi mii khǎai bpen gii-loo", english: "Today there is sold by the kilogram.", hindi: "आज किलोग्राम के हिसाब से बिकता है उपलब्ध है।"),
        ],
        1768: [
            WordExample(thai: "ฉันต้องการขายเป็นขีด", romanization: "chǎn dtɔ̂ng-gaan khǎai bpen khìit", english: "I need sold by 100 grams.", hindi: "मुझे सौ ग्राम के हिसाब से बिकता है चाहिए।"),
            WordExample(thai: "วันนี้มีขายเป็นขีด", romanization: "wan-níi mii khǎai bpen khìit", english: "Today there is sold by 100 grams.", hindi: "आज सौ ग्राम के हिसाब से बिकता है उपलब्ध है।"),
        ],
        1769: [
            WordExample(thai: "ฉันต้องการสดใหม่", romanization: "chǎn dtɔ̂ng-gaan sòt mài", english: "I need freshly harvested or made.", hindi: "मुझे ताज़ा नया चाहिए।"),
            WordExample(thai: "วันนี้มีสดใหม่", romanization: "wan-níi mii sòt mài", english: "Today there is freshly harvested or made.", hindi: "आज ताज़ा नया उपलब्ध है।"),
        ],
        1770: [
            WordExample(thai: "ฉันต้องการเลือกเองได้ไหม", romanization: "chǎn dtɔ̂ng-gaan lʉ̂ak eeng dâai mái", english: "I need may I choose them myself?.", hindi: "मुझे क्या मैं खुद चुन सकता हूँ? चाहिए।"),
            WordExample(thai: "วันนี้มีเลือกเองได้ไหม", romanization: "wan-níi mii lʉ̂ak eeng dâai mái", english: "Today there is may I choose them myself?.", hindi: "आज क्या मैं खुद चुन सकता हूँ? उपलब्ध है।"),
        ],
        1771: [
            WordExample(thai: "ฉันต้องการชั่งให้หน่อย", romanization: "chǎn dtɔ̂ng-gaan chàng hâi nɔ̀i", english: "I need please weigh it.", hindi: "मुझे कृपया इसे तौल दें चाहिए।"),
            WordExample(thai: "วันนี้มีชั่งให้หน่อย", romanization: "wan-níi mii chàng hâi nɔ̀i", english: "Today there is please weigh it.", hindi: "आज कृपया इसे तौल दें उपलब्ध है।"),
        ],
        1772: [
            WordExample(thai: "ฉันต้องการลดได้ไหม", romanization: "chǎn dtɔ̂ng-gaan lót dâai mái", english: "I need can you lower the price?.", hindi: "मुझे क्या कीमत कम कर सकते हैं? चाहिए।"),
            WordExample(thai: "วันนี้มีลดได้ไหม", romanization: "wan-níi mii lót dâai mái", english: "Today there is can you lower the price?.", hindi: "आज क्या कीमत कम कर सकते हैं? उपलब्ध है।"),
        ],
        1773: [
            WordExample(thai: "ฉันต้องการเอาอันนี้", romanization: "chǎn dtɔ̂ng-gaan ao an níi", english: "I need I will take this one.", hindi: "मुझे मैं यह वाला लूँगा चाहिए।"),
            WordExample(thai: "วันนี้มีเอาอันนี้", romanization: "wan-níi mii ao an níi", english: "Today there is I will take this one.", hindi: "आज मैं यह वाला लूँगा उपलब्ध है।"),
        ],
        1774: [
            WordExample(thai: "ฉันต้องการไม่เอาถุง", romanization: "chǎn dtɔ̂ng-gaan mâi ao thǔng", english: "I need no bag, please.", hindi: "मुझे कृपया थैला नहीं चाहिए चाहिए।"),
            WordExample(thai: "วันนี้มีไม่เอาถุง", romanization: "wan-níi mii mâi ao thǔng", english: "Today there is no bag, please.", hindi: "आज कृपया थैला नहीं चाहिए उपलब्ध है।"),
        ],
        1775: [
            WordExample(thai: "ฉันต้องการถุงกระดาษ", romanization: "chǎn dtɔ̂ng-gaan thǔng grà-dàat", english: "I need paper bag.", hindi: "मुझे कागज़ का थैला चाहिए।"),
            WordExample(thai: "วันนี้มีถุงกระดาษ", romanization: "wan-níi mii thǔng grà-dàat", english: "Today there is paper bag.", hindi: "आज कागज़ का थैला उपलब्ध है।"),
        ],
        1776: [
            WordExample(thai: "ฉันต้องการผักสด", romanization: "chǎn dtɔ̂ng-gaan phàk sòt", english: "I need fresh vegetables.", hindi: "मुझे ताज़ी सब्ज़ियाँ चाहिए।"),
            WordExample(thai: "วันนี้มีผักสด", romanization: "wan-níi mii phàk sòt", english: "Today there is fresh vegetables.", hindi: "आज ताज़ी सब्ज़ियाँ उपलब्ध है।"),
        ],
        1777: [
            WordExample(thai: "ฉันต้องการเนื้อสด", romanization: "chǎn dtɔ̂ng-gaan nʉ́a sòt", english: "I need fresh meat.", hindi: "मुझे ताज़ा मांस चाहिए।"),
            WordExample(thai: "วันนี้มีเนื้อสด", romanization: "wan-níi mii nʉ́a sòt", english: "Today there is fresh meat.", hindi: "आज ताज़ा मांस उपलब्ध है।"),
        ],
        1778: [
            WordExample(thai: "ฉันต้องการอาหารพร้อมกิน", romanization: "chǎn dtɔ̂ng-gaan aa-hǎan phrɔ́ɔm gin", english: "I need ready-to-eat food.", hindi: "मुझे तुरंत खाने योग्य भोजन चाहिए।"),
            WordExample(thai: "วันนี้มีอาหารพร้อมกิน", romanization: "wan-níi mii aa-hǎan phrɔ́ɔm gin", english: "Today there is ready-to-eat food.", hindi: "आज तुरंत खाने योग्य भोजन उपलब्ध है।"),
        ],
        1779: [
            WordExample(thai: "ฉันต้องการชิมฟรี", romanization: "chǎn dtɔ̂ng-gaan chim frii", english: "I need free sample tasting.", hindi: "मुझे मुफ़्त चखना चाहिए।"),
            WordExample(thai: "วันนี้มีชิมฟรี", romanization: "wan-níi mii chim frii", english: "Today there is free sample tasting.", hindi: "आज मुफ़्त चखना उपलब्ध है।"),
        ],
        1780: [
            WordExample(thai: "ฉันต้องการของฝากกินได้", romanization: "chǎn dtɔ̂ng-gaan khɔ̌ɔng fàak gin dâai", english: "I need edible souvenir.", hindi: "मुझे खाने योग्य स्मारिका चाहिए।"),
            WordExample(thai: "วันนี้มีของฝากกินได้", romanization: "wan-níi mii khɔ̌ɔng fàak gin dâai", english: "Today there is edible souvenir.", hindi: "आज खाने योग्य स्मारिका उपलब्ध है।"),
        ],
        1781: [
            WordExample(thai: "ฉันต้องการผลไม้ตามฤดูกาล", romanization: "chǎn dtɔ̂ng-gaan phǒn-lá-mái dtaam rʉ́-duu-gaan", english: "I need seasonal fruit.", hindi: "मुझे मौसमी फल चाहिए।"),
            WordExample(thai: "วันนี้มีผลไม้ตามฤดูกาล", romanization: "wan-níi mii phǒn-lá-mái dtaam rʉ́-duu-gaan", english: "Today there is seasonal fruit.", hindi: "आज मौसमी फल उपलब्ध है।"),
        ],
        1782: [
            WordExample(thai: "ฉันต้องการทุเรียนหมอนทอง", romanization: "chǎn dtɔ̂ng-gaan tú-rian mɔ̌ɔn-thɔɔng", english: "I need Monthong durian.", hindi: "मुझे मोंथोंग दुरियन चाहिए।"),
            WordExample(thai: "วันนี้มีทุเรียนหมอนทอง", romanization: "wan-níi mii tú-rian mɔ̌ɔn-thɔɔng", english: "Today there is Monthong durian.", hindi: "आज मोंथोंग दुरियन उपलब्ध है।"),
        ],
        1783: [
            WordExample(thai: "ฉันต้องการมะม่วงน้ำดอกไม้", romanization: "chǎn dtɔ̂ng-gaan má-mûang náam dɔ̀ɔk-mái", english: "I need Nam Dok Mai mango.", hindi: "मुझे नाम डॉक माई आम चाहिए।"),
            WordExample(thai: "วันนี้มีมะม่วงน้ำดอกไม้", romanization: "wan-níi mii má-mûang náam dɔ̀ɔk-mái", english: "Today there is Nam Dok Mai mango.", hindi: "आज नाम डॉक माई आम उपलब्ध है।"),
        ],
        1784: [
            WordExample(thai: "ฉันต้องการสละ", romanization: "chǎn dtɔ̂ng-gaan sà-là", english: "I need salak fruit.", hindi: "मुझे सालक फल चाहिए।"),
            WordExample(thai: "วันนี้มีสละ", romanization: "wan-níi mii sà-là", english: "Today there is salak fruit.", hindi: "आज सालक फल उपलब्ध है।"),
        ],
        1785: [
            WordExample(thai: "ฉันต้องการลองกอง", romanization: "chǎn dtɔ̂ng-gaan long-gɔɔng", english: "I need langsat fruit.", hindi: "मुझे लांगसाट फल चाहिए।"),
            WordExample(thai: "วันนี้มีลองกอง", romanization: "wan-níi mii long-gɔɔng", english: "Today there is langsat fruit.", hindi: "आज लांगसाट फल उपलब्ध है।"),
        ],
        1786: [
            WordExample(thai: "ฉันต้องการน้อยหน่า", romanization: "chǎn dtɔ̂ng-gaan nɔ́ɔi nàa", english: "I need custard apple.", hindi: "मुझे सीताफल चाहिए।"),
            WordExample(thai: "วันนี้มีน้อยหน่า", romanization: "wan-níi mii nɔ́ɔi nàa", english: "Today there is custard apple.", hindi: "आज सीताफल उपलब्ध है।"),
        ],
        1787: [
            WordExample(thai: "ฉันต้องการชมพู่", romanization: "chǎn dtɔ̂ng-gaan chom-phûu", english: "I need rose apple.", hindi: "मुझे जामुन फल चाहिए।"),
            WordExample(thai: "วันนี้มีชมพู่", romanization: "wan-níi mii chom-phûu", english: "Today there is rose apple.", hindi: "आज जामुन फल उपलब्ध है।"),
        ],
        1788: [
            WordExample(thai: "ฉันต้องการมะเฟือง", romanization: "chǎn dtɔ̂ng-gaan má-fʉang", english: "I need star fruit.", hindi: "मुझे कमरख चाहिए।"),
            WordExample(thai: "วันนี้มีมะเฟือง", romanization: "wan-níi mii má-fʉang", english: "Today there is star fruit.", hindi: "आज कमरख उपलब्ध है।"),
        ],
        1789: [
            WordExample(thai: "ฉันต้องการมะขามหวาน", romanization: "chǎn dtɔ̂ng-gaan má-khǎam wǎan", english: "I need sweet tamarind.", hindi: "मुझे मीठी इमली चाहिए।"),
            WordExample(thai: "วันนี้มีมะขามหวาน", romanization: "wan-níi mii má-khǎam wǎan", english: "Today there is sweet tamarind.", hindi: "आज मीठी इमली उपलब्ध है।"),
        ],
        1790: [
            WordExample(thai: "ฉันต้องการมะยงชิด", romanization: "chǎn dtɔ̂ng-gaan má-yong-chít", english: "I need Marian plum.", hindi: "मुझे मैरियन प्लम चाहिए।"),
            WordExample(thai: "วันนี้มีมะยงชิด", romanization: "wan-níi mii má-yong-chít", english: "Today there is Marian plum.", hindi: "आज मैरियन प्लम उपलब्ध है।"),
        ],
        1791: [
            WordExample(thai: "ฉันต้องการกระท้อน", romanization: "chǎn dtɔ̂ng-gaan grà-thɔ́ɔn", english: "I need santol fruit.", hindi: "मुझे संतोल फल चाहिए।"),
            WordExample(thai: "วันนี้มีกระท้อน", romanization: "wan-níi mii grà-thɔ́ɔn", english: "Today there is santol fruit.", hindi: "आज संतोल फल उपलब्ध है।"),
        ],
        1792: [
            WordExample(thai: "ฉันต้องการระกำ", romanization: "chǎn dtɔ̂ng-gaan rá-gam", english: "I need snake fruit.", hindi: "मुझे स्नेक फ्रूट चाहिए।"),
            WordExample(thai: "วันนี้มีระกำ", romanization: "wan-níi mii rá-gam", english: "Today there is snake fruit.", hindi: "आज स्नेक फ्रूट उपलब्ध है।"),
        ],
        1793: [
            WordExample(thai: "ฉันต้องการลูกตาล", romanization: "chǎn dtɔ̂ng-gaan lûuk dtaan", english: "I need palmyra palm fruit.", hindi: "मुझे ताड़ का फल चाहिए।"),
            WordExample(thai: "วันนี้มีลูกตาล", romanization: "wan-níi mii lûuk dtaan", english: "Today there is palmyra palm fruit.", hindi: "आज ताड़ का फल उपलब्ध है।"),
        ],
        1794: [
            WordExample(thai: "ฉันต้องการข้าวโพดอ่อน", romanization: "chǎn dtɔ̂ng-gaan khâao phôot ɔ̀ɔn", english: "I need baby corn.", hindi: "मुझे बेबी कॉर्न चाहिए।"),
            WordExample(thai: "วันนี้มีข้าวโพดอ่อน", romanization: "wan-níi mii khâao phôot ɔ̀ɔn", english: "Today there is baby corn.", hindi: "आज बेबी कॉर्न उपलब्ध है।"),
        ],
        1795: [
            WordExample(thai: "ฉันต้องการฟักแม้ว", romanization: "chǎn dtɔ̂ng-gaan fák mɛ̂ɛo", english: "I need chayote squash.", hindi: "मुझे चायोट स्क्वैश चाहिए।"),
            WordExample(thai: "วันนี้มีฟักแม้ว", romanization: "wan-níi mii fák mɛ̂ɛo", english: "Today there is chayote squash.", hindi: "आज चायोट स्क्वैश उपलब्ध है।"),
        ],
        1796: [
            WordExample(thai: "นี่คือห้องโถง", romanization: "nîi khʉʉ hâwng-thǒong", english: "This is entrance hall.", hindi: "यह प्रवेश कक्ष है।"),
            WordExample(thai: "ห้องโถงอยู่ที่นี่", romanization: "hâwng-thǒong yùu thîi nîi", english: "The entrance hall is here.", hindi: "प्रवेश कक्ष यहाँ है।"),
        ],
        1797: [
            WordExample(thai: "นี่คือห้องรับแขก", romanization: "nîi khʉʉ hâwng-ráp-khàek", english: "This is guest room.", hindi: "यह बैठक कक्ष है।"),
            WordExample(thai: "ห้องรับแขกอยู่ที่นี่", romanization: "hâwng-ráp-khàek yùu thîi nîi", english: "The guest room is here.", hindi: "बैठक कक्ष यहाँ है।"),
        ],
        1798: [
            WordExample(thai: "นี่คือห้องอาหาร", romanization: "nîi khʉʉ hâwng-aa-hǎan", english: "This is dining room.", hindi: "यह भोजन कक्ष है।"),
            WordExample(thai: "ห้องอาหารอยู่ที่นี่", romanization: "hâwng-aa-hǎan yùu thîi nîi", english: "The dining room is here.", hindi: "भोजन कक्ष यहाँ है।"),
        ],
        1799: [
            WordExample(thai: "นี่คือห้องทำงาน", romanization: "nîi khʉʉ hâwng-tham-ngaan", english: "This is home office.", hindi: "यह घर का कार्यकक्ष है।"),
            WordExample(thai: "ห้องทำงานอยู่ที่นี่", romanization: "hâwng-tham-ngaan yùu thîi nîi", english: "The home office is here.", hindi: "घर का कार्यकक्ष यहाँ है।"),
        ],
        1800: [
            WordExample(thai: "นี่คือห้องเก็บของ", romanization: "nîi khʉʉ hâwng-kèp-khǎawng", english: "This is storage room.", hindi: "यह भंडार कक्ष है।"),
            WordExample(thai: "ห้องเก็บของอยู่ที่นี่", romanization: "hâwng-kèp-khǎawng yùu thîi nîi", english: "The storage room is here.", hindi: "भंडार कक्ष यहाँ है।"),
        ],
        1801: [
            WordExample(thai: "นี่คือห้องใต้หลังคา", romanization: "nîi khʉʉ hâwng-tâi-lǎng-khaa", english: "This is attic.", hindi: "यह अटारी है।"),
            WordExample(thai: "ห้องใต้หลังคาอยู่ที่นี่", romanization: "hâwng-tâi-lǎng-khaa yùu thîi nîi", english: "The attic is here.", hindi: "अटारी यहाँ है।"),
        ],
        1802: [
            WordExample(thai: "นี่คือห้องแต่งตัว", romanization: "nîi khʉʉ hâwng-tàeng-tua", english: "This is dressing room.", hindi: "यह कपड़े बदलने का कमरा है।"),
            WordExample(thai: "ห้องแต่งตัวอยู่ที่นี่", romanization: "hâwng-tàeng-tua yùu thîi nîi", english: "The dressing room is here.", hindi: "कपड़े बदलने का कमरा यहाँ है।"),
        ],
        1803: [
            WordExample(thai: "นี่คือห้องพระ", romanization: "nîi khʉʉ hâwng-phrá", english: "This is Buddha room.", hindi: "यह पूजा कक्ष है।"),
            WordExample(thai: "ห้องพระอยู่ที่นี่", romanization: "hâwng-phrá yùu thîi nîi", english: "The Buddha room is here.", hindi: "पूजा कक्ष यहाँ है।"),
        ],
        1804: [
            WordExample(thai: "นี่คือห้องนอนใหญ่", romanization: "nîi khʉʉ hâwng-nawn-yài", english: "This is master bedroom.", hindi: "यह मुख्य शयनकक्ष है।"),
            WordExample(thai: "ห้องนอนใหญ่อยู่ที่นี่", romanization: "hâwng-nawn-yài yùu thîi nîi", english: "The master bedroom is here.", hindi: "मुख्य शयनकक्ष यहाँ है।"),
        ],
        1805: [
            WordExample(thai: "นี่คือห้องน้ำแขก", romanization: "nîi khʉʉ hâwng-náam-khàek", english: "This is guest bathroom.", hindi: "यह मेहमान स्नानघर है।"),
            WordExample(thai: "ห้องน้ำแขกอยู่ที่นี่", romanization: "hâwng-náam-khàek yùu thîi nîi", english: "The guest bathroom is here.", hindi: "मेहमान स्नानघर यहाँ है।"),
        ],
        1806: [
            WordExample(thai: "นี่คือห้องซักรีด", romanization: "nîi khʉʉ hâwng-sák-rîit", english: "This is laundry room.", hindi: "यह कपड़े धोने का कमरा है।"),
            WordExample(thai: "ห้องซักรีดอยู่ที่นี่", romanization: "hâwng-sák-rîit yùu thîi nîi", english: "The laundry room is here.", hindi: "कपड़े धोने का कमरा यहाँ है।"),
        ],
        1807: [
            WordExample(thai: "นี่คือห้องครัวเล็ก", romanization: "nîi khʉʉ hâwng-khrua-lék", english: "This is kitchenette.", hindi: "यह छोटा रसोईघर है।"),
            WordExample(thai: "ห้องครัวเล็กอยู่ที่นี่", romanization: "hâwng-khrua-lék yùu thîi nîi", english: "The kitchenette is here.", hindi: "छोटा रसोईघर यहाँ है।"),
        ],
        1808: [
            WordExample(thai: "นี่คือเพิง", romanization: "nîi khʉʉ phoeng", english: "This is shed.", hindi: "यह छप्परनुमा भंडार है।"),
            WordExample(thai: "เพิงอยู่ที่นี่", romanization: "phoeng yùu thîi nîi", english: "The shed is here.", hindi: "छप्परनुमा भंडार यहाँ है।"),
        ],
        1809: [
            WordExample(thai: "นี่คือโรงรถ", romanization: "nîi khʉʉ roong-rót", english: "This is garage.", hindi: "यह गैरेज है।"),
            WordExample(thai: "โรงรถอยู่ที่นี่", romanization: "roong-rót yùu thîi nîi", english: "The garage is here.", hindi: "गैरेज यहाँ है।"),
        ],
        1810: [
            WordExample(thai: "นี่คือทางเดิน", romanization: "nîi khʉʉ thaang-doen", english: "This is corridor.", hindi: "यह गलियारा है।"),
            WordExample(thai: "ทางเดินอยู่ที่นี่", romanization: "thaang-doen yùu thîi nîi", english: "The corridor is here.", hindi: "गलियारा यहाँ है।"),
        ],
        1811: [
            WordExample(thai: "นี่คือมุม", romanization: "nîi khʉʉ mum", english: "This is corner.", hindi: "यह कोना है।"),
            WordExample(thai: "มุมอยู่ที่นี่", romanization: "mum yùu thîi nîi", english: "The corner is here.", hindi: "कोना यहाँ है।"),
        ],
        1812: [
            WordExample(thai: "นี่คือมุมอ่านหนังสือ", romanization: "nîi khʉʉ mum-àan-nǎng-sʉ̌ʉ", english: "This is reading nook.", hindi: "यह पढ़ने का कोना है।"),
            WordExample(thai: "มุมอ่านหนังสืออยู่ที่นี่", romanization: "mum-àan-nǎng-sʉ̌ʉ yùu thîi nîi", english: "The reading nook is here.", hindi: "पढ़ने का कोना यहाँ है।"),
        ],
        1813: [
            WordExample(thai: "นี่คือธรณีประตู", romanization: "nîi khʉʉ thaw-rá-nii prà-tuu", english: "This is door sill.", hindi: "यह दरवाज़े की देहलीज़ है।"),
            WordExample(thai: "ธรณีประตูอยู่ที่นี่", romanization: "thaw-rá-nii prà-tuu yùu thîi nîi", english: "The door sill is here.", hindi: "दरवाज़े की देहलीज़ यहाँ है।"),
        ],
        1814: [
            WordExample(thai: "นี่คือลูกบิดประตู", romanization: "nîi khʉʉ lûuk-bìt prà-tuu", english: "This is doorknob.", hindi: "यह दरवाज़े का हैंडल है।"),
            WordExample(thai: "ลูกบิดประตูอยู่ที่นี่", romanization: "lûuk-bìt prà-tuu yùu thîi nîi", english: "The doorknob is here.", hindi: "दरवाज़े का हैंडल यहाँ है।"),
        ],
        1815: [
            WordExample(thai: "นี่คือกลอนประตู", romanization: "nîi khʉʉ klawn prà-tuu", english: "This is door latch.", hindi: "यह दरवाज़े की कुंडी है।"),
            WordExample(thai: "กลอนประตูอยู่ที่นี่", romanization: "klawn prà-tuu yùu thîi nîi", english: "The door latch is here.", hindi: "दरवाज़े की कुंडी यहाँ है।"),
        ],
        1816: [
            WordExample(thai: "นี่คือมือจับ", romanization: "nîi khʉʉ mʉʉ-jàp", english: "This is handle.", hindi: "यह हैंडल है।"),
            WordExample(thai: "มือจับอยู่ที่นี่", romanization: "mʉʉ-jàp yùu thîi nîi", english: "The handle is here.", hindi: "हैंडल यहाँ है।"),
        ],
        1817: [
            WordExample(thai: "นี่คือบานพับ", romanization: "nîi khʉʉ baan-pháp", english: "This is hinge.", hindi: "यह कब्ज़ा है।"),
            WordExample(thai: "บานพับอยู่ที่นี่", romanization: "baan-pháp yùu thîi nîi", english: "The hinge is here.", hindi: "कब्ज़ा यहाँ है।"),
        ],
        1818: [
            WordExample(thai: "นี่คือมุ้งลวด", romanization: "nîi khʉʉ múng-lûat", english: "This is window screen.", hindi: "यह मच्छर-जाली है।"),
            WordExample(thai: "มุ้งลวดอยู่ที่นี่", romanization: "múng-lûat yùu thîi nîi", english: "The window screen is here.", hindi: "मच्छर-जाली यहाँ है।"),
        ],
        1819: [
            WordExample(thai: "นี่คือมู่ลี่", romanization: "nîi khʉʉ mûu-lîi", english: "This is venetian blinds.", hindi: "यह पट्टीदार परदे है।"),
            WordExample(thai: "มู่ลี่อยู่ที่นี่", romanization: "mûu-lîi yùu thîi nîi", english: "The venetian blinds is here.", hindi: "पट्टीदार परदे यहाँ है।"),
        ],
        1820: [
            WordExample(thai: "นี่คือพรมเช็ดเท้า", romanization: "nîi khʉʉ phrom-chét-tháao", english: "This is doormat.", hindi: "यह पायदान है।"),
            WordExample(thai: "พรมเช็ดเท้าอยู่ที่นี่", romanization: "phrom-chét-tháao yùu thîi nîi", english: "The doormat is here.", hindi: "पायदान यहाँ है।"),
        ],
        1821: [
            WordExample(thai: "นี่คือตะขอ", romanization: "nîi khʉʉ tà-khǎaw", english: "This is hook.", hindi: "यह काँटा है।"),
            WordExample(thai: "ตะขออยู่ที่นี่", romanization: "tà-khǎaw yùu thîi nîi", english: "The hook is here.", hindi: "काँटा यहाँ है।"),
        ],
        1822: [
            WordExample(thai: "นี่คือราวแขวนผ้า", romanization: "nîi khʉʉ raao-khwǎen-phâa", english: "This is clothes rail.", hindi: "यह कपड़े टाँगने की रॉड है।"),
            WordExample(thai: "ราวแขวนผ้าอยู่ที่นี่", romanization: "raao-khwǎen-phâa yùu thîi nîi", english: "The clothes rail is here.", hindi: "कपड़े टाँगने की रॉड यहाँ है।"),
        ],
        1823: [
            WordExample(thai: "นี่คือไม้แขวนเสื้อ", romanization: "nîi khʉʉ máai-khwǎen-sʉ̂ʉa", english: "This is clothes hanger.", hindi: "यह कपड़े का हैंगर है।"),
            WordExample(thai: "ไม้แขวนเสื้ออยู่ที่นี่", romanization: "máai-khwǎen-sʉ̂ʉa yùu thîi nîi", english: "The clothes hanger is here.", hindi: "कपड़े का हैंगर यहाँ है।"),
        ],
        1824: [
            WordExample(thai: "นี่คือตู้รองเท้า", romanization: "nîi khʉʉ tûu-rawng-tháao", english: "This is shoe cabinet.", hindi: "यह जूते की अलमारी है।"),
            WordExample(thai: "ตู้รองเท้าอยู่ที่นี่", romanization: "tûu-rawng-tháao yùu thîi nîi", english: "The shoe cabinet is here.", hindi: "जूते की अलमारी यहाँ है।"),
        ],
        1825: [
            WordExample(thai: "นี่คือตู้โชว์", romanization: "nîi khʉʉ tûu-choo", english: "This is display cabinet.", hindi: "यह प्रदर्शन अलमारी है।"),
            WordExample(thai: "ตู้โชว์อยู่ที่นี่", romanization: "tûu-choo yùu thîi nîi", english: "The display cabinet is here.", hindi: "प्रदर्शन अलमारी यहाँ है।"),
        ],
        1826: [
            WordExample(thai: "นี่คือตู้เซฟ", romanization: "nîi khʉʉ tûu-sèep", english: "This is safe.", hindi: "यह तिजोरी है।"),
            WordExample(thai: "ตู้เซฟอยู่ที่นี่", romanization: "tûu-sèep yùu thîi nîi", english: "The safe is here.", hindi: "तिजोरी यहाँ है।"),
        ],
        1827: [
            WordExample(thai: "นี่คือชั้นหนังสือ", romanization: "nîi khʉʉ chán-nǎng-sʉ̌ʉ", english: "This is bookshelf.", hindi: "यह किताबों की अलमारी है।"),
            WordExample(thai: "ชั้นหนังสืออยู่ที่นี่", romanization: "chán-nǎng-sʉ̌ʉ yùu thîi nîi", english: "The bookshelf is here.", hindi: "किताबों की अलमारी यहाँ है।"),
        ],
        1828: [
            WordExample(thai: "นี่คือโต๊ะข้างเตียง", romanization: "nîi khʉʉ tó-khâang-tiiang", english: "This is bedside table.", hindi: "यह बिस्तर के पास की मेज़ है।"),
            WordExample(thai: "โต๊ะข้างเตียงอยู่ที่นี่", romanization: "tó-khâang-tiiang yùu thîi nîi", english: "The bedside table is here.", hindi: "बिस्तर के पास की मेज़ यहाँ है।"),
        ],
        1829: [
            WordExample(thai: "นี่คือเก้าอี้นวม", romanization: "nîi khʉʉ kâo-îi-nuam", english: "This is upholstered chair.", hindi: "यह गद्दीदार कुर्सी है।"),
            WordExample(thai: "เก้าอี้นวมอยู่ที่นี่", romanization: "kâo-îi-nuam yùu thîi nîi", english: "The upholstered chair is here.", hindi: "गद्दीदार कुर्सी यहाँ है।"),
        ],
        1830: [
            WordExample(thai: "นี่คือเก้าอี้โยก", romanization: "nîi khʉʉ kâo-îi-yôok", english: "This is rocking chair.", hindi: "यह झूलने वाली कुर्सी है।"),
            WordExample(thai: "เก้าอี้โยกอยู่ที่นี่", romanization: "kâo-îi-yôok yùu thîi nîi", english: "The rocking chair is here.", hindi: "झूलने वाली कुर्सी यहाँ है।"),
        ],
        1831: [
            WordExample(thai: "นี่คือฟูก", romanization: "nîi khʉʉ fûuk", english: "This is mattress.", hindi: "यह गद्दा है।"),
            WordExample(thai: "ฟูกอยู่ที่นี่", romanization: "fûuk yùu thîi nîi", english: "The mattress is here.", hindi: "गद्दा यहाँ है।"),
        ],
        1832: [
            WordExample(thai: "นี่คือผ้าปูที่นอน", romanization: "nîi khʉʉ phâa-puu-thîi-nawn", english: "This is bed sheet.", hindi: "यह चादर है।"),
            WordExample(thai: "ผ้าปูที่นอนอยู่ที่นี่", romanization: "phâa-puu-thîi-nawn yùu thîi nîi", english: "The bed sheet is here.", hindi: "चादर यहाँ है।"),
        ],
        1833: [
            WordExample(thai: "นี่คือปลอกหมอน", romanization: "nîi khʉʉ plàawk-mǎawn", english: "This is pillowcase.", hindi: "यह तकिए का गिलाफ है।"),
            WordExample(thai: "ปลอกหมอนอยู่ที่นี่", romanization: "plàawk-mǎawn yùu thîi nîi", english: "The pillowcase is here.", hindi: "तकिए का गिलाफ यहाँ है।"),
        ],
        1834: [
            WordExample(thai: "นี่คือผ้านวม", romanization: "nîi khʉʉ phâa-nuam", english: "This is duvet.", hindi: "यह रजाई है।"),
            WordExample(thai: "ผ้านวมอยู่ที่นี่", romanization: "phâa-nuam yùu thîi nîi", english: "The duvet is here.", hindi: "रजाई यहाँ है।"),
        ],
        1835: [
            WordExample(thai: "นี่คือผ้าม่าน", romanization: "nîi khʉʉ phâa-mâan", english: "This is curtain fabric.", hindi: "यह परदे का कपड़ा है।"),
            WordExample(thai: "ผ้าม่านอยู่ที่นี่", romanization: "phâa-mâan yùu thîi nîi", english: "The curtain fabric is here.", hindi: "परदे का कपड़ा यहाँ है।"),
        ],
        1836: [
            WordExample(thai: "นี่คือพัดลมเพดาน", romanization: "nîi khʉʉ phát-lom-pheedaan", english: "This is ceiling fan.", hindi: "यह छत का पंखा है।"),
            WordExample(thai: "พัดลมเพดานอยู่ที่นี่", romanization: "phát-lom-pheedaan yùu thîi nîi", english: "The ceiling fan is here.", hindi: "छत का पंखा यहाँ है।"),
        ],
        1837: [
            WordExample(thai: "นี่คือสวิตช์ไฟ", romanization: "nîi khʉʉ sà-wít-fai", english: "This is light switch.", hindi: "यह बिजली का स्विच है।"),
            WordExample(thai: "สวิตช์ไฟอยู่ที่นี่", romanization: "sà-wít-fai yùu thîi nîi", english: "The light switch is here.", hindi: "बिजली का स्विच यहाँ है।"),
        ],
        1838: [
            WordExample(thai: "นี่คือปลั๊กพ่วง", romanization: "nîi khʉʉ plák-phûang", english: "This is power strip.", hindi: "यह मल्टीप्लग है।"),
            WordExample(thai: "ปลั๊กพ่วงอยู่ที่นี่", romanization: "plák-phûang yùu thîi nîi", english: "The power strip is here.", hindi: "मल्टीप्लग यहाँ है।"),
        ],
        1839: [
            WordExample(thai: "นี่คือเครื่องกรองน้ำ", romanization: "nîi khʉʉ khrʉ̂ang-krawng-náam", english: "This is water filter.", hindi: "यह पानी का फ़िल्टर है।"),
            WordExample(thai: "เครื่องกรองน้ำอยู่ที่นี่", romanization: "khrʉ̂ang-krawng-náam yùu thîi nîi", english: "The water filter is here.", hindi: "पानी का फ़िल्टर यहाँ है।"),
        ],
        1840: [
            WordExample(thai: "นี่คือถังแก๊ส", romanization: "nîi khʉʉ thǎng-káet", english: "This is gas cylinder.", hindi: "यह गैस सिलेंडर है।"),
            WordExample(thai: "ถังแก๊สอยู่ที่นี่", romanization: "thǎng-káet yùu thîi nîi", english: "The gas cylinder is here.", hindi: "गैस सिलेंडर यहाँ है।"),
        ],
        1841: [
            WordExample(thai: "นี่คือเครื่องดูดควัน", romanization: "nîi khʉʉ khrʉ̂ang-dùut-khwan", english: "This is range hood.", hindi: "यह रसोई धुआँ-निकास है।"),
            WordExample(thai: "เครื่องดูดควันอยู่ที่นี่", romanization: "khrʉ̂ang-dùut-khwan yùu thîi nîi", english: "The range hood is here.", hindi: "रसोई धुआँ-निकास यहाँ है।"),
        ],
        1842: [
            WordExample(thai: "ฉันดูดฝุ่น", romanization: "chǎn dùut-fùn", english: "I vacuum clean.", hindi: "मैं वैक्यूम करना।"),
            WordExample(thai: "เขาดูดฝุ่น", romanization: "khǎo dùut-fùn", english: "He or she will vacuum clean.", hindi: "वह वैक्यूम करना।"),
        ],
        1843: [
            WordExample(thai: "ฉันเช็ดฝุ่น", romanization: "chǎn chét-fùn", english: "I dust surfaces.", hindi: "मैं धूल पोंछना।"),
            WordExample(thai: "เขาเช็ดฝุ่น", romanization: "khǎo chét-fùn", english: "He or she will dust surfaces.", hindi: "वह धूल पोंछना।"),
        ],
        1844: [
            WordExample(thai: "ฉันขัดพื้น", romanization: "chǎn khàt-phʉ́ʉn", english: "I scrub the floor.", hindi: "मैं फर्श रगड़ना।"),
            WordExample(thai: "เขาขัดพื้น", romanization: "khǎo khàt-phʉ́ʉn", english: "He or she will scrub the floor.", hindi: "वह फर्श रगड़ना।"),
        ],
        1845: [
            WordExample(thai: "ฉันถูพื้น", romanization: "chǎn thǔu-phʉ́ʉn", english: "I mop the floor.", hindi: "मैं फर्श पोछना।"),
            WordExample(thai: "เขาถูพื้น", romanization: "khǎo thǔu-phʉ́ʉn", english: "He or she will mop the floor.", hindi: "वह फर्श पोछना।"),
        ],
        1846: [
            WordExample(thai: "ฉันกวาดใบไม้", romanization: "chǎn kwàat-bai-máai", english: "I sweep leaves.", hindi: "मैं पत्ते बुहारना।"),
            WordExample(thai: "เขากวาดใบไม้", romanization: "khǎo kwàat-bai-máai", english: "He or she will sweep leaves.", hindi: "वह पत्ते बुहारना।"),
        ],
        1847: [
            WordExample(thai: "ฉันเก็บที่นอน", romanization: "chǎn kèp-thîi-nawn", english: "I make the bed.", hindi: "मैं बिस्तर समेटना।"),
            WordExample(thai: "เขาเก็บที่นอน", romanization: "khǎo kèp-thîi-nawn", english: "He or she will make the bed.", hindi: "वह बिस्तर समेटना।"),
        ],
        1848: [
            WordExample(thai: "ฉันเปลี่ยนผ้าปูที่นอน", romanization: "chǎn plìan-phâa-puu-thîi-nawn", english: "I change bed sheets.", hindi: "मैं चादर बदलना।"),
            WordExample(thai: "เขาเปลี่ยนผ้าปูที่นอน", romanization: "khǎo plìan-phâa-puu-thîi-nawn", english: "He or she will change bed sheets.", hindi: "वह चादर बदलना।"),
        ],
        1849: [
            WordExample(thai: "ฉันพับผ้าห่ม", romanization: "chǎn pháp-phâa-hòm", english: "I fold a blanket.", hindi: "मैं कंबल तह करना।"),
            WordExample(thai: "เขาพับผ้าห่ม", romanization: "khǎo pháp-phâa-hòm", english: "He or she will fold a blanket.", hindi: "वह कंबल तह करना।"),
        ],
        1850: [
            WordExample(thai: "ฉันตากผ้าขนหนู", romanization: "chǎn tàak-phâa-khǒn-nǔu", english: "I hang towels to dry.", hindi: "मैं तौलिए सुखाना।"),
            WordExample(thai: "เขาตากผ้าขนหนู", romanization: "khǎo tàak-phâa-khǒn-nǔu", english: "He or she will hang towels to dry.", hindi: "वह तौलिए सुखाना।"),
        ],
        1851: [
            WordExample(thai: "ฉันรีดเสื้อ", romanization: "chǎn rîit-sʉ̂ʉa", english: "I iron a shirt.", hindi: "मैं कमीज़ इस्त्री करना।"),
            WordExample(thai: "เขารีดเสื้อ", romanization: "khǎo rîit-sʉ̂ʉa", english: "He or she will iron a shirt.", hindi: "वह कमीज़ इस्त्री करना।"),
        ],
        1852: [
            WordExample(thai: "ฉันซ่อม", romanization: "chǎn sâawm", english: "I repair.", hindi: "मैं मरम्मत करना।"),
            WordExample(thai: "เขาซ่อม", romanization: "khǎo sâawm", english: "He or she will repair.", hindi: "वह मरम्मत करना।"),
        ],
        1853: [
            WordExample(thai: "ฉันซ่อมแซม", romanization: "chǎn sâawm-sǎaem", english: "I mend.", hindi: "मैं ठीक करना।"),
            WordExample(thai: "เขาซ่อมแซม", romanization: "khǎo sâawm-sǎaem", english: "He or she will mend.", hindi: "वह ठीक करना।"),
        ],
        1854: [
            WordExample(thai: "ฉันเปลี่ยนหลอดไฟ", romanization: "chǎn plìan-làawt-fai", english: "I replace a light bulb.", hindi: "मैं बल्ब बदलना।"),
            WordExample(thai: "เขาเปลี่ยนหลอดไฟ", romanization: "khǎo plìan-làawt-fai", english: "He or she will replace a light bulb.", hindi: "वह बल्ब बदलना।"),
        ],
        1855: [
            WordExample(thai: "ฉันอุดรอยรั่ว", romanization: "chǎn ùt-rawi-rûa", english: "I seal a leak.", hindi: "मैं रिसाव बंद करना।"),
            WordExample(thai: "เขาอุดรอยรั่ว", romanization: "khǎo ùt-rawi-rûa", english: "He or she will seal a leak.", hindi: "वह रिसाव बंद करना।"),
        ],
        1856: [
            WordExample(thai: "ฉันล้างห้องน้ำ", romanization: "chǎn láang-hâwng-náam", english: "I clean the bathroom.", hindi: "मैं स्नानघर साफ़ करना।"),
            WordExample(thai: "เขาล้างห้องน้ำ", romanization: "khǎo láang-hâwng-náam", english: "He or she will clean the bathroom.", hindi: "वह स्नानघर साफ़ करना।"),
        ],
        1857: [
            WordExample(thai: "ฉันล้างอ่างล้างจาน", romanization: "chǎn láang-àang-láang-jaan", english: "I clean the sink.", hindi: "मैं सिंक साफ़ करना।"),
            WordExample(thai: "เขาล้างอ่างล้างจาน", romanization: "khǎo láang-àang-láang-jaan", english: "He or she will clean the sink.", hindi: "वह सिंक साफ़ करना।"),
        ],
        1858: [
            WordExample(thai: "ฉันแช่ผ้า", romanization: "chǎn châe-phâa", english: "I soak laundry.", hindi: "मैं कपड़े भिगोना।"),
            WordExample(thai: "เขาแช่ผ้า", romanization: "khǎo châe-phâa", english: "He or she will soak laundry.", hindi: "वह कपड़े भिगोना।"),
        ],
        1859: [
            WordExample(thai: "ฉันบิดผ้า", romanization: "chǎn bìt-phâa", english: "I wring clothes.", hindi: "मैं कपड़े निचोड़ना।"),
            WordExample(thai: "เขาบิดผ้า", romanization: "khǎo bìt-phâa", english: "He or she will wring clothes.", hindi: "वह कपड़े निचोड़ना।"),
        ],
        1860: [
            WordExample(thai: "ฉันตากแดด", romanization: "chǎn tàak-dàet", english: "I sun-dry.", hindi: "मैं धूप में सुखाना।"),
            WordExample(thai: "เขาตากแดด", romanization: "khǎo tàak-dàet", english: "He or she will sun-dry.", hindi: "वह धूप में सुखाना।"),
        ],
        1861: [
            WordExample(thai: "ฉันแยกขยะ", romanization: "chǎn yâek-khàyà", english: "I sort waste.", hindi: "मैं कचरा अलग करना।"),
            WordExample(thai: "เขาแยกขยะ", romanization: "khǎo yâek-khàyà", english: "He or she will sort waste.", hindi: "वह कचरा अलग करना।"),
        ],
        1862: [
            WordExample(thai: "ฉันรีไซเคิล", romanization: "chǎn rii-sai-khoen", english: "I recycle.", hindi: "मैं पुनर्चक्रण करना।"),
            WordExample(thai: "เขารีไซเคิล", romanization: "khǎo rii-sai-khoen", english: "He or she will recycle.", hindi: "वह पुनर्चक्रण करना।"),
        ],
        1863: [
            WordExample(thai: "ฉันทิ้งขยะ", romanization: "chǎn thíng-khàyà", english: "I throw away trash.", hindi: "मैं कचरा फेंकना।"),
            WordExample(thai: "เขาทิ้งขยะ", romanization: "khǎo thíng-khàyà", english: "He or she will throw away trash.", hindi: "वह कचरा फेंकना।"),
        ],
        1864: [
            WordExample(thai: "ฉันผูกถุงขยะ", romanization: "chǎn phùuk-thǔng-khàyà", english: "I tie a garbage bag.", hindi: "मैं कूड़े की थैली बाँधना।"),
            WordExample(thai: "เขาผูกถุงขยะ", romanization: "khǎo phùuk-thǔng-khàyà", english: "He or she will tie a garbage bag.", hindi: "वह कूड़े की थैली बाँधना।"),
        ],
        1865: [
            WordExample(thai: "ฉันรดน้ำต้นไม้", romanization: "chǎn rót-náam-tôn-máai", english: "I water plants.", hindi: "मैं पौधों को पानी देना।"),
            WordExample(thai: "เขารดน้ำต้นไม้", romanization: "khǎo rót-náam-tôn-máai", english: "He or she will water plants.", hindi: "वह पौधों को पानी देना।"),
        ],
        1866: [
            WordExample(thai: "ฉันตัดแต่งกิ่งไม้", romanization: "chǎn tàt-tàeng-kìng-máai", english: "I prune branches.", hindi: "मैं टहनियाँ छाँटना।"),
            WordExample(thai: "เขาตัดแต่งกิ่งไม้", romanization: "khǎo tàt-tàeng-kìng-máai", english: "He or she will prune branches.", hindi: "वह टहनियाँ छाँटना।"),
        ],
        1867: [
            WordExample(thai: "ฉันถอนวัชพืช", romanization: "chǎn thǎawn-wát-chá-phʉ̂ʉt", english: "I pull weeds.", hindi: "मैं खरपतवार निकालना।"),
            WordExample(thai: "เขาถอนวัชพืช", romanization: "khǎo thǎawn-wát-chá-phʉ̂ʉt", english: "He or she will pull weeds.", hindi: "वह खरपतवार निकालना।"),
        ],
        1868: [
            WordExample(thai: "ฉันพรวนดิน", romanization: "chǎn phruan-din", english: "I loosen soil.", hindi: "मैं मिट्टी गुड़ाई करना।"),
            WordExample(thai: "เขาพรวนดิน", romanization: "khǎo phruan-din", english: "He or she will loosen soil.", hindi: "वह मिट्टी गुड़ाई करना।"),
        ],
        1869: [
            WordExample(thai: "ฉันกดชักโครก", romanization: "chǎn kòt-chák-khrôok", english: "I flush the toilet.", hindi: "मैं फ़्लश करना।"),
            WordExample(thai: "เขากดชักโครก", romanization: "khǎo kòt-chák-khrôok", english: "He or she will flush the toilet.", hindi: "वह फ़्लश करना।"),
        ],
        1870: [
            WordExample(thai: "ฉันล้างรถ", romanization: "chǎn láang-rót", english: "I wash a car.", hindi: "मैं कार धोना।"),
            WordExample(thai: "เขาล้างรถ", romanization: "khǎo láang-rót", english: "He or she will wash a car.", hindi: "वह कार धोना।"),
        ],
        1871: [
            WordExample(thai: "ฉันเติมน้ำมัน", romanization: "chǎn toem-náam-man", english: "I refill fuel.", hindi: "मैं ईंधन भरना।"),
            WordExample(thai: "เขาเติมน้ำมัน", romanization: "khǎo toem-náam-man", english: "He or she will refill fuel.", hindi: "वह ईंधन भरना।"),
        ],
        1872: [
            WordExample(thai: "ฉันจัดโต๊ะ", romanization: "chǎn jàt-tó", english: "I set the table.", hindi: "मैं मेज़ सजाना।"),
            WordExample(thai: "เขาจัดโต๊ะ", romanization: "khǎo jàt-tó", english: "He or she will set the table.", hindi: "वह मेज़ सजाना।"),
        ],
        1873: [
            WordExample(thai: "ฉันล้างแก้ว", romanization: "chǎn láang-kâeo", english: "I wash glasses.", hindi: "मैं गिलास धोना।"),
            WordExample(thai: "เขาล้างแก้ว", romanization: "khǎo láang-kâeo", english: "He or she will wash glasses.", hindi: "वह गिलास धोना।"),
        ],
        1874: [
            WordExample(thai: "ฉันเก็บจาน", romanization: "chǎn kèp-jaan", english: "I clear the dishes.", hindi: "मैं बर्तन हटाना।"),
            WordExample(thai: "เขาเก็บจาน", romanization: "khǎo kèp-jaan", english: "He or she will clear the dishes.", hindi: "वह बर्तन हटाना।"),
        ],
        1875: [
            WordExample(thai: "ฉันลับมีด", romanization: "chǎn láp-mîit", english: "I sharpen a knife.", hindi: "मैं चाकू तेज़ करना।"),
            WordExample(thai: "เขาลับมีด", romanization: "khǎo láp-mîit", english: "He or she will sharpen a knife.", hindi: "वह चाकू तेज़ करना।"),
        ],
        1876: [
            WordExample(thai: "ฉันเปิดหน้าต่าง", romanization: "chǎn pòet-nâa-tàang", english: "I open a window.", hindi: "मैं खिड़की खोलना।"),
            WordExample(thai: "เขาเปิดหน้าต่าง", romanization: "khǎo pòet-nâa-tàang", english: "He or she will open a window.", hindi: "वह खिड़की खोलना।"),
        ],
        1877: [
            WordExample(thai: "ฉันปิดม่าน", romanization: "chǎn pìt-mâan", english: "I draw the curtains.", hindi: "मैं परदे बंद करना।"),
            WordExample(thai: "เขาปิดม่าน", romanization: "khǎo pìt-mâan", english: "He or she will draw the curtains.", hindi: "वह परदे बंद करना।"),
        ],
        1878: [
            WordExample(thai: "ฉันล็อกประตู", romanization: "chǎn lɔ́k-prà-tuu", english: "I lock the door.", hindi: "मैं दरवाज़ा बंद करना।"),
            WordExample(thai: "เขาล็อกประตู", romanization: "khǎo lɔ́k-prà-tuu", english: "He or she will lock the door.", hindi: "वह दरवाज़ा बंद करना।"),
        ],
        1879: [
            WordExample(thai: "ฉันไขกุญแจ", romanization: "chǎn khǎi-kun-jaae", english: "I unlock with a key.", hindi: "मैं चाबी से खोलना।"),
            WordExample(thai: "เขาไขกุญแจ", romanization: "khǎo khǎi-kun-jaae", english: "He or she will unlock with a key.", hindi: "वह चाबी से खोलना।"),
        ],
        1880: [
            WordExample(thai: "ฉันชาร์จแบตเตอรี่", romanization: "chǎn châat-bàet-dtə-rii", english: "I charge a battery.", hindi: "मैं बैटरी चार्ज करना।"),
            WordExample(thai: "เขาชาร์จแบตเตอรี่", romanization: "khǎo châat-bàet-dtə-rii", english: "He or she will charge a battery.", hindi: "वह बैटरी चार्ज करना।"),
        ],
        1881: [
            WordExample(thai: "ฉันเสียบปลั๊ก", romanization: "chǎn sìap-plák", english: "I plug in.", hindi: "मैं प्लग लगाना।"),
            WordExample(thai: "เขาเสียบปลั๊ก", romanization: "khǎo sìap-plák", english: "He or she will plug in.", hindi: "वह प्लग लगाना।"),
        ],
        1882: [
            WordExample(thai: "ฉันถอดปลั๊ก", romanization: "chǎn thàawt-plák", english: "I unplug.", hindi: "मैं प्लग निकालना।"),
            WordExample(thai: "เขาถอดปลั๊ก", romanization: "khǎo thàawt-plák", english: "He or she will unplug.", hindi: "वह प्लग निकालना।"),
        ],
        1883: [
            WordExample(thai: "ฉันกดกริ่ง", romanization: "chǎn kòt-krìng", english: "I ring the doorbell.", hindi: "मैं घंटी बजाना।"),
            WordExample(thai: "เขากดกริ่ง", romanization: "khǎo kòt-krìng", english: "He or she will ring the doorbell.", hindi: "वह घंटी बजाना।"),
        ],
        1884: [
            WordExample(thai: "ฉันรับพัสดุ", romanization: "chǎn ráp-phát-dù", english: "I receive a parcel.", hindi: "मैं पार्सल लेना।"),
            WordExample(thai: "เขารับพัสดุ", romanization: "khǎo ráp-phát-dù", english: "He or she will receive a parcel.", hindi: "वह पार्सल लेना।"),
        ],
        1885: [
            WordExample(thai: "ฉันแกะพัสดุ", romanization: "chǎn kàe-phát-dù", english: "I unpack a parcel.", hindi: "मैं पार्सल खोलना।"),
            WordExample(thai: "เขาแกะพัสดุ", romanization: "khǎo kàe-phát-dù", english: "He or she will unpack a parcel.", hindi: "वह पार्सल खोलना।"),
        ],
        1886: [
            WordExample(thai: "ฉันย้ายเฟอร์นิเจอร์", romanization: "chǎn yáai-foe-ní-choe", english: "I move furniture.", hindi: "मैं फर्नीचर हटाना।"),
            WordExample(thai: "เขาย้ายเฟอร์นิเจอร์", romanization: "khǎo yáai-foe-ní-choe", english: "He or she will move furniture.", hindi: "वह फर्नीचर हटाना।"),
        ],
        1887: [
            WordExample(thai: "ฉันประกอบ", romanization: "chǎn prà-kàawp", english: "I assemble.", hindi: "मैं जोड़कर बनाना।"),
            WordExample(thai: "เขาประกอบ", romanization: "khǎo prà-kàawp", english: "He or she will assemble.", hindi: "वह जोड़कर बनाना।"),
        ],
        1888: [
            WordExample(thai: "ฉันติดตั้ง", romanization: "chǎn tìt-tâng", english: "I install.", hindi: "मैं स्थापित करना।"),
            WordExample(thai: "เขาติดตั้ง", romanization: "khǎo tìt-tâng", english: "He or she will install.", hindi: "वह स्थापित करना।"),
        ],
        1889: [
            WordExample(thai: "ฉันวัดขนาด", romanization: "chǎn wát-khà-nàat", english: "I measure dimensions.", hindi: "मैं माप लेना।"),
            WordExample(thai: "เขาวัดขนาด", romanization: "khǎo wát-khà-nàat", english: "He or she will measure dimensions.", hindi: "वह माप लेना।"),
        ],
        1890: [
            WordExample(thai: "นี่คือขนาด", romanization: "nîi khʉʉ khà-nàat", english: "This is size; dimensions.", hindi: "यह आकार; माप है।"),
            WordExample(thai: "ขนาดอยู่ที่นี่", romanization: "khà-nàat yùu thîi nîi", english: "The size; dimensions is here.", hindi: "आकार; माप यहाँ है।"),
        ],
        1891: [
            WordExample(thai: "นี่คือกว้างขวาง", romanization: "nîi khʉʉ kwâang-khwǎang", english: "This is spacious.", hindi: "यह विशाल है।"),
            WordExample(thai: "กว้างขวางอยู่ที่นี่", romanization: "kwâang-khwǎang yùu thîi nîi", english: "The spacious is here.", hindi: "विशाल यहाँ है।"),
        ],
        1892: [
            WordExample(thai: "นี่คือคับแคบ", romanization: "nîi khʉʉ kháp-khâep", english: "This is cramped.", hindi: "यह तंग है।"),
            WordExample(thai: "คับแคบอยู่ที่นี่", romanization: "kháp-khâep yùu thîi nîi", english: "The cramped is here.", hindi: "तंग यहाँ है।"),
        ],
        1893: [
            WordExample(thai: "นี่คือเป็นระเบียบ", romanization: "nîi khʉʉ pen-rá-bìap", english: "This is orderly.", hindi: "यह सुव्यवस्थित है।"),
            WordExample(thai: "เป็นระเบียบอยู่ที่นี่", romanization: "pen-rá-bìap yùu thîi nîi", english: "The orderly is here.", hindi: "सुव्यवस्थित यहाँ है।"),
        ],
        1894: [
            WordExample(thai: "นี่คือรก", romanization: "nîi khʉʉ rók", english: "This is cluttered.", hindi: "यह बिखरा हुआ है।"),
            WordExample(thai: "รกอยู่ที่นี่", romanization: "rók yùu thîi nîi", english: "The cluttered is here.", hindi: "बिखरा हुआ यहाँ है।"),
        ],
        1895: [
            WordExample(thai: "นี่คือเรียบร้อย", romanization: "nîi khʉʉ rîap-ráawy", english: "This is neat; proper.", hindi: "यह साफ़-सुथरा है।"),
            WordExample(thai: "เรียบร้อยอยู่ที่นี่", romanization: "rîap-ráawy yùu thîi nîi", english: "The neat; proper is here.", hindi: "साफ़-सुथरा यहाँ है।"),
        ],
        1896: [
            WordExample(thai: "นี่คือมิดชิด", romanization: "nîi khʉʉ mít-chít", english: "This is well covered; private.", hindi: "यह ढका हुआ; निजी है।"),
            WordExample(thai: "มิดชิดอยู่ที่นี่", romanization: "mít-chít yùu thîi nîi", english: "The well covered; private is here.", hindi: "ढका हुआ; निजी यहाँ है।"),
        ],
        1897: [
            WordExample(thai: "นี่คือโปร่ง", romanization: "nîi khʉʉ pròng", english: "This is airy.", hindi: "यह हवादार है।"),
            WordExample(thai: "โปร่งอยู่ที่นี่", romanization: "pròng yùu thîi nîi", english: "The airy is here.", hindi: "हवादार यहाँ है।"),
        ],
        1898: [
            WordExample(thai: "นี่คือทึบ", romanization: "nîi khʉʉ thʉ́p", english: "This is opaque; stuffy.", hindi: "यह अपारदर्शी; घुटनभरा है।"),
            WordExample(thai: "ทึบอยู่ที่นี่", romanization: "thʉ́p yùu thîi nîi", english: "The opaque; stuffy is here.", hindi: "अपारदर्शी; घुटनभरा यहाँ है।"),
        ],
        1899: [
            WordExample(thai: "นี่คือสว่าง", romanization: "nîi khʉʉ sà-wàang", english: "This is bright.", hindi: "यह उजला है।"),
            WordExample(thai: "สว่างอยู่ที่นี่", romanization: "sà-wàang yùu thîi nîi", english: "The bright is here.", hindi: "उजला यहाँ है।"),
        ],
        1900: [
            WordExample(thai: "นี่คือมืด", romanization: "nîi khʉʉ mʉ̂ʉt", english: "This is dark.", hindi: "यह अंधेरा है।"),
            WordExample(thai: "มืดอยู่ที่นี่", romanization: "mʉ̂ʉt yùu thîi nîi", english: "The dark is here.", hindi: "अंधेरा यहाँ है।"),
        ],
        1901: [
            WordExample(thai: "นี่คือเงียบสงบ", romanization: "nîi khʉʉ ngîap-sà-ngòp", english: "This is quiet and peaceful.", hindi: "यह शांत है।"),
            WordExample(thai: "เงียบสงบอยู่ที่นี่", romanization: "ngîap-sà-ngòp yùu thîi nîi", english: "The quiet and peaceful is here.", hindi: "शांत यहाँ है।"),
        ],
        1902: [
            WordExample(thai: "นี่คือวุ่นวาย", romanization: "nîi khʉʉ wûn-waai", english: "This is chaotic; busy.", hindi: "यह अव्यवस्थित; व्यस्त है।"),
            WordExample(thai: "วุ่นวายอยู่ที่นี่", romanization: "wûn-waai yùu thîi nîi", english: "The chaotic; busy is here.", hindi: "अव्यवस्थित; व्यस्त यहाँ है।"),
        ],
        1903: [
            WordExample(thai: "ฉันปลอดภัย", romanization: "chǎn plàawt-phai", english: "I safe.", hindi: "मैं सुरक्षित।"),
            WordExample(thai: "เขาปลอดภัย", romanization: "khǎo plàawt-phai", english: "He or she will safe.", hindi: "वह सुरक्षित।"),
        ],
        1904: [
            WordExample(thai: "ฉันเสี่ยง", romanization: "chǎn sìang", english: "I risky.", hindi: "मैं जोखिमभरा।"),
            WordExample(thai: "เขาเสี่ยง", romanization: "khǎo sìang", english: "He or she will risky.", hindi: "वह जोखिमभरा।"),
        ],
        1905: [
            WordExample(thai: "นี่คือแน่นหนา", romanization: "nîi khʉʉ nâen-nǎa", english: "This is secure; firm.", hindi: "यह मजबूत; सुरक्षित है।"),
            WordExample(thai: "แน่นหนาอยู่ที่นี่", romanization: "nâen-nǎa yùu thîi nîi", english: "The secure; firm is here.", hindi: "मजबूत; सुरक्षित यहाँ है।"),
        ],
        1906: [
            WordExample(thai: "นี่คือชำรุด", romanization: "nîi khʉʉ cham-rút", english: "This is damaged; defective.", hindi: "यह क्षतिग्रस्त है।"),
            WordExample(thai: "ชำรุดอยู่ที่นี่", romanization: "cham-rút yùu thîi nîi", english: "The damaged; defective is here.", hindi: "क्षतिग्रस्त यहाँ है।"),
        ],
        1907: [
            WordExample(thai: "นี่คือแตกหัก", romanization: "nîi khʉʉ tàek-hàk", english: "This is broken.", hindi: "यह टूटा हुआ है।"),
            WordExample(thai: "แตกหักอยู่ที่นี่", romanization: "tàek-hàk yùu thîi nîi", english: "The broken is here.", hindi: "टूटा हुआ यहाँ है।"),
        ],
        1908: [
            WordExample(thai: "นี่คือคม", romanization: "nîi khʉʉ khom", english: "This is sharp.", hindi: "यह तेज़ है।"),
            WordExample(thai: "คมอยู่ที่นี่", romanization: "khom yùu thîi nîi", english: "The sharp is here.", hindi: "तेज़ यहाँ है।"),
        ],
        1909: [
            WordExample(thai: "ฉันลื่น", romanization: "chǎn lʉ̂ʉn", english: "I slippery.", hindi: "मैं फिसलन भरा।"),
            WordExample(thai: "เขาลื่น", romanization: "khǎo lʉ̂ʉn", english: "He or she will slippery.", hindi: "वह फिसलन भरा।"),
        ],
        1910: [
            WordExample(thai: "นี่คือเหนียวแน่น", romanization: "nîi khʉʉ nǐao-nâen", english: "This is tight; solid.", hindi: "यह मज़बूत है।"),
            WordExample(thai: "เหนียวแน่นอยู่ที่นี่", romanization: "nǐao-nâen yùu thîi nîi", english: "The tight; solid is here.", hindi: "मज़बूत यहाँ है।"),
        ],
        1911: [
            WordExample(thai: "นี่คือเปราะ", romanization: "nîi khʉʉ pràw", english: "This is fragile.", hindi: "यह नाज़ुक है।"),
            WordExample(thai: "เปราะอยู่ที่นี่", romanization: "pràw yùu thîi nîi", english: "The fragile is here.", hindi: "नाज़ुक यहाँ है।"),
        ],
        1912: [
            WordExample(thai: "นี่คือหยัก", romanization: "nîi khʉʉ yàk", english: "This is jagged.", hindi: "यह दाँतेदार है।"),
            WordExample(thai: "หยักอยู่ที่นี่", romanization: "yàk yùu thîi nîi", english: "The jagged is here.", hindi: "दाँतेदार यहाँ है।"),
        ],
        1913: [
            WordExample(thai: "นี่คือมน", romanization: "nîi khʉʉ mon", english: "This is rounded.", hindi: "यह गोल किनारे वाला है।"),
            WordExample(thai: "มนอยู่ที่นี่", romanization: "mon yùu thîi nîi", english: "The rounded is here.", hindi: "गोल किनारे वाला यहाँ है।"),
        ],
        1914: [
            WordExample(thai: "ฉันหยาบคาย", romanization: "chǎn yàap-khaai", english: "I rude.", hindi: "मैं अभद्र।"),
            WordExample(thai: "เขาหยาบคาย", romanization: "khǎo yàap-khaai", english: "He or she will rude.", hindi: "वह अभद्र।"),
        ],
        1915: [
            WordExample(thai: "ฉันสุภาพอ่อนโยน", romanization: "chǎn sù-phâap-àawn-yoon", english: "I polite and gentle.", hindi: "मैं विनम्र और कोमल।"),
            WordExample(thai: "เขาสุภาพอ่อนโยน", romanization: "khǎo sù-phâap-àawn-yoon", english: "He or she will polite and gentle.", hindi: "वह विनम्र और कोमल।"),
        ],
        1916: [
            WordExample(thai: "ฉันชัดเจน", romanization: "chǎn chát-jeen", english: "I clear; explicit.", hindi: "मैं स्पष्ट।"),
            WordExample(thai: "เขาชัดเจน", romanization: "khǎo chát-jeen", english: "He or she will clear; explicit.", hindi: "वह स्पष्ट।"),
        ],
        1917: [
            WordExample(thai: "ฉันคลุมเครือ", romanization: "chǎn khlum-khrʉa", english: "I ambiguous.", hindi: "मैं अस्पष्ट।"),
            WordExample(thai: "เขาคลุมเครือ", romanization: "khǎo khlum-khrʉa", english: "He or she will ambiguous.", hindi: "वह अस्पष्ट।"),
        ],
        1918: [
            WordExample(thai: "นี่คือเร่งด่วน", romanization: "nîi khʉʉ rêng-dùan", english: "This is urgent.", hindi: "यह तत्काल है।"),
            WordExample(thai: "เร่งด่วนอยู่ที่นี่", romanization: "rêng-dùan yùu thîi nîi", english: "The urgent is here.", hindi: "तत्काल यहाँ है।"),
        ],
        1919: [
            WordExample(thai: "นี่คือล่าช้า", romanization: "nîi khʉʉ lâa-cháa", english: "This is delayed.", hindi: "यह विलंबित है।"),
            WordExample(thai: "ล่าช้าอยู่ที่นี่", romanization: "lâa-cháa yùu thîi nîi", english: "The delayed is here.", hindi: "विलंबित यहाँ है।"),
        ],
        1920: [
            WordExample(thai: "นี่คือตรงเวลา", romanization: "nîi khʉʉ trong-wee-laa", english: "This is on time.", hindi: "यह समय पर है।"),
            WordExample(thai: "ตรงเวลาอยู่ที่นี่", romanization: "trong-wee-laa yùu thîi nîi", english: "The on time is here.", hindi: "समय पर यहाँ है।"),
        ],
        1921: [
            WordExample(thai: "นี่คือชั่วคราว", romanization: "nîi khʉʉ chûa-khraao", english: "This is temporary.", hindi: "यह अस्थायी है।"),
            WordExample(thai: "ชั่วคราวอยู่ที่นี่", romanization: "chûa-khraao yùu thîi nîi", english: "The temporary is here.", hindi: "अस्थायी यहाँ है।"),
        ],
        1922: [
            WordExample(thai: "นี่คือถาวร", romanization: "nîi khʉʉ thǎa-wawn", english: "This is permanent.", hindi: "यह स्थायी है।"),
            WordExample(thai: "ถาวรอยู่ที่นี่", romanization: "thǎa-wawn yùu thîi nîi", english: "The permanent is here.", hindi: "स्थायी यहाँ है।"),
        ],
        1923: [
            WordExample(thai: "นี่คือรายวัน", romanization: "nîi khʉʉ raai-wan", english: "This is daily.", hindi: "यह दैनिक है।"),
            WordExample(thai: "รายวันอยู่ที่นี่", romanization: "raai-wan yùu thîi nîi", english: "The daily is here.", hindi: "दैनिक यहाँ है।"),
        ],
        1924: [
            WordExample(thai: "นี่คือรายเดือน", romanization: "nîi khʉʉ raai-dʉan", english: "This is monthly.", hindi: "यह मासिक है।"),
            WordExample(thai: "รายเดือนอยู่ที่นี่", romanization: "raai-dʉan yùu thîi nîi", english: "The monthly is here.", hindi: "मासिक यहाँ है।"),
        ],
        1925: [
            WordExample(thai: "นี่คือรายปี", romanization: "nîi khʉʉ raai-pii", english: "This is yearly.", hindi: "यह वार्षिक है।"),
            WordExample(thai: "รายปีอยู่ที่นี่", romanization: "raai-pii yùu thîi nîi", english: "The yearly is here.", hindi: "वार्षिक यहाँ है।"),
        ],
        1926: [
            WordExample(thai: "นี่คือกำหนด", romanization: "nîi khʉʉ kam-nòt", english: "This is set; determine.", hindi: "यह निर्धारित करना है।"),
            WordExample(thai: "กำหนดอยู่ที่นี่", romanization: "kam-nòt yùu thîi nîi", english: "The set; determine is here.", hindi: "निर्धारित करना यहाँ है।"),
        ],
        1927: [
            WordExample(thai: "นี่คือกำหนดเวลา", romanization: "nîi khʉʉ kam-nòt-wee-laa", english: "This is deadline; scheduled time.", hindi: "यह समय-सीमा है।"),
            WordExample(thai: "กำหนดเวลาอยู่ที่นี่", romanization: "kam-nòt-wee-laa yùu thîi nîi", english: "The deadline; scheduled time is here.", hindi: "समय-सीमा यहाँ है।"),
        ],
        1928: [
            WordExample(thai: "นี่คือเลื่อนนัด", romanization: "nîi khʉʉ lʉ̂an-nát", english: "This is reschedule an appointment.", hindi: "यह मुलाकात टालना है।"),
            WordExample(thai: "เลื่อนนัดอยู่ที่นี่", romanization: "lʉ̂an-nát yùu thîi nîi", english: "The reschedule an appointment is here.", hindi: "मुलाकात टालना यहाँ है।"),
        ],
        1929: [
            WordExample(thai: "ฉันยืนยัน", romanization: "chǎn yʉʉn-yan", english: "I confirm.", hindi: "मैं पुष्टि करना।"),
            WordExample(thai: "เขายืนยัน", romanization: "khǎo yʉʉn-yan", english: "He or she will confirm.", hindi: "वह पुष्टि करना।"),
        ],
        1930: [
            WordExample(thai: "ฉันปฏิเสธ", romanization: "chǎn pà-tì-sèet", english: "I decline; refuse.", hindi: "मैं अस्वीकार करना।"),
            WordExample(thai: "เขาปฏิเสธ", romanization: "khǎo pà-tì-sèet", english: "He or she will decline; refuse.", hindi: "वह अस्वीकार करना।"),
        ],
        1931: [
            WordExample(thai: "ฉันอนุญาต", romanization: "chǎn à-nú-yâat", english: "I permit; authorize.", hindi: "मैं अनुमति देना।"),
            WordExample(thai: "เขาอนุญาต", romanization: "khǎo à-nú-yâat", english: "He or she will permit; authorize.", hindi: "वह अनुमति देना।"),
        ],
        1932: [
            WordExample(thai: "ฉันแจ้ง", romanization: "chǎn jâeng", english: "I notify.", hindi: "मैं सूचित करना।"),
            WordExample(thai: "เขาแจ้ง", romanization: "khǎo jâeng", english: "He or she will notify.", hindi: "वह सूचित करना।"),
        ],
        1933: [
            WordExample(thai: "ฉันแจ้งเตือน", romanization: "chǎn jâeng-dtʉan", english: "I alert; notify.", hindi: "मैं चेतावनी देना।"),
            WordExample(thai: "เขาแจ้งเตือน", romanization: "khǎo jâeng-dtʉan", english: "He or she will alert; notify.", hindi: "वह चेतावनी देना।"),
        ],
        1934: [
            WordExample(thai: "ฉันเตือน", romanization: "chǎn dtʉan", english: "I warn; remind.", hindi: "मैं चेतावनी देना; याद दिलाना।"),
            WordExample(thai: "เขาเตือน", romanization: "khǎo dtʉan", english: "He or she will warn; remind.", hindi: "वह चेतावनी देना; याद दिलाना।"),
        ],
        1935: [
            WordExample(thai: "ฉันแนะนำตัว", romanization: "chǎn nâe-nam-tua", english: "I introduce oneself.", hindi: "मैं अपना परिचय देना।"),
            WordExample(thai: "เขาแนะนำตัว", romanization: "khǎo nâe-nam-tua", english: "He or she will introduce oneself.", hindi: "वह अपना परिचय देना।"),
        ],
        1936: [
            WordExample(thai: "ฉันอธิบาย", romanization: "chǎn à-thí-baai", english: "I explain.", hindi: "मैं समझाना।"),
            WordExample(thai: "เขาอธิบาย", romanization: "khǎo à-thí-baai", english: "He or she will explain.", hindi: "वह समझाना।"),
        ],
        1937: [
            WordExample(thai: "ฉันยกตัวอย่าง", romanization: "chǎn yók-tua-yàang", english: "I give an example.", hindi: "मैं उदाहरण देना।"),
            WordExample(thai: "เขายกตัวอย่าง", romanization: "khǎo yók-tua-yàang", english: "He or she will give an example.", hindi: "वह उदाहरण देना।"),
        ],
        1938: [
            WordExample(thai: "ฉันเน้น", romanization: "chǎn nén", english: "I emphasize.", hindi: "मैं ज़ोर देना।"),
            WordExample(thai: "เขาเน้น", romanization: "khǎo nén", english: "He or she will emphasize.", hindi: "वह ज़ोर देना।"),
        ],
        1939: [
            WordExample(thai: "ฉันสรุป", romanization: "chǎn sà-rùp", english: "I summarize.", hindi: "मैं सारांश देना।"),
            WordExample(thai: "เขาสรุป", romanization: "khǎo sà-rùp", english: "He or she will summarize.", hindi: "वह सारांश देना।"),
        ],
        1940: [
            WordExample(thai: "ฉันเปรียบเทียบ", romanization: "chǎn prìap-thîap", english: "I compare.", hindi: "मैं तुलना करना।"),
            WordExample(thai: "เขาเปรียบเทียบ", romanization: "khǎo prìap-thîap", english: "He or she will compare.", hindi: "वह तुलना करना।"),
        ],
        1941: [
            WordExample(thai: "ฉันเห็นด้วย", romanization: "chǎn hěn-dûai", english: "I agree.", hindi: "मैं सहमत होना।"),
            WordExample(thai: "เขาเห็นด้วย", romanization: "khǎo hěn-dûai", english: "He or she will agree.", hindi: "वह सहमत होना।"),
        ],
        1942: [
            WordExample(thai: "ฉันไม่เห็นด้วย", romanization: "chǎn mâi-hěn-dûai", english: "I disagree.", hindi: "मैं असहमत होना।"),
            WordExample(thai: "เขาไม่เห็นด้วย", romanization: "khǎo mâi-hěn-dûai", english: "He or she will disagree.", hindi: "वह असहमत होना।"),
        ],
        1943: [
            WordExample(thai: "ฉันขัดจังหวะ", romanization: "chǎn khàt-jàng-wà", english: "I interrupt.", hindi: "मैं बात काटना।"),
            WordExample(thai: "เขาขัดจังหวะ", romanization: "khǎo khàt-jàng-wà", english: "He or she will interrupt.", hindi: "वह बात काटना।"),
        ],
        1944: [
            WordExample(thai: "ฉันกระซิบ", romanization: "chǎn grà-sìp", english: "I whisper.", hindi: "मैं फुसफुसाना।"),
            WordExample(thai: "เขากระซิบ", romanization: "khǎo grà-sìp", english: "He or she will whisper.", hindi: "वह फुसफुसाना।"),
        ],
        1945: [
            WordExample(thai: "ฉันตะโกน", romanization: "chǎn dtà-gòon", english: "I shout.", hindi: "मैं चिल्लाना।"),
            WordExample(thai: "เขาตะโกน", romanization: "khǎo dtà-gòon", english: "He or she will shout.", hindi: "वह चिल्लाना।"),
        ],
        1946: [
            WordExample(thai: "ฉันออกเสียง", romanization: "chǎn àawk-sǐang", english: "I pronounce.", hindi: "मैं उच्चारण करना।"),
            WordExample(thai: "เขาออกเสียง", romanization: "khǎo àawk-sǐang", english: "He or she will pronounce.", hindi: "वह उच्चारण करना।"),
        ],
        1947: [
            WordExample(thai: "ฉันสะกด", romanization: "chǎn sà-kòt", english: "I spell.", hindi: "मैं हिज्जे बोलना।"),
            WordExample(thai: "เขาสะกด", romanization: "khǎo sà-kòt", english: "He or she will spell.", hindi: "वह हिज्जे बोलना।"),
        ],
        1948: [
            WordExample(thai: "ฉันพิมพ์", romanization: "chǎn phim", english: "I type.", hindi: "मैं टाइप करना।"),
            WordExample(thai: "เขาพิมพ์", romanization: "khǎo phim", english: "He or she will type.", hindi: "वह टाइप करना।"),
        ],
        1949: [
            WordExample(thai: "ฉันแนบไฟล์", romanization: "chǎn nâep-fai", english: "I attach a file.", hindi: "मैं फ़ाइल संलग्न करना।"),
            WordExample(thai: "เขาแนบไฟล์", romanization: "khǎo nâep-fai", english: "He or she will attach a file.", hindi: "वह फ़ाइल संलग्न करना।"),
        ],
        1950: [
            WordExample(thai: "ฉันส่งข้อความ", romanization: "chǎn sòng-khâaw-khwaam", english: "I send a message.", hindi: "मैं संदेश भेजना।"),
            WordExample(thai: "เขาส่งข้อความ", romanization: "khǎo sòng-khâaw-khwaam", english: "He or she will send a message.", hindi: "वह संदेश भेजना।"),
        ],
        1951: [
            WordExample(thai: "ฉันรับสาย", romanization: "chǎn ráp-sǎai", english: "I answer a call.", hindi: "मैं फ़ोन उठाना।"),
            WordExample(thai: "เขารับสาย", romanization: "khǎo ráp-sǎai", english: "He or she will answer a call.", hindi: "वह फ़ोन उठाना।"),
        ],
        1952: [
            WordExample(thai: "ฉันวางสาย", romanization: "chǎn waang-sǎai", english: "I hang up.", hindi: "मैं फ़ोन रखना।"),
            WordExample(thai: "เขาวางสาย", romanization: "khǎo waang-sǎai", english: "He or she will hang up.", hindi: "वह फ़ोन रखना।"),
        ],
        1953: [
            WordExample(thai: "ฉันฝากข้อความ", romanization: "chǎn fàak-khâaw-khwaam", english: "I leave a message.", hindi: "मैं संदेश छोड़ना।"),
            WordExample(thai: "เขาฝากข้อความ", romanization: "khǎo fàak-khâaw-khwaam", english: "He or she will leave a message.", hindi: "वह संदेश छोड़ना।"),
        ],
        1954: [
            WordExample(thai: "ฉันรหัสผ่าน", romanization: "chǎn rá-hàt-phàan", english: "I password.", hindi: "मैं पासवर्ड।"),
            WordExample(thai: "เขารหัสผ่าน", romanization: "khǎo rá-hàt-phàan", english: "He or she will password.", hindi: "वह पासवर्ड।"),
        ],
        1955: [
            WordExample(thai: "ฉันลายนิ้วมือ", romanization: "chǎn laai-níw-mʉʉ", english: "I fingerprint.", hindi: "मैं उँगली का निशान।"),
            WordExample(thai: "เขาลายนิ้วมือ", romanization: "khǎo laai-níw-mʉʉ", english: "He or she will fingerprint.", hindi: "वह उँगली का निशान।"),
        ],
        1956: [
            WordExample(thai: "ฉันกล้องวงจรปิด", romanization: "chǎn klâawng-wong-jon-pìt", english: "I CCTV camera.", hindi: "मैं सीसीटीवी कैमरा।"),
            WordExample(thai: "เขากล้องวงจรปิด", romanization: "khǎo klâawng-wong-jon-pìt", english: "He or she will CCTV camera.", hindi: "वह सीसीटीवी कैमरा।"),
        ],
        1957: [
            WordExample(thai: "ฉันสัญญาณเตือนภัย", romanization: "chǎn sǎn-yaan-dtʉan-phai", english: "I alarm signal.", hindi: "मैं अलार्म संकेत।"),
            WordExample(thai: "เขาสัญญาณเตือนภัย", romanization: "khǎo sǎn-yaan-dtʉan-phai", english: "He or she will alarm signal.", hindi: "वह अलार्म संकेत।"),
        ],
        1958: [
            WordExample(thai: "ฉันถังดับเพลิง", romanization: "chǎn thǎng-dàp-phloeng", english: "I fire extinguisher.", hindi: "मैं अग्निशामक।"),
            WordExample(thai: "เขาถังดับเพลิง", romanization: "khǎo thǎng-dàp-phloeng", english: "He or she will fire extinguisher.", hindi: "वह अग्निशामक।"),
        ],
        1959: [
            WordExample(thai: "ฉันทางหนีไฟ", romanization: "chǎn thaang-nǐi-fai", english: "I fire exit.", hindi: "मैं आपात निकास।"),
            WordExample(thai: "เขาทางหนีไฟ", romanization: "khǎo thaang-nǐi-fai", english: "He or she will fire exit.", hindi: "वह आपात निकास।"),
        ],
        1960: [
            WordExample(thai: "ฉันจุดรวมพล", romanization: "chǎn jùt-ruam-phon", english: "I assembly point.", hindi: "मैं एकत्र होने का स्थान।"),
            WordExample(thai: "เขาจุดรวมพล", romanization: "khǎo jùt-ruam-phon", english: "He or she will assembly point.", hindi: "वह एकत्र होने का स्थान।"),
        ],
        1961: [
            WordExample(thai: "ฉันโทรฉุกเฉิน", romanization: "chǎn thoo-chùk-chǒen", english: "I make an emergency call.", hindi: "मैं आपातकालीन फ़ोन करना।"),
            WordExample(thai: "เขาโทรฉุกเฉิน", romanization: "khǎo thoo-chùk-chǒen", english: "He or she will make an emergency call.", hindi: "वह आपातकालीन फ़ोन करना।"),
        ],
        1962: [
            WordExample(thai: "ฉันระวังไฟฟ้า", romanization: "chǎn rá-wang-fai-fáa", english: "I beware of electricity.", hindi: "मैं बिजली से सावधान।"),
            WordExample(thai: "เขาระวังไฟฟ้า", romanization: "khǎo rá-wang-fai-fáa", english: "He or she will beware of electricity.", hindi: "वह बिजली से सावधान।"),
        ],
        1963: [
            WordExample(thai: "ฉันห้ามเข้า", romanization: "chǎn hâam-khâo", english: "I do not enter.", hindi: "मैं प्रवेश निषिद्ध।"),
            WordExample(thai: "เขาห้ามเข้า", romanization: "khǎo hâam-khâo", english: "He or she will do not enter.", hindi: "वह प्रवेश निषिद्ध।"),
        ],
        1964: [
            WordExample(thai: "ฉันห้ามสูบบุหรี่", romanization: "chǎn hâam-sùup-bù-rìi", english: "I no smoking.", hindi: "मैं धूम्रपान निषिद्ध।"),
            WordExample(thai: "เขาห้ามสูบบุหรี่", romanization: "khǎo hâam-sùup-bù-rìi", english: "He or she will no smoking.", hindi: "वह धूम्रपान निषिद्ध।"),
        ],
        1965: [
            WordExample(thai: "ฉันอันตรายจากไฟฟ้า", romanization: "chǎn an-dtà-raai-jàak-fai-fáa", english: "I electrical hazard.", hindi: "मैं बिजली का खतरा।"),
            WordExample(thai: "เขาอันตรายจากไฟฟ้า", romanization: "khǎo an-dtà-raai-jàak-fai-fáa", english: "He or she will electrical hazard.", hindi: "वह बिजली का खतरा।"),
        ],
        1966: [
            WordExample(thai: "นี่คือบัญชีธนาคาร", romanization: "nîi khʉʉ ban-chii-tha-naa-khaan", english: "This is bank account.", hindi: "यह बैंक खाता है।"),
            WordExample(thai: "บัญชีธนาคารอยู่ที่นี่", romanization: "ban-chii-tha-naa-khaan yùu thîi nîi", english: "The bank account is here.", hindi: "बैंक खाता यहाँ है।"),
        ],
        1967: [
            WordExample(thai: "นี่คือเปิดบัญชี", romanization: "nîi khʉʉ pòet-ban-chii", english: "This is open an account.", hindi: "यह खाता खोलना है।"),
            WordExample(thai: "เปิดบัญชีอยู่ที่นี่", romanization: "pòet-ban-chii yùu thîi nîi", english: "The open an account is here.", hindi: "खाता खोलना यहाँ है।"),
        ],
        1968: [
            WordExample(thai: "นี่คือฝากเงิน", romanization: "nîi khʉʉ fàak-ngoen", english: "This is deposit money.", hindi: "यह पैसे जमा करना है।"),
            WordExample(thai: "ฝากเงินอยู่ที่นี่", romanization: "fàak-ngoen yùu thîi nîi", english: "The deposit money is here.", hindi: "पैसे जमा करना यहाँ है।"),
        ],
        1969: [
            WordExample(thai: "นี่คือถอนเงิน", romanization: "nîi khʉʉ thǎawn-ngoen", english: "This is withdraw money.", hindi: "यह पैसे निकालना है।"),
            WordExample(thai: "ถอนเงินอยู่ที่นี่", romanization: "thǎawn-ngoen yùu thîi nîi", english: "The withdraw money is here.", hindi: "पैसे निकालना यहाँ है।"),
        ],
        1970: [
            WordExample(thai: "นี่คือโอนเงิน", romanization: "nîi khʉʉ oon-ngoen", english: "This is transfer money.", hindi: "यह पैसे भेजना है।"),
            WordExample(thai: "โอนเงินอยู่ที่นี่", romanization: "oon-ngoen yùu thîi nîi", english: "The transfer money is here.", hindi: "पैसे भेजना यहाँ है।"),
        ],
        1971: [
            WordExample(thai: "นี่คือยอดเงินคงเหลือ", romanization: "nîi khʉʉ yâawt-ngoen-khong-lʉ̌ʉa", english: "This is account balance.", hindi: "यह शेष राशि है।"),
            WordExample(thai: "ยอดเงินคงเหลืออยู่ที่นี่", romanization: "yâawt-ngoen-khong-lʉ̌ʉa yùu thîi nîi", english: "The account balance is here.", hindi: "शेष राशि यहाँ है।"),
        ],
        1972: [
            WordExample(thai: "นี่คือบัตรเดบิต", romanization: "nîi khʉʉ bàt-dee-bìt", english: "This is debit card.", hindi: "यह डेबिट कार्ड है।"),
            WordExample(thai: "บัตรเดบิตอยู่ที่นี่", romanization: "bàt-dee-bìt yùu thîi nîi", english: "The debit card is here.", hindi: "डेबिट कार्ड यहाँ है।"),
        ],
        1973: [
            WordExample(thai: "นี่คือบัตรเครดิต", romanization: "nîi khʉʉ bàt-khree-dìt", english: "This is credit card.", hindi: "यह क्रेडिट कार्ड है।"),
            WordExample(thai: "บัตรเครดิตอยู่ที่นี่", romanization: "bàt-khree-dìt yùu thîi nîi", english: "The credit card is here.", hindi: "क्रेडिट कार्ड यहाँ है।"),
        ],
        1974: [
            WordExample(thai: "นี่คือรหัสเอทีเอ็ม", romanization: "nîi khʉʉ rá-hàt-ee-thii-em", english: "This is ATM PIN.", hindi: "यह एटीएम पिन है।"),
            WordExample(thai: "รหัสเอทีเอ็มอยู่ที่นี่", romanization: "rá-hàt-ee-thii-em yùu thîi nîi", english: "The ATM PIN is here.", hindi: "एटीएम पिन यहाँ है।"),
        ],
        1975: [
            WordExample(thai: "นี่คือตู้เอทีเอ็ม", romanization: "nîi khʉʉ tûu-ee-thii-em", english: "This is ATM.", hindi: "यह एटीएम है।"),
            WordExample(thai: "ตู้เอทีเอ็มอยู่ที่นี่", romanization: "tûu-ee-thii-em yùu thîi nîi", english: "The ATM is here.", hindi: "एटीएम यहाँ है।"),
        ],
        1976: [
            WordExample(thai: "นี่คือดอกเบี้ย", romanization: "nîi khʉʉ dàawk-bîa", english: "This is interest.", hindi: "यह ब्याज है।"),
            WordExample(thai: "ดอกเบี้ยอยู่ที่นี่", romanization: "dàawk-bîa yùu thîi nîi", english: "The interest is here.", hindi: "ब्याज यहाँ है।"),
        ],
        1977: [
            WordExample(thai: "นี่คือค่าธรรมเนียม", romanization: "nîi khʉʉ khâa-tham-niam", english: "This is fee.", hindi: "यह शुल्क है।"),
            WordExample(thai: "ค่าธรรมเนียมอยู่ที่นี่", romanization: "khâa-tham-niam yùu thîi nîi", english: "The fee is here.", hindi: "शुल्क यहाँ है।"),
        ],
        1978: [
            WordExample(thai: "นี่คืออัตราแลกเปลี่ยน", romanization: "nîi khʉʉ àt-dtraa-lâek-plìan", english: "This is exchange rate.", hindi: "यह विनिमय दर है।"),
            WordExample(thai: "อัตราแลกเปลี่ยนอยู่ที่นี่", romanization: "àt-dtraa-lâek-plìan yùu thîi nîi", english: "The exchange rate is here.", hindi: "विनिमय दर यहाँ है।"),
        ],
        1979: [
            WordExample(thai: "นี่คือสกุลเงิน", romanization: "nîi khʉʉ sà-kun-ngoen", english: "This is currency.", hindi: "यह मुद्रा है।"),
            WordExample(thai: "สกุลเงินอยู่ที่นี่", romanization: "sà-kun-ngoen yùu thîi nîi", english: "The currency is here.", hindi: "मुद्रा यहाँ है।"),
        ],
        1980: [
            WordExample(thai: "นี่คือเงินสด", romanization: "nîi khʉʉ ngoen-sòt", english: "This is cash.", hindi: "यह नकद है।"),
            WordExample(thai: "เงินสดอยู่ที่นี่", romanization: "ngoen-sòt yùu thîi nîi", english: "The cash is here.", hindi: "नकद यहाँ है।"),
        ],
        1981: [
            WordExample(thai: "นี่คือใบแจ้งยอด", romanization: "nîi khʉʉ bai-jâeng-yâawt", english: "This is bank statement.", hindi: "यह बैंक विवरण है।"),
            WordExample(thai: "ใบแจ้งยอดอยู่ที่นี่", romanization: "bai-jâeng-yâawt yùu thîi nîi", english: "The bank statement is here.", hindi: "बैंक विवरण यहाँ है।"),
        ],
        1982: [
            WordExample(thai: "นี่คือชำระเงิน", romanization: "nîi khʉʉ cham-rá-ngoen", english: "This is make a payment.", hindi: "यह भुगतान करना है।"),
            WordExample(thai: "ชำระเงินอยู่ที่นี่", romanization: "cham-rá-ngoen yùu thîi nîi", english: "The make a payment is here.", hindi: "भुगतान करना यहाँ है।"),
        ],
        1983: [
            WordExample(thai: "นี่คือผ่อนชำระ", romanization: "nîi khʉʉ phàawn-cham-rá", english: "This is pay in installments.", hindi: "यह किस्तों में भुगतान करना है।"),
            WordExample(thai: "ผ่อนชำระอยู่ที่นี่", romanization: "phàawn-cham-rá yùu thîi nîi", english: "The pay in installments is here.", hindi: "किस्तों में भुगतान करना यहाँ है।"),
        ],
        1984: [
            WordExample(thai: "นี่คือหนี้สิน", romanization: "nîi khʉʉ nîi-sǐn", english: "This is debt.", hindi: "यह कर्ज़ है।"),
            WordExample(thai: "หนี้สินอยู่ที่นี่", romanization: "nîi-sǐn yùu thîi nîi", english: "The debt is here.", hindi: "कर्ज़ यहाँ है।"),
        ],
        1985: [
            WordExample(thai: "นี่คือเงินออม", romanization: "nîi khʉʉ ngoen-aawm", english: "This is savings.", hindi: "यह बचत है।"),
            WordExample(thai: "เงินออมอยู่ที่นี่", romanization: "ngoen-aawm yùu thîi nîi", english: "The savings is here.", hindi: "बचत यहाँ है।"),
        ],
        1986: [
            WordExample(thai: "นี่คือบัตรประชาชน", romanization: "nîi khʉʉ bàt-prà-chaa-chon", english: "This is national ID card.", hindi: "यह राष्ट्रीय पहचान पत्र है।"),
            WordExample(thai: "บัตรประชาชนอยู่ที่นี่", romanization: "bàt-prà-chaa-chon yùu thîi nîi", english: "The national ID card is here.", hindi: "राष्ट्रीय पहचान पत्र यहाँ है।"),
        ],
        1987: [
            WordExample(thai: "นี่คือสำเนา", romanization: "nîi khʉʉ sam-nao", english: "This is copy; duplicate.", hindi: "यह प्रतिलिपि है।"),
            WordExample(thai: "สำเนาอยู่ที่นี่", romanization: "sam-nao yùu thîi nîi", english: "The copy; duplicate is here.", hindi: "प्रतिलिपि यहाँ है।"),
        ],
        1988: [
            WordExample(thai: "นี่คือสำเนาบัตรประชาชน", romanization: "nîi khʉʉ sam-nao-bàt-prà-chaa-chon", english: "This is copy of ID card.", hindi: "यह पहचान पत्र की प्रतिलिपि है।"),
            WordExample(thai: "สำเนาบัตรประชาชนอยู่ที่นี่", romanization: "sam-nao-bàt-prà-chaa-chon yùu thîi nîi", english: "The copy of ID card is here.", hindi: "पहचान पत्र की प्रतिलिपि यहाँ है।"),
        ],
        1989: [
            WordExample(thai: "นี่คือแบบฟอร์ม", romanization: "nîi khʉʉ bàep-faawm", english: "This is form.", hindi: "यह प्रपत्र है।"),
            WordExample(thai: "แบบฟอร์มอยู่ที่นี่", romanization: "bàep-faawm yùu thîi nîi", english: "The form is here.", hindi: "प्रपत्र यहाँ है।"),
        ],
        1990: [
            WordExample(thai: "นี่คือกรอกแบบฟอร์ม", romanization: "nîi khʉʉ kràawk-bàep-faawm", english: "This is fill out a form.", hindi: "यह फॉर्म भरना है।"),
            WordExample(thai: "กรอกแบบฟอร์มอยู่ที่นี่", romanization: "kràawk-bàep-faawm yùu thîi nîi", english: "The fill out a form is here.", hindi: "फॉर्म भरना यहाँ है।"),
        ],
        1991: [
            WordExample(thai: "นี่คือลงชื่อ", romanization: "nîi khʉʉ long-chʉ̂ʉ", english: "This is sign; write one’s name.", hindi: "यह हस्ताक्षर करना है।"),
            WordExample(thai: "ลงชื่ออยู่ที่นี่", romanization: "long-chʉ̂ʉ yùu thîi nîi", english: "The sign; write one’s name is here.", hindi: "हस्ताक्षर करना यहाँ है।"),
        ],
        1992: [
            WordExample(thai: "นี่คือลายเซ็น", romanization: "nîi khʉʉ laai-sen", english: "This is signature.", hindi: "यह हस्ताक्षर है।"),
            WordExample(thai: "ลายเซ็นอยู่ที่นี่", romanization: "laai-sen yùu thîi nîi", english: "The signature is here.", hindi: "हस्ताक्षर यहाँ है।"),
        ],
        1993: [
            WordExample(thai: "นี่คือตราประทับ", romanization: "nîi khʉʉ dtraa-prà-tháp", english: "This is official stamp.", hindi: "यह मुहर है।"),
            WordExample(thai: "ตราประทับอยู่ที่นี่", romanization: "dtraa-prà-tháp yùu thîi nîi", english: "The official stamp is here.", hindi: "मुहर यहाँ है।"),
        ],
        1994: [
            WordExample(thai: "นี่คือเอกสาร", romanization: "nîi khʉʉ èek-gà-sǎan", english: "This is document.", hindi: "यह दस्तावेज़ है।"),
            WordExample(thai: "เอกสารอยู่ที่นี่", romanization: "èek-gà-sǎan yùu thîi nîi", english: "The document is here.", hindi: "दस्तावेज़ यहाँ है।"),
        ],
        1995: [
            WordExample(thai: "นี่คือเอกสารสำคัญ", romanization: "nîi khʉʉ èek-gà-sǎan-sǎm-khan", english: "This is important document.", hindi: "यह महत्वपूर्ण दस्तावेज़ है।"),
            WordExample(thai: "เอกสารสำคัญอยู่ที่นี่", romanization: "èek-gà-sǎan-sǎm-khan yùu thîi nîi", english: "The important document is here.", hindi: "महत्वपूर्ण दस्तावेज़ यहाँ है।"),
        ],
        1996: [
            WordExample(thai: "นี่คือใบสมัคร", romanization: "nîi khʉʉ bai-sà-màk", english: "This is application form.", hindi: "यह आवेदन पत्र है।"),
            WordExample(thai: "ใบสมัครอยู่ที่นี่", romanization: "bai-sà-màk yùu thîi nîi", english: "The application form is here.", hindi: "आवेदन पत्र यहाँ है।"),
        ],
        1997: [
            WordExample(thai: "นี่คือใบอนุญาต", romanization: "nîi khʉʉ bai-à-nú-yâat", english: "This is permit; license.", hindi: "यह अनुमति पत्र है।"),
            WordExample(thai: "ใบอนุญาตอยู่ที่นี่", romanization: "bai-à-nú-yâat yùu thîi nîi", english: "The permit; license is here.", hindi: "अनुमति पत्र यहाँ है।"),
        ],
        1998: [
            WordExample(thai: "นี่คือสัญญา", romanization: "nîi khʉʉ sǎn-yaa", english: "This is contract.", hindi: "यह अनुबंध है।"),
            WordExample(thai: "สัญญาอยู่ที่นี่", romanization: "sǎn-yaa yùu thîi nîi", english: "The contract is here.", hindi: "अनुबंध यहाँ है।"),
        ],
        1999: [
            WordExample(thai: "นี่คือเงื่อนไข", romanization: "nîi khʉʉ ngʉ̂an-khǎi", english: "This is condition; term.", hindi: "यह शर्त है।"),
            WordExample(thai: "เงื่อนไขอยู่ที่นี่", romanization: "ngʉ̂an-khǎi yùu thîi nîi", english: "The condition; term is here.", hindi: "शर्त यहाँ है।"),
        ],
        2000: [
            WordExample(thai: "นี่คือวันหมดอายุ", romanization: "nîi khʉʉ wan-mòt-aa-yú", english: "This is expiry date.", hindi: "यह समाप्ति तिथि है।"),
            WordExample(thai: "วันหมดอายุอยู่ที่นี่", romanization: "wan-mòt-aa-yú yùu thîi nîi", english: "The expiry date is here.", hindi: "समाप्ति तिथि यहाँ है।"),
        ],
        2001: [
            WordExample(thai: "นี่คือต่ออายุ", romanization: "nîi khʉʉ dtàaw-aa-yú", english: "This is renew; extend validity.", hindi: "यह नवीनीकरण करना है।"),
            WordExample(thai: "ต่ออายุอยู่ที่นี่", romanization: "dtàaw-aa-yú yùu thîi nîi", english: "The renew; extend validity is here.", hindi: "नवीनीकरण करना यहाँ है।"),
        ],
        2002: [
            WordExample(thai: "นี่คือรับรอง", romanization: "nîi khʉʉ ráp-rawng", english: "This is certify; endorse.", hindi: "यह प्रमाणित करना है।"),
            WordExample(thai: "รับรองอยู่ที่นี่", romanization: "ráp-rawng yùu thîi nîi", english: "The certify; endorse is here.", hindi: "प्रमाणित करना यहाँ है।"),
        ],
        2003: [
            WordExample(thai: "นี่คือแปลเอกสาร", romanization: "nîi khʉʉ plaae-èek-gà-sǎan", english: "This is translate a document.", hindi: "यह दस्तावेज़ का अनुवाद करना है।"),
            WordExample(thai: "แปลเอกสารอยู่ที่นี่", romanization: "plaae-èek-gà-sǎan yùu thîi nîi", english: "The translate a document is here.", hindi: "दस्तावेज़ का अनुवाद करना यहाँ है।"),
        ],
        2004: [
            WordExample(thai: "นี่คือยื่นเอกสาร", romanization: "nîi khʉʉ yʉ̂ʉn-èek-gà-sǎan", english: "This is submit documents.", hindi: "यह दस्तावेज़ जमा करना है।"),
            WordExample(thai: "ยื่นเอกสารอยู่ที่นี่", romanization: "yʉ̂ʉn-èek-gà-sǎan yùu thîi nîi", english: "The submit documents is here.", hindi: "दस्तावेज़ जमा करना यहाँ है।"),
        ],
        2005: [
            WordExample(thai: "นี่คือวันพระ", romanization: "nîi khʉʉ wan-phrá", english: "This is Buddhist holy day.", hindi: "यह बौद्ध पवित्र दिन है।"),
            WordExample(thai: "วันพระอยู่ที่นี่", romanization: "wan-phrá yùu thîi nîi", english: "The Buddhist holy day is here.", hindi: "बौद्ध पवित्र दिन यहाँ है।"),
        ],
        2006: [
            WordExample(thai: "นี่คือพระสงฆ์", romanization: "nîi khʉʉ phrá-sǒng", english: "This is Buddhist monkhood.", hindi: "यह बौद्ध संघ है।"),
            WordExample(thai: "พระสงฆ์อยู่ที่นี่", romanization: "phrá-sǒng yùu thîi nîi", english: "The Buddhist monkhood is here.", hindi: "बौद्ध संघ यहाँ है।"),
        ],
        2007: [
            WordExample(thai: "นี่คือสามเณร", romanization: "nîi khʉʉ sǎa-má-neen", english: "This is novice monk.", hindi: "यह नवदीक्षित भिक्षु है।"),
            WordExample(thai: "สามเณรอยู่ที่นี่", romanization: "sǎa-má-neen yùu thîi nîi", english: "The novice monk is here.", hindi: "नवदीक्षित भिक्षु यहाँ है।"),
        ],
        2008: [
            WordExample(thai: "นี่คือพระพุทธรูป", romanization: "nîi khʉʉ phrá-phút-thá-rûup", english: "This is Buddha image.", hindi: "यह बुद्ध प्रतिमा है।"),
            WordExample(thai: "พระพุทธรูปอยู่ที่นี่", romanization: "phrá-phút-thá-rûup yùu thîi nîi", english: "The Buddha image is here.", hindi: "बुद्ध प्रतिमा यहाँ है।"),
        ],
        2009: [
            WordExample(thai: "นี่คือศาลา", romanization: "nîi khʉʉ sǎa-laa", english: "This is pavilion.", hindi: "यह मंडप है।"),
            WordExample(thai: "ศาลาอยู่ที่นี่", romanization: "sǎa-laa yùu thîi nîi", english: "The pavilion is here.", hindi: "मंडप यहाँ है।"),
        ],
        2010: [
            WordExample(thai: "นี่คืออุโบสถ", romanization: "nîi khʉʉ ù-bòot", english: "This is ordination hall.", hindi: "यह उपासना कक्ष है।"),
            WordExample(thai: "อุโบสถอยู่ที่นี่", romanization: "ù-bòot yùu thîi nîi", english: "The ordination hall is here.", hindi: "उपासना कक्ष यहाँ है।"),
        ],
        2011: [
            WordExample(thai: "นี่คือวิหาร", romanization: "nîi khʉʉ wí-hǎan", english: "This is temple hall.", hindi: "यह विहार है।"),
            WordExample(thai: "วิหารอยู่ที่นี่", romanization: "wí-hǎan yùu thîi nîi", english: "The temple hall is here.", hindi: "विहार यहाँ है।"),
        ],
        2012: [
            WordExample(thai: "นี่คือเจดีย์", romanization: "nîi khʉʉ jee-dii", english: "This is stupa.", hindi: "यह स्तूप है।"),
            WordExample(thai: "เจดีย์อยู่ที่นี่", romanization: "jee-dii yùu thîi nîi", english: "The stupa is here.", hindi: "स्तूप यहाँ है।"),
        ],
        2013: [
            WordExample(thai: "นี่คือระฆัง", romanization: "nîi khʉʉ rá-khang", english: "This is temple bell.", hindi: "यह मंदिर की घंटी है।"),
            WordExample(thai: "ระฆังอยู่ที่นี่", romanization: "rá-khang yùu thîi nîi", english: "The temple bell is here.", hindi: "मंदिर की घंटी यहाँ है।"),
        ],
        2014: [
            WordExample(thai: "นี่คือธูป", romanization: "nîi khʉʉ thûup", english: "This is incense stick.", hindi: "यह अगरबत्ती है।"),
            WordExample(thai: "ธูปอยู่ที่นี่", romanization: "thûup yùu thîi nîi", english: "The incense stick is here.", hindi: "अगरबत्ती यहाँ है।"),
        ],
        2015: [
            WordExample(thai: "นี่คือเทียน", romanization: "nîi khʉʉ thian", english: "This is candle.", hindi: "यह मोमबत्ती है।"),
            WordExample(thai: "เทียนอยู่ที่นี่", romanization: "thian yùu thîi nîi", english: "The candle is here.", hindi: "मोमबत्ती यहाँ है।"),
        ],
        2016: [
            WordExample(thai: "นี่คือพวงมาลัย", romanization: "nîi khʉʉ phuang-maa-lai", english: "This is flower garland.", hindi: "यह फूलों की माला है।"),
            WordExample(thai: "พวงมาลัยอยู่ที่นี่", romanization: "phuang-maa-lai yùu thîi nîi", english: "The flower garland is here.", hindi: "फूलों की माला यहाँ है।"),
        ],
        2017: [
            WordExample(thai: "นี่คือดอกบัว", romanization: "nîi khʉʉ dàawk-buaa", english: "This is lotus flower.", hindi: "यह कमल है।"),
            WordExample(thai: "ดอกบัวอยู่ที่นี่", romanization: "dàawk-buaa yùu thîi nîi", english: "The lotus flower is here.", hindi: "कमल यहाँ है।"),
        ],
        2018: [
            WordExample(thai: "นี่คือทำบุญ", romanization: "nîi khʉʉ tham-bun", english: "This is make merit.", hindi: "यह पुण्य करना है।"),
            WordExample(thai: "ทำบุญอยู่ที่นี่", romanization: "tham-bun yùu thîi nîi", english: "The make merit is here.", hindi: "पुण्य करना यहाँ है।"),
        ],
        2019: [
            WordExample(thai: "นี่คือถวาย", romanization: "nîi khʉʉ thà-waai", english: "This is offer to monks.", hindi: "यह भिक्षुओं को अर्पित करना है।"),
            WordExample(thai: "ถวายอยู่ที่นี่", romanization: "thà-waai yùu thîi nîi", english: "The offer to monks is here.", hindi: "भिक्षुओं को अर्पित करना यहाँ है।"),
        ],
        2020: [
            WordExample(thai: "นี่คือใส่บาตร", romanization: "nîi khʉʉ sài-bàat", english: "This is give alms to monks.", hindi: "यह भिक्षा देना है।"),
            WordExample(thai: "ใส่บาตรอยู่ที่นี่", romanization: "sài-bàat yùu thîi nîi", english: "The give alms to monks is here.", hindi: "भिक्षा देना यहाँ है।"),
        ],
        2021: [
            WordExample(thai: "นี่คือสวดมนต์", romanization: "nîi khʉʉ sùat-mon", english: "This is chant prayers.", hindi: "यह मंत्र जपना है।"),
            WordExample(thai: "สวดมนต์อยู่ที่นี่", romanization: "sùat-mon yùu thîi nîi", english: "The chant prayers is here.", hindi: "मंत्र जपना यहाँ है।"),
        ],
        2022: [
            WordExample(thai: "นี่คือนั่งสมาธิ", romanization: "nîi khʉʉ nâng-sà-màa-thí", english: "This is meditate.", hindi: "यह ध्यान करना है।"),
            WordExample(thai: "นั่งสมาธิอยู่ที่นี่", romanization: "nâng-sà-màa-thí yùu thîi nîi", english: "The meditate is here.", hindi: "ध्यान करना यहाँ है।"),
        ],
        2023: [
            WordExample(thai: "นี่คือเวียนเทียน", romanization: "nîi khʉʉ wian-thian", english: "This is walk with candles in ceremony.", hindi: "यह मोमबत्ती लेकर परिक्रमा करना है।"),
            WordExample(thai: "เวียนเทียนอยู่ที่นี่", romanization: "wian-thian yùu thîi nîi", english: "The walk with candles in ceremony is here.", hindi: "मोमबत्ती लेकर परिक्रमा करना यहाँ है।"),
        ],
        2024: [
            WordExample(thai: "นี่คือสงกรานต์", romanization: "nîi khʉʉ sǒng-kraan", english: "This is Songkran festival.", hindi: "यह सोंगक्रान त्योहार है।"),
            WordExample(thai: "สงกรานต์อยู่ที่นี่", romanization: "sǒng-kraan yùu thîi nîi", english: "The Songkran festival is here.", hindi: "सोंगक्रान त्योहार यहाँ है।"),
        ],
        2025: [
            WordExample(thai: "นี่คือลอยกระทง", romanization: "nîi khʉʉ lawy-grà-thong", english: "This is Loy Krathong festival.", hindi: "यह लोई क्रथोंग त्योहार है।"),
            WordExample(thai: "ลอยกระทงอยู่ที่นี่", romanization: "lawy-grà-thong yùu thîi nîi", english: "The Loy Krathong festival is here.", hindi: "लोई क्रथोंग त्योहार यहाँ है।"),
        ],
        2026: [
            WordExample(thai: "นี่คือกระทง", romanization: "nîi khʉʉ grà-thong", english: "This is floating basket offering.", hindi: "यह तैरता दीप-पात्र है।"),
            WordExample(thai: "กระทงอยู่ที่นี่", romanization: "grà-thong yùu thîi nîi", english: "The floating basket offering is here.", hindi: "तैरता दीप-पात्र यहाँ है।"),
        ],
        2027: [
            WordExample(thai: "นี่คือปีใหม่ไทย", romanization: "nîi khʉʉ pii-mài-thai", english: "This is Thai New Year.", hindi: "यह थाई नववर्ष है।"),
            WordExample(thai: "ปีใหม่ไทยอยู่ที่นี่", romanization: "pii-mài-thai yùu thîi nîi", english: "The Thai New Year is here.", hindi: "थाई नववर्ष यहाँ है।"),
        ],
        2028: [
            WordExample(thai: "นี่คือวันเกิด", romanization: "nîi khʉʉ wan-gòet", english: "This is birthday.", hindi: "यह जन्मदिन है।"),
            WordExample(thai: "วันเกิดอยู่ที่นี่", romanization: "wan-gòet yùu thîi nîi", english: "The birthday is here.", hindi: "जन्मदिन यहाँ है।"),
        ],
        2029: [
            WordExample(thai: "นี่คือวันครบรอบ", romanization: "nîi khʉʉ wan-khrop-râawp", english: "This is anniversary.", hindi: "यह वर्षगाँठ है।"),
            WordExample(thai: "วันครบรอบอยู่ที่นี่", romanization: "wan-khrop-râawp yùu thîi nîi", english: "The anniversary is here.", hindi: "वर्षगाँठ यहाँ है।"),
        ],
        2030: [
            WordExample(thai: "นี่คือเช้ามืด", romanization: "nîi khʉʉ cháao-mʉ̂ʉt", english: "This is before dawn.", hindi: "यह भोर से पहले है।"),
            WordExample(thai: "เช้ามืดอยู่ที่นี่", romanization: "cháao-mʉ̂ʉt yùu thîi nîi", english: "The before dawn is here.", hindi: "भोर से पहले यहाँ है।"),
        ],
        2031: [
            WordExample(thai: "นี่คือรุ่งเช้า", romanization: "nîi khʉʉ rûng-cháao", english: "This is early morning.", hindi: "यह सुबह सवेरे है।"),
            WordExample(thai: "รุ่งเช้าอยู่ที่นี่", romanization: "rûng-cháao yùu thîi nîi", english: "The early morning is here.", hindi: "सुबह सवेरे यहाँ है।"),
        ],
        2032: [
            WordExample(thai: "นี่คือสายมาก", romanization: "nîi khʉʉ sǎai-mâak", english: "This is very late morning.", hindi: "यह देर सुबह है।"),
            WordExample(thai: "สายมากอยู่ที่นี่", romanization: "sǎai-mâak yùu thîi nîi", english: "The very late morning is here.", hindi: "देर सुबह यहाँ है।"),
        ],
        2033: [
            WordExample(thai: "นี่คือพลบค่ำ", romanization: "nîi khʉʉ phlóp-khâm", english: "This is dusk.", hindi: "यह गोधूलि है।"),
            WordExample(thai: "พลบค่ำอยู่ที่นี่", romanization: "phlóp-khâm yùu thîi nîi", english: "The dusk is here.", hindi: "गोधूलि यहाँ है।"),
        ],
        2034: [
            WordExample(thai: "นี่คือเที่ยงคืน", romanization: "nîi khʉʉ thîang-khʉʉn", english: "This is midnight.", hindi: "यह आधी रात है।"),
            WordExample(thai: "เที่ยงคืนอยู่ที่นี่", romanization: "thîang-khʉʉn yùu thîi nîi", english: "The midnight is here.", hindi: "आधी रात यहाँ है।"),
        ],
        2035: [
            WordExample(thai: "นี่คือเมื่อครู่", romanization: "nîi khʉʉ mʉ̂a-khrûu", english: "This is a moment ago.", hindi: "यह अभी थोड़ी देर पहले है।"),
            WordExample(thai: "เมื่อครู่อยู่ที่นี่", romanization: "mʉ̂a-khrûu yùu thîi nîi", english: "The a moment ago is here.", hindi: "अभी थोड़ी देर पहले यहाँ है।"),
        ],
        2036: [
            WordExample(thai: "นี่คือในไม่ช้า", romanization: "nîi khʉʉ nai-mâi-cháa", english: "This is soon.", hindi: "यह जल्द है।"),
            WordExample(thai: "ในไม่ช้าอยู่ที่นี่", romanization: "nai-mâi-cháa yùu thîi nîi", english: "The soon is here.", hindi: "जल्द यहाँ है।"),
        ],
        2037: [
            WordExample(thai: "นี่คือระหว่าง", romanization: "nîi khʉʉ rá-wàang", english: "This is during; between.", hindi: "यह के दौरान; बीच में है।"),
            WordExample(thai: "ระหว่างอยู่ที่นี่", romanization: "rá-wàang yùu thîi nîi", english: "The during; between is here.", hindi: "के दौरान; बीच में यहाँ है।"),
        ],
        2038: [
            WordExample(thai: "นี่คือทันที", romanization: "nîi khʉʉ than-thii", english: "This is immediately.", hindi: "यह तुरंत है।"),
            WordExample(thai: "ทันทีอยู่ที่นี่", romanization: "than-thii yùu thîi nîi", english: "The immediately is here.", hindi: "तुरंत यहाँ है।"),
        ],
        2039: [
            WordExample(thai: "นี่คือล่วงหน้า", romanization: "nîi khʉʉ lûang-nâa", english: "This is in advance.", hindi: "यह पहले से है।"),
            WordExample(thai: "ล่วงหน้าอยู่ที่นี่", romanization: "lûang-nâa yùu thîi nîi", english: "The in advance is here.", hindi: "पहले से यहाँ है।"),
        ],
        2040: [
            WordExample(thai: "นี่คือตลอดเวลา", romanization: "nîi khʉʉ dtà-làawt-wee-laa", english: "This is all the time.", hindi: "यह हर समय है।"),
            WordExample(thai: "ตลอดเวลาอยู่ที่นี่", romanization: "dtà-làawt-wee-laa yùu thîi nîi", english: "The all the time is here.", hindi: "हर समय यहाँ है।"),
        ],
        2041: [
            WordExample(thai: "นี่คือนับตั้งแต่", romanization: "nîi khʉʉ náp-dtâng-dtàe", english: "This is since; starting from.", hindi: "यह से; आरंभ से है।"),
            WordExample(thai: "นับตั้งแต่อยู่ที่นี่", romanization: "náp-dtâng-dtàe yùu thîi nîi", english: "The since; starting from is here.", hindi: "से; आरंभ से यहाँ है।"),
        ],
        2042: [
            WordExample(thai: "นี่คือช่วงเวลา", romanization: "nîi khʉʉ chûang-wee-laa", english: "This is time period.", hindi: "यह समयावधि है।"),
            WordExample(thai: "ช่วงเวลาอยู่ที่นี่", romanization: "chûang-wee-laa yùu thîi nîi", english: "The time period is here.", hindi: "समयावधि यहाँ है।"),
        ],
        2043: [
            WordExample(thai: "นี่คือวาระ", romanization: "nîi khʉʉ waa-rá", english: "This is occasion; agenda.", hindi: "यह अवसर; कार्यसूची है।"),
            WordExample(thai: "วาระอยู่ที่นี่", romanization: "waa-rá yùu thîi nîi", english: "The occasion; agenda is here.", hindi: "अवसर; कार्यसूची यहाँ है।"),
        ],
        2044: [
            WordExample(thai: "นี่คือนัดหมาย", romanization: "nîi khʉʉ nát-mǎai", english: "This is appointment.", hindi: "यह नियुक्त समय है।"),
            WordExample(thai: "นัดหมายอยู่ที่นี่", romanization: "nát-mǎai yùu thîi nîi", english: "The appointment is here.", hindi: "नियुक्त समय यहाँ है।"),
        ],
        2045: [
            WordExample(thai: "นี่คือเส้นตาย", romanization: "nîi khʉʉ sên-dtaai", english: "This is deadline.", hindi: "यह अंतिम समय-सीमा है।"),
            WordExample(thai: "เส้นตายอยู่ที่นี่", romanization: "sên-dtaai yùu thîi nîi", english: "The deadline is here.", hindi: "अंतिम समय-सीमा यहाँ है।"),
        ],
        2046: [
            WordExample(thai: "ผมซื้อที่ระลึก", romanization: "phǒm súe thîi-rá-lúek", english: "I am buying a souvenir", hindi: "मैं यादगार खरीद रहा हूँ"),
            WordExample(thai: "นี่คือที่ระลึก", romanization: "nîi khuue thîi-rá-lúek", english: "This is a souvenir", hindi: "यह यादगार है"),
        ],
    ]


    private static let examples4: [Int: [WordExample]] = [
        2047: [
            WordExample(thai: "ฉันกินทอดมะระ", romanization: "chǎn kin thôt-má-rá", english: "I eat fried bitter gourd.", hindi: "मैं तला करेला खाता/खाती हूँ।"),
            WordExample(thai: "ทอดมะระอร่อย", romanization: "thôt-má-rá à-ròi", english: "Fried bitter gourd is delicious.", hindi: "तला करेला स्वादिष्ट है।"),
        ],
        2048: [
            WordExample(thai: "ฉันกินทอดกะหล่ำดอก", romanization: "chǎn kin thôt-gà-làm-dàawk", english: "I eat fried cauliflower.", hindi: "मैं तला फूलगोभी खाता/खाती हूँ।"),
            WordExample(thai: "ทอดกะหล่ำดอกอร่อย", romanization: "thôt-gà-làm-dàawk à-ròi", english: "Fried cauliflower is delicious.", hindi: "तला फूलगोभी स्वादिष्ट है।"),
        ],
        2049: [
            WordExample(thai: "ฉันกินทอดบรอกโคลี", romanization: "chǎn kin thôt-brɔ̀ɔk-khoo-lii", english: "I eat fried broccoli.", hindi: "मैं तला ब्रोकली खाता/खाती हूँ।"),
            WordExample(thai: "ทอดบรอกโคลีอร่อย", romanization: "thôt-brɔ̀ɔk-khoo-lii à-ròi", english: "Fried broccoli is delicious.", hindi: "तला ब्रोकली स्वादिष्ट है।"),
        ],
        2050: [
            WordExample(thai: "ฉันกินทอดผักโขม", romanization: "chǎn kin thôt-phàk-khǒom", english: "I eat fried spinach.", hindi: "मैं तला पालक खाता/खाती हूँ।"),
            WordExample(thai: "ทอดผักโขมอร่อย", romanization: "thôt-phàk-khǒom à-ròi", english: "Fried spinach is delicious.", hindi: "तला पालक स्वादिष्ट है।"),
        ],
        2051: [
            WordExample(thai: "ฉันกินทอดผักกวางตุ้ง", romanization: "chǎn kin thôt-phàk-gwaang-tûng", english: "I eat fried bok choy.", hindi: "मैं तला बॉक चॉय खाता/खाती हूँ।"),
            WordExample(thai: "ทอดผักกวางตุ้งอร่อย", romanization: "thôt-phàk-gwaang-tûng à-ròi", english: "Fried bok choy is delicious.", hindi: "तला बॉक चॉय स्वादिष्ट है।"),
        ],
        2052: [
            WordExample(thai: "ฉันกินทอดเห็ดหอม", romanization: "chǎn kin thôt-hèt-hǎawm", english: "I eat fried shiitake mushroom.", hindi: "मैं तला शीताके मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ทอดเห็ดหอมอร่อย", romanization: "thôt-hèt-hǎawm à-ròi", english: "Fried shiitake mushroom is delicious.", hindi: "तला शीताके मशरूम स्वादिष्ट है।"),
        ],
        2053: [
            WordExample(thai: "ฉันกินทอดเห็ดนางรม", romanization: "chǎn kin thôt-hèt-naang-rom", english: "I eat fried oyster mushroom.", hindi: "मैं तला ऑयस्टर मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ทอดเห็ดนางรมอร่อย", romanization: "thôt-hèt-naang-rom à-ròi", english: "Fried oyster mushroom is delicious.", hindi: "तला ऑयस्टर मशरूम स्वादिष्ट है।"),
        ],
        2054: [
            WordExample(thai: "ฉันกินทอดเห็ดเข็มทอง", romanization: "chǎn kin thôt-hèt-khém-thaawng", english: "I eat fried enoki mushroom.", hindi: "मैं तला एनोकी मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ทอดเห็ดเข็มทองอร่อย", romanization: "thôt-hèt-khém-thaawng à-ròi", english: "Fried enoki mushroom is delicious.", hindi: "तला एनोकी मशरूम स्वादिष्ट है।"),
        ],
        2055: [
            WordExample(thai: "ฉันกินทอดเต้าหู้", romanization: "chǎn kin thôt-tâo-hûu", english: "I eat fried tofu.", hindi: "मैं तला टोफू खाता/खाती हूँ।"),
            WordExample(thai: "ทอดเต้าหู้อร่อย", romanization: "thôt-tâo-hûu à-ròi", english: "Fried tofu is delicious.", hindi: "तला टोफू स्वादिष्ट है।"),
        ],
        2056: [
            WordExample(thai: "ฉันกินทอดหมูยอ", romanization: "chǎn kin thôt-mǔu-yaw", english: "I eat fried Vietnamese pork sausage.", hindi: "मैं तला वियतनामी पोर्क सॉसेज खाता/खाती हूँ।"),
            WordExample(thai: "ทอดหมูยออร่อย", romanization: "thôt-mǔu-yaw à-ròi", english: "Fried vietnamese pork sausage is delicious.", hindi: "तला वियतनामी पोर्क सॉसेज स्वादिष्ट है।"),
        ],
        2057: [
            WordExample(thai: "ฉันกินทอดปลาดุก", romanization: "chǎn kin thôt-plaa-dùk", english: "I eat fried catfish.", hindi: "मैं तला कैटफ़िश खाता/खाती हूँ।"),
            WordExample(thai: "ทอดปลาดุกอร่อย", romanization: "thôt-plaa-dùk à-ròi", english: "Fried catfish is delicious.", hindi: "तला कैटफ़िश स्वादिष्ट है।"),
        ],
        2058: [
            WordExample(thai: "ฉันกินทอดปลาทู", romanization: "chǎn kin thôt-plaa-thuu", english: "I eat fried mackerel.", hindi: "मैं तला मैकेरल खाता/खाती हूँ।"),
            WordExample(thai: "ทอดปลาทูอร่อย", romanization: "thôt-plaa-thuu à-ròi", english: "Fried mackerel is delicious.", hindi: "तला मैकेरल स्वादिष्ट है।"),
        ],
        2059: [
            WordExample(thai: "ฉันกินทอดปลาหมึก", romanization: "chǎn kin thôt-plaa-mʉ̀k", english: "I eat fried squid.", hindi: "मैं तला स्क्विड खाता/खाती हूँ।"),
            WordExample(thai: "ทอดปลาหมึกอร่อย", romanization: "thôt-plaa-mʉ̀k à-ròi", english: "Fried squid is delicious.", hindi: "तला स्क्विड स्वादिष्ट है।"),
        ],
        2060: [
            WordExample(thai: "ฉันกินทอดหอยแมลงภู่", romanization: "chǎn kin thôt-hɔ̌ɔi-mae-lang-phùu", english: "I eat fried mussels.", hindi: "मैं तला शंबुक खाता/खाती हूँ।"),
            WordExample(thai: "ทอดหอยแมลงภู่อร่อย", romanization: "thôt-hɔ̌ɔi-mae-lang-phùu à-ròi", english: "Fried mussels is delicious.", hindi: "तला शंबुक स्वादिष्ट है।"),
        ],
        2061: [
            WordExample(thai: "ฉันกินทอดหอยลาย", romanization: "chǎn kin thôt-hɔ̌ɔi-laai", english: "I eat fried clams.", hindi: "मैं तला क्लैम खाता/खाती हूँ।"),
            WordExample(thai: "ทอดหอยลายอร่อย", romanization: "thôt-hɔ̌ɔi-laai à-ròi", english: "Fried clams is delicious.", hindi: "तला क्लैम स्वादिष्ट है।"),
        ],
        2062: [
            WordExample(thai: "ฉันกินทอดเนื้อไก่", romanization: "chǎn kin thôt-nʉ́a-gài", english: "I eat fried chicken meat.", hindi: "मैं तला चिकन मांस खाता/खाती हूँ।"),
            WordExample(thai: "ทอดเนื้อไก่อร่อย", romanization: "thôt-nʉ́a-gài à-ròi", english: "Fried chicken meat is delicious.", hindi: "तला चिकन मांस स्वादिष्ट है।"),
        ],
        2063: [
            WordExample(thai: "ฉันกินทอดเนื้อหมู", romanization: "chǎn kin thôt-nʉ́a-mǔu", english: "I eat fried pork.", hindi: "मैं तला सूअर का मांस खाता/खाती हूँ।"),
            WordExample(thai: "ทอดเนื้อหมูอร่อย", romanization: "thôt-nʉ́a-mǔu à-ròi", english: "Fried pork is delicious.", hindi: "तला सूअर का मांस स्वादिष्ट है।"),
        ],
        2064: [
            WordExample(thai: "ฉันกินทอดเนื้อวัว", romanization: "chǎn kin thôt-nʉ́a-wua", english: "I eat fried beef.", hindi: "मैं तला बीफ खाता/खाती हूँ।"),
            WordExample(thai: "ทอดเนื้อวัวอร่อย", romanization: "thôt-nʉ́a-wua à-ròi", english: "Fried beef is delicious.", hindi: "तला बीफ स्वादिष्ट है।"),
        ],
        2065: [
            WordExample(thai: "ฉันกินทอดกากหมู", romanization: "chǎn kin thôt-gàak-mǔu", english: "I eat fried pork cracklings.", hindi: "मैं तला कुरकुरी सूअर की चर्बी खाता/खाती हूँ।"),
            WordExample(thai: "ทอดกากหมูอร่อย", romanization: "thôt-gàak-mǔu à-ròi", english: "Fried pork cracklings is delicious.", hindi: "तला कुरकुरी सूअर की चर्बी स्वादिष्ट है।"),
        ],
        2066: [
            WordExample(thai: "ฉันกินทอดไข่เยี่ยวม้า", romanization: "chǎn kin thôt-khài-yîao-máa", english: "I eat fried century egg.", hindi: "मैं तला सेंचुरी एग खाता/खाती हूँ।"),
            WordExample(thai: "ทอดไข่เยี่ยวม้าอร่อย", romanization: "thôt-khài-yîao-máa à-ròi", english: "Fried century egg is delicious.", hindi: "तला सेंचुरी एग स्वादिष्ट है।"),
        ],
        2067: [
            WordExample(thai: "ฉันกินทอดปลาสลิด", romanization: "chǎn kin thôt-plaa-sà-lìt", english: "I eat fried snakehead gourami.", hindi: "मैं तला स्नेकहेड गौरामी मछली खाता/खाती हूँ।"),
            WordExample(thai: "ทอดปลาสลิดอร่อย", romanization: "thôt-plaa-sà-lìt à-ròi", english: "Fried snakehead gourami is delicious.", hindi: "तला स्नेकहेड गौरामी मछली स्वादिष्ट है।"),
        ],
        2068: [
            WordExample(thai: "ฉันกินทอดหมูกรอบ", romanization: "chǎn kin thôt-mǔu-grɔ̀ɔp", english: "I eat fried crispy pork belly.", hindi: "मैं तला कुरकुरा पोर्क बेली खाता/खाती हूँ।"),
            WordExample(thai: "ทอดหมูกรอบอร่อย", romanization: "thôt-mǔu-grɔ̀ɔp à-ròi", english: "Fried crispy pork belly is delicious.", hindi: "तला कुरकुरा पोर्क बेली स्वादिष्ट है।"),
        ],
        2069: [
            WordExample(thai: "ฉันกินทอดไก่ฉีก", romanization: "chǎn kin thôt-gài-chìik", english: "I eat fried shredded chicken.", hindi: "मैं तला रेशेदार चिकन खाता/खाती हूँ।"),
            WordExample(thai: "ทอดไก่ฉีกอร่อย", romanization: "thôt-gài-chìik à-ròi", english: "Fried shredded chicken is delicious.", hindi: "तला रेशेदार चिकन स्वादिष्ट है।"),
        ],
        2070: [
            WordExample(thai: "ฉันกินทอดหมูสับ", romanization: "chǎn kin thôt-mǔu-sàp", english: "I eat fried minced pork.", hindi: "मैं तला सूअर का कीमा खाता/खाती हूँ।"),
            WordExample(thai: "ทอดหมูสับอร่อย", romanization: "thôt-mǔu-sàp à-ròi", english: "Fried minced pork is delicious.", hindi: "तला सूअर का कीमा स्वादिष्ट है।"),
        ],
        2071: [
            WordExample(thai: "ฉันกินทอดกุ้งแห้ง", romanization: "chǎn kin thôt-gûng-hâeng", english: "I eat fried dried shrimp.", hindi: "मैं तला सूखी झींगा खाता/खाती हूँ।"),
            WordExample(thai: "ทอดกุ้งแห้งอร่อย", romanization: "thôt-gûng-hâeng à-ròi", english: "Fried dried shrimp is delicious.", hindi: "तला सूखी झींगा स्वादिष्ट है।"),
        ],
        2072: [
            WordExample(thai: "ฉันกินย่างมะระ", romanization: "chǎn kin yâang-má-rá", english: "I eat grilled bitter gourd.", hindi: "मैं ग्रिल्ड करेला खाता/खाती हूँ।"),
            WordExample(thai: "ย่างมะระอร่อย", romanization: "yâang-má-rá à-ròi", english: "Grilled bitter gourd is delicious.", hindi: "ग्रिल्ड करेला स्वादिष्ट है।"),
        ],
        2073: [
            WordExample(thai: "ฉันกินย่างกะหล่ำดอก", romanization: "chǎn kin yâang-gà-làm-dàawk", english: "I eat grilled cauliflower.", hindi: "मैं ग्रिल्ड फूलगोभी खाता/खाती हूँ।"),
            WordExample(thai: "ย่างกะหล่ำดอกอร่อย", romanization: "yâang-gà-làm-dàawk à-ròi", english: "Grilled cauliflower is delicious.", hindi: "ग्रिल्ड फूलगोभी स्वादिष्ट है।"),
        ],
        2074: [
            WordExample(thai: "ฉันกินย่างบรอกโคลี", romanization: "chǎn kin yâang-brɔ̀ɔk-khoo-lii", english: "I eat grilled broccoli.", hindi: "मैं ग्रिल्ड ब्रोकली खाता/खाती हूँ।"),
            WordExample(thai: "ย่างบรอกโคลีอร่อย", romanization: "yâang-brɔ̀ɔk-khoo-lii à-ròi", english: "Grilled broccoli is delicious.", hindi: "ग्रिल्ड ब्रोकली स्वादिष्ट है।"),
        ],
        2075: [
            WordExample(thai: "ฉันกินย่างผักโขม", romanization: "chǎn kin yâang-phàk-khǒom", english: "I eat grilled spinach.", hindi: "मैं ग्रिल्ड पालक खाता/खाती हूँ।"),
            WordExample(thai: "ย่างผักโขมอร่อย", romanization: "yâang-phàk-khǒom à-ròi", english: "Grilled spinach is delicious.", hindi: "ग्रिल्ड पालक स्वादिष्ट है।"),
        ],
        2076: [
            WordExample(thai: "ฉันกินย่างผักกวางตุ้ง", romanization: "chǎn kin yâang-phàk-gwaang-tûng", english: "I eat grilled bok choy.", hindi: "मैं ग्रिल्ड बॉक चॉय खाता/खाती हूँ।"),
            WordExample(thai: "ย่างผักกวางตุ้งอร่อย", romanization: "yâang-phàk-gwaang-tûng à-ròi", english: "Grilled bok choy is delicious.", hindi: "ग्रिल्ड बॉक चॉय स्वादिष्ट है।"),
        ],
        2077: [
            WordExample(thai: "ฉันกินย่างเห็ดหอม", romanization: "chǎn kin yâang-hèt-hǎawm", english: "I eat grilled shiitake mushroom.", hindi: "मैं ग्रिल्ड शीताके मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ย่างเห็ดหอมอร่อย", romanization: "yâang-hèt-hǎawm à-ròi", english: "Grilled shiitake mushroom is delicious.", hindi: "ग्रिल्ड शीताके मशरूम स्वादिष्ट है।"),
        ],
        2078: [
            WordExample(thai: "ฉันกินย่างเห็ดนางรม", romanization: "chǎn kin yâang-hèt-naang-rom", english: "I eat grilled oyster mushroom.", hindi: "मैं ग्रिल्ड ऑयस्टर मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ย่างเห็ดนางรมอร่อย", romanization: "yâang-hèt-naang-rom à-ròi", english: "Grilled oyster mushroom is delicious.", hindi: "ग्रिल्ड ऑयस्टर मशरूम स्वादिष्ट है।"),
        ],
        2079: [
            WordExample(thai: "ฉันกินย่างเห็ดเข็มทอง", romanization: "chǎn kin yâang-hèt-khém-thaawng", english: "I eat grilled enoki mushroom.", hindi: "मैं ग्रिल्ड एनोकी मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ย่างเห็ดเข็มทองอร่อย", romanization: "yâang-hèt-khém-thaawng à-ròi", english: "Grilled enoki mushroom is delicious.", hindi: "ग्रिल्ड एनोकी मशरूम स्वादिष्ट है।"),
        ],
        2080: [
            WordExample(thai: "ฉันกินย่างเต้าหู้", romanization: "chǎn kin yâang-tâo-hûu", english: "I eat grilled tofu.", hindi: "मैं ग्रिल्ड टोफू खाता/खाती हूँ।"),
            WordExample(thai: "ย่างเต้าหู้อร่อย", romanization: "yâang-tâo-hûu à-ròi", english: "Grilled tofu is delicious.", hindi: "ग्रिल्ड टोफू स्वादिष्ट है।"),
        ],
        2081: [
            WordExample(thai: "ฉันกินย่างหมูยอ", romanization: "chǎn kin yâang-mǔu-yaw", english: "I eat grilled Vietnamese pork sausage.", hindi: "मैं ग्रिल्ड वियतनामी पोर्क सॉसेज खाता/खाती हूँ।"),
            WordExample(thai: "ย่างหมูยออร่อย", romanization: "yâang-mǔu-yaw à-ròi", english: "Grilled vietnamese pork sausage is delicious.", hindi: "ग्रिल्ड वियतनामी पोर्क सॉसेज स्वादिष्ट है।"),
        ],
        2082: [
            WordExample(thai: "ฉันกินย่างปลาดุก", romanization: "chǎn kin yâang-plaa-dùk", english: "I eat grilled catfish.", hindi: "मैं ग्रिल्ड कैटफ़िश खाता/खाती हूँ।"),
            WordExample(thai: "ย่างปลาดุกอร่อย", romanization: "yâang-plaa-dùk à-ròi", english: "Grilled catfish is delicious.", hindi: "ग्रिल्ड कैटफ़िश स्वादिष्ट है।"),
        ],
        2083: [
            WordExample(thai: "ฉันกินย่างปลาทู", romanization: "chǎn kin yâang-plaa-thuu", english: "I eat grilled mackerel.", hindi: "मैं ग्रिल्ड मैकेरल खाता/खाती हूँ।"),
            WordExample(thai: "ย่างปลาทูอร่อย", romanization: "yâang-plaa-thuu à-ròi", english: "Grilled mackerel is delicious.", hindi: "ग्रिल्ड मैकेरल स्वादिष्ट है।"),
        ],
        2084: [
            WordExample(thai: "ฉันกินย่างปลาหมึก", romanization: "chǎn kin yâang-plaa-mʉ̀k", english: "I eat grilled squid.", hindi: "मैं ग्रिल्ड स्क्विड खाता/खाती हूँ।"),
            WordExample(thai: "ย่างปลาหมึกอร่อย", romanization: "yâang-plaa-mʉ̀k à-ròi", english: "Grilled squid is delicious.", hindi: "ग्रिल्ड स्क्विड स्वादिष्ट है।"),
        ],
        2085: [
            WordExample(thai: "ฉันกินย่างหอยแมลงภู่", romanization: "chǎn kin yâang-hɔ̌ɔi-mae-lang-phùu", english: "I eat grilled mussels.", hindi: "मैं ग्रिल्ड शंबुक खाता/खाती हूँ।"),
            WordExample(thai: "ย่างหอยแมลงภู่อร่อย", romanization: "yâang-hɔ̌ɔi-mae-lang-phùu à-ròi", english: "Grilled mussels is delicious.", hindi: "ग्रिल्ड शंबुक स्वादिष्ट है।"),
        ],
        2086: [
            WordExample(thai: "ฉันกินย่างหอยลาย", romanization: "chǎn kin yâang-hɔ̌ɔi-laai", english: "I eat grilled clams.", hindi: "मैं ग्रिल्ड क्लैम खाता/खाती हूँ।"),
            WordExample(thai: "ย่างหอยลายอร่อย", romanization: "yâang-hɔ̌ɔi-laai à-ròi", english: "Grilled clams is delicious.", hindi: "ग्रिल्ड क्लैम स्वादिष्ट है।"),
        ],
        2087: [
            WordExample(thai: "ฉันกินย่างเนื้อไก่", romanization: "chǎn kin yâang-nʉ́a-gài", english: "I eat grilled chicken meat.", hindi: "मैं ग्रिल्ड चिकन मांस खाता/खाती हूँ।"),
            WordExample(thai: "ย่างเนื้อไก่อร่อย", romanization: "yâang-nʉ́a-gài à-ròi", english: "Grilled chicken meat is delicious.", hindi: "ग्रिल्ड चिकन मांस स्वादिष्ट है।"),
        ],
        2088: [
            WordExample(thai: "ฉันกินย่างเนื้อหมู", romanization: "chǎn kin yâang-nʉ́a-mǔu", english: "I eat grilled pork.", hindi: "मैं ग्रिल्ड सूअर का मांस खाता/खाती हूँ।"),
            WordExample(thai: "ย่างเนื้อหมูอร่อย", romanization: "yâang-nʉ́a-mǔu à-ròi", english: "Grilled pork is delicious.", hindi: "ग्रिल्ड सूअर का मांस स्वादिष्ट है।"),
        ],
        2089: [
            WordExample(thai: "ฉันกินย่างเนื้อวัว", romanization: "chǎn kin yâang-nʉ́a-wua", english: "I eat grilled beef.", hindi: "मैं ग्रिल्ड बीफ खाता/खाती हूँ।"),
            WordExample(thai: "ย่างเนื้อวัวอร่อย", romanization: "yâang-nʉ́a-wua à-ròi", english: "Grilled beef is delicious.", hindi: "ग्रिल्ड बीफ स्वादिष्ट है।"),
        ],
        2090: [
            WordExample(thai: "ฉันกินย่างกากหมู", romanization: "chǎn kin yâang-gàak-mǔu", english: "I eat grilled pork cracklings.", hindi: "मैं ग्रिल्ड कुरकुरी सूअर की चर्बी खाता/खाती हूँ।"),
            WordExample(thai: "ย่างกากหมูอร่อย", romanization: "yâang-gàak-mǔu à-ròi", english: "Grilled pork cracklings is delicious.", hindi: "ग्रिल्ड कुरकुरी सूअर की चर्बी स्वादिष्ट है।"),
        ],
        2091: [
            WordExample(thai: "ฉันกินย่างไข่เยี่ยวม้า", romanization: "chǎn kin yâang-khài-yîao-máa", english: "I eat grilled century egg.", hindi: "मैं ग्रिल्ड सेंचुरी एग खाता/खाती हूँ।"),
            WordExample(thai: "ย่างไข่เยี่ยวม้าอร่อย", romanization: "yâang-khài-yîao-máa à-ròi", english: "Grilled century egg is delicious.", hindi: "ग्रिल्ड सेंचुरी एग स्वादिष्ट है।"),
        ],
        2092: [
            WordExample(thai: "ฉันกินย่างปลาสลิด", romanization: "chǎn kin yâang-plaa-sà-lìt", english: "I eat grilled snakehead gourami.", hindi: "मैं ग्रिल्ड स्नेकहेड गौरामी मछली खाता/खाती हूँ।"),
            WordExample(thai: "ย่างปลาสลิดอร่อย", romanization: "yâang-plaa-sà-lìt à-ròi", english: "Grilled snakehead gourami is delicious.", hindi: "ग्रिल्ड स्नेकहेड गौरामी मछली स्वादिष्ट है।"),
        ],
        2093: [
            WordExample(thai: "ฉันกินย่างหมูกรอบ", romanization: "chǎn kin yâang-mǔu-grɔ̀ɔp", english: "I eat grilled crispy pork belly.", hindi: "मैं ग्रिल्ड कुरकुरा पोर्क बेली खाता/खाती हूँ।"),
            WordExample(thai: "ย่างหมูกรอบอร่อย", romanization: "yâang-mǔu-grɔ̀ɔp à-ròi", english: "Grilled crispy pork belly is delicious.", hindi: "ग्रिल्ड कुरकुरा पोर्क बेली स्वादिष्ट है।"),
        ],
        2094: [
            WordExample(thai: "ฉันกินย่างไก่ฉีก", romanization: "chǎn kin yâang-gài-chìik", english: "I eat grilled shredded chicken.", hindi: "मैं ग्रिल्ड रेशेदार चिकन खाता/खाती हूँ।"),
            WordExample(thai: "ย่างไก่ฉีกอร่อย", romanization: "yâang-gài-chìik à-ròi", english: "Grilled shredded chicken is delicious.", hindi: "ग्रिल्ड रेशेदार चिकन स्वादिष्ट है।"),
        ],
        2095: [
            WordExample(thai: "ฉันกินย่างหมูสับ", romanization: "chǎn kin yâang-mǔu-sàp", english: "I eat grilled minced pork.", hindi: "मैं ग्रिल्ड सूअर का कीमा खाता/खाती हूँ।"),
            WordExample(thai: "ย่างหมูสับอร่อย", romanization: "yâang-mǔu-sàp à-ròi", english: "Grilled minced pork is delicious.", hindi: "ग्रिल्ड सूअर का कीमा स्वादिष्ट है।"),
        ],
        2096: [
            WordExample(thai: "ฉันกินย่างกุ้งแห้ง", romanization: "chǎn kin yâang-gûng-hâeng", english: "I eat grilled dried shrimp.", hindi: "मैं ग्रिल्ड सूखी झींगा खाता/खाती हूँ।"),
            WordExample(thai: "ย่างกุ้งแห้งอร่อย", romanization: "yâang-gûng-hâeng à-ròi", english: "Grilled dried shrimp is delicious.", hindi: "ग्रिल्ड सूखी झींगा स्वादिष्ट है।"),
        ],
        2097: [
            WordExample(thai: "ฉันกินนึ่งมะระ", romanization: "chǎn kin nʉ̂ng-má-rá", english: "I eat steamed bitter gourd.", hindi: "मैं भाप में पका करेला खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งมะระอร่อย", romanization: "nʉ̂ng-má-rá à-ròi", english: "Steamed bitter gourd is delicious.", hindi: "भाप में पका करेला स्वादिष्ट है।"),
        ],
        2098: [
            WordExample(thai: "ฉันกินนึ่งกะหล่ำดอก", romanization: "chǎn kin nʉ̂ng-gà-làm-dàawk", english: "I eat steamed cauliflower.", hindi: "मैं भाप में पका फूलगोभी खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งกะหล่ำดอกอร่อย", romanization: "nʉ̂ng-gà-làm-dàawk à-ròi", english: "Steamed cauliflower is delicious.", hindi: "भाप में पका फूलगोभी स्वादिष्ट है।"),
        ],
        2099: [
            WordExample(thai: "ฉันกินนึ่งบรอกโคลี", romanization: "chǎn kin nʉ̂ng-brɔ̀ɔk-khoo-lii", english: "I eat steamed broccoli.", hindi: "मैं भाप में पका ब्रोकली खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งบรอกโคลีอร่อย", romanization: "nʉ̂ng-brɔ̀ɔk-khoo-lii à-ròi", english: "Steamed broccoli is delicious.", hindi: "भाप में पका ब्रोकली स्वादिष्ट है।"),
        ],
        2100: [
            WordExample(thai: "ฉันกินนึ่งผักโขม", romanization: "chǎn kin nʉ̂ng-phàk-khǒom", english: "I eat steamed spinach.", hindi: "मैं भाप में पका पालक खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งผักโขมอร่อย", romanization: "nʉ̂ng-phàk-khǒom à-ròi", english: "Steamed spinach is delicious.", hindi: "भाप में पका पालक स्वादिष्ट है।"),
        ],
        2101: [
            WordExample(thai: "ฉันกินนึ่งผักกวางตุ้ง", romanization: "chǎn kin nʉ̂ng-phàk-gwaang-tûng", english: "I eat steamed bok choy.", hindi: "मैं भाप में पका बॉक चॉय खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งผักกวางตุ้งอร่อย", romanization: "nʉ̂ng-phàk-gwaang-tûng à-ròi", english: "Steamed bok choy is delicious.", hindi: "भाप में पका बॉक चॉय स्वादिष्ट है।"),
        ],
        2102: [
            WordExample(thai: "ฉันกินนึ่งเห็ดหอม", romanization: "chǎn kin nʉ̂ng-hèt-hǎawm", english: "I eat steamed shiitake mushroom.", hindi: "मैं भाप में पका शीताके मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งเห็ดหอมอร่อย", romanization: "nʉ̂ng-hèt-hǎawm à-ròi", english: "Steamed shiitake mushroom is delicious.", hindi: "भाप में पका शीताके मशरूम स्वादिष्ट है।"),
        ],
        2103: [
            WordExample(thai: "ฉันกินนึ่งเห็ดนางรม", romanization: "chǎn kin nʉ̂ng-hèt-naang-rom", english: "I eat steamed oyster mushroom.", hindi: "मैं भाप में पका ऑयस्टर मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งเห็ดนางรมอร่อย", romanization: "nʉ̂ng-hèt-naang-rom à-ròi", english: "Steamed oyster mushroom is delicious.", hindi: "भाप में पका ऑयस्टर मशरूम स्वादिष्ट है।"),
        ],
        2104: [
            WordExample(thai: "ฉันกินนึ่งเห็ดเข็มทอง", romanization: "chǎn kin nʉ̂ng-hèt-khém-thaawng", english: "I eat steamed enoki mushroom.", hindi: "मैं भाप में पका एनोकी मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งเห็ดเข็มทองอร่อย", romanization: "nʉ̂ng-hèt-khém-thaawng à-ròi", english: "Steamed enoki mushroom is delicious.", hindi: "भाप में पका एनोकी मशरूम स्वादिष्ट है।"),
        ],
        2105: [
            WordExample(thai: "ฉันกินนึ่งเต้าหู้", romanization: "chǎn kin nʉ̂ng-tâo-hûu", english: "I eat steamed tofu.", hindi: "मैं भाप में पका टोफू खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งเต้าหู้อร่อย", romanization: "nʉ̂ng-tâo-hûu à-ròi", english: "Steamed tofu is delicious.", hindi: "भाप में पका टोफू स्वादिष्ट है।"),
        ],
        2106: [
            WordExample(thai: "ฉันกินนึ่งหมูยอ", romanization: "chǎn kin nʉ̂ng-mǔu-yaw", english: "I eat steamed Vietnamese pork sausage.", hindi: "मैं भाप में पका वियतनामी पोर्क सॉसेज खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งหมูยออร่อย", romanization: "nʉ̂ng-mǔu-yaw à-ròi", english: "Steamed vietnamese pork sausage is delicious.", hindi: "भाप में पका वियतनामी पोर्क सॉसेज स्वादिष्ट है।"),
        ],
        2107: [
            WordExample(thai: "ฉันกินนึ่งปลาดุก", romanization: "chǎn kin nʉ̂ng-plaa-dùk", english: "I eat steamed catfish.", hindi: "मैं भाप में पका कैटफ़िश खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งปลาดุกอร่อย", romanization: "nʉ̂ng-plaa-dùk à-ròi", english: "Steamed catfish is delicious.", hindi: "भाप में पका कैटफ़िश स्वादिष्ट है।"),
        ],
        2108: [
            WordExample(thai: "ฉันกินนึ่งปลาทู", romanization: "chǎn kin nʉ̂ng-plaa-thuu", english: "I eat steamed mackerel.", hindi: "मैं भाप में पका मैकेरल खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งปลาทูอร่อย", romanization: "nʉ̂ng-plaa-thuu à-ròi", english: "Steamed mackerel is delicious.", hindi: "भाप में पका मैकेरल स्वादिष्ट है।"),
        ],
        2109: [
            WordExample(thai: "ฉันกินนึ่งปลาหมึก", romanization: "chǎn kin nʉ̂ng-plaa-mʉ̀k", english: "I eat steamed squid.", hindi: "मैं भाप में पका स्क्विड खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งปลาหมึกอร่อย", romanization: "nʉ̂ng-plaa-mʉ̀k à-ròi", english: "Steamed squid is delicious.", hindi: "भाप में पका स्क्विड स्वादिष्ट है।"),
        ],
        2110: [
            WordExample(thai: "ฉันกินนึ่งหอยแมลงภู่", romanization: "chǎn kin nʉ̂ng-hɔ̌ɔi-mae-lang-phùu", english: "I eat steamed mussels.", hindi: "मैं भाप में पका शंबुक खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งหอยแมลงภู่อร่อย", romanization: "nʉ̂ng-hɔ̌ɔi-mae-lang-phùu à-ròi", english: "Steamed mussels is delicious.", hindi: "भाप में पका शंबुक स्वादिष्ट है।"),
        ],
        2111: [
            WordExample(thai: "ฉันกินนึ่งหอยลาย", romanization: "chǎn kin nʉ̂ng-hɔ̌ɔi-laai", english: "I eat steamed clams.", hindi: "मैं भाप में पका क्लैम खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งหอยลายอร่อย", romanization: "nʉ̂ng-hɔ̌ɔi-laai à-ròi", english: "Steamed clams is delicious.", hindi: "भाप में पका क्लैम स्वादिष्ट है।"),
        ],
        2112: [
            WordExample(thai: "ฉันกินนึ่งเนื้อไก่", romanization: "chǎn kin nʉ̂ng-nʉ́a-gài", english: "I eat steamed chicken meat.", hindi: "मैं भाप में पका चिकन मांस खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งเนื้อไก่อร่อย", romanization: "nʉ̂ng-nʉ́a-gài à-ròi", english: "Steamed chicken meat is delicious.", hindi: "भाप में पका चिकन मांस स्वादिष्ट है।"),
        ],
        2113: [
            WordExample(thai: "ฉันกินนึ่งเนื้อหมู", romanization: "chǎn kin nʉ̂ng-nʉ́a-mǔu", english: "I eat steamed pork.", hindi: "मैं भाप में पका सूअर का मांस खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งเนื้อหมูอร่อย", romanization: "nʉ̂ng-nʉ́a-mǔu à-ròi", english: "Steamed pork is delicious.", hindi: "भाप में पका सूअर का मांस स्वादिष्ट है।"),
        ],
        2114: [
            WordExample(thai: "ฉันกินนึ่งเนื้อวัว", romanization: "chǎn kin nʉ̂ng-nʉ́a-wua", english: "I eat steamed beef.", hindi: "मैं भाप में पका बीफ खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งเนื้อวัวอร่อย", romanization: "nʉ̂ng-nʉ́a-wua à-ròi", english: "Steamed beef is delicious.", hindi: "भाप में पका बीफ स्वादिष्ट है।"),
        ],
        2115: [
            WordExample(thai: "ฉันกินนึ่งกากหมู", romanization: "chǎn kin nʉ̂ng-gàak-mǔu", english: "I eat steamed pork cracklings.", hindi: "मैं भाप में पका कुरकुरी सूअर की चर्बी खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งกากหมูอร่อย", romanization: "nʉ̂ng-gàak-mǔu à-ròi", english: "Steamed pork cracklings is delicious.", hindi: "भाप में पका कुरकुरी सूअर की चर्बी स्वादिष्ट है।"),
        ],
        2116: [
            WordExample(thai: "ฉันกินนึ่งไข่เยี่ยวม้า", romanization: "chǎn kin nʉ̂ng-khài-yîao-máa", english: "I eat steamed century egg.", hindi: "मैं भाप में पका सेंचुरी एग खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งไข่เยี่ยวม้าอร่อย", romanization: "nʉ̂ng-khài-yîao-máa à-ròi", english: "Steamed century egg is delicious.", hindi: "भाप में पका सेंचुरी एग स्वादिष्ट है।"),
        ],
        2117: [
            WordExample(thai: "ฉันกินนึ่งปลาสลิด", romanization: "chǎn kin nʉ̂ng-plaa-sà-lìt", english: "I eat steamed snakehead gourami.", hindi: "मैं भाप में पका स्नेकहेड गौरामी मछली खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งปลาสลิดอร่อย", romanization: "nʉ̂ng-plaa-sà-lìt à-ròi", english: "Steamed snakehead gourami is delicious.", hindi: "भाप में पका स्नेकहेड गौरामी मछली स्वादिष्ट है।"),
        ],
        2118: [
            WordExample(thai: "ฉันกินนึ่งหมูกรอบ", romanization: "chǎn kin nʉ̂ng-mǔu-grɔ̀ɔp", english: "I eat steamed crispy pork belly.", hindi: "मैं भाप में पका कुरकुरा पोर्क बेली खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งหมูกรอบอร่อย", romanization: "nʉ̂ng-mǔu-grɔ̀ɔp à-ròi", english: "Steamed crispy pork belly is delicious.", hindi: "भाप में पका कुरकुरा पोर्क बेली स्वादिष्ट है।"),
        ],
        2119: [
            WordExample(thai: "ฉันกินนึ่งไก่ฉีก", romanization: "chǎn kin nʉ̂ng-gài-chìik", english: "I eat steamed shredded chicken.", hindi: "मैं भाप में पका रेशेदार चिकन खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งไก่ฉีกอร่อย", romanization: "nʉ̂ng-gài-chìik à-ròi", english: "Steamed shredded chicken is delicious.", hindi: "भाप में पका रेशेदार चिकन स्वादिष्ट है।"),
        ],
        2120: [
            WordExample(thai: "ฉันกินนึ่งหมูสับ", romanization: "chǎn kin nʉ̂ng-mǔu-sàp", english: "I eat steamed minced pork.", hindi: "मैं भाप में पका सूअर का कीमा खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งหมูสับอร่อย", romanization: "nʉ̂ng-mǔu-sàp à-ròi", english: "Steamed minced pork is delicious.", hindi: "भाप में पका सूअर का कीमा स्वादिष्ट है।"),
        ],
        2121: [
            WordExample(thai: "ฉันกินนึ่งกุ้งแห้ง", romanization: "chǎn kin nʉ̂ng-gûng-hâeng", english: "I eat steamed dried shrimp.", hindi: "मैं भाप में पका सूखी झींगा खाता/खाती हूँ।"),
            WordExample(thai: "นึ่งกุ้งแห้งอร่อย", romanization: "nʉ̂ng-gûng-hâeng à-ròi", english: "Steamed dried shrimp is delicious.", hindi: "भाप में पका सूखी झींगा स्वादिष्ट है।"),
        ],
        2122: [
            WordExample(thai: "ฉันกินผัดมะระ", romanization: "chǎn kin phàt-má-rá", english: "I eat stir-fried bitter gourd.", hindi: "मैं भुना करेला खाता/खाती हूँ।"),
            WordExample(thai: "ผัดมะระอร่อย", romanization: "phàt-má-rá à-ròi", english: "Stir-fried bitter gourd is delicious.", hindi: "भुना करेला स्वादिष्ट है।"),
        ],
        2123: [
            WordExample(thai: "ฉันกินผัดกะหล่ำดอก", romanization: "chǎn kin phàt-gà-làm-dàawk", english: "I eat stir-fried cauliflower.", hindi: "मैं भुना फूलगोभी खाता/खाती हूँ।"),
            WordExample(thai: "ผัดกะหล่ำดอกอร่อย", romanization: "phàt-gà-làm-dàawk à-ròi", english: "Stir-fried cauliflower is delicious.", hindi: "भुना फूलगोभी स्वादिष्ट है।"),
        ],
        2124: [
            WordExample(thai: "ฉันกินผัดบรอกโคลี", romanization: "chǎn kin phàt-brɔ̀ɔk-khoo-lii", english: "I eat stir-fried broccoli.", hindi: "मैं भुना ब्रोकली खाता/खाती हूँ।"),
            WordExample(thai: "ผัดบรอกโคลีอร่อย", romanization: "phàt-brɔ̀ɔk-khoo-lii à-ròi", english: "Stir-fried broccoli is delicious.", hindi: "भुना ब्रोकली स्वादिष्ट है।"),
        ],
        2125: [
            WordExample(thai: "ฉันกินผัดผักโขม", romanization: "chǎn kin phàt-phàk-khǒom", english: "I eat stir-fried spinach.", hindi: "मैं भुना पालक खाता/खाती हूँ।"),
            WordExample(thai: "ผัดผักโขมอร่อย", romanization: "phàt-phàk-khǒom à-ròi", english: "Stir-fried spinach is delicious.", hindi: "भुना पालक स्वादिष्ट है।"),
        ],
        2126: [
            WordExample(thai: "ฉันกินผัดผักกวางตุ้ง", romanization: "chǎn kin phàt-phàk-gwaang-tûng", english: "I eat stir-fried bok choy.", hindi: "मैं भुना बॉक चॉय खाता/खाती हूँ।"),
            WordExample(thai: "ผัดผักกวางตุ้งอร่อย", romanization: "phàt-phàk-gwaang-tûng à-ròi", english: "Stir-fried bok choy is delicious.", hindi: "भुना बॉक चॉय स्वादिष्ट है।"),
        ],
        2127: [
            WordExample(thai: "ฉันกินผัดเห็ดหอม", romanization: "chǎn kin phàt-hèt-hǎawm", english: "I eat stir-fried shiitake mushroom.", hindi: "मैं भुना शीताके मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ผัดเห็ดหอมอร่อย", romanization: "phàt-hèt-hǎawm à-ròi", english: "Stir-fried shiitake mushroom is delicious.", hindi: "भुना शीताके मशरूम स्वादिष्ट है।"),
        ],
        2128: [
            WordExample(thai: "ฉันกินผัดเห็ดนางรม", romanization: "chǎn kin phàt-hèt-naang-rom", english: "I eat stir-fried oyster mushroom.", hindi: "मैं भुना ऑयस्टर मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ผัดเห็ดนางรมอร่อย", romanization: "phàt-hèt-naang-rom à-ròi", english: "Stir-fried oyster mushroom is delicious.", hindi: "भुना ऑयस्टर मशरूम स्वादिष्ट है।"),
        ],
        2129: [
            WordExample(thai: "ฉันกินผัดเห็ดเข็มทอง", romanization: "chǎn kin phàt-hèt-khém-thaawng", english: "I eat stir-fried enoki mushroom.", hindi: "मैं भुना एनोकी मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ผัดเห็ดเข็มทองอร่อย", romanization: "phàt-hèt-khém-thaawng à-ròi", english: "Stir-fried enoki mushroom is delicious.", hindi: "भुना एनोकी मशरूम स्वादिष्ट है।"),
        ],
        2130: [
            WordExample(thai: "ฉันกินผัดเต้าหู้", romanization: "chǎn kin phàt-tâo-hûu", english: "I eat stir-fried tofu.", hindi: "मैं भुना टोफू खाता/खाती हूँ।"),
            WordExample(thai: "ผัดเต้าหู้อร่อย", romanization: "phàt-tâo-hûu à-ròi", english: "Stir-fried tofu is delicious.", hindi: "भुना टोफू स्वादिष्ट है।"),
        ],
        2131: [
            WordExample(thai: "ฉันกินผัดหมูยอ", romanization: "chǎn kin phàt-mǔu-yaw", english: "I eat stir-fried Vietnamese pork sausage.", hindi: "मैं भुना वियतनामी पोर्क सॉसेज खाता/खाती हूँ।"),
            WordExample(thai: "ผัดหมูยออร่อย", romanization: "phàt-mǔu-yaw à-ròi", english: "Stir-fried vietnamese pork sausage is delicious.", hindi: "भुना वियतनामी पोर्क सॉसेज स्वादिष्ट है।"),
        ],
        2132: [
            WordExample(thai: "ฉันกินผัดปลาดุก", romanization: "chǎn kin phàt-plaa-dùk", english: "I eat stir-fried catfish.", hindi: "मैं भुना कैटफ़िश खाता/खाती हूँ।"),
            WordExample(thai: "ผัดปลาดุกอร่อย", romanization: "phàt-plaa-dùk à-ròi", english: "Stir-fried catfish is delicious.", hindi: "भुना कैटफ़िश स्वादिष्ट है।"),
        ],
        2133: [
            WordExample(thai: "ฉันกินผัดปลาทู", romanization: "chǎn kin phàt-plaa-thuu", english: "I eat stir-fried mackerel.", hindi: "मैं भुना मैकेरल खाता/खाती हूँ।"),
            WordExample(thai: "ผัดปลาทูอร่อย", romanization: "phàt-plaa-thuu à-ròi", english: "Stir-fried mackerel is delicious.", hindi: "भुना मैकेरल स्वादिष्ट है।"),
        ],
        2134: [
            WordExample(thai: "ฉันกินผัดปลาหมึก", romanization: "chǎn kin phàt-plaa-mʉ̀k", english: "I eat stir-fried squid.", hindi: "मैं भुना स्क्विड खाता/खाती हूँ।"),
            WordExample(thai: "ผัดปลาหมึกอร่อย", romanization: "phàt-plaa-mʉ̀k à-ròi", english: "Stir-fried squid is delicious.", hindi: "भुना स्क्विड स्वादिष्ट है।"),
        ],
        2135: [
            WordExample(thai: "ฉันกินผัดหอยแมลงภู่", romanization: "chǎn kin phàt-hɔ̌ɔi-mae-lang-phùu", english: "I eat stir-fried mussels.", hindi: "मैं भुना शंबुक खाता/खाती हूँ।"),
            WordExample(thai: "ผัดหอยแมลงภู่อร่อย", romanization: "phàt-hɔ̌ɔi-mae-lang-phùu à-ròi", english: "Stir-fried mussels is delicious.", hindi: "भुना शंबुक स्वादिष्ट है।"),
        ],
        2136: [
            WordExample(thai: "ฉันกินผัดหอยลาย", romanization: "chǎn kin phàt-hɔ̌ɔi-laai", english: "I eat stir-fried clams.", hindi: "मैं भुना क्लैम खाता/खाती हूँ।"),
            WordExample(thai: "ผัดหอยลายอร่อย", romanization: "phàt-hɔ̌ɔi-laai à-ròi", english: "Stir-fried clams is delicious.", hindi: "भुना क्लैम स्वादिष्ट है।"),
        ],
        2137: [
            WordExample(thai: "ฉันกินผัดเนื้อไก่", romanization: "chǎn kin phàt-nʉ́a-gài", english: "I eat stir-fried chicken meat.", hindi: "मैं भुना चिकन मांस खाता/खाती हूँ।"),
            WordExample(thai: "ผัดเนื้อไก่อร่อย", romanization: "phàt-nʉ́a-gài à-ròi", english: "Stir-fried chicken meat is delicious.", hindi: "भुना चिकन मांस स्वादिष्ट है।"),
        ],
        2138: [
            WordExample(thai: "ฉันกินผัดเนื้อหมู", romanization: "chǎn kin phàt-nʉ́a-mǔu", english: "I eat stir-fried pork.", hindi: "मैं भुना सूअर का मांस खाता/खाती हूँ।"),
            WordExample(thai: "ผัดเนื้อหมูอร่อย", romanization: "phàt-nʉ́a-mǔu à-ròi", english: "Stir-fried pork is delicious.", hindi: "भुना सूअर का मांस स्वादिष्ट है।"),
        ],
        2139: [
            WordExample(thai: "ฉันกินผัดเนื้อวัว", romanization: "chǎn kin phàt-nʉ́a-wua", english: "I eat stir-fried beef.", hindi: "मैं भुना बीफ खाता/खाती हूँ।"),
            WordExample(thai: "ผัดเนื้อวัวอร่อย", romanization: "phàt-nʉ́a-wua à-ròi", english: "Stir-fried beef is delicious.", hindi: "भुना बीफ स्वादिष्ट है।"),
        ],
        2140: [
            WordExample(thai: "ฉันกินผัดกากหมู", romanization: "chǎn kin phàt-gàak-mǔu", english: "I eat stir-fried pork cracklings.", hindi: "मैं भुना कुरकुरी सूअर की चर्बी खाता/खाती हूँ।"),
            WordExample(thai: "ผัดกากหมูอร่อย", romanization: "phàt-gàak-mǔu à-ròi", english: "Stir-fried pork cracklings is delicious.", hindi: "भुना कुरकुरी सूअर की चर्बी स्वादिष्ट है।"),
        ],
        2141: [
            WordExample(thai: "ฉันกินผัดไข่เยี่ยวม้า", romanization: "chǎn kin phàt-khài-yîao-máa", english: "I eat stir-fried century egg.", hindi: "मैं भुना सेंचुरी एग खाता/खाती हूँ।"),
            WordExample(thai: "ผัดไข่เยี่ยวม้าอร่อย", romanization: "phàt-khài-yîao-máa à-ròi", english: "Stir-fried century egg is delicious.", hindi: "भुना सेंचुरी एग स्वादिष्ट है।"),
        ],
        2142: [
            WordExample(thai: "ฉันกินผัดปลาสลิด", romanization: "chǎn kin phàt-plaa-sà-lìt", english: "I eat stir-fried snakehead gourami.", hindi: "मैं भुना स्नेकहेड गौरामी मछली खाता/खाती हूँ।"),
            WordExample(thai: "ผัดปลาสลิดอร่อย", romanization: "phàt-plaa-sà-lìt à-ròi", english: "Stir-fried snakehead gourami is delicious.", hindi: "भुना स्नेकहेड गौरामी मछली स्वादिष्ट है।"),
        ],
        2143: [
            WordExample(thai: "ฉันกินผัดหมูกรอบ", romanization: "chǎn kin phàt-mǔu-grɔ̀ɔp", english: "I eat stir-fried crispy pork belly.", hindi: "मैं भुना कुरकुरा पोर्क बेली खाता/खाती हूँ।"),
            WordExample(thai: "ผัดหมูกรอบอร่อย", romanization: "phàt-mǔu-grɔ̀ɔp à-ròi", english: "Stir-fried crispy pork belly is delicious.", hindi: "भुना कुरकुरा पोर्क बेली स्वादिष्ट है।"),
        ],
        2144: [
            WordExample(thai: "ฉันกินผัดไก่ฉีก", romanization: "chǎn kin phàt-gài-chìik", english: "I eat stir-fried shredded chicken.", hindi: "मैं भुना रेशेदार चिकन खाता/खाती हूँ।"),
            WordExample(thai: "ผัดไก่ฉีกอร่อย", romanization: "phàt-gài-chìik à-ròi", english: "Stir-fried shredded chicken is delicious.", hindi: "भुना रेशेदार चिकन स्वादिष्ट है।"),
        ],
        2145: [
            WordExample(thai: "ฉันกินผัดหมูสับ", romanization: "chǎn kin phàt-mǔu-sàp", english: "I eat stir-fried minced pork.", hindi: "मैं भुना सूअर का कीमा खाता/खाती हूँ।"),
            WordExample(thai: "ผัดหมูสับอร่อย", romanization: "phàt-mǔu-sàp à-ròi", english: "Stir-fried minced pork is delicious.", hindi: "भुना सूअर का कीमा स्वादिष्ट है।"),
        ],
        2146: [
            WordExample(thai: "ฉันกินผัดกุ้งแห้ง", romanization: "chǎn kin phàt-gûng-hâeng", english: "I eat stir-fried dried shrimp.", hindi: "मैं भुना सूखी झींगा खाता/खाती हूँ।"),
            WordExample(thai: "ผัดกุ้งแห้งอร่อย", romanization: "phàt-gûng-hâeng à-ròi", english: "Stir-fried dried shrimp is delicious.", hindi: "भुना सूखी झींगा स्वादिष्ट है।"),
        ],
        2147: [
            WordExample(thai: "ฉันกินต้มมะระ", romanization: "chǎn kin tôm-má-rá", english: "I eat boiled bitter gourd.", hindi: "मैं उबला करेला खाता/खाती हूँ।"),
            WordExample(thai: "ต้มมะระอร่อย", romanization: "tôm-má-rá à-ròi", english: "Boiled bitter gourd is delicious.", hindi: "उबला करेला स्वादिष्ट है।"),
        ],
        2148: [
            WordExample(thai: "ฉันกินต้มกะหล่ำดอก", romanization: "chǎn kin tôm-gà-làm-dàawk", english: "I eat boiled cauliflower.", hindi: "मैं उबला फूलगोभी खाता/खाती हूँ।"),
            WordExample(thai: "ต้มกะหล่ำดอกอร่อย", romanization: "tôm-gà-làm-dàawk à-ròi", english: "Boiled cauliflower is delicious.", hindi: "उबला फूलगोभी स्वादिष्ट है।"),
        ],
        2149: [
            WordExample(thai: "ฉันกินต้มบรอกโคลี", romanization: "chǎn kin tôm-brɔ̀ɔk-khoo-lii", english: "I eat boiled broccoli.", hindi: "मैं उबला ब्रोकली खाता/खाती हूँ।"),
            WordExample(thai: "ต้มบรอกโคลีอร่อย", romanization: "tôm-brɔ̀ɔk-khoo-lii à-ròi", english: "Boiled broccoli is delicious.", hindi: "उबला ब्रोकली स्वादिष्ट है।"),
        ],
        2150: [
            WordExample(thai: "ฉันกินต้มผักโขม", romanization: "chǎn kin tôm-phàk-khǒom", english: "I eat boiled spinach.", hindi: "मैं उबला पालक खाता/खाती हूँ।"),
            WordExample(thai: "ต้มผักโขมอร่อย", romanization: "tôm-phàk-khǒom à-ròi", english: "Boiled spinach is delicious.", hindi: "उबला पालक स्वादिष्ट है।"),
        ],
        2151: [
            WordExample(thai: "ฉันกินต้มผักกวางตุ้ง", romanization: "chǎn kin tôm-phàk-gwaang-tûng", english: "I eat boiled bok choy.", hindi: "मैं उबला बॉक चॉय खाता/खाती हूँ।"),
            WordExample(thai: "ต้มผักกวางตุ้งอร่อย", romanization: "tôm-phàk-gwaang-tûng à-ròi", english: "Boiled bok choy is delicious.", hindi: "उबला बॉक चॉय स्वादिष्ट है।"),
        ],
        2152: [
            WordExample(thai: "ฉันกินต้มเห็ดหอม", romanization: "chǎn kin tôm-hèt-hǎawm", english: "I eat boiled shiitake mushroom.", hindi: "मैं उबला शीताके मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ต้มเห็ดหอมอร่อย", romanization: "tôm-hèt-hǎawm à-ròi", english: "Boiled shiitake mushroom is delicious.", hindi: "उबला शीताके मशरूम स्वादिष्ट है।"),
        ],
        2153: [
            WordExample(thai: "ฉันกินต้มเห็ดนางรม", romanization: "chǎn kin tôm-hèt-naang-rom", english: "I eat boiled oyster mushroom.", hindi: "मैं उबला ऑयस्टर मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ต้มเห็ดนางรมอร่อย", romanization: "tôm-hèt-naang-rom à-ròi", english: "Boiled oyster mushroom is delicious.", hindi: "उबला ऑयस्टर मशरूम स्वादिष्ट है।"),
        ],
        2154: [
            WordExample(thai: "ฉันกินต้มเห็ดเข็มทอง", romanization: "chǎn kin tôm-hèt-khém-thaawng", english: "I eat boiled enoki mushroom.", hindi: "मैं उबला एनोकी मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ต้มเห็ดเข็มทองอร่อย", romanization: "tôm-hèt-khém-thaawng à-ròi", english: "Boiled enoki mushroom is delicious.", hindi: "उबला एनोकी मशरूम स्वादिष्ट है।"),
        ],
        2155: [
            WordExample(thai: "ฉันกินต้มเต้าหู้", romanization: "chǎn kin tôm-tâo-hûu", english: "I eat boiled tofu.", hindi: "मैं उबला टोफू खाता/खाती हूँ।"),
            WordExample(thai: "ต้มเต้าหู้อร่อย", romanization: "tôm-tâo-hûu à-ròi", english: "Boiled tofu is delicious.", hindi: "उबला टोफू स्वादिष्ट है।"),
        ],
        2156: [
            WordExample(thai: "ฉันกินต้มหมูยอ", romanization: "chǎn kin tôm-mǔu-yaw", english: "I eat boiled Vietnamese pork sausage.", hindi: "मैं उबला वियतनामी पोर्क सॉसेज खाता/खाती हूँ।"),
            WordExample(thai: "ต้มหมูยออร่อย", romanization: "tôm-mǔu-yaw à-ròi", english: "Boiled vietnamese pork sausage is delicious.", hindi: "उबला वियतनामी पोर्क सॉसेज स्वादिष्ट है।"),
        ],
        2157: [
            WordExample(thai: "ฉันกินต้มปลาดุก", romanization: "chǎn kin tôm-plaa-dùk", english: "I eat boiled catfish.", hindi: "मैं उबला कैटफ़िश खाता/खाती हूँ।"),
            WordExample(thai: "ต้มปลาดุกอร่อย", romanization: "tôm-plaa-dùk à-ròi", english: "Boiled catfish is delicious.", hindi: "उबला कैटफ़िश स्वादिष्ट है।"),
        ],
        2158: [
            WordExample(thai: "ฉันกินต้มปลาทู", romanization: "chǎn kin tôm-plaa-thuu", english: "I eat boiled mackerel.", hindi: "मैं उबला मैकेरल खाता/खाती हूँ।"),
            WordExample(thai: "ต้มปลาทูอร่อย", romanization: "tôm-plaa-thuu à-ròi", english: "Boiled mackerel is delicious.", hindi: "उबला मैकेरल स्वादिष्ट है।"),
        ],
        2159: [
            WordExample(thai: "ฉันกินต้มปลาหมึก", romanization: "chǎn kin tôm-plaa-mʉ̀k", english: "I eat boiled squid.", hindi: "मैं उबला स्क्विड खाता/खाती हूँ।"),
            WordExample(thai: "ต้มปลาหมึกอร่อย", romanization: "tôm-plaa-mʉ̀k à-ròi", english: "Boiled squid is delicious.", hindi: "उबला स्क्विड स्वादिष्ट है।"),
        ],
        2160: [
            WordExample(thai: "ฉันกินต้มหอยแมลงภู่", romanization: "chǎn kin tôm-hɔ̌ɔi-mae-lang-phùu", english: "I eat boiled mussels.", hindi: "मैं उबला शंबुक खाता/खाती हूँ।"),
            WordExample(thai: "ต้มหอยแมลงภู่อร่อย", romanization: "tôm-hɔ̌ɔi-mae-lang-phùu à-ròi", english: "Boiled mussels is delicious.", hindi: "उबला शंबुक स्वादिष्ट है।"),
        ],
        2161: [
            WordExample(thai: "ฉันกินต้มหอยลาย", romanization: "chǎn kin tôm-hɔ̌ɔi-laai", english: "I eat boiled clams.", hindi: "मैं उबला क्लैम खाता/खाती हूँ।"),
            WordExample(thai: "ต้มหอยลายอร่อย", romanization: "tôm-hɔ̌ɔi-laai à-ròi", english: "Boiled clams is delicious.", hindi: "उबला क्लैम स्वादिष्ट है।"),
        ],
        2162: [
            WordExample(thai: "ฉันกินต้มเนื้อไก่", romanization: "chǎn kin tôm-nʉ́a-gài", english: "I eat boiled chicken meat.", hindi: "मैं उबला चिकन मांस खाता/खाती हूँ।"),
            WordExample(thai: "ต้มเนื้อไก่อร่อย", romanization: "tôm-nʉ́a-gài à-ròi", english: "Boiled chicken meat is delicious.", hindi: "उबला चिकन मांस स्वादिष्ट है।"),
        ],
        2163: [
            WordExample(thai: "ฉันกินต้มเนื้อหมู", romanization: "chǎn kin tôm-nʉ́a-mǔu", english: "I eat boiled pork.", hindi: "मैं उबला सूअर का मांस खाता/खाती हूँ।"),
            WordExample(thai: "ต้มเนื้อหมูอร่อย", romanization: "tôm-nʉ́a-mǔu à-ròi", english: "Boiled pork is delicious.", hindi: "उबला सूअर का मांस स्वादिष्ट है।"),
        ],
        2164: [
            WordExample(thai: "ฉันกินต้มเนื้อวัว", romanization: "chǎn kin tôm-nʉ́a-wua", english: "I eat boiled beef.", hindi: "मैं उबला बीफ खाता/खाती हूँ।"),
            WordExample(thai: "ต้มเนื้อวัวอร่อย", romanization: "tôm-nʉ́a-wua à-ròi", english: "Boiled beef is delicious.", hindi: "उबला बीफ स्वादिष्ट है।"),
        ],
        2165: [
            WordExample(thai: "ฉันกินต้มกากหมู", romanization: "chǎn kin tôm-gàak-mǔu", english: "I eat boiled pork cracklings.", hindi: "मैं उबला कुरकुरी सूअर की चर्बी खाता/खाती हूँ।"),
            WordExample(thai: "ต้มกากหมูอร่อย", romanization: "tôm-gàak-mǔu à-ròi", english: "Boiled pork cracklings is delicious.", hindi: "उबला कुरकुरी सूअर की चर्बी स्वादिष्ट है।"),
        ],
        2166: [
            WordExample(thai: "ฉันกินต้มไข่เยี่ยวม้า", romanization: "chǎn kin tôm-khài-yîao-máa", english: "I eat boiled century egg.", hindi: "मैं उबला सेंचुरी एग खाता/खाती हूँ।"),
            WordExample(thai: "ต้มไข่เยี่ยวม้าอร่อย", romanization: "tôm-khài-yîao-máa à-ròi", english: "Boiled century egg is delicious.", hindi: "उबला सेंचुरी एग स्वादिष्ट है।"),
        ],
        2167: [
            WordExample(thai: "ฉันกินต้มปลาสลิด", romanization: "chǎn kin tôm-plaa-sà-lìt", english: "I eat boiled snakehead gourami.", hindi: "मैं उबला स्नेकहेड गौरामी मछली खाता/खाती हूँ।"),
            WordExample(thai: "ต้มปลาสลิดอร่อย", romanization: "tôm-plaa-sà-lìt à-ròi", english: "Boiled snakehead gourami is delicious.", hindi: "उबला स्नेकहेड गौरामी मछली स्वादिष्ट है।"),
        ],
        2168: [
            WordExample(thai: "ฉันกินต้มหมูกรอบ", romanization: "chǎn kin tôm-mǔu-grɔ̀ɔp", english: "I eat boiled crispy pork belly.", hindi: "मैं उबला कुरकुरा पोर्क बेली खाता/खाती हूँ।"),
            WordExample(thai: "ต้มหมูกรอบอร่อย", romanization: "tôm-mǔu-grɔ̀ɔp à-ròi", english: "Boiled crispy pork belly is delicious.", hindi: "उबला कुरकुरा पोर्क बेली स्वादिष्ट है।"),
        ],
        2169: [
            WordExample(thai: "ฉันกินต้มไก่ฉีก", romanization: "chǎn kin tôm-gài-chìik", english: "I eat boiled shredded chicken.", hindi: "मैं उबला रेशेदार चिकन खाता/खाती हूँ।"),
            WordExample(thai: "ต้มไก่ฉีกอร่อย", romanization: "tôm-gài-chìik à-ròi", english: "Boiled shredded chicken is delicious.", hindi: "उबला रेशेदार चिकन स्वादिष्ट है।"),
        ],
        2170: [
            WordExample(thai: "ฉันกินต้มหมูสับ", romanization: "chǎn kin tôm-mǔu-sàp", english: "I eat boiled minced pork.", hindi: "मैं उबला सूअर का कीमा खाता/खाती हूँ।"),
            WordExample(thai: "ต้มหมูสับอร่อย", romanization: "tôm-mǔu-sàp à-ròi", english: "Boiled minced pork is delicious.", hindi: "उबला सूअर का कीमा स्वादिष्ट है।"),
        ],
        2171: [
            WordExample(thai: "ฉันกินต้มกุ้งแห้ง", romanization: "chǎn kin tôm-gûng-hâeng", english: "I eat boiled dried shrimp.", hindi: "मैं उबला सूखी झींगा खाता/खाती हूँ।"),
            WordExample(thai: "ต้มกุ้งแห้งอร่อย", romanization: "tôm-gûng-hâeng à-ròi", english: "Boiled dried shrimp is delicious.", hindi: "उबला सूखी झींगा स्वादिष्ट है।"),
        ],
        2172: [
            WordExample(thai: "ฉันกินอบมะระ", romanization: "chǎn kin òp-má-rá", english: "I eat baked bitter gourd.", hindi: "मैं बेक किया हुआ करेला खाता/खाती हूँ।"),
            WordExample(thai: "อบมะระอร่อย", romanization: "òp-má-rá à-ròi", english: "Baked bitter gourd is delicious.", hindi: "बेक किया हुआ करेला स्वादिष्ट है।"),
        ],
        2173: [
            WordExample(thai: "ฉันกินอบกะหล่ำดอก", romanization: "chǎn kin òp-gà-làm-dàawk", english: "I eat baked cauliflower.", hindi: "मैं बेक किया हुआ फूलगोभी खाता/खाती हूँ।"),
            WordExample(thai: "อบกะหล่ำดอกอร่อย", romanization: "òp-gà-làm-dàawk à-ròi", english: "Baked cauliflower is delicious.", hindi: "बेक किया हुआ फूलगोभी स्वादिष्ट है।"),
        ],
        2174: [
            WordExample(thai: "ฉันกินอบบรอกโคลี", romanization: "chǎn kin òp-brɔ̀ɔk-khoo-lii", english: "I eat baked broccoli.", hindi: "मैं बेक किया हुआ ब्रोकली खाता/खाती हूँ।"),
            WordExample(thai: "อบบรอกโคลีอร่อย", romanization: "òp-brɔ̀ɔk-khoo-lii à-ròi", english: "Baked broccoli is delicious.", hindi: "बेक किया हुआ ब्रोकली स्वादिष्ट है।"),
        ],
        2175: [
            WordExample(thai: "ฉันกินอบผักโขม", romanization: "chǎn kin òp-phàk-khǒom", english: "I eat baked spinach.", hindi: "मैं बेक किया हुआ पालक खाता/खाती हूँ।"),
            WordExample(thai: "อบผักโขมอร่อย", romanization: "òp-phàk-khǒom à-ròi", english: "Baked spinach is delicious.", hindi: "बेक किया हुआ पालक स्वादिष्ट है।"),
        ],
        2176: [
            WordExample(thai: "ฉันกินอบผักกวางตุ้ง", romanization: "chǎn kin òp-phàk-gwaang-tûng", english: "I eat baked bok choy.", hindi: "मैं बेक किया हुआ बॉक चॉय खाता/खाती हूँ।"),
            WordExample(thai: "อบผักกวางตุ้งอร่อย", romanization: "òp-phàk-gwaang-tûng à-ròi", english: "Baked bok choy is delicious.", hindi: "बेक किया हुआ बॉक चॉय स्वादिष्ट है।"),
        ],
        2177: [
            WordExample(thai: "ฉันกินอบเห็ดหอม", romanization: "chǎn kin òp-hèt-hǎawm", english: "I eat baked shiitake mushroom.", hindi: "मैं बेक किया हुआ शीताके मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "อบเห็ดหอมอร่อย", romanization: "òp-hèt-hǎawm à-ròi", english: "Baked shiitake mushroom is delicious.", hindi: "बेक किया हुआ शीताके मशरूम स्वादिष्ट है।"),
        ],
        2178: [
            WordExample(thai: "ฉันกินอบเห็ดนางรม", romanization: "chǎn kin òp-hèt-naang-rom", english: "I eat baked oyster mushroom.", hindi: "मैं बेक किया हुआ ऑयस्टर मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "อบเห็ดนางรมอร่อย", romanization: "òp-hèt-naang-rom à-ròi", english: "Baked oyster mushroom is delicious.", hindi: "बेक किया हुआ ऑयस्टर मशरूम स्वादिष्ट है।"),
        ],
        2179: [
            WordExample(thai: "ฉันกินอบเห็ดเข็มทอง", romanization: "chǎn kin òp-hèt-khém-thaawng", english: "I eat baked enoki mushroom.", hindi: "मैं बेक किया हुआ एनोकी मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "อบเห็ดเข็มทองอร่อย", romanization: "òp-hèt-khém-thaawng à-ròi", english: "Baked enoki mushroom is delicious.", hindi: "बेक किया हुआ एनोकी मशरूम स्वादिष्ट है।"),
        ],
        2180: [
            WordExample(thai: "ฉันกินอบเต้าหู้", romanization: "chǎn kin òp-tâo-hûu", english: "I eat baked tofu.", hindi: "मैं बेक किया हुआ टोफू खाता/खाती हूँ।"),
            WordExample(thai: "อบเต้าหู้อร่อย", romanization: "òp-tâo-hûu à-ròi", english: "Baked tofu is delicious.", hindi: "बेक किया हुआ टोफू स्वादिष्ट है।"),
        ],
        2181: [
            WordExample(thai: "ฉันกินอบหมูยอ", romanization: "chǎn kin òp-mǔu-yaw", english: "I eat baked Vietnamese pork sausage.", hindi: "मैं बेक किया हुआ वियतनामी पोर्क सॉसेज खाता/खाती हूँ।"),
            WordExample(thai: "อบหมูยออร่อย", romanization: "òp-mǔu-yaw à-ròi", english: "Baked vietnamese pork sausage is delicious.", hindi: "बेक किया हुआ वियतनामी पोर्क सॉसेज स्वादिष्ट है।"),
        ],
        2182: [
            WordExample(thai: "ฉันกินอบปลาดุก", romanization: "chǎn kin òp-plaa-dùk", english: "I eat baked catfish.", hindi: "मैं बेक किया हुआ कैटफ़िश खाता/खाती हूँ।"),
            WordExample(thai: "อบปลาดุกอร่อย", romanization: "òp-plaa-dùk à-ròi", english: "Baked catfish is delicious.", hindi: "बेक किया हुआ कैटफ़िश स्वादिष्ट है।"),
        ],
        2183: [
            WordExample(thai: "ฉันกินอบปลาทู", romanization: "chǎn kin òp-plaa-thuu", english: "I eat baked mackerel.", hindi: "मैं बेक किया हुआ मैकेरल खाता/खाती हूँ।"),
            WordExample(thai: "อบปลาทูอร่อย", romanization: "òp-plaa-thuu à-ròi", english: "Baked mackerel is delicious.", hindi: "बेक किया हुआ मैकेरल स्वादिष्ट है।"),
        ],
        2184: [
            WordExample(thai: "ฉันกินอบปลาหมึก", romanization: "chǎn kin òp-plaa-mʉ̀k", english: "I eat baked squid.", hindi: "मैं बेक किया हुआ स्क्विड खाता/खाती हूँ।"),
            WordExample(thai: "อบปลาหมึกอร่อย", romanization: "òp-plaa-mʉ̀k à-ròi", english: "Baked squid is delicious.", hindi: "बेक किया हुआ स्क्विड स्वादिष्ट है।"),
        ],
        2185: [
            WordExample(thai: "ฉันกินอบหอยแมลงภู่", romanization: "chǎn kin òp-hɔ̌ɔi-mae-lang-phùu", english: "I eat baked mussels.", hindi: "मैं बेक किया हुआ शंबुक खाता/खाती हूँ।"),
            WordExample(thai: "อบหอยแมลงภู่อร่อย", romanization: "òp-hɔ̌ɔi-mae-lang-phùu à-ròi", english: "Baked mussels is delicious.", hindi: "बेक किया हुआ शंबुक स्वादिष्ट है।"),
        ],
        2186: [
            WordExample(thai: "ฉันกินอบหอยลาย", romanization: "chǎn kin òp-hɔ̌ɔi-laai", english: "I eat baked clams.", hindi: "मैं बेक किया हुआ क्लैम खाता/खाती हूँ।"),
            WordExample(thai: "อบหอยลายอร่อย", romanization: "òp-hɔ̌ɔi-laai à-ròi", english: "Baked clams is delicious.", hindi: "बेक किया हुआ क्लैम स्वादिष्ट है।"),
        ],
        2187: [
            WordExample(thai: "ฉันกินอบเนื้อไก่", romanization: "chǎn kin òp-nʉ́a-gài", english: "I eat baked chicken meat.", hindi: "मैं बेक किया हुआ चिकन मांस खाता/खाती हूँ।"),
            WordExample(thai: "อบเนื้อไก่อร่อย", romanization: "òp-nʉ́a-gài à-ròi", english: "Baked chicken meat is delicious.", hindi: "बेक किया हुआ चिकन मांस स्वादिष्ट है।"),
        ],
        2188: [
            WordExample(thai: "ฉันกินอบเนื้อหมู", romanization: "chǎn kin òp-nʉ́a-mǔu", english: "I eat baked pork.", hindi: "मैं बेक किया हुआ सूअर का मांस खाता/खाती हूँ।"),
            WordExample(thai: "อบเนื้อหมูอร่อย", romanization: "òp-nʉ́a-mǔu à-ròi", english: "Baked pork is delicious.", hindi: "बेक किया हुआ सूअर का मांस स्वादिष्ट है।"),
        ],
        2189: [
            WordExample(thai: "ฉันกินอบเนื้อวัว", romanization: "chǎn kin òp-nʉ́a-wua", english: "I eat baked beef.", hindi: "मैं बेक किया हुआ बीफ खाता/खाती हूँ।"),
            WordExample(thai: "อบเนื้อวัวอร่อย", romanization: "òp-nʉ́a-wua à-ròi", english: "Baked beef is delicious.", hindi: "बेक किया हुआ बीफ स्वादिष्ट है।"),
        ],
        2190: [
            WordExample(thai: "ฉันกินอบกากหมู", romanization: "chǎn kin òp-gàak-mǔu", english: "I eat baked pork cracklings.", hindi: "मैं बेक किया हुआ कुरकुरी सूअर की चर्बी खाता/खाती हूँ।"),
            WordExample(thai: "อบกากหมูอร่อย", romanization: "òp-gàak-mǔu à-ròi", english: "Baked pork cracklings is delicious.", hindi: "बेक किया हुआ कुरकुरी सूअर की चर्बी स्वादिष्ट है।"),
        ],
        2191: [
            WordExample(thai: "ฉันกินอบไข่เยี่ยวม้า", romanization: "chǎn kin òp-khài-yîao-máa", english: "I eat baked century egg.", hindi: "मैं बेक किया हुआ सेंचुरी एग खाता/खाती हूँ।"),
            WordExample(thai: "อบไข่เยี่ยวม้าอร่อย", romanization: "òp-khài-yîao-máa à-ròi", english: "Baked century egg is delicious.", hindi: "बेक किया हुआ सेंचुरी एग स्वादिष्ट है।"),
        ],
        2192: [
            WordExample(thai: "ฉันกินอบปลาสลิด", romanization: "chǎn kin òp-plaa-sà-lìt", english: "I eat baked snakehead gourami.", hindi: "मैं बेक किया हुआ स्नेकहेड गौरामी मछली खाता/खाती हूँ।"),
            WordExample(thai: "อบปลาสลิดอร่อย", romanization: "òp-plaa-sà-lìt à-ròi", english: "Baked snakehead gourami is delicious.", hindi: "बेक किया हुआ स्नेकहेड गौरामी मछली स्वादिष्ट है।"),
        ],
        2193: [
            WordExample(thai: "ฉันกินอบหมูกรอบ", romanization: "chǎn kin òp-mǔu-grɔ̀ɔp", english: "I eat baked crispy pork belly.", hindi: "मैं बेक किया हुआ कुरकुरा पोर्क बेली खाता/खाती हूँ।"),
            WordExample(thai: "อบหมูกรอบอร่อย", romanization: "òp-mǔu-grɔ̀ɔp à-ròi", english: "Baked crispy pork belly is delicious.", hindi: "बेक किया हुआ कुरकुरा पोर्क बेली स्वादिष्ट है।"),
        ],
        2194: [
            WordExample(thai: "ฉันกินอบไก่ฉีก", romanization: "chǎn kin òp-gài-chìik", english: "I eat baked shredded chicken.", hindi: "मैं बेक किया हुआ रेशेदार चिकन खाता/खाती हूँ।"),
            WordExample(thai: "อบไก่ฉีกอร่อย", romanization: "òp-gài-chìik à-ròi", english: "Baked shredded chicken is delicious.", hindi: "बेक किया हुआ रेशेदार चिकन स्वादिष्ट है।"),
        ],
        2195: [
            WordExample(thai: "ฉันกินอบหมูสับ", romanization: "chǎn kin òp-mǔu-sàp", english: "I eat baked minced pork.", hindi: "मैं बेक किया हुआ सूअर का कीमा खाता/खाती हूँ।"),
            WordExample(thai: "อบหมูสับอร่อย", romanization: "òp-mǔu-sàp à-ròi", english: "Baked minced pork is delicious.", hindi: "बेक किया हुआ सूअर का कीमा स्वादिष्ट है।"),
        ],
        2196: [
            WordExample(thai: "ฉันกินอบกุ้งแห้ง", romanization: "chǎn kin òp-gûng-hâeng", english: "I eat baked dried shrimp.", hindi: "मैं बेक किया हुआ सूखी झींगा खाता/खाती हूँ।"),
            WordExample(thai: "อบกุ้งแห้งอร่อย", romanization: "òp-gûng-hâeng à-ròi", english: "Baked dried shrimp is delicious.", hindi: "बेक किया हुआ सूखी झींगा स्वादिष्ट है।"),
        ],
        2197: [
            WordExample(thai: "ฉันกินลวกมะระ", romanization: "chǎn kin lûak-má-rá", english: "I eat blanched bitter gourd.", hindi: "मैं हल्का उबला करेला खाता/खाती हूँ।"),
            WordExample(thai: "ลวกมะระอร่อย", romanization: "lûak-má-rá à-ròi", english: "Blanched bitter gourd is delicious.", hindi: "हल्का उबला करेला स्वादिष्ट है।"),
        ],
        2198: [
            WordExample(thai: "ฉันกินลวกกะหล่ำดอก", romanization: "chǎn kin lûak-gà-làm-dàawk", english: "I eat blanched cauliflower.", hindi: "मैं हल्का उबला फूलगोभी खाता/खाती हूँ।"),
            WordExample(thai: "ลวกกะหล่ำดอกอร่อย", romanization: "lûak-gà-làm-dàawk à-ròi", english: "Blanched cauliflower is delicious.", hindi: "हल्का उबला फूलगोभी स्वादिष्ट है।"),
        ],
        2199: [
            WordExample(thai: "ฉันกินลวกบรอกโคลี", romanization: "chǎn kin lûak-brɔ̀ɔk-khoo-lii", english: "I eat blanched broccoli.", hindi: "मैं हल्का उबला ब्रोकली खाता/खाती हूँ।"),
            WordExample(thai: "ลวกบรอกโคลีอร่อย", romanization: "lûak-brɔ̀ɔk-khoo-lii à-ròi", english: "Blanched broccoli is delicious.", hindi: "हल्का उबला ब्रोकली स्वादिष्ट है।"),
        ],
        2200: [
            WordExample(thai: "ฉันกินลวกผักโขม", romanization: "chǎn kin lûak-phàk-khǒom", english: "I eat blanched spinach.", hindi: "मैं हल्का उबला पालक खाता/खाती हूँ।"),
            WordExample(thai: "ลวกผักโขมอร่อย", romanization: "lûak-phàk-khǒom à-ròi", english: "Blanched spinach is delicious.", hindi: "हल्का उबला पालक स्वादिष्ट है।"),
        ],
        2201: [
            WordExample(thai: "ฉันกินลวกผักกวางตุ้ง", romanization: "chǎn kin lûak-phàk-gwaang-tûng", english: "I eat blanched bok choy.", hindi: "मैं हल्का उबला बॉक चॉय खाता/खाती हूँ।"),
            WordExample(thai: "ลวกผักกวางตุ้งอร่อย", romanization: "lûak-phàk-gwaang-tûng à-ròi", english: "Blanched bok choy is delicious.", hindi: "हल्का उबला बॉक चॉय स्वादिष्ट है।"),
        ],
        2202: [
            WordExample(thai: "ฉันกินลวกเห็ดหอม", romanization: "chǎn kin lûak-hèt-hǎawm", english: "I eat blanched shiitake mushroom.", hindi: "मैं हल्का उबला शीताके मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ลวกเห็ดหอมอร่อย", romanization: "lûak-hèt-hǎawm à-ròi", english: "Blanched shiitake mushroom is delicious.", hindi: "हल्का उबला शीताके मशरूम स्वादिष्ट है।"),
        ],
        2203: [
            WordExample(thai: "ฉันกินลวกเห็ดนางรม", romanization: "chǎn kin lûak-hèt-naang-rom", english: "I eat blanched oyster mushroom.", hindi: "मैं हल्का उबला ऑयस्टर मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ลวกเห็ดนางรมอร่อย", romanization: "lûak-hèt-naang-rom à-ròi", english: "Blanched oyster mushroom is delicious.", hindi: "हल्का उबला ऑयस्टर मशरूम स्वादिष्ट है।"),
        ],
        2204: [
            WordExample(thai: "ฉันกินลวกเห็ดเข็มทอง", romanization: "chǎn kin lûak-hèt-khém-thaawng", english: "I eat blanched enoki mushroom.", hindi: "मैं हल्का उबला एनोकी मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ลวกเห็ดเข็มทองอร่อย", romanization: "lûak-hèt-khém-thaawng à-ròi", english: "Blanched enoki mushroom is delicious.", hindi: "हल्का उबला एनोकी मशरूम स्वादिष्ट है।"),
        ],
        2205: [
            WordExample(thai: "ฉันกินลวกเต้าหู้", romanization: "chǎn kin lûak-tâo-hûu", english: "I eat blanched tofu.", hindi: "मैं हल्का उबला टोफू खाता/खाती हूँ।"),
            WordExample(thai: "ลวกเต้าหู้อร่อย", romanization: "lûak-tâo-hûu à-ròi", english: "Blanched tofu is delicious.", hindi: "हल्का उबला टोफू स्वादिष्ट है।"),
        ],
        2206: [
            WordExample(thai: "ฉันกินลวกหมูยอ", romanization: "chǎn kin lûak-mǔu-yaw", english: "I eat blanched Vietnamese pork sausage.", hindi: "मैं हल्का उबला वियतनामी पोर्क सॉसेज खाता/खाती हूँ।"),
            WordExample(thai: "ลวกหมูยออร่อย", romanization: "lûak-mǔu-yaw à-ròi", english: "Blanched vietnamese pork sausage is delicious.", hindi: "हल्का उबला वियतनामी पोर्क सॉसेज स्वादिष्ट है।"),
        ],
        2207: [
            WordExample(thai: "ฉันกินลวกปลาดุก", romanization: "chǎn kin lûak-plaa-dùk", english: "I eat blanched catfish.", hindi: "मैं हल्का उबला कैटफ़िश खाता/खाती हूँ।"),
            WordExample(thai: "ลวกปลาดุกอร่อย", romanization: "lûak-plaa-dùk à-ròi", english: "Blanched catfish is delicious.", hindi: "हल्का उबला कैटफ़िश स्वादिष्ट है।"),
        ],
        2208: [
            WordExample(thai: "ฉันกินลวกปลาทู", romanization: "chǎn kin lûak-plaa-thuu", english: "I eat blanched mackerel.", hindi: "मैं हल्का उबला मैकेरल खाता/खाती हूँ।"),
            WordExample(thai: "ลวกปลาทูอร่อย", romanization: "lûak-plaa-thuu à-ròi", english: "Blanched mackerel is delicious.", hindi: "हल्का उबला मैकेरल स्वादिष्ट है।"),
        ],
        2209: [
            WordExample(thai: "ฉันกินลวกปลาหมึก", romanization: "chǎn kin lûak-plaa-mʉ̀k", english: "I eat blanched squid.", hindi: "मैं हल्का उबला स्क्विड खाता/खाती हूँ।"),
            WordExample(thai: "ลวกปลาหมึกอร่อย", romanization: "lûak-plaa-mʉ̀k à-ròi", english: "Blanched squid is delicious.", hindi: "हल्का उबला स्क्विड स्वादिष्ट है।"),
        ],
        2210: [
            WordExample(thai: "ฉันกินลวกหอยแมลงภู่", romanization: "chǎn kin lûak-hɔ̌ɔi-mae-lang-phùu", english: "I eat blanched mussels.", hindi: "मैं हल्का उबला शंबुक खाता/खाती हूँ।"),
            WordExample(thai: "ลวกหอยแมลงภู่อร่อย", romanization: "lûak-hɔ̌ɔi-mae-lang-phùu à-ròi", english: "Blanched mussels is delicious.", hindi: "हल्का उबला शंबुक स्वादिष्ट है।"),
        ],
        2211: [
            WordExample(thai: "ฉันกินลวกหอยลาย", romanization: "chǎn kin lûak-hɔ̌ɔi-laai", english: "I eat blanched clams.", hindi: "मैं हल्का उबला क्लैम खाता/खाती हूँ।"),
            WordExample(thai: "ลวกหอยลายอร่อย", romanization: "lûak-hɔ̌ɔi-laai à-ròi", english: "Blanched clams is delicious.", hindi: "हल्का उबला क्लैम स्वादिष्ट है।"),
        ],
        2212: [
            WordExample(thai: "ฉันกินลวกเนื้อไก่", romanization: "chǎn kin lûak-nʉ́a-gài", english: "I eat blanched chicken meat.", hindi: "मैं हल्का उबला चिकन मांस खाता/खाती हूँ।"),
            WordExample(thai: "ลวกเนื้อไก่อร่อย", romanization: "lûak-nʉ́a-gài à-ròi", english: "Blanched chicken meat is delicious.", hindi: "हल्का उबला चिकन मांस स्वादिष्ट है।"),
        ],
        2213: [
            WordExample(thai: "ฉันกินลวกเนื้อหมู", romanization: "chǎn kin lûak-nʉ́a-mǔu", english: "I eat blanched pork.", hindi: "मैं हल्का उबला सूअर का मांस खाता/खाती हूँ।"),
            WordExample(thai: "ลวกเนื้อหมูอร่อย", romanization: "lûak-nʉ́a-mǔu à-ròi", english: "Blanched pork is delicious.", hindi: "हल्का उबला सूअर का मांस स्वादिष्ट है।"),
        ],
        2214: [
            WordExample(thai: "ฉันกินลวกเนื้อวัว", romanization: "chǎn kin lûak-nʉ́a-wua", english: "I eat blanched beef.", hindi: "मैं हल्का उबला बीफ खाता/खाती हूँ।"),
            WordExample(thai: "ลวกเนื้อวัวอร่อย", romanization: "lûak-nʉ́a-wua à-ròi", english: "Blanched beef is delicious.", hindi: "हल्का उबला बीफ स्वादिष्ट है।"),
        ],
        2215: [
            WordExample(thai: "ฉันกินลวกกากหมู", romanization: "chǎn kin lûak-gàak-mǔu", english: "I eat blanched pork cracklings.", hindi: "मैं हल्का उबला कुरकुरी सूअर की चर्बी खाता/खाती हूँ।"),
            WordExample(thai: "ลวกกากหมูอร่อย", romanization: "lûak-gàak-mǔu à-ròi", english: "Blanched pork cracklings is delicious.", hindi: "हल्का उबला कुरकुरी सूअर की चर्बी स्वादिष्ट है।"),
        ],
        2216: [
            WordExample(thai: "ฉันกินลวกไข่เยี่ยวม้า", romanization: "chǎn kin lûak-khài-yîao-máa", english: "I eat blanched century egg.", hindi: "मैं हल्का उबला सेंचुरी एग खाता/खाती हूँ।"),
            WordExample(thai: "ลวกไข่เยี่ยวม้าอร่อย", romanization: "lûak-khài-yîao-máa à-ròi", english: "Blanched century egg is delicious.", hindi: "हल्का उबला सेंचुरी एग स्वादिष्ट है।"),
        ],
        2217: [
            WordExample(thai: "ฉันกินลวกปลาสลิด", romanization: "chǎn kin lûak-plaa-sà-lìt", english: "I eat blanched snakehead gourami.", hindi: "मैं हल्का उबला स्नेकहेड गौरामी मछली खाता/खाती हूँ।"),
            WordExample(thai: "ลวกปลาสลิดอร่อย", romanization: "lûak-plaa-sà-lìt à-ròi", english: "Blanched snakehead gourami is delicious.", hindi: "हल्का उबला स्नेकहेड गौरामी मछली स्वादिष्ट है।"),
        ],
        2218: [
            WordExample(thai: "ฉันกินลวกหมูกรอบ", romanization: "chǎn kin lûak-mǔu-grɔ̀ɔp", english: "I eat blanched crispy pork belly.", hindi: "मैं हल्का उबला कुरकुरा पोर्क बेली खाता/खाती हूँ।"),
            WordExample(thai: "ลวกหมูกรอบอร่อย", romanization: "lûak-mǔu-grɔ̀ɔp à-ròi", english: "Blanched crispy pork belly is delicious.", hindi: "हल्का उबला कुरकुरा पोर्क बेली स्वादिष्ट है।"),
        ],
        2219: [
            WordExample(thai: "ฉันกินลวกไก่ฉีก", romanization: "chǎn kin lûak-gài-chìik", english: "I eat blanched shredded chicken.", hindi: "मैं हल्का उबला रेशेदार चिकन खाता/खाती हूँ।"),
            WordExample(thai: "ลวกไก่ฉีกอร่อย", romanization: "lûak-gài-chìik à-ròi", english: "Blanched shredded chicken is delicious.", hindi: "हल्का उबला रेशेदार चिकन स्वादिष्ट है।"),
        ],
        2220: [
            WordExample(thai: "ฉันกินลวกหมูสับ", romanization: "chǎn kin lûak-mǔu-sàp", english: "I eat blanched minced pork.", hindi: "मैं हल्का उबला सूअर का कीमा खाता/खाती हूँ।"),
            WordExample(thai: "ลวกหมูสับอร่อย", romanization: "lûak-mǔu-sàp à-ròi", english: "Blanched minced pork is delicious.", hindi: "हल्का उबला सूअर का कीमा स्वादिष्ट है।"),
        ],
        2221: [
            WordExample(thai: "ฉันกินลวกกุ้งแห้ง", romanization: "chǎn kin lûak-gûng-hâeng", english: "I eat blanched dried shrimp.", hindi: "मैं हल्का उबला सूखी झींगा खाता/खाती हूँ।"),
            WordExample(thai: "ลวกกุ้งแห้งอร่อย", romanization: "lûak-gûng-hâeng à-ròi", english: "Blanched dried shrimp is delicious.", hindi: "हल्का उबला सूखी झींगा स्वादिष्ट है।"),
        ],
        2222: [
            WordExample(thai: "ฉันกินยำมะระ", romanization: "chǎn kin yam-má-rá", english: "I eat spicy salad with bitter gourd.", hindi: "मैं मसालेदार सलाद में करेला खाता/खाती हूँ।"),
            WordExample(thai: "ยำมะระอร่อย", romanization: "yam-má-rá à-ròi", english: "Spicy salad with bitter gourd is delicious.", hindi: "मसालेदार सलाद में करेला स्वादिष्ट है।"),
        ],
        2223: [
            WordExample(thai: "ฉันกินยำกะหล่ำดอก", romanization: "chǎn kin yam-gà-làm-dàawk", english: "I eat spicy salad with cauliflower.", hindi: "मैं मसालेदार सलाद में फूलगोभी खाता/खाती हूँ।"),
            WordExample(thai: "ยำกะหล่ำดอกอร่อย", romanization: "yam-gà-làm-dàawk à-ròi", english: "Spicy salad with cauliflower is delicious.", hindi: "मसालेदार सलाद में फूलगोभी स्वादिष्ट है।"),
        ],
        2224: [
            WordExample(thai: "ฉันกินยำบรอกโคลี", romanization: "chǎn kin yam-brɔ̀ɔk-khoo-lii", english: "I eat spicy salad with broccoli.", hindi: "मैं मसालेदार सलाद में ब्रोकली खाता/खाती हूँ।"),
            WordExample(thai: "ยำบรอกโคลีอร่อย", romanization: "yam-brɔ̀ɔk-khoo-lii à-ròi", english: "Spicy salad with broccoli is delicious.", hindi: "मसालेदार सलाद में ब्रोकली स्वादिष्ट है।"),
        ],
        2225: [
            WordExample(thai: "ฉันกินยำผักโขม", romanization: "chǎn kin yam-phàk-khǒom", english: "I eat spicy salad with spinach.", hindi: "मैं मसालेदार सलाद में पालक खाता/खाती हूँ।"),
            WordExample(thai: "ยำผักโขมอร่อย", romanization: "yam-phàk-khǒom à-ròi", english: "Spicy salad with spinach is delicious.", hindi: "मसालेदार सलाद में पालक स्वादिष्ट है।"),
        ],
        2226: [
            WordExample(thai: "ฉันกินยำผักกวางตุ้ง", romanization: "chǎn kin yam-phàk-gwaang-tûng", english: "I eat spicy salad with bok choy.", hindi: "मैं मसालेदार सलाद में बॉक चॉय खाता/खाती हूँ।"),
            WordExample(thai: "ยำผักกวางตุ้งอร่อย", romanization: "yam-phàk-gwaang-tûng à-ròi", english: "Spicy salad with bok choy is delicious.", hindi: "मसालेदार सलाद में बॉक चॉय स्वादिष्ट है।"),
        ],
        2227: [
            WordExample(thai: "ฉันกินยำเห็ดหอม", romanization: "chǎn kin yam-hèt-hǎawm", english: "I eat spicy salad with shiitake mushroom.", hindi: "मैं मसालेदार सलाद में शीताके मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ยำเห็ดหอมอร่อย", romanization: "yam-hèt-hǎawm à-ròi", english: "Spicy salad with shiitake mushroom is delicious.", hindi: "मसालेदार सलाद में शीताके मशरूम स्वादिष्ट है।"),
        ],
        2228: [
            WordExample(thai: "ฉันกินยำเห็ดนางรม", romanization: "chǎn kin yam-hèt-naang-rom", english: "I eat spicy salad with oyster mushroom.", hindi: "मैं मसालेदार सलाद में ऑयस्टर मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ยำเห็ดนางรมอร่อย", romanization: "yam-hèt-naang-rom à-ròi", english: "Spicy salad with oyster mushroom is delicious.", hindi: "मसालेदार सलाद में ऑयस्टर मशरूम स्वादिष्ट है।"),
        ],
        2229: [
            WordExample(thai: "ฉันกินยำเห็ดเข็มทอง", romanization: "chǎn kin yam-hèt-khém-thaawng", english: "I eat spicy salad with enoki mushroom.", hindi: "मैं मसालेदार सलाद में एनोकी मशरूम खाता/खाती हूँ।"),
            WordExample(thai: "ยำเห็ดเข็มทองอร่อย", romanization: "yam-hèt-khém-thaawng à-ròi", english: "Spicy salad with enoki mushroom is delicious.", hindi: "मसालेदार सलाद में एनोकी मशरूम स्वादिष्ट है।"),
        ],
        2230: [
            WordExample(thai: "ฉันกินยำเต้าหู้", romanization: "chǎn kin yam-tâo-hûu", english: "I eat spicy salad with tofu.", hindi: "मैं मसालेदार सलाद में टोफू खाता/खाती हूँ।"),
            WordExample(thai: "ยำเต้าหู้อร่อย", romanization: "yam-tâo-hûu à-ròi", english: "Spicy salad with tofu is delicious.", hindi: "मसालेदार सलाद में टोफू स्वादिष्ट है।"),
        ],
        2231: [
            WordExample(thai: "ฉันกินยำหมูยอ", romanization: "chǎn kin yam-mǔu-yaw", english: "I eat spicy salad with Vietnamese pork sausage.", hindi: "मैं मसालेदार सलाद में वियतनामी पोर्क सॉसेज खाता/खाती हूँ।"),
            WordExample(thai: "ยำหมูยออร่อย", romanization: "yam-mǔu-yaw à-ròi", english: "Spicy salad with vietnamese pork sausage is delicious.", hindi: "मसालेदार सलाद में वियतनामी पोर्क सॉसेज स्वादिष्ट है।"),
        ],
        2232: [
            WordExample(thai: "ฉันกินยำปลาดุก", romanization: "chǎn kin yam-plaa-dùk", english: "I eat spicy salad with catfish.", hindi: "मैं मसालेदार सलाद में कैटफ़िश खाता/खाती हूँ।"),
            WordExample(thai: "ยำปลาดุกอร่อย", romanization: "yam-plaa-dùk à-ròi", english: "Spicy salad with catfish is delicious.", hindi: "मसालेदार सलाद में कैटफ़िश स्वादिष्ट है।"),
        ],
        2233: [
            WordExample(thai: "ฉันกินยำปลาทู", romanization: "chǎn kin yam-plaa-thuu", english: "I eat spicy salad with mackerel.", hindi: "मैं मसालेदार सलाद में मैकेरल खाता/खाती हूँ।"),
            WordExample(thai: "ยำปลาทูอร่อย", romanization: "yam-plaa-thuu à-ròi", english: "Spicy salad with mackerel is delicious.", hindi: "मसालेदार सलाद में मैकेरल स्वादिष्ट है।"),
        ],
        2234: [
            WordExample(thai: "ฉันกินยำปลาหมึก", romanization: "chǎn kin yam-plaa-mʉ̀k", english: "I eat spicy salad with squid.", hindi: "मैं मसालेदार सलाद में स्क्विड खाता/खाती हूँ।"),
            WordExample(thai: "ยำปลาหมึกอร่อย", romanization: "yam-plaa-mʉ̀k à-ròi", english: "Spicy salad with squid is delicious.", hindi: "मसालेदार सलाद में स्क्विड स्वादिष्ट है।"),
        ],
        2235: [
            WordExample(thai: "ฉันกินยำหอยแมลงภู่", romanization: "chǎn kin yam-hɔ̌ɔi-mae-lang-phùu", english: "I eat spicy salad with mussels.", hindi: "मैं मसालेदार सलाद में शंबुक खाता/खाती हूँ।"),
            WordExample(thai: "ยำหอยแมลงภู่อร่อย", romanization: "yam-hɔ̌ɔi-mae-lang-phùu à-ròi", english: "Spicy salad with mussels is delicious.", hindi: "मसालेदार सलाद में शंबुक स्वादिष्ट है।"),
        ],
        2236: [
            WordExample(thai: "ฉันกินยำหอยลาย", romanization: "chǎn kin yam-hɔ̌ɔi-laai", english: "I eat spicy salad with clams.", hindi: "मैं मसालेदार सलाद में क्लैम खाता/खाती हूँ।"),
            WordExample(thai: "ยำหอยลายอร่อย", romanization: "yam-hɔ̌ɔi-laai à-ròi", english: "Spicy salad with clams is delicious.", hindi: "मसालेदार सलाद में क्लैम स्वादिष्ट है।"),
        ],
        2237: [
            WordExample(thai: "ฉันกินยำเนื้อไก่", romanization: "chǎn kin yam-nʉ́a-gài", english: "I eat spicy salad with chicken meat.", hindi: "मैं मसालेदार सलाद में चिकन मांस खाता/खाती हूँ।"),
            WordExample(thai: "ยำเนื้อไก่อร่อย", romanization: "yam-nʉ́a-gài à-ròi", english: "Spicy salad with chicken meat is delicious.", hindi: "मसालेदार सलाद में चिकन मांस स्वादिष्ट है।"),
        ],
        2238: [
            WordExample(thai: "ฉันกินยำเนื้อหมู", romanization: "chǎn kin yam-nʉ́a-mǔu", english: "I eat spicy salad with pork.", hindi: "मैं मसालेदार सलाद में सूअर का मांस खाता/खाती हूँ।"),
            WordExample(thai: "ยำเนื้อหมูอร่อย", romanization: "yam-nʉ́a-mǔu à-ròi", english: "Spicy salad with pork is delicious.", hindi: "मसालेदार सलाद में सूअर का मांस स्वादिष्ट है।"),
        ],
        2239: [
            WordExample(thai: "ฉันกินยำเนื้อวัว", romanization: "chǎn kin yam-nʉ́a-wua", english: "I eat spicy salad with beef.", hindi: "मैं मसालेदार सलाद में बीफ खाता/खाती हूँ।"),
            WordExample(thai: "ยำเนื้อวัวอร่อย", romanization: "yam-nʉ́a-wua à-ròi", english: "Spicy salad with beef is delicious.", hindi: "मसालेदार सलाद में बीफ स्वादिष्ट है।"),
        ],
        2240: [
            WordExample(thai: "ฉันกินยำกากหมู", romanization: "chǎn kin yam-gàak-mǔu", english: "I eat spicy salad with pork cracklings.", hindi: "मैं मसालेदार सलाद में कुरकुरी सूअर की चर्बी खाता/खाती हूँ।"),
            WordExample(thai: "ยำกากหมูอร่อย", romanization: "yam-gàak-mǔu à-ròi", english: "Spicy salad with pork cracklings is delicious.", hindi: "मसालेदार सलाद में कुरकुरी सूअर की चर्बी स्वादिष्ट है।"),
        ],
        2241: [
            WordExample(thai: "ฉันกินยำไข่เยี่ยวม้า", romanization: "chǎn kin yam-khài-yîao-máa", english: "I eat spicy salad with century egg.", hindi: "मैं मसालेदार सलाद में सेंचुरी एग खाता/खाती हूँ।"),
            WordExample(thai: "ยำไข่เยี่ยวม้าอร่อย", romanization: "yam-khài-yîao-máa à-ròi", english: "Spicy salad with century egg is delicious.", hindi: "मसालेदार सलाद में सेंचुरी एग स्वादिष्ट है।"),
        ],
        2242: [
            WordExample(thai: "ฉันกินยำปลาสลิด", romanization: "chǎn kin yam-plaa-sà-lìt", english: "I eat spicy salad with snakehead gourami.", hindi: "मैं मसालेदार सलाद में स्नेकहेड गौरामी मछली खाता/खाती हूँ।"),
            WordExample(thai: "ยำปลาสลิดอร่อย", romanization: "yam-plaa-sà-lìt à-ròi", english: "Spicy salad with snakehead gourami is delicious.", hindi: "मसालेदार सलाद में स्नेकहेड गौरामी मछली स्वादिष्ट है।"),
        ],
        2243: [
            WordExample(thai: "ฉันกินยำหมูกรอบ", romanization: "chǎn kin yam-mǔu-grɔ̀ɔp", english: "I eat spicy salad with crispy pork belly.", hindi: "मैं मसालेदार सलाद में कुरकुरा पोर्क बेली खाता/खाती हूँ।"),
            WordExample(thai: "ยำหมูกรอบอร่อย", romanization: "yam-mǔu-grɔ̀ɔp à-ròi", english: "Spicy salad with crispy pork belly is delicious.", hindi: "मसालेदार सलाद में कुरकुरा पोर्क बेली स्वादिष्ट है।"),
        ],
        2244: [
            WordExample(thai: "ฉันกินยำไก่ฉีก", romanization: "chǎn kin yam-gài-chìik", english: "I eat spicy salad with shredded chicken.", hindi: "मैं मसालेदार सलाद में रेशेदार चिकन खाता/खाती हूँ।"),
            WordExample(thai: "ยำไก่ฉีกอร่อย", romanization: "yam-gài-chìik à-ròi", english: "Spicy salad with shredded chicken is delicious.", hindi: "मसालेदार सलाद में रेशेदार चिकन स्वादिष्ट है।"),
        ],
        2245: [
            WordExample(thai: "ฉันกินยำหมูสับ", romanization: "chǎn kin yam-mǔu-sàp", english: "I eat spicy salad with minced pork.", hindi: "मैं मसालेदार सलाद में सूअर का कीमा खाता/खाती हूँ।"),
            WordExample(thai: "ยำหมูสับอร่อย", romanization: "yam-mǔu-sàp à-ròi", english: "Spicy salad with minced pork is delicious.", hindi: "मसालेदार सलाद में सूअर का कीमा स्वादिष्ट है।"),
        ],
        2246: [
            WordExample(thai: "ฉันกินยำกุ้งแห้ง", romanization: "chǎn kin yam-gûng-hâeng", english: "I eat spicy salad with dried shrimp.", hindi: "मैं मसालेदार सलाद में सूखी झींगा खाता/खाती हूँ।"),
            WordExample(thai: "ยำกุ้งแห้งอร่อย", romanization: "yam-gûng-hâeng à-ròi", english: "Spicy salad with dried shrimp is delicious.", hindi: "मसालेदार सलाद में सूखी झींगा स्वादिष्ट है।"),
        ],
    ]

    // CHUNKS: sentence batches are appended as examples1, examples2, … by
    // tools/integrate_batch.py, which also maintains this merge list.
    private static let exampleChunks: [[Int: [WordExample]]] = [examples0, examples1, examples3, examples4]
    private static let examples: [Int: [WordExample]] = exampleChunks.reduce(into: [:]) { $0.merge($1) { a, _ in a } }

    // How the word combines with (or is built from) other words.
    private static let compounds: [Int: String] = [
        449: "เชียง (chiang) city (old northern word) / नगर + ใหม่ (mài) new / नया → เชียงใหม่ new city / नया शहर",
        450: "กรุง (krung) capital / राजधानी + เทพ (thêep) god / देवता → กรุงเทพ city of gods / देवताओं का शहर",
        223: "พวก (phûak) group / समूह + เรา (rao) we / हम → พวกเรา all of us / हम सब",
        226: "ของ (khǒong) of / का + ฉัน (chǎn) I / मैं → ของฉัน mine / मेरा",
        235: "ทุก (thúk) every / हर + วัน (wan) day / दिन → ทุกวัน every day / हर दिन",
        236: "บาง (baang) some / कुछ + คน (khon) person / व्यक्ति → บางคน some people / कुछ लोग",
        240: "ที่ (thîi) at / पर + นี่ (nîi) this / यह → ที่นี่ here / यहाँ",
        246: "ด้วย (dûai) also / भी + กัน (kan) each other / आपस में → ด้วยกัน together / साथ में",
        247: "ขอบคุณ (khòop-khun) thank you / धन्यवाद + นะ (ná) → ขอบคุณนะ friendly thanks / प्यार से धन्यवाद",
        249: "เครื่อง (khrûeang) thing / चीज़ + ดื่ม (dùem) drink / पीना → เครื่องดื่ม = beverage / पेय",
        250: "ใช้ (chái) use / इस्तेमाल + เงิน (ngern) money / पैसा → ใช้เงิน = to spend money / पैसे खर्च करना",
        252: "เห็น (hěn) see / दिखना + ด้วย (dûai) also / भी → เห็นด้วย = to agree / सहमत होना",
        254: "คำ (kham) word / शब्द + ถาม (thǎam) ask / पूछना → คำถาม = question / सवाल",
        255: "คำ (kham) word / शब्द + ตอบ (tòop) answer / जवाब देना → คำตอบ = answer (noun) / जवाब",
        256: "เล่น (lên) play / खेलना + น้ำ (náam) water / पानी → เล่นน้ำ = to play in the water / पानी में खेलना",
        257: "โรง (roong) building / भवन + เรียน (rian) study / पढ़ना → โรงเรียน = school / स्कूल",
        259: "จ่าย (jàai) pay / देना + เงิน (ngern) money / पैसा → จ่ายเงิน = to pay money / भुगतान करना",
        264: "ไป (pai) go / जाना + ส่ง (sòng) send / भेजना → ไปส่ง = to drop (someone) off / छोड़ने जाना",
        265: "ไป (pai) go / जाना + รับ (ráp) receive / लेना → ไปรับ = to go pick (someone) up / लेने जाना",
        266: "เปลี่ยน (plìan) change / बदलना + เสื้อ (sûea) shirt / शर्ट → เปลี่ยนเสื้อ = to change clothes / कपड़े बदलना",
        268: "ใส่ (sài) wear / पहनना + รองเท้า (roong-tháao) shoes / जूते → ใส่รองเท้า = to wear shoes / जूते पहनना",
        269: "นั่ง (nâng) sit / बैठना + รถ (rót) vehicle / गाड़ी → นั่งรถ = to ride (a vehicle) / गाड़ी से जाना",
        270: "ขอบคุณ (khòp-khun) thank you / धन्यवाद + มาก (mâak) → thank you very much / बहुत धन्यवाद",
        271: "น้อย (nói) little / कम + หน่อย (nòi) a bit / थोड़ा → น้อยหน่อย a little less / थोड़ा कम",
        273: "ง่วง (ngûang) drowsy / उनींदा + นอน (noon) to sleep / सोना → ง่วงนอน sleepy / नींद आना",
        276: "อิ่ม (ìm) full / पेट भरा + แล้ว (láew) already / हो गया → อิ่มแล้ว I'm full / पेट भर गया",
        277: "เวลา (wee-laa) time / समय + ว่าง (wâang) free / खाली → เวลาว่าง free time / खाली समय",
        279: "อ้วน (ûan) fat / मोटा ↔ ผอม (phǒom) thin / दुबला — opposite pair used for people and animals / लोगों और जानवरों के लिए",
        280: "ผม (phǒm) means both I (male) / मैं (पुरुष) and hair / बाल — ผมสั้น = short hair / छोटे बाल",
        281: "สั้น (sân) short / छोटा ↔ ยาว (yaao) long / लंबा — for length; for height use สูง (sǔung) / ऊँचाई के लिए สูง",
        283: "กว้าง (kwâang) wide / चौड़ा ↔ แคบ (khâep) narrow / संकरा",
        285: "หนัก (nàk) heavy / भारी ↔ เบา (bao) light / हल्का",
        286: "เสียง (sǐang) sound / आवाज़ + ดัง (dang) → เสียงดัง loud, noisy / तेज़ आवाज़, शोर",
        287: "ดัง (dang) loud / तेज़ ↔ เงียบ (ngîap) quiet / शांत",
        288: "พูด (phûut) speak / बोलना + เก่ง (kèng) → พูดเก่ง speaks well / अच्छा बोलता है — verb + เก่ง = good at that action / क्रिया + เก่ง = उसमें माहिर",
        289: "หอม (hǒom) fragrant / खुशबूदार + มะลิ (má-lí) jasmine / चमेली → ข้าวหอมมะลิ jasmine rice / जैस्मिन चावल",
        290: "สบาย (sà-baai) comfortable / आराम + ดี (dii) good / अच्छा → สบายดี I'm fine / मैं ठीक हूँ",
        292: "ถูก (thùuk) alone also means cheap / सस्ता — adding ต้อง (tông) makes ถูกต้อง clearly mean correct / सही",
        293: "เข้าใจ (khâo-jai) understand / समझना + ผิด (phìt) → เข้าใจผิด misunderstand / गलत समझना",
        295: "วัน (wan) day / दिन + จันทร์ (jan) moon, from Sanskrit चंद्र → Monday / सोमवार — same moon-day idea as Hindi!",
        296: "วัน (wan) day / दिन + อังคาร (ang-khaan) Mars, from Sanskrit अंगारक (मंगल ग्रह) → Tuesday / मंगलवार — same planet as Hindi!",
        297: "วัน (wan) day / दिन + พุธ (phút) Mercury, from Sanskrit बुध → Wednesday / बुधवार — exactly like Hindi!",
        298: "From Sanskrit बृहस्पति (Jupiter / गुरु ग्रह) → Thursday / गुरुवार. In speech Thais shorten it to วันพฤหัส (wan-phá-rúe-hàt).",
        299: "วัน (wan) day / दिन + ศุกร์ (sùk) Venus, from Sanskrit शुक्र → Friday / शुक्रवार — same as Hindi!",
        300: "วัน (wan) day / दिन + เสาร์ (sǎo) Saturn / शनि ग्रह → Saturday / शनिवार — same Saturn-day idea as Hindi!",
        301: "วัน (wan) day / दिन + อาทิตย์ (aa-thít) sun, from Sanskrit आदित्य (सूर्य) → Sunday / रविवार. อาทิตย์ alone also means \"week\" in everyday speech.",
        302: "ตอน (toon) period-time / समय + นี้ (níi) this / यह → now / अभी",
        303: "Goes at the end of the sentence / वाक्य के अंत में आता है: กินบ่อย (kin bòi) = eat often / अक्सर खाना",
        304: "บาง (baang) some / कुछ + ครั้ง (khráng) time-occasion / बार → sometimes / कभी-कभी. Spoken Thai also uses บางที (baang-thii).",
        305: "Goes at the end of the sentence / वाक्य के अंत में आता है — unlike English \"always\" / अंग्रेज़ी से अलग क्रम",
        306: "ไม่ (mâi) not / नहीं + เคย (kheuy) ever / कभी → never / कभी नहीं",
        307: "เร็ว (reo) fast / तेज़ + ๆ (repeat) + นี้ (níi) this / यह → soon / जल्दी ही",
        308: "ก่อน (kòon) before / पहले + นอน (noon) sleep / सोना → ก่อนนอน = before bed / सोने से पहले",
        309: "หลัง also means \"back (of the body)\" / पीठ. หลังจากนั้น (lǎng-jàak-nán) = after that / उसके बाद",
        310: "สาย = late in the morning or for appointments / सुबह या मीटिंग के लिए देर; late at night is ดึก (dùek) / रात की देरी के लिए ดึก",
        311: "ข้าว (khâao) rice / चावल + เที่ยง (thîang) noon / दोपहर → ข้าวเที่ยง = lunch / दोपहर का खाना",
        312: "เสาร์ (sǎo) Saturday / शनिवार + อาทิตย์ (aa-thít) Sunday / रविवार → weekend / वीकेंड. Formal word: วันหยุดสุดสัปดาห์.",
        313: "อาทิตย์ (aa-thít) week / हफ़्ता + หน้า (nâa) next-front / अगला → next week / अगले हफ़्ते",
        314: "อาทิตย์ (aa-thít) week / हफ़्ता + ที่แล้ว (thîi-láew) last-past / पिछला → last week / पिछले हफ़्ते",
        315: "บ่าย = roughly 1 pm to 4 pm / लगभग 1 से 4 बजे. บ่ายสอง (bàai sǒong) = 2 pm / दोपहर 2 बजे",
        316: "ทุก (thúk) every / हर + วัน (wan) day / दिन → every day / हर दिन",
        317: "คืน (kheun) night / रात + นี้ (níi) this / यह → tonight / आज रात. เมื่อคืน (mûea-kheun) = last night / कल रात",
        318: "วัน (wan) day / दिन + หยุด (yùt) stop / रुकना → holiday, day off / छुट्टी",
        319: "นานแค่ไหน (naan khâe-nǎi) = how long? / कितनी देर?",
        320: "กี่ + classifier: กี่คน (kìi khon) how many people / कितने लोग; กี่บาท (kìi bàat) how many baht / कितने बाथ",
        321: "หมา 2 ตัว (mǎa sǒong tua) = two dogs / दो कुत्ते; เสื้อ 1 ตัว (sûea nùeng tua) = one shirt / एक शर्ट",
        322: "เพื่อน 3 คน (phûean sǎam khon) = three friends / तीन दोस्त",
        323: "อันนี้ (an níi) = this one / यह वाला; อันไหน (an nǎi) = which one / कौन-सा",
        324: "ตั๋ว 2 ใบ (tǔa sǒong bai) = two tickets / दो टिकट; กระเป๋า 1 ใบ (kra-pǎo nùeng bai) = one bag / एक बैग",
        325: "น้ำ 1 แก้ว (náam nùeng kâew) = one glass of water / एक गिलास पानी",
        326: "น้ำ 2 ขวด (náam sǒong khùat) = two bottles of water / दो बोतल पानी; ขวดน้ำ (khùat náam) = water bottle / पानी की बोतल",
        327: "ข้าวผัด 1 จาน (khâao-phàt nùeng jaan) = one plate of fried rice / एक प्लेट फ्राइड राइस",
        328: "แกง 1 ถ้วย (kaeng nùeng thûai) = one bowl of curry / एक कटोरी करी",
        329: "รองเท้า 1 คู่ (roong-tháo nùeng khûu) = one pair of shoes / एक जोड़ी जूते",
        330: "ไก่ 2 ชิ้น (kài sǒong chín) = two pieces of chicken / चिकन के दो टुकड़े",
        331: "หนังสือ 1 เล่ม (nǎng-sǔe nùeng lêm) = one book / एक किताब",
        332: "อีกครั้ง (ìik khráng) = again / फिर से; ครั้งแรก (khráng râek) = first time / पहली बार",
        333: "สอง (sǒong) two / दो + ร้อย → สองร้อย (sǒong rói) = 200 / दो सौ",
        334: "หนึ่งพัน (nùeng phan) = 1,000 / एक हज़ार; ห้าพัน (hâa phan) = 5,000 / पाँच हज़ार",
        335: "หนึ่งหมื่น (nùeng mùen) = 10,000 / दस हज़ार; สองหมื่น (sǒong mùen) = 20,000 / बीस हज़ार",
        336: "หนึ่งแสน (nùeng sǎen) = 100,000 / एक लाख — same as Hindi लाख / बिल्कुल हिंदी के लाख जैसा",
        337: "หนึ่งล้าน (nùeng láan) = 1,000,000 / दस लाख; สิบล้าน (sìp láan) = 10,000,000 / एक करोड़",
        338: "ครึ่งชั่วโมง (khrûeng chûa-moong) = half an hour / आधा घंटा; ชั่วโมงครึ่ง (chûa-moong khrûeng) = one and a half hours / डेढ़ घंटा",
        339: "นิด (nít) tiny bit / ज़रा + หน่อย (nòi) a little / थोड़ा → a little bit / थोड़ा-सा",
        340: "คนเยอะ (khon yóe) = many people / बहुत लोग",
        341: "ทั้ง (tháng) whole / पूरा + หมด (mòt) finished / ख़त्म → all, total / कुल",
        342: "classifier + ละ: อันละ 10 บาท (an lá sìp bàat) = 10 baht each / हर एक दस बाथ; วันละครั้ง (wan lá khráng) = once a day / दिन में एक बार",
        343: "Thai phone numbers start with ศูนย์แปด (sǔun pàet) 08 / थाई फ़ोन नंबर 08 से शुरू होते हैं",
        344: "ยี่ (yîi) special form of two / दो का विशेष रूप + สิบ (sìp) ten / दस → 20 / बीस (not สองสิบ!)",
        345: "ห้อง (hôong) room / कमरा + น้ำ (náam) water / पानी → ห้องน้ำ bathroom / बाथरूम; + นอน (noon) sleep / सोना → ห้องนอน bedroom / बेडरूम",
        349: "โต๊ะ (tó) table / मेज़ + อาหาร (aa-hǎan) food / खाना → โต๊ะอาหาร dining table / खाने की मेज़",
        350: "เก้าอี้ 2 ตัว (kâo-îi sǒong tua) = two chairs / दो कुर्सियाँ",
        351: "มือ (meuu) hand / हाथ + ถือ (thěuu) to hold / पकड़ना → มือถือ mobile phone / मोबाइल",
        352: "กุญแจ (kun-jae) key / चाबी + ห้อง (hôong) room / कमरा → กุญแจห้อง room key / कमरे की चाबी",
        353: "เสื้อ (sûea) shirt / कमीज़ + ผ้า (phâa) cloth / कपड़ा → เสื้อผ้า clothes / कपड़े",
        354: "กางเกง (kaang-keeng) pants / पैंट + ขาสั้น (khǎa-sân) short legs / छोटी टाँगें → กางเกงขาสั้น shorts / निक्कर",
        356: "ผ้า (phâa) cloth / कपड़ा + เช็ด (chét) wipe / पोंछना + ตัว (tua) body / शरीर → towel / तौलिया",
        357: "ไฟ (fai) fire, light / आग + ฟ้า (fáa) sky / आकाश → ไฟฟ้า electricity / बिजली",
        358: "เปิดแอร์ (pèrt ae) = turn on the AC / एसी चलाना; ปิดแอร์ (pìt ae) = turn off the AC / एसी बंद करना",
        359: "พัด (phát) to fan / झलना + ลม (lom) wind / हवा → พัดลม fan / पंखा",
        360: "ตู้ (tûu) cabinet / अलमारी + เย็น (yen) cold / ठंडा → ตู้เย็น fridge / फ्रिज",
        362: "โคม (khoom) lantern / कंदील + ไฟ (fai) light / रोशनी → โคมไฟ lamp / लैंप",
        363: "ห้อง (hôong) room / कमरा + นอน (noon) to sleep / सोना → ห้องนอน bedroom / सोने का कमरा",
        364: "ห้อง (hôong) room / कमरा + ครัว (khrua) kitchen / रसोई → ห้องครัว kitchen / रसोईघर",
        365: "แปรง (praeng) brush / ब्रश + สี (sǐi) scrub / रगड़ना + ฟัน (fan) teeth / दाँत → toothbrush / टूथब्रश",
        366: "ยา (yaa) medicine / दवा + สีฟัน (sǐi-fan) scrub teeth / दाँत रगड़ना → toothpaste / टूथपेस्ट",
        367: "หมอน 2 ใบ (mǒon sǒong bai) = two pillows / दो तकिए",
        368: "ผ้า (phâa) cloth / कपड़ा + ห่ม (hòm) to cover / ओढ़ना → ผ้าห่ม blanket / कंबल",
        369: "ส่องกระจก (sòong krà-jòk) = to look in the mirror / आईना देखना",
        370: "ภาษา (phaa-sǎa) language / भाषा + ไทย (thai) Thai / थाई → Thai language / थाई भाषा",
        371: "ภาษา (phaa-sǎa) language / भाषा + ไทย (thai) Thai / थाई → Thai language / थाई भाषा",
        372: "ภาษา (phaa-sǎa) language / भाषा + อังกฤษ (ang-krìt) England / इंग्लैंड → English language / अंग्रेज़ी",
        373: "แปล (plae) translate / अनुवाद + ว่า (wâa) that / कि → แปลว่า it means / मतलब है",
        374: "หมาย (mǎai) signify / संकेत + ความ (khwaam) -ness / भाव + ว่า (wâa) that / कि → to mean that / मतलब होना",
        375: "โทร (thoo) call / फ़ोन + ศัพท์ (sàp) word / शब्द → โทรศัพท์ telephone / टेलीफ़ोन",
        376: "ข้อ (khôo) item / बिंदु + ความ (khwaam) content / बात → message / संदेश",
        378: "เบอร์ (bəə) number / नंबर + โทร (thoo) call / फ़ोन → เบอร์โทร phone number / फ़ोन नंबर",
        379: "ที่ (thîi) place / जगह + อยู่ (yùu) to live / रहना → address / पता",
        380: "ชื่อ (chêu) name / नाम + เล่น (lên) play / खेलना → nickname / निकनेम",
        382: "เพื่อน (phêuan) friend / दोस्त + บ้าน (bâan) house / घर → neighbor / पड़ोसी",
        383: "หัว (hǔa) head / सिर + หน้า (nâa) front / आगे → boss / बॉस",
        384: "เพื่อน (phêuan) friend / दोस्त + ร่วม (rûam) share / साझा + งาน (ngaan) work / काम → colleague / सहकर्मी",
        385: "ห้อง (hông) room / कमरा + ประชุม (prà-chum) meeting / मीटिंग → meeting room / मीटिंग रूम",
        386: "ทำ (tham) do / करना + งาน (ngaan) work / काम → ทำงาน to work / काम करना",
        388: "คำถาม (kham-thǎam) question / सवाल; คำตอบ (kham-tòop) answer / जवाब",
        389: "ปวด (pùat) ache / दर्द + ขา → ปวดขา leg pain / टांग में दर्द",
        390: "เสื้อ (sûea) shirt / कमीज़ + แขนสั้น (khǎen sân) short arm → short-sleeved shirt / आधी बाजू की कमीज़",
        391: "ปวด (pùat) ache / दर्द + ท้อง → ปวดท้อง stomachache / पेट दर्द",
        392: "ปากกา (pàak-kaa) = pen / कलम — a common word that starts with ปาก",
        394: "หู + ฟัง (fang) listen / सुनना → หูฟัง earphones / ईयरफोन",
        396: "รอง (roong) support / सहारा + เท้า → รองเท้า shoes / जूते",
        397: "นิ้ว + เท้า (tháo) foot / पैर → นิ้วเท้า toe / पैर की उंगली",
        398: "เจ็บ (jèp) hurt / दर्द + คอ → เจ็บคอ sore throat / गले में दर्द",
        399: "หน้า also means front: ข้างหน้า (khâang nâa) = in front / आगे",
        400: "เจ็บ + body part: เจ็บคอ (jèp khoo) sore throat / गले में दर्द",
        401: "เป็น (pen) to be / होना + ไข้ → เป็นไข้ to have a fever / बुखार होना",
        402: "ยา (yaa) medicine / दवा + แก้ (kâe) cure / ठीक करना + ไอ → ยาแก้ไอ cough medicine / खांसी की दवा",
        403: "เป็น (pen) to be / होना + หวัด → เป็นหวัด have a cold / ज़ुकाम होना; ไข้หวัดใหญ่ (khâi-wàt-yài) = flu / फ्लू",
        404: "ยา (yaa) medicine / दवा + แก้ (kâe) cure / ठीक करना + ปวด (pùat) pain / दर्द → painkiller / दर्द की दवा",
        405: "also means to lose: แพ้เกม (pháe keem) lose the game / खेल हारना",
        406: "เลือด + ออก (òok) exit / निकलना → เลือดออก to bleed / खून निकलना",
        409: "รถ (rót) vehicle / गाड़ी + พยาบาล (phá-yaa-baan) nurse / नर्स → ambulance / एम्बुलेंस",
        410: "ร้าน (ráan) shop / दुकान + ขาย (khǎai) to sell / बेचना + ยา (yaa) medicine / दवा → pharmacy / दवाई की दुकान",
        411: "ประกัน + สุขภาพ (sùk-khà-phâap) health / स्वास्थ्य → ประกันสุขภาพ health insurance / स्वास्थ्य बीमा",
        412: "พัก (phák) pause / रुकना + ผ่อน (phòn) ease / ढीला छोड़ना → to rest / आराम करना",
        187: "ดี (dii) good / अच्छा + ใจ (jai) heart / दिल → happy / खुश",
        188: "เสีย (sǐa) lost / खोया + ใจ (jai) heart / दिल → sad / दुखी",
        191: "ตื่น (dtùun) wake up / जागना + เต้น (dtên) jump-dance / कूदना → excited / उत्साहित",
        192: "คิด (kít) think / सोचना + ถึง (tǔng) to / तक → to miss / याद आना",
        194: "รอ (ror) wait / इंतज़ार + สัก (sàk) just / ज़रा + ครู่ (krûu) moment / क्षण → wait a moment / ज़रा रुकिए",
        195: "อาจ (àat) may / शायद + จะ (jà) will / -गा → maybe / शायद",
        196: "แน่ (nâe) certain / पक्का + นอน (non) lie down / लेटना → certainly (fixed idiom / रूढ़ प्रयोग)",
        197: "ด้วย (dûai) with / साथ + กัน (gan) each other / आपस में → together / साथ में",
        198: "คน (kon) person / व्यक्ति + เดียว (diao) single / एक ही → alone / अकेला",
        199: "กระเป๋า (grà-bpǎo) bag / बैग + เงิน (ngern) money / पैसा → wallet / बटुआ",
        200: "เสื้อ (sûea) shirt / शर्ट + ผ้า (pâa) cloth / कपड़ा → clothes / कपड़े",
        201: "รอง (rawng) to support / सहारा देना + เท้า (táao) foot / पैर → shoes / जूते",
        202: "ที่ (tîi) thing for / साधन + ชาร์จ (châat) to charge / चार्ज करना → charger / चार्जर",
        203: "ต่อ (dtàw) to negotiate / मोल करना + ราคา (raa-khaa) price / क़ीमत → to bargain / मोल-भाव करना",
        204: "ลด (lót) reduce / कम करना + หน่อย (nòi) a little / थोड़ा + ได้ไหม (dâi mǎi) can you? / क्या हो सकता है? → can you lower a bit? / थोड़ा कम करेंगे?",
        206: "พอ (phaw) enough / काफ़ी + ดี (dii) good / अच्छा → just right / एकदम ठीक",
        207: "ลอง (lawng) try / आज़माना + ใส่ (sài) wear / पहनना → ลองใส่ try on (clothes) / पहनकर देखना",
        208: "ใบ (bai) sheet, slip / पर्ची + เสร็จ (sèt) finished / पूरा → receipt / रसीद",
        209: "ถุง (tǔng) bag, sack / थैली + พลาสติก (pláat-sà-dtìk) plastic / प्लास्टिक → plastic bag / प्लास्टिक की थैली",
        210: "กี่ (gìi) how many / कितने + โมง (mohng) o'clock / बजे → what time? / कितने बजे?",
        211: "ชาย (chaai) edge / किनारा + หาด (hàat) sandy shore / रेतीला तट → beach / समुद्र तट",
        212: "เกาะ (gò) island / द्वीप + ช้าง (cháang) elephant / हाथी → เกาะช้าง Koh Chang (Elephant Island) / हाथी द्वीप",
        213: "ตั๋ว (dtǔa) ticket / टिकट + รถไฟ (rót-fai) train / ट्रेन → ตั๋วรถไฟ train ticket / ट्रेन टिकट",
        214: "นั่ง (nâng) to sit / बैठना + เรือ (rʉa) boat / नाव → นั่งเรือ to travel by boat / नाव से जाना",
        215: "วิน (win) taxi stand / स्टैंड + มอเตอร์ไซค์ (moo-dter-sai) motorcycle / मोटरसाइकिल → motorbike taxi / बाइक टैक्सी",
        216: "ข้าว (khâao) rice / चावल + เหนียว (nǐao) sticky / चिपचिपा + มะม่วง (má-mûang) mango / आम → mango sticky rice / मैंगो स्टिकी राइस",
        217: "ส้ม (sôm) sour / खट्टा + ตำ (dtam) pounded / कूटा हुआ → pounded papaya salad / पपीते का सलाद",
        218: "ผัด (phàt) stir-fried / भूना हुआ + ไทย (thai) Thai / थाई → Thai stir-fried noodles / थाई भुनी नूडल्स",
        219: "ขวด (khùat) bottle / बोतल + น้ำ (náam) water / पानी → water bottle / पानी की बोतल",
        220: "เช็ค (chék) check / चेक + บิล (bin) bill / बिल → 'bill, please' phrase; final ล sounds like น / अंतिम ล का उच्चारण 'न' जैसा होता है",
        221: "ช้อน (chóon) spoon / चम्मच + ส้อม (sôom) fork / काँटा → ช้อนส้อม, the usual Thai cutlery pair / थाई खाने की आम जोड़ी",
        222: "ส้อม (sôom, long vowel) fork / काँटा ≠ ส้ม (sôm, short) orange / संतरा; ช้อนส้อม (chóon-sôom) = spoon and fork / चम्मच-काँटा",
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
        1264: "น้ำ (náam) water / पानी + ท่วม (thûam) overflow / छलना → flood / बाढ़",
        1797: "ห้อง (hâwng) room / कमरा + รับแขก (ráp-khàek) receive guests / मेहमान लेना → guest room / बैठक कक्ष",
        1798: "ห้อง (hâwng) room / कमरा + อาหาร (aa-hǎan) food / भोजन → dining room / भोजन कक्ष",
        1799: "ห้อง (hâwng) room / कमरा + ทำงาน (tham-ngaan) work / काम करना → home office / घर का कार्यकक्ष",
        1800: "ห้อง (hâwng) room / कमरा + เก็บของ (kèp-khǎawng) store things / सामान रखना → storage room / भंडार कक्ष",
        1801: "ห้อง (hâwng) room / कमरा + ใต้หลังคา (tâi-lǎng-khaa) under roof / छत के नीचे → attic / अटारी",
        1802: "ห้อง (hâwng) room / कमरा + แต่งตัว (tàeng-tua) dress oneself / कपड़े पहनना → dressing room / कपड़े बदलने का कमरा",
        1803: "ห้อง (hâwng) room / कमरा + พระ (phrá) Buddha monk / बुद्ध प्रतिमा → Buddha room / पूजा कक्ष",
        1804: "ห้องนอน (hâwng-nawn) bedroom / शयनकक्ष + ใหญ่ (yài) large / बड़ा → master bedroom / मुख्य शयनकक्ष",
        1805: "ห้องน้ำ (hâwng-náam) bathroom / स्नानघर + แขก (khàek) guest / मेहमान → guest bathroom / मेहमान स्नानघर",
        1806: "ห้อง (hâwng) room / कमरा + ซักรีด (sák-rîit) wash and iron / धोना-इस्त्री करना → laundry room / कपड़े धोने का कमरा",
        1807: "ห้องครัว (hâwng-khrua) kitchen / रसोईघर + เล็ก (lék) small / छोटा → kitchenette / छोटा रसोईघर",
        1809: "โรง (roong) building / इमारत + รถ (rót) vehicle / वाहन → garage / गैरेज",
        1810: "ทาง (thaang) way / रास्ता + เดิน (doen) walk / चलना → corridor / गलियारा",
        1812: "มุม (mum) corner / कोना + อ่านหนังสือ (àan-nǎng-sʉ̌ʉ) read books / किताब पढ़ना → reading nook / पढ़ने का कोना",
        1814: "ลูกบิด (lûuk-bìt) knob / घुंडी + ประตู (prà-tuu) door / दरवाज़ा → doorknob / दरवाज़े का हैंडल",
        1815: "กลอน (klawn) latch / कुंडी + ประตู (prà-tuu) door / दरवाज़ा → door latch / दरवाज़े की कुंडी",
        1816: "มือ (mʉʉ) hand / हाथ + จับ (jàp) grasp / पकड़ना → handle / हैंडल",
        1818: "มุ้ง (múng) mosquito net / मच्छरदानी + ลวด (lûat) wire / तार → window screen / मच्छर-जाली",
        1820: "พรม (phrom) mat / चटाई + เช็ดเท้า (chét-tháao) wipe feet / पैर पोंछना → doormat / पायदान",
        1822: "ราว (raao) rail / रॉड + แขวนผ้า (khwǎen-phâa) hang clothes / कपड़े टाँगना → clothes rail / कपड़े टाँगने की रॉड",
        1823: "ไม้ (máai) wood / लकड़ी + แขวนเสื้อ (khwǎen-sʉ̂ʉa) hang shirt / कपड़े टाँगना → clothes hanger / कपड़े का हैंगर",
        1824: "ตู้ (tûu) cabinet / अलमारी + รองเท้า (rawng-tháao) shoes / जूते → shoe cabinet / जूते की अलमारी",
        1827: "ชั้น (chán) shelf / शेल्फ + หนังสือ (nǎng-sʉ̌ʉ) book / किताब → bookshelf / किताबों की अलमारी",
        1828: "โต๊ะ (tó) table / मेज़ + ข้างเตียง (khâang-tiiang) beside bed / बिस्तर के पास → bedside table / बिस्तर के पास की मेज़",
        1832: "ผ้า (phâa) cloth / कपड़ा + ปู (puu) spread / बिछाना + ที่นอน (thîi-nawn) bed / बिस्तर → bed sheet / चादर",
        1833: "ปลอก (plàawk) cover / खोल + หมอน (mǎawn) pillow / तकिया → pillowcase / तकिए का गिलाफ",
        1835: "ผ้า (phâa) cloth / कपड़ा + ม่าน (mâan) curtain / परदा → curtain / परदे का कपड़ा",
        1836: "พัดลม (phát-lom) fan / पंखा + เพดาน (pheedaan) ceiling / छत → ceiling fan / छत का पंखा",
        1837: "สวิตช์ (sà-wít) switch / स्विच + ไฟ (fai) light / बिजली → light switch / बिजली का स्विच",
        1838: "ปลั๊ก (plák) plug / प्लग + พ่วง (phûang) extend / जोड़ना → power strip / मल्टीप्लग",
        1839: "เครื่อง (khrʉ̂ang) machine / मशीन + กรองน้ำ (krawng-náam) filter water / पानी छानना → water filter / पानी का फ़िल्टर",
        1840: "ถัง (thǎng) tank / टंकी + แก๊ส (káet) gas / गैस → gas cylinder / गैस सिलेंडर",
        1841: "เครื่อง (khrʉ̂ang) machine / मशीन + ดูดควัน (dùut-khwan) suck smoke / धुआँ खींचना → range hood / रसोई धुआँ-निकास",
        1842: "ดูด (dùut) suck / खींचना + ฝุ่น (fùn) dust / धूल → vacuum clean / वैक्यूम करना",
        1843: "เช็ด (chét) wipe / पोंछना + ฝุ่น (fùn) dust / धूल → dust surfaces / धूल पोंछना",
        1844: "ขัด (khàt) scrub / रगड़ना + พื้น (phʉ́ʉn) floor / फर्श → scrub the floor / फर्श रगड़ना",
        1845: "ถู (thǔu) rub / पोछना + พื้น (phʉ́ʉn) floor / फर्श → mop the floor / फर्श पोछना",
        1846: "กวาด (kwàat) sweep / बुहारना + ใบไม้ (bai-máai) leaves / पत्ते → sweep leaves / पत्ते बुहारना",
        1847: "เก็บ (kèp) put away / समेटना + ที่นอน (thîi-nawn) bed / बिस्तर → make the bed / बिस्तर समेटना",
        1848: "เปลี่ยน (plìan) change / बदलना + ผ้าปูที่นอน (phâa-puu-thîi-nawn) bed sheet / चादर → change bed sheets / चादर बदलना",
        1849: "พับ (pháp) fold / तह करना + ผ้าห่ม (phâa-hòm) blanket / कंबल → fold a blanket / कंबल तह करना",
        1850: "ตาก (tàak) dry in sun / सुखाना + ผ้าขนหนู (phâa-khǒn-nǔu) towel / तौलिया → hang towels to dry / तौलिए सुखाना",
        1851: "รีด (rîit) iron / इस्त्री करना + เสื้อ (sʉ̂ʉa) shirt / कमीज़ → iron a shirt / कमीज़ इस्त्री करना",
        1854: "เปลี่ยน (plìan) change / बदलना + หลอดไฟ (làawt-fai) light bulb / बल्ब → replace a light bulb / बल्ब बदलना",
        1855: "อุด (ùt) plug / बंद करना + รอยรั่ว (rawi-rûa) leak / रिसाव → seal a leak / रिसाव बंद करना",
        1856: "ล้าง (láang) wash / साफ़ करना + ห้องน้ำ (hâwng-náam) bathroom / स्नानघर → clean the bathroom / स्नानघर साफ़ करना",
        1857: "ล้าง (láang) wash / साफ़ करना + อ่างล้างจาน (àang-láang-jaan) sink / सिंक → clean the sink / सिंक साफ़ करना",
        1860: "ตาก (tàak) dry / सुखाना + แดด (dàet) sunlight / धूप → sun-dry / धूप में सुखाना",
        1861: "แยก (yâek) separate / अलग करना + ขยะ (khàyà) garbage / कचरा → sort waste / कचरा अलग करना",
        1863: "ทิ้ง (thíng) discard / फेंकना + ขยะ (khàyà) garbage / कचरा → throw away trash / कचरा फेंकना",
        1864: "ผูก (phùuk) tie / बाँधना + ถุงขยะ (thǔng-khàyà) garbage bag / कूड़े की थैली → tie a garbage bag / कूड़े की थैली बाँधना",
        1865: "รดน้ำ (rót-náam) water / पानी देना + ต้นไม้ (tôn-máai) plants / पौधे → water plants / पौधों को पानी देना",
        1866: "ตัดแต่ง (tàt-tàeng) trim / छाँटना + กิ่งไม้ (kìng-máai) branches / टहनियाँ → prune branches / टहनियाँ छाँटना",
        1869: "กด (kòt) press / दबाना + ชักโครก (chák-khrôok) toilet / शौचालय → flush the toilet / फ़्लश करना",
        1870: "ล้าง (láang) wash / धोना + รถ (rót) car / कार → wash a car / कार धोना",
        1871: "เติม (toem) fill / भरना + น้ำมัน (náam-man) fuel / ईंधन → refill fuel / ईंधन भरना",
        1872: "จัด (jàt) arrange / सजाना + โต๊ะ (tó) table / मेज़ → set the table / मेज़ सजाना",
        1873: "ล้าง (láang) wash / धोना + แก้ว (kâeo) glass / गिलास → wash glasses / गिलास धोना",
        1874: "เก็บ (kèp) clear away / हटाना + จาน (jaan) plate / बर्तन → clear the dishes / बर्तन हटाना",
        1875: "ลับ (láp) sharpen / तेज़ करना + มีด (mîit) knife / चाकू → sharpen a knife / चाकू तेज़ करना",
        1876: "เปิด (pòet) open / खोलना + หน้าต่าง (nâa-tàang) window / खिड़की → open a window / खिड़की खोलना",
        1877: "ปิด (pìt) close / बंद करना + ม่าน (mâan) curtain / परदा → draw the curtains / परदे बंद करना",
        1878: "ล็อก (lɔ́k) lock / ताला लगाना + ประตู (prà-tuu) door / दरवाज़ा → lock the door / दरवाज़ा बंद करना",
        1879: "ไข (khǎi) unlock / खोलना + กุญแจ (kun-jaae) key / चाबी → unlock with a key / चाबी से खोलना",
        1880: "ชาร์จ (châat) charge / चार्ज करना + แบตเตอรี่ (bàet-dtə-rii) battery / बैटरी → charge a battery / बैटरी चार्ज करना",
        1881: "เสียบ (sìap) insert / लगाना + ปลั๊ก (plák) plug / प्लग → plug in / प्लग लगाना",
        1882: "ถอด (thàawt) remove / निकालना + ปลั๊ก (plák) plug / प्लग → unplug / प्लग निकालना",
        1883: "กด (kòt) press / दबाना + กริ่ง (krìng) bell / घंटी → ring the doorbell / घंटी बजाना",
        1884: "รับ (ráp) receive / लेना + พัสดุ (phát-dù) parcel / पार्सल → receive a parcel / पार्सल लेना",
        1885: "แกะ (kàe) unwrap / खोलना + พัสดุ (phát-dù) parcel / पार्सल → unpack a parcel / पार्सल खोलना",
        1889: "วัด (wát) measure / मापना + ขนาด (khà-nàat) size / आकार → measure dimensions / माप लेना",
        1903: "ปลอด (plàawt) free from / मुक्त + ภัย (phai) danger / खतरा → safe / सुरक्षित",
        1927: "กำหนด (kam-nòt) set / निर्धारित करना + เวลา (wee-laa) time / समय → deadline / समय-सीमा",
        1928: "เลื่อน (lʉ̂an) postpone / टालना + นัด (nát) appointment / मुलाकात → reschedule an appointment / मुलाकात टालना",
        1933: "แจ้ง (jâeng) notify / सूचित करना + เตือน (dtʉan) warn / चेतावनी देना → alert / चेतावनी देना",
        1935: "แนะนำ (nâe-nam) introduce / परिचय कराना + ตัว (tua) self / स्वयं → introduce oneself / अपना परिचय देना",
        1941: "เห็น (hěn) see / देखना + ด้วย (dûai) with / साथ → agree / सहमत होना",
        1942: "ไม่ (mâi) not / नहीं + เห็นด้วย (hěn-dûai) agree / सहमत → disagree / असहमत होना",
        1946: "ออก (àawk) out / बाहर + เสียง (sǐang) sound / आवाज़ → pronounce / उच्चारण करना",
        1949: "แนบ (nâep) attach / संलग्न करना + ไฟล์ (fai) file / फ़ाइल → attach a file / फ़ाइल संलग्न करना",
        1950: "ส่ง (sòng) send / भेजना + ข้อความ (khâaw-khwaam) message / संदेश → send a message / संदेश भेजना",
        1951: "รับ (ráp) receive / लेना + สาย (sǎai) call / कॉल → answer a call / फ़ोन उठाना",
        1952: "วาง (waang) put down / रखना + สาย (sǎai) call / कॉल → hang up / फ़ोन रखना",
        1953: "ฝาก (fàak) leave with / छोड़ना + ข้อความ (khâaw-khwaam) message / संदेश → leave a message / संदेश छोड़ना",
        1954: "รหัส (rá-hàt) code / कूट + ผ่าน (phàan) pass / प्रवेश → password / पासवर्ड",
        1955: "ลาย (laai) pattern / निशान + นิ้วมือ (níw-mʉʉ) finger / उँगली → fingerprint / उँगली का निशान",
        1956: "กล้อง (klâawng) camera / कैमरा + วงจรปิด (wong-jon-pìt) closed circuit / बंद परिपथ → CCTV camera / सीसीटीवी कैमरा",
        1957: "สัญญาณ (sǎn-yaan) signal / संकेत + เตือนภัย (dtʉan-phai) warn danger / खतरे की चेतावनी → alarm signal / अलार्म संकेत",
        1958: "ถัง (thǎng) tank / डिब्बा + ดับเพลิง (dàp-phloeng) extinguish fire / आग बुझाना → fire extinguisher / अग्निशामक",
        1959: "ทาง (thaang) route / रास्ता + หนีไฟ (nǐi-fai) escape fire / आग से बचना → fire exit / आपात निकास",
        1960: "จุด (jùt) point / बिंदु + รวมพล (ruam-phon) gather people / लोगों को इकट्ठा करना → assembly point / एकत्र होने का स्थान",
        1961: "โทร (thoo) call / फ़ोन करना + ฉุกเฉิน (chùk-chǒen) emergency / आपातकाल → make an emergency call / आपातकालीन फ़ोन करना",
        1962: "ระวัง (rá-wang) beware / सावधान + ไฟฟ้า (fai-fáa) electricity / बिजली → beware of electricity / बिजली से सावधान",
        1963: "ห้าม (hâam) prohibit / मना करना + เข้า (khâo) enter / प्रवेश करना → do not enter / प्रवेश निषिद्ध",
        1964: "ห้าม (hâam) prohibit / मना + สูบบุหรี่ (sùup-bù-rìi) smoke / धूम्रपान करना → no smoking / धूम्रपान निषिद्ध",
        1965: "อันตราย (an-dtà-raai) danger / खतरा + จากไฟฟ้า (jàak-fai-fáa) from electricity / बिजली से → electrical hazard / बिजली का खतरा",
        1966: "บัญชี (ban-chii) account / खाता + ธนาคาร (tha-naa-khaan) bank / बैंक → bank account / बैंक खाता",
        1967: "เปิด (pòet) open / खोलना + บัญชี (ban-chii) account / खाता → open an account / खाता खोलना",
        1968: "ฝาก (fàak) deposit / जमा करना + เงิน (ngoen) money / पैसा → deposit money / पैसे जमा करना",
        1969: "ถอน (thǎawn) withdraw / निकालना + เงิน (ngoen) money / पैसा → withdraw money / पैसे निकालना",
        1970: "โอน (oon) transfer / भेजना + เงิน (ngoen) money / पैसा → transfer money / पैसे भेजना",
        1971: "ยอดเงิน (yâawt-ngoen) amount / रकम + คงเหลือ (khong-lʉ̌ʉa) remaining / बचा हुआ → account balance / शेष राशि",
        1974: "รหัส (rá-hàt) code / कूट + เอทีเอ็ม (ee-thii-em) ATM / एटीएम → ATM PIN / एटीएम पिन",
        1978: "อัตรา (àt-dtraa) rate / दर + แลกเปลี่ยน (lâek-plìan) exchange / विनिमय → exchange rate / विनिमय दर",
        1980: "เงิน (ngoen) money / पैसा + สด (sòt) ready / नकद → cash / नकद",
        1981: "ใบ (bai) document / पत्र + แจ้งยอด (jâeng-yâawt) state balance / शेष बताना → bank statement / बैंक विवरण",
        1982: "ชำระ (cham-rá) pay / भुगतान करना + เงิน (ngoen) money / पैसा → make a payment / भुगतान करना",
        1985: "เงิน (ngoen) money / पैसा + ออม (aawm) save / बचाना → savings / बचत",
        1986: "บัตร (bàt) card / कार्ड + ประชาชน (prà-chaa-chon) citizen / नागरिक → national ID card / राष्ट्रीय पहचान पत्र",
        1988: "สำเนา (sam-nao) copy / प्रतिलिपि + บัตรประชาชน (bàt-prà-chaa-chon) ID card / पहचान पत्र → copy of ID card / पहचान पत्र की प्रतिलिपि",
        1990: "กรอก (kràawk) fill in / भरना + แบบฟอร์ม (bàep-faawm) form / फॉर्म → fill out a form / फॉर्म भरना",
        1991: "ลง (long) put down / लिखना + ชื่อ (chʉ̂ʉ) name / नाम → sign / हस्ताक्षर करना",
        1993: "ตรา (dtraa) seal / मुहर + ประทับ (prà-tháp) stamp / छापना → official stamp / मुहर",
        1995: "เอกสาร (èek-gà-sǎan) document / दस्तावेज़ + สำคัญ (sǎm-khan) important / महत्वपूर्ण → important document / महत्वपूर्ण दस्तावेज़",
        1996: "ใบ (bai) paper / पत्र + สมัคร (sà-màk) apply / आवेदन करना → application form / आवेदन पत्र",
        1997: "ใบ (bai) paper / पत्र + อนุญาต (à-nú-yâat) permit / अनुमति → permit / अनुमति पत्र",
        2000: "วัน (wan) day / दिन + หมดอายุ (mòt-aa-yú) expire / समाप्त होना → expiry date / समाप्ति तिथि",
        2001: "ต่อ (dtàaw) extend / बढ़ाना + อายุ (aa-yú) validity / अवधि → renew / नवीनीकरण करना",
        2003: "แปล (plaae) translate / अनुवाद करना + เอกสาร (èek-gà-sǎan) document / दस्तावेज़ → translate a document / दस्तावेज़ का अनुवाद करना",
        2004: "ยื่น (yʉ̂ʉn) submit / जमा करना + เอกสาร (èek-gà-sǎan) document / दस्तावेज़ → submit documents / दस्तावेज़ जमा करना",
        2005: "วัน (wan) day / दिन + พระ (phrá) sacred / पवित्र → Buddhist holy day / बौद्ध पवित्र दिन",
        2006: "พระ (phrá) monk / भिक्षु + สงฆ์ (sǒng) Buddhist order / संघ → Buddhist monkhood / बौद्ध संघ",
        2008: "พระ (phrá) sacred / पवित्र + พุทธรูป (phút-thá-rûup) Buddha image / बुद्ध प्रतिमा → Buddha image / बुद्ध प्रतिमा",
        2017: "ดอก (dàawk) flower / फूल + บัว (buaa) lotus / कमल → lotus flower / कमल",
        2018: "ทำ (tham) do / करना + บุญ (bun) merit / पुण्य → make merit / पुण्य करना",
        2020: "ใส่ (sài) put in / डालना + บาตร (bàat) alms bowl / भिक्षापात्र → give alms / भिक्षा देना",
        2021: "สวด (sùat) chant / जपना + มนต์ (mon) prayer / मंत्र → chant prayers / मंत्र जपना",
        2022: "นั่ง (nâng) sit / बैठना + สมาธิ (sà-màa-thí) meditation / ध्यान → meditate / ध्यान करना",
        2027: "ปีใหม่ (pii-mài) new year / नववर्ष + ไทย (thai) Thai / थाई → Thai New Year / थाई नववर्ष",
        2028: "วัน (wan) day / दिन + เกิด (gòet) birth / जन्म → birthday / जन्मदिन",
        2029: "วัน (wan) day / दिन + ครบรอบ (khrop-râawp) anniversary / वर्षगाँठ → anniversary / वर्षगाँठ",
        2030: "เช้า (cháao) morning / सुबह + มืด (mʉ̂ʉt) dark / अंधेरा → before dawn / भोर से पहले",
        2042: "ช่วง (chûang) period / अवधि + เวลา (wee-laa) time / समय → time period / समयावधि",
        2045: "เส้น (sên) line / रेखा + ตาย (dtaai) dead / अंतिम → deadline / अंतिम समय-सीमा",
    ]
}
