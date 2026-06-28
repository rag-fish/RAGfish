# Project Hermes: Execution Roadmap v2

**Status:** Active  
**Date:** 2026-06-28  
**Scope:** All four Noema repos  
**Governance owner:** Taka  
**Bridges:** [Project Charter v2](PROJECT-CHARTER-v2.md) → implementation Issues

---

## 1. Hermes Overview

Hermes is the internal codename for Project v2 of the Noema Architecture. Where Project v1 proved that local private RAG can be grounded, audited, and corrected, Hermes builds the governed infrastructure layer that makes those properties systematic and durable.

Hermes focuses on **architectural capabilities** rather than repository-centric development. Work is organised by the capability it delivers — Governance, Trust, Evidence, Performance, Observability, Multi-model Orchestration — and individual repositories participate in whichever capabilities intersect their responsibility boundary. No repository drives Hermes alone.

This document is the operational bridge between the [Project Charter v2](PROJECT-CHARTER-v2.md) and the GitHub Issues that implement it. It defines what to build first, why, which repositories are involved, and which agent is best suited for each class of work. It does not introduce new architecture or restate the ADRs.

> The [Project Charter v2](PROJECT-CHARTER-v2.md) defines what Hermes aims to achieve.  
> This document defines how Hermes will be executed.

---

## 2. Core Capability Themes

### Theme 1 — Governance

**Purpose:** Encode human approval gates structurally so they cannot be bypassed by optimisation or iteration pressure. Governance is an architectural property, not a process layer bolted on after the fact.

**Repositories:**

| Repo | Participation |
|------|--------------|
| `rag-fish/noema-agent` | Route Contract formation; policy enforcement; approval gate implementation |
| `rag-fish/NoesisNoema` | Opt-in route contract invocation; local governance signals |
| `rag-fish/RAGfish` | Route Contract v1 specification; governance ADRs |

**Expected deliverables:**

- Route Contract v1 specification (ADR or contract document in `RAGfish`)
- Human approval gate schema — which decision classes require explicit approval, in what form
- Policy enforcement contract in `noema-agent`

---

### Theme 2 — Trust

**Purpose:** Separate knowledge trust from model confidence across the full pipeline. Trust signals are evaluated at corpus ingestion time and carried through the Route Contract to the evidence artifact. High model fluency cannot silently mask low knowledge quality.

**Repositories:**

| Repo | Participation |
|------|--------------|
| `rag-fish/noesisnoema-pipeline` | Trust signal computation; RAGpack trust metadata; corpus quality gates |
| `rag-fish/noema-agent` | Trust context carry-through in Route Contract; trust surface in evidence |
| `rag-fish/NoesisNoema` | Trust context consumption at inference time |
| `rag-fish/RAGfish` | Trust context schema; ADRs for trust model |

**Expected deliverables:**

- Trust context schema (provenance, corpus quality, freshness, validation history)
- RAGpack trust metadata standard — fields, format, versioning
- Trust signal integration point in Route Contract v1
- Trust surface in evidence artifact schema

---

### Theme 3 — Evidence

**Purpose:** Make every significant decision permanently reconstructable. Evidence artifacts are first-class outputs of the governance pipeline — not log entries or metadata side effects.

**Repositories:**

| Repo | Participation |
|------|--------------|
| `rag-fish/RAGfish` | Evidence artifact schema; decision log specification; ADRs |
| `rag-fish/noema-agent` | Decision log write path; evidence artifact generation |
| `rag-fish/noesisnoema-pipeline` | Validation report format; corpus quality evidence |

**Expected deliverables:**

- Evidence artifact schema (types, required fields, provenance chain)
- Decision log specification — threshold for entry, format, durability requirement
- Validation report format for corpus quality and retrieval quality
- Asynchronous evidence write path design

---

### Theme 4 — Performance

**Purpose:** Governance must not justify avoidable latency. Caching, pre-computation of trust signals, async evidence generation, and local-first execution are engineering requirements — not optimisations to add later.

**Repositories:**

| Repo | Participation |
|------|--------------|
| `rag-fish/noema-agent` | Policy cache design; async evidence write path |
| `rag-fish/noesisnoema-pipeline` | Trust pre-computation at ingestion |
| `rag-fish/NoesisNoema` | Local-first execution; no remote latency on local path |
| `rag-fish/RAGfish` | Latency budget specification; runtime principles documentation |

**Expected deliverables:**

- Policy cache design — per user context and request class; invalidation rules
- Trust pre-computation contract — fields computed at ingestion, consumed at inference
- Async evidence write path — durability guarantee without blocking response
- Latency budget specification for governed inference

---

### Theme 5 — Observability

**Purpose:** Every pipeline execution must be traceable stage by stage. Identifier types, trace relationships, and synchronous/asynchronous boundaries must be defined before cross-component instrumentation is built.

**Repositories:**

| Repo | Participation |
|------|--------------|
| `rag-fish/RAGfish` | Observability model document; identifier schema |
| `rag-fish/noema-agent` | Trace emission; decision log integration |
| `rag-fish/NoesisNoema` | App-layer trace points |
| `rag-fish/noesisnoema-pipeline` | Pipeline trace points; validation report linkage |

**Expected deliverables:**

- Observability model v0 — `trace_id`, `request_id`, `audit_id`, `decision_id` definitions
- Trace relationship model — route events → decision logs → PR evidence → validation reports
- Synchronous vs asynchronous observability boundary specification
- Stage-level trace format for the nine governance pipeline stages (ADR-0002)

---

### Theme 6 — Multi-model Orchestration

**Purpose:** Route requests across local and remote execution modes based on policy, privacy, latency, and trust signals — without coupling routing authority to execution capability. The Route Contract is the architectural separation point.

**Repositories:**

| Repo | Participation |
|------|--------------|
| `rag-fish/noema-agent` | Remote execution; tool orchestration; route contract formation |
| `rag-fish/NoesisNoema` | Local execution; route contract consumption (opt-in) |
| `rag-fish/RAGfish` | Execution mode selection policy; routing ADRs |

**Expected deliverables:**

- Execution mode selection policy — local, remote, tool, human; selection criteria
- Local-first routing default — specification that remote is opt-in, never default
- Remote execution opt-in contract — when and how `NoesisNoema` invokes `noema-agent`
- Route Contract v1 (shared with Governance theme — the same artifact enables both)

---

## 3. Execution Order

Hermes work is sequenced so that each phase produces the foundations its successors depend on. No phase begins until the prior phase has produced durable evidence artifacts (ADRs, contract documents, or validated implementations).

```
Phase A — Governance Foundation
         │
         ▼
Phase B — Trust Foundation
         │
         ▼
Phase C — Evidence
         │
         ▼
Phase D — Performance
         │
         ▼
Phase E — Observability
         │
         ▼
Phase F — Multi-model Orchestration
```

### Phase A — Governance Foundation

**Why first:** Governance is the architectural primitive. Route Contract v1 and the approval gate schema define the contracts that all other phases must respect. Building Trust, Evidence, or Orchestration before Governance contracts are in place risks building to an unspecified interface.

**Focus:** Route Contract v1 specification; human approval gate schema; governance ADR.

**Milestone alignment:** Charter M2 — Governance pipeline contracts.

---

### Phase B — Trust Foundation

**Why second:** Trust signals flow through the Route Contract. Phase A must define the Route Contract's shape before Phase B can specify the trust context fields it carries. The pipeline's corpus quality gates feed trust metadata into the contract at inference time.

**Focus:** Trust context schema; RAGpack trust metadata standard; trust field integration in Route Contract v1.

**Milestone alignment:** Charter M3 — Trust and corpus quality.

---

### Phase C — Evidence

**Why third:** Evidence artifacts carry trust context, route decisions, and approval records. The evidence schema cannot be finalised until the Route Contract (Phase A) and trust context (Phase B) shapes are stable. The decision log specification depends on knowing what a significant decision looks like in the pipeline.

**Focus:** Evidence artifact schema; decision log specification; validation report format; async write path design.

**Milestone alignment:** Charter M2 (evidence schema) + M4 (decision log in agent).

---

### Phase D — Performance

**Why fourth:** Performance design depends on knowing what will be cached (policy decisions), what will be pre-computed (trust signals), and what will be written asynchronously (evidence). All of those shapes are defined in Phases A–C. Designing the policy cache before the policy contract is specified would produce rework.

**Focus:** Policy cache design; trust pre-computation contract; async evidence write path; latency budget.

**Milestone alignment:** Charter M6 — Performance hardening.

---

### Phase E — Observability

**Why fifth:** Observability instruments the pipeline. Identifier types, trace relationships, and the sync/async boundary can only be defined once the pipeline stages (Governance, Trust, Evidence) have stable contracts. Instrumenting an unstable contract produces brittle instrumentation.

**Focus:** Observability model v0; identifier schema; trace format; stage-level trace points.

**Milestone alignment:** Charter M5 — Observability.

---

### Phase F — Multi-model Orchestration

**Why last:** Orchestration is the runtime assembly of all prior capabilities. It requires a stable Route Contract (Phase A), trust context (Phase B), evidence write path (Phase C), performance contracts (Phase D), and trace points (Phase E). Attempting orchestration before these are in place produces an ungoverneed routing layer — which is the opposite of Hermes.

**Focus:** Execution mode selection policy; remote execution opt-in contract; routing implementation in `noema-agent`; local-first default confirmation in `NoesisNoema`.

**Milestone alignment:** Charter M4 — Orchestration layer.

---

## 4. Dependency Matrix

The table below captures known Hermes issues and their dependencies. Future issues will be added as each Phase is sequenced into GitHub Issues.

| Issue | Title | Theme | Repo | Depends On | Primary Owner | Status |
|-------|-------|-------|------|------------|---------------|--------|
| [#25](https://github.com/rag-fish/RAGfish/issues/25) | Docs: define Project v2 charter | Foundation | `RAGfish` | ADR-0001, ADR-0002 | Claude CLI | Closed |
| [#26](https://github.com/rag-fish/RAGfish/issues/26) | Docs: define Project v2 backlog and sequencing | Foundation | `RAGfish` | #25 | Claude CLI | Open |
| [#27](https://github.com/rag-fish/RAGfish/issues/27) | Docs: define observability model v0 | Observability (Phase E) | `RAGfish` | Route Contract v1, decision log stub | Claude CLI | Open |
| TBD | Docs: Route Contract v1 specification | Governance (Phase A) | `RAGfish` | ADR-0001, ADR-0002 | Claude CLI | Planned |
| TBD | Docs: human approval gate schema | Governance (Phase A) | `RAGfish` | Route Contract v1 | Claude CLI | Planned |
| TBD | Docs: trust context schema | Trust (Phase B) | `RAGfish` | Route Contract v1 | Claude CLI | Planned |
| TBD | Feature: RAGpack trust metadata standard | Trust (Phase B) | `noesisnoema-pipeline` | Trust context schema | Codex CLI | Planned |
| TBD | Docs: evidence artifact schema | Evidence (Phase C) | `RAGfish` | Route Contract v1, trust context schema | Claude CLI | Planned |
| TBD | Docs: decision log specification | Evidence (Phase C) | `RAGfish` | Evidence artifact schema | Claude CLI | Planned |
| TBD | Feature: decision log stub | Evidence (Phase C) | `noema-agent` | Decision log specification | Codex CLI | Planned |
| TBD | Docs: policy cache design | Performance (Phase D) | `RAGfish` | Route Contract v1 | Claude CLI | Planned |
| TBD | Docs: latency budget specification | Performance (Phase D) | `RAGfish` | Policy cache design, trust pre-computation | Claude CLI | Planned |
| TBD | Feature: route contract formation | Orchestration (Phase F) | `noema-agent` | Route Contract v1, trust context schema, evidence schema | Codex CLI | Planned |

> **Note:** "TBD" issues will be created as GitHub Issues in the appropriate repo when the preceding phase's evidence artifacts are complete. Issue numbering is assigned at creation time.

---

## 5. Repository Participation

Repositories in Hermes participate in capabilities rather than working independently. The same capability may require work in two or three repos simultaneously — the Route Contract spec lives in `RAGfish`, the contract formation logic in `noema-agent`, and the consumption path in `NoesisNoema`.

| Repo | Primary Role in Hermes | Themes |
|------|----------------------|--------|
| `rag-fish/RAGfish` | Architecture Hub — schemas, ADRs, specs, roadmap | All themes (documentation lead) |
| `rag-fish/noema-agent` | Orchestration Server — policy, routing, verification, evidence write | Governance, Evidence, Performance, Orchestration |
| `rag-fish/NoesisNoema` | Local Cognition Node — local execution, intent capture, trust consumption | Governance (opt-in), Trust (consumption), Orchestration |
| `rag-fish/noesisnoema-pipeline` | Corpus Production Line — trust signal computation, RAGpack quality gates | Trust, Performance (pre-computation) |

### Cross-repo coordination rule

When a capability requires work across multiple repositories, `RAGfish` produces the contract or schema document first. No repo begins implementation until the contract document exists in `RAGfish` and has been merged to main. This prevents implementation drift against unspecified interfaces.

---

## 6. AI Collaboration Model

Work in Hermes is assigned to the agent best suited to the task class. The division is not territorial — it is based on each agent's strengths.

### Claude CLI — Architecture, ADRs, Audit, Planning, Documentation

Claude is the primary author of architectural artifacts: ADRs, contract documents, schemas, roadmaps, observability models, and audit findings. Claude reasons across the full architecture and translates design decisions into durable documentation.

| Task class | Examples |
|------------|---------|
| Architecture documents | ADRs, contract specs, schema definitions |
| Planning documents | Roadmaps, sequencing, dependency analysis |
| Audit | Cross-repo consistency checks, contract conformance |
| Documentation | Human-governed loop updates, observability model |

### Codex CLI — Implementation, Tests, Validation, Refactoring

Codex is the primary implementor of code-level changes: feature implementation, test coverage, data format implementation, and targeted refactors. Codex works from specifications produced by Claude and confirmed by Taka.

| Task class | Examples |
|------------|---------|
| Feature implementation | Decision log stub, Route Contract formation, trust metadata fields |
| Tests | Unit and integration tests for pipeline stages |
| Validation | Latency benchmarks, corpus quality validation |
| Refactoring | Targeted refactors within a single repo boundary |

### Human (Taka) — Governance, Review, Merge, Prioritisation

Taka is the governance owner. All merges require Taka's review. Architecture decisions are not authoritative until Taka has accepted them. Prioritisation of planned issues is Taka's decision.

| Task class | Examples |
|------------|---------|
| Review | PR review for every merge |
| Merge | All merges to main, all repos |
| Architecture approval | Accepting ADRs and contract documents |
| Prioritisation | Deciding which planned issue is sequenced next |

---

## 7. Development Lifecycle

Every capability in Hermes follows this lifecycle. No work bypasses any stage.

```
Capability identified
        │
        ▼
GitHub Issue created (scope, DoD, branch, owner agent)
        │
        ▼
Branch created (docs/<name> or feature/<name>)
        │
        ▼
Implementation (Claude: docs/specs; Codex: code/tests)
        │
        ▼
Pull Request opened (linked to Issue, validation performed)
        │
        ▼
Human Review (Taka reviews; feedback incorporated)
        │
        ▼
Merge to main (Taka merges; squash strategy)
        │
        ▼
Evidence recorded (ADR, contract, or implementation now in main)
        │
        ▼
Architecture evolution (future ADRs and Issues cite this record)
```

Every merged PR is a permanent evidence artifact. The commit history, linked Issue, and PR body together form the decision record for that piece of work. This is the governance pipeline applied to its own development.

The full task lifecycle specification — issue fields, branch naming, PR templates, CLI automation — is in [human-governed-loop.md](../human-governed-loop.md).

---

## 8. Future Expansion

Hermes is not the final phase of the Noema Architecture. Future projects — the working name for the next phase is Athena — should extend Hermes rather than replace it.

Extension means:

- Hermes capabilities (Governance, Trust, Evidence, Performance, Observability, Orchestration) remain the foundation
- New capabilities are added as new themes, not as replacements for existing ones
- ADRs from Hermes remain authoritative; new projects supersede specific decisions by citing the prior ADR explicitly
- The Human-Governed Loop, the four-repo structure, and the governance pipeline are invariants — they are not renegotiated by future projects

The architectural record built in Hermes — ADRs, contracts, schemas, evidence artifacts — is the starting point for every future project. A system that cannot trace its own evolution cannot be trusted to govern cognition.

---

## Related Documents

- [Project Charter v2](PROJECT-CHARTER-v2.md) — vision, mission, principles, success criteria
- [ADR-0001: Noema Architecture as Governed Multi-Model Cognition](../adr/ADR-0001-noema-architecture.md)
- [ADR-0002: Noema Governance Pipeline](../adr/ADR-0002-noema-governance-pipeline.md)
- [Human-Governed Development Loop](../human-governed-loop.md)
- [Product Constitution (ADR-0000)](../../adr/adr-0000-product-constitution.md)
- GitHub Issue: [rag-fish/RAGfish#26](https://github.com/rag-fish/RAGfish/issues/26)
