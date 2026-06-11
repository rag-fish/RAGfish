# Claude Code Task — hotfix: populate VectorStore.shared from persisted RAGpack chunks at launch

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main` (PR #105 merged or open — use current main).

## Bug (P0 release blocker)

`VectorStore.shared.chunks.count == 0` at query time, even when a RAGpack was imported in a prior session and is visible on disk.

**Root cause (confirmed by PR #105 investigation):**

- `PersistenceStore.loadRAGpackChunks()` loads persisted chunks into `DocumentManager.ragpackChunks` (@Published dict) at launch — this works fine.
- The only lifecycle write to `VectorStore.shared.chunks` is the live-import append at `DocumentManager.swift:216`.
- Nothing copies `ragpackChunks` → `VectorStore.shared` on startup. The disk → in-memory re-hydration hop is **missing**.
- Result: RAG only works in the same session as a fresh import. Any pack imported in a prior session is invisible to the retriever.

**Evidence from UAT (post-PR-#103 clean rebuild):**

```
[PersistenceStore] ✅ Loaded RAGpack Chunks: 7.06 MB, 1 packs  ← disk load: OK
...
🔎 [LocalExecutor/RAG] store-state: VectorStore.shared.chunks.count=0  ← store empty: BUG
🔎 [LocalExecutor/RAG] retrieved chunks.count=0
🔎 [LocalExecutor/RAG] no chunks retrieved — context will be empty
```

## Fix

### What to change

**File: `DocumentManager.swift`**

After `loadRAGpackChunks()` populates `ragpackChunks`, add a call that copies all persisted chunks into `VectorStore.shared`. The call must happen on **every launch**, once, in the startup initialisation path.

**Exact requirements:**

1. **Use `addChunks(_:deduplicate:)` (or direct assignment), NOT `addTexts`.** Persisted chunks already carry embeddings. `addTexts` would re-embed and must not be called here.
2. **Guard on `VectorStore.shared.chunks.isEmpty`** before the populate call — or use `deduplicate: true` — to prevent double-population when the `DocumentManager` initialiser is called from `#Preview` sites or tests.
3. **Placement:** right after `loadRAGpackChunks()` completes and `ragpackChunks` is populated. The live-import path at `:216` is correct and must not be changed.
4. **Flatten correctly:** `ragpackChunks` is `[String: [Chunk]]`; flatten with `.values.flatMap { $0 }` to get `[Chunk]`.

**Pseudocode (do not paste verbatim — read the actual types and adapt):**

```swift
// In DocumentManager.init() or at end of loadRAGpackChunks()
let allChunks = ragpackChunks.values.flatMap { $0 }
if !allChunks.isEmpty && VectorStore.shared.chunks.isEmpty {
    VectorStore.shared.addChunks(allChunks, deduplicate: true)
}
```

Adapt parameter names and method signatures to what actually exists in `VectorStore.swift`. **Read both files before writing a single line.**

### What NOT to change

- Do not touch `VectorStore.swift` unless `addChunks(_:deduplicate:)` literally does not exist, in which case add the minimal overload there (one function, no other changes) and note it in the PR.
- Do not touch `PersistenceStore.swift`.
- Do not touch `LocalExecutor.swift`.
- Do not touch any UI file.
- Do not touch `project.pbxproj`.
- Do not change the live-import path at `DocumentManager.swift:216`.

## Acceptance criteria

1. After a fresh launch (no import in this session), `VectorStore.shared.chunks.count > 0` when at least one RAGpack has been imported in a prior session.
2. The `🔎 [LocalExecutor/RAG] store-state:` print shows a non-zero count for Q3 ("Quote a passage from Spinoza's Ethics about substance.") with the existing Spinoza pack.
3. The `🔎 [LocalExecutor/RAG] retrieved chunks.count` is non-zero and `Context:` is populated in the LLM entry print.
4. A fresh import in the same session still works (live-import path unchanged).
5. All 4 builds green: macOS Debug, macOS Release, iOS Simulator arm64 Debug, iOS Simulator arm64 Release (`ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`). Serial iOS builds (DerivedData lock).

## Notes from investigation (Section 8 of PR #105)

- There is a redundant second `EmbeddingModel` load at query time (orthogonal inefficiency — do NOT fix in this PR, flag as `// TODO: avoid re-init at query time` comment at the call site if you find it clearly).
- `VectorStore.findRelevant` silently skips dimension-mismatched chunks — after this fix lands, Taka will verify embedding dimensions match at runtime (not your concern here).
- `#Preview` sites call `DocumentManager()` — the empty-guard prevents them from stacking live pack data.

## Commit + PR

Branch: `fix/vectorstore-populate-on-launch`

Single commit acceptable. PR title:

```
fix(rag): populate VectorStore.shared from persisted chunks on launch
```

PR body MUST include:
- One-line root cause description
- File:line of the change
- The `addChunks` vs `addTexts` rationale (embeddings preserved)
- Confirmation that live-import path (`:216`) is unchanged
- Confirmation that `#Preview` guard is in place
- 4-build matrix
- UAT instruction: "launch app without importing, ask Q3, confirm `store-state: chunks.count > 0`"
- Any orthogonal findings noted but not fixed

Do NOT merge — Taka runs UAT first.

## Report back

- PR number
- File:line of the change (exact)
- The `addChunks` call as written (paste the 3–5 lines)
- 4-build matrix result
