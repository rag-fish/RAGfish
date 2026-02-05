# noema-agent v2: Constrained Execution Service

**Version**: 2.0  
**Date**: 2026-02-05  
**Status**: Canonical  
**Type**: Architectural Definition

---

## 1. Purpose

noema-agent v2 is a **constrained execution service** within the RAGfish / Noema ecosystem.

Its sole purpose is to execute explicit requests issued by a Client under clearly defined constraints.

It is **not** an autonomous agent and does not possess intent, goals, memory, or decision authority.

**Core Principle**:
> noema-agent exists to execute, not to decide.

---

## 2. Architectural Position

noema-agent v2 operates strictly within the **Execution Layer** as defined by the Architecture Constitution.

It is always invoked by a Client (e.g., Noesis Noema) through an explicit invocation boundary.

At no point does noema-agent initiate actions or determine policy.

**Constitutional Reference**:
> The execution layer answers questions; it does not decide which questions to ask nor how much autonomy to take.  
> (Architecture Constitution, Section 3.2)

---

## 3. Core Invariant

**Architectural Invariant**:
> **noema-agent is a tool used by clients. It is never a decision-making entity.**

This invariant supersedes all other considerations.

---

## 4. Responsibilities

noema-agent v2 is responsible for the following, and **only** the following:

### 4.1 Execution
- Execute requests exactly as specified by the Client
- Respect all provided constraints without modification

### 4.2 Orchestration
- Coordinate bounded execution steps required to fulfill a request
- Perform no speculative or exploratory actions

### 4.3 Delivery
- Return execution results and metadata to the Client
- Preserve transparency of all execution steps

### 4.4 Statelessness
- Maintain no long-term memory across requests
- Treat every invocation as independent unless explicitly constrained otherwise

### 4.5 Constraint Enforcement
- Refuse execution when constraints are missing, ambiguous, or violated

---

## 5. Non-Responsibilities (Explicit Exclusions)

noema-agent v2 **explicitly does not**:

- Make routing decisions
- Define or evaluate policy
- Select or curate knowledge
- Set goals or priorities
- Retry, escalate, or fallback autonomously
- Learn or adapt from past executions

**Constitutional Rule**:
> Any attempt to introduce these behaviors is a violation of the Architecture Constitution.

---

## 6. Interaction with the Client

All interactions with noema-agent v2 are **client-initiated**.

### 6.1 Client Responsibilities

The Client:
- Owns all routing decisions
- Defines execution constraints
- Determines acceptable outcomes
- Bears full responsibility for results

### 6.2 noema-agent Responsibilities

noema-agent:
- Executes within the provided constraints
- Exposes all behavior for inspection
- Holds zero authority over outcomes

---

## 7. Interaction with Knowledge (RAGpack)

noema-agent v2 may access knowledge **only under explicit client instruction**.

### 7.1 Access Characteristics

- **Retrieval-only**: No modification of knowledge
- **Client-defined scope**: Client specifies what knowledge to access
- **No autonomous selection**: Client chooses RAGpack(s)
- **No mutation**: Knowledge assets remain unchanged

**Principle**:
> Knowledge remains passive and model-agnostic.

---

## 8. Behavioral Boundaries

noema-agent v2 **must never**:

1. Initiate execution
2. Modify constraints
3. Optimize beyond instruction
4. Escalate decisions
5. Persist state

**Rule**:
> Violation of any boundary constitutes misuse.

---

## 9. Failure Modes

Failure scenarios are handled as follows:

### 9.1 Constraint Violation
- Execution is refused with explicit reason

### 9.2 Execution Error
- Error is reported transparently to the Client

### 9.3 Resource Unavailability
- Client is informed; no retry is attempted

### 9.4 Ambiguous Instruction
- Execution is rejected pending clarification

**Absolute Rule**:
> Under no circumstance does noema-agent attempt recovery independently.

---

## 10. Lifecycle & Evolution Constraints

### 10.1 Replaceability
- noema-agent v2 is replaceable without client redesign

### 10.2 Evolution Speed
- It evolves slowly relative to Client applications

### 10.3 Agnosticism
- It remains agnostic to models, runtimes, and infrastructure

### 10.4 Compatibility
- Backward compatibility is prioritized over feature expansion

---

## 11. Constitutional Alignment

This document is fully aligned with:

- **Architecture Constitution** (`docs/architect/ARCHITECTURE.md`)
- **ADR-0004**: Architecture Constitution Introduction
- **ADR-0005**: Client-side Routing as a First-Class Architectural Principle
- **OPERATIONS.md**: Validation and human-in-the-loop requirements

**Conflict Resolution**:
> In case of conflict, the Architecture Constitution prevails.

---

## 12. Review Policy

### 12.1 Review Frequency
- Infrequent, intent-driven

### 12.2 Review Trigger
- Architectural drift or boundary violation

### 12.3 Review Authority
- Human maintainers only

---

## 13. Summary

noema-agent v2 is a **deliberately limited execution service**.

Its power lies not in autonomy, but in strict adherence to constraints defined by humans.

**By Design**:
> Misuse as an autonomous agent is structurally impossible.

---

## Document Metadata

**Authority**: System Architect  
**Applies To**: All noema-agent implementations (v2 and beyond)  
**Review Frequency**: Annually or after ADR changes  
**Last Reviewed**: 2026-02-05  
**Next Review**: 2027-02-05

**This document is non-negotiable.**
