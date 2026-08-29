# Project Hermes: Execution Roadmap v3 — Epistemic-Governance Rebaseline

**Status:** Active (planning baseline; revision 2 addresses architecture-review findings 1–5; awaiting re-review by Max / ChatGPT and governance acceptance by Taka)
**Date:** 2026-08-29
**Scope:** All four Noema repos
**Governance owner:** Taka
**Owner agent (this document):** Claude Code CLI
**Architecture Review:** Max / ChatGPT
**Final Review / Merge Owner:** Taka
**Supersedes for future execution planning:** [EXECUTION-ROADMAP-v2](EXECUTION-ROADMAP-v2.md) — v2 is retained unchanged as historical evidence.
**Architectural baseline:** [ADR-0004: Noesis / Noema Epistemic Separation](../adr/ADR-0004-noesis-noema-epistemic-separation.md) (merged to `main` via PR #36, incl. amendment `23b5736` — invariants I11/I12).

**Revision 2 changelog (architecture-review corrections):**
1. Added the implementation + automated-validation layer to Phases 2–7 (17 implementation tasks, 12 automated validation/test tasks). Every runtime capability now has Spec/ADR → Implementation → Automated tests → Integration validation.
2. Every task has exactly **one Owner Agent**. Review roles are recorded separately (`Architecture Review`, `Final Review / Merge Owner`).
3. `Dependencies` now reference only executable/planning artifacts (issues, task IDs, merged ADRs/contracts). Architectural invariants moved to a new `Governed By` field.
4. Phase 8 gating strengthened — Final UAT is unreachable until all implementation + all automated tests + all three integration gates are complete.
5. Task catalog recalculated: **75 tasks**, DAG re-verified acyclic.

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
this roadmap is subordinate to them. Tasks reference these in their **Governed By** field
(never in **Dependencies** — see §5.0).

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

*(Unchanged from revision 1 — architecture review accepted the classification.)*

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
| Charter milestones **M1–M6** | **KEEP + remap** | M1 complete; M2–M6 remain valid coarse groupings. No contradiction with ADR-0004. | Mapping table in §5.11; Charter unchanged (§6). |
| Dependency-matrix rows referencing **"Issue 4" / "Issue 7"** | **RETIRE** | **Reason:** those refer to closed EPIC-era issues (#2–#5 vintage) that no longer correspond to active work. Stale pointers only. | Replaced by the Phase 0–8 DAG (§8). |
| Dependency-matrix "TBD" placeholder rows | **REPLACE** | Objective (sequence the themes into issues) is still valid, but the placeholder set is superseded by the concrete task catalog. | §5 task catalog. |
| #25 (charter), #26 / #18 (backlog & sequencing docs) | **KEEP (historical)** | Completed foundation work; ROADMAP-v3 supersedes #26/#18 *for future planning* without erasing them. | Historical evidence. |

### 3.3 Capability deliverables

| Hermes v2 deliverable | Class | Rationale | New home |
|---|---|---|---|
| **Route Contract v1** specification | **KEEP + MOVE** | Still the cognition ↔ execution boundary. ADR-0004 maps onto it. Must *evolve* to carry an investigation flag, "external acquisition in scope pending Human Gate", and `investigation_id` linkage. | Phase 7 · `H7-ROUTE-CONTRACT-V1` (spec) + `H7-IMPL-ROUTE-CONTRACT` (impl) |
| **Human approval gate schema** (generic) | **REPLACE** | **Superseded by** (a) ADR-0004's scoped **Human Gate** approval-record schema for the external trust boundary, and (b) ADR-0003's existing **Human Decision Gate** for policy changes / pack promotion (already in place). A third generic schema would be ambiguous and redundant. | Phase 1 · `H1-HUMANGATE-RECORD` (+ existing ADR-0003 gate, KEEP) |
| Policy enforcement contract (`noema-agent`) | **KEEP + MOVE** | Concept unchanged; sequenced after the governance contract (#33). | Phase 6 · `H6-PERF-CONTRACTS` (spec) + `H6-IMPL-CACHING-ASYNC` (impl) |
| Governance audit tooling | **KEEP + MOVE** | Folds into audit-chain + evidence-package work. | Phase 5 · `H5-AUDITCHAIN-EPISTEMIC` (spec) + `H5-IMPL-AUDIT-EMISSION` / `H5-TEST-AUDITCHAIN-VERIFY` |
| **Trust context schema** | **KEEP + MOVE** | Still required. Must reconcile with Noesis *calibrated confidence*, which ADR-0004 keeps separate from trust (INV-10). | Phase 5 · `H5-TRUST-CONTEXT-SCHEMA` (spec) + `H5-IMPL-TRUST-CONTEXT` |
| **RAGpack trust metadata standard** | **KEEP (largely DONE)** | RAGpack v1.3 already implemented (ADR-0003). Extend only for source-independence signal. | Phase 5 · `H5-SOURCE-INDEPENDENCE-TRUST` (spec) + `H5-IMPL-PROVENANCE-DEPENDENCY` |
| **Evidence artifact schema** (single catch-all) | **REPLACE** | **Superseded:** ADR-0004 distinguishes three artifact classes with different capability rules — *Evidence* (Noesis input), *`investigation_result`* (handoff, no raw evidence), *audit-chain records*. One schema cannot serve all three without breaking the capability matrix. | Phase 0 · #34 (handoff) + Phase 1 · `H1-EVIDENCE-CONTRACT` (input) + Phase 5 · audit |
| Decision log specification | **KEEP + MOVE** | ADR-0002 §9 + ADR-0003 G6 stand. Extend with epistemic-lifecycle events. | Phase 6 · `H6-DECISION-AUDIT-RELATIONSHIP` |
| Validation report format (corpus / retrieval quality) | **KEEP** | `spec-g3-promotion-gate.md` exists and is unchanged by ADR-0004. Reconcile references only. | Phase 5 · `H5-EVIDENCE-AUDIT-RECONCILE` |
| Async evidence write path | **KEEP + MOVE** | Performance requirement unchanged. | Phase 6 · `H6-PERF-CONTRACTS` + `H6-IMPL-CACHING-ASYNC` |
| Policy cache design | **KEEP + MOVE** | Unchanged. | Phase 6 · `H6-PERF-CONTRACTS` + `H6-IMPL-CACHING-ASYNC` |
| Trust pre-computation contract | **KEEP + MOVE** | Unchanged. | Phase 6 · `H6-PERF-CONTRACTS` + `H5-IMPL-PROVENANCE-DEPENDENCY` |
| **Latency budget** specification | **KEEP + MOVE + extend** | Add budgets for Noesis assessment, re-analysis *recompute*, and Noema narrative. | Phase 6 · `H6-LATENCY-BUDGET` (spec) + `H6-TEST-BENCHMARKS` |
| **Observability model v0 (#27)** | **KEEP + AMEND + MOVE** | Needs new identifiers and trace points for the epistemic lifecycle. #27 is **not modified in this task** — see §9.2. | Phase 6 · `H6-27-AMEND` |
| Trace relationship model (route events → decision logs → PR evidence → validation reports) | **KEEP + extend** | Add Noesis assessment / Human Gate / acquisition / re-analysis / `investigation_result` / Noema validation. | Phase 6 · `H6-DECISION-AUDIT-RELATIONSHIP` |
| Sync vs async observability boundary | **KEEP** | Unchanged. | Phase 6 |
| Stage-level trace format for the nine pipeline stages | **KEEP** | Nine stages retained; epistemic dimension is an overlay. | Phase 6 · `H6-IMPL-TRACE-EMISSION` |
| Execution mode selection policy (local / remote / tool / human) | **KEEP + MOVE** | Unchanged; add: external acquisition is never a selectable execution mode without a Human Gate approval. | Phase 7 · `H7-EXEC-MODE-POLICY` |
| Local-first routing default / remote opt-in contract | **KEEP + MOVE** | ADR-0004 explicitly preserves it (INV-9). Reaffirm. | Phase 7 · `H7-LOCAL-FIRST-OPTIN` + `H7-IMPL-ROUTING-CHANGES` |

### 3.4 RETIRE summary (with reasons)

1. **Execution Order Phase A–F sequence** — replaced by the epistemic-lifecycle-driven Phase 0–8. The linear order would place downstream capability work ahead of the NOESIS/NOEMA contracts it depends on (INV-8 violation). Phase rationale is preserved, not lost.
2. **Generic "human approval gate schema" deliverable** — ADR-0004 replaced the generic notion with a *scoped* Human Gate (external trust boundary) approval-record; ADR-0003 already owns the policy/pack Human Decision Gate. A third generic artifact is ambiguous and redundant.
3. **Single catch-all "evidence artifact schema" deliverable** — ADR-0004 splits evidence into three artifact classes with incompatible capability rules; a unified schema would violate the capability matrix (INV-4).
4. **Dependency-matrix references to "Issue 4 / Issue 7"** — closed EPIC-era issues that no longer map to active work.

Nothing else is retired. Every other Hermes asset is KEEP or MOVE.

---

## 4. Phase model (Phase 0 → Phase 8)

Every phase from 2 onward now contains a full **Spec/ADR → Implementation → Automated
validation → Integration validation** chain (integration validation where the capability
crosses a repo boundary or a governance boundary).

| Phase | Name | Produces | Gate to exit (all must be merged/green) |
|---|---|---|---|
| **0** | Epistemic Governance Foundation | governance contract, capability matrix, `investigation_result` v0.1, governance regression cases | #33, #34, #35 merged |
| **1** | Evidence & Acquisition Contracts | Evidence/provenance contract, source-dependency model, Human Gate approval-record schema, external acquisition request/result contract, ADR-0005 (acquisition execution locus) | all Phase 1 specs + schemas + ADR-0005 merged |
| **2** | NOESIS Runtime | 5 specs + NOESIS runtime impl, assessment/uncertainty structures impl, source-dependency eval impl, recompute impl, unit tests | all Phase 2 specs merged; all Phase 2 impl merged; H2 unit tests green |
| **3** | NOEMA Runtime | 4 specs/ADR + isolated Noema context impl, output-validator impl, capability-isolation tests, validator unit tests | all Phase 3 specs + ADR-0006 merged; impl merged; H3 tests green |
| **4** | Human-Gated External Acquisition | 5 designs + Human Gate enforcement impl, sealed gateway impl, provider adapter impl, fail-closed integration tests, gateway unit tests | all Phase 4 designs merged; impl merged; H4 tests green |
| **5** | Trust / Evidence / Audit Integration | 5 specs + provenance/dependency impl, lifecycle audit-emission impl, trust-context impl, audit-chain verification, trust-context unit tests | all Phase 5 specs merged; impl merged; H5 tests green |
| **6** | Observability / Performance | 5 specs + trace-emission impl, caching/async impl, benchmarks, trace-completeness tests | all Phase 6 specs merged; impl merged; H6 tests green |
| **7** | Multi-model Orchestration | 5 specs/ADRs + Route Contract impl, routing-change impl, model-selection impl, no-gate-bypass integration tests, Route Contract unit tests | all Phase 7 specs + ADR-0007/0008 merged; impl merged; H7 tests green |
| **8** | Final UAT / Release | integration UAT plan, 3 integration gates (governance regression, capability boundary, cross-repo UAT run), Taka Final UAT, release tags, release notes, rag.fish update, publication | Taka Final UAT sign-off; then release; then publication |

**Scope note (revision 2):** This roadmap now **schedules** the implementation and
automated-validation tasks in the runtime repositories so Project #16 carries the complete
`Purpose → Means → Plan → Implementation → Validation/UAT → Review → Next action` chain.
**No code is written under this task.** Every implementation task is `Planned` and gated:
it depends on its governing spec/ADR being **merged** (INV-8), and where the execution
locus is still undecided (external-acquisition executor) the implementation task depends on
**ADR-0005 (`H1-ADR-ACQ-LOCUS`)** and its Target Repository is marked *Conditional* until
that ADR resolves it (§9.4).

---

## 5. Task catalog

### 5.0 Field conventions

Every task carries these 13 fields. The first 12 are the Human-Governed-Loop task contract;
**Governed By** is added per architecture-review finding 3.

| Field | Rule |
|---|---|
| Title · Description · Objective | One line / one sentence each. |
| Target Repository | Exactly one of the four repos, or `Conditional — resolved by <ADR>` (§9.4). |
| Scope · Out of Scope | Bullet phrases. |
| Branch Name | `<type>/<short-name>`, lowercase-hyphen, 2–5 words, no issue numbers. `docs/` for spec/ADR/audit, `feature/` for implementation & schema, `test/` for tests. |
| **Owner Agent** | **Exactly one** of: `Claude CLI`, `Codex CLI`, `Taka`. Never a pair, never an arrow. |
| Definition of Done | Checkable exit criteria. |
| Validation | Shell command(s) or a named manual check. |
| **Dependencies** | Only executable/planning artifacts: a GitHub issue (`#NN`), a task ID (`H2-…`), or a merged ADR/contract (`ADR-0004`). **Never** an invariant. |
| **Governed By** | The ADR clauses / `INV-n` the task must not violate. Advisory constraint, not a scheduling edge. |
| Review / Merge Rule | Always: `Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka · squash`. Extra hold conditions noted where they apply. |

Owner-vs-reviewer: **Max / ChatGPT is a reviewer, not an execution owner.** Every ADR is
authored by Claude CLI and carries `Architecture Review — Max / ChatGPT`. Human-intrinsic
tasks (Final UAT, release tagging, external posting) are owned by **Taka**.

### 5.1 Master task table

Type: `spec` (doc/contract) · `adr` · `schema` · `impl` · `test` · `human`.

| ID | Title | Ph | Type | Target repo | Owner | Depends on | Status |
|---|---|---|---|---|---|---|---|
| #32 | ADR-0004 Noesis/Noema epistemic separation | 0 | adr | RAGfish | Claude CLI | — | **DONE** (PR #36 + `23b5736`) |
| #33 | Governance contract + capability matrix | 0 | spec | RAGfish | Claude CLI | #32 | OPEN — **next** |
| #34 | `investigation_result` contract v0.1 | 0 | schema | RAGfish | Codex CLI | #32, #33 | OPEN |
| #35 | Noesis/Noema governance regression cases | 0 | test | RAGfish | Codex CLI | #32, #33, #34 | OPEN |
| H1-EVIDENCE-CONTRACT | Evidence object & provenance contract | 1 | spec | RAGfish | Claude CLI | #33 | Planned |
| H1-SOURCE-DEP-MODEL | Source-dependency / independent-chain model | 1 | spec | RAGfish | Claude CLI | #33, #34 | Planned |
| H1-HUMANGATE-RECORD | Human Gate approval-record schema | 1 | schema | RAGfish | Codex CLI | #33, #34 | Planned |
| H1-ACQUISITION-CONTRACT | External acquisition request/result contract | 1 | schema | RAGfish | Codex CLI | #33, #34, H1-EVIDENCE-CONTRACT | Planned |
| H1-ADR-ACQ-LOCUS | ADR-0005 (Noema): external-acquisition execution locus | 1 | adr | RAGfish | Claude CLI | H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT | Planned |
| H2-NOESIS-CONTRACT | NOESIS runtime & I/O contract | 2 | spec | RAGfish | Claude CLI | #33, #34 | Planned |
| H2-ASSESSMENT-MODEL | Claim decomposition + calibrated assessment + uncertainty model | 2 | spec | RAGfish | Claude CLI | #34, H2-NOESIS-CONTRACT | Planned |
| H2-HYPOTHESES | Competing-hypothesis representation | 2 | spec | RAGfish | Claude CLI | H2-ASSESSMENT-MODEL | Planned |
| H2-SOURCEDEP-EVAL | Source-dependency evaluation algorithm | 2 | spec | RAGfish | Claude CLI | H1-SOURCE-DEP-MODEL, H2-NOESIS-CONTRACT | Planned |
| H2-REANALYSIS-SEMANTICS | Re-analysis / recompute semantics | 2 | spec | RAGfish | Claude CLI | H2-ASSESSMENT-MODEL, H2-HYPOTHESES, H2-SOURCEDEP-EVAL, H1-ACQUISITION-CONTRACT | Planned |
| H2-IMPL-NOESIS-RUNTIME | Implement NOESIS runtime capability | 2 | impl | NoesisNoema | Codex CLI | H2-NOESIS-CONTRACT, #34 | Planned |
| H2-IMPL-ASSESSMENT-STRUCTURES | Implement claim / assessment / uncertainty / hypothesis structures | 2 | impl | NoesisNoema | Codex CLI | H2-ASSESSMENT-MODEL, H2-HYPOTHESES, #34, H2-IMPL-NOESIS-RUNTIME | Planned |
| H2-IMPL-SOURCEDEP-EVAL | Implement source-dependency evaluation | 2 | impl | NoesisNoema | Codex CLI | H2-SOURCEDEP-EVAL, H2-IMPL-ASSESSMENT-STRUCTURES | Planned |
| H2-IMPL-RECOMPUTE | Implement re-analysis / recompute semantics | 2 | impl | NoesisNoema | Codex CLI | H2-REANALYSIS-SEMANTICS, H2-IMPL-ASSESSMENT-STRUCTURES | Planned |
| H2-TEST-NOESIS-UNIT | NOESIS runtime unit tests | 2 | test | NoesisNoema | Codex CLI | H2-IMPL-NOESIS-RUNTIME, H2-IMPL-ASSESSMENT-STRUCTURES, H2-IMPL-SOURCEDEP-EVAL, H2-IMPL-RECOMPUTE, #35 | Planned |
| H3-NOEMA-ISOLATION | Isolated Noema invocation + capability-isolation spec | 3 | spec | RAGfish | Claude CLI | #33, #34 | Planned |
| H3-NARRATIVE-CONTRACT | Presentation / narrative transformation contract | 3 | spec | RAGfish | Claude CLI | #34, H3-NOEMA-ISOLATION | Planned |
| H3-OUTPUT-VALIDATION-SPEC | Noema output-validation spec (no new claims, no confidence escalation) | 3 | spec | RAGfish | Claude CLI | #34, #35, H3-NOEMA-ISOLATION | Planned |
| H3-ADR-NOEMA-HOSTING | ADR-0006 (Noema): where Noema-layer narrative work runs | 3 | adr | RAGfish | Claude CLI | H3-NOEMA-ISOLATION, ADR-0004 | Planned |
| H3-IMPL-NOEMA-CONTEXT | Implement isolated Noema execution context (`investigation_result`-only input; no retrieval / evidence-store / external-API bindings) | 3 | impl | NoesisNoema | Codex CLI | H3-NOEMA-ISOLATION, H3-NARRATIVE-CONTRACT, H3-ADR-NOEMA-HOSTING, #34 | Planned |
| H3-IMPL-OUTPUT-VALIDATOR | Implement Noema output validator | 3 | impl | NoesisNoema | Codex CLI | H3-OUTPUT-VALIDATION-SPEC, H3-IMPL-NOEMA-CONTEXT | Planned |
| H3-TEST-CAPABILITY-ISOLATION | Adversarial / capability-isolation tests for Noema | 3 | test | NoesisNoema | Codex CLI | H3-IMPL-NOEMA-CONTEXT, #35 | Planned |
| H3-TEST-OUTPUT-VALIDATOR-UNIT | Output-validator unit tests | 3 | test | NoesisNoema | Codex CLI | H3-IMPL-OUTPUT-VALIDATOR, #35 | Planned |
| H4-SEALED-GATEWAY | Sealed acquisition-gateway design | 4 | spec | RAGfish | Claude CLI | H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H1-ADR-ACQ-LOCUS | Planned |
| H4-APPROVAL-ENFORCEMENT | Human-approval enforcement design ("can't rather than won't") | 4 | spec | RAGfish | Claude CLI | H1-HUMANGATE-RECORD, H4-SEALED-GATEWAY | Planned |
| H4-EXECUTOR-SELECTION | Acquisition executor selection (per ADR-0005) | 4 | spec | RAGfish | Claude CLI | H1-ADR-ACQ-LOCUS, H4-SEALED-GATEWAY | Planned |
| H4-PROVIDER-TEMPLATE | Provider-agnostic acquisition integration template | 4 | spec | RAGfish | Claude CLI | H4-SEALED-GATEWAY, H4-EXECUTOR-SELECTION | Planned |
| H4-ACQ-RETURN-TRIGGER | Acquisition-return + re-analysis trigger contract | 4 | spec | RAGfish | Claude CLI | H4-SEALED-GATEWAY, H2-REANALYSIS-SEMANTICS | Planned |
| H4-IMPL-HUMANGATE-ENFORCEMENT | Implement Human Gate approval enforcement (surface + record) | 4 | impl | NoesisNoema | Codex CLI | H1-HUMANGATE-RECORD, H4-APPROVAL-ENFORCEMENT | Planned |
| H4-IMPL-SEALED-GATEWAY | Implement the sealed acquisition gateway | 4 | impl | Conditional — ADR-0005 (candidate: noema-agent) | Codex CLI | H1-ADR-ACQ-LOCUS, H4-SEALED-GATEWAY, H4-EXECUTOR-SELECTION, H4-ACQ-RETURN-TRIGGER | Planned |
| H4-IMPL-PROVIDER-ADAPTER | Implement one provider adapter (no credentials; contract-driven) | 4 | impl | Conditional — ADR-0005 | Codex CLI | H4-PROVIDER-TEMPLATE, H4-IMPL-SEALED-GATEWAY | Planned |
| H4-TEST-FAILCLOSED-INTEGRATION | Integration tests proving fail-closed (reject unapproved acquisition; reject AI `approved_by`) | 4 | test | Conditional — ADR-0005 | Codex CLI | H4-IMPL-HUMANGATE-ENFORCEMENT, H4-IMPL-SEALED-GATEWAY, #35 | Planned |
| H4-TEST-GATEWAY-UNIT | Gateway + enforcement unit tests | 4 | test | Conditional — ADR-0005 | Codex CLI | H4-IMPL-SEALED-GATEWAY, H4-IMPL-HUMANGATE-ENFORCEMENT | Planned |
| H5-EVIDENCE-AUDIT-RECONCILE | Reconcile RAGpack provenance / integrity / validation reports with Evidence contract | 5 | spec | RAGfish | Claude CLI | H1-EVIDENCE-CONTRACT | Planned |
| H5-TRUST-CONTEXT-SCHEMA | Trust context schema (evolved) | 5 | spec | RAGfish | Claude CLI | H1-EVIDENCE-CONTRACT, H5-EVIDENCE-AUDIT-RECONCILE | Planned |
| H5-SIGNED-EVIDENCE-PACKAGES | Ed25519 evidence-package applicability to `investigation_result` + Human Gate record | 5 | spec | RAGfish | Claude CLI | #34, H1-HUMANGATE-RECORD, H5-EVIDENCE-AUDIT-RECONCILE | Planned |
| H5-AUDITCHAIN-EPISTEMIC | Audit-chain integration for epistemic-lifecycle events (extends ADR-0003 G6) | 5 | spec | RAGfish | Claude CLI | #34, H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H2-REANALYSIS-SEMANTICS | Planned |
| H5-SOURCE-INDEPENDENCE-TRUST | Source independence/dependency in RAGpack trust metadata | 5 | spec | RAGfish | Claude CLI | H1-SOURCE-DEP-MODEL, H5-TRUST-CONTEXT-SCHEMA | Planned |
| H5-IMPL-PROVENANCE-DEPENDENCY | Implement provenance + source-independence metadata in the pipeline | 5 | impl | noesisnoema-pipeline | Codex CLI | H5-SOURCE-INDEPENDENCE-TRUST, H5-TRUST-CONTEXT-SCHEMA | Planned |
| H5-IMPL-AUDIT-EMISSION | Implement lifecycle audit emission (runtime side) | 5 | impl | NoesisNoema | Codex CLI | H5-AUDITCHAIN-EPISTEMIC, H2-IMPL-RECOMPUTE, H3-IMPL-NOEMA-CONTEXT, H4-IMPL-HUMANGATE-ENFORCEMENT | Planned |
| H5-IMPL-TRUST-CONTEXT | Implement trust-context carry-through | 5 | impl | noema-agent | Codex CLI | H5-TRUST-CONTEXT-SCHEMA, H5-IMPL-PROVENANCE-DEPENDENCY | Planned |
| H5-TEST-AUDITCHAIN-VERIFY | Automated audit-chain verification (+ canonical-JSON vectors) | 5 | test | noesisnoema-pipeline | Codex CLI | H5-IMPL-AUDIT-EMISSION, H5-AUDITCHAIN-EPISTEMIC | Planned |
| H5-TEST-TRUST-CONTEXT-UNIT | Trust-context unit tests | 5 | test | noema-agent | Codex CLI | H5-IMPL-TRUST-CONTEXT | Planned |
| H6-27-AMEND | Amend observability model v0 (#27) for the epistemic lifecycle | 6 | spec | RAGfish | Claude CLI | #27, #33, #34, H5-AUDITCHAIN-EPISTEMIC | Planned |
| H6-EPISTEMIC-TRACE-IDS | Epistemic-lifecycle trace identifiers | 6 | spec | RAGfish | Claude CLI | H6-27-AMEND | Planned |
| H6-DECISION-AUDIT-RELATIONSHIP | Decision/audit + trace relationship model | 6 | spec | RAGfish | Claude CLI | H6-27-AMEND, H5-AUDITCHAIN-EPISTEMIC | Planned |
| H6-LATENCY-BUDGET | Latency budget (Noesis assessment, recompute, Noema narrative) | 6 | spec | RAGfish | Claude CLI | H2-REANALYSIS-SEMANTICS, H3-NARRATIVE-CONTRACT | Planned |
| H6-PERF-CONTRACTS | Performance contracts (policy cache, trust pre-compute, async paths) | 6 | spec | RAGfish | Claude CLI | #33, H5-TRUST-CONTEXT-SCHEMA, H5-AUDITCHAIN-EPISTEMIC | Planned |
| H6-IMPL-TRACE-EMISSION | Implement epistemic trace emission (runtime side) | 6 | impl | NoesisNoema | Codex CLI | H6-EPISTEMIC-TRACE-IDS, H6-DECISION-AUDIT-RELATIONSHIP, H5-IMPL-AUDIT-EMISSION | Planned |
| H6-IMPL-CACHING-ASYNC | Implement policy cache / trust pre-compute read / async evidence-audit paths | 6 | impl | noema-agent | Codex CLI | H6-PERF-CONTRACTS, H5-IMPL-TRUST-CONTEXT | Planned |
| H6-TEST-BENCHMARKS | Latency benchmarks + regression validation | 6 | test | NoesisNoema | Codex CLI | H6-IMPL-TRACE-EMISSION, H6-IMPL-CACHING-ASYNC, H2-IMPL-NOESIS-RUNTIME, H3-IMPL-NOEMA-CONTEXT, H6-LATENCY-BUDGET | Planned |
| H6-TEST-TRACE-COMPLETENESS | Automated check: every lifecycle event emits required trace + audit IDs | 6 | test | noesisnoema-pipeline | Codex CLI | H6-IMPL-TRACE-EMISSION, H5-TEST-AUDITCHAIN-VERIFY | Planned |
| H7-ROUTE-CONTRACT-V1 | ADR-0007 (Noema) + Route Contract v1 (evolved) | 7 | adr | RAGfish | Claude CLI | #33, #34, H1-ADR-ACQ-LOCUS | Planned |
| H7-EXEC-MODE-POLICY | Execution mode selection policy | 7 | spec | RAGfish | Claude CLI | H7-ROUTE-CONTRACT-V1 | Planned |
| H7-LOCAL-FIRST-OPTIN | Local-first default + remote opt-in contract | 7 | spec | RAGfish | Claude CLI | H7-ROUTE-CONTRACT-V1 | Planned |
| H7-ROUTING-AUTHORITY-INVARIANT | ADR-0008 (Noema): routing authority ≠ execution capability; no Human-Gate bypass | 7 | adr | RAGfish | Claude CLI | H7-ROUTE-CONTRACT-V1, H4-APPROVAL-ENFORCEMENT | Planned |
| H7-PROVIDER-MODEL-SELECTION | Provider / model selection contract | 7 | spec | RAGfish | Claude CLI | H7-EXEC-MODE-POLICY | Planned |
| H7-IMPL-ROUTE-CONTRACT | Implement evolved Route Contract (formation) | 7 | impl | noema-agent | Codex CLI | H7-ROUTE-CONTRACT-V1, H7-ROUTING-AUTHORITY-INVARIANT | Planned |
| H7-IMPL-ROUTING-CHANGES | Implement local/remote routing changes + opt-in consumption | 7 | impl | NoesisNoema | Codex CLI | H7-LOCAL-FIRST-OPTIN, H7-EXEC-MODE-POLICY, H7-IMPL-ROUTE-CONTRACT | Planned |
| H7-IMPL-MODEL-SELECTION | Implement explicit model/provider selection | 7 | impl | noema-agent | Codex CLI | H7-PROVIDER-MODEL-SELECTION, H7-IMPL-ROUTE-CONTRACT | Planned |
| H7-TEST-NO-GATE-BYPASS-INTEGRATION | Integration tests proving routing cannot bypass the Human Gate | 7 | test | noema-agent | Codex CLI | H7-IMPL-ROUTE-CONTRACT, H7-IMPL-ROUTING-CHANGES, H4-IMPL-HUMANGATE-ENFORCEMENT, #35 | Planned |
| H7-TEST-ROUTE-CONTRACT-UNIT | Route Contract formation unit tests | 7 | test | noema-agent | Codex CLI | H7-IMPL-ROUTE-CONTRACT | Planned |
| H8-INTEGRATION-UAT-PLAN | Cross-repository integration UAT plan | 8 | spec | RAGfish | Claude CLI | *(all Phase 1–7 `spec`/`adr`/`schema` tasks merged)* | Planned |
| H8-GOV-REGRESSION-GATE | Governance regression suite execution gate | 8 | test | RAGfish | Codex CLI | #35, *(all Phase 2–7 `impl` + `test` tasks)*, H8-INTEGRATION-UAT-PLAN | Planned |
| H8-CAPABILITY-BOUNDARY-GATE | Capability-boundary test gate | 8 | test | RAGfish | Codex CLI | #35, H3-TEST-CAPABILITY-ISOLATION, H4-TEST-FAILCLOSED-INTEGRATION, *(all Phase 2–7 `impl`)*, H8-INTEGRATION-UAT-PLAN | Planned |
| H8-INTEGRATION-UAT-RUN | Execute the cross-repository integration UAT | 8 | test | RAGfish (coordination) | Codex CLI | *(all Phase 2–7 `impl` + `test` tasks)*, H8-INTEGRATION-UAT-PLAN | Planned |
| H8-FINAL-UAT | Final human UAT | 8 | human | all repos | Taka | H8-GOV-REGRESSION-GATE, H8-CAPABILITY-BOUNDARY-GATE, H8-INTEGRATION-UAT-RUN | Planned |
| H8-RELEASE-TAGS | Release tags across repos | 8 | human | all repos | Taka | H8-FINAL-UAT | Planned |
| H8-RELEASE-NOTES | Release notes | 8 | spec | RAGfish | Claude CLI | H8-RELEASE-TAGS | Planned |
| H8-RAGFISH-UPDATE | rag.fish website update | 8 | spec | RAGfish | Claude CLI | H8-RELEASE-NOTES | Planned |
| H8-PUBLICATION | X / LinkedIn / Facebook publication | 8 | human | external | Taka | H8-RAGFISH-UPDATE, H8-RELEASE-TAGS | Planned |

**Count: 75 tasks** — Phase 0: 4 · Phase 1: 5 · Phase 2: 10 · Phase 3: 8 · Phase 4: 10 ·
Phase 5: 10 · Phase 6: 9 · Phase 7: 10 · Phase 8: 9.
Of these: **17 implementation tasks**, **12 automated validation/test tasks** added in
revision 2 (plus #35 and the 3 Phase-8 gates that already existed).

### 5.2 Phase 0 — Epistemic Governance Foundation

*(Detail unchanged from revision 1; `Governed By` added, review line normalised.)*

#### #32 — ADR-0004: Noesis/Noema epistemic separation — **DONE**
Merged via PR #36 incl. amendment `23b5736` (I11 advisory-artifacts, I12 human-noesis ≠ NOESIS-layer). No further action.

#### #33 — Docs: governance contract and capability matrix
- **Description:** Explicit, reviewable governance rules + a capability matrix, each control mapped to an enforcement mechanism.
- **Objective:** Make INV-2 and INV-4 concrete and reviewable before any schema or prompt work.
- **Target Repository:** `rag-fish/RAGfish`
- **Scope:** governance contract for Noesis / Human Gate / external acquisition / re-analysis / Noema; capability matrix (read/write/invoke over evidence store, external APIs, mutable state, audit store, presentation outputs); human-only fields incl. approval ownership; controls → enforcement mechanism (policy / schema / type / credential / endpoint / test). Path `docs/noema/governance/`.
- **Out of Scope:** credentials/endpoints/databases; runtime prompts; JSON Schema validators; provider integration.
- **Branch Name:** `docs/governance-capability-contract`
- **Owner Agent:** Claude CLI
- **Definition of Done:** contract + matrix under `docs/noema/governance/`; Noema shown as no-evidence-store / no-external-API; Human Gate authority + approval ownership explicit; every control mapped to a mechanism; cites ADR-0004 incl. I11/I12.
- **Validation:** `rg -n "Noesis|Noema|Human Gate|evidence|external|capability|approval" docs/noema/governance`; manual cross-check vs ADR-0004 + Human-Governed Loop; confirm no control is prompt-only.
- **Dependencies:** #32
- **Governed By:** ADR-0004 §2, I6, I7, I8; INV-2, INV-4, INV-6
- **Review / Merge Rule:** Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka · squash.

#### #34 — Feature: `investigation_result` contract v0.1
- **Description:** The machine-readable Noesis → Noema handoff — calibrated findings + approved recommendations, no raw evidence, no acquisition capability.
- **Objective:** Give Phases 2/3/5/6 a single named, testable object to constrain against (INV-3).
- **Target Repository:** `rag-fish/RAGfish`
- **Scope:** `investigation_result` v0.1 JSON Schema + contract doc; separate claim / assessment / uncertainty / evidence-chain summary / recommendation / human-approval; bounded assessment-state enum (no `verified: boolean`); independent-source-chain counts without raw evidence; Noema-referenceable vs intentionally-absent fields; downstream invariants; valid + invalid payloads. Path `docs/noema/schemas/`.
- **Out of Scope:** evidence-store schema; external-acquisition schema; provider fields; prompts; UI.
- **Branch Name:** `feature/investigation-result-contract`
- **Owner Agent:** Codex CLI
- **Definition of Done:** schema exists; no `verified: boolean`; bounded enum; confidence + uncertainty defined; no raw evidence in the Noema-facing contract; `approved_by` cannot be AI (documented rule); example payloads.
- **Validation:** `python -m json.tool docs/noema/schemas/investigation-result.schema.json >/dev/null`; validate payloads; manual check vs ADR-0004 + #33.
- **Dependencies:** #32, #33
- **Governed By:** ADR-0004 I3, I5, I6; INV-3, INV-4
- **Review / Merge Rule:** Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka · squash · do not merge if the Noema-facing schema exposes raw evidence or permits unbounded claim creation.

#### #35 — Test: Noesis/Noema governance regression cases
- **Description:** Adversarial / regression cases proving the boundary fails closed.
- **Objective:** Satisfy INV-8 (governance-boundary tests before production integration) for the epistemic lifecycle.
- **Target Repository:** `rag-fish/RAGfish`
- **Scope:** regression test spec: Noema new-claim rejection; confidence-escalation rejection; external-acquisition-attempt rejection; source-dependency counting (many reports, one origin = one chain); AI identity in `approved_by` rejection; external acquisition without approval rejection. Per case: input, attempted violation, expected outcome, enforcement layer. Distinguish prompt refusal from architectural inability. Path `docs/noema/tests/`.
- **Out of Scope:** runtime harness in downstream repos; provider tests; perf/load; UI/UAT scripts.
- **Branch Name:** `test/noesis-noema-governance-cases`
- **Owner Agent:** Codex CLI
- **Definition of Done:** spec exists; ≥6 core negative-path cases; each ADR-0004 invariant → ≥1 case; convertible to automated tests later.
- **Validation:** `rg -n "new claim|confidence|external|approved_by|independent|cannot|reject" docs/noema/tests`; manual invariant→case traceability.
- **Dependencies:** #32, #33, #34
- **Governed By:** ADR-0004 I4, I6, I7, I8; INV-2, INV-4, INV-6, INV-7
- **Review / Merge Rule:** Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka · squash · do not merge unless every critical invariant has a negative-path test.

### 5.3 Phase 1 — Evidence & Acquisition Contracts

#### H1-EVIDENCE-CONTRACT
- **Description:** Define the *Evidence* artifact class Noesis (and only Noesis) consumes — provenance, trust-metadata reference, corpus vs. externally-acquired origin.
- **Objective:** Replace the generic Hermes "evidence artifact schema" for the *input* class; give Phase 2 a defined input surface.
- **Target Repository:** `rag-fish/RAGfish`
- **Scope:** evidence object fields; provenance chain; trust-metadata reference (not recompute); origin marker; consumed-by-Noesis-only rule; alignment with RAGpack v1.3 (G2) and ADR-0002 §3.
- **Out of Scope:** evidence-store implementation; retrieval API; acquisition mechanics; validators.
- **Branch Name:** `docs/evidence-object-contract`
- **Owner Agent:** Claude CLI
- **Definition of Done:** contract doc under `docs/noema/governance/`; three artifact classes delineated; cites ADR-0004 + #33 + #34; grants Noema nothing.
- **Validation:** `rg -n "provenance|trust|origin|Noesis|evidence" docs/noema` ; manual cross-check vs RAGpack v1.3 + ADR-0002 §3.
- **Dependencies:** #33
- **Governed By:** ADR-0004 §"Evidence"; INV-4, INV-10
- **Review / Merge Rule:** Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka · squash.

#### H1-SOURCE-DEP-MODEL
- **Description:** Formalize "how many *independent* source chains support a claim" (many reports, one origin = one chain).
- **Objective:** Feed #34's independent-chain counts, Phase 2 evaluation, Phase 5 trust metadata, #35 case.
- **Target Repository:** `rag-fish/RAGfish`
- **Scope:** independent-chain definition; origin-collapse rules; representation in `investigation_result`; ≥3 worked examples incl. the one-origin case.
- **Out of Scope:** implementation; scoring functions.
- **Branch Name:** `docs/source-dependency-model`
- **Owner Agent:** Claude CLI
- **Definition of Done:** model doc; worked examples; field names consistent with #34.
- **Validation:** manual review vs ADR-0004 §"Source dependency analysis" and #35's source-dependency case.
- **Dependencies:** #33, #34
- **Governed By:** ADR-0004 §"Source dependency analysis"; INV-10
- **Review / Merge Rule:** Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka · squash.

#### H1-HUMANGATE-RECORD
- **Description:** The recorded, scoped, human-only authorization object for crossing an external trust boundary.
- **Objective:** Replace the generic Hermes "human approval gate schema".
- **Target Repository:** `rag-fish/RAGfish`
- **Scope:** JSON Schema + doc; `approved_by` constrained to a human identity type; scope fields (specific acquisition, not standing capability); explicit-decline representation; no inference-from-inaction; `investigation_id` linkage. Path `docs/noema/schemas/`.
- **Out of Scope:** approval UI; runtime gate; credential storage; provider fields.
- **Branch Name:** `feature/human-gate-approval-record`
- **Owner Agent:** Codex CLI
- **Definition of Done:** schema exists; `approved_by` cannot be an agent/model/service by construction + documented rule; decline is first-class; valid/invalid payloads.
- **Validation:** `python -m json.tool docs/noema/schemas/human-gate-approval.schema.json >/dev/null`; payload tests; cross-check #33 human-only fields.
- **Dependencies:** #33, #34
- **Governed By:** ADR-0004 I8, B3; INV-6
- **Review / Merge Rule:** Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka · squash · do not merge if `approved_by` can be non-human.

#### H1-ACQUISITION-CONTRACT
- **Description:** The request Noesis *proposes* and the result an approved acquisition returns — provider-agnostic, provenance-carrying.
- **Objective:** Make acquired evidence re-enter Noesis with comparable metadata (INV-7).
- **Target Repository:** `rag-fish/RAGfish`
- **Scope:** acquisition-request schema (proposal only; no execution authority); acquisition-result schema (provenance, trust metadata, origin marker); binding to a Human Gate approval record; provider-agnostic. Path `docs/noema/schemas/`.
- **Out of Scope:** provider endpoints/credentials; any named provider; the executor decision (H1-ADR-ACQ-LOCUS).
- **Branch Name:** `feature/external-acquisition-contract`
- **Owner Agent:** Codex CLI
- **Definition of Done:** both schemas + doc; request inert without a linked approval record; result matches the Evidence contract shape.
- **Validation:** `python -m json.tool` on both schemas; payload tests; cross-check ADR-0004 §"External Evidence Acquisition".
- **Dependencies:** #33, #34, H1-EVIDENCE-CONTRACT
- **Governed By:** ADR-0004 I3, I4; INV-6, INV-7
- **Review / Merge Rule:** Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka · squash.

#### H1-ADR-ACQ-LOCUS — ADR-0005 (Noema): external-acquisition execution locus
- **Description:** Decide **where** approved external acquisition executes. ADR-0004 names `noema-agent` only as a candidate and defers this.
- **Objective:** Unblock Phase 4 implementation with a decided, capability-posture-defined executor. **Do not auto-assign `noema-agent`.**
- **Target Repository:** `rag-fish/RAGfish`
- **Scope:** options analysis (`noema-agent` constrained task / new sealed component / `NoesisNoema` surface only / other); decision + rationale; executor capability posture; consistency with INV-2, INV-5, INV-6.
- **Out of Scope:** implementing the executor; credentials; provider choice.
- **Branch Name:** `docs/adr-0005-acquisition-execution-locus`
- **Owner Agent:** Claude CLI
- **Definition of Done:** ADR-0005 merged with a clear decision; if `noema-agent` is chosen its "exists to execute, not to decide" definition is preserved (INV-5); follow-up issues identified; §9.4 of this roadmap updated by the ADR's merge.
- **Validation:** manual review vs ADR-0004 I5/I9 + ADR-0001 repo boundaries; Max sign-off recorded.
- **Dependencies:** H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT
- **Governed By:** ADR-0004 I5, I9; INV-2, INV-5, INV-6
- **Review / Merge Rule:** Architecture Review — Max / ChatGPT · Final Review / Merge Owner — Taka (accepts the ADR) · squash.

### 5.4 Phase 2 — NOESIS Runtime

Preserve throughout: **NOESIS assesses; human noesis governs.** Outputs are advisory (I11).

**Specs** (Owner: Claude CLI · Target: `rag-fish/RAGfish` · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Description / Objective | Scope highlights | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|
| H2-NOESIS-CONTRACT | Define the NOESIS layer's I/O contract + capability posture + prompt-interface shape — without writing the prompt. | inputs (Evidence, question, policy); outputs (`investigation_result` or acquisition proposal); capability posture vs #33; NOESIS as a distinct capability context. | the system prompt; model selection; Swift code. | `docs/noesis-runtime-contract` | contract doc; posture matches #33; states outputs are advisory (I11), never approval (I8). | cross-check #33, ADR-0004 §"NOESIS Layer Responsibilities". | #33, #34 | ADR-0004 I2, I8, I11; INV-1 |
| H2-ASSESSMENT-MODEL | How a compound question → assessable claims; bounded assessment state + calibrated confidence (evidence strength/independence, not fluency); uncertainty representation. | decomposition rules; assessment-state semantics (aligned to #34 enum); calibration method; explicit uncertainty; trust-vs-confidence separation. | implementation; calibration training. | `docs/noesis-assessment-model` | model doc; 1:1 with #34 fields; worked example question → claims → assessment. | manual vs #34, ADR-0002 §3, ADR-0004. | #34, H2-NOESIS-CONTRACT | ADR-0004 §"Calibrated assessment"; INV-10 |
| H2-HYPOTHESES | How Noesis holds >1 explanation when evidence does not force one, and how it survives to `investigation_result` and through Noema unchanged. | representation structure; non-collapse rule; carry-through. | implementation; ranking heuristics. | `docs/competing-hypothesis-representation` | doc; consistent with #34; two-hypothesis example. | manual vs ADR-0004. | H2-ASSESSMENT-MODEL | ADR-0004 §"Competing hypotheses"; INV-4 |
| H2-SOURCEDEP-EVAL | Turn H1-SOURCE-DEP-MODEL into an evaluation procedure Noesis follows to count independent chains. | procedure; inputs from Evidence provenance; output into `investigation_result`; edge cases. | implementation. | `docs/source-dependency-evaluation` | doc; deterministic procedure; maps to #35 source-dependency case. | run the procedure by hand vs #35 fixture. | H1-SOURCE-DEP-MODEL, H2-NOESIS-CONTRACT | ADR-0004 §"Source dependency analysis" |
| H2-REANALYSIS-SEMANTICS | Newly acquired evidence causes a **recompute** over the enlarged set — not patch/append/override (INV-7); how iteration terminates. | recompute definition; supersede-not-edit rule; iteration/termination; audit events per re-analysis. | implementation; caching (Phase 6). | `docs/noesis-reanalysis-semantics` | doc; "single coherent judgment over all evidence" guarantee; audit-event list for Phase 5. | manual vs ADR-0004 I4 + §"NOESIS Re-analysis". | H2-ASSESSMENT-MODEL, H2-HYPOTHESES, H2-SOURCEDEP-EVAL, H1-ACQUISITION-CONTRACT | ADR-0004 I4; INV-7 |

**Implementation & tests** (Owner: Codex CLI · Target: `rag-fish/NoesisNoema`, strict pure-Swift · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|
| H2-IMPL-NOESIS-RUNTIME | Stand up the NOESIS layer as a distinct pure-Swift capability context per H2-NOESIS-CONTRACT. | entry point; input binding (Evidence, question, policy); output of `investigation_result` or an acquisition proposal; retrieval + evidence-store access wired **only** here. | assessment maths; Noema; external APIs; prompts. | `feature/noesis-runtime-capability` | builds pure-Swift; emits a schema-valid `investigation_result` stub; no outbound provider-API capability present; unit-test target exists. | `swift test --filter NoesisRuntime`; schema-validate emitted `investigation_result` vs #34. | H2-NOESIS-CONTRACT, #34 | ADR-0004 I2, I11; INV-1, INV-2, INV-9 |
| H2-IMPL-ASSESSMENT-STRUCTURES | Implement claim / assessment-state / calibrated-confidence / uncertainty / competing-hypothesis structures. | typed structures; enum from #34; calibration hook; hypothesis set. | source-dependency; recompute; prompts. | `feature/noesis-assessment-structures` | structures compile; round-trip to `investigation_result`; property tests for enum + confidence bounds. | `swift test --filter Assessment`; schema round-trip. | H2-ASSESSMENT-MODEL, H2-HYPOTHESES, #34, H2-IMPL-NOESIS-RUNTIME | ADR-0004 §"Calibrated assessment"; INV-4, INV-10 |
| H2-IMPL-SOURCEDEP-EVAL | Implement the deterministic independent-chain counting procedure. | procedure from H2-SOURCEDEP-EVAL; provenance input; count into `investigation_result`. | trust metadata (Phase 5); prompts. | `feature/source-dependency-evaluation` | procedure implemented; the "many reports, one origin = one chain" fixture returns 1. | `swift test --filter SourceDependency` incl. #35 fixture. | H2-SOURCEDEP-EVAL, H2-IMPL-ASSESSMENT-STRUCTURES | ADR-0004 §"Source dependency analysis" |
| H2-IMPL-RECOMPUTE | Implement recompute-not-append semantics for re-analysis. | full recompute over enlarged set; prior assessment superseded; iteration guard; emits per-re-analysis audit event. | the audit sink itself (H5); caching. | `feature/noesis-recompute-semantics` | re-analysis recomputes; no downstream patch path exists; iteration terminates; audit event emitted. | `swift test --filter Recompute`; assert no append API is reachable. | H2-REANALYSIS-SEMANTICS, H2-IMPL-ASSESSMENT-STRUCTURES | ADR-0004 I4; INV-7 |
| H2-TEST-NOESIS-UNIT | Consolidated unit-test suite for the Phase 2 implementation, mapped to #35 where applicable. | assessment bounds; hypothesis non-collapse; source-dependency counting; recompute-not-append; advisory-only output. | integration/UAT (Phase 8); downstream harness. | `test/noesis-runtime-unit` | every Phase 2 impl task has ≥1 test; #35 source-dependency + confidence cases represented; suite green in CI. | `swift test --filter Noesis`. | H2-IMPL-NOESIS-RUNTIME, H2-IMPL-ASSESSMENT-STRUCTURES, H2-IMPL-SOURCEDEP-EVAL, H2-IMPL-RECOMPUTE, #35 | ADR-0004 I2, I4; INV-7, INV-10 |

### 5.5 Phase 3 — NOEMA Runtime

Governance enforced **architecturally, not by prompting** (INV-2).

**Specs / ADR** (Owner: Claude CLI · Target: `rag-fish/RAGfish` · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|
| H3-NOEMA-ISOLATION | Specify Noema as a separate capability context invoked with `investigation_result` **only** — no evidence-store credentials, no retrieval bindings, no outbound provider-API capability. | invocation contract; input surface = `investigation_result`; enumerated absent capabilities; enforcement mechanism per capability. | narrative prompt; process implementation; hosting decision. | `docs/noema-invocation-isolation` | spec; every INV-4 capability shown absent with a named mechanism (not "prompt"); cites #33 + #34. | cross-check #33, ADR-0004 §"Trust Boundaries" + §"Capability Restrictions". | #33, #34 | ADR-0004 I6, B2, B4; INV-3, INV-4 |
| H3-NARRATIVE-CONTRACT | Define exactly what Noema may do — reorder/summarise/explain/format; carry through assessment states, confidence, uncertainty, hypotheses, limitations exactly as received. | permitted transformations; "state the limitation, do not acquire the fact" rule; no new claims; no confidence change. | prompt; UI rendering. | `docs/noema-narrative-contract` | contract doc; permitted/forbidden lists; consistent with H3-OUTPUT-VALIDATION-SPEC. | manual vs ADR-0004 §"NOEMA". | #34, H3-NOEMA-ISOLATION | ADR-0004 §"NOEMA"; INV-4 |
| H3-OUTPUT-VALIDATION-SPEC | A checkable spec that Noema output introduced no new factual claim and did not raise confidence above the `investigation_result`. | validation rules; claim-set comparison; confidence-ceiling check; failure codes. | the validator implementation (H3-IMPL-OUTPUT-VALIDATOR); UI. | `docs/noema-output-validation-spec` | spec + example pass/fail fixtures; maps to #35 new-claim + confidence-escalation cases. | `rg -n "claim|confidence|reject|fail" docs/noema`; fixture review. | #34, #35, H3-NOEMA-ISOLATION | ADR-0004 I6; INV-4 |
| H3-ADR-NOEMA-HOSTING — ADR-0006 (Noema) | Decide whether Noema-layer work runs as a constrained task inside `noema-agent` or as its own context — without weakening INV-5. | options; decision + rationale; how INV-4 stays "can't" under the chosen hosting; explicit epistemic-Noema ≠ `noema-agent` statement. | implementation. | `docs/adr-0006-noema-hosting` | ADR-0006 merged; INV-5 preserved; capability-isolation mechanism named. | Max sign-off; cross-check ADR-0004 I9 + Rejected Alternative D. | H3-NOEMA-ISOLATION, ADR-0004 | ADR-0004 I5, I9; INV-5 |

**Implementation & tests** (Owner: Codex CLI · Target: `rag-fish/NoesisNoema` · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|
| H3-IMPL-NOEMA-CONTEXT | Implement the isolated Noema execution context: `investigation_result`-only input; remove/omit retrieval, evidence-store, and external-API bindings. | separate context/target; input binding to `investigation_result` only; build-time absence of evidence-store + retrieval + outbound-network capability; hosting per ADR-0006. | the validator (H3-IMPL-OUTPUT-VALIDATOR); prompt. | `feature/noema-isolated-context` | Noema context builds with no retrieval/evidence-store/network dependency in its module graph; input surface is `investigation_result` only; passes capability-isolation tests. | `swift test --filter NoemaIsolation`; dependency-graph assertion that forbidden modules are absent. | H3-NOEMA-ISOLATION, H3-NARRATIVE-CONTRACT, H3-ADR-NOEMA-HOSTING, #34 | ADR-0004 I5, I6, B2, B4; INV-2, INV-3, INV-4 |
| H3-IMPL-OUTPUT-VALIDATOR | Implement the Noema output validator per H3-OUTPUT-VALIDATION-SPEC. | claim-set diff vs `investigation_result`; confidence-ceiling check; structured failure codes; runs post-Noema pre-surface. | integration wiring into Route Contract (Phase 7). | `feature/noema-output-validator` | validator rejects a synthetic new claim and a synthetic confidence bump; failure codes match spec. | `swift test --filter OutputValidator`. | H3-OUTPUT-VALIDATION-SPEC, H3-IMPL-NOEMA-CONTEXT | ADR-0004 I6; INV-4 |
| H3-TEST-CAPABILITY-ISOLATION | Adversarial / capability-isolation tests: attempt retrieval, evidence-store access, external API, state mutation from within Noema — all must be impossible, not merely refused. | probes per INV-4 capability; distinguishes prompt refusal from architectural inability; maps to #35. | non-Noema boundaries. | `test/noema-capability-isolation` | each forbidden capability probe fails to compile or has no reachable API; #35 Noema cases represented; green in CI. | `swift test --filter NoemaCapabilityIsolation`. | H3-IMPL-NOEMA-CONTEXT, #35 | ADR-0004 I6, B4; INV-2, INV-4 |
| H3-TEST-OUTPUT-VALIDATOR-UNIT | Unit tests for the validator (new-claim rejection, confidence-escalation rejection, pass-through of unchanged narrative). | positive + negative fixtures from H3-OUTPUT-VALIDATION-SPEC and #35. | integration. | `test/noema-output-validator-unit` | new-claim + confidence-escalation cases fail closed; unchanged narrative passes; green in CI. | `swift test --filter OutputValidatorUnit`. | H3-IMPL-OUTPUT-VALIDATOR, #35 | ADR-0004 I6; INV-4 |

### 5.6 Phase 4 — Human-Gated External Acquisition

No automatic external acquisition. No provider credentials created in this roadmap.

**Specs / designs** (Owner: Claude CLI · Target: `rag-fish/RAGfish` · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|
| H4-SEALED-GATEWAY | Design the single choke point every external acquisition must pass, sealed so it cannot run without a valid Human Gate approval record. | gateway responsibilities; approval-record precondition; provenance capture on return; audit events; fail-closed behaviour. | endpoints, credentials, provider SDKs, code. | `docs/sealed-acquisition-gateway` | design doc; "no approval record ⇒ no acquisition" as a structural property; audit-event list. | manual vs ADR-0004 §"Human Gate" + INV-2/INV-6. | H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H1-ADR-ACQ-LOCUS | ADR-0004 I3, B1; INV-2, INV-6 |
| H4-APPROVAL-ENFORCEMENT | Specify the mechanisms (schema validation, type constraints, absent credentials, separate context) that make bypassing the Human Gate impossible. | enforcement mechanism per bypass vector; mapping to #33 controls; prompt layer noted as non-sole. | implementation. | `docs/human-approval-enforcement` | doc; every known bypass vector has a non-prompt mechanism; maps to #35 "external acquisition without approval". | manual vs INV-2; Max sign-off. | H1-HUMANGATE-RECORD, H4-SEALED-GATEWAY | ADR-0004 I7, I8; INV-2, INV-6 |
| H4-EXECUTOR-SELECTION | Apply ADR-0005 to specify which component executes an approved acquisition and its capability posture. | executor responsibilities; scoped to the approved acquisition only; no standing capability. | credentials; provider choice; implementation. | `docs/acquisition-executor-selection` | doc consistent with ADR-0005; scope-limited executor. | cross-check ADR-0005. | H1-ADR-ACQ-LOCUS, H4-SEALED-GATEWAY | ADR-0004 I5, I9; INV-5 |
| H4-PROVIDER-TEMPLATE | A template for adding a provider later (required provenance/trust/scoping obligations) — no actual provider. | required provider-supplied fields; provenance/trust obligations; scoping; "not yet integrated" status list. | any named provider integration; API keys; endpoints. | `docs/provider-integration-template` | template doc; states no provider is integrated and each integration needs its own issue + review. | manual vs ADR-0004 Out-of-Scope list. | H4-SEALED-GATEWAY, H4-EXECUTOR-SELECTION | ADR-0004 §"External Evidence Acquisition"; INV-6 |
| H4-ACQ-RETURN-TRIGGER | Specify how an acquisition result returns into Noesis and triggers a recompute (INV-7), not an append. | return path; re-analysis trigger; audit events; iteration bounds. | implementation. | `docs/acquisition-return-reanalysis` | contract doc; consistent with H2-REANALYSIS-SEMANTICS. | manual vs ADR-0004 I4. | H4-SEALED-GATEWAY, H2-REANALYSIS-SEMANTICS | ADR-0004 I4; INV-7 |

**Implementation & tests** (Owner: Codex CLI · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Target repo | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|---|
| H4-IMPL-HUMANGATE-ENFORCEMENT | `rag-fish/NoesisNoema` (surface, per ADR-0004) | Implement Human Gate approval capture + enforcement: an acquisition cannot proceed without a schema-valid, human-owned approval record. | approval capture surface; record write; `approved_by` type = human only; decline path; no inference-from-inaction. | the gateway itself; provider adapter; UI polish. | `feature/human-gate-enforcement` | unapproved acquisition path is unreachable; `approved_by` rejects an agent/model identity at compile/schema time; decline recorded. | `swift test --filter HumanGate`; attempt to construct an AI-owned approval → fails. | H1-HUMANGATE-RECORD, H4-APPROVAL-ENFORCEMENT | ADR-0004 I3, I7, I8, B3; INV-1, INV-2, INV-6 |
| H4-IMPL-SEALED-GATEWAY | **Conditional — ADR-0005** (candidate `rag-fish/noema-agent`) | Implement the sealed acquisition gateway in the repo ADR-0005 selects. | choke-point; approval-record precondition check; provenance capture; audit emission; fail-closed default. | provider-specific code; credentials. | `feature/sealed-acquisition-gateway` | gateway rejects any call lacking a valid approval record; returns provenance-stamped result to Noesis; emits audit events. | integration test: call without approval → rejected; call with approval → provenance present. | H1-ADR-ACQ-LOCUS, H4-SEALED-GATEWAY, H4-EXECUTOR-SELECTION, H4-ACQ-RETURN-TRIGGER | ADR-0004 I3, B1; INV-2, INV-6 |
| H4-IMPL-PROVIDER-ADAPTER | **Conditional — ADR-0005** | Implement exactly one provider adapter, contract-driven, **only after** H4-PROVIDER-TEMPLATE merges. **No credentials committed.** | one adapter conforming to the template; provenance + trust + scope obligations. | credentials/secrets; a second provider; endpoints in code beyond config. | `feature/acquisition-provider-adapter` | adapter conforms to the template; runs only behind the sealed gateway; secret material read from environment, never committed. | adapter contract tests; secret-scan clean. | H4-PROVIDER-TEMPLATE, H4-IMPL-SEALED-GATEWAY | ADR-0004 §"External Evidence Acquisition"; INV-6 |
| H4-TEST-FAILCLOSED-INTEGRATION | **Conditional — ADR-0005** (matches gateway repo) | Integration tests proving fail-closed behaviour end-to-end. | unapproved acquisition rejected; AI `approved_by` rejected; expired/mismatched-scope approval rejected; declined → Noesis proceeds on existing evidence. | perf; provider live calls. | `test/acquisition-failclosed-integration` | all four fail-closed scenarios pass; maps to #35 external-acquisition cases. | integration suite green in CI. | H4-IMPL-HUMANGATE-ENFORCEMENT, H4-IMPL-SEALED-GATEWAY, #35 | ADR-0004 I3, I7, I8; INV-2, INV-6 |
| H4-TEST-GATEWAY-UNIT | **Conditional — ADR-0005** | Unit tests for gateway + enforcement logic. | precondition check; provenance stamping; audit-event shape; decline handling. | integration. | `test/acquisition-gateway-unit` | branch coverage of the precondition check; green in CI. | gateway unit suite. | H4-IMPL-SEALED-GATEWAY, H4-IMPL-HUMANGATE-ENFORCEMENT | ADR-0004 I3; INV-6 |

### 5.7 Phase 5 — Trust / Evidence / Audit Integration

Reuse RAGpack v1.3, `spec-audit-pipeline.md`, `spec-g3-promotion-gate.md`, ADR-0003 G1–G6.

**Specs** (Owner: Claude CLI · Target: `rag-fish/RAGfish` · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|
| H5-EVIDENCE-AUDIT-RECONCILE | Cross-repo audit that the Evidence contract is consistent with what RAGpack v1.3 + pipeline already produce; identify gaps only. | field-by-field reconciliation; integrity-hash coverage; validation-report linkage; gap list. | changing pipeline code; new schemas. | `audit/evidence-provenance-reconcile` | audit finding doc; explicit KEEP/GAP list; no downstream code changes. | cross-check RAGpack v1.3 schema, `spec-g3-promotion-gate.md`, ADR-0003. | H1-EVIDENCE-CONTRACT | ADR-0003 G2, G6; ADR-0004 §"Evidence" |
| H5-TRUST-CONTEXT-SCHEMA | The Hermes Theme-2 trust context schema, reconciled so trust stays independent of Noesis calibrated confidence (INV-10). | provenance, corpus quality, freshness, validation history, source-independence ref; carried in Route Contract + recorded in evidence/audit; explicit "not confidence" note. | trust algorithm in code; pipeline changes. | `docs/trust-context-schema` | schema doc; trust/confidence separation explicit; consumed from pre-computed metadata at inference. | cross-check ADR-0002 §3, ADR-0003 Knowledge plane. | H1-EVIDENCE-CONTRACT, H5-EVIDENCE-AUDIT-RECONCILE | ADR-0002 §3; INV-10 |
| H5-SIGNED-EVIDENCE-PACKAGES | How `spec-audit-pipeline.md`'s signed evidence packages apply to `investigation_result` + the Human Gate record. | which epistemic artifacts get packaged/signed; content-redaction defaults; offline verifiability. | implementation; key management. | `docs/signed-evidence-packages-epistemic` | doc; reuses the existing evidence-package format; no new crypto design. | cross-check `spec-audit-pipeline.md`, ADR-0003 §"Audit storage". | #34, H1-HUMANGATE-RECORD, H5-EVIDENCE-AUDIT-RECONCILE | ADR-0003 §"Audit storage"; ADR-0004 I5 |
| H5-AUDITCHAIN-EPISTEMIC | Extend ADR-0003 G6 to cover every epistemic step: assessment, gate approve/decline, each acquisition, each re-analysis, the handoff, Noema validation. | event taxonomy; hash-chain placement; G6 extension text; ordering guarantees. | implementation; canonical-JSON vectors (H5-TEST-AUDITCHAIN-VERIFY). | `docs/epistemic-audit-chain` | doc; complete event list; cites ADR-0003 G6; feeds Phase 6. | cross-check ADR-0003, ADR-0004 §"Mapping onto governance rules G1–G6". | #34, H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT, H2-REANALYSIS-SEMANTICS | ADR-0003 G6; ADR-0004 §"Mapping onto governance rules" |
| H5-SOURCE-INDEPENDENCE-TRUST | Add a source-independence/dependency signal to RAGpack trust metadata (spec only). | metadata field spec; relation to H1-SOURCE-DEP-MODEL; RAGpack version-bump plan. | pipeline implementation (H5-IMPL-PROVENANCE-DEPENDENCY). | `docs/ragpack-source-independence` | spec; version-bump plan; downstream follow-up identified. | cross-check RAGpack v1.3 schema. | H1-SOURCE-DEP-MODEL, H5-TRUST-CONTEXT-SCHEMA | ADR-0002 §3; ADR-0004 §"Source dependency analysis"; INV-10 |

**Implementation & tests** (Owner: Codex CLI · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Target repo | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|---|
| H5-IMPL-PROVENANCE-DEPENDENCY | `rag-fish/noesisnoema-pipeline` | Implement provenance + source-independence metadata emission in RAGpack generation per H5-SOURCE-INDEPENDENCE-TRUST. | metadata fields; RAGpack version bump; back-compat note. | runtime consumption (H5-IMPL-TRUST-CONTEXT). | `feature/ragpack-source-independence` | RAGpack emits the new fields; existing packs still validate; version bumped. | `pytest -k source_independence`; RAGpack schema validation. | H5-SOURCE-INDEPENDENCE-TRUST, H5-TRUST-CONTEXT-SCHEMA | ADR-0003 Knowledge plane; INV-10 |
| H5-IMPL-AUDIT-EMISSION | `rag-fish/NoesisNoema` | Implement runtime lifecycle audit emission per H5-AUDITCHAIN-EPISTEMIC (pipeline side already implemented per ADR-0003). | emit hash-chained events for assessment, gate approve/decline, acquisition, re-analysis, handoff, Noema validation; a missing event invalidates the run. | pipeline-side emitter (done); verifier (H5-TEST-AUDITCHAIN-VERIFY). | `feature/epistemic-audit-emission` | every lifecycle step emits an event; run with a suppressed event is flagged invalid; canonical JSON. | `swift test --filter AuditEmission`. | H5-AUDITCHAIN-EPISTEMIC, H2-IMPL-RECOMPUTE, H3-IMPL-NOEMA-CONTEXT, H4-IMPL-HUMANGATE-ENFORCEMENT | ADR-0003 G6; ADR-0004 I4, I8; INV-2 |
| H5-IMPL-TRUST-CONTEXT | `rag-fish/noema-agent` | Implement trust-context carry-through into the Route Contract + evidence artifact, read from pre-computed metadata. | read pre-computed trust metadata; attach to Route Contract; record in evidence; keep separate from confidence. | recomputing trust at inference; UI. | `feature/trust-context-carrythrough` | trust context present in Route Contract + evidence; no per-request recompute; confidence field untouched by trust. | `pytest -k trust_context`. | H5-TRUST-CONTEXT-SCHEMA, H5-IMPL-PROVENANCE-DEPENDENCY | ADR-0002 §3, §4; INV-10 |
| H5-TEST-AUDITCHAIN-VERIFY | `rag-fish/noesisnoema-pipeline` | Automated audit-chain verification + cross-language canonical-JSON conformance vectors (Python + Swift byte-compatible). | chain integrity check; missing-event detection; RFC 8785 conformance vectors. | new event types. | `test/auditchain-verification` | verifier detects a broken chain and a missing event; conformance vectors pass in both languages. | `pytest -k auditchain`; run vectors against the Swift emitter output. | H5-IMPL-AUDIT-EMISSION, H5-AUDITCHAIN-EPISTEMIC | ADR-0003 G6 |
| H5-TEST-TRUST-CONTEXT-UNIT | `rag-fish/noema-agent` | Unit tests for trust-context carry-through and the trust≠confidence separation. | positive carry-through; assertion that confidence is not derived from trust. | integration. | `test/trust-context-unit` | trust present end-to-end in a unit fixture; a test asserts no code path lets trust modify confidence. | `pytest -k trust_context_unit`. | H5-IMPL-TRUST-CONTEXT | ADR-0002 §3; INV-10 |

### 5.8 Phase 6 — Observability / Performance

**Specs** (Owner: Claude CLI · Target: `rag-fish/RAGfish` · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|
| H6-27-AMEND | Re-scope #27 for the epistemic lifecycle. Carries the #27 amendment; **#27 not edited before this task is scheduled.** | add epistemic trace points; update #27's stale "Issue 4/7" deps to current tasks; keep four-layer coverage. | observability tooling; APM. | `docs/observability-model-v0-epistemic` | amended model doc; #27 stale refs replaced; four layers covered; no code. | `rg -n "trace_id|request_id|audit_id|decision_id|investigation_id" docs/noema`; manual vs ADR-0004. | #27, #33, #34, H5-AUDITCHAIN-EPISTEMIC | ADR-0004 §"Relationship to Existing Architecture" |
| H6-EPISTEMIC-TRACE-IDS | Define `investigation_id`, `assessment_id`, `gate_approval_id`, `acquisition_id`, `reanalysis_id` — scope, cardinality, relationships to existing IDs. | identifier definitions; parent/child; one `investigation_id` spanning re-analysis iterations. | implementation. | `docs/epistemic-trace-identifiers` | doc; consistent with #27 identifiers; every epistemic audit event carries the right IDs. | manual vs H5-AUDITCHAIN-EPISTEMIC. | H6-27-AMEND | ADR-0004; ADR-0002 (observability theme) |
| H6-DECISION-AUDIT-RELATIONSHIP | Update the Hermes trace-relationship model to include epistemic artifacts + the nine-stage overlay. | relationship graph; sync/async boundary for epistemic events; decision-log threshold for investigations. | implementation; unified decision-log persistence (future ADR). | `docs/decision-audit-relationship` | doc; graph covers epistemic + development evidence; async-by-default preserved. | cross-check ADR-0002 §7–§9, ADR-0003 G6. | H6-27-AMEND, H5-AUDITCHAIN-EPISTEMIC | ADR-0002 §7–§9; ADR-0003 G6 |
| H6-LATENCY-BUDGET | The Hermes latency budget, extended with Noesis assessment, re-analysis recompute, and Noema narrative budgets. | per-stage budgets incl. epistemic stages; recompute-vs-append cost note; local-first zero-remote-latency assumption. | benchmark implementation (H6-TEST-BENCHMARKS). | `docs/latency-budget-spec` | budget doc; epistemic stages included; consistent with ADR-0002 runtime principles. | manual vs ADR-0002 §"Runtime Principles". | H2-REANALYSIS-SEMANTICS, H3-NARRATIVE-CONTRACT | ADR-0002 §"Runtime Principles"; INV-9 |
| H6-PERF-CONTRACTS | Deliver the KEEP'd Hermes performance deliverables as one contract set, updated so re-analysis is not silently cache-elided (INV-7). | policy cache design + invalidation; trust pre-computation contract; async evidence/audit write path; "recompute is not cache-elided" rule. | implementation. | `docs/performance-contracts` | contract doc; all three sub-contracts present; INV-7 protected against caching shortcuts. | cross-check ADR-0002 §"Runtime Principles", ADR-0003. | #33, H5-TRUST-CONTEXT-SCHEMA, H5-AUDITCHAIN-EPISTEMIC | ADR-0002 §"Runtime Principles"; ADR-0003; INV-7, INV-9 |

**Implementation & tests** (Owner: Codex CLI · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Target repo | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|---|
| H6-IMPL-TRACE-EMISSION | `rag-fish/NoesisNoema` | Implement runtime trace emission for the epistemic lifecycle per H6-EPISTEMIC-TRACE-IDS + H6-DECISION-AUDIT-RELATIONSHIP. | emit trace IDs at each epistemic stage; link to audit events; sync/async per contract. | agent-side + pipeline-side emission (companion issues at population if scope demands). | `feature/epistemic-trace-emission` | each stage emits the required IDs; traces link to audit chain; no PII in trace payloads. | `swift test --filter TraceEmission`. | H6-EPISTEMIC-TRACE-IDS, H6-DECISION-AUDIT-RELATIONSHIP, H5-IMPL-AUDIT-EMISSION | ADR-0004 §"Relationship…"; INV-1 |
| H6-IMPL-CACHING-ASYNC | `rag-fish/noema-agent` | Implement policy cache, trust pre-computed-metadata read, and async evidence/audit write paths per H6-PERF-CONTRACTS. **Only after the contract merges.** | policy result cache + invalidation on policy change; async evidence/audit writes with durability; explicit guard that re-analysis bypasses any assessment cache. | new caching beyond the contract; runtime human gates. | `feature/performance-caching-async` | cache invalidates on policy change; async writes are durable + non-blocking; a test proves re-analysis is never served from an assessment cache. | `pytest -k "cache or async"`. | H6-PERF-CONTRACTS, H5-IMPL-TRUST-CONTEXT | ADR-0002 §"Runtime Principles"; INV-7, INV-9 |
| H6-TEST-BENCHMARKS | `rag-fish/NoesisNoema` | Latency benchmarks for the epistemic lifecycle + a regression check against H6-LATENCY-BUDGET. | benchmark Noesis assessment, recompute, Noema narrative; CI regression thresholds from the budget. | load testing. | `test/latency-benchmarks` | benchmarks run in CI; exceeding a budget threshold fails the check. | `swift test --filter Benchmarks` (or the benchmark runner). | H6-IMPL-TRACE-EMISSION, H6-IMPL-CACHING-ASYNC, H2-IMPL-NOESIS-RUNTIME, H3-IMPL-NOEMA-CONTEXT, H6-LATENCY-BUDGET | ADR-0002 §"Runtime Principles"; INV-9 |
| H6-TEST-TRACE-COMPLETENESS | `rag-fish/noesisnoema-pipeline` | Automated check that every lifecycle event emits the required trace + audit IDs (completeness, per G6). | scan a recorded run; assert no epistemic stage is missing its trace/audit IDs. | new event types. | `test/trace-completeness` | a run with a dropped trace ID fails the check; green on a complete run. | `pytest -k trace_completeness`. | H6-IMPL-TRACE-EMISSION, H5-TEST-AUDITCHAIN-VERIFY | ADR-0003 G6; ADR-0004 |

### 5.9 Phase 7 — Multi-model Orchestration

**Specs / ADRs** (Owner: Claude CLI · Target: `rag-fish/RAGfish` · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|
| H7-ROUTE-CONTRACT-V1 — ADR-0007 (Noema) | Evolve the Route Contract to declare investigation vs. not, external-acquisition-in-scope-pending-Human-Gate, and carry `investigation_id`; fix Route Contract v1 as an ADR. | ADR-0007 + contract doc; fields: selected path, why, confidence, trust context, approval requirements, investigation flag, acquisition-in-scope-pending-gate, `investigation_id`; "declares, does not execute" preserved. | implementation; transport/serialization (future ADR). | `docs/adr-0007-route-contract-v1` | ADR + contract merged; ADR-0002 §4 semantics preserved + extended; maps onto the epistemic lifecycle. | cross-check ADR-0002 §4, ADR-0004 §"Mapping onto the nine-stage pipeline". | #33, #34, H1-ADR-ACQ-LOCUS | ADR-0002 §4; ADR-0004 §"Route Contract"; INV-6, INV-9 |
| H7-EXEC-MODE-POLICY | The Hermes execution-mode policy (local/remote/tool/human) + the rule that external acquisition is never a selectable mode without a Human Gate approval. | selection criteria; acquisition-exclusion rule; human-executor mode. | implementation. | `docs/execution-mode-policy` | policy doc; acquisition-exclusion rule explicit. | cross-check ADR-0002 §5, INV-6. | H7-ROUTE-CONTRACT-V1 | ADR-0002 §5; INV-6 |
| H7-LOCAL-FIRST-OPTIN | Reaffirm and specify INV-9: local default and non-degraded; remote opt-in; never a silent fallback. | default-path spec; opt-in trigger; no-silent-fallback rule; zero-runtime-human-gate for ordinary queries preserved. | implementation. | `docs/local-first-remote-optin` | contract doc; consistent with ADR-0001, ADR-0003. | cross-check ADR-0003 §"governance without runtime humans". | H7-ROUTE-CONTRACT-V1 | ADR-0001; ADR-0003 §"governance without runtime humans"; INV-9 |
| H7-ROUTING-AUTHORITY-INVARIANT — ADR-0008 (Noema) | Record that orchestration/routing never gains execution or acquisition authority and can never bypass the Human Gate. | invariant statement; relation to ADR-0000 §2/§6 and ADR-0004 INV-6; enforcement note. | implementation. | `docs/adr-0008-routing-authority` | ADR merged; invariant explicit and testable (feeds H7-TEST-NO-GATE-BYPASS-INTEGRATION). | Max sign-off; cross-check ADR-0000 Anti-Patterns §6. | H7-ROUTE-CONTRACT-V1, H4-APPROVAL-ENFORCEMENT | ADR-0000 §2, §6; ADR-0004 I3, I8; INV-6 |
| H7-PROVIDER-MODEL-SELECTION | Specify explicit, non-silent model/provider selection (ADR-0000 §6) within the evolved Route Contract. | explicit-selection rule; no silent switching/upgrade; disclosure requirement; recorded in evidence. | implementation; provider credentials. | `docs/provider-model-selection` | contract doc; consistent with ADR-0000 §6 + Anti-Pattern §2. | cross-check ADR-0000. | H7-EXEC-MODE-POLICY | ADR-0000 §6; INV-1 |

**Implementation & tests** (Owner: Codex CLI · Review: Arch — Max / ChatGPT · Merge — Taka · squash):

| ID | Target repo | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By |
|---|---|---|---|---|---|---|---|---|---|
| H7-IMPL-ROUTE-CONTRACT | `rag-fish/noema-agent` | Implement evolved Route Contract formation per ADR-0007 + ADR-0008. | contract formation; investigation flag; acquisition-in-scope-pending-gate; `investigation_id`; declares-not-executes. | routing heuristics beyond the policy; transport. | `feature/route-contract-v1` | formation produces a valid v1 contract; a contract can never carry "acquisition approved" without a linked Human Gate record. | `pytest -k route_contract`. | H7-ROUTE-CONTRACT-V1, H7-ROUTING-AUTHORITY-INVARIANT | ADR-0002 §4; ADR-0004 I3; INV-6 |
| H7-IMPL-ROUTING-CHANGES | `rag-fish/NoesisNoema` | Implement local/remote routing changes + opt-in remote consumption per H7-LOCAL-FIRST-OPTIN. | local default path; explicit remote opt-in; no silent fallback; consume Route Contract v1. | agent-side formation. | `feature/local-first-routing` | local path works with no network; remote requires explicit opt-in; a test proves no silent fallback. | `swift test --filter Routing`. | H7-LOCAL-FIRST-OPTIN, H7-EXEC-MODE-POLICY, H7-IMPL-ROUTE-CONTRACT | ADR-0001; INV-9 |
| H7-IMPL-MODEL-SELECTION | `rag-fish/noema-agent` | Implement explicit model/provider selection + disclosure recording. | explicit selection field; no auto-switch/upgrade; disclosure recorded in evidence. | provider credentials. | `feature/model-provider-selection` | selection is explicit in every contract; a test proves no code path switches model silently. | `pytest -k model_selection`. | H7-PROVIDER-MODEL-SELECTION, H7-IMPL-ROUTE-CONTRACT | ADR-0000 §6 |
| H7-TEST-NO-GATE-BYPASS-INTEGRATION | `rag-fish/noema-agent` | Integration tests proving routing cannot bypass the Human Gate for external acquisition. | attempt to route to acquisition without an approval record → rejected; attempt to synthesise approval in routing → rejected; maps to #35. | perf. | `test/routing-no-gate-bypass` | both bypass attempts fail closed; green in CI. | integration suite. | H7-IMPL-ROUTE-CONTRACT, H7-IMPL-ROUTING-CHANGES, H4-IMPL-HUMANGATE-ENFORCEMENT, #35 | ADR-0004 I3, I8; INV-6 |
| H7-TEST-ROUTE-CONTRACT-UNIT | `rag-fish/noema-agent` | Unit tests for Route Contract formation. | field validation; investigation flag; `investigation_id`; declares-not-executes assertion. | integration. | `test/route-contract-unit` | branch coverage of formation; green in CI. | `pytest -k route_contract_unit`. | H7-IMPL-ROUTE-CONTRACT | ADR-0002 §4 |

### 5.10 Phase 8 — Final UAT / Release

Phase 8 is **unreachable** until every Phase 1–7 spec/ADR is merged **and** every Phase 2–7
implementation task is complete **and** every Phase 2–7 unit/adversarial test is green
(§8, §12.8).

| ID | Type | Target repo | Owner | Description / Objective | Scope | Out of Scope | Branch | DoD | Validation | Dependencies | Governed By | Review / Merge |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| H8-INTEGRATION-UAT-PLAN | spec | RAGfish | Claude CLI | Define how the full epistemic lifecycle is exercised end-to-end across the four repos. | scenarios covering Evidence → NOESIS → Human Gate → (acquisition) → re-analysis → `investigation_result` → NOEMA; per-repo responsibilities; entry/exit criteria; each INV mapped to ≥1 scenario. | running the UAT. | `docs/integration-uat-plan` | plan doc; every INV covered. | manual invariant coverage check. | all Phase 1–7 `spec`/`adr`/`schema` tasks merged | ADR-0004 (whole); INV-1…INV-11 | Arch — Max / ChatGPT · Merge — Taka · squash |
| H8-GOV-REGRESSION-GATE | test | RAGfish | Codex CLI | The pass/fail gate running #35's cases against the integrated system. | wire #35 cases to a runnable suite; pass = every critical invariant fails closed; CI gate. | authoring new cases (#35). | `test/governance-regression-gate` | gate defined + runnable; green required for release. | suite run against the integration build. | #35, *all Phase 2–7 `impl` + `test` tasks*, H8-INTEGRATION-UAT-PLAN | ADR-0004 I6, I7, I8; INV-2, INV-4, INV-6 | Arch — Max / ChatGPT · Merge — Taka · squash |
| H8-CAPABILITY-BOUNDARY-GATE | test | RAGfish | Codex CLI | Prove "can't rather than won't" holds in the built system. | boundary probes per INV-2/INV-4/INV-6 against the integrated build; distinguishes prompt refusal from architectural inability. | new spec authoring. | `test/capability-boundary-gate` | gate defined; every INV-4 capability probed and shown absent by architecture; green required for release. | probe run against the integration build. | #35, H3-TEST-CAPABILITY-ISOLATION, H4-TEST-FAILCLOSED-INTEGRATION, *all Phase 2–7 `impl`*, H8-INTEGRATION-UAT-PLAN | ADR-0004 I2, I6, B1–B4; INV-2 | Arch — Max / ChatGPT · Merge — Taka · squash |
| H8-INTEGRATION-UAT-RUN | test | RAGfish (coordination) | Codex CLI | Execute the cross-repository integration UAT from H8-INTEGRATION-UAT-PLAN. | run every scenario across the four repos; record pass/fail per scenario + per INV. | fixing bugs found (spawns follow-up issues). | `test/integration-uat-run` | every scenario executed; results recorded as an evidence artifact; all green required for Final UAT. | UAT scenario run report. | *all Phase 2–7 `impl` + `test` tasks*, H8-INTEGRATION-UAT-PLAN | ADR-0004 (whole); INV-1…INV-11 | Arch — Max / ChatGPT · Merge — Taka · squash |
| H8-FINAL-UAT | human | all repos | Taka | Taka's governance acceptance of the integrated system. | review the three gate reports + the UAT run report; record sign-off as an evidence artifact. | code changes. | *(review activity — no branch)* | recorded Taka sign-off; all three gates + UAT run green. | gate + run reports attached. | H8-GOV-REGRESSION-GATE, H8-CAPABILITY-BOUNDARY-GATE, H8-INTEGRATION-UAT-RUN | ADR-0000; ADR-0004 INV-1, INV-11 | Final Review / Merge Owner — Taka |
| H8-RELEASE-TAGS | human | all repos | Taka | Tag releases across the four repos. | version tags per repo; only after Final UAT. | notes; publication. | *(tagging activity — no branch)* | tags pushed; each references the Final UAT evidence artifact. | tag review. | H8-FINAL-UAT | INV-11 | Final Review / Merge Owner — Taka |
| H8-RELEASE-NOTES | spec | RAGfish | Claude CLI | Release notes describing the epistemic-governance capability. | changelog linking ADR-0004 → Phase 0–8 evidence; engineering framing. | posting. | `docs/release-notes-hermes` | notes merged; reference the release tags. | review vs ADR-0002 §"External Positioning". | H8-RELEASE-TAGS | ADR-0002 §"External Positioning" | Arch — Max / ChatGPT · Merge — Taka · squash |
| H8-RAGFISH-UPDATE | spec | RAGfish + rag.fish | Claude CLI | Update the rag.fish website with the release. | site page update; external positioning (no philosophy-first framing, no codename-as-descriptor). | posting to social. | `docs/ragfish-site-update` | site update drafted + merged; Taka approves deploy. | external-positioning checklist (ADR-0002). | H8-RELEASE-NOTES | ADR-0002 §"External Positioning" | Arch — Max / ChatGPT · Merge — Taka · squash |
| H8-PUBLICATION | human | external | Taka | Post the X / LinkedIn / Facebook publication package. | X package; LinkedIn post; Facebook post; posted **only after** release tags + site update exist. | posting before release; internal codenames externally. | *(posting activity — no branch)* | posts published; content matches the approved drafts. | Taka review; external-positioning checklist. | H8-RAGFISH-UPDATE, H8-RELEASE-TAGS | ADR-0002 §"External Positioning" | Final Review / Merge Owner — Taka |

### 5.11 Charter milestone remap

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
- The Charter's "read alongside" list cites only ADR-0001/ADR-0002 and omits ADR-0003 **and** ADR-0004. This is **pre-existing documentation drift** (the Charter was not updated when ADR-0003 merged either), not a contradiction introduced by ADR-0004. Fixing it is out of scope for this rebaseline and is better done as its own small `docs/` task (see §9.2).

If architecture review disagrees and wants ADR-0004 explicitly anchored in the Charter, the **minimal** amendment is: add ADR-0003 and ADR-0004 to the "read alongside" list and one sentence pointing to this roadmap — nothing more.

---

## 7. Agent assignment rationale

One Owner Agent per task. Review roles are separate fields, never co-owners.

| Agent | Owns | Why |
|---|---|---|
| **Claude CLI** | Every ADR, governance/capability contract, spec, cross-repo audit, this roadmap, release notes, site update. (37 tasks) | Reasons across the full architecture; translates decisions into durable docs. Authors ADRs; does not merge them. |
| **Codex CLI** | Every JSON Schema (#34, H1-HUMANGATE-RECORD, H1-ACQUISITION-CONTRACT), #35, every implementation task (17), every automated test/benchmark/gate/UAT-run (15). (35 tasks) | Focused implementation, schema, tests, validators, benchmarks from a settled spec. |
| **Taka** | Human-intrinsic tasks only: H8-FINAL-UAT, H8-RELEASE-TAGS, H8-PUBLICATION. (3 tasks) | Governance owner; release + external-communication authority; the UAT sign-off is intrinsically human. |
| **Max / ChatGPT** | *No task ownership.* Architecture Review on every task; named sign-off on all ADRs (ADR-0005/0006/0007/0008) and on H4-APPROVAL-ENFORCEMENT. | Reviewer and task/prompt designer — not the execution owner of a GitHub task. |

*(#35 is `test`-type and design-heavy; Owner = Codex CLI, consistent with "test design owner: Codex" already on the issue. Architecture Review: Max.)*

Ownership totals: Claude 37 + Codex 35 + Taka 3 = **75**.

---

## 8. Dependency DAG

### 8.1 Phase-level flow

```
Phase 0  #32(DONE) → #33 → #34 → #35
                                  │
   ┌──────────────────────────────┼──────────────────────────────┐
   ▼                              ▼                              ▼
Phase 1                        Phase 2                        Phase 3
(Evidence & Acquisition        specs → impl → unit tests      specs/ADR → impl → tests
 contracts + ADR-0005)              │                              │
   │                                │   (H2 impl feeds H5 & H6)    │  (H3 impl feeds H5 & H6)
   ├───────────────┬────────────────┴───────────────┬─────────────┘
   ▼               ▼                                ▼
Phase 4         Phase 5                          (H4 impl feeds H5-IMPL-AUDIT-EMISSION,
specs → impl    specs → impl → tests              H7-TEST-NO-GATE-BYPASS)
 → tests           │
   │               │
   └───────┬───────┘
           ▼
        Phase 6   specs → impl → benchmarks/completeness tests
           │
           ▼
        Phase 7   specs/ADRs → impl → integration + unit tests
           │
           ▼
        Phase 8   UAT plan → [GOV-REGRESSION-GATE ∧ CAPABILITY-BOUNDARY-GATE ∧ INTEGRATION-UAT-RUN]
                            → FINAL-UAT → RELEASE-TAGS → RELEASE-NOTES → RAGFISH-UPDATE → PUBLICATION
```

### 8.2 Within-phase pattern (Phases 2–7)

```
spec/ADR (Claude)  ──merged──▶  impl (Codex)  ──merged──▶  unit/adversarial tests (Codex)  ──green──▶  (Phase 8 gates)
                                    │
                       cross-phase: an impl task may depend on a lower-phase impl task
                       (e.g. H5-IMPL-AUDIT-EMISSION ← H2-IMPL-RECOMPUTE, H3-IMPL-NOEMA-CONTEXT, H4-IMPL-HUMANGATE-ENFORCEMENT)
```

### 8.3 Phase 8 gate (strengthened — finding 4)

```
                 ┌─ all Phase 1–7 spec/adr/schema merged ─┐
                 │                                        ▼
                 │                              H8-INTEGRATION-UAT-PLAN
                 │                                        │
 all Phase 2–7 impl complete ───────┐                     │
 all Phase 2–7 unit/adversarial ────┤                     │
   tests green                      ▼                     ▼
                          H8-GOV-REGRESSION-GATE    H8-INTEGRATION-UAT-RUN
                          H8-CAPABILITY-BOUNDARY-GATE      │
                                    │                      │
                                    └───────────┬──────────┘
                                                ▼
                                         H8-FINAL-UAT   (Taka)
                                                ▼
                                         H8-RELEASE-TAGS (Taka)
                                                ▼
                                         H8-RELEASE-NOTES
                                                ▼
                                         H8-RAGFISH-UPDATE
                                                ▼
                                         H8-PUBLICATION  (Taka)  ◀── downstream of successful release
```

### 8.4 Acyclicity & ordering checks

- **Acyclic:** every dependency edge points from a lower or equal phase number to a higher or equal one; within a phase the only edges are `spec → impl → test` (a chain); cross-phase edges only ever go *earlier → later*. No back-edges ⇒ no cycles. (Re-verified by inspection of §5.1 after adding 31 tasks.)
- **Every `impl` task depends on its governing `spec`/`adr`:** verified per row in §5.1 (e.g. `H3-IMPL-NOEMA-CONTEXT` ← `H3-NOEMA-ISOLATION`, `H3-NARRATIVE-CONTRACT`, `H3-ADR-NOEMA-HOSTING`).
- **Every `test` task depends on the `impl` it validates.**
- **Every release/UAT task has implementation completion in its dependency chain:** `H8-FINAL-UAT` ← `H8-INTEGRATION-UAT-RUN` ← *all Phase 2–7 impl + test*; `H8-RELEASE-TAGS` ← `H8-FINAL-UAT`; publication ← release tags.
- **No implementation precedes its spec:** all `impl`/`test` are in the same or a later phase than their governing `spec`/`adr`, which must be *merged* first (INV-8).

---

## 9. Findings

### 9.1 Conflicts with ADR-0000 → ADR-0004

**None.** Cross-checked:

- **ADR-0000 (Human Sovereignty):** every phase preserves explicit invocation, routing authority with the human (H7-ROUTING-AUTHORITY-INVARIANT, H7-TEST-NO-GATE-BYPASS-INTEGRATION), execution transparency (audit-chain impl + verification), human override (decline at the Human Gate), state-mutation consent (only Noesis mutates investigation state; H2-IMPL-RECOMPUTE has no downstream patch path), model neutrality (H7-IMPL-MODEL-SELECTION + its no-silent-switch test), transparency over optimization (H6-IMPL-CACHING-ASYNC test proves re-analysis is never served from a cache). No Anti-Pattern introduced.
- **ADR-0001 (four repos):** no repo boundary changes; every spec lands in `RAGfish` first; impl tasks target exactly one repo (or `Conditional` pending ADR-0005).
- **ADR-0002 (nine-stage pipeline):** the epistemic lifecycle is an overlay; Route Contract impl (H7) extends ADR-0002 §4; trust-vs-confidence preserved and unit-tested (H5-TEST-TRUST-CONTEXT-UNIT).
- **ADR-0003 (four planes, G1–G6, zero runtime human gates for ordinary queries):** Human Gate scoped to the external trust boundary only (INV-6, INV-9); "can't rather than won't" is enforced by the capability-isolation + fail-closed tests; G6 extended by H5-AUDITCHAIN-EPISTEMIC + verified by H5-TEST-AUDITCHAIN-VERIFY.
- **ADR-0004 (incl. `23b5736`):** INV-1…INV-7 lifted directly; I11/I12 honoured — no task assigns governance authority to the NOESIS layer.

No task violates human sovereignty, "can't rather than won't", Noema capability isolation, the `investigation_result`-only handoff, or contracts-before-implementation.

### 9.2 Stale / needs-attention existing issues

| Item | Recommendation (not actioned here) |
|---|---|
| **#27** depends on closed EPIC-era "Issue 4 / Issue 7" and predates ADR-0004 | Amend via `H6-27-AMEND` in Phase 6. **#27 not edited in this task.** |
| **ROADMAP-v2 Dependency Matrix** — "TBD" rows + "Issue 4/7" refs | Superseded by §5. v2 retained unchanged as history (with a superseded-by pointer added to its status block only). |
| **#26 / #18** — backlog & sequencing docs | Superseded by ROADMAP-v3 for future planning; kept as historical evidence. |
| **ADR-0001/0002/0003/0004 headers still say `Status: Proposed`** despite being merged and authoritative | Status-hygiene task, own `docs/` PR. Out of scope here. |
| **Charter v2 "read alongside" list** omits ADR-0003 and ADR-0004 | Minimal `docs/` touch-up (§6). Out of scope here. |
| **GitHub Project #16** not inspectable — `gh` token lacks `read:project` | Run `gh auth refresh -s read:project` and verify Project #16 field IDs before board population (§10). |

### 9.3 Project Charter v2 modification

**Not modified.** See §6.

### 9.4 Unresolved execution-locus questions

| Question | Resolved by | Tasks left `Conditional` until then |
|---|---|---|
| **Where does approved external acquisition execute?** ADR-0004 names `noema-agent` only as a *candidate* and defers the decision. | **`H1-ADR-ACQ-LOCUS` (ADR-0005, Noema)** | `H4-IMPL-SEALED-GATEWAY`, `H4-IMPL-PROVIDER-ADAPTER`, `H4-TEST-FAILCLOSED-INTEGRATION`, `H4-TEST-GATEWAY-UNIT` — Target Repository = `Conditional — ADR-0005 (candidate: noema-agent)`; each already depends on `H1-ADR-ACQ-LOCUS`. |
| **Does Noema-layer narrative work run inside `noema-agent` or its own context?** ADR-0004 leaves this open (Rejected Alternative D allows a later "host inside `noema-agent`" decision). | **`H3-ADR-NOEMA-HOSTING` (ADR-0006, Noema)** | `H3-IMPL-NOEMA-CONTEXT` proceeds in `NoesisNoema` regardless (the *isolation* is required either way), but its hosting/module boundary is finalised by ADR-0006, which is a dependency. |

Both ADRs are **inside Phase 1 / Phase 3** and gate their implementation tasks — the roadmap does not assume either answer.

---

## 10. Rebuilding GitHub Project #16 from this roadmap

Project #16 (Hermes) is **not touched** by this task. After architecture review approves the roadmap:

1. **Keep** #33, #34, #35 as-is; mark #32 Done.
2. **Move** #27 into Phase 6, `blocked pending H6-27-AMEND`.
3. **Retire from the board** items whose only content is the old Phase A–F framing or the "Issue 4 / Issue 7" rows (§3.4). Retire = remove from the active board, not delete the issue.
4. **Create** one issue per task in §5.1 (all 71 non-#32 tasks), using the §5.2–§5.10 field blocks/rows verbatim for the Issue body (13 fields incl. Governed By).
5. **Set dependencies** per §8; expand the "*all Phase 2–7 `impl` + `test`*" shorthands on the three Phase-8 gates into explicit task-ID lists at creation time.
6. **Status field:** #33 → `ready`; every other task → `proposed` until its dependencies are merged/green.
7. `Conditional` target repos (H4 impl/test) get their repo set the moment ADR-0005 merges.

Issue creation and board population happen **after** this roadmap passes architecture review — not in this task.

---

## 11. Next executable task

**#33 — Docs: define governance contract and capability matrix.** Unchanged from revision 1.

- Its only dependency, **#32 (ADR-0004)**, is merged to `main` (PR #36, incl. `23b5736`).
- Gating contract for #34, #35, and every Phase 1 task.
- No blocking architectural dependency ahead of it.
- Owner: **Claude CLI**. Branch: `docs/governance-capability-contract`.

---

## 12. Validation performed

1. **Cross-check against ADR-0000 → ADR-0004** — §9.1. No conflicts.
2. **Cross-check against Project Charter v2** — §6. No change required.
3. **Cross-check against the Human-Governed Development Loop** — every task carries the 12 loop fields **plus Governed By** (§5.0); branch names follow `<type>/<short-name>`; every merge is `Final Review / Merge Owner — Taka`.
4. **Referenced existing issues verified to exist:** #27 (open), #32 (closed/merged), #33 (open), #34 (open), #35 (open), #25/#26 (closed) — via `gh issue view`.
5. **Every task has exactly one Owner Agent** — `Claude CLI` (37), `Codex CLI` (35), `Taka` (3); total 75. Max / ChatGPT owns nothing (reviewer only). No task lists a pair or an arrow. (§7)
6. **Dependencies contain only task/artifact references** — issues, task IDs, merged ADRs. Architectural constraints are in the separate **Governed By** field. `INV-*` and `I5`-style clauses appear only under Governed By. (§5.0, §5.2–§5.10)
7. **Implementation layer added** — 17 `impl` tasks across Phases 2–7; every one depends on its governing spec/ADR (§8.4).
8. **Automated validation layer added** — 12 new `test`/benchmark/UAT-run tasks (plus the pre-existing #35 and the 3 Phase-8 gates). Every `impl` task has ≥1 test task depending on it.
9. **Phase 8 cannot be reached without implementation completion** — `H8-FINAL-UAT` ← `H8-INTEGRATION-UAT-RUN` + `H8-GOV-REGRESSION-GATE` + `H8-CAPABILITY-BOUNDARY-GATE`, each of which depends on *all Phase 2–7 `impl` + `test` tasks*. Publication (`H8-PUBLICATION`) ← `H8-RAGFISH-UPDATE` ← `H8-RELEASE-NOTES` ← `H8-RELEASE-TAGS` ← `H8-FINAL-UAT`. (§8.3)
10. **DAG re-verified acyclic** after adding 31 tasks — §8.4.
11. **Total task count recalculated: 75** (was 44 in revision 1). Breakdown in §5.1.
12. **Historical Hermes assets not silently discarded** — §3 unchanged; RETIRE list still 4 entries, each with a reason; ROADMAP-v2 retained.
13. **Preserved items checked:** ADR-0004 baseline (unchanged), Phase 0 #32→#33→#34→#35 (unchanged), KEEP/MOVE/REPLACE/RETIRE rationale (unchanged), Charter v2 (untouched), ROADMAP-v2 historical preservation (banner only), Human Gate scope (external trust boundary only), Noema capability isolation (INV-4, now with impl + adversarial tests), "NOESIS assesses / human noesis governs" (INV-1, I11/I12), external-acquisition executor deferral (§9.4), local-first default (INV-9, H7-LOCAL-FIRST-OPTIN + impl + test).

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
