# Claude Code Task — PR-A: Foundation for Real Semantic Embedding (ADR-0011 §1-2, §7 partial)

Work in the local repo at:
`/Users/raskolnikoff/Xcode Projects/NoesisNoema`
Repo: `rag-fish/NoesisNoema`. Branch off `main` (HEAD `89ed7b9`, PR #96 merged).

This is **PR-A of two** for ADR-0011 implementation. PR-A delivers the foundation: a
real llama.cpp-backed embedding API and a new `EmbeddingModel`. **PR-A alone does NOT
enable RAGpack v1.2 import** — that ships in PR-B (a separate, later prompt). PR-A
intentionally leaves the v1.1 import path broken pending PR-B (documented below).

## Background

ADR-0011 (committed at `c61a2ae` in `rag-fish/RAGfish`) decided:
- Embedding runs in the **existing llama.cpp xcframework** (no CoreML, no new ML runtime).
- The embedder GGUF is **replaceable** (architecture must not hard-code it).
- The current `EmbeddingModel.swift` (10-dim pseudo-hash) is the root cause of broken
  RAG; it gets fully replaced.

PR #96 already cleaned `ModelRegistry` to Llama 3.2 3B only. The embedder GGUF
`nomic-embed-text-v1.5.Q5_K_M.gguf` (~100 MB, 768-dim, mean pooling, L2-normalized,
8192 token context) has been manually placed in
`Apps/macOS/NoesisNoema/Resources/Models/` by Taka and is git-ignored
(`.gitignore` already excludes `*.gguf`).

## Scope of PR-A

### A1. New llama.cpp embedding-mode actor

Create `Shared/Llama/LlamaEmbeddingContext.swift` as a **new Swift actor**, parallel to
`LlamaContext` in `LibLlama.swift` but specialised for embedding inference. Reference
`LibLlama.swift` for the existing `llama_*` C-API call patterns (it already wraps the
xcframework). Key API surface:

```swift
actor LlamaEmbeddingContext {
    static func load(modelPath: String) throws -> LlamaEmbeddingContext
    /// Returns the L2-normalized mean-pooled embedding for `text` as 768 float32s.
    func embed(text: String) async throws -> [Float]
    /// Embedding dimension as reported by the loaded model.
    nonisolated var dimension: Int { get }
    /// Stable content hash of the loaded GGUF file (used for fingerprinting; PR-B uses it).
    nonisolated var modelFingerprint: String { get }
}
```

Initialisation MUST set:
- `llama_model_params` — `n_gpu_layers` set to use Metal when available (mirror what
  `LibLlama.swift` already does at init).
- `llama_context_params` — `embeddings = true` (this is the critical flag enabling
  embedding mode), `n_ctx = 8192` (nomic-embed-text-v1.5 supports 8192 tokens),
  `n_batch = 8192` (so a long chunk fits in a single batch), `n_ubatch = 8192`, pooling
  type `LLAMA_POOLING_TYPE_MEAN` (mean pooling — set via
  `llama_context_params.pooling_type`).

`embed(text:)` procedure:
1. Tokenize `text` using `llama_tokenize` (mirror existing LibLlama tokenization).
   Truncate to `n_ctx` tokens if longer (log a warning; do not silently misrepresent).
2. Clear and prepare a batch: `llama_batch_clear` / `llama_batch_add` for each token,
   with `logits = false` for all positions (we want embeddings, not logits).
3. Call `llama_decode(ctx, batch)`. Throw on non-zero return (do NOT print-and-continue
   — ADR-0000 §4; mirror the parked L3 issue from PR #95 explicitly here for the
   embedding path).
4. Read pooled embedding via `llama_get_embeddings_seq(ctx, 0)` (sequence-0 pooled
   output when `pooling_type = MEAN`). The pointer returns `n_embd` floats; copy into
   `[Float]`.
5. **L2-normalize** the resulting vector (divide by `sqrt(sum(x_i^2))`; if norm is 0,
   throw — that's a degenerate output).
6. Return the normalized `[Float]` of length `dimension`.

`modelFingerprint` is the **SHA-256 hex digest** of the GGUF file bytes, computed once
at load time and cached. Use `CryptoKit.SHA256` for this. PR-B uses this string in
manifest validation; PR-A only needs to compute and expose it.

Error type:

```swift
enum EmbeddingError: Error {
    case modelLoadFailed(path: String, underlying: String)
    case contextInitFailed
    case tokenizationFailed
    case decodeFailed(rc: Int32)
    case poolingUnavailable
    case zeroNorm
}
```

Throw the appropriate case on every failure path. **No silent fallback** anywhere in
this file.

### A2. New `EmbeddingModel` backed by `LlamaEmbeddingContext`

Rewrite `Shared/RAG/EmbeddingModel.swift` end-to-end. Constraints:

- Preserve the **public synchronous signature** `func embed(text: String) -> [Float]`.
  The current code is sync and many call sites (`BanditRetriever.swift:30`,
  `MobileHomeView.swift:350`, `DesktopChatView.swift:284`, etc.) assume sync. Changing
  to async would explode the surface beyond PR-A scope.
  Implementation: hold a `LlamaEmbeddingContext` instance and call its async `embed`
  via a blocking bridge — `DispatchSemaphore` or `Task { await ... }` + semaphore wait.
  Pure Swift, no Combine.

- Keep the cache layer (`embeddingCache: [String: [Float]]`, `maxCacheSize = 500`,
  concurrent-queue + barrier writes). Cache is a real win at 768-dim and llama-cpp
  inference cost.

- Apply the **task prefix** `"search_query: "` to the text **before** the cache key and
  before embedding. nomic-embed-text-v1.5 requires task prefixes for correct semantic
  output. (PR-B will distinguish `"search_query: "` vs `"search_document: "` based on
  caller intent — for PR-A, default to `"search_query: "` since the only live callers
  are query-side; pack-side ingestion is in PR-B's reader.)

- **Remove `loadEmbeddingsCSV(from:)`** entirely. It's dead (v0.x format, not called by
  any non-test code — grep confirms only EmbeddingModel.swift defines and uses it). Its
  removal is part of the v1.2 transition.

- Expose the underlying `modelFingerprint` and `dimension` (forward from
  `LlamaEmbeddingContext`) — PR-B needs these.

- `init(name: String)` — keep the signature so call sites compile. Internally resolve
  the embedder GGUF via `Bundle.main.url(forResource:withExtension:subdirectory:)`,
  trying `(nil, "Models", "Resources/Models", "Resources")` subdirectories (mirror the
  pattern in `LlamaState.swift defaultModelUrl`). Throw / fatalError with a clear
  message if not found. Resource name to search:
  `nomic-embed-text-v1.5.Q5_K_M` with extension `gguf`.

  (If `init` throwing is too invasive, use a `failable` init **plus** a
  `static func defaultInstance() throws -> EmbeddingModel` factory and keep the
  non-throwing init for compatibility, marking it as `@available(*, deprecated)` —
  state which path you chose in the PR body.)

### A3. `.gitignore` extension

Ensure the embedder GGUF cannot be accidentally committed. The repo's `.gitignore`
already has `*.gguf` (verify this is true; grep for it). If it's there, no change
needed — note that in the PR body. If for any reason it's not there (e.g. only listed
in a sub-directory `.gitignore`), add `*.gguf` to the root `.gitignore`.

### A4. Unit-test or sanity check

Add a minimal smoke test in `NoesisNoemaTests` (or wherever the existing tests live —
inspect first). The test should:

1. Create an `EmbeddingModel(name: "default")`.
2. Call `embed(text: "hello world")`.
3. Assert: returned `[Float]` has count == 768.
4. Assert: L2 norm of the returned vector is within `0.001` of `1.0`.
5. Assert: `embed("hello world")` called twice returns identical vectors (cache hit
   determinism).
6. Assert: `embed("hello world")` and `embed("entirely different text")` are NOT
   identical (basic semantic check; the previous hash-based stub would have passed
   this trivially, real embedder will too, but it documents intent).

If the test target requires the GGUF in the test bundle and the file is too big or
the runner doesn't pick it up: it's OK to `#if canImport(...)` gate the test or skip
on CI; document why in the test file comment.

### A5. Explicit "PR-A leaves v1.1 import broken" guard

In `Shared/DocumentManager.swift`, find `processRAGpackImport(fileURL:)` (the function
that currently expects v0.x `embeddings.csv`-shaped packs). Add a comment block at
the top of that function explaining:

```swift
// NOTE (ADR-0011, PR-A foundation merged; PR-B reader pending):
// This function still expects the legacy v0.x pack shape and will NOT work with
// pipeline-produced v1.1 packs (no embeddings.csv → silent return). PR-B replaces
// this entire function with a v1.2 RAGpackReader (chunks.json + embeddings.npy +
// manifest.json + citations.jsonl) and surfaces failures via UI alert. Do not ship
// without PR-B.
```

This is documentation-only; do not change the function's behaviour in PR-A. (The
"silent return" is a real bug per ADR-0000 §4; PR-B fixes it. PR-A's job is to put
the comment so a hypothetical "merge PR-A and ship" mistake is caught at code review.)

### A6. CallsSites that pass through unchanged

Confirm via grep that the following Swift call sites still compile against the new
`EmbeddingModel`:
- `Shared/RAG/BanditRetriever.swift:30` — `store.embeddingModel.embed(text: query)`
- `Apps/iOS/NoesisNoemaMobile/Views/MobileHomeView.swift:350`
- `Apps/iOS/NoesisNoemaMobile/Views/ChatView.swift:141`
- `Apps/macOS/NoesisNoema/Views/DesktopChatView.swift:284`
- `Apps/CLI/LlamaBridgeTest/{QAContextStoreShim,SemanticAnswerCacheShim}.swift`
- `Shared/ModelManager.swift` (the `currentEmbeddingModel` property and
  `switchEmbeddingModel(name:)` method)

None of these should require changes if A2's signature preservation is done correctly.
If any call site DOES break, that's a signal to revisit A2's design — STOP and report
rather than papering over.

## Build matrix (mandatory, all green)

- macOS Debug
- macOS Release
- iOS Simulator arm64 Debug
- iOS Simulator arm64 Release (use `ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`)

**Run iOS builds SERIALLY**, not in parallel — DerivedData lock contention has bitten
this project repeatedly. No new warnings from new files.

## Test execution

Run the new smoke test from A4 if the test target builds. If it doesn't run from
`xcodebuild test` (e.g. GGUF not in test bundle), document the manual run procedure
in the PR body. Don't gate the PR on test runs in CI if they don't work yet — Taka
will run them manually on his Mac.

## Commit + PR

Conventional commit(s) — one or two commits acceptable, e.g.:
1. `feat(rag): add LlamaEmbeddingContext (llama.cpp embedding mode wrapper)`
2. `feat(rag): replace EmbeddingModel with real semantic implementation (PR-A)`

Push branch (suggested name `feat/embedding-foundation-pr-a`). Open PR to `main`:
**Title**: `feat(rag): real semantic embedder foundation — ADR-0011 PR-A`

PR body MUST include:
- ADR-0011 reference + this-is-PR-A statement
- The A1 file summary (new actor, what flags are set, error type)
- The A2 swap summary (which call sites verified unchanged via grep)
- The A3 gitignore status (already had `*.gguf` or had to add it)
- The A4 smoke test status (passes / requires manual run / skipped because…)
- The A5 NOTE comment placement in DocumentManager
- The build matrix (all 4 green)
- **Explicit "PR-A alone breaks RAGpack import until PR-B lands"** — this is by
  design; do NOT merge PR-A without intending to land PR-B immediately after
- Any unexpected findings (out-of-scope dead code, broken siblings, etc.) — note,
  don't fix

Do NOT merge yourself; Taka does that after review + smoke test on his Mac.

## Scope (hard)

- Touch ONLY:
  - `Shared/Llama/LlamaEmbeddingContext.swift` (new)
  - `Shared/RAG/EmbeddingModel.swift` (rewrite)
  - `.gitignore` (only if necessary — verify first)
  - `Shared/DocumentManager.swift` (A5 documentation comment only)
  - new smoke test file under the tests target
- Do NOT touch:
  - `Shared/Llama/LibLlama.swift` (LlamaContext stays; embedding is a separate actor)
  - `Shared/RAG/VectorStore.swift`, `Shared/RAG/BanditRetriever.swift` (PR-B may, PR-A doesn't)
  - `Shared/RAG/RAGpackReader.swift` — doesn't exist yet, PR-B creates it
  - any view file
  - any coordinator / executor / model registry file
  - `project.pbxproj` (synced folder convention covers it)
- Pure Swift; no new dependencies.

## Report back

- The diff per file (file list + per-file size of change)
- Grep self-check: `grep -rn "unicodeScalars.reduce\|loadEmbeddingsCSV\|hashValue + UInt32(i \* 31)" --include="*.swift" .`
  must return ZERO matches after the change (the old hash-impl and CSV-loader are gone)
- A list of all `EmbeddingModel` callers verified to still compile (from A6)
- Build matrix (all 4 green; serial iOS)
- Smoke test result (or manual run instructions)
- The `modelFingerprint` SHA-256 hex string from one successful `EmbeddingModel`
  initialisation — Taka needs this for PR-B's manifest fingerprint
- PR number

## Anti-goals

- Do NOT write the RAGpack v1.2 reader (that's PR-B).
- Do NOT add the `"search_document: "` prefix yet (PR-B handles document-side embedding).
- Do NOT change the `Chunk` type, manifest schema, or any pipeline contracts.
- Do NOT modify error surfacing in UI (that's PR-B's UI alert work).
- Do NOT silently swallow `llama_decode` non-zero returns even "to keep tests passing"
  — throw, the same way we should have been throwing all along (ADR-0000 §4).
