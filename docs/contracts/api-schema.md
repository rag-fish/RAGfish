# API Schema Contract  
Version: 1.1.0  
Status: Locked  

This document defines the canonical API structures for Noema Agent.  
All structures MUST comply with Invocation Boundary v1.0.0.

---

## InvocationRequest

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| request_id | string | yes | Unique request identifier |
| user_intent | string | yes | Declared user objective |
| input_payload | string | yes | Natural language or structured input |
| authority_level | string | yes | Declared authority scope |
| privacy_scope | string | yes | Data privacy boundary |
| execution_mode | string | yes | local | cloud | hybrid |
| knowledge_scope | array | no | Explicit knowledge sources allowed |
| constraints | array | no | Execution constraints |
| metadata | object | no | Trace and routing metadata |

---

## InvocationResponse

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| request_id | string | yes | Mirrors request |
| execution_status | string | yes | success | failure |
| output_payload | string | yes | Final generated response |
| routing_trace | RoutingDecision | yes | Full routing trace |
| confidence_score | number | yes | Model confidence estimation |
| metadata | ExecutionMetadata | yes | Execution trace metadata |
| error | ExecutionError | no | Error if occurred |

---

## RoutingDecision

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| strategy | string | yes | local | cloud | hybrid |
| model | string | yes | Model selected |
| reason | string | yes | Decision explanation |
| cost_estimate | number | no | Estimated token cost |
| privacy_compliance | boolean | yes | Privacy boundary respected |
| authority_validated | boolean | yes | Authority verified |

---

## ExecutionContext

**Note**: ExecutionContext provides runtime environment metadata. This complements (does not replace) the InvocationRequest fields defined in Invocation Boundary v1.0.0 section 4.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_role | string | yes | Role classification |
| privacy_level | string | yes | Privacy boundary |
| environment | string | yes | Execution environment |
| timestamp | ISO8601 | yes | Invocation timestamp |

---

## ExecutionMetadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| duration_ms | number | yes | Total execution time |
| token_input | number | yes | Input token count |
| token_output | number | yes | Output token count |
| route | RoutingDecision | yes | Routing decision object |

**Note**: The `route` field provides observability of the routing decision made for *this specific invocation*. It does NOT imply stateful routing history across invocations. Each invocation is independent per Invocation Boundary v1.0.0 section 2.4.

---

## ExecutionError

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| code | string | yes | Error classification code |
| message | string | yes | Human-readable explanation |
| recoverable | boolean | yes | Indicates retry possibility |

---

## KnowledgeReference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| source_id | string | yes | Unique source identifier |
| title | string | no | Source title |
| uri | string | no | Source location |
| confidence | number | yes | Relevance confidence |

---

# Contract Enforcement Rules

1. All executions MUST originate from InvocationRequest.  
2. Router mediation is mandatory.  
3. Authority escalation is forbidden.  
4. Stateless execution is required.  
5. Implicit memory injection is prohibited.  

---

# Change Policy

- Backward incompatible changes require major version increment.  
- Additive changes require minor version increment.  
- Editorial changes require patch increment.  
- Contract-breaking changes require ADR approval.