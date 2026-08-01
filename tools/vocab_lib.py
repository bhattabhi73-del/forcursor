"""Shared helpers for the Thai Learn 10k-word content pipeline.

Parses the Swift content files, runs the greedy-segmentation sentence
coverage check (standing rule: every Thai word used in an example sentence
must itself be a dictionary entry), and manages pipeline state.
"""
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IOS = ROOT / "ThaiWallpaperLearn"
VOCAB_FILE = IOS / "Shared" / "Vocabulary.swift"
EXTRAS_FILE = IOS / "Shared" / "ThaiWord.swift"
ANDROID_JSON = ROOT / "android" / "app" / "src" / "main" / "assets" / "vocabulary.json"
STATE_FILE = Path(__file__).resolve().parent / "pipeline_state.json"
BATCH_DIR = Path(__file__).resolve().parent / "batches"

ENTRY_RE = re.compile(
    r'ThaiWord\(id:\s*(\d+),\s*thai:\s*"([^"]*)",\s*romanization:\s*"([^"]*)",'
    r'\s*hindiPronunciation:\s*"([^"]*)",\s*englishMeaning:\s*"([^"]*)",'
    r'\s*hindiMeaning:\s*"([^"]*)",\s*category:\s*"([^"]*)"\)'
)
EXAMPLE_RE = re.compile(r'WordExample\(thai:\s*"([^"]*)"')

FIELDS = ("thai", "roman", "hindiPron", "en", "hi", "category")


def load_words():
    """All ThaiWord entries currently in Vocabulary.swift, in file order."""
    text = VOCAB_FILE.read_text(encoding="utf-8")
    words = []
    for m in ENTRY_RE.finditer(text):
        words.append({
            "id": int(m.group(1)), "thai": m.group(2), "roman": m.group(3),
            "hindiPron": m.group(4), "en": m.group(5), "hi": m.group(6),
            "category": m.group(7),
        })
    return words


def load_sentence_thai():
    """Thai text of every example sentence in ThaiWord.swift."""
    text = EXTRAS_FILE.read_text(encoding="utf-8")
    return [m.group(1) for m in EXAMPLE_RE.finditer(text)]


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
