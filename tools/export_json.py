#!/usr/bin/env python3
"""Export the Swift-literal content into the canonical JSON both apps read.

Single source of truth lives in the Swift files today; this script lifts it out
so iOS and Android load identical data instead of drifting (Android was stuck at
1,046 words while iOS had 4,446).

Canonical schema (short keys — JSON is the wire format, iOS maps on decode):

  content.json
    { "version": 1,
      "words":   [ {id, thai, roman, hindiPron, en, hi, category}, ... ],
      "examples": { "<id>": [ {thai, roman, en, hi}, ... ] },
      "forms":    { "<id>": [ {thai, roman, en, hi, note}, ... ] },
      "similar":  { "<id>": [id, ...] },
      "compounds":{ "<id>": "note" },
      "emoji":    { "<id>": "X" } }

Usage:  python3 tools/export_json.py [--check]
  --check  parse and report counts without writing files
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOCAB = ROOT / "ThaiWallpaperLearn/Shared/Vocabulary.swift"
EXTRAS = ROOT / "ThaiWallpaperLearn/Shared/ThaiWord.swift"
MORE = ROOT / "ThaiWallpaperLearn/App/ContentView.swift"
IOS_OUT = ROOT / "ThaiWallpaperLearn/Shared/content.json"
ANDROID_OUT = ROOT / "android/app/src/main/assets/content.json"

# Swift string literal: handles \" escapes.
STR = r'"((?:[^"\\]|\\.)*)"'


def unescape(s: str) -> str:
    return s.replace('\\"', '"').replace("\\\\", "\\")


def parse_words(src: str):
    pat = re.compile(
        r"ThaiWord\(\s*id:\s*(\d+),\s*thai:\s*" + STR +
        r",\s*romanization:\s*" + STR +
        r",\s*hindiPronunciation:\s*" + STR +
        r",\s*englishMeaning:\s*" + STR +
        r",\s*hindiMeaning:\s*" + STR +
        r",\s*category:\s*" + STR + r"\s*\)"
    )
    out = []
    for m in pat.finditer(src):
        out.append({
            "id": int(m.group(1)),
            "thai": unescape(m.group(2)),
            "roman": unescape(m.group(3)),
            "hindiPron": unescape(m.group(4)),
            "en": unescape(m.group(5)),
            "hi": unescape(m.group(6)),
            "category": unescape(m.group(7)),
        })
    return out


def _literal_span(src: str, decl: str):
    """Return the body of the array literal that follows `decl`.

    The declaration looks like `private static let forms: [Int: [WordForm]] = [`,
    so the first `[` after the name belongs to the *type*, not the literal — we
    must anchor on the `= [` instead.
    """
    start = src.find(decl)
    if start == -1:
        return None
    eq = src.find("= [", start)
    if eq == -1:
        return None
    i = eq + 2
    depth, j = 0, i
    while j < len(src):
        if src[j] == "[":
            depth += 1
        elif src[j] == "]":
            depth -= 1
            if depth == 0:
                break
        j += 1
    return src[i + 1:j]


def _dict_blocks(src: str, decl: str):
    """Yield (id, body) for each `<id>: [ ... ],` entry in the literal."""
    body = _literal_span(src, decl)
    if body is None:
        return
    for m in re.finditer(r"(\d+)\s*:\s*\[(.*?)\n\s*\],", body, re.S):
        yield int(m.group(1)), m.group(2)


def parse_examples(src: str):
    out = {}
    pat = re.compile(
        r"WordExample\(thai:\s*" + STR + r",\s*romanization:\s*" + STR +
        r",\s*english:\s*" + STR + r",\s*hindi:\s*" + STR + r"\)"
    )
    for decl in re.findall(r"private static let (examples\d+):", src):
        for wid, body in _dict_blocks(src, f"let {decl}:"):
            rows = [{"thai": unescape(a), "roman": unescape(b),
                     "en": unescape(c), "hi": unescape(d)}
                    for a, b, c, d in pat.findall(body)]
            if rows:
                out.setdefault(str(wid), []).extend(rows)
    return out


def parse_forms(src: str):
    out = {}
    pat = re.compile(
        r"WordForm\(thai:\s*" + STR + r",\s*romanization:\s*" + STR +
        r",\s*english:\s*" + STR + r",\s*hindi:\s*" + STR +
        r",\s*note:\s*" + STR + r"\)"
    )
    for wid, body in _dict_blocks(src, "let forms:"):
        rows = [{"thai": unescape(a), "roman": unescape(b), "en": unescape(c),
                 "hi": unescape(d), "note": unescape(e)}
                for a, b, c, d, e in pat.findall(body)]
        if rows:
            out[str(wid)] = rows
    return out


def parse_int_map(src: str, decl: str):
    """Parse `[Int: String]` literals such as emojis / numberCompounds."""
    body = _literal_span(src, decl)
    if body is None:
        return {}
    return {m.group(1): unescape(m.group(2))
            for m in re.finditer(r"(\d+)\s*:\s*" + STR, body)}


def parse_similar(src: str):
    body = _literal_span(src, "let similar:")
    if body is None:
        return {}
    out = {}
    for m in re.finditer(r"(\d+)\s*:\s*\[([\d,\s]*)\]", body):
        ids = [int(x) for x in re.findall(r"\d+", m.group(2))]
        if ids:
            out[m.group(1)] = ids
    return out


FUN_FIELDS = ("thai", "roman", "meaning", "hindi", "note")
PAIR_FIELDS = ("thaiA", "romanA", "meaningA", "hindiA",
               "thaiB", "romanB", "meaningB", "hindiB", "note")


def _ctor_re(name, fields):
    """Regex for `Name(field: "…", field: "…")` with Swift string escapes."""
    body = r",\s*".join(rf"{f}:\s*{STR}" for f in fields)
    return re.compile(rf"{name}\(\s*{body}\s*\)", re.S)


FUN_RE = _ctor_re("FunWord", FUN_FIELDS)
PAIR_RE = _ctor_re("WordPair", PAIR_FIELDS)


FACT_RE = re.compile(rf"\(\s*{STR}\s*,\s*{STR}\s*\)", re.S)


def parse_facts(src: str):
    """`static let facts: [(String, String)]` — (title, body) tuples."""
    body = _literal_span(src, "let facts:")
    if body is None:
        return []
    return [{"title": unescape(m.group(1)), "body": unescape(m.group(2))}
            for m in FACT_RE.finditer(body)]


LETTER_FIELDS = ("letter", "name", "nameRoman", "nameEnglish", "nameHindi",
                 "sound", "devanagari")
# `obsolete` has a Swift default, so only the two dead letters (ฃ ฅ) carry it.
LETTER_RE = re.compile(
    r"ThaiLetter\(\s*" +
    r",\s*".join(rf"{f}:\s*{STR}" for f in LETTER_FIELDS) +
    r"(?:\s*,\s*obsolete:\s*(true|false))?\s*\)", re.S)


def parse_letters(src: str):
    body = _literal_span(src, "let all:")
    if body is None:
        return []
    out = []
    for m in LETTER_RE.finditer(body):
        row = dict(zip(LETTER_FIELDS, (unescape(g) for g in m.groups()[:7])))
        row["obsolete"] = m.group(8) == "true"
        out.append(row)
    return out


def parse_more(src: str, decl: str, pattern, fields):
    """Rows of one MoreData literal (slang / cousins / opposites / similars)."""
    body = _literal_span(src, decl)
    if body is None:
        return []
    return [dict(zip(fields, (unescape(g) for g in m.groups())))
            for m in pattern.finditer(body)]


def main():
    check_only = "--check" in sys.argv
    vocab_src = VOCAB.read_text(encoding="utf-8")
    extras_src = EXTRAS.read_text(encoding="utf-8")
    more_src = MORE.read_text(encoding="utf-8")

    # Migration is incremental: each section moves out of Swift and into
    # content.json one at a time. Once a section's literals are gone the parser
    # returns nothing for it, which must mean "already migrated, keep what the
    # JSON has" — not "wipe it". Anything still in Swift wins, so re-running
    # after a word batch still picks up the new literals.
    existing = {}
    if IOS_OUT.exists():
        existing = json.loads(IOS_OUT.read_text(encoding="utf-8"))

    def section(name, parsed):
        if parsed:
            return parsed, "swift"
        return existing.get(name, type(parsed)()), "json (already migrated)"

    sections = {
        "words": parse_words(vocab_src),
        "examples": parse_examples(extras_src),
        "forms": parse_forms(extras_src),
        "similar": parse_similar(extras_src),
        # `compoundNote` reads `compounds[id] ?? numberCompounds[id]`, so the
        # hand-written notes must win over the generated number ones. Merging
        # in that order reproduces the accessor exactly.
        "compounds": {**parse_int_map(extras_src, "let numberCompounds:"),
                      **parse_int_map(extras_src, "let compounds:")},
        "emoji": parse_int_map(extras_src, "let emojis:"),
        # The More tab's content, lifted out of ContentView.swift for the same
        # reason as the word list: it was iOS-only Swift literals, so Android
        # had no way to show any of it.
        "slang": parse_more(more_src, "let slang:", FUN_RE, FUN_FIELDS),
        "cousins": parse_more(more_src, "let cousins:", FUN_RE, FUN_FIELDS),
        "opposites": parse_more(more_src, "let opposites:", PAIR_RE, PAIR_FIELDS),
        "similars": parse_more(more_src, "let similars:", PAIR_RE, PAIR_FIELDS),
        "facts": parse_facts(more_src),
        "letters": parse_letters(more_src),
    }
    origin = {}
    payload = {"version": 1}
    for name, parsed in sections.items():
        payload[name], origin[name] = section(name, parsed)

    words = payload["words"]
    ids = [w["id"] for w in words]
    problems = []
    if not ids:
        problems.append("no words found in Swift or JSON")
    if len(ids) != len(set(ids)):
        problems.append("duplicate ids")
    if ids and sorted(ids) != list(range(min(ids), max(ids) + 1)):
        problems.append("gaps in id sequence")
    thais = [w["thai"] for w in words]
    if len(thais) != len(set(thais)):
        problems.append("duplicate thai words")

    for name in sections:
        print(f"  {name:9} <- {origin[name]}")
    span = f" (ids {min(ids)}-{max(ids)})" if ids else ""
    print(f"words     : {len(words)}{span}")
    print(f"examples  : {len(payload['examples'])} words, "
          f"{sum(len(v) for v in payload['examples'].values())} sentences")
    print(f"forms     : {len(payload['forms'])}")
    print(f"similar   : {len(payload['similar'])}")
    print(f"compounds : {len(payload['compounds'])}")
    print(f"emoji     : {len(payload['emoji'])}")
    print("integrity :", "OK" if not problems else "; ".join(problems))

    if check_only:
        return 0 if not problems else 1
    if problems:
        print("refusing to write — fix integrity problems first")
        return 1

    blob = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    # Size in bytes, not characters — Thai and Devanagari are 3 bytes each in
    # UTF-8, so len(str) understates the on-disk size by about a third.
    megabytes = len(blob.encode("utf-8")) / 1024 / 1024
    for dest in (IOS_OUT, ANDROID_OUT):
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(blob, encoding="utf-8")
        print(f"wrote {dest.relative_to(ROOT)}  ({megabytes:.2f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
