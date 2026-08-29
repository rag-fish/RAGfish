# Noesis / Noema Governance Contract

**Status:** Proposed
**Date:** 2026-08-29
**Deciders:** Taka (governance owner, final reviewer, merge approver) · Max / ChatGPT (architecture review)
**Author:** Claude Code CLI
**Architectural basis:** [ADR-0004: Noesis / Noema Epistemic Separation](../adr/ADR-0004-noesis-noema-epistemic-separation.md) (incl. amendment invariants I11, I12)
**Companion document:** [CAPABILITY-MATRIX.md](CAPABILITY-MATRIX.md)
**Issue:** [rag-fish/RAGfish#33](https://github.com/rag-fish/RAGfish/issues/33) · **Branch:** `docs/governance-capability-contract`
**Scope:** All four Noema repos — the operational governance contract for the epistemic lifecycle.

---

## 1. Purpose

ADR-0004 established the epistemic separation between the layer that *investigates and
assesses* (NOESIS) and the layer that *writes the narrative* (NOEMA), the **Human Gate**
for crossing an external trust boundary, and the principle **"can't rather than won't."**
ADR-0004 §"Capability Restrictions" explicitly defers *the full enforcement-mechanism
mapping — policy / schema / type-system / credential / endpoint / test —* to **this task
(Issue #33)**.

This document is that mapping. It:

1. names every architectural actor and, for each, states what it **MAY**, **MUST**, **MUST NOT**, and **CANNOT** do;
2. classifies each prohibition as **governance-critical** or **advisory**;
3. assigns every governance-critical prohibition an **architectural enforcement mechanism** (or marks it *not yet implemented* with the owning downstream task);
4. is accompanied by [CAPABILITY-MATRIX.md](CAPABILITY-MATRIX.md), which makes capability ownership visually unambiguous.

**This is a governance-contract document only.** It designs no runtime code, no JSON Schema,
no credentials, no endpoints. It does not decide ADR-0005 (acquisition execution locus) or
ADR-0006 (Noema hosting). It does not start Issue #34 or #35.

### The one sentence this contract exists to protect

> **NOESIS assesses. Human noesis governs. No AI layer owns sovereign governance judgment.**

---

## 2. Carried-forward invariants (do not reopen)

This contract is **subordinate to** and does not renumber the invariants already fixed by
ADR-0004 and the Hermes rebaseline. It references them by their existing identifiers.

### ADR-0004 architectural invariants

`I1` lifecycle · `I2` Noesis is the only layer that reads raw evidence / invokes retrieval /
performs calibrated assessment · `I3` external trust-boundary crossing needs recorded human
authorization at the Human Gate (Noesis may *propose*, not *perform*) · `I4` acquired
evidence re-enters Noesis and the assessment is **recomputed**, not patched · `I5`
`investigation_result` is the sole Noesis → Noema handoff · `I6` Noema does presentation
only and **cannot** read raw evidence / reach the evidence store / invoke retrieval / call
external APIs / mutate investigation state / introduce new claims / raise confidence · `I7`
every governance-critical restriction is enforced by capability removal, not prompt
instruction alone · `I8` AI identity cannot own a Human Gate approval; approval ownership is
a human-only field · `I9` epistemic **Noema** ≠ the **`noema-agent`** service · `I10` the
lifecycle maps onto ADR-0003's four planes and ADR-0002's nine stages; it adds a dimension,
it does not replace them · `I11` Noesis outputs (assessments, confidence estimates,
hypotheses, recommendations) are **advisory artifacts** — not governance decisions, routing
authority, approval, or human judgment ownership · `I12` **human noesis** (the sovereign
act, ADR-0000) and the **NOESIS** system layer are distinct; the layer assists, it never
owns sovereign judgment or governance authority.

### Hermes carried-forward invariants (`EXECUTION-ROADMAP-v3.md` §1)

`INV-1` human sovereignty · `INV-2` "can't rather than won't" · `INV-3` `investigation_result`
sole handoff · `INV-4` Noema capability isolation · `INV-5` epistemic Noema ≠ `noema-agent` ·
`INV-6` external trust-boundary crossing is human-gated · `INV-7` recompute, don't append ·
`INV-8` contracts before implementation · `INV-9` local-first default; zero runtime human
gates for ordinary grounded queries · `INV-10` trust ≠ confidence · `INV-11` 1 task = 1
Issue = 1 branch = 1 PR; Taka reviews and merges; every decision recorded.

**The twelfth requirement from Issue #33's framing** — *NOESIS assessment is advisory; human
noesis governs* — is **ADR-0004 I11 + I12**, restated here for emphasis, not a new invariant.

---

## 3. "Can't rather than won't" — the enforcement taxonomy

ADR-0004 §2: a restriction is **governance-critical** when its violation would

- **(a)** cross an external trust boundary without human authorization,
- **(b)** introduce a factual claim that no evidence supports,
- **(c)** raise a stated confidence above what the investigation justified, or
- **(d)** represent AI as the owner of a human approval.

For every governance-critical restriction, the architecture removes the **capability**, not
merely instructs against its use. Prompt-level instruction is permitted **as defense in
depth, never as the sole control.**

### Enforcement mechanism classes

| Code | Mechanism | "Can't" because… |
|---|---|---|
| **CRED** | Credential absent from the execution context | there is no key to authenticate with |
| **EP** | Endpoint / outbound-network capability absent | there is nowhere to send the request |
| **CTX** | Separate execution context / process / module boundary | the capability is not linked into this context |
| **BIND** | Tool / retrieval / evidence-store binding absent | the function is not wired in |
| **SCH** | Schema constraint — a field is absent, or its type forbids the value | the data cannot be represented |
| **TYP** | Type-system / language-level constraint | the code does not compile |
| **VAL** | Deterministic output validator rejects the violating output | the output is refused before it is surfaced |
| **POL** | Policy manifest (`noema-policy.yaml`) declares the boundary | the run is rejected at policy evaluation |
| **AUD** | Append-only hash-chained audit (ADR-0003 G6); a missing or altered event invalidates the run | tampering is detectable and fails the run |
| **HUM** | Human-only field / human identity required; AI actor identity rejected | an AI cannot populate the field |
| **DID** | Defense-in-depth prompt instruction — **never a sole control** | (supplementary only) |
| **N/I** | **Not yet implemented** — mechanism named, owned by a downstream task | (tracked, not yet enforced) |

`N/I` is legitimate for this contract: Issue #33 is a *contract*, and INV-8 ("contracts
before implementation") means enforcement lands later. Every `N/I` entry names its owning
downstream task so the gap is tracked, not hidden.

---

## 4. Architectural actors

Seven actors. For each: **Purpose · Inputs · Outputs · Allowed · Forbidden · Decision
authority · Trust-boundary access · Credential access · Retrieval access · Evidence access ·
Mutation rights · External API rights · Human-approval requirements.**

### 4.1 Human / human noesis

| Field | Statement |
|---|---|
| **Purpose** | The **sovereign** act of inquiry, judgment, and decision ownership (ADR-0004 I12; ADR-0000). Originates the question; governs the lifecycle; owns every governance decision and every Human Gate approval. |
| **Inputs** | The user's own question and intent; NOESIS advisory artifacts (assessments, confidence estimates, hypotheses, recommendations, acquisition proposals); audit records; the NOEMA narrative. |
| **Outputs** | Governance decisions; Human Gate approvals / declines (human-owned); acceptance or rejection of NOESIS recommendations; routing authorization; the decision to run, halt, redirect, or override any execution. |
| **Allowed** | Everything the architecture reserves to a human: authorize/decline external acquisition; approve governance decisions; finalize routing; halt or override any execution (ADR-0000 §4); assert their own claims and judgments; accept or reject any AI advisory output. |
| **Forbidden** | Nothing is *forbidden* to the human by this contract. (The human is bound by ADR-0000's constraints on how the *system* may act on their behalf, not by a capability ceiling.) |
| **Decision authority** | **Total and sovereign.** Human noesis governs. No AI layer's output substitutes for it (I11, I12). |
| **Trust-boundary access** | Authorizes crossings of B1 (corpus boundary). Owns B3 (approval-authority boundary) — only a human is on the authorizing side. |
| **Credential access** | The human operator manages provider / evidence-store credentials **out of band**. Credentials are never handed to an AI layer that this contract marks credential-absent. |
| **Retrieval access** | May search their own corpus through the application surface. |
| **Evidence access** | Full — it is the human's own corpus. Sees NOESIS's evidence-chain *summaries*, not necessarily raw dumps, in the advisory artifacts. |
| **Mutation rights** | Governs whether an investigation runs, re-runs, or stops. Does **not** hand-edit `investigation state` or `investigation_result` as data operations — those are NOESIS-owned; the human governs them, NOESIS performs them. |
| **External API rights** | Out-of-band credential owner; authorizes acquisition. |
| **Human-approval requirements** | N/A — the human *is* the approver. |

### 4.2 NOESIS layer

| Field | Statement |
|---|---|
| **Purpose** | The investigative and **calibrated-epistemic-assessment** layer. It **assists** human noesis; it does not exercise it (ADR-0004 I12). It **assesses; it does not govern.** |
| **Inputs** | The human's question; **Evidence** (retrieved chunks from the user-owned corpus with provenance + trust metadata; and — only after Human Gate approval — externally acquired sources); policy context. |
| **Outputs** | The `investigation_result` handoff object (sole producer); and, when current evidence is insufficient, a **proposal** for additional external evidence acquisition addressed to the Human Gate. Every NOESIS output is an **advisory artifact** (I11). |
| **Allowed** | Investigation; claim decomposition; evidence synthesis; competing-hypothesis maintenance; source-dependency analysis (many reports from one origin = **one** independent chain); uncertainty representation; calibrated assessment (bounded assessment state + calibrated confidence reflecting evidence strength and independence, *not* model fluency); reads raw evidence; invokes retrieval **over the user-owned corpus**; mutates investigation state (it owns it); produces `investigation_result`; **proposes** acquisition. |
| **Forbidden / CANNOT** | Unilaterally cross an external trust boundary (I3 — proposes only) · own a Human Gate approval (I8) · own a governance decision, routing authority, or sovereign judgment (I11, I12) · call external APIs (proposes only) · access external-API credentials · raise confidence beyond what the evidence and its independence justify. |
| **Decision authority** | **None that is sovereign.** NOESIS *recommends*; the human *decides*. Its assessments, confidence estimates, hypotheses, and recommendations "do not constitute governance decisions, routing authority, approval, or human judgment ownership" (I11). |
| **Trust-boundary access** | Reads across the corpus interior freely. **Cannot** cross B1 (proposes only). Is the *only* actor on the investigation side of B2 (produces `investigation_result`). Cannot cross B3 (no approval ownership). |
| **Credential access** | Evidence-store credentials: **YES** (it is the layer that reads the corpus). External-API credentials: **NO** (CRED). |
| **Retrieval access** | **YES** over the user-owned corpus (I2). No retrieval outside it. |
| **Evidence access** | **Full** for user-owned-corpus evidence and for evidence returned by an *approved* acquisition. Is the *only* layer that reads raw evidence (I2). |
| **Mutation rights** | **Sole owner** of investigation state. On re-analysis it **recomputes** over the enlarged evidence set — it does not patch, append, or override a prior assessment downstream (I4, INV-7). |
| **External API rights** | **NONE.** May emit an acquisition *proposal* only. |
| **Human-approval requirements** | Must obtain a recorded Human Gate approval before any externally-acquired evidence may enter the investigation (I3). Declining is a valid outcome — NOESIS then produces `investigation_result` on existing evidence with the corresponding uncertainty stated. |

### 4.3 Human Gate

| Field | Statement |
|---|---|
| **Purpose** | The explicit governance **checkpoint** for crossing an external trust boundary (B1). It is the **only** mechanism by which external evidence acquisition becomes permitted. It is a checkpoint, **not an actor with authority of its own** — a *human* authorizes *through* it. |
| **Inputs** | A NOESIS acquisition **proposal** (specific external evidence, with rationale). |
| **Outputs** | A recorded, scoped **approval** owned by a human identity — **or** a recorded **decline**. Both emit an audit event. |
| **Allowed** | Present the proposal to a human; capture the human's explicit authorization or decline; record it with scope (a specific acquisition, not a standing capability); emit the audit event. |
| **Forbidden / CANNOT** | Authorize on its own · infer approval from human inaction · extend a prior approval to a new or different acquisition · represent an agent / model / service as the approver (`approved_by` is a **human-only field** — I8, B3). |
| **Decision authority** | **None of its own.** It carries a *human's* decision. |
| **Trust-boundary access** | Sits astride B1. Authorizes (via a human) a crossing; performs no crossing itself. Owns the human side of B3. |
| **Credential access** | **NONE.** |
| **Retrieval access** | **NONE.** |
| **Evidence access** | Reviews the *proposal* and the NOESIS-supplied context for it. Not an arbitrary evidence-store reader. |
| **Mutation rights** | **NONE** over investigation state. |
| **External API rights** | **NONE.** |
| **Human-approval requirements** | It *is* the approval-capture mechanism. **Scope note:** this gate applies **only** when investigation would reach outside the user-owned corpus. It does **not** add a runtime approval prompt to ordinary grounded queries inside the user's own corpus — those still pass **zero** runtime human gates (ADR-0003; INV-9). See §7. |

### 4.4 External Evidence Acquisition layer

| Field | Statement |
|---|---|
| **Purpose** | Acquire **new external evidence** — sources not already in the user-owned corpus — **only** after a Human Gate approval, and **only** within the scope that approval granted. |
| **Inputs** | A valid, scoped Human Gate approval record; the acquisition request it authorizes. |
| **Outputs** | Acquired evidence, captured with provenance and trust metadata comparable to corpus evidence, **returned into NOESIS** (which recomputes — I4). An audit event per acquisition. |
| **Allowed** | Invoke external APIs / web retrieval / third-party services **within the approved scope**; write the acquired evidence into the evidence store; return it to NOESIS. |
| **Forbidden / CANNOT** | Run without a valid approval record (the sealed gateway rejects it — H4-SEALED-GATEWAY) · exceed the approved scope · deliver evidence anywhere except back into NOESIS · patch or append to a prior assessment (it returns evidence; NOESIS recomputes) · originate an acquisition (it executes; it does not decide). |
| **Decision authority** | **None.** Executes an approved, scoped instruction. |
| **Trust-boundary access** | The **only** actor that crosses B1 — and only with a valid approval (I3). |
| **Credential access** | External-API credentials: **YES, within approved scope**, provided by the operator out of band. Evidence-store: **write path** for the acquired evidence. |
| **Retrieval access** | Fetches *external* sources (not "retrieval" over the user corpus). |
| **Evidence access** | Reads the sources it fetched; writes them into the store with provenance. |
| **Mutation rights** | **NONE** over investigation state — it returns evidence; NOESIS recomputes. |
| **External API rights** | **YES**, scoped to the approval. |
| **Human-approval requirements** | **A valid, scoped, human-owned Human Gate approval is a hard precondition.** No approval ⇒ no acquisition (structural — the gateway fails closed). |
| **Execution locus** | **UNRESOLVED — deferred to ADR-0005 / [H1-ADR-ACQ-LOCUS](https://github.com/rag-fish/RAGfish/issues/43).** This contract does **not** decide that `noema-agent` (or any component) is the executor. |

### 4.5 NOEMA layer (epistemic)

| Field | Statement |
|---|---|
| **Purpose** | Presentation / **narrative transformation only**. Transforms `investigation_result` into user-facing narrative. That is its entire remit (ADR-0004 I6). |
| **Inputs** | **`investigation_result` and nothing else** from the investigation side (I5, B2). |
| **Outputs** | User-facing narrative — a reordered, summarised, explained, formatted rendering of the findings already present in `investigation_result`, carrying through the assessment states, confidence, uncertainty, and competing hypotheses **exactly as received**. |
| **Allowed** | Reorder · summarise · explain · format · surface the stated limitations · present the competing hypotheses NOESIS recorded · carry the calibrated confidence and uncertainty through **unchanged**. |
| **Forbidden / CANNOT** | Read raw evidence · reach the evidence store · invoke retrieval · call external APIs · cross the corpus boundary · mutate investigation state · introduce a new factual claim · **raise confidence above the NOESIS result** · acquire a fact it finds missing (the correct outcome is to *state the limitation*, not fetch — needing more evidence is a signal to return to NOESIS via a new human-initiated request, never a licence for NOEMA to retrieve). |
| **Decision authority** | **None.** |
| **Trust-boundary access** | On the **outside** of B4 (evidence-access boundary) with **no capability to cross** (I6). Consumes B2 in one direction only; no back-channel. |
| **Credential access** | **NONE** — runs without evidence-store credentials and without outbound-network capability to provider APIs (CRED, EP). |
| **Retrieval access** | **NONE** — no retrieval binding (BIND). |
| **Evidence access** | **NONE** — raw evidence objects are not present in its input; only the evidence-chain *summary* inside `investigation_result` (SCH — enforced by the #34 contract). |
| **Mutation rights** | **NONE.** |
| **External API rights** | **NONE.** |
| **Human-approval requirements** | N/A — NOEMA is downstream of every approval; it never triggers one. |

### 4.6 `noema-agent` execution service (existing)

| Field | Statement |
|---|---|
| **Purpose** | The constrained, **stateless Execution Layer** — *"exists to execute, not to decide."* Policy enforcement, Route Contract formation, verification, decision logging. **Unchanged by ADR-0004 and by this contract.** |
| **Inputs** | An ExecutionContext / Route Contract (formed under the nine-stage pipeline). |
| **Outputs** | Execution results; Route Contract; decision-log entries; audit events. |
| **Allowed** | Execute the provided ExecutionContext; form the Route Contract (*declare*, not finalize); enforce policy; run verification; write decision-log entries; emit audit events. |
| **Forbidden / CANNOT** | Construct routing decisions autonomously · finalize routing without human approval (ADR-0000 §2) · mutate constraints or escalate authority (ADR-0000 §6 anti-pattern) · gain intent, memory, or decision authority · **be silently redefined as the epistemic NOEMA layer** (I9, I5) · **be assumed to be the External Acquisition executor** (that is ADR-0005's decision, not this contract's). |
| **Decision authority** | **None.** Execution only. |
| **Trust-boundary access** | None that this contract grants. |
| **Credential access** | Its existing v2 posture (unchanged). This contract adds **no** external-API or evidence-store credential. |
| **Retrieval access** | Not a retrieval layer. |
| **Evidence access** | None that this contract grants. |
| **Mutation rights** | Stateless — no investigation-state mutation. Audit is append-only. |
| **External API rights** | Its existing constrained v2 posture. **This contract grants no new external-API right.** Any future acquisition-executor role is **ADR-0005**. |
| **Human-approval requirements** | Route Contract may **declare** an approval requirement; it does not execute high-stakes routing until the recorded approval exists (ADR-0002 §8). |
| **Relationship to epistemic NOEMA** | **`noema-agent` ≠ epistemic NOEMA** (I9, INV-5). They are different concepts. A later ADR (ADR-0006) *may* decide to *host* Noema-layer narrative work as a constrained task inside `noema-agent`; **until that ADR is accepted, "NOEMA" means the epistemic layer and "`noema-agent`" means the execution service**, and neither definition is substituted for the other. |

### 4.7 Evidence store / evidence infrastructure (resource, not an autonomous actor)

| Field | Statement |
|---|---|
| **Purpose** | Holds Evidence (user-owned-corpus chunks with provenance + trust metadata per RAGpack v1.3 / ADR-0003 Knowledge plane; and — after Human Gate approval — externally acquired sources with comparable provenance). |
| **Read access** | **NOESIS only** (I2). |
| **Write access** | The pipeline (corpus ingestion) and the External Acquisition layer (approved acquisitions), within their boundaries. |
| **NOEMA access** | **NONE** — no credentials, no binding, not in NOEMA's input surface (CRED, BIND, SCH). This is B4. |
| **`noema-agent` access** | **NONE** granted by this contract. |
| **Trust metadata** | Carries the ex-ante **trust** signal, which is **separate from** the NOESIS-calibrated **confidence** (INV-10). Neither substitutes for the other. |

---

## 5. Trust boundaries and their enforcement

| Boundary | Between | Crossing rule | Enforcement (this contract) |
|---|---|---|---|
| **B1 — Corpus boundary** | user-owned corpus ↔ external sources | crossed **only** by External Evidence Acquisition, **only** after a valid Human Gate approval (I3) | **HUM** (approval is a human-only field) + **N/I: sealed gateway** rejects any acquisition call lacking a valid approval record — owned by [H4-SEALED-GATEWAY](https://github.com/rag-fish/RAGfish/issues/53) / [H4-IMPL-HUMANGATE-ENFORCEMENT](https://github.com/rag-fish/NoesisNoema/issues/137); regression [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| **B2 — Epistemic handoff** | NOESIS ↔ NOEMA | crossed **only** by `investigation_result`, one direction, no back-channel (I5) | **CTX** (separate execution context) + **SCH** (`investigation_result` is NOEMA's *only* input field) + **N/I** — owned by [H3-NOEMA-ISOLATION](https://github.com/rag-fish/RAGfish/issues/49) / [H3-IMPL-NOEMA-CONTEXT](https://github.com/rag-fish/NoesisNoema/issues/133) |
| **B3 — Approval-authority** | AI identity ↔ human approval | AI **cannot** cross into approval ownership (I8) | **HUM** + **SCH** (`approved_by` type accepts a human identity only; an agent/model/service identity is rejected) + **N/I** — schema owned by [#34](https://github.com/rag-fish/RAGfish/issues/34) / [H1-HUMANGATE-RECORD](https://github.com/rag-fish/RAGfish/issues/41); regression [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| **B4 — Evidence-access** | raw evidence / evidence store / retrieval ↔ NOEMA | NOEMA is on the outside with **no capability to cross** (I6) | **CRED** (no evidence-store credential in NOEMA) + **EP** (no outbound network to provider APIs) + **BIND** (no retrieval binding) + **SCH** (no raw-evidence field in NOEMA's input) + **N/I** — owned by [H3-NOEMA-ISOLATION](https://github.com/rag-fish/RAGfish/issues/49); adversarial regression [H3-TEST-CAPABILITY-ISOLATION](https://github.com/rag-fish/NoesisNoema/issues/135), [#35](https://github.com/rag-fish/RAGfish/issues/35) |

---

## 6. `investigation_result` — the handoff boundary (capability-level requirements only)

`investigation_result` is the **sole** Noesis → Noema handoff object (I5, INV-3). **This
contract does not define its JSON Schema — [Issue #34](https://github.com/rag-fish/RAGfish/issues/34)
owns that.** This contract states the **capability-level requirements** the #34 schema and
its validator must enforce:

| Requirement | Rationale | Mechanism #34 must use |
|---|---|---|
| **No raw evidence objects** — evidence-chain **summary** only (including independent-source-chain counts) | B4; I6 — NOEMA must have no path to raw evidence | **SCH** — the schema has no raw-evidence field; raw content is unrepresentable |
| **Calibrated findings** — bounded assessment states + calibrated confidence + explicit uncertainty | I11; INV-10 — advisory, evidence-strength-based, trust ≠ confidence | **SCH** — bounded enum (no `verified: boolean`); confidence + uncertainty are distinct fields |
| **Uncertainty preserved** — what is unknown / unresolved / under-evidenced is carried, not dropped | ADR-0004 §"Uncertainty" | **SCH** — uncertainty is a required, non-nullable field |
| **Confidence cannot be increased by NOEMA** — the value NOEMA receives is a ceiling | (c) governance-critical; I6 | **VAL** — a downstream validator rejects any NOEMA output whose asserted confidence exceeds the `investigation_result` value (owned by [H3-OUTPUT-VALIDATION-SPEC](https://github.com/rag-fish/RAGfish/issues/51) / [H3-IMPL-OUTPUT-VALIDATOR](https://github.com/rag-fish/NoesisNoema/issues/134)) |
| **Traceable claim identifiers** — every claim carries a stable ID minted by NOESIS | (b) governance-critical — lets the validator detect a NOEMA-introduced claim | **SCH** + **VAL** — claim-set diff vs `investigation_result`; a claim ID not present in the handoff is a NOEMA-introduced claim and is rejected |
| **Immutable approved NOESIS state** — the handoff is a frozen snapshot of the recomputed assessment; nothing downstream edits it | I4, I5, INV-7 | **SCH/TYP** — the object is read-only to consumers; **AUD** — its hash is recorded in the audit chain |
| **Human-approval record for any external acquisition that occurred** — carried, with a human `approved_by` | I8, B3 | **SCH** — `approved_by` is a human-only-typed field |
| **Version pinning** — records the `(embedder_id, model_id, manifest_sha256)` triplet | ADR-0003 G2 | **SCH** — required triplet field |

Downstream design constraints for #34 stop here. **Field names, cardinalities, the assessment-state
enum, and example payloads are #34's to design** — this contract does not preempt them.

---

## 7. The Human Gate — scope statement (read this before implementing anything)

**The Human Gate in this contract is *exclusively* for crossing the external trust boundary
(B1).** "External" = any source not already in the user-owned corpus: external APIs, web
retrieval, third-party services, provider tools.

**It MUST NOT introduce a runtime approval prompt for ordinary grounded queries inside the
user's own corpus.** ADR-0003's design choice stands unchanged:

- Ordinary grounded queries pass **zero** runtime human gates (ADR-0003 §"governance without runtime humans"; INV-9).
- Governance for ordinary queries is achieved by *ex-ante policy* (`noema-policy.yaml`) plus *ex-post verifiable audit* (hash chain) — **not** by a per-query approval.
- The Human Gate is the **investigation-time analogue** of ADR-0003's Human Decision Gate for policy changes and pack promotion — a checkpoint at the exact boundary where trust changes, and nowhere else.

**Enforcement of this scope limit:** the Human Gate is *only* reachable from a NOESIS
acquisition **proposal**, which is *only* produced when NOESIS determines current evidence
is insufficient **and** would need to reach outside the corpus. There is no code path from
an ordinary retrieval over the user-owned corpus to the Human Gate. (Structural — owned by
the runtime tasks; regression coverage: [#35](https://github.com/rag-fish/RAGfish/issues/35),
[H3/H4 tests].)

---

## 8. `approved_by` / approval ownership — the human-only field

Per ADR-0004: *"Approval ownership is a human-only field (Issue #33 / #34 encode the
enforcement)."* This contract's requirement (the schema is #34's, the record shape is
[H1-HUMANGATE-RECORD](https://github.com/rag-fish/RAGfish/issues/41)'s):

1. `approved_by` **MUST** be typed such that it accepts **only a human identity**. An agent, model, or service identity **CANNOT** be represented in it (**SCH/TYP** + **HUM**).
2. Approval **MUST NOT** be inferred from human inaction (no timeout-approves, no default-approve) (**SCH** — there is no "implicit approval" state).
3. An approval **MUST** be **scoped** to a specific acquisition and **MUST NOT** be extended to a later or different acquisition (**SCH** — scope is a required field; the gateway matches request↔approval scope).
4. A **decline** is a first-class, recorded outcome (**SCH** — decline is a representable, audited state).
5. The approval record is **immutable** once written and its hash is recorded in the audit chain (**AUD**).

Enforcement status: **N/I** (contract-level requirement; schema by #34, record by
H1-HUMANGATE-RECORD, runtime by H4-IMPL-HUMANGATE-ENFORCEMENT, regression by #35).

---

## 9. Relationship to the existing architecture (no contradictions)

| Existing structure | This contract's relationship |
|---|---|
| **ADR-0000 — Human Sovereignty** | Reinforced. §1: "human noesis governs and AI accompanies." §2 Routing Authority → NOESIS *proposes*, never finalizes; the human authorizes. §4 Human Override → decline at the Human Gate is always available. §5 State Mutation Consent → only NOESIS mutates investigation state, within one invocation; NOEMA mutates nothing. §6 Model Neutrality → deferred to Phase 7 (H7-PROVIDER-MODEL-SELECTION), unchanged here. Anti-pattern §6 (authority escalation) → the capability matrix is the explicit guard. |
| **ADR-0001 — four repos** | No repo boundary changes. This contract lives in `rag-fish/RAGfish` (Architecture Hub). |
| **ADR-0002 — nine-stage pipeline** | The epistemic lifecycle is an **overlay** (I10). NOESIS assessment and NOEMA narrative are *Execution*-stage work; neither owns *Route Contract* authority. Trust Evaluation (stage 3) feeds NOESIS; trust stays separate from the confidence NOESIS calibrates (INV-10). |
| **ADR-0003 — four planes, G1–G6, zero runtime human gates for ordinary queries** | Preserved. The Human Gate is **scoped to the external trust boundary only** (§7). "Can't rather than won't" = ADR-0003's "governance by capability, not supervision." G6 (audit completeness) is extended to every epistemic step (owned by Phase 5); a missing audit event invalidates the run. |
| **ADR-0004 — epistemic separation** | This contract is the enforcement-mechanism mapping ADR-0004 §"Capability Restrictions" deferred to Issue #33. It adds nothing to ADR-0004's decisions; it operationalises them. |
| **`docs/contracts/authority-model.md`** — SYSTEM → USER → AGENT → MODEL | Consistent. Human noesis (USER) sits above every AGENT/MODEL layer; NOESIS and NOEMA are MODEL-layer capabilities with no authority. |
| **Human-Governed Loop** | This document was produced as `1 task = 1 Issue (#33) = 1 branch (docs/governance-capability-contract) = 1 PR`; Taka reviews and merges; Max / ChatGPT architecture-reviews (INV-11). |

---

## 10. Unresolved / deferred enforcement decisions

| Decision | Owner | Why this contract does not decide it |
|---|---|---|
| **Where approved external acquisition executes** (is `noema-agent` the executor?) | **ADR-0005 / [H1-ADR-ACQ-LOCUS](https://github.com/rag-fish/RAGfish/issues/43)** | ADR-0004 names `noema-agent` only as a *candidate* and explicitly defers this. §4.4 / §4.6 mark the External Acquisition executor and `noema-agent`'s acquisition role as **UNRESOLVED**. |
| **Whether NOEMA-layer narrative work is hosted inside `noema-agent`** | **ADR-0006 / [H3-ADR-NOEMA-HOSTING](https://github.com/rag-fish/RAGfish/issues/52)** | ADR-0004 Rejected Alternative D leaves this open. Until ADR-0006, "NOEMA" = the epistemic layer and "`noema-agent`" = the execution service; the capability matrix's `noema-agent` column for narrative is **CONDITIONAL — ADR-0006**. |
| **The `investigation_result` JSON Schema** | **[Issue #34](https://github.com/rag-fish/RAGfish/issues/34)** | §6 gives capability-level requirements only. |
| **Runtime enforcement of every `N/I` mechanism** | The named Phase 2–7 implementation tasks | INV-8: contract before implementation. Every `N/I` cell names its owning task. |
| **Governance regression suite** | **[Issue #35](https://github.com/rag-fish/RAGfish/issues/35)** | Adversarial proof that the boundary fails closed; not authored here. |

---

## 11. Validation performed

See [CAPABILITY-MATRIX.md](CAPABILITY-MATRIX.md) §"Validation" for the matrix-side checks.
For this contract:

1. **Cross-checked ADR-0000 → ADR-0004** (§9). No contradiction found. Every ADR-0004
   invariant I1–I12 and every Hermes INV-1–INV-11 is preserved and referenced by its
   existing identifier; **no competing invariant numbering is introduced.**
2. **Searched for accidental grants to NOEMA** of retrieval, raw-evidence access, external-API
   access, confidence escalation, or investigation mutation: **none.** Every NOEMA row in §4.5,
   §5 (B4), §6, and the capability matrix is "NO / NONE / CANNOT," each with a mechanism.
3. **Searched for accidental grants to NOESIS** of sovereign governance authority or final
   human-approval ownership: **none.** §4.2 "Decision authority: None that is sovereign";
   I11/I12 cited throughout; "NOESIS assesses, human noesis governs" is the contract's stated
   purpose.
4. **Human Gate scope** (§7): confirmed it applies **only** to B1 crossings and does **not**
   touch ordinary local grounded queries; ADR-0003's zero-runtime-gate behaviour is restated
   and preserved (INV-9).
5. **`noema-agent` not silently redefined** (§4.6, §10): stated three times that epistemic
   NOEMA ≠ `noema-agent` (I9, INV-5); the acquisition-executor question is explicitly left to
   ADR-0005; the hosting question to ADR-0006.
6. **Every MUST NOT / CANNOT rule** has an architectural enforcement mechanism from the §3
   taxonomy, **or** is explicitly marked `N/I` with its owning downstream task.
7. **Matrix ↔ prose consistency**: the capability matrix is a strict operationalisation of
   §4; §"Cross-check against ADR-0004" in the matrix document confirms the matrix does not
   contradict ADR-0004 §"Capability Restrictions" (it is a superset — 18 rows × 6 columns vs
   ADR-0004's 12 × 4 — with every shared cell identical).

No contradictions found. Where a rule is not yet enforced in running code, it is marked
`N/I` and attributed, per DoD.

---

## 12. Related documents

- [CAPABILITY-MATRIX.md](CAPABILITY-MATRIX.md) — the companion matrix
- [ADR-0004: Noesis / Noema Epistemic Separation](../adr/ADR-0004-noesis-noema-epistemic-separation.md) — architectural basis
- [ADR-0003: Noema Governance Platform (v0.8)](../adr/ADR-0003-noema-governance-platform.md) — four planes, G1–G6, zero-runtime-gate design
- [ADR-0002: Noema Governance Pipeline](../adr/ADR-0002-noema-governance-pipeline.md) — nine-stage pipeline, Route Contract
- [ADR-0001: Noema Architecture](../adr/ADR-0001-noema-architecture.md) — four-repo structure
- [ADR-0000: Product Constitution / Human Sovereignty](../../adr/adr-0000-product-constitution.md)
- [EXECUTION-ROADMAP-v3.md](../project/EXECUTION-ROADMAP-v3.md) — §1 carried-forward invariants; §5.2 the #33 task contract
- [PROJECT-CHARTER-v2.md](../project/PROJECT-CHARTER-v2.md)
- [Human-Governed Development Loop](../human-governed-loop.md)
- [`docs/architect/noema-agent-v2.md`](../../architect/noema-agent-v2.md) — the constrained execution service definition
- GitHub Issue: [rag-fish/RAGfish#33](https://github.com/rag-fish/RAGfish/issues/33)
- Downstream: [#34](https://github.com/rag-fish/RAGfish/issues/34) (`investigation_result` schema), [#35](https://github.com/rag-fish/RAGfish/issues/35) (governance regression cases), ADR-0005 ([#43](https://github.com/rag-fish/RAGfish/issues/43)), ADR-0006 ([#52](https://github.com/rag-fish/RAGfish/issues/52))
