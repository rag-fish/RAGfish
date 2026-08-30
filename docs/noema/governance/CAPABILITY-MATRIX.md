# Noesis / Noema Capability Matrix

**Status:** Proposed
**Date:** 2026-08-29
**Deciders:** Human governance owner · Architecture reviewer
**Architectural basis:** [ADR-0004: Noesis / Noema Epistemic Separation](../adr/ADR-0004-noesis-noema-epistemic-separation.md)
**Prose contract:** [NOESIS-NOEMA-GOVERNANCE-CONTRACT.md](NOESIS-NOEMA-GOVERNANCE-CONTRACT.md)
**Issue:** [rag-fish/RAGfish#33](https://github.com/rag-fish/RAGfish/issues/33)

Operationalises [NOESIS-NOEMA-GOVERNANCE-CONTRACT.md](NOESIS-NOEMA-GOVERNANCE-CONTRACT.md)
§4. A strict **superset** of ADR-0004 §"Capability Restrictions" (§4 here confirms every
shared cell is identical). Where this matrix and the prose contract could differ, **the more
restrictive reading stands** and the discrepancy is raised for review — never resolved by
weakening the rule.

---

## 1. Legend

**State:** `YES` may and can · `NO` **cannot** — capability architecturally absent (not
merely discouraged); governance-critical `NO` cells carry a mechanism · `COND` allowed only
under a stated precondition (see row note) · `N/A` not part of this operation's flow.

**Mechanism codes** (contract §3): `CRED` `EP` `CTX` `BIND` `SCH` `TYP` `VAL` `POL` `AUD`
`HUM` `DID` (never a sole control) `N/I` (not yet implemented — owned by a downstream task).

**Governance-critical classes** (ADR-0004 §2): `(a)` cross an external trust boundary
without human authorization · `(b)` introduce a factual claim no evidence supports · `(c)`
raise a stated confidence above what the investigation justified · `(d)` represent AI as the
owner of a human approval.

---

## 2. The matrix

`Human` = human noesis (the sovereign act of inquiry, judgment, and decision ownership —
ADR-0004 `I12`) plus the human operator. The other five are the ADR-0004 epistemic actors
plus the existing `noema-agent` execution service (`I9` — a *distinct* concept from epistemic
NOEMA).

| # | Capability | Human | NOESIS | Human Gate | External Acquisition | NOEMA | noema-agent |
|---|---|---|---|---|---|---|---|
| 1 | Read raw evidence | YES | **YES** (`I2`) | COND `[n1]` | YES (approved scope) | **NO** `CRED,BIND,SCH,CTX` (B4) | **NO** — not granted |
| 2 | Read `investigation_result` | YES (via artifacts) | YES (produces it) | N/A | N/A | **YES** (sole consumer, `I5`) | COND `[n2]` |
| 3 | Write / update investigation state | **NO** `[n3]` | **YES** (sole owner, `I4`) | **NO** | **NO** — returns evidence; Noesis recomputes (`I4`, `INV-7`) | **NO** `CTX,SCH` (`I6`) | **NO** (stateless) |
| 4 | Produce epistemic assessment (calibrated, advisory) | **NO** `[n4]` | **YES** (sole producer; advisory, `I11`) | **NO** | **NO** | **NO** (`I6`) | **NO** |
| 5 | Propose additional evidence acquisition | YES | **YES** (proposal only, `I3`) | **NO** (receives it) | **NO** (executes, ≠ originates) | **NO** (`I6`) | **NO** |
| 6 | Authorize external acquisition | **YES** (sole authorizing identity) `HUM` `(d)` | **NO** (proposes only, `I3`) | COND `[n5]` | **NO** | **NO** | **NO** |
| 7 | Execute external acquisition | COND `[n6]` | **NO** (`I3`) | **NO** (authorizes, ≠ executes) | **YES** — approved scope only, after a valid Human Gate approval (`I3`) `(a)` | **NO** `EP,CRED` (`I6`) | **COND — UNRESOLVED, ADR-0005** `[n7]` |
| 8 | Access external-API credentials | COND `[n8]` | **NO** `CRED` | **NO** `CRED` | YES (approved scope; out-of-band) | **NO** `CRED,EP` (B4) | **COND — ADR-0005** `[n7]` |
| 9 | Access evidence-store credentials | COND `[n8]` | **YES** (reads the corpus, `I2`) | **NO** `CRED` | COND — write path for approved evidence `[n9]` | **NO** `CRED` (B4) | **NO** — not granted |
| 10 | Perform retrieval (over user-owned corpus) | YES (app surface) | **YES** (corpus only, `I2`) | **NO** `BIND` | N/A `[n10]` | **NO** `BIND` (B4) | **NO** (not a retrieval layer) |
| 11 | Introduce new factual claims | YES — recorded as independent human judgment, not an edit to `investigation_result` `[n16]` | **YES** (from evidence; stable claim ID) | **NO** | **NO** (returns evidence, ≠ asserts) | **NO** `VAL,SCH` `(b)` | **NO** |
| 12 | Modify claim confidence (in investigation state / `investigation_result`) | **NO** `[n16]` | **YES** (sole calibrator / sole setter; set once over all evidence) | **NO** | **NO** (triggers recompute; Noesis re-sets) | **NO** `VAL` `(c)` | **NO** |
| 13 | Increase confidence during presentation | N/A `[n11]` | N/A (does not present) | N/A | N/A | **NO** `VAL` — ceiling = `investigation_result` value `(c)` | N/A |
| 14 | Produce narrative / presentation | COND `[n12]` | **NO** (produces `investigation_result`, ≠ narrative) | **NO** | **NO** | **YES** (sole producer, `I6`) | **COND — ADR-0006** `[n2]` |
| 15 | Approve governance decision | **YES** (sovereign — `I11`, `I12`) `HUM` | **NO** (advisory only, `I11`) | **NO** (checkpoint, ≠ authority) | **NO** | **NO** | **NO** ("execute, not decide") |
| 16 | Route execution | **YES** (routing authority stays with the human — ADR-0000 §2) | **NO** (may propose acquisition; does not route, `I11`) | **NO** | **NO** | **NO** | **COND** — *forms* the Route Contract (declares, ≠ finalizes); no finalization without human approval `[n13]` |
| 17 | Mutate audit history | **NO** `AUD` | **NO** `AUD` | **NO** `AUD` | **NO** `AUD` | **NO** `AUD` | **NO** `AUD` `[n14]` |
| 18 | Emit audit events | N/A `[n15]` | **YES** (every governed action — G6) | **YES** (approve/decline) | **YES** (per acquisition) | **YES** (per output validation) | **YES** (per execution) |

**The two cells most likely to be eroded under iteration pressure** (ADR-0004 calls these
out): **NOEMA has no evidence-acquisition capability of any kind** — no retrieval, no
evidence store, no external API, no corpus-boundary crossing (rows 1, 8–10) — and **NOEMA
cannot raise confidence** (rows 12–13); it carries the Noesis calibrated confidence and
uncertainty through unchanged.

---

## 3. Row notes (deltas only)

- `[n1]` **Human Gate / read raw evidence.** Reviews the Noesis acquisition **proposal** and its supplied context; no evidence-store binding or credential.
- `[n2]` **noema-agent / read `investigation_result` & produce narrative — COND, ADR-0006.** Today epistemic NOEMA ≠ `noema-agent` (`I9`): `noema-agent` does no narrative and reads no `investigation_result`. [ADR-0006 / #52](https://github.com/rag-fish/RAGfish/issues/52) *may* decide to **host** NOEMA-layer work inside it — the NOEMA capability ceiling (rows 1, 3–13) is unchanged either way; hosting does not grant capability.
- `[n3]` **Human / write investigation state.** Human noesis **governs** whether an investigation runs, re-runs, or halts; it does **not** hand-edit investigation state as a data operation (row 3 / NOESIS = YES).
- `[n4]` **Human / produce epistemic assessment.** Human noesis forms **judgment** and **governs**; the calibrated-assessment *artifact* is the NOESIS layer's advisory output (`I11`). The crisp statement of *NOESIS assesses; human noesis governs*.
- `[n5]` **Human Gate / authorize external acquisition — COND.** The Gate is the **checkpoint** through which a **human** authorizes; the `approved_by` in the record is always a human identity (`HUM`; row 6 / Human = YES). Read as "carries a human's authorization," never "authorizes."
- `[n6]` **Human / execute external acquisition — COND.** A human may acquire material **manually and out of band** (e.g. add a document to their corpus, which enters as ordinary ingested evidence). The **automated** acquisition path is the External Acquisition layer's, gated by row 6.
- `[n7]` **External Acquisition executor & its credentials — UNRESOLVED.** Where approved acquisition executes, and which component holds external-API credentials, is deferred to [ADR-0005 / #43](https://github.com/rag-fish/RAGfish/issues/43). ADR-0004 names `noema-agent` only as a *candidate*. Until that decision, `noema-agent` rows 7–8 default to **NO**.
- `[n8]` **Human / credential access — COND.** The operator manages provider and evidence-store credentials **out of band**; they are never injected into an AI layer marked `CRED`-absent.
- `[n9]` **External Acquisition / evidence-store credentials — COND.** A **write path** for the approved acquired evidence only, within scope — not a general credential. The read side stays NOESIS-only (row 1).
- `[n10]` **External Acquisition / retrieval — N/A.** It **fetches external sources**; that is not "retrieval" over the user-owned corpus (row 10 / NOESIS = YES only).
- `[n11]` **Human / increase confidence during presentation — N/A.** "During presentation" is the NOEMA narrative step; the human is not an actor inside it. A human may record an independent judgment that differs from the Noesis confidence — this does not mutate the assessment artifact; see `[n16]`.
- `[n12]` **Human / produce narrative — COND.** A human may write their own prose; the **system's** narrative capability is NOEMA-only (row 14).
- `[n13]` **noema-agent / route execution — COND.** `noema-agent` **forms** the Route Contract — *declares* the proposed path with justification; it does **not** finalize routing without a human approval when one is declared required (ADR-0000 §2; ADR-0002 §4). Routing **authority** stays with the human (row 16 / Human = YES).
- `[n14]` **Mutate audit history — NO for every actor, the human included.** The audit chain is append-only and hash-chained (ADR-0003 Audit plane, G6). A missing or altered event invalidates the run.
- `[n15]` **Human / emit audit events — N/A.** Governed **human decisions** (Gate approvals, routing authorizations, overrides) are **recorded by the runtime**; the human is the *subject* of the event, not the emitter.
- `[n16]` **Human / modify claim confidence — NO.** The Noesis-calibrated confidence and assessment states, once written into investigation state / `investigation_result`, are **not** editable by any actor — the human included. A human may **express, record, or act on** an independent human judgment, **including disagreement with the Noesis confidence**, but this is recorded as the human's own judgment and does **not** mutate the Noesis-calibrated assessment artifact. **Core distinction: a human may disagree with the assessment; a human does not rewrite the assessment.** Noesis remains the sole owner and sole setter of the calibrated assessment state (row 3, row 12 / NOESIS = YES; contract §4.2).

---

## 4. Cross-check against ADR-0004 §"Capability Restrictions"

ADR-0004's matrix is 12×4 (Noesis / Human Gate / External Acquisition / Noema). This one is
18×6 — adds the `Human` and `noema-agent` columns and splits several rows for precision
(authorize vs execute; credential access vs API invocation; set vs raise-during-presentation
confidence; read vs produce `investigation_result`; mutate vs emit audit). **Every shared
cell is identical:**

| ADR-0004 row | here | Noesis | Human Gate | Ext. Acq. | Noema |
|---|---|---|---|---|---|
| Read raw evidence | 1 | YES | COND (reviews proposal) | YES (produces) | NO |
| Access evidence store | 9 | YES | NO | COND (write path) | NO |
| Invoke retrieval | 10 | YES | NO | N/A | NO |
| Invoke external APIs | 7–8 | NO (proposes) | NO | YES (scoped) | NO |
| Cross corpus boundary (B1) | 7 | NO (proposes) | COND (authorizes) | YES (if authorized) | NO |
| Mutate investigation state | 3 | YES (owns) | NO | NO (returns to Noesis) | NO |
| Introduce new factual claims | 11 | YES (from evidence) | NO | NO | NO |
| Set / raise confidence | 12–13 | YES (calibrated) | NO | NO | NO |
| Own a human approval | 6 | NO | COND (human only) | NO | NO |
| Own a governance decision / routing / sovereign judgment | 15–16 | NO (advisory, `I11`) | COND (human only) | NO | NO |
| Produce `investigation_result` | 2 | YES (sole) | NO | NO | NO (consumer only) |
| Produce user-facing narrative | 14 | NO | NO | NO | YES (sole) |

No contradiction with ADR-0004 or with [NOESIS-NOEMA-GOVERNANCE-CONTRACT.md](NOESIS-NOEMA-GOVERNANCE-CONTRACT.md) §4.

---

## 5. Enforcement-mechanism mapping

Every governance-critical `NO` / `COND`, its mechanism, status, and owning task.

| Restriction | Class | Mechanism(s) | Status | Owner |
|---|---|---|---|---|
| NOEMA cannot read raw evidence | B4 | `SCH` + `BIND` + `CRED` + `CTX` | `N/I` | schema [#34](https://github.com/rag-fish/RAGfish/issues/34); isolation [#49](https://github.com/rag-fish/RAGfish/issues/49) → [NN#133](https://github.com/rag-fish/NoesisNoema/issues/133); test [NN#135](https://github.com/rag-fish/NoesisNoema/issues/135), [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| NOEMA cannot perform retrieval | B4 | `BIND` + `CTX` | `N/I` | [#49](https://github.com/rag-fish/RAGfish/issues/49) → [NN#133](https://github.com/rag-fish/NoesisNoema/issues/133) |
| NOEMA cannot call external APIs / reach the evidence store | B4 | `EP` + `CRED` + `BIND` | `N/I` | [#49](https://github.com/rag-fish/RAGfish/issues/49) |
| NOEMA cannot introduce a new factual claim | `(b)` | `VAL` (claim-set diff vs `investigation_result`; unknown claim ID ⇒ reject) + `SCH` (stable Noesis-minted claim IDs) | `N/I` | spec [#51](https://github.com/rag-fish/RAGfish/issues/51); impl [NN#134](https://github.com/rag-fish/NoesisNoema/issues/134); test [NN#136](https://github.com/rag-fish/NoesisNoema/issues/136), [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| NOEMA cannot increase confidence | `(c)` | `VAL` (ceiling check: NOEMA confidence ≤ `investigation_result` confidence) + `SCH` (read-only ceiling) | `N/I` | [#51](https://github.com/rag-fish/RAGfish/issues/51) → [NN#134](https://github.com/rag-fish/NoesisNoema/issues/134); [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| NOEMA cannot mutate investigation state | `I6` | `CTX` (one-directional B2) + `SCH` (no state handle in input) | `N/I` | [#49](https://github.com/rag-fish/RAGfish/issues/49) |
| NOESIS cannot cross the corpus boundary / call external APIs | `(a)` | `CRED` (no external-API credential) + capability = *propose only* | `N/I` | [#44](https://github.com/rag-fish/RAGfish/issues/44) → [NN#128](https://github.com/rag-fish/NoesisNoema/issues/128) |
| NOESIS cannot own a governance decision / routing authority / sovereign judgment | `I11`, `I12` | `SCH` (outputs typed as *advisory*; no decision / approval / route-final field) + `DID` | `N/I` | [#44](https://github.com/rag-fish/RAGfish/issues/44); [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| No AI actor identity can be represented as `approved_by`; no inference from inaction; no cross-scope extension | `(d)` | `HUM` + `SCH`/`TYP` (identity type rejects agent/model/service; no implicit-approval state; scope is required and matched) | `N/I` | record [#41](https://github.com/rag-fish/RAGfish/issues/41); schema [#34](https://github.com/rag-fish/RAGfish/issues/34); [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| External acquisition cannot run without a valid, scope-matched, human-owned approval | `(a)` | `HUM` + sealed gateway fails closed | `N/I` | design [#53](https://github.com/rag-fish/RAGfish/issues/53), [#54](https://github.com/rag-fish/RAGfish/issues/54); impl [NN#137](https://github.com/rag-fish/NoesisNoema/issues/137); executor **ADR-0005 [#43](https://github.com/rag-fish/RAGfish/issues/43)**; [#35](https://github.com/rag-fish/RAGfish/issues/35) |
| Re-analysis must recompute, not patch | `I4`, `INV-7` | `TYP` (no downstream mutation API on `investigation_result`) + `AUD` (per-re-analysis event; final hash chained) | `N/I` | [#48](https://github.com/rag-fish/RAGfish/issues/48) → [NN#131](https://github.com/rag-fish/NoesisNoema/issues/131) |
| No actor can mutate audit history | ADR-0003 G6 | `AUD` (append-only, hash-chained; signed evidence packages per ADR-0003 §"Audit storage") | pipeline side implemented (ADR-0003) / `N/I` runtime side | [#61](https://github.com/rag-fish/RAGfish/issues/61) → [NN#138](https://github.com/rag-fish/NoesisNoema/issues/138); verify [pipeline#36](https://github.com/rag-fish/noesisnoema-pipeline/issues/36) |
| B2 handoff is `investigation_result`-only, one direction, no back-channel | `I5` | `CTX` + `SCH` (NOEMA's sole input field) | `N/I` | [#49](https://github.com/rag-fish/RAGfish/issues/49) |
| `noema-agent` cannot finalize routing without human approval | ADR-0000 §2 | existing v2 posture; Route Contract declares the approval requirement | existing (ADR-0002); extended in Phase 7 [#67](https://github.com/rag-fish/RAGfish/issues/67) | — |

`N/I` is expected — Issue #33 is a contract (`INV-8`). No governance-critical restriction
relies on prompt wording as a sole control: every one has a named architectural mechanism.

---

## 6. Validation

`rg -n "Noesis|Noema|Human Gate|evidence|external|capability|approval" docs/noema/governance`
— expected: dense matches in both files.

Manual-check results are in [NOESIS-NOEMA-GOVERNANCE-CONTRACT.md](NOESIS-NOEMA-GOVERNANCE-CONTRACT.md)
§11. Specific to this matrix: §4 confirms it is a strict superset of ADR-0004's table with
every shared cell identical; all 18 rows have identical markdown column structure; every
governance-critical `NO`/`COND` cell has a §5 mechanism or an explicit `N/I` + owner.
