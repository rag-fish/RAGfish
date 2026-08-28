# Noema Architecture Audit — Checklist v0.8 (Consulting Deliverable)

Framework: assess any AI/RAG system against governance rules G1–G6. Each rule scored on a maturity scale:
**L0** absent · **L1** convention only (docs/process) · **L2** machine-checked offline · **L3** machine-enforced at runtime.

| Rule | Audit question | Evidence requested | Typical failure observed |
|---|---|---|---|
| G1 Grounding | Can the system emit an answer with no retrieval support without labeling it? | Answer objects / logs showing citation fields; test with an out-of-corpus query | Confabulation presented as retrieval (the exact NoesisNoema v0.x incident — first-party case study) |
| G2 Version pinning | Is every answer attributable to an exact (embedder, model, corpus-manifest) triplet? | Per-answer metadata; reproduction of one historical answer | Embedder upgraded silently; historical answers unreproducible |
| G3 Promotion gate | Can corpus/index changes reach production without passing a measured retrieval-quality gate? | Gate config, gold-set, last N gate reports | "Eval exists but is not blocking" (L1 masquerading as L2) |
| G4 Change control | Are architecture and index changes forced through reviewable channels? | Branch protection settings, ADR log | Direct pushes to prod index |
| G5 Budget | Are context/token budgets enforced before inference, with defined trim behavior? | Budget config, overflow test | Silent truncation with undefined ordering |
| G6 Audit | Does every governed action leave a tamper-evident record? Can evidence be exported without exposing content? | Hash-chain verification run, sample evidence package | Logs exist but are mutable / content-leaking |

## Engagement structure (Noema Architecture Audit)

1. **Scoping (0.5 day):** system inventory, planes mapping (which components own policy/knowledge/runtime/audit — usually the audit plane is missing entirely).
2. **Assessment (1–2 days):** G1–G6 scoring with evidence; live probes (out-of-corpus query for G1, chain tamper test for G6).
3. **Report:** maturity radar (L0–L3 × 6 rules), prioritized remediation path, reference architecture (4-plane model).
4. **Demo asset:** NoesisNoema evidence package verified live, offline — differentiator: "governance without cloud."

## Honest-scope statements (include verbatim in reports)
- The local hash chain is tamper-*evident*, not tamper-*proof* against a device-root adversary holding the signing key.
- G6 coverage checking detects missing events only for declared governed actions.
- Recall@k thresholds are calibration values per corpus, not universal quality claims.
