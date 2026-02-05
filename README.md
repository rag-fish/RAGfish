# RAGfish

**System architecture and specifications for human-accountable RAG systems**

---

## What This Repository Is

RAGfish is an **architectural specification repository** for the Noesis Noema ecosystem.

This repository defines:
- System architecture and component boundaries
- Operational constraints and validation requirements
- API contracts and responsibility models
- Knowledge representation formats (RAGpack)

This repository is **not**:
- An application (see [Noesis Noema](https://github.com/raskolnikoff/NoesisNoema) for the client app)
- A service implementation (see noema-agent for execution layer)
- A product offering
- A tutorial or how-to guide

**Purpose**: RAGfish serves as the system-design anchor for retrieval-augmented generation systems where humans remain accountable decision-makers and AI systems function as constrained execution tools.

---

## Ecosystem Overview

The Noesis Noema ecosystem consists of three architectural layers with explicit responsibility boundaries:

### Client Layer: Noesis Noema
- **Repository**: [NoesisNoema](https://github.com/raskolnikoff/NoesisNoema)
- **Role**: Decision and routing layer
- **Responsibilities**:
  - All routing decisions (local vs cloud execution)
  - Policy enforcement (privacy, cost, latency)
  - Context aggregation and knowledge selection
  - User interaction and presentation
- **Authority**: 100% decision authority
- **Evolution**: Fast (feature-driven, user-facing)

### Execution Layer: noema-agent
- **Role**: Constrained execution service
- **Responsibilities**:
  - Execute tasks under client-specified constraints
  - Orchestrate computational resources
  - Return results with complete metadata
- **Authority**: 0% decision authority
- **Constraints**: Stateless, replaceable, observable
- **Evolution**: Slow (stability-driven, contract-preserving)

### Knowledge Layer: RAGpack
- **Role**: Persistent knowledge assets
- **Format**: ZIP-based, model-agnostic embeddings and chunks
- **Characteristics**: Passive, portable, shareable
- **Responsibilities**: None (knowledge does not execute)
- **Evolution**: Independent (domain-driven)

**Architectural Invariant**:
> Routing decisions belong to the client, not the server.  
> AI systems assist reasoning but never own intent, memory, or responsibility.

---

## Core Principles

### 1. Human Accountability
Humans are the only accountable actors in the system. All long-lived intent remains human-inspectable and human-controllable.

### 2. AI as Tool, Not Subject
AI systems (LLMs, embeddings, retrieval) are stateless probabilistic executors. They assist reasoning but do not make decisions, set goals, or own responsibility.

### 3. Client-Side Routing
All routing, policy, and execution placement decisions are made at the client layer. Execution layers are constrained executors with zero decision authority.

### 4. Deterministic Responsibility Boundaries
Each layer has explicit responsibilities and explicit non-responsibilities. Boundary violations are architectural failures.

### 5. Validation Requires Human Judgment
Automated tests are necessary but not sufficient. Semantic correctness, intent alignment, and value trade-offs require human validation.

### 6. No Autonomous Behavior
Execution layers do not retry, fallback, escalate, learn, or optimize autonomously. All such decisions are client-controlled.

---

## Architecture Overview

The system is decomposed by **responsibility and rate of change**, not by technology.

### Three-Layer Architecture

```
Client (Noesis Noema)
    ↓ [Invocation Boundary]
Execution (noema-agent)
    ↓ [Retrieval]
Knowledge (RAGpack)
```

**Client Layer**:
- Fast iteration
- Human-adjacent
- Policy-rich
- Owns routing and context

**Execution Layer**:
- On-demand
- Stateless
- Bounded agentic reasoning under constraints

**Knowledge Layer**:
- Model-agnostic
- Structured for retrieval
- Evolves independently

- No embedded behavior

### Canonical Architecture Diagram

The following diagram is the **canonical visual representation** of the RAGfish / Noema architecture. It defines responsibility boundaries and authority distribution across all layers.

![RAGfish / Noema Architecture](docs/assets/Architecture.png)

This diagram establishes that **client-side routing is architectural** (ADR-0005). The Invocation Boundary is not merely an API—it is a responsibility border. The execution layer operates as a constrained executor with zero decision authority. All routing, policy, and knowledge selection decisions remain client-controlled.

**Key Property**: Human intent flows top-down. Execution results flow bottom-up. No autonomous lateral or upward decision-making.

---

## Operational Model

### Client-Side Evolution
- **Frequency**: Weekly to monthly
- **Drivers**: User needs, feature development, policy changes
- **Deployment**: User-controlled (app updates)
- **Validation**: Human UAT required before release

### Execution-Side Evolution
- **Frequency**: Monthly to quarterly
- **Drivers**: Security patches, model backend upgrades, performance improvements
- **Deployment**: Service-managed (rolling updates, canary)
- **Validation**: Human UAT + constraint enforcement verification required
- **Constraint**: API changes require 90-day deprecation notice

### Knowledge-Side Evolution
- **Frequency**: Independent, on-demand per domain
- **Drivers**: New knowledge domains, updated sources
- **Deployment**: User-controlled (RAGpack import)
- **Validation**: Human curator verifies semantic correctness

### Why This Separation Exists
Components with different evolution speeds must not be tightly coupled. Client feature velocity should not force execution layer changes. Execution stability should not block client innovation. Knowledge updates should not require system-wide coordination.

---

## Documentation Index

### Architecture & Design
- [Architecture Constitution](docs/architect/ARCHITECTURE.md) — Foundational principles and layer definitions
- [noema-agent v2 Definition](docs/architect/noema-agent-v2.md) — Execution service specification
- [Architecture Diagram (PlantUML)](docs/diagrams/architecture.aws.puml) — Canonical system diagram

### Architectural Decision Records (ADRs)
- [ADR-0001](docs/adr/adr-0001.md) — RAGpack ZIP format and tokenizer removal
- [ADR-0004](docs/adr/adr-0004.md) — Architecture Constitution introduction
- [ADR-0005](docs/adr/adr-0005.md) — Client-side routing as first-class principle

### Operations & Validation
- [OPERATIONS.md](docs/OPERATIONS.md) — Operational governance and lifecycle management
- [VALIDATION.md](docs/validation/VALIDATION.md) — Validation philosophy and human-in-the-loop requirements
- [UAT.md](docs/uat/UAT.md) — User acceptance testing procedures and checklist

### Legacy Documentation
- [Design Document](docs/designs/DesignDoc.md) — Historical design notes
- [BPMN Diagrams](docs/bpmn/) — Process flow diagrams
- [UML Diagrams](docs/uml/) — Class, component, sequence, and use case diagrams

---

## Non-Goals

RAGfish explicitly does **not** aim to:

- Provide a deployable application (use Noesis Noema client)
- Offer a hosted service or SaaS platform
- Maximize AI autonomy or agentic capabilities
- Compete on model performance benchmarks
- Support cloud-first or server-driven architectures
- Enable autonomous task delegation or goal-setting by AI
- Replace human judgment in validation or decision-making
- Optimize for speed over human accountability
- Abstract away responsibility boundaries

**Principle**: If a design choice increases AI autonomy at the cost of human accountability, it violates project goals.

---

## Status

**Active Development** — Design-first, implementation follows.

This repository is under active architectural development. Specifications are stabilizing. Implementation repositories (Noesis Noema, noema-agent) track this architecture.

**Current Focus**:
- Finalizing Architecture Constitution (completed)
- Defining noema-agent v2 API contract (in progress)
- Establishing validation and UAT procedures (completed)
- Refining RAGpack v2 specification (planned)

**Stability**:
- Core principles: Stable (non-negotiable)
- Layer boundaries: Stable
- API contracts: Stabilizing (breaking changes require ADR + 90-day notice)
- Implementation details: Evolving

---

## Contributing

Contributions that align with the Architecture Constitution and existing ADRs are welcome.

Before contributing:
1. Read [Architecture Constitution](docs/architect/ARCHITECTURE.md)
2. Review relevant [ADRs](docs/adr/)
3. Understand [validation requirements](docs/validation/VALIDATION.md)

Contributions that violate core principles (e.g., introducing autonomous AI decision-making) will be rejected regardless of technical merit.

---

## License

[MIT](./LICENSE)

---

## Related Repositories

- [Noesis Noema](https://github.com/raskolnikoff/NoesisNoema) — Client application (macOS/iOS)
- [noesisnoema-pipeline](https://github.com/raskolnikoff/noesisnoema-pipeline) — RAGpack preprocessing toolkit

---

**RAGfish**: System architecture for human-accountable RAG systems.  
**Last Updated**: 2026-02-05
