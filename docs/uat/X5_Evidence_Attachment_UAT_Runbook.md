# X-5 Manual UAT Runbook

**Release:** X-4 — Evidence Attachment  
**Target Repository:** rag-fish/RAGFish  
**Status:** Operational  
**Version:** 2.1  

---

## 1. Purpose

This runbook defines the concrete execution procedure required to validate:

**X-5 — Manual UAT**

Definition of Done (DoD):

- UAT.md executed  
- Results documented  
- Human approval recorded  

---

## 2. Preconditions

- X-4 merged into `main`
- All automated tests pass
- No pending schema changes

```bash
git checkout main
git pull origin main
```

---

## 3. Environment Setup

Start noema-agent:

```bash
uvicorn app.main:app --reload --port 8000
```

Health check:

```bash
curl -s http://127.0.0.1:8000/health | jq
```

Expected:

- HTTP 200
- Service status OK

---

# 4. Functional Validation — Invocation

## 4.1 Normal Invocation

```bash
curl -s -X POST http://127.0.0.1:8000/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "uat-001",
    "request_id": "req-001",
    "task_type": "echo",
    "payload": {
      "text": "hello uat"
    }
  }' | jq
```

Verify:

- HTTP 200
- `request_id` present
- `timestamp` present (server-generated execution timestamp)
- `result` present

---

## 4.2 Evidence Attachment Verification

```bash
curl -s -X POST http://127.0.0.1:8000/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "uat-002",
    "request_id": "req-002",
    "task_type": "echo",
    "payload": {
      "text": "evidence test"
    }
  }' | jq
```

Verify:

- `evidence` field exists (or explicitly `[]` if no evidence)
- Evidence entries are human-readable
- No corruption of content

---

# 5. Error Handling Validation

## 5.1 Unsupported Task

```bash
curl -s -X POST http://127.0.0.1:8000/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "uat-003",
    "request_id": "req-003",
    "task_type": "non_existing_task",
    "payload": {}
  }' | jq
```

Verify:

- Structured error JSON
- `error.code` present
- `request_id` present
- No stacktrace leakage

---

## 5.2 Malformed Payload

```bash
curl -s -X POST http://127.0.0.1:8000/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "uat-004",
    "request_id": "req-004",
    "task_type": "echo"
  }' | jq
```

Verify:

- Validation error returned
- No crash

---

# 6. Determinism Validation

```bash
curl -s -X POST http://127.0.0.1:8000/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "uat-005",
    "request_id": "req-005",
    "task_type": "echo",
    "payload": {
      "text": "determinism"
    }
  }' > r1.json
```

```bash
curl -s -X POST http://127.0.0.1:8000/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "uat-006",
    "request_id": "req-006",
    "task_type": "echo",
    "payload": {
      "text": "determinism"
    }
  }' > r2.json
```

Compare:

```bash
jq 'del(.trace_id, .timestamp, .execution_time_ms)' r1.json > c1.json
jq 'del(.trace_id, .timestamp, .execution_time_ms)' r2.json > c2.json
diff c1.json c2.json
```

Expected:

- No diff

---

# 7. Observability Validation

Check logs for lifecycle events:

```bash
grep invocation_started -R .
grep invocation_executed -R .
grep invocation_completed -R .
```

Verify:

- Lifecycle events recorded
- No raw prompt leakage

---

# 8. Session Isolation

```bash
curl -s -X POST http://127.0.0.1:8000/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "session-A",
    "request_id": "req-session-A",
    "task_type": "echo",
    "payload": {
      "text": "A"
    }
  }' | jq
```

```bash
curl -s -X POST http://127.0.0.1:8000/invoke \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "session-B",
    "request_id": "req-session-B",
    "task_type": "echo",
    "payload": {
      "text": "B"
    }
  }' | jq
```

Verify:

- No state crossover

---

# 9. Architectural Guardrails

Confirm absence of forbidden patterns:

```bash
grep -R "router" .
grep -R "background" .
grep -R "retry" .
```

Verify:

- No autonomous routing
- No hidden background execution
- No automatic retries

---

# 10. Result Documentation

Append results to:

`docs/uat/UAT.md`

Use:

```
## X-5 Manual UAT Execution Log

Release: X-4 Evidence Attachment
Date: YYYY-MM-DD
Validator: [Name]

- Invocation success: PASS / FAIL
- Evidence attachment: PASS / FAIL
- Error handling: PASS / FAIL
- Determinism: PASS / FAIL
- Observability: PASS / FAIL
- Session isolation: PASS / FAIL

Recommendation: APPROVE / BLOCK
Signature:
Timestamp:
```

---

# 11. Completion Criteria

X-5 complete when:

- All scenarios executed
- Results documented
- Human approval recorded

---

**End of Runbook**