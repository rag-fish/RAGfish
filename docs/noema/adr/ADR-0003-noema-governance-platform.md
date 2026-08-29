# ADR-0003: Noema Architecture v0.8 — Governance Platform

**Status:** Proposed
**Date:** 2026-07-02 (JST)
**Deciders:** Human governance owner, Architecture reviewer
**Supersedes:** extends ADR-0011 (semantic embedding, layer separation). ADR-0011 remains valid.
**Drafted as:** ADR-0012 (v0.8 design session, 2026-07-02); renumbered into the Noema ADR lineage.

## Context

Through v0.4, Noema Architecture enforced its core philosophy — "AI is not the subject; AI is a tool executed under human-controlled policy" — only by convention: branch protection, ADR discipline, manifest-gated normalization. Nothing in the system *mechanically* enforces it. Two incidents motivate hardening:

1. The v0.x silent-import failure produced months of LLM confabulation presented as RAG answers (fixed in ADR-0011). Grounding was assumed, never verified.
2. Retrieval quality regressions (PDF extraction, anisotropy) were caught by manual investigation, not by any gate.

v0.8 makes governance a first-class, machine-enforced layer. Scope decision (2026-07-02): **architecture-complete and pipeline-complete**; runtime (Swift) enforcement is specified here but implemented in v0.9. The spec serves two deliverable streams: (a) NoesisNoema product capability, (b) Noema Architecture Audit consulting framework.

Constraints carried forward:
- NoesisNoema app is strict pure-Swift (no Python, no subprocess, no PythonKit).
- Pipeline owns text quality; app owns retrieval geometry (ADR-0011 layer separation preserved).
- noesisnoema-pipeline main is branch-protected (PR required); RAGfish main accepts direct commits.
- Audit must never require cloud storage.

## Decision

Adopt a **four-plane model** with six machine-checkable governance rules (G1–G6).

| Plane | Owner | Implementation | v0.8 status |
|---|---|---|---|
| Policy | Human | Declarative YAML manifest (`noema-policy.yaml`), sha256-pinned by consumers | Implemented (schema + v0.8.0 instance) |
| Knowledge | Pipeline | Python; RAGpack v1.3 (provenance, license, integrity, promotion fields) | Implemented |
| Runtime | NoesisNoema | Pure Swift; G1/G5 enforcement + G6 emission | **Spec only → v0.9** |
| Audit | Both | Append-only hash-chained JSONL; Ed25519-signed evidence packages | Pipeline side implemented; runtime side v0.9 |

### Governance Rules

| Rule | Statement | Enforcement point |
|---|---|---|
| G1 | No ungrounded generation: every answer carries chunk-level provenance meeting the policy threshold, or is explicitly labeled `model-only`. | Runtime (v0.9) |
| G2 | Version pinning: every answer records the `(embedder_id, model_id, manifest_sha256)` triplet. | Runtime (v0.9); pipeline stamps manifest |
| G3 | Promotion gate: a RAGpack may be promoted only if gold-set Recall@k ≥ policy threshold. | Pipeline (v0.8) |
| G4 | Change control: architecture changes via ADR; pipeline main via PR only. | Process (existing, now codified) |
| G5 | Budget enforcement: token/context budgets enforced pre-inference. | Runtime (v0.9; generalizes existing token-budget manager) |
| G6 | Audit completeness: every governed action emits an audit event; a missing event makes the run invalid. | Pipeline (v0.8), Runtime (v0.9) |

### Key design choice: governance without runtime humans

Ordinary queries pass **zero** human gates. Governance is achieved by *ex-ante policy* (manifest) plus *ex-post verifiable audit* (hash chain). A Human Decision Gate exists only for policy changes and pack promotion approval. This is the condition under which an on-device product remains usable.

### Audit storage

On-device by default. Export is explicit, optional, and produces a cryptographically verifiable **evidence package** (see spec-audit-pipeline.md): content-redacted by default (hashes only), Ed25519 detached signature, offline-verifiable. Cloud storage is never required.

## Options Considered

### Option A: Runtime human-in-the-loop gates
| Dimension | Assessment |
|---|---|
| Governance strength | High (per-answer approval) |
| Latency / UX | Fatal for on-device assistant |
| Complexity | Medium |

**Rejected.** Destroys the product; conflates governance with supervision.

### Option B: Cloud audit service
| Dimension | Assessment |
|---|---|
| Verifiability | High (server-side trust anchor) |
| Privacy | Violates local-first principle and core philosophy |
| Cost / ops | New infra burden for a solo founder |

**Rejected.** A governance platform that leaks data to govern it is self-refuting.

### Option C (chosen): Ex-ante policy + ex-post verifiable local audit
| Dimension | Assessment |
|---|---|
| Governance strength | High for accountability; medium for prevention (G1/G5 add runtime prevention in v0.9) |
| Latency | Zero human latency on query path; hash-chain append is O(1) |
| Complexity | Low-medium; pure-Swift-compatible (CryptoKit) |
| Consulting value | G1–G6 map 1:1 to an audit checklist (sellable artifact) |

## Trade-off Analysis

- **Prevention vs. accountability:** v0.8 buys accountability (audit) before prevention (runtime gates). Acceptable because the pipeline gate (G3) already prevents the worst failure class (bad packs shipping), and confabulation labeling (G1) follows in v0.9.
- **Hash chain vs. Merkle tree:** linear chain chosen. Verification is O(n) but n is small (device-local events); Merkle adds complexity with no consumer for partial proofs yet. Revisit if evidence packages exceed ~10^6 events.
- **Ed25519 vs. platform attestation (DeviceCheck/App Attest):** Ed25519 is offline-verifiable, cross-platform (Python `cryptography` now, Swift CryptoKit in v0.9), and consulting-demo friendly. App Attest binds to Apple infra — deferred, noted as v1.x option.
- **Recall@k as sole promotion metric:** deliberately narrow. Precision/faithfulness metrics deferred to keep the gate cheap and unambiguous. Threshold (default 0.80@k=5) is an initial calibration value, policy-configurable, to be re-baselined after the first gold-set run — not a claim of empirical validity.

## Consequences

Easier:
- Confabulation incidents become detectable (G6 + G2) and, from v0.9, labeled at answer time (G1).
- The existing LOW-priority follow-up "gold-set Recall@k" is promoted to a mandatory gate — quality regressions like the pypdf/anisotropy chain get caught pre-promotion.
- Consulting stream gets a concrete, demonstrable artifact: evidence package + checklist.

Harder:
- Pack promotion gains friction (gold-set required per corpus domain).
- Manifest schema hardening (existing MED follow-up) becomes a **prerequisite**, not optional.
- Two audit emitters (Python now, Swift later) must stay byte-compatible on canonical JSON — cross-language canonicalization (RFC 8785) is a known risk; conformance vectors required.

Revisit:
- v0.9: runtime enforcement (G1/G5/G6-runtime) per spec-runtime-v0.9-handover.md.
- Threshold calibration after first three gated promotions.
- chunks:6649 anomaly (open MED follow-up) — fold into first Auditor drift report.

## Action Items
1. [ ] Commit this ADR + policy manifest + BPMN to RAGfish (direct commit; prompt A).
2. [ ] Pipeline PR: manifest v1.3 validator, G3 gate CLI, audit emitter + verifier, tests (prompt B).
3. [ ] Commit runtime v0.9 spec to NoesisNoema as docs-only PR (prompt C).
4. [ ] Build first gold-set (≥30 queries) for the primary corpus; run calibration.
5. [ ] Generate demo evidence package for consulting collateral.
