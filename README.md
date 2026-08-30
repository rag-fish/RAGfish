# RAGfish

**RAGfish** is the architecture hub for the **Noema Architecture** — a governed AI
design in which **human judgment governs and AI accompanies**. This repository holds
the architecture decision records, the governance contract, the capability matrix,
and the execution roadmap. Runtime code lives in the sibling repositories.

> **AI is not the subject.** AI is a capability exercised under human-controlled
> policy, at defined boundaries, with a durable audit trail.

---

## Architectural core

The current baseline is the **epistemic lifecycle** introduced by
[ADR-0004](docs/noema/adr/ADR-0004-noesis-noema-epistemic-separation.md):

```
Evidence
   │   user-owned corpus, plus — only after a Human Gate approval — externally acquired sources
   ▼
NOESIS                 investigation and calibrated epistemic assessment
   │                   (may produce a proposal to acquire more external evidence)
   ▼
Human Gate             a human explicitly authorizes or declines any crossing of an
   │                   external trust boundary — required only when acquisition is needed
   ▼
External acquisition   executes only within the approved scope
   │
   ▼
NOESIS re-analysis     recompute over the enlarged evidence set — not a patch
   │
   ▼
investigation_result   the sole NOESIS → NOEMA handoff object
   │
   ▼
NOEMA                  presentation / narrative transformation only
```

The lifecycle may iterate (NOESIS → Human Gate → acquisition → re-analysis) while a
human keeps approving. It always terminates in NOESIS producing an
`investigation_result`; NOEMA is always downstream of it.

This is an **added dimension** over the existing governance model, not a replacement:
the **decision / execution / knowledge / audit** planes remain separated.

---

## Load-bearing principles

| Principle | Meaning |
|---|---|
| **Human sovereignty** | Human noesis governs the lifecycle and owns every governance decision. AI accompanies. |
| **NOESIS assesses; human noesis governs** | The NOESIS layer produces advisory assessments, confidence, hypotheses, and recommendations. It never owns sovereign judgment, routing authority, or approval. |
| **"Can't rather than won't"** | Governance-critical restrictions are enforced by absent capability — no credential, no endpoint, no code path, no field, schema/type constraint, separate execution context — not by prompt instruction alone. |
| **`investigation_result` is the sole handoff** | NOEMA receives `investigation_result` and nothing else from the investigation side. |
| **NOEMA has no evidence-acquisition capability** | No retrieval, no evidence store, no external API, no corpus-boundary crossing. NOEMA also cannot introduce new claims or raise confidence above the NOESIS result. |
| **Separation of planes** | Decision, execution, knowledge, and audit remain distinct. No component both decides and executes. The audit record is append-only. |

Full definitions and the enforcement mechanism for each restriction are in the
[Governance Contract](docs/noema/governance/NOESIS-NOEMA-GOVERNANCE-CONTRACT.md) and
the [Capability Matrix](docs/noema/governance/CAPABILITY-MATRIX.md).

---

## Architecture documentation

**Primary entry points** — read these first:

| Document | Purpose |
|---|---|
| [ADR-0004 — Noesis / Noema Epistemic Separation](docs/noema/adr/ADR-0004-noesis-noema-epistemic-separation.md) | The current architectural baseline: the epistemic lifecycle, the Human Gate, and "can't rather than won't". |
| [Governance Contract](docs/noema/governance/NOESIS-NOEMA-GOVERNANCE-CONTRACT.md) | What each architectural actor may, must, must not, and cannot do — with the enforcement mechanism for every governance-critical restriction. |
| [Capability Matrix](docs/noema/governance/CAPABILITY-MATRIX.md) | Capability ownership as an explicit grid (18 capabilities × 6 actors) plus the enforcement-mechanism mapping. |
| [Execution Roadmap v3](docs/noema/project/EXECUTION-ROADMAP-v3.md) | **The current execution baseline.** Phase 0–8 plan, task catalog, and dependency graph. |
| [Project Charter](docs/noema/project/PROJECT-CHARTER-v2.md) | Vision, mission, principles, and success criteria. |
| [Human-Governed Development Loop](docs/noema/human-governed-loop.md) | Task lifecycle, task fields, branch and PR discipline. |

**Foundational ADRs** — still authoritative:

- [ADR-0000 — Human Sovereignty Principle](docs/adr/adr-0000-product-constitution.md)
- [ADR-0001 — Noema Architecture](docs/noema/adr/ADR-0001-noema-architecture.md) — four-repo structure and responsibility boundaries
- [ADR-0002 — Noema Governance Pipeline](docs/noema/adr/ADR-0002-noema-governance-pipeline.md) — the nine-stage pipeline
- [ADR-0003 — Governance Platform](docs/noema/adr/ADR-0003-noema-governance-platform.md) — four-plane model and machine-checkable rules G1–G6

**Historical / superseded** — kept for traceability, not current guidance:

- [Execution Roadmap v2](docs/noema/project/EXECUTION-ROADMAP-v2.md) — superseded for execution planning by Roadmap v3; retained as historical evidence.

---

## Repositories

| Repository | Role |
|---|---|
| `rag-fish/RAGfish` | Architecture hub — ADRs, governance contract, capability matrix, roadmap, public narrative. |
| `rag-fish/NoesisNoema` | Client / runtime implementation — local retrieval, on-device inference, user interaction. |
| `rag-fish/noema-agent` | Constrained execution service — *exists to execute, not to decide.* Stateless; policy enforcement, route-contract formation, verification, decision logging. Distinct from the epistemic NOEMA layer. |
| `rag-fish/noesisnoema-pipeline` | Evidence / package pipeline — source extraction, chunking, embedding, corpus quality gates, provenance and trust metadata. |

Repository boundaries are enforced by ADRs and contracts, not by code coupling.

---

## Development governance

All work follows the [Human-Governed Development Loop](docs/noema/human-governed-loop.md):
**1 task = 1 issue = 1 branch = 1 PR**, with a human as the final reviewer and merge owner.

```
Ready task
   → read the authoritative references (ADRs, governance contract, roadmap)
   → inspect the target repository's code
   → produce an implementation plan
   → review
   → implement + validate
   → open a PR
   → human review / merge
```

### Task discipline

Every task states the standard fields (target repo, task type, owner, branch,
Definition of Done, validation) — see the loop document — **plus**:

- **`README Impact: YES / NO`** — with a one-line rationale. If `YES`, the task
  must update this README (or spawn a follow-up task that does), so the public
  entry point never drifts from the architecture baseline.

---

## License

TBD
