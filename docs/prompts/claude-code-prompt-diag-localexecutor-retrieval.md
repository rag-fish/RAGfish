# Claude Code Task — diagnostic patch: surface retrieval state at the LocalExecutor boundary

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main` (PR #102 already merged).

## Why (NOT a hotfix — diagnostic only)

The Spinoza UAT post-PR#102 console log shows the second question on the LocalExecutor path (Q3) hitting `Context: none` and `[RAG] context length: 0`:

```
🧠 [SESSION-MEM/EXEC] LocalExecutor.execute(history-aware) entered; history.count=2
🧠 [SESSION-MEM/EXEC] calling generateAsync with history.count=2
…
   Question: What does Spinoza say about the third kind of knowledge?
   Context: none
[RAG] context length: 0
⚠️ [buildPrompt] WARNING: No context provided - answering without RAG
```

That's catastrophic: the entire ADR-0011 effort exists so that RAG retrieval feeds context into the LLM, but at this call site the LLM is being asked the question with **zero retrieved chunks**. We do NOT know whether:
  (a) `VectorStore.shared.chunks` is empty in this app process (import did not actually populate it / persistence path broken)
  (b) `LocalRetriever.retrieve(...)` returned an empty result for this specific query
  (c) `DeepSearch` is enabled in UserDefaults and is silently filtering everything out
  (d) the retrieval succeeds but the join into `context` produces an empty string for some reason

A separate ModelManager path (`generateAsyncAnswer`) prints `[RAG] chunks loaded: N` and `[RAG] query =`, but the LocalExecutor path that the Coordinator drives does not print equivalent breadcrumbs, so we are flying blind from the dispatched path.

**This task does ONE thing**: add a handful of print statements at the LocalExecutor retrieval boundary so the next UAT run tells us which of (a)–(d) is happening. Do not change any behavior.

## Changes — `Shared/Runtime/Executors/LocalExecutor.swift` ONLY

Add three diagnostic print blocks inside `execute(query:sessionId:history:)`. Do NOT change any control flow, error throwing, threading, or return values. The diagnostic should be unconditional `print` (not `#if DEBUG` gated) so Taka sees them in any build configuration the UAT runs in.

Use distinctive tags so the lines are trivially greppable.

### Block 1 — before the retrieval Task

Immediately after the `let traceId = UUID()` line (right before "Stage 1: Retrieve relevant chunks" comment), insert:

```swift
print("🔎 [LocalExecutor/RAG] store-state: VectorStore.shared.chunks.count=\(VectorStore.shared.chunks.count)")
print("🔎 [LocalExecutor/RAG] query: \"\(query.prefix(120))\"")
print("🔎 [LocalExecutor/RAG] topK=\(defaultTopK), useDeepSearch=\(UserDefaults.standard.bool(forKey: Self.deepSearchDefaultsKey))")
```

(Reading `VectorStore.shared.chunks.count` from outside the `Task.detached` is intentional — we want the snapshot the executor sees synchronously at entry. Don't synchronize, don't lock, don't touch its internals — just print the count.)

### Block 2 — after the retrieval Task resolves

Immediately after `}.value` (the line that ends the `let chunks = await Task.detached(...).value` block), insert:

```swift
print("🔎 [LocalExecutor/RAG] retrieved chunks.count=\(chunks.count)")
if let first = chunks.first {
    let preview = first.content.prefix(120).replacingOccurrences(of: "\n", with: " ")
    print("🔎 [LocalExecutor/RAG] chunk[0] preview: \"\(preview)\"")
} else {
    print("🔎 [LocalExecutor/RAG] no chunks retrieved — context will be empty")
}
```

### Block 3 — after `context` is built

Immediately after `let context = chunks.map { $0.content }.joined(separator: "\n\n")`:

```swift
print("🔎 [LocalExecutor/RAG] context length=\(context.count) chars (chunks joined)")
```

That is the entire patch. Three blocks of print, no behavior change.

## Acceptance

- 4-build matrix all green (serial iOS; Release with `ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`).
- Diff strictly limited to `Shared/Runtime/Executors/LocalExecutor.swift`.
- No new types, no new imports, no signature changes, no test file additions.
- No `#if DEBUG` gating on the new prints (we want them in whatever Taka's running).

## Scope (hard)

- Touch ONLY `Shared/Runtime/Executors/LocalExecutor.swift`.
- Do NOT touch any RAG / registry / embedder / llama code; do NOT touch `ModelManager`, `NoesisCompletionPipeline`, or `LibLlama`. ALL of PR #99/100/101/102 is unaffected.
- Do NOT modify `VectorStore` even to add a property — read the existing public `chunks` count.

## Commit + PR

Single commit. Branch suggestion: `diag/localexecutor-retrieval-trace`.
PR title: `chore(diag): trace retrieval state at the LocalExecutor boundary (UAT diagnostic)`

PR body MUST include:
- A one-paragraph statement that this is a temporary diagnostic patch — to be reverted or absorbed into a real fix once the failure mode is identified
- The three print blocks shown above (verbatim)
- 4-build matrix
- Note: this PR is intentionally NOT a fix. Merge → re-run Spinoza UAT → share the new console output → real fix lands in a subsequent PR.

Do NOT merge — Taka merges, re-runs Spinoza Q1–Q5 with the UAT chat, and shares the new console output containing the `🔎 [LocalExecutor/RAG]` lines.

## Report back

- Diff (which lines added; paste the three blocks in context)
- 4-build matrix
- PR number
