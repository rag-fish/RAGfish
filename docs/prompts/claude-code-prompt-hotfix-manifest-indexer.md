# Claude Code Task — Hotfix: manifest indexer decode failure + ragpack zip naming

Two small tasks in two repos. Separate branches/PRs per repo.

## Task 1 — NoesisNoema: tolerant decoding of informational manifest blocks (UAT BLOCKER)

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main`.

### Bug

The first real v1.2 pack import (Spinoza Ethica, 406 chunks) failed at decode:

```
DecodingError.keyNotFound: Key 'method' not found in keyed decoding container. Path: indexer.
```

The pipeline's actual v1.2 manifest `indexer` block is:

```json
"indexer": { "document_count": 1, "chunk_count": 406, "timestamp": "2026-06-11T06:18:52Z" }
```

while the app's `RAGpackManifest.IndexerInfo` (PR #98) requires `method` (and `dimension`). This was a **contract inconsistency between the two implementation prompts** (the app-side PR-B prompt specified `indexer: {method, dimension}`; the pipeline prompt said "lift the v1.1 schema" whose indexer shape is document_count/chunk_count/timestamp). Both implementations followed their prompts faithfully — the prompts disagreed. The pipeline's shape is the de-facto v1.2; the app adapts.

### Fix policy (ADR-0011 spirit)

Be strict ONLY where identity/correctness lives. UNCHANGED and still strictly required + validated: `pack_version`, the entire `embedder` block (`embedding_model`, `embedding_dimension`, `model_hash`, `dtype`, `pooling`, `l2_normalized`), and `files.chunks` + `files.embeddings`. Everything informational decodes tolerantly:

- `indexer`: make the property optional (`let indexer: IndexerInfo?`) AND make all its fields optional, covering BOTH shapes: `method: String?`, `dimension: Int?`, `documentCount: Int?`, `chunkCount: Int?`, `timestamp: String?` (snake_case CodingKeys).
- `chunker`: make all fields optional too (`ChunkerInfo` stays a required property if trivial, but no required fields inside). Today's shapes happen to match; don't rely on it.
- `stats`: already optional; leave as is.
- `files.citations`: stays optional. Unknown nested keys (e.g. `files.metadata`) are already ignored by Codable — no action.
- Do NOT touch `validate(againstCurrentEmbedder:)` semantics for embedder/pack_version.

### Acceptance

- Add a unit/smoke test that decodes the REAL manifest from Taka's pack (fixture below) and passes validation up to the fingerprint check (`0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6` — it should MATCH the current embedder).
- All 4 builds green (serial iOS; Release with ARCHS=arm64 ONLY_ACTIVE_ARCH=NO).
- PR body documents the contract fix and pastes the fixture.

Fixture (real manifest from the failing pack):

```json
{
  "pack_version": "1.2",
  "pack_id": "pack-9edb42ffa01d5da2c388d03f42562c70",
  "created_at": "2026-06-11T06:18:52Z",
  "chunker": { "method": "token_based", "chunk_size": 512, "overlap": 50, "tokenizer_name": "gpt2", "preserve_sentences": false, "config_hash": "a02e1eef8320ac74aae10efdfaaa0d703e2af4fccea685f355ea85f7918542ba" },
  "embedder": { "embedding_model": "nomic-embed-text-v1.5.Q5_K_M.gguf", "embedding_version": "0.3.28", "embedding_dimension": 768, "model_hash": "0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6", "dtype": "float32", "pooling": "mean", "l2_normalized": true, "name": "nomic-embed-text-v1.5.Q5_K_M.gguf", "version": "0.3.28", "dimensions": 768, "runtime": "llama.cpp" },
  "indexer": { "document_count": 1, "chunk_count": 406, "timestamp": "2026-06-11T06:18:52Z" },
  "files": { "chunks": "chunks.json", "embeddings": "embeddings.npy", "citations": "citations.jsonl", "metadata": { "embeddings_csv": "embeddings.csv", "manifest": "manifest.json" } },
  "source_documents": [ { "doc_id": "2015.263056.Ethics_text.txt", "title": "2015.263056.Ethics_text", "path": "/content/input/2015.263056.Ethics_text.txt", "source_hash": "c66d146a7faaa5bdf203aa5a6a2f38494bd4ca58063071cfc5e38847b34a9ed2", "char_count": 566764 } ]
}
```

Note `source_documents` is a top-level key the app's struct doesn't declare — Codable ignores it; no action needed. PR title: `fix(rag): tolerant decode for informational manifest blocks (indexer/chunker)`.

### Orthogonal (report only, do NOT fix)

The pipeline manifest carries v1.1 residue: `files.metadata.embeddings_csv` and duplicated embedder fields (`name`/`version`/`dimensions` alongside the canonical ones). Harmless to the app; flag for a later pipeline cleanup PR.

## Task 2 — noesisnoema-pipeline: name the ragpack zip after the source document

Local repo: `/Users/raskolnikoff/PycharmProjects/noesisnoema-pipeline`. **main is PROTECTED — branch + PR** (e.g. `feat/notebook-zip-naming`). Run `git fetch origin && git checkout main && git pull` FIRST (this clone has been stale three times).

In `notebooks/build_ragpack_v1_2.ipynb`, the Zip cell archives to `output.zip`. Derive the name from the first source file instead:

```python
import re
stem = source_files[0].stem if source_files else OUTPUT_DIR.name
safe = re.sub(r"[^A-Za-z0-9._-]", "_", stem)[:40].rstrip("._-")
zip_base = OUTPUT_DIR.parent / f"{safe}_ragpack"
```

Keep the rest of the cell logic identical (`shutil.make_archive(str(zip_base), "zip", str(OUTPUT_DIR))` etc.). Result example: `2015.263056.Ethics_text_ragpack.zip`. The 40-char cap + sanitization guards against very long or unicode-heavy PDF names. Update the Zip markdown cell's one-liner accordingly. Notebook must stay valid JSON / nbformat 4.4; touch only these two cells. PR title: `feat(notebook): name the ragpack zip after the source document`.

## Report back

Per task: diff summary, build / JSON-validity results, fixture-decode test output (Task 1), PR numbers.
