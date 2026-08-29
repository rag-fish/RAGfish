# Project Hermes: Execution Roadmap v3 — Epistemic-Governance Rebaseline

**Status:** Active (planning baseline; awaiting architecture review by Max / ChatGPT and governance acceptance by Taka)
**Date:** 2026-08-29
**Scope:** All four Noema repos
**Governance owner:** Taka
**Owner agent (this document):** Claude Code CLI
**Supersedes for future execution planning:** [EXECUTION-ROADMAP-v2](EXECUTION-ROADMAP-v2.md) — v2 is retained unchanged as historical evidence.
**Architectural baseline:** [ADR-0004: Noesis / Noema Epistemic Separation](../adr/ADR-0004-noesis-noema-epistemic-separation.md) (merged to `main` via PR #36, incl. amendment `23b5736` — invariants I11/I12).

---

## 0. Why v3 exists

ROADMAP-v2 sequenced Hermes as six capability themes delivered in a linear order
(Governance → Trust → Evidence → Performance → Observability → Orchestration).
That sequence pre-dates **ADR-0004**, which introduces a formal **epistemic lifecycle**
and a hard separation between the layer that *investigates and assesses* (NOESIS) and
the layer that *writes the narrative* (NOEMA), plus a **Human Gate** for any crossing of
an external trust boundary.

ADR-0004 does **not** discard Hermes. It adds an epistemic dimension that the six themes
must now be sequenced *around*. Building Trust, Evidence, Observability, or Orchestration
before the NOESIS/NOEMA capability split and its contracts exist would mean building to an
unspecified interface — the exact failure mode "contracts before implementation" and
ADR-0004 exist to prevent.

**v3 keeps every still-valid Hermes asset** and re-sequences the rest into a Phase 0–8
model driven by the epistemic lifecycle. Nothing is retired for age; every RETIRE
decision below carries an explicit reason.

> ROADMAP-v2 remains the historical record of the original Hermes plan.
> ROADMAP-v3 is the authoritative plan for **future** execution and for rebuilding
> GitHub Project #16.

---

## 1. Carried-forward invariants (do not reopen)

These are fixed by ADR-0000 → ADR-0004 and by the Human-Governed Loop. Every task in
this roadmap is subordinate to them.

| # | Invariant | Source |
|---|---|---|
| INV-1 | **Human sovereignty.** Human noesis governs; AI accompanies. The NOESIS *layer* assists — it assesses, it does not govern (ADR-0004 I11, I12). | ADR-0000, ADR-0004 |
| INV-2 | **"Can't rather than won't."** Governance-critical restrictions are enforced by absent capability (no credential, no endpoint, no code path, no field, schema/type constraint, separate execution context) — never by prompt instruction alone. | ADR-0004 §2, I7 |
| INV-3 | **`investigation_result` is the sole Noesis → Noema handoff.** Noema has no other input channel from the investigation side. | ADR-0004 I5, B2 |
| INV-4 | **Noema capability isolation.** Noema cannot read raw evidence, reach the evidence store, invoke retrieval, call external APIs, mutate investigation state, introduce new factual claims, or raise confidence above the Noesis result. | ADR-0004 I6, B4 |
| INV-5 | **Epistemic Noema ≠ `noema-agent`.** The epistemic presentation layer and the constrained execution service stay distinct; neither definition is silently substituted for the other. | ADR-0004 I9 |
| INV-6 | **External trust-boundary crossing is human-gated.** Noesis may *propose* acquisition; only a recorded human authorization at the Human Gate permits it. AI identity cannot own that approval. | ADR-0004 I3, I8, B1, B3 |
| INV-7 | **Recompute, don't append.** Newly acquired evidence re-enters Noesis; the assessment is recomputed over the enlarged set, not patched downstream. | ADR-0004 I4 |
| INV-8 | **Contracts before implementation; architecture before credentials/endpoints; capability restrictions before agent prompting; governance-boundary tests before production integration.** | ADR-0000, ADR-0002, ADR-0003, Charter v2 |
| INV-9 | **Local-first is the default, non-degraded path.** Remote and external acquisition are opt-in and never a silent fallback. Zero runtime human gates for ordinary grounded queries. | ADR-0001, ADR-0003 |
| INV-10 | **Trust ≠ confidence.** Knowledge trust (evaluated ex-ante) and model/assessment confidence (calibrated by Noesis) are independent and neither substitutes for the other. | ADR-0002, ADR-0003 |
| INV-11 | **1 task = 1 Issue = 1 branch = 1 PR; Taka reviews and merges; every decision is recorded as an ADR/contract/evidence artifact.** | Human-Governed Loop, ADR-0001 |

---

## 2. The epistemic execution model

```
Evidence
   │  (raw material; user-owned corpus + — only after Human Gate — externally acquired sources)
   ▼
NOESIS
   │  claim decomposition · evidence synthesis · competing hypotheses ·
   │  source-dependency analysis · uncertainty · calibrated epistemic assessment ·
   │  (optionally) a PROPOSAL for additional evidence acquisition
   ▼
HUMAN GATE
   │  a human explicitly authorizes or declines any crossing of an external trust boundary
   ▼
External Evidence Acquisition        — ONLY when explicitly approved
   │
   ▼
NOESIS Re-analysis                    — recompute over the enlarged evidence set (INV-7)
   │
   ▼
investigation_result                  — the sole Noesis → Noema handoff object (INV-3)
   │
   ▼
NOEMA                                 — presentation / narrative transformation only (INV-4)
```

The lifecycle may iterate (Noesis → Human Gate → acquisition → re-analysis)\* while a
human keeps approving. It always terminates in Noesis producing an `investigation_result`;
Noema is always downstream of it.

This model is an **added dimension** over ADR-0002's nine-stage pipeline and ADR-0003's
four planes — not a replacement. Mapping is in ADR-0004 § "Relationship to Existing Architecture".

---

## 3. Hermes v2 asset classification — KEEP / MOVE / REPLACE / RETIRE

Legend: **KEEP** = still valid, no material conceptual change · **MOVE** = still valid, resequenced ·
**REPLACE** = objective still valid, old contract/task superseded by the epistemic architecture ·
**RETIRE** = genuinely obsolete or contradictory (explicit reason required).

### 3.1 Structural assets

| Hermes v2 asset | Class | Rationale | New home |
|---|---|---|---|
| Six capability themes (Governance, Trust, Evidence, Performance, Observability, Multi-model Orchestration) | **KEEP** | ADR-0004 adds an epistemic dimension; it removes no theme. | Retained as cross-cutting capability lenses, mapped onto Phases 5–7. |
| Repository participation model (which repo does what) | **KEEP** | ADR-0004 § "Repository Responsibility Mapping" is consistent with ADR-0001; no repo boundary changes. | Unchanged. |
| AI collaboration model (Claude / Codex / Taka / Max) | **KEEP** | Same actors, same division of labour. | Unchanged; see §7. |
| Development lifecycle (Issue → Branch → PR → Review → Merge → Evidence) | **KEEP** | Human-Governed Loop invariant (INV-11). | Unchanged. |
| "Future Expansion → Athena" (extend, don't replace) | **KEEP** | ADR-0004 is that principle applied — Hermes extended, not replaced. | Unchanged. |
| Cross-repo rule: `RAGfish` produces the contract/schema first, merged to `main`, before any repo implements | **KEEP** | Reinforced by INV-8. | Governs every phase. |

### 3.2 Sequencing assets

| Hermes v2 asset | Class | Rationale | New home |
|---|---|---|---|
| Execution Order **Phase A–F** (the linear sequence itself) | **RETIRE** | **Reason:** the linear capability sequence pre-dates the epistemic lifecycle. It would sequence Trust/Evidence/Observability/Orchestration before the NOESIS/NOEMA split and its contracts exist, i.e. building to an unspecified interface (violates INV-8). The *rationale* of each phase ("why first / why last") is preserved and folded into Phases 0–8. | Phase 0–8 model (§4–§5). |
| Charter milestones **M1–M6** | **KEEP + remap** | M1 complete; M2–M6 remain valid coarse groupings. No contradiction with ADR-0004. | Mapping table in §5.10; Charter unchanged (§6). |
| Dependency-matrix rows referencing **"Issue 4" / "Issue 7"** | **RETIRE** | **Reason:** those refer to closed EPIC-era issues (#2–#5 vintage) that no longer correspond to active work. Stale pointers only. | Replaced by the Phase 0–8 DAG (§8). |
| Dependency-matrix "TBD" placeholder rows | **REPLACE** | Objective (sequence the themes into issues) is still valid, but the placeholder set is superseded by the concrete task catalog. | §5 task catalog. |
| #25 (charter), #26 / #18 (backlog & sequencing docs) | **KEEP (historical)** | Completed foundation work; ROADMAP-v3 supersedes #26/#18 *for future planning* without erasing them. | Historical evidence. |

### 3.3 Capability deliverables

| Hermes v2 deliverable | Class | Rationale | New home |
|---|---|---|---|
| **Route Contract v1** specification | **KEEP + MOVE** | Still the cognition ↔ execution boundary. ADR-0004 maps onto it. Must *evolve* to carry an investigation flag, "external acquisition in scope pending Human Gate", and `investigation_id` linkage. | Phase 7 · `H7-ROUTE-CONTRACT-V1` |
| **Human approval gate schema** (generic) | **REPLACE** | **Superseded by** (a) ADR-0004's scoped **Human Gate** approval-record schema for the external trust boundary, and (b) ADR-0003's existing **Human Decision Gate** for policy changes / pack promotion (already in place). A third generic schema would be ambiguous and redundant. | Phase 1 · `H1-HUMANGATE-RECORD` (+ existing ADR-0003 gate, KEEP) |
| Policy enforcement contract (`noema-agent`) | **KEEP + MOVE** | Concept unchanged; sequenced after the governance contract (#33). | Phase 6 · `H6-PERF-CONTRACTS` (design) + downstream impl (deferred) |
| Governance audit tooling | **KEEP + MOVE** | Folds into audit-chain + evidence-package work. | Phase 5 · `H5-AUDITCHAIN-EPISTEMIC` |
| **Trust context schema** | **KEEP + MOVE** | Still required. Must reconcile with Noesis *calibrated confidence*, which ADR-0004 keeps separate from trust (INV-10). | Phase 5 · `H5-TRUST-CONTEXT-SCHEMA` |
| **RAGpack trust metadata standard** | **KEEP (largely DONE)** | RAGpack v1.3 already implemented (ADR-0003). Extend only for source-independence signal. | Phase 5 · `H5-SOURCE-INDEPENDENCE-TRUST` |
| **Evidence artifact schema** (single catch-all) | **REPLACE** | **Superseded:** ADR-0004 distinguishes three artifact classes with different capability rules — *Evidence* (Noesis input), *`investigation_result`* (handoff, no raw evidence), *audit-chain records*. One schema cannot serve all three without breaking the capability matrix. | Phase 0 · #34 (handoff) + Phase 1 · `H1-EVIDENCE-CONTRACT` (input) + Phase 5 · audit |
| Decision log specification | **KEEP + MOVE** | ADR-0002 §9 + ADR-0003 G6 stand. Extend with epistemic-lifecycle events. | Phase 6 · `H6-DECISION-AUDIT-RELATIONSHIP` |
| Validation report format (corpus / retrieval quality) | **KEEP** | `spec-g3-promotion-gate.md` exists and is unchanged by ADR-0004. Reconcile references only. | Phase 5 · `H5-EVIDENCE-AUDIT-RECONCILE` |
| Async evidence write path | **KEEP + MOVE** | Performance requirement unchanged. | Phase 6 · `H6-PERF-CONTRACTS` |
| Policy cache design | **KEEP + MOVE** | Unchanged. | Phase 6 · `H6-PERF-CONTRACTS` |
| Trust pre-computation contract | **KEEP + MOVE** | Unchanged. | Phase 6 · `H6-PERF-CONTRACTS` |
| **Latency budget** specification | **KEEP + MOVE + extend** | Add budgets for Noesis assessment, re-analysis *recompute*, and Noema narrative. | Phase 6 · `H6-LATENCY-BUDGET` |
| **Observability model v0 (#27)** | **KEEP + AMEND + MOVE** | Needs new identifiers and trace points for the epistemic lifecycle. #27 is **not modified in this task** — see §6.3 recommendation. | Phase 6 · `H6-27-AMEND` |
| Trace relationship model (route events → decision logs → PR evidence → validation reports) | **KEEP + extend** | Add Noesis assessment / Human Gate / acquisition / re-analysis / `investigation_result` / Noema validation. | Phase 6 · `H6-DECISION-AUDIT-RELATIONSHIP` |
| Sync vs async observability boundary | **KEEP** | Unchanged. | Phase 6 |
| Stage-level trace format for the nine pipeline stages | **KEEP** | Nine stages retained; epistemic dimension is an overlay. | Phase 6 |
| Execution mode selection policy (local / remote / tool / human) | **KEEP + MOVE** | Unchanged; add: external acquisition is never a selectable execution mode without a Human Gate approval. | Phase 7 · `H7-EXEC-MODE-POLICY` |
| Local-first routing default / remote opt-in contract | **KEEP + MOVE** | ADR-0004 explicitly preserves it (INV-9). Reaffirm. | Phase 7 · `H7-LOCAL-FIRST-OPTIN` |

### 3.4 RETIRE summary (with reasons)

1. **Execution Order Phase A–F sequence** — replaced by the epistemic-lifecycle-driven Phase 0–8. The linear order would place downstream capability work ahead of the NOESIS/NOEMA contracts it depends on (INV-8 violation). Phase rationale is preserved, not lost.
2. **Generic "human approval gate schema" deliverable** — ADR-0004 replaced the generic notion with a *scoped* Human Gate (external trust boundary) approval-record; ADR-0003 already owns the policy/pack Human Decision Gate. A third generic artifact is ambiguous and redundant.
3. **Single catch-all "evidence artifact schema" deliverable** — ADR-0004 splits evidence into three artifact classes with incompatible capability rules; a unified schema would violate the capability matrix (INV-4).
4. **Dependency-matrix references to "Issue 4 / Issue 7"** — closed EPIC-era issues that no longer map to active work.

Nothing else is retired. Every other Hermes asset is KEEP or MOVE.

---

## 4. Phase model (Phase 0 → Phase 8)

| Phase | Name | Produces | Gate to exit |
|---|---|---|---|
| **0** | Epistemic Governance Foundation | ADR-0004 (done) → governance contract, capability matrix, `investigation_result` v0.1, governance regression cases | #33, #34, #35 merged |
| **1** | Evidence & Acquisition Contracts | Evidence/provenance contract, source-dependency model, Human Gate approval-record schema, external acquisition request/result contract, ADR on acquisition execution locus | all Phase 1 contracts + ADR merged |
| **2** | NOESIS Runtime (contracts & specs) | NOESIS runtime/prompt contract, claim decomposition, calibrated assessment, competing-hypothesis representation, source-dependency evaluation, uncertainty representation, re-analysis/recompute semantics | all Phase 2 specs merged |
| **3** | NOEMA Runtime (contracts & specs) | Isolated Noema invocation contract, `investigation_result`-only input rule, narrative transformation contract, capability-isolation spec, output-validation spec, hosting ADR | all Phase 3 specs + ADR merged |
| **4** | Human-Gated External Acquisition (design) | Sealed acquisition gateway design, human-approval enforcement design, executor selection, provider-agnostic integration template, acquisition-return + re-analysis-trigger contract | all Phase 4 designs merged |
| **5** | Trust / Evidence / Audit Integration | Evidence↔audit reconciliation, trust context schema, signed evidence packages, audit-chain epistemic integration, source-independence trust signal | all Phase 5 specs merged |
| **6** | Observability / Performance | #27 amendment, epistemic trace identifiers, decision/audit relationship model, latency budget, performance contracts (policy cache, trust pre-compute, async paths) | all Phase 6 specs merged |
| **7** | Multi-model Orchestration | Route Contract v1 (evolved), execution mode selection policy, local-first/remote-opt-in contract, routing-authority-vs-execution invariant ADR, provider/model selection contract | all Phase 7 specs + ADR merged |
| **8** | Final UAT / Release | Cross-repo integration UAT plan, governance regression gate, capability-boundary gate, final human UAT, release, publication package | Taka's final UAT + release approval |

**Scope note:** Phases 2, 3, 4 in this roadmap produce **contracts, specs, and ADRs in `RAGfish` only**.
Runtime implementation in `NoesisNoema` / `noema-agent` / `noesisnoema-pipeline` is
**explicitly deferred** and gated on the corresponding contract merging to `main`
(INV-8). Downstream implementation issues are **not created by this roadmap**; they are
noted as `future / downstream` in the task catalog and will be scheduled as a subsequent
execution wave after architecture review.

---

## 5. Task catalog

Task IDs are provisional planning keys (`H<phase>-<slug>`). Real GitHub Issue numbers are
assigned at creation time (after architecture review). Existing issues keep their numbers.

### 5.0 Master dependency table

| ID | Title | Phase | Target repo | Owner | Depends on | Status |
|---|---|---|---|---|---|---|
| #32 | ADR-0004: Noesis/Noema epistemic separation | 0 | RAGfish | Claude | — | **DONE** (merged, PR #36 + `23b5736`) |
| #33 | Docs: governance contract + capability matrix | 0 | RAGfish | Claude | #32 | OPEN — **next** |
| #34 | Feature: `investigation_result` contract v0.1 | 0 | RAGfish | Codex | #32, #33 | OPEN |
| #35 | Test: Noesis/Noema governance regression cases | 0 | RAGfish | Codex | #32, #33, #34 | OPEN |
| H1-EVIDENCE-CONTRACT | Docs: Evidence object & provenance contract | 1 | RAGfish | Claude | #33 | Planned |
| H1-SOURCE-DEP-MODEL | Docs: source-dependency / independent-chain model | 1 | RAGfish | Max + Claude | #33, #34 | Planned |
| H1-HUMANGATE-RECORD | Feature: Human Gate approval-record schema | 1 | RAGfish | Codex (from Claude/Max spec) | #33, #34 | Planned |
| H1-ACQUISITION-CONTRACT | Feature: external acquisition request/result contract | 1 | RAGfish | Codex (from Claude/Max spec) | #33, #34, H1-EVIDENCE-CONTRACT | Planned |
| H1-ADR-ACQ-LOCUS | ADR-0005 (Noema): external-acquisition execution locus | 1 | RAGfish | Claude (draft) → Max (review) → Taka (accept) | H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT | Planned |
| H2-NOESIS-CONTRACT | Docs: NOESIS runtime & prompt contract | 2 | RAGfish | Claude + Max | #33, #34 | Planned |
| H2-ASSESSMENT-MODEL | Docs: claim decomposition + calibrated assessment + uncertainty model | 2 | RAGfish | Max + Claude | #34, H2-NOESIS-CONTRACT | Planned |
| H2-HYPOTHESES | Docs: competing-hypothesis representation | 2 | RAGfish | Max + Claude | H2-ASSESSMENT-MODEL | Planned |
| H2-SOURCEDEP-EVAL | Docs: source-dependency evaluation algorithm | 2 | RAGfish | Claude | H1-SOURCE-DEP-MODEL, H2-NOESIS-CONTRACT | Planned |
| H2-REANALYSIS-SEMANTICS | Docs: re-analysis / recompute semantics | 2 | RAGfish | Claude + Max | H2-ASSESSMENT-MODEL, H2-HYPOTHESES, H2-SOURCEDEP-EVAL, H1-ACQUISITION-CONTRACT | Planned |
| H3-NOEMA-ISOLATION | Docs: isolated Noema invocation + capability-isolation spec | 3 | RAGfish | Claude + Max | #33, #34 | Planned |
| H3-NARRATIVE-CONTRACT | Docs: presentation / narrative transformation contract | 3 | RAGfish | Claude | #34, H3-NOEMA-ISOLATION | Planned |
| H3-OUTPUT-VALIDATION | Feature: Noema output-validation spec (no new claims, no confidence escalation) | 3 | RAGfish | Codex (from Claude spec) | #34, #35, H3-NOEMA-ISOLATION | Planned |
| H3-ADR-NOEMA-HOSTING | ADR-0006 (Noema): where Noema-layer narrative work runs | 3 | RAGfish | Claude → Max → Taka | H3-NOEMA-ISOLATION, INV-5 | Planned |
| H4-SEALED-GATEWAY | Docs: sealed acquisition-gateway design | 4 | RAGfish | Claude | H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H1-ADR-ACQ-LOCUS | Planned |
| H4-APPROVAL-ENFORCEMENT | Docs: human-approval enforcement design ("can't rather than won't") | 4 | RAGfish | Claude + Max | H1-HUMANGATE-RECORD, H4-SEALED-GATEWAY | Planned |
| H4-EXECUTOR-SELECTION | Docs: acquisition executor selection (per ADR-0005) | 4 | RAGfish | Claude | H1-ADR-ACQ-LOCUS, H4-SEALED-GATEWAY | Planned |
| H4-PROVIDER-TEMPLATE | Docs: provider-agnostic acquisition integration template | 4 | RAGfish | Claude | H4-SEALED-GATEWAY, H4-EXECUTOR-SELECTION | Planned |
| H4-ACQ-RETURN-TRIGGER | Docs: acquisition-artifact return + re-analysis trigger contract | 4 | RAGfish | Claude + Max | H4-SEALED-GATEWAY, H2-REANALYSIS-SEMANTICS | Planned |
| H5-EVIDENCE-AUDIT-RECONCILE | Audit: reconcile RAGpack provenance / integrity hashes / validation reports with Evidence contract | 5 | RAGfish (cross-repo audit) | Claude | H1-EVIDENCE-CONTRACT | Planned |
| H5-TRUST-CONTEXT-SCHEMA | Docs: trust context schema (evolved from Hermes Theme 2) | 5 | RAGfish | Claude | H1-EVIDENCE-CONTRACT, H5-EVIDENCE-AUDIT-RECONCILE | Planned |
| H5-SIGNED-EVIDENCE-PACKAGES | Docs: Ed25519 evidence-package applicability to `investigation_result` + Human Gate record | 5 | RAGfish | Claude | #34, H1-HUMANGATE-RECORD, H5-EVIDENCE-AUDIT-RECONCILE | Planned |
| H5-AUDITCHAIN-EPISTEMIC | Docs: audit-chain integration for epistemic-lifecycle events (extends ADR-0003 G6) | 5 | RAGfish | Claude | #34, H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H2-REANALYSIS-SEMANTICS | Planned |
| H5-SOURCE-INDEPENDENCE-TRUST | Docs: source independence/dependency in RAGpack trust metadata | 5 | RAGfish (+ pipeline follow-up) | Claude | H1-SOURCE-DEP-MODEL, H5-TRUST-CONTEXT-SCHEMA | Planned |
| H6-27-AMEND | Docs: amend observability model v0 (#27) for the epistemic lifecycle | 6 | RAGfish | Claude | #33, #34, H5-AUDITCHAIN-EPISTEMIC | Planned |
| H6-EPISTEMIC-TRACE-IDS | Docs: epistemic-lifecycle trace identifiers | 6 | RAGfish | Claude | H6-27-AMEND | Planned |
| H6-DECISION-AUDIT-RELATIONSHIP | Docs: decision/audit relationship model + trace relationship update | 6 | RAGfish | Claude | H6-27-AMEND, H5-AUDITCHAIN-EPISTEMIC | Planned |
| H6-LATENCY-BUDGET | Docs: latency budget (Noesis assessment, re-analysis recompute, Noema narrative) | 6 | RAGfish | Claude (+ Codex benchmarks later) | H2-REANALYSIS-SEMANTICS, H3-NARRATIVE-CONTRACT | Planned |
| H6-PERF-CONTRACTS | Docs: performance contracts — policy cache, trust pre-computation, async evidence/audit paths | 6 | RAGfish | Claude | #33, H5-TRUST-CONTEXT-SCHEMA, H5-AUDITCHAIN-EPISTEMIC | Planned |
| H7-ROUTE-CONTRACT-V1 | ADR-0007 (Noema) + Docs: Route Contract v1 (evolved for investigation + acquisition scope) | 7 | RAGfish | Claude + Max | #33, #34, H1-ADR-ACQ-LOCUS | Planned |
| H7-EXEC-MODE-POLICY | Docs: execution mode selection policy reconciled with the epistemic lifecycle | 7 | RAGfish | Claude | H7-ROUTE-CONTRACT-V1 | Planned |
| H7-LOCAL-FIRST-OPTIN | Docs: local-first default + remote opt-in contract (reaffirm INV-9) | 7 | RAGfish | Claude | H7-ROUTE-CONTRACT-V1 | Planned |
| H7-ROUTING-AUTHORITY-INVARIANT | ADR-0008 (Noema): routing authority ≠ execution capability; orchestration must not bypass the Human Gate | 7 | RAGfish | Claude → Max → Taka | H7-ROUTE-CONTRACT-V1, H4-APPROVAL-ENFORCEMENT | Planned |
| H7-PROVIDER-MODEL-SELECTION | Docs: provider / model selection contract | 7 | RAGfish | Claude | H7-EXEC-MODE-POLICY | Planned |
| H8-INTEGRATION-UAT-PLAN | Docs: cross-repository integration UAT plan | 8 | RAGfish | Claude + Taka | all Phase 2–7 contract tasks | Planned |
| H8-GOV-REGRESSION-GATE | Test: governance regression suite execution gate (from #35) | 8 | RAGfish (gate def) → downstream (impl) | Codex | #35, H8-INTEGRATION-UAT-PLAN | Planned |
| H8-CAPABILITY-BOUNDARY-GATE | Test: capability-boundary test gate | 8 | RAGfish (gate def) → downstream (impl) | Codex | #35, H3-OUTPUT-VALIDATION, H8-INTEGRATION-UAT-PLAN | Planned |
| H8-FINAL-UAT | Final human UAT by Taka | 8 | all repos | Taka | H8-GOV-REGRESSION-GATE, H8-CAPABILITY-BOUNDARY-GATE | Planned |
| H8-RELEASE | Release tags + release notes | 8 | all repos | Taka | H8-FINAL-UAT | Planned |
| H8-PUBLICATION | rag.fish update + X / LinkedIn / Facebook publication package | 8 | RAGfish + web | Claude/Max draft → Taka approves & posts | H8-RELEASE | Planned |

### 5.1 Phase 0 — Epistemic Governance Foundation

Purpose: turn ADR-0004's conceptual separation into explicit contracts and testable
governance boundaries.

#### #32 — ADR-0004: Noesis/Noema epistemic separation — **DONE**
Merged to `main` via PR #36, including amendment `23b5736` (invariants I11 "Noesis outputs
are advisory artifacts" and I12 "human noesis ≠ NOESIS layer"). No further action.

#### #33 — Docs: define governance contract and capability matrix
- **Description:** Translate the Noesis/Noema separation into explicit, reviewable governance rules plus a capability matrix that makes prohibited actions unambiguous across layers, each control mapped to an enforcement mechanism (policy / schema / type-system / credential / endpoint / test).
- **Objective:** Make INV-2 and INV-4 concrete and reviewable before any schema or prompt work begins.
- **Target repository:** `rag-fish/RAGfish`
- **Scope:** governance contract for Noesis, Human Gate, external acquisition, Noesis re-analysis, Noema; capability matrix (read/write/invoke over evidence store, external APIs, mutable investigation state, audit store, presentation outputs); human-only fields incl. approval ownership; controls mapped to enforcement mechanism. Path: `docs/noema/governance/`.
- **Out of scope:** credentials/endpoints/databases; runtime prompts; JSON Schema validators; provider-specific integration.
- **Branch:** `docs/governance-capability-contract`
- **Owner agent:** Claude CLI (broad governance documentation; cross-layer reasoning).
- **Definition of Done:** governance contract + capability matrix under `docs/noema/governance/`; Noema shown as no-evidence-store / no-external-API in the matrix; Human Gate authority + approval ownership explicit; every control mapped to an enforcement mechanism; documents cite ADR-0004 (incl. I11/I12) as basis.
- **Validation:** `rg -n "Noesis|Noema|Human Gate|evidence|external|capability|approval" docs/noema/governance`; manual cross-check against ADR-0004 and the Human-Governed Loop; confirm no control is "prompt-only".
- **Dependencies:** #32 (merged).
- **Review / merge rule:** Reviewer Taka; architecture review Max/ChatGPT; squash; do not merge before #32's contract is accepted stable (it is).

#### #34 — Feature: define `investigation_result` contract v0.1
- **Description:** The machine-readable Noesis → Noema handoff. Exposes calibrated findings and approved recommendations without raw evidence or any acquisition capability.
- **Objective:** Give Phases 2, 3, 5, 6 a single named, testable object to constrain against (INV-3).
- **Target repository:** `rag-fish/RAGfish`
- **Scope:** `investigation_result` v0.1 JSON Schema + contract doc; separate claim / assessment / uncertainty / evidence-chain summary / recommendation / human-approval concepts; bounded assessment-state enum (no `verified: boolean`); independent-source-chain counts without raw evidence; fields Noema may reference vs. intentionally absent; downstream invariants (Noema cannot raise confidence or mint claim IDs); valid + invalid example payloads. Path: `docs/noema/schemas/`.
- **Out of scope:** evidence-store schema; external-acquisition schema; provider-specific fields; runtime prompts; UI.
- **Branch:** `feature/investigation-result-contract`
- **Owner agent:** Codex CLI (focused JSON Schema implementation + fixtures), from a Claude/Max contract sketch.
- **Definition of Done:** schema exists; no `verified: boolean`; bounded enum (`supported` / `partially_supported` / `contradicted` / `unresolved` / `insufficient_evidence` — final naming per this task); confidence + uncertainty fields defined; no raw evidence content in the Noema-facing contract; `approved_by` cannot represent AI ownership (documented validation rule); example valid/invalid payloads.
- **Validation:** `python -m json.tool docs/noema/schemas/investigation-result.schema.json >/dev/null`; validate example payloads; manual check against ADR-0004 + #33 capability matrix.
- **Dependencies:** #32; #33 (final capability constraints).
- **Review / merge rule:** Reviewer Taka; architecture review Max; schema impl Codex; squash; do not merge if the Noema-facing schema exposes raw evidence or permits unbounded claim creation.

#### #35 — Test: define Noesis/Noema governance regression cases
- **Description:** Adversarial / regression cases proving the boundary fails closed.
- **Objective:** Satisfy INV-8 ("governance-boundary tests before production integration") for the whole epistemic lifecycle.
- **Target repository:** `rag-fish/RAGfish`
- **Scope:** regression test specification covering: Noema new-claim rejection; Noema confidence-escalation rejection; Noema external-acquisition-attempt rejection; source-dependency counting (many reports, one origin = one chain); AI identity in `approved_by` rejection; external acquisition without human approval rejection. Each case: input, attempted violation, expected outcome, enforcement layer. Distinguish prompt-level refusal from architectural inability. Path: `docs/noema/tests/`.
- **Out of scope:** runtime harness in downstream repos; provider-specific tests; perf/load tests; UI/UAT scripts.
- **Branch:** `test/noesis-noema-governance-cases`
- **Owner agent:** Codex CLI (test design), reviewed by Max.
- **Definition of Done:** spec exists; ≥6 core negative-path cases fully specified; each ADR-0004 invariant maps to ≥1 case; cases convertible to automated tests in `NoesisNoema` / `noema-agent` later.
- **Validation:** `rg -n "new claim|confidence|external|approved_by|independent|cannot|reject" docs/noema/tests`; manual 1:1 invariant→case traceability.
- **Dependencies:** #32; #33; #34 (schema-facing assertions).
- **Review / merge rule:** Reviewer Taka; architecture review Max; test design Codex; squash; do not merge unless every critical invariant has a negative-path test.

### 5.2 Phase 1 — Evidence & Acquisition Contracts

#### H1-EVIDENCE-CONTRACT — Docs: Evidence object & provenance contract
- **Description / Objective:** Define the *Evidence* artifact class that Noesis (and only Noesis) consumes — provenance, trust metadata, corpus vs. externally-acquired origin — distinct from `investigation_result` and from audit records. Replaces the generic Hermes "evidence artifact schema" for the *input* class.
- **Target repository:** `rag-fish/RAGfish`   · **Branch:** `docs/evidence-object-contract`   · **Owner:** Claude CLI
- **Scope:** evidence object fields; provenance chain; trust-metadata reference (not recompute); origin marker (`user_corpus` | `externally_acquired`); consumed-by-Noesis-only rule; alignment with RAGpack v1.3 (ADR-0003 G2) and ADR-0002 Trust Evaluation.
- **Out of scope:** evidence-store implementation; retrieval API; acquisition mechanics; JSON Schema validators.
- **Definition of Done:** contract doc under `docs/noema/governance/` or `docs/noema/schemas/`; three artifact classes explicitly delineated; cites ADR-0004 + #33 + #34; no capability granted to Noema.
- **Validation:** `rg -n "provenance|trust|origin|Noesis|evidence" docs/noema/**` ; manual cross-check vs RAGpack v1.3 schema and ADR-0002 §3.
- **Dependencies:** #33.   · **Review/merge:** Taka + Max; squash; not before #33 merged.

#### H1-SOURCE-DEP-MODEL — Docs: source-dependency / independent-chain model
- **Description / Objective:** Formalize "how many *independent* source chains support a claim" (ADR-0004: multiple reports from one origin = one chain). Feeds #34's independent-source-chain counts, Phase 2 evaluation, Phase 5 trust metadata, and #35 test case.
- **Target repository:** `rag-fish/RAGfish`   · **Branch:** `docs/source-dependency-model`   · **Owner:** Max + Claude (Max: model design; Claude: documentation)
- **Scope:** definition of an independent source chain; origin-collapse rules; representation in `investigation_result`; worked examples.
- **Out of scope:** implementation; ranking/scoring functions in code.
- **Definition of Done:** model doc; ≥3 worked examples incl. the "many reports, one origin" case; consistent with #34 field names.
- **Validation:** manual review against ADR-0004 § "Source dependency analysis" and #35's source-dependency case.
- **Dependencies:** #33, #34.   · **Review/merge:** Taka + Max; squash.

#### H1-HUMANGATE-RECORD — Feature: Human Gate approval-record schema
- **Description / Objective:** The recorded, scoped, human-only authorization object for crossing an external trust boundary. Replaces the generic Hermes "human approval gate schema".
- **Target repository:** `rag-fish/RAGfish`   · **Branch:** `feature/human-gate-approval-record`   · **Owner:** Codex CLI (schema), from Claude/Max spec
- **Scope:** JSON Schema + doc; `approved_by` constrained to a human identity type (INV-6, I8); scope fields (specific acquisition, not standing capability); explicit-decline representation; no inference-from-inaction; linkage to `investigation_id`.
- **Out of scope:** approval UI; runtime gate; credential storage; provider fields.
- **Definition of Done:** schema under `docs/noema/schemas/`; `approved_by` cannot be an agent/model/service by construction + documented validation rule; decline is a first-class outcome; valid/invalid payloads.
- **Validation:** `python -m json.tool docs/noema/schemas/human-gate-approval.schema.json >/dev/null`; payload tests; cross-check #33 human-only fields.
- **Dependencies:** #33, #34.   · **Review/merge:** Taka + Max; Codex impl; squash; do not merge if `approved_by` can be non-human.

#### H1-ACQUISITION-CONTRACT — Feature: external acquisition request/result contract
- **Description / Objective:** The request Noesis *proposes* and the result an approved acquisition *returns* — provider-agnostic. Carries provenance forward so acquired evidence re-enters Noesis with comparable metadata (INV-7).
- **Target repository:** `rag-fish/RAGfish`   · **Branch:** `feature/external-acquisition-contract`   · **Owner:** Codex CLI, from Claude/Max spec
- **Scope:** acquisition-request schema (proposal only; no execution authority); acquisition-result schema (provenance, trust metadata, origin marker); binding to a Human Gate approval record; provider-agnostic.
- **Out of scope:** provider endpoints/credentials; Grok or any specific provider; the *executor* decision (that is H1-ADR-ACQ-LOCUS).
- **Definition of Done:** both schemas + doc; request is inert without a linked approval record; result feeds the Evidence contract (H1-EVIDENCE-CONTRACT) shape.
- **Validation:** `python -m json.tool` on both schemas; payload tests; cross-check ADR-0004 §"External Evidence Acquisition".
- **Dependencies:** #33, #34, H1-EVIDENCE-CONTRACT.   · **Review/merge:** Taka + Max; Codex; squash.

#### H1-ADR-ACQ-LOCUS — ADR-0005 (Noema): external-acquisition execution locus
- **Description / Objective:** Decide **where** approved external acquisition executes. ADR-0004 names `noema-agent` only as a *candidate* and explicitly defers this. **Do not auto-assign `noema-agent`.**
- **Target repository:** `rag-fish/RAGfish`   · **Branch:** `docs/adr-0005-acquisition-execution-locus`   · **Owner:** Claude (draft) → Max (architecture review) → Taka (accept)
- **Scope:** options analysis (`noema-agent` as constrained task / a new sealed component / `NoesisNoema` surface only / other); decision + rationale; capability posture of the chosen executor; consistency with INV-2, INV-5, INV-6.
- **Out of scope:** implementing the executor; credentials; provider choice.
- **Definition of Done:** ADR-0005 (Noema) merged with a clear decision; `noema-agent`'s "exists to execute, not to decide" definition preserved if it is chosen (INV-5); follow-up issues identified.
- **Validation:** manual review vs ADR-0004 I5/I9 and ADR-0001 repo boundaries; Max sign-off.
- **Dependencies:** H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT.   · **Review/merge:** Taka accepts; squash.

### 5.3 Phase 2 — NOESIS Runtime (contracts & specs)

Preserve throughout: **NOESIS assesses; human noesis governs.** Outputs are advisory
artifacts (I11). All Phase 2 tasks are `RAGfish` docs/specs; runtime code is `future / downstream`.

#### H2-NOESIS-CONTRACT — Docs: NOESIS runtime & prompt contract
- **Objective:** Define the NOESIS layer's I/O contract, capability posture (has retrieval + evidence access; no external API; no approval ownership), and the shape of its prompt/runtime interface — without writing the prompt.
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `docs/noesis-runtime-contract`   · **Owner:** Claude + Max
- **Scope:** inputs (Evidence, question, policy context); outputs (`investigation_result`, or an acquisition proposal to the Human Gate); capability posture cross-referenced to #33 matrix; separation from Noema as a distinct capability context (INV-2).
- **Out of scope:** the actual system prompt; model selection; downstream Swift code.
- **DoD:** contract doc; capability posture matches #33; explicitly states NOESIS produces advisory artifacts (I11) and never owns approval (I8).
- **Validation:** cross-check #33, ADR-0004 §"NOESIS Layer Responsibilities".   · **Deps:** #33, #34.   · **Review/merge:** Taka + Max; squash.

#### H2-ASSESSMENT-MODEL — Docs: claim decomposition + calibrated assessment + uncertainty
- **Objective:** Define how a compound question becomes individually assessable claims, how each claim gets a bounded assessment state + calibrated confidence (reflecting evidence strength and independence, not model fluency — INV-10), and how uncertainty is represented.
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `docs/noesis-assessment-model`   · **Owner:** Max + Claude
- **Scope:** decomposition rules; assessment-state semantics (aligned to #34 enum); calibration method; explicit-uncertainty representation; trust-vs-confidence separation.
- **Out of scope:** implementation; specific model calibration training.
- **DoD:** model doc; 1:1 alignment with #34 fields; worked example from question → claims → assessment.
- **Validation:** manual vs #34, ADR-0002 §3, ADR-0004.   · **Deps:** #34, H2-NOESIS-CONTRACT.   · **Review/merge:** Taka + Max; squash.

#### H2-HYPOTHESES — Docs: competing-hypothesis representation
- **Objective:** Define how Noesis holds >1 candidate explanation when evidence does not force one, and how that survives into `investigation_result` and through Noema unchanged (INV-4).
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `docs/competing-hypothesis-representation`   · **Owner:** Max + Claude
- **Scope:** representation structure; non-collapse rule; carry-through to `investigation_result`.
- **Out of scope:** implementation; ranking heuristics in code.
- **DoD:** doc; consistent with #34; example with two live hypotheses.
- **Validation:** manual vs ADR-0004.   · **Deps:** H2-ASSESSMENT-MODEL.   · **Review/merge:** Taka + Max; squash.

#### H2-SOURCEDEP-EVAL — Docs: source-dependency evaluation algorithm
- **Objective:** Turn H1-SOURCE-DEP-MODEL into an evaluation procedure Noesis follows to count independent chains.
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `docs/source-dependency-evaluation`   · **Owner:** Claude
- **Scope:** procedure; inputs from Evidence provenance; output into `investigation_result`; edge cases.
- **Out of scope:** implementation.
- **DoD:** doc; deterministic procedure; maps to #35 source-dependency case.
- **Validation:** run the procedure by hand against #35's fixture.   · **Deps:** H1-SOURCE-DEP-MODEL, H2-NOESIS-CONTRACT.   · **Review/merge:** Taka + Max; squash.

#### H2-REANALYSIS-SEMANTICS — Docs: re-analysis / recompute semantics
- **Objective:** Specify that newly acquired evidence causes a **recompute** over the enlarged set — not a patch, append, or downstream override (INV-7) — and how iteration terminates.
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `docs/noesis-reanalysis-semantics`   · **Owner:** Claude + Max
- **Scope:** recompute definition; supersede-not-edit rule; iteration/termination; audit events emitted per re-analysis.
- **Out of scope:** implementation; caching strategy (that is Phase 6).
- **DoD:** doc; explicit "single coherent judgment over all evidence" guarantee; audit-event list for Phase 5.
- **Validation:** manual vs ADR-0004 I4 and §"NOESIS Re-analysis".   · **Deps:** H2-ASSESSMENT-MODEL, H2-HYPOTHESES, H2-SOURCEDEP-EVAL, H1-ACQUISITION-CONTRACT.   · **Review/merge:** Taka + Max; squash.

### 5.4 Phase 3 — NOEMA Runtime (contracts & specs)

Governance is enforced **architecturally, not by prompting** (INV-2). All Phase 3 tasks
are `RAGfish` docs/specs; runtime code is `future / downstream`.

#### H3-NOEMA-ISOLATION — Docs: isolated Noema invocation + capability-isolation spec
- **Objective:** Specify Noema as a separate capability context invoked with `investigation_result` **only** — no evidence-store credentials, no retrieval bindings, no outbound provider-API capability (INV-3, INV-4, B2, B4).
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `docs/noema-invocation-isolation`   · **Owner:** Claude + Max
- **Scope:** invocation contract; input surface = `investigation_result`; enumerated absent capabilities; enforcement mechanism per capability (credential absent / binding absent / network policy / process boundary).
- **Out of scope:** the narrative prompt; Swift/process implementation; the hosting decision (H3-ADR-NOEMA-HOSTING).
- **DoD:** spec; every INV-4 capability shown absent with a named mechanism (not "prompt"); cites #33 matrix + #34.
- **Validation:** cross-check #33, ADR-0004 §"Trust Boundaries" + §"Capability Restrictions".   · **Deps:** #33, #34.   · **Review/merge:** Taka + Max; squash.

#### H3-NARRATIVE-CONTRACT — Docs: presentation / narrative transformation contract
- **Objective:** Define exactly what Noema may do — reorder, summarise, explain, format; carry through assessment states, confidence, uncertainty, competing hypotheses, limitations **exactly as received**.
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `docs/noema-narrative-contract`   · **Owner:** Claude
- **Scope:** permitted transformations; "state the limitation, do not acquire the fact" rule; no new claims; no confidence change.
- **Out of scope:** prompt; UI rendering.
- **DoD:** contract doc; permitted/forbidden lists; consistent with H3-OUTPUT-VALIDATION.
- **Validation:** manual vs ADR-0004 §"NOEMA".   · **Deps:** #34, H3-NOEMA-ISOLATION.   · **Review/merge:** Taka + Max; squash.

#### H3-OUTPUT-VALIDATION — Feature: Noema output-validation spec
- **Objective:** A checkable spec that Noema output introduced no new factual claim and did not raise confidence above the `investigation_result` — the verification-stage check ADR-0004 references (regression: #35).
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `feature/noema-output-validation`   · **Owner:** Codex (from Claude spec)
- **Scope:** validation rules; claim-set comparison; confidence-ceiling check; failure codes.
- **Out of scope:** downstream harness; UI.
- **DoD:** spec + example pass/fail fixtures; maps to #35 new-claim + confidence-escalation cases.
- **Validation:** `rg -n "claim|confidence|reject|fail" docs/noema/**`; fixture review.
- **Deps:** #34, #35, H3-NOEMA-ISOLATION.   · **Review/merge:** Taka + Max; Codex; squash.

#### H3-ADR-NOEMA-HOSTING — ADR-0006 (Noema): where Noema-layer narrative work runs
- **Objective:** ADR-0004 leaves open whether Noema-layer work runs as a constrained task inside `noema-agent` or as its own context. Decide it — without weakening INV-5.
- **Target repo:** `rag-fish/RAGfish`   · **Branch:** `docs/adr-0006-noema-hosting`   · **Owner:** Claude → Max → Taka
- **Scope:** options; decision + rationale; how INV-4 stays "can't" under the chosen hosting; explicit statement that epistemic Noema ≠ `noema-agent` regardless of co-location.
- **Out of scope:** implementation.
- **DoD:** ADR merged; INV-5 preserved; capability-isolation mechanism named.
- **Validation:** Max sign-off; cross-check ADR-0004 I9 + Rejected Alternative D.
- **Deps:** H3-NOEMA-ISOLATION.   · **Review/merge:** Taka accepts; squash.

### 5.5 Phase 4 — Human-Gated External Acquisition (design only)

No automatic external acquisition. No credentials, no provider integration, no runtime
Human Gate in this phase — design artifacts only.

#### H4-SEALED-GATEWAY — Docs: sealed acquisition-gateway design
- **Objective:** Design the single choke point through which any external acquisition must pass, sealed so it cannot run without a valid Human Gate approval record (INV-2, INV-6).
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/sealed-acquisition-gateway`   · **Owner:** Claude
- **Scope:** gateway responsibilities; the approval-record precondition; provenance capture on the way back; audit events; failure-closed behaviour.
- **Out of scope:** endpoints, credentials, provider SDKs, runtime code.
- **DoD:** design doc; "no approval record ⇒ no acquisition" as a structural property; audit-event list.
- **Validation:** manual vs ADR-0004 §"Human Gate" + INV-2/INV-6.
- **Deps:** H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H1-ADR-ACQ-LOCUS.   · **Review/merge:** Taka + Max; squash.

#### H4-APPROVAL-ENFORCEMENT — Docs: human-approval enforcement design ("can't rather than won't")
- **Objective:** Specify the mechanisms (schema validation, type constraints, absent credentials, separate context) that make bypassing the Human Gate *impossible*, not merely disallowed.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/human-approval-enforcement`   · **Owner:** Claude + Max
- **Scope:** enforcement mechanism per bypass vector; mapping to #33 controls; defense-in-depth prompt layer noted as non-sole.
- **Out of scope:** implementation.
- **DoD:** doc; every known bypass vector has a non-prompt mechanism; maps to #35 "external acquisition without approval" case.
- **Validation:** manual vs INV-2; Max sign-off.
- **Deps:** H1-HUMANGATE-RECORD, H4-SEALED-GATEWAY.   · **Review/merge:** Taka + Max; squash.

#### H4-EXECUTOR-SELECTION — Docs: acquisition executor selection
- **Objective:** Apply ADR-0005 (H1-ADR-ACQ-LOCUS) to specify which component executes an approved acquisition and its capability posture.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/acquisition-executor-selection`   · **Owner:** Claude
- **Scope:** executor responsibilities; scoped to the approved acquisition only; no standing capability.
- **Out of scope:** credentials; provider choice; implementation.
- **DoD:** doc consistent with ADR-0005; scope-limited executor.
- **Validation:** cross-check ADR-0005.   · **Deps:** H1-ADR-ACQ-LOCUS, H4-SEALED-GATEWAY.   · **Review/merge:** Taka + Max; squash.

#### H4-PROVIDER-TEMPLATE — Docs: provider-agnostic acquisition integration template
- **Objective:** A template for adding a provider later (what a provider integration must supply: provenance, trust metadata, scoping) — **no actual provider, no credentials**.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/provider-integration-template`   · **Owner:** Claude
- **Scope:** required provider-supplied fields; provenance/trust obligations; scoping obligations; a "not yet integrated" status list.
- **Out of scope:** Grok or any named provider integration; API keys; endpoints.
- **DoD:** template doc; explicitly states no provider is integrated and each integration needs its own issue + review.
- **Validation:** manual vs ADR-0004 Out-of-Scope list.   · **Deps:** H4-SEALED-GATEWAY, H4-EXECUTOR-SELECTION.   · **Review/merge:** Taka + Max; squash.

#### H4-ACQ-RETURN-TRIGGER — Docs: acquisition-artifact return + re-analysis trigger contract
- **Objective:** Specify how an acquisition result returns into Noesis and triggers a recompute (INV-7), not an append.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/acquisition-return-reanalysis`   · **Owner:** Claude + Max
- **Scope:** return path; re-analysis trigger; audit events; iteration bounds.
- **Out of scope:** implementation.
- **DoD:** contract doc; consistent with H2-REANALYSIS-SEMANTICS.
- **Validation:** manual vs ADR-0004 I4.   · **Deps:** H4-SEALED-GATEWAY, H2-REANALYSIS-SEMANTICS.   · **Review/merge:** Taka + Max; squash.

### 5.6 Phase 5 — Trust / Evidence / Audit Integration

Reuse existing assets (RAGpack v1.3, `spec-audit-pipeline.md`, `spec-g3-promotion-gate.md`,
ADR-0003 G1–G6). Do not reinvent implemented mechanisms.

#### H5-EVIDENCE-AUDIT-RECONCILE — Audit: reconcile RAGpack provenance / integrity / validation reports with the Evidence contract
- **Objective:** Cross-repo audit that the Evidence contract (H1-EVIDENCE-CONTRACT) is consistent with what RAGpack v1.3 and the pipeline already produce; identify gaps only.
- **Repo:** `rag-fish/RAGfish` (audit doc; pipeline follow-ups filed separately)   · **Branch:** `audit/evidence-provenance-reconcile`   · **Owner:** Claude
- **Scope:** field-by-field reconciliation; integrity-hash coverage; validation-report linkage; gap list.
- **Out of scope:** changing pipeline code; new schemas.
- **DoD:** audit finding doc; explicit KEEP/GAP list; no downstream code changes.
- **Validation:** cross-check RAGpack v1.3 schema, `spec-g3-promotion-gate.md`, ADR-0003.
- **Deps:** H1-EVIDENCE-CONTRACT.   · **Review/merge:** Taka; squash.

#### H5-TRUST-CONTEXT-SCHEMA — Docs: trust context schema (evolved)
- **Objective:** Deliver the Hermes Theme-2 trust context schema, reconciled so trust stays independent of Noesis calibrated confidence (INV-10).
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/trust-context-schema`   · **Owner:** Claude
- **Scope:** provenance, corpus quality, freshness, validation history, source-independence ref; carried in Route Contract + recorded in evidence/audit; explicit "not confidence" note.
- **Out of scope:** trust algorithm in code; pipeline changes.
- **DoD:** schema doc; trust/confidence separation explicit; consumed at inference from pre-computed metadata (ADR-0002 runtime principle).
- **Validation:** cross-check ADR-0002 §3, ADR-0003 Knowledge plane.
- **Deps:** H1-EVIDENCE-CONTRACT, H5-EVIDENCE-AUDIT-RECONCILE.   · **Review/merge:** Taka + Max; squash.

#### H5-SIGNED-EVIDENCE-PACKAGES — Docs: Ed25519 evidence-package applicability
- **Objective:** Decide how `spec-audit-pipeline.md`'s signed evidence packages apply to `investigation_result` and the Human Gate approval record.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/signed-evidence-packages-epistemic`   · **Owner:** Claude
- **Scope:** which epistemic artifacts get packaged/signed; content-redaction defaults; offline verifiability.
- **Out of scope:** implementation; key management.
- **DoD:** doc; reuses existing evidence-package format; no new crypto design.
- **Validation:** cross-check `spec-audit-pipeline.md`, ADR-0003 §"Audit storage".
- **Deps:** #34, H1-HUMANGATE-RECORD, H5-EVIDENCE-AUDIT-RECONCILE.   · **Review/merge:** Taka; squash.

#### H5-AUDITCHAIN-EPISTEMIC — Docs: audit-chain integration for epistemic-lifecycle events
- **Objective:** Extend ADR-0003 G6 (audit completeness) to cover every epistemic step: assessment, Human Gate approve/decline, each acquisition, each re-analysis, the `investigation_result` handoff, Noema validation. A missing event invalidates the run.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/epistemic-audit-chain`   · **Owner:** Claude
- **Scope:** event taxonomy; hash-chain placement; G6 extension text; ordering guarantees.
- **Out of scope:** implementation; canonical-JSON conformance vectors (downstream).
- **DoD:** doc; complete event list; cites ADR-0003 G6; feeds Phase 6 observability.
- **Validation:** cross-check ADR-0003, ADR-0004 §"Mapping onto governance rules G1–G6".
- **Deps:** #34, H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H2-REANALYSIS-SEMANTICS.   · **Review/merge:** Taka + Max; squash.

#### H5-SOURCE-INDEPENDENCE-TRUST — Docs: source independence in RAGpack trust metadata
- **Objective:** Add a source-independence/dependency signal to RAGpack trust metadata (spec only; pipeline impl filed as a follow-up).
- **Repo:** `rag-fish/RAGfish` (+ `noesisnoema-pipeline` follow-up)   · **Branch:** `docs/ragpack-source-independence`   · **Owner:** Claude
- **Scope:** metadata field spec; relation to H1-SOURCE-DEP-MODEL; versioning note for RAGpack.
- **Out of scope:** pipeline implementation (separate issue, `noesisnoema-pipeline`).
- **DoD:** spec; RAGpack version-bump plan; downstream follow-up issue identified (not created here).
- **Validation:** cross-check RAGpack v1.3 schema.
- **Deps:** H1-SOURCE-DEP-MODEL, H5-TRUST-CONTEXT-SCHEMA.   · **Review/merge:** Taka + Max; squash.

### 5.7 Phase 6 — Observability / Performance

#### H6-27-AMEND — Docs: amend observability model v0 (#27) for the epistemic lifecycle
- **Objective:** Re-scope #27 so it covers the epistemic lifecycle. **This is the task that carries the #27 amendment; #27 itself is not edited before this task is approved.**
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/observability-model-v0-epistemic`   · **Owner:** Claude
- **Scope:** add epistemic trace points (Noesis assessment, Human Gate, acquisition, re-analysis, `investigation_result`, Noema validation) to the observability model; update #27's stale dependency references ("Issue 4 / Issue 7" → current tasks); keep the four-layer coverage.
- **Out of scope:** observability tooling; APM; editing #27's body in this phase (do it when this task is scheduled).
- **DoD:** amended model doc; #27's stale refs replaced; four layers still covered; no code.
- **Validation:** `rg -n "trace_id|request_id|audit_id|decision_id|investigation_id" docs/noema/**`; manual vs ADR-0004.
- **Deps:** #33, #34, H5-AUDITCHAIN-EPISTEMIC.   · **Review/merge:** Taka; squash.

#### H6-EPISTEMIC-TRACE-IDS — Docs: epistemic-lifecycle trace identifiers
- **Objective:** Define `investigation_id`, `assessment_id`, `gate_approval_id`, `acquisition_id`, `reanalysis_id` — scope, cardinality, relationships to `trace_id` / `request_id` / `audit_id` / `decision_id`.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/epistemic-trace-identifiers`   · **Owner:** Claude
- **Scope:** identifier definitions; parent/child relationships; one `investigation_id` spanning re-analysis iterations.
- **Out of scope:** implementation.
- **DoD:** doc; consistent with existing #27 identifiers; every epistemic audit event carries the right IDs.
- **Validation:** manual vs H5-AUDITCHAIN-EPISTEMIC.   · **Deps:** H6-27-AMEND.   · **Review/merge:** Taka; squash.

#### H6-DECISION-AUDIT-RELATIONSHIP — Docs: decision/audit relationship model
- **Objective:** Update the Hermes trace relationship model (route events → decision logs → PR evidence → validation reports) to include the epistemic artifacts and the nine-stage overlay.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/decision-audit-relationship`   · **Owner:** Claude
- **Scope:** relationship graph; sync vs async boundary for epistemic events; decision-log threshold for investigations.
- **Out of scope:** implementation; unified decision-log persistence (future ADR per ADR-0002 §9).
- **DoD:** doc; graph covers epistemic + development evidence; async-by-default preserved.
- **Validation:** cross-check ADR-0002 §7–§9, ADR-0003 G6.   · **Deps:** H6-27-AMEND, H5-AUDITCHAIN-EPISTEMIC.   · **Review/merge:** Taka; squash.

#### H6-LATENCY-BUDGET — Docs: latency budget specification (extended)
- **Objective:** Deliver the Hermes latency budget, extended with Noesis assessment, re-analysis *recompute* cost, and Noema narrative budgets.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/latency-budget-spec`   · **Owner:** Claude (Codex benchmarks later, downstream)
- **Scope:** per-stage budgets incl. epistemic stages; recompute-vs-append cost note; local-first zero-remote-latency assumption (INV-9).
- **Out of scope:** benchmark implementation (downstream).
- **DoD:** budget doc; epistemic stages included; consistent with ADR-0002 runtime principles.
- **Validation:** manual vs ADR-0002 §"Runtime Principles".   · **Deps:** H2-REANALYSIS-SEMANTICS, H3-NARRATIVE-CONTRACT.   · **Review/merge:** Taka + Max; squash.

#### H6-PERF-CONTRACTS — Docs: performance contracts (policy cache, trust pre-computation, async paths)
- **Objective:** Deliver the KEEP'd Hermes performance deliverables as one contract set, updated for the epistemic lifecycle (e.g. re-analysis must not be silently cached in a way that violates INV-7).
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/performance-contracts`   · **Owner:** Claude
- **Scope:** policy cache design + invalidation; trust pre-computation contract; async evidence/audit write path; explicit "recompute is not cache-elided" rule.
- **Out of scope:** implementation.
- **DoD:** contract doc; all three sub-contracts present; INV-7 protected against caching shortcuts.
- **Validation:** cross-check ADR-0002 §"Runtime Principles", ADR-0003.   · **Deps:** #33, H5-TRUST-CONTEXT-SCHEMA, H5-AUDITCHAIN-EPISTEMIC.   · **Review/merge:** Taka + Max; squash.

### 5.8 Phase 7 — Multi-model Orchestration

Orchestration must not bypass the Human Gate for external acquisition. Routing authority
stays separate from execution capability (ADR-0000 §2, §6).

#### H7-ROUTE-CONTRACT-V1 — ADR-0007 (Noema) + Docs: Route Contract v1 (evolved)
- **Objective:** Evolve the Hermes Route Contract to declare whether a request is an investigation and whether external acquisition is in scope *pending the Human Gate*, and to carry `investigation_id`. Also produce the ADR that fixes Route Contract v1.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/route-contract-v1`   · **Owner:** Claude + Max
- **Scope:** ADR-0007 (Noema) + contract doc; fields: selected path, why, confidence, trust context, approval requirements, investigation flag, acquisition-in-scope-pending-gate, `investigation_id`; "the contract declares, it does not execute" preserved.
- **Out of scope:** implementation in `noema-agent`; transport/serialization (future ADR).
- **DoD:** ADR + contract merged; ADR-0002 §4 Route Contract semantics preserved and extended; maps onto the epistemic lifecycle.
- **Validation:** cross-check ADR-0002 §4, ADR-0004 §"Mapping onto the nine-stage pipeline".
- **Deps:** #33, #34, H1-ADR-ACQ-LOCUS.   · **Review/merge:** Taka accepts; Max reviews; squash.

#### H7-EXEC-MODE-POLICY — Docs: execution mode selection policy
- **Objective:** Deliver the Hermes execution-mode policy (local / remote / tool / human), adding that external acquisition is never a selectable mode without a Human Gate approval.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/execution-mode-policy`   · **Owner:** Claude
- **Scope:** selection criteria; the acquisition exclusion rule; human-executor mode.
- **Out of scope:** implementation.
- **DoD:** policy doc; acquisition-exclusion rule explicit.
- **Validation:** cross-check ADR-0002 §5, INV-6.   · **Deps:** H7-ROUTE-CONTRACT-V1.   · **Review/merge:** Taka + Max; squash.

#### H7-LOCAL-FIRST-OPTIN — Docs: local-first default + remote opt-in contract
- **Objective:** Reaffirm and specify INV-9: local is default and non-degraded; remote is opt-in; never a silent fallback.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/local-first-remote-optin`   · **Owner:** Claude
- **Scope:** default-path spec; opt-in trigger; no-silent-fallback rule; zero-runtime-human-gate for ordinary queries preserved.
- **Out of scope:** implementation.
- **DoD:** contract doc; consistent with ADR-0001, ADR-0003.
- **Validation:** cross-check ADR-0003 §"governance without runtime humans".   · **Deps:** H7-ROUTE-CONTRACT-V1.   · **Review/merge:** Taka + Max; squash.

#### H7-ROUTING-AUTHORITY-INVARIANT — ADR-0008 (Noema): routing authority ≠ execution capability
- **Objective:** Record as an ADR that orchestration/routing never gains execution or acquisition authority, and can never bypass the Human Gate.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/adr-0008-routing-authority`   · **Owner:** Claude → Max → Taka
- **Scope:** invariant statement; relation to ADR-0000 §2/§6 and ADR-0004 INV-6; enforcement note.
- **Out of scope:** implementation.
- **DoD:** ADR merged; invariant explicit and testable (feeds #35-style cases).
- **Validation:** Max sign-off; cross-check ADR-0000 Anti-Patterns §6.
- **Deps:** H7-ROUTE-CONTRACT-V1, H4-APPROVAL-ENFORCEMENT.   · **Review/merge:** Taka accepts; squash.

#### H7-PROVIDER-MODEL-SELECTION — Docs: provider / model selection contract
- **Objective:** Specify explicit, non-silent model/provider selection (ADR-0000 §6 Model Neutrality) within the evolved Route Contract.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/provider-model-selection`   · **Owner:** Claude
- **Scope:** explicit-selection rule; no silent switching/upgrade; disclosure requirement; recorded in evidence.
- **Out of scope:** implementation; provider credentials.
- **DoD:** contract doc; consistent with ADR-0000 §6 and Anti-Pattern §2.
- **Validation:** cross-check ADR-0000.   · **Deps:** H7-EXEC-MODE-POLICY.   · **Review/merge:** Taka + Max; squash.

### 5.9 Phase 8 — Final UAT / Release

Release/publication occurs **only after** final UAT passes.

#### H8-INTEGRATION-UAT-PLAN — Docs: cross-repository integration UAT plan
- **Objective:** Define how the full epistemic lifecycle is exercised end-to-end across the four repos before release.
- **Repo:** `rag-fish/RAGfish`   · **Branch:** `docs/integration-uat-plan`   · **Owner:** Claude + Taka
- **Scope:** UAT scenarios covering Evidence → NOESIS → Human Gate → (acquisition) → re-analysis → `investigation_result` → NOEMA; per-repo responsibilities; entry/exit criteria.
- **Out of scope:** running the UAT; downstream test harnesses.
- **DoD:** plan doc; every INV mapped to at least one scenario.
- **Validation:** manual invariant coverage check.
- **Deps:** all Phase 2–7 contract tasks.   · **Review/merge:** Taka; squash.

#### H8-GOV-REGRESSION-GATE — Test: governance regression suite execution gate
- **Objective:** The pass/fail gate that runs #35's cases against the integrated system.
- **Repo:** `rag-fish/RAGfish` (gate definition) → downstream (execution)   · **Branch:** `test/governance-regression-gate`   · **Owner:** Codex
- **Scope:** gate definition; wiring #35 cases to a runnable suite; pass criteria = every critical invariant fails closed.
- **Out of scope:** authoring new governance cases (that is #35).
- **DoD:** gate defined; suite runnable; green required for release.
- **Validation:** suite run against integration build.
- **Deps:** #35, H8-INTEGRATION-UAT-PLAN.   · **Review/merge:** Taka + Max; squash.

#### H8-CAPABILITY-BOUNDARY-GATE — Test: capability-boundary test gate
- **Objective:** Prove the "can't rather than won't" boundaries hold in the built system (Noema has no evidence store / retrieval / external API / confidence-raise path; acquisition sealed without approval).
- **Repo:** `rag-fish/RAGfish` (gate definition) → downstream (execution)   · **Branch:** `test/capability-boundary-gate`   · **Owner:** Codex
- **Scope:** boundary probes per INV-2/INV-4/INV-6; distinguishes prompt refusal from architectural inability.
- **Out of scope:** new spec authoring.
- **DoD:** gate defined; every INV-4 capability probed and shown absent by architecture.
- **Validation:** probe run against integration build.
- **Deps:** #35, H3-OUTPUT-VALIDATION, H8-INTEGRATION-UAT-PLAN.   · **Review/merge:** Taka + Max; squash.

#### H8-FINAL-UAT — Final human UAT by Taka
- **Objective:** Taka's governance acceptance of the integrated system.
- **Repo:** all   · **Branch:** n/a (review activity; sign-off recorded as an evidence artifact)   · **Owner:** Taka
- **Scope:** execute H8-INTEGRATION-UAT-PLAN; confirm regression + capability gates green; record sign-off.
- **Out of scope:** code changes.
- **DoD:** recorded Taka sign-off; all gates green.
- **Validation:** gate reports attached.
- **Deps:** H8-GOV-REGRESSION-GATE, H8-CAPABILITY-BOUNDARY-GATE.   · **Review/merge:** Taka.

#### H8-RELEASE — Release tags + release notes
- **Objective:** Tag releases across repos and write release notes describing the epistemic-governance capability.
- **Repo:** all   · **Branch:** `docs/release-notes-hermes` (notes) + tags per repo   · **Owner:** Taka (Claude drafts notes)
- **Scope:** version tags; release notes; changelog linking ADR-0004 → Phase 0–8 evidence.
- **Out of scope:** publication (H8-PUBLICATION).
- **DoD:** tags pushed; notes merged; only after H8-FINAL-UAT.
- **Validation:** tag + notes review.
- **Deps:** H8-FINAL-UAT.   · **Review/merge:** Taka.

#### H8-PUBLICATION — rag.fish update + X / LinkedIn / Facebook publication package
- **Objective:** External communication of the release, using engineering/business framing (ADR-0002 §"External Positioning").
- **Repo:** `rag-fish/RAGfish` + rag.fish website   · **Branch:** `docs/publication-package-hermes`   · **Owner:** Claude/Max draft → **Taka approves and posts**
- **Scope:** rag.fish page update; X publication package; LinkedIn post; Facebook post; all using external positioning (no philosophy-first framing, no codename-as-descriptor).
- **Out of scope:** posting before H8-RELEASE; sharing internal codenames externally.
- **DoD:** drafts approved by Taka; posted only after release tags exist.
- **Validation:** Taka review; external-positioning checklist (ADR-0002).
- **Deps:** H8-RELEASE.   · **Review/merge:** Taka approves and executes the posts.

### 5.10 Charter milestone remap

| Charter milestone | Maps to |
|---|---|
| M1 — Architecture definition | Complete (ADR-0001/0002/0003) + ADR-0004 (Phase 0) |
| M2 — Governance pipeline contracts | Phase 0 (#33, #34, #35) + Phase 1 |
| M3 — Trust and corpus quality | Phase 5 |
| M4 — Orchestration layer | Phase 7 |
| M5 — Observability | Phase 6 (observability tasks) |
| M6 — Performance hardening | Phase 6 (performance tasks) |
| *(new)* Epistemic runtime | Phases 2, 3, 4 |
| *(new)* Integration & release | Phase 8 |

---

## 6. Project Charter v2 — status

**No change required.** `PROJECT-CHARTER-v2.md` is left untouched. Rationale:

- ADR-0004 is **additive** — it introduces an epistemic dimension and does not contradict any Charter Vision statement, Mission bullet, Project Principle, Repository Responsibility, or Success Criterion.
- Every Charter principle is *reinforced* by ADR-0004: "Governance before autonomy" ↔ INV-1/INV-2; "Evidence before intelligence" ↔ INV-3/audit-chain; "Contracts before implementation" ↔ INV-8; "Human approval is explicit" ↔ INV-6; "Trust is separate from confidence" ↔ INV-10; "Single responsibility per layer" ↔ NOESIS/NOEMA split.
- The six Core Themes are all KEEP (see §3.1).
- The Charter's "read alongside" list cites only ADR-0001/ADR-0002 and omits ADR-0003 **and** ADR-0004. This is **pre-existing documentation drift** (the Charter was not updated when ADR-0003 merged either), not a contradiction introduced by ADR-0004. Fixing it is out of scope for this rebaseline and is better done as its own small `docs/` task (see §9 recommendations).

If architecture review disagrees and wants ADR-0004 explicitly anchored in the Charter, the **minimal** amendment is: add ADR-0003 and ADR-0004 to the "read alongside" list and one sentence pointing to this roadmap — nothing more.

---

## 7. Agent assignment rationale

| Agent | Gets | Why |
|---|---|---|
| **Claude Code CLI** | ADRs, governance/capability contracts, cross-repo audits, roadmap, most Phase 1–7 documentation | Reasons across the full architecture; translates decisions into durable docs. |
| **Codex CLI** | #34 (`investigation_result` JSON Schema), #35 (regression cases), H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H3-OUTPUT-VALIDATION, Phase 8 gates | Focused schema/test/validator implementation from a settled spec. |
| **Max / ChatGPT** | Architecture review on every ADR/contract; co-owner of the NOESIS assessment model (H2-ASSESSMENT-MODEL, H2-HYPOTHESES) and enforcement design (H4-APPROVAL-ENFORCEMENT) | Architecture review + task/prompt/assessment design is Max's strength; the NOESIS epistemic model is design-heavy. |
| **Taka** | Prioritisation; review + merge of everything; ADR acceptance; H8-FINAL-UAT; H8-RELEASE; H8-PUBLICATION posting | Governance owner; release and external-communication authority. |

Assignments are per-task, not territorial (see §5 master table).

---

## 8. Dependency DAG

```
Phase 0:  #32(DONE) ──▶ #33 ──▶ #34 ──▶ #35
                          │       │       │
        ┌─────────────────┼───────┼───────┴───────────────┐
        │                 │       │                       │
        ▼                 ▼       ▼                       ▼
   ┌─ Phase 1 ─┐    ┌── Phase 2 ──┐              ┌── Phase 3 ──┐
   H1-EVIDENCE-      H2-NOESIS-                   H3-NOEMA-
   CONTRACT          CONTRACT                     ISOLATION
   H1-SOURCE-DEP  ─▶ H2-ASSESSMENT-MODEL          H3-NARRATIVE-CONTRACT
   H1-HUMANGATE-     H2-HYPOTHESES                H3-OUTPUT-VALIDATION ◀─(#35)
   RECORD            H2-SOURCEDEP-EVAL ◀──────────┐ H3-ADR-NOEMA-HOSTING
   H1-ACQUISITION-   H2-REANALYSIS-SEMANTICS      │
   CONTRACT          │                            │
   H1-ADR-ACQ-LOCUS  │  (H2-SOURCEDEP-EVAL needs H1-SOURCE-DEP-MODEL)
        │            │
        ├────────────┴──────────────┐
        ▼                           ▼
   ┌── Phase 4 ──┐            ┌── Phase 5 ──┐
   H4-SEALED-GATEWAY          H5-EVIDENCE-AUDIT-RECONCILE
   H4-APPROVAL-ENFORCEMENT    H5-TRUST-CONTEXT-SCHEMA
   H4-EXECUTOR-SELECTION      H5-SIGNED-EVIDENCE-PACKAGES
   H4-PROVIDER-TEMPLATE       H5-AUDITCHAIN-EPISTEMIC ◀─(H2-REANALYSIS-SEMANTICS)
   H4-ACQ-RETURN-TRIGGER ◀────(H2-REANALYSIS-SEMANTICS)
   H5-SOURCE-INDEPENDENCE-TRUST
        │                           │
        └─────────────┬─────────────┘
                      ▼
                ┌── Phase 6 ──┐
                H6-27-AMEND ──▶ H6-EPISTEMIC-TRACE-IDS
                          └───▶ H6-DECISION-AUDIT-RELATIONSHIP
                H6-LATENCY-BUDGET   H6-PERF-CONTRACTS
                      │
                      ▼
                ┌── Phase 7 ──┐
                H7-ROUTE-CONTRACT-V1 ──▶ H7-EXEC-MODE-POLICY ──▶ H7-PROVIDER-MODEL-SELECTION
                                    └──▶ H7-LOCAL-FIRST-OPTIN
                H7-ROUTING-AUTHORITY-INVARIANT ◀─(H4-APPROVAL-ENFORCEMENT)
                      │
                      ▼
                ┌── Phase 8 ──┐
                H8-INTEGRATION-UAT-PLAN ──▶ H8-GOV-REGRESSION-GATE ──┐
                                       └──▶ H8-CAPABILITY-BOUNDARY-GATE ──┤
                                                                         ▼
                                            H8-FINAL-UAT ──▶ H8-RELEASE ──▶ H8-PUBLICATION
```

**Acyclicity:** every dependency edge points from a lower phase number to an equal-or-higher
one, and each within-phase sub-graph is a tree/DAG (verified by inspection in §5.0). No cycles.

**No implementation before its governing spec:**
- #34 (schema) after #33 (governance contract); #35 (tests) after #34.
- H1-HUMANGATE-RECORD / H1-ACQUISITION-CONTRACT (schemas) after #33 + #34.
- H3-OUTPUT-VALIDATION (checkable spec) after #34 + #35 + H3-NOEMA-ISOLATION.
- All downstream runtime implementation is `future / downstream`, gated on the Phase 1–7 contract merging (§4 scope note).
- Phase 8 gates run only after the contracts and #35 exist; publication only after release.

---

## 9. Findings

### 9.1 Conflicts with ADR-0000 → ADR-0004

**None.** Cross-checked:

- **ADR-0000 (Human Sovereignty):** every phase preserves explicit invocation, routing authority with the human, execution transparency (audit-chain), human override (decline at the Human Gate), state-mutation consent (only Noesis mutates investigation state, within one invocation), model neutrality (H7-PROVIDER-MODEL-SELECTION), transparency over optimization (H6-PERF-CONTRACTS protects INV-7 against caching shortcuts). No Anti-Pattern is introduced — no autonomous loop, no silent model switch, no opaque routing, no auto-execution chain, no authority escalation.
- **ADR-0001 (four repos):** no repo boundary changes; all new contracts land in `RAGfish` first (cross-repo rule KEEP).
- **ADR-0002 (nine-stage pipeline):** the epistemic lifecycle is an overlay; Route Contract (Phase 7) extends ADR-0002 §4 without replacing it; trust-vs-confidence preserved.
- **ADR-0003 (four planes, G1–G6, zero runtime human gates for ordinary queries):** the Human Gate is scoped to the external trust boundary only (INV-6, INV-9); "can't rather than won't" aligns with "governance by capability, not supervision"; G6 is extended, not weakened (H5-AUDITCHAIN-EPISTEMIC).
- **ADR-0004 (incl. amendment `23b5736`):** INV-1…INV-7 are lifted directly from it; I11 (advisory artifacts) and I12 (human noesis ≠ NOESIS layer) are honoured — no task assigns governance authority to the NOESIS layer.

No task violates human sovereignty, "can't rather than won't", Noema capability isolation,
the `investigation_result`-only handoff, or contracts-before-implementation.

### 9.2 Stale / needs-attention existing issues

| Item | Issue | Recommendation (not actioned here) |
|---|---|---|
| **#27** depends on "Issue 4" / "Issue 7" (closed EPIC-era issues) and predates ADR-0004 | #27 | Amend via `H6-27-AMEND` in Phase 6: replace stale deps, add epistemic trace points + identifiers. Do **not** edit #27 now. |
| **ROADMAP-v2 Dependency Matrix** — "TBD" rows + "Issue 4/7" refs | — | Superseded by this roadmap's §5 catalog. v2 retained as history. |
| **#26 / #18** — backlog & sequencing docs | #26, #18 | Superseded by ROADMAP-v3 for future planning; keep as historical evidence. |
| **ADR-0001, ADR-0002, ADR-0003, ADR-0004 headers still say `Status: Proposed`** despite being merged and cited as authoritative | — | Status-hygiene task (own `docs/` PR): move merged ADRs to `Accepted`. Out of scope here. |
| **Charter v2 "read alongside" list** omits ADR-0003 and ADR-0004 | — | Minimal `docs/` touch-up task (§6). Out of scope here. |
| **GitHub Project #16** could not be inspected — `gh` token lacks `read:project` scope | — | Before Project population, run `gh auth refresh -s read:project` and verify Project #16 field IDs (see `human-governed-loop.md` § Open Questions). This roadmap is written to be sufficient to rebuild #16 without that access (§10). |

### 9.3 Project Charter v2 modification

**Not modified.** See §6 for the full rationale (ADR-0004 is additive; no contradiction;
the cross-reference gap is pre-existing drift).

---

## 10. Rebuilding GitHub Project #16 from this roadmap

Project #16 (Hermes) is **not touched** by this task. When architecture review approves this
roadmap, Project #16 can be rebaselined deterministically:

1. **Keep** the four Phase-0 items as issues: #33, #34, #35 stay as-is; #32 marked Done.
2. **Move** #27 into Phase 6 and mark it *blocked pending `H6-27-AMEND`*.
3. **Retire from the board** any item whose only content is the old Phase A–F sequence framing or the "Issue 4 / Issue 7" dependency rows (§3.4). Retire = remove from the active board, not delete the issue.
4. **Create** one issue per task in §5.0 (Phase 1 → Phase 8), using the metadata blocks in §5.1–§5.9 verbatim for the Issue body (Objective / Target Repo / Scope / Out of Scope / Branch / Owner Agent / Definition of Done / Validation / Dependencies / Review-Merge Rule).
5. **Set dependencies** per the §8 DAG.
6. **Status field:** #33 → `ready`; everything else → `proposed` until its dependencies merge.
7. Do **not** create the `future / downstream` runtime-implementation issues yet — they are scheduled as a later wave once Phase 1–7 contracts merge.

Issue creation and board population happen **after** this roadmap passes architecture
review — not in this task.

---

## 11. Next executable task

**#33 — Docs: define governance contract and capability matrix.**

- Its only dependency, **#32 (ADR-0004)**, is merged to `main` (PR #36, incl. amendment `23b5736`).
- It is the gating contract for #34, #35, and every Phase 1 task — nothing else can start correctly until the capability matrix and enforcement-mechanism mapping exist (INV-8).
- Repository analysis found **no blocking architectural dependency** ahead of it.
- Owner: **Claude CLI**. Branch: `docs/governance-capability-contract` (as already specified on #33).

---

## 12. Validation performed

1. **Cross-check against ADR-0000 → ADR-0004** — §9.1. No conflicts.
2. **Cross-check against Project Charter v2** — §6. No change required; ADR-0004 additive.
3. **Cross-check against the Human-Governed Development Loop** — every task in §5 carries the eleven required fields (Title, Description, Objective, Target Repo, Scope, Out of Scope, Branch, Owner Agent, Definition of Done, Validation, Dependencies, Review/Merge Rule); branch names follow `<type>/<short-name>`; merge owner is Taka throughout.
4. **Referenced existing issues verified to exist:** #27 (open), #32 (closed/merged), #33 (open), #34 (open), #35 (open), #25/#26 (closed). Verified via `gh issue view`.
5. **No task violates:** human sovereignty (INV-1), "can't rather than won't" (INV-2), Noema capability isolation (INV-4), `investigation_result`-only handoff (INV-3), contracts-before-implementation (INV-8) — checked per task in §5 and summarised in §9.1.
6. **Dependency graph checked for cycles** — §8. Acyclic: all edges go low-phase → high-phase; within-phase sub-graphs are DAGs.
7. **No planned implementation precedes its governing specification** — §8; downstream runtime work is explicitly deferred and gated (§4).
8. **Historical Hermes assets not silently discarded** — §3 classifies every asset; RETIRE list (§3.4) has four entries, each with a reason; ROADMAP-v2 retained unchanged as history.

---

## 13. Related documents

- [ADR-0004: Noesis / Noema Epistemic Separation](../adr/ADR-0004-noesis-noema-epistemic-separation.md) — architectural baseline
- [ADR-0003: Noema Governance Platform (v0.8)](../adr/ADR-0003-noema-governance-platform.md) — four planes, G1–G6
- [ADR-0002: Noema Governance Pipeline](../adr/ADR-0002-noema-governance-pipeline.md) — nine-stage pipeline, Route Contract
- [ADR-0001: Noema Architecture](../adr/ADR-0001-noema-architecture.md) — four-repo structure
- [ADR-0000: Product Constitution / Human Sovereignty](../../adr/adr-0000-product-constitution.md)
- [Project Charter v2](PROJECT-CHARTER-v2.md) — unchanged; anchors this roadmap
- [Execution Roadmap v2](EXECUTION-ROADMAP-v2.md) — superseded for future planning; retained as history
- [Human-Governed Development Loop](../human-governed-loop.md) — task fields, branch naming, templates
- [spec-audit-pipeline.md](../specs/spec-audit-pipeline.md) · [spec-g3-promotion-gate.md](../specs/spec-g3-promotion-gate.md) · [spec-runtime-v0.9-handover.md](../specs/spec-runtime-v0.9-handover.md)
- GitHub Issues: [#27](https://github.com/rag-fish/RAGfish/issues/27), [#33](https://github.com/rag-fish/RAGfish/issues/33), [#34](https://github.com/rag-fish/RAGfish/issues/34), [#35](https://github.com/rag-fish/RAGfish/issues/35)
- GitHub Project: [rag-fish Project #16 — Hermes](https://github.com/orgs/rag-fish/projects/16) (operational task schedule; not modified by this task)
