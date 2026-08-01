"""Integrate one verified batch JSON into the app content files.

Usage: python3 tools/integrate_batch.py tools/batches/batch_001.json [--commit] [--dry-run]

Steps: validate + normalize romanization -> dedupe by Thai spelling ->
assign sequential ids -> append words and example sentences to content.json ->
mirror to the Android assets -> schema-validate (reverts on failure) ->
coverage report -> optional git commit+push.
Prints a JSON summary on the last line.

Before 2026-08-02 this injected Swift literals into Vocabulary.swift and
ThaiWord.swift and gated on `swiftc -typecheck`. Both files now decode
content.json instead, so the compiler no longer sees the content at all and a
typecheck would prove nothing. The gate is `vocab_lib.validate_content`, which
mirrors ContentStore.Payload — the same shape whose mismatch is a fatalError at
app launch. It is also far cheaper: type-checking the old literals reached 18 GB
and kernel-panicked this 8 GB machine.
"""
import json
import re
import subprocess
import sys

import vocab_lib as V


def main():
    from pathlib import Path
    arg = Path(sys.argv[1])
    batch_path = arg if arg.is_absolute() else V.ROOT / arg
    do_commit = "--commit" in sys.argv
    dry = "--dry-run" in sys.argv
    batch = json.loads(batch_path.read_text(encoding="utf-8"))

    payload = V.load_content()
    existing = payload["words"]
    seen = {re.sub(r"\s", "", w["thai"]) for w in existing}
    next_id = max(w["id"] for w in existing) + 1

    accepted, skipped, rejected = [], 0, []
    for w in batch["words"]:
        w = dict(w)
        w.setdefault("examples", [])
        problems = V.validate_word(w)
        if problems:
            rejected.append({"thai": w.get("thai"), "problems": problems})
            continue
        key = re.sub(r"\s", "", w["thai"])
        if key in seen:
            skipped += 1
            continue
        seen.add(key)
        w["roman"] = V.normalize_roman(w["roman"])
        for ex in w["examples"]:
            ex["roman"] = V.normalize_roman(ex["roman"])
        w["id"] = next_id
        next_id += 1
        accepted.append(w)

    if not accepted:
        print(json.dumps({"added": 0, "skipped": skipped, "rejected": rejected,
                          "total": len(existing)}, ensure_ascii=False))
        return

    for w in accepted:
        payload["words"].append({k: w[k] for k in V.WORD_KEYS})
        if w["examples"]:
            payload["examples"][str(w["id"])] = [
                {"thai": ex["thai"], "roman": ex["roman"],
                 "en": ex["en"], "hi": ex["hi"]}
                for ex in w["examples"]
            ]

    # Validate before anything touches disk, so a bad batch needs no revert.
    problems = V.validate_content(payload)
    if problems:
        print(json.dumps({"error": "schema validation failed — nothing written",
                          "problems": problems[:10]}, ensure_ascii=False))
        sys.exit(2)

    all_words = payload["words"]
    sentences = [row["thai"]
                 for rows in payload["examples"].values()
                 for row in rows]
    gaps = V.coverage_gaps([w["thai"] for w in all_words], sentences)
    top_gaps = gaps.most_common(10)

    n = batch.get("batch", "?")
    themes = ", ".join(t["name"] for t in batch.get("themes", []))[:100]

    state = V.load_state()
    state["gap_tokens"] = {t: c for t, c in top_gaps}
    state["history"].append({"batch": n, "added": len(accepted),
                             "skipped": skipped, "total": len(all_words)})

    summary = {"batch": n, "added": len(accepted), "skipped_dupes": skipped,
               "rejected": len(rejected), "reject_detail": rejected[:5],
               "total": len(all_words), "target": state["target"],
               "gap_tokens_top": top_gaps, "dry_run": dry}

    if dry:
        print(json.dumps(summary, ensure_ascii=False))
        return

    V.save_content(payload)
    V.save_state(state)

    if do_commit:
        subprocess.run(["git", "add", str(V.CONTENT_FILE), str(V.ANDROID_CONTENT),
                        str(V.STATE_FILE), str(batch_path)],
                       cwd=V.ROOT, check=True)
        msg = (f"Vocab batch {n}: +{len(accepted)} words (total {len(all_words)}"
               f"/{state['target']}) — {themes}\n\n"
               "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>")
        subprocess.run(["git", "commit", "-m", msg], cwd=V.ROOT, check=True)
        push = subprocess.run(["git", "push"], cwd=V.ROOT, capture_output=True, text=True)
        summary["pushed"] = push.returncode == 0
        summary["commit"] = subprocess.run(["git", "rev-parse", "--short", "HEAD"],
                                           cwd=V.ROOT, capture_output=True,
                                           text=True).stdout.strip()

    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    main()
