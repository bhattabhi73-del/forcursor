#!/usr/bin/env python3
"""Merge /tmp/thailearn_batches/batch*.json into Vocabulary.swift + ThaiWord.swift.

Adds a new wordsN chunk and examplesN chunk with sequential ids after current max.
Dedupe by Thai spelling against existing vocab and across batches.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOCAB = ROOT / "Shared" / "Vocabulary.swift"
THAIWORD = ROOT / "Shared" / "ThaiWord.swift"
BATCH_DIR = Path("/tmp/thailearn_batches")


def load_existing_thai(text: str) -> set[str]:
    return set(re.findall(r'thai:\s*"([^"]+)"', text))


def max_id(text: str) -> int:
    ids = [int(x) for x in re.findall(r"ThaiWord\(id:\s*(\d+)", text)]
    return max(ids) if ids else 0


def next_chunk_index(text: str, prefix: str) -> int:
    nums = [int(x) for x in re.findall(rf"{prefix}(\d+)", text)]
    return (max(nums) + 1) if nums else 0


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def word_literal(w: dict, wid: int) -> str:
    return (
        f'        ThaiWord(id: {wid}, thai: "{esc(w["thai"])}", '
        f'romanization: "{esc(w["romanization"])}", '
        f'hindiPronunciation: "{esc(w["hindiPronunciation"])}", '
        f'englishMeaning: "{esc(w["englishMeaning"])}", '
        f'hindiMeaning: "{esc(w["hindiMeaning"])}", '
        f'category: "{esc(w["category"])}"),'
    )


def examples_literal(wid: int, examples: list, word: dict | None = None) -> str:
    lines = [f"        {wid}: ["]
    cleaned = []
    for ex in examples[:2]:
        if isinstance(ex, dict) and "thai" in ex and "english" in ex:
            cleaned.append(ex)
    if len(cleaned) < 2 and word:
        thai = word["thai"]
        rom = word["romanization"]
        en = word["englishMeaning"].split("/")[0].strip()
        hi = word["hindiMeaning"].split("/")[0].strip()
        cleaned = [
            {"thai": f"ผมชอบ{thai}", "romanization": f"phǒm chôp {rom}", "english": f"I like {en}", "hindi": f"मुझे {hi} पसंद है"},
            {"thai": f"นี่คือ{thai}", "romanization": f"nîi khuue {rom}", "english": f"This is {en}", "hindi": f"यह {hi} है"},
        ]
    for ex in cleaned[:2]:
        lines.append(
            "            WordExample("
            f'thai: "{esc(ex["thai"])}", '
            f'romanization: "{esc(ex["romanization"])}", '
            f'english: "{esc(ex["english"])}", '
            f'hindi: "{esc(ex["hindi"])}"),'
        )
    lines.append("        ],")
    return "\n".join(lines)


def compound_literal(wid: int, note: str) -> str:
    return f'        {wid}: "{esc(note)}",'


def emoji_literal(wid: int, emoji: str) -> str:
    return f'        {wid}: "{esc(emoji)}",'


def load_batches(files: list[Path] | None = None) -> list[dict]:
    if files:
        paths = files
    else:
        prefer = (
            sorted(BATCH_DIR.glob("inject_ready.json"))
            + sorted(BATCH_DIR.glob("cycle*.json"))
            + sorted(BATCH_DIR.glob("quality_seed.json"))
            + sorted(BATCH_DIR.glob("hq_*.json"))
        )
        paths = prefer if prefer else sorted(BATCH_DIR.glob("batch*.json"))
    items: list[dict] = []
    for f in paths:
        data = json.loads(f.read_text(encoding="utf-8"))
        if not isinstance(data, list):
            raise SystemExit(f"{f} is not a JSON array")
        items.extend(data)
        print(f"loaded {f.name}: {len(data)}")
    return items


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    cap = 200
    for a in sys.argv[1:]:
        if a.startswith("--cap="):
            cap = int(a.split("=", 1)[1])
    files = [Path(a) if Path(a).is_absolute() else BATCH_DIR / a for a in args] if args else None
    batches = load_batches(files)
    if not batches:
        raise SystemExit("No batch JSON files found in /tmp/thailearn_batches")

    vocab_text = VOCAB.read_text(encoding="utf-8")
    tw_text = THAIWORD.read_text(encoding="utf-8")
    existing = load_existing_thai(vocab_text)
    start_id = max_id(vocab_text) + 1

    accepted: list[tuple[int, dict]] = []
    seen = set(existing)
    skipped = 0
    for w in batches:
        thai = w.get("thai", "").strip()
        if not thai or thai in seen:
            skipped += 1
            continue
        if not all(k in w for k in ("romanization", "hindiPronunciation", "englishMeaning", "hindiMeaning", "category")):
            skipped += 1
            continue
        ex = w.get("examples") or []
        if len(ex) < 2:
            skipped += 1
            continue
        seen.add(thai)
        wid = start_id + len(accepted)
        accepted.append((wid, w))

    if not accepted:
        raise SystemExit("Nothing to inject after dedupe")

    accepted = accepted[:cap]
    chunk_i = next_chunk_index(vocab_text, "words")
    # Prefer words2 if words0+words1 exist
    if "words1" in vocab_text and chunk_i < 2:
        chunk_i = 2

    word_lines = "\n".join(word_literal(w, wid) for wid, w in accepted)
    words_block = f"\n    private static let words{chunk_i}: [ThaiWord] = [\n{word_lines}\n    ]\n"

    # Insert words chunk before // CHUNKS comment or before static let all
    marker = "    // CHUNKS: word batches"
    if marker not in vocab_text:
        marker = "    static let all: [ThaiWord]"
        vocab_text = vocab_text.replace(marker, words_block + "\n" + marker, 1)
    else:
        vocab_text = vocab_text.replace(marker, words_block + "\n" + marker, 1)

    # Update all = words0 + words1 + ...
    all_pat = re.compile(r"static let all: \[ThaiWord\] = ([^\n]+)")
    m = all_pat.search(vocab_text)
    if not m:
        raise SystemExit("Could not find static let all")
    parts = [p.strip() for p in m.group(1).split("+")]
    new_name = f"words{chunk_i}"
    if new_name not in parts:
        parts.append(new_name)
    vocab_text = all_pat.sub(f"static let all: [ThaiWord] = {' + '.join(parts)}", vocab_text, count=1)
    VOCAB.write_text(vocab_text, encoding="utf-8")

    # Examples chunk
    ex_i = next_chunk_index(tw_text, "examples")
    if "examples1" in tw_text and ex_i < 2:
        ex_i = 2
    ex_body = "\n".join(examples_literal(wid, w["examples"], w) for wid, w in accepted)
    ex_block = f"\n    private static let examples{ex_i}: [Int: [WordExample]] = [\n{ex_body}\n    ]\n"

    ex_marker = "    // CHUNKS: sentence batches"
    if ex_marker not in tw_text:
        ex_marker = "    private static let exampleChunks"
        tw_text = tw_text.replace(ex_marker, ex_block + "\n" + ex_marker, 1)
    else:
        tw_text = tw_text.replace(ex_marker, ex_block + "\n" + ex_marker, 1)

    chunk_pat = re.compile(
        r"private static let exampleChunks: \[\[Int: \[WordExample\]\]\] = \[([^\]]*)\]"
    )
    cm = chunk_pat.search(tw_text)
    if not cm:
        raise SystemExit("Could not find exampleChunks")
    names = [x.strip() for x in cm.group(1).split(",") if x.strip()]
    new_ex = f"examples{ex_i}"
    if new_ex not in names:
        names.append(new_ex)
    tw_text = chunk_pat.sub(
        "private static let exampleChunks: [[Int: [WordExample]]] = [" + ", ".join(names) + "]",
        tw_text,
        count=1,
    )

    # Compounds + emojis append before closing of their dicts if present
    compounds = [(wid, w["compound"]) for wid, w in accepted if w.get("compound")]
    emojis = [(wid, w["emoji"]) for wid, w in accepted if w.get("emoji")]

    if compounds:
        comp_lines = "\n".join(compound_literal(wid, note) for wid, note in compounds)
        # Insert before the closing of compounds dict — find last entry pattern near end of compounds
        comp_close = re.search(
            r"(private static let compounds: \[Int: String\] = \[)(.*?)(\n    \])",
            tw_text,
            re.S,
        )
        if comp_close:
            tw_text = (
                tw_text[: comp_close.end(2)]
                + "\n"
                + comp_lines
                + tw_text[comp_close.end(2) :]
            )

    if emojis:
        emoji_lines = "\n".join(emoji_literal(wid, e) for wid, e in emojis)
        # emojis dict may be empty [:]
        tw_text = tw_text.replace(
            "private static let emojis: [Int: String] = [:]",
            "private static let emojis: [Int: String] = [\n"
            + emoji_lines
            + "\n    ]",
            1,
        )
        if "private static let emojis: [Int: String] = [" in tw_text and "emojis: [Int: String] = [:" not in tw_text:
            # already non-empty — append before its closing
            em = re.search(
                r"(private static let emojis: \[Int: String\] = \[)(.*?)(\n    \])",
                tw_text,
                re.S,
            )
            if em and emoji_lines not in em.group(2):
                tw_text = tw_text[: em.end(2)] + "\n" + emoji_lines + tw_text[em.end(2) :]

    THAIWORD.write_text(tw_text, encoding="utf-8")

    print(
        json.dumps(
            {
                "injected": len(accepted),
                "skipped": skipped,
                "id_range": [accepted[0][0], accepted[-1][0]],
                "words_chunk": f"words{chunk_i}",
                "examples_chunk": f"examples{ex_i}",
                "compounds": len(compounds),
                "emojis": len(emojis),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
