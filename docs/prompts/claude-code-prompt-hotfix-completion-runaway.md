# Claude Code Task — NoesisNoema hotfix #4: stop the KV-cache overflow runaway (UAT blocker)

Local repo: `/Users/raskolnikoff/Xcode Projects/NoesisNoema`. Branch off `main` (PR #101 just merged).

## Bug (release blocker, surfaced after PR #101)

After PR #101 made the LLM dispatch correct (Llama 3.2 3B), the **5th question** in Taka's Spinoza UAT hung the runtime. Xcode console log:

```
init: the tokens of sequence 0 in the input batch have inconsistent sequence positions:
  - the last position stored in the memory module of the context (i.e. the KV cache) for sequence 0 is X = 4095
  - the tokens for sequence 0 in the input batch have a starting position of Y = 910640
  it is required that the sequence positions remain consecutive: Y = X + 1
decode: failed to initialize batch
llama_decode: failed to decode, ret = -1
failed to evaluate llama!
[909790 tokens...]
```

Y kept incrementing one at a time (910640 → 910641 → 910642 → 910643 → 910644 → 910645 …). The `[909790 tokens...]` line is `NoesisCompletionPipeline.swift`'s 10-token progress print — the generation loop iterated ~910k times after the decode error, never stopping.

The decisive symptom: KV cache stuck at X = 4095 (= n_ctx 4096 − 1), Swift-side `n_cur` runaway into the hundreds of thousands. Q1–Q4 all returned answers, including Q1's clean verbatim Spinoza quote ("Substance, or God, or Nature, is that which is conceived through itself, and is conceived through itself alone." — Part I, Definition 3), proving the embedder/registry/RAG path is correct end-to-end. Q5 is purely a runtime-loop hazard.

## Root cause: three composing bugs in `Shared/Llama/LibLlama.swift`

### B1 — `completion_init` does NOT bail when `n_kv_req > n_ctx`

```swift
let n_ctx = llama_n_ctx(context)
let n_kv_req = tokens_list.count + (Int(n_len) - tokens_list.count)
if n_kv_req > n_ctx {
    print("error: n_kv_req > n_ctx, the required KV cache size is not big enough")
    // ← only prints; execution continues into llama_decode below
}
// ...
if llama_decode(context, batch) != 0 {
    print("llama_decode() failed")
    // ← prints; n_cur is then set from batch.n_tokens regardless
}
n_cur = batch.n_tokens   // ← Swift now believes cur position = prompt token count (e.g. 13,000)
                         //    even though llama.cpp's KV cache stopped at 4095
```

Multi-turn (ADR-0009) accumulates 3 prior Q/A turns; each retrieved RAG context is ~2,500 tokens (5 chunks × 512). By Q5 the rendered ChatML prompt easily reaches 12–13k tokens — well past n_ctx=4096 on macOS.

### B2 — `completion_loop` swallows decode failure

```swift
if llama_decode(context, batch) != 0 {
    print("failed to evaluate llama!")
    // ← no `is_done = true`, no return; loop keeps going
}
return new_token_str
```

Combined with B1, every iteration calls `llama_batch_add(&batch, new_token_id, n_cur, [0], true)` with an ever-increasing `n_cur` that's already out of sync with the KV cache. llama.cpp emits the "inconsistent sequence positions" error on every iteration, but the Swift loop never observes it.

### B3 — `n_cur == n_len` is an equality, not `>=`

```swift
if llama_vocab_is_eog(vocab, new_token_id) || n_cur == n_len {
    is_done = true
    // ...
}
```

If anything pushes `n_cur` past `n_len` (e.g. starting from a bad n_cur after B1, or any future skip), the equality is never true and only EOG can stop the loop. With B2 swallowing decode failures, EOG sampling is also unreliable. Result: unbounded loop.

The three bugs only compose into a runaway under specific conditions (over-budget prompt + decode error not propagated + equality cutoff). Q1–Q4 stayed under n_ctx in their individual rendered prompts, so the chain didn't trip until Q5.

## Fix policy (minimum surgical, release-blocker priority)

Touch ONLY `Shared/Llama/LibLlama.swift`. All three fixes go in one PR. **Do not** redesign history budgeting in this PR — that's a follow-up.

### Fix B1 — bail out when the prompt does not fit

Replace the `if n_kv_req > n_ctx { print(...) }` block with a hard return + `is_done = true`, so the caller's `while !ctx.is_done` exits immediately. The function is `func completion_init(text:)` returning `Void`, so set an internal error string we can surface, OR just log + set `is_done = true` + clear `tokens_list` so the loop body has nothing to do. **Recommended**: add a stored property `last_error: String?` and set it on bail-out; expose a getter `func get_last_error() -> String?`. Then change the signature of `completion_init` from `func completion_init(text: String)` to `func completion_init(text: String) -> Bool` (returns true on success, false on bail). Update the single call site in `NoesisCompletionPipeline.swift` accordingly:

```swift
let initOK = await ctx.completion_init(text: prompt)
if !initOK {
    let err = await ctx.get_last_error() ?? "unknown init error"
    print("⚠️ [NoesisCompletion] completion_init bailed: \(err)")
    // skip the loop; return a user-visible message via the same return path
    return "The question exceeded the model's context window. " +
           "Try a shorter question or clear chat history."
}
```

In `completion_init`:

```swift
let n_ctx = llama_n_ctx(context)
let n_prompt = tokens_list.count
let n_kv_req = n_prompt + Int(n_len)   // prompt tokens + tokens we want to generate
if n_kv_req > Int(n_ctx) {
    last_error = "prompt + n_len (\(n_kv_req)) exceeds n_ctx (\(n_ctx))"
    print("⚠️ [LlamaContext] \(last_error!) — aborting completion_init")
    is_done = true
    return false
}
// ... existing decode path unchanged
if llama_decode(context, batch) != 0 {
    last_error = "llama_decode failed during completion_init"
    print("❌ [LlamaContext] \(last_error!)")
    is_done = true
    return false
}
n_cur = batch.n_tokens
is_done = false
return true
```

### Fix B2 — abort the loop on decode failure

In `completion_loop`, after the `llama_decode` call at the bottom:

```swift
if llama_decode(context, batch) != 0 {
    last_error = "llama_decode failed in completion_loop at n_cur=\(n_cur)"
    print("❌ [LlamaContext] \(last_error!)")
    is_done = true
    return ""    // ← caller observes is_done on the next iteration and exits
}
```

(`new_token_str` does NOT get returned on this failure path; the empty return is fine — `NoesisCompletionPipeline.swift` skips empties via `if chunk.isEmpty { continue }`, and on the next iteration `while !ctx.is_done` is false.)

### Fix B3 — make the cutoff `>=`

```swift
if llama_vocab_is_eog(vocab, new_token_id) || n_cur >= n_len {
    // ...
}
```

One-character change; the only purpose is to guarantee termination even if `n_cur` ever drifts past `n_len`.

## Acceptance

- Add a small unit/smoke test (same `#if DEBUG` pattern as #99/#100/#101) that:
  1. Constructs a synthetic over-budget prompt (e.g. ~5000-char string for the actor's smoke test, or just exercise the bail-out branch directly via a test seam if `last_error` is observable).
  2. Asserts `completion_init` returns `false`, `last_error` is non-nil, `is_done == true`, and a subsequent `completion_loop` returns "" without crashing.
- All 4 builds green (serial iOS; Release with `ARCHS=arm64 ONLY_ACTIVE_ARCH=NO`).
- Manual UAT verification deferred to Taka: re-run the 5-question Spinoza UAT; Q5 must either answer briefly or print the "exceeded the context window" message — never hang, never emit `[N tokens...]` past `n_len`.

## Scope (hard)

- Touch ONLY:
  - `Shared/Llama/LibLlama.swift` (the three fixes + `last_error` + `get_last_error()` + signature change of `completion_init`)
  - `Shared/Llama/NoesisCompletionPipeline.swift` (the call-site update for `completion_init`'s new return value)
  - Optionally a new `Apps/macOS/NoesisNoema/Tests/LibLlamaCompletionBailTests.swift` matching the existing test placement pattern (synchronized group; no pbxproj edit needed)
- Do NOT touch:
  - sampling configuration, sampler chain, batch allocation, tokenizer, model loading — they are correct
  - any RAG / registry / embedder code (PR #99–#101 just stabilized them)
  - history budgeting in `ChatViewModel` or wherever ADR-0009 caps live — that is a SEPARATE follow-up PR (see Anti-goals)
- Pure Swift; no new dependencies; no changes to llama.cpp C bindings.

## Commit + PR

Single commit acceptable. Branch suggestion: `fix/completion-runaway`.
PR title: `fix(llama): bail on KV-cache overflow + propagate decode failure (UAT blocker)`

PR body MUST include:
- The Q5 Xcode console error block (verbatim)
- The Q1 success block from the UAT screenshot (the verbatim Spinoza quote) as evidence the rest of the stack is correct
- The three-bug analysis (B1/B2/B3) with the line citations
- The behavioural change: over-budget Q5 now returns "The question exceeded the model's context window. Try a shorter question or clear chat history." instead of looping
- 4-build matrix
- Note: this PR does NOT change history budgeting — a follow-up PR is needed to cap history by token budget rather than turn count (ADR-0009 follow-up)

Do NOT merge — Taka merges, re-runs Spinoza Q1–Q5 UAT to confirm graceful termination.

## Anti-goals (explicit out of scope, follow-up PRs)

- **History token budgeting (ADR-0009 follow-up)**: the real underlying issue is that 3 turns × ~2500-token RAG context blows past n_ctx=4096. The right long-term fix is to cap history by token budget (e.g. ≤ 30% of n_ctx), not by turn count. This PR makes the failure graceful; the follow-up PR makes the failure rare.
- **Bumping n_ctx beyond 4096**: tempting but expensive (memory + latency). Defer until the budgeting fix is in.
- **Prompt truncation / sliding window**: a more user-friendly response than "exceeded the context window" would be auto-truncation. Out of scope here — that requires deciding which parts of the prompt to drop (system? oldest history? RAG context?). One ADR's worth of design.

## Orthogonal findings (report only, do NOT fix)

- `n_len` derivation in `completion_init` is currently `tokens_list.count + (Int(n_len) - tokens_list.count)` which simplifies to just `Int(n_len)` — likely a copy-paste leftover. Worth simplifying in a future cleanup; functionally equivalent today.
- The `n_decode` counter inside the actor is incremented but never read. Dead instrumentation; flag for cleanup.

## Report back

- Diff per file (file list + per-file size of change)
- The smoke output (over-budget bail-out demonstration)
- 4-build matrix
- PR number
