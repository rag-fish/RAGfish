

# Evaluation Framework

## Status
Draft

---

# 1. Purpose

The Evaluation Framework defines how system correctness, determinism, and response integrity
are measured and validated.

Evaluation must not rely on subjective impressions.
Evaluation must be reproducible.

---

# 2. Evaluation Layers

The system is evaluated across four independent layers.

---

## L1 — Schema Compliance

Validate that:

- All Question objects conform to NoemaQuestion schema
- Invocation respects Invocation Boundary
- No undeclared fields are present
- privacy_level is honored

Failure at L1 blocks execution.

---

## L2 — Routing Determinism

Given identical:

- Question object
- System configuration
- Model capability
- Network state

The Router MUST produce identical routing decisions.

Test Requirements:

- Snapshot tests for routing output
- Deterministic evaluation of fallback behavior
- confidence must equal 1.0 for routing layer

---

## L3 — Execution Integrity

Validate that each Invocation:

- Has exactly one entry point
- Has exactly one exit point
- Produces one structured Response or one structured Error
- Does not trigger recursive invocation
- Does not mutate undeclared state

Execution integrity must be testable via integration tests.

---

## L4 — Response Quality (Human Review Layer)

This layer evaluates:

- Relevance to Question intent
- Logical coherence
- Explicit uncertainty when applicable
- Absence of hallucinated claims

This layer may include manual review.

This layer MUST NOT introduce autonomous tuning.

---

# 3. Deterministic Test Mode

The system must support a deterministic test mode in which:

- Model calls may be mocked
- Router decisions are snapshot-testable
- Session behavior is time-controlled
- Error paths are reproducible

Test mode must not alter production logic.

---

# 4. Metrics

Evaluation metrics must include:

- Routing consistency rate (target: 100%)
- Invocation boundary compliance (target: 100%)
- Structured error rate visibility (target: 100%)
- Session expiration correctness (target: 100%)

Model answer “accuracy” is secondary to structural compliance.

---

# 5. Non-Goals

The following are explicitly excluded:

- Self-learning evaluation loops
- Reinforcement-based optimization
- Autonomous metric-driven routing adjustment
- Hidden performance tuning

Evaluation must not mutate system behavior.

---

# 6. Governance

All evaluation procedures must comply with:

- ADR-0000 (Human Sovereignty Principle)
- Router Decision Matrix
- Invocation Boundary
- Memory Lifecycle

Violation requires explicit ADR update.