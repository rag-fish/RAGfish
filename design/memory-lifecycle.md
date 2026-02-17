# Memory Lifecycle

## Status
Draft

---

# 1. Purpose

This document defines the lifecycle, scope, and termination rules of conversational memory
within Noesis Noema.

Memory must enhance usability while preserving human sovereignty
and preventing autonomous persistence.

---

# 2. Scope Definition

Memory is strictly **session-scoped**.

There is no cross-session persistence.
There is no autonomous long-term storage.

Memory exists only to support coherent interaction
within a bounded time window.

---

# 3. Session Definition

A Session is defined as:

- Explicitly initiated by human interaction
- Identified by a unique `session_id`
- Containing multiple Invocations
- Bound by a fixed timeout window

Session Timeout:

**45 minutes (fixed)**

The timeout is non-extendable.
Any new interaction after expiration creates a new Session.

---

# 4. Storage Model

## Client Side (Primary Authority)

- Memory is stored client-side.
- Client owns the session state.
- Client may clear memory at any time.

## Server Side (Ephemeral Mirror)

- Server may hold session data during active session only.
- Server data is indexed by `session_id`.
- Server must discard all session data upon:
  - Timeout expiration
  - Explicit session termination

Server must not retain memory beyond active session window.

---

# 5. Memory Content Rules

Session memory may contain:

- Prior Question objects
- Prior Response objects
- Routing decisions
- Structured metadata

Session memory must not contain:

- Undeclared external data
- Hidden embeddings
- Cross-user information
- Persistent profile enrichment

---

# 6. Expiration Policy

At 45 minutes of inactivity:

- Session state is invalidated
- Client memory is cleared
- Server memory is deleted
- Any attempt to reuse session_id is rejected

No background archival is permitted.

## 6.1 Timeout Enforcement Authority

Both Client and Server independently enforce the 45-minute timeout.

Timeout is measured from `last_activity_at` (activity-based).

The Client is authoritative for user-facing behavior.
The Server is authoritative for security enforcement.

If disagreement occurs, Server rejection prevails (E-SESSION-001).

---

# 7. Garbage Collection

The system must guarantee:

- Deterministic memory deletion
- No residual references
- No shadow persistence

Memory release must be verifiable.

---

# 8. Forbidden Behaviors

The following are strictly prohibited:

- Automatic long-term summarization for retention
- Silent memory compression
- Cross-session carry-over
- Memory-based routing without user visibility
- Persistent vector store accumulation

Any introduction of persistent memory requires a new ADR.

---

# 9. Governance Rule

Memory lifecycle must comply with:

- ADR-0000 (Human Sovereignty Principle)
- Invocation Boundary
- Router Decision Matrix

Violation invalidates system compliance.