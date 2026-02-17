

# Router Decision Matrix

## Status
Draft

---

# 1. Purpose

The Router determines whether a Question is executed in local or cloud context.

The Router MUST be fully deterministic.
Given identical inputs and identical system state, the Router MUST always produce the same output.

The Router prioritizes predictability over optimization.

## 1.1 Execution Location

The Router MUST execute client-side.

The server MUST NOT make routing decisions.

The server MAY validate routing decisions but MUST NOT override them.

Client-side routing ensures:
- Human-controllable routing policy
- Inspectable routing logic
- No hidden server-side escalation

---

# 2. Input Object

The Router operates exclusively on the structured `NoemaQuestion` object defined in `design/context-index.md`.

The Router MUST NOT inspect raw prompt strings outside the structured object.

Input fields used for routing:

- privacy_level
- intent
- content (for token estimation only)
- constraints (optional)

Runtime state inputs:

- local_model_capability
- cloud_model_capability
- network_state
- token_threshold

### Runtime State: local_model_capability

A declarative structure defining what the local model supports.

Schema:
```json
{
  "model_name": "string",
  "max_tokens": "number",
  "supported_intents": ["informational", "analytical", "retrieval"],
  "available": "boolean"
}
```

Router MUST NOT execute local route if `available == false`.

Router MUST verify that the Question's `intent` (if specified) is in `supported_intents`.

### Runtime State: network_state

Possible values:
- `online` — Network connectivity confirmed
- `offline` — Network unavailable
- `degraded` — Network available but high latency

Network state MUST be checked before cloud route selection.

### Runtime State: token_threshold

The maximum token count for local execution.

Default value: 4096 tokens (configurable)

Token estimation method:
- Use deterministic tokenizer (must match local model)
- Count tokens in `content` field
- Include session memory token count if applicable

---

# 3. Deterministic Routing Rules

Routing follows strict priority order.

## Rule 1 — Privacy Enforcement

If `privacy_level == "local"`:
- route = "local"
- fallback_allowed = false

If `privacy_level == "cloud"`:
- route = "cloud"
- fallback_allowed = false

## Rule 2 — Auto Mode

If `privacy_level == "auto"`:

1. Estimate token count from `content`.
2. Check if local model supports `intent`.
3. If:
   - token_count <= token_threshold
   - AND local_model_capability supports intent
   - AND network_state is irrelevant

   Then:
   - route = "local"
   - fallback_allowed = true

4. Else:
   - route = "cloud"
   - fallback_allowed = false

## Rule 3 — Local Failure Handling

If route == "local" AND execution fails:

- If fallback_allowed == true:
  - route = "cloud"
  - log escalation reason
- Else:
  - return structured error

## Rule 4 — Cloud Failure Handling

If route == "cloud" AND execution fails:

- return structured error
- no automatic retry

---

# 4. Router Output Schema

```json
{
  "route": "local | cloud",
  "model": "string",
  "reason": "string",
  "fallback_allowed": true,
  "confidence": 1.0
}
```

Notes:
- confidence is always 1.0 for deterministic routing.
- model must be explicitly selected.

---

# 5. Logging Requirements

Each routing decision MUST log:

- question_id
- selected_route
- selected_model
- evaluated_rules
- fallback_flag

Logs MUST be inspectable by the user.

---

# 6. Forbidden Behaviors

The following are strictly prohibited:

- Silent model escalation
- Recursive routing
- Dynamic probabilistic switching
- Hidden fallback execution
- Prompt-based routing outside structured fields

Violation of these rules requires ADR update.

---

# 7. Determinism Guarantee

The Router must behave as a pure decision function.

It must not:
- Learn
- Adapt
- Self-modify

All changes to routing behavior require explicit versioned modification.