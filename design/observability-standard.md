

# Observability Standard

## Status
Draft

---

# 1. Purpose

This document defines the observability requirements for Noesis Noema.

Observability must make system behavior:
- Traceable
- Auditable
- Deterministic to reconstruct
- User-inspectable (without leaking secrets)

Observability must not introduce hidden autonomy.

---

# 2. Core Principles

## 2.1 Traceability by Design

Every user-triggered Invocation MUST be traceable end-to-end.

## 2.2 Deterministic Reconstruction

Given logs and configuration versions, an operator must be able to reconstruct:

- What happened
- Why routing was chosen
- Which model was invoked
- Whether fallback occurred
- Which errors occurred

## 2.3 Privacy Preservation

Logs are sensitive.
Production logging must avoid raw prompt disclosure by default.

## 2.4 Human Sovereignty

Logging must not enable background autonomous execution.
Logs are passive records, not triggers.

---

# 3. Required Identifiers

All telemetry MUST include the following identifiers where applicable:

- trace_id (UUID) — per Invocation
- session_id (UUID) — per active session
- question_id (UUID) — per Question
- response_id (UUID) — per Response

Identifier rules:

- trace_id MUST be generated at Invocation entry
- trace_id MUST be propagated across boundaries (client ⇄ server)
- trace_id MUST appear in user-visible errors

---

# 4. Event Taxonomy

The system MUST emit structured events.

Required event types:

## 4.1 Session Events

- session_created
- session_expired
- session_terminated

## 4.2 Invocation Events

- invocation_started
- invocation_routed
- invocation_executed
- invocation_fallback_used
- invocation_completed

## 4.3 Error Events

- error_raised
- error_returned

---

# 5. Minimum Structured Log Fields

Every event MUST contain:

- event_name
- timestamp (ISO 8601)
- trace_id
- session_id (if applicable)
- question_id (if applicable)

Additional required fields by event:

## invocation_routed

- route (local | cloud)
- reason (rule identifier or explanation)
- selected_model
- fallback_allowed (true | false)

## invocation_executed

- route
- selected_model
- latency_ms
- result (success | error)

## invocation_fallback_used

- from_route
- to_route
- reason

## error_raised / error_returned

- error_code
- error_category
- recoverable (true | false)

---

# 6. Prompt and Data Redaction Policy

## 6.1 Production Default

Production logs MUST NOT include raw `content` (prompt text) by default.

Allowed alternatives:

- content_hash (stable hash of content)
- content_length
- truncated_preview (first N chars, configurable, default disabled)

## 6.2 Development Mode

Development logs MAY include raw content only when explicitly enabled.

---

# 7. User-Inspectable Logs

Users must be able to inspect high-level execution records without exposing secrets.

Minimum user-visible fields:

- timestamp
- route (local | cloud)
- selected_model
- fallback_used
- error_code (if any)
- trace_id

The UI must not display raw internal stack traces.

---

# 8. Metrics

The system SHOULD provide aggregated metrics:

- routing_distribution (local vs cloud)
- fallback_rate
- error_rate by code
- latency percentiles
- session_expiration_count

Metrics must never trigger autonomous behavior changes.

---

# 9. Forbidden Behaviors

The following are prohibited:

- Using logs as triggers for background re-execution
- Silent telemetry that bypasses privacy_level
- Storing raw prompts in production without explicit user enablement
- Cross-session correlation identifiers that create persistent profiling

---

# 10. Governance

Observability must comply with:

- ADR-0000 (Human Sovereignty Principle)
- Router Decision Matrix
- Invocation Boundary
- Memory Lifecycle
- Security Model
- Error Doctrine

Any change to redaction defaults or identifier propagation requires an ADR.