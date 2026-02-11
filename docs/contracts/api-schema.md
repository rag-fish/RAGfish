# API Schema Contract
Version: 1.0.0
Status: Locked

This document defines the canonical API structures for Noema Agent.

---

## InvocationRequest

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| request_id | string | yes | Unique request identifier |
| input | string | yes | Natural language input |
| context | object | no | Additional structured context |
| constraints | array | no | Execution constraints |
| metadata | object | no | Trace and routing metadata |

---

## InvocationResponse

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| request_id | string | yes | Mirrors request |
| output | string | yes | Final generated response |
| references | array | no | Grounding references |
| execution | ExecutionMetadata | yes | Execution trace metadata |
| error | ExecutionError | no | Error if occurred |

---

## RoutingDecision

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| strategy | string | yes | local | cloud | hybrid |
| model | string | yes | Model selected |
| reason | string | yes | Decision explanation |
| cost_estimate | number | no | Estimated token cost |

---

## ExecutionContext

| Field | Type | Required |
|-------|------|----------|
| user_role | string | yes |
| privacy_level | string | yes |
| environment | string | yes |
| timestamp | ISO8601 | yes |

---

## ExecutionMetadata

| Field | Type | Required |
|-------|------|----------|
| duration_ms | number | yes |
| token_input | number | yes |
| token_output | number | yes |
| route | RoutingDecision | yes |

---

## ExecutionError

| Field | Type | Required |
|-------|------|----------|
| code | string | yes |
| message | string | yes |
| recoverable | boolean | yes |

---

## KnowledgeReference

| Field | Type | Required |
|-------|------|----------|
| source_id | string | yes |
| title | string | no |
| uri | string | no |
| confidence | number | yes |

---

# Change Policy

- Backward incompatible changes require major version increment.
- Additive changes require minor version increment.
- Editorial changes require patch increment.