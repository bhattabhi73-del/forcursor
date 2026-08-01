#!/usr/bin/env python3
"""Validate enriched Set A chunks and prepare inject_ready.json (max 1000)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

BATCH = Path("/tmp/thailearn_batches")
FORBIDDEN_ROM = re.compile(r"[ʉɔəɛɤ ]")
BAD_G = re.compile(r"(^|-)g(?!ng)", re.I)
DEVA = re.compile(r"^[\u0900-\u097F\s\-]+$")


def validate(items: list[dict], expected_thai: set[str]) -> list[str]:
    errs = []
    got = {w.get("thai") for w in items}
    if got != expected_thai:
        errs.append(f"thai mismatch missing={len(expected_thai-got)} extra={len(got-expected_thai)}")
    ens = []
    for i, w in enumerate(items):
        rom = w.get("romanization") or ""
        hip = w.get("hindiPronunciation") or ""
        him = w.get("hindiMeaning") or ""
        en = w.get("englishMeaning") or ""
        ex = w.get("examples") or []
        if FORBIDDEN_ROM.search(rom):
            errs.append(f"[{i}] {w.get('thai')} bad rom chars/space: {rom}")
        if BAD_G.search(rom):
            errs.append(f"[{i}] {w.get('thai')} g-for-k?: {rom}")
        if not DEVA.match(hip):
            errs.append(f"[{i}] {w.get('thai')} hindiPron not Devanagari: {hip}")
        if not DEVA.match(him):
            errs.append(f"[{i}] {w.get('thai')} hindiMeaning not Devanagari: {him}")
        if len(ex) < 2 or not isinstance(ex[0], dict) or "english" not in ex[0]:
            errs.append(f"[{i}] {w.get('thai')} need 2 example dicts")
        ens.append(en.lower())
    from collections import Counter
    for e, n in Counter(ens).items():
        if n > 1:
            errs.append(f"duplicate englishMeaning in batch: {e} x{n}")
    return errs


def main() -> None:
    merged = []
    for i in range(1, 6):
        p = BATCH / f"setA_chunk{i}.json"
        raw = BATCH / f"setA_chunk{i}_raw.json"
        if not p.exists():
            print(f"MISSING {p.name}")
            continue
        data = json.loads(p.read_text(encoding="utf-8"))
        expected = {w["thai"] for w in json.loads(raw.read_text(encoding="utf-8"))}
        errs = validate(data, expected)
        print(f"chunk{i}: {len(data)} errs={len(errs)}")
        for e in errs[:8]:
            print(" ", e)
        if errs:
            sys.exit(1)
        merged.extend(data)
    if len(merged) != 1000:
        print(f"expected 1000 got {len(merged)}")
        sys.exit(1)
    # global EN uniqueness within setA
    from collections import Counter
    dups = [e for e, n in Counter(w["englishMeaning"].lower() for w in merged).items() if n > 1]
    if dups:
        print("global EN dups", dups[:10])
        sys.exit(1)
    out = BATCH / "inject_ready.json"
    out.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"READY {out} count={len(merged)}")


if __name__ == "__main__":
    main()
