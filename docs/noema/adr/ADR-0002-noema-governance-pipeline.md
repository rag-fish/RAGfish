# ADR-0002: Noema Governance Pipeline

**Status:** Proposed  
**Date:** 2026-06-27  
**Revised:** 2026-06-27  
**Deciders:** Taka (governance owner), Max / ChatGPT (architect)  
**Scope:** All four Noema repos

---

## Context

ADR-0001 defined the physical architecture of Noema: four repositories with explicit responsibility boundaries, governed by ADRs, contracts, and a human-gated development loop.

ADR-0001 answered: *what exists and where does it live?*

ADR-0002 answers: *how does the system evaluate, route, execute, and produce verifiable outcomes?*

The following work established the conditions that make this ADR possible:

- **ADR-0001** — four-repo physical architecture and actor model
- **Human-Governed Loop** — task lifecycle from Issue to Merge
- **Route Contract v0** — stable interface between cognition and execution
- **Corpus Quality Gates** — trust evaluation for pipeline-produced knowledge
- **noema-agent architecture audit** — constrained execution layer defined
- **NoesisNoema routing audit** — client-side routing authority confirmed
- **Pipeline contract audit** — knowledge boundary hardened

The architecture now exists. This ADR describes how it works and the principles that govern its design.

---

## Design Commitment

> Intelligence without governance is automation.  
> Governance without evidence is opinion.  
> Noema exists to transform AI-assisted decisions into verifiable, auditable evidence.

An AI system that executes without governance cannot be audited or appealed. A system that claims governance but produces no durable artifacts has no audit trail.

Noema's design commitment is that decisions passing through the governance pipeline produce durable evidence artifacts. Those artifacts — not model confidence scores — are what make the system auditable. This is an engineering requirement, not a philosophical position: auditability is what differentiates governed AI from automated AI in regulated, enterprise, and privacy-sensitive contexts.

---

## Decision

The **Noema Governance Pipeline** defines nine architectural responsibilities that govern how a user request is evaluated, routed, executed, and recorded.

Each stage owns exactly one responsibility. The diagram below represents the logical flow of that responsibility — it does not prescribe synchronous execution order. See [Runtime Principles](#runtime-principles) for how implementations may optimise stage execution through caching, pre-computation, and asynchrony.

```
User Intent
      │
      ▼
Policy Evaluation
      │
      ▼
Trust Evaluation
      │
      ▼
Route Contract
      │
      ▼
Execution
      │
      ▼
Verification
      │
      ▼
Evidence
      │
      ▼
Human Approval
      │
      ▼
Decision Log
```

---

## Pipeline Stages

### 1. Intent

**What the user actually wants.**

Intent is not the prompt. A prompt is a surface signal. Intent is the underlying purpose: what the user is trying to achieve, what they are willing to accept, and what constraints they implicitly bring.

Intent may be:

- **Literal** — the user's stated question maps directly to a task
- **Inferred** — the system infers unstated context (e.g., privacy preference, time sensitivity)
- **Clarified** — the system requests clarification before proceeding
- **Constrained** — a prior policy or governance rule narrows what is acceptable

Intent is the starting point. If intent is misread, every downstream stage is working toward the wrong goal. Clarifying intent before execution is not overhead — it is governance.

**Primary repo:** `rag-fish/NoesisNoema` — the user-facing interaction surface where intent originates and is captured.

---

### 2. Policy Evaluation

**Human-defined constraints applied before routing.**

Policy is not model behavior. Policy is the set of rules that govern what the system may do on behalf of a user, regardless of what the model is capable of.

Policy covers:

- **Business rules** — what the system is permitted to do in context
- **Security** — access constraints, scope limits, privilege boundaries
- **Privacy** — what data may or may not leave the local boundary (see ADR-0000, Constraint Contract)
- **Governance** — compliance with architectural invariants
- **Compliance** — regulatory or organizational requirements

Policy is evaluated before any routing decision is made. A request that violates policy is rejected at this stage, not after execution.

Policy is human-defined. The system enforces policy; it does not originate it. This is the distinction between a governed system and an autonomous one.

**Primary repo:** `rag-fish/noema-agent` — policy enforcement lives in the orchestration layer, outside the client app and outside the knowledge corpus.

---

### 3. Trust Evaluation

**Evaluating whether the available knowledge is appropriate to use for this request.**

Trust and confidence are distinct properties evaluated independently.

**Confidence** is the model's internal estimate of the correctness of its output. It is a property of the model's inference process and is generated by the model itself.

**Trust** is an externally evaluated property of the knowledge source. It is a governance judgment made by the system before retrieval, not by the model during inference.

Trust factors:

| Factor | Description |
|--------|-------------|
| **Provenance** | Where did this knowledge originate? Is the source identified and acknowledged? |
| **Corpus quality** | Has this knowledge passed the corpus quality gates defined in the pipeline? |
| **Source identity** | Who produced this knowledge? Is the author identifiable? |
| **Freshness** | Is this knowledge current enough for this request? |
| **Validation history** | Has this knowledge been previously validated, and under what conditions? |

**Engineering example — why this matters:** A model answers a question about medication dosage with 0.95 confidence. The retrieved document is an anonymous forum post, ingested 14 months ago, with no corpus validation record. Trust Evaluation marks the source as low-trust. The system surfaces this signal in the Route Contract and the resulting evidence artifact. The high model confidence does not override the low source trust — these are independent measurements. If the same question is answered using a validated clinical guideline with full provenance, both signals are high and the result is treated accordingly.

This separation prevents a common failure mode in retrieval-augmented systems: high model fluency masking low knowledge quality.

Trust signals are computed at corpus ingestion time by the pipeline's quality gates. At inference time, Trust Evaluation reads pre-computed trust metadata — it does not recompute it per request. This design keeps per-request latency low while preserving the governance guarantee.

Trust Evaluation produces a **trust context** that flows into the Route Contract and is recorded in the evidence artifact, making the knowledge basis of any decision auditable.

**Primary repo:** `rag-fish/noesisnoema-pipeline` — corpus quality gates and RAGpack validation produce and store the trust signals consumed at inference time.

---

### 4. Route Contract

**A contract between cognition and execution.**

The Route Contract is the formal artifact that separates the decision about *how to proceed* from the act of *proceeding*. It is not code. It is a declared intent with explicit justification.

The Route Contract specifies:

- **Selected path** — which execution mode is appropriate (local, remote, tool, human)
- **Why** — the reasoning behind the path selection, in human-readable form
- **Confidence** — the system's estimate of the appropriateness of the selected path
- **Trust context** — the trust evaluation result from Stage 3
- **Approval requirements** — whether human approval is required before execution proceeds, and why

The Route Contract does not execute. It declares. Execution happens in the next stage, under the terms of this contract.

This separation is not a formality. It is the architectural guarantee that the system's reasoning is inspectable before any action is taken. A system that skips the Route Contract — that goes directly from input to execution — is not a governed system.

The Route Contract corresponds to the Route Contract v0 interface that `NoesisNoema` may optionally invoke against `noema-agent`.

**Primary repo:** `rag-fish/noema-agent` — the route contract is the stable interface at the boundary of the orchestration layer.

---

### 5. Execution

**Performing the work declared in the Route Contract.**

Execution is intentionally replaceable. The Route Contract defines what should happen; execution is the mechanism that makes it happen.

Execution modes:

| Mode | Description |
|------|-------------|
| **Local** | On-device model inference (iOS / macOS, `NoesisNoema`) |
| **Remote** | Server-side model execution via `noema-agent` |
| **Tool** | Structured tool call (retrieval, search, external API) |
| **Human** | The required executor is a human, not a model |

Execution does not own routing authority. It does not decide which path to take. It does not retry, escalate, or fall back autonomously. It executes the contract and returns a result.

The replaceability of execution is a design principle, not an accident. If execution were tightly coupled to routing or policy, replacing an execution engine would require renegotiating governance. Keeping execution isolated means the governance pipeline can evolve independently of the execution technology.

**Primary repos:** `rag-fish/NoesisNoema` (local execution), `rag-fish/noema-agent` (remote and tool execution).

---

### 6. Verification

**Determining whether execution succeeded — technically and semantically.**

Verification is not a log check. It is an evaluation of whether the execution result satisfies the intent declared in Stage 1 under the constraints declared in Stage 2.

Verification operates at two levels:

- **Technical verification** — did the execution complete without error? Did it respect the constraints?
- **Semantic verification** — does the output actually address the user's intent? Is the result coherent, within scope, and non-harmful?

Semantic verification is applied where appropriate. Not every execution requires deep semantic review. But the system must be capable of semantic verification, and the Route Contract declares when it is required.

A verification failure at this stage does not result in silent fallback or autonomous retry. It surfaces to the human, with the full execution trace, for human judgment.

**Primary repo:** `rag-fish/noema-agent` — the verifier is part of the orchestration layer, positioned after execution and before evidence generation.

---

### 7. Evidence

**A durable, auditable artifact of what was decided and why.**

Evidence is a first-class output of the governance pipeline. It is not a log entry or metadata. It is a purposefully created artifact that can be reviewed, cited, and used as the basis for future decisions and audits.

Evidence examples:

| Type | Description |
|------|-------------|
| **Issue** | GitHub Issue documenting a proposed task, its scope, and Definition of Done |
| **Pull Request** | GitHub PR with linked issue, change summary, and validation |
| **Audit report** | Written finding from an architectural or code audit |
| **ADR** | Architectural Decision Record — this document is itself evidence |
| **Decision log** | Record of a specific routing or approval decision |
| **Validation report** | Result of a corpus quality or retrieval quality evaluation |

Evidence enables:

- **Audit** — any stakeholder can reconstruct what was decided and why
- **Architecture evolution** — decisions can only be superseded when the prior decision is on record
- **Compliance** — regulated environments require a durable decision trail
- **Trust accumulation** — a validated evidence corpus is itself a trust signal over time

**Asynchronous generation:** Evidence does not have to block the response. For routine inferences, evidence artifacts may be written after the response is delivered to the user. The governance requirement is that evidence is complete and durable — not that it is written synchronously. High-stakes decisions where the evidence record must be confirmed before the response is surfaced to the user are declared in the Route Contract.

**Distributed across repos:** Issues and PRs in any Noema repo. ADRs and decision logs in `rag-fish/RAGfish`. Validation reports in `rag-fish/noesisnoema-pipeline`.

---

### 8. Human Approval

**The explicit governance gate — applied where governance scope requires it.**

Human Approval is a governance primitive: a structural guarantee that significant decisions are not finalised without a recorded human judgment. It is not a fallback for low-confidence outputs. It is an architectural requirement for defined decision classes.

Human Approval does not mean that every inference waits for a human response. The Route Contract declares the approval requirement for each request. Routine low-stakes inferences proceed without blocking approval. High-stakes decisions, architectural changes, corpus updates, and actions with external effects require explicit, recorded approval.

Approval is explicit, recorded, and traceable. The system does not infer approval from inaction or extend a prior approval to a new context.

Approval contexts:

| Context | Form of Approval |
|---------|-----------------|
| Development work | Taka reviews and merges the PR |
| Architecture decisions | ADR accepted by governance owner |
| Corpus updates | RAGpack version approved before deployment |
| High-stakes execution routing | Route Contract declares approval required; approval is recorded before execution proceeds |
| Routine inference | No blocking approval required; governance is maintained through policy and trust evaluation |

**Governance owner:** Taka, across all four repos. The human-governed loop encodes this responsibility in every task lifecycle.

---

### 9. Decision Log

**A persistent, queryable record of significant decisions.**

The Decision Log records what was decided, by whom, under what constraints, and with what evidence. It enables any decision to be reconstructed after the fact, independent of session state.

Decision log entries do not block user interaction. They are written asynchronously after execution completes. The governance requirement is completeness and durability, not synchrony.

Not every execution requires a decision log entry. The threshold is significance: decisions that affect architecture, corpus, contracts, or user-facing behaviour should be permanently reconstructable.

Current implementation is distributed:

- **ADRs** — architectural decisions are their own decision log
- **GitHub Issues and PRs** — task-level decisions, with full provenance chain
- **Commit history** — implementation decisions linked to PRs

Future work may implement a unified, queryable decision log as a dedicated artifact. This ADR records the requirement; implementation details belong in a future ADR.

**Primary repo:** `rag-fish/RAGfish` — ADRs and contract documents. GitHub Project board as the operational state log.

---

## Design Principles

These principles govern the design of the pipeline. They are not aspirational — they are constraints that must not be violated.

| Principle | Statement |
|-----------|-----------|
| **Governance before autonomy** | No stage of the pipeline grants the system authority to bypass human approval. |
| **Evidence before intelligence** | A decision without a durable artifact is not a governed decision. |
| **Contracts before implementation** | The Route Contract is declared before execution begins. Execution follows the contract. |
| **Local-first privacy** | Data that should not leave the device does not leave the device. Policy enforces this; execution respects it. |
| **Human approval is explicit** | Approval is a recorded act, not an inferred state. |
| **Governance without a latency tax** | Transparency is not sacrificed for performance, and governance must not justify avoidable latency. Implementations are expected to use caching, pre-computation, and asynchrony. Opacity is never acceptable; latency should be engineered away. |
| **Trust is separate from confidence** | Model confidence and knowledge trust are evaluated independently. Neither substitutes for the other. |
| **Every layer has a single responsibility** | Each pipeline stage owns exactly one concern. Cross-cutting concerns are handled by contracts, not by expanding a stage's scope. |

---

## Runtime Principles

The logical pipeline defines architectural responsibility. It does not prescribe synchronous execution.

A naive implementation that executes all nine stages sequentially for every inference would add unacceptable latency. This is an implementation failure, not an architectural requirement. The following runtime principles describe how implementations are expected to manage latency without compromising governance.

### Policy decisions may be cached

Policy rules change infrequently. Per-request policy evaluation can be replaced with a cached policy result for a given user context, request class, and constraint set. The cache must be invalidated when policy changes. Caching does not change the logical responsibility of the Policy Evaluation stage — it changes when that evaluation runs.

### Trust signals are pre-computed

Trust metadata is evaluated at corpus ingestion time, not at inference time. When a RAGpack passes the pipeline's quality gates, its trust context is computed and stored. At inference time, Trust Evaluation reads stored metadata rather than re-evaluating the corpus. This keeps per-request latency for trust evaluation close to zero.

### Local execution has no remote latency

When the Route Contract selects local execution (on-device model inference), there is no network round-trip. Local execution is the default and non-degraded path. Remote execution is opt-in. This design keeps the common case fast.

### Verification may be asynchronous

For low-stakes inferences, verification may be scheduled after the response is returned to the user. The Route Contract declares when synchronous pre-response verification is required. When asynchronous, a verification failure is surfaced in the next available interaction rather than blocking the current response.

### Evidence generation is asynchronous by default

Writing evidence artifacts — decision log entries, validation records, structured audit traces — does not have to block the response. These artifacts may be written after the user has received their result. The governance requirement is that they are written and durable. The Route Contract may declare synchronous evidence generation for high-stakes requests where the audit record must exist before the response is surfaced.

### Decision log entries are non-blocking

Decision log writes are background operations. They must complete and be durable, but they need not complete before the response is delivered. Infrastructure that writes to the decision log must handle write failures without silently discarding entries.

### Human approval gates are scoped

Human approval is required where the Route Contract declares it. Routine inferences do not trigger blocking approval. This means the governance pipeline can operate at interactive latency for the common case while applying full approval gates to significant decisions.

### Summary

| Concern | Runtime approach |
|---------|----------------|
| Policy evaluation | Cache per user context and request class; invalidate on policy change |
| Trust evaluation | Pre-compute at ingestion; read cached metadata at inference time |
| Local vs remote execution | Prefer local; remote is opt-in |
| Verification | Asynchronous for routine inferences; synchronous when Route Contract requires |
| Evidence generation | Asynchronous by default; synchronous for high-stakes requests |
| Decision logging | Background write; non-blocking; must be durable |
| Human approval | Scoped to significant decisions; routine inferences proceed without blocking approval |

---

## Repository Responsibilities

Each pipeline stage has a primary home in the four-repo architecture defined by ADR-0001.

| Pipeline Stage | Primary Repo | Responsibility |
|---------------|-------------|---------------|
| Intent | `NoesisNoema` | User-facing interaction; intent capture and clarification |
| Policy Evaluation | `noema-agent` | Policy enforcement; constraint evaluation; approval gates |
| Trust Evaluation | `noesisnoema-pipeline` | Corpus quality gates; RAGpack validation; provenance tracking |
| Route Contract | `noema-agent` | Contract formation; path selection; trust context carry-through |
| Execution (local) | `NoesisNoema` | On-device model inference; local RAG |
| Execution (remote/tool) | `noema-agent` | Server-side model execution; tool orchestration |
| Verification | `noema-agent` | Technical and semantic verification of execution results |
| Evidence | Distributed | Issues/PRs in all repos; ADRs and decision logs in `RAGfish` |
| Human Approval | All repos | Taka reviews and merges; governance owner approves architecture |
| Decision Log | `RAGfish` | ADRs, contracts, architecture narrative |

---

## The GitHub Project as Governance State Machine

The GitHub Project board is not a task-management convenience. It is a component of the governance pipeline.

It implements the operational state machine for every development decision in Noema:

```
Issue (proposed intent)
      │
      ▼
Branch (execution declared)
      │
      ▼
Pull Request (execution completed, evidence attached)
      │
      ▼
Merge (human approval recorded)
      │
      ▼
Evidence (ADR, validation report, or implementation in main)
      │
      ▼
Architecture evolution (future ADRs cite this record)
```

Each transition in this state machine is a governance event. The Issue is the declared intent. The Branch is the Route Contract equivalent for development work. The PR is the evidence artifact awaiting approval. The Merge is Human Approval. The result — code, ADR, or contract — is the Decision Log entry.

The Human-Governed Loop is not a development workflow layered on top of Noema. It is the Noema governance pipeline applied to the project's own development. The project governs itself by the same principles it imposes on cognition. A system that cannot govern its own development cannot be trusted to govern anything else.

---

## External Positioning

**Internal names:** Noesis and Noema are internal architectural and project names. They carry meaning within the team and the documentation, but they are not required in external communication.

**External communication** should lead with practical engineering and business value:

| Audience | Positioning |
|----------|------------|
| Enterprise architects | Governed AI Architecture — every AI-assisted decision is policy-evaluated, auditable, and human-approved at defined gates |
| Security and compliance teams | Explainable AI with full decision provenance — routing decisions, trust signals, and approval records are durable artifacts |
| Privacy-focused organisations | Local-first AI — on-device execution is the default and non-degraded path; data stays on the device unless explicitly routed otherwise |
| Engineering teams | Trust-aware AI systems — knowledge trust and model confidence are evaluated independently; high model fluency cannot mask low source quality |
| Enterprise integration | Enterprise AI Governance — a defined pipeline for policy enforcement, constraint evaluation, verification, and evidence generation |

**What to avoid externally:**

- Philosophy-first framing that requires explanation before the engineering value is clear
- Project codenames as the primary descriptor
- Justifying governance by invoking autonomy risks without grounding the claim in concrete engineering behaviour

The architecture's engineering properties — auditability, explainability, local-first privacy, trust-aware retrieval, policy-enforced routing — are the appropriate entry points for external audiences. The philosophical framing that motivates those properties is internal design context, not external messaging.

---

## Comparison with Other Agent Frameworks

Noema is not the only approach to multi-model cognition. The following frameworks represent mature, widely-used alternatives. The comparison here is not a criticism — each framework reflects genuine design choices and serves its intended use cases well.

| Framework | Design Emphasis |
|-----------|----------------|
| **LangGraph** | Stateful graph-based agent orchestration; cycle detection; conditional branching |
| **CrewAI** | Role-based multi-agent collaboration; agent specialization; crew coordination |
| **AutoGen** | Conversational multi-agent patterns; agent-to-agent dialogue; task delegation |
| **Sakana Fugu** | Evolutionary optimization of model configurations; automated architecture search |

These frameworks are optimised for **autonomous throughput**: reducing the human steps required per task, enabling agent-to-agent coordination without per-step intervention, and maximising capability.

Noema is optimised for **governed auditability**: every significant decision is policy-evaluated, trust-grounded, contract-declared, evidence-producing, and human-approved at defined gates. The pipeline produces a durable audit trail as a first-class output.

The difference is not caution versus capability. It is a different primary engineering requirement. These frameworks ask: *how can the system complete more tasks with less human input?* Noema asks: *how can every decision the system participates in be reconstructed, audited, and attributed?*

For throughput-oriented use cases, autonomous frameworks are the appropriate choice. Noema is the appropriate choice when auditability, explainability, data privacy, and human accountability are first-class requirements — regulated environments, enterprise deployments, and systems where the decision record matters as much as the decision outcome.

---

## Non-Goals

This ADR explicitly does not:

- Specify internal implementation of the Policy Engine
- Define routing algorithms or scoring functions
- Specify API surface, serialization format, or network transport
- Define the Trust Evaluation algorithm in code
- Describe the internal structure of the Decision Log persistence layer
- Specify which LLM provider executes at the Execution stage

These concerns belong to future ADRs and to the internal ADRs of each repository.

---

## Consequences

### Positive

- **Inspectable cognition.** Every governance pipeline execution can be traced stage by stage. No stage is a black box.
- **Durable accountability.** Evidence artifacts persist beyond the session. Decisions are reconstructable.
- **Trust separated from confidence.** Model confidence no longer silently masks knowledge quality problems.
- **Human approval is structural.** Approval cannot be accidentally removed by an optimization that bypasses a checkpoint.
- **Architecture is self-documenting.** The pipeline stages map to repo responsibilities, which map to ADRs. The system describes itself.

### Negative / Tradeoffs

- **Latency requires active design.** A naive synchronous implementation of nine pipeline stages would add unacceptable latency. The architecture requires caching, pre-computation, and asynchrony to meet interactive latency targets. This is an engineering discipline requirement at the implementation level; the logical pipeline does not prevent fast execution, but it does not deliver it for free.
- **Governance discipline is ongoing.** Each stage must be implemented, maintained, and respected. The risk of drift under iteration pressure is real and requires sustained architectural review.
- **Not the right model for pure throughput.** Noema's explicit contracts, scoped approval gates, and evidence requirements are overhead in contexts where maximising autonomous throughput is the primary goal. Those contexts are better served by autonomous frameworks.
- **Evidence production has an upfront cost.** Writing well-structured Issues, PRs, and ADRs takes time. The value compounds as the audit corpus grows; the cost is paid immediately.

---

## Related Documents

- [`docs/noema/adr/ADR-0001-noema-architecture.md`](ADR-0001-noema-architecture.md) — physical four-repo architecture; repo responsibility model
- [`docs/noema/human-governed-loop.md`](../human-governed-loop.md) — task lifecycle; branch naming; issue and PR templates
- [`docs/adr/adr-0000-product-constitution.md`](../../adr/adr-0000-product-constitution.md) — Human Sovereignty Principle; foundational constitutional constraint
- [`docs/contracts/authority-model.md`](../../contracts/authority-model.md) — authority hierarchy: SYSTEM → USER → AGENT → MODEL
- [`docs/contracts/invocation-boundary.md`](../../contracts/invocation-boundary.md) — invocation boundary specification; deterministic invocation invariants
- [`docs/contracts/constraint-contract.md`](../../contracts/constraint-contract.md) — execution constraints; evaluation order
- [`docs/architect/noema-agent-v2.md`](../../architect/noema-agent-v2.md) — constrained execution service definition
- GitHub Issue (original): [rag-fish/RAGfish#20](https://github.com/rag-fish/RAGfish/issues/20)
- GitHub Issue (revision): [rag-fish/RAGfish#22](https://github.com/rag-fish/RAGfish/issues/22)
