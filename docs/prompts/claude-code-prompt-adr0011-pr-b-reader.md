# Claude Code Task — PR-B: RAGpack v1.2 Reader + UI Alert + Dead Code Cleanup (ADR-0011 §3-§7)

Work in the local repo at:
`/Users/raskolnikoff/Xcode Projects/NoesisNoema`
Repo: `rag-fish/NoesisNoema`. Branch off `main` (HEAD `ac261c7`, PR #97 PR-A merged).

This is **PR-B of two** for ADR-0011 implementation. PR-A delivered the foundation:
real semantic embedding via llama.cpp, new `EmbeddingModel` with 768-dim output,
SHA-256 `modelFingerprint`. PR-B delivers the **import-side completion**: RAGpack v1.2
reader (NumPy .npy parser + manifest validator + fingerprint check), UI alert
surfacing for import failures, and incidental dead-code cleanup.

After PR-B merges, NoesisNoema will perform true semantic retrieval end-to-end —
*provided* the user supplies a v1.2 RAGpack from `noesisnoema-pipeline` (separate
PR (3), parallel work).

## Background

ADR-0011 (committed at `c61a2ae` in `rag-fish/RAGfish`) §3-§7 prescribe:
- **§3**: Embedder identity by **fingerprint**, not name. Manifest carries GGUF
  SHA-256 + dim + pooling + norm flag + human name. App verifies on import.
- **§4**: **No silent fallback.** Every import error throws a structured error;
  UI surfaces it via alert.
- **§5**: Pipeline updated to **RAGpack v1.2 manifest shape**. (Pipeline-side work
  is PR (3), out of scope here. PR-B's reader implements what the v1.2 manifest
  WILL specify, in coordination with the pipeline-side PR.)
- **§6**: Existing v1.1 packs (MiniLM-based) become incompatible at import. Hard
  break, accepted.
- **§7**: Scope explicitly excludes chat template / router / session memory /
  macOS UI shell.

The PR-A modelFingerprint recorded for the current bundled embedder
(`nomic-embed-text-v1.5.Q5_K_M.gguf`) is:
**`0c7930f6c4f6f29b7da5046e3a2c0832aa3f602db3de5760a95f0582dbd3d6e6`**

This string is needed below for the validator behavior (it's the fingerprint the
app's currently-loaded embedder produces; manifests carrying a DIFFERENT fingerprint
must be rejected with a clear error).

## Verified pre-existing state

- `Shared/DocumentManager.swift`:
  - `importDocument(file:)` at line 113 — entry point, dispatches to
    `processRAGpackImport`.
  - `processRAGpackImport(fileURL:)` at line 129 — reads v0.x shape (chunks.json +
    embeddings.csv + metadata.json). PR-A inlined the CSV parse here byte-for-byte.
    PR-B replaces this function entirely with v1.2 logic.
  - PR-A added a NOTE comment block above this function flagging the broken-by-design
    state. Remove that NOTE block as part of this PR's commit (PR-B replaces what
    the NOTE was warning about).
  - Confirmed inlined CSV parse is at lines ~183–210 (`chunks.json`, `embeddings.csv`,
    `metadata.json` references). Replace this entire block; do NOT preserve the CSV
    path even as a fallback.
- UI alert wiring sites:
  - `Apps/macOS/NoesisNoema/Views/DesktopSettingsView.swift:364` — `.fileImporter`
    inside the "Manage RAGpacks" sheet, calls
    `documentManager.importDocument(file: url)` on success.
  - `Apps/iOS/NoesisNoemaMobile/Views/SettingsView.swift:235` — same pattern.
  - Neither currently surfaces import failures to the user — that's why PR #96's
    Spinoza UAT showed silent corruption.
- Out-of-scope dead code noted by previous CLI report:
  - `Shared/DocumentManager.swift:269` — `inferWithLlama(..., fileName:
    "llama3-8b.gguf", ...)` is a dead function (zero callers). Remove it as part of
    this PR (PR-B touches DocumentManager anyway; doing it here is cheap).

## Scope of PR-B

### B1. NumPy `.npy` parser

New file `Shared/RAG/NumpyReader.swift`. Public surface:

```swift
struct NumpyReader {
    /// Parsed float32 array from a .npy file. Throws on every malformation.
    static func readFloat32(from url: URL) throws -> (shape: [Int], data: [Float])
}

enum NumpyReadError: Error {
    case fileTooSmall
    case badMagic              // not "\x93NUMPY"
    case unsupportedVersion    // we accept 1.0 and 2.0; reject others
    case headerMalformed(String)
    case unsupportedDtype(String) // we accept only "<f4" (little-endian float32)
    case shapeMalformed(String)
    case dataLengthMismatch(expected: Int, actual: Int)
}
```

Implementation specification:

- `.npy` v1.0 binary layout:
  - bytes 0..5: magic string `\x93NUMPY` (6 bytes)
  - bytes 6..7: major/minor version (uint8 each)
  - bytes 8..9: header length (uint16 little-endian, for v1.0)
  - bytes 10..(10+header_len): ASCII Python dict literal like
    `{'descr': '<f4', 'fortran_order': False, 'shape': (N, 384), }` padded with
    spaces, terminated by `\n`.
  - remainder: raw little-endian float32 buffer, `prod(shape)` floats.
- Version 2.0 differs only in header length being uint32 instead of uint16.
- ONLY accept `'descr': '<f4'` (little-endian float32). Reject `'<f8'`, `'>f4'`,
  `'|u1'`, anything else, with `.unsupportedDtype`.
- ONLY accept `'fortran_order': False`. Reject Fortran order.
- Parse shape via small hand-written parser (don't pull in regex frameworks for
  this — it's a tuple of integers); accept arbitrary rank, but typical usage is
  2-D `(N, embed_dim)`.
- After reading shape, validate `data_size == prod(shape) * 4` exactly. If not,
  throw `.dataLengthMismatch`.
- Copy the raw bytes into `[Float]` via `withUnsafeBytes`/`load(fromByteOffset:as:)`
  in a single pass; do NOT re-parse text or use JSON.
- Return `(shape, data)`. `data.count == prod(shape)`. Caller reshapes.

No third-party dependencies. Pure Swift `Foundation`.

### B2. RAGpack v1.2 manifest model + validator

New file `Shared/RAG/RAGpackManifest.swift`. Define a `Codable` struct that mirrors
the v1.2 manifest schema below. The schema is **derived from**
`noesisnoema-pipeline`'s existing `schemas/manifest_v1_1.json`, lifted to v1.2 with
the embedder fields adjusted for the llama.cpp-based embedder identity (ADR-0011 §3).

**The v1.2 schema this PR commits to** (this is what the pipeline PR (3) will be
asked to produce):

```jsonc
{
  "pack_version": "1.2",
  "pack_id": "<uuid or similar>",
  "created_at": "<ISO 8601>",
  "chunker": {
    "method": "<token_based|sentence_based|...>",
    "chunk_size": 512,
    "overlap": 64,
    "tokenizer_name": "<optional>",
    "preserve_sentences": true,
    "config_hash": "<sha256 hex, optional but recommended>"
  },
  "embedder": {
    "embedding_model": "nomic-embed-text-v1.5",  // human-readable name
    "embedding_dimension": 768,
    "model_hash": "<sha256 hex of the GGUF file>",   // REQUIRED — this is the fingerprint
    "dtype": "float32",
    "pooling": "mean",      // or "cls" / "max" — only "mean" supported in v1.2
    "l2_normalized": true,  // boolean; required
    "runtime": "llama.cpp"  // free-form; "llama.cpp" is what the app expects
  },
  "indexer": {
    "method": "flat",       // free-form; v1.2 doesn't constrain
    "dimension": 768
  },
  "files": {
    "chunks": "chunks.json",
    "embeddings": "embeddings.npy",
    "citations": "citations.jsonl"   // optional in v1.2
  },
  "stats": {                // optional
    "chunk_count": 1234,
    "total_tokens": 543210
  }
}
```

Provide:

```swift
struct RAGpackManifest: Codable {
    let packVersion: String   // must equal "1.2"
    let packId: String
    let createdAt: String
    let chunker: ChunkerInfo
    let embedder: EmbedderInfo
    let indexer: IndexerInfo
    let files: FilesInfo
    let stats: StatsInfo?

    struct EmbedderInfo: Codable {
        let embeddingModel: String
        let embeddingDimension: Int
        let modelHash: String   // <-- the fingerprint
        let dtype: String
        let pooling: String
        let l2Normalized: Bool
        let runtime: String?
    }
    // ... ChunkerInfo, IndexerInfo, FilesInfo, StatsInfo as appropriate
}
```

Use `CodingKeys` to map `pack_version` ↔ `packVersion` (snake_case JSON, camelCase
Swift) and so on.

Validation function:

```swift
extension RAGpackManifest {
    /// Validates manifest against the v1.2 spec AND against the current app embedder.
    /// Throws specific RAGpackImportError cases on every violation.
    func validate(againstCurrentEmbedder current: EmbeddingModel) throws
}
```

Validations:
- `pack_version == "1.2"` — else `.unsupportedPackVersion(found: ...)`
- `embedder.dtype == "float32"` — else `.unsupportedEmbedderDtype(...)`
- `embedder.pooling == "mean"` — else `.unsupportedEmbedderPooling(...)`
- `embedder.l2_normalized == true` — else `.embedderNotL2Normalized`
- `embedder.embedding_dimension == current.dimension` (768 for the current
  embedder) — else `.embedderDimensionMismatch(expected: 768, found: ...)`
- `embedder.model_hash == current.modelFingerprint` (case-insensitive hex compare)
  — else `.embedderFingerprintMismatch(expected: ..., found: ...)`. This is the
  central ADR-0011 §3 check.

### B3. RAGpack v1.2 reader

New file `Shared/RAG/RAGpackReader.swift`. Public surface:

```swift
struct RAGpackReader {
    /// Reads a v1.2 RAGpack from an unzipped directory. Throws on every malformation.
    /// - Parameters:
    ///   - unzippedDir: directory containing manifest.json, chunks.json, embeddings.npy, etc.
    ///   - embedder:    the app's current EmbeddingModel — used to validate
    ///                  embedder fingerprint and dimension
    /// - Returns: parsed (chunks: [Chunk], embeddings: [[Float]])
    static func readPack(at unzippedDir: URL,
                         embedder: EmbeddingModel) throws -> (chunks: [Chunk],
                                                              embeddings: [[Float]])
}

enum RAGpackImportError: Error, LocalizedError {
    case manifestMissing
    case manifestMalformed(underlying: String)
    case chunksMissing
    case chunksMalformed(underlying: String)
    case embeddingsMissing
    case embeddingsMalformed(underlying: String)
    case citationsMalformed(underlying: String)    // citations are optional but if present must parse
    case unsupportedPackVersion(found: String)
    case unsupportedEmbedderDtype(found: String)
    case unsupportedEmbedderPooling(found: String)
    case embedderNotL2Normalized
    case embedderDimensionMismatch(expected: Int, found: Int)
    case embedderFingerprintMismatch(expected: String, found: String)
    case chunksEmbeddingsCountMismatch(chunks: Int, embeddings: Int)
    case embeddingShapeUnexpected(shape: [Int])  // not (N, dim)

    var errorDescription: String? { /* user-facing messages */ }
}
```

Read order:
1. `manifest.json` → decode `RAGpackManifest` (throw `.manifestMissing` /
   `.manifestMalformed` as appropriate)
2. `manifest.validate(againstCurrentEmbedder: embedder)` — all schema and identity
   checks
3. `chunks.json` → `[Chunk]` (use existing `Chunk` Codable; if `Chunk` isn't
   Codable, make it Codable additively without breaking any existing call site —
   ADR-0006 says contracts are locked, but additive Codable conformance is
   non-breaking)
4. `embeddings.npy` → `(shape, flat)` via `NumpyReader.readFloat32(from:)`. Validate
   `shape.count == 2`, `shape[1] == embedder.dimension`, throw
   `.embeddingShapeUnexpected` otherwise.
5. Reshape flat to `[[Float]]` of length `shape[0]`, each inner array of length
   `shape[1]`.
6. Cross-check `chunks.count == embeddings.count`, throw
   `.chunksEmbeddingsCountMismatch` otherwise.
7. `citations.jsonl` — if file exists, parse each line as JSON, attach citation
   info to the corresponding chunk by index. If file missing, that's fine (it's
   optional per the v1.2 schema). Errors during parse → `.citationsMalformed`.
8. Return `(chunks, embeddings)`.

Citations format (derived from `noesisnoema-pipeline`'s `chunk_text_with_offsets`
output): one JSON object per line, keyed by chunk index:
```json
{"chunk_index": 0, "doc_id": "...", "page": 12, "char_start": 100, "char_end": 612,
 "paragraph_boundaries": [0, 87, 234, 612]}
```
Attach these fields to `Chunk` additively. If `Chunk` doesn't have those fields,
add them as optionals (`page: Int?`, `charStart: Int?`, etc.); existing code that
constructs `Chunk` without them continues to compile.

### B4. DocumentManager rewrite

Replace `processRAGpackImport(fileURL:)` end-to-end. New behavior:

```swift
private func processRAGpackImport(fileURL: URL) async throws {
    // (security-scoped access — keep PR #94's iOS+macOS startAccessing fix)
    // 1. Unzip to a temp dir
    // 2. Call RAGpackReader.readPack(at: tempDir, embedder: self.embedder)
    //    Note: this throws RAGpackImportError — let it propagate.
    // 3. On success, add (chunks, embeddings) to the VectorStore.
    // 4. Clean up temp dir (defer).
    // No prints. No silent returns. No fallback to v0.x CSV.
}
```

- Remove the PR-A NOTE comment block above the function (its concern is now addressed).
- Remove the inlined CSV parse (the byte-for-byte block from PR-A) — gone.
- Remove `loadEmbeddingsCSV` from anywhere it still lives (was inlined in
  DocumentManager per PR-A; ensure no reference survives).
- Change `processRAGpackImport`'s signature to `async throws` (currently `async`).
- Change `importDocument(file:)` to call it inside `do { try await ... } catch { ... }`
  and route the error to a new `@Published var lastImportError: RAGpackImportError?`
  property on `DocumentManager`. Set it on failure; clear on success.

### B5. UI alert wiring

Both Settings views observe `DocumentManager.lastImportError` and present a SwiftUI
`.alert` when it's non-nil:

- **`Apps/macOS/NoesisNoema/Views/DesktopSettingsView.swift`**: after the existing
  `.fileImporter`, add `.alert(isPresented: ...)` (or
  `.alert(item: $documentManager.lastImportError)` pattern — make
  `RAGpackImportError` `Identifiable` if you go this route). Display
  `error.errorDescription` as the message. Provide a single "OK" dismiss action
  that clears `lastImportError = nil`.
- **`Apps/iOS/NoesisNoemaMobile/Views/SettingsView.swift`**: same pattern, same
  binding, same dismiss.

Both views ALREADY hold a reference to `documentManager` (verified via grep). No new
property wiring needed beyond the alert modifier.

### B6. Dead function cleanup (incidental)

Remove `inferWithLlama(..., fileName: "llama3-8b.gguf", ...)` at
`Shared/DocumentManager.swift:269`. Verified zero callers in PR #96's report.
Document this in the PR body.

### B7. .gitignore (no change expected)

`.gitignore` already has `*.gguf` (per PR-A). No change to `.gitignore` in this PR.
If anything else needs to be ignored (e.g. RAGpack zip files under
`Resources/`), state in the PR body and apply a single rule — don't go on a
gitignore reorganization.

## Build matrix (mandatory, all green)

- macOS Debug
- macOS Release
- iOS Simulator arm64 Debug
- iOS Simulator arm64 Release (`ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`)

**Run iOS builds SERIALLY** — the DerivedData lock recurring lesson. No new
warnings.

## Grep self-checks

After edits, all of the following must return ZERO matches in non-test Swift code:

```
grep -rn "embeddings.csv" --include="*.swift" .
grep -rn "loadEmbeddingsCSV" --include="*.swift" .
grep -rn 'fileName:\s*"llama3-8b.gguf"' --include="*.swift" .
grep -rn "metadata.json" --include="*.swift" .   # v0.x manifest file name
```

`manifest.json` (v1.2 file name) MAY appear — that's expected. Confirm in the PR
body that this is the only `*.json` filename reference of its kind.

## Commit + PR

Conventional commit(s) — 3-5 commits acceptable:

1. `feat(rag): add NumpyReader (.npy float32 parser)`
2. `feat(rag): add RAGpackManifest + RAGpackReader (v1.2 spec)`
3. `feat(rag): replace processRAGpackImport with v1.2 reader (throws structured error)`
4. `feat(ui): surface RAGpack import errors via alert (iOS + macOS)`
5. `chore: remove dead inferWithLlama function (no callers)`

Push branch (suggested `feat/ragpack-v12-reader-pr-b`). Open PR to `main`:
**Title**: `feat(rag): RAGpack v1.2 reader + import error UI — ADR-0011 PR-B`

PR body MUST include:
- ADR-0011 reference + this-is-PR-B statement
- v1.2 manifest schema summary (the JSON shape committed to)
- The B1 NumpyReader file summary
- The B2 manifest model + validation rules
- The B3 RAGpackReader read order + error type
- The B4 DocumentManager change summary (before/after of `processRAGpackImport`)
- The B5 UI alert wiring confirmation (iOS + macOS both wired)
- The B6 dead function removal confirmation
- Grep self-check output (all ZERO)
- Build matrix (all 4 green; serial iOS)
- **Explicit statement: the pipeline must be updated to v1.2 (separate PR in
  noesisnoema-pipeline) before any new RAGpack can be imported successfully.
  Existing v1.1 packs (MiniLM-based) are rejected with
  `embedderFingerprintMismatch`** — that's by design (ADR-0011 §6).
- Any other findings noted but not fixed.

Do NOT merge yourself. Taka does that after Spinoza Ethica re-UAT (which requires
the pipeline-side v1.2 PR landed and a v1.2 Spinoza pack regenerated).

## Scope (hard)

- Touch ONLY:
  - `Shared/RAG/NumpyReader.swift` (new)
  - `Shared/RAG/RAGpackManifest.swift` (new)
  - `Shared/RAG/RAGpackReader.swift` (new)
  - `Shared/DocumentManager.swift` (rewrite `processRAGpackImport`; remove dead
    `inferWithLlama`; remove PR-A NOTE block; add `lastImportError`)
  - `Shared/RAG/Chunk.swift` (additive citation fields ONLY if `Chunk` doesn't
    already have them)
  - `Apps/iOS/NoesisNoemaMobile/Views/SettingsView.swift` (add `.alert` modifier)
  - `Apps/macOS/NoesisNoema/Views/DesktopSettingsView.swift` (add `.alert` modifier)
- Do NOT touch:
  - `Shared/Llama/*` (PR-A finished the embedder)
  - `Shared/RAG/EmbeddingModel.swift` (PR-A finished it)
  - `Shared/RAG/VectorStore.swift` (the reader returns `(chunks, embeddings)` and
    DocumentManager adds them; VectorStore's existing add path should suffice. If
    something MUST change there, STOP and report.)
  - `Shared/RAG/BanditRetriever.swift`
  - any coordinator / executor / model registry / view file other than the two
    Settings views
  - `project.pbxproj`
- Pure Swift; no new dependencies.

## Anti-goals

- Do NOT support v1.1 packs in parallel (ADR-0011 §6 — explicit break).
- Do NOT keep any v0.x `embeddings.csv` reading path even as a fallback.
- Do NOT change the embedder, fingerprint computation, or `EmbeddingModel` surface
  (PR-A's done).
- Do NOT modify the pipeline manifest schema in this repo (it lives in
  `noesisnoema-pipeline`; PR (3) handles it).
- Do NOT add UI for "switch embedder" / "regenerate pack" beyond the alert.
  That's a future ADR.

## Report back

- The diff per file (file list + per-file size of change)
- Grep self-check outputs (all ZERO)
- Build matrix (all 4 green; serial iOS)
- Confirmation that `Chunk` Codable conformance is additive (existing constructors
  unchanged)
- Confirmation that `RAGpackImportError`'s `errorDescription` produces user-readable
  strings (paste a few examples in the PR body)
- Any orthogonal findings noted but not fixed
- PR number
