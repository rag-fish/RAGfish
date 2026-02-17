

# Session Management

## Status
Draft

---

# 1. Purpose

This document defines how sessions are created, validated, maintained, and terminated.

Session management must:
- Preserve human sovereignty
- Enforce session-scoped memory rules
- Prevent replay and cross-session leakage
- Remain deterministic and auditable

This document is normative for both Client and Server.

---

# 2. Definitions

## 2.1 Session

A Session is a bounded conversational container that may include multiple Invocations.

A Session:
- Is initiated by explicit human interaction
- Has a unique `session_id`
- Has a fixed inactivity timeout
- Owns session-scoped memory

## 2.2 Invocation

An Invocation is a single execution attempt bound to one Question object.
Invocation rules are defined in `design/invocation-boundary.md`.

---

# 3. Session Lifecycle

## 3.1 Creation

A Session is created when:
- The user submits the first Question
- No valid active session exists

Creation requirements:
- Generate cryptographically strong `session_id` (UUID v4 or equivalent)
- Record `created_at` and `last_activity_at`
- Initialize empty session memory container

Client is the primary authority for session state.

## 3.2 Active State

While active, the session:
- Accepts new Questions
- Associates each Invocation with `session_id`
- Updates `last_activity_at` on each user-triggered Invocation

## 3.3 Expiration

A session expires after:

**45 minutes of inactivity (fixed)**

Expiration rules:
- Expiration is non-extendable
- Any interaction after expiration creates a new Session

### Timeout Enforcement

Timeout is measured from `last_activity_at` (activity-based).

Both Client and Server independently enforce the 45-minute timeout:

- **Client:** MUST enforce timeout locally and clear memory.
  - Client is authoritative for user-facing behavior.
  - Client MUST prevent UI from sending requests with expired session_id.

- **Server:** MUST enforce timeout independently and purge session.
  - Server is authoritative for security enforcement.
  - Server MUST reject requests with expired session_id.

- **Disagreement:** If Client sends a request with expired session_id, Server MUST reject with E-SESSION-001.

Both enforcement layers are mandatory and independent.

## 3.4 Termination

A session terminates when:
- Timeout expires
- The user explicitly clears/ends the session

Termination requirements:
- Client clears session memory deterministically
- Server deletes mirrored session object deterministically

---

# 4. Client Responsibilities

The Client MUST:

- Generate and store the active `session_id`
- Attach `session_id` to every Invocation
- Maintain session-scoped memory locally
- Enforce timeout and clear memory on expiration
- Provide user controls to:
  - View session status
  - Clear session memory

The Client MUST NOT:
- Persist session memory across sessions
- Auto-extend session timeout
- Run background invocations

---

# 5. Server Responsibilities

The Server MAY keep an ephemeral mirror of session state indexed by `session_id`.

The Server MUST:

- Treat `session_id` as a secret
- Reject unknown `session_id`
- Reject expired `session_id`
- Delete mirrored session state upon:
  - Expiration
  - Explicit termination

The Server MUST NOT:
- Retain session memory beyond the active window
- Create sessions autonomously
- Join or merge sessions

---

# 6. Validation Rules

## 6.1 session_id Validation

- Must be present for any session-aware operation
- Must match expected format
- Must map to an active session

## 6.2 Replay Resistance

- Expired session_id reuse must be rejected
- Server must not accept timestamps outside session window

---

# 7. Observability

Each Invocation must log:

- session_id
- question_id
- route
- model
- timestamp

Session lifecycle events must log:

- session_created
- session_expired
- session_terminated

Logs must avoid raw prompt content in production.

---

# 8. Failure Handling

Session-related failures must return structured errors:

- E-SESSION-001 — SessionExpired
- E-SESSION-002 — InvalidSessionID

No silent session recreation is allowed.
The user must be informed when a session has expired.

---

# 9. Governance

Session management must comply with:

- Memory Lifecycle
- Invocation Boundary
- Router Decision Matrix
- Security Model
- Error Doctrine

Any change to timeout policy or cross-session behavior requires an ADR.