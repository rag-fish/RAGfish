# Claude Code Task — INVESTIGATION ONLY: VectorStore.shared is empty at query time

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main` (PR #104 merged or open — use current main).

## ⚠️ Hard constraints

**This task writes ZERO code.** Do not edit any source file. Do not create any branch for code changes. Do not run the app. Do not run `xcodebuild`. The deliverable is a single markdown report saved to `docs/investigations/2026-06-12-vectorstore-populate-investigation.md`, committed and pushed on its own branch with a PR — that file is the ONLY artifact.

If you find yourself wanting to add a `print` for diagnosis: stop. Note "would help to add a print at <file:line>" in the report instead.

If you find yourself wanting to fix the bug: stop. Note it as a fix proposal in Section 7. Taka and the design Claude will decide the next action.

This boundary exists because the prompt-edit-build-PR-merge-UAT round trip is expensive. We are buying information here, nothing else.

## Context (what we know from UAT logs)

Post-PR-#103 clean rebuild + UAT confirmed the following across **all 5 queries** (Q1–Q5):

```
[PersistenceStore] ✅ Loaded RAGpack Chunks: 7.06 MB, 1 packs
...
🔎 [LocalExecutor/RAG] store-state: VectorStore.shared.chunks.count=0
🔎 [LocalExecutor/RAG] retrieved chunks.count=0
🔎 [LocalExecutor/RAG] no chunks retrieved — context will be empty
```

**Key facts:**

1. `PersistenceStore` successfully loads a RAGpack from disk at startup (7.06 MB, 1 pack).
2. Despite this, `VectorStore.shared.chunks.count` is **always 0** at query time.
3. This is confirmed on current `main` (PR #103 prints are present, stale build hypothesis is ruled out).
4. All 5 queries get `Context: none` — RAG has never worked in this build.

**Symptom also confirmed from log:**

- Q1 and Q2 return answers from Llama 3.2 3B general knowledge (not RAG).
- Q2's raw output contains `|>` and `|>assistant` residue which contaminates history. By Q4 and Q5, the accumulated `|>` garbage in the prompt causes the model to emit only 1 token (immediate EOS), producing empty answers.

The two bugs are orthogonal. This investigation focuses **only** on the VectorStore populate gap (P0). The `|>` issue is P1 and out of scope for this prompt.

## Investigation tasks

Treat each section below as "produce a section in the report titled the same way". Use code excerpts (path:line ranges) and brief explanations. Be precise — name the function, the file, the line range. Quote the relevant ~5–20 lines verbatim.

### Section 1 — Locate VectorStore and its public interface

Find the `VectorStore` type (likely `Shared/RAG/VectorStore.swift` or similar). Quote:
- The full type declaration (class/struct/actor, `shared` singleton if present)
- The property that holds chunks (`chunks`, `entries`, or equivalent) with its type
- All public mutating methods that add chunks to the store (e.g. `add(chunks:)`, `populate(...)`, `insert(...)`)
- Any `clear()` or `reset()` method

State whether the type is an actor, a class, a struct, or something else, and whether access to `shared` is thread-safe.

### Section 2 — Locate PersistenceStore and its RAGpack load path

Find where `PersistenceStore` loads RAGpack chunks from disk. The log line is:
```
[PersistenceStore] ✅ Loaded RAGpack Chunks: 7.06 MB, 1 packs
```

Quote the relevant code (~10–30 lines). Identify:
- The function that produces this log line
- The type returned (what does it hold? chunks as `[String]`? `[RAGChunk]`? something else?)
- The variable or property the loaded data is assigned to after loading

### Section 3 — Find the connection (or absence) between PersistenceStore and VectorStore

This is the core question. After `PersistenceStore` loads chunks from disk, is there ANY call site that takes those chunks and writes them into `VectorStore.shared`?

Search the entire codebase for:
- All call sites of `VectorStore.shared` (every read AND write)
- All call sites of the mutating methods found in Section 1
- Any place that reads from `PersistenceStore`'s loaded chunks and passes them somewhere

For each call site produce a row in a table:

| File:line | Caller | Operation (read/write) | What is passed / returned |
|---|---|---|---|

After the table, answer directly: **Is there a call that populates VectorStore.shared from PersistenceStore's loaded data? Yes or No.** If yes, quote it. If no, state it plainly.

### Section 4 — Trace app startup to find all VectorStore.shared write calls

Starting from app entry point (e.g. `@main`, `AppDelegate`, `SceneDelegate`, or equivalent SwiftUI `App` struct), trace the initialization sequence. Identify every place `VectorStore.shared` (or equivalent) is written to. Quote the relevant code for each.

If no write ever happens during startup, state that explicitly.

### Section 5 — Trace RAGpack import path to find VectorStore write calls

Find where the user imports a RAGpack (likely a file picker / import handler somewhere in the macOS UI). Trace from the UI action down to wherever the parsed chunks end up. Identify:
- Whether `VectorStore.shared` is written to at the end of this path
- If not, where the chunks go instead (e.g. only saved to PersistenceStore without populating in-memory store)

Quote the relevant 10–20 lines at each key hop.

### Section 6 — Understand EmbeddingModel initialization timing

The log shows `EmbeddingModel` loading twice — once at app start and once inside `LocalExecutor.execute`. The second load happens at query time:

```
[EmbeddingModel] Loaded embedder 'default-embedding' dim=768 fp=0c7930f6c4f6…
🔎 [LocalExecutor/RAG] store-state: VectorStore.shared.chunks.count=0
```

The store is checked **after** the embedder is loaded. Find `EmbeddingModel` initialization and answer:
- Is VectorStore populated as a side-effect of EmbeddingModel initialization? (It shouldn't be, but check.)
- Is there any lazy-load or on-demand populate triggered by embedder readiness?

### Section 7 — Fix proposal (describe, do not implement)

Based on Sections 1–6, propose the minimal fix. Describe in plain English (no code):
- Exactly which function should call which VectorStore method
- At which point in the lifecycle (app startup? after import? both?)
- Whether persistence and in-memory state need to be kept in sync on every launch, or only on import
- Any risk of double-population if both startup and import paths write to VectorStore

### Section 8 — Open questions

List anything you could not answer from static reading alone. Name the specific file and line you would need a runtime trace or additional context to answer.

## Report format

Save as `docs/investigations/2026-06-12-vectorstore-populate-investigation.md` with:

- Top-of-file YAML frontmatter:
  ```
  ---
  date: 2026-06-12
  author: claude-code
  pr_context: post-#104 UAT (VectorStore always empty)
  scope: read-only investigation
  ---
  ```
- The 8 sections above, in order, each as `## Section N — …`
- Code blocks with language tags (`swift`)
- File:line references in the form `Shared/Foo/Bar.swift:120-140`
- Tables in markdown table syntax

## Process

1. `git fetch && git pull` to ensure you are on current main.
2. Branch `investigate/vectorstore-populate` from main.
3. Read code, write report.
4. Commit only `docs/investigations/2026-06-12-vectorstore-populate-investigation.md`.
5. Open PR titled `docs(investigation): VectorStore populate gap — why chunks.count=0 at query time (no code changes)`.
6. PR body: paste Section 7 (fix proposal) and Section 8 (open questions).
7. **Do NOT merge**. Taka and the design Claude read the report, then decide on the next action.

## Anti-goals

- Do not add `print` statements
- Do not edit any `.swift` file
- Do not edit `project.pbxproj`
- Do not run the app
- Do not run `xcodebuild`
- Do not speculate beyond what's in the code — note unknowns in Section 8 instead
- Do not fix the `|>` / chat template bug — that is P1 and out of scope

## Report back

- PR number
- The PR body (Section 7 fix proposal + Section 8 open questions)

That's it.
