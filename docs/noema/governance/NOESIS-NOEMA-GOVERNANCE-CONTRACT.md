# Noesis / Noema Governance Contract

**Status:** Proposed
**Date:** 2026-08-29
**Deciders:** Human governance owner · Architecture reviewer
**Architectural basis:** [ADR-0004: Noesis / Noema Epistemic Separation](../adr/ADR-0004-noesis-noema-epistemic-separation.md)
**Companion:** [CAPABILITY-MATRIX.md](CAPABILITY-MATRIX.md)
**Issue:** [rag-fish/RAGfish#33](https://github.com/rag-fish/RAGfish/issues/33)
**Scope:** All four Noema repos.

---

## 1. Purpose

ADR-0004 §"Capability Restrictions" states: *"The full enforcement-mechanism mapping —
policy / schema / type-system / credential / endpoint / test — is Issue #33."* This
document is that mapping. It:

1. names each architectural actor and states what it **MAY / MUST / MUST NOT / CANNOT** do;
2. classifies each prohibition as **governance-critical** (ADR-0004 §2) or advisory;
3. assigns every governance-critical prohibition an **architectural enforcement mechanism**, or marks it *not yet implemented* (`N/I`) with the owning downstream task;
4. is accompanied by [CAPABILITY-MATRIX.md](CAPABILITY-MATRIX.md).

It designs no runtime code, no schema, no credentials, no endpoints. It does not decide
ADR-0005 (acquisition execution locus) or ADR-0006 (Noema hosting), and does not start
Issue #34 or #35.

> **NOESIS assesses. Human noesis governs. No AI layer owns sovereign governance judgment.**

---

## 2. Invariant basis

This contract is subordinate to and does **not** renumber the invariants fixed by ADR-0004
(`I1`–`I12`) and the Hermes carried-forward set ([EXECUTION-ROADMAP-v3](../project/EXECUTION-ROADMAP-v3.md) §1,
`INV-1`–`INV-11`). It cites them by their existing identifiers; it introduces no competing
numbering.

The two most load-bearing for this document:

- **`I11`** — Noesis outputs (assessments, confidence estimates, hypotheses, recommendations) are **advisory artifacts**: not governance decisions, routing authority, approval, or human judgment ownership.
- **`I12`** — **human noesis** (the sovereign act, ADR-0000) and the **NOESIS** system layer are distinct; the layer assists, it never owns sovereign judgment or governance authority.

"NOESIS assessment is advisory; human noesis governs" is `I11` + `I12`, restated for
emphasis — not a new invariant.

---

## 3. Enforcement taxonomy — "can't rather than won't"

ADR-0004 §2: a restriction is **governance-critical** when its violation would **(a)** cross
an external trust boundary without human authorization, **(b)** introduce a factual claim no
evidence supports, **(c)** raise a stated confidence above what the investigation justified,
or **(d)** represent AI as the owner of a human approval. For every such restriction the
architecture removes the **capability**; a prompt is defense-in-depth only, never the sole
control.

| Code | Mechanism |
|---|---|
| `CRED` | credential absent from the execution context |
| `EP` | outbound-network / endpoint capability absent |
| `CTX` | separate execution context / process / module boundary |
| `BIND` | tool / retrieval / evidence-store binding absent |
| `SCH` | schema constraint — a field is absent, or its type forbids the value |
| `TYP` | type-system / language-level constraint |
| `VAL` | deterministic output validator rejects the violating output |
| `POL` | policy manifest (`noema-policy.yaml`) declares the boundary |
| `AUD` | append-only hash-chained audit (ADR-0003 G6); a missing/altered event invalidates the run |
| `HUM` | human-only field / human identity required; an AI actor identity is rejected |
| `DID` | defense-in-depth prompt instruction — **never a sole control** |
| `N/I` | **not yet implemented** — mechanism named, owned by a downstream task |

`N/I` is expected: Issue #33 is a contract (`INV-8`, contracts before implementation). Every
`N/I` entry names its owning task so the gap is tracked, not hidden.

---

## 4. Architectural actors

Seven actors. Each is defined over: **Purpose · Inputs · Outputs · Allowed · Forbidden /
CANNOT · Decision authority · Trust-boundary access · Credential access · Retrieval access ·
Evidence access · Mutation rights · External-API rights · Human-approval requirements.**

### 4.1 Human / human noesis

| Field | Statement |
|---|---|
| Purpose | The **sovereign** act of inquiry, judgment, and decision ownership (`I12`; ADR-0000). Originates the question; governs the lifecycle; owns every governance decision and every Human Gate approval. |
| Inputs | The user's question and intent; Noesis advisory artifacts; audit records; the Noema narrative. |
| Outputs | Governance decisions; Human Gate approvals / declines; acceptance or rejection of Noesis recommendations; routing authorization; the decision to run, halt, redirect, or override. |
| Allowed | Everything the architecture reserves to a human: authorize/decline acquisition; approve governance decisions; finalize routing; halt or override any execution (ADR-0000 §4); assert own claims and judgments. |
| Forbidden / CANNOT | Nothing is forbidden to the human by this contract. |
| Decision authority | **Total and sovereign.** No AI layer's output substitutes for it (`I11`, `I12`). |
| Trust-boundary access | Authorizes B1 crossings. Owns the human side of B3. |
| Credential access | The operator manages credentials **out of band**; they are never handed to a credential-absent AI layer. |
| Retrieval access | May search their own corpus through the application surface. |
| Evidence access | Full — it is the human's own corpus. Sees evidence-chain *summaries* in the advisory artifacts. |
| Mutation rights | Governs whether an investigation runs, re-runs, or stops. Does **not** hand-edit investigation state (that is Noesis-owned; the human governs it, Noesis performs it). |
| External-API rights | Out-of-band credential owner; authorizes acquisition. |
| Human-approval requirements | N/A — the human is the approver. |

### 4.2 NOESIS layer

| Field | Statement |
|---|---|
| Purpose | The investigative and **calibrated-epistemic-assessment** layer. It **assists** human noesis; it does not exercise it (`I12`). It **assesses; it does not govern.** |
| Inputs | The question; **Evidence** (user-owned-corpus chunks with provenance + trust metadata; and — only after Human Gate approval — externally acquired sources); policy context. |
| Outputs | `investigation_result` (sole producer); and, when evidence is insufficient, a **proposal** for additional external acquisition addressed to the Human Gate. Every output is an **advisory artifact** (`I11`). |
| Allowed | Investigation; claim decomposition; evidence synthesis; competing-hypothesis maintenance; source-dependency analysis (many reports from one origin = **one** independent chain); uncertainty representation; calibrated assessment (bounded state + calibrated confidence reflecting evidence strength and independence, not model fluency); reads raw evidence; invokes retrieval **over the user-owned corpus**; owns and mutates investigation state; produces `investigation_result`; **proposes** acquisition. |
| Forbidden / CANNOT | Unilaterally cross an external trust boundary (`I3` — proposes only) · own a Human Gate approval (`I8`) · own a governance decision, routing authority, or sovereign judgment (`I11`, `I12`) · call external APIs · hold external-API credentials · raise confidence beyond what the evidence and its independence justify. |
| Decision authority | **None that is sovereign.** Recommends; the human decides. |
| Trust-boundary access | Reads across the corpus interior freely. **Cannot** cross B1 (proposes only). Sole actor on the investigation side of B2. Cannot cross B3. |
| Credential access | Evidence store **YES**; external-API **NO** (`CRED`). |
| Retrieval access | **YES** over the user-owned corpus only (`I2`). |
| Evidence access | **Full** for user-owned-corpus evidence and for evidence returned by an *approved* acquisition. The only layer that reads raw evidence (`I2`). |
| Mutation rights | **Sole owner** of investigation state. On re-analysis it **recomputes** over the enlarged evidence set — never patches, appends, or overrides downstream (`I4`, `INV-7`). |
| External-API rights | **NONE.** Emits an acquisition *proposal* only. |
| Human-approval requirements | Must obtain a recorded Human Gate approval before externally-acquired evidence enters the investigation (`I3`). A decline is valid — Noesis then produces `investigation_result` on existing evidence with the uncertainty stated. |

### 4.3 Human Gate

| Field | Statement |
|---|---|
| Purpose | The explicit governance **checkpoint** for crossing an external trust boundary (B1) — the only mechanism by which external acquisition becomes permitted. A checkpoint, **not an actor with authority of its own**: a *human* authorizes *through* it. |
| Inputs | A Noesis acquisition **proposal** (specific external evidence, with rationale). |
| Outputs | A recorded, scoped **approval** owned by a human identity — **or** a recorded **decline**. Both emit an audit event. |
| Allowed | Present the proposal to a human; capture the explicit authorization or decline; record it with scope; emit the audit event. |
| Forbidden / CANNOT | Authorize on its own · infer approval from inaction · extend a prior approval to a different acquisition · represent an agent/model/service as the approver (`approved_by` is a **human-only field** — `I8`, B3). |
| Decision authority | **None of its own.** It carries a human's decision. |
| Trust-boundary access | Sits astride B1; authorizes (via a human) a crossing, performs none. Owns the human side of B3. |
| Credential / Retrieval / Evidence / Mutation / External-API | **NONE.** Reviews the proposal and its Noesis-supplied context only — not an arbitrary evidence-store reader. |
| Human-approval requirements | It *is* the approval-capture mechanism. **Scope:** applies **only** when investigation would reach outside the user-owned corpus; it does **not** add a runtime approval prompt to ordinary grounded queries — those pass **zero** runtime human gates (ADR-0003; `INV-9`). See §7. |

### 4.4 External Evidence Acquisition layer

| Field | Statement |
|---|---|
| Purpose | Acquire **new external evidence** — sources not already in the user-owned corpus — **only** after a Human Gate approval and **only** within its granted scope. |
| Inputs | A valid, scoped Human Gate approval record; the acquisition request it authorizes. |
| Outputs | Acquired evidence with provenance and trust metadata comparable to corpus evidence, **returned into Noesis** (which recomputes — `I4`). An audit event per acquisition. |
| Allowed | Invoke external services within the approved scope; write acquired evidence into the store; return it to Noesis. |
| Forbidden / CANNOT | Run without a valid approval record · exceed the approved scope · deliver evidence anywhere except back into Noesis · patch or append to a prior assessment · originate an acquisition. |
| Decision authority | **None.** Executes an approved, scoped instruction. |
| Trust-boundary access | The **only** actor that crosses B1 — and only with a valid approval (`I3`). |
| Credential access | External-API: **YES**, within approved scope, provided out of band. Evidence store: **write path** for the acquired evidence only. |
| Retrieval access | Fetches *external* sources (not corpus retrieval). |
| Evidence access | Reads the sources it fetched; writes them with provenance. |
| Mutation rights | **NONE** over investigation state — it returns evidence; Noesis recomputes. |
| External-API rights | **YES**, scoped to the approval. |
| Human-approval requirements | A valid, scoped, human-owned Human Gate approval is a **hard precondition** — no approval ⇒ no acquisition (the gateway fails closed). |
| Execution locus | **UNRESOLVED — deferred to ADR-0005 / [H1-ADR-ACQ-LOCUS (#43)](https://github.com/rag-fish/RAGfish/issues/43).** This contract does not decide that `noema-agent` (or any component) is the executor. |

### 4.5 NOEMA layer (epistemic)

| Field | Statement |
|---|---|
| Purpose | **Presentation / narrative transformation only** — transforms `investigation_result` into user-facing narrative (`I6`). |
| Inputs | **`investigation_result` and nothing else** from the investigation side (`I5`, B2). |
| Outputs | User-facing narrative — a reordered, summarised, explained, formatted rendering of the findings already in `investigation_result`, carrying the assessment states, confidence, uncertainty, and competing hypotheses through **exactly as received**. |
| Allowed | Reorder · summarise · explain · format · surface the stated limitations · present the recorded competing hypotheses. |
| Forbidden / CANNOT | Read raw evidence · reach the evidence store · invoke retrieval · call external APIs · cross the corpus boundary · mutate investigation state · introduce a new factual claim · **raise confidence above the Noesis result** · acquire a missing fact (the correct outcome is to *state the limitation*; needing more evidence is a signal to return to Noesis via a new human-initiated request). |
| Decision authority | **None.** |
| Trust-boundary access | On the **outside** of B4 with **no capability to cross** (`I6`). Consumes B2 one-directionally; no back-channel. |
| Credential access | **NONE** — no evidence-store credential, no outbound-network capability (`CRED`, `EP`). |
| Retrieval access | **NONE** — no retrieval binding (`BIND`). |
| Evidence access | **NONE** — raw evidence is not in its input; only the evidence-chain *summary* inside `investigation_result` (`SCH`, enforced by the #34 contract). |
| Mutation rights | **NONE.** |
| External-API rights | **NONE.** |
| Human-approval requirements | N/A — downstream of every approval; never triggers one. |

### 4.6 `noema-agent` execution service (existing)

| Field | Statement |
|---|---|
| Purpose | The constrained, **stateless Execution Layer** — *"exists to execute, not to decide."* Policy enforcement, Route Contract formation, verification, decision logging. **Unchanged by ADR-0004 and by this contract.** |
| Inputs / Outputs | An execution context / Route Contract in; execution results, Route Contract, decision-log entries, audit events out. |
| Allowed | Execute the provided execution context; **form** the Route Contract (*declare*, not finalize); enforce policy; run verification; write decision-log entries; emit audit events. |
| Forbidden / CANNOT | Construct routing decisions autonomously · finalize routing without human approval (ADR-0000 §2) · mutate constraints or escalate authority · gain intent, memory, or decision authority · **be silently redefined as the epistemic NOEMA layer** (`I9`) · **be assumed to be the External Acquisition executor** (ADR-0005's decision, not this contract's). |
| Decision authority | **None.** Execution only. |
| Credential / Retrieval / Evidence / Mutation | Its existing v2 posture, unchanged. This contract adds **no** external-API or evidence-store credential, and **no** investigation-state mutation. Audit is append-only. |
| External-API rights | Its existing constrained v2 posture. **This contract grants no new external-API right.** Any future acquisition-executor role is **ADR-0005**. |
| Human-approval requirements | A Route Contract may *declare* an approval requirement; high-stakes routing does not proceed until the recorded approval exists (ADR-0002 §8). |
| Relationship to epistemic NOEMA | **`noema-agent` ≠ epistemic NOEMA** (`I9`, `INV-5`). Until ADR-0006 is accepted, "NOEMA" means the epistemic layer and "`noema-agent`" means the execution service; neither definition is substituted for the other. |

### 4.7 Evidence store (resource, not an autonomous actor)

| Field | Statement |
|---|---|
| Purpose | Holds Evidence — user-owned-corpus chunks with provenance + trust metadata (RAGpack v1.3 / ADR-0003 Knowledge plane); and, after Human Gate approval, externally acquired sources with comparable provenance. |
| Read access | **NOESIS only** (`I2`). |
| Write access | The corpus-production pipeline (ingestion) and the External Acquisition layer (approved acquisitions), within their boundaries. |
| NOEMA access | **NONE** — no credential, no binding, not in NOEMA's input surface (`CRED`, `BIND`, `SCH`). This is B4. |
| `noema-agent` access | **NONE** granted by this contract. |
| Trust metadata | The ex-ante **trust** signal is **separate from** the Noesis-calibrated **confidence** (`INV-10`). Neither substitutes for the other. |

---

## 5. Trust boundaries and their enforcement

| Boundary | Crossing rule | Enforcement |
|---|---|---|
| **B1 — Corpus boundary** (user-owned corpus ↔ external sources) | crossed **only** by External Acquisition, **only** after a valid Human Gate approval (`I3`) | `HUM` + `N/I` — sealed gateway rejects any acquisition call lacking a scope-matched, human-owned approval record; owner [H4-SEALED-GATEWAY #53](https://github.com/rag-fish/RAGfish/issues/53), [H4-IMPL-HUMANGATE-ENFORCEMENT NN#137](https://github.com/rag-fish/NoesisNoema/issues/137); regression [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| **B2 — Epistemic handoff** (Noesis ↔ Noema) | crossed **only** by `investigation_result`, one direction, no back-channel (`I5`) | `CTX` + `SCH` (`investigation_result` is Noema's only input field) + `N/I` — owner [H3-NOEMA-ISOLATION #49](https://github.com/rag-fish/RAGfish/issues/49) → [H3-IMPL-NOEMA-CONTEXT NN#133](https://github.com/rag-fish/NoesisNoema/issues/133) |
| **B3 — Approval-authority** (AI identity ↔ human approval) | AI **cannot** cross into approval ownership (`I8`) | `HUM` + `SCH` (`approved_by` accepts a human identity only) + `N/I` — schema owner [#34](https://github.com/rag-fish/RAGfish/issues/34), record owner [H1-HUMANGATE-RECORD #41](https://github.com/rag-fish/RAGfish/issues/41); regression [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| **B4 — Evidence-access** (raw evidence / evidence store / retrieval ↔ Noema) | Noema is on the outside with **no capability to cross** (`I6`) | `CRED` + `EP` + `BIND` + `SCH` + `N/I` — owner [H3-NOEMA-ISOLATION #49](https://github.com/rag-fish/RAGfish/issues/49); adversarial regression [H3-TEST-CAPABILITY-ISOLATION NN#135](https://github.com/rag-fish/NoesisNoema/issues/135), [#35](https://github.com/rag-fish/RAGfish/issues/35) |

---

## 6. `investigation_result` — capability-level requirements only

`investigation_result` is the **sole** Noesis → Noema handoff (`I5`, `INV-3`). **This
contract does not define its schema — [Issue #34](https://github.com/rag-fish/RAGfish/issues/34)
does.** It states the capability-level requirements #34's schema and validator must enforce;
field names, cardinalities, the assessment-state enum, and example payloads are #34's to
design.

| Requirement | Rationale | Mechanism #34 must use |
|---|---|---|
| No raw evidence objects — evidence-chain **summary** only (incl. independent-source-chain counts) | B4; `I6` | `SCH` — no raw-evidence field; raw content unrepresentable |
| Calibrated findings — bounded assessment states + calibrated confidence + explicit uncertainty | `I11`; `INV-10` | `SCH` — bounded enum (no `verified: boolean`); confidence and uncertainty are distinct fields |
| Uncertainty preserved | ADR-0004 §"Uncertainty" | `SCH` — uncertainty is a required, non-nullable field |
| Confidence cannot be increased by Noema — the received value is a ceiling | `(c)` | `VAL` — a downstream validator rejects Noema output whose confidence exceeds the `investigation_result` value; owner [H3-OUTPUT-VALIDATION-SPEC #51](https://github.com/rag-fish/RAGfish/issues/51) → [H3-IMPL-OUTPUT-VALIDATOR NN#134](https://github.com/rag-fish/NoesisNoema/issues/134) |
| Traceable claim identifiers — every claim carries a stable ID minted by Noesis | `(b)` — lets the validator detect a Noema-introduced claim | `SCH` + `VAL` — a claim ID not present in the handoff is rejected |
| Immutable approved Noesis state — a frozen snapshot; nothing downstream edits it | `I4`, `I5`, `INV-7` | `SCH`/`TYP` read-only to consumers; `AUD` — its hash is chained |
| Human `approved_by` for any external acquisition that occurred | `I8`, B3 | `SCH` — `approved_by` is a human-only-typed field |
| Version pinning — records `(embedder_id, model_id, manifest_sha256)` | ADR-0003 G2 | `SCH` — required triplet field |

---

## 7. Human Gate scope

**The Human Gate is exclusively for crossing the external trust boundary (B1)** — "external"
being any source not already in the user-owned corpus.

**It MUST NOT introduce a runtime approval prompt for ordinary grounded queries inside the
user's own corpus.** ADR-0003's design stands: ordinary grounded queries pass **zero**
runtime human gates (`INV-9`); governance for them is *ex-ante policy* plus *ex-post
verifiable audit*. The Human Gate is the investigation-time analogue of ADR-0003's Human
Decision Gate — a checkpoint at the exact boundary where trust changes, and nowhere else.

**Enforcement:** the Human Gate is only reachable from a Noesis acquisition **proposal**,
which is only produced when Noesis determines current evidence is insufficient *and* would
need to reach outside the corpus. There is no code path from ordinary corpus retrieval to
the Human Gate. Regression coverage: [#35](https://github.com/rag-fish/RAGfish/issues/35).

---

## 8. `approved_by` — the human-only field

Per ADR-0004: *"Approval ownership is a human-only field (Issue #33 / #34 encode the
enforcement)."* The requirement (schema is #34's; record shape is
[H1-HUMANGATE-RECORD #41](https://github.com/rag-fish/RAGfish/issues/41)'s):

1. `approved_by` accepts **only a human identity**; an agent/model/service identity cannot be represented (`SCH`/`TYP` + `HUM`).
2. Approval is **not** inferred from inaction — there is no implicit-approval state (`SCH`).
3. An approval is **scoped** to a specific acquisition and not extended to a different one (`SCH` — the gateway matches request↔approval scope).
4. A **decline** is a first-class, recorded outcome (`SCH`).
5. The approval record is **immutable** once written; its hash is chained (`AUD`).

Status: `N/I` — schema by #34, record by H1-HUMANGATE-RECORD, runtime by
[H4-IMPL-HUMANGATE-ENFORCEMENT NN#137](https://github.com/rag-fish/NoesisNoema/issues/137),
regression by [#35](https://github.com/rag-fish/RAGfish/issues/35).

---

## 9. Relationship to the existing architecture

No contradiction with ADR-0000 → ADR-0004.

| Structure | This contract |
|---|---|
| **ADR-0000 — Human Sovereignty** | Reinforced. Routing authority stays with the human (Noesis proposes, never finalizes); decline is always available; only Noesis mutates investigation state, within one invocation; Noema mutates nothing; the capability matrix is the explicit guard against authority escalation (Anti-pattern §6). Model neutrality (ADR-0000 §6) is unchanged here — deferred to Phase 7 ([H7-PROVIDER-MODEL-SELECTION #71](https://github.com/rag-fish/RAGfish/issues/71)). |
| **ADR-0001 — four repos** | No repo boundary changes; this contract lives in `rag-fish/RAGfish`. |
| **ADR-0002 — nine-stage pipeline** | The epistemic lifecycle is an **overlay** (`I10`). Noesis assessment and Noema narrative are Execution-stage work with no Route Contract authority. Trust Evaluation feeds Noesis; trust stays separate from confidence (`INV-10`). |
| **ADR-0003 — four planes, G1–G6, zero runtime gates for ordinary queries** | Preserved. The Human Gate is scoped to B1 only (§7). "Can't rather than won't" = "governance by capability, not supervision." G6 is extended to every epistemic step (Phase 5), not weakened — a missing audit event invalidates the run. |
| **ADR-0004 — epistemic separation** | This contract is the enforcement-mechanism mapping ADR-0004 §"Capability Restrictions" deferred to Issue #33. It operationalises ADR-0004's decisions; it adds none. |
| **`docs/contracts/authority-model.md`** (SYSTEM → USER → AGENT → MODEL) | Consistent. Human noesis (USER) sits above every AGENT/MODEL layer; NOESIS and NOEMA are MODEL-layer capabilities with no authority. |

---

## 10. Deferred decisions

| Decision | Owner |
|---|---|
| Where approved external acquisition executes (is `noema-agent` the executor?) | **ADR-0005 / [H1-ADR-ACQ-LOCUS #43](https://github.com/rag-fish/RAGfish/issues/43)** |
| Whether Noema-layer narrative work is hosted inside `noema-agent` | **ADR-0006 / [H3-ADR-NOEMA-HOSTING #52](https://github.com/rag-fish/RAGfish/issues/52)** |
| The `investigation_result` schema | **[Issue #34](https://github.com/rag-fish/RAGfish/issues/34)** — §6 gives capability-level requirements only |
| Runtime enforcement of every `N/I` mechanism | the named Phase 2–7 implementation tasks (`INV-8`) |
| Governance regression suite | **[Issue #35](https://github.com/rag-fish/RAGfish/issues/35)** |

---

## 11. Validation performed

1. **Cross-check ADR-0000 → ADR-0004** (§9): no contradiction. Every `I1`–`I12` and `INV-1`–`INV-11` is preserved and referenced by its existing identifier; no competing numbering introduced.
2. **No accidental grant to NOEMA** of retrieval, raw-evidence access, external-API access, confidence escalation, or investigation mutation: every NOEMA entry in §4.5, §5 (B4), §6, and the matrix is NO / NONE / CANNOT, each with a mechanism.
3. **No accidental grant to NOESIS** of sovereign governance authority or final approval ownership: §4.2 "Decision authority: None that is sovereign"; `I11`/`I12` cited throughout.
4. **Human Gate scope** (§7): applies only to B1 crossings; ordinary local grounded queries keep ADR-0003's zero runtime gates (`INV-9`).
5. **`noema-agent` not silently redefined** (§4.6, §10): epistemic NOEMA ≠ `noema-agent` (`I9`, `INV-5`); the acquisition-executor question is ADR-0005's, the hosting question ADR-0006's.
6. **Every MUST NOT / CANNOT** has a §3 mechanism or an explicit `N/I` with owner.
7. **Matrix ↔ contract consistency**: the matrix ([CAPABILITY-MATRIX.md](CAPABILITY-MATRIX.md) §5) is a strict superset of ADR-0004 §"Capability Restrictions" (18×6 vs 12×4) with every shared cell identical.

---

## 12. Related documents

- [CAPABILITY-MATRIX.md](CAPABILITY-MATRIX.md)
- [ADR-0004](../adr/ADR-0004-noesis-noema-epistemic-separation.md) · [ADR-0003](../adr/ADR-0003-noema-governance-platform.md) · [ADR-0002](../adr/ADR-0002-noema-governance-pipeline.md) · [ADR-0001](../adr/ADR-0001-noema-architecture.md) · [ADR-0000](../../adr/adr-0000-product-constitution.md)
- [EXECUTION-ROADMAP-v3](../project/EXECUTION-ROADMAP-v3.md) §1 (invariants), §5.2 (the #33 task contract) · [PROJECT-CHARTER-v2](../project/PROJECT-CHARTER-v2.md) · [Human-Governed Development Loop](../human-governed-loop.md)
- GitHub: [#33](https://github.com/rag-fish/RAGfish/issues/33) · downstream [#34](https://github.com/rag-fish/RAGfish/issues/34), [#35](https://github.com/rag-fish/RAGfish/issues/35), ADR-0005 ([#43](https://github.com/rag-fish/RAGfish/issues/43)), ADR-0006 ([#52](https://github.com/rag-fish/RAGfish/issues/52))
