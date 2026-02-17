

# Execution Flow Specification

## 1. Purpose

This document defines the deterministic execution flow of Noesis Noema.
It formalizes how a user question (Noesis) becomes a computed response (Noema)
under human sovereignty.

The flow must:
- Be deterministic
- Contain no hidden autonomous behavior
- Respect the Router Decision Matrix
- Respect the Invocation Boundary

---

## 2. High-Level Flow

```
User Input
   ↓
Client Pre-Processing
   ↓
Router Decision Matrix
   ↓
Invocation Boundary Validation
   ↓
Execution Path (Offline | Online)
   ↓
Response Normalization
   ↓
Client Rendering
```

---

## 3. Detailed Execution Steps

### Step 1 — User Input (Noesis Origin)

- User submits a prompt from Client UI
- Client assigns:
  - session-id
  - request-id (UUID)
  - timestamp
- Input is immutable after submission

Invariant:
> AI does not modify or reinterpret intent before routing.

---

### Step 2 — Client Pre-Processing

Client performs deterministic preprocessing:

- Trim whitespace
- Validate input length
- Attach session metadata
- Optional: classify input type (informational / analytical / retrieval)

No inference occurs here.

---

### Step 3 — Router Decision Matrix

**Execution Location: Client-side**

The Router executes entirely within the Client boundary.

The server does not make routing decisions.

Router evaluates using predefined deterministic rules:

Inputs:
- Prompt characteristics
- Token length estimate
- Local model availability
- Connectivity state
- Policy constraints

Output:
- Route = OFFLINE or ONLINE
- Model profile selection

Rules must be:
- Pure functions
- Versioned
- Logged

No probabilistic routing allowed.

---

### Step 4 — Invocation Boundary Validation

Before execution:

- Validate session-id
- Validate rate limits
- Validate payload schema
- Enforce security constraints

If validation fails:
- Return structured error
- Do not invoke model

### Step 4.5 — Privacy Enforcement

Before any network transmission:

- Validate privacy_level from Question object
- If privacy_level == "local":
  - Block all network calls
  - Block cloud fallback (set fallback_allowed = false)
  - Fail execution if local route fails (return structured error)
  - Zero network transmission guaranteed

This check is mandatory and non-bypassable.

Privacy enforcement must be logged with trace_id.

---

### Step 5 — Execution Path

#### 5A — Offline Path

- Local LLM invoked
- Session memory injected (if within 45 min window)
- Execution is synchronous

Constraints:
- No background autonomy
- No recursive self-calls
- No tool self-discovery

#### 5B — Online Path

- Remote LLM endpoint invoked
- Payload strictly matches contract
- Timeout enforced
- Response streamed or returned fully

Constraints:
- No dynamic endpoint switching
- No hidden chain-of-thought storage

---

### Step 6 — Response Normalization

Server or client layer:

- Enforce response schema
- Strip system metadata
- Log evaluation signals
- Attach response-id

No hidden augmentation.

---

### Step 7 — Client Rendering

Client:
- Displays response
- Stores session memory (client-scoped)
- Updates session expiration timer (45 min)

No automatic follow-up generation.

---

## 4. Memory Handling

- Scope: Client-scoped
- Duration: 45 minutes
- Storage: Server session object indexed by session-id
- Automatic purge on timeout

No persistent memory unless explicitly approved by user.

---

## 5. Failure Handling

All failures must be:

- Deterministic
- Logged
- Structured

Categories:
- ValidationError
- RoutingError
- InvocationError
- TimeoutError
- PolicyViolation

No silent fallback behavior.

---

## 6. Non-Negotiable Constraints

1. Human origin of question is preserved
2. AI never self-initiates tasks
3. No hidden autonomy
4. All routing is explainable
5. All execution paths are traceable

---

## 7. Versioning

This execution flow specification must be versioned.

Changes require:
- ADR reference
- Router matrix update
- Invocation boundary review

---

End of Execution Flow Specification.
