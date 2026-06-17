# ADR-0011 (Update): Retrieval Quality Recovery & On-Device Context Budget

**Status:** Accepted
**Date:** 2026-06-17
**Deciders:** Taka, Max (co-engineering reviewer)
**Supersedes (partial):** the "missing-prefix" root-cause hypothesis recorded in the PR #21 audit (corrected below)
**Scope of this update:** retrieval quality (text + embedding geometry) and multi-turn context-overflow on device. Generation-pipeline repair (PRs #107–#111) is unchanged and remains the prior body of ADR-0011.

---

## Context

After the generation pipeline was repaired (PRs #107–#111), retrieval quality remained poor on two axes simultaneously: correct chunks did not rank highly, and relevant chunks were often not retrieved at all. A subsequent device UAT then surfaced a second, independent failure: multi-turn conversations aborted with "exceeded context window" on iPhone, even though the same questions succeeded as single turns.

Investigation revealed that "poor retrieval" was not one problem but **two stacked defects**, and that the device failure was a **third, separate** problem rooted in an environment-specific constant. Each is documented below with the evidence that settled it.

The campaign also established a measurement-driven decision practice (the "modern UAT" goal): no major parameter was chosen by intuition; each was fixed against on-device numbers.

---

## Problem 1 — Retrieval quality: two stacked defects

### 1a. Document text was whitespace-stripped (the real root cause)

The shipped RAGpacks were built with `pypdf.extract_text()`, which collapsed word boundaries into spaceless token-soup (e.g. `Spinozaisoneofthosegreatmen`). Because the **same text field fed both the embeddings and `chunks.json`**, the embeddings were computed on garbled input — doubly compromised. nomic-embed-text-v1.5 maps spaceless soup to near-identical directions, destroying per-document signal.

**Verdict:** extraction defect, confirmed end-to-end (pypdf `extract_text()` at notebook cell 11). The chunker was exonerated — it only slices; gpt2 is used for token *counting*, never detokenization.

### 1b. Embedding anisotropy (intrinsic, initially misdiagnosed)

Raw-vector analysis of a shipped pack showed an apparent "collapse":

| Metric | Measured (broken pack) | Healthy expectation |
|---|---|---|
| mean-vector norm | 0.893 | < 0.3 |
| min cos(chunk, global-mean-dir) | 0.744 (no exceptions) | scattered |
| effective dim (participation ratio) | 71.9 / 768 | hundreds |
| intra-pack off-diagonal cos | 0.79 | ~0.3–0.5 |

The **initial hypothesis was a missing `search_document:` prefix**. This was wrong and is hereby corrected: the prefix was present and correct from the embedder's first commit. The "collapse" is partly the spaceless-text defect (1a) and partly **intrinsic anisotropy of nomic-embed-text-v1.5** — verified by embedding 10 maximally-unrelated sentences and still observing eff-dim 8.4/768. Anisotropy is a property of the model, not a bug in the pack, and **cannot be removed by fixing extraction**. It is removed at query time by mean-centering.

Removing the common direction restored health: off-diagonal cos → −0.002 (orthogonal), and the top-1 vs top-10 score gap widened 2–18× (e.g. 0.059 → 0.347), i.e. retrieval could finally discriminate by content.

---

## Problem 2 — Multi-turn context overflow on device

Device UAT: a question that succeeded as a single turn failed as the 4th turn of a conversation with "exceeded context window." Root-cause audit (PR #115) established:

- **Device `n_ctx` = 1024** (`LibLlama.swift:131`), while **macOS used 4096** — a silent 4× environment difference. Effective prompt budget on device ≈ 768 (1024 − n_len 256).
- Chat history was capped by **turn count (≤3) but not by token volume**; full prior turns were replayed verbatim.
- The pre-decode check was a **tripwire that rejected** the request, not a budget manager that trims — pushing cleanup onto the user ("clear chat history").
- Two divergent generation paths existed (`ModelManager.generateAsyncAnswer` vs the coordinator path), risking fix drift.

This is distinct from PR #111 (a stop-condition bug). Here the cause is **unbounded history growth against an environment-specific, too-small `n_ctx`.**

---

## Decision

Adopt a **clean separation of responsibility** across the two repositories, and make the device context budget **measured, not assumed**.

1. **Text quality is the pipeline's responsibility.** Replace pypdf with a measured-best extractor; add a fail-loud quality gate so a broken extraction can never ship again.
2. **Embedding geometry (anisotropy) is the app's responsibility.** Apply manifest-gated mean-centering at import and at query time, per pack. **Do not** add mean-centering to the pipeline (rejected — see trade-offs).
3. **Context budget is owned by a single point in the app's shared pipeline.** Replace reject-on-overflow with trim-to-fit, and raise device `n_ctx` to a value validated by on-device measurement.

---

## Options Considered

### Embedding correction: where does mean-centering live?

#### Option A: App-side, manifest-gated (CHOSEN)
| Dimension | Assessment |
|---|---|
| Complexity | Low–Med (single helper) |
| Correctness | Per-pack mean owned at import; query corrected with the same mean |
| Risk | Gated by `mean_centered` flag → no double-correction |

**Pros:** correction lives in the retrieval layer where it belongs; per-pack independence; legacy packs recovered without regeneration.
**Cons:** packs imported before the change keep raw vectors until re-imported (manual re-import).

#### Option B: Pipeline-side mean-centering (REJECTED)
**Pros:** new packs ship "de-anisotropized."
**Cons:** duplicates the correction across two repos; breaks the per-pack mean ownership the app design depends on; makes double-correction a permanent coordination hazard; violates layer separation (pipeline owns text, not retrieval-time geometry).

### Text extraction: which extractor? (bake-off on the real Ethics PDF)

| Extractor | ws_ratio | dict_hit | max_tok | sec | Verdict |
|---|---|---|---|---|---|
| pypdf default (broken) | 0.001 | 0.115 | 2183 | 3.6 | catastrophic |
| pypdf layout | 0.364 | 0.872 | 77 | 4.2 | rejected — over-pads, ws out of band |
| pdfplumber | 0.132 | 0.796 | 64 | 14.8 | slower, lower quality |
| **pymupdf (fitz)** | **0.144** | **0.887** | **27** | **0.9** | **winner** |

The pre-registered caution was vindicated: pypdf "layout" mode regressed rather than fixed.

### Device `n_ctx`: chosen by on-device measurement (iPhone 17 Pro Max, 12GB)

5-question sequential UAT with accumulating capped history (the faithful production path), per `n_ctx` level:

| n_ctx | answered | BAIL | loaded | peak_gen | prompt_eval_ms | tok/s | total_ms/Q |
|---|---|---|---|---|---|---|---|
| 1024 | 4/5 | **1** | 525.8MB | 883.4MB | 4548.9* | 13.83* | 12445.2* |
| 2048 | 5/5 | 0 | 360.8MB | 576.6MB | 12841.0 | 11.03 | 20351.4 |
| **4096** | **5/5** | **0** | 583.9MB | 793.6MB | 12486.1 | 11.60 | 19083.7 |
| 8192 | 5/5 | 0 | 1215.2MB | 1572.6MB | 12770.2 | 11.64 | 19479.1 |

\*1024's "fast" means are an artifact: one question BAILed and was excluded from latency means.

**Reading:** memory is a non-constraint (max 1.57GB vs a ~4.5GB safe line on 12GB). Latency *plateaus* from 2048 upward, because `n_ctx` is container size while real prompts are only ~1400–1772 tokens — a larger container adds essentially no compute. Only 1024 BAILs.

**Chosen: 4096.** Zero latency/memory penalty versus 2048, but leaves ~3840 prompt budget — headroom to grow RAG context later. 8192 adds cost-free capacity that nothing will use in the foreseeable term (KV cache idling at 1.2GB) and was declined as over-spec.

---

## Trade-off Analysis

- **Two-repo layering vs convenience.** Keeping text-quality (pipeline) and geometry (app) strictly separate costs a manual re-import step for legacy packs, but avoids a permanent double-correction coordination hazard. The separation was the single most important architectural choice of the campaign.
- **Trim vs reject on overflow.** Trimming history (newest-first kept, oldest dropped) while protecting RAG context and the generation reserve produces a "best-effort history, guaranteed answer" UX. The cost is silent loss of old conversational context — acceptable for a document-QA app.
- **4096 everywhere vs adaptive.** A single safe 4096 is simplest and is proven safe on the top device. It is **not yet proven on minimum-spec devices** — see Action Items.

---

## Consequences

**Easier**
- Retrieval discriminates by content (off-diag cos 0.79 → ~0.12 after centering; device top-1 returns content, not front-matter).
- Multi-turn conversations no longer abort: 5-question sequential device run returns all 5, BAIL = 0, including the Latin "Substantia" at the final turn.
- Bad extractions cannot ship: fail-loud gate (hard floor 0.80, warn band 0.80–0.90, OK ≥ 0.90) at the UAT/reporting layer; the pipeline build floor stays at 0.60 to avoid false-rejecting valid noisy scans.
- A reusable measurement harness (footprint + latency, DEBUG-gated) now exists for future parameter decisions.

**Harder / to revisit**
- Legacy packs must be **manually re-imported** to gain mean-centering (no in-place migration).
- A new pack must emit `mean_centered: false` (or omit it) so the app applies correction; mislabeling a pack `true` would silently skip correction.
- 4096 on minimum-spec devices is **unverified** and may force the adaptive-`n_ctx` work sooner.

**Corrected record**
- The PR #21 "missing `search_document:` prefix" verdict is **superseded**: the prefix was always correct; the collapse was spaceless text (extraction) plus intrinsic nomic anisotropy (model property). Recorded deliberately as an intellectual-honesty trail — the measured collapse was real, but the cause was re-attributed correctly.

---

## Key lessons (carry forward)

1. **Symptoms can stack.** "Poor retrieval" was text-quality AND embedding-geometry. Fixing one alone would have looked like partial failure.
2. **Implicit constants differ by environment.** `n_ctx` was 1024 on iOS but 4096 on macOS — a 4× gap that hid until a device multi-turn test. Audit environment-specific defaults explicitly.
3. **Measure, don't assume.** `n_ctx` was chosen from a footprint+latency table, not intuition. The harness made "memory is a non-constraint; latency plateaus" visible — and refuted the earlier worry that raising `n_ctx` would be costly.
4. **Hold the layer boundary.** Rejecting pipeline-side mean-centering kept correction in one place and prevented a double-correction class of bug.
5. **Logic-level UAT is necessary but not sufficient.** XCTest (11/11) passed while the real multi-turn overflow bug existed, because unit tests ran isolated questions. The accumulating-history device run is what exposed it.

---

## Implementation map (PRs)

| Repo | PR | Change |
|---|---|---|
| noesisnoema-pipeline | #21 | Root-cause audit (later corrected re: anisotropy) |
| noesisnoema-pipeline | #22 | pymupdf extractor + fail-loud quality gate |
| noesisnoema-pipeline | #24 | Self-verifying notebook UAT cell (visual evidence) + dict_hit 0.80 floor + warn band |
| NoesisNoema | #112 | Retrieval root-cause audit |
| NoesisNoema | #113 | Manifest-gated mean-centering (import + query, per-pack) |
| NoesisNoema | #114 | Logic-level retrieval UAT (XCTest, 11/11) |
| NoesisNoema | #115 | Multi-turn context-overflow root-cause audit |
| NoesisNoema | #116 | n_ctx footprint + latency harness (DEBUG-gated, 4 levels) |
| NoesisNoema | #117 | Token-budget manager (trim, not reject) + device n_ctx → 4096 |

---

## Action Items

1. [ ] Merge order: #116 → #117 (stacked); #24, #112, #113, #114, #115 independent.
2. [ ] Verify 4096 is safe on the **minimum supported device**; if not, promote device-RAM-adaptive `n_ctx` (12GB→4096/8192, 6GB→2048, …) to the immediate next task. (Separate future ADR.)
3. [ ] Add `query_prefix` / `doc_prefix` / quality flags to the manifest schema so the app can loudly refuse or correct mismatched packs (currently relies on convention).
4. [ ] Re-import any legacy packs to apply mean-centering (no in-place migration exists).
5. [ ] Tag **v0.4** once the above merges land and the device 5-question run is confirmed green.
6. [ ] (Investigate) Device pack showed `chunks: 6649` during measurement vs the 417-chunk Ethics pack — confirm whether multiple packs are loaded unintentionally.
