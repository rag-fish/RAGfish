

# Error Handling Standard

## Purpose

This document defines the unified error handling policy for Noesis Noema.

The objective is:

- Deterministic failure behavior
- Explicit error visibility
- Zero silent failures
- Clear separation between user-facing errors and internal diagnostics

Error handling must align with:

- Product Constitution (Human Sovereignty)
- Invocation Boundary rules
- Observability standards

---

# 1. Error Design Principles

## 1.1 No Silent Failure

The system MUST NOT:

- Swallow exceptions
- Retry silently
- Fallback to alternative routes without explicit log entry

Every failure must be:

- Logged
- Classified
- Traceable via trace-id

---

## 1.2 Deterministic Failure Response

Given the same input and same system state:

The same error must be produced.

No probabilistic error recovery.

---

## 1.3 User Sovereignty

AI must never:

- Fabricate results when retrieval fails
- Mask missing context
- Generate speculative responses due to backend failure

If retrieval fails:

The user must be informed explicitly.

---

# 2. Error Classification

All errors must be categorized into one of the following types.

## 2.1 ROUTING_ERROR

Failure in deterministic router decision.

Examples:

- No rule match
- Conflicting rule evaluation

---

## 2.2 INVOCATION_ERROR

Failure during LLM call.

Examples:

- Timeout
- Model unavailable
- Token overflow

---

## 2.3 MEMORY_ERROR

Session memory inconsistency.

Examples:

- Invalid session-id
- Expired session
- Corrupted session object

---

## 2.4 VALIDATION_ERROR

Invalid user input.

Examples:

- Empty prompt
- Exceeds max length

---

## 2.5 SYSTEM_ERROR

Unexpected internal failure.

Examples:

- Unhandled exception
- Dependency crash

---

# 3. Structured Error Response Format

All external-facing errors must follow this JSON schema:

```json
{
  "error": {
    "code": "ROUTING_ERROR",
    "message": "No routing rule matched.",
    "trace_id": "uuid",
    "timestamp": "ISO-8601"
  }
}
```

Requirements:

- trace_id is mandatory
- timestamp is mandatory
- message must be human-readable

Internal stack traces must NOT be exposed in production.

---

# 4. Logging Requirements

Every error must log:

- error_code
- session_id
- route_type
- invocation_boundary_state
- model_name (if applicable)
- latency (if applicable)

Logs must allow full post-mortem reconstruction.

---

# 5. Retry Policy

Retries are allowed only under the following conditions:

- Error type is network timeout
- Explicit retry flag is set

Retry rules:

- Maximum 1 retry
- Retry must be logged with trace_id
- User must be informed if retry occurred
- Never silent

No infinite retry loops.

All other error types must fail immediately without retry.

---

# 6. Production vs Development Behavior

## Development Mode

- Full stack trace allowed
- Verbose logging
- Model debug metadata allowed

## Production Mode

- No stack traces exposed
- Minimal user-facing error
- Full diagnostic logging internally

---

# 7. Failure is a First-Class State

Failure is not exceptional.

Failure is a defined system state.

The system must treat failure paths as explicitly designed execution flows.

---

# Compliance Gate

Before merging any feature:

- All new errors must map to classification
- Structured response format must be preserved
- No silent catch blocks allowed

If any of these fail:

Feature must not be merged.