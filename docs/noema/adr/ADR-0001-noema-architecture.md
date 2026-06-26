# ADR-0001: Noema Architecture as Governed Multi-Model Cognition

**Status:** Proposed  
**Date:** 2026-06-26  
**Deciders:** Taka (governance owner), Max / ChatGPT (architect)  
**Scope:** All four Noema repos

---

## Context

NoesisNoema v0.4 completed the first major product milestone: a working private local LLM RAG app that grounds responses in a user-owned corpus, supports on-device model execution, and provides auditable, correctable retrieval. The v0.4 milestone proved that local private RAG can be grounded, audited, and corrected without a server dependency.

The immediate next goal is not to replace or extend the local app. It is to place it within a larger, governed architecture that:

- routes tasks across models and tools with explicit policy
- separates corpus production from retrieval-time decisions
- records decisions and requires human approval at defined gates
- treats the GitHub Project board as the authoritative state machine for all development work

Without an architectural decision at this level, the four active repos risk scope confusion: app developers pull in pipeline concerns, pipeline authors make retrieval assumptions, agent contracts drift, and documentation diverges from implementation.

This ADR defines the four-repo structure as a deliberate governance boundary, not an organizational convenience.

---

## Decision

**Noema Architecture** is defined as a governance-first, multi-model cognition architecture where local private knowledge, server-side orchestration, corpus production, and human approval are separated into explicit layers.

Each repo owns a distinct layer. The boundaries are enforced by ADRs, contracts, and the human-governed development loop — not by code coupling.

### `rag-fish/NoesisNoema` — Private Local Cognition Node

- Local RAG: retrieval, ranking, context assembly
- On-device model execution (iOS / macOS)
- User-facing interaction surface
- Retrieval-time geometry (mean-centering and related normalization belong here, not in the pipeline)
- Local audit and logging where appropriate
- Optional future connection to `noema-agent` for governed routing
- **Must preserve local-only mode as the default and non-degraded path**
- **Must not be made server-dependent**

### `rag-fish/noesisnoema-pipeline` — Trusted Corpus Production Line

- Source extraction and text normalization
- Chunking
- Embedding pack generation (RAGpack format)
- Corpus quality gates
- RAGpack manifest hardening and versioning
- Owns text quality: extraction correctness, chunking correctness, embedding correctness
- **Must not own retrieval-time geometry** — mean-centering and query-time transforms belong to the app

### `rag-fish/noema-agent` — Governed Orchestration Server

- Policy-based routing (model routing, tool routing)
- Verifier: checks outputs against declared constraints
- Decision log: persistent record of routing choices and approvals
- Approval requirements: gates that require human sign-off before execution continues
- App-facing route contract: the stable interface `NoesisNoema` may optionally call
- Orchestration is opt-in for the app; the app must remain fully functional without it

### `rag-fish/RAGfish` — Architecture Hub

- ADR home: all architecture decision records live here
- Public narrative: project documentation, design rationale
- Contract definitions and interface specs
- Human-governed loop documentation
- Backlog sequencing and project-level planning
- Does not contain app code, pipeline code, or agent code

---

## Human-Governed Loop

All development across the four repos follows this operating model:

```
1 task = 1 GitHub Issue = 1 branch = 1 PR
```

Every piece of work is proposed, scoped, assigned, executed, reviewed, and merged through this loop. No work enters a repo without a matching Issue and PR.

### Actors

| Actor | Role |
|-------|------|
| **Taka** | Final reviewer, governance owner, merge approver |
| **Max / ChatGPT** | Architect, reviewer, prompt designer |
| **Claude CLI** | Audits, architecture docs, broad investigation |
| **Codex CLI** | Focused implementation, tests, small patches |
| **GitHub Project** | State machine — single source of truth for work status |

### Why governance is encoded this way

Governance is not enforced by automation alone. It is encoded as project state (GitHub Project board), issue evidence (scope, DoD, branch), PR evidence (linked issue, validation, reviewer), ADRs (decisions with reasoning), and human approval (Taka reviews and merges). Each layer is independently auditable.

This means:
- No work is silently in progress
- No merge happens without human review
- No architectural decision is implicit

See [`docs/noema/human-governed-loop.md`](../human-governed-loop.md) for the full loop specification including task lifecycle, branch naming convention, issue and PR templates, and CLI automation.

---

## Why Repos Remain Separate

The four repos will not be consolidated into a monorepo at this time. The reasons are:

1. **Different lifecycles.** The iOS/macOS app (`NoesisNoema`) must be independently releasable through the App Store. Its build and test cycle is tied to Xcode, simulators, and device hardware. The pipeline is a Python-based batch process. The agent is a server process. These lifecycles are incompatible in a single build graph.

2. **Different build and test constraints.** App build artifacts are platform-specific and cannot share a CI runner with Python embedding jobs or server tests without significant infrastructure investment that is not yet justified.

3. **App must stay independently releasable.** A monorepo dependency tree that includes server and pipeline code risks coupling the app release to non-app changes.

4. **Pipeline must stay independently testable.** Corpus pack generation must be testable in isolation. Mixing it into a monorepo risks entangling test environments.

5. **`noema-agent` is still contract-forming.** The agent's interface with the app is not yet stable. Premature consolidation would lock in an interface before it is proven.

6. **Repo boundaries preserve architecture boundaries.** Separate repos enforce the layer separation defined in this ADR. A monorepo without strict module enforcement often collapses boundaries under iteration pressure.

---

## When Monorepo Migration May Be Reconsidered

The following conditions would justify revisiting the repo structure:

- The app-agent contract is stable and versioned
- The RAGpack manifest contract is stable and versioned
- Shared CI needs genuinely exceed the cost of maintaining repo boundaries
- Cross-repo changes become frequent enough that coordination overhead is a measurable bottleneck
- Release orchestration across the four repos becomes more expensive than maintaining a single build graph

None of these conditions are met as of this ADR.

---

## Non-Goals

This ADR explicitly does not:

- Replace or retire the NoesisNoema local RAG app
- Make the app server-dependent
- Move retrieval-time geometry (mean-centering) into the pipeline
- Collapse all four repos prematurely or by default
- Build autonomous agent behavior that executes without human approval gates
- Optimize for model performance at the cost of governance transparency
- Define the internal implementation of any repo (each repo owns its own ADRs for that)

---

## Consequences

### Positive

- **Clearer ownership.** Each repo has an unambiguous responsibility boundary. Scope disputes have a reference to resolve against.
- **Safer multi-agent development.** Agents operate within defined contracts; no agent can silently expand scope across layers.
- **Local privacy preserved.** The app's local-only mode is protected by architecture, not just by convention.
- **Server orchestration can evolve independently.** `noema-agent` can iterate on routing policy without requiring app releases.
- **Pipeline quality can improve without app churn.** Corpus production improvements are decoupled from retrieval-time changes.
- **Project-driven development loop is part of the architecture.** The GitHub Project board is not a management tool bolted on; it is an architectural component.

### Negative / Tradeoffs

- **Cross-repo coordination remains necessary.** Contract changes must be agreed across repos. This requires discipline and introduces coordination latency.
- **More documentation discipline required.** Architecture decisions must be recorded in ADRs; undocumented decisions are not considered authoritative.
- **Some automation must handle GitHub Projects and linked issues.** The loop depends on consistent issue and PR hygiene; this is a human cost as much as a tooling cost.
- **Integration work must wait for contracts.** App-agent integration cannot begin until the route contract is stable, which delays certain features.

---

## Related Documents

- [`docs/noema/human-governed-loop.md`](../human-governed-loop.md) — operating model for all development across Noema repos
- [`docs/adr/adr-0000-product-constitution.md`](../../adr/adr-0000-product-constitution.md) — Human Sovereignty Principle
- [`docs/adr/ADR-0011-update-retrieval-quality-and-context-budget.md`](../../adr/ADR-0011-update-retrieval-quality-and-context-budget.md) — retrieval quality and context budget decisions
- GitHub Issue: [rag-fish/RAGfish#17](https://github.com/rag-fish/RAGfish/issues/17)
