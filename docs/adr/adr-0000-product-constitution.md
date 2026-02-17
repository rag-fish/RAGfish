# ADR-0000 — Human Sovereignty Principle

## Status
Accepted

## Context

AI-driven systems face inherent architectural risk: the gradual drift toward autonomous behavior. As capabilities expand, systems may accumulate implicit decision-making authority, opaque routing logic, and background execution patterns that erode human control.

This risk is compounded when:
- Model capabilities exceed system governance structures
- Optimization incentives favor automation over transparency
- Architectural boundaries become ambiguous under iteration pressure
- Business requirements prioritize velocity over accountability

Without a foundational constitutional constraint, subsequent architectural decisions may inadvertently permit:
- Autonomous agent loops
- Hidden model switching
- Opaque execution chains
- Silent state mutations
- Execution authority escalation

This ADR exists to prevent such drift by establishing an immutable governing principle: **Human Sovereignty**.

All design decisions, implementation patterns, and operational behaviors must derive from and comply with this principle.

## Decision

### Foundational Declaration

**Noesis Noema is an intelligence layer in which human noesis governs and AI accompanies. The question originates from the human. AI runs alongside — never ahead, never above. Noema emerges under human sovereignty.**

### System Constraints

This declaration is enforced through the following architectural constraints:

#### 1. Explicit Invocation Only
- The system executes only upon explicit human invocation.
- No background tasks, autonomous loops, or self-triggered processes are permitted.
- Every execution trace must originate from a documented human request.

#### 2. Routing Authority
- All routing decisions remain under human control.
- AI may propose routing options but must not finalize routing without human approval.
- Routing logic must be inspectable and auditable at all times.

#### 3. Execution Transparency
- No hidden execution steps.
- All model invocations, tool calls, and data retrievals must be logged and visible.
- The execution path must be reconstructable from audit logs.

#### 4. Human Override Authority
- The human operator retains absolute authority to halt, redirect, or override any execution.
- No system optimization may override human directive.
- System behavior must degrade gracefully when human intervention occurs.

#### 5. State Mutation Consent
- No persistent state may be mutated without explicit human consent.
- Temporary execution state is permissible only within the scope of a single invocation.
- Knowledge layer updates require documented approval.

#### 6. Model Neutrality
- No implicit model selection or model switching.
- Model choice must be explicit in the invocation request or routing decision.
- The system must not autonomously upgrade or replace models.

#### 7. Transparency Over Optimization
- When optimization conflicts with transparency, transparency wins.
- Performance improvements must not obscure execution logic.
- Latency is acceptable; opacity is not.

## Design Constraints

### Architectural Enforcement

All system layers must enforce the following:

**Client Layer (Noesis Noema)**
- Constructs all routing decisions.
- Maintains human-in-the-loop for policy changes.
- Provides full execution visibility to the operator.

**Invocation Boundary**
- Validates that all requests contain explicit routing decisions.
- Rejects requests that imply autonomous authority.
- Logs all boundary crossings with full context.

**Execution Layer (noema-agent)**
- Executes only the provided ExecutionContext.
- Does not construct routing decisions.
- Does not mutate constraints or escalate authority.

**Knowledge Layer (RAGpack)**
- Returns knowledge references only.
- Contains no execution logic.
- Does not trigger actions or workflows.

### Implementation Discipline

All code changes must pass the following test:

> "Can a mid-level engineer, unfamiliar with this system, trace the full execution path from a single invocation request and identify the human decision point?"

If the answer is no, the change violates ADR-0000.

## Anti-Patterns (Explicitly Forbidden)

The following patterns are explicitly forbidden and must be rejected during design review:

### 1. Autonomous Agent Loops
- No self-prompting agents.
- No recursive execution without explicit per-step approval.
- No background reasoning processes.

### 2. Silent Model Switching
- No runtime model replacement without human notification.
- No fallback logic that changes model providers silently.
- No A/B testing of models without disclosure.

### 3. Opaque Routing Logic
- No black-box routing algorithms.
- No ML-based routing without explainability.
- No hidden policy engines that override user intent.

### 4. Memory Injection Without Disclosure
- No implicit context injection from previous sessions.
- No hidden conversation memory.
- No undisclosed retrieval augmentation.

### 5. Auto-Execution Chains
- No multi-step workflows triggered by a single invocation without stepwise approval.
- No background task scheduling.
- No deferred execution without explicit human queue management.

### 6. Authority Escalation
- The execution layer must never gain routing authority.
- The knowledge layer must never gain execution authority.
- No component may autonomously expand its responsibility scope.

## Consequences

### Positive
- **Governance**: The system remains governable over time.
- **Trust**: Operators trust system behavior because it is auditable.
- **Compliance**: Easier to satisfy regulatory and ethical review.
- **Stability**: Architectural boundaries remain clear under iteration pressure.

### Negative
- **Velocity**: Feature development is slower due to explicitness requirements.
- **Complexity**: Human-in-the-loop patterns require more UI and interaction design.
- **Performance**: Transparency mechanisms add latency and logging overhead.

### Trade-offs Accepted
- We accept slower execution in favor of inspectability.
- We accept higher architectural discipline in favor of long-term governability.
- We accept reduced automation in favor of human sovereignty.

## Governance Rule

**This ADR governs all subsequent ADRs.**

Any future architectural decision must comply with ADR-0000. If a proposed ADR conflicts with the Human Sovereignty Principle, it must either:
1. Be rejected, or
2. Explicitly supersede ADR-0000 through a formal constitutional amendment process.

No ADR may silently weaken or bypass ADR-0000.

### Amendment Process

ADR-0000 may only be amended through:
1. Explicit acknowledgment that a constitutional change is proposed.
2. Documentation of risks introduced by the amendment.
3. Approval by system governance authority (human decision-maker).
4. Creation of a new ADR (e.g., ADR-0000-v2) with full traceability.

Implicit amendments are void.

## References

- ADR-0004: Architecture Constitution
- ADR-0005: Client-side Routing as a First-Class Architectural Principle
- ADR-0006: Contract Lock
- docs/contracts/authority-model.md
- docs/contracts/invocation-boundary.md

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-12  
**Change Policy**: Constitutional amendment only

