# Claude Code Task — NoesisNoema hotfix: tolerant decode for informational manifest blocks

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main`.

## Bug (UAT blocker)

The first real v1.2 pack import (Spinoza Ethica, 406 chunks) failed at decode:

```
RAGpack Import Failed
The RAGpack manifest.json could not be read: DecodingError.keyNotFound:
Key 'method' not found in keyed decoding container. Path: indexer.
```

The pipeline's actual v1.2 manifest `indexer` block is:

```json
"indexer": { "document_count": 1, "chunk_count": 406, "timestamp": "2026-06-11T06:18:52Z" }
```

while the app's `RAGpackManifest.IndexerInfo` (PR #98) requires `method` (and `dimension`). This was a **contract inconsistency between two implementation prompts** I wrote: the app-side PR-B prompt specified `indexer: {method, dimension}`; the pipeline prompt said "lift the v1.1 schema" whose indexer shape is `document_count`/`chunk_count`/`timestamp`. Both CLIs followed their prompts faithfully — the prompts disagreed. The pipeline's shape is the de-facto v1.2 (it's what real packs ship); the app adapts.

## Fix policy (ADR-0011 spirit)

Stay strict ONLY where identity/correctness lives. **Strictly required + validated, UNCHANGED:** `pack_version` and the entire `embedder` block (`embedding_model`, `embedding_dimension`, `model_hash`, `dtype`, `pooling`, `l2_normalized`) and `files.chunks` + `files.embeddings`. Everything informational decodes tolerantly.

### Changes in `Shared/RAG/RAGpackManifest.swift`

- `IndexerInfo`: make ALL fields optional, covering BOTH shapes:
  - keep `method: String?` and `dimension: Int?` (forward-compat with the original PR-B prompt's shape)
  - add `documentCount: Int?`, `chunkCount: Int?`, `timestamp: String?` (snake_case `CodingKeys`: `document_count`, `chunk_count`, `timestamp`)
- `RAGpackManifest.indexer`: make the property itself optional (`let indexer: IndexerInfo?`) — the pipeline always emits it today, but it's informational, so don't fail decode if a future producer omits it.
- `ChunkerInfo`: make all fields optional too. Current shapes match, but informational blocks should never be the reason a pack is rejected. Keep `chunker` itself a required property if Codable already treats it so — adjust to taste; the key requirement is no required fields *inside*.
- `stats` is already optional — leave as is.
- `files.citations` stays optional. `files.metadata` (a v1.1-residue nested dict the pipeline still emits) is ignored by Codable automatically — no action.
- Do NOT touch `validate(againstCurrentEmbedder:)` semantics. The embedder/pack_version checks remain strict.

## Acceptance

- Add a test that decodes the REAL manifest fixture below and runs `validate(againstCurrentEmbedder:)` to the fingerprint check successfully (`embedder.model_hash` = `0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6` MUST MATCH the current embedder). Where to put the test: `NoesisNoemaTests/` if it's wired; if it isn't (per PR-A's note that the target is unwired), add a free-standing decode smoke at the call site of the reader or in a new `Tests/RAG/RAGpackManifestDecodeTests.swift` that you can run via `xcodebuild test` — but DO NOT spend time wiring the test target in this PR. If unwireable, at minimum add a `#if DEBUG` smoke function that decodes the fixture string and asserts no throw, callable manually.
- All 4 builds green: macOS Debug, macOS Release, iOS Simulator arm64 Debug, iOS Simulator arm64 Release (`ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`). Serial iOS (DerivedData lock).
- PR body documents the contract fix and pastes the fixture.

### Fixture (real manifest from the failing Spinoza pack — embed verbatim as a Swift string literal)

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

`source_documents` is a top-level key the app's struct doesn't declare — Codable ignores it; no action needed.

## Scope (hard)

- Touch ONLY: `Shared/RAG/RAGpackManifest.swift` and the new test file (or DEBUG smoke).
- Do NOT touch: any embedder code (`Shared/Llama/*`, `EmbeddingModel.swift`), `RAGpackReader.swift` (its calls to `validate(...)` must keep working unchanged), `NumpyReader.swift`, `DocumentManager.swift`, UI files, `project.pbxproj`.
- Pure Swift; no new dependencies.

## Commit + PR

Single commit acceptable. Branch suggestion: `fix/manifest-tolerant-decode`.
PR title: `fix(rag): tolerant decode for informational manifest blocks (indexer/chunker)`

PR body MUST include:
- Reference to this bug (the Spinoza UAT alert text) and to ADR-0011's strict-vs-tolerant policy
- Per-field optional/required summary for `IndexerInfo` and `ChunkerInfo`
- Confirmation that the embedder block + `pack_version` validation are unchanged
- The fixture above + decode test result
- 4-build matrix
- Any orthogonal findings noted but not fixed

Do NOT merge — Taka does that, then re-imports the EXISTING Spinoza zip (no re-embedding needed) and continues UAT.

## Orthogonal (report only, do NOT fix)

The pipeline manifest carries v1.1 residue: `files.metadata.embeddings_csv` and duplicated embedder fields (`name`/`version`/`dimensions` alongside canonical `embedding_model`/`embedding_version`/`embedding_dimension`). Harmless to the app (Codable ignores unknown keys); flag for a later pipeline cleanup PR.

## Report back

- Diff per file (file list + per-file size of change)
- Decode test output (paste)
- 4-build matrix
- PR number
