# Operations Manual: RAGfish / Noema Ecosystem

**Version**: 1.0  
**Date**: 2026-02-05  
**Status**: Canonical

---

## 1. Overview

This document defines how the RAGfish / Noema ecosystem is **operated, maintained, and evolved** over time.

It does not describe implementation, architecture, or feature specifications. Those belong to:
- Architecture Constitution (`docs/architect/ARCHITECTURE.md`)
- ADRs (`docs/adr/`)
- Design documents (`docs/designs/`)

This document is for **operators, release managers, and maintainers**.

---

## 2. System Structure

The RAGfish / Noema ecosystem consists of three independently-operated layers:

### 2.1 Client Layer

**Primary Instance**: Noesis Noema (macOS/iOS application)

**Operational Role**:
- User interface and interaction
- Routing decisions (local vs cloud execution)
- Policy enforcement (privacy, cost, latency)
- Context aggregation and RAGpack selection

**Update Frequency**: Fast (weekly to monthly)

**Deployment Model**: User-controlled (App Store, TestFlight, or direct distribution)

---

### 2.2 Execution Layer

**Primary Instance**: noema-agent (Dockerized service)

**Operational Role**:
- Constrained task execution
- LLM inference orchestration
- Tool invocation under client-specified constraints

**Update Frequency**: Slow (monthly to quarterly)

**Deployment Model**: Service-managed (Docker, cloud platform, or local daemon)

---

### 2.3 Knowledge Layer

**Primary Instance**: RAGpack (ZIP-based knowledge archives)

**Operational Role**:
- Persistent knowledge storage
- Model-agnostic retrieval references
- Shareable between clients and execution layers

**Update Frequency**: Independent (on-demand per knowledge domain)

**Deployment Model**: User-controlled or repository-managed

---

## 3. Release & Update Cycles

### 3.1 Principles

The three layers evolve at **different speeds** and must remain **loosely coupled**.

**Constitutional Rule**:
> Components with different evolution speeds must never be tightly coupled.  
> (Architecture Constitution, Section 4)

### 3.2 Client Layer Updates

**Trigger**: Feature development, UX improvements, policy changes

**Ownership**: Client development team

**Validation Requirements**:
- Routing logic must remain human-inspectable
- Execution requests must remain backward-compatible with stable execution layer APIs
- RAGpack format compatibility must be preserved

**Approval Authority**: Client product owner

**Deployment**: User-initiated (via app updates)

**Rollback**: User-controlled (OS-level app version management)

---

### 3.3 Execution Layer Updates

**Trigger**: Bug fixes, security patches, model backend upgrades

**Ownership**: Execution layer maintainers

**Validation Requirements**:
- API contract stability (clients must not break)
- Constraint enforcement verification (execution must respect client-specified limits)
- Performance regression testing (latency, memory, cost)

**Approval Authority**: System architect + security reviewer

**Deployment**: Service-managed (rolling updates, canary deployments)

**Rollback**: Operator-initiated (service version pinning)

**Deprecation Policy**:
- Breaking API changes require 90-day notice
- Old API versions must remain available during deprecation period
- Execution layer updates must never force client updates

---

### 3.4 Knowledge Layer Updates

**Trigger**: New knowledge domains, updated embeddings, corrected metadata

**Ownership**: Knowledge curators (domain experts, not developers)

**Validation Requirements**:
- RAGpack structure integrity (valid ZIP, parsable metadata)
- Embedding dimension compatibility (must match client/execution expectations)
- No executable code or behavior encoding

**Approval Authority**: Knowledge domain owner

**Deployment**: User-initiated (manual import or repository sync)

**Rollback**: User-controlled (delete or replace RAGpack)

**Versioning**: RAGpacks are immutable once published. Updates are new versions, not in-place modifications.

---

## 4. Responsibility & Ownership

### 4.1 Decision Authority

| Decision Type | Authority | Accountability |
|---------------|-----------|----------------|
| Routing (local vs cloud) | Client layer | User |
| Execution constraints (privacy, cost) | Client layer | User |
| Task execution | Execution layer | Execution layer operator |
| Knowledge selection | Client layer | User |
| Knowledge creation | Knowledge layer curator | Curator |
| API contract changes | System architect | Architect + execution operator |

**Invariant**:
> Routing decisions belong to the client, not the server.  
> (ADR-0005: Client-side Routing)

---

### 4.2 Failure Accountability

| Failure Type | Accountable Party | Mitigation Owner |
|--------------|-------------------|------------------|
| Client crash or data loss | Client development team | Client team |
| Execution failure (timeout, error) | Execution layer operator | Execution team |
| Incorrect execution result | Execution layer operator | Execution team |
| RAGpack corruption or invalid structure | Knowledge curator | Curator |
| User data privacy violation | User (via client routing) | User + client team |
| Cost overrun | User (via client policy) | User + client team |

**Constitutional Principle**:
> Humans are the only accountable actors in the system.  
> (Architecture Constitution, Section 2.2)

When execution fails, the **client retains responsibility** for deciding how to handle the failure (retry, fallback, abort, notify user).

The execution layer does not autonomously retry, escalate, or delegate.

---

## 5. Validation & User Acceptance Testing (UAT)

### 5.1 Minimum Validation Requirements

Before any release to production:

#### Client Layer
- [ ] Routing logic is human-inspectable (logged or visualizable)
- [ ] Execution requests conform to stable API contract
- [ ] Privacy-sensitive data remains local when user policy requires it
- [ ] RAGpack selection and loading is user-controllable

#### Execution Layer
- [ ] Constraint enforcement is verified (does not exceed client-specified limits)
- [ ] API backward compatibility is tested
- [ ] Performance regression is measured (latency, memory)
- [ ] Security audit is completed (no new CVEs, no privilege escalation)

#### Knowledge Layer
- [ ] RAGpack structure is valid (parsable ZIP, correct metadata)
- [ ] No executable code is embedded
- [ ] Embedding dimensions match documented schema
- [ ] Source attribution is preserved

---

### 5.2 Human-in-the-Loop Verification

**Principle**:
> Anything not verifiable by a human is considered untrusted.  
> (Architecture Constitution, Section 2.2)

#### Required Human Validation

1. **Client Routing Decisions**
   - A human operator must manually verify that routing logic produces expected outcomes for representative scenarios (local-only, cloud-only, hybrid).

2. **Execution Constraint Enforcement**
   - A human operator must manually verify that execution respects client-specified constraints (privacy, cost, timeout).

3. **Knowledge Integrity**
   - A human curator must manually verify that RAGpack content matches source material and does not contain unintended artifacts.

#### Automated Testing is Insufficient

Automated tests are necessary but not sufficient. The following require human judgment:

- Does the routing decision align with user intent?
- Is the execution result semantically correct (not just syntactically valid)?
- Does the RAGpack represent the intended knowledge domain?

**Operational Rule**:
> No production release occurs without human sign-off on the above verification points.

---

## 6. Failure Handling

### 6.1 Failure Categories

#### 6.1.1 Client-Side Failures

**Examples**:
- Client crash
- Routing logic error
- RAGpack loading failure

**Response**:
- Client logs error locally
- User is notified
- Execution is **not** attempted

**Accountability**: Client development team

---

#### 6.1.2 Execution-Side Failures

**Examples**:
- Execution timeout
- LLM inference error
- Tool invocation failure

**Response**:
- Execution layer returns error to client
- Client decides next action (retry, fallback, abort)
- Execution layer does **not** autonomously retry

**Accountability**: Execution layer operator (for execution correctness), Client (for retry/fallback policy)

---

#### 6.1.3 Knowledge-Side Failures

**Examples**:
- Corrupted RAGpack
- Missing embeddings
- Incompatible schema

**Response**:
- Client detects invalid RAGpack during loading
- User is notified
- Execution using that RAGpack is blocked

**Accountability**: Knowledge curator

---

### 6.2 Acceptable Degradation

The following are **acceptable** forms of degradation:

#### Client Layer
- Slower routing decisions (e.g., user must manually select local/cloud)
- Reduced feature availability (e.g., advanced UI features disabled)
- Fallback to older RAGpack versions

#### Execution Layer
- Increased latency (within client-specified timeout)
- Reduced throughput (within client-specified rate limits)
- Fallback to simpler models (if client permits)

#### Knowledge Layer
- Reduced retrieval quality (fewer or less relevant chunks)
- Missing optional metadata (as long as core structure remains valid)

---

### 6.3 Unacceptable Degradation

The following are **unacceptable** and must trigger immediate rollback or incident response:

#### Client Layer
- Loss of user data (RAGpacks, history, settings)
- Routing decisions that violate user privacy policy
- Execution requests sent without user consent

#### Execution Layer
- Execution exceeding client-specified constraints (privacy, cost, timeout)
- Non-deterministic behavior (same input, different output without client awareness)
- Autonomous task delegation or escalation

#### Knowledge Layer
- RAGpack containing executable code
- RAGpack encoding behavior or decision logic
- Loss of source attribution or provenance

---

## 7. Monitoring & Observability

### 7.1 Client Layer Metrics

**Required**:
- Routing decision frequency (local vs cloud vs hybrid)
- Execution request success rate
- RAGpack loading success rate

**Optional**:
- User session duration
- Feature usage statistics

**Privacy Constraint**: All metrics must remain local unless user explicitly opts in to telemetry.

---

### 7.2 Execution Layer Metrics

**Required**:
- Execution success rate
- Execution latency (p50, p95, p99)
- Constraint violation rate (must be zero)

**Optional**:
- Model inference cost
- Memory usage
- Request rate

**Privacy Constraint**: Metrics must not include user data or RAGpack content.

---

### 7.3 Knowledge Layer Metrics

**Required**:
- RAGpack validity rate (valid structure, parsable metadata)
- Retrieval success rate

**Optional**:
- Retrieval quality (human-evaluated)
- Embedding coverage (percentage of chunks with embeddings)

**Privacy Constraint**: Metrics must not reveal RAGpack content or user queries.

---

## 8. Incident Response

### 8.1 Severity Levels

| Severity | Definition | Response Time | Accountability |
|----------|------------|---------------|----------------|
| **Critical** | User data loss, privacy violation, uncontrolled execution | Immediate (< 1 hour) | System architect + affected layer owner |
| **High** | Service unavailable, constraint violation, security vulnerability | Same day (< 8 hours) | Affected layer owner |
| **Medium** | Degraded performance, incorrect results, UI bugs | Next release cycle | Affected layer owner |
| **Low** | Minor UX issues, documentation errors | Backlog | Affected layer owner |

---

### 8.2 Rollback Criteria

Rollback is **required** if:

1. **Client Layer**: User data is at risk or privacy policy is violated
2. **Execution Layer**: Constraint enforcement fails or security vulnerability is exploited
3. **Knowledge Layer**: RAGpack contains executable code or malicious content

Rollback is **optional** if:

1. Performance degrades but remains within acceptable bounds
2. Non-critical features are unavailable
3. UX is suboptimal but functional

---

### 8.3 Post-Incident Review

After any Critical or High severity incident:

1. **Root Cause Analysis** (within 7 days)
   - What failed?
   - Why did existing validation not catch it?
   - Which constitutional principle was violated (if any)?

2. **Corrective Actions** (within 14 days)
   - Code or configuration fixes
   - Updated validation procedures
   - Updated operational procedures

3. **ADR Update** (if constitutional principle violated)
   - New ADR or amendment to existing ADR
   - Updated architecture diagrams if needed

---

## 9. Deprecation & End-of-Life

### 9.1 Client Layer

**Trigger**: OS platform deprecation, security end-of-support

**Notice Period**: 90 days

**User Impact**: App no longer receives updates, may stop functioning on newer OS versions

**Mitigation**: Users may continue using last stable version indefinitely (if local-only)

---

### 9.2 Execution Layer

**Trigger**: API version deprecation, infrastructure retirement

**Notice Period**: 90 days

**User Impact**: Clients must update to newer API version or switch to local execution

**Mitigation**: Old API versions remain available during deprecation period

---

### 9.3 Knowledge Layer

**Trigger**: Schema version deprecation, source material obsolescence

**Notice Period**: None (RAGpacks are immutable)

**User Impact**: Old RAGpacks may become incompatible with newer clients/execution layers

**Mitigation**: Users may continue using old RAGpacks with compatible client/execution versions

---

## 10. Governance & Decision-Making

### 10.1 Change Approval Matrix

| Change Type | Requires Approval From |
|-------------|------------------------|
| Client feature addition | Client product owner |
| Client routing logic change | System architect |
| Execution API contract change | System architect + execution operator |
| Execution implementation change | Execution operator |
| Knowledge schema change | System architect + knowledge curator |
| RAGpack content update | Knowledge curator |
| ADR creation or amendment | System architect |
| Operations manual update | System architect + layer owners |

---

### 10.2 Conflict Resolution

If a proposed change creates conflict between layers:

1. **Principle Check**: Does the change violate Architecture Constitution or existing ADRs?
   - If yes: Change is rejected
   - If no: Proceed to step 2

2. **Impact Assessment**: Which layers are affected?
   - Client-only: Client owner decides
   - Execution-only: Execution owner decides
   - Cross-layer: System architect mediates

3. **Constitutional Alignment**: Does the change preserve:
   - Human accountability?
   - Client-side routing authority?
   - Execution layer constraint enforcement?
   - Knowledge layer passivity?

4. **Final Decision**: System architect has final authority on constitutional questions

---

## 11. Operational Principles (Summary)

1. **Human Accountability First**: Operations must preserve human decision authority at all times.

2. **Loose Coupling**: Layers evolve independently. No synchronous cross-layer updates.

3. **Client Authority**: Routing and policy decisions remain client-side.

4. **Execution Constraint**: Execution layer obeys client constraints without exception.

5. **Knowledge Passivity**: Knowledge does not encode behavior or decision logic.

6. **Validation is Human**: Automated tests are necessary but not sufficient. Human judgment is required.

7. **Failure is Local**: Failures do not cascade. Each layer handles its own failures within defined boundaries.

8. **Rollback is Fast**: Any layer can roll back independently without coordinating with other layers.

---

## 12. References

- **Architecture Constitution**: `docs/architect/ARCHITECTURE.md`
- **ADR-0004**: Architecture Constitution Introduction
- **ADR-0005**: Client-side Routing as a First-Class Architectural Principle
- **Architecture Diagram**: `docs/diagrams/architecture.aws.puml`

---

## Document Metadata

**Maintained By**: System Architect  
**Review Frequency**: Quarterly  
**Last Reviewed**: 2026-02-05  
**Next Review**: 2026-05-05  

**Version History**:
- 1.0 (2026-02-05): Initial release
