"""Shared helpers for the Thai Learn 10k-word content pipeline.

Reads and writes `content.json` — the single source of truth for both apps
since the 2026-08-02 migration (commit 0c672d5) took the word list out of
Swift literals. Also runs the greedy-segmentation sentence coverage check
(standing rule: every Thai word used in an example sentence must itself be a
dictionary entry) and manages pipeline state.
"""
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IOS = ROOT / "ThaiWallpaperLearn"
CONTENT_FILE = IOS / "Shared" / "content.json"
ANDROID_DIR = ROOT / "android" / "app" / "src" / "main" / "assets"
ANDROID_CONTENT = ANDROID_DIR / "content.json"
STATE_FILE = Path(__file__).resolve().parent / "pipeline_state.json"
BATCH_DIR = Path(__file__).resolve().parent / "batches"

FIELDS = ("thai", "roman", "hindiPron", "en", "hi", "category")
WORD_KEYS = ("id",) + FIELDS

# Mirrors ContentStore.Payload in Vocabulary.swift. A mismatch here is a
# fatalError at app launch, so this is the gate that replaced the old swiftc
# typecheck — the content is no longer Swift, so the compiler cannot see it.
ROW_SCHEMA = {
    "examples": ("thai", "roman", "en", "hi"),
    "forms": ("thai", "roman", "en", "hi", "note"),
}

# The More tab's flat lists — not keyed by word id, so they are checked
# separately from the per-word sections above.
LIST_SCHEMA = {
    "slang": ("thai", "roman", "meaning", "hindi", "note"),
    "cousins": ("thai", "roman", "meaning", "hindi", "note"),
    "opposites": ("thaiA", "romanA", "meaningA", "hindiA",
                  "thaiB", "romanB", "meaningB", "hindiB", "note"),
    "similars": ("thaiA", "romanA", "meaningA", "hindiA",
                 "thaiB", "romanB", "meaningB", "hindiB", "note"),
    "facts": ("title", "body"),
}


def load_content():
    """The whole content.json payload."""
    return json.loads(CONTENT_FILE.read_text(encoding="utf-8"))


def save_content(payload):
    """Write the payload to every destination that consumes it.

    Both apps read this same file — iOS via ContentStore, Android via the
    Content object in ThaiWord.kt. There is deliberately no second Android
    format: the old flat `vocabulary.json` was what let Android drift to 1,046
    words behind iOS, so it was deleted rather than kept in sync.
    """
    blob = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    for dest in (CONTENT_FILE, ANDROID_CONTENT):
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(blob, encoding="utf-8")


def validate_content(payload):
    """Problems that would make ContentStore.Payload fail to decode."""
    problems = []
    for key in ("version", "words", "examples", "forms", "similar",
                "compounds", "emoji", *LIST_SCHEMA):
        if key not in payload:
            problems.append(f"missing top-level key {key}")
    if problems:
        return problems

    for section, keys in LIST_SCHEMA.items():
        for i, row in enumerate(payload[section]):
            bad = [k for k in keys if not isinstance(row.get(k), str)]
            if bad:
                problems.append(f"{section}[{i}] missing/non-string {bad}")

    ids = []
    for w in payload["words"]:
        missing = [k for k in WORD_KEYS if k not in w]
        if missing:
            problems.append(f"word {w.get('thai', '?')} missing {missing}")
            continue
        if any(not isinstance(w[f], str) for f in FIELDS):
            problems.append(f"word {w['thai']} has a non-string field")
        # Skip a malformed id rather than collecting it — the ordering checks
        # below would raise TypeError comparing it against the ints, and a
        # validator that crashes reports nothing at all.
        if not isinstance(w["id"], int) or isinstance(w["id"], bool):
            problems.append(f"word {w['thai']} has non-int id {w['id']!r}")
            continue
        ids.append(w["id"])

    if len(ids) != len(set(ids)):
        problems.append("duplicate word ids")
    if ids and sorted(ids) != list(range(min(ids), max(ids) + 1)):
        problems.append("gaps in id sequence")
    thais = [w.get("thai") for w in payload["words"]]
    if len(thais) != len(set(thais)):
        problems.append("duplicate thai spellings")

    known = set(ids)
    for section, keys in ROW_SCHEMA.items():
        for wid, rows in payload[section].items():
            if not wid.isdigit() or int(wid) not in known:
                problems.append(f"{section} key {wid} is not a known word id")
            for row in rows:
                bad = [k for k in keys if not isinstance(row.get(k), str)]
                if bad:
                    problems.append(f"{section}[{wid}] row missing/non-string {bad}")
    for section in ("compounds", "emoji"):
        for wid, val in payload[section].items():
            if not wid.isdigit() or int(wid) not in known:
                problems.append(f"{section} key {wid} is not a known word id")
            elif not isinstance(val, str):
                problems.append(f"{section}[{wid}] is not a string")
    for wid, val in payload["similar"].items():
        if not isinstance(val, list) or any(not isinstance(x, int) for x in val):
            problems.append(f"similar[{wid}] is not a list of ints")

    return problems


def load_words():
    """All word entries, in file order."""
    return load_content()["words"]


def load_sentence_thai():
    """Thai text of every example sentence."""
    return [row["thai"]
            for rows in load_content()["examples"].values()
            for row in rows]


_STRIP_RE = re.compile(r'[\s!?.,;:()"\'‘’“”0-9๐-๙]')


def coverage_gaps(vocab_thai, sentences):
    """Greedy longest-match segmentation of each sentence against the vocab.

    Returns a Counter of unmatched substrings (gap tokens).
    """
    vocab = {_STRIP_RE.sub("", w) for w in vocab_thai if _STRIP_RE.sub("", w)}
    max_len = max((len(w) for w in vocab), default=1)
    gaps = Counter()
    for sent in sentences:
        s = _STRIP_RE.sub("", sent)
        i, run = 0, ""
        while i < len(s):
            matched = 0
            for length in range(min(max_len, len(s) - i), 0, -1):
                if s[i:i + length] in vocab:
                    matched = length
                    break
            if matched:
                if run:
                    gaps[run] += 1
                    run = ""
                i += matched
            else:
                run += s[i]
                i += 1
        if run:
            gaps[run] += 1
    return gaps


def load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    return {
        "target": 10000,
        "batch": 1,
        "theme_cursor": 0,
        "words_per_theme": 30,
        "gap_tokens": {},
        "history": [],
    }


def save_state(state):
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2),
                          encoding="utf-8")


def normalize_roman(roman):
    """House romanization style: syllable-initial g→k, dt→t, bp→p."""
    parts = re.split(r"([-\s]+)", roman)
    out = []
    for p in parts:
        if re.fullmatch(r"[-\s]+", p) or not p:
            out.append(p)
            continue
        if p.startswith("bp"):
            p = "p" + p[2:]
        elif p.startswith("dt"):
            p = "t" + p[2:]
        elif p.startswith("g") and not p.startswith("ng"):
            p = "k" + p[1:]
        out.append(p)
    return "".join(out)


THAI_RE = re.compile(r'^[฀-๿\s]+$')
THAI_SENT_RE = re.compile(r'^[฀-๿\s!?.,]+$')
DEVA_RE = re.compile(r'^[ऀ-ॿ\s\-]+$')


def validate_word(w):
    """Returns a list of problems; empty list = valid."""
    problems = []
    for f in FIELDS:
        v = w.get(f)
        if not isinstance(v, str) or not v.strip():
            problems.append(f"missing field {f}")
        elif '"' in v or "\\" in v:
            problems.append(f"illegal quote/backslash in {f}")
    if not problems:
        if not THAI_RE.fullmatch(w["thai"]):
            problems.append("thai field is not pure Thai script")
        if not DEVA_RE.fullmatch(w["hindiPron"]):
            problems.append("hindiPron is not Devanagari")
    for ex in w.get("examples", []):
        for f in ("thai", "roman", "en", "hi"):
            v = ex.get(f)
            if not isinstance(v, str) or not v.strip():
                problems.append(f"example missing {f}")
            elif '"' in v or "\\" in v:
                problems.append(f"illegal quote/backslash in example {f}")
    return problems
