# Concept Note 0001 — Dialogue Engineering

**Status:** Draft  
**Date:** 2026-06-28  
**Project:** Hermes  
**Scope:** Architectural concept — no implementation prescribed

---

## Summary

Dialogue Engineering treats long-running human-AI dialogue as an engineering process that produces architectural knowledge.

Its objective is not to optimize individual prompts. Its objective is to evolve shared understanding between humans and AI systems across multiple exchanges, producing concepts, constraints, and architecture that neither party would have reached alone.

This concept note documents the observation that emerged during Hermes architectural work and its relationship to the governance model defined in [ADR-0002](../adr/ADR-0002-noema-governance-pipeline.md).

---

## Background

Modern large language models are probabilistic generators. At inference time, a model generates a sequence of tokens by recursively sampling from a conditional probability distribution over its vocabulary.

The standard autoregressive formulation is:

$$P(x_{1:N}) = \prod_{t=1}^{N} P(x_t \mid x_{1:t-1}, \theta)$$

Where:

- $x_{1:N}$ is the generated token sequence
- $x_t$ is the token generated at step $t$
- $x_{1:t-1}$ is the context of all tokens generated before step $t$
- $\theta$ represents the model's learned parameters

Each generated token is a sample from the distribution over the vocabulary conditioned on all prior context. The model is and remains probabilistic — successive invocations with identical input may produce different outputs.

**Hermes accepts this.** The probabilistic nature of language models is not a problem to be engineered away. The goal is not deterministic language generation. The goal is deterministic engineering decisions under identical constraints.

---

## Observation

Individual prompts rarely produce software architecture.

Architecture emerges through iterative dialogue. A single exchange can surface an insight, a constraint, or a candidate design. It rarely produces a complete architectural decision — because architectural decisions depend on accumulated context: prior decisions, known constraints, failure modes observed, and the specific problem the team is trying to solve.

Iterative dialogue gradually refines:

- **Concepts** — what is the thing we are building, and how should we name it?
- **Assumptions** — what do we take for granted, and are those assumptions valid?
- **Constraints** — what must the system not do, regardless of capability?
- **Architectural intent** — what properties must survive the implementation?
- **Implementation boundaries** — where does one component's responsibility end and another's begin?

Dialogue is therefore treated as a design activity — not a querying activity. The output of a well-run dialogue session is not a better answer to a question. It is a better shared model of the problem.

---

## Dialogue Engineering

Prompt Engineering optimizes individual prompts for better immediate outputs from a language model.

Dialogue Engineering optimizes the process by which humans and AI systems build shared understanding across a sustained conversation — producing architectural knowledge that enters the public record as concepts, ADRs, contracts, and implementation.

The lifecycle:

```
Dialogue
    │
    ▼
Concept
    │
    ▼
Constraint
    │
    ▼
Architecture
    │
    ▼
Implementation
    │
    ▼
Evidence
    │
    ▼
Dialogue
```

The loop is intentionally recursive. Implementation produces evidence — ADRs, validated contracts, merged PRs. Evidence becomes context for future dialogue. Each iteration improves the shared model of the system.

This document is itself a product of that loop: an insight from Hermes dialogue that has been distilled into a concept note and is now entering the public architectural record.

---

## From Probability to Governance

The autoregressive model described above produces probabilistic outputs. The engineering question for Hermes is not: *how do we make the model deterministic?* It is: *how do we produce consistent decisions despite operating on probabilistic outputs?*

The following is an architectural model — not a mathematical proof. Its purpose is to describe how governed systems transform knowledge into consistent engineering decisions.

$$\text{Decision} = \text{Consistency}(\text{Knowledge},\ \text{Constraints},\ \text{Context})$$

A decision is consistent when:

- it applies the same knowledge base
- it respects the same declared constraints
- it operates in the same runtime context

Consistency of this form is achievable in governed systems even when the underlying language model is probabilistic — because the inputs to the decision function are controlled, not the model's token sampling.

---

## Consistency over Certainty

Hermes does not pursue absolute certainty from language models. Absolute certainty is not a property of probabilistic systems and requiring it would make governed AI systems impossible to build.

Hermes pursues **consistent decisions**. Given identical knowledge, identical constraints, and identical runtime context, the resulting decision should remain consistent across invocations.

Consistency enables:

| Property | Description |
|----------|-------------|
| **Explainability** | Any decision can be traced to its knowledge basis, constraints, and context |
| **Governance** | Decisions can be evaluated against declared policy |
| **Reproducibility** | Given the same inputs, the outcome can be reconstructed |
| **Engineering trust** | Teams can reason about system behaviour without requiring certainty about individual model outputs |

This is the distinction between an AI system that is *governed* and one that is merely *capable*. Capability is a property of the model. Governability is a property of the architecture surrounding it.

---

## Governed Decision

The Noema Governance Pipeline (ADR-0002) surrounds probabilistic language generation with structural governance. The conceptual model is:

$$\text{GovernedDecision} = G\bigl(P(x),\ \text{Trust},\ \text{Evidence},\ \text{Human}\bigr)$$

Where:

- $P(x)$ is the probabilistic language model output
- $\text{Trust}$ is the evaluated trustworthiness of the knowledge used (computed at ingestion, independent of model confidence)
- $\text{Evidence}$ is the durable artifact produced by the decision
- $\text{Human}$ is the governance gate — explicit approval where the Route Contract requires it

LLMs remain probabilistic. Hermes surrounds probabilistic generation with:

- **Governance** — policy evaluation before routing
- **Trust evaluation** — independent of model confidence
- **Evidence** — every significant decision produces a durable artifact
- **Consistency** — controlled inputs produce predictable decisions
- **Human approval** — structural gate for defined decision classes

Probability is not replaced. It is governed.

---

## Human-Governed Dialogue

Architecture in Hermes emerges from collaboration between humans and AI systems. The responsibilities are complementary and non-overlapping.

**Humans provide:**

- Architectural intent — what the system must achieve and why
- Governance — which decisions require human approval, and what approval means
- Prioritisation — what to build next, and what to defer
- Accountability — the final authority on what enters the public record

**AI systems contribute:**

- Exploration — surfacing candidate concepts, constraints, and designs across a broad space
- Reasoning — tracing implications of architectural choices across the full system
- Implementation assistance — executing well-specified tasks within defined boundaries
- Validation support — checking consistency of proposals against existing ADRs and contracts

Neither humans nor AI systems produce architecture alone. Architecture emerges from the dialogue between them — governed, recorded, and entered into the public record through the Human-Governed Development Loop.

---

## Working Memory and Public Record

Not all dialogue output is public architectural knowledge. The distinction matters for how knowledge is stored.

**Private (rag-fish-strategy):** Dialogue history, prompt experiments, working investigations, in-progress reasoning, and exploratory sketches belong in the private strategy repository. These are the raw material of Dialogue Engineering — valuable for the team, not yet distilled into public knowledge.

**Public (rag-fish/RAGfish and other public repos):** Only distilled engineering knowledge enters the public repositories:

| Artifact type | Home |
|--------------|------|
| Concept Notes | `rag-fish/RAGfish` — `docs/noema/concepts/` |
| ADRs | `rag-fish/RAGfish` — `docs/noema/adr/` |
| Architecture documents | `rag-fish/RAGfish` — `docs/` hierarchy |
| Contracts and schemas | `rag-fish/RAGfish` — `docs/contracts/` |
| Implementation | Respective repo (`NoesisNoema`, `noema-agent`, `noesisnoema-pipeline`) |

Private prompt contents, experimental dialogue, and working investigations are never exposed in public repositories. What enters the public record is the output of the distillation process — the concept, the constraint, the ADR — not the dialogue that produced it.

This is the Project Working Memory model. The concept is noted here as an architectural principle; the implementation of Working Memory is managed in the private strategy repository.

---

## Closing

Prompt Engineering improves prompts.

Dialogue Engineering improves understanding.

Hermes does not attempt to replace probabilistic language generation. The model's probabilistic nature is the foundation, not an obstacle. Hermes gives probabilistic language a consistent architectural home: governed inputs, trust-evaluated knowledge, evidence-producing decisions, and human approval at defined gates.

The result is not a deterministic AI. It is a governed one.

---

## Related Documents

- [Project Charter v2](../project/PROJECT-CHARTER-v2.md) — vision, mission, and principles for Project Hermes
- [Execution Roadmap v2](../project/EXECUTION-ROADMAP-v2.md) — capability themes and execution sequencing
- [ADR-0001: Noema Architecture as Governed Multi-Model Cognition](../adr/ADR-0001-noema-architecture.md)
- [ADR-0002: Noema Governance Pipeline](../adr/ADR-0002-noema-governance-pipeline.md)
- [Human-Governed Development Loop](../human-governed-loop.md)
