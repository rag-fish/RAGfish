# Noesis / Noema Capability Matrix

**Status:** Proposed
**Date:** 2026-08-29
**Deciders:** Taka (governance owner) · Max / ChatGPT (architecture review)
**Author:** Claude Code CLI
**Architectural basis:** [ADR-0004: Noesis / Noema Epistemic Separation](../adr/ADR-0004-noesis-noema-epistemic-separation.md)
**Prose contract:** [NOESIS-NOEMA-GOVERNANCE-CONTRACT.md](NOESIS-NOEMA-GOVERNANCE-CONTRACT.md)
**Issue:** [rag-fish/RAGfish#33](https://github.com/rag-fish/RAGfish/issues/33)

This matrix operationalises [NOESIS-NOEMA-GOVERNANCE-CONTRACT.md](NOESIS-NOEMA-GOVERNANCE-CONTRACT.md)
§4. It is a strict **superset** of ADR-0004 §"Capability Restrictions" (see §5). Where the
matrix and the prose contract could differ, **the more restrictive reading wins** and must
be reported, not silently weakened.

---

## 1. Legend

### Capability state

| Value | Meaning |
|---|---|
| **YES** | The actor may and can perform this. |
| **NO** | The actor **cannot** — the capability is architecturally absent (not merely discouraged). Governance-critical `NO` cells carry an enforcement mechanism. |
| **COND** | Conditional — allowed only under a stated precondition; see the row note. |
| **N/A** | Not applicable — the actor is not part of this operation's flow. |

### Enforcement mechanism codes (see contract §3)

`CRED` credential absent · `EP` no outbound endpoint / network · `CTX` separate execution
context · `BIND` no tool/retrieval/evidence-store binding · `SCH` schema constraint (field
absent / type forbids) · `TYP` type-system constraint · `VAL` deterministic output validator ·
`POL` policy-manifest declared · `AUD` append-only hash-chained audit (G6) · `HUM` human-only
field / human identity required · `DID` defense-in-depth prompt (**never a sole control**) ·
`N/I` **not yet implemented** — mechanism named, owned by a downstream task.

### Governance-critical restriction classes (ADR-0004 §2)

`(a)` cross an external trust boundary without human authorization · `(b)` introduce a
factual claim no evidence supports · `(c)` raise a stated confidence above what the
investigation justified · `(d)` represent AI as the owner of a human approval.

---

## 2. The matrix

**Columns.** `Human` = human noesis (the sovereign act of inquiry, judgment, and decision
ownership — ADR-0004 I12) plus the human operator. The other five are the ADR-0004 epistemic
actors plus the existing `noema-agent` execution service (ADR-0004 I9 — a *distinct* concept
from epistemic NOEMA).

| # | Capability | Human | NOESIS | Human Gate | External Acquisition | NOEMA | noema-agent |
|---|---|---|---|---|---|---|---|
| 1 | Read raw evidence | YES | **YES** (I2) | COND `[n1]` | YES (approved scope) | **NO** `CRED,BIND,SCH,CTX` (b4) | **NO** — not granted |
| 2 | Read `investigation_result` | YES (via artifacts) | YES (produces it) | N/A | N/A | **YES** (sole consumer, I5) | COND `[n2]` |
| 3 | Write / update investigation state | **NO** `[n3]` | **YES** (sole owner, I4) | **NO** | **NO** — returns evidence; NOESIS recomputes (I4, INV-7) | **NO** `CTX,SCH` (I6) | **NO** (stateless) |
| 4 | Produce epistemic assessment (calibrated, advisory) | **NO** `[n4]` | **YES** (sole producer; advisory, I11) | **NO** | **NO** | **NO** (I6) | **NO** |
| 5 | Propose additional evidence acquisition | YES | **YES** (proposal only, I3) | **NO** (receives it) | **NO** (executes, not originates) | **NO** (I6) | **NO** |
| 6 | Authorize external acquisition | **YES** (sole authorizing identity) `HUM` (d) | **NO** (proposes only, I3) | COND `[n5]` | **NO** | **NO** | **NO** |
| 7 | Execute external acquisition | COND `[n6]` | **NO** (I3) | **NO** (authorizes, ≠ executes) | **YES** — approved scope only, after a valid Human Gate approval (I3) (a) | **NO** `EP,CRED` (I6) | **COND — UNRESOLVED, ADR-0005** `[n7]` |
| 8 | Access external-API credentials | COND `[n8]` | **NO** `CRED` | **NO** `CRED` | YES (approved scope; out-of-band) | **NO** `CRED,EP` (b4) | **COND — ADR-0005** `[n7]` |
| 9 | Access evidence-store credentials | COND `[n8]` | **YES** (reads the corpus, I2) | **NO** `CRED` | COND — write path for approved evidence `[n9]` | **NO** `CRED` (b4) | **NO** — not granted |
| 10 | Perform retrieval (over user-owned corpus) | YES (app surface) | **YES** (corpus only, I2) | **NO** `BIND` | N/A `[n10]` | **NO** `BIND` (b4) | **NO** (not a retrieval layer) |
| 11 | Introduce new factual claims | YES (own judgment) | **YES** (from evidence; stable claim ID) | **NO** | **NO** (returns evidence, ≠ asserts) | **NO** `VAL,SCH` (b) | **NO** |
| 12 | Modify claim confidence | YES (human judgment may override/annotate) | **YES** (sole calibrator; set once over all evidence) | **NO** | **NO** (triggers recompute; NOESIS re-sets) | **NO** `VAL` (c) | **NO** |
| 13 | Increase confidence during presentation | N/A `[n11]` | N/A (does not present) | N/A | N/A | **NO** `VAL` — ceiling = `investigation_result` value (c) | N/A |
| 14 | Produce narrative / presentation | COND `[n12]` | **NO** (produces `investigation_result`, ≠ narrative) | **NO** | **NO** | **YES** (sole producer, I6) | **COND — ADR-0006** `[n2]` |
| 15 | Approve governance decision | **YES** (sovereign — I11, I12) `HUM` | **NO** (advisory only, I11) | **NO** (checkpoint, ≠ authority) | **NO** | **NO** | **NO** ("execute, not decide") |
| 16 | Route execution | **YES** (routing authority stays with the human — ADR-0000 §2) | **NO** (may propose acquisition; does not route, I11) | **NO** | **NO** | **NO** | **COND** — *forms* the Route Contract (declares, ≠ finalizes); no finalization without human approval `[n13]` |
| 17 | Mutate audit history | **NO** `AUD` | **NO** `AUD` | **NO** `AUD` | **NO** `AUD` | **NO** `AUD` | **NO** `AUD` `[n14]` |
| 18 | Emit audit events | N/A `[n15]` | **YES** (every governed action — G6) | **YES** (approve/decline) | **YES** (per acquisition) | **YES** (per output validation) | **YES** (per execution) |

**The two cells most likely to be eroded under iteration pressure** (ADR-0004 calls these
out explicitly):

- **Row 1 / NOEMA = NO** and **rows 8–10 / NOEMA = NO**: NOEMA has **no** evidence-acquisition
  capability of any kind — no retrieval, no evidence store, no external API, no corpus-boundary
  crossing. Every one of those cells is NO **by architecture**.
- **Rows 12–13 / NOEMA = NO**: NOEMA **cannot raise confidence**. It carries the NOESIS
  calibrated confidence and uncertainty through unchanged and has no path to compute or assert
  a higher one.

---

## 3. Row notes

- **`[n1]`** *Human Gate / read raw evidence — COND.* The Gate reviews the NOESIS **acquisition
  proposal** and the context NOESIS supplies with it. It is **not** an arbitrary evidence-store
  reader — it has no evidence-store binding and no credential. Bounded to the proposal.
- **`[n2]`** *noema-agent / read `investigation_result` & produce narrative — COND, ADR-0006.*
  Today epistemic **NOEMA ≠ `noema-agent`** (I9, INV-5) — `noema-agent` does **NO** narrative
  and reads **no** `investigation_result`. A *later* ADR ([ADR-0006 / #52](https://github.com/rag-fish/RAGfish/issues/52))
  *may* decide to **host** NOEMA-layer work as a constrained task inside `noema-agent`. Even
  then, the NOEMA capability *ceiling* (rows 1, 3–13) is unchanged — hosting does not grant
  capability. **This contract does not make that decision.**
- **`[n3]`** *Human / write investigation state — NO.* Human noesis **governs** whether an
  investigation runs, re-runs, or halts; it does **not** hand-edit `investigation state` or
  `investigation_result` as a data operation. Those are NOESIS-owned (row 3 / NOESIS = YES).
  The human's lever is *governance*, not *mutation*.
- **`[n4]`** *Human / produce epistemic assessment — NO.* Human noesis forms **judgment** and
  **governs**. The *calibrated-assessment artifact* (bounded state + calibrated confidence +
  uncertainty) is the **NOESIS layer's advisory output** (I11). The human consumes it, accepts
  or rejects it, and decides — the human does not "produce" the artifact. This row is the
  crisp statement of **"NOESIS assesses; human noesis governs."**
- **`[n5]`** *Human Gate / authorize external acquisition — COND.* The Gate is the
  **checkpoint** through which a **human** authorizes. It holds **no authority of its own**;
  the `approved_by` in the record is always a human identity (`HUM`; row 6 / Human = YES). Read
  this cell as "carries a human's authorization," never "authorizes."
- **`[n6]`** *Human / execute external acquisition — COND.* A human may acquire external
  material **manually and out of band** (e.g. paste a document into their corpus, which then
  enters as ordinary ingested evidence). The **automated** acquisition path is **not** the
  human's — it is the External Acquisition layer's, gated by row 6.
- **`[n7]`** *External Acquisition executor & its credentials — UNRESOLVED.* **Where** approved
  acquisition executes, and therefore which component holds external-API credentials, is
  **deferred to ADR-0005 / [H1-ADR-ACQ-LOCUS (#43)](https://github.com/rag-fish/RAGfish/issues/43)**.
  ADR-0004 names `noema-agent` only as a *candidate*. This contract does **not** decide it.
  Until ADR-0005 is accepted: `noema-agent` rows 7–8 are **COND — pending ADR-0005**, defaulting
  to **NO** in the absence of that decision.
- **`[n8]`** *Human / credential access — COND.* The human **operator** manages provider and
  evidence-store credentials **out of band**. Credentials are never injected into an AI layer
  that this matrix marks `CRED`-absent.
- **`[n9]`** *External Acquisition / evidence-store credentials — COND.* A **write path** for
  the approved acquired evidence only, within the approved scope — not a general read/write
  credential. The read side of the evidence store stays NOESIS-only (row 1).
- **`[n10]`** *External Acquisition / retrieval — N/A.* External Acquisition **fetches external
  sources**; that is not "retrieval" over the user-owned corpus. Corpus retrieval is row 10 /
  NOESIS = YES only.
- **`[n11]`** *Human / increase confidence during presentation — N/A.* "During presentation"
  is specifically the NOEMA narrative step; the human is not an actor inside it. The human's
  ability to override a stated confidence in their **own judgment** is row 12 / Human = YES.
- **`[n12]`** *Human / produce narrative — COND.* A human may of course write their own prose
  about the findings. The **system's** narrative-production capability is NOEMA-only (row 14 /
  NOEMA = YES).
- **`[n13]`** *noema-agent / route execution — COND.* `noema-agent` **forms** the Route
  Contract — it *declares* the proposed path with justification; it does **not** finalize
  routing without a human approval when the contract declares one required (ADR-0000 §2;
  ADR-0002 §4). Routing **authority** stays with the human (row 16 / Human = YES).
- **`[n14]`** *Mutate audit history — NO for every actor.* The audit chain is append-only and
  hash-chained (ADR-0003 Audit plane, G6). **No actor — human included — can rewrite history.**
  A missing or altered event invalidates the run.
- **`[n15]`** *Human / emit audit events — N/A.* Governed **human decisions** (Gate approvals,
  routing authorizations, overrides) are **recorded by the runtime** as audit events; the
  human is the *subject* of the event, not the emitter.

---

## 4. Enforcement-mechanism mapping (every governance-critical `NO` / `COND`)

| Restriction | Class | Mechanism(s) | Status | Owner |
|---|---|---|---|---|
| NOEMA cannot read raw evidence | b4 | `SCH` (no raw-evidence field in NOEMA input) + `BIND` (no evidence-store binding) + `CRED` + `CTX` | **N/I** | schema: [#34](https://github.com/rag-fish/RAGfish/issues/34); isolation: [H3-NOEMA-ISOLATION #49](https://github.com/rag-fish/RAGfish/issues/49) → [H3-IMPL-NOEMA-CONTEXT NN#133](https://github.com/rag-fish/NoesisNoema/issues/133); test: [H3-TEST-CAPABILITY-ISOLATION NN#135](https://github.com/rag-fish/NoesisNoema/issues/135), [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| NOEMA cannot perform retrieval | b4 | `BIND` (no retrieval binding) + `CTX` | **N/I** | H3-NOEMA-ISOLATION #49 → H3-IMPL-NOEMA-CONTEXT NN#133 |
| NOEMA cannot call external APIs | b4 | `EP` (no outbound network in NOEMA context) + `CRED` | **N/I** | H3-NOEMA-ISOLATION #49 → H3-IMPL-NOEMA-CONTEXT NN#133 |
| NOEMA cannot reach the evidence store | b4 | `CRED` (no evidence-store credential) + `BIND` | **N/I** | H3-NOEMA-ISOLATION #49 |
| NOEMA cannot introduce a new factual claim | (b) | `VAL` (claim-set diff vs `investigation_result`; unknown claim ID ⇒ reject) + `SCH` (stable claim IDs minted by NOESIS) | **N/I** | spec: [H3-OUTPUT-VALIDATION-SPEC #51](https://github.com/rag-fish/RAGfish/issues/51); impl: [H3-IMPL-OUTPUT-VALIDATOR NN#134](https://github.com/rag-fish/NoesisNoema/issues/134); test: [H3-TEST-OUTPUT-VALIDATOR-UNIT NN#136](https://github.com/rag-fish/NoesisNoema/issues/136), [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| NOEMA cannot increase confidence | (c) | `VAL` (confidence-ceiling check: NOEMA output confidence ≤ `investigation_result` confidence) + `SCH` (`investigation_result` confidence is a read-only ceiling) | **N/I** | H3-OUTPUT-VALIDATION-SPEC #51 → H3-IMPL-OUTPUT-VALIDATOR NN#134; [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| NOEMA cannot mutate investigation state | I6 | `CTX` (separate context, one-directional B2) + no state handle in NOEMA input `SCH` | **N/I** | H3-NOEMA-ISOLATION #49 |
| NOESIS cannot cross the corpus boundary / call external APIs | (a) | `CRED` (no external-API credential in NOESIS) + capability = *propose only* | **N/I** | [H2-NOESIS-CONTRACT #44](https://github.com/rag-fish/RAGfish/issues/44) → [H2-IMPL-NOESIS-RUNTIME NN#128](https://github.com/rag-fish/NoesisNoema/issues/128) |
| NOESIS cannot own a governance decision / routing authority / sovereign judgment | I11, I12 | `SCH` (NOESIS outputs are typed as *advisory artifacts*; no "decision" / "approval" / "route-final" field) + `DID` (defense-in-depth) | **N/I** | H2-NOESIS-CONTRACT #44; [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| NOESIS cannot own a Human Gate approval | (d) | `HUM` + `SCH` (`approved_by` accepts only a human identity type) | **N/I** | record: [H1-HUMANGATE-RECORD #41](https://github.com/rag-fish/RAGfish/issues/41); schema: [#34](https://github.com/rag-fish/RAGfish/issues/34); [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| External acquisition cannot run without a valid human approval | (a) | `HUM` + sealed gateway rejects any acquisition call lacking a scope-matched, human-owned approval record; fail-closed default | **N/I** | design: [H4-SEALED-GATEWAY #53](https://github.com/rag-fish/RAGfish/issues/53), [H4-APPROVAL-ENFORCEMENT #54](https://github.com/rag-fish/RAGfish/issues/54); impl: [H4-IMPL-HUMANGATE-ENFORCEMENT NN#137](https://github.com/rag-fish/NoesisNoema/issues/137); executor: **ADR-0005 #43**; test: [H4-TEST-FAILCLOSED-INTEGRATION (conditional)], [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| An AI actor identity cannot be represented as `approved_by` | (d) | `HUM` + `SCH/TYP` (identity type rejects agent/model/service) | **N/I** | H1-HUMANGATE-RECORD #41; #34; [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| Approval cannot be inferred from inaction / extended to a different acquisition | (d) | `SCH` (no implicit-approval state; scope is a required field; gateway matches request↔approval scope) | **N/I** | H1-HUMANGATE-RECORD #41; H4-SEALED-GATEWAY #53 |
| Re-analysis must recompute, not patch | I4, INV-7 | `TYP` (no downstream mutation API on `investigation_result`) + `AUD` (each re-analysis emits an event; the final result's hash is chained) | **N/I** | [H2-REANALYSIS-SEMANTICS #48](https://github.com/rag-fish/RAGfish/issues/48) → [H2-IMPL-RECOMPUTE NN#131](https://github.com/rag-fish/NoesisNoema/issues/131) |
| No actor can mutate audit history | ADR-0003 G6 | `AUD` (append-only, hash-chained; Ed25519-signed evidence packages) | **partially implemented** (pipeline side per ADR-0003) / **N/I** runtime side | [H5-AUDITCHAIN-EPISTEMIC #61](https://github.com/rag-fish/RAGfish/issues/61) → [H5-IMPL-AUDIT-EMISSION NN#138](https://github.com/rag-fish/NoesisNoema/issues/138); verify: [H5-TEST-AUDITCHAIN-VERIFY (pipeline#36)](https://github.com/rag-fish/noesisnoema-pipeline/issues/36) |
| B2 handoff is `investigation_result`-only, one direction, no back-channel | I5 | `CTX` + `SCH` (NOEMA's sole input field) | **N/I** | H3-NOEMA-ISOLATION #49 |
| `noema-agent` cannot finalize routing without human approval | ADR-0000 §2 | existing v2 posture + Route Contract declares approval requirement | **existing** (ADR-0002) — carried, extended in Phase 7 ([H7-ROUTE-CONTRACT-V1 #67](https://github.com/rag-fish/RAGfish/issues/67)) | — |

**`N/I` is expected and acceptable here.** Issue #33 is a *contract* (INV-8: contracts before
implementation). Every `N/I` names its owning task so the enforcement gap is tracked on
Project #16, not hidden. **No governance-critical restriction relies on prompt wording as a
sole control** — every one has a named architectural mechanism.

---

## 5. Cross-check against ADR-0004 §"Capability Restrictions"

ADR-0004's matrix is **12 rows × 4 columns** (Noesis / Human Gate / External Acquisition /
Noema). This matrix is **18 rows × 6 columns** — a strict superset that adds the `Human` and
`noema-agent` columns and splits several ADR-0004 rows for precision (authorize vs execute;
credential access vs API invocation; set vs raise-during-presentation confidence; read vs
produce `investigation_result`; mutate vs emit audit).

**Every cell shared with ADR-0004 is identical:**

| ADR-0004 row | This matrix | Noesis | Human Gate | Ext. Acq. | Noema | Match |
|---|---|---|---|---|---|---|
| Read raw evidence | row 1 | YES | COND (reviews proposal) | YES (produces) | NO | ✅ |
| Access evidence store | row 9 | YES | NO | COND (write path) | NO | ✅ |
| Invoke retrieval | row 10 | YES | NO | N/A | NO | ✅ |
| Invoke external APIs | rows 7–8 | NO (proposes) | NO | YES (scoped) | NO | ✅ |
| Cross corpus boundary (B1) | row 7 | NO (proposes) | COND (authorizes) | YES (if authorized) | NO | ✅ |
| Mutate investigation state | row 3 | YES (owns) | NO | NO (returns to NOESIS) | NO | ✅ |
| Introduce new factual claims | row 11 | YES (from evidence) | NO | NO | NO | ✅ |
| Set / raise confidence | rows 12–13 | YES (calibrated) | NO | NO | NO | ✅ |
| Own a human approval | row 6 | NO | COND (human only) | NO | NO | ✅ |
| Own a governance decision / routing / sovereign judgment | rows 15–16 | NO (advisory, I11) | COND (human only) | NO | NO | ✅ |
| Produce `investigation_result` | row 2 | YES (sole) | NO | NO | NO (consumer only) | ✅ |
| Produce user-facing narrative | row 14 | NO | NO | NO | YES (sole) | ✅ |

No contradiction between this matrix and ADR-0004, and none between this matrix and
[NOESIS-NOEMA-GOVERNANCE-CONTRACT.md](NOESIS-NOEMA-GOVERNANCE-CONTRACT.md) §4.

---

## 6. Validation

`rg` check from Issue #33:

```sh
rg -n "Noesis|Noema|Human Gate|evidence|external|capability|approval" docs/noema/governance
```
Expected: dense matches in both files.

Manual checks performed (results in [NOESIS-NOEMA-GOVERNANCE-CONTRACT.md](NOESIS-NOEMA-GOVERNANCE-CONTRACT.md) §11):

1. Cross-check ADR-0000 → ADR-0004 — **no contradiction**.
2. NOEMA never granted retrieval / raw-evidence / external-API / confidence-escalation /
   investigation-mutation — **rows 1, 3, 8, 10–13 all NO**, each with a mechanism.
3. NOESIS never granted sovereign governance authority or final approval ownership —
   **rows 6, 15, 16 all NO**; I11/I12 cited.
4. Human Gate does not affect ordinary local grounded queries — see contract §7; the Gate is
   only reachable from a NOESIS acquisition proposal; ADR-0003 zero-runtime-gate preserved
   (INV-9).
5. `noema-agent` not silently redefined — **column `noema-agent`**: NO / COND-with-ADR-pointer
   only; rows 2 & 14 explicitly `COND — ADR-0006`; rows 7–8 `COND — ADR-0005`; I9 / INV-5
   cited.
6. Every MUST NOT / CANNOT has a mechanism from §1's code set **or** an explicit `N/I` with a
   named owner (§4).
7. Matrix ↔ prose consistency, and matrix ⊇ ADR-0004 with all shared cells identical (§5).

**If a future change makes the matrix and the prose contract disagree, the more restrictive
cell stands and the discrepancy must be raised for architecture review — not resolved by
weakening the rule.**
