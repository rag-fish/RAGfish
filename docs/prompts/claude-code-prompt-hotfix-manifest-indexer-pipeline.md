# Claude Code Task — Pipeline: name the ragpack zip after the source document

Local repo: `/Users/raskolnikoff/PycharmProjects/noesisnoema-pipeline`.

**FIRST — fix the stale clone (this repo's local has been stale three times in this series):**

```bash
git fetch origin
git checkout main
git pull
```

Verify `git log --oneline -1` shows the latest main HEAD before branching.

**main is PROTECTED** — direct push fails with an opaque "Tool execution failed" (memory note #7). Branch + PR, e.g. `feat/notebook-zip-naming`.

## Change

In `notebooks/build_ragpack_v1_2.ipynb`, the Zip cell currently archives to `output.zip` — opaque when the user accumulates packs on disk. Derive the zip name from the first source file's stem, sanitized:

```python
import re
stem = source_files[0].stem if source_files else OUTPUT_DIR.name
safe = re.sub(r"[^A-Za-z0-9._-]", "_", stem)[:40].rstrip("._-") or OUTPUT_DIR.name
zip_base = OUTPUT_DIR.parent / f"{safe}_ragpack"
```

Then keep the rest of the cell logic identical: `zip_path = Path(shutil.make_archive(str(zip_base), "zip", str(OUTPUT_DIR)))` etc. Examples:
- `2015.263056.Ethics_text.pdf` → `2015.263056.Ethics_text_ragpack.zip`
- An absurdly long unicode title → sanitized + truncated to 40 chars → `…_ragpack.zip`

The 40-char cap + character whitelist (`A-Za-z0-9._-`) guard against very long, unicode-heavy, or shell-unfriendly PDF names. The `.rstrip("._-")` keeps the final filename tidy. The `or OUTPUT_DIR.name` fallback covers the edge case where sanitization eats the whole stem.

Also update the Zip cell's markdown header one-liner to reflect the new naming (e.g. "Archives the output directory into a `<source-name>_ragpack.zip`…").

The `source_files` variable already exists in the build cell — re-derive it at the top of the Zip cell (same guarded `glob` already used in the existing build/inspect cells) so the Zip cell is self-contained even after a runtime restart, BUT still gate the whole thing on the existing `if "result" not in globals(): print("No build result yet...")` guard from PR #18. Put the new naming logic inside the `else` branch.

## Scope (hard)

- Touch ONLY `notebooks/build_ragpack_v1_2.ipynb`. No pipeline code, no schemas, no README, no other notebooks.
- Keep the notebook valid JSON / nbformat 4.4 (verify with `python -c "import json; json.load(open('notebooks/build_ragpack_v1_2.ipynb'))"`).
- Touch ONLY the Zip cell + its preceding markdown header. All other cells byte-identical.

## Commit + PR

Single commit. PR title: `feat(notebook): name the ragpack zip after the source document`

PR body MUST include:
- Why (Taka's UX request: `output.zip` is opaque)
- The sanitization rules (40-char cap + whitelist + rstrip + fallback) and one concrete example output
- JSON validity check output
- Confirmation that all other cells are byte-identical
- Any orthogonal findings noted but not fixed

Do NOT merge — Taka merges.

## Report back

- Diff (which 2 cells, paste new source of the Zip code cell)
- JSON validity check output
- PR number
