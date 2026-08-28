# ADR-0004: Noesis / Noema Epistemic Separation

**Status:** Proposed
**Date:** 2026-08-28
**Deciders:** Taka (governance owner, final reviewer, merge approver), Max / ChatGPT (architect / architecture review)
**Author:** Claude CLI
**Scope:** All four Noema repos — conceptual basis for the next Noema Architecture revision
**Relationship to prior ADRs:** Extends ADR-0001, ADR-0002, ADR-0003. Does not supersede them. Does not replace the four-plane model (Policy / Knowledge / Runtime / Audit) or the nine-stage governance pipeline.

---

## Context

ADR-0001 defined the physical four-repo architecture. ADR-0002 defined the nine-stage governance pipeline (Intent → Policy → Trust → Route Contract → Execution → Verification → Evidence → Human Approval → Decision Log). ADR-0003 (v0.8) made governance machine-enforced through a four-plane model (Policy / Knowledge / Runtime / Audit) and six governance rules (G1–G6), with the explicit design choice that ordinary queries pass **zero** runtime human gates — governance is achieved by *ex-ante policy* plus *ex-post verifiable audit*.

ADR-0000 (Product Constitution) fixed the foundational declaration:

> Noesis Noema is an intelligence layer in which human noesis governs and AI accompanies. The question originates from the human. AI runs alongside — never ahead, never above. Noema emerges under human sovereignty.

That declaration names two epistemic roles — **noesis** (the human-governed act of inquiry and judgment) and **Noema** (what emerges from it) — but the architecture has never formally defined them as layers with distinct responsibilities, trust boundaries, and capabilities.

The system is now moving toward work that involves **investigation**: decomposing a claim, synthesising evidence from multiple sources, holding competing hypotheses, assessing source dependency, and producing a calibrated judgment. Some of that work may, when a human explicitly approves it, involve acquiring *new external evidence* — crossing a trust boundary out of the local, user-owned corpus.

Investigation output must eventually be turned into readable narrative for the user. Today there is no architectural rule that separates *the entity that investigates and judges* from *the entity that writes the narrative*. Without that separation, a single model context holds both the investigative capability (retrieval, evidence access, the ability to reach out for more) and the presentation task. In that arrangement, the only thing stopping the presentation step from quietly acquiring more evidence, inventing a supporting claim, or nudging confidence upward is the model choosing not to. That is governance by prompt obedience, and ADR-0003 already rejected that posture for grounding (G1) and for policy/pack changes (Human Decision Gate).

This ADR closes that gap at the conceptual level. It does not design schemas, prompts, endpoints, credentials, or provider integrations — those belong to the follow-up issues (#33, #34, #35).

---

## Problem

1. **No formal epistemic lifecycle.** The architecture describes how a request is routed and executed, but not how *evidence becomes a calibrated judgment* and how that judgment *becomes narrative*. The steps, their order, and the gate between them are undefined.

2. **Investigation capability and presentation capability are not separated.** Nothing in the architecture says the component that writes the user-facing answer must be unable to retrieve, unable to reach the evidence store, and unable to call external APIs.

3. **Governance-critical restrictions rely on prompt compliance.** The current implicit model trusts an agent *not to* exceed its remit. For governance-critical boundaries — external trust-boundary crossing, factual-claim creation, confidence escalation — "won't" is not sufficient. The boundary must be "can't".

4. **Terminology collision.** The epistemic concept **Noema** (presentation / narrative transformation layer) collides with the existing repository and service **`noema-agent`** (the constrained, stateless Execution Layer defined in `docs/architect/noema-agent-v2.md`). If these are conflated, `noema-agent` could be silently redefined as "the Noema presentation layer", which is wrong and would weaken both definitions.

5. **No named handoff boundary.** There is no single, formal object that constitutes the Noesis → Noema handoff. Without one, the presentation layer's input surface is ambiguous, and "what Noema is allowed to see" cannot be enforced.

---

## Decision

### 1. Adopt a formal epistemic lifecycle

The Noema Architecture recognises the following epistemic lifecycle as an architectural invariant:

```
Evidence
   │
   ▼
NOESIS                     — investigation, decomposition, synthesis,
   │                         competing hypotheses, source-dependency
   │                         analysis, uncertainty, calibrated assessment,
   │                         and (optionally) a proposal for additional
   │                         evidence acquisition
   ▼
HUMAN GATE                 — a human explicitly authorizes (or declines)
   │                         any crossing of an external trust boundary
   ▼
External Evidence Acquisition   — occurs ONLY when explicitly approved
   │                              at the Human Gate
   ▼
NOESIS Re-analysis         — the newly acquired evidence re-enters Noesis;
   │                         assessment is recomputed, not appended
   ▼
investigation_result       — the sole formal Noesis → Noema handoff object
   │
   ▼
NOEMA                      — presentation / narrative transformation only
```

The lifecycle may iterate: Noesis → Human Gate → acquisition → Noesis re-analysis may repeat while a human keeps approving further acquisition. It terminates in Noesis producing an `investigation_result`. Noema is always downstream of `investigation_result` and never upstream of it.

### 2. Core architectural principle: "Can't rather than won't"

> Governance-critical restrictions must not rely only on prompt obedience.

A restriction is **governance-critical** when its violation would (a) cross an external trust boundary without human authorization, (b) introduce a factual claim that no evidence supports, (c) raise a stated confidence above what the investigation justified, or (d) represent AI as the owner of a human approval.

For every governance-critical restriction, the architecture must remove the *capability*, not merely instruct against its use. The enforcement mechanism is architecture — absent credentials, absent endpoints, absent code paths, absent fields, schema validation, type constraints, and separate execution contexts — not a system prompt. Prompt-level instruction is permitted as defense in depth, never as the sole control.

This principle is consistent with ADR-0003's "governance by capability, not supervision" and ADR-0000's constraints against execution-authority escalation and silent state mutation.

### 3. `investigation_result` is the sole Noesis → Noema handoff boundary

The Noesis → Noema handoff is a single, named object: `investigation_result`. Noema receives `investigation_result` and nothing else from the investigation side. Its detailed JSON Schema is **not** designed in this ADR — that is Issue #34. This ADR fixes only that (a) the boundary exists, (b) it is the only channel, and (c) it carries calibrated findings and approved recommendations, not raw evidence.

### 4. The epistemic **Noema** is distinct from the service **`noema-agent`**

| Term | Meaning |
|---|---|
| **Noema** (epistemic concept) | The presentation / narrative transformation layer defined in this ADR. Consumes `investigation_result`. Capability-restricted. |
| **`noema-agent`** (repository / service) | The constrained, stateless Execution Layer defined in `docs/architect/noema-agent-v2.md` and ADR-0002. "Exists to execute, not to decide." Unchanged by this ADR. |

`noema-agent` is **not** automatically redefined as the Noema presentation layer. It remains the Execution Layer. A future implementation *may* choose to run Noema-layer narrative transformation as one constrained task inside `noema-agent`, but that is an implementation decision for a later ADR and is out of scope here. Until such a decision is recorded, "Noema" in architecture text means the epistemic layer, and "`noema-agent`" means the execution service.

---

## Architectural Invariants

| # | Invariant |
|---|---|
| **I1** | Every investigation follows the epistemic lifecycle: Evidence → Noesis → (Human Gate → External Acquisition → Noesis re-analysis)\* → `investigation_result` → Noema. |
| **I2** | Noesis is the only layer that reads raw evidence, invokes retrieval, or performs calibrated assessment. |
| **I3** | Crossing an external trust boundary (acquiring evidence not already in the user-owned corpus) requires explicit, recorded human authorization at the Human Gate. Noesis may *propose* it; Noesis may not *perform* it unilaterally. |
| **I4** | External evidence acquisition, once approved, re-enters Noesis. The assessment is **recomputed** over the enlarged evidence set — it is not patched, appended to, or overridden downstream. |
| **I5** | `investigation_result` is the sole Noesis → Noema handoff. Noema has no other input channel from the investigation side. |
| **I6** | Noema performs presentation and narrative transformation only. It cannot read raw evidence, reach the evidence store, invoke retrieval, call external APIs, mutate investigation state, introduce new factual claims, or raise confidence above the Noesis result. |
| **I7** | Every governance-critical restriction (I3, I6, and human-approval ownership) is enforced by capability removal — "can't rather than won't" — not by prompt instruction alone. |
| **I8** | AI identity cannot own a Human Gate approval. Approval ownership is a human-only field. The system does not infer approval from inaction and does not extend a prior approval to a new acquisition. |
| **I9** | The epistemic **Noema** layer and the **`noema-agent`** service are distinct. Neither definition is silently substituted for the other. |
| **I10** | This lifecycle maps onto the existing four planes (ADR-0003) and nine-stage pipeline (ADR-0002). It adds an epistemic dimension; it does not replace Decision / Execution / Knowledge / Audit. |

`*` = may iterate zero or more times under repeated human authorization.

---

## Layer Responsibilities

### Evidence (input)

Raw material for investigation: retrieved chunks from the user-owned corpus (with provenance, per RAGpack v1.3 and G2), and — only after Human Gate approval — externally acquired sources. Evidence carries provenance and trust metadata computed at ingestion time (ADR-0002 Trust Evaluation; ADR-0003 Knowledge plane). Evidence is consumed by Noesis and by no other layer.

### NOESIS — investigation and calibrated judgment

Noesis is the investigative and epistemic-assessment layer. Its responsibilities:

- **Investigation** — pursuing the question the human posed; organising the inquiry.
- **Claim decomposition** — breaking a compound question or assertion into individually assessable claims.
- **Evidence synthesis** — assembling what the available evidence does and does not say about each claim.
- **Competing hypotheses** — maintaining more than one candidate explanation where the evidence does not force a single one; not collapsing to a single answer prematurely.
- **Source dependency analysis** — determining how many *independent* source chains support a claim. Multiple reports derived from one origin count as **one** independent chain, not several.
- **Uncertainty** — explicitly representing what is unknown, unresolved, or under-evidenced.
- **Calibrated assessment** — assigning a bounded assessment state (e.g. supported / partially supported / contradicted / unresolved / insufficient evidence — final enum is Issue #34) and a calibrated confidence that reflects evidence strength and independence, not model fluency. Trust remains separate from confidence (ADR-0002).
- **Proposal for additional evidence acquisition** — when the current evidence is insufficient, Noesis may produce a *proposal* to acquire specific additional external evidence. The proposal is an output to the Human Gate; it is not an acquisition and does not authorize one.

Noesis capabilities: reads raw evidence; invokes retrieval over the user-owned corpus; performs assessment; produces `investigation_result`. Noesis does **not** unilaterally cross external trust boundaries and does **not** own human approval.

### HUMAN GATE — external trust-boundary authorization

The Human Gate is the explicit governance checkpoint for crossing an external trust boundary. It is the only mechanism by which external evidence acquisition becomes permitted.

- **External trust-boundary crossing requires explicit human authorization.** "External" means any source not already in the user-owned corpus — external APIs, web retrieval, third-party services, provider tools.
- **AI identity cannot own approval.** The approver is a human. Approval ownership is a human-only field (Issue #33 / #34 encode the enforcement). The system does not represent an agent, model, or service as `approved_by`.
- **Approval is explicit, recorded, and scoped.** It authorizes a specific acquisition, not a standing capability. It is not inferred from inaction and is not extended to a later, different acquisition.
- **Declining is a valid outcome.** If the human declines, Noesis proceeds to `investigation_result` on the evidence it already has, with the corresponding uncertainty stated.

This gate is the investigation-time analogue of ADR-0003's Human Decision Gate for policy changes and pack promotion. It does not add a human gate to ordinary grounded queries — those still pass zero runtime human gates (ADR-0003). It applies specifically when investigation would reach outside the user-owned corpus.

### External Evidence Acquisition — only when explicitly approved

Acquisition of new external evidence occurs only after Human Gate approval, and only within the scope that approval granted. Acquired evidence is captured with provenance and returned into Noesis. Acquisition is never performed by Noema and never performed by Noesis without a recorded approval. Provider-specific acquisition design (endpoints, credentials, API shape) is out of scope for this ADR.

### NOESIS Re-analysis — recompute, do not append

Newly acquired evidence re-enters Noesis. Noesis recomputes claim decomposition, synthesis, hypotheses, source-dependency counts, uncertainty, and calibrated assessment over the enlarged evidence set. The prior assessment is superseded, not edited in place downstream. This guarantees that the final `investigation_result` is a single coherent judgment over all evidence, not a base judgment with patches.

### investigation_result — the handoff object

`investigation_result` is the sole formal Noesis → Noema handoff boundary. It carries:

- decomposed claims and their calibrated assessment states,
- calibrated confidence and explicit uncertainty,
- an evidence-chain **summary** (including independent-source-chain counts) — **not** raw evidence objects,
- recommendations, including which were human-approved,
- the human-approval record for any external acquisition that occurred.

It does **not** carry raw evidence content, evidence-store handles, retrieval capability, or acquisition capability. Its detailed schema, field list, invariants, and example payloads are **Issue #34** and are explicitly not designed here.

### NOEMA — presentation / narrative transformation only

Noema transforms `investigation_result` into user-facing narrative. That is its entire remit.

Noema **cannot**:

- access raw evidence,
- access the evidence store,
- access retrieval,
- invoke external APIs,
- mutate investigation state,
- introduce new factual claims,
- raise confidence beyond the Noesis result.

Noema **may**: reorder, summarise, explain, and format the findings already present in `investigation_result`; carry through the assessment states, confidence, and uncertainty exactly as received; present competing hypotheses that Noesis recorded; and surface the stated limitations.

If narrative generation appears to require a fact not in `investigation_result`, the correct outcome is that Noema states the limitation — not that Noema acquires the fact. Needing more evidence is a signal to return to Noesis (via a new human-initiated request), never a licence for Noema to retrieve.

---

## Trust Boundaries

| Boundary | Between | Crossing rule |
|---|---|---|
| **B1 — Corpus boundary** | User-owned corpus ↔ external sources | Crossed only by External Evidence Acquisition, only after Human Gate approval (I3). |
| **B2 — Epistemic handoff boundary** | Noesis ↔ Noema | Crossed only by `investigation_result` (I5). One direction: Noesis → Noema. No back-channel. |
| **B3 — Approval-authority boundary** | AI identity ↔ human approval | AI cannot cross into approval ownership (I8). |
| **B4 — Evidence-access boundary** | Raw evidence / evidence store / retrieval ↔ Noema | Noema is on the outside and has no capability to cross (I6). |

The boundaries are enforced structurally: Noema runs without evidence-store credentials, without retrieval bindings, without outbound network capability to provider APIs, and with an input surface that is `investigation_result` only. This is the "can't rather than won't" principle applied to B2 and B4.

---

## Capability Restrictions

Capability posture by layer. "No" means the capability is architecturally absent, not merely discouraged. (The full enforcement-mechanism mapping — policy / schema / type-system / credential / endpoint / test — is **Issue #33**.)

| Capability | Noesis | Human Gate | External Acquisition | Noema |
|---|---|---|---|---|
| Read raw evidence | Yes | — (reviews proposal) | Produces evidence | **No** |
| Access evidence store | Yes | No | Writes acquired evidence in | **No** |
| Invoke retrieval | Yes | No | N/A | **No** |
| Invoke external APIs | **No** (proposes only) | No | Yes, within approved scope | **No** |
| Cross corpus boundary (B1) | **No** (proposes only) | Authorizes | Yes, if authorized | **No** |
| Mutate investigation state | Yes (owns it) | No | Returns evidence to Noesis | **No** |
| Introduce new factual claims | Yes (from evidence) | No | No | **No** |
| Set / raise confidence | Yes (calibrated) | No | No | **No** (carries through only) |
| Own a human approval | **No** | Human only | No | **No** |
| Produce `investigation_result` | Yes (sole producer) | No | No | **No** (consumer only) |
| Produce user-facing narrative | No | No | No | Yes (sole producer) |

Two restrictions to call out explicitly, because they are the ones most likely to be eroded under iteration pressure:

1. **Noema has no evidence-acquisition capability of any kind** — no retrieval, no evidence store, no external API, no corpus-boundary crossing. Every cell in the Noema column for those rows is "No", by architecture.
2. **Noema cannot raise confidence.** It carries the Noesis calibrated confidence and uncertainty through unchanged. It has no path to compute or assert a higher one.

---

## Relationship to Existing Architecture

This ADR adds an **epistemic dimension**. It does not replace the Decision / Execution / Knowledge / Audit planes (ADR-0003) or the nine-stage pipeline (ADR-0002).

### Mapping onto the four planes (ADR-0003)

| Plane | Owner | How the epistemic lifecycle uses it |
|---|---|---|
| **Policy** | Human (`noema-policy.yaml`) | Declares when investigation may propose external acquisition, what the Human Gate requires, and the calibration thresholds. The Human Gate is a policy-declared checkpoint. |
| **Knowledge** | Pipeline (RAGpack v1.3) | Supplies Evidence with provenance and trust metadata. Externally acquired evidence must be captured with comparable provenance. |
| **Runtime** | NoesisNoema (pure Swift) | Hosts Noesis (retrieval, assessment) and Noema (narrative) as **separate capability contexts**. Enforces I6 by construction. G1 (grounding) and G5 (budget) still apply. |
| **Audit** | Both (hash-chained JSONL) | Records the Noesis assessment, the Human Gate approval/decline, each acquisition, each re-analysis, and the `investigation_result` handoff. G6 (audit completeness) applies to every step. |

### Mapping onto the nine-stage pipeline (ADR-0002)

- **Intent** — the human's question originates the investigation (unchanged; ADR-0000).
- **Policy Evaluation** — gates whether investigation and acquisition proposals are permitted in this context.
- **Trust Evaluation** — feeds Noesis; trust stays separate from the confidence Noesis calibrates.
- **Route Contract** — declares whether a request is an investigation, and whether external acquisition is in scope pending the Human Gate.
- **Execution** — Noesis assessment and Noema narrative are execution work under the contract. Neither owns routing authority.
- **Verification** — checks that `investigation_result` invariants hold and that the narrative did not add claims or raise confidence (regression cases: Issue #35).
- **Evidence** — `investigation_result`, the Human Gate record, and the audit chain are evidence artifacts.
- **Human Approval** — the Human Gate is the investigation-time instance of this stage; it does not add approval to ordinary grounded queries.
- **Decision Log** — the investigation and its approvals are reconstructable from the audit chain and linked artifacts.

### Mapping onto governance rules G1–G6 (ADR-0003)

| Rule | Interaction with this ADR |
|---|---|
| G1 — no ungrounded generation | Noema narrative inherits grounding from `investigation_result`; it cannot generate ungrounded claims because it cannot introduce claims. |
| G2 — version pinning | `investigation_result` and narrative record the `(embedder_id, model_id, manifest_sha256)` triplet. |
| G3 — promotion gate | Unchanged; corpus evidence still comes from promoted packs. |
| G4 — change control | This ADR is the change-control artifact for the epistemic separation. |
| G5 — budget enforcement | Applies to Noesis and Noema execution. |
| G6 — audit completeness | Every lifecycle step (assessment, gate, acquisition, re-analysis, handoff) emits an audit event; a missing event invalidates the run. |

### Consistency with ADR-0000 (Human Sovereignty)

- Explicit Invocation Only → investigation starts from a human question; acquisition starts from a human approval.
- Routing Authority → Noesis proposes acquisition; the human authorizes it.
- Execution Transparency → every step is audited (G6).
- Human Override Authority → declining at the Human Gate is always available.
- State Mutation Consent → only Noesis mutates investigation state, within one invocation; Noema mutates nothing.

### Consistency with `noema-agent` v2

`noema-agent` remains the constrained, stateless Execution Layer — "exists to execute, not to decide." This ADR does not give it intent, memory, or decision authority, and does not rename it. The epistemic **Noema** layer is a separate concept (I9).

---

## Repository Responsibility Mapping

No repository boundary from ADR-0001 changes. This ADR assigns the epistemic layers to existing repos:

| Epistemic element | Primary repo | Notes |
|---|---|---|
| Epistemic lifecycle definition, invariants (this ADR) | `rag-fish/RAGfish` | Architecture Hub. ADRs live here. |
| Governance contract + capability matrix (Issue #33) | `rag-fish/RAGfish` | `docs/noema/governance/` |
| `investigation_result` contract + JSON Schema (Issue #34) | `rag-fish/RAGfish` | `docs/noema/schemas/` (or agreed path) |
| Governance regression case specification (Issue #35) | `rag-fish/RAGfish` | `docs/noema/tests/` (or agreed path) |
| Evidence provenance / trust metadata | `rag-fish/noesisnoema-pipeline` | Knowledge plane; RAGpack v1.3; unchanged |
| Noesis runtime (retrieval, assessment) | `rag-fish/NoesisNoema` | Runtime plane; pure Swift; capability context that *has* retrieval + evidence access |
| Noema runtime (narrative transformation) | `rag-fish/NoesisNoema` | Runtime plane; pure Swift; **separate** capability context with no retrieval, no evidence store, no outbound API |
| Human Gate (approval capture + record) | `rag-fish/NoesisNoema` (surface) + `rag-fish/RAGfish` (schema of the record) | Human-only approval field |
| External evidence acquisition (execution) | `rag-fish/noema-agent` (candidate) | Constrained execution service; acquisition would be an explicit, approved, scoped task. **Design deferred** — not decided by this ADR. |
| Audit chain of the epistemic lifecycle | `rag-fish/noesisnoema-pipeline` + `rag-fish/NoesisNoema` | Audit plane; hash-chained JSONL; G6 |
| Policy declaring gate + calibration thresholds | `rag-fish/RAGfish` (`noema-policy.yaml` schema) | Policy plane |

---

## Consequences

### Positive

- **Governance-critical boundaries become structural.** External acquisition, claim creation, and confidence escalation are prevented by absent capability, not by trusting a prompt.
- **The narrative layer cannot leak or fabricate.** Noema physically has no evidence store, no retrieval, and no outbound API, so a compromised or misaligned narrative step cannot exfiltrate evidence or reach outside the corpus.
- **Confidence integrity.** A single calibrated confidence, set once by Noesis over all evidence, flows to the user unmodified.
- **Human authority at the exact boundary that matters.** The Human Gate sits precisely where trust changes — leaving the user-owned corpus — and nowhere that would add friction to ordinary grounded queries.
- **Terminology is unambiguous.** "Noema" (epistemic layer) and "`noema-agent`" (execution service) are formally separated; neither can be silently substituted for the other.
- **Clean handoff for downstream work.** `investigation_result` gives #33, #34, #35 a single, named object to constrain and test.
- **Consistent with the existing architecture.** The four planes, nine stages, G1–G6, and ADR-0000 all still hold; this is an added dimension, not a rewrite.

### Negative / Trade-offs

- **Two runtime capability contexts instead of one.** Noesis and Noema must be separated in implementation (separate credentials/bindings, possibly separate processes). That is more engineering than a single agent context. This cost is the point — it is what makes I6 "can't" rather than "won't".
- **`investigation_result` becomes a hard contract.** Once defined (#34), changing it is change-controlled. Under-specifying it early would force rework; over-specifying it here would pre-empt #34. This ADR deliberately stops at "the boundary exists".
- **Iteration friction for investigations needing external evidence.** Each external acquisition needs an explicit human approval, and re-analysis recomputes rather than patches. This is slower than letting an agent fetch freely — deliberately.
- **The `noema-agent`-as-acquisition-executor question is left open.** This ADR names it as a candidate but does not decide it, so a future ADR is required before that path is built.
- **Verification surface grows.** "Narrative added no claim / raised no confidence" is a new class of check that must be built (#35).

### Neutral

- No code changes result from this ADR. It is a conceptual decision record. Runtime implementation follows in downstream issues and repos.

---

## Rejected Alternatives

### A. Single investigative-and-presentational agent, governed by prompt

One model context does investigation, evidence access, external acquisition, and narrative, restrained by a system prompt that tells it not to exceed scope.

**Rejected.** This is governance by obedience. It violates the core principle of this ADR and is inconsistent with ADR-0003, which already rejected prompt-only enforcement for grounding. A prompt cannot prevent a capable model with live credentials from acquiring evidence or asserting a claim.

### B. Noema retrieval allowed for "presentation gap-filling"

Let Noema perform limited retrieval when the narrative needs a supporting detail not in `investigation_result`.

**Rejected.** Any retrieval capability in Noema means Noema can introduce evidence Noesis never assessed, which breaks calibrated assessment (the confidence would no longer cover all evidence used) and breaks the audit chain's ordering. The correct response to a presentation gap is for Noema to state the limitation and for a human to start a new investigation request.

### C. Human Gate on every grounded query

Require human approval for all retrieval, not just external-boundary crossing.

**Rejected.** ADR-0003 established that ordinary grounded queries pass zero runtime human gates; this is the condition under which an on-device assistant is usable. The Human Gate in this ADR is scoped to the *external trust boundary* only — retrieval within the user-owned corpus is not gated.

### D. Redefine `noema-agent` as the Noema presentation layer

Adopt the name collision and make `noema-agent` the presentation layer.

**Rejected.** `noema-agent` is the constrained Execution Layer with a locked definition ("exists to execute, not to decide"). Overloading it would confuse two distinct roles and risk importing execution capability (tool calls, remote execution) into the presentation layer, which must have none. The layers stay separate (I9). A later ADR may decide to *host* Noema-layer work inside `noema-agent` as a constrained task, but that is a separate, explicit decision.

### E. `verified: boolean` truth field on the handoff

Represent each claim as verified true/false in `investigation_result`.

**Rejected** (and pre-empting #34). A binary truth flag destroys calibration and hides uncertainty and source dependency. The handoff must use bounded assessment states plus explicit uncertainty. (Final enum is #34.)

### F. Defer the whole epistemic separation until schemas are ready

Do nothing until `investigation_result` and the capability matrix are designed.

**Rejected.** The schema and matrix work (#33, #34, #35) all declare a dependency on a stable architectural basis. Without ADR-0004 they would be building to an unspecified interface — exactly the failure the Hermes execution order is designed to prevent.

---

## Follow-up Work

| Issue | Title | Depends on | What it adds |
|---|---|---|---|
| **#33** | Docs: define governance contract and capability matrix | #32 | Turns the capability restrictions in this ADR into explicit, reviewable rules and a full capability matrix, each control mapped to an enforcement mechanism (policy / schema / type-system / credential / endpoint / test). Defines human-only fields such as approval ownership. Path: `docs/noema/governance/`. |
| **#34** | Feature: define `investigation_result` contract v0.1 | #32, #33 | Designs the `investigation_result` JSON Schema and contract docs: bounded assessment-state enum (no `verified: boolean`), calibrated confidence + uncertainty fields, independent-source-chain counts without raw evidence, fields Noema may reference vs. fields intentionally absent, downstream invariants (Noema cannot raise confidence or mint claim IDs), example valid/invalid payloads. |
| **#35** | Test: define Noesis/Noema governance regression cases | #32, #33, #34 | Adversarial / regression cases proving the boundary fails closed: Noema new-claim rejection, confidence-escalation rejection, external-acquisition-attempt rejection, source-dependency counting (many reports from one origin = one chain), AI identity in `approved_by` rejection, external acquisition without human approval rejection. Distinguishes prompt-level refusal from architectural inability. |

Not tracked by a numbered issue yet, and explicitly deferred by this ADR:

- Whether external evidence acquisition executes inside `noema-agent` or elsewhere (requires its own ADR).
- Provider-specific acquisition API design (e.g. Grok integration).
- Runtime prompts for Noesis and Noema.
- The evidence-store schema and the external-acquisition request schema.

---

## Out of Scope

Consistent with Issue #32:

- Code changes; runtime implementation.
- Grok integration; any provider-specific API design.
- Detailed `investigation_result` JSON Schema (that is #34).
- Prompts for runtime agents.
- Changes to `NoesisNoema`, `noema-agent`, or `noesisnoema-pipeline` code.
- Production release / version tagging.
- Redesign of the existing four-plane model or nine-stage pipeline.

---

## Validation Performed

**Consistency check against ADR-0001 → ADR-0003:**

- ADR-0001 (four repos) — no repo boundary changed; epistemic layers mapped onto existing repos (§ Repository Responsibility Mapping). Local-only default path preserved; no new server dependency introduced (external acquisition is human-gated and optional).
- ADR-0002 (nine-stage pipeline) — epistemic lifecycle mapped onto all nine stages (§ Relationship to Existing Architecture). Trust-vs-confidence separation preserved. Human Approval stage not added to routine inference. Route Contract still declared before execution.
- ADR-0003 (four planes, G1–G6, zero runtime human gates for ordinary queries) — lifecycle mapped onto all four planes and all six rules. The Human Gate is scoped to the external trust boundary only, consistent with ADR-0003's "ordinary queries pass zero human gates". "Can't rather than won't" is consistent with ADR-0003's "governance by capability, not supervision".
- ADR-0000 (Human Sovereignty) — checked against all five system constraints (§ Consistency with ADR-0000).

**Check that no statement accidentally gives Noema evidence-acquisition capability:**

- Reviewed every mention of "Noema" in this ADR. In the § NOEMA responsibilities, § Capability Restrictions matrix, invariant I6, and trust boundary B4, Noema is "No" for: read raw evidence, access evidence store, invoke retrieval, invoke external APIs, cross the corpus boundary, mutate investigation state, introduce claims, raise confidence. Rejected Alternative B explicitly forecloses "presentation gap-filling" retrieval. No sentence grants Noema a read/fetch/acquire path.

**Check that the existing `noema-agent` role is preserved:**

- `noema-agent` is described only as the constrained, stateless Execution Layer ("exists to execute, not to decide"). Invariant I9 and Rejected Alternative D keep the epistemic "Noema" and the service "`noema-agent`" distinct. `noema-agent` is named as a *candidate* executor for approved external acquisition with design explicitly deferred to a future ADR — no capability or authority is added to it here.

**Terminology grep (per Issue #32 validation):**

```sh
grep -n "Noesis\|Noema\|investigation_result\|can't\|cannot" \
  docs/noema/adr/ADR-0004-noesis-noema-epistemic-separation.md
```

Expected: matches present for all five terms, including the "can't rather than won't" principle statement and the enumerated `cannot` capability restrictions on Noema.

---

## Related Documents

- [`docs/noema/adr/ADR-0001-noema-architecture.md`](ADR-0001-noema-architecture.md) — four-repo physical architecture; repo responsibility model
- [`docs/noema/adr/ADR-0002-noema-governance-pipeline.md`](ADR-0002-noema-governance-pipeline.md) — nine-stage governance pipeline; trust vs. confidence
- [`docs/noema/adr/ADR-0003-noema-governance-platform.md`](ADR-0003-noema-governance-platform.md) — four-plane model; G1–G6; zero-runtime-human-gate design choice
- [`docs/noema/human-governed-loop.md`](../human-governed-loop.md) — task lifecycle; actors; branch and PR discipline
- [`docs/noema/project/PROJECT-CHARTER-v2.md`](../project/PROJECT-CHARTER-v2.md) — Project v2 (Hermes) vision, principles, success criteria
- [`docs/noema/project/EXECUTION-ROADMAP-v2.md`](../project/EXECUTION-ROADMAP-v2.md) — Hermes execution order; contract-before-implementation rule
- [`docs/adr/adr-0000-product-constitution.md`](../../adr/adr-0000-product-constitution.md) — Human Sovereignty Principle
- [`docs/architect/noema-agent-v2.md`](../../architect/noema-agent-v2.md) — `noema-agent` v2: constrained execution service
- [`docs/contracts/authority-model.md`](../../contracts/authority-model.md) — SYSTEM → USER → AGENT → MODEL authority hierarchy
- GitHub Issue: [rag-fish/RAGfish#32](https://github.com/rag-fish/RAGfish/issues/32)
- Follow-up: [#33](https://github.com/rag-fish/RAGfish/issues/33), [#34](https://github.com/rag-fish/RAGfish/issues/34), [#35](https://github.com/rag-fish/RAGfish/issues/35)
