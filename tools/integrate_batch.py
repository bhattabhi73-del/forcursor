"""Integrate one verified batch JSON into the app content files.

Usage: python3 tools/integrate_batch.py tools/batches/batch_001.json [--commit] [--dry-run]

Steps: validate + normalize romanization -> dedupe by Thai spelling ->
assign sequential ids -> append Swift literals to the current chunk in
Vocabulary.swift (new chunk every ~500 words) and example sentences to
ThaiWord.swift -> regenerate android vocabulary.json -> swiftc typecheck
(reverts on failure) -> coverage report -> optional git commit+push.
Prints a JSON summary on the last line.
"""
import json
import re
import shutil
import subprocess
import sys

import vocab_lib as V

CHUNK_LIMIT = 500


def find_chunk_spans(lines, decl_re):
    """[(chunk_index, decl_line, close_line)] for literal chunks; close is the
    line that is exactly '    ]'."""
    spans = []
    for i, line in enumerate(lines):
        m = decl_re.match(line)
        if m:
            for j in range(i + 1, len(lines)):
                if lines[j] == "    ]":
                    spans.append((int(m.group(1)), i, j))
                    break
    return spans


def swift_word_line(w):
    return (f'        ThaiWord(id: {w["id"]}, thai: "{w["thai"]}", '
            f'romanization: "{w["roman"]}", hindiPronunciation: "{w["hindiPron"]}", '
            f'englishMeaning: "{w["en"]}", hindiMeaning: "{w["hi"]}", '
            f'category: "{w["category"]}"),')


def swift_example_block(w):
    out = [f'        {w["id"]}: [']
    for ex in w["examples"]:
        out.append(f'            WordExample(thai: "{ex["thai"]}", '
                   f'romanization: "{ex["roman"]}", english: "{ex["en"]}", '
                   f'hindi: "{ex["hi"]}"),')
    out.append("        ],")
    return out


def inject(path, decl_re, decl_template, new_lines, count_re, header,
           rebuild_combiner):
    """Append new_lines into the last chunk of `path`, opening a new chunk when
    the current one is full. rebuild_combiner(lines, indices) fixes the line
    that merges the chunks."""
    text = path.read_text(encoding="utf-8")
    lines = text.split("\n")
    spans = find_chunk_spans(lines, decl_re)
    if not spans:
        raise SystemExit(f"no content chunks found in {path.name}")
    idx, decl_i, close_i = spans[-1]
    body = "\n".join(lines[decl_i:close_i])
    used = len(count_re.findall(body))

    if used >= CHUNK_LIMIT:
        anchor = next(i for i, l in enumerate(lines) if "// CHUNKS:" in l)
        idx += 1
        block = ["    " + decl_template.format(n=idx)] + [header] + new_lines + ["    ]", ""]
        lines[anchor:anchor] = block
    else:
        lines[close_i:close_i] = [header] + new_lines

    indices = [s[0] for s in find_chunk_spans("\n".join(lines).split("\n"), decl_re)]
    if idx not in indices:
        indices.append(idx)
    rebuild_combiner(lines, sorted(set(indices)))
    path.write_text("\n".join(lines), encoding="utf-8")


def rebuild_all_line(lines, indices):
    joined = " + ".join(f"words{i}" for i in indices)
    for i, l in enumerate(lines):
        if l.startswith("    static let all: [ThaiWord] ="):
            lines[i] = f"    static let all: [ThaiWord] = {joined}"
            return
    raise SystemExit("could not find `static let all` line")


def rebuild_chunks_line(lines, indices):
    joined = ", ".join(f"examples{i}" for i in indices)
    for i, l in enumerate(lines):
        if l.startswith("    private static let exampleChunks:"):
            lines[i] = ("    private static let exampleChunks: "
                        f"[[Int: [WordExample]]] = [{joined}]")
            return
    raise SystemExit("could not find exampleChunks line")


def typecheck():
    sdk = subprocess.run(["xcrun", "--show-sdk-path", "--sdk", "iphonesimulator"],
                         capture_output=True, text=True).stdout.strip()
    r = subprocess.run(
        ["xcrun", "swiftc", "-typecheck", "-sdk", sdk,
         "-target", "arm64-apple-ios17.0-simulator",
         str(V.EXTRAS_FILE), str(V.VOCAB_FILE)],
        capture_output=True, text=True)
    return r.returncode == 0, r.stderr[-3000:]


def main():
    from pathlib import Path
    arg = Path(sys.argv[1])
    batch_path = arg if arg.is_absolute() else V.ROOT / arg
    do_commit = "--commit" in sys.argv
    dry = "--dry-run" in sys.argv
    batch = json.loads(batch_path.read_text(encoding="utf-8"))

    existing = V.load_words()
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

    backup_dir = V.STATE_FILE.parent / ".backup"
    backup_dir.mkdir(exist_ok=True)
    for f in (V.VOCAB_FILE, V.EXTRAS_FILE):
        shutil.copy(f, backup_dir / f.name)

    n = batch.get("batch", "?")
    themes = ", ".join(t["name"] for t in batch.get("themes", []))[:100]
    inject(V.VOCAB_FILE,
           re.compile(r"\s*private static let words(\d+): \[ThaiWord\] = \["),
           "private static let words{n}: [ThaiWord] = [",
           [swift_word_line(w) for w in accepted],
           V.ENTRY_RE, f"        // MARK: Batch {n}: {themes}",
           rebuild_all_line)

    with_examples = [w for w in accepted if w["examples"]]
    if with_examples:
        ex_lines = []
        for w in with_examples:
            ex_lines.extend(swift_example_block(w))
        inject(V.EXTRAS_FILE,
               re.compile(r"\s*private static let examples(\d+): \[Int: \[WordExample\]\] = \["),
               "private static let examples{n}: [Int: [WordExample]] = [",
               ex_lines,
               re.compile(r"^\s{8}\d+: \[", re.M),
               f"        // Batch {n}", rebuild_chunks_line)

    all_words = V.load_words()
    V.ANDROID_JSON.write_text(
        json.dumps([{k: w[k] for k in ("id", "thai", "roman", "hindiPron", "en", "hi", "category")}
                    for w in all_words], ensure_ascii=False),
        encoding="utf-8")

    ok, err = typecheck()
    if not ok:
        for f in (V.VOCAB_FILE, V.EXTRAS_FILE):
            shutil.copy(backup_dir / f.name, f)
        V.ANDROID_JSON.write_text(
            json.dumps([{k: w[k] for k in ("id", "thai", "roman", "hindiPron", "en", "hi", "category")}
                        for w in existing], ensure_ascii=False), encoding="utf-8")
        print(json.dumps({"error": "typecheck failed — batch reverted",
                          "stderr": err}, ensure_ascii=False))
        sys.exit(2)

    gaps = V.coverage_gaps([w["thai"] for w in all_words], V.load_sentence_thai())
    top_gaps = gaps.most_common(10)

    state = V.load_state()
    state["gap_tokens"] = {t: c for t, c in top_gaps}
    state["history"].append({"batch": n, "added": len(accepted),
                             "skipped": skipped, "total": len(all_words)})
    V.save_state(state)

    summary = {"batch": n, "added": len(accepted), "skipped_dupes": skipped,
               "rejected": len(rejected), "reject_detail": rejected[:5],
               "total": len(all_words), "target": state["target"],
               "gap_tokens_top": top_gaps, "dry_run": dry}

    if dry:
        for f in (V.VOCAB_FILE, V.EXTRAS_FILE):
            shutil.copy(backup_dir / f.name, f)
        V.ANDROID_JSON.write_text(
            json.dumps([{k: w[k] for k in ("id", "thai", "roman", "hindiPron", "en", "hi", "category")}
                        for w in existing], ensure_ascii=False), encoding="utf-8")
    elif do_commit:
        subprocess.run(["git", "add", str(V.VOCAB_FILE), str(V.EXTRAS_FILE),
                        str(V.ANDROID_JSON), str(V.STATE_FILE), str(batch_path)],
                       cwd=V.ROOT, check=True)
        msg = (f"Vocab batch {n}: +{len(accepted)} words (total {len(all_words)}"
               f"/{state['target']}) — {themes}\n\n"
               "Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>\n"
               "Claude-Session: https://claude.ai/code/session_01F89wc1XD4uEZ9Cb2Um3bGK")
        subprocess.run(["git", "commit", "-m", msg], cwd=V.ROOT, check=True)
        push = subprocess.run(["git", "push"], cwd=V.ROOT, capture_output=True, text=True)
        summary["pushed"] = push.returncode == 0
        summary["commit"] = subprocess.run(["git", "rev-parse", "--short", "HEAD"],
                                           cwd=V.ROOT, capture_output=True,
                                           text=True).stdout.strip()

    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    main()
