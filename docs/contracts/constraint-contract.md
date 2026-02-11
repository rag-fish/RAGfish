# Constraint Contract
Version: 1.0.0
Status: Locked

This document defines execution constraints.

---

## Fundamental Principles

1. Deterministic routing
2. Explicit privacy boundaries
3. Authority verification
4. Observable execution
5. Reproducibility

---

## Constraint Types

### PrivacyConstraint
Defines whether data may leave local boundary.

### CostConstraint
Maximum allowed token or monetary cost.

### LatencyConstraint
Maximum allowed response time.

### AuthorityConstraint
Defines required authority level.

### SafetyConstraint
Defines prohibited output domains.

---

## Validation Rules

- All constraints must be validated before routing.
- Conflicting constraints must cause immediate rejection.
- AuthorityConstraint overrides CostConstraint.

---

## Composition Rules

Constraints are evaluated in this order:

1. Authority
2. Privacy
3. Safety
4. Cost
5. Latency

---

# Enforcement

Violation results in ExecutionError.