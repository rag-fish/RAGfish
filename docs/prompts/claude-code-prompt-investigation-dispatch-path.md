# Claude Code Task — INVESTIGATION ONLY: identify the non-LocalExecutor LLM dispatch path

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main` (PR #103 merged).

## ⚠️ Hard constraints

**This task writes ZERO code.** Do not edit any source file. Do not create any branch. Do not open any PR. Do not commit anything. The deliverable is a single markdown report saved to `docs/investigations/2026-06-11-dispatch-path-investigation.md`, committed and pushed on its own branch with a PR — that file is the ONLY artifact.

If you find yourself wanting to add a `print` for diagnosis: stop. Note "would help to add a print at <file:line>" in the report instead. Taka and the design Claude will decide whether that lands in a follow-up patch.

If you find yourself wanting to refactor what you see: stop. Note it as an observation in the report.

This boundary exists because the prompt-edit-build-PR-merge-UAT round trip is expensive. We are buying information here, nothing else.

## Context (what we already know from the UAT log)

The post-PR-#103 Spinoza UAT showed Q3 ("What does Spinoza say about the third kind of knowledge?") producing this console output sequence:

```
🧠 [SESSION-MEM/COORD] request.history.count=2
🧠 [SESSION-MEM/COORD] dispatching to executor; passing history.count=2
🧠 [SESSION-MEM/EXEC] LocalExecutor.execute(history-aware) entered; history.count=2
🧠 [SESSION-MEM/EXEC] calling generateAsync with history.count=2
🎬 [LLMModel] generateAsync ENTRY POINT
   Question: 56 chars - 'What does Spinoza say about the third kind of knowledge?'
   Context: none
[RAG] context length: 0
…
🧠 [SESSION-MEM/PROMPT] buildPrompt entered; history.count=3
⚠️ [buildPrompt] WARNING: No context provided - answering without RAG
🧠 [SESSION-MEM/PROMPT] final prompt length=2139 chars
```

The PR #103 prints (`🔎 [LocalExecutor/RAG]`) are **completely absent** from this log. PR #103 added them inside `LocalExecutor.execute(...)` such that they fire unconditionally on entry. The `🧠 [SESSION-MEM/EXEC] LocalExecutor.execute(history-aware) entered` line **does** appear from `LocalExecutor`, so the executor IS being entered. Yet the `🔎` retrieval lines are not. This means one of:

  - The branch that the PR #103 prints sit in is bypassed (e.g. an early `return` or a different code path inside `execute`)
  - PR #103's prints landed in a different `execute(...)` overload than the one called
  - The build that produced this log did not include PR #103 (clean-build issue / DerivedData)

Whatever the cause, Q3 was answered with `context: none` — meaning retrieval did not feed the LLM. Q1 returned a high-quality verbatim Spinoza quote, but we don't know yet whether Q1 went through retrieval or got it from Llama 3.2 3B's general knowledge.

Also visible in the same log:
- `history.count=2` at COORD/EXEC but `history.count=3` inside buildPrompt — an off-by-one (or extra append) somewhere between dispatch and prompt construction.
- The prompt uses ChatML (`<|im_start|>system`, `<|im_end|>`, etc.) for Llama 3.2 3B Instruct, which expects Llama-3 chat template (`<|begin_of_text|>`, `<|start_header_id|>`, `<|end_header_id|>`, `<|eot_id|>`). The mismatch may be the source of the `|>` and `|>assistant` residue Taka has been seeing leak into history.

## Investigation tasks

Treat each section below as "produce a section in the report titled the same way". Use code excerpts (path:line ranges) and brief explanations. Be precise — name the function, the file, the line range. Do not paraphrase: quote the relevant ~5–20 lines verbatim.

### Section 1 — Confirm PR #103's prints are on `main` and in the right place

- Show `git log --oneline -5 main` and confirm PR #103's commit is in.
- Show the 3 print blocks in `Shared/Runtime/Executors/LocalExecutor.swift` with file:line ranges.
- Explain whether they are inside or outside any conditional / early-return scope.
- If there is more than one `execute(...)` method on `LocalExecutor` (sync vs async, different signatures, or extensions), list them all with signatures, and state which one would handle a request from the Coordinator.

### Section 2 — Map ALL call sites that invoke `LLMModel.generateAsync(...)`

Search the entire codebase for any path that ends up calling `LLMModel.generateAsync(...)`. For each call site list:
- File and line
- Caller function name
- What value is passed for `context` (literal `""`, computed string, etc.)
- The class/actor/struct chain that leads to this call (e.g. `ChatViewModel → Coordinator → LocalExecutor → LLMModel.generateAsync`)

Output as a table.

### Section 3 — Trace the request path for a Q3-style question

Starting from the user pressing send in the chat UI on macOS, trace through to `LLMModel.generateAsync`. Quote the relevant 5–15 lines at each hop. Identify:
- Where the dispatch decision happens (e.g. Coordinator decides "local vs remote", "with RAG vs without RAG")
- Whether there is ANY code path where `LLMModel.generateAsync(context: "")` is called WITHOUT going through `LocalExecutor.execute`
- The exact file:line where retrieval (`LocalRetriever.retrieve` / `VectorStore.search` / whatever it's called) is invoked

If the path through `LocalExecutor.execute` is the ONLY path, but the `🔎` prints are missing from the UAT log, then PR #103 must be on a different `execute` overload than the one called — investigate that.

### Section 4 — Account for the `history.count` jump from 2 → 3

The COORD and EXEC logs say `history.count=2`. `buildPrompt` reports `history.count=3`. Find where the +1 happens. Quote the relevant code. State whether the current question is being appended to its own history before being prompted (which would explain the +1).

### Section 5 — Where does `|>` residue come from?

The UAT log's prompt-dump shows assistant turns ending in `|>` followed by `|>assistant` on the next line. This is BERT-style ChatML residue leaked from earlier responses and accumulated in history. Find:
- The function that constructs the prompt from history (you found it in Section 3)
- The function that decodes the LLM's raw output into a string before it lands in history (clean-up steps in `NoesisCompletionPipeline` and downstream)
- Identify which step OUGHT to strip `<|im_end|>`, `<|im_start|>...`, `<|eot_id|>`, and any `|>` fragments
- State whether the current code does any such stripping, and where

### Section 6 — Confirm Q1's path matches Q3's

You don't have a Q1 log in this conversation — Taka can produce one separately. But by reading the code in Section 3, you should be able to predict:
- Will Q1 ALSO hit `context: none` and `[buildPrompt] WARNING: No context provided`?
- If yes: Q1's correct-looking Spinoza quote was Llama 3.2 3B general knowledge, not RAG.
- If no: there is a per-question branching condition. Find it. Quote it.

### Section 7 — `LLMModel.generateAsync` signature(s) and `context` parameter

Quote the full signature(s) of `LLMModel.generateAsync` (there may be variants). Note:
- Where the `context` parameter is plumbed in
- Whether there's any default value
- Whether anywhere overloads it to be optional

### Section 8 — Top 3 likely root causes, ranked

Based ONLY on what Sections 1–7 found, list the three most likely root causes of "Q3 reaches `LLMModel.generateAsync` with `context: ""` despite `LocalExecutor.execute` being entered". For each:
- Hypothesis statement
- The specific evidence in the report sections that supports it
- The minimum diagnostic or fix needed to confirm/resolve it (without writing the code — just describe it)

### Section 9 — Open questions

List anything you couldn't answer from static reading alone. Don't speculate. State which file/line you'd need a runtime trace of to answer it.

## Report format

Save as `docs/investigations/2026-06-11-dispatch-path-investigation.md` with:

- Top-of-file YAML frontmatter:
  ```
  ---
  date: 2026-06-11
  author: claude-code
  pr_context: post-#103 UAT
  scope: read-only investigation
  ---
  ```
- The 9 sections above, in order, each as `## Section N — …`
- Code blocks with language tags (`swift`)
- File:line references in the form `Shared/Foo/Bar.swift:120-140`
- Tables in markdown table syntax

## Process

1. Branch `investigate/dispatch-path` from main.
2. Read code, write report.
3. Commit only `docs/investigations/2026-06-11-dispatch-path-investigation.md`.
4. Open PR titled `docs(investigation): dispatch path & RAG retrieval bypass (no code changes)`.
5. PR body: paste Sections 8 and 9 of the report (top-3 root causes + open questions).
6. **Do NOT merge**. Taka and the design Claude read the report, then decide on the next action.

## Anti-goals

- Do not add `print` statements
- Do not edit any `.swift` file
- Do not edit `project.pbxproj`
- Do not run the app
- Do not run `xcodebuild`
- Do not speculate beyond what's in the code — note unknowns in Section 9 instead

## Report back

- PR number
- The PR body (which contains Sections 8 + 9 already)

That's it. No build matrix, no diff stats, no smoke output. Just the report.
