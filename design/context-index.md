# RAGfish / Noesis Noema – Context Index

This file defines the authoritative entry points for all design decisions.

## 1. Product Constitution
- docs/constitution/ (Human Sovereignty Principle)
- ADR-0000 (Governing architecture constraints)

## 2. Architecture Decisions
- docs/adr/ (All binding architectural decisions)

## 3. Contracts
- contracts/ (Schema, invocation boundaries, routing constraints)

## 4. RAGpack Definition
- DesignDoc.md (High-level architecture narrative)
- docs/architecture/ (If exists)

## 5. Implementation Constraints
- No hidden autonomous execution
- No implicit routing escalation
- All model invocation must respect invocation boundary

## 6. Core Schemas

### NoemaQuestion

The structured input object for all Invocations.

Required fields:
- `id` (UUID) — Question identifier
- `session_id` (UUID) — Associated session
- `content` (string) — User-provided prompt
- `privacy_level` (enum: "local" | "cloud" | "auto") — Privacy constraint
- `timestamp` (ISO-8601) — Submission time

Optional fields:
- `intent` (enum: "informational" | "analytical" | "retrieval") — Intent classification
- `constraints` (object) — Execution constraints

Schema must be validated before routing.

### NoemaResponse

The structured output object for all successful Invocations.

Required fields:
- `id` (UUID) — Response identifier
- `question_id` (UUID) — Associated Question
- `session_id` (UUID) — Associated session
- `content` (string) — Generated response
- `model` (string) — Model used
- `route` (enum: "local" | "cloud") — Execution route
- `trace_id` (UUID) — Traceability identifier
- `timestamp` (ISO-8601) — Response generation time
- `fallback_used` (boolean) — Whether fallback occurred

Optional fields:
- `confidence` (float) — Model confidence (if available)
- `uncertainty_reason` (string) — Explanation if confidence is low

## 7. Instruction to AI Agents
Before implementing any feature:
1. Read this file.
2. Read ADR-0000.
3. Do not violate Constitution or contracts.