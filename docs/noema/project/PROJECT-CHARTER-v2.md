# Project Charter v2

**Status:** Active  
**Date:** 2026-06-28  
**Scope:** All four Noema repos  
**Governance owner:** Taka

---

## Overview

This document is the primary strategic document for Project v2. It establishes the vision, mission, principles, and success criteria for the next phase of the Noema Architecture. It does not replace the ADRs — it anchors them.

This charter should be read alongside:

- [ADR-0001: Noema Architecture as Governed Multi-Model Cognition](../adr/ADR-0001-noema-architecture.md) — four-repo physical structure and responsibility model
- [ADR-0002: Noema Governance Pipeline](../adr/ADR-0002-noema-governance-pipeline.md) — how the system evaluates, routes, executes, and produces verifiable outcomes
- [Human-Governed Development Loop](../human-governed-loop.md) — task lifecycle, branch naming, issue and PR discipline

> **Codename note:** "Hermes" is the internal codename for this project phase. External communication should use practical engineering and business terminology — see [External Positioning](#external-positioning).

---

## Vision

AI-assisted decisions that are policy-evaluated, trust-grounded, and permanently reconstructable — without sacrificing local privacy or interactive performance.

---

## Mission

Build a governed multi-model cognition architecture where:

- every significant decision passes through a defined policy, trust, and contract pipeline
- every execution produces a durable evidence artifact
- local-first privacy is the default and non-degraded path
- human approval is structural, not optional, for defined decision classes
- the project governs its own development by the same principles it applies to cognition

---

## Project Principles

These principles govern every design and implementation decision in Project v2.

| Principle | Statement |
|-----------|-----------|
| **Governance before autonomy** | No pipeline stage grants the system authority to bypass human approval. |
| **Evidence before intelligence** | A decision without a durable artifact is not a governed decision. |
| **Contracts before implementation** | The Route Contract is declared before execution begins. |
| **Local-first privacy** | Data that should not leave the device does not leave the device. Policy enforces this; implementation respects it. |
| **Human approval is explicit** | Approval is a recorded act, not an inferred state. |
| **Governance without a latency tax** | Transparency is not sacrificed for performance. Caching, pre-computation, and asynchrony are engineering requirements, not optimisations. |
| **Trust is separate from confidence** | Model confidence and knowledge trust are evaluated independently. Neither substitutes for the other. |
| **Single responsibility per layer** | Each pipeline stage owns exactly one concern. Cross-cutting concerns are handled by contracts. |

---

## Repository Responsibilities

Project v2 is built across four repositories. Each owns a distinct layer. Boundaries are enforced by ADRs and contracts — not by code coupling.

| Repo | Layer | Primary Responsibility |
|------|-------|----------------------|
| `rag-fish/NoesisNoema` | Private Local Cognition Node | Local RAG, on-device inference, user-facing interaction, intent capture |
| `rag-fish/noesisnoema-pipeline` | Trusted Corpus Production Line | Source extraction, chunking, embedding, RAGpack generation, corpus quality gates |
| `rag-fish/noema-agent` | Governed Orchestration Server | Policy enforcement, route contracts, verification, decision logging |
| `rag-fish/RAGfish` | Architecture Hub | ADRs, contracts, public narrative, human-governed loop documentation |

Full boundary definitions are in [ADR-0001](../adr/ADR-0001-noema-architecture.md).

---

## Core Themes

Project v2 is organised around six themes. Each theme represents a class of engineering work that advances the architecture toward the mission.

### 1. Governance

Encode human approval gates structurally — in the Route Contract, in the development loop, and in the evidence artifacts — so that governance cannot be accidentally removed by optimisation or iteration pressure.

Key deliverables: Route Contract v1, human approval gate specification, governance audit tooling.

### 2. Trust

Separate knowledge trust from model confidence across the full pipeline. Trust signals are computed at corpus ingestion time and carried through the Route Contract to the evidence artifact.

Key deliverables: Trust context schema, RAGpack trust metadata standard, trust surface in evidence artifacts.

### 3. Evidence

Make every significant decision permanently reconstructable. Evidence artifacts — Issues, PRs, ADRs, decision log entries, validation reports — are first-class outputs of the governance pipeline.

Key deliverables: Evidence artifact schema, decision log specification, validation report format.

### 4. Performance

Governance must not justify avoidable latency. Caching, pre-computation of trust signals, asynchronous evidence generation, and local-first execution are required — not optional.

Key deliverables: Policy cache design, trust pre-computation at ingestion, asynchronous evidence write path, latency benchmarks for governed inference.

### 5. Observability

Every pipeline execution must be traceable stage by stage. No stage is a black box. Observability is an architectural requirement, not an afterthought.

Key deliverables: Stage-level trace format, decision log query interface, audit dashboard specification.

### 6. Multi-model Orchestration

The system must route requests across local and remote execution modes based on policy, privacy, latency, and trust signals — without coupling routing authority to execution capability.

Key deliverables: Route Contract v1, execution mode selection policy, local-first routing default, remote execution opt-in contract.

---

## Capability Roadmap

The following milestones sequence Project v2 work. Each milestone produces concrete evidence artifacts (ADRs, contracts, validated implementations).

| Milestone | Focus | Status |
|-----------|-------|--------|
| M1 — Architecture definition | ADR-0001 and ADR-0002, four-repo structure, governance pipeline | Complete |
| M2 — Governance pipeline contracts | Route Contract v1, trust context schema, evidence artifact schema | In progress |
| M3 — Trust and corpus quality | RAGpack trust metadata, pipeline quality gates, provenance tracking | Planned |
| M4 — Orchestration layer | `noema-agent` policy enforcement, route contract formation, verification | Planned |
| M5 — Observability | Stage-level tracing, decision log, audit interface | Planned |
| M6 — Performance hardening | Policy cache, asynchronous evidence paths, latency benchmarks | Planned |

Milestone details and task sequencing are managed through the [Human-Governed Development Loop](../human-governed-loop.md) and the GitHub Project board.

---

## Human-Governed Development Loop

All Project v2 work follows the single-task, human-gated loop defined in [human-governed-loop.md](../human-governed-loop.md):

```
1 task = 1 GitHub Issue = 1 branch = 1 PR
```

The development loop is not a project management layer — it is the Noema governance pipeline applied to the project's own development. The project governs itself by the same principles it applies to cognition.

### Actors

| Actor | Role |
|-------|------|
| **Taka** | Governance owner, final reviewer, merge approver |
| **Max / ChatGPT** | Architect, reviewer, prompt designer |
| **Claude CLI** | Architecture docs, audit, broad investigation |
| **Codex CLI** | Focused implementation, tests, small patches |
| **GitHub Project** | Operational state machine — single source of truth for work status |

### Governance guarantee

No work enters a repo without a matching Issue and PR. No merge happens without Taka's review. No architectural decision is implicit — it is recorded as an ADR.

---

## External Positioning

The system's practical engineering properties are the appropriate entry points for external audiences. Project codenames and internal architecture names are not required in external communication.

| Audience | Positioning |
|----------|------------|
| Enterprise architects | Governed AI Architecture — every AI-assisted decision is policy-evaluated, auditable, and human-approved at defined gates |
| Security and compliance teams | Explainable AI with full decision provenance — routing decisions, trust signals, and approval records are durable artifacts |
| Privacy-focused organisations | Local-first AI — on-device execution is the default and non-degraded path; data stays on the device unless explicitly routed otherwise |
| Engineering teams | Trust-aware AI systems — knowledge trust and model confidence are evaluated independently |
| Enterprise integration | Enterprise AI Governance — a defined pipeline for policy enforcement, constraint evaluation, verification, and evidence generation |

Full external positioning rationale is in [ADR-0002 § External Positioning](../adr/ADR-0002-noema-governance-pipeline.md#external-positioning).

---

## Success Criteria

Project v2 is successful when:

- [ ] The Noema Governance Pipeline (ADR-0002) is implemented across all four repos, with each stage owning its defined responsibility
- [ ] Trust signals are computed at corpus ingestion time and carried through the Route Contract to the evidence artifact
- [ ] Every significant pipeline execution produces a durable, queryable evidence artifact
- [ ] Local-only mode in `NoesisNoema` remains the default and fully functional path — no server dependency introduced
- [ ] Human approval gates are structural — encoded in the Route Contract, not enforced by convention
- [ ] Latency for governed inference is within interactive bounds — policy caching, trust pre-computation, and async evidence generation are in place
- [ ] The governance pipeline is self-documenting — ADRs, contracts, and evidence artifacts describe the system's behaviour from first principles
- [ ] All development work follows the Human-Governed Loop — no undocumented decisions, no unreviewed merges

---

## Related Documents

- [ADR-0001: Noema Architecture as Governed Multi-Model Cognition](../adr/ADR-0001-noema-architecture.md)
- [ADR-0002: Noema Governance Pipeline](../adr/ADR-0002-noema-governance-pipeline.md)
- [Human-Governed Development Loop](../human-governed-loop.md)
- [Product Constitution (ADR-0000)](../../adr/adr-0000-product-constitution.md)
- [Authority Model](../../contracts/authority-model.md)
- GitHub Issue: [rag-fish/RAGfish#25](https://github.com/rag-fish/RAGfish/issues/25)
