# MVP Consistency Checklist

## Purpose
This checklist ensures that the Vertical Slice MVP remains fully aligned with:

- Product Constitution (Human Sovereignty)
- Deterministic Router Model
- Explicit Invocation Boundary
- Session-Scoped Memory Policy
- No Hidden Autonomy Principle

This document must be validated before any MVP-related branch is merged.

---

## 1. Human Sovereignty Validation

- [ ] The user explicitly triggers every execution (no background auto-run)
- [ ] No autonomous task scheduling exists
- [ ] The system does not rewrite or reinterpret user intent without explicit confirmation
- [ ] AI never pre-fetches or pre-computes speculative responses

Failure Condition:
If any hidden execution path exists, MVP is invalid.

---

## 2. Deterministic Routing Validation

- [ ] Router decision matrix is rule-based (no probabilistic routing)
- [ ] Every route decision is explainable via logged rule match
- [ ] Offline/Online switching is traceable
- [ ] Routing does not depend on hidden model heuristics

Failure Condition:
If routing cannot be reproduced deterministically, MVP is invalid.

---

## 3. Invocation Boundary Validation

- [ ] Every LLM invocation is explicit and logged
- [ ] No chained hidden calls
- [ ] Invocation metadata includes: session-id, route-type, timestamp
- [ ] No silent retry logic without log entry

Failure Condition:
If LLM execution cannot be audited, MVP is invalid.

---

## 4. Session & Memory Validation

- [ ] Memory scope = session only
- [ ] Session timeout = 45 minutes
- [ ] Memory cleared automatically after timeout
- [ ] No persistent memory unless explicitly approved by user
- [ ] Memory never shared across sessions

Failure Condition:
If memory survives beyond session scope, MVP is invalid.

---

## 5. Error Handling Compliance

- [ ] All errors return structured response (code, message, trace-id)
- [ ] User-facing messages are human-readable
- [ ] Internal errors are logged but not exposed
- [ ] No silent failure paths

Failure Condition:
If errors are swallowed or hidden, MVP is invalid.

---

## 6. Observability & Auditability

- [ ] Each execution produces structured logs
- [ ] Logs include routing decision
- [ ] Logs include invocation boundary confirmation
- [ ] Logs do not contain sensitive raw prompts in production mode

Failure Condition:
If system behavior cannot be reconstructed from logs, MVP is invalid.

---

## Final Gate

MVP is considered valid only if all checklist items are satisfied.

No feature expansion is allowed before this checklist passes.
