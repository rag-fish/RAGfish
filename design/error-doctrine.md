

# Error Doctrine

## Status
Draft

---

# 1. Purpose

The Error Doctrine defines how failures are classified, surfaced, and handled.

The system must:
- Fail explicitly
- Fail deterministically
- Never hide uncertainty
- Never silently recover

AI systems must not conceal errors behind probabilistic output.

---

# 2. Error Classification

All errors must belong to a typed category.

## 2.1 Routing Errors

- E-ROUTE-001 — RoutingFailure
- E-ROUTE-002 — InvalidPrivacyConstraint

## 2.2 Execution Errors

- E-LOCAL-001 — LocalModelFailure
- E-CLOUD-001 — CloudModelFailure
- E-TIMEOUT-001 — InvocationTimeout

## 2.3 Validation Errors

- E-VALID-001 — SchemaValidationFailure
- E-VALID-002 — InvocationBoundaryViolation

## 2.4 Session Errors

- E-SESSION-001 — SessionExpired
- E-SESSION-002 — InvalidSessionID

## 2.5 Network Errors

- E-NET-001 — NetworkUnavailable
- E-NET-002 — CloudEndpointUnreachable

Each error must be uniquely identifiable and stable across versions.

---

# 3. Structured Error Response

All failures must return a structured error object.

```json
{
  "status": "error",
  "error_code": "E-LOCAL-001",
  "message": "Local model execution failed.",
  "recoverable": false,
  "session_id": "uuid",
  "question_id": "uuid",
  "timestamp": "ISO8601"
}
```

Rules:

- No raw string errors
- No stack traces exposed to user
- No fallback without explicit rule
- recoverable must be deterministic

---

# 4. Fail-Fast Policy

The system must terminate execution immediately when an error occurs.

Prohibited behaviors:

- Silent retry (retry without logging or without explicit retry flag)
- Implicit prompt rewriting
- Hidden model escalation
- Recursive execution loops

Fallback is allowed only if explicitly defined in Router rules.

### Exception: Explicit Network Retry

Retry is permitted ONLY under these strict conditions:

- Error type is network timeout
- Explicit retry flag is set
- Maximum 1 retry attempt
- Retry is logged with trace_id
- Never silent

All other retry scenarios are forbidden.

---

# 5. Uncertainty Policy

If a response is produced but uncertainty is high, the response must include structured confidence metadata.

Example:

```json
{
  "status": "success",
  "confidence": 0.68,
  "uncertainty_reason": "Insufficient context",
  "response": { ... }
}
```

Confidence must never trigger autonomous retry.

---

# 6. Observability Requirements

Every error must be logged with:

- error_code
- session_id
- question_id
- routing_decision
- model_used
- timestamp

Logs must be inspectable.

---

# 7. No Autonomous Recovery Rule

The system must never attempt self-correction without human intervention.

This includes:

- Automatic summarization to compensate for failure
- Silent cloud fallback outside Router policy
- Memory mutation to mask inconsistency

---

# 8. Governance

Error handling must comply with:

- ADR-0000 (Human Sovereignty Principle)
- Invocation Boundary
- Router Decision Matrix

Any deviation requires explicit ADR amendment.