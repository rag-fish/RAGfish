# Claude Code Task — NoesisNoema hotfix #2: chunks.json is `[String]`, not `[Chunk]`

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main` (PR #99 just merged).

## Bug (UAT blocker, second one in the same import path)

After PR #99 unblocked manifest decode, the next decode step fails:

```
RAGpack Import Failed
The RAGpack chunks.json could not be read: DecodingError.typeMismatch:
expected value of type Dictionary<String, Any>. Path: [0]. Debug
description: Expected to decode Dictionary<String, Any> but found a
string instead.
```

## Root cause: pipeline shape is `[String]`, not `[Chunk]`

The pipeline writes `chunks.json` as a **flat array of chunk text**, not an array of objects. Verified in `writer/pack_writer.py` on main:

```python
chunks_json = [chunk['text'] for chunk in chunks_with_metadata]   # line ~110
# …
zf.writestr("chunks.json", json.dumps(chunks_json, …).encode('utf-8'))
```

So the actual file on disk for the Spinoza pack is shaped:

```json
["First chunk text…", "Second chunk text…", …, "406th chunk text…"]
```

The app reader (PR #98) decodes it as `[Chunk]` (array of objects with `content`, `embedding`, …) — type mismatch at `[0]`.

All chunk **metadata** (`chunk_index`, `doc_id`, `page`, `char_start`, `char_end`, `paragraph_boundaries`, plus an extra `snippet`) lives in `citations.jsonl`, **one record per chunk, keyed by `chunk_index`** that aligns with the `embeddings.npy` row. The pipeline's design is intentional: text in `chunks.json`, metadata in `citations.jsonl`, joined by row index.

This is the same shape of root cause as the indexer issue PR #99 fixed: my PR-B prompt and pipeline prompt disagreed. The pipeline's two-file split is the de-facto v1.2; the app adapts.

## Fix policy

Change the app's reader to honor the pipeline's two-file split. The semantics of "a chunk" in memory don't change — we still build `[Chunk]` for `VectorStore` — we just build it differently from the inputs.

### Changes in `Shared/RAG/RAGpackReader.swift`

In `RAGpackReader.readPack(...)`:

1. Decode `chunks.json` as `[String]` (not `[Chunk]`). Throw `.chunksMalformed("expected [String], got …")` on type mismatch.
2. Parse `citations.jsonl` FIRST when constructing chunks (it used to be a post-attach step). Build a dictionary `[Int: CitationFields]` keyed by `chunk_index`. Required fields per line: `chunk_index` (Int). Optional: `doc_id`, `page`, `char_start`, `char_end`, `paragraph_boundaries`, and any extras (e.g. `snippet`) are ignored.
3. For each text in `chunks.json`, construct a `Chunk` from:
   - `content` = the string from `chunks.json`
   - `embedding` = `embeddings[i]` (the i-th row)
   - citation fields = `citations[i]` if present, else nil/empty defaults
   - any other `Chunk` fields default to their existing defaults (whatever PR-B set)
4. Cross-check counts EXACTLY as before:
   - `chunks.count == embeddings.count` else `.chunksEmbeddingsCountMismatch(chunks: c, embeddings: e)`
   - if `citations.jsonl` exists and is non-empty, `citations.count` should equal `chunks.count`. Mismatch → `.citationsMalformed("citation count \(c) != chunks count \(n)")`. If the file is missing entirely, that's still fine (citations are optional in v1.2).
   - if a citation references a `chunk_index` outside `[0, chunks.count)`, throw `.citationsMalformed("chunk_index out of range")`.

### `Shared/RAG/Chunk.swift` adjustment (only if needed)

If `Chunk`'s current Codable conformance (additive citation fields from PR #98) implies it MUST decode as an object — fine, keep it; we are no longer decoding `Chunk` directly from `chunks.json`. If `Chunk` has a Codable init that's only used by the old reader path, leave it; do NOT remove it. Other call sites that construct `Chunk` programmatically (`Chunk(content:embedding:…)`) keep working. Touch this file ONLY if you find a hard compile error from the reader change; if you do, prefer adding a new failable initializer over modifying existing ones.

### Error types

`RAGpackImportError.chunksMalformed(underlying:)` already exists from PR #98 — reuse it. Same for `.citationsMalformed`. No new cases needed unless something genuinely doesn't fit; if it doesn't, name the new case explicitly and document why.

## Acceptance

- Add a test fixture: a small `chunks.json = ["alpha", "beta", "gamma"]`, three rows of `embeddings.npy` (mock 3×768 zeros, since the existing `NumpyReader` test path is fine), and a `citations.jsonl` with three lines keyed `chunk_index: 0..2`, doc_id `"test"`. Verify `RAGpackReader.readPack(...)` returns three `Chunk`s with `content` matching, citation fields wired, and the chunk-embedding count cross-check passes.
- Add a NEGATIVE test: same fixture but with `chunks.json = [{"text": "alpha"}, …]` — the OLD object shape. Reader MUST throw `.chunksMalformed(...)`. This locks the contract: we now expect strings, not objects.
- All 4 builds green (serial iOS; Release with `ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`).
- If the test target is still unwired, follow the same pattern as PR #99: commit the XCTest file for future wiring, and add a `#if DEBUG` smoke runnable manually.

## Scope (hard)

- Touch ONLY: `Shared/RAG/RAGpackReader.swift`, new test fixture file(s) (under `Tests/RAG/`), and at most `Shared/RAG/Chunk.swift` IF a hard compile error forces it (additive only).
- Do NOT touch: `RAGpackManifest.swift` (PR #99 just stabilized it), embedder code, `NumpyReader.swift`, `DocumentManager.swift`, UI, `project.pbxproj`.
- Pure Swift; no new dependencies.

## Commit + PR

Single commit. Branch suggestion: `fix/chunks-string-array`.
PR title: `fix(rag): chunks.json is [String], citations.jsonl carries metadata (ADR-0011 §5)`

PR body MUST include:
- The error text from the failing import (the alert message)
- The pipeline's pack_writer.py line that proves `chunks_json = [chunk['text'] …]`
- The new reader flow: chunks.json → [String] → join with citations[i] → Chunk[i]
- Confirmation that the chunk-embedding count cross-check is preserved
- Test results (positive + negative)
- 4-build matrix
- Any orthogonal findings noted but not fixed

Do NOT merge — Taka merges, then re-imports the EXISTING Spinoza zip (still no re-embedding) to continue UAT.

## Orthogonal (report only, do NOT fix)

If `chunks.json`'s old object shape is referenced anywhere in the codebase outside `RAGpackReader.swift` (e.g., a writer or a test fixture), note it. The app is a CONSUMER of v1.2 packs and does not produce them; if any producer-side code still emits the object shape, it's dead code from before PR #98 and can be cleaned up in a follow-up.

## Report back

- Diff per file (size of change)
- Test output (positive + negative — paste both)
- 4-build matrix
- PR number
