

# Security Model

## Status
Draft

---

# 1. Purpose

This document defines the security boundaries, threat assumptions, and required controls
for Noesis Noema.

Security must reinforce human sovereignty.
Security must prevent:
- Unauthorized execution
- Data leakage across boundaries
- Silent privilege escalation
- Hidden persistence

---

# 2. Trust Boundaries

Noesis Noema operates across explicit trust zones.

## 2.1 Client (Trusted by User)

- Runs on the user device
- Holds session-scoped memory (authoritative)
- Initiates all invocations

## 2.2 Local Execution (On-Device / Local Runtime)

- Executes offline route
- Must not exfiltrate data
- Must enforce invocation boundary

## 2.3 Network Boundary

- Any network transmission is treated as untrusted transport
- TLS is mandatory
- Request/response must be integrity-checked

## 2.4 Cloud Execution (Least Trusted)

- Executes online route
- Receives only contract-approved payloads
- Must not receive data when privacy_level == local

## 2.5 Observability Surface

- Logs are sensitive
- Must avoid raw prompt disclosure in production
- Must be user-inspectable without leaking secrets

---

# 3. Threat Model (High-Level)

Primary threats to address:

- T1: Data exfiltration from client/session memory
- T2: Prompt leakage via logs or telemetry
- T3: Silent cloud escalation (privacy bypass)
- T4: Injection into session context (context poisoning)
- T5: Replay attacks using session_id
- T6: Supply chain compromise (dependencies, models)
- T7: Unauthorized tool execution / hidden autonomy

---

# 4. Required Controls

## 4.1 Identity and Authorization

- Session objects must be bound to a cryptographically strong session_id
- session_id must be treated as secret
- Server must reject unknown or expired session_id

## 4.2 Transport Security

- TLS required for all cloud requests
- Certificate validation must not be bypassed
- No plaintext transport

## 4.3 Input Validation

- All inputs must validate against NoemaQuestion schema
- Reject additionalProperties (no undeclared fields)
- Enforce maximum input length

## 4.4 Privacy Enforcement

- privacy_level == local must guarantee zero network transmission of content
- Router must log the privacy decision
- Cloud payload must be minimized and contract-driven

## 4.5 Session Protection

- Session timeout = 45 minutes (fixed)
- Server must delete mirrored session data on expiry
- Client must clear session memory on expiry
- Reject reuse of expired session_id

## 4.6 Execution Restrictions

- No background execution
- No recursive invocation
- No tool self-discovery
- No undeclared external calls

These restrictions must be enforceable via invocation boundary checks.

## 4.7 Logging and Redaction

Production logs must:

- Avoid raw prompt content unless explicitly enabled
- Store only hashes or truncated previews if needed
- Include trace_id and question_id

---

# 5. Security Invariants

The following invariants must always hold:

1. Human triggers every invocation.
2. privacy_level is never bypassed.
3. No session data persists beyond 45 minutes.
4. No hidden network calls occur.
5. No response is returned without traceability.

Violation of any invariant is a security incident.

---

# 6. Security Incident Handling

If a violation is detected:

- Fail fast
- Return a structured error
- Log incident with trace_id
- Prevent continued execution

No silent recovery is allowed.

---

# 7. Governance

This Security Model must comply with:

- ADR-0000 (Human Sovereignty Principle)
- Router Decision Matrix
- Invocation Boundary
- Memory Lifecycle
- Error Doctrine

Any change to trust boundaries or invariants requires an ADR.