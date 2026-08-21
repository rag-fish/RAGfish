# Governed AI Development

A framework for building software where AI executes and humans decide — and where the system keeps working if either one temporarily can't.

## 1. Executive Summary

Governed AI Development is a methodology for building software systems in which specification, task orchestration, implementation, and maintenance are separated into distinct, auditable layers — so that AI and human contributors can each do the part they are actually good at, without either becoming a single point of failure.

The problem it solves is structural, not motivational. AI systems, however capable, cannot originate design intent: they have no stake in a product's future, no accountability for a wrong tradeoff, and no memory across sessions unless one is built for them. Humans, meanwhile, cannot execute at the speed or breadth that modern development demands — not because they lack skill, but because attention and time are finite.

Governed AI Development treats this as complementarity, not compromise: design decisions are human-owned, execution is AI-enabled, and both are bound to a shared specification that survives either party's absence. The result is a system that is resilient (functions with or without AI assistance), credible (every decision traces to a written rationale), and maintainable (the person who inherits the code six months from now can reconstruct *why*, not just *what*).

## 2. Philosophical Foundation

Socratic method begins from an admission: *I know that I know nothing.* That posture — treating one's own certainty as the thing to interrogate — is usually read as a discipline for the human mind. Applied to AI-assisted development, it becomes something more literal. An AI model, however articulate, knows nothing about a specific system until it is told: no context on why a table was denormalized, no memory of the incident that made a given check mandatory, no stake in whether next quarter's roadmap survives a shortcut taken today. Its fluency can disguise this unknowing, which is precisely why the disguise has to be refused rather than trusted.

The complementary failure sits on the human side. A person can hold intent, tradeoffs, and long-term consequences in mind — but cannot type, test, and verify at the rate a codebase now demands, nor hold every file in working memory at once. Neither party's gap is a flaw to be trained away. It is a permanent asymmetry to be designed around.

Governed AI Development designs around it by drawing one hard line: **design decisions are human-owned; execution can be AI-enabled.** A decision is anything that trades one future against another — what a system will and won't do, what failure it accepts in exchange for what it prevents. Execution is anything that, once a decision is written down, can be carried out by whoever or whatever is fastest and most available.

The hinge between the two is the specification. Not a ticket description or a comment thread, but a written artifact — an ADR, a schema, a policy manifest — durable enough that a human reads it to understand *why*, and precise enough that an AI (or a new engineer) can execute against it without re-deriving intent from scratch. The spec is not a deliverable of the process. It is the interface the whole process runs on.

## 3. Core Hierarchy

Governed AI Development organizes work into four layers. Each layer has a distinct owner, produces a distinct artifact, and closes off a distinct failure mode. Skipping a layer doesn't speed the system up — it just moves the failure downstream, where it costs more to find.

### Layer 1 — Specification (Human-owned)

**Purpose:** Record the decision and the reasoning behind it before any code is written.
**Artifacts:** Architecture Decision Records (ADRs), interface/schema definitions (UML, JSON Schema, XML), design docs stating context, decision, options considered, and consequences.
**Prevents:** Silent scope drift and undocumented tradeoffs. A team of four repositories that each maintains its own ADR sequence — as RAGfish's Noema architecture does across ADR-0000 (the Human Sovereignty Principle), ADR-0001 (repo boundaries), and ADR-0002/0003 (governance pipeline) — can resolve a scope dispute by pointing at a document instead of re-litigating it in a thread.

### Layer 2 — Task Orchestration (Spec-driven)

**Purpose:** Turn an approved spec into trackable, dependency-ordered units of work.
**Artifacts:** A project board treated as a state machine, not a to-do list — one task, one issue, one branch, one PR. Status transitions (`proposed → ready → in progress → in review → merged`, with an explicit `blocked` state) are the visible record of where work actually stands.
**Prevents:** Work that exists nowhere but a contributor's local branch, and the coordination failures that follow — two agents editing the same boundary, a merge with no linked rationale, a "done" that no one can verify.

### Layer 3 — Implementation (AI or Human)

**Purpose:** Execute against the spec, by whichever contributor — human or AI — is best suited to the task's shape.
**Artifacts:** Coding rules as hard constraints (not suggestions), structured prompts that carry the spec's intent forward instead of re-summarizing it, and machine-checkable validation gates that reject output the spec doesn't sanction.
**Prevents:** Divergence between what was decided and what was built. A concrete pattern for this is a promotion gate: work is not "in" until it passes a checkable condition tied back to the spec — not a subjective review, a specific threshold. Assign implementation by task shape, not by ideology — broad investigation and documentation to one kind of contributor, narrow well-scoped patches to another, exploratory or ambiguous work to a human.

### Layer 4 — Maintenance (Either / Both)

**Purpose:** Keep the spec and the system truthful to each other as both evolve.
**Artifacts:** ADR amendments (superseding, not silently editing, prior decisions), audit trails that record what happened independent of who or what triggered it, operational feedback that closes the loop back to Layer 1 when reality contradicts the spec.
**Prevents:** The slow rot where documentation and implementation quietly diverge until neither can be trusted — the single most common reason inherited systems become unmaintainable.

The layers form a cycle, not a pipeline: maintenance feeds discoveries back into specification, and the loop runs again.

## 4. Resilience Model

A framework earns its credibility by naming its own failure modes before a prospect finds them.

### Scenario 1 — AI-Only Execution

**What works:** High-throughput implementation against an existing spec. Machine-checkable gates keep output within declared bounds without needing a human in the per-task loop.
**What breaks:** Design tradeoffs. An AI system executing without a human decision layer cannot originate the judgment call embedded in "we accept slower promotion in exchange for catching regressions before they ship" — it can only optimize whatever objective it's handed, including a badly chosen one. Left alone, AI-only execution silently expands scope, invents interfaces the spec never sanctioned, and treats plausible output as validated output. The concrete failure this framework is built to prevent looks exactly like this: a system quietly producing confident, ungrounded answers because nothing forced a check on whether the underlying data actually supported them.

### Scenario 2 — Human-Only Maintenance

**What works:** Judgment, accountability, and the ability to reason about consequences an automated gate can't yet formalize.
**What breaks:** Parallelism. A human maintaining a system alone cannot keep pace with implementation, testing, and documentation running concurrently across multiple work streams. Throughput collapses to whatever one person can hold in working memory, and the backlog of "known but not yet done" grows without bound.

### Scenario 3 — Human + Spec-Driven AI

**What works:** Both failure modes close simultaneously. The human owns the decision layer (Layer 1) and holds final approval at defined gates; AI executes at Layer 3 against a spec precise enough to bound its behavior. Because the spec is the shared interface, neither party needs to re-derive the other's context — the human doesn't need to review every line of generated code, and the AI doesn't need to guess intent. This is the condition under which an interactive, latency-sensitive system can stay governed without putting a human in every request path: ordinary execution passes through machine-checkable policy, and a human gate exists only where a decision — not an execution — is being made, such as approving a policy change or a corpus promotion.

## 5. Implementation: What's Framework vs. Practice

Consulting engagements fail when a client can't tell which parts of a methodology are load-bearing and which are just how the last team happened to do it. Governed AI Development draws that line explicitly.

**FRAMEWORK — non-negotiable:**
- Spec-first, not explore-first: no implementation begins without a written decision to execute against.
- Design decisions live in an ADR (or equivalent durable record) — not a chat log, not tribal knowledge.
- Coding rules are constraints the system enforces, not style guidance a contributor may skip under deadline pressure.
- Output is validated against the spec and the rules before it's considered done — validation is a gate, not a suggestion.
- A human approval gate exists at defined points (policy change, promotion, release) — it is never fully automated away.

**PRACTICE — flexible, adapt to your team:**
- Which version control system and hosting platform.
- How tasks link to branches and PRs (naming convention, automation tooling).
- Exact ADR template syntax and numbering scheme.
- Which code review tooling or CI provider is in use.

These are preferences; adjust them for your team's existing tooling. The framework survives a change in any of them.

## 6. Consulting Positioning

The pitch "AI is fast" is a commodity claim — every vendor makes it, and it collapses the moment a prospect asks what happens when the fast thing is also wrong. "Governed AI Development" sells a different claim: *this system stays correct and maintainable regardless of which contributor — human or AI — touches it next.* That claim survives scrutiny because it's falsifiable — a prospect can ask to see the ADR, the gate, and the audit trail, and each one either exists or doesn't.

**Case study: Noema Architecture.** RAGfish's Noema platform is a working instance of this framework, not a hypothetical. Its decision layer is a sequence of ADRs: ADR-0000 establishes Human Sovereignty as an immutable governing principle; ADR-0001 defines a four-repository architecture as a deliberate governance boundary (private local cognition, corpus production, orchestration, and architecture hub, each with an explicit non-goal list); ADR-0002 and ADR-0003 extend that into a machine-enforced governance platform.

That platform is organized as four planes — Policy, Knowledge, Runtime, Audit — bound by six machine-checkable rules (G1–G6): no ungrounded generation without an explicit label, version pinning on every answer via a `(model_id, manifest_sha256)` triplet, a promotion gate that blocks a corpus update unless it clears a quality threshold, change control via ADR and pull request, budget enforcement pre-inference, and audit completeness — a missing audit event invalidates the run. The policy manifest itself is sha256-pinned, so consumers can verify they're running against the exact decision that was approved, not a drifted copy.

Maintenance-readiness is designed in, not bolted on: audit evidence is an append-only, hash-chained log, Ed25519-signed for offline verification, so a prospect (or a successor engineer) can check what happened without trusting whoever is reporting it. Task orchestration runs through a GitHub Project board treated as the authoritative state machine — one task, one issue, one branch, one PR — with defined actors for broad audit and documentation work, focused implementation, and final merge approval. None of this depends on any single contributor remaining in the loop.

Sell the resilience, not the speed. A prospect who has been burned by an AI-only pilot that quietly drifted from its spec is not looking for a faster version of what failed — they're looking for a framework that names the failure mode and closes it.

## 7. Getting Started

You don't need the full six-rule governance platform on day one. The minimal viable version:

**Essential:**
1. Write one ADR for the first real architectural decision on the project — context, decision, options considered, consequences. This is the seed of Layer 1.
2. Write a one-page coding-rules document stating hard constraints (not style preferences) that any contributor, human or AI, must satisfy.
3. Set up a task board with a single lifecycle: proposed → ready → in progress → in review → merged/blocked. One task, one issue, one branch, one PR.
4. Define one human approval gate — even just "the repo owner merges every PR" counts as a start.

**Optional until it hurts to not have it:**
- Machine-checkable promotion gates tied to a quality metric.
- An audit trail beyond what your version control already gives you.
- Multiple named AI contributor roles (broad investigation vs. focused implementation).

**Example ADR skeleton:**
```markdown
# ADR-NNNN: <Decision Title>

**Status:** Proposed | Accepted | Superseded
**Date:** YYYY-MM-DD
**Deciders:** <names>

## Context
<What forces this decision now?>

## Decision
<What are we doing?>

## Options Considered
<Alternatives and why they were rejected>

## Consequences
<What gets easier, what gets harder>
```

For a working example at greater scale, see RAGfish's `docs/adr/` and `docs/noema/adr/` — two ADR sequences, one per governance scope, cross-referenced rather than merged, showing how the pattern holds even when a project outgrows a single decision log.
