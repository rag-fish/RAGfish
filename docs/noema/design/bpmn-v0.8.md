# BPMN v0.8 — Governed Processes

Two processes. Human tasks appear ONLY in P1 (promotion) and on policy changes — the runtime query path (P2) has zero human gates by design.

## P1: Pack build & promotion (Knowledge plane)

```mermaid
flowchart LR
  A[Ingest sources] --> B[Curate\npymupdf extraction]
  B --> C[Build RAGpack v1.3\nmanifest + integrity hashes]
  C --> D{G3 gate\nRecall@k >= threshold?}
  D -- fail --> E[Reject\naudit: gate.run fail]
  E --> B
  D -- pass --> F[[Human approval\ngate.stamp --approved-by]]
  F --> G[Promote\nstatus=promoted]
  G --> H[(Audit chain\npack.build / gate.run / gate.stamp / pack.promote)]
```

Changes vs v0.4 flow: G3 decision gate inserted before promotion; human approval is a stamped, audited task; every step emits chained events.

## P2: Runtime query (Runtime plane — spec now, enforcement v0.9)

```mermaid
flowchart LR
  Q[User query] --> R[Retrieve\nmean-centering per manifest]
  R --> S{G1 provenance\nchunks cited >= policy min?}
  S -- yes --> T[Generate\ngrounded answer + citations]
  S -- no --> U[Generate\nlabel: model-only]
  T --> V[(Audit event\nquery.generate + triplet)]
  U --> V
  Q -.-> W{G5 budget\nn_ctx 4096, oldest-first trim}
  W -.-> R
```

Notes:
- G1 does not block generation; it forces honest labeling. Blocking mode is a policy option deferred to v0.9 discussion.
- G5 wraps the existing token-budget manager; no new runtime behavior, only policy-sourced parameters.

## P3: Policy change (Policy plane)

```mermaid
flowchart LR
  P1[Draft policy edit] --> P2[[Human decision gate\nADR if architectural]]
  P2 --> P3[Commit to RAGfish\nnew sha256]
  P3 --> P4[Consumers re-pin sha256]
  P4 --> P5[(Audit event\npolicy.change)]
```
