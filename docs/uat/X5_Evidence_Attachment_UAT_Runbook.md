# X-5 Manual UAT Runbook

**Release:** X-4 — Evidence Attachment
**Target Repository:** rag-fish/RAGFish
**Status:** Operational
**Version:** 1.0

---

## 1. Purpose

This runbook defines the concrete execution procedure required to validate:

**X-5 — Manual UAT**

This document ensures the following Definition of Done (DoD):

- UAT.md executed
- Results documented
- Human approval recorded

This runbook operationalizes the validation requirements defined in:

- docs/uat/UAT.md
- design/invocation-boundary.md
- design/error-doctrine.md
- design/execution-flow.md
- docs/adr/adr-0000-product-constitution.md

---

## 2. Preconditions

Before executing UAT:

- X-4 (Evidence Attachment) is merged into `main`
- All automated tests pass
- No pending schema changes
- Local environment matches latest `main`

Update repository:

```bash
git checkout main
git pull origin main
```

---

## 3. Environment Setup

Start the noema-agent service:

```bash
uvicorn app.main:app --reload --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

Expected result:

- HTTP 200 OK

---

## 4. Functional Validation — Evidence

### 4.1 Echo With Evidence

```bash
curl -X POST http://localhost:8000/execute \
  -H "Content-Type: application/json" \
  -d '{
    "task": "echo",
    "input": "hello",
    "evidence": [
      {
        "source_id": "doc-1",
        "source_type": "note",
        "location": "§1",
        "snippet": "hello world",
        "score": 0.98
      }
    ]
  }'
```

### Expected:

- `evidence` field present
- `source_id` preserved
- `snippet` readable UTF-8 text
- No mutation of evidence content
- `trace_id` present
- `execution_time_ms` present

---

### 4.2 Echo Without Evidence

```bash
curl -X POST http://localhost:8000/execute \
  -H "Content-Type: application/json" \
  -d '{"task": "echo", "input": "hello"}'
```

Expected:

- `evidence: []`
- No server error

---

## 5. Error Handling Validation

### 5.1 Unsupported Task

```bash
curl -X POST http://localhost:8000/execute \
  -H "Content-Type: application/json" \
  -d '{"task": "unknown"}'
```

Expected:

- Structured error JSON
- `error.code` present
- `trace_id` present
- No stacktrace leakage

---

### 5.2 Malformed Evidence

Remove required field (e.g., `source_id`) from evidence payload.

Expected:

- Validation error returned
- No crash
- Proper error schema

---

## 6. Determinism Validation

Repeat identical request twice.

Verify:

- Logical output identical
- Different `trace_id`
- No randomness
- No hidden retries

---

## 7. Autonomous Behavior Prevention

Confirm:

- No automatic subtask creation
- No retries
- No hidden routing logic
- No goal reinterpretation

---

## 8. Observability Validation

Confirm:

- `trace_id` appears in:
  - API response
  - Server logs
- `execution_time_ms` logged
- No raw prompt leakage
- Evidence not excessively logged (only metadata if applicable)

---

## 9. Constitutional Compliance

Confirm:

- Execution layer does not make routing decisions
- Evidence treated as passive data
- No session persistence introduced
- No background tasks

---

## 10. Result Documentation (Append to UAT.md)

After execution, append the following to `docs/uat/UAT.md`:

```
## X-5 Manual UAT Execution Log

Release: X-4 Evidence Attachment  
Date: YYYY-MM-DD  
Validator: [Name]  
Role: Product Owner  

### Execution Results

- Echo with evidence: PASS / FAIL
- Echo without evidence: PASS / FAIL
- Unsupported task: PASS / FAIL
- Malformed evidence: PASS / FAIL
- Determinism: PASS / FAIL
- Constitutional compliance: PASS / FAIL
- Observability: PASS / FAIL

Blockers Found: Yes / No  
Recommendation: APPROVE / BLOCK  

Signature: [Name]  
Timestamp: [ISO 8601]
```

---

## 11. Completion Criteria

X-5 is complete when:

- All above tests executed
- Results recorded in `UAT.md`
- Human approval explicitly signed
- No constitutional violations observed

---

**End of Runbook**
